///
///  Created by George Cox on 1/22/20.
///

import Foundation

public enum JobCancellationReason {
  case movedToWaiting
  case movedToDelayed
  case removed
  case movedToPaused
  case queueSuspended
}
