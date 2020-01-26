///
///  Created by George Cox on 1/22/20.
///

import Foundation
import JobQueueCore
import JobQueue

struct TestPayload1: Codable, Equatable {
  var name: String
}
struct TestJob2: Job {
  var id: JobID
  var rawPayload: [UInt8]
  var payload: TestPayload1
  var status: JobStatus
  var schedule: JobSchedule?
  var queuedAt: Date
  var order: Float?
  var progress: Float?
}
