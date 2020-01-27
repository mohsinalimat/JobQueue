///
///  Created by George Cox on 1/22/20.
///

import Foundation

public typealias JobID = String
public typealias JobName = String
public typealias JobQueueName = String

public func notImplemented(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
  let message = message()
  fatalError(message != String() ? message : "Not implemented", file: file, line: line)
}

public func abstract(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
  let message = message()
  fatalError(message != String() ? message : "Function is abstract", file: file, line: line)
}

public typealias JobCompletion = (Result<Void, Error>) -> Void
public enum JobCancellationReason {
  case statusChangedToWaiting
  case statusChangedToDelayed
  case removed
  case statusChangedToPaused
  case queueSuspended
}
