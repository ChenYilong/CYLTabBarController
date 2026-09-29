//
//  AppDelegate.swift
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit

 
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {
    var window: UIWindow?
    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CYLPlusButtonSubclass.register()

        // The window is created in SceneDelegate (UIScene life cycle).
        //iOS26 不推荐设置 `UITabBar.appearance().backgroundColor` 不仅无法设置背景，同时会干扰 TabBar 里的 Label 未选中颜色，iOS26 里无选中时的Label颜色为系统内部逻辑， 无法自定义。
//        UITabBar.appearance().backgroundColor = UIColor.white
//        UITabBar.appearance().unselectedItemTintColor = UIColor.label;
        
        return true
    }

    func application(_: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
