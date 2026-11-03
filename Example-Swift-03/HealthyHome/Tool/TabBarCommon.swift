//
//  TabBarCommon.swift
//  HealthyHome
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit
import CYLTabBarController

class TabBarCommon: NSObject {
    
    /// MARK: 切换跳转主界面
    /// Replaces `window.rootViewController` with a new tab bar controller (#488: the old one is then deallocated; in
    /// DEBUG, `cyl_setRootViewControllerProvider` logs a warning if it is not).
    /// 用新的 TabBarController 替换 `window.rootViewController`（#488：旧的随后会释放；DEBUG 下未释放时会打印警告）。
    class func tabBarSelectIndex(_ selectIndex: Int) {
        CYLPlusButtonSubclass.register()
        // Rebuilt after a language change too, so every text shows in the new language.
        UIApplication.shared.delegate?.window??.cyl_setRootViewControllerProvider {
            let tabBarController = RootTabBarController(viewControllers: viewControllers(), tabBarItemsAttributes: tabBarItemsAttributesForController())
            tabBarController.tabBarStyleType = .liquidGlass
            tabBarController.selectedIndex = selectIndex
            return tabBarController
        }
    }
    
    /// MARK: 切换跳转主界面 操作其他事件
    class func completionhandler(_ selectIndex: Int, _ completion: (() -> Void)? = nil) {
        tabBarSelectIndex(selectIndex)
        completion?()
    }
    
    /// MARK: 进入APP
    class func enterApp(_ completion: (() -> Void)? = nil) {
        setUpRootTabBarController()
        completion?()
    }
    
    /// MARK: 创建根视图
    class func setUpRootTabBarController() {
        CYLPlusButtonSubclass.register()
        // Rebuilt after a language change, so every text shows in the new language.
        UIApplication.shared.delegate?.window??.cyl_setRootViewControllerProvider {
            RootTabBarController(viewControllers: viewControllers(), tabBarItemsAttributes: tabBarItemsAttributesForController())
        }
    }
    
    //MARK:主界面
    class func viewControllers() -> [RootNavigationController] {

        let home = RootNavigationController(rootViewController: HomeVC())
        let healthy = RootNavigationController(rootViewController: HealthyVC())
        let friends = RootNavigationController(rootViewController: FriendsVC())
        let me = RootNavigationController(rootViewController: MeVC())
        
        let viewControllers = [home, healthy, friends, me]

        return viewControllers
    }
        
    
    class func tabBarItemsAttributesForController() -> [[AnyHashable: Any]] {
            
        let tabBarItemHome = [CYLTabBarItemTitle: CYLLocalizedString("首页"),
                              CYLTabBarItemImage: "Home",
                              CYLTabBarItemSelectedImage: "HomeSelected"]
        
        // Dark Mode (#620): "Home" also loads Home_dark (naming convention), this tab names its dark image, "Me" has its
        // own Dark appearance. 深色模式：见 README「适配深色模式」。
        let tabBarItemHealthy = [CYLTabBarItemTitle: CYLLocalizedString("健康"),
                              CYLTabBarItemImage: "Message",
                              CYLTabBarItemDarkImage: "Message_night",
                              CYLTabBarItemSelectedImage: "MessageSelected"]

        let tabBarItemFriends = [CYLTabBarItemTitle: CYLLocalizedString("朋友圈"),
                              CYLTabBarItemImage: "lianxiren",
                              CYLTabBarItemSelectedImage: "lianxirenSelected"]
        
        let tabBarItemMe = [CYLTabBarItemTitle: CYLLocalizedString("我的"),
                              CYLTabBarItemImage: "Me",
                              CYLTabBarItemSelectedImage: "MeSelected"]

        let tabBarItemsAttributes = [tabBarItemHome, tabBarItemHealthy, tabBarItemFriends, tabBarItemMe]
        // #442 (Lottie 4.x): one Lottie file per tab follows Dark Mode, its colors set with Lottie's value providers.
        // Shown in SwiftManager (SPM, Lottie 4.x); this project's Core subspec keeps the images.
        // 每个 Tab 一份 Lottie 文件适配深色模式。SwiftManager（SPM，Lottie 4.x）中显示；本工程只引入 Core 子库，仍显示图片。
        let lottieAttributes = CYLTabBarItemsAttributesAddingLottieFiles(tabBarItemsAttributes, ["green_lottie_tab_home", "green_lottie_tab_discover", "green_lottie_tab_news", "green_lottie_tab_mine"], nil)
        let darkColors = ["Icon_Shop", "Icon_Discovery", "Icon_Knowledge", "Icon_Mine"].map { layer -> [String: UIColor] in
            // Gray outline of the unselected icon → light gray, pale fill of the selected one → dark green.
            // 未选中的灰色描边 → 浅灰，选中的浅色填充 → 深绿。
            ["\(layer)_Normal.**.Color": UIColor(white: 0.78, alpha: 1),
             "\(layer)_Active_Main.**.Color": UIColor(red: 0.15, green: 0.39, blue: 0.16, alpha: 1)]
        }
        return zip(lottieAttributes, darkColors).map { item, colors in
            var item = item
            item[CYLTabBarLottieDarkColors] = colors
            return item
        }
    }

    
}
