///
///  Created by George Cox on 1/22/20.
///

import Foundation
import JobQueue

public struct TestPayload1: Codable, Equatable {
  public var name: String
}
public struct TestJob2: Job {
  public var id: JobID
  public var rawPayload: [UInt8]?
  public var payload: TestPayload1
  public var status: JobStatus
  public var schedule: JobSchedule?
  public var queuedAt: Date
  public var order: Float?
  public var progress: Float?

  public static func make(
    id: JobID,
    payload: TestPayload1,
    queuedAt: Date = Date(),
    order: Float? = nil,
    status: JobStatus = .waiting
  ) throws -> Self {
    Self(id: id,
         rawPayload: try Self.serialize(payload),
         payload: payload,
         status: status,
         schedule: nil,
         queuedAt: queuedAt,
         order: order,
         progress: nil)
  }
}
