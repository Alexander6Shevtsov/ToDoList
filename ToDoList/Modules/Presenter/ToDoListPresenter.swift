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
    // MARK: - Dependencies
    private weak var view: ToDoListViewInput?
    private weak var viewController: UIViewController?
    private let interactor: ToDoListInteractorInput
    private let router: ToDoListRouterInput
    private let searchDebounce: TimeInterval
    private var searchDebounceWorkItem: DispatchWorkItem?

    // MARK: - State
    private var lastItems: [ToDoEntity] = [] // [CHANGE] храним список для быстрого доступа по id

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
        if searchDebounce <= 0 { interactor.search(query: query); return }
        let work = DispatchWorkItem { [weak self] in self?.interactor.search(query: query) }
        searchDebounceWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + searchDebounce, execute: work)
    }

    func didSelectItem(id: Int) {
        guard let entity = lastItems.first(where: { $0.id == id }),
              let vc = viewController else { return }

        // [CHANGE] Формируем модель для деталей
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

        // [CHANGE] Открываем экран деталей. Колбэки: редактирование и удаление.
        router.openDetails(
            model: model,
            from: vc,
            onEdit: { [weak self] id in
                guard let self, let vc = self.viewController else { return }
                self.router.openEdit(id: id, from: vc)
            },
            onDelete: { [weak self] id in
                self?.interactor.delete(id: id)
            },
            onToggleDone: { [weak self] id in
                self?.interactor.toggleDone(id: id)
            }
        )
    }
}

// MARK: - Interactor → Presenter
extension ToDoListPresenter: ToDoListInteractorOutput {
    func didChangeLoading(_ isLoading: Bool) { view?.setLoading(isLoading) }

    func didUpdate(items: [ToDoEntity]) {
        lastItems = items // [CHANGE]
        view?.display(items: map(items))
    }

    func didFail(error: Error) { view?.showError(error.localizedDescription) }
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
