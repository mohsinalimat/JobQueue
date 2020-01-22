///
///  Created by George Cox on 1/22/20.
///

import Foundation
import ReactiveSwift

public enum JobProcessorError: Swift.Error {
  case invalidJobType
  case abstractFunction
}

public typealias JobCompletion = (Result<Void, Error>) -> Void

public protocol AnyJobProcessor {
  /**
   Cancel processing of a job

   - Parameter reason: the reason processing is being cancelled
   */
  func cancel(reason: JobCancellationReason)

  /**
   Process a job

   - Parameters:
     - job: the job to process
     - queue: the queue the job belongs to
     - done: a completion callback accepting a `Result<Void, Error>` argument
   */
  func process(job: AnyJob, queue: JobQueue, done: @escaping JobCompletion)
}

public protocol JobProcessor: class, AnyJobProcessor, Equatable {
  associatedtype JobType: Job

  init()

  /**
   Process a job

   - Parameters:
     - job: the job to process
     - queue: the queue the job belongs to
     - done: a completion callback accepting a `Result<Void, Error>` argument
   */
  func process(job: JobType, queue: JobQueue, done: @escaping JobCompletion)
}

extension JobProcessor {
  public func process(job: AnyJob, queue: JobQueue, done: @escaping JobCompletion) {
    guard let job = job as? JobType else {
      done(.failure(JobProcessorError.invalidJobType))
      return
    }
    self.process(job: job, queue: queue, done: done)
  }
}

/**
 # DefaultJobProcessor

 A default job processor that provides a `cancelled` property that the processor
 can observe while processing a job in order to properly cancel the job.
 */
open class DefaultJobProcessor<T>: JobProcessor where T: Job {
  public typealias JobType = T

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
  open func process(job: T, queue: JobQueue, done: @escaping JobCompletion) {
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
}

extension JobProcessor {
  public static func == (lhs: Self, rhs: Self) -> Bool {
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
  }
}
