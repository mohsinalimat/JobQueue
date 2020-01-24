///
///  Created by George Cox on 1/22/20.
///

import Foundation
import JobQueueCore

public enum JobType {
  case standard
  case scheduled(schedule: JobSchedule)
}
