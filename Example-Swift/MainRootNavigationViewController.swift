//
//  MainRootNavigationViewController.swift
//  CYLTabBarController-Swift
//
//  Created by chenyilong on 2026/4/13.
//  Copyright © 2026 Anthony. All rights reserved.
//

import Foundation
import UIKit
import CYLTabBarController

class MainRootNavigationViewController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let mainTabBarVc = MainTabBarController(context: "")
        self.viewControllers = [mainTabBarVc]
    }
    
    
}

 
