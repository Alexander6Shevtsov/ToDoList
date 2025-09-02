//
//  ToDoListModuleBuilder.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import UIKit

enum ToDoListModuleBuilder {
    static func build() -> UIViewController {
        let viewController = ToDoListViewController()
        let repository = ToDoRepository()
        let interactor = ToDoListInteractor(repository: repository)
        let router = ToDoListRouter()
        let presenter = ToDoListPresenter(
            view: viewController,
            interactor: interactor,
            router: router
        )
        
        interactor.output = presenter
        viewController.output = presenter
        
        return viewController
    }
}
