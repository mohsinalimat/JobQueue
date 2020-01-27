///
///  Created by George Cox on 1/27/20.
///

import Foundation
import ReactiveSwift

public protocol JobStorageTransaction {
  func get(_ id: JobID, queue: JobQueueProtocol?) -> Result<JobDetails, Error>
  func getAll(queue: JobQueueProtocol?) -> Result<[JobDetails], Error>

  func store(_ details: JobDetails, queue: JobQueueProtocol?) -> Result<JobDetails, Error>

  func remove(_ id: JobID, queue: JobQueueProtocol?) -> Result<JobID, Error>
  func remove(_ details: JobDetails, queue: JobQueueProtocol?) -> Result<JobDetails, Error>
  func removeAll(queue: JobQueueProtocol?) -> Result<Void, Error>
}

public extension JobStorageTransaction {
  func get(_ id: JobID) -> Result<JobDetails, Error> {
    self.get(id, queue: nil)
  }
  func getAll() -> Result<[JobDetails], Error> {
    self.getAll(queue: nil)
  }
  func store(_ job: JobDetails) -> Result<JobDetails, Error> {
    self.store(job, queue: nil)
  }

  func remove(_ id: JobID) -> Result<JobID, Error> {
    self.remove(id, queue: nil)
  }
  func remove(_ job: JobDetails) -> Result<JobDetails, Error> {
    self.remove(job, queue: nil)
  }

  func removeAll() -> Result<Void, Error> {
    self.removeAll(queue: nil)
  }
}
