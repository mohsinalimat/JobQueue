///
///  Created by George Cox on 1/25/20.
///

import Foundation
import ReactiveSwift
import CoreData
#if SWIFT_PACKAGE
import JobQueueCore
#endif

public class JobQueueCoreDataStorageEntity: NSManagedObject {
  dynamic var jobId: String!
  dynamic var jobQueueName: String!
  dynamic var job: AnyJob!
}

public class JobQueueCoreDataStorage<Entity: JobQueueCoreDataStorageEntity>: JobStorage {
  private let logger: Logger
  private let createContext: () -> NSManagedObjectContext?
  private let rollback: (NSManagedObjectContext) -> Void
  private let commit: (NSManagedObjectContext) -> SignalProducer<Void, Error>

  public init(
    _ entity: Entity.Type,
    createContext: @escaping () -> NSManagedObjectContext,
    rollback: @escaping (NSManagedObjectContext) -> Void,
    commit: @escaping (NSManagedObjectContext) -> SignalProducer<Void, Error>,
    logger: Logger = ConsoleLogger()
  ) {
    self.createContext = createContext
    self.rollback = rollback
    self.commit = commit
    self.logger = logger
  }

  public func transaction<T>(
    queue: JobQueueProtocol,
    _ closure: @escaping (JobStorageTransaction) throws -> T
  ) -> SignalProducer<T, Error> {
    return SignalProducer { o, lt in
      guard let context = self.createContext() else {
        o.send(error: Errors.noContext)
        return
      }
      let transaction = Transaction(
        queue: queue,
        context: context,
        logger: self.logger
      )
      do {
        let closureResult = try closure(transaction)
        self.commit(context).startWithResult { commitResult in
          switch commitResult {
          case .success:
            o.send(value: closureResult)
            o.sendCompleted()
          case .failure(let error):
            o.send(error: error)
          }
        }
      } catch {
        self.rollback(context)
        o.send(error: error)
      }
    }
  }
}

extension JobQueueCoreDataStorage {
  public enum Errors: Error {
    case noContext
  }
}

extension NSManagedObjectID {
  static func from(_ string: String, in context: NSManagedObjectContext) -> NSManagedObjectID? {
    guard let coordinator = context.persistentStoreCoordinator else {
      return nil
    }
    guard let url = URL(string: string) else {
      return nil
    }
    return coordinator.managedObjectID(forURIRepresentation: url)
  }
}
extension NSManagedObject {
  static func with(id: String, queue: JobQueueProtocol, in context: NSManagedObjectContext) -> Self? {
    guard let managedObjectID = NSManagedObjectID.from(id, in: context) else {
      return nil
    }
    return context.object(with: managedObjectID) as? Self
  }
}
extension JobQueueCoreDataStorage {
  public class Transaction: JobStorageTransaction {
    private var queue: JobQueueProtocol?
    private let logger: Logger
    private let context: NSManagedObjectContext

    internal let id = UUID().uuidString

    public init(
      queue: JobQueueProtocol? = nil,
      context: NSManagedObjectContext,
      logger: Logger
    ) {
      self.queue = queue
      self.context = context
      self.logger = logger
    }

