///
///  Created by George Cox on 1/22/20.
///

import Foundation
import ReactiveSwift
#if SWIFT_PACKAGE
import JobQueueCore
#endif

public enum JobProcessorError: Swift.Error {
  case invalidJobType
  case abstractFunction
  case payloadDeserializationFailed
}
