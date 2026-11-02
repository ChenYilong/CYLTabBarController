//
//  MainTabBarController.swift
//  SwiftDemo
//
//  Created by Anthony on 2017/12/29.
//  Copyright © 2017年 Anthony. All rights reserved.
//

import UIKit
import CYLTabBarController

class MainTabBarController: CYLTabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        lottieAnimationSpeed = 1.5 // Issue #428: Lottie tab icons at 1.5x (no effect without Lottie) Lottie 图标 1.5 倍速
    }
    
    
    
}

extension MainTabBarController{
    
    override func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        self.updateSelectionStatusIfNeeded(for: tabBarController, shouldSelect: viewController)
        return true
    }
    
}


