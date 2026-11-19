//
//  CYLDetailsViewController.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/**
 [EN] The details page pushed from "Nearby" (Swift since docs/Swift-Migration.md step 112): landscape while shown, a badge on the
      back button; a tap selects the "Me" tab and pushes its test page.
 [CN] 从「同城」推入的详情页（自第 112 步起为 Swift）：显示期间为横屏，返回按钮带角标；点击屏幕选中「我的」并推入其测试页面。
 */
@objc(CYLDetailsViewController)
class CYLDetailsViewController: CYLBaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .orange
        let label = UILabel()
        label.text = cylDemoLocalizedString("点击屏幕可跳转到“我的”，执行testPush")
        label.frame = CGRect(x: 20, y: 150, width: view.frame.width - 2 * 20, height: 20)
        label.autoresizingMask = .flexibleWidth
        label.textAlignment = .center
        view.addSubview(label)
        // [EN] #425: the badge style comes from CYLBadgeAppearance (SceneDelegate). [CN] #425：角标样式来自 CYLBadgeAppearance（SceneDelegate）。
        navigationItem.backBarButtonItem?.cyl_showBadge()
        navigationItem.backBarButtonItem?.cyl_showBadgeValue("", animationType: .scale)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cyl_sharedAppDelegate()?.cyl_forceUpdateInterfaceOrientation(.landscapeLeft)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cyl_sharedAppDelegate()?.cyl_forceUpdateInterfaceOrientation(.portrait)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        cyl_popSelectTabBarChildViewController(forClassType: CYLMineViewController.self) { selected in
            (selected as? CYLMineViewController)?.testPush()
        }
    }
}
