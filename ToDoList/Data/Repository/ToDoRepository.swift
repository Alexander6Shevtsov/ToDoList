//
//  ToDoRepository.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 02.09.2025.
//

import UIKit
import CoreData

final class ToDoRepository {
    
    // MARK: - Private Properties
    private let persistentContainer: NSPersistentContainer
    private var mainContext: NSManagedObjectContext { persistentContainer.viewContext }
    
    // MARK: - Initializers
    init(persistentContainer: NSPersistentContainer? = nil) {
        if let persistentContainer {
            self.persistentContainer = persistentContainer
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            self.persistentContainer = appDelegate.persistentContainer
        }
        // Обновления из фоновых контекстов автоматически мерджатся в mainContext
        self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
        self.persistentContainer.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // MARK: - Public Methods
    func fetchAll(completion: @escaping (Result<[ToDoEntity], Error>) -> Void) {
        performBackground { context in
            let request: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.createdAt
                ),
                ascending: false
            )]
            let objects = try context.fetch(request)
            return objects.map { $0.toDomain() }
        } completion: { completion($0) }
    }
    
    // MARK: - Public Methods
    func search(query: String, completion: @escaping (Result<[ToDoEntity], Error>) -> Void) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else {
            fetchAll(completion: completion)
            return
        }
        
        let normalizedQuery = trimmedQuery.lowercased()
        
        fetchAll { result in
            switch result {
            case .success(let allItems):
                let filteredItems = allItems.filter { entity in
                    let titleMatch = entity.title.lowercased().contains(normalizedQuery)
                    let detailsMatch = entity.details?.lowercased().contains(normalizedQuery) ?? false
                    return titleMatch || detailsMatch
                }
                completion(.success(filteredItems))
            case .failure(let repositoryError):
                completion(.failure(repositoryError))
            }
        }
    }
    
    
    func upsert(
        _ entities: [ToDoEntity],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        performBackground { context in
            for entity in entities {
                let fetchRequest: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
                fetchRequest.fetchLimit = 1
                fetchRequest.predicate = NSPredicate(format: "id == %lld", Int64(entity.id))
                if let existingObject = try context.fetch(fetchRequest).first {
                    existingObject.apply(from: entity)
                } else {
                    _ = CDToDo.insert(into: context, from: entity)
                }
            }
            try context.save()
            return ()
        } completion: { completion($0) }
    }
    
    func toggleDone(
        id: Int,
        completion: @escaping (Result<[ToDoEntity], Error>) -> Void
    ) {
        performBackground { context in
            let fetchRequest: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = NSPredicate(format: "id == %lld", Int64(id))
            if let object = try context.fetch(fetchRequest).first {
                object.isDone.toggle()
                try context.save()
            }
            // Возвращаем актуальный список
            let allRequest: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            allRequest.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.createdAt
                ),
                ascending: false
            )]
            return try context.fetch(allRequest).map { $0.toDomain() }
        } completion: { completion($0) }
    }
    
    func delete(
        id: Int,
        completion: @escaping (Result<[ToDoEntity], Error>) -> Void
    ) {
        performBackground { context in
            let fetchRequest: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = NSPredicate(format: "id == %lld", Int64(id))
            if let object = try context.fetch(fetchRequest).first {
                context.delete(object)
                try context.save()
            }
            let allRequest: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            allRequest.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.createdAt
                ),
                ascending: false
            )]
            return try context.fetch(allRequest).map { $0.toDomain() }
        } completion: { completion($0) }
    }
    
    func replaceAll(
        with items: [ToDoEntity],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.undoManager = nil
        
        backgroundContext.perform {
            do {
                let storeType = backgroundContext.persistentStoreCoordinator?.persistentStores.first?.type
                if storeType == NSInMemoryStoreType {
                    let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CDToDo")
                    fetchRequest.includesPropertyValues = false
                    let fetchedObjects = try backgroundContext.fetch(fetchRequest)
                    fetchedObjects.forEach { backgroundContext.delete($0) }
                } else {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CDToDo")
                    let batchDelete = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    batchDelete.resultType = .resultTypeObjectIDs
                    if let deleteResult = try backgroundContext.execute(batchDelete) as? NSBatchDeleteResult,
                       let deletedObjectIds = deleteResult.result as? [NSManagedObjectID] {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [NSDeletedObjectsKey: deletedObjectIds],
                            into: [self.mainContext]
                        )
                    }
                }
                
                for item in items {
                    let cdToDo = CDToDo(context: backgroundContext)
                    cdToDo.id        = Int64(item.id)
                    cdToDo.title     = item.title
                    cdToDo.details   = item.details
                    cdToDo.createdAt = item.createdAt
                    cdToDo.isDone    = item.isDone
                }
                
                try backgroundContext.save()
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // Проверка пустоты
    func isStoreEmpty() -> Bool {
        var isEmpty = true
        mainContext.performAndWait {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDToDo")
            request.fetchLimit = 1
            do {
                isEmpty = try mainContext.count(for: request) == 0
            } catch {
                isEmpty = true
            }
        }
        return isEmpty
    }
    
    func create(
        title: String,
        details: String?,
        completion: @escaping (Result<[ToDoEntity], Error>) -> Void
    ) {
        performBackground { context in
            // nextId = max(id) + 1
            let lastRequest: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            lastRequest.fetchLimit = 1
            lastRequest.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.id
                ),
                ascending: false
            )]
            let lastObject = try context.fetch(lastRequest).first
            let nextId = Int((lastObject?.id ?? 0) + 1)
            
            let entity = ToDoEntity(
                id: nextId,
                title: title,
                details: details,
                createdAt: Date(),
                isDone: false
            )
            _ = CDToDo.insert(into: context, from: entity)
            try context.save()
            
            let allRequest: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            allRequest.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.createdAt
                ),
                ascending: false
            )]
            return try context.fetch(allRequest).map { $0.toDomain() }
        } completion: { completion($0) }
    }
    
    func update(
        id: Int,
        title: String,
        details: String?,
        completion: @escaping (Result<[ToDoEntity], Error>) -> Void
    ) {
        performBackground { context in
            let fetchRequest: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            fetchRequest.fetchLimit = 1
            fetchRequest.predicate = NSPredicate(format: "id == %lld", Int64(id))
            if let object = try context.fetch(fetchRequest).first {
                object.title = title
                object.details = details
                try context.save()
            }
            let allRequest: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            allRequest.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.createdAt
                ),
                ascending: false
            )]
            return try context.fetch(allRequest).map { $0.toDomain() }
        } completion: { completion($0) }
    }
    
    // MARK: - Private Methods
    private func performBackground<T>(
        _ work: @escaping (NSManagedObjectContext) throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.perform {
            do {
                let result = try work(backgroundContext)
                completion(.success(result))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
