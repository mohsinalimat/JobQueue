///
///  Created by George Cox on 1/22/20.
///

import Foundation

private func abstract(_ message: @autoclosure () -> String = String(), file: StaticString = #file, line: UInt = #line) -> Never {
  let message = message()
  fatalError(message != String() ? message : "Function is abstract", file: file, line: line)
}

/// Abstract Logger
///
/// Sub-classes should override all of it's functions and not call them via super
open class Logger {
  open func trace(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    abstract()
  }

  open func info(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    abstract()
  }

  open func notice(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    abstract()
  }

  open func warning(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    abstract()
  }

  open func error(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    abstract()
  }

  open func fatal(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    abstract()
  }
}

/// ConsoleLogger
///
/// A Logger subclass that logs to the console via `print``
public final class ConsoleLogger: Logger {
  static let timestampFormatter: DateFormatter = {
    var formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.sss"
    return formatter
  }()

  public override init() {}

  private func format(file: StaticString = #file, line: UInt = #line, level: String, _ message: String, _ meta: Any...) -> String {
    let timestamp = ConsoleLogger.timestampFormatter.string(from: Date())
    let filename = NSString(string: String(describing: file)).lastPathComponent
    return "\(timestamp) [\(line):\(filename)] \(message)"
  }

  public override func trace(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, level: "TRACE", message, meta))
  }

  public override func info(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, level: "INFO", message, meta))
  }

  public override func notice(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, level: "NOTICE", message, meta))
  }

  public override func warning(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, level: "WARN", message, meta))
  }

  public override func error(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, level: "ERROR", message, meta))
  }

  public override func fatal(file: StaticString = #file, line: UInt = #line, _ message: String, _ meta: Any...) {
    print(self.format(file: file, line: line, level: "FATAL", message, meta))
  }
}
