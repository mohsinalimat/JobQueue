///
///  Created by George Cox on 1/22/20.
///

import Foundation
import JobQueue
import ReactiveSwift

public enum JobStorageTransactionChange {
  case stored(JobQueueName, JobID, AnyJob)
  case removed(JobQueueName, JobID, AnyJob)
  case removedAll(JobQueueName)
}

public class JobQueueInMemoryStorageTransaction: JobStorageTransaction {
  private var data: [JobQueueName: [JobID: AnyJob]]
  private var queue: JobQueue?

  internal var changes = [JobStorageTransactionChange]()

  public init(
    queue: JobQueue? = nil,
    data: [JobQueueName: [JobID: AnyJob]]
  ) {
    self.queue = queue
    self.data = data
  }

  public func get(_ id: JobID, queue: JobQueue?) -> Result<AnyJob, Error> {
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

  public func get<T>(_ id: JobID, queue: JobQueue?) -> Result<T, Error> where T: Job {
    switch self.get(id, queue: queue) {
    case .success(let job):
      guard let job = job as? T else {
        return .failure(JobStorageError.jobTypeMismatch)
      }
      return .success(job)
    case .failure(let error):
      return .failure(error)
    }
  }

  public func get<T>(_ type: T.Type, _ id: JobID, queue: JobQueue?) -> Result<T, Error> where T : Job {
    self.get(id, queue: queue)
  }

  public func getAll(queue: JobQueue?) -> Result<[AnyJob], Error> {
    guard let queue = (queue ?? self.queue) else {
      return .failure(JobStorageError.noQueueProvided)
    }
    guard let jobs = self.data[queue.name] else {
      return .failure(JobStorageError.queueNotFound(queue.name))
    }
    return .success(jobs.values.map { $0 })
  }

  public func store(_ job: AnyJob, queue: JobQueue?) -> Result<AnyJob, Error> {
    guard let queue = (queue ?? self.queue) else {
      return .failure(JobStorageError.noQueueProvided)
    }
    var jobs = self.data[queue.name, default: [JobID: AnyJob]()]
    jobs[job.id] = job
    self.data[queue.name] = jobs
    self.changes.append(.stored(queue.name, job.id, job))
    return .success(job)
  }

  public func store<T>(_ job: T, queue: JobQueue?) -> Result<T, Error> where T: Job {
    guard let queue = (queue ?? self.queue) else {
      return .failure(JobStorageError.noQueueProvided)
    }
    var jobs = self.data[queue.name, default: [JobID: AnyJob]()]
    jobs[job.id] = job
    self.data[queue.name] = jobs
    self.changes.append(.stored(queue.name, job.id, job))
    return .success(job)
  }

  public func store<T>(_ type: T.Type, _ job: T, queue: JobQueue?) -> Result<T, Error> where T : Job {
    self.store(job, queue: queue)
  }

  public func remove(_ id: JobID, queue: JobQueue?) -> Result<JobID, Error> {
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

  public func remove(_ job: AnyJob, queue: JobQueue?) -> Result<AnyJob, Error> {
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

  public func remove<T>(_ job: T, queue: JobQueue?) -> Result<T, Error> where T: Job {
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

  public func remove<T>(_ type: T.Type, _ job: T, queue: JobQueue?) -> Result<T, Error> where T : Job {
    self.remove(job, queue: queue)
  }

  public func removeAll(queue: JobQueue?) -> Result<Void, Error> {
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

public class JobQueueInMemoryStorage: JobStorage {
  private var data = [JobQueueName: [JobID: AnyJob]]()
  private let scheduler: Scheduler

  public init(scheduler: Scheduler) {
    self.scheduler = scheduler
  }

  public func transaction<T>(queue: JobQueue, _ closure: @escaping (JobStorageTransaction) throws -> T) -> SignalProducer<T, Error> {
    return SignalProducer { o, lt in
      let transaction = JobQueueInMemoryStorageTransaction(queue: queue, data: self.data)
      do {
        let result = try closure(transaction)
        transaction.changes.forEach { change in
          switch change {
          case .stored(let queueName, let jobId, let job):
            var jobs = self.data[queueName, default: [JobID: AnyJob]()]
            jobs[jobId] = job
            self.data[queueName] = jobs
          case .removed(let queueName, let jobId, let job):
            guard var jobs = self.data[queueName] else {
              return
            }
            jobs[jobId] = job
            self.data[queueName] = jobs
          case .removedAll(let queueName):
            self.data.removeValue(forKey: queueName)
          }
        }
        o.send(value: result)
        o.sendCompleted()
      } catch {
        o.send(error: error)
      }
    }.start(on: self.scheduler)
  }
}
