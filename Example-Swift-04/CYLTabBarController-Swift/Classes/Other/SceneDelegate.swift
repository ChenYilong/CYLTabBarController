//
//  SceneDelegate.swift
//  SwiftDemo
//
//  UIScene life cycle is required for apps built with the iOS 27 SDK.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = appDelegate.makeMainTabBarController()
        window.makeKeyAndVisible()
        self.window = window
        // Keep AppDelegate.window in sync for code that still reads it.
        appDelegate.window = window
    }
}
