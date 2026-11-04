//
//  AppDelegate.swift
//  CYLTabBarGallery
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Shows the gallery list in a navigation controller; no storyboard, no scenes.
// [CN] 在导航控制器中显示图库列表；不使用 storyboard 与 scene。
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = UINavigationController(rootViewController: GalleryViewController())
        window.makeKeyAndVisible()
        self.window = window
        return true
    }
}
