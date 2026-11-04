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
    
    /// [CN] MARK: 切换跳转主界面 操作其他事件
    /// [EN] MARK: Switch to the main screen and handle other events
    class func completionhandler(_ selectIndex: Int, _ completion: (() -> Void)? = nil) {
        tabBarSelectIndex(selectIndex)
        completion?()
    }
    
    /// [CN] MARK: 进入APP
    /// [EN] MARK: Enter the app
    class func enterApp(_ completion: (() -> Void)? = nil) {
        setUpRootTabBarController()
        completion?()
    }
    
    /// [CN] MARK: 创建根视图
    /// [EN] MARK: Create the root view
    class func setUpRootTabBarController() {
        CYLPlusButtonSubclass.register()
        // Rebuilt after a language change, so every text shows in the new language.
        UIApplication.shared.delegate?.window??.cyl_setRootViewControllerProvider {
            RootTabBarController(viewControllers: viewControllers(), tabBarItemsAttributes: tabBarItemsAttributesForController())
        }
    }
    
    // [CN] MARK:主界面
    // [EN] MARK: Main screen
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
        // [EN] #604: PAG animations (Tencent libpag) instead of Lottie, with the `CYLTabBarController/PAG` subspec. Each name is
        //      "<name>.pag" in the main bundle (Example-Shared/PAGResources/pag-ios, fetched by `pod install`); "<name>_dark.pag" would be its Dark Mode version.
        //      Without the subspec the PAG keys are ignored and the images show.
        // [CN] #604：使用 PAG 动画（腾讯 libpag）代替 Lottie，需引入 `CYLTabBarController/PAG` 子库。每个名称对应 main bundle 中的
        //      「<名称>.pag」（Example-Shared/PAGResources/pag-ios，由 `pod install` 下载）；「<名称>_dark.pag」为其深色模式版本。未引入子库时忽略 PAG key，显示图片。
        // [EN] #477: only some tabs are animated. Each tab takes its own file through
        //      `CYLTabBarItemAttributesAddingAnimationFile()` ("<name>.pag": PAG, "<name>.json": Lottie, or the file type of
        //      any library added later); "" leaves the second tab ("健康") with its images. Selecting it stops the animated tabs.
        // [CN] #477：只有部分 Tab 有动画。每个 Tab 通过 `CYLTabBarItemAttributesAddingAnimationFile()` 使用自己的文件（「名称.pag」为 PAG，
        //      「名称.json」为 Lottie，或以后新增动画库的文件类型）；"" 表示第二个 Tab（「健康」）保持图片。选中它时，有动画的 Tab 会停止。
        let animationFiles = ["1.pag", "", "22.pag", "test2.pag"]
        return zip(tabBarItemsAttributes, animationFiles).map { attributes, fileName in
            var item = CYLTabBarItemAttributesAddingAnimationFile(attributes, fileName, nil)
            // [EN] The generic size key, for any animation library: `CYLTabBarAnimationSize` (only for the animated tabs).
            // [CN] 通用的尺寸 key，适用于任意动画库：`CYLTabBarAnimationSize`（仅用于有动画的 Tab）。
            if item[CYLTabBarAnimationFilePath] != nil {
                item[CYLTabBarAnimationSize] = NSValue(cgSize: CGSize(width: 33, height: 33))
            }
            return item
        }
    }

    
}
