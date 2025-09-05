//
//  ToDoListRouter.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 30.08.2025.
//

import UIKit

final class ToDoListRouter: ToDoListRouterInput {

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.calendar = .init(identifier: .gregorian)
        f.dateFormat = "dd/MM/yy"
        return f
    }()

    func openCreate(from: UIViewController, onSave: @escaping (String, String?) -> Void) {
        let vc = TaskEditorViewController(
            mode: .create,
            title: nil,
            details: nil,
            dateText: dateFormatter.string(from: Date())
        )
        vc.onSave = onSave
        from.present(UINavigationController(rootViewController: vc), animated: true)
    }

    func openEdit(id: Int, title: String, details: String?, date: Date, from: UIViewController, onSave: @escaping (String, String?) -> Void) {
        let vc = TaskEditorViewController(
            mode: .edit(id: id),
            title: title,
            details: details,
            dateText: dateFormatter.string(from: date)
        )
        vc.onSave = onSave
        from.present(UINavigationController(rootViewController: vc), animated: true)
    }

    func openDetails(
        model: ToDoDetailsModel,
        from: UIViewController,
        onEdit: @escaping (Int) -> Void,
        onDelete: @escaping (Int) -> Void,
        onToggleDone: @escaping (Int) -> Void
    ) {
        let vc = ToDoDetailsSheetViewController(model: model)
        vc.onEdit = { onEdit(model.id) }
        vc.onDelete = { onDelete(model.id) }
        vc.onToggleDone = { onToggleDone(model.id) }
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        from.present(vc, animated: true)
    }
}
