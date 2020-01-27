///
///  Created by George Cox on 1/22/20.
///

import Foundation
import ReactiveSwift

public enum JobStorageError: Error {
  case noQueueProvided
  case queueNotFound(JobQueueName)
  case jobNotFound(JobQueueName, JobID)
  case jobTypeMismatch
  case jobDeserializationFailed
  case jobSerializationFailed
}

public protocol JobStorage {
  func transaction<T>(queue: JobQueueProtocol, _ closure: @escaping (JobStorageTransaction) throws -> T) -> SignalProducer<T, Error>
}
