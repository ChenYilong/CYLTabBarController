//
//  MainRootNavigationViewController.swift
//  CYLTabBarController-Swift
//
//  Created by chenyilong on 2026/4/13.
//  Copyright © 2026 Anthony. All rights reserved.
//

import Foundation
import UIKit
import CYLTabBarController

class MainRootNavigationViewController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CYLPlusButtonSubclass.register()

        let imageInsets = UIEdgeInsets.zero
        let titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -3.5)
        
        let mainTabBarVc = MainTabBarController(viewControllers: Self.viewControllers(), tabBarItemsAttributes: Self.tabBarItemsAttributesForController(), imageInsets: imageInsets, titlePositionAdjustment: titlePositionAdjustment, context: "")
        self.viewControllers = [mainTabBarVc]
    }
    
    
    static func viewControllers() -> [UINavigationController]{
        let home = UINavigationController(rootViewController: HomeViewController())
        let connection = UINavigationController(rootViewController: ConnectionViewController())
        let message = UINavigationController(rootViewController: MessageViewController())
        let personal =   UINavigationController(rootViewController: PersonalViewController())
        let viewControllers = [home, connection, message, personal]
        
        return viewControllers
        
    }
    

    static func tabBarItemsAttributesForController() ->  [[String : String]] {
        
        let tabBarItemOne = [CYLTabBarItemTitle:"首页",
                             CYLTabBarItemImage:"home_normal",
                             CYLTabBarItemSelectedImage:"home_highlight"]
        
        let tabBarItemTwo = [CYLTabBarItemTitle:"同城",
                             CYLTabBarItemImage:"mycity_normal",
                             CYLTabBarItemSelectedImage:"mycity_highlight"]
        
        let tabBarItemThree = [CYLTabBarItemTitle:"消息",
                               CYLTabBarItemImage:"message_normal",
                               CYLTabBarItemSelectedImage:"message_highlight"]
        
        let tabBarItemFour = [CYLTabBarItemTitle:"我的",
                              CYLTabBarItemImage:"account_normal",
                              CYLTabBarItemSelectedImage:"account_highlight"]
        let tabBarItemsAttributes = [tabBarItemOne,tabBarItemTwo,tabBarItemThree,tabBarItemFour]
        return tabBarItemsAttributes
    }
}

 
