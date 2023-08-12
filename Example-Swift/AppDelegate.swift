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

        let mainTabBarVc = MainTabBarController(viewControllers: viewControllers(), tabBarItemsAttributes: tabBarItemsAttributesForController())

        window = UIWindow()
        window?.frame = UIScreen.main.bounds
        window?.rootViewController = mainTabBarVc
        mainTabBarVc?.hideTabBadgeBackgroundSeparator()
        mainTabBarVc.hideTabBarShadowImageView();

        window?.makeKeyAndVisible()

        UITabBar.appearance().backgroundColor = UIColor.white

        return true
    }

    func viewControllers() -> [UINavigationController] {
        let home = UINavigationController(rootViewController: HomeViewController())
        let connection = UINavigationController(rootViewController: ConnectionViewController())
        let message = UINavigationController(rootViewController: MessageViewController())
        let personal = UINavigationController(rootViewController: PersonalViewController())
        let viewControllers = [home, connection, message, personal]

        return viewControllers
    }

    func tabBarItemsAttributesForController() -> [[String: String]] {
        let tabBarItemOne = [CYLTabBarItemTitle: "首页",
                             CYLTabBarItemImage: "home_normal",
                             CYLTabBarItemSelectedImage: "home_highlight"]

        let tabBarItemTwo = [CYLTabBarItemTitle: "同城",
                             CYLTabBarItemImage: "mycity_normal",
                             CYLTabBarItemSelectedImage: "mycity_highlight"]

        let tabBarItemThree = [CYLTabBarItemTitle: "消息",
                               CYLTabBarItemImage: "message_normal",
                               CYLTabBarItemSelectedImage: "message_highlight"]

        let tabBarItemFour = [CYLTabBarItemTitle: "我的",
                              CYLTabBarItemImage: "account_normal",
                              CYLTabBarItemSelectedImage: "account_highlight"]
        let tabBarItemsAttributes = [tabBarItemOne, tabBarItemTwo, tabBarItemThree, tabBarItemFour]
        return tabBarItemsAttributes
    }
}
