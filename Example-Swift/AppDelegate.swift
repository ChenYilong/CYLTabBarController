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

//        let mainTabBarVc = MainTabBarController()
        let mainTabBarVc = MainRootNavigationViewController()
        window = UIWindow()
        window?.frame = UIScreen.main.bounds
        window?.rootViewController = mainTabBarVc


        window?.makeKeyAndVisible()

        UITabBar.appearance().backgroundColor = UIColor.white

        return true
    }

}
