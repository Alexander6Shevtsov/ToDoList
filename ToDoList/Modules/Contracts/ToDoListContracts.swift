//
//  ToDoListContracts.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 29.08.2025.
//

import UIKit

// MARK: - View
protocol ToDoListViewInput: AnyObject {
    func display(items: [ToDoViewModel])
    func setLoading(_ isLoading: Bool)
    func showError(_ message: String)
    func setCounterText(_ text: String)
}

protocol ToDoListViewOutput: AnyObject {
    func viewDidLoad()
    func didTapAdd()
    func didSelectItem(id: Int)
    func didToggleDone(id: Int)
    func didDelete(id: Int)
    func didSearch(query: String)
}

// MARK: - Interactor
protocol ToDoListInteractorInput: AnyObject {
    func initialLoad()
    func fetchAll()
    func search(query: String)
    func toggleDone(id: Int)
    func delete(id: Int)
    func create(title: String, details: String?)
    func editTask(id: Int, title: String, details: String?)
}

protocol ToDoListInteractorOutput: AnyObject {
    func didUpdate(items: [ToDoEntity])
    func didFail(error: Error)
    func didChangeLoading(_ isLoading: Bool)
}

extension ToDoListInteractorInput {
    func create(title: String, details: String?) {}
    func editTask(id: Int, title: String, details: String?) {}
}

// MARK: - Router
protocol ToDoListRouterInput: AnyObject {
    func openCreate(
        from: UIViewController,
        onSave: @escaping (_ title: String, _ details: String?) -> Void
    )
    
    func openEdit(
        id: Int,
        title: String,
        details: String?,
        date: Date,
        from: UIViewController,
        onSave: @escaping (_ title: String, _ details: String?) -> Void
    )
    
    func openDetails(
        model: ToDoDetailsModel,
        from: UIViewController,
        onEdit: @escaping (Int) -> Void,
        onDelete: @escaping (Int) -> Void,
        onToggleDone: @escaping (Int) -> Void
    )
}

// MARK: - Models
struct ToDoEntity: Equatable {
    let id: Int
    let title: String
    let details: String?
    let createdAt: Date
    let isDone: Bool
}

struct ToDoViewModel: Equatable {
    let id: Int
    let title: String
    let subtitle: String?
    let meta: String
    let isDone: Bool
}
