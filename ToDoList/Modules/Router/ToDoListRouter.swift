//
//  ToDoListRouter.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 30.08.2025.
//

import UIKit

final class ToDoListRouter: ToDoListRouterInput {
    
    private lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ru_RU")
        formatter.calendar = .init(identifier: .gregorian)
        formatter.dateFormat = "dd/MM/yy"
        return formatter
    }()
    
    func openCreate(
        from: UIViewController,
        onSave: @escaping (String, String?) -> Void
    ) {
        let editor = TaskEditorViewController(
            mode: .create,
            title: nil,
            details: nil,
            dateText: dateFormatter.string(from: Date())
        )
        editor.onSave = onSave
        from.present(UINavigationController(rootViewController: editor), animated: true)
    }
    
    // MARK: - Public Methods
    func openEdit(
        id: Int,
        title: String,
        details: String?,
        date: Date,
        from presenterViewController: UIViewController,
        onSave: @escaping (String, String?) -> Void
    ) {
        let editor = TaskEditorViewController(
            mode: .edit(id: id),
            title: title,
            details: details,
            dateText: dateFormatter.string(from: date)
        )
        editor.onSave = onSave
        presenterViewController.present(
            UINavigationController(rootViewController: editor),
            animated: true
        )
    }
    
    func openDetails(
        model: ToDoDetailsModel,
        from presenterViewController: UIViewController,
        onEdit: @escaping (Int) -> Void,
        onDelete: @escaping (Int) -> Void,
        onToggleDone: @escaping (Int) -> Void
    ) {
        let detailsSheet = ToDoDetailsSheetViewController(model: model)
        detailsSheet.onEdit = { onEdit(model.id) }
        detailsSheet.onDelete = { onDelete(model.id) }
        detailsSheet.onToggleDone = { onToggleDone(model.id) }
        detailsSheet.modalPresentationStyle = .automatic
        detailsSheet.modalTransitionStyle = .coverVertical
        presenterViewController.present(detailsSheet, animated: true)
    }
}
