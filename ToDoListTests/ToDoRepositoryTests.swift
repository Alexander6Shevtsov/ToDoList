//
//  ToDoRepositoryTests.swift
//  ToDoListTests
//
//  Created by Alexander Shevtsov on 03.09.2025.
//

import XCTest
import CoreData
@testable import ToDoList

final class ToDoRepositoryTests: XCTestCase {
    
    private var container: NSPersistentContainer!
    private var repository: ToDoRepository!
    
    override func setUp() {
        super.setUp()
        container = makeInMemoryContainer()
        repository = ToDoRepository(persistentContainer: container)
    }
    
    override func tearDown() {
        repository = nil
        container = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    func test_emptyStore_fetchAll_returnsEmpty() {
        let exp = expectation(description: "fetch empty")
        repository.fetchAll { result in
            if case let .success(items) = result {
                XCTAssertTrue(items.isEmpty)
            } else {
                XCTFail("Expected success with empty array")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
    }
    
    func test_create_fetch_toggle_update_delete_flow() {
        // create #1
        let exp1 = expectation(description: "create 1")
        repository.create(title: "First", details: "A") { result in
            guard case let .success(items) = result else { return XCTFail() }
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items.first?.title, "First")
            exp1.fulfill()
        }
        wait(for: [exp1], timeout: 2.0)
        
        // create #2
        let exp2 = expectation(description: "create 2")
        repository.create(title: "Second", details: nil) { result in
            guard case let .success(items) = result else { return XCTFail() }
            XCTAssertEqual(items.count, 2)
            // сортировка: createdAt desc → второй элемент сверху
            XCTAssertEqual(items.first?.title, "Second")
            exp2.fulfill()
        }
        wait(for: [exp2], timeout: 2.0)
        
        // toggle done for id=1
        let exp3 = expectation(description: "toggle")
        repository.toggleDone(id: 1) { result in
            guard case let .success(items) = result else { return XCTFail() }
            let first = items.first(where: { $0.id == 1 })
            XCTAssertEqual(first?.isDone, true)
            exp3.fulfill()
        }
        wait(for: [exp3], timeout: 2.0)
        
        // update id=2
        let exp4 = expectation(description: "update")
        repository.update(id: 2, title: "Second updated", details: "B") { result in
            guard case let .success(items) = result else { return XCTFail() }
            let item = items.first(where: { $0.id == 2 })
            XCTAssertEqual(item?.title, "Second updated")
            XCTAssertEqual(item?.details, "B")
            exp4.fulfill()
        }
        wait(for: [exp4], timeout: 2.0)
        
        // delete id=1
        let exp5 = expectation(description: "delete")
        repository.delete(id: 1) { result in
            guard case let .success(items) = result else { return XCTFail() }
            XCTAssertEqual(items.count, 1)
            XCTAssertNil(items.first(where: { $0.id == 1 }))
            exp5.fulfill()
        }
        wait(for: [exp5], timeout: 2.0)
    }
    
    // MARK: - Helpers
    private func makeInMemoryContainer() -> NSPersistentContainer {
        let bundle = Bundle(for: CDToDo.self)
        guard let modelURL = bundle.url(forResource: "ToDoList", withExtension: "momd"),
              let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Failed to load Core Data model")
        }
        let container = NSPersistentContainer(name: "ToDoList", managedObjectModel: model)
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        description.shouldAddStoreAsynchronously = false
        container.persistentStoreDescriptions = [description]
        
        var loadError: Error?
        container.loadPersistentStores { _, error in loadError = error }
        if let loadError { fatalError("Failed to load in-memory store: \(loadError)") }
        return container
    }
}
