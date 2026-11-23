//
//  CYLMessageViewController.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/**
 [EN] The "Messages" tab of the Objective-C example (Swift since docs/Swift-Migration.md step 112): the playback controls of
      the tab icon animations, and rows that push tab bar controllers: the same context (row 0), a new context whose plus
      button has a tappable X subview (row 1, issue #202), or the other plus button (the other rows).
 [CN] Objective-C 示例的「消息」Tab（自第 112 步起为 Swift）：Tab 图标动画的播放控件，以及推入 TabBarController 的行：同一个 context
      （第 0 行）、PlusButton 带可点击 X 子按钮的新 context（第 1 行，issue #202）、另一个 PlusButton（其余行）。
 */
@objc(CYLMessageViewController)
class CYLMessageViewController: CYLDemoBadgeTableViewController {

    override var placeholderAnimation: CYLDemoPlaceholderAnimation { .rive }

    override func viewDidLoad() {
        super.viewDidLoad()
        // [EN] Play all, speed slider and loop switch (AGENTS.md, "Animated icon examples").
        // [CN] 「全部播放」、倍速滑块与循环开关（AGENTS.md「Animated icon examples」）。
        CYLDemoPlaybackControlsView.install(on: tableView, in: self)
        // [EN] Launch argument `-CYLDemoLifecycleLog` writes the lifecycle moments to the unified log (docs/Lifecycle-Library.md, step 21).
        // [CN] 启动参数 `-CYLDemoLifecycleLog` 把生命周期时机写入统一日志（docs/Lifecycle-Library.md，第 21 步）。
        if ProcessInfo.processInfo.arguments.contains("-CYLDemoLifecycleLog") {
            CYLAnimationEventBridge.logsLifecycleMoments(true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.leftBarButtonItem?.cyl_showBadge()
    }

    override func configure(_ cell: UITableViewCell, for indexPath: IndexPath) {
        cell.cylShowBadge(forRow: indexPath.row)
        cell.cylWrapsTextLabels()
        switch indexPath.row {
        case 0:
            // [EN] Pushes a tab bar controller of the SAME context. [CN] 推入同一个 context 的 TabBarController。
            cell.textLabel?.text = cylDemoLocalizedString("Push 同一个 context 的 TabBarController（同一个 PlusButton 类）")
            cell.detailTextLabel?.text = UITableViewCell.cylBadgeTitle(forRow: indexPath.row)
        case 1:
            // [EN] Issue #202: the plus button has a tappable X subview. [CN] Issue #202：PlusButton 带可点击的 X 子按钮。
            cell.textLabel?.text = cylDemoLocalizedString("Push 新 context 的 TabBarController（PlusButton 带可点击的 X 子按钮，issue #202）")
            cell.detailTextLabel?.text = cylDemoLocalizedString("点击 PlusButton 右上角的 X：X 随机改变颜色，PlusButton 不响应")
        default:
            super.configure(cell, for: indexPath)
        }
    }

    override func didSelectPageRow(at indexPath: IndexPath) {
        // [EN] As the plus button's "Switch Style" menu: the tab bar controller we push from keeps its own plus button.
        // [CN] 与 PlusButton“切换样式”菜单相同：当前的 TabBarController 保留自己的 PlusButton。
        let tabBarController: MainTabBarController
        switch indexPath.row {
        case 0:
            // [EN] The SAME context, without registering again: another instance of the same plus button class.
            // [CN] 相同的 context，不重新注册：同一个 PlusButton 类的另一个实例。
            tabBarController = MainTabBarController(context: cylTabBarController?.cyl_context ?? "")
            tabBarController.allowsVerticalBar = true
        case 1:
            tabBarController = CYLMainRootViewController.newLiquidGlassTabBarController(withPlusButtonClass: CYLCloseSubviewPlusButtonSubclass.self)
        default:
            tabBarController = CYLMainRootViewController.newLiquidGlassTabBarController(
                withPlusButtonClass: CYLPlusButtonSubclass.alternatePlusButtonClass(forOwner: self))
        }
        tabBarController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(tabBarController, animated: true)
    }
}
