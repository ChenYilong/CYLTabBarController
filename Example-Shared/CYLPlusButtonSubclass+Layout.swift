//
//  CYLPlusButtonSubclass+Layout.swift
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit

// [EN] The plus button's place, page and title alignment, shared by Example-Swift and Example-Swift-02. Each project keeps
//      `plusButton()` in its own `CYLPlusButtonSubclass.swift`, so each draws its own button.
// [CN] PlusButton 的位置、页面与标题对齐，由 Example-Swift 与 Example-Swift-02 共用。各工程在自己的 `CYLPlusButtonSubclass.swift` 中
//      保留 `plusButton()`，因此各自绘制自己的按钮。
extension CYLPlusButtonSubclass {
    // The plus button's title stays on the same center line as the tab item titles, in every tab bar style.
    static func alignsTitleWithTabBarItemTitles() -> Bool {
        return true
    }

    static func indexOfPlusButtonInTabBar() -> UInt {
        return 2
    }

    static func multiplier(ofTabBarHeight _: CGFloat) -> CGFloat {
        return 0.3
    }

    static func constantOfPlusButtonCenterYOffset(forTabBarHeight _: CGFloat) -> CGFloat {
        return -10
    }

    // #408: the plus button's identifier, read as `control.cyl_tabBarItemIdentifier`. PlusButton 的标识。
    static func tabBarItemIdentifier() -> String {
        return "plus"
    }

    static func plusChildViewController() -> UIViewController {
        let vc = PublishViewController()
        let nav = UINavigationController(rootViewController: vc)
        return nav
    }

    static func shouldSelectPlusChildViewController() -> Bool {
        return true
    }
}
