///
///  Created by George Cox on 1/22/20.
///

import Foundation
#if SWIFT_PACKAGE
import JobQueueCore
#endif

public enum JobType {
  case standard
  case scheduled(schedule: JobSchedule)
}
