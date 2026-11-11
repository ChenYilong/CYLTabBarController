//
//  AppDelegate.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/11.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit
import CYLTabBarController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ _: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // The window is created in SceneDelegate (UIScene life cycle).
        return true
    }

    func application(_ _: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // Empty UIApplicationDelegate life-cycle methods were removed: they are optional, and the UIScene life cycle
    // reports these events to SceneDelegate. 空的生命周期方法已删除：它们是可选的，UIScene 生命周期会通知 SceneDelegate。
}
