//
//  ToDoListRouter.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 30.08.2025.
//

import UIKit

final class ToDoListRouter: ToDoListRouterInput {
    func openCreate(from: UIViewController) {
        let alert = UIAlertController(
            title: "Create",
            message: "Stub screen",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        from.present(alert, animated: true)
    }
    
    func openEdit(id: Int, from: UIViewController) {
        let alert = UIAlertController(
            title: "Edit",
            message: "Stub for id \(id)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        from.present(alert, animated: true)
    }
}
