//
//  RiveTabBarController.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/*!
 * [EN] Example-Rive's tab bar controller: the plus button's badge demo shared by every Swift demo
 *      (Example-Shared/CYLPlusButtonBadgeDemo.swift): 1 after launch, +1 on each tap of the plus button.
 * [CN] Example-Rive 的 TabBarController：所有 Swift Demo 共用的 PlusButton 角标演示（Example-Shared/CYLPlusButtonBadgeDemo.swift）：
 *      启动后显示 1，每次点击 PlusButton 加 1。
 */
final class RiveTabBarController: CourseTabBarController, CYLFlatDesignUITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // [EN] `tabBarController(_:didSelect:)` below is a delegate method. [CN] 下面的 `tabBarController(_:didSelect:)` 是代理方法。
        delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        demoShowPlusButtonBadgeAfterLayout()
        // [EN] `-CYLDemoRiveFollowsAppearance YES`: tab badges on tinted Rive icons, to check that a tint never covers a badge.
        // [CN] `-CYLDemoRiveFollowsAppearance YES`：着色 Rive 图标上的 Tab 角标，用于检查着色不会遮盖角标。
        // [EN] Through the view controllers, as the ObjC demo: FlatDesign takes badges this way. [CN] 与 ObjC Demo 一样通过视图控制器设置：扁平样式通过这种方式接收角标。
        if UserDefaults.standard.bool(forKey: "CYLDemoRiveFollowsAppearance"), let pages = viewControllers {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pages.first?.cyl_showBadgeValue("3", animationType: .none)
                pages.last?.cyl_showBadgeValue("", animationType: .none)
            }
        }
    }

    override func tabBarController(_: CYLTabBarController, didSelect control: UIControl) {
        demoPlusButtonDidTap(control)
    }
}
