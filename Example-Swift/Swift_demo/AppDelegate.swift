//
//  AppDelegate.swift
//  Swift_demo
//
//  Created by Willei Wang on 2017/12/11.
//  Copyright © 2017年 WenLei Wang. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate,CYLTabBarControllerDelegate {
    
    var window: UIWindow?
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        CYLPlusButtonSubclass.register()
        
        application.statusBarStyle = UIStatusBarStyle.lightContent
        UINavigationBar.appearance().barTintColor = UIColor(hue:0.13, saturation:0.62, brightness:0.98, alpha:1.00)
        UINavigationBar.appearance().tintColor = UIColor.black
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.black]
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let tabBarController = CYLTabBarControllerConfig().tabBarController
        self.window!.rootViewController = tabBarController
        tabBarController.delegate = self
        self.window!.makeKeyAndVisible()
        
        self.customizeInterfaceWithTabBarController(tabBarController: tabBarController)
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController!, didSelect control: UIControl!) {
        var animationView = UIView()
        
        if control.cyl_isTabButton() {
            if (self.cyl_tabBarController.selectedViewController?.cyl_isShowTabBadgePoint())! {
                self.cyl_tabBarController.selectedViewController?.cyl_removeTabBadgePoint()
            } else {
                self.cyl_tabBarController.selectedViewController?.cyl_showTabBadgePoint()
            }
            
            animationView = control.cyl_tabImageView()
        }
        
        if control.cyl_isPlusButton() {
            let button:UIButton = CYLExternPlusButton
            animationView = button.imageView!
            
        }
        
        if self.cyl_tabBarController.selectedIndex == 1 || self.cyl_tabBarController.selectedIndex == 4{
            //            self.addScaleAnimationOnView(animationView: animationView, repeatCount: 1)
            self.addRotateAnimationOnView(animationView: animationView)
        } else {
            self.addScaleAnimationOnView(animationView: animationView, repeatCount: 1)
        }
        
    }
    //缩放动画
    func addScaleAnimationOnView(animationView: UIView,repeatCount: Float) {
        //需要实现的帧动画，这里根据需求自定义
        
        let animation = CAKeyframeAnimation()
        animation.keyPath = "transform.scale";
        animation.values = [1.0,1.3,0.9,1.15,0.95,1.02,1.0];
        animation.duration = 1;
        animation.repeatCount = repeatCount;
        animation.calculationMode = kCAAnimationCubic;
        animationView.layer.add(animation, forKey: nil)
    }
    
    //旋转动画
    func addRotateAnimationOnView(animationView: UIView) {
        // 针对旋转动画，需要将旋转轴向屏幕外侧平移，最大图片宽度的一半
        // 否则背景与按钮图片处于同一层次，当按钮图片旋转时，转轴就在背景图上，动画时会有一部分在背景图之下。
        // 动画结束后复位
        
        animationView.layer.zPosition = 65 / 2
        UIView.animate(withDuration: 0.32, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: {
            animationView.layer.transform = CATransform3DMakeRotation(CGFloat(M_PI), 0, 1, 0)
        }, completion: nil)
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
            UIView.animate(withDuration: 0.7, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.2, options: UIViewAnimationOptions.curveEaseOut, animations: {
                animationView.layer.transform = CATransform3DMakeRotation( CGFloat(M_PI*2 ), 0, 1, 0)
            }, completion: nil)
        })
        
        
        
        
    }
    
    func customizeInterfaceWithTabBarController(tabBarController: CYLTabBarController) {
        //设置导航栏
        self.setUpNavigationBarAppearance()
        
        tabBarController.hideTabBadgeBackgroundSeparator()
        //添加小红点
        let viewController = tabBarController.viewControllers[0]
        let tabBadgePointView0: UIView = UIView.cyl_tabBadgePointView(withClolor: randomColor, radius: 4.5)
        viewController.tabBarItem.cyl_tabButton.cyl_tabBadgePointView = tabBadgePointView0
        viewController.cyl_showTabBadgePoint()
        
        let tabBadgePointView1: UIView = UIView.cyl_tabBadgePointView(withClolor: randomColor, radius: 4.5)
        
        do {
            try
                tabBarController.viewControllers[1].cyl_tabBadgePointView = tabBadgePointView1
            tabBarController.viewControllers[1].cyl_showTabBadgePoint()
            
            let tabBadgePointView2: UIView = UIView.cyl_tabBadgePointView(withClolor: randomColor, radius: 4.5)
            tabBarController.viewControllers[2].cyl_tabBadgePointView = tabBadgePointView2
            tabBarController.viewControllers[2].cyl_showTabBadgePoint()
            
            tabBarController.viewControllers[3].cyl_showTabBadgePoint()
            
            //添加提示动画，引导用户点击
            self.addScaleAnimationOnView(animationView: tabBarController.viewControllers[3].cyl_tabButton.cyl_tabImageView(), repeatCount: 20)
            
            
            
        } catch _ as NSException {
            
        }
        
    }
    
    func setUpNavigationBarAppearance() {
        let navigationBarAppearance = UINavigationBar.appearance()
        
        let backgroundImage = UIImage.init(named: "navigationbar_background_tall")
        let textAttributes:Dictionary = [
            NSAttributedStringKey.font : UIFont.boldSystemFont(ofSize: 18),
            NSAttributedStringKey.foregroundColor : UIColor.black
        ]
        
        
        navigationBarAppearance.setBackgroundImage(backgroundImage, for: .default)
        navigationBarAppearance.titleTextAttributes = textAttributes
        
        
        
        
        //        UINavigationBar *navigationBarAppearance = [UINavigationBar appearance];
        
        //        UIImage *backgroundImage = nil;
        //        NSDictionary *textAttributes = nil;
        //        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        //            backgroundImage = [UIImage imageNamed:@"navigationbar_background_tall"];
        //
        //            textAttributes = @{
        //                NSFontAttributeName : [UIFont boldSystemFontOfSize:18],
        //                NSForegroundColorAttributeName : [UIColor blackColor],
        //            };
        //        } else {
        //            #if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
        //                backgroundImage = [UIImage imageNamed:@"navigationbar_background"];
        //                textAttributes = @{
        //                    UITextAttributeFont : [UIFont boldSystemFontOfSize:18],
        //                    UITextAttributeTextColor : [UIColor blackColor],
        //                    UITextAttributeTextShadowColor : [UIColor clearColor],
        //                    UITextAttributeTextShadowOffset : [NSValue valueWithUIOffset:UIOffsetZero],
        //                };
        //            #endif
        //        }
        
        //        [navigationBarAppearance setBackgroundImage:backgroundImage
        //        forBarMetrics:UIBarMetricsDefault];
        //        [navigationBarAppearance setTitleTextAttributes:textAttributes];
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    
}

