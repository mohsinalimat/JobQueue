///
///  Created by George Cox on 1/27/20.
///

import Foundation
import CoreData
import JobQueue
import ReactiveSwift

private class CoreDataStack {
  let container: NSPersistentContainer
  let model = CoreDataStack.createModel()

  init() {
    self.container = NSPersistentContainer(name: "test", managedObjectModel: self.model)
    let desc = NSPersistentStoreDescription()
    desc.type = NSInMemoryStoreType
    self.container.persistentStoreDescriptions = [desc]
    self.container.loadPersistentStores { desc, error in
      guard let error = error else {
        return
      }
      print("Error loading persistent stores: \(error)")
    }
  }

  func rollback(_ ctx: NSManagedObjectContext) {
    ctx.reset()
  }

  func commit(_ ctx: NSManagedObjectContext) -> SignalProducer<Void, Error> {
    return SignalProducer { o, lt in
      typealias SaveFunction = (NSManagedObjectContext, Any) -> Void
      let save: SaveFunction = { ctx, _save in
        do {
          try ctx.save()
          guard let parent = ctx.parent else {
            o.send(value: ())
            o.sendCompleted()
            return
          }
          guard let saveParent = _save as? SaveFunction else {
            o.send(value: ())
            o.sendCompleted()
            return
          }
          saveParent(parent, _save)
        } catch {
          o.send(error: error)
        }
      }
      save(ctx, save)
    }
  }

  static func createModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()

    let entity = NSEntityDescription()
    entity.name = "JobQueueCoreDataStorageEntity"
    entity.managedObjectClassName = String(describing: JobQueueCoreDataStorageEntity.self)

    let jobID = NSAttributeDescription()
    jobID.attributeType = .stringAttributeType
    jobID.name = "id"
    jobID.isOptional = false

    let jobTypeName = NSAttributeDescription()
    jobTypeName.attributeType = .stringAttributeType
    jobTypeName.name = "type"
    jobTypeName.isOptional = false

    let jobQueueName = NSAttributeDescription()
    jobQueueName.attributeType = .stringAttributeType
    jobQueueName.name = "queue"
    jobQueueName.isOptional = false

    let jobDetails = NSAttributeDescription()
    jobDetails.attributeType = .binaryDataAttributeType
    jobDetails.name = "details"
    jobDetails.isOptional = false

    entity.properties = [jobID, jobTypeName, jobQueueName, jobDetails]
    model.entities = [entity]

    return model
  }
}
