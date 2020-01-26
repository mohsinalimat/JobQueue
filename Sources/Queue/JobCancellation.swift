///
///  Created by George Cox on 1/22/20.
///

import Foundation

public enum JobCancellationReason {
  case statusChangedToWaiting
  case statusChangedToDelayed
  case removed
  case statusChangedToPaused
  case queueSuspended
}
