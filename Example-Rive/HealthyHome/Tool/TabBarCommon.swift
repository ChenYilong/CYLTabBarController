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
    
    /// [CN] MARK: 切换跳转主界面
    /// [EN] MARK: Switch to the main screen
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
        // [EN] Rive animations instead of Lottie, with the `CYLTabBarController/Rive` subspec. Every icon is an artboard of
        //      one file, "icon-set.riv" (rive_animated_icon, MIT; Example-Shared/RiveResources, fetched by `pod install`):
        //      `CYLTabBarRiveAnimationURL()` names the artboard and its state machine. Selecting a tab sets the view model
        //      boolean "active" to true for a second, which plays the icon. Without the subspec the Rive keys are ignored
        //      and the images show.
        // [CN] 使用 Rive 动画代替 Lottie，需引入 `CYLTabBarController/Rive` 子库。所有图标都是同一个文件「icon-set.riv」中的画板
        //      （rive_animated_icon，MIT；Example-Shared/RiveResources，由 `pod install` 下载）：`CYLTabBarRiveAnimationURL()` 指定画板及其状态机。
        //      选中 Tab 时，view model 布尔属性 "active" 设为 true 一秒，图标随之播放。未引入子库时忽略 Rive key，显示图片。
        // [EN] Only some tabs are animated (#477): nil leaves the second tab ("健康") with its images. Selecting it stops the
        //      animated tabs.
        // [CN] 只有部分 Tab 有动画（#477）：nil 表示第二个 Tab（「健康」）保持图片。选中它时，有动画的 Tab 会停止。
        let iconSet = Bundle.main.url(forResource: "icon-set", withExtension: "riv")
        let artboards: [(artboard: String, stateMachine: String)?] = [
            ("HOME", "HOME_interactivity"),
            nil,
            ("BELL", "BELL_Interactivity"),
            ("USER", "USER_Interactivity"),
        ]
        return zip(tabBarItemsAttributes, artboards).map { attributes, icon in
            var item: [AnyHashable: Any] = attributes
            guard let icon, let url = CYLTabBarRiveAnimationURL(iconSet, [
                .artboard: icon.artboard,
                .stateMachine: icon.stateMachine,
                // [EN] The icons' light color, set on the view model property "color". [CN] 图标的浅色颜色，设置到 view model 属性 "color"。
                .color: "#1F1F1F",
            ]) else {
                return item
            }
            item[CYLTabBarRiveURL] = url
            item[CYLTabBarRiveSize] = NSValue(cgSize: CGSize(width: 30, height: 30))
            // [EN] Dark Mode with the same file: the view model color "color" turns white. [CN] 同一份文件适配深色模式：view model 颜色 "color" 变为白色。
            item[CYLTabBarRiveDarkColors] = ["color": UIColor.white]
            return item
        }
    }

    
}
