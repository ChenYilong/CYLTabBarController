//
//  CYLBaseViewController.swift
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 [EN] A view controller that applies its navigation settings (`cyl_navigationBarHidden`, `cyl_disablePopGestureRecognizer`, …)
      as it appears and disappears. An `open` Swift class since docs/Swift-Migration.md step 113 (phase ②): subclasses are
      written in Swift (docs/Subclassing-In-Swift.md).
 [CN] 在出现与消失时应用导航设置（`cyl_navigationBarHidden`、`cyl_disablePopGestureRecognizer` 等）的视图控制器。自第 113 步（第 ② 阶段）起为
      `open` 的 Swift 类：子类用 Swift 编写（docs/Subclassing-In-Swift.md）。
 */
@objc(CYLBaseViewController)
open class CYLBaseViewController: UIViewController {

    open override func viewDidLoad() {
        super.viewDidLoad()
        view.layoutIfNeeded()
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cylViewWillAppearNavigationSetting(animated)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cylViewDidAppearNavigationSetting(animated)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cylViewWillDisappearNavigationSetting(animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cylViewDidDisappearNavigationSetting(animated)
    }

    deinit {
        cylDeallocNavigationSetting()
    }
}
