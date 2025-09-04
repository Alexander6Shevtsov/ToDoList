//
//  ToDoListInteractor.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import Foundation

final class ToDoListInteractor: ToDoListInteractorInput {
    
    weak var output: ToDoListInteractorOutput?
    
    // MARK: - First-launch seed flag
    private let seedFlagKey = "seededOnce"
    private var hasSeeded: Bool {
        get { userDefaults.bool(forKey: seedFlagKey) }
        set { userDefaults.set(newValue, forKey: seedFlagKey) }
    }
    
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
        if !hasSeeded && repository.isStoreEmpty() {
            apiClient.fetchAll { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let items):
                    self.repository.replaceAll(with: items) { [weak self] _ in
                        guard let self else { return }
                        self.hasSeeded = true
                        self.fetchAll()
                    }
                case .failure(let error):
                    self.output?.didFail(error: error)
                    self.fetchAll()
                }
            }
            return
        }
        fetchAll()
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
    
    func create(title: String, details: String?) {
        operationQueue.addOperation { [weak self] in
            self?.repository.create(title: title, details: details) { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let items): self.notify(items: items)
                case .failure(let error): self.notifyError(error)
                }
            }
        }
    }
    
    func update(id: Int, title: String, details: String?) {
        operationQueue.addOperation { [weak self] in
            self?.repository.update(
                id: id,
                title: title,
                details: details
            ) { [weak self] result in
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
