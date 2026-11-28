//
//  CYLMineViewController.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/**
 [EN] The "Me" tab of the Objective-C example (Swift since docs/Swift-Migration.md step 112): an opaque navigation bar, the dark
      style forced (it relays the tab bar out, a check for layout bugs), badge rows; a row shows its number as the tab's badge
      and pushes a page.
 [CN] Objective-C 示例的「我的」Tab（自第 112 步起为 Swift）：不透明导航栏，强制深色模式（会重新布局 TabBar，用于检查布局问题），角标行；
      点击一行把行号显示为 Tab 角标并推入一个页面。
 */
@objc(CYLMineViewController)
class CYLMineViewController: CYLDemoBadgeTableViewController {

    override var placeholderAnimation: CYLDemoPlaceholderAnimation { .gif }

    override var minimumBadgeRowCount: Int { 30 }

    override func viewDidLoad() {
        super.viewDidLoad()
        // [EN] An opaque navigation bar. [CN] 不透明的导航栏。
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.cyl_systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.cyl_label]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.compactAppearance = appearance
        // [EN] A dark mode switch relays the tab bar out: a check for common layout bugs.
        // [CN] 深色模式切换会重新布局 TabBar：用于检查常见的布局问题。
        overrideUserInterfaceStyle = .dark
    }

    override func didSelectPageRow(at indexPath: IndexPath) {
        // [EN] Shows the red dot. [CN] 展示红点。
        cyl_badgeCenterOffset = .zero
        cyl_showBadgeValue("\(indexPath.row)", animationType: .none)
        testPush()
    }

    /**
     [EN] Pushes a red page with the pop gesture off (also called by the details page). [CN] 推入一个关闭返回手势的红色页面（详情页也会调用）。
     */
    @objc func testPush() {
        let viewController = CYLBaseViewController()
        viewController.view.backgroundColor = .red
        viewController.cyl_disablePopGestureRecognizer = true
        navigationController?.pushViewController(viewController, animated: true)
    }
}
