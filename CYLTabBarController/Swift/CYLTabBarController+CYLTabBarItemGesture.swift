//
//  CYLTabBarController+CYLTabBarItemGesture.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import QuartzCore
import UIKit

/**
 * [EN] What the gesture recognition remembers between taps: the last tapped control and when, the view controller that was
 *      selected after the previous tap, and whether this run loop turn already reported a control (programmatic selection can
 *      report the same control twice in one turn; that is not a second tap).
 * [CN] 手势识别在两次点击之间记录的信息：上次点击的控件与时间、上次点击后选中的控制器，以及当前 runloop 是否已上报过控件（代码切换时同一
 *      runloop 内可能上报同一控件两次，这不是第二次点击）。
 */
final class CYLTabBarItemGestureState: NSObject {
    weak var lastControl: UIControl?
    var lastTapTime: CFTimeInterval = 0
    weak var selectedViewControllerBeforeTap: UIViewController?
    weak var controlReportedInCurrentRunLoop: UIControl?
    /// [EN] YES once a tab tap came through `-cyl_recognizeTabBarItemTapWillSelectViewController:`.
    /// [CN] 一旦有 Tab 点击经过 `-cyl_recognizeTabBarItemTapWillSelectViewController:` 即为 YES。
    var receivesTabTapsBeforeSelection = false
}

/**
 * [EN] The settings of the item gestures, attached to a tab bar controller. [CN] 附加到 TabBarController 上的 item 手势设置。
 */
final class CYLTabBarItemGestureSettings: NSObject {
    var handler: (@convention(block) (CYLTabBarController, CYLTabBarItemGesture, UIControl, UIViewController?) -> Void)?
    var doubleTapInterval: NSNumber?
    var state: CYLTabBarItemGestureState?
}

enum CYLTabBarItemGestureKeys {
    static let settings = CYLUtilsKeys.key("cyl_tabBarItemGestureSettings")
}

/**
 * [EN] `CYLTabBarController (CYLTabBarItemGesture)`: tab bar item gestures: tap, double tap and long press (issue #152).
 *      Translated from Objective-C (docs/Swift-Migration.md, step 38). `CYLTabBarController` is still an Objective-C class, so
 *      the declarations stay in `CYLTabBarController.h` and `CYLTabBarController+CYLPrivate.h`, and these members are internal
 *      `@objc` methods with the declared selectors.
 * [CN] `CYLTabBarController (CYLTabBarItemGesture)`：Tab bar item 手势：单击、双击与长按（issue #152）。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 38 步）。`CYLTabBarController` 仍是 Objective-C 类，因此声明仍在 `CYLTabBarController.h` 与
 *      `CYLTabBarController+CYLPrivate.h` 中，这些成员是使用已声明 selector 的 internal `@objc` 方法。
 */
extension CYLTabBarController {

    /**
     * [EN] Calls a method declared only in the private header (`CYLTabBarController+CYLPrivate.h`) by its selector.
     * [CN] 通过 selector 调用只在私有头文件（`CYLTabBarController+CYLPrivate.h`）中声明的方法。
     */
    private func cylPrivateVoid(_ name: String, _ argument: Any?) {
        let selector = NSSelectorFromString(name)
        guard responds(to: selector) else { return }
        if let argument {
            _ = perform(selector, with: argument)
        } else {
            _ = perform(selector)
        }
    }

    private func cylPrivateBool(_ name: String) -> Bool {
        let selector = NSSelectorFromString(name)
        guard responds(to: selector), let implementation = method(for: selector) else { return false }
        typealias Function = @convention(c) (AnyObject, Selector) -> Bool
        return unsafeBitCast(implementation, to: Function.self)(self, selector)
    }

