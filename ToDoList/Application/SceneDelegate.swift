//
//  SceneDelegate.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 29.08.2025.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    // MARK: - Public Properties
    var window: UIWindow?
    
    // MARK: - UIWindowSceneDelegate
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        ThemeConfigurator.apply()
        
        guard let windowScene = scene as? UIWindowScene else { return }
        setRootController(in: windowScene)
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            appDelegate.saveContext()
        }
    }
    
    // MARK: - Private Methods
    /// Создаём окно и назначаем корневой контроллер
    private func setRootController(in windowScene: UIWindowScene) {
        let appWindow = UIWindow(windowScene: windowScene)
        
        // Экран списка задач создаётся билдером модуля
        let listViewController = ToDoListModuleBuilder.build()
        let navigationController = UINavigationController(rootViewController: listViewController)
        
        appWindow.rootViewController = navigationController
        appWindow.makeKeyAndVisible()
        window = appWindow
    }
}
