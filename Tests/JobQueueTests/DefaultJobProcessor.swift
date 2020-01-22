///
///  Created by George Cox on 1/22/20.
///

import Foundation
import Nimble
import Quick
import ReactiveSwift

@testable import JobQueue

class DefaultJobProcessorTests: QuickSpec {
  override func spec() {
    describe("cancelling") {
      context("when cancelled") {
        var processor: DefaultJobProcessor<TestJob1>!

        beforeEach {
          processor = DefaultJobProcessor()
        }

        it("should send the cancel reason") {
          waitUntil { done in
            processor.cancelled.producer.startWithValues { reason in
              guard let reason = reason else {
                return
              }
              switch reason {
              case .statusChangedToWaiting:
                done()
              default:
                fail("Did not send the expected cancellation reason")
              }
            }
            processor.cancel(reason: .statusChangedToWaiting)
          }
        }
      }
    }

    describe("processing") {
      context("an `AnyJob`") {
        context("that doesn't match the processor's JobType") {
          var queue: JobQueue!
          var schedulers: JobQueueSchedulers!
          var storage: JobStorage!
          var processor: DefaultJobProcessor<TestJob2>!

          beforeEach {
            schedulers = JobQueueSchedulers()
            storage = TestJobStorage(scheduler: schedulers.storage)

            queue = JobQueue(name: "test",
                             schedulers: schedulers,
                             storage: storage)
            processor = DefaultJobProcessor()
          }

          it("should send an error because the default job processor is abstract") {
            processor.process(job: (try! TestJob1.make(id: "0", payload: "test")) as AnyJob,
                              queue: queue) { result in
              switch result {
              case .success:
                fail("should have failed")
              case .failure(let error):
                guard let e = error as? JobProcessorError else {
                  fail("unexpected error type: \(error)")
                  return
                }
                expect(e).to(equal(.invalidJobType))
              }
            }
          }
        }
        context("that matches the processor's JobType") {
          var queue: JobQueue!
          var schedulers: JobQueueSchedulers!
          var storage: JobStorage!
          var processor: DefaultJobProcessor<TestJob1>!

          beforeEach {
            schedulers = JobQueueSchedulers()
            storage = TestJobStorage(scheduler: schedulers.storage)

            queue = JobQueue(name: "test",
                             schedulers: schedulers,
                             storage: storage)
            processor = DefaultJobProcessor()
          }

          it("should send an error because the default job processor is abstract") {
            processor.process(job: (try! TestJob1.make(id: "0", payload: "test")) as AnyJob,
                              queue: queue) { result in
              switch result {
              case .success:
                fail("should have failed")
              case .failure(let error):
                guard let e = error as? JobProcessorError else {
                  fail("unexpected error type: \(error)")
                  return
                }
                expect(e).to(equal(.abstractFunction))
              }
            }
          }
        }
      }

      context("a typed job") {
        var queue: JobQueue!
        var schedulers: JobQueueSchedulers!
        var storage: JobStorage!
        var processor: DefaultJobProcessor<TestJob1>!

        beforeEach {
          schedulers = JobQueueSchedulers()
          storage = TestJobStorage(scheduler: schedulers.storage)

          queue = JobQueue(name: "test",
                           schedulers: schedulers,
                           storage: storage)
          processor = DefaultJobProcessor()
        }

        it("should send an error because the default job processor is abstract") {
          processor.process(job: try! TestJob1.make(id: "0", payload: "test"),
                            queue: queue) { result in
            switch result {
            case .success:
              fail("should have failed")
            case .failure(let error):
              guard let e = error as? JobProcessorError else {
                fail("unexpected error type: \(error)")
                return
              }
              expect(e).to(equal(.abstractFunction))
            }
          }
        }
      }
    }
  }
}
