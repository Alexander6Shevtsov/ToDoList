//
//  ThemeConfigurator.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 03.09.2025.
//

import UIKit

enum ThemeConfigurator {
    static func apply() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = AppColor.black
        nav.titleTextAttributes = [.foregroundColor: AppColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: AppColor.white]
        
        let bar = UINavigationBar.appearance()
        bar.standardAppearance = nav
        bar.scrollEdgeAppearance = nav
        bar.compactAppearance = nav
        bar.tintColor = AppColor.yellow
        
        // Таблица и ячейки
        UITableView.appearance().backgroundColor = AppColor.black
        UITableViewCell.appearance().backgroundColor = AppColor.black
        UITableView.appearance().separatorColor = AppColor.stroke
    }
}
