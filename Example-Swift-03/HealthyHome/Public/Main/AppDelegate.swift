//
//  AppDelegate.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/11.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // The window is created in SceneDelegate (UIScene life cycle).
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    //程序进入非活动状态，调用此方法，在此期间程序不接受任何消息或事件
    func applicationWillResignActive(_ application: UIApplication) {
        
        
    }

    //程序被推送至后台，调用此方法，如果要设置期间程序继续执行某些事件或动作可在此添加方法
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        
    }

    //当程序将要从后台重新回到前台，执行此方法
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        
    }

    //重新进入活动状态进入此方法
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        
    }

    //当程序将要退出时，调用此方法
    func applicationWillTerminate(_ application: UIApplication) {
       
        
    }


}

