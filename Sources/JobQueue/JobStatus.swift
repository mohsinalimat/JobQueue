///
///  Created by George Cox on 1/22/20.
///

import Foundation

public enum JobStatus: Equatable {
  case waiting
  case active
  case completed(at: Date)
  case delayed(until: Date)
  case failed(at: Date, message: String)
  case paused

  public var isActive: Bool {
    switch self {
    case .active:
      return true
    default:
      return false
    }
  }

  public var completedAt: Date? {
    switch self {
    case .completed(let date):
      return date
    default: return nil
    }
  }
  public var isComplete: Bool {
    switch self {
    case .completed:
      return true
    default:
      return false
    }
  }

  public var failedAt: Date? {
    switch self {
    case .failed(let date, _):
      return date
    default: return nil
    }
  }
  public var failedMessage: String? {
    switch self {
    case .failed(_, let message):
      return message
    default: return nil
    }
  }
  public var isFailed: Bool {
    switch self {
    case .failed:
      return true
    default:
      return false
    }
  }

  public var delayedUntil: Date? {
    switch self {
    case .delayed(let date):
      return date
    default: return nil
    }
  }
  public var isDelayed: Bool {
    switch self {
    case .delayed:
      return true
    default:
      return false
    }
  }
}
