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
final class RiveTabBarController: CYLTabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // [EN] `tabBarController(_:didSelect:)` below is a delegate method. [CN] 下面的 `tabBarController(_:didSelect:)` 是代理方法。
        delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        demoShowPlusButtonBadgeAfterLayout()
    }

    override func tabBarController(_: CYLTabBarController, didSelect control: UIControl) {
        demoPlusButtonDidTap(control)
    }
}
