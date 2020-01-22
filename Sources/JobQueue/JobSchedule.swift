///
///  Created by George Cox on 1/22/20.
///

import Foundation

public enum JobSchedule {
  // Process the job every n seconds. If a DateInterval is provided,
  // processing will only occur within that DateInterval.
  case timeInterval(TimeInterval, DateInterval?)

  public var dateInterval: DateInterval {
    switch self {
    case .timeInterval(_, let dateInterval):
      guard let dateInterval = dateInterval else {
        return DateInterval(start: Date.distantPast, end: Date.distantFuture)
      }
      return dateInterval
    }
  }
}
