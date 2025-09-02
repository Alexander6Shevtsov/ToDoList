//
//  ToDoListInteractor.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import Foundation

final class ToDoListInteractor: ToDoListInteractorInput {
    
    weak var output: ToDoListInteractorOutput?
    
    private let apiClient: ToDosAPIClient
    private let userDefaults: UserDefaults
    private let repository: ToDoRepository
    private let seededKey = "todo.seeded"
    
    // Фоновая очередь
    private let operationQueue: OperationQueue = {
        let operationQueue = OperationQueue()
        operationQueue.name = "todo.interactor.queue"
        operationQueue.qualityOfService = .userInitiated
        return operationQueue
    }()
    
    // MARK: - Init
    init(
        apiClient: ToDosAPIClient = ToDosAPIClient(),
        userDefaults: UserDefaults = .standard,
        repository: ToDoRepository = ToDoRepository()
    ) {
        self.apiClient = apiClient
        self.userDefaults = userDefaults
        self.repository = repository
    }
    
    // MARK: - ToDoListInteractorInput
    func initialLoad() {
        output?.didChangeLoading(true)
        operationQueue.addOperation { [weak self] in
            guard let self else { return }
            
            self.repository.fetchAll { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let items) where items.isEmpty == false:
                    self.notify(items: items)
                    self.notifyLoading(false)
                    
                case .success:
                    self.apiClient.fetchAll { [weak self] apiResult in
                        guard let self else { return }
                        switch apiResult {
                        case .success(let entities):
                            self.repository.upsert(entities) { [weak self] upsertResult in
                                guard let self else { return }
                                switch upsertResult {
                                case .success:
                                    self.userDefaults.set(true, forKey: self.seededKey)
                                    self.repository.fetchAll { [weak self] fetch2 in
                                        guard let self else { return }
                                        switch fetch2 {
                                        case .success(let items2):
                                            self.notify(items: items2)
                                        case .failure(let error):
                                            self.notifyError(error)
                                        }
                                        self.notifyLoading(false)
                                    }
                                case .failure(let error):
                                    self.notifyError(error)
                                    self.notifyLoading(false)
                                }
                            }
                        case .failure(let error):
                            self.notifyError(error)
                            self.notifyLoading(false)
                        }
                    }
                    
                case .failure(let error):
                    self.notifyError(error)
                    self.notifyLoading(false)
                }
            }
        }
    }
    
    func fetchAll() {
        output?.didChangeLoading(true)
        operationQueue.addOperation { [weak self] in
            self?.repository.fetchAll { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let items): self.notify(items: items)
                case .failure(let error): self.notifyError(error)
                }
                self.notifyLoading(false)
            }
        }
    }
    
    func search(query: String) {
        operationQueue.addOperation { [weak self] in
            self?.repository.search(query: query) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let items): self.notify(items: items)
                case .failure(let error): self.notifyError(error)
                }
            }
        }
    }
    
    func toggleDone(id: Int) {
        operationQueue.addOperation { [weak self] in
            self?.repository.toggleDone(id: id) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let items): self.notify(items: items)
                case .failure(let error): self.notifyError(error)
                }
            }
        }
    }
    
    func delete(id: Int) {
        operationQueue.addOperation { [weak self] in
            self?.repository.delete(id: id) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let items): self.notify(items: items)
                case .failure(let error): self.notifyError(error)
                }
            }
        }
    }
    
    // MARK: - Notify
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
    
    private func notifyError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.output?.didFail(error: error)
        }
    }
}
