//
//  ToDoListPresenterTests.swift
//  ToDoListTests
//
//  Created by Alexander Shevtsov on 03.09.2025.
//

import XCTest
@testable import ToDoList

final class ToDoListPresenterTests: XCTestCase {
    
    // MARK: - Mocks
    // Экран списка — реализует ToDoListViewInput и сохраняет последние значения
    private final class MockViewController: UIViewController, ToDoListViewInput {
        
        // Что читают тесты
        var displayCallCount = 0
        var lastDisplayedItems: [ToDoViewModel]?
        var isLoading = false
        var lastError: String?
        var lastCounterText: String?
        
        // MARK: - ToDoListViewInput
        func display(items: [ToDoViewModel]) {
            displayCallCount += 1
            lastDisplayedItems = items
        }
        
        func setLoading(_ isLoading: Bool) {
            self.isLoading = isLoading
        }
        
        func showError(_ message: String) {
            lastError = message
        }
        
        func setCounterText(_ text: String) {
            lastCounterText = text
        }
    }
    
    private final class MockInteractor: ToDoListInteractorInput {
        var initialLoadCallCount = 0
        var fetchedAll = false
        var searchedQuery: String?
        var toggledId: Int?
        var deletedId: Int?
        var created: (title: String, details: String?)?
        var updated: (id: Int, title: String, details: String?)?
        
        func initialLoad() { initialLoadCallCount += 1 }
        func fetchAll() { fetchedAll = true }
        func search(query: String) { searchedQuery = query }
        func toggleDone(id: Int) { toggledId = id }
        func delete(id: Int) { deletedId = id }
        func create(title: String, details: String?) { created = (title, details) }
        func editTask(id: Int, title: String, details: String?) {
            updated = (id, title, details)
        }
    }
    
    private final class MockRouter: ToDoListRouterInput {
        var openCreateCallCount = 0
        var openEditCallCount = 0
        var openDetailsCallCount = 0
        
        var lastFrom: UIViewController?
        var lastEditId: Int?
        var lastDetailsModel: ToDoDetailsModel?
        
        // захваченное замыкание
        var capturedOnEdit: ((Int) -> Void)?
        
        func openCreate(
            from: UIViewController,
            onSave: @escaping (String, String?) -> Void
        ) {
            openCreateCallCount += 1
            lastFrom = from
        }
        
        func openEdit(
            id: Int,
            title: String,
            details: String?,
            date: Date,
            from: UIViewController,
            onSave: @escaping (String, String?) -> Void
        ) {
            openEditCallCount += 1
            lastEditId = id
            lastFrom = from
        }
        
        func openDetails(
            model: ToDoDetailsModel,
            from: UIViewController,
            onEdit: @escaping (Int) -> Void,
            onDelete: @escaping (Int) -> Void,
            onToggleDone: @escaping (Int) -> Void
        ) {
            openDetailsCallCount += 1
            lastDetailsModel = model
            lastFrom = from
            capturedOnEdit = onEdit
        }
    }
    
    // MARK: - SUT
    private func makeSUT() -> (
        presenter: ToDoListPresenter,
        view: MockViewController,
        interactor: MockInteractor,
        router: MockRouter
    ) {
        let viewController = MockViewController()
        let interactor = MockInteractor()
        let router = MockRouter()
        let presenter = ToDoListPresenter(
            view: viewController,
            interactor: interactor,
            router: router,
            searchDebounce: 0
        )
        return (presenter, viewController, interactor, router)
    }
    
    // MARK: - Tests
    func test_viewDidLoad_triggersInitialLoad() {
        let (presenter, _, interactor, _) = makeSUT()
        presenter.viewDidLoad()
        XCTAssertEqual(interactor.initialLoadCallCount, 1)
    }
    
    func test_didUpdate_callsViewDisplay() {
        let (presenter, view, _, _) = makeSUT()
        let now = Date()
        let items = [
            ToDoEntity(id: 1, title: "A", details: "d", createdAt: now, isDone: false),
            ToDoEntity(id: 2, title: "B", details: nil, createdAt: now, isDone: true)
        ]
        presenter.didUpdate(items: items)
        XCTAssertEqual(view.displayCallCount, 1)
        XCTAssertEqual(view.lastDisplayedItems?.count, 2)
    }
    
    func test_didTapAdd_routesToCreate() {
        let (presenter, view, _, router) = makeSUT()
        presenter.viewDidLoad()
        presenter.didTapAdd()
        XCTAssertEqual(router.openCreateCallCount, 1)
        XCTAssertTrue(router.lastFrom === view)
    }
    
    func test_didSelectItem_routesToEditViaDetailsSheet() {
        let (presenter, view, _, router) = makeSUT()
        presenter.viewDidLoad()
        
        let now = Date()
        presenter.didUpdate(items: [
            ToDoEntity(id: 42, title: "T", details: "D", createdAt: now, isDone: false)
        ])
        
        presenter.didSelectItem(id: 42)
        
        XCTAssertEqual(router.openDetailsCallCount, 1)
        XCTAssertNotNil(router.lastDetailsModel)
        XCTAssertTrue(router.lastFrom === view)
        
        router.capturedOnEdit?(42)
        
        XCTAssertEqual(router.openEditCallCount, 1)
        XCTAssertEqual(router.lastEditId, 42)
        XCTAssertTrue(router.lastFrom === view)
    }
    
    func test_toggleDeleteSearch_forwardToInteractor() {
        let (presenter, _, interactor, _) = makeSUT()
        presenter.didToggleDone(id: 7)
        presenter.didDelete(id: 9)
        presenter.didSearch(query: "abcd")
        XCTAssertEqual(interactor.toggledId, 7)
        XCTAssertEqual(interactor.deletedId, 9)
        XCTAssertEqual(interactor.searchedQuery, "abcd")
    }
    
    func test_loadingAndError_forwardToView() {
        let (presenter, view, _, _) = makeSUT()
        presenter.didChangeLoading(true)
        XCTAssertEqual(view.isLoading, true)
        presenter.didChangeLoading(false)
        XCTAssertEqual(view.isLoading, false)
        
        presenter.didFail(error: NSError(domain: "x", code: 1))
        XCTAssertNotNil(view.lastError)
    }
}
