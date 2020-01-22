///
///  Created by George Cox on 1/22/20.
///

import Foundation
import ReactiveSwift

public enum JobQueueError: Error {
  case jobNotFound(JobID)
}

public enum JobQueueEvent {
  case resumed
  case suspended
  case added(AnyJob)
  case updated(AnyJob)
  case removed(AnyJob)
  case registeredProcessor(JobName, concurrency: Int)
  case updatedStatus(AnyJob)
  case updatedProgress(AnyJob)
  case beganProcessing(AnyJob)
  case cancelledProcessing(AnyJob?, JobCancellationReason)
  case failedProcessing(AnyJob, Error)
  case finishedProcessing(AnyJob)
}

public final class JobQueue {
  public let name: String

  private let _isActive = MutableProperty(false)
  /// When `true`, the queue is active and can process jobs.
  /// When `false`, the queue is suspended, will not synchronize, and will not process jobs
  public let isActive: Property<Bool>

  private let _isSynchronizing = MutableProperty(false)
  private let isSynchronizing: Property<Bool>

  private let _events = Signal<JobQueueEvent, Never>.pipe()
  /// An observable stream of events produced by the queue
  public let events: Signal<JobQueueEvent, Never>

  private let shouldSynchronize = Signal<Void, Never>.pipe()
  internal let schedulers: JobQueueSchedulers
  private let storage: JobStorage
  private let processors = JobQueueProcessors()
  private let sorter: JobSorter
  private let delayStrategy: JobQueueDelayStrategy
  private let logger: LoggerProtocol

  public init(
    name: String,
    schedulers: JobQueueSchedulers,
    storage: JobStorage,
    sorter: JobSorter = DefaultJobSorter(),
    delayStrategy: JobQueueDelayStrategy = JobQueueDelayPollingStrategy(),
    logger: Logger = ConsoleLogger()
  ) {
    self.name = name
    self.schedulers = schedulers
    self.storage = storage
    self.sorter = sorter
    self.delayStrategy = delayStrategy
    self.isActive = Property(capturing: self._isActive)
    self.isSynchronizing = Property(capturing: self._isSynchronizing)
    self.events = self._events.output
    self.logger = logger

    /**
     Monitor `shouldSynchronize`, throttling for noise, while the queue is suspended,
     and while the queue is synchronizing.

     Once those conditions are met, the `isSynchronizing` property is set to `true`,
     the queue's jobs are fetched, the queue is synchronized using those jobs, and
     the `isSynchronizing` property is then set back to `false`.
     */
    self.shouldSynchronize.output.producer
      .throttle(
        0.1,
        on: self.schedulers.shouldSynchronize
      )
      .throttle(
        while: self.isActive.map { !$0 },
        on: self.schedulers.shouldSynchronize
      )
      .throttle(
        while: self.isSynchronizing.map { $0 },
        on: self.schedulers.shouldSynchronize
      )
      .on(value: { _ in
        self._isSynchronizing.swap(true)
      })
      .flatMap(.concat) { _ in
        self.getAll()
      }
      .flatMap(.concat) {
        self.synchronize(jobs: $0).on(completed: {
          self._isSynchronizing.value = false
        })
      }
      .start()

    logger.info("Initialized")
  }
}

/// `isActive` mutation functions
public extension JobQueue {
  /**
   Resumes the queue.

   This will set the `isActive` property to `true`. This will eventually trigger synchronization.

   - Returns: A `SignalProducer<Bool, Error>`
   The producer echoes the resulting `isActive` value or, if something went wrong,
   an `Error`.
   */
  func resume() -> SignalProducer<Bool, Error> {
    self.change(active: true)
      .on(value: {
        guard $0 else {
          return
        }
        self._events.input.send(value: .resumed)
      })
  }

  /**
   Suspends the queue.

   This will set the `isActive` property to `false` and, as soon as possible, any
   processing jobs will be cancelled with a `JobCancellationReason` of `queueSuspended`.

   - Note: Synchronization does not run while the queue is suspended.

   - Returns: A `SignalProducer<Bool, Error>`
   The producer echoes the resulting `isActive` value or, if something went wrong,
   an `Error`.
   */
  func suspend() -> SignalProducer<Bool, Error> {
    self.change(active: false)
      .on(value: {
        guard !$0 else {
          return
        }
        self._events.input.send(value: .suspended)
      })
  }

  private func change(active: Bool) -> SignalProducer<Bool, Error> {
    return SignalProducer { o, lt in
      self._isActive.swap(active)
      o.send(value: self.isActive.value)
      o.sendCompleted()
    }
  }
}

