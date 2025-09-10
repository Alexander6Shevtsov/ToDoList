//
//  ToDoListModuleBuilder.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import UIKit
import CoreData

// MARK: - ToDoListModuleBuilder
enum ToDoListModuleBuilder {
    
    static func build() -> UIViewController {
        let container = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer
        
        let repository = ToDoRepository(persistentContainer: container)
        
        // Слои VIPER
        let interactor = ToDoListInteractor(repository: repository)
        let router = ToDoListRouter()
        let viewController = ToDoListViewController()
        let presenter = ToDoListPresenter(
            view: viewController,
            interactor: interactor,
            router: router
        )
        
        // Связи
        interactor.output = presenter
        viewController.output = presenter
        
        return viewController
    }
}
