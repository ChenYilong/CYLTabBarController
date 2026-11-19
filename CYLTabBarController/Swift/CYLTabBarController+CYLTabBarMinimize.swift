//
//  CYLTabBarController+CYLTabBarMinimize.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import QuartzCore
import UIKit

// [EN] Minimize or hide the tab bar on scroll (issue #13). One API, three isolated paths, chosen by `CYLTabBarMinimizeMode.mode(for:)`;
//      each path is behind its own guard:
//      - FlatDesign (FlatDesign style with a `CYLFlatDesignTabBar`, found at run time): the selected page's scroll view is observed
//        and the flat tab bar is hidden and shown with `-setTabBarHidden:animated:`.
//      - Liquid Glass (`+[CYLConstants isLiquidGlassActive]`): the native `UITabBarController.tabBarMinimizeBehavior`; the scroll view
//        is observed only to keep the plus button centered while the system minimizes the bar.
//      - Classic (not FlatDesign, Liquid Glass not active): the system tab bar (with its plus button) is hidden and shown while the
//        page scrolls.
//      See docs/TabBar-Minimize-On-Scroll.md.
// [CN] 滚动时缩小或隐藏 TabBar（issue #13）。一个接口，三条相互隔离的路径，由 `CYLTabBarMinimizeMode.mode(for:)` 选择，每条路径都在各自的
//      guard 之后：
//      - 扁平样式（扁平样式且 TabBar 为 `CYLFlatDesignTabBar`，运行时判断）：观察选中页面的滚动视图，用 `-setTabBarHidden:animated:`
//        隐藏、显示扁平 TabBar。
//      - 液态玻璃（`+[CYLConstants isLiquidGlassActive]`）：使用系统原生的 `UITabBarController.tabBarMinimizeBehavior`；观察滚动视图只为在
//        系统缩小 TabBar 时让 PlusButton 保持居中。
//      - 经典样式（非扁平样式且液态玻璃未启用）：页面滚动时，隐藏、显示系统 TabBar（连同 PlusButton）。
//      见 docs/TabBar-Minimize-On-Scroll.md。

/**
 * [EN] The method only `CYLTabBar.m` declares (issue #13). [CN] 只在 `CYLTabBar.m` 中声明的方法（issue #13）。
 */
@objc protocol CYLTabBarMinimizePrivateAPI {
    @objc(cyl_showsMinimizedBar) func cylShowsMinimizedBar() -> Bool
}

private enum CYLTabBarMinimizeConstants {
    /// [EN] Distance (pt) to scroll in one direction before the tab bar hides or shows. [CN] 同一方向滚动超过该距离（pt）才隐藏或显示 TabBar。
    static let scrollDistance: CGFloat = 12
    /// [EN] Content that scrolls less than this (pt) never hides the tab bar. [CN] 可滚动距离小于该值（pt）的内容不隐藏 TabBar。
    static let minimumScrollableDistance: CGFloat = 100
    /// [EN] Hysteresis: hiding needs more scrollable distance (pt) than keeping the bar hidden, because hiding the bar makes the
    ///      visible area taller and the content shorter to scroll.
    /// [CN] 滞回：隐藏需要的可滚动距离（pt）大于保持隐藏所需的距离，因为隐藏 TabBar 会让可见区域变高、内容可滚动距离变短。
    static let hideMinimumScrollableDistance: CGFloat = 200
    /// [EN] Classic style: how often the page on screen is checked again. [CN] 经典样式：重新确认当前页面的间隔。
    static let classicPageCheckInterval: TimeInterval = 0.5
    /// [EN] While the tab bar is hidden or minimized by scrolling: how often the safety net checks whether it must come back.
    /// [CN] TabBar 被滚动隐藏或缩小期间：安全网检查是否需要恢复的间隔。
    static let restoreCheckInterval: TimeInterval = 0.25
    /// [EN] As in the Facebook app, the tab bar hides only once the user has scrolled this far (pt) into the content.
    /// [CN] 与 Facebook App 一致，用户滚入内容超过该距离（pt）后才隐藏 TabBar。
    static let hideStartDistance: CGFloat = 50
    /// [EN] How long a found scroll view is reused while the page on screen stays the same. [CN] 当前页面不变时复用已找到的滚动视图的时长。
    static let resolveCacheDuration: CFTimeInterval = 2
    /// [EN] Liquid Glass: when the forced expand is checked. [CN] 液态玻璃：检查强制恢复结果的时间。
    static let liquidGlassExpandCheckDelay: TimeInterval = 0.35
    /// [EN] Half a point of tolerance at the edges, for pixel rounding. [CN] 边缘处允许半个点的误差（像素取整）。
    static let edgeTolerance: CGFloat = 0.5
}

/**
 * [EN] Which path handles `cyl_tabBarMinimizeBehavior`. [CN] 由哪条路径处理 `cyl_tabBarMinimizeBehavior`。
 */
enum CYLTabBarMinimizeMode {
    /// [EN] Nothing to track (Automatic, Never, or the view is not loaded). [CN] 无需跟踪（Automatic、Never，或视图尚未加载）。
    case none, flatDesign, liquidGlass, classic

    /// [EN] The path for a tab bar controller, decided by guards in order. Never loads the view. [CN] 依次通过各个 guard 决定路径。不会触发视图加载。
    static func mode(for tabBarController: CYLTabBarController) -> CYLTabBarMinimizeMode {
        let behavior = tabBarController.cyl_tabBarMinimizeBehavior
        // [EN] Guard: only the scroll behaviors are tracked. [CN] 只跟踪滚动相关的取值。
        guard behavior == .onScrollDown || behavior == .onScrollUp else { return .none }
        // [EN] Guard: the `cyl_tabBar` getter sets the tab bar up, so wait for the view. [CN] `cyl_tabBar` 的 getter 会创建 TabBar，需等视图加载。
        guard tabBarController.isViewLoaded else { return .none }
        if tabBarController.tabBarStyleType == .flatDesign {
            return CYLTabBarMinimizeEnvironment.isFlatDesignTabBar(tabBarController.cyl_tabBar) ? .flatDesign : .none
        }
        if CYLConstants.isLiquidGlassActive() {
            return tabBarController.cyl_tabBar is CYLTabBar ? .liquidGlass : .none
        }
        // [EN] Everything else is the classic system tab bar. [CN] 其余都是经典系统 TabBar。
        return .classic
    }
}

enum CYLTabBarMinimizeEnvironment {

    static func isFlatDesignTabBar(_ view: UIView?) -> Bool {
        guard let view, let flatClass = NSClassFromString("CYLFlatDesignTabBar") else { return false }
        return view.isKind(of: flatClass)
    }

    /// [EN] Whether `tabBar` is a `CYLTabBar` that the system shows minimized. [CN] `tabBar` 是否为系统正以缩小状态显示的 `CYLTabBar`。
    static func showsMinimizedBar(_ tabBar: UIView?) -> Bool {
        guard let tabBar = tabBar as? CYLTabBar else { return false }
        return unsafeBitCast(tabBar as AnyObject, to: CYLTabBarMinimizePrivateAPI.self).cylShowsMinimizedBar()
    }

    /// [EN] The page the user sees in a tab: the top page of a navigation controller. [CN] 用户在 Tab 中看到的页面：导航控制器的栈顶页面。
    static func visibleViewController(_ viewController: UIViewController?) -> UIViewController? {
        (viewController as? UINavigationController)?.topViewController ?? viewController
    }

