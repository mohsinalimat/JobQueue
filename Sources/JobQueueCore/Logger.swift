///
///  Created by George Cox on 1/22/20.
///

import Foundation

/**
 # Logger

 An abstract logging class meant to be sub-classed before use

 The `JobQueue` and it's related source may invoke any of this class's functions,
 so sub-classes should override them all.

 If you're using a logging module, like `swift-log`/`CocoaLumberjack`/`XLFacility`/etc,
 create a sub-class of `Logger` that invokes the equivalent logging function in
 that module.

 A `ConsoleLogger` has been provided for convenience, but you should really be using
 something more robust.
 */
open class Logger {
  open func trace(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    abstract()
  }

  open func info(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    abstract()
  }

  open func notice(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    abstract()
  }

  open func warning(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    abstract()
  }

  open func error(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    abstract()
  }

  open func fatal(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    abstract()
  }
}

/// ConsoleLogger
///
/// A Logger subclass that logs to the console via the `print` function.
/// Only use this sub-class when you have no other logging solution in place.
public final class ConsoleLogger: Logger {
  private class PrintDestination: TextOutputStream {
    let fileHandle: FileHandle
    init(_ fileHandle: FileHandle) {
      self.fileHandle = fileHandle
    }

    func write(_ string: String) {
      guard let data = string.data(using: .utf8) else {
        return
      }
      self.fileHandle.write(data)
    }
  }

  private var stdError = PrintDestination(FileHandle.standardError)

  public override init() {}

  private func format(file: StaticString, line: UInt, function: StaticString, level: String, _ message: String, _ meta: [String: Any]? = nil) -> String {
    let filename = NSString(string: String(describing: file)).lastPathComponent
    let timeStamp: String = {
      let stamp = Date().iso8601
      guard let zone = TimeZone.current.abbreviation() else {
        return stamp
      }
      return "\(stamp):\(zone)"
    }()
    return "\(timeStamp) • \(level) • \(filename):\(line) • \(message)"
  }

  public override func trace(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    print(self.format(file: file, line: line, function: function, level: "TRACE ", message, meta))
  }

  public override func info(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    print(self.format(file: file, line: line, function: function, level: "INFO  ", message, meta))
  }

  public override func notice(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    print(self.format(file: file, line: line, function: function, level: "NOTICE", message, meta))
  }

  public override func warning(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    print(self.format(file: file, line: line, function: function, level: "WARN  ", message, meta))
  }

  public override func error(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    print(self.format(file: file, line: line, function: function, level: "ERROR ", message, meta), to: &stdError)
  }

  public override func fatal(file: StaticString = #file, line: UInt = #line, function: StaticString = #function, _ message: String, _ meta: [String: Any]? = nil) {
    print(self.format(file: file, line: line, function: function, level: "FATAL ", message, meta), to: &stdError)
  }
}
