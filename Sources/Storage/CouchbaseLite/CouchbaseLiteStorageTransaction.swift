///
///  Created by George Cox on 1/27/20.
///

import CouchbaseLiteSwift
import Foundation
import ReactiveSwift

#if SWIFT_PACKAGE
import JobQueueCore
#endif

extension CouchbaseLiteStorage {
  public class Transaction: JobStorageTransaction {
    let queue: JobQueueProtocol?
    let database: Database
    let logger: Logger

    public init(queue: JobQueueProtocol? = nil, database: Database, logger: Logger) {
      self.queue = queue
      self.database = database
      self.logger = logger
    }

    private func key(from details: JobDetails) -> String {
      return self.key(from: details.id, queueName: details.queueName)
    }

    private func key(from id: JobID, queueName: JobQueueName) -> String {
      return "\(queueName)/\(id)"
    }

    public func removeAll(queue: JobQueueProtocol?) -> Swift.Result<Void, Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }

      let query = QueryBuilder
        .select(SelectResult.expression(Meta.id))
        .from(DataSource.database(self.database))
        .where(Expression.property("queue").equalTo(Expression.string(queue.name)))

      do {
        for result in try query.execute() {
          guard let id = result.string(forKey: "_id") else {
            return .failure(JobStorageError.jobTypeMismatch)
          }
          guard let document = database.document(withID: id) else {
            return .failure(JobStorageError.jobNotFound(queue.name, id))
          }
          try database.deleteDocument(document)
        }
        return .success(())
      } catch {
        return .failure(error)
      }
    }

    public func remove(_ details: JobDetails, queue: JobQueueProtocol?) -> Swift.Result<JobDetails, Error> {
      switch self.remove(details.id, queue: queue) {
      case .success:
        return .success(details)
      case .failure(let error):
        return .failure(error)
      }
    }

    public func remove(_ id: JobID, queue: JobQueueProtocol?) -> Swift.Result<JobID, Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }

      do {
        guard let document = database.document(withID: self.key(from: id, queueName: queue.name)) else {
          return .failure(JobStorageError.jobNotFound(queue.name, id))
        }
        try database.deleteDocument(document)
        return .success(id)
      } catch {
        return .failure(error)
      }
    }

    public func store(_ details: JobDetails, queue: JobQueueProtocol?) -> Swift.Result<JobDetails, Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }

      do {
        let _id = self.key(from: details)
        let document = database.document(withID: _id)?.toMutable() ?? MutableDocument(id: _id)
        document.setBlob(Blob(contentType: "application/json", data: try details.toData()), forKey: "details")
        document.setString(queue.name, forKey: "queue")
        try database.saveDocument(document)
        return .success(details)
      } catch {
        return .failure(error)
      }
    }

    public func getAll(queue: JobQueueProtocol?) -> Swift.Result<[JobDetails], Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }

      let query = QueryBuilder
        .select(SelectResult.expression(Meta.id),
                SelectResult.property("details"))
        .from(DataSource.database(self.database))
        .where(Expression.property("queue").equalTo(Expression.string(queue.name)))

      do {
        return .success(try query.execute().reduce(into: [JobDetails]()) { acc, result in
          guard let blob = result.blob(forKey: "details") else {
            return
          }
          acc.append(try JobDetails.from(blob: blob))
        })
      } catch {
        return .failure(error)
      }
    }

    public func get(_ id: JobID, queue: JobQueueProtocol?) -> Swift.Result<JobDetails, Error> {
      guard let queue = (queue ?? self.queue) else {
        return .failure(JobStorageError.noQueueProvided)
      }

      do {
        guard let document = database.document(withID: self.key(from: id, queueName: queue.name)) else {
          return .failure(JobStorageError.jobNotFound(queue.name, id))
        }
        guard let blob = document.blob(forKey: "details") else {
          return .failure(JobStorageError.jobNotFound(queue.name, id))
        }
        return .success(try JobDetails.from(blob: blob))
      } catch {
        return .failure(error)
      }
    }
  }
}

extension JobDetails {
  func toData() throws -> Data {
    try JSONEncoder().encode(self)
  }

  static func from(blob: Blob) throws -> Self {
    guard let data = blob.content else {
      throw JobStorageError.jobDeserializationFailed
    }
    return try JSONDecoder().decode(JobDetails.self, from: data)
  }
}
