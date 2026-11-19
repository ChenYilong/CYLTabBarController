//
//  CYLSameCityViewController.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/**
 [EN] The "Nearby" tab of the Objective-C example (Swift since docs/Swift-Migration.md step 112): badge rows; a row pushes the
      details page without the navigation bar.
 [CN] Objective-C 示例的「同城」Tab（自第 112 步起为 Swift）：角标行；点击一行推入没有导航栏的详情页。
 */
@objc(CYLSameCityViewController)
class CYLSameCityViewController: CYLDemoBadgeTableViewController {

    override var placeholderAnimation: CYLDemoPlaceholderAnimation { .pag }

    override func didSelectPageRow(at _: IndexPath) {
        let viewController = CYLDetailsViewController()
        viewController.cyl_navigationBarHidden = true
        viewController.cyl_disablePopGestureRecognizer = true
        navigationController?.pushViewController(viewController, animated: true)
    }
}
