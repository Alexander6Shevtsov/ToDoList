//
//  ToDoListInteractor.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import Foundation

final class ToDoListInteractor: ToDoListInteractorInput {
    weak var output: ToDoListInteractorOutput?
    
    // Фоновая очередь для операций
    private let operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "todo.interactor.queue"
        operationQueue.qualityOfService = .userInitiated
        return operationQueue
    }()
    
    // Временное хранилище
    private var storage: [ToDoEntity] = []
    
    // MARK: ToDoListInteractorInput
    
    func initialLoad() {
        output?.didChangeLoading(true)
        operationQueue.addOperation { [weak self] in
            guard let self else { return }
            
            // Имитация первичной загрузки. Позже: импорт из API → Core Data.
            Thread.sleep(forTimeInterval: 0.1) // пауза, чтобы проверить индикатор
            
            self.notifyUpdate()
            self.notifyLoading(false)
        }
    }
    
    func fetchAll() {
        output?.didChangeLoading(true)
        operationQueue.addOperation { [weak self] in
            self?.notifyUpdate()
            self?.notifyLoading(false)
        }
    }
    
    func search(query: String) {
        operationQueue.addOperation { [weak self] in
            guard let self else { return }
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let result: [ToDoEntity]
            if trimmed.isEmpty {
                result = self.storage
            } else {
                result = self.storage.filter {
                    $0.title.lowercased().contains(trimmed) || (
                        $0.details?.lowercased().contains(trimmed) ?? false
                    )
                }
            }
            self.notify(items: result)
        }
    }
    
    func toggleDone(id: Int) {
        operationQueue.addOperation { [weak self] in
            guard let self else { return }
            if let idx = self.storage.firstIndex(where: { $0.id == id }) {
                var item = self.storage[idx]
                item = ToDoEntity(
                    id: item.id,
                    title: item.title,
                    details: item.details,
                    createdAt: item.createdAt,
                    isDone: !item.isDone
                )
                self.storage[idx] = item
            }
            self.notifyUpdate()
        }
    }
    
    func delete(id: Int) {
        operationQueue.addOperation { [weak self] in
            guard let self else { return }
            self.storage.removeAll { $0.id == id }
            self.notifyUpdate()
        }
    }
    
    // MARK: - Helpers
    
    private func notifyUpdate() {
        let snapshot = storage
        DispatchQueue.main.async { [weak self] in
            self?.output?.didUpdate(items: snapshot)
        }
    }
    
    private func notify(items: [ToDoEntity]) {
        DispatchQueue.main.async { [weak self] in
            self?.output?.didUpdate(items: items)
        }
    }
    
    private func notifyLoading(_ isLoading: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.output?.didChangeLoading(isLoading)
        }
    }
}