    /**
     * [EN] The scroll view that drives the tab bar, chosen as UIKit does: the page's bottom content scroll view, otherwise the first
     *      visible scroll view that scrolls vertically (breadth first, so a list inside a horizontal pager wins over the pager), otherwise
     *      the first scroll view. Never loads a view.
     * [CN] 控制 TabBar 的滚动视图，与 UIKit 的选择方式一致：页面底部的 content scroll view；没有时取第一个可以竖向滚动的可见滚动视图（广度优先，
     *      因此横向分页容器中的列表优先于分页容器）；再没有时取第一个滚动视图。不会触发视图加载。
     */
    static func scrollView(for viewController: UIViewController?) -> UIScrollView? {
        guard let visible = visibleViewController(viewController), visible.isViewLoaded else { return nil }
        if let contentScrollView = visible.contentScrollView(for: .bottom) {
            return contentScrollView
        }
        var firstScrollView: UIScrollView?
        var views: [UIView] = [visible.view]
        var index = 0
        while index < views.count {
            let view = views[index]
            index += 1
            if view.isHidden {
                continue
            }
            if let scrollView = view as? UIScrollView, !(view is UITextView) {
                let scrollsVertically = scrollView.contentSize.height > scrollView.bounds.height + 1
                let isHorizontalPager = scrollView.isPagingEnabled && scrollView.contentSize.width > scrollView.bounds.width + 1
                if scrollsVertically && !isHorizontalPager {
                    return scrollView
                }
                firstScrollView = firstScrollView ?? scrollView
            }
            views.append(contentsOf: view.subviews)
        }
        return firstScrollView
    }

    /// [EN] Classic style: whether the tab bar sits at the bottom of its superview. [CN] 经典样式：TabBar 是否位于父视图底部。
    static func classicTabBarIsAtBottom(_ tabBar: UITabBar) -> Bool {
        guard let container = tabBar.superview else { return false }
        return tabBar.center.y + tabBar.bounds.height * 0.5 >= container.bounds.height - 1
    }

    /// [EN] Classic style: whether UIKit hides the tab bar for the page on screen (`hidesBottomBarWhenPushed` above the root).
    /// [CN] 经典样式：UIKit 是否因当前页面隐藏 TabBar（根页面之上被 push 的页面设置了 `hidesBottomBarWhenPushed`）。
    static func classicPageHidesTabBar(_ selectedViewController: UIViewController?) -> Bool {
        guard let navigationController = selectedViewController as? UINavigationController else { return false }
        return navigationController.viewControllers.dropFirst().contains { $0.hidesBottomBarWhenPushed }
    }

    /**
     * [EN] Whether `window` is the key window of its scene, and the scene is in the foreground and active (several scenes on iPad).
     * [CN] `window` 是否是其 Scene 的 key window，且该 Scene 在前台并处于活跃状态（iPad 多 Scene）。
     */
    static func windowIsKeyAndActive(_ window: UIWindow?) -> Bool {
        guard let window else { return false }
        if let windowScene = window.windowScene {
            return windowScene.activationState == .foregroundActive && windowScene.keyWindow === window
        }
        return window.isKeyWindow && UIApplication.shared.applicationState == .active
    }

    /**
     * [EN] Opt-in diagnostics: set the environment variable `CYLTabBarMinimizeLog` (or `CYL_TAB_BAR_MINIMIZE_LOG`) to `1` in the
     *      scheme to log every session start, every restore with its reason, and every takeover by the app.
     * [CN] 可选诊断：在 scheme 中把环境变量 `CYLTabBarMinimizeLog`（或 `CYL_TAB_BAR_MINIMIZE_LOG`）设为 `1`，即可打印每次会话开始、每次恢复
     *      及其原因、以及每次 App 接管。
     */
    static let logEnabled: Bool = {
        let environment = ProcessInfo.processInfo.environment
        return [environment["CYLTabBarMinimizeLog"], environment["CYL_TAB_BAR_MINIMIZE_LOG"]].contains { ($0 as NSString?)?.boolValue ?? false }
    }()

    static func log(_ event: String, _ reason: String?) {
        if logEnabled {
            NSLog("[CYLTabBarController] scroll hiding: %@ (%@)", event, reason ?? "-")
        }
    }
}

/**
 * [EN] Observes the scroll view of the page on screen and runs the path's action. See the comment at the top of this file.
 * [CN] 观察当前显示页面的滚动视图，并执行对应路径的处理。见本文件顶部说明。
 */
final class CYLTabBarMinimizeScrollTracker: NSObject, UIGestureRecognizerDelegate {
    private typealias Env = CYLTabBarMinimizeEnvironment
    private typealias Constants = CYLTabBarMinimizeConstants

    private(set) weak var tabBarController: CYLTabBarController?
    private(set) weak var scrollView: UIScrollView?
    private(set) var mode: CYLTabBarMinimizeMode = .none

    /// [EN] Distance scrolled in the current direction (positive: content moves up). [CN] 当前方向的累计滚动距离（正值：内容上移）。
    private var scrolledDistance: CGFloat = 0
    /// [EN] YES when the tab bar was hidden by scrolling, not by the app. [CN] TabBar 是滚动隐藏的，而不是 App 自己隐藏的。
    private var hiddenByScroll = false
    /// [EN] Liquid Glass: the minimized state the tab bar was last laid out for. [CN] 液态玻璃：上次布局时 TabBar 的缩小状态。
    private var laidOutMinimized = false
    private var checkTimer: Timer?
    private var checkTimerInterval: TimeInterval = 0
    /// [EN] After a restore, the tab bar hides again only on a new drag. [CN] 恢复之后，只有新的拖动才会再次隐藏 TabBar。
    private var needsNewDrag = false
    /// [EN] `isTracking` at the last offset change, to see a new drag start. [CN] 上次偏移变化时的 `isTracking`，用于识别新拖动的开始。
    private var lastSeenTracking = false
    private var notificationObservers: [NSObjectProtocol] = []
    private var contentOffsetObservation: NSKeyValueObservation?
    /// [EN] The one flag (whitelist): YES only while a hide session runs. See `beginHideSession()`.
    /// [CN] 唯一的标记（白名单）：只有隐藏会话进行中才为 YES。见 `beginHideSession()`。
    private var hideSessionActive = false
    private weak var sessionScrollView: UIScrollView?
    private weak var sessionSelectedViewController: UIViewController?
    private weak var sessionPage: UIViewController?
    private weak var sessionWindow: UIWindow?
    /// [EN] The controller's frame in its window and its top safe area when the session began. [CN] 会话开始时控制器在窗口中的 frame 及顶部安全区。
    private var sessionFrameInWindow = CGRect.zero
    private var sessionSafeAreaTop: CGFloat = 0
    private var sessionBehavior: CYLTabBarMinimizeBehavior = .automatic
    private var sessionMode: CYLTabBarMinimizeMode = .none
    /// [EN] Observes a long press on the followed scroll view; never cancels or delays its touches. [CN] 观察所跟随滚动视图上的长按；从不取消或延迟触摸。
    private var longPressObserver: UILongPressGestureRecognizer?
    /// [EN] Observes taps anywhere in the controller's view; never cancels or delays touches. [CN] 观察控制器视图中任意位置的点击；从不取消或延迟触摸。
    private var tapObserver: UITapGestureRecognizer?
    /// [EN] YES while scroll hiding itself calls `-setTabBarHidden:animated:`. [CN] 滚动隐藏自己调用 `-setTabBarHidden:animated:` 期间为 YES。
    private var settingTabBarHidden = false
    /// [EN] YES while the keyboard is on screen: the bar never hides then. [CN] 键盘显示期间为 YES：此时不隐藏 TabBar。
    private var keyboardVisible = false
    private weak var resolvedPage: UIViewController?
    private var resolvedAt: CFTimeInterval = 0
    /// [EN] Scroll hiding's own last request and when it was made: a FlatDesign animation may replay it shortly after.
    /// [CN] 滚动隐藏自己最近一次请求及时间：扁平样式的动画可能稍后重放它。
    private var lastOwnRequestHidden = false
    private var lastOwnRequestTime: CFTimeInterval = 0
    /// [EN] The app took the tab bar over after scroll hiding's last request. [CN] 滚动隐藏最近一次请求之后，App 接管了 TabBar。
    private var appTookTabBarOver = false

