///
///  Created by George Cox on 1/22/20.
///

import Foundation
import JobQueueCore
import JobQueue

struct TestJob1: Job {
  var id: JobID
  var rawPayload: [UInt8]
  var payload: String
  var status: JobStatus
  var schedule: JobSchedule?
  var queuedAt: Date
  var order: Float?
  var progress: Float?
}

extension TestJob1 {
  static func make(
    id: JobID,
    payload: Payload,
    queuedAt: Date = Date(),
    status: JobStatus = .waiting,
    order: Float? = nil
  ) throws -> Self {
    TestJob1(id: id,
             rawPayload: try Self.serialize(payload),
             payload: payload,
             status: status,
             queuedAt: queuedAt,
             order: order)
  }
}

