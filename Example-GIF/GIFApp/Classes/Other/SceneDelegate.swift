//
//  SceneDelegate.swift
//  SwiftDemo
//
//  UIScene life cycle is required for apps built with the iOS 27 SDK.
//

import UIKit
import CYLTabBarController

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }

        let window = UIWindow(windowScene: windowScene)
        // Rebuilt after a language change, so every text shows in the new language.
        window.cyl_setRootViewControllerProvider { appDelegate.makeMainTabBarController() }
        // [EN] The navigation bar button of the first tab rebuilds the tab bar in the other style.
        // [CN] 第一个 Tab 的导航栏按钮以另一种样式重建 TabBar。
        CYLDemoTabBarStyle.rebuildRootViewController = { [weak window] in
            window?.rootViewController = appDelegate.makeMainTabBarController()
        }
        window.makeKeyAndVisible()
        self.window = window
        // Keep AppDelegate.window in sync for code that still reads it.
        appDelegate.window = window
    }
}