    init(tabBarController: CYLTabBarController) {
        self.tabBarController = tabBarController
        super.init()
        observeLifecycleNotifications()
    }

    deinit {
        checkTimer?.invalidate()
        if let tapObserver {
            tapObserver.view?.removeGestureRecognizer(tapObserver)
        }
        notificationObservers.forEach { NotificationCenter.default.removeObserver($0) }
        contentOffsetObservation?.invalidate()
        if let longPressObserver {
            longPressObserver.view?.removeGestureRecognizer(longPressObserver)
        }
    }

    // MARK: Lifecycle

    /**
     * [EN] Where bugs hide: when the tab bar must come back. Every event below restores a tab bar hidden or minimized by scrolling, and
     *      then waits for a new drag: resign active (calls, system alerts, Control Center, the app switcher), background and foreground
     *      switches, memory warnings, the same scene events (only this window's scene), another window becoming key, accessibility and
     *      power changes. In-app alerts and modals, pushes and pops have no notification; the check timer catches them.
     * [CN] 最容易出 bug 的地方：何时恢复显示。下列事件都会恢复被滚动隐藏或缩小的 TabBar，之后等待新的拖动：失去活跃（来电、系统弹框、控制中心、
     *      App 切换器）、前后台切换、内存警告、对应的 Scene 事件（只处理本窗口的 Scene）、其他窗口成为 key window、辅助功能与电量模式变化。
     *      App 内的弹框与模态页面、push 与 pop 没有通知，由定时检查处理。
     */
    private func observeLifecycleNotifications() {
        let names: [Notification.Name] = [
            UIApplication.willResignActiveNotification,
            UIApplication.didEnterBackgroundNotification,
            UIApplication.willEnterForegroundNotification,
            UIApplication.didBecomeActiveNotification,
            UIApplication.didReceiveMemoryWarningNotification,
            UIWindow.didBecomeKeyNotification,
            UIResponder.keyboardWillShowNotification,
            UIResponder.keyboardWillHideNotification,
            UIAccessibility.voiceOverStatusDidChangeNotification,
            UIAccessibility.switchControlStatusDidChangeNotification,
            UIAccessibility.reduceMotionStatusDidChangeNotification,
            UIAccessibility.guidedAccessStatusDidChangeNotification,
            Notification.Name.NSProcessInfoPowerStateDidChange,
            UIScene.willDeactivateNotification,
            UIScene.didEnterBackgroundNotification,
            UIScene.willEnterForegroundNotification,
            UIScene.didActivateNotification,
        ]
        notificationObservers = names.map { name in
            NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                MainActor.assumeIsolated { self?.restoreTabBar(for: notification) }
            }
        }
    }

    private func restoreTabBar(for notification: Notification) {
        let window = tabBarController?.viewIfLoaded?.window
        switch notification.name {
        case UIResponder.keyboardWillHideNotification:
            // [EN] Keyboard: its going away is not an interruption. [CN] 键盘收起不算打断。
            keyboardVisible = false
            return
        case UIResponder.keyboardWillShowNotification:
            // [EN] Only this window's keyboard counts: not another app's, nor one in another scene of this app.
            // [CN] 只处理本窗口的键盘：不处理其他 App 的键盘，也不处理本 App 其他 Scene 中的键盘。
            let isLocal = (notification.userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? NSNumber)?.boolValue ?? true
            if !isLocal || !Env.windowIsKeyAndActive(window) {
                return
            }
            keyboardVisible = true
        case UIApplication.didEnterBackgroundNotification:
            // [EN] A keyboard left up in the background may never post WillHide; forget it here. [CN] 进入后台时仍显示的键盘可能不会发送 WillHide；在这里清除记录。
            keyboardVisible = false
        case UIWindow.didBecomeKeyNotification:
            // [EN] Guard: this tab bar's own window becoming key is not an interruption. [CN] 本 TabBar 自己的窗口成为 key window 不算打断。
            if let object = notification.object as AnyObject?, object === window {
                return
            }
        default:
            break
        }
        // [EN] Guard: scene events of other scenes (iPad multiple windows). [CN] 其他 Scene 的事件（iPad 多窗口）。
        if let scene = notification.object as? UIScene, let windowScene = window?.windowScene, scene !== windowScene {
            return
        }
        restoreTabBar(reason: notification.name.rawValue)
    }

    /**
     * [EN] Shows a tab bar hidden or minimized by scrolling again, at once, and blocks hiding until the user starts a new drag. Does nothing
     *      to a tab bar the app hid itself.
     * [CN] 立即重新显示被滚动隐藏或缩小的 TabBar，并在用户开始新的拖动之前不再隐藏。App 自己隐藏的 TabBar 不处理。
     */
    func restoreTabBar(reason: String = "restore") {
        if isTabBarHiddenOrMinimizedByScroll() {
            Env.log("restore", reason)
        }
        endHideSession()
        needsNewDrag = true
        lastSeenTracking = scrollView?.isTracking ?? false
        scrolledDistance = 0
        expandTabBar()
        // [EN] Guard: Liquid Glass, only a bar the system shows minimized. [CN] 液态玻璃：只处理系统正以缩小状态显示的 TabBar。
        if mode == .liquidGlass, let tabBarController, Env.showsMinimizedBar(tabBarController.cyl_tabBar) {
            tabBarController.cylExpandSystemMinimizedTabBar()
        }
        updateCheckTimer()
    }

    /// [EN] YES while scrolling hid or the system minimized the tab bar. [CN] TabBar 被滚动隐藏或被系统缩小期间为 YES。
    func isTabBarHiddenOrMinimizedByScroll() -> Bool {
        if hiddenByScroll {
            return true
        }
        return mode == .liquidGlass && Env.showsMinimizedBar(tabBarController?.cyl_tabBar)
    }

    /// [EN] Why the app does not allow hiding now, or nil when it does (also used for the log). [CN] 当前不允许隐藏的原因，允许时返回 nil（也用于日志）。
    private func environmentRefusalReason() -> String? {
        let tabBarController = self.tabBarController
        if !Env.windowIsKeyAndActive(tabBarController?.viewIfLoaded?.window) {
            return "window not key, or its scene / the app not active"
        }
        // [EN] On a Mac a pointer and a resizable window make hiding the tab bar pointless. [CN] 在 Mac 上，鼠标与可调整大小的窗口使隐藏 TabBar 没有意义。
        #if targetEnvironment(macCatalyst)
        return "Mac Catalyst"
        #else
        if ProcessInfo.processInfo.isiOSAppOnMac {
            return "iOS app running on a Mac"
        }
        // [EN] VoiceOver and Switch Control users move through the tabs: never take them away.
        // [CN] VoiceOver 与切换控制的用户依靠 Tab 导航：不隐藏 TabBar。
        if UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning {
            return "VoiceOver or Switch Control running"
        }
        if keyboardVisible {
            return "keyboard on screen"
        }
        // [EN] Presented by this controller or an ancestor, by the selected tab, or by the page on screen.
        // [CN] 由本控制器或其祖先、选中的 Tab、或当前页面 present。
        let selectedViewController = tabBarController?.selectedViewController
        if tabBarController?.presentedViewController != nil || selectedViewController?.presentedViewController != nil ||
            Env.visibleViewController(selectedViewController)?.presentedViewController != nil {
            return "a view controller is presented"
        }
        if selectedViewController?.transitionCoordinator != nil {
            return "a push / pop transition is running"
        }
        if scrollView?.window == nil {
            return "scroll view off screen"
        }
        return nil
        #endif
    }

    private func environmentAllowsHiding() -> Bool {
        environmentRefusalReason() == nil
    }

    // MARK: Hide session (whitelist)

    /**
     * [EN] The robust core, a whitelist instead of a list of events: hiding the bar is valid only inside a "hide session". The one way to
     *      start a session is the user scrolling down through content (for Liquid Glass, the system minimizing the bar while the app
     *      allows hiding). The session records its context: the scroll view, the selected tab, the page on screen, the window, the
     *      behavior and the path. Anything that does not match that context, or that the environment refuses, ends the session and
     *      brings the bar back at once, also for situations nobody listed.
     * [CN] 健壮性的核心是白名单而不是事件列表：只有在“隐藏会话”内，TabBar 才可以保持隐藏。开始会话的唯一方式是用户向下滚动浏览内容（液态玻璃为
     *      App 允许隐藏时系统缩小了 TabBar）。会话记录当时的上下文：滚动视图、选中的 Tab、当前页面、窗口、取值与路径。任何与该上下文不一致、或环境
     *      不允许的情况，都会结束会话并立即恢复显示，包括没有被列举到的情况。
     */
    private func beginHideSession() {
        Env.log("hide session begins", mode == .liquidGlass ? "system minimized" : "user scrolled down")
        let selectedViewController = tabBarController?.selectedViewController
        hideSessionActive = true
        sessionScrollView = scrollView
        sessionSelectedViewController = selectedViewController
        sessionPage = Env.visibleViewController(selectedViewController)
        sessionWindow = tabBarController?.viewIfLoaded?.window
        sessionBehavior = tabBarController?.cyl_tabBarMinimizeBehavior ?? .automatic
        sessionMode = mode
        let controllerView = tabBarController?.viewIfLoaded
        sessionFrameInWindow = controllerView.map { $0.convert($0.bounds, to: nil) } ?? .zero
        sessionSafeAreaTop = controllerView?.safeAreaInsets.top ?? 0
    }

    private func endHideSession() {
        hideSessionActive = false
        sessionScrollView = nil
        sessionSelectedViewController = nil
        sessionPage = nil
        sessionWindow = nil
    }

    /// [EN] Why the running session is no longer valid, or nil while it is. [CN] 正在进行的会话为何不再有效，有效时返回 nil。
    private func hideSessionInvalidReason() -> String? {
        guard hideSessionActive else { return "no hide session" }
        if let refusal = environmentRefusalReason() {
            return refusal
        }
        let selectedViewController = tabBarController?.selectedViewController
        if scrollView == nil || scrollView !== sessionScrollView {
            return "scroll view changed"
        }
        if selectedViewController == nil || selectedViewController !== sessionSelectedViewController {
            return "tab changed"
        }
        if sessionPage == nil || Env.visibleViewController(selectedViewController) !== sessionPage {
            return "page changed (push / pop)"
        }
        if sessionWindow == nil || tabBarController?.viewIfLoaded?.window !== sessionWindow {
            return "window changed"
        }
        if tabBarController?.cyl_tabBarMinimizeBehavior != sessionBehavior || mode != sessionMode {
            return "value or style changed"
        }
        let controllerView = tabBarController?.viewIfLoaded
        let frame = controllerView.map { $0.convert($0.bounds, to: nil) } ?? .zero
        if abs(frame.minX - sessionFrameInWindow.minX) > 1 || abs(frame.minY - sessionFrameInWindow.minY) > 1 ||
            abs(frame.width - sessionFrameInWindow.width) > 1 || abs(frame.height - sessionFrameInWindow.height) > 1 {
            return "controller moved or resized in its window (side menu, container transition)"
        }
        if abs((controllerView?.safeAreaInsets.top ?? 0) - sessionSafeAreaTop) > 0.5 {
            return "top safe area changed (in-call / hotspot / recording status bar)"
        }
        return nil
    }

    /**
     * [EN] Brings the bar back unless a valid session explains why it is hidden or minimized. Liquid Glass: a bar the system minimized
     *      while hiding is allowed adopts a session (the system decides when to minimize), any other is restored.
     * [CN] 除非有一个有效的会话说明 TabBar 为何被隐藏或缩小，否则恢复显示。液态玻璃：在允许隐藏时被系统缩小的 TabBar 会开始一个会话，其他情况恢复显示。
     */
    func validateHideSession() {
        let tabBarController = self.tabBarController
        // [EN] Shown again by the app or UIKit: not hidden by scrolling any more. Not while our own hide is under way: during the call, and
        //      for 0.5 s after it, FlatDesign may still report the bar as shown (seen on iOS 26.5).
        // [CN] 已被 App 或 UIKit 重新显示：不再是滚动隐藏状态。我们自己的隐藏进行中时不判断：调用期间及之后 0.5 秒内，扁平样式可能仍报告 TabBar 为显示
        //      （在 iOS 26.5 上出现）。
        let ownHideUnderWay = settingTabBarHidden || (lastOwnRequestHidden && CACurrentMediaTime() - lastOwnRequestTime < 0.5)
        if hiddenByScroll && !(tabBarController?.isTabBarHidden ?? false) && !ownHideUnderWay {
            Env.log("no longer hidden by scrolling", "the tab bar was shown again by the app or UIKit")
            hiddenByScroll = false
        }
        // [EN] Classic: a pushed page with `hidesBottomBarWhenPushed` holds the bar; UIKit owns it there. End the session once and wait.
        // [CN] 经典样式：设置了 `hidesBottomBarWhenPushed` 的页面占用 TabBar，此时由 UIKit 控制。只结束一次会话并等待。
        if mode == .classic && hiddenByScroll && Env.classicPageHidesTabBar(tabBarController?.selectedViewController) {
            if hideSessionActive {
                endHideSession()
            }
            return
        }
        if !isTabBarHiddenOrMinimizedByScroll() {
            // [EN] Shown again: the session is over. [CN] 已重新显示：会话结束。
            if hideSessionActive {
                endHideSession()
            }
            return
        }
        // [EN] Liquid Glass: a minimize while hiding is allowed is adopted even before a new drag. [CN] 液态玻璃：允许隐藏时的缩小即使发生在新的拖动之前也会被接受。
        if mode == .liquidGlass && !hideSessionActive && environmentAllowsHiding() {
            beginHideSession()
            return
        }
        if let invalidReason = hideSessionInvalidReason() {
            restoreTabBar(reason: invalidReason)
        }
    }

    // MARK: Long press on content and taps outside it

    /**
     * [EN] A long press on the content (a context menu, drag and drop, text selection) is not reading: it ends the session and shows the bar.
     * [CN] 在内容上长按（上下文菜单、拖放、选择文字）不是浏览：结束会话并显示 TabBar。
     */
    @objc private func contentLongPressed(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            restoreTabBar(reason: "long press on content (context menu, drag, text selection)")
        }
    }

    func gestureRecognizer(_: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer) -> Bool {
        true
    }

    /// [EN] Attaches the tap observer to the controller's view (once). [CN] 将点击观察者加到控制器的视图上（只加一次）。
    func observeTaps(in view: UIView?) {
        guard let view, tapObserver?.view !== view else { return }
        let observer = tapObserver ?? Self.makeObserver(UITapGestureRecognizer(target: self, action: #selector(controllerViewTapped(_:))), delegate: self)
        tapObserver = observer
        observer.view?.removeGestureRecognizer(observer)
        view.addGestureRecognizer(observer)
    }

    private static func makeObserver<Recognizer: UIGestureRecognizer>(_ recognizer: Recognizer, delegate: UIGestureRecognizerDelegate) -> Recognizer {
        recognizer.cancelsTouchesInView = false
        recognizer.delaysTouchesBegan = false
        recognizer.delaysTouchesEnded = false
        recognizer.delegate = delegate
        return recognizer
    }

    /**
     * [EN] While the bar is hidden or minimized, a tap outside the followed scroll view (a navigation bar button, a menu button, a header)
     *      is not reading: it ends the session and shows the bar. Taps inside the content keep it hidden, as in the Facebook app.
     * [CN] TabBar 被隐藏或缩小期间，在所跟随滚动视图之外的点击（导航栏按钮、菜单按钮、头部）不是浏览：结束会话并显示 TabBar。内容中的点击保持隐藏，
     *      与 Facebook App 一致。
     */
    @objc private func controllerViewTapped(_ recognizer: UITapGestureRecognizer) {
        guard recognizer.state == .ended, isTabBarHiddenOrMinimizedByScroll() else { return }
        if let scrollView, scrollView.point(inside: recognizer.location(in: scrollView), with: nil) {
            return
        }
        restoreTabBar(reason: "tap outside the content (navigation bar, menu button, header)")
    }

    // MARK: Testing

    /// [EN] Hides as a user's downward scroll would (FlatDesign, classic), for self-tests. [CN] 像用户向下滚动一样隐藏（扁平样式、经典样式），用于自测。
    func simulateHideForTesting() -> Bool {
        guard mode == .flatDesign || mode == .classic else {
            Env.log("test hide refused", mode == .liquidGlass ? "Liquid Glass: the system minimizes the bar" : "scroll hiding is off")
            return false
        }
        if let refusal = environmentRefusalReason() {
            Env.log("test hide refused", refusal)
            return false
        }
        needsNewDrag = false
        minimizeTabBar()
        if !hiddenByScroll {
            let scrollView = self.scrollView
            Env.log("test hide refused", String(format: "the bar did not hide (tab bar hidden already: %@, scroll view: %@, content height %.0f, bounds height %.0f, offset %.0f)",
                                                (tabBarController?.isTabBarHidden ?? false) ? "YES" : "NO",
                                                scrollView.map { NSStringFromClass(type(of: $0)) } ?? "none",
                                                Double(scrollView?.contentSize.height ?? 0), Double(scrollView?.bounds.height ?? 0),
                                                Double(scrollView?.contentOffset.y ?? 0)))
        }
        return hiddenByScroll
    }

    // MARK: Scroll view lookup and the check timer

    /**
     * [EN] The scroll view to follow. While the page on screen stays the same and the followed scroll view is still on screen, it is
     *      reused for a while instead of searching the view hierarchy on every layout. A new page is always searched at once.
     * [CN] 要跟随的滚动视图。当前页面不变且所跟随的滚动视图仍在屏幕上时，在一段时间内直接复用，不必每次布局都遍历视图层级。新页面总会立即查找。
     */
    func scrollView(forSelectedViewController selectedViewController: UIViewController?) -> UIScrollView? {
        let page = Env.visibleViewController(selectedViewController)
        let now = CACurrentMediaTime()
        if let page, page === resolvedPage, now - resolvedAt < Constants.resolveCacheDuration, scrollView == nil || scrollView?.window != nil {
            return scrollView
        }
        resolvedPage = page
        resolvedAt = now
        return Env.scrollView(for: selectedViewController)
    }

    /// [EN] Runs the check timer while it is needed: always for the classic path, and for every path while the bar is hidden or minimized.
    /// [CN] 仅在需要时运行定时检查：经典样式始终运行；任何路径在 TabBar 被隐藏或缩小期间运行。
    private func updateCheckTimer() {
        var interval: TimeInterval = 0
        if isTabBarHiddenOrMinimizedByScroll() {
            interval = Constants.restoreCheckInterval
        } else if mode == .classic {
            interval = Constants.classicPageCheckInterval
        }
        if checkTimer != nil && interval == checkTimerInterval {
            return
        }
        checkTimer?.invalidate()
        checkTimer = nil
        checkTimerInterval = interval
        guard interval > 0 else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self, self.tabBarController != nil else {
                    timer.invalidate()
                    return
                }
                self.checkTimerFired()
            }
        }
        timer.tolerance = interval * 0.5
        checkTimer = timer
    }

    /**
     * [EN] The safety net for what no notification reports: a page change is found by re-resolving the scroll view; an alert, a modal or a
     *      lost key window restores the bar.
     * [CN] 没有通知可监听情况的安全网：重新确认滚动视图即可发现页面变化；弹框、模态页面或失去 key window 时恢复 TabBar。
     */
    private func checkTimerFired() {
        if let tabBarController, tabBarController.viewIfLoaded?.window != nil {
            tabBarController.cylUpdateTabBarMinimizeTracking()
        }
        validateHideSession()
        updateCheckTimer()
    }

    func updateMode(_ newMode: CYLTabBarMinimizeMode) {
        guard mode != newMode else { return }
        // [EN] Leaving a path: give back a tab bar it hid. [CN] 离开某条路径：恢复它隐藏的 TabBar。
        expandTabBar()
        mode = newMode
        scrolledDistance = 0
        laidOutMinimized = false
        updateCheckTimer()
    }

    func observe(_ newScrollView: UIScrollView?) {
        guard scrollView !== newScrollView else { return }
        contentOffsetObservation?.invalidate()
        contentOffsetObservation = nil
        if let longPressObserver {
            longPressObserver.view?.removeGestureRecognizer(longPressObserver)
        }
        scrollView = newScrollView
        scrolledDistance = 0
        guard let newScrollView else { return }
        let observer = longPressObserver ?? Self.makeObserver(UILongPressGestureRecognizer(target: self, action: #selector(contentLongPressed(_:))), delegate: self)
        longPressObserver = observer
        newScrollView.addGestureRecognizer(observer)
        contentOffsetObservation = newScrollView.observe(\.contentOffset, options: [.old, .new]) { [weak self] scrollView, change in
            MainActor.assumeIsolated { self?.contentOffsetDidChange(scrollView, old: change.oldValue, new: change.newValue) }
        }
    }

    private func contentOffsetDidChange(_ observed: UIScrollView, old: CGPoint?, new: CGPoint?) {
        guard let scrollView, observed === scrollView else { return }
        // [EN] Guard: Liquid Glass only follows the system; it never hides the bar itself. [CN] 液态玻璃只跟随系统，从不自行隐藏 TabBar。
        if mode == .liquidGlass {
            // [EN] A new drag hands the minimize behavior back to the system after a restore. [CN] 恢复之后，新的拖动把缩小行为交还给系统。
            let tracking = scrollView.isTracking
            if tracking && !lastSeenTracking {
                needsNewDrag = false
                tabBarController?.cylReleaseSystemMinimizeHoldIfNeeded()
            }
            lastSeenTracking = tracking
            layOutTabBarIfMinimizedStateChanged()
            validateHideSession()
            return
        }
        // [EN] Every scroll event checks the session first. [CN] 每次滚动都先检查会话。
        validateHideSession()
        guard let old, let new else { return }
        self.scrollView(scrollView, didScrollFromOffsetY: old.y, toOffsetY: new.y)
    }

    /// [EN] FlatDesign and classic: decide from the user's scrolling whether to hide or show the tab bar.
    /// [CN] 扁平样式与经典样式：根据用户的滚动决定隐藏或显示 TabBar。
    private func scrollView(_ scrollView: UIScrollView, didScrollFromOffsetY oldOffsetY: CGFloat, toOffsetY newOffsetY: CGFloat) {
        guard mode == .flatDesign || mode == .classic else { return }
        let behavior = tabBarController?.cyl_tabBarMinimizeBehavior
        let minimizesOnScrollDown = behavior == .onScrollDown
        guard minimizesOnScrollDown || behavior == .onScrollUp else { return }
        let insets = scrollView.adjustedContentInset
        let minOffsetY = -insets.top
        let maxOffsetY = max(minOffsetY, scrollView.contentSize.height + insets.bottom - scrollView.bounds.height)
        // [EN] Checked before the user-scroll guard below, so these also work for offsets set in code: content that no longer scrolls never
        //      keeps the bar hidden, and back at the edge the content starts from the bar comes back, as the system does.
        // [CN] 放在下方“仅用户滚动”的 guard 之前，因此代码设置的偏移同样生效：不再能滚动的内容不会让 TabBar 保持隐藏；回到内容的起始边缘时，与系统一致，
        //      重新显示 TabBar。
        if maxOffsetY - minOffsetY < Constants.minimumScrollableDistance {
            scrolledDistance = 0
            if hiddenByScroll {
                Env.log("restore", "the content no longer scrolls")
            }
            expandTabBar()
            return
        }
        if (minimizesOnScrollDown && newOffsetY <= minOffsetY + Constants.edgeTolerance) ||
            (!minimizesOnScrollDown && newOffsetY >= maxOffsetY - Constants.edgeTolerance) {
            scrolledDistance = 0
            if hiddenByScroll {
                Env.log("restore", "back at the edge the content starts from")
            }
            expandTabBar()
            return
        }
        // [EN] A new drag starts when `isTracking` turns on; it lifts the block set by a restore. [CN] `isTracking` 由 NO 变为 YES 即开始新的拖动，解除恢复时设置的限制。
        let tracking = scrollView.isTracking
        if tracking && !lastSeenTracking {
            needsNewDrag = false
        }
        lastSeenTracking = tracking
        // [EN] Only scrolling by the user counts. [CN] 只响应用户的滚动。
        guard tracking || scrollView.isDragging || scrollView.isDecelerating else { return }
        // [EN] Ignore the rubber band beyond either edge. [CN] 忽略超出边缘的回弹。
        let range = minOffsetY...maxOffsetY
        guard range.contains(oldOffsetY), range.contains(newOffsetY) else { return }
        let delta = newOffsetY - oldOffsetY
        guard delta != 0 else { return }
        if (delta > 0) != (scrolledDistance > 0) {
            scrolledDistance = 0
        }
        scrolledDistance += delta
        guard abs(scrolledDistance) >= Constants.scrollDistance else { return }
        // [EN] Positive: the content moves up, i.e. the user scrolls down to read on. [CN] 正值：内容上移，即用户向下滚动继续浏览。
        let scrollsDown = scrolledDistance > 0
        scrolledDistance = 0
        if scrollsDown != minimizesOnScrollDown {
            expandTabBar()
            return
        }
        // [EN] Hide only while the user reads on: not before a new drag after a restore, not at the start of the content, and only when the
        //      app allows it. [CN] 只在用户继续浏览内容时隐藏：恢复后需新的拖动，内容开头不隐藏，并且需要 App 环境允许。
        guard !needsNewDrag else { return }
        let farEnoughIntoContent = minimizesOnScrollDown ? newOffsetY > minOffsetY + Constants.hideStartDistance
                                                         : newOffsetY < maxOffsetY - Constants.hideStartDistance
        guard farEnoughIntoContent, maxOffsetY - minOffsetY >= Constants.hideMinimumScrollableDistance, environmentAllowsHiding() else { return }
        minimizeTabBar()
    }

    // MARK: Liquid Glass

    /**
     * [EN] Liquid Glass: the system minimizes or expands the tab bar while the page scrolls, without a public callback. When the platter's
     *      geometry flips, lay the tab bar out so the plus button follows; once more after the system's animation.
     * [CN] 液态玻璃：页面滚动时系统会缩小或恢复 TabBar，没有公开的回调。当 platter 的几何尺寸发生变化时重新布局 TabBar，让 PlusButton 跟随；
     *      系统动画结束后再布局一次。
     */
    private func layOutTabBarIfMinimizedStateChanged() {
        guard let tabBar = tabBarController?.cyl_tabBar as? CYLTabBar else { return }
        let minimized = Env.showsMinimizedBar(tabBar)
        guard minimized != laidOutMinimized else { return }
        laidOutMinimized = minimized
        // [EN] Minimized: the safety net watches for anything that must bring the bar back. [CN] 缩小后：由安全网检查何时需要恢复。
        updateCheckTimer()
        tabBar.setNeedsLayout()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak tabBar] in
            tabBar?.setNeedsLayout()
        }
    }

    // MARK: Hide / show

    /**
     * [EN] FlatDesign and classic: hide the tab bar through the public `-setTabBarHidden:animated:`. Each path has its own guard: only a tab
     *      bar on screen is hidden, not one hidden by the app, nor by `hidesBottomBarWhenPushed`.
     * [CN] 扁平样式与经典样式：通过公开的 `-setTabBarHidden:animated:` 隐藏 TabBar。每条路径都有自己的 guard：只隐藏正在显示的 TabBar。
     */
    private func minimizeTabBar() {
        guard let tabBarController else { return }
        if tabBarController.isTabBarHidden {
            // [EN] Safety net: the bar is hidden by our own last request and the app has not taken it over since, but the flag was lost.
            // [CN] 安全网：TabBar 是我们最近一次请求隐藏的，此后 App 也没有接管，但标记丢失了。
            if !hiddenByScroll && lastOwnRequestHidden && !appTookTabBarOver && (mode == .flatDesign || mode == .classic) {
                Env.log("hidden by scrolling again", "our own hide was still in effect")
                hiddenByScroll = true
                beginHideSession()
                updateCheckTimer()
            }
            return
        }
        switch mode {
        case .flatDesign:
            guard flatDesignCanHideTabBar() else { return }
        case .classic:
            guard classicCanHideTabBar() else { return }
        case .liquidGlass, .none:
            return
        }
        hiddenByScroll = true
        // [EN] The one place a session starts for FlatDesign and classic. [CN] 扁平样式与经典样式开始会话的唯一位置。
        beginHideSession()
        setTabBarHiddenFromScroll(true)
        updateCheckTimer()
    }

    func expandTabBar() {
        // [EN] Guard: only a tab bar hidden by scrolling is shown again. [CN] 只恢复被滚动隐藏的 TabBar。
        guard hiddenByScroll else { return }
        let tabBarController = self.tabBarController
        // [EN] Guard (classic): a pushed page hides the bar through `hidesBottomBarWhenPushed`; wait until a page that shows it is back.
        // [CN] Guard（经典样式）：被 push 的页面通过 `hidesBottomBarWhenPushed` 隐藏了 TabBar；等显示 TabBar 的页面回来后再显示。
        if mode == .classic && Env.classicPageHidesTabBar(tabBarController?.selectedViewController) {
            return
        }
        hiddenByScroll = false
        guard mode == .flatDesign || mode == .classic else { return }
        if tabBarController?.isTabBarHidden ?? false {
            setTabBarHiddenFromScroll(false)
        }
        updateCheckTimer()
    }

    /// [EN] Scroll hiding's own call of the public `-setTabBarHidden:animated:`, marked so it is not taken for the app's.
    /// [CN] 滚动隐藏自己调用公开的 `-setTabBarHidden:animated:`，做上标记，避免被当作 App 的调用。
    private func setTabBarHiddenFromScroll(_ hidden: Bool) {
        settingTabBarHidden = true
        lastOwnRequestHidden = hidden
        lastOwnRequestTime = CACurrentMediaTime()
        appTookTabBarOver = false
        // [EN] No slide with Reduce Motion, nor when this window or its scene is not active (the app switcher snapshot shows the bar back).
        // [CN] 开启“减弱动态效果”时、或本窗口及其 Scene 不活跃时不执行滑动动画（App 切换器快照显示完整恢复的 TabBar）。
        let animated = !UIAccessibility.isReduceMotionEnabled && Env.windowIsKeyAndActive(tabBarController?.viewIfLoaded?.window)
        tabBarController?.setTabBarHidden(hidden, animated: animated)
        settingTabBarHidden = false
    }

    /**
     * [EN] The app called `-setTabBarHidden:animated:` itself: it owns the tab bar from now on, and the session ends. Ignored: scroll hiding's
     *      own calls, and a FlatDesign replay of our own last request within 0.5 s.
     * [CN] App 自己调用了 `-setTabBarHidden:animated:`：之后由 App 控制 TabBar，会话结束。忽略：滚动隐藏自己的调用，以及 0.5 秒内扁平样式对我们
     *      最近一次请求的重放。
     */
    func appDidRequestTabBarHidden(_ hidden: Bool) {
        guard !settingTabBarHidden else { return }
        if hidden == lastOwnRequestHidden && CACurrentMediaTime() - lastOwnRequestTime < 0.5 {
            return
        }
        // [EN] Any accepted app request: the safety net in `minimizeTabBar()` no longer takes the bar back.
        // [CN] 任何被接受的 App 请求：`minimizeTabBar()` 中的安全网不再收回 TabBar。
        appTookTabBarOver = true
        guard hiddenByScroll || hideSessionActive else { return }
        Env.log("the app takes the tab bar over", hidden ? "setTabBarHidden:YES" : "setTabBarHidden:NO")
        hiddenByScroll = false
        endHideSession()
        needsNewDrag = true
        lastSeenTracking = scrollView?.isTracking ?? false
        updateCheckTimer()
    }

    /// [EN] FlatDesign guard: the flat tab bar is on screen in the controller's view. [CN] 扁平样式 guard：扁平 TabBar 正显示在控制器的视图中。
    private func flatDesignCanHideTabBar() -> Bool {
        guard let tabBarController, let tabBar = tabBarController.cyl_tabBar else { return false }
        return Env.isFlatDesignTabBar(tabBar) && !tabBar.isHidden && tabBar.superview === tabBarController.view
    }

    /// [EN] Classic guard: the system tab bar is on screen at the bottom, not hidden by `hidesBottomBarWhenPushed`.
    /// [CN] 经典样式 guard：系统 TabBar 正显示在底部，且没有被 `hidesBottomBarWhenPushed` 隐藏。
    private func classicCanHideTabBar() -> Bool {
        guard let tabBarController else { return false }
        let tabBar: UITabBar = tabBarController.tabBar
        if tabBar.isHidden || tabBar.alpha < 0.01 || tabBar.window == nil || !Env.classicTabBarIsAtBottom(tabBar) {
            return false
        }
        return !Env.classicPageHidesTabBar(tabBarController.selectedViewController)
    }
}

