//
//  ToDoListPresenter.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 29.08.2025.
//

import UIKit

final class ToDoListPresenter {
    
    // MARK: - Dependencies
    private weak var view: ToDoListViewInput?
    private weak var viewController: UIViewController?
    private let interactor: ToDoListInteractorInput
    private let router: ToDoListRouterInput
    private let searchDebounce: TimeInterval
    private var searchDebounceWorkItem: DispatchWorkItem?
    
    // MARK: - State
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    
    // MARK: - Init
    init(
        view: ToDoListViewInput & UIViewController,
        interactor: ToDoListInteractorInput,
        router: ToDoListRouterInput,
        searchDebounce: TimeInterval = 0.3
    ) {
        self.view = view
        self.viewController = view
        self.interactor = interactor
        self.router = router
        self.searchDebounce = searchDebounce
    }
    
    // MARK: - Mapping
    private func map(_ items: [ToDoEntity]) -> [ToDoViewModel] {
        items.map { entity in
            let trimmedDetails = entity.details?.trimmingCharacters(in: .whitespacesAndNewlines)
            let body = (trimmedDetails?.isEmpty == false) ? trimmedDetails : nil
            
            return ToDoViewModel(
                id: entity.id,
                title: entity.title,
                subtitle: body,
                meta: dateFormatter.string(from: entity.createdAt),
                isDone: entity.isDone
            )
        }
    }
}

// MARK: - View -> Presenter
extension ToDoListPresenter: ToDoListViewOutput {
    func viewDidLoad() { interactor.initialLoad() }
    
    func didTapAdd() {
        if let vc = viewController { router.openCreate(from: vc) }
    }
    
    func didToggleDone(id: Int) { interactor.toggleDone(id: id) }
    
    func didDelete(id: Int) { interactor.delete(id: id) }
    
    func didSearch(query: String) {
        searchDebounceWorkItem?.cancel()
        if searchDebounce <= 0 {
            interactor.search(query: query)
            return
        }
        let work = DispatchWorkItem { [weak self] in
            self?.interactor.search(query: query)
        }
        searchDebounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + searchDebounce, execute: work)
    }
    
    func didSelectItem(id: Int) {
        if let vc = viewController {
            router.openEdit(id: id, from: vc)
        }
    }
}

// MARK: - Interactor → Presenter
extension ToDoListPresenter: ToDoListInteractorOutput {
    func didChangeLoading(_ isLoading: Bool) {
        view?.setLoading(isLoading)
    }
    
    func didUpdate(items: [ToDoEntity]) {
        view?.display(items: map(items))
    }
    
    func didFail(error: Error) {
        view?.showError(error.localizedDescription)
    }
}

// MARK: - Inputs from Create/Edit
extension ToDoListPresenter {
    func handleCreateInput(title: String, details: String?) {
        interactor.create(title: title, details: details)
    }
    
    func handleUpdateInput(id: Int, title: String, details: String?) {
        interactor.update(id: id, title: title, details: details)
    }
}
