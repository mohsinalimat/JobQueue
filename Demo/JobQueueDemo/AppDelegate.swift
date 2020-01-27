///
///  Created by George Cox on 1/24/20.
///

import JobQueue
import UIKit
import ReactiveSwift
import NanoID

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
  let schedulers = JobQueueSchedulers()

  var inMemoryQueue: JobQueue?
  var coreDataQueeu: JobQueue?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    // Override point for customization after application launch.
    self.demoInMemoryQueue()
    self.demoCoreDataQueue()
    return true
  }

  func demoInMemoryQueue() {
    self.inMemoryQueue = JobQueue(
      name: "InMemoryQueue",
      schedulers: schedulers,
      storage: JobQueueInMemoryStorage(scheduler: schedulers.storage)
    )
    guard let queue = self.inMemoryQueue else {
      return
    }
    self.demo(queue: queue)
  }

  func demoCoreDataQueue() {
    self.inMemoryQueue = JobQueue(
      name: "CoreDataQueue",
      schedulers: schedulers,
      storage: JobQueueInMemoryStorage(scheduler: schedulers.storage)
    )
    guard let queue = self.inMemoryQueue else {
      return
    }
    self.demo(queue: queue)
  }

  func demo(queue: JobQueue) {
    let id = ID(size: 10)

    queue.register(TestJob.self, concurrency: 3)
    queue.resume().start()

    // Add 10 jobs
    let jobs = (0..<10).map { idx -> JobDetails in
      let jobId = id.generate()
      return try! JobDetails(
        TestJob.self,
        id: jobId,
        queueName: queue.name,
        payload: "Job #\(idx), ID: \(jobId)"
      )
    }
    SignalProducer(jobs)
      .flatMap(.merge) { queue.store($0) }
      .startWithCompleted {
        print("Finished storing jobs in queue: \(queue.name)")
      }
  }

  // MARK: UISceneSession Lifecycle

  func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
  }

  func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
  }
}

class TestJob: DefaultJob<String> {
  override func process(details: JobDetails, payload: Payload, queue: JobQueueProtocol, done: @escaping JobCompletion) {
    QueueScheduler().schedule(after: Date().addingTimeInterval(5)) {
      done(.success(()))
    }
  }
}
