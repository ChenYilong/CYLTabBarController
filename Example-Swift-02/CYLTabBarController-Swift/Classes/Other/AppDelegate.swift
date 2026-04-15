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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
       
//        CYLPlusButtonSubclass.register()
        

//        let mainTabBarVc = MainRootNavigationViewController()
//
//        self.window = UIWindow()
//        self.window?.frame = UIScreen.main.bounds
//        self.window?.rootViewController = mainTabBarVc
//        self.window?.makeKeyAndVisible()
        
//        //tabbar背景色
//        UITabBar.appearance().backgroundColor = UIColor.white
//        //tabbar字体颜色
//        UITabBar.appearance().tintColor = UIColor(red:255.0/255.0,green:102.0/255.0,blue:0,alpha:1.0)

        return true
    }
}



    class SceneDelegate: UIResponder, UIWindowSceneDelegate {

        var window: UIWindow?

        func scene(
            _ scene: UIScene,
            willConnectTo session: UISceneSession,
            options connectionOptions: UIScene.ConnectionOptions
        ) {

            guard let windowScene = scene as? UIWindowScene else { return }

            let window = CYLGetRootWindow()
            // ✅ Move your original logic here
            let mainTabBarVc = MainRootNavigationViewController()

            window?.rootViewController = mainTabBarVc
            window?.makeKeyAndVisible()

            self.window = window

            // Optional UI config
            // UITabBar.appearance().backgroundColor = .white
            // UITabBar.appearance().tintColor = UIColor(...)
        }
    
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
    }
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
    }

}