    private var cyl_gestureSettings: CYLTabBarItemGestureSettings {
        if let settings = objc_getAssociatedObject(self, CYLTabBarItemGestureKeys.settings) as? CYLTabBarItemGestureSettings {
            return settings
        }
        let settings = CYLTabBarItemGestureSettings()
        objc_setAssociatedObject(self, CYLTabBarItemGestureKeys.settings, settings, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return settings
    }

    @objc(cyl_tabBarItemGestureHandler)
    func cylTabBarItemGestureHandler() -> (@convention(block) (CYLTabBarController, CYLTabBarItemGesture, UIControl, UIViewController?) -> Void)? {
        cyl_gestureSettings.handler
    }

    @objc(cyl_setTabBarItemGestureHandler:)
    func cylSetTabBarItemGestureHandler(_ handler: (@convention(block) (CYLTabBarController, CYLTabBarItemGesture, UIControl, UIViewController?) -> Void)?) {
        cyl_gestureSettings.handler = handler
        if isViewLoaded {
            cylInstallTabBarItemLongPressIfNeeded()
        }
    }

    @objc(cyl_tabBarItemDoubleTapInterval)
    func cylTabBarItemDoubleTapInterval() -> TimeInterval {
        cyl_gestureSettings.doubleTapInterval?.doubleValue ?? 0.35
    }

    @objc(cyl_setTabBarItemDoubleTapInterval:)
    func cylSetTabBarItemDoubleTapInterval(_ interval: TimeInterval) {
        cyl_gestureSettings.doubleTapInterval = NSNumber(value: max(interval, 0))
    }

    /**
     * [EN] The same duration as `cyl_tabButtonLongPressMinimumDuration` (issue #535): one recognizer serves both long press APIs,
     *      see `CYLTabBarController+CYLInteraction.m`.
     * [CN] 与 `cyl_tabButtonLongPressMinimumDuration`（issue #535）是同一个时长：两套长按 API 共用一个手势，见
     *      `CYLTabBarController+CYLInteraction.m`。
     */
    @objc(cyl_tabBarItemLongPressDuration)
    func cylTabBarItemLongPressDuration() -> TimeInterval {
        cyl_tabButtonLongPressMinimumDuration
    }

    @objc(cyl_setTabBarItemLongPressDuration:)
    func cylSetTabBarItemLongPressDuration(_ duration: TimeInterval) {
        cyl_tabButtonLongPressMinimumDuration = duration
    }

    private var gestureState: CYLTabBarItemGestureState {
        let settings = cyl_gestureSettings
        if let state = settings.state {
            return state
        }
        let state = CYLTabBarItemGestureState()
        state.selectedViewControllerBeforeTap = selectedViewController
        settings.state = state
        return state
    }

    /**
     * [EN] YES when someone listens to the gestures: the handler, a reselect behavior (`cyl_reselectBehavior` is driven by the
     *      Reselect gesture too), or the delegate.
     * [CN] 有人监听手势时为 YES：handler、重复点击操作（`cyl_reselectBehavior` 同样由 Reselect 手势驱动），或代理。
     */
    @objc(cyl_hasTabBarItemGestureReceiver)
    func cylHasTabBarItemGestureReceiver() -> Bool {
        cyl_gestureSettings.handler != nil || !cyl_reselectBehavior.isEmpty
            || ((self as UITabBarController).delegate?.responds(to: NSSelectorFromString("tabBarController:didRecognizeTabBarItemGesture:control:viewController:")) ?? false)
    }

    /**
     * [EN] Taps are recognized for the gesture receivers above, and also for a tab item's `-[UITabBarItem cyl_doubleTapBlock]`. The
     *      long press keeps `cyl_hasTabBarItemGestureReceiver`, so its recognizer is added only when someone listens.
     * [CN] 除上面的手势接收方外，Tab item 的 `-[UITabBarItem cyl_doubleTapBlock]` 也需要识别点击。长按仍使用 `cyl_hasTabBarItemGestureReceiver`，因此只有存在
     *      接收方时才添加长按手势。
     */
    @objc(cyl_hasTabBarItemTapReceiver)
    func cylHasTabBarItemTapReceiver() -> Bool {
        cylHasTabBarItemGestureReceiver() || (viewControllers ?? []).contains { doubleTapBlock(for: $0) != nil }
    }

    /**
     * [EN] The double tap block of a tab: its item's, else its root view controller's item's. [CN] Tab 的双击 block：其 item 的，否则为根控制器 item 的。
     */
    private func doubleTapBlock(for viewController: UIViewController?) -> (@convention(block) (UITabBarItem, Int) -> Void)? {
        guard let viewController else { return nil }
        return viewController.tabBarItem.cyl_doubleTapBlock ?? viewController.cyl_getViewControllerInsteadOfNavigation().tabBarItem.cyl_doubleTapBlock
    }

    /**
     * [EN] YES when `control` is one of this controller's tab buttons, or its plus button; `viewController` is then the tab's view
     *      controller (the plus child view controller for the plus button, nil without one).
     * [CN] `control` 为本控制器的 Tab 按钮或 PlusButton 时返回 YES；此时 `viewController` 为对应 Tab 的控制器（PlusButton 为其子控制器，没有子控制器时为 nil）。
     */
    @objc(cyl_isTabBarItemGestureControl:viewController:)
    func cylIsTabBarItemGestureControl(_ control: UIControl?, viewController: AutoreleasingUnsafeMutablePointer<UIViewController?>?) -> Bool {
        guard let control else { return false }
        // [EN] Guard: the plus button only when there is one. [CN] 仅在有 PlusButton 时处理 PlusButton。
        if hasPlusButton() && control.cyl_isPlusButton() {
            // [EN] Guard: the child view controller only when there is one. [CN] 仅在有子控制器时取子控制器。
            viewController?.pointee = hasPlusChildViewController() ? CYLPlusButton.plusChildViewController(forOwner: self) : nil
            return true
        }
        for each in viewControllers ?? [] where !each.cyl_isPlaceholder {
            if each.tabBarItem.cyl_tabButton === control || each.cyl_tabButton === control {
                viewController?.pointee = each
                return true
            }
        }
        return false
    }

    private func gestureControl(_ control: UIControl?) -> (UIControl, UIViewController?)? {
        var viewController: UIViewController?
        return cylIsTabBarItemGestureControl(control, viewController: &viewController) ? (control!, viewController) : nil
    }

    @objc(cyl_reportTabBarItemGesture:control:viewController:)
    func cylReportTabBarItemGesture(_ gesture: CYLTabBarItemGesture, control: UIControl, viewController: UIViewController?) {
        // [EN] The built-in reselect behavior (CYLReselect) runs first, then the callbacks. [CN] 先执行内置的重复点击操作（CYLReselect），再回调。
        if gesture == .reselect, let viewController {
            cylPrivateVoid("cyl_performReselectBehaviorForViewController:", viewController)
        }
        cyl_gestureSettings.handler?(self, gesture, control, viewController)
        let delegate = (self as UITabBarController).delegate as? CYLTabBarControllerDelegate
        delegate?.tabBarController?(self, didRecognize: gesture, control: control, viewController: viewController)
        // [EN] The tab's own double tap block, after the handler and the delegate. [CN] Tab 自己的双击 block，在 handler 与代理之后。
        if gesture == .doubleTap, let viewController, let index = viewControllers?.firstIndex(of: viewController),
           let block = doubleTapBlock(for: viewController) {
            block(viewController.tabBarItem, index)
        }
    }

    @objc(cyl_recognizeTabBarItemGestureForReportedControl:)
    func cylRecognizeTabBarItemGestureForReportedControl(_ control: UIControl) {
        guard cylHasTabBarItemTapReceiver() else { return }
        // [EN] A CYLPlusButton counts its own taps (`-cyl_recognizePlusButtonTap:…`), tab buttons count before the selection
        //      (`-cyl_recognizeTabBarItemTapWillSelectViewController:`) once that is reached. The reports remain the source for a
        //      plus button that is not a CYLPlusButton, and for tab buttons when `shouldSelectViewController` is not reached.
        // [CN] CYLPlusButton 自己计数（`-cyl_recognizePlusButtonTap:…`）；Tab 按钮在执行到 `-cyl_recognizeTabBarItemTapWillSelectViewController:`
        //      后改为在选中之前计数。不是 CYLPlusButton 的 PlusButton，以及未执行到 `shouldSelectViewController` 时的 Tab 按钮，仍使用上报。
        if control is CYLPlusButton { return }
        guard let (control, viewController) = gestureControl(control) else { return }
        let state = gestureState
        let isPlusButton = hasPlusButton() && control.cyl_isPlusButton()
        if !isPlusButton && state.receivesTabTapsBeforeSelection { return }
        let isReselect = viewController != nil && viewController === state.selectedViewControllerBeforeTap
        cylRecognizeTabBarItemTap(on: control, viewController: viewController, isReselect: isReselect)
        // [EN] After the selection settles (FlatDesign reports before selecting; a tab needing login may refuse it).
        // [CN] 选中状态确定后再记录（扁平样式在选中之前上报；需要登录的 Tab 可能拒绝选中）。
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.gestureState.selectedViewControllerBeforeTap = self.selectedViewController
        }
    }

