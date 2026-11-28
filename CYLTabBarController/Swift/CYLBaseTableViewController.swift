//
//  CYLBaseTableViewController.swift
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 [EN] The table view controller counterpart of `CYLBaseViewController`. An `open` Swift class since docs/Swift-Migration.md
      step 113 (phase ②).
 [CN] 与 `CYLBaseViewController` 对应的表格视图控制器。自第 113 步（第 ② 阶段）起为 `open` 的 Swift 类。
 */
@objc(CYLBaseTableViewController)
open class CYLBaseTableViewController: UITableViewController {

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
