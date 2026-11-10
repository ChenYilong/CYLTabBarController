//
//  HomeVC.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

class HomeVC: ViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = CYLDemoLocalizedString("首页")
        self.view.backgroundColor = .red

        addRightBarButtonItemImage("屏幕全屏", self, action: #selector(tapAction))
        // Animated badge in a random color on the right button. 右侧按钮上的随机颜色动画角标。
        cyl_showNavigationBadge(value: "", animationType: .shake, backgroundColor: UIColor.cyl_randomColor)
        cyl_addBadgeHelperTable()
    }
    
    @objc func tapAction() {
        let child = ChilderVC()
        self.navigationController?.pushViewController(child, animated: true)
    }
    
    
    
}
