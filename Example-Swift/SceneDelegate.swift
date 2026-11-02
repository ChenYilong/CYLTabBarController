//
//  SceneDelegate.swift
//
//  UIScene life cycle is required for apps built with the iOS 27 SDK.
//

import UIKit
import CYLTabBarController

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        // Rebuilt after a language change, so every text shows in the new language.
        window.cyl_setRootViewControllerProvider { MainRootNavigationViewController() }
        window.makeKeyAndVisible()
        self.window = window
        // Keep AppDelegate.window in sync for code that still reads it.
        (UIApplication.shared.delegate as? AppDelegate)?.window = window
    }
}
