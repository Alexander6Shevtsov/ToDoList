//
//  ToDoRepositoryReplaceAllTests.swift
//  ToDoListTests
//
//  Created by Alexander Shevtsov on 04.09.2025.
//

import XCTest
import CoreData
@testable import ToDoList

final class ToDoRepositoryReplaceAllTests: XCTestCase {
    var container: NSPersistentContainer!
    var repository: ToDoRepository!
    
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
    
    func test_replaceAll_overwritesStore_and_fetchesSorted() {
        // given: исходные данные
        let old = [
            ToDoEntity(id: 1, title: "old-1", details: nil, createdAt: Date(timeIntervalSince1970: 10), isDone: false),
            ToDoEntity(id: 2, title: "old-2", details: nil, createdAt: Date(timeIntervalSince1970: 20), isDone: false)
        ]
        let seedDone = expectation(description: "seed old")
        repository.replaceAll(with: old) { _ in seedDone.fulfill() }
        wait(for: [seedDone], timeout: 2)
        
        // when: меняем на новые
        let now = Date()
        let newer = [
            ToDoEntity(id: 3, title: "new-3", details: "a", createdAt: now.addingTimeInterval(-60), isDone: false),
            ToDoEntity(id: 4, title: "new-4", details: "b", createdAt: now, isDone: true)
        ]
        let repl = expectation(description: "replace")
        repository.replaceAll(with: newer) { _ in repl.fulfill() }
        wait(for: [repl], timeout: 2)
        
        // then: fetchAll возвращает только новые и по дате убыв.
        let fetched = expectation(description: "fetch")
        repository.fetchAll { result in
            guard case let .success(items) = result else { return XCTFail() }
            XCTAssertEqual(Set(items.map { $0.title }), ["new-3","new-4"])
            XCTAssertTrue(items.first?.isDone == true)
            XCTAssertEqual(items.map { $0.id }, [4, 3])
            XCTAssertEqual(items.first?.title, "new-4")
            XCTAssertEqual(items.count, 2)
            fetched.fulfill()
        }
        wait(for: [fetched], timeout: 2)
    }
}
