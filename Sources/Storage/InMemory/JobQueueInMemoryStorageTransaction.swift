///
///  Created by George Cox on 1/27/20.
///

import Foundation
import ReactiveSwift
#if SWIFT_PACKAGE
import JobQueueCore
#endif

public class JobQueueInMemoryStorageTransaction: JobStorageTransaction {
  private let logger: Logger
  private var data: [JobQueueName: [JobID: JobDetails]]
  private var queue: JobQueueProtocol?

  internal var changes = [JobStorageTransactionChange]()
  internal let id = UUID().uuidString

  public init(
    queue: JobQueueProtocol? = nil,
    data: [JobQueueName: [JobID: JobDetails]],
    logger: Logger
  ) {
    self.logger = logger
    self.queue = queue
    self.data = data
  }

  public func get(_ id: JobID, queue: JobQueueProtocol?) -> Result<JobDetails, Error> {
    guard let queue = (queue ?? self.queue) else {
      return .failure(JobStorageError.noQueueProvided)
    }
    guard let jobs = self.data[queue.name] else {
      return .failure(JobStorageError.queueNotFound(queue.name))
    }
    guard let job = jobs[id] else {
      return .failure(JobStorageError.jobNotFound(queue.name, id))
    }
    return .success(job)
  }

  public func getAll(queue: JobQueueProtocol?) -> Result<[JobDetails], Error> {
    guard let queue = (queue ?? self.queue) else {
      return .failure(JobStorageError.noQueueProvided)
    }
    guard let jobs = self.data[queue.name] else {
      return .success([JobDetails]())
    }
    return .success(jobs.values.map { $0 })
  }

  public func store(_ job: JobDetails, queue: JobQueueProtocol?) -> Result<JobDetails, Error> {
    guard let queue = (queue ?? self.queue) else {
      return .failure(JobStorageError.noQueueProvided)
    }
    var jobs = self.data[queue.name, default: [JobID: JobDetails]()]
    jobs[job.id] = job
    self.data[queue.name] = jobs
    self.changes.append(.stored(queue.name, job.id, job))
    return .success(job)
  }

  public func remove(_ id: JobID, queue: JobQueueProtocol?) -> Result<JobID, Error> {
    guard let queue = (queue ?? self.queue) else {
      return .failure(JobStorageError.noQueueProvided)
    }
    guard var jobs = self.data[queue.name] else {
      return .success(id)
    }
    guard let job = jobs[id] else {
      return .success(id)
    }
    jobs.removeValue(forKey: id)
    self.data[queue.name] = jobs
    self.changes.append(.removed(queue.name, job.id, job))
    return .success(id)
  }

  public func remove(_ job: JobDetails, queue: JobQueueProtocol?) -> Result<JobDetails, Error> {
    guard let queue = (queue ?? self.queue) else {
      return .failure(JobStorageError.noQueueProvided)
    }
    guard var jobs = self.data[queue.name] else {
      return .success(job)
    }
    guard jobs[job.id] != nil else {
      return .success(job)
    }
    jobs.removeValue(forKey: job.id)
    self.data[queue.name] = jobs
    self.changes.append(.removed(queue.name, job.id, job))
    return .success(job)
  }

  public func removeAll(queue: JobQueueProtocol?) -> Result<Void, Error> {
    guard let queue = (queue ?? self.queue) else {
      return .failure(JobStorageError.noQueueProvided)
    }
    guard self.data[queue.name] != nil else {
      return .success(())
    }
    self.data.removeValue(forKey: queue.name)
    self.changes.append(.removedAll(queue.name))
    return .success(())
  }
}