/**
 * [EN] The stored state of this category, one object per tab bar controller. [CN] 本分类保存的状态，每个 TabBarController 一个对象。
 */
final class CYLTabBarMinimizeSettings: NSObject {
    /// [EN] nil until the app sets a value: UIKit's own default is left untouched. [CN] App 设置取值之前为 nil：不改动 UIKit 自身的默认值。
    var behavior: CYLTabBarMinimizeBehavior?
    var tracker: CYLTabBarMinimizeScrollTracker?
    /// [EN] Liquid Glass: `Never` is held to expand the bar until the user starts a new drag. [CN] 液态玻璃：为恢复 TabBar 保持 `Never`，直到用户开始新的拖动。
    var holdsSystemNever = false
}

private enum CYLTabBarMinimizeKeys {
    static let settings = CYLUtilsKeys.key("cyl_tabBarMinimizeSettings")
}

@available(iOS 26.0, *)
private extension CYLTabBarMinimizeBehavior {
    /// [EN] The native value. [CN] 对应的系统取值。
    var system: UITabBarController.MinimizeBehavior {
        switch self {
        case .never: return .never
        case .onScrollDown: return .onScrollDown
        case .onScrollUp: return .onScrollUp
        default: return .automatic
        }
    }

    init(system: UITabBarController.MinimizeBehavior) {
        switch system {
        case .never: self = .never
        case .onScrollDown: self = .onScrollDown
        case .onScrollUp: self = .onScrollUp
        default: self = .automatic
        }
    }
}

