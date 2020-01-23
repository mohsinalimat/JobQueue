///
///  Created by George Cox on 1/23/20.
///
///  Credit: https://stackoverflow.com/a/28016692/182591
///

import Foundation

extension ISO8601DateFormatter {
  convenience init(_ formatOptions: Options, timeZone: TimeZone = TimeZone(secondsFromGMT: 0)!) {
    self.init()
    self.formatOptions = formatOptions
    self.timeZone = timeZone
  }
}

extension Formatter {
  static let iso8601 = ISO8601DateFormatter([.withInternetDateTime, .withFractionalSeconds])
}

extension Date {
  var iso8601: String {
    return Formatter.iso8601.string(from: self)
  }
}

extension String {
  var iso8601: Date? {
    return Formatter.iso8601.date(from: self)
  }
}
