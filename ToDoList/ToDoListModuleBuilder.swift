//
//  ToDoListModuleBuilder.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 01.09.2025.
//

import UIKit

enum ToDoListModuleBuilder {
    static func build() -> UIViewController {
        let view = ToDoListViewController()
        let interactor = ToDoListInteractor()
        let router = ToDoListRouter()
        let presenter = ToDoListPresenter(
            view: view,
            interactor: interactor,
            router: router
        )
        
        interactor.output = presenter
        view.output = presenter
        
        return view
    }
}