// Job access
public extension JobQueue {
  private func transaction<T>(_ closure: @escaping (JobStorageTransaction) throws -> T) -> SignalProducer<T, Error> {
    return self.storage.transaction(queue: self, closure)
  }

  func set(_ id: JobID, status: JobStatus) -> SignalProducer<AnyJob, Error> {
    return self.transaction {
      var job = (try $0.get(id).get())
      guard !job.status.isActive else {
        return job
      }
      job.status = status
      return try $0.store(job).get()
    }.on(completed: {
      self.scheduleSynchronization()
    })
  }

  func set(_ job: AnyJob, status: JobStatus) -> SignalProducer<AnyJob, Error> {
    guard job.status != status else {
      return SignalProducer(value: job)
    }
    return self.set(job.id, status: status)
  }

  /**
   Fetch one job of type `AnyJob`

   - Parameter id: the id of the job to get
   - Returns: A `SignalProducer<AnyJob, Error>` that sends the job or, if not found, an error
   */
  func get(_ id: JobID) -> SignalProducer<AnyJob, Error> {
    self.transaction { try $0.get(id).get() }
  }

  /**
   Fetch one job of type `T`

   - Parameter id: the id of the job to get
   - Returns: A `SignalProducer<AnyJob, Error>` that sends the job or, if not found, an error
   */
  func get<T>(_ id: JobID) -> SignalProducer<T, Error> where T: Job {
    self.transaction { try ($0.get(id)).get() }
  }

  /**
   Get all jobs in the queue

   - Returns: A `SignalProducer<[AnyJob], Error>` that sends the jobs in the queue or
   any error from the underlying storage provider
   */
  func getAll() -> SignalProducer<[AnyJob], Error> {
    self.transaction { try $0.getAll().get() }
  }

  /**
   Stores one job, of type `AnyJob`

   If the job is stored successfully. This will eventually trigger synchronization.

   - Parameter job: the job to store
   - Returns: A `SignalProducer<AnyJob, Error>` that echoes the job or any error
   from the underlying storage provider
   */
  func store(_ job: AnyJob, synchronize: Bool = true) -> SignalProducer<AnyJob, Error> {
    self.transaction { try $0.store(job).get() }
      .on(completed: {
        if synchronize {
          self.scheduleSynchronization()
        }
      })
  }

  /**
   Stores one job, of type `T`

   If the job is stored successfully. This will eventually trigger synchronization.

   - Parameter job: the job to store
   - Returns: A `SignalProducer<T, Error>` that echoes the job or any error
   from the underlying storage provider
   */
  func store<T>(_ job: T, synchronize: Bool = true) -> SignalProducer<T, Error> where T: Job {
    self.transaction { try $0.store(job).get() }
      .on(completed: {
        if synchronize {
          self.scheduleSynchronization()
        }
      })
  }

  /**
   Remove one job by id

   Removes a job from persistance. If processing, the job will be cancelled with
   a `JobCancellationReason` of `removed`.

   - Parameter id: the id of the job to remove
   - Returns: A `SignalProducer<JobID, Error>` that sends the id or any error
     from the underlying storage provider
   */
  func remove(_ id: JobID, synchronize: Bool = true) -> SignalProducer<JobID, Error> {
    self.transaction { try $0.remove(id).get() }
      .on(completed: {
        if synchronize {
          self.scheduleSynchronization()
        }
      })
  }

  /**
   Remove one job

   Removes a job from persistance. If processing, the job will be cancelled with
   a `JobCancellationReason` of `removed`.

   - Note: Although the `SignalProducer` will send the job if it is removed successfully,
   the job will no longer be persisted and the job should be used with that in mind.

   - Parameter job: the job to remove
   - Returns: A `SignalProducer<AnyJob, Error>` that sends the job or any error
   from the underlying storage provider
   */
  func remove(_ job: AnyJob, synchronize: Bool = true) -> SignalProducer<AnyJob, Error> {
    self.transaction { try $0.remove(job).get() }
      .on(completed: {
        if synchronize {
          self.scheduleSynchronization()
        }
      })
  }
}

