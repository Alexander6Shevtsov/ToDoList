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
    private let interactor: ToDoListInteractorInput
    private let router: ToDoListRouterInput
    
    // MARK: - State
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: - Init
    init(
        view: ToDoListViewInput,
        interactor: ToDoListInteractorInput,
        router: ToDoListRouterInput
    ) {
        self.view = view
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
    func viewDidLoad() {
        view?.setLoading(true)
        interactor.initialLoad()
    }
    
    func didTapAdd() {
        if let vc = view as? UIViewController {
            router.openCreate(from: vc)
        }
    }
    
    func didSelectItem(id: Int) {
        if let vc = view as? UIViewController {
            router.openEdit(id: id, from: vc)
        }
    }

    func didToggleDone(id: Int) {
        interactor.toggleDone(id: id)
    }

    func didDelete(id: Int) {
        interactor.delete(id: id)
    }

    func didSearch(qwerty: String) {
        interactor.search(qwerty: qwerty)
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
