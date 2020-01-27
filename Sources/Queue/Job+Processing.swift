///
///  Created by George Cox on 1/27/20.
///

import Foundation
import ReactiveSwift

#if SWIFT_PACKAGE
import JobQueueCore
#endif

extension Job {
  public func process(details: JobDetails, queue: JobQueueProtocol, done: @escaping JobCompletion) {
    do {
      let payload = try Self.deserialize(details.payload)
      self.process(details: details, payload: payload, queue: queue, done: done)
    } catch {
      done(.failure(JobProcessorError.invalidJobType))
    }
  }
}

extension Job {
  public static var typeName: JobName { String(describing: Self.self) }
}

open class DefaultJob<T>: Job, Equatable where T: Codable {
  public typealias Payload = T

  private let _cancelled = MutableProperty<JobCancellationReason?>(nil)
  public private(set) lazy var cancelled = Property(capturing: _cancelled)

  public required init() {}

  /**
   Starts processing a job

   This is an **abstract** implementation meant to be overridden by sub-classes.
   Sub-classes should not invoke it using `super`.

   - Parameters:
     - job: the job to process
     - queue: the queue the job belongs to
     - done: the completion callback.
   */
  open func process(details: JobDetails, payload: Payload, queue: JobQueueProtocol, done: @escaping JobCompletion) {
    done(.failure(JobProcessorError.abstractFunction))
  }

  /**
   Cancel processing the job

   This implementation updates the backing property for the `cancelled` property
   so the `process` implementation can observe the change and cancel the job cleanly.

   - Parameter reason: the reason the job is being cancelled
   */
  public func cancel(reason: JobCancellationReason) {
    self._cancelled.swap(reason)
  }

  public static func == (lhs: DefaultJob<T>, rhs: DefaultJob<T>) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
}