public extension JobQueue {
  /**
   Registers a `JobProcessor` type with the queue

   Each `JobProcessor` processes a specific type of `Job`, `JobProcessor.JobType`.

   Each `JobProcessor` instance processes one job at a time.

   There can be up to `concurrency` instances of the registered `JobProcessor`,
   which means up to `concurrency` `JobProcessor.JobType` jobs can be processed
   concurrently.

   - Parameters:
     - type: the `JobProcessor`'s type
     - concurrency: the maximum number of instances of this `JobProcessor` that can
     simultaneously process jobs. defaults to `1`.
   */
  func register<T>(_ type: T.Type, concurrency: Int = 1) where T: JobProcessor {
    self.processors.configurations[T.JobType.name] =
      JobProcessorConfiguration(type, concurrency: concurrency)

    self._events.input.send(value: .registeredProcessor(T.JobType.name, concurrency: concurrency))
  }
}

private extension JobQueue {
  func scheduleSynchronization() {
    self.shouldSynchronize.input.send(value: ())
  }

  func configureDelayTimer(for jobs: [AnyJob]) {}

  /**
   Synchronize the queue

   This inspects the queue's jobs, determines which jobs should be active, and applies
   the necessary mutations to make that happen.

   This happens on the `schedulers.synchronize` `Scheduler`.

   - Parameter jobs: all jobs in the queue
   */
  func synchronize(jobs: [AnyJob]) -> SignalProducer<Void, Error> {
    return SignalProducer { o, lt in
      let sortedJobs = self.sorter.sort(jobs: jobs)
      let jobsToProcessByName = self.processable(jobs: sortedJobs)
      let jobIDsToProcess = jobsToProcessByName.jobIDs
      let processorsToCancelByID = self.processors.activeProcessorsByID(excluding: jobIDsToProcess)

      self.delayStrategy.update(queue: self, jobs: sortedJobs.delayedJobs)

      // Apply cancellations
      processorsToCancelByID.forEach { kvp in
        guard let job = sortedJobs.first(where: { $0.id == kvp.key }) else {
          kvp.value.cancel(reason: .removed)
          self._events.input.send(value: .cancelledProcessing(nil, .removed))
          return
        }
        kvp.value.cancel(reason: .statusChangedToWaiting)
        self._events.input.send(value: .cancelledProcessing(job, .statusChangedToWaiting))
      }

      // Cleanup processors
      self.processors.remove(processors: processorsToCancelByID.keys.map { $0 })

      // Process jobs to process
      lt += SignalProducer(
        jobsToProcessByName.reduce(into: [AnyJob]()) { acc, kvp in
          acc.append(contentsOf: kvp.value)
        }
      ).flatMap(.concat) {
        self.beginProcessing(job: $0)
      }.startWithCompleted {
        o.send(value: ())
        o.sendCompleted()
      }
    }
    .start(on: self.schedulers.synchronize)
  }

  /**
   Reduces a list of jobs down to only the jobs that should be currently processing
   in the form of a map from job name to jobs.

   - Parameter jobs: the list of jobs to reduce
   */
  func processable(jobs: [AnyJob]) -> [JobName: [AnyJob]] {
    return jobs.reduce(into: [JobName: [AnyJob]]()) { acc, job in
      guard let configuration = self.processors.configurations[job.name] else {
        return
      }
      guard configuration.concurrency > 0 else {
        return
      }
      switch job.status {
      case .completed, .paused, .failed, .delayed:
        return
      default:
        break
      }
      var nextJobs = acc[job.name, default: [AnyJob]()]
      guard nextJobs.count < configuration.concurrency else {
        return
      }
      acc[job.name] = {
        nextJobs.append(job)
        return nextJobs
      }()
    }
  }

  /**
   Starts processing a job

   Triggers a `.beganProcessing` event immediately, then either a `.finishedProcessing`
   or `.failedProcessing` event when the job completes.

   - Parameter job: the job to process
   */
  func beginProcessing(job: AnyJob) -> SignalProducer<AnyJob, Error> {
    return self.set(job, status: .active)
      .on(
        value: { _job in
          guard let processor = self.processors.activeProcessor(for: _job) else {
            return
          }
          processor.process(job: _job, queue: self) { result in
            self.schedulers.synchronize.schedule {
              switch result {
              case .success:
                self.set(_job.id, status: .completed(at: Date()))
                  .on(value: {
                    self.processors.remove(processors: [$0.id])
                    self._events.input.send(value: .finishedProcessing($0))
                })
                  .start()
              case .failure(let error):
                self.set(_job.id, status: .failed(at: Date(), message: error.localizedDescription))
                  .on(
                    value: {
                      self.processors.remove(processors: [$0.id])
                      self._events.input.send(value: .failedProcessing($0, error))
                    }
                  )
                  .start()
              }
              self._events.input.send(value: .beganProcessing(job))
            }
          }
        }
      )
  }
}
