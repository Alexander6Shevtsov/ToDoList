//
//  AppDelegate.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 29.08.2025.
//

import UIKit
import CoreData

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    // MARK: - Public Properties
    var persistentContainer: NSPersistentContainer { coreDataStack.persistentContainer }
    
    // MARK: - Private Properties
    // Инкапсулированный стек Core Data
    private let coreDataStack = CoreDataStack(modelName: "ToDoList")
    
    // MARK: - Overrides
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        true
    }
    
    // MARK: - Public Methods
    func saveContext() {
        coreDataStack.saveContext()
    }
    
    func makeViewContext() -> NSManagedObjectContext {
        coreDataStack.viewContext
    }
}

// MARK: - CoreDataStack
private final class CoreDataStack {
    
    // MARK: - Public Properties
    var viewContext: NSManagedObjectContext { container.viewContext }
    var persistentContainer: NSPersistentContainer { container }
    
    // MARK: - Private Properties
    private let container: NSPersistentContainer
    
    // MARK: - Initializers
    init(modelName: String) {
        container = NSPersistentContainer(name: modelName)
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("CoreData load error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Public Methods
    func saveContext() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        context.perform {
            do {
                try context.save()
            } catch {
                assertionFailure("CoreData save error: \(error)")
            }
        }
    }
}
