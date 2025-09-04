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
        // Arrange
        let container = makeInMemoryContainer()
        let repository = ToDoRepository(persistentContainer: container)
        
        // 1) seed old
        let oldDate1 = Date(timeIntervalSince1970: 1)
        let oldDate2 = Date(timeIntervalSince1970: 2)
        let oldItems: [ToDoEntity] = [
            ToDoEntity(id: 1, title: "old A", details: nil, createdAt: oldDate1, isDone: false),
            ToDoEntity(id: 2, title: "old B", details: "x", createdAt: oldDate2, isDone: true)
        ]
        let seedExp = expectation(description: "seed old")
        repository.replaceAll(with: oldItems) { _ in seedExp.fulfill() }
        wait(for: [seedExp], timeout: 5)
        
        // 2) replace with new
        let newDate1 = Date(timeIntervalSince1970: 10)
        let newDate2 = Date(timeIntervalSince1970: 20)
        let newItems: [ToDoEntity] = [
            ToDoEntity(id: 1, title: "new A", details: nil, createdAt: newDate1, isDone: false),
            ToDoEntity(id: 2, title: "new B", details: nil, createdAt: newDate2, isDone: false)
        ]
        let replaceExp = expectation(description: "replace")
        repository.replaceAll(with: newItems) { _ in replaceExp.fulfill() }
        wait(for: [replaceExp], timeout: 5)
        
        // 3) fetch and assert
        let fetchExp = expectation(description: "fetch")
        repository.fetchAll { result in
            guard case let .success(items) = result else { XCTFail("fetch failed"); return }
            XCTAssertEqual(items.count, 2)
            XCTAssertEqual(items.map { $0.title }.sorted(), ["new A", "new B"])
            XCTAssertEqual(items.first?.createdAt, newDate2)
            fetchExp.fulfill()
        }
        wait(for: [fetchExp], timeout: 5)
    }
}
