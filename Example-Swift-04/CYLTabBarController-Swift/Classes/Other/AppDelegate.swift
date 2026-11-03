//
//  AppDelegate.swift
//  SwiftDemo
//
//  Created by Anthony on 2017/10/12.
//  Copyright © 2017年 Anthony. All rights reserved.
//

import UIKit
import CYLTabBarController

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,UITabBarControllerDelegate {
  
    var window: UIWindow?

    func application(_ _: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        CYLPlusButtonSubclass.register()

        // The window is created in SceneDelegate (UIScene life cycle).

        //tabbar背景色
//        UITabBar.appearance().backgroundColor = UIColor.white
        // [CN] tabbar字体颜色
        // [EN] tabbar font color
        UITabBar.appearance().tintColor = UIColor(red: 1.0, green: 102.0 / 255.0, blue: 0, alpha: 1.0)

        return true
    }

    func application(_ _: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options _: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func makeMainTabBarController() -> MainTabBarController {
        // Dark Mode (#620): "home_normal" also loads home_normal_dark (naming convention), the message tab names its dark
        // image, account_normal has its own Dark appearance. 深色模式：见 README「适配深色模式」。
        let tabBarItemsAttributes = CYLLocalizedTabBarItemsAttributes(["首页", "同城", "消息", "我的"],
                                                                      ["home_normal", "mycity_normal", "message_normal", "account_normal"],
                                                                      ["home_highlight", "mycity_highlight", "message_highlight", "account_highlight"],
                                                                      [2: "message_normal_night"])
        // #442: Lottie icons, with their Dark Mode versions (<name>_dark.json → CYLTabBarLottieDarkFilePath).
        // Lottie 图标及其深色版本（<名称>_dark.json → CYLTabBarLottieDarkFilePath）。
        // Shown with a Lottie subspec (e.g. pod 'CYLTabBarController/LottieSwift'); the Core subspec keeps the images.
        // 需引入 Lottie 子库（如 pod 'CYLTabBarController/LottieSwift'）才显示；只引入 Core 时仍显示图片。
        let lottieTabBarItemsAttributes = CYLTabBarItemsAttributesAddingLottieFiles(tabBarItemsAttributes, ["green_lottie_tab_home", "green_lottie_tab_discover", "green_lottie_tab_news", "green_lottie_tab_mine"], nil)
        // #535: a plus button, registered before the tab bar controller is created, to show its badge (MainTabBarController.swift).
        // #535：在创建 TabBarController 之前注册 PlusButton，用于演示其角标（见 MainTabBarController.swift）。
        DemoPlusButton.register()
        return MainTabBarController(viewControllers: viewControllers(), tabBarItemsAttributes: lottieTabBarItemsAttributes)
    }


    func viewControllers() -> [UINavigationController]{
        let home = UINavigationController(rootViewController: CYLBadgeHelperTableViewController())
        let connection = UINavigationController(rootViewController: ConnectionViewController())
        let message = UINavigationController(rootViewController: MessageViewController())
        let personal =   UINavigationController(rootViewController: PersonalViewController())
        let viewControllers = [home, connection, message, personal]
        
        return viewControllers
        
    }
    




}

