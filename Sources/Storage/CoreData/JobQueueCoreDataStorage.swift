///
///  Created by George Cox on 1/25/20.
///

import Foundation
import ReactiveSwift
import CoreData
#if SWIFT_PACKAGE
import JobQueueCore
#endif

public class JobQueueCoreDataStorageEntity: NSManagedObject {
  dynamic var jobId: String!
  dynamic var jobQueueName: String!
  dynamic var job: JobDetails!
}

public class JobQueueCoreDataStorage<Entity: JobQueueCoreDataStorageEntity>: JobStorage {
  private let logger: Logger
  private let createContext: () -> NSManagedObjectContext?
  private let rollback: (NSManagedObjectContext) -> Void
  private let commit: (NSManagedObjectContext) -> SignalProducer<Void, Error>

  public init(
    _ entity: Entity.Type,
    createContext: @escaping () -> NSManagedObjectContext,
    rollback: @escaping (NSManagedObjectContext) -> Void,
    commit: @escaping (NSManagedObjectContext) -> SignalProducer<Void, Error>,
    logger: Logger = ConsoleLogger()
  ) {
    self.createContext = createContext
    self.rollback = rollback
    self.commit = commit
    self.logger = logger
  }

  public func transaction<T>(
    queue: JobQueueProtocol,
    _ closure: @escaping (JobStorageTransaction) throws -> T
  ) -> SignalProducer<T, Error> {
    return SignalProducer { o, lt in
      guard let context = self.createContext() else {
        o.send(error: Errors.noContext)
        return
      }
      let transaction = Transaction(
        queue: queue,
        context: context,
        logger: self.logger
      )
      do {
        let closureResult = try closure(transaction)
        self.commit(context).startWithResult { commitResult in
          switch commitResult {
          case .success:
            o.send(value: closureResult)
            o.sendCompleted()
          case .failure(let error):
            o.send(error: error)
          }
        }
      } catch {
        self.rollback(context)
        o.send(error: error)
      }
    }
  }
}

extension JobQueueCoreDataStorage {
  public enum Errors: Error {
    case noContext
  }
}

extension NSManagedObjectID {
  static func from(_ string: String, in context: NSManagedObjectContext) -> NSManagedObjectID? {
    guard let coordinator = context.persistentStoreCoordinator else {
      return nil
    }
    guard let url = URL(string: string) else {
      return nil
    }
    return coordinator.managedObjectID(forURIRepresentation: url)
  }
}
extension NSManagedObject {
  static func with(id: String, queue: JobQueueProtocol, in context: NSManagedObjectContext) -> Self? {
    guard let managedObjectID = NSManagedObjectID.from(id, in: context) else {
      return nil
    }
    return context.object(with: managedObjectID) as? Self
  }
}
