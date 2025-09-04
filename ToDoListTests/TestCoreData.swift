//
//  TestCoreData.swift
//  ToDoListTests
//
//  Created by Alexander Shevtsov on 04.09.2025.
//

import CoreData
@testable import ToDoList

func makeInMemoryContainer() -> NSPersistentContainer {
    let model = NSManagedObjectModel.mergedModel(from: [Bundle(for: CDToDo.self)])!
    let container = NSPersistentContainer(name: "ToDoList", managedObjectModel: model)
    
    let description = NSPersistentStoreDescription()
    description.type = NSInMemoryStoreType
    description.shouldMigrateStoreAutomatically = true
    description.shouldInferMappingModelAutomatically = true
    container.persistentStoreDescriptions = [description]
    
    container.loadPersistentStores { _, error in
        precondition(error == nil, "In-memory store failed: \(String(describing: error))")
    }
    
    let viewContext = container.viewContext
    viewContext.automaticallyMergesChangesFromParent = true
    viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    viewContext.name = "test.viewContext"
    viewContext.undoManager = nil
    return container
}