    /**
     * FIX: issue #152 — the unified entry for taps on tab buttons, in every style.
     * [EN] A user tap on a tab button is about to select `viewController`. Called from `-tabBarController:shouldSelectViewController:`
     *      (classic and Liquid Glass: UIKit asks it once per user tap, for a new tab and for the selected tab alike, before the
     *      selection changes, and never for a selection made in code) and from `-_cyltabBarItemClicked:` (FlatDesign). So every tab
     *      tap is timed at the same moment and Reselect is simply "it is already selected". Once this is called, the
     *      `didSelectControl` reports are no longer used for tab buttons; they stay the source for tab bar controllers whose
     *      `-tabBarController:shouldSelectViewController:` is not reached.
     * [CN] 用户点击 Tab 按钮、即将选中 `viewController`。由 `-tabBarController:shouldSelectViewController:`（经典与液态玻璃：UIKit 对每次用户点击
     *      询问一次，无论是新 Tab 还是已选中的 Tab，都在选中变化之前，代码切换时不会询问）和 `-_cyltabBarItemClicked:`（扁平样式）调用。因此每次
     *      Tab 点击都在同一时刻计时，Reselect 就是"已经选中"。一旦调用过本方法，Tab 按钮不再使用 `didSelectControl` 上报；未执行到
     *      `-tabBarController:shouldSelectViewController:` 的 TabBarController 仍使用上报。
     */
    @objc(cyl_recognizeTabBarItemTapWillSelectViewController:)
    func cylRecognizeTabBarItemTapWillSelect(_ viewController: UIViewController) {
        guard cylHasTabBarItemTapReceiver(), !viewController.cyl_isPlaceholder else { return }
        let control: UIControl?
        // [EN] Guard: the plus child view controller, selected from the tab button under the plus button: a tap on the plus button.
        // [CN] PlusButton 子控制器（点击 PlusButton 下方的 Tab 按钮选中）：算作点击 PlusButton。
        if hasPlusButton() && hasPlusChildViewController() && viewController === CYLPlusButton.plusChildViewController(forOwner: self) {
            control = CYLPlusButton(forOwner: self)
        } else {
            control = viewController.tabBarItem.cyl_tabButton ?? viewController.cyl_tabButton
        }
        guard let control else { return }
        // [EN] Liquid Glass: tab taps are counted when UIKit's own gesture ends (`-cyl_recognizeLiquidGlassTapOnControl:…`), which
        //      knows whether the press was a tap, a long press or a drag. The plus child view controller is still counted here.
        // [CN] 液态玻璃：Tab 的点击在系统手势结束时计数（`-cyl_recognizeLiquidGlassTapOnControl:…`），那里知道这次是点击、长按还是拖动。PlusButton
        //      子控制器仍在这里计数。
        if !control.cyl_isPlusButton() && cylPrivateBool("cyl_liquidGlassTakesTabTaps") { return }
        let state = gestureState
        let isFirstTapFromHere = !state.receivesTabTapsBeforeSelection
        state.receivesTabTapsBeforeSelection = true
        // [EN] The switch from the reports: in Liquid Glass a tap on the selected tab is reported on touch down, before UIKit asks here
        //      on lift. The first time, that report was already counted; do not count the same tap again.
        // [CN] 从上报切换过来时：液态玻璃下点击已选中的 Tab 在手指按下时上报，UIKit 在抬起时才询问这里。第一次时该上报已计数，不再重复计数。
        if isFirstTapFromHere && state.lastControl === control && CACurrentMediaTime() - state.lastTapTime < 1.0 { return }
        cylRecognizeTabBarItemTap(on: control, viewController: viewController, isReselect: viewController === selectedViewController)
    }

