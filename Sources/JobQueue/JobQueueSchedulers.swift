///
///  Created by George Cox on 1/22/20.
///

import Foundation
import ReactiveSwift

public struct JobQueueSchedulers {
  let synchronize: Scheduler
  let shouldSynchronize: DateScheduler
  let storage: Scheduler
  let delay: DateScheduler

  /**
   Initializes a `JobQueueSchedulers` instance.

    - Parameter synchronize: A `Scheduler` used to schedule the queue's synchronization
    procedure.
    - Parameter shouldSynchronize: A `Scheduler` used to monitor the queue's internal
    state to determine when synchronization should occur.
    - Parameter storage: A `Scheduler` used by the queue's `JobStorage` implementation
    to schedule access to the underlying storage mechanism.
   */
  public init(
    synchronize: Scheduler = QueueScheduler(
      qos: .background,
      name: "JobQueue.synchronize",
      targeting: DispatchQueue(label: "JobQueue.synchronize")),
    shouldSynchronize: DateScheduler = QueueScheduler(
      qos: .background,
      name: "JobQueue.shouldSynchronize",
      targeting: DispatchQueue(label: "JobQueue.shouldSynchronize")),
    storage: Scheduler = QueueScheduler(
      qos: .background,
      name: "JobQueue.storage",
      targeting: DispatchQueue(label: "JobQueue.storage")),
    delay: DateScheduler = QueueScheduler(
      qos: .background,
      name: "JobQueue.delay",
      targeting: DispatchQueue(label: "JobQueue.delay"))
    ) {
    self.synchronize = synchronize
    self.shouldSynchronize = shouldSynchronize
    self.storage = storage
    self.delay = delay
  }
}
