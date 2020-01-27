///
///  Created by George Cox on 1/27/20.
///

import Foundation

public protocol JobResolver {
  func registerResolver<T>(_ closure: @escaping (AnyJob) throws -> T) where T: Job
  func resolve<T>(_ job: AnyJob) throws -> T where T: Job
}

public enum JobResolverError: Error {
  case noResolver(JobName)
  case noValidResolver(JobName)
  case resolutionFailure(JobName, Error)
}

public class DefaultJobResolver: JobResolver {
  var resolvers = [JobName: Any]()

  public func registerResolver<T>(_ closure: @escaping (AnyJob) throws -> T) where T : Job {
    resolvers[T.name] = closure
  }
  public func resolve<T>(_ job: AnyJob) throws -> T where T : Job {
    guard let anyResolver = resolvers[T.name] else {
      throw JobResolverError.noResolver(T.name)
    }
    guard let resolver = anyResolver as? (AnyJob) throws -> T else {
      throw JobResolverError.noValidResolver(T.name)
    }
    return try resolver(job)
  }
}
