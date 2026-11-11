//
//  HomeVC.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit
import CYLTabBarController

class HomeVC: ViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = cylDemoLocalizedString("首页")
        self.view.backgroundColor = .red

        addRightBarButtonItemImage("屏幕全屏", self, action: #selector(tapAction))
        // Animated badge in a random color on the right button. 右侧按钮上的随机颜色动画角标。
        cyl_showNavigationBadge(value: "", animationType: .shake, backgroundColor: UIColor.cyl_randomColor)
        addBadgeHelperTable()
    }
    
    /// [EN] The library's badge helper list, inset grouped like the other demo lists (rounded section backgrounds);
    ///      `cyl_addBadgeHelperTable()` would add it in the plain style.
    /// [CN] 库提供的角标辅助列表，与其他示例列表一样使用 inset grouped（分组圆角背景）；`cyl_addBadgeHelperTable()` 会以 plain 样式添加。
    private func addBadgeHelperTable() {
        let badgeHelper = CYLBadgeHelperTableViewController(style: .insetGrouped)
        addChild(badgeHelper)
        badgeHelper.view.frame = view.bounds
        badgeHelper.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(badgeHelper.view)
        badgeHelper.didMove(toParent: self)
    }

    @objc func tapAction() {
        let child = ChilderVC()
        self.navigationController?.pushViewController(child, animated: true)
    }
    
    
    
}