extension CYLTabBarController {

    private var cylMinimize: CYLTabBarMinimizeSettings {
        if let settings = objc_getAssociatedObject(self, CYLTabBarMinimizeKeys.settings) as? CYLTabBarMinimizeSettings {
            return settings
        }
        let settings = CYLTabBarMinimizeSettings()
        objc_setAssociatedObject(self, CYLTabBarMinimizeKeys.settings, settings, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return settings
    }

    @objc(cyl_tabBarMinimizeScrollViewForViewController:)
    func cylTabBarMinimizeScrollView(for viewController: UIViewController?) -> UIScrollView? {
        CYLTabBarMinimizeEnvironment.scrollView(for: viewController)
    }

    @objc(cyl_tabBarMinimizeBehavior)
    var cylTabBarMinimizeBehavior: CYLTabBarMinimizeBehavior {
        get { cylMinimize.behavior ?? .automatic }
        @objc(setCyl_tabBarMinimizeBehavior:) set {
            cylMinimize.behavior = newValue
            // [EN] A new value from the app ends a Liquid Glass hold. [CN] App 设置新取值时结束液态玻璃的保持状态。
            cylMinimize.holdsSystemNever = false
            cylUpdateTabBarMinimizeTracking()
        }
    }

    /**
     * [EN] Liquid Glass: UIKit has no API to expand a minimized tab bar. Writing `Never` (through `super`) makes the system expand it;
     *      `Never` is held until the user starts a new drag, then the app's value is written back. Does nothing on other systems or when
     *      the system value is already `Never`.
     * [CN] 液态玻璃：UIKit 没有恢复已缩小 TabBar 的接口。通过 `super` 写入 `Never` 让系统恢复 TabBar；`Never` 保持到用户开始新的拖动，之后写回
     *      App 的取值。其他系统或系统取值已是 `Never` 时不做处理。
     */
    @objc(cyl_expandSystemMinimizedTabBar)
    func cylExpandSystemMinimizedTabBar() {
        guard #available(iOS 26.0, *), super.tabBarMinimizeBehavior != .never else { return }
        cylMinimize.holdsSystemNever = true
        super.tabBarMinimizeBehavior = .never
        DispatchQueue.main.asyncAfter(deadline: .now() + CYLTabBarMinimizeConstants.liquidGlassExpandCheckDelay) {
            self.cylExpandSystemMinimizedTabBarFallbackIfNeeded()
        }
    }

    /**
     * [EN] Liquid Glass, second mechanism: if writing `Never` did not expand the bar, hide and show it once with UIKit's own
     *      `-setTabBarHidden:animated:` (not animated, through `super` so it is not taken for the app's request). Skipped for a bar the
     *      app hid itself.
     * [CN] 液态玻璃的第二种方式：如果写入 `Never` 没有恢复 TabBar，用 UIKit 自己的 `-setTabBarHidden:animated:`（无动画，通过 `super` 调用，
     *      不会被当作 App 的请求）隐藏再显示一次。App 自己隐藏的 TabBar 不处理。
     */
    private func cylExpandSystemMinimizedTabBarFallbackIfNeeded() {
        guard #available(iOS 26.0, *), CYLTabBarMinimizeEnvironment.showsMinimizedBar(cyl_tabBar), !super.isTabBarHidden else { return }
        CYLTabBarMinimizeEnvironment.log("Liquid Glass: writing Never did not expand the minimized tab bar; trying hide / show", nil)
        super.setTabBarHidden(true, animated: false)
        super.setTabBarHidden(false, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + CYLTabBarMinimizeConstants.liquidGlassExpandCheckDelay) {
            let stillMinimized = CYLTabBarMinimizeEnvironment.showsMinimizedBar(self.cyl_tabBar)
            CYLTabBarMinimizeEnvironment.log(stillMinimized ? "Liquid Glass: hide / show did not expand it either" : "Liquid Glass: hide / show expanded it", nil)
        }
    }

    @objc(cyl_releaseSystemMinimizeHoldIfNeeded)
    func cylReleaseSystemMinimizeHoldIfNeeded() {
        guard cylMinimize.holdsSystemNever else { return }
        cylMinimize.holdsSystemNever = false
        // [EN] Writes the app's value back to UIKit. [CN] 把 App 的取值写回 UIKit。
        cylUpdateTabBarMinimizeTracking()
    }

    // MARK: cyl_hidesTabBarOnScroll

    @objc(cyl_isTabBarHiddenByScroll)
    var cylIsTabBarHiddenByScroll: Bool {
        cylMinimize.tracker?.isTabBarHiddenOrMinimizedByScroll() ?? false
    }

    @objc(cyl_simulateHideOnScrollForTesting)
    func cylSimulateHideOnScrollForTesting() -> Bool {
        cylUpdateTabBarMinimizeTracking()
        guard let tracker = cylMinimize.tracker else {
            CYLTabBarMinimizeEnvironment.log("test hide refused", "no scroll tracker (scroll hiding is off, or no scroll view on the selected page)")
            return false
        }
        return tracker.simulateHideForTesting()
    }

    /**
     * [EN] The direct switch, one branch per style. All branches store the same value as `cyl_tabBarMinimizeBehavior` (OnScrollDown or
     *      Never), so the two APIs always agree, also after a style change.
     * [CN] 直接的开关，每种样式一个分支。所有分支保存的都是与 `cyl_tabBarMinimizeBehavior` 相同的取值（OnScrollDown 或 Never），因此两个接口始终一致，
     *      样式改变后也一样。
     */
    @objc(cyl_hidesTabBarOnScroll)
    var cylHidesTabBarOnScroll: Bool {
        get {
            let behavior = cylTabBarMinimizeBehavior
            return behavior == .onScrollDown || behavior == .onScrollUp
        }
        @objc(setCyl_hidesTabBarOnScroll:) set {
            // [EN] 1. Liquid Glass (iOS 26+): Apple's own API; the system minimizes the tab bar.
            // [CN] 1. 液态玻璃（iOS 26+）：直接调用 Apple 自己的接口，由系统缩小 TabBar。
            if #available(iOS 26.0, *), tabBarStyleType != .flatDesign, CYLConstants.isLiquidGlassActive() {
                cylSetSystemTabBarMinimizeBehaviorFromApp(newValue ? .onScrollDown : .never)
                return
            }
            // [EN] 2. FlatDesign and 3. the classic tab bar: CYLTabBarController follows the page's scroll view and hides the bar with
            //      `-setTabBarHidden:animated:`.
            // [CN] 2. 扁平样式与 3. 经典 TabBar：CYLTabBarController 跟随页面的滚动视图，用 `-setTabBarHidden:animated:` 隐藏 TabBar。
            cylTabBarMinimizeBehavior = newValue ? .onScrollDown : .never
        }
    }

