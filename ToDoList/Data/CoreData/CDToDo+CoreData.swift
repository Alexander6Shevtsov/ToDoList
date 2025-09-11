//
//  CDToDo+CoreData.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import Foundation
import CoreData

// MARK: - Core Data Entity
@objc(CDToDo)
final class CDToDo: NSManagedObject {}

// MARK: - Fetch Request & Managed Properties
extension CDToDo {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CDToDo> {
        NSFetchRequest<CDToDo>(entityName: "CDToDo")
    }
    
    // Хранимые поля Core Data
    @NSManaged var id: Int64
    @NSManaged var title: String
    @NSManaged var details: String?
    @NSManaged var createdAt: Date
    @NSManaged var isDone: Bool
    
    @NSManaged var userId: NSNumber?
    
    var userIdInt: Int? {
        get { userId?.intValue }
        set { userId = newValue.map { NSNumber(value: $0) } }
    }
}

// MARK: - Mapping (CoreData ↔ Domain)
extension CDToDo {
    func toDomain() -> ToDoEntity {
        ToDoEntity(
            id: Int(id),
            title: title,
            details: details,
            createdAt: createdAt,
            isDone: isDone
        )
    }
    
    func apply(from entity: ToDoEntity) {
        title = entity.title
        details = entity.details
        createdAt = entity.createdAt
        isDone = entity.isDone
    }
    
    static func insert(
        into context: NSManagedObjectContext,
        from entity: ToDoEntity
    ) -> CDToDo {
        let managedObject = CDToDo(context: context)
        managedObject.id = Int64(entity.id)
        managedObject.title = entity.title
        managedObject.details = entity.details
        managedObject.createdAt = entity.createdAt
        managedObject.isDone = entity.isDone
        return managedObject
    }
}