    /**
     * FIX: issue #152 — taps on tab buttons in Liquid Glass.
     * [EN] Called when UIKit's Liquid Glass gesture ends where it began, without a long press: one tap. `selectedViewController` is what
     *      was selected on touch down, so a tap on the selected tab is a Reselect even if UIKit already selected it on touch down.
     * [CN] 系统液态玻璃手势在按下的位置结束、且不是长按时调用：一次点击。`selectedViewController` 为手指按下时选中的控制器，因此点击已选中的 Tab
     *      时，即使系统在按下时已选中它，也算 Reselect。
     */
    @objc(cyl_recognizeLiquidGlassTapOnControl:selectedViewControllerAtTouchDown:)
    func cylRecognizeLiquidGlassTap(on control: UIControl, selectedViewControllerAtTouchDown selected: UIViewController?) {
        guard cylHasTabBarItemTapReceiver(), let (control, viewController) = gestureControl(control) else { return }
        gestureState.receivesTabTapsBeforeSelection = true
        cylRecognizeTabBarItemTap(on: control, viewController: viewController, isReselect: viewController != nil && viewController === selected)
    }

    /**
     * FIX: issue #152 — taps on the plus button, through the same entry as the tab buttons.
     * [EN] Called by a CYLPlusButton on `UIControlEventTouchUpInside`, in every style, with and without a child view controller.
     *      `selectedViewController` is what was selected on touch down; nil when there was no touch down (actions sent by code).
     * [CN] CYLPlusButton 在 `UIControlEventTouchUpInside` 时调用，适用于所有样式，有无子控制器均可。`selectedViewController` 为手指按下时选中的
     *      控制器；没有按下（代码发送的事件）时为 nil。
     */
    @objc(cyl_recognizePlusButtonTap:selectedViewControllerAtTouchDown:)
    func cylRecognizePlusButtonTap(_ plusButton: UIControl, selectedViewControllerAtTouchDown selected: UIViewController?) {
        // [EN] Guard: only with a plus button. [CN] 仅在有 PlusButton 时处理。
        guard cylHasTabBarItemTapReceiver(), hasPlusButton(), let (control, viewController) = gestureControl(plusButton) else { return }
        cylRecognizeTabBarItemTap(on: control, viewController: viewController, isReselect: viewController != nil && viewController === selected)
    }

