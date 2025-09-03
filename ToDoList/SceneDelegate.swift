//
//  SceneDelegate.swift
//  ToDoList
//
//  Created by Alexander Shevtsov on 29.08.2025.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        
        ThemeConfigurator.apply()
        
        let window = UIWindow(windowScene: windowScene)
        window.tintColor = AppColor.yellow
        
        let listVC = ToDoListModuleBuilder.build()
        let rootNavigationController = UINavigationController(rootViewController: listVC)
        
        window.rootViewController = rootNavigationController
        window.makeKeyAndVisible()
        self.window = window
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {}
    
    func sceneDidBecomeActive(_ scene: UIScene) {}
    
    func sceneWillResignActive(_ scene: UIScene) {}
    
    func sceneWillEnterForeground(_ scene: UIScene) {}
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }
}
