//
//  MainTabBarController.swift
//  SwiftDemo
//
//  Created by Anthony on 2017/12/29.
//  Copyright © 2017年 Anthony. All rights reserved.
//

import UIKit
import CYLTabBarController

class MainTabBarController: CYLTabBarController, CYLFlatDesignUITabBarControllerDelegate {

    // #535: the plus button's badge, shared by every Swift demo (Example-Shared/CYLPlusButtonBadgeDemo.swift).
    // #535：PlusButton 的角标，所有 Swift Demo 共用（Example-Shared/CYLPlusButtonBadgeDemo.swift）。
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        demoShowPlusButtonBadgeAfterLayout()
    }

    override func tabBarController(_ _: CYLTabBarController, didSelect control: UIControl) {
        demoPlusButtonDidTap(control)
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        tabBarItemAnimationSpeed = 1.5 // Issue #428: tab icon animations at 1.5x (no effect without an animation subspec) Tab 图标动画 1.5 倍速
    }
    
    
    
}

extension MainTabBarController{
    
    override func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        self.updateSelectionStatusIfNeeded(for: tabBarController, shouldSelect: viewController)
        return true
    }
    
}
