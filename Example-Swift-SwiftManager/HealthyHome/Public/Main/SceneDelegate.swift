//
//  SceneDelegate.swift
//  CYLTabBarController
//
//  UIScene life cycle is required for apps built with the iOS 27 SDK.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = .white
        self.window = window
        // TabBarCommon sets the root view controller through AppDelegate.window.
        (UIApplication.shared.delegate as? AppDelegate)?.window = window

        if isFirst() {
            let guide = GuideViewController()
            guide.timeEndBlock = {
                TabBarCommon.TabBarController()
            }
            window.rootViewController = guide
        }else {
            TabBarCommon.TabBarController()
        }

        window.makeKeyAndVisible()
    }
}
