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
    private final class MockViewController: UIViewController, ToDoListViewInput {
        var displayed: [ToDoViewModel] = []
        var isLoading: Bool?
        var lastError: String?
        var displayCallCount = 0
        var lastDisplayedItems: [ToDoViewModel]?
        
        func display(items: [ToDoViewModel]) {
            displayCallCount += 1
            lastDisplayedItems = items
        }
        func setLoading(_ isLoading: Bool) { self.isLoading = isLoading }
        func showError(_ message: String) { lastError = message }
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
        func update(id: Int, title: String, details: String?) {
            updated = (id, title, details)
        }
    }
    
    final class MockRouter: ToDoListRouterInput {
        // счётчики + последние параметры
        var openCreateCallCount = 0
        var openEditCallCount = 0
        var openDetailsCallCount = 0
        var lastFrom: UIViewController?
        var lastEditId: Int?
        var lastDetailsModel: ToDoDetailsModel?
        // захват колбэка "Редактировать" из листа
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
        ToDoListPresenter,
        MockViewController,
        MockInteractor,
        MockRouter
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
        let (presenter, viewController, _, _) = makeSUT()
        let currentDate = Date()
        let items = [
            ToDoEntity(id: 1, title: "A", details: "d", createdAt: currentDate, isDone: false),
            ToDoEntity(id: 2, title: "B", details: nil, createdAt: currentDate, isDone: true)
        ]
        presenter.didUpdate(items: items)
        XCTAssertEqual(viewController.displayCallCount, 1)
        XCTAssertEqual(viewController.lastDisplayedItems?.count, 2)
    }
    
    func test_didTapAdd_routesToCreate() {
        let (presenter, viewController, _, router) = makeSUT()
        presenter.viewDidLoad()
        presenter.didTapAdd()
        XCTAssertEqual(router.openCreateCallCount, 1)
        XCTAssertTrue(router.lastFrom === viewController)
    }
    
    func test_didSelectItem_routesToEdit() {
        let (presenter, viewController, _, router) = makeSUT()
        presenter.viewDidLoad()

        // GIVEN: презентер знает про выбранную задачу
        let now = Date()
        presenter.didUpdate(items: [
            ToDoEntity(id: 42, title: "T", details: "D", createdAt: now, isDone: false)
        ])

        // WHEN: пользователь выбирает задачу
        presenter.didSelectItem(id: 42)

        // THEN: открыт лист деталей
        XCTAssertEqual(router.openDetailsCallCount, 1)
        XCTAssertNotNil(router.lastDetailsModel)
        XCTAssertTrue(router.lastFrom === viewController)

        // AND: по нажатию "Редактировать" открывается редактор
        router.capturedOnEdit?(42)
        XCTAssertEqual(router.openEditCallCount, 1)
        XCTAssertEqual(router.lastEditId, 42)
        XCTAssertTrue(router.lastFrom === viewController)
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
        let (presenter, viewController, _, _) = makeSUT()
        presenter.didChangeLoading(true)
        XCTAssertEqual(viewController.isLoading, true)
        presenter.didChangeLoading(false)
        XCTAssertEqual(viewController.isLoading, false)
        
        presenter.didFail(error: NSError(domain: "x", code: 1))
        XCTAssertNotNil(viewController.lastError)
    }
}
