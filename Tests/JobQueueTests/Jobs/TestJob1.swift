//
//  File.swift
//
//
//  Created by George Cox on 1/20/20.
//

import Foundation
import JobQueue

public struct TestJob1: Job {
  public var id: JobID
  public var rawPayload: [UInt8]?
  public var payload: String
  public var status: JobStatus
  public var schedule: JobSchedule?
  public var queuedAt: Date
  public var order: Float?
  public var progress: Float?

  public static func make(
    id: JobID,
    payload: String,
    status: JobStatus = .waiting,
    queuedAt: Date = Date(),
    order: Float? = nil
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
