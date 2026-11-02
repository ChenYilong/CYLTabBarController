//
//  HomeViewController.swift
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/// The home page: the badge samples, plus an animated badge in a random color on the navigation bar.
/// 首页：角标样例列表，以及导航栏上随机颜色的动画角标。
final class HomeViewController: CYLBadgeHelperTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // No navigation bar button here: a bell button is added first. 没有导航栏按钮：先添加铃铛按钮。
        cyl_showNavigationBadge(value: "new", animationType: .breathe, backgroundColor: UIColor.cyl_randomColor)
    }
}
