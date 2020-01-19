//
//  File.swift
//  
//
//  Created by George Cox on 1/21/20.
//

import Foundation
import ReactiveSwift

public enum JobStorageError: Error {
  case noQueueProvided
  case queueNotFound(JobQueueName)
  case jobNotFound(JobQueueName, JobID)
  case jobTypeMismatch
}

public protocol JobStorage {
  func transaction<T>(queue: JobQueue, _ closure: @escaping (JobStorageTransaction) throws -> T) -> SignalProducer<T, Error>
}

public protocol JobStorageTransaction {
  func get(_ id: JobID, queue: JobQueue?) -> Result<AnyJob, Error>
  func get<T>(_ id: JobID, queue: JobQueue?) -> Result<T, Error> where T: Job
  func get<T>(_ type: T.Type, _ id: JobID, queue: JobQueue?) -> Result<T, Error> where T: Job
  func getAll(queue: JobQueue?) -> Result<[AnyJob], Error>

  func store(_ job: AnyJob, queue: JobQueue?) -> Result<AnyJob, Error>
  func store<T>(_ job: T, queue: JobQueue?) -> Result<T, Error> where T: Job
  func store<T>(_ type: T.Type, _ job: T, queue: JobQueue?) -> Result<T, Error> where T: Job

  func remove(_ id: JobID, queue: JobQueue?) -> Result<JobID, Error>
  func remove(_ job: AnyJob, queue: JobQueue?) -> Result<AnyJob, Error>
  func remove<T>(_ job: T, queue: JobQueue?) -> Result<T, Error> where T: Job
  func remove<T>(_ type: T.Type, _ job: T, queue: JobQueue?) -> Result<T, Error> where T: Job
  func removeAll(queue: JobQueue?) -> Result<Void, Error>
}

public extension JobStorageTransaction {
  func get(_ id: JobID) -> Result<AnyJob, Error> {
    self.get(id, queue: nil)
  }
  func get<T>(_ id: JobID) -> Result<T, Error> where T: Job {
    self.get(id, queue: nil)
  }
  func get<T>(_ type: T.Type, _ id: JobID) -> Result<T, Error> where T: Job {
    self.get(type, id, queue: nil)
  }
  func getAll() -> Result<[AnyJob], Error> {
    self.getAll(queue: nil)
  }
  func store(_ job: AnyJob) -> Result<AnyJob, Error> {
    self.store(job, queue: nil)
  }
  func store<T>(_ job: T) -> Result<T, Error> where T: Job {
    self.store(job, queue: nil)
  }
  func store<T>(_ type: T.Type, _ job: T) -> Result<T, Error> where T: Job {
    self.store(type, job, queue: nil)
  }

  func remove(_ id: JobID) -> Result<JobID, Error> {
    self.remove(id, queue: nil)
  }
  func remove(_ job: AnyJob) -> Result<AnyJob, Error> {
    self.remove(job, queue: nil)
  }
  func remove<T>(_ job: T) -> Result<T, Error> where T: Job {
    self.remove(job, queue: nil)
  }
  func remove<T>(_ type: T.Type, _ job: T) -> Result<T, Error> where T: Job {
    self.remove(type, job, queue: nil)
  }
  func removeAll() -> Result<Void, Error> {
    self.removeAll(queue: nil)
  }
}
