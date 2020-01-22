///
///  Created by George Cox on 1/22/20.
///

import Foundation

internal extension Sequence where Element == AnyJob {
  var earliestDelayedJob: Element? {
    return self.delayedJobs
      .sorted { $0.delayedUntil! < $1.delayedUntil! }
      .first
  }

  var delayedJobs: [AnyJob] {
    return self.filter { $0.status.isDelayed }
  }
}
