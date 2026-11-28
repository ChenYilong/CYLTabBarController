//
//  CYLMessageViewController.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController
import CYLDeallocBlockExecutor

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
        let playbackControls = CYLDemoPlaybackControlsView.install(on: tableView, in: self)
        // [EN] The teardown of the library lifecycle (docs/Lifecycle-Library.md, step 21): releases the tab bar controller and
        //      shows that its dealloc callbacks ran. [CN] 库生命周期的销毁（docs/Lifecycle-Library.md，第 21 步）：释放 TabBarController，并显示其 dealloc 回调已执行。
        playbackControls.appendRow(CYLDemoReleaseRow(viewController: self))
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


/**
 [EN] Counts the dealloc callbacks that ran for the objects released by `CYLDemoReleaseRow`. A callback is registered on each
      object through CYLDeallocBlockExecutor (`cylWillDealloc(key:)`), so the number is the library's own evidence that the
      tab bar controller was released.
 [CN] 统计 `CYLDemoReleaseRow` 所释放对象的 dealloc 回调执行次数。每个对象都通过 CYLDeallocBlockExecutor（`cylWillDealloc(key:)`）
      登记了回调，因此该数字是库本身给出的「TabBarController 已被释放」的证据。
 */
enum CYLDemoTeardown {
    static let didChangeNotification = Notification.Name("CYLDemoTeardownDidChange")
    private(set) static var armed: [String] = []
    private(set) static var ran: [String] = []

    /// [EN] Registers a dealloc callback on `object`, named `name` in the report. [CN] 在 `object` 上登记 dealloc 回调，报告中名为 `name`。
    static func arm(_ object: NSObject, name: String) {
        armed.append(name)
        _ = object.cylWillDealloc(key: "cyl.demo.teardown") { _, _, _ in
            ran.append(name)
            NotificationCenter.default.post(name: didChangeNotification, object: nil)
        }
    }

    static var summary: String {
        ran.isEmpty ? String(format: cylDemoLocalizedString("dealloc callbacks ran: %d / %d"), ran.count, armed.count)
            : String(format: cylDemoLocalizedString("dealloc callbacks ran: %d / %d (%@)"), ran.count, armed.count, ran.joined(separator: ", "))
    }
}

/**
 [EN] The row "Release the tab bar controller" of the playback card: after a 3 second countdown it replaces the window's root
      view controller with `CYLDemoReleasedViewController`, which drops the tab bar controller; the label shows how many dealloc
      callbacks ran. The texts are localized (CYLDemo.bundle); only the identifiers and counters inside them are not.
 [CN] 播放卡片中的「释放 TabBarController」行：倒计时 3 秒后，把窗口的根视图控制器换成 `CYLDemoReleasedViewController`，
      TabBarController 随之被释放；标签显示已执行的 dealloc 回调数。文字已本地化（CYLDemo.bundle），其中的标识符与计数不翻译。
 */
final class CYLDemoReleaseRow: UIStackView {
    private weak var viewController: UIViewController?
    private let button = UIButton(type: .system)
    private let statusLabel = UILabel()
    private var timer: Timer?

    init(viewController: UIViewController) {
        self.viewController = viewController
        super.init(frame: .zero)
        axis = .vertical
        spacing = 6
        button.setTitle(cylDemoLocalizedString("Release the tab bar controller (in 3 s)"), for: .normal)
        button.contentHorizontalAlignment = .leading
        button.accessibilityIdentifier = "CYLDemoReleaseTabBarController"
        button.addTarget(self, action: #selector(start), for: .touchUpInside)
        statusLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        statusLabel.textColor = .secondaryLabel
        statusLabel.numberOfLines = 0
        statusLabel.text = cylDemoLocalizedString("teardown: not run")
        statusLabel.accessibilityIdentifier = "CYLDemoTeardownStatus"
        addArrangedSubview(button)
        addArrangedSubview(statusLabel)
    }

    @available(*, unavailable)
    required init(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func start() {
        guard timer == nil, let tabBarController = viewController?.cylTabBarController,
              let window = tabBarController.view.window else {
            return
        }
        // [EN] The tab bar controller and the window's root controller (the app's container, when it is another object).
        // [CN] TabBarController 与窗口的根控制器（当它是另一个对象时，即 App 的容器）。
        CYLDemoTeardown.arm(tabBarController, name: "CYLTabBarController")
        if let root = window.rootViewController, root !== tabBarController {
            CYLDemoTeardown.arm(root, name: String(describing: type(of: root)))
        }
        var remaining = 3
        statusLabel.text = String(format: cylDemoLocalizedString("teardown: releasing in %d s"), remaining)
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self, weak window] timer in
            remaining -= 1
            if remaining > 0 {
                self?.statusLabel.text = String(format: cylDemoLocalizedString("teardown: releasing in %d s"), remaining)
                return
            }
            timer.invalidate()
            self?.timer = nil
            window?.rootViewController = CYLDemoReleasedViewController()
        }
    }
}

/**
 [EN] What the window shows after the tab bar controller was released: the dealloc callbacks that ran (it listens until they
      all ran) and the animation bridge counters.
 [CN] TabBarController 被释放后窗口显示的内容：已执行的 dealloc 回调（等所有回调都执行完为止）与动画桥接计数。
 */
final class CYLDemoReleasedViewController: UIViewController {
    private let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        label.font = .monospacedSystemFont(ofSize: 17, weight: .regular)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.accessibilityIdentifier = "CYLDemoReleasedStatus"
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
        ])
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: CYLDemoTeardown.didChangeNotification, object: nil)
        refresh()
    }

    @objc private func refresh() {
        label.text = cylDemoLocalizedString("Tab bar controller released") + "\n\n\(CYLDemoTeardown.summary)\n\n"
            + String(format: cylDemoLocalizedString("bridge: pause %d, resume %d"), CYLAnimationEventBridge.pauseCount, CYLAnimationEventBridge.resumeCount)
    }
}
