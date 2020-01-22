//
//  File.swift
//
//
//  Created by George Cox on 1/20/20.
//

import Foundation

public protocol AnyJob: StaticallyNamed {
  /// Unique identifier of the job
  var id: JobID { get }

  /// Raw payload bytes
  var rawPayload: [UInt8]? { get }

  /// The job's status
  var status: JobStatus { get set }

  /// The job's schedule, only for scheduled jobs
  var schedule: JobSchedule? { get set }

  /// The date the job was added to the queue
  var queuedAt: Date { get set }

  /// The specific order of the job in the queue. Sort order of jobs is by
  /// `order`, if not nil, then `queuedAt`
  var order: Float? { get set }

  /// Optional progress of the job
  var progress: Float? { get set }

  /// If a Job's `status` is delayed, it will have an associated date, which
  /// is returned by this property. The job won't be processed until after this
  /// date.
  var delayedUntil: Date? { get }

  /// The date the job completed successfully
  var completedAt: Date? { get }

  /// The date the job *last* failed
  var failedAt: Date? { get }

  /// The *last* error message for a failed job
  var failedMessage: String? { get }
}

public protocol Job: AnyJob {
  associatedtype Payload: Codable

  /// The deserialized payload
  var payload: Payload { get }

  /// Converts the `Payload` to bytes. This is what's stored in the `rawPayload`
  /// property.
  ///
  /// - Parameter payload: the payload
  static func serialize(_ payload: Payload) throws -> [UInt8]

  /// Converts the raw payload bytes to `Payload`.
  ///
  /// - Parameter rawPayload: the raw payload bytes
  static func deserialize(_ rawPayload: [UInt8]) throws -> Payload
}

extension Job {
  /// Default implementation that uses the JSONEncoder
  ///
  /// - Parameter payload: the payload
  public static func serialize(_ payload: Payload) throws -> [UInt8] {
    return try .init(JSONEncoder().encode([payload]))
  }

  /// Default implementation that uses the JSONDecoder
  ///
  /// - Parameter rawPayload: the raw payload bytes
  public static func deserialize(_ rawPayload: [UInt8]) throws -> Payload {
    return try JSONDecoder().decode([Payload].self, from: .init(rawPayload)).first!
  }
}

extension AnyJob {
  public var delayedUntil: Date? { status.delayedUntil }
  public var completedAt: Date? { status.completedAt }
  public var failedAt: Date? { status.failedAt }
  public var failedMessage: String? { status.failedMessage }
}
