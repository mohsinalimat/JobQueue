///
///  Created by George Cox on 1/22/20.
///

import Foundation

public enum JobType {
  case standard
  case scheduled(schedule: JobSchedule)
}
