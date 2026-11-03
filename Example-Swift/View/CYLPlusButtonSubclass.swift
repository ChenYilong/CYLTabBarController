//
//  CYLPlusButtonSubclass.swift
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit

class CYLPlusButtonSubclass: CYLPlusButton, CYLPlusButtonSubclassing {
    static func plusButton() -> Any {
        return CYLPlusButtonSubclass.cyl_plusButton(with: UIImage(named: "post_normal")!, title: "发布",
                                                    selectedTitle: "选中", selectedTitleColor: .blue)
    }

//    @objc static func testClick(sender: UIButton){
//        print("testClick")
//    }

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
