//
//  ToDoListModuleBuilder.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import UIKit

// MARK: - ToDoListModuleBuilder
enum ToDoListModuleBuilder {
    
    // MARK: - Public Methods
    static func build() -> ToDoListViewController {
        let viewController = ToDoListViewController()
        let interactor = ToDoListInteractor()
        let router = ToDoListRouter()
        
        let presenter = ToDoListPresenter(
            view: viewController,
            interactor: interactor,
            router: router
        )
        
        viewController.output = presenter
        interactor.output = presenter
        
        viewController.title = "ToDo List"
        
        return viewController
    }
}
