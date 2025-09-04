//
//  ToDoListRouter.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 30.08.2025.
//

import UIKit

final class ToDoListRouter: ToDoListRouterInput {
    
    weak var presenter: ToDoListPresenter?
    
    func openCreate(from: UIViewController) {
        presentForm(
            from: from,
            title: "New ToDo",
            initialTitle: nil,
            initialDetails: nil
        ) { [weak self] title, details in
            self?.presenter?.handleCreateInput(title: title, details: details)
        }
    }
    
    func openEdit(id: Int, from: UIViewController) {
        presentForm(
            from: from,
            title: "Edit ToDo",
            initialTitle: nil,
            initialDetails: nil
        ) { [weak self] title, details in
            self?.presenter?.handleUpdateInput(id: id, title: title, details: details)
        }
    }
    
    // MARK: - Private
    private func presentForm(
        from: UIViewController,
        title: String,
        initialTitle: String?,
        initialDetails: String?,
        onSave: @escaping (_ title: String, _ details: String?) -> Void
    ) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.overrideUserInterfaceStyle = .dark
        alert.view.tintColor = AppColor.yellow
        
        alert.addTextField { tf in
            tf.layer.masksToBounds = true
            tf.borderStyle = .none
            tf.autocapitalizationType = .sentences
            tf.placeholder = "Title"
            tf.text = initialTitle
            tf.clearButtonMode = .whileEditing
            tf.keyboardAppearance = .dark
            tf.textColor = AppColor.white
            tf.tintColor = AppColor.yellow
            tf.backgroundColor = AppColor.gray
            tf.layer.cornerRadius = 8
            tf.attributedPlaceholder = NSAttributedString(
                string: "Title",
                attributes: [.foregroundColor: UIColor.secondaryLabel]
            )
        }
        alert.addTextField { tf in
            tf.placeholder = "Details (optional)"
            tf.text = initialDetails
            tf.clearButtonMode = .whileEditing
            tf.keyboardAppearance = .dark
            tf.textColor = AppColor.white
            tf.tintColor = AppColor.yellow
            tf.backgroundColor = AppColor.gray
            tf.layer.cornerRadius = 8
            tf.attributedPlaceholder = NSAttributedString(
                string: "Details (optional)",
                attributes: [.foregroundColor: UIColor.secondaryLabel]
            )
        }
        
        let save = UIAlertAction(title: "Save", style: .default) { _ in
            let titleText = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let detailsText = alert.textFields?.last?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !titleText.isEmpty else { return }
            onSave(titleText, detailsText?.isEmpty == true ? nil : detailsText)
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(save)
        from.present(alert, animated: true)
    }
}
