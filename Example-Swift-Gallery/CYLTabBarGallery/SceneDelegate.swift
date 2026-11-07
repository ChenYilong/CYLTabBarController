//
//  SceneDelegate.swift
//  CYLTabBarGallery
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Creates the window for the scene: apps built with the iOS 27 SDK must adopt the UIScene life cycle.
// [CN] 为 scene 创建 window：使用 iOS 27 SDK 构建的 App 必须采用 UIScene 生命周期。
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = UINavigationController(rootViewController: GalleryViewController())
        window.makeKeyAndVisible()
        self.window = window
    }
}
