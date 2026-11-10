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
class AppDelegate: UIResponder, UIApplicationDelegate {
  
    var window: UIWindow?

    func application(_ _: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
        CYLPlusButtonSubclass.register()

        // The window is created in SceneDelegate (UIScene life cycle).

        // [EN] The tab bar's tint color. [CN] TabBar 的着色。
        UITabBar.appearance().tintColor = UIColor(red: 1.0, green: 102.0 / 255.0, blue: 0, alpha: 1.0)

        return true
    }

    // [EN] No `application(_:configurationForConnecting:options:)`: Info.plist names the "Default Configuration" and its
    //      SceneDelegate, which UIKit uses without it. [CN] 不实现 `application(_:configurationForConnecting:options:)`：Info.plist
    //      已声明 "Default Configuration" 及其 SceneDelegate，UIKit 会直接使用。

    func makeMainTabBarController() -> MainTabBarController {
        let titles = CYLLocalizedTabBarItemsAttributes(["首页", "同城", "消息", "我的"],
                                                       ["home_normal", "mycity_normal", "message_normal", "account_normal"],
                                                       ["home_highlight", "mycity_highlight", "message_highlight", "account_highlight"],
                                                       [:])
        var items = titles.compactMap { $0 as? [String: Any] }
        // [EN] Issue #605: how a GIF plays depends on the key that gives it.
        // [CN] Issue #605：GIF 如何播放取决于传入它的 key。
        let size = NSValue(cgSize: CGSize(width: 30, height: 30))
        // [EN] Tab 1, a GIF key: the first frame, then once when selected, staying on the last frame.
        // [CN] 第 1 个 Tab，GIF key：显示第一帧，选中时播放一次，然后停在最后一帧。
        items[0][CYLTabBarGIFFilePath] = Bundle.main.path(forResource: "tab_rocket", ofType: "gif")
        items[0][CYLTabBarGIFSize] = size
        // [EN] Tab 2, the generic helper: finds the file by name and picks the library by its extension. Plays the same way.
        // [CN] 第 2 个 Tab，通用函数：按名称查找文件，并按扩展名选择动画库。播放方式相同。
        if let item = CYLTabBarItemAttributesAddingAnimationFile(items[1], "tab_star.gif", nil) as? [String: Any] {
            items[1] = item
            items[1][CYLTabBarAnimationSize] = size
        }
        // [EN] Tab 3, a plain image entry: no animation key, so the GIF keeps looping, selected or not.
        // [CN] 第 3 个 Tab，普通图片入口：没有动画 key，因此 GIF 一直循环，无论是否选中。
        items[2][CYLTabBarItemImageURL] = Bundle.main.url(forResource: "tab_fire", withExtension: "gif")
        items[2][CYLTabBarItemImageURLSize] = size
        // [EN] Tab 4 keeps its static images. [CN] 第 4 个 Tab 保持静态图片。
        DemoPlusButton.register()
        return MainTabBarController(viewControllers: viewControllers(), tabBarItemsAttributes: items, styleType: CYLDemoTabBarStyle.styleType, context: nil)
    }


    func viewControllers() -> [UINavigationController]{
        let home = UINavigationController(rootViewController: CYLSettingsDemoTableViewController())
        let connection = UINavigationController(rootViewController: ConnectionViewController())
        let message = UINavigationController(rootViewController: MessageViewController())
        let personal =   UINavigationController(rootViewController: PersonalViewController())
        let viewControllers = [home, connection, message, personal]
        
        return viewControllers
        
    }
    




}

