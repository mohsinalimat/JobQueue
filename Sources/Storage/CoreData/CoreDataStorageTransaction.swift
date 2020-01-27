///
///  Created by George Cox on 1/27/20.
///

import Foundation
import ReactiveSwift
import CoreData
#if SWIFT_PACKAGE
import JobQueueCore
#endif

extension CoreDataStorage {
  public class Transaction: JobStorageTransaction {
    private var queue: JobQueueProtocol?
    private let logger: Logger
    private let context: NSManagedObjectContext
    private typealias Entity = JobDetailsCoreDataStorageEntity

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
      fetchRequest.predicate = NSPredicate(format: "queue == %@", queue.name)
      do {
        let rawResult = try context.fetch(fetchRequest)
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
      fetchRequest.predicate = NSPredicate(format: "queue == %@ && id == %@", queue.name, id)
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

    public func get(_ id: JobID, queue: JobQueueProtocol?) -> Result<JobDetails, Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }
      let entityResult = self.getEntity(id, queue: queue)
      switch entityResult {
      case .success(let entity):
        do {
          return .success(try entity.getJobDetails())
        } catch {
          return .failure(error)
        }
      case .failure(let error):
        return .failure(error)
      }
    }

    public func getAll(queue: JobQueueProtocol?) -> Result<[JobDetails], Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }
      let result = self.getEntities(queue: queue)
      switch result {
      case .success(let entities):
        do {
          return .success(try entities.map { try $0.getJobDetails() })
        } catch {
          return .failure(error)
        }
      case .failure(let error):
        return .failure(error)
      }
    }

    public func store(_ details: JobDetails, queue: JobQueueProtocol?) -> Result<JobDetails, Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }
      let entityResult = self.getEntity(details.id, queue: queue)
      switch entityResult {
      case .success(let entity):
        // TODO: Guard for entity.jobId matching job.id
        // TODO: Guard for entity.jobQueueName matching queue.name
        do {
          try entity.setJobDetails(details)
          return .success(details)
        } catch {
          return .failure(error)
        }
      case .failure(let error):
        switch error {
        case JobStorageError.jobNotFound:
          let entity = Entity(context: self.context)
          do {
            try context.obtainPermanentIDs(for: [entity])
            try entity.setJobDetails(details)
            return .success(details)
          } catch {
            return .failure(error)
          }
        default:
          return .failure(error)
        }
      }
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

    public func remove(_ job: JobDetails, queue: JobQueueProtocol?) -> Result<JobDetails, Error> {
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
