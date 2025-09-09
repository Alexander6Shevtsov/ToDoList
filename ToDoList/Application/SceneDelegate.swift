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
    
    // MARK: - Overrides
    // Точка входа при создании сцены: конфигурируем тему, окно и корневой модуль
    override func responds(to aSelector: Selector!) -> Bool {
        super.responds(to: aSelector)
    }
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        ThemeConfigurator.apply()
        
        guard let windowScene = scene as? UIWindowScene else { return }
        
        // Выделил установку корневого контроллера в отдельный метод
        setRootController(in: windowScene)
    }
    
    // Сохранение контекста при уходе в фон
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
    
    // MARK: - Private Methods
    // Создание окна и установка корневого контроллера навигации
    private func setRootController(in windowScene: UIWindowScene) {
        let window = UIWindow(windowScene: windowScene)
        
        // Инкапсулируем зависимости в ToDoListModuleBuilder.
        let rootViewController = ToDoListModuleBuilder.build()
        
        let navigationController = UINavigationController(
            rootViewController: rootViewController
        )
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
    }
}
