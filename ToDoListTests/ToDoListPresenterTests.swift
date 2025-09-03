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

        func display(items: [ToDoViewModel]) { displayed = items }
        func setLoading(_ isLoading: Bool) { self.isLoading = isLoading }
        func showError(_ message: String) { lastError = message }
    }

    private final class MockInteractor: ToDoListInteractorInput {
        var didCallInitialLoad = false
        var fetchedAll = false
        var searchedQuery: String?
        var toggledId: Int?
        var deletedId: Int?
        var created: (title: String, details: String?)?
        var updated: (id: Int, title: String, details: String?)?

        func initialLoad() { didCallInitialLoad = true }
        func fetchAll() { fetchedAll = true }
        func search(query: String) { searchedQuery = query }
        func toggleDone(id: Int) { toggledId = id }
        func delete(id: Int) { deletedId = id }
        func create(title: String, details: String?) { created = (title, details) }
        func update(id: Int, title: String, details: String?) { updated = (id, title, details) }
    }

    private final class MockRouter: ToDoListRouterInput {
        var didOpenCreateFrom: UIViewController?
        var didOpenEdit: (id: Int, from: UIViewController)?

        func openCreate(from: UIViewController) { didOpenCreateFrom = from }
        func openEdit(id: Int, from: UIViewController) { didOpenEdit = (id, from) }
    }

    // MARK: - SUT

    private func makeSUT() -> (ToDoListPresenter, MockViewController, MockInteractor, MockRouter) {
        let view = MockViewController()
        let interactor = MockInteractor()
        let router = MockRouter()
        let presenter = ToDoListPresenter(view: view, interactor: interactor, router: router)
        return (presenter, view, interactor, router)
    }

    // MARK: - Tests

    func test_viewDidLoad_triggersInitialLoad() {
        let (sut, _, interactor, _) = makeSUT()
        sut.viewDidLoad()
        XCTAssertTrue(interactor.didCallInitialLoad)
    }

    func test_didTapAdd_routesToCreate() {
        let (sut, view, _, router) = makeSUT()
        sut.didTapAdd()
        XCTAssertTrue(router.didOpenCreateFrom === view)
    }

    func test_didSelectItem_routesToEditWithId() {
        let (sut, view, _, router) = makeSUT()
        sut.didSelectItem(id: 42)
        XCTAssertEqual(router.didOpenEdit?.id, 42)
        XCTAssertTrue(router.didOpenEdit?.from === view)
    }

    func test_toggleDeleteSearch_forwardToInteractor() {
        let (sut, _, interactor, _) = makeSUT()
        sut.didToggleDone(id: 7)
        sut.didDelete(id: 9)
        sut.didSearch(query: "abc")
        XCTAssertEqual(interactor.toggledId, 7)
        XCTAssertEqual(interactor.deletedId, 9)
        XCTAssertEqual(interactor.searchedQuery, "abc")
    }

    func test_interactorOutput_updatesViewModels() {
        let (sut, view, _, _) = makeSUT()
        // Симулируем коллбек из Interactor
        let items = [
            ToDoEntity(id: 1, title: "T1", details: "D1", createdAt: Date(), isDone: false),
            ToDoEntity(id: 2, title: "T2", details: nil, createdAt: Date(), isDone: true)
        ]
        sut.didUpdate(items: items)

        XCTAssertEqual(view.displayed.count, 2)
        XCTAssertEqual(view.displayed[0].id, 1)
        XCTAssertEqual(view.displayed[0].title, "T1")
        XCTAssertEqual(view.displayed[0].subtitle, "D1")
        XCTAssertFalse(view.displayed[0].isDone)
        XCTAssertEqual(view.displayed[1].id, 2)
        XCTAssertTrue(view.displayed[1].isDone)
        XCTAssertFalse(view.displayed[1].meta.isEmpty) // meta форматируется датой
    }

    func test_loadingAndError_forwardToView() {
        let (sut, view, _, _) = makeSUT()
        sut.didChangeLoading(true)
        XCTAssertEqual(view.isLoading, true)
        sut.didChangeLoading(false)
        XCTAssertEqual(view.isLoading, false)

        sut.didFail(error: NSError(domain: "x", code: 1))
        XCTAssertNotNil(view.lastError)
    }
}
