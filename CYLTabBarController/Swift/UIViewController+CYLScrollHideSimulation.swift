//
//  UIViewController+CYLScrollHideSimulation.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * FIX: issue #13
 * [EN] Scroll hiding: rows that simulate the interruptions the tab bar must come back from. Each row turns scroll hiding on
 *      and fires its interruption after `delay`, so there is time to scroll down and hide the bar first. Row titles name the
 *      API or event they trigger; system events that cannot be triggered from code (a real call, the low battery alert) are
 *      simulated by posting the notifications the system posts.
 * [CN] 滚动隐藏：模拟各种意外情况的演示行，TabBar 都必须从中恢复显示。每行先开启滚动隐藏，并在 `delay` 之后触发，留出时间先向下滚动隐藏
 *      TabBar。行标题即触发的 API 或事件名称；无法用代码触发的系统事件（真实来电、低电量弹框）通过发送系统会发送的通知来模拟。
 */
enum CYLScrollHideSimulation {

    enum Row: Int, CaseIterable {
        case alert, actionSheet, fullScreenModal, pageSheet, pushThenPop, pushHidesBottomBar, switchTab, resignActive
        case backgroundForeground, notificationTapPush, memoryWarning, overlayWindow, keyboard, shareSheet, scrollToTopInCode
        case scrollDownInCode, appHidesTabBar, turnOffAndOn, voiceOverStatus, keyboardWhileScrolling, reduceMotionStatus
        case lowPowerMode, rotation, overCurrentContext, popover, drawer, safeAreaTop, sceneDeactivate, manualLongPress
        case manualTapOutside, manualKeepDragging, realBackground, realSystemAlert, otherAppKeyboard, guidedAccess
        case sameTabAgain, turnOnAgain, appShowsTabBar, selfTest
    }

    /**
     * [EN] What a simulation expects. [CN] 模拟的预期。
     */
    enum Kind {
        /**
         * [EN] The bar comes back. [CN] TabBar 恢复显示。
         */
        case restore
        /**
         * [EN] The bar does not change. [CN] TabBar 不变。
         */
        case keep
        /**
         * [EN] Done by hand, as the title says; the bar comes back. [CN] 按标题手动操作；TabBar 恢复显示。
         */
        case manual
        /**
         * [EN] Runs the automatic self-test. [CN] 运行自动自测。
         */
        case selfTest
    }

    /**
     * [EN] What the self-test expects after a simulation. [CN] 自测在模拟之后的预期。
     */
    enum Expectation {
        /**
         * [EN] Not automatic (manual, real, leaves the app). [CN] 不能自动执行（手动、真实触发、会离开 App）。
         */
        case skip
        /**
         * [EN] The bar is shown again. [CN] TabBar 重新显示。
         */
        case restored
        /**
         * [EN] The bar stays hidden by scroll hiding. [CN] TabBar 保持被滚动隐藏。
         */
        case stillHidden
        /**
         * [EN] The app took the bar over: hidden, but not by scroll hiding. [CN] App 接管了 TabBar：已隐藏，但不是滚动隐藏。
         */
        case appHidden
    }

    /**
     * [EN] Seconds between the tap and the interruption. [CN] 点击到触发之间的秒数。
     */
    static let delay: TimeInterval = 1.5
    /**
     * [EN] Seconds a temporary page, window or keyboard stays. [CN] 临时页面、窗口或键盘停留的秒数。
     */
    static let hold: TimeInterval = 1.5
    /**
     * [EN] Self-test: when a simulation is checked, when the next one starts, the wait after the simulated hide, and how
     *      much longer a restore row may wait for a slow presentation (e.g. a share sheet on a simulator).
     * [CN] 自测：检查模拟结果的时间、开始下一个模拟的时间、模拟隐藏后的等待时间，以及“应恢复”的行为等待较慢的 present（例如模拟器上的
     *      分享面板）最多再等待的时间。
     */
    static let checkDelay: TimeInterval = 2.7
    static let nextDelay: TimeInterval = 1.5
    static let hideSettleDelay: TimeInterval = 0.6
    static let restoreExtraWait: TimeInterval = 8

