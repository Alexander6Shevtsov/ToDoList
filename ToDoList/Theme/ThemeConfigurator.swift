//
//  ThemeConfigurator.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 02.09.2025.
//

import UIKit

// MARK: - ThemeConfigurator
enum ThemeConfigurator {
    
    /// Запускается из SceneDelegate
    static func apply() {
        configureNavigationBarAppearance()
        configureBarButtonItemAppearance()
        configureSearchBarAppearance()
        configureTableViewAppearance()
        configureViewsAppearance()
        configureWindowTint()
    }
    
    // MARK: - Private Methods
    /// UINavigationBar: фон, шрифты, цвета
    private static func configureNavigationBarAppearance() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = AppColor.background
        navAppearance.shadowColor = .clear
        navAppearance.titleTextAttributes = [
            .foregroundColor: AppColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: AppColor.white,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]
        
        let navigationBar = UINavigationBar.appearance()
        navigationBar.standardAppearance = navAppearance
        navigationBar.scrollEdgeAppearance = navAppearance
        navigationBar.compactAppearance = navAppearance
        navigationBar.tintColor = AppColor.yellow
        navigationBar.prefersLargeTitles = true
        navigationBar.isTranslucent = false
    }
    
    
    /// UIBarButtonItem: цвет текста и шрифты
    private static func configureBarButtonItemAppearance() {
        let barButtonItem = UIBarButtonItem.appearance()
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: AppColor.yellow,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        barButtonItem.setTitleTextAttributes(attributes, for: .normal)
        barButtonItem.setTitleTextAttributes(attributes, for: .highlighted)
    }
    
    /// UISearchBar: цвета текстфилда и плейсхолдера
    private static func configureSearchBarAppearance() {
        let searchTextField = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        searchTextField.textColor = AppColor.white
        searchTextField.tintColor = AppColor.yellow
        searchTextField.backgroundColor = AppColor.surface
        
        let placeholderAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(white: 1, alpha: 0.6),
            .font: UIFont.systemFont(ofSize: 16, weight: .regular)
        ]
        searchTextField.attributedPlaceholder = NSAttributedString(
            string: "Search",
            attributes: placeholderAttributes
        )
        
        let searchBar = UISearchBar.appearance()
        searchBar.barTintColor = AppColor.background
        searchBar.searchBarStyle = .minimal
    }
    
    /// UITableView: фон, разделители, индикаторы
    private static func configureTableViewAppearance() {
        let tableView = UITableView.appearance()
        tableView.backgroundColor = AppColor.background
        tableView.separatorColor = AppColor.stroke
        tableView.indicatorStyle = .white
    }
    
    /// UIView базовый tint
    private static func configureViewsAppearance() {
        UIView.appearance().tintColor = AppColor.yellow
    }
    
    /// Глобальный tint для окна
    private static func configureWindowTint() {
        UIWindow.appearance().tintColor = AppColor.yellow
    }
}
