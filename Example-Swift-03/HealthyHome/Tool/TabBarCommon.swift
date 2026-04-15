//
//  TabBarCommon.swift
//  HealthyHome
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

class TabBarCommon: NSObject {
    
    /// MARK: 切换跳转主界面
    class func tabBarSelectIndex(_ selectIndex: Int) {
        CYLPlusButtonSubclass.register()
        let tabBarController = RootTabBarController(viewControllers: ViewControllers(), tabBarItemsAttributes: tabBarItemsAttributesForController())
        tabBarController.tabBarStyleType = .liquidGlass
//        tabBarController.noNeedUIDesignCompatibility = true
        tabBarController.selectedIndex = selectIndex;
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = tabBarController
    }
    
    /// MARK: 切换跳转主界面 操作其他事件
    class func completionhandler(_ selectIndex: Int, _: () ->())  {
        tabBarSelectIndex(selectIndex)
    }
    
    /// MARK: 进入APP
    class func enterApp(_ : () -> ()) {
        TabBarController()
    }
    
    /// MARK: 创建根视图
    class func TabBarController() {
        CYLPlusButtonSubclass.register()
        let appDelegate = UIApplication.shared.delegate
        appDelegate?.window??.rootViewController = RootTabBarController(viewControllers: ViewControllers(), tabBarItemsAttributes: tabBarItemsAttributesForController())
    }
    
    //MARK:主界面
    class func ViewControllers() -> [RootNavigationController] {

        let home = RootNavigationController(rootViewController: HomeVC())
        let healthy = RootNavigationController(rootViewController: HealthyVC())
        let friends = RootNavigationController(rootViewController: FriendsVC())
        let me = RootNavigationController(rootViewController: MeVC())
        
        let viewControllers = [home, healthy, friends, me]

        return viewControllers
    }
        
    
    class func tabBarItemsAttributesForController() -> [[String: String]] {
            
        let tabBarItemHome = [CYLTabBarItemTitle: "首页",
                              CYLTabBarItemImage: "Home",
                              CYLTabBarItemSelectedImage: "HomeSelected"]
        
        let tabBarItemHealthy = [CYLTabBarItemTitle: "健康",
                              CYLTabBarItemImage: "Message",
                              CYLTabBarItemSelectedImage: "MessageSelected"]

        let tabBarItemFriends = [CYLTabBarItemTitle: "朋友圈",
                              CYLTabBarItemImage: "lianxiren",
                              CYLTabBarItemSelectedImage: "lianxirenSelected"]
        
        let tabBarItemMe = [CYLTabBarItemTitle: "我的",
                              CYLTabBarItemImage: "Me",
                              CYLTabBarItemSelectedImage: "MeSelected"]

        let tabBarItemsAttributes = [tabBarItemHome, tabBarItemHealthy, tabBarItemFriends, tabBarItemMe]
        
        return tabBarItemsAttributes
    }

    
}
