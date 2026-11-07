//
//  AppDelegate.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/*!
 * [EN] A UIKit app (no SwiftUI `App`): the root view controller of the scene's window (SceneDelegate.swift) is a
 *      CYLTabBarController whose tab icons are Rive artboards. It reuses the course's screens, Rive files and assets from Example-SwiftUI-Rive (see README.md).
 * [CN] 一个 UIKit App（不使用 SwiftUI `App`）：scene 的 window（SceneDelegate.swift）的根控制器是 CYLTabBarController，其 Tab 图标是 Rive 画板。它复用
 *      Example-SwiftUI-Rive 中课程的页面、Rive 文件与资源（见 README.md）。
 */
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        true
    }
}
