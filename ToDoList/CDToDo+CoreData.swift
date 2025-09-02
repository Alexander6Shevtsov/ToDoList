//
//  CDToDo+CoreData.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import Foundation
import CoreData

@objc(CDToDo)
final class CDToDo: NSManagedObject {}

extension CDToDo {
    @nonobjc class func fetchRequest() -> NSFetchRequest<CDToDo> {
        NSFetchRequest<CDToDo>(entityName: "CDToDo")
    }
    
    @NSManaged var id: Int
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

// MARK: - Мапинг Core Data

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
        let object = CDToDo(context: context)
        object.id = Int(entity.id)
        object.title = entity.title
        object.details = entity.details
        object.createdAt = entity.createdAt
        object.isDone = entity.isDone
        return object
    }
}
