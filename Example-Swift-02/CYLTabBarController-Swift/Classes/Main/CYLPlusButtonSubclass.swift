//
//  CYLPlusButtonSubclass.swift
//  SwiftDemo
//
//  Created by Anthony on 2017/12/29.
//  Copyright © 2017年 Anthony. All rights reserved.
//

import UIKit
import CYLTabBarController

class CYLPlusButtonSubclass: CYLPlusButton,CYLPlusButtonSubclassing {

    
    static func plusButton() -> Any {
        return CYLPlusButtonSubclass.cyl_plusButton(with: UIImage(named: "post_normal")!, title: "发布",
                                                    selectedTitle: "选中", selectedTitleColor: UIColor(red: 1, green: 102.0 / 255.0, blue: 0, alpha: 1))
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
