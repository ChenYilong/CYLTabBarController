//
//  RootTabBarController.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit
import CYLTabBarController

class RootTabBarController: CYLTabBarController {

    // #535: the plus button's badge, shared by every Swift demo (Example-Shared/CYLPlusButtonBadgeDemo.swift).
    // #535：PlusButton 的角标，所有 Swift Demo 共用（Example-Shared/CYLPlusButtonBadgeDemo.swift）。
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        demoShowPlusButtonBadgeAfterLayout()
    }

    override func tabBarController(_ _: CYLTabBarController, didSelect control: UIControl) {
        demoPlusButtonDidTap(control)
    }

    

    #if CYL_DEMO_PAG
    /// [EN] #216: a skin can change a tab's PAG file in place. The Grapefruit skin swaps the files of "Moments" and "Me"; every
    ///      other skin uses the files of `TabBarCommon`. PAG has no color override, so the file is what a skin can change. A color skin, because the
    ///      icons of a holiday skin are shown over the animations.
    ///      `cyl_themeDidChangeBlock` runs after the theme was applied to this controller.
    /// [CN] #216：皮肤可以原地更换 Tab 的 PAG 文件。西柚皮肤互换「朋友圈」与「我的」的文件；其他皮肤使用 `TabBarCommon` 中的文件。
    ///      PAG 没有颜色覆盖，因此皮肤能更换的就是文件。使用配色皮肤，因为节日皮肤的图标会显示在动画之上。`cyl_themeDidChangeBlock` 在主题应用到本控制器之后执行。
    private func applySkinAnimations() {
        let swapsFiles = (cyl_themeManager.currentThemeIdentifier as? String) == "Grapefruit"
        // [EN] Indexes in `viewControllers`: the PlusButton's tab is index 2. [CN] `viewControllers` 中的索引：PlusButton 的 Tab 是索引 2。
        // [EN] `CYLTabBarItemAttributesAddingAnimationFile()` finds the file in the main bundle; `CYLTabBarAnimationFilePath` itself is a full path.
        // [CN] `CYLTabBarItemAttributesAddingAnimationFile()` 在 main bundle 中查找文件；`CYLTabBarAnimationFilePath` 本身是完整路径。
        let setFile = { (index: UInt, fileName: String) in
            if let attributes = CYLTabBarItemAttributesAddingAnimationFile([:], fileName, nil) as? [String: Any] {
                self.updateTabBarItem(at: index, attributes: attributes)
            }
        }
        setFile(3, swapsFiles ? "tab_me.pag" : "tab_moments.pag")
        setFile(4, swapsFiles ? "tab_moments.pag" : "tab_me.pag")
    }
    #endif

    override func viewDidLoad() {
        tabBarItemAnimationSpeed = 1.5 // Issue #428: tab icon animations at 1.5x (no effect without an animation subspec) Tab 图标动画 1.5 倍速

        super.viewDidLoad()

        #if CYL_DEMO_PAG
        view.cyl_themeDidChangeBlock = { [weak self] in
            self?.applySkinAnimations()
        }
        #endif

        self.delegate = self

        customizeInterface()
        CYLPlusChildViewController.view.layoutIfNeeded()

    }
    
    /// [CN] MARK:TabBard底部标签设置
    /// [EN] MARK: TabBar bottom tab settings
    func customizeInterface() {
        
        if #available(iOS 11.0, *) {
            tabBar.unselectedItemTintColor = .lightGray
            tabBar.tintColor = .hexColor("3A57ED")
        }else {
            let normalAttrs: NSDictionary = [NSAttributedString.Key.foregroundColor: UIColor.red]
            let selectAttrs: NSDictionary = [NSAttributedString.Key.foregroundColor: UIColor.blue]

            self.tabBarItem.setTitleTextAttributes(normalAttrs as? [NSAttributedString.Key: AnyObject], for: .normal)
            self.tabBarItem.setTitleTextAttributes(selectAttrs as? [NSAttributedString.Key: AnyObject], for: .selected)
        }
        
        // [CN] MARK:设置背景图片
        // [EN] MARK: Set the background image
        tabBar.backgroundImage = UIImage.imageWithColor(.white)
        // [CN] MARK:去除 TabBar 自带的顶部阴影
        // [EN] MARK: Remove the TabBar's built-in top shadow
        self.tabBar.shadowImage = UIImage()
        
//        appearanceShawIamge()
    }
    
    @available(iOS 13, *)
    func appearanceShawIamge() {
        let appearance = tabBar.standardAppearance
        appearance.shadowImage = .imageWithColor(.clear)
        tabBar.standardAppearance = appearance
    }
}

extension RootTabBarController {

    func tabBarController(_ tabBarController: CYLTabBarController, shouldSelect viewController: UIViewController) -> Bool {

        super.tabBarController(tabBarController, shouldSelect: viewController)

        return true
    }

    override func tabBarController(_ _: CYLTabBarController, shouldShowPlatterLiquidLensViewFor _: UIControl) -> Bool {
//        return super.tabBarController(tabBarController, shouldShowPlatterLiquidLensViewFor: control)
        return true
    }
}

// [EN] Example-Swift-Carthage and Example-PAG (`CYL_DEMO_FLATDESIGN_DELEGATE`) build FlatDesign too, so `delegate` is
//      `CYLTabBarControllerDelegate & CYLFlatDesignUITabBarControllerDelegate`: adopt both to set `delegate = self`.
// [CN] Example-Swift-Carthage 与 Example-PAG（`CYL_DEMO_FLATDESIGN_DELEGATE`）同时构建扁平样式，`delegate` 的类型为
//      `CYLTabBarControllerDelegate & CYLFlatDesignUITabBarControllerDelegate`：同时遵守两者才能设置 `delegate = self`。
#if CYL_DEMO_FLATDESIGN_DELEGATE
extension RootTabBarController: CYLFlatDesignUITabBarControllerDelegate {}
#endif