    static func after(_ seconds: TimeInterval, _ block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: block)
    }

    /**
     * [EN] The row's title (the API or event it triggers, the same in every language, so not translated) and its kind.
     * [CN] 行标题（触发的 API 或事件，在所有语言中都相同，因此不翻译）及其类型。
     */
    static func title(of row: Row) -> (String, Kind) {
        switch row {
        case .alert: return ("UIAlertController (alert)", .restore)
        case .actionSheet: return ("UIAlertController (actionSheet)", .restore)
        case .fullScreenModal: return ("present (UIModalPresentationFullScreen)", .restore)
        case .pageSheet: return ("present (UIModalPresentationPageSheet)", .restore)
        case .pushThenPop: return ("push, then pop", .restore)
        case .pushHidesBottomBar: return ("push (hidesBottomBarWhenPushed), then pop", .restore)
        case .switchTab: return ("selectedIndex + 1, then back", .restore)
        case .resignActive: return ("WillResignActive / DidBecomeActive (call, low battery, system alert)", .restore)
        case .backgroundForeground: return ("DidEnterBackground / WillEnterForeground", .restore)
        case .notificationTapPush: return ("Push notification tap: foreground, then push", .restore)
        case .memoryWarning: return ("UIApplicationDidReceiveMemoryWarningNotification", .restore)
        case .overlayWindow: return ("UIWindow (alert level) makeKeyAndVisible", .restore)
        case .keyboard: return ("UITextField becomeFirstResponder (keyboard)", .restore)
        case .shareSheet: return ("UIActivityViewController", .restore)
        case .scrollToTopInCode: return ("setContentOffset: top (status bar tap)", .restore)
        case .scrollDownInCode: return ("setContentOffset: down, in code", .keep)
        case .appHidesTabBar: return ("App: setTabBarHidden:YES for 4 s", .keep)
        case .turnOffAndOn: return ("cyl_hidesTabBarOnScroll = NO, then YES", .restore)
        case .voiceOverStatus: return ("UIAccessibilityVoiceOverStatusDidChangeNotification", .restore)
        case .keyboardWhileScrolling: return ("Keyboard up for 4 s: scroll, the bar must not hide", .keep)
        case .reduceMotionStatus: return ("UIAccessibilityReduceMotionStatusDidChangeNotification", .restore)
        case .lowPowerMode: return ("NSProcessInfoPowerStateDidChangeNotification (Low Power Mode)", .restore)
        case .rotation: return ("requestGeometryUpdate: landscape, then portrait (iOS 16+)", .restore)
        case .overCurrentContext: return ("present (OverCurrentContext) from a page that definesPresentationContext", .restore)
        case .popover: return ("present (UIModalPresentationPopover)", .restore)
        case .drawer: return ("tabBarController.view slides away and back (side menu / drawer)", .restore)
        case .safeAreaTop: return ("additionalSafeAreaInsets.top + 20 (in-call / hotspot status bar)", .restore)
        case .sceneDeactivate: return ("UISceneWillDeactivateNotification (this scene)", .restore)
        case .manualLongPress: return ("Manual: long press a row (context menu, drag, text selection)", .manual)
        case .manualTapOutside: return ("Manual: tap a navigation bar button (UIMenu, action)", .manual)
        case .manualKeepDragging: return ("Manual: after a restore, fling on without lifting; only a new drag hides it", .manual)
        case .realBackground: return ("Real: open Settings (the app really goes to the background; come back)", .restore)
        case .realSystemAlert: return ("Real system alert: tel:// call prompt (iPhone; tap Cancel)", .restore)
        case .otherAppKeyboard: return ("UIKeyboardWillShow of another app (UIKeyboardIsLocalUserInfoKey = NO)", .keep)
        case .guidedAccess: return ("UIAccessibilityGuidedAccessStatusDidChangeNotification", .restore)
        case .sameTabAgain: return ("selectedIndex = the same tab (no change)", .keep)
        case .turnOnAgain: return ("cyl_hidesTabBarOnScroll = YES again (no change)", .keep)
        case .appShowsTabBar: return ("App: setTabBarHidden:NO", .restore)
        case .selfTest: return ("Self-test: run every automatic simulation, report PASS / FAIL", .selfTest)
        }
    }

    static func expectation(of row: Row) -> Expectation {
        switch row {
        case .scrollDownInCode, .otherAppKeyboard, .sameTabAgain, .turnOnAgain:
            return .stillHidden
        case .appHidesTabBar:
            return .appHidden
        case .keyboardWhileScrolling, .rotation, .manualLongPress, .manualTapOutside, .manualKeepDragging, .realBackground,
             .realSystemAlert, .selfTest:
            return .skip
        default:
            return .restored
        }
    }
}

