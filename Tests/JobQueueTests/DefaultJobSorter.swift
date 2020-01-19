//
//  File.swift
//
//
//  Created by George Cox on 1/21/20.
//

import Foundation
import Nimble
import Quick

@testable import JobQueue

class DefaultJobSorterTests: QuickSpec {
  override func spec() {
    describe("sort") {
      it("should sort by order, then queued at") {
        let jobs: [AnyJob] = [
          try! TestJob1.make(id: "1", payload: "test", queuedAt: Date(timeIntervalSince1970: 200)),
          try! TestJob1.make(id: "0", payload: "test", queuedAt: Date(timeIntervalSince1970: 100)),
          try! TestJob1.make(id: "2", payload: "test", queuedAt: Date(timeIntervalSince1970: 75), order: 1.25),
          try! TestJob1.make(id: "4", payload: "test", queuedAt: Date(timeIntervalSince1970: 50), order: 1.25),
          try! TestJob1.make(id: "3", payload: "test", queuedAt: Date(timeIntervalSince1970: 25), order: 1.0)
        ]
        let sorted = DefaultJobSorter().sort(jobs: jobs)
        expect(sorted.map { $0.id }).to(equal(["3", "4", "2", "0", "1"]))
      }
    }
  }
}
