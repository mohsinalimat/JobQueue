///
///  Created by George Cox on 1/22/20.
///

import Foundation

func abstract(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
  let message = message()
  fatalError(message != String() ? message : "Function is abstract", file: file, line: line)
}

/**
 # Logger

 An abstract logging class meant to be sub-classed before use

 The `JobQueue` and it's related source may invoke any of this class's functions,
 so sub-classes should override them all.

 If you're using a logging module, like `swift-log`/`CocoaLumberjack`/`XLFacility`,
 create a sub-class of `Logger` that invokes the equivalent logging function in
 that module.

 A `ConsoleLogger` has been provided
 */
open class Logger {
  open func trace(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    abstract()
  }

  open func info(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    abstract()
  }

  open func notice(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    abstract()
  }

  open func warning(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    abstract()
  }

  open func error(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    abstract()
  }

  open func fatal(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    abstract()
  }
}

/// ConsoleLogger
///
/// A Logger subclass that logs to the console via `print`.
/// Only use this sub-class when you have no other logging solution in place.
public final class ConsoleLogger: Logger {
  public override init() {}

  private func format(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, level: String, _ message: String, _ meta: Any...) -> String {
    let timestamp = Date().iso8601
    let filename = NSString(string: String(describing: file)).lastPathComponent
    return "\(timestamp) • \(level) • \(filename):\(line) • \(message)"
  }

  public override func trace(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, function: function, level: "TRACE", message, meta))
  }

  public override func info(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, function: function, level: "INFO", message, meta))
  }

  public override func notice(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, function: function, level: "NOTICE", message, meta))
  }

  public override func warning(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, function: function, level: "WARN", message, meta))
  }

  public override func error(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, function: function, level: "ERROR", message, meta))
  }

  public override func fatal(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, function: function, level: "FATAL", message, meta))
  }
}
