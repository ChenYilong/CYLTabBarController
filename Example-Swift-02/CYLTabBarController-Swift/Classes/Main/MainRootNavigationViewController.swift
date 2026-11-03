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
        let home = UINavigationController(rootViewController: CYLBadgeHelperTableViewController())
        let connection = UINavigationController(rootViewController: ConnectionViewController())
        let message = UINavigationController(rootViewController: MessageViewController())
        let personal =   UINavigationController(rootViewController: PersonalViewController())
        let viewControllers = [home, connection, message, personal]
        
        return viewControllers
        
    }
    

    static func tabBarItemsAttributesForController() -> [[AnyHashable: Any]] {
        // Dark Mode (#620): "home_normal" also loads home_normal_dark (naming convention), the message tab names its dark
        // image, account_normal has its own Dark appearance. 深色模式：见 README「适配深色模式」。
        let attributes = CYLLocalizedTabBarItemsAttributes(["首页", "同城", "消息", "我的"],
                                                           ["home_normal", "mycity_normal", "message_normal", "account_normal"],
                                                           ["home_highlight", "mycity_highlight", "message_highlight", "account_highlight"],
                                                           [2: "message_normal_night"])
        // #442: Lottie icons, with their Dark Mode versions (<name>_dark.json → CYLTabBarLottieDarkFilePath).
        // Lottie 图标及其深色版本（<名称>_dark.json → CYLTabBarLottieDarkFilePath）。
        let lottieAttributes = CYLTabBarItemsAttributesAddingLottieFiles(attributes, ["green_lottie_tab_home", "green_lottie_tab_discover", "green_lottie_tab_news", "green_lottie_tab_mine"], nil)
        // #408: an identifier per tab (the plus button's is `CYLPlusButtonSubclass.tabBarItemIdentifier()`). 每个 Tab 的标识。
        return zip(lottieAttributes, ["home", "city", "message", "mine"]).map { item, identifier in
            var item = item
            item[CYLTabBarItemIdentifier] = identifier
            return item
        }
    }
}

 
