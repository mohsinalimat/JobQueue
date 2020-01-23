///
///  Created by George Cox on 1/22/20.
///

import Foundation

public protocol StaticallyNamed {
  static var name: String { get }
  var name: String { get }
}
public extension StaticallyNamed {
  static var name: String { String(describing: self) }
  var name: String { Self.name }
}

public typealias JobID = String
public typealias JobName = String
public typealias JobQueueName = String

func notImplemented(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
  let message = message()
  fatalError(message != String() ? message : "Not implemented", file: file, line: line)
}

func abstract(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
  let message = message()
  fatalError(message != String() ? message : "Function is abstract", file: file, line: line)
}
