//
//  ToDoListPresenter.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 29.08.2025.
//

import UIKit

// MARK: - DTO для экрана деталей
struct ToDoDetailsModel {
    let id: Int
    let title: String
    let details: String?
    let dateText: String
    let isDone: Bool
}

final class ToDoListPresenter {
    // MARK: Dependencies
    private weak var view: ToDoListViewInput?
    private weak var viewController: UIViewController?
    private let interactor: ToDoListInteractorInput
    private let router: ToDoListRouterInput
    private let searchDebounce: TimeInterval
    private var searchDebounceWorkItem: DispatchWorkItem?
    
    // MARK: State
    private var lastItems: [ToDoEntity] = []
    
    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "dd/MM/yy"
        return f
    }()
    
    // MARK: Init
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
    
    // MARK: Mapping
    private func map(_ items: [ToDoEntity]) -> [ToDoViewModel] {
        items.map { e in
            let trimmed = e.details?.trimmingCharacters(in: .whitespacesAndNewlines)
            return ToDoViewModel(
                id: e.id,
                title: e.title,
                subtitle: (trimmed?.isEmpty == false) ? trimmed : nil,
                meta: dateFormatter.string(from: e.createdAt),
                isDone: e.isDone
            )
        }
    }
}

// MARK: - View → Presenter
extension ToDoListPresenter: ToDoListViewOutput {
    func viewDidLoad() { interactor.initialLoad() }
    
    func didTapAdd() {
        guard let vc = viewController else { return }
        router.openCreate(from: vc) { [weak self] title, details in
            self?.interactor.create(title: title, details: details)
        }
    }
    
    func didToggleDone(id: Int) { interactor.toggleDone(id: id) }
    
    func didDelete(id: Int) { interactor.delete(id: id) }
    
    func didSearch(query: String) {
        searchDebounceWorkItem?.cancel()
        if searchDebounce <= 0 { interactor.search(query: query); return }
        let work = DispatchWorkItem { [weak self] in self?.interactor.search(query: query) }
        searchDebounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + searchDebounce, execute: work)
    }
    
    func didSelectItem(id: Int) {
        guard let entity = lastItems.first(where: { $0.id == id }),
              let vc = viewController else { return }
        
        let model = ToDoDetailsModel(
            id: entity.id,
            title: entity.title,
            details: {
                let t = entity.details?.trimmingCharacters(in: .whitespacesAndNewlines)
                return (t?.isEmpty == false) ? t : nil
            }(),
            dateText: dateFormatter.string(from: entity.createdAt),
            isDone: entity.isDone
        )
        
        router.openDetails(
            model: model,
            from: vc,
            onEdit: { [weak self] (id: Int) in
                guard let self,
                      let ent = self.lastItems.first(where: { $0.id == id }),
                      let vc = self.viewController else { return }
                self.router.openEdit(
                    id: id,
                    title: ent.title,
                    details: ent.details,
                    date: ent.createdAt,
                    from: vc
                ) { [weak self] newTitle, newDetails in
                    self?.interactor.update(id: id, title: newTitle, details: newDetails)
                }
            },
            onDelete: { [weak self] (id: Int) in
                self?.interactor.delete(id: id)
            },
            onToggleDone: { [weak self] (id: Int) in
                self?.interactor.toggleDone(id: id)
            }
        )
        
    }
}

// MARK: - Interactor → Presenter
extension ToDoListPresenter: ToDoListInteractorOutput {
    func didChangeLoading(_ isLoading: Bool) { view?.setLoading(isLoading) }
    
    func didUpdate(items: [ToDoEntity]) {
        lastItems = items
        view?.display(items: map(items))
    }
    
    func didFail(error: Error) { view?.showError(error.localizedDescription) }
}