    /**
     * [EN] The core of the unified entry: one tap on a tab button or the plus button. Several calls for the same control in one run
     *      loop turn are one tap.
     * [CN] 统一入口的核心：Tab 按钮或 PlusButton 的一次点击。同一 runloop 内对同一控件的多次调用算一次点击。
     */
    @objc(cyl_recognizeTabBarItemTapOnControl:viewController:isReselect:)
    func cylRecognizeTabBarItemTap(on control: UIControl, viewController: UIViewController?, isReselect: Bool) {
        let state = gestureState
        if state.controlReportedInCurrentRunLoop === control { return }
        state.controlReportedInCurrentRunLoop = control
        cylRecognizeTap(on: control, viewController: viewController, isReselect: isReselect)
        DispatchQueue.main.async { [weak self] in
            self?.gestureState.controlReportedInCurrentRunLoop = nil
        }
    }

    /**
     * [EN] Reports Reselect and DoubleTap for one tap. [CN] 为一次点击上报 Reselect 与 DoubleTap。
     */
    @objc(cyl_recognizeTapOnControl:viewController:isReselect:)
    func cylRecognizeTap(on control: UIControl, viewController: UIViewController?, isReselect: Bool) {
        let state = gestureState
        let now = CACurrentMediaTime()
        let isDoubleTap = state.lastControl === control && now - state.lastTapTime <= cylTabBarItemDoubleTapInterval()
        // [EN] A third tap starts a new pair instead of making a second DoubleTap. [CN] 第三次点击重新开始计数，而不是再算一次 DoubleTap。
        state.lastControl = control
        state.lastTapTime = isDoubleTap ? 0 : now
        if isReselect {
            cylReportTabBarItemGesture(.reselect, control: control, viewController: viewController)
        }
        if isDoubleTap {
            cylReportTabBarItemGesture(.doubleTap, control: control, viewController: viewController)
        }
    }

    @objc(cyl_installTabBarItemLongPressIfNeeded)
    func cylInstallTabBarItemLongPressIfNeeded() {
        guard cylHasTabBarItemGestureReceiver(), isViewLoaded else { return }
        // [EN] Remember what is selected before the first tap. [CN] 记录第一次点击之前选中的控制器。
        _ = gestureState
        // [EN] The long press recognizer is shared with issue #535 (`CYLTabBarController+CYLInteraction.m`). [CN] 长按手势与 issue #535 共用。
        cylPrivateVoid("cyl_installInteractionGestureRecognizersIfNeeded", nil)
    }
}
