//
//  SceneDelegate.swift
//
//  UIScene life cycle is required for apps built with the iOS 27 SDK.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

//        let mainTabBarVc = MainTabBarController()
        let mainTabBarVc = MainRootNavigationViewController()
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = mainTabBarVc
        window.makeKeyAndVisible()
        self.window = window
        // Keep AppDelegate.window in sync for code that still reads it.
        (UIApplication.shared.delegate as? AppDelegate)?.window = window
    }
}