    private func getEntities(queue: JobQueueProtocol?) -> Result<[Entity], Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }
      let fetchRequest = Entity.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "jobQueueName == %@", queue.name, id)
      do {
        guard let rawResult = try context.fetch(fetchRequest).first else {
          return .failure(JobStorageError.jobNotFound(queue.name, id))
        }
        guard let result = rawResult as? [Entity] else {
          return .failure(JobStorageError.jobNotFound(queue.name, id))
        }
        return .success(result)
      } catch {
        return .failure(error)
      }
    }

    private func getEntity(_ id: JobID, queue: JobQueueProtocol?) -> Result<Entity, Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }
      let fetchRequest = Entity.fetchRequest()
      fetchRequest.predicate = NSPredicate(format: "jobQueueName == %@ && jobQueueJobId == %@", queue.name, id)
      do {
        guard let rawResult = try context.fetch(fetchRequest).first else {
          return .failure(JobStorageError.jobNotFound(queue.name, id))
        }
        guard let result = rawResult as? Entity else {
          return .failure(JobStorageError.jobNotFound(queue.name, id))
        }
        return .success(result)
      } catch {
        return .failure(error)
      }
    }

    public func get(_ id: JobID, queue: JobQueueProtocol?) -> Result<AnyJob, Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }
      let entityResult = self.getEntity(id, queue: queue)
      switch entityResult {
      case .success(let entity):
        return .success(entity.job)
      case .failure(let error):
        return .failure(error)
      }
    }

    public func get<T>(_ id: JobID, queue: JobQueueProtocol?) -> Result<T, Error> where T: Job {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }
      let entityResult = self.getEntity(id, queue: queue)
      switch entityResult {
      case .success(let entity):
        guard let job = entity.job as? T else {
          return .failure(JobStorageError.jobTypeMismatch)
        }
        return .success(job)
      case .failure(let error):
        return .failure(error)
      }
    }

    public func get<T>(_ type: T.Type, _ id: JobID, queue: JobQueueProtocol?) -> Result<T, Error> where T : Job {
      self.get(id, queue: queue)
    }

    public func getAll(queue: JobQueueProtocol?) -> Result<[AnyJob], Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }
      let result = self.getEntities(queue: queue)
      switch result {
      case .success(let entities):
        return .success(entities.map { $0.job })
      case .failure(let error):
        return .failure(error)
      }
    }

    public func store(_ job: AnyJob, queue: JobQueueProtocol?) -> Result<AnyJob, Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }
      let entityResult = self.getEntity(job.id, queue: queue)
      switch entityResult {
      case .success(let entity):
        // TODO: Guard for entity.jobId matching job.id
        // TODO: Guard for entity.jobQueueName matching queue.name
        entity.job = job
        return .success(job)
      case .failure(let error):
        switch error {
        case JobStorageError.jobNotFound:
          let entity = Entity(context: self.context)
          entity.job = job
          entity.jobId = job.id
          entity.jobQueueName = queue.name
          return .success(job)
        default:
          return .failure(error)
        }
      }
    }

    public func store<T>(_ job: T, queue: JobQueueProtocol?) -> Result<T, Error> where T: Job {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }
      let entityResult = self.getEntity(job.id, queue: queue)
      switch entityResult {
      case .success(let entity):
        // TODO: Guard for entity.jobId matching job.id
        // TODO: Guard for entity.jobQueueName matching queue.name
        // TODO: Guard for job type matching T
        entity.job = job
        return .success(job)
      case .failure(let error):
        switch error {
        case JobStorageError.jobNotFound:
          let entity = Entity(context: self.context)
          entity.job = job
          entity.jobId = job.id
          entity.jobQueueName = queue.name
          return .success(job)
        default:
          return .failure(error)
        }
      }
    }

    public func store<T>(_ type: T.Type, _ job: T, queue: JobQueueProtocol?) -> Result<T, Error> where T : Job {
      self.store(job, queue: queue)
    }

    public func remove(_ id: JobID, queue: JobQueueProtocol?) -> Result<JobID, Error> {
      let result = self.getEntity(id, queue: queue)
      switch result {
      case .success(let entity):
        context.delete(entity)
        return .success(id)
      case .failure(let error):
        switch error {
        case JobStorageError.jobNotFound:
          return .success(id)
        default:
          return .failure(error)
        }
      }
    }

    public func remove(_ job: AnyJob, queue: JobQueueProtocol?) -> Result<AnyJob, Error> {
      let result = self.getEntity(job.id, queue: queue)
      switch result {
      case .success(let entity):
        context.delete(entity)
        return .success(job)
      case .failure(let error):
        switch error {
        case JobStorageError.jobNotFound:
          return .success(job)
        default:
          return .failure(error)
        }
      }
    }

    public func remove<T>(_ job: T, queue: JobQueueProtocol?) -> Result<T, Error> where T: Job {
      let result = self.getEntity(job.id, queue: queue)
      switch result {
      case .success(let entity):
        // TODO: Guard for entity's job matching type of T
        context.delete(entity)
        return .success(job)
      case .failure(let error):
        switch error {
        case JobStorageError.jobNotFound:
          return .success(job)
        default:
          return .failure(error)
        }
      }
    }

    public func remove<T>(_ type: T.Type, _ job: T, queue: JobQueueProtocol?) -> Result<T, Error> where T : Job {
      self.remove(job, queue: queue)
    }

    public func removeAll(queue: JobQueueProtocol?) -> Result<Void, Error> {
      let result = self.getEntities(queue: queue)
      switch result {
      case .success(let entities):
        entities.forEach { entity in
          context.delete(entity)
        }
        return .success(())
      case .failure(let error):
        return .failure(error)
      }
    }
  }
}