    /**
     * [EN] The same switch through Apple's own API (iOS 26+): `tabBarController.tabBarMinimizeBehavior = ...` turns scroll hiding on and
     *      off in every style, exactly as `cyl_tabBarMinimizeBehavior`. `CYLTabBarController.m` overrides `-setTabBarMinimizeBehavior:` and
     *      `-tabBarMinimizeBehavior` with these two (a Swift override would put this class into the generated header); the value really
     *      given to UIKit is written through `super`.
     * [CN] 通过 Apple 自己的接口（iOS 26+）使用同一个开关：`tabBarController.tabBarMinimizeBehavior = ...` 在所有样式下开启、关闭滚动隐藏，与
     *      `cyl_tabBarMinimizeBehavior` 完全相同。`CYLTabBarController.m` 用下面两个方法重写 `-setTabBarMinimizeBehavior:` 与
     *      `-tabBarMinimizeBehavior`（Swift 的 override 会把本类写入生成的头文件）；真正交给 UIKit 的取值通过 `super` 写入。
     */
    @available(iOS 26.0, *)
    @objc(cyl_setSystemTabBarMinimizeBehaviorFromApp:)
    func cylSetSystemTabBarMinimizeBehaviorFromApp(_ behavior: UITabBarController.MinimizeBehavior) {
        cylTabBarMinimizeBehavior = CYLTabBarMinimizeBehavior(system: behavior)
    }

