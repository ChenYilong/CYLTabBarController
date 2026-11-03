//
//  AppDelegate.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/11.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

// [EN] SwiftUI demo: the entry point is `HealthyHomeSwiftUIApp` (SwiftUI `App`), which keeps this delegate through
//      `@UIApplicationDelegateAdaptor`; SwiftUI creates the window and the scenes.
// [CN] SwiftUI 演示：入口是 `HealthyHomeSwiftUIApp`（SwiftUI `App`），通过 `@UIApplicationDelegateAdaptor` 保留本代理；
//      窗口与场景由 SwiftUI 创建。
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ _: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // [EN] The window is created by SwiftUI (`WindowGroup` in SwiftUIApp.swift).
        // [CN] 窗口由 SwiftUI 创建（SwiftUIApp.swift 中的 `WindowGroup`）。
        return true
    }

    // [EN] Empty UIApplicationDelegate life-cycle methods were removed: they are optional, and SwiftUI reports scene
    //      events through `scenePhase`.
    // [CN] 空的生命周期方法已删除：它们是可选的，SwiftUI 通过 `scenePhase` 通知场景事件。
}