extension UIViewController {

    /**
     * [EN] Number of simulations. [CN] 模拟的数量。
     */
    @objc(cyl_scrollHideSimulationRowCount)
    public func cyl_scrollHideSimulationRowCount() -> Int {
        CYLScrollHideSimulation.Row.allCases.count
    }

    /**
     * [EN] The cell of simulation `row`. [CN] 第 `row` 个模拟的 cell。
     */
    @objc(cyl_scrollHideSimulationCellForTableView:row:)
    public func cyl_scrollHideSimulationCell(for tableView: UITableView, row: Int) -> UITableViewCell {
        let identifier = "CYLScrollHideSimulationCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            cell.detailTextLabel?.numberOfLines = 0
            cell.imageView?.image = UIImage(systemName: "exclamationmark.triangle")
            return cell
        }()
        guard let simulation = CYLScrollHideSimulation.Row(rawValue: row) else {
            cell.textLabel?.text = "-"
            return cell
        }
        let (title, kind) = CYLScrollHideSimulation.title(of: simulation)
        cell.textLabel?.text = title
        switch kind {
        case .restore:
            cell.detailTextLabel?.text = CYLLocalizedString("点击后 1.5 秒触发。请先向下滚动隐藏 TabBar。预期：TabBar 立即恢复显示，惯性滚动不会再次隐藏。")
        case .keep:
            cell.detailTextLabel?.text = CYLLocalizedString("点击后 1.5 秒触发。预期：TabBar 的状态不因此改变（不会被隐藏，App 隐藏的也不会被显示）。")
        case .manual:
            cell.detailTextLabel?.text = CYLLocalizedString("手动操作：点击开启滚动隐藏，向下滚动隐藏 TabBar 后按标题操作。预期：TabBar 立即恢复显示。")
        case .selfTest:
            cell.detailTextLabel?.text = CYLLocalizedString("自动依次运行所有可自动化的模拟并报告通过 / 失败（约 2 分钟），结果同时打印到控制台。也可以用启动参数 -CYLScrollHideSelfTest YES 运行。")
        }
        return cell
    }

    /**
     * [EN] Runs simulation `row` after 1.5 s (a manual row only turns scroll hiding on; the user does the rest).
     * [CN] 1.5 秒后执行第 `row` 个模拟（手动行只开启滚动隐藏，其余由用户操作）。
     */
    @objc(cyl_didSelectScrollHideSimulationRow:)
    public func cyl_didSelectScrollHideSimulationRow(_ row: Int) {
        guard let tabBarController = cyl_owningTabBarController() ?? cyl_tabBarController,
              let simulation = CYLScrollHideSimulation.Row(rawValue: row) else {
            return
        }
        tabBarController.cyl_hidesTabBarOnScroll = true
        switch CYLScrollHideSimulation.title(of: simulation).1 {
        case .manual:
            return
        case .selfTest:
            cyl_runScrollHideSelfTest()
        case .restore, .keep:
            CYLScrollHideSimulation.after(CYLScrollHideSimulation.delay) { [weak self] in
                self?.cyl_runScrollHideSimulation(simulation, tabBarController: tabBarController)
            }
        }
    }

    /**
     * [EN] Lists every simulation in an action sheet; the chosen one fires after 1.5 s.
     * [CN] 用操作表列出全部模拟，所选模拟在 1.5 秒后触发。
     */
    @objc(cyl_presentScrollHideSimulationMenu)
    public func cyl_presentScrollHideSimulationMenu() {
        let menu = UIAlertController(title: CYLLocalizedString("滚动隐藏：模拟意外情况（issue #13）"),
                                     message: CYLLocalizedString("选择一种意外情况，1.5 秒后触发。请先向下滚动隐藏 TabBar。"),
                                     preferredStyle: .actionSheet)
        for simulation in CYLScrollHideSimulation.Row.allCases {
            menu.addAction(UIAlertAction(title: CYLScrollHideSimulation.title(of: simulation).0, style: .default) { [weak self] _ in
                self?.cyl_didSelectScrollHideSimulationRow(simulation.rawValue)
            })
        }
        menu.addAction(UIAlertAction(title: CYLLocalizedString("取消"), style: .cancel))
        cyl_anchorPopover(menu.popoverPresentationController)
        present(menu, animated: true)
    }

    private func cyl_anchorPopover(_ popover: UIPopoverPresentationController?) {
        popover?.sourceView = view
        popover?.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1)
    }

    /**
     * [EN] The scroll view of this page. [CN] 当前页面的滚动视图。
     */
    private var cyl_scrollHideSimulationScrollView: UIScrollView? {
        (self as? UITableViewController)?.tableView ?? view as? UIScrollView
    }

    /**
     * [EN] A plain page that leaves by itself. [CN] 一个会自行离开的普通页面。
     */
    private func cyl_scrollHideSimulationPage() -> UIViewController {
        let page = UIViewController()
        page.view.backgroundColor = UIColor(red: 0.35, green: 0.78, blue: 0.98, alpha: 1)
        return page
    }

    private func cyl_presentThenDismiss(_ page: UIViewController, completion: (() -> Void)? = nil) {
        present(page, animated: true) {
            CYLScrollHideSimulation.after(CYLScrollHideSimulation.hold) {
                page.dismiss(animated: true, completion: completion)
            }
        }
    }

    private func cyl_showKeyboard(for seconds: TimeInterval) {
        let textField = UITextField(frame: CGRect(x: 0, y: -100, width: 10, height: 10))
        view.addSubview(textField)
        textField.becomeFirstResponder()
        CYLScrollHideSimulation.after(seconds) {
            textField.resignFirstResponder()
            textField.removeFromSuperview()
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func cyl_runScrollHideSimulation(_ simulation: CYLScrollHideSimulation.Row, tabBarController: CYLTabBarController) {
        let center = NotificationCenter.default
        let application = UIApplication.shared
        let hold = CYLScrollHideSimulation.hold
        let after = CYLScrollHideSimulation.after
        switch simulation {
        case .alert, .actionSheet:
            let alert = UIAlertController(title: "CYLTabBarController", message: "#13", preferredStyle: simulation == .alert ? .alert : .actionSheet)
            alert.addAction(UIAlertAction(title: CYLLocalizedString("OK"), style: .cancel))
            cyl_anchorPopover(alert.popoverPresentationController)
            present(alert, animated: true)
        case .fullScreenModal, .pageSheet:
            let page = cyl_scrollHideSimulationPage()
            page.modalPresentationStyle = simulation == .fullScreenModal ? .fullScreen : .pageSheet
            cyl_presentThenDismiss(page)
        case .pushThenPop, .pushHidesBottomBar, .notificationTapPush:
            if simulation == .notificationTapPush {
                center.post(name: UIApplication.willEnterForegroundNotification, object: application)
                center.post(name: UIApplication.didBecomeActiveNotification, object: application)
            }
            let page = cyl_scrollHideSimulationPage()
            page.hidesBottomBarWhenPushed = simulation == .pushHidesBottomBar
            navigationController?.pushViewController(page, animated: true)
            after(hold) { [weak self] in self?.navigationController?.popViewController(animated: true) }
        case .switchTab:
            let original = tabBarController.selectedIndex
            let count = tabBarController.viewControllers?.count ?? 0
            if count > 1 {
                tabBarController.selectedIndex = (original + 1) % count
                after(hold) { tabBarController.selectedIndex = original }
            }
        case .resignActive:
            center.post(name: UIApplication.willResignActiveNotification, object: application)
            after(hold) { center.post(name: UIApplication.didBecomeActiveNotification, object: application) }
        case .backgroundForeground:
            center.post(name: UIApplication.didEnterBackgroundNotification, object: application)
            after(hold) {
                center.post(name: UIApplication.willEnterForegroundNotification, object: application)
                center.post(name: UIApplication.didBecomeActiveNotification, object: application)
            }
        case .memoryWarning:
            center.post(name: UIApplication.didReceiveMemoryWarningNotification, object: application)
        case .overlayWindow:
            let mainWindow = view.window
            let overlay = mainWindow?.windowScene.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: mainWindow?.bounds ?? .zero)
            overlay.windowLevel = .alert
            overlay.rootViewController = cyl_scrollHideSimulationPage()
            overlay.rootViewController?.view.alpha = 0.6
            overlay.makeKeyAndVisible()
            after(hold) {
                overlay.isHidden = true
                mainWindow?.makeKey()
            }
        case .keyboard:
            cyl_showKeyboard(for: hold)
        case .keyboardWhileScrolling:
            cyl_showKeyboard(for: 4)
        case .shareSheet:
            let share = UIActivityViewController(activityItems: ["https://github.com/ChenYilong/CYLTabBarController/issues/13"], applicationActivities: nil)
            cyl_anchorPopover(share.popoverPresentationController)
            present(share, animated: true)
        case .scrollToTopInCode:
            if let scrollView = cyl_scrollHideSimulationScrollView {
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -scrollView.adjustedContentInset.top), animated: true)
            }
        case .scrollDownInCode:
            if let scrollView = cyl_scrollHideSimulationScrollView {
                let maxOffsetY = max(-scrollView.adjustedContentInset.top,
                                     scrollView.contentSize.height + scrollView.adjustedContentInset.bottom - scrollView.bounds.height)
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: min(maxOffsetY, scrollView.contentOffset.y + 600)), animated: true)
            }
        case .appHidesTabBar:
            tabBarController.setTabBarHidden(true, animated: true)
            after(4) { tabBarController.setTabBarHidden(false, animated: true) }
        case .turnOffAndOn:
            tabBarController.cyl_hidesTabBarOnScroll = false
            after(hold) { tabBarController.cyl_hidesTabBarOnScroll = true }
        case .voiceOverStatus:
            center.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        case .reduceMotionStatus:
            center.post(name: UIAccessibility.reduceMotionStatusDidChangeNotification, object: nil)
        case .lowPowerMode:
            center.post(name: .NSProcessInfoPowerStateDidChange, object: ProcessInfo.processInfo)
        case .rotation:
            if #available(iOS 16.0, *), let windowScene = view.window?.windowScene {
                windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
                after(hold) { windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait)) }
            }
        case .overCurrentContext:
            let definedPresentationContext = definesPresentationContext
            definesPresentationContext = true
            let page = cyl_scrollHideSimulationPage()
            page.view.alpha = 0.7
            page.modalPresentationStyle = .overCurrentContext
            cyl_presentThenDismiss(page) { [weak self] in self?.definesPresentationContext = definedPresentationContext }
        case .popover:
            let page = cyl_scrollHideSimulationPage()
            page.modalPresentationStyle = .popover
            page.preferredContentSize = CGSize(width: 240, height: 160)
            cyl_anchorPopover(page.popoverPresentationController)
            cyl_presentThenDismiss(page)
        case .drawer:
            let controllerView = tabBarController.view!
            UIView.animate(withDuration: 0.3, animations: {
                controllerView.transform = CGAffineTransform(translationX: controllerView.bounds.width * 0.6, y: 0)
            }, completion: { _ in
                after(hold) { UIView.animate(withDuration: 0.3) { controllerView.transform = .identity } }
            })
        case .safeAreaTop:
            let insets = tabBarController.additionalSafeAreaInsets
            var taller = insets
            taller.top += 20
            tabBarController.additionalSafeAreaInsets = taller
            after(hold) { tabBarController.additionalSafeAreaInsets = insets }
        case .sceneDeactivate:
            if let windowScene = view.window?.windowScene {
                center.post(name: UIScene.willDeactivateNotification, object: windowScene)
                after(hold) { center.post(name: UIScene.didActivateNotification, object: windowScene) }
            }
        case .realBackground:
            // [EN] Not a simulation: the app really resigns active and goes to the background.
            // [CN] 不是模拟：App 真正失去活跃并进入后台。
            if let settings = URL(string: UIApplication.openSettingsURLString) {
                application.open(settings)
            }
        case .realSystemAlert:
            // [EN] Not a simulation: iPhone shows a real system prompt (none in the simulator). [CN] 不是模拟：iPhone 显示真实的系统提示（模拟器中不显示）。
            if let call = URL(string: "tel://10086") {
                application.open(call)
            }
        case .otherAppKeyboard:
            center.post(name: UIResponder.keyboardWillShowNotification, object: nil, userInfo: [UIResponder.keyboardIsLocalUserInfoKey: false])
            after(hold) {
                center.post(name: UIResponder.keyboardWillHideNotification, object: nil, userInfo: [UIResponder.keyboardIsLocalUserInfoKey: false])
            }
        case .guidedAccess:
            center.post(name: UIAccessibility.guidedAccessStatusDidChangeNotification, object: nil)
        case .sameTabAgain:
            tabBarController.selectedIndex = tabBarController.selectedIndex
        case .turnOnAgain:
            tabBarController.cyl_hidesTabBarOnScroll = true
        case .appShowsTabBar:
            tabBarController.setTabBarHidden(false, animated: true)
        case .selfTest, .manualLongPress, .manualTapOutside, .manualKeepDragging:
            break
        }
    }

    // MARK: Self-test

    /**
     * [EN] The automatic self-test: for every automatic simulation, scroll into the content, hide the bar as a downward scroll
     *      would (`-cyl_simulateHideOnScrollForTesting`), run the simulation, check the expected result, dismiss what it
     *      presented and go on. Logs one line per simulation (scripts/scroll-hide-self-test.sh reads the PASS / FAIL lines, so
     *      they stay in English) and shows a summary. Liquid Glass cannot be hidden from code, so every row is SKIP there.
     *      Launching the app with `-CYLScrollHideSelfTest YES` runs it once on the first page.
     * [CN] 自动自测：对每个可自动化的模拟，先滚入内容，像向下滚动一样隐藏 TabBar（`-cyl_simulateHideOnScrollForTesting`），执行模拟，检查
     *      预期结果，关闭它 present 的页面后继续。每个模拟打印一行日志（scripts/scroll-hide-self-test.sh 读取 PASS / FAIL 行，因此保持英文），
     *      最后显示汇总。液态玻璃无法用代码隐藏，因此其中每一行都为 SKIP。以 `-CYLScrollHideSelfTest YES` 启动 App 时会在第一个页面上运行一次。
     */
    @objc(cyl_runScrollHideSelfTest)
    public func cyl_runScrollHideSelfTest() {
        guard let tabBarController = cyl_owningTabBarController() ?? cyl_tabBarController else { return }
        tabBarController.cyl_hidesTabBarOnScroll = true
        NSLog("[CYLTabBarController] scroll hiding self-test: start (%@ simulations)", NSNumber(value: CYLScrollHideSimulation.Row.allCases.count))
        cyl_runScrollHideSelfTestRow(0, tabBarController: tabBarController, results: [], attempt: 0)
    }

    /**
     * [EN] Before each row, shows a bar left hidden (not by scrolling) and dismisses what a previous simulation left presented
     *      (a share sheet can appear seconds late on a simulator, and scroll hiding refuses to hide while a page is presented).
     *      Tries every 0.5 s, for at most 10 s.
     * [CN] 每一行开始前，显示遗留的隐藏（不是滚动隐藏）TabBar，并关闭上一个模拟遗留的页面（模拟器上分享面板可能在几秒后才出现，而有页面
     *      present 时滚动隐藏会拒绝隐藏）。每 0.5 秒尝试一次，最多 10 秒。
     */
    private func cyl_runScrollHideSelfTestRow(_ row: Int, tabBarController: CYLTabBarController, results: [String], attempt: Int) {
        guard let simulation = CYLScrollHideSimulation.Row(rawValue: row) else {
            cyl_finishScrollHideSelfTest(results)
            return
        }
        let retry = { [weak self] in
            CYLScrollHideSimulation.after(0.5) {
                self?.cyl_runScrollHideSelfTestRow(row, tabBarController: tabBarController, results: results, attempt: attempt + 1)
            }
        }
        if tabBarController.isTabBarHidden && !tabBarController.cyl_isTabBarHiddenByScroll && attempt < 20 {
            tabBarController.setTabBarHidden(false, animated: false)
            retry()
            return
        }
        let root = view.window?.rootViewController ?? tabBarController
        if let presented = root.presentedViewController, attempt < 20 {
            if !presented.isBeingDismissed {
                root.dismiss(animated: false)
            }
            retry()
            return
        }
        let title = CYLScrollHideSimulation.title(of: simulation).0
        let expectation = CYLScrollHideSimulation.expectation(of: simulation)
        let next: ([String]) -> Void = { [weak self] results in
            self?.cyl_runScrollHideSelfTestRow(row + 1, tabBarController: tabBarController, results: results, attempt: 0)
        }
        // [EN] Scroll into the content (in code: does not hide by itself), then hide as a downward scroll would.
        // [CN] 先滚入内容（代码滚动本身不会隐藏），再像向下滚动一样隐藏。
        if let scrollView = cyl_scrollHideSimulationScrollView {
            let minOffsetY = -scrollView.adjustedContentInset.top
            let maxOffsetY = max(minOffsetY, scrollView.contentSize.height + scrollView.adjustedContentInset.bottom - scrollView.bounds.height)
            scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: min(maxOffsetY, minOffsetY + 600)), animated: false)
        }
        if expectation == .skip || !tabBarController.cyl_simulateHideOnScrollForTesting() {
            let line = "SKIP \(title)"
            NSLog("[CYLTabBarController] scroll hiding self-test: %@", line as NSString)
            next(results + [line])
            return
        }
        // [EN] The simulation runs a moment after the hide, as a real interruption comes after the user scrolled: an app
        //      request repeating the last hide within 0.5 s is taken for a FlatDesign replay of it and ignored.
        // [CN] 隐藏之后稍等片刻再执行模拟，与真实的打断在用户滚动之后发生一致：0.5 秒内重复最近一次隐藏的 App 请求会被当作扁平样式对它的
        //      重放而忽略。
        CYLScrollHideSimulation.after(CYLScrollHideSimulation.hideSettleDelay) { [weak self] in
            self?.cyl_runScrollHideSimulation(simulation, tabBarController: tabBarController)
            CYLScrollHideSimulation.after(CYLScrollHideSimulation.checkDelay) {
                self?.cyl_checkScrollHideSelfTest(title: title, expectation: expectation, tabBarController: tabBarController,
                                                  results: results, next: next, waited: 0)
            }
        }
    }

    /**
     * [EN] Checks one row. A row that expects the bar back is polled every 0.5 s for up to `restoreExtraWait` more seconds
     *      before it fails; the other expectations are checked once. Then cleans up and goes on.
     * [CN] 检查一行。期望 TabBar 恢复的行在判为失败前，每 0.5 秒再检查一次，最多再等 `restoreExtraWait` 秒；其他期望只检查一次。然后清理并继续。
     */
    private func cyl_checkScrollHideSelfTest(title: String, expectation: CYLScrollHideSimulation.Expectation,
                                             tabBarController: CYLTabBarController, results: [String],
                                             next: @escaping ([String]) -> Void, waited: TimeInterval) {
        let hiddenByScroll = tabBarController.cyl_isTabBarHiddenByScroll
        if expectation == .restored && hiddenByScroll && waited < CYLScrollHideSimulation.restoreExtraWait {
            CYLScrollHideSimulation.after(0.5) { [weak self] in
                self?.cyl_checkScrollHideSelfTest(title: title, expectation: expectation, tabBarController: tabBarController,
                                                  results: results, next: next, waited: waited + 0.5)
            }
            return
        }
        let passed: Bool
        switch expectation {
        case .restored: passed = !hiddenByScroll
        case .stillHidden: passed = hiddenByScroll
        case .appHidden: passed = !hiddenByScroll && tabBarController.isTabBarHidden
        case .skip: passed = false
        }
        let line = "\(passed ? "PASS" : "FAIL") \(title)"
        NSLog("[CYLTabBarController] scroll hiding self-test: %@", line as NSString)
        // [EN] Clean up: dismiss what is still presented, show a bar left hidden. [CN] 清理：关闭仍在显示的页面，显示仍被隐藏的 TabBar。
        let root = view.window?.rootViewController ?? tabBarController
        if let presented = root.presentedViewController, !presented.isBeingDismissed {
            root.dismiss(animated: false)
        }
        var wait = CYLScrollHideSimulation.nextDelay
        if expectation == .appHidden {
            wait += 2
        } else if tabBarController.isTabBarHidden {
            tabBarController.setTabBarHidden(false, animated: false)
        }
        CYLScrollHideSimulation.after(wait) { next(results + [line]) }
    }

    private func cyl_finishScrollHideSelfTest(_ results: [String]) {
        let passed = results.filter { $0.hasPrefix("PASS") }.count
        let failed = results.filter { $0.hasPrefix("FAIL") }.count
        let summary = "\(passed) passed, \(failed) failed, \(results.count - passed - failed) skipped"
        NSLog("[CYLTabBarController] scroll hiding self-test: done: %@", summary as NSString)
        let alert = UIAlertController(title: "Scroll hiding self-test (#13)", message: summary + "\n\n" + results.joined(separator: "\n"),
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: CYLLocalizedString("OK"), style: .cancel))
        present(alert, animated: true)
    }
}