    @available(iOS 26.0, *)
    @objc(cyl_systemTabBarMinimizeBehaviorForApp)
    func cylSystemTabBarMinimizeBehaviorForApp() -> UITabBarController.MinimizeBehavior {
        // [EN] Not set by the app yet: UIKit's own value. [CN] App 尚未设置：返回 UIKit 自己的取值。
        guard let behavior = cylMinimize.behavior else { return super.tabBarMinimizeBehavior }
        return behavior.system
    }

    @objc(cyl_updateTabBarMinimizeTracking)
    func cylUpdateTabBarMinimizeTracking() {
        let settings = cylMinimize
        // [EN] Nothing to do until the app sets a value. [CN] App 设置取值之前不做任何处理。
        guard let behavior = settings.behavior else { return }
        if #available(iOS 26.0, *) {
            // [EN] Only Liquid Glass lets the system minimize the tab bar; FlatDesign and the classic tab bar hide it themselves, so the system
            //      is told never to minimize. Checked on every layout; only a different value is written, through `super`. While a hold keeps
            //      `Never` to expand the bar, leave it.
            // [CN] 只有液态玻璃交给系统缩小 TabBar；扁平样式与经典 TabBar 自行隐藏，因此让系统不缩小。每次布局都会检查；只有取值不同时才通过 `super` 写入。
            //      为恢复 TabBar 保持 `Never` 期间不改动。
            let systemMinimizes = !settings.holdsSystemNever && tabBarStyleType != .flatDesign && CYLConstants.isLiquidGlassActive()
            let systemBehavior: UITabBarController.MinimizeBehavior = systemMinimizes ? behavior.system : .never
            if super.tabBarMinimizeBehavior != systemBehavior {
                super.tabBarMinimizeBehavior = systemBehavior
            }
        }
        let mode = CYLTabBarMinimizeMode.mode(for: self)
        // [EN] Not Liquid Glass any more: drop a hold, nothing will release it. [CN] 不再是液态玻璃：清除保持状态，之后不会再有释放它的拖动。
        if mode != .liquidGlass {
            settings.holdsSystemNever = false
        }
        guard mode != .none else {
            if let tracker = settings.tracker {
                let previousMode = tracker.mode
                // [EN] Turned off: stop observing and give back a tab bar that scrolling hid. [CN] 已关闭：停止观察，并恢复被滚动隐藏的 TabBar。
                tracker.observe(nil)
                tracker.updateMode(.none)
                settings.tracker = nil
                // [EN] Liquid Glass: put the plus button back at its usual position. [CN] 液态玻璃：让 PlusButton 回到常规位置。
                if previousMode == .liquidGlass && isViewLoaded {
                    cyl_tabBar?.setNeedsLayout()
                }
            }
            return
        }
        let tracker = settings.tracker ?? CYLTabBarMinimizeScrollTracker(tabBarController: self)
        settings.tracker = tracker
        tracker.updateMode(mode)
        tracker.observeTaps(in: viewIfLoaded)
        let scrollView = tracker.scrollView(forSelectedViewController: selectedViewController)
        if scrollView !== tracker.scrollView {
            // [EN] Another tab or page is on screen: show the tab bar again, as the system does. [CN] 切换到其他 Tab 或页面：与系统一致，重新显示 TabBar。
            tracker.restoreTabBar(reason: "page or scroll view changed")
            tracker.observe(scrollView)
        }
        // [EN] Every layout of this controller checks the hide session. [CN] 本控制器每次布局都检查隐藏会话。
        tracker.validateHideSession()
    }

    @objc(cyl_tabBarMinimizeDidReceiveTabBarHiddenRequest:)
    func cylTabBarMinimizeDidReceiveTabBarHiddenRequest(_ hidden: Bool) {
        cylMinimize.tracker?.appDidRequestTabBarHidden(hidden)
    }

    @objc(cyl_tabBarMinimizeLifecycleEvent)
    func cylTabBarMinimizeLifecycleEvent() {
        // [EN] Guard: only while scroll hiding is on. [CN] 仅在开启滚动隐藏时处理。
        cylMinimize.tracker?.restoreTabBar(reason: "view lifecycle (appear / disappear / size change)")
    }
}
