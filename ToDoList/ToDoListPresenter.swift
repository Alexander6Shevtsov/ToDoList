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
    private var searchDebounceWorkItem: DispatchWorkItem?
    
    // MARK: - State
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Init
    init(view: ToDoListViewInput & UIViewController,
         interactor: ToDoListInteractorInput,
         router: ToDoListRouterInput) {
        self.view = view
        self.viewController = view
        self.interactor = interactor
        self.router = router
    }
    
    // MARK: - Mapping
    private func map(_ items: [ToDoEntity]) -> [ToDoViewModel] {
        items.map { entity in
            ToDoViewModel(
                id: entity.id,
                title: entity.title,
                subtitle: entity.details,
                meta: dateFormatter.string(from: entity.createdAt),
                isDone: entity.isDone
            )
        }
    }
}

// MARK: - View -> Presenter
extension ToDoListPresenter: ToDoListViewOutput {
    func viewDidLoad() { interactor.initialLoad() }
    func didTapAdd() { if let vc = viewController { router.openCreate(from: vc) } }
    func didToggleDone(id: Int) { interactor.toggleDone(id: id) }
    func didDelete(id: Int) { interactor.delete(id: id) }
    func didSearch(query: String) {
        searchDebounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.interactor.search(query: query)
        }
        searchDebounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }
    
    func didSelectItem(id: Int) {
        if let vc = viewController {
            router.openEdit(
                id: id,
                from: vc
            )
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

extension ToDoListPresenter {
    func handleCreateInput(title: String, details: String?) {
        interactor.create(title: title, details: details)
    }
    
    func handleUpdateInput(id: Int, title: String, details: String?) {
        interactor.update(id: id, title: title, details: details)
    }
}
