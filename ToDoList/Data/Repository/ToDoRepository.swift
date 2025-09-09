//
//  ToDoRepository.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 02.09.2025.
//

import UIKit
import CoreData

final class ToDoRepository {
    private let persistentContainer: NSPersistentContainer
    
    init(persistentContainer: NSPersistentContainer? = nil) {
        if let persistentContainer {
            self.persistentContainer = persistentContainer
        } else {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            self.persistentContainer = appDelegate.persistentContainer
        }
        self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    // MARK: - Public API
    func fetchAll(completion: @escaping (Result<[ToDoEntity], Error>) -> Void) {
        performBackground { context in
            let request: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(CDToDo.createdAt),
                ascending: false
            )]
            let objects = try context.fetch(request)
            return objects.map { $0.toDomain() }
        } completion: { completion($0) }
    }
    
    func search(
        query: String,
        completion: @escaping (Result<[ToDoEntity], Error>) -> Void
    ) {
        performBackground { context in
            let request: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty == false {
                request.predicate = NSPredicate(
                    format: "title CONTAINS[cd] %@ OR details CONTAINS[cd] %@",
                    trimmed,
                    trimmed
                )
            }
            request.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(CDToDo.createdAt),
                ascending: false
            )]
            let objects = try context.fetch(request)
            return objects.map { $0.toDomain() }
        } completion: { completion($0) }
    }
    
    func upsert(
        _ entities: [ToDoEntity],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        performBackground { context in
            for entity in entities {
                let fetch: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
                fetch.fetchLimit = 1
                fetch.predicate = NSPredicate(format: "id == %lld", Int64(entity.id))
                if let existing = try context.fetch(fetch).first {
                    existing.apply(from: entity)
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
        completion: @escaping (
            Result<[ToDoEntity], Error>
        ) -> Void
    ) {
        performBackground { context in
            let fetch: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            fetch.fetchLimit = 1
            fetch.predicate = NSPredicate(format: "id == %lld", Int64(id))
            if let obj = try context.fetch(fetch).first {
                obj.isDone.toggle()
                try context.save()
            }
            // Возвращаем актуальный список
            let all: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            all.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.createdAt
                ),
                ascending: false
            )]
            return try context.fetch(all).map { $0.toDomain() }
        } completion: { completion($0) }
    }
    
    func delete(
        id: Int,
        completion: @escaping (Result<[ToDoEntity], Error>) -> Void
    ) {
        performBackground { context in
            let fetch: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            fetch.fetchLimit = 1
            fetch.predicate = NSPredicate(format: "id == %lld", Int64(id))
            if let obj = try context.fetch(fetch).first {
                context.delete(obj)
                try context.save()
            }
            let all: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            all.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.createdAt
                ),
                ascending: false
            )]
            return try context.fetch(all).map { $0.toDomain() }
        } completion: { completion($0) }
    }
    
    func replaceAll(with items: [ToDoEntity], completion: @escaping (Result<Void, Error>) -> Void) {
        let backgroundContext = persistentContainer.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        backgroundContext.undoManager = nil
        backgroundContext.perform {
            do {
                let storeType = backgroundContext.persistentStoreCoordinator?.persistentStores.first?.type
                if storeType == NSInMemoryStoreType {
                    let fetch = NSFetchRequest<NSManagedObject>(entityName: "CDToDo")
                    fetch.includesPropertyValues = false
                    let all = try backgroundContext.fetch(fetch)
                    all.forEach { backgroundContext.delete($0) }
                } else {
                    let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "CDToDo")
                    let delete = NSBatchDeleteRequest(fetchRequest: fetch)
                    delete.resultType = .resultTypeObjectIDs
                    if let result = try backgroundContext.execute(delete) as? NSBatchDeleteResult,
                       let ids = result.result as? [NSManagedObjectID] {
                        NSManagedObjectContext.mergeChanges(
                            fromRemoteContextSave: [NSDeletedObjectsKey: ids],
                            into: [self.persistentContainer.viewContext]
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
    
    // MARK: - Introspection
    func isStoreEmpty() -> Bool {
        let viewContext = persistentContainer.viewContext
        var result = true
        viewContext.performAndWait {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "CDToDo")
            request.fetchLimit = 1
            do {
                result = try viewContext.count(for: request) == 0
            } catch {
                result = true
            }
        }
        return result
    }
    
    
    // MARK: - Helpers
    private func performBackground<T>(
        _ work: @escaping (
            NSManagedObjectContext
        ) throws -> T,
        completion: @escaping (Result<T, Error>) -> Void
    ) {
        let context = persistentContainer.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.perform {
            do { completion(.success(try work(context))) }
            catch { completion(.failure(error)) }
        }
    }
    
    func create(
        title: String,
        details: String?,
        completion: @escaping (Result<[ToDoEntity], Error>) -> Void
    ) {
        performBackground { context in
            // nextId = max(id) + 1
            let request: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            request.fetchLimit = 1
            request.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.id
                ),
                ascending: false
            )]
            let last = try context.fetch(request).first
            let nextId = Int((last?.id ?? 0) + 1)
            
            let entity = ToDoEntity(
                id: nextId,
                title: title,
                details: details,
                createdAt: Date(),
                isDone: false
            )
            _ = CDToDo.insert(into: context, from: entity)
            try context.save()
            
            let all: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            all.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.createdAt
                ),
                ascending: false
            )]
            return try context.fetch(all).map { $0.toDomain() }
        } completion: { completion($0) }
    }
    
    func update(
        id: Int,
        title: String,
        details: String?,
        completion: @escaping (Result<[ToDoEntity], Error>) -> Void
    ) {
        performBackground { context in
            let fetch: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            fetch.fetchLimit = 1
            fetch.predicate = NSPredicate(format: "id == %lld", Int64(id))
            if let obj = try context.fetch(fetch).first {
                obj.title = title
                obj.details = details
                try context.save()
            }
            let all: NSFetchRequest<CDToDo> = CDToDo.fetchRequest()
            all.sortDescriptors = [NSSortDescriptor(
                key: #keyPath(
                    CDToDo.createdAt
                ),
                ascending: false
            )]
            return try context.fetch(all).map { $0.toDomain() }
        } completion: { completion($0) }
    }
}
