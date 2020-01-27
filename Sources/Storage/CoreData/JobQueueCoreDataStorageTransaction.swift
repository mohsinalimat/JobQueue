///
///  Created by George Cox on 1/27/20.
///

import Foundation
import ReactiveSwift
import CoreData
#if SWIFT_PACKAGE
import JobQueueCore
#endif

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

    public func get(_ id: JobID, queue: JobQueueProtocol?) -> Result<JobDetails, Error> {
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

    public func getAll(queue: JobQueueProtocol?) -> Result<[JobDetails], Error> {
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

    public func store(_ job: JobDetails, queue: JobQueueProtocol?) -> Result<JobDetails, Error> {
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
