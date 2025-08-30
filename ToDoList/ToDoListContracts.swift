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
}

protocol ToDoListViewOutput: AnyObject {
    func viewDidLoad()
    func didTapAdd()
    func didSelectItem(id: Int)
    func didToggleDone(id: Int)
    func didDelete(id: Int)
    func didSearch(qwerty: String)
}

// MARK: Interactor
protocol ToDoListInteractorInput: AnyObject {
    func initialLoad()
    func fetchAll()
    func search(qwerty: String)
    func toggleDone(id: Int)
    func delete(id: Int)
}

protocol ToDoListInteractorOutput: AnyObject {
    func didUpdate(items: [ToDoEntity])
    func didFail(error: Error)
    func didChangeLoading(_ isLoading: Bool)
}

// MARK: - Router
protocol ToDoListRouterInput: AnyObject {
    func openCreate(from: UIViewController)
    func openEdit(id: Int, from: UIViewController)
}

// MARK: - черновые модели
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
