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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "dd/MM/yy"
        return formatter
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
    private func map(_ entities: [ToDoEntity]) -> [ToDoViewModel] {
        entities.map { entity in
            let trimmed = entity.details?.trimmingCharacters(in: .whitespacesAndNewlines)
            return ToDoViewModel(
                id: entity.id,
                title: entity.title,
                subtitle: (trimmed?.isEmpty == false) ? trimmed : nil,
                meta: dateFormatter.string(from: entity.createdAt),
                isDone: entity.isDone
            )
        }
    }
    
    private func pluralizeTasks(_ count: Int) -> String {
        let lastDigit = count % 10
        let lastTwoDigits = count % 100
        
        if lastDigit == 1 && lastTwoDigits != 11 { return "\(count) Задача" }
        if (2...4).contains(lastDigit) && !(12...14)
            .contains(lastTwoDigits) { return "\(count) Задачи" }
        return "\(count) Задач"
    }
}

// MARK: - View → Presenter
extension ToDoListPresenter: ToDoListViewOutput {
    func viewDidLoad() { interactor.initialLoad() }
    
    func didTapAdd() {
        guard let present = viewController else { return }
        router.openCreate(from: present) { [weak self] title, details in
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
        guard
            let selectedEntity = lastItems.first(where: { $0.id == id }),
            let presentingViewController = viewController
        else { return }
        
        let trimmedDetails: String? = {
            let detailsCandidate = selectedEntity.details?.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            return (detailsCandidate?.isEmpty == false) ? detailsCandidate : nil
        }()
        
        let detailsModel = ToDoDetailsModel(
            id: selectedEntity.id,
            title: selectedEntity.title,
            details: trimmedDetails,
            dateText: dateFormatter.string(from: selectedEntity.createdAt),
            isDone: selectedEntity.isDone
        )
        
        router.openDetails(
            model: detailsModel,
            from: presentingViewController,
            onEdit: { [weak self] editedId in
                guard
                    let self,
                    let editableEntity = self.lastItems.first(where: { $0.id == editedId }),
                    let editPresenter = self.viewController
                else { return }
                
                self.router.openEdit(
                    id: editedId,
                    title: editableEntity.title,
                    details: editableEntity.details,
                    date: editableEntity.createdAt,
                    from: editPresenter
                ) { [weak self] newTitle, newDetails in
                    self?.interactor.update(id: editedId, title: newTitle, details: newDetails)
                }
            },
            onDelete: { [weak self] deletedId in
                self?.interactor.delete(id: deletedId)
            },
            onToggleDone: { [weak self] toggledId in
                self?.interactor.toggleDone(id: toggledId)
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
        view?.setCounterText(pluralizeTasks(items.count))
    }
    
    func didFail(error: Error) { view?.showError(error.localizedDescription) }
}
