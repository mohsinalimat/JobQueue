///
///  Created by George Cox on 1/22/20.
///

import Foundation

public protocol JobSorter {
  func sort(jobs: [AnyJob]) -> [AnyJob]
}

public struct DefaultJobSorter: JobSorter {
  public init() {}
  public func sort(jobs: [AnyJob]) -> [AnyJob] {
    return jobs.sorted { lhs, rhs in
      if
        let lhsOrder = lhs.order,
        let rhsOrder = rhs.order,
        fabsf(lhsOrder - rhsOrder) > Float.ulpOfOne {
        return lhsOrder < rhsOrder
      }
      if lhs.order != nil {
        return true
      }
      if rhs.order != nil {
        return false
      }
      return lhs.queuedAt < rhs.queuedAt
    }
  }
}
