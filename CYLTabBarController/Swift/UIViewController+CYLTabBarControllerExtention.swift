//
//  UIViewController+CYLTabBarControllerExtention.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 16/2/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] `UIViewController (CYLTabBarControllerExtention)` and `(CYLTabBarControllerExtentionDeprecated)`: what a page knows
 *      about its tab (index, identifier, tab button), selecting another tab with its stack popped, pushing or popping to a
 *      page, and the badge of its tab (`CYLBadgeProtocol`, forwarded to the view or item that hosts it). Translated from
 *      Objective-C (docs/Swift-Migration.md, step 27); every declared selector and Swift name is kept. The FlatDesign item
 *      (`cyl_tabBarItem`) lives in the FlatDesign subspec; Core reaches FlatDesign only by selector and class name, so it
 *      builds without it.
 * [CN] `UIViewController (CYLTabBarControllerExtention)` 与 `(CYLTabBarControllerExtentionDeprecated)`：页面对其 Tab 的了解（下标、
 *      标识、Tab 按钮）、pop 当前栈并选中另一个 Tab、push 或 pop 到某个页面，以及其 Tab 的角标（`CYLBadgeProtocol`，转发给承载角标的
 *      视图或 item）。已从 Objective-C 翻译（docs/Swift-Migration.md，第 27 步），保留所有已声明的 selector 与 Swift 名称。扁平样式的
 *      item（`cyl_tabBarItem`）位于扁平样式子库中；Core 只通过 selector 与类名访问扁平样式，因此没有它也能编译。
 */
/**
 * [EN] `CYLPopSelectTabBarChildViewControllerCompletion`, `CYLPushOrPopCompletionHandler` and `CYLPushOrPopCallback` of the
 *      Objective-C header, spelled out: a typedef of a module header in a public signature makes the generated header import
 *      the umbrella header (a cycle) and use the typedef before it is declared.
 * [CN] Objective-C 头文件中的 `CYLPopSelectTabBarChildViewControllerCompletion`、`CYLPushOrPopCompletionHandler` 与
 *      `CYLPushOrPopCallback` 的展开写法：公开签名中使用模块头文件的 typedef 会让生成的头文件导入总头文件（形成循环），并在 typedef
 *      声明之前使用它。
 */
public typealias CYLPopSelectCompletion = (UIViewController?) -> Void
public typealias CYLPushOrPopHandler = (_ shouldPop: Bool, _ viewControllerPopTo: UIViewController?,
                                        _ shouldPopSelectTabBarChildViewController: Bool, _ index: UInt) -> Void
public typealias CYLPushOrPopDecision = (_ viewControllers: [UIViewController], _ completionHandler: @escaping CYLPushOrPopHandler) -> Void

enum CYLViewControllerTabBarKeys {
    static let tabIndex = CYLUtilsKeys.key("cyl_tabIndex")
    static let tabBarItemIdentifier = CYLUtilsKeys.key("cyl_tabBarItemIdentifier")
    static let tabButton = CYLUtilsKeys.key("cyl_tabButton")
    static let plusViewControllerEverAdded = CYLUtilsKeys.key("cyl_plusViewControllerEverAdded")
}

/**
 * [EN] The FlatDesign subspec, reached by selector and class name (it is optional).
 * [CN] 扁平样式子库（可选），通过 selector 与类名访问。
 */
enum CYLFlatDesignLookup {
    static let tabBarClass: AnyClass? = NSClassFromString("CYLFlatDesignTabBar")
    static let tabBarItemClass: AnyClass? = NSClassFromString("CYLFlatDesignTabBarItem")
    static let tabBarButtonClass: AnyClass? = NSClassFromString("CYLFlatDesignTabBarButton")

    static func object(_ target: NSObject?, _ selectorName: String) -> NSObject? {
        let selector = NSSelectorFromString(selectorName)
        guard let target, target.responds(to: selector) else { return nil }
        return target.perform(selector)?.takeUnretainedValue() as? NSObject
    }

    static func isKind(_ object: NSObject?, _ objectClass: AnyClass?) -> Bool {
        guard let object, let objectClass else { return false }
        return object.isKind(of: objectClass)
    }

    /**
     * [EN] The FlatDesign item of `viewController` (`-cyl_tabBarItem`), nil without FlatDesign.
     * [CN] `viewController` 的扁平样式 item（`-cyl_tabBarItem`），没有扁平样式时为 nil。
     */
    static func tabBarItem(of viewController: UIViewController) -> NSObject? {
        object(viewController, "cyl_tabBarItem")
    }
}

extension UIViewController {

    // MARK: The tab bar style

    /**
     * [EN] YES if `self` is a CYLTabBarController with a system tab bar (classic or Liquid Glass).
     * [CN] `self` 为使用系统 TabBar（经典或液态玻璃）的 CYLTabBarController 时为 YES。
     */
    @objc(cyl_isSystemStyleTabBar)
    public func cyl_isSystemStyleTabBar() -> Bool {
        guard let tabBarController = self as? CYLTabBarController else { return false }
        return tabBarController.tabBarStyleType != .flatDesign
    }

    /**
     * [EN] YES if `self` is a CYLTabBarController with the FlatDesign tab bar.
     * [CN] `self` 为使用扁平样式 TabBar 的 CYLTabBarController 时为 YES。
     */
    @objc(cyl_isFlatDesignStyleTabBar)
    public func cyl_isFlatDesignStyleTabBar() -> Bool {
        (self as? CYLTabBarController)?.tabBarStyleType == .flatDesign
    }

    // MARK: What the page knows about its tab

    /**
     * [EN] YES when the page (or the root of its navigation controller) is a tab of a tab bar controller; also updates
     *      `cyl_tabIndex`. NO for the plus child view controller and placeholders.
     * [CN] 页面（或其导航控制器的根页面）是某个 TabBarController 的 Tab 时为 YES，并更新 `cyl_tabIndex`。PlusButton 子控制器与占位页面为 NO。
     */
    @objc(cyl_embedInTabBarController)
    public var cyl_embedInTabBarController: Bool {
        @objc(cyl_isEmbedInTabBarController) get {
            let contentViewController = cyl_getViewControllerInsteadOfNavigation()
            guard cyl_tabBarController != nil || contentViewController.cyl_tabBarController != nil,
                  !cyl_isPlusChildViewController, !cyl_isPlaceholder, !contentViewController.cyl_isPlaceholder,
                  let viewControllers = cyl_tabBarController?.viewControllers,
                  let index = viewControllers.firstIndex(where: { $0.cyl_getViewControllerInsteadOfNavigation() === contentViewController }) else {
                return false
            }
            objc_setAssociatedObject(self, CYLViewControllerTabBarKeys.tabIndex, NSNumber(value: index), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return true
        }
    }

    /**
     * [EN] The index of the page's tab; `NSNotFound` when it is not a tab (`cyl_embedInTabBarController`).
     * [CN] 页面所在 Tab 的下标；不是 Tab 时（`cyl_embedInTabBarController`）为 `NSNotFound`。
     */
    @objc(cyl_tabIndex)
    public var cyl_tabIndex: Int {
        guard cyl_embedInTabBarController else { return NSNotFound }
        return (objc_getAssociatedObject(self, CYLViewControllerTabBarKeys.tabIndex) as? NSNumber)?.intValue ?? 0
    }

    /**
     * FIX: issue #408
     * [EN] The tab's identifier (`CYLTabBarItemIdentifier`), else the default of the tab bar controller it belongs to (any
     *      style). Setting it also sets it on the content page (e.g. a navigation controller's root), where app code is.
     * [CN] Tab 的标识（`CYLTabBarItemIdentifier`），未设置时为所属 TabBarController（任意样式）生成的默认值。设置时也会设置到内容页面
     *      （例如导航控制器的根页面），App 代码通常在那里。
     */
    @objc(cyl_tabBarItemIdentifier)
    public var cyl_tabBarItemIdentifier: String? {
        @objc(cyl_tabBarItemIdentifier) get {
            if let identifier = objc_getAssociatedObject(self, CYLViewControllerTabBarKeys.tabBarItemIdentifier) as? String {
                return identifier
            }
            return cyl_owningTabBarController()?.cyl_defaultTabBarItemIdentifier(for: self)
        }
        @objc(cyl_setTabBarItemIdentifier:) set {
            objc_setAssociatedObject(self, CYLViewControllerTabBarKeys.tabBarItemIdentifier, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            let contentViewController = cyl_getViewControllerInsteadOfNavigation()
            if contentViewController !== self {
                objc_setAssociatedObject(contentViewController, CYLViewControllerTabBarKeys.tabBarItemIdentifier, newValue,
                                         .OBJC_ASSOCIATION_COPY_NONATOMIC)
            }
        }
    }

    /**
     * [EN] The tab button of the page's tab (the plus button for the plus child view controller); stored on the page and on
     *      its content page.
     * [CN] 页面所在 Tab 的按钮（PlusButton 子控制器对应 PlusButton）；保存在页面及其内容页面上。
     */
    @objc(cyl_tabButton)
    public var cyl_tabButton: UIControl? {
        @objc(cyl_tabButton) get {
            let stored = objc_getAssociatedObject(self, CYLViewControllerTabBarKeys.tabButton) as? UIControl
            // FIX: issue #605
            // [EN] A stored button that left the tab bar was replaced by UIKit (the classic tab bar does that when a tab's
            //      title changes): look up the current one below.
            // [CN] 已离开 TabBar 的已存储按钮被 UIKit 替换了（经典 TabBar 在 Tab 标题变化时会这样）：在下面查找当前按钮。
            if let stored {
                let isReplaced = stored.superview == nil && stored.cyl_isTabButton() && !CYLConstants.isLiquidGlassActive()
                    && cyl_tabBarController?.tabBarStyleType != .flatDesign
                if !isReplaced {
                    return stored
                }
            }
            return cyl_lookUpTabButton()
        }
        @objc(cyl_setTabButton:) set {
            objc_setAssociatedObject(self, CYLViewControllerTabBarKeys.tabButton, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(cyl_getViewControllerInsteadOfNavigation(), CYLViewControllerTabBarKeys.tabButton, newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] YES once the page was added as the plus child view controller.
     * [CN] 页面曾作为 PlusButton 子控制器添加后为 YES。
     */
    @objc(cyl_plusViewControllerEverAdded)
    public var cyl_plusViewControllerEverAdded: Bool {
        @objc(cyl_plusViewControllerEverAdded) get {
            (objc_getAssociatedObject(self, CYLViewControllerTabBarKeys.plusViewControllerEverAdded) as? NSNumber)?.boolValue ?? false
        }
        @objc(cyl_setPlusViewControllerEverAdded:) set {
            objc_setAssociatedObject(self, CYLViewControllerTabBarKeys.plusViewControllerEverAdded, NSNumber(value: newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] The tab button that shows the page's tab now: the selected-state button under Liquid Glass, else `cyl_tabButton`.
     * [CN] 当前显示页面所在 Tab 的按钮：液态玻璃下为选中态按钮，否则为 `cyl_tabButton`。
     */
    @objc(cyl_visiableTabButton)
    public func cyl_visiableTabButton() -> UIControl? {
        if CYLConstants.isLiquidGlassActive() {
            return tabBarItem.cyl_selectedTabButton
        }
        return cyl_tabButton
    }

    /**
     * [EN] YES if the two pages are the same, or have the same content page (navigation controllers compare their roots).
     * [CN] 两个页面相同，或内容页面相同（导航控制器比较其根页面）时为 YES。
     */
    @objc(cyl_isEqualToViewController:)
    public func cyl_isEqual(to compairedViewController: UIViewController) -> Bool {
        self == compairedViewController
            || cyl_getViewControllerInsteadOfNavigation() == compairedViewController.cyl_getViewControllerInsteadOfNavigation()
    }

    /**
     * [EN] `-addChildViewController:` that ignores anything but a page, and placeholders.
     * [CN] 忽略非页面对象与占位页面的 `-addChildViewController:`。
     */
    @objc(cyl_addChildViewController:)
    public func cyl_addChildViewController(_ childController: Any) {
        guard let viewController = childController as? UIViewController, !viewController.cyl_isPlaceholder,
              !viewController.cyl_getViewControllerInsteadOfNavigation().cyl_isPlaceholder else {
            return
        }
        addChild(viewController)
    }

    /**
     * [EN] How far the tab bar overlaps the page's view from the bottom; 0 when it is hidden, off the page or the page is
     *      pushed with `hidesBottomBarWhenPushed`.
     * [CN] TabBar 从底部遮住页面视图的高度；TabBar 隐藏、不在页面上，或页面以 `hidesBottomBarWhenPushed` push 时为 0。
     */
    @objc(cyl_tabBarSpacingInViewCoordinator)
    public var cyl_tabBarSpacingInViewCoordinator: CGFloat {
        guard isViewLoaded, view.window != nil, let tabBarController else { return 0 }
        var tabBar: UIView = tabBarController.tabBar
        // [EN] FlatDesign draws its own bar. [CN] 扁平样式使用自己的 TabBar。
        if let flatTabBar = (tabBarController as? CYLTabBarController)?.cyl_tabBar {
            tabBar = flatTabBar
        }
        guard tabBar.superview != nil, !tabBar.isHidden, tabBar.alpha > 0.01 else { return 0 }
        if hidesBottomBarWhenPushed, let navigationController, navigationController.viewControllers.first !== self {
            return 0
        }
        let overlap = view.bounds.intersection(view.convert(tabBar.bounds, from: tabBar))
        if overlap.isNull || overlap.isEmpty {
            return 0
        }
        return view.bounds.maxY - overlap.minY
    }

    // MARK: Selecting a tab with the current stack popped

    /**
     * [EN] Pops the current navigation stack to its root and selects the tab at `index`, without animation. Returns the
     *      selected page (the content page, not its navigation controller), or nil for an index that is not a tab.
     * [CN] 将当前导航栈 pop 到根页面，并选中 `index` 处的 Tab，无动画。返回选中的页面（内容页面，而非其导航控制器）；index 不是 Tab 时返回 nil。
     */
    @objc(cyl_popSelectTabBarChildViewControllerAtIndex:)
    @discardableResult
    public func cyl_popSelectTabBarChildViewController(at index: UInt) -> UIViewController? {
        cyl_popSelectTabBarChildViewController(at: index, animated: false)
    }

    /**
     * FIX: issue #519
     * [EN] The same, with `animated`. The current stack is popped after the tab switch, while it is off screen, so both it
     *      and the newly selected tab are laid out at once (else the navigation bar is updated only when the tab is shown
     *      again, and the tab flickers). Popping before the switch is not an option: the popped page would disappear on
     *      screen, and work it does in `-viewDidDisappear:`, such as a forced rotation, breaks the switch.
     * [CN] 同上，带 `animated`。当前导航栈在切换 Tab 之后、已不在屏幕上时才 pop，因此立即对它和新选中的 Tab 布局（否则导航栏要等再次显示该 Tab
     *      时才更新，导致闪动）。不能改为先 pop 再切换：被 pop 的页面会在屏幕上消失，它在 `-viewDidDisappear:` 中的操作（例如强制旋转）会打乱切换。
     */
    @objc(cyl_popSelectTabBarChildViewControllerAtIndex:animated:)
    @discardableResult
    public func cyl_popSelectTabBarChildViewController(at index: UInt, animated: Bool) -> UIViewController? {
        let viewController = cyl_getViewControllerInsteadOfNavigation()
        guard let tabBarController = viewController.cyl_popSelectTabBarController,
              let viewControllers = tabBarController.viewControllers, index < viewControllers.count else {
            cyl_logInvalidTabIndex()
            return nil
        }
        viewController.cyl_deselectPlusButtonIfNeeded(in: tabBarController, forIndex: Int(index))
        let navigationController = viewController.cyl_popSelectNavigationController(in: tabBarController)
        tabBarController.selectedIndex = Int(index)
        navigationController?.popToRootViewController(animated: animated)
        navigationController?.view.setNeedsLayout()
        navigationController?.view.layoutIfNeeded()
        let selectedViewController = tabBarController.selectedViewController
        selectedViewController?.view.setNeedsLayout()
        selectedViewController?.view.layoutIfNeeded()
        return selectedViewController?.cyl_getViewControllerInsteadOfNavigation()
    }

    /**
     * [EN] The same, calling `completion` with the selected page on the next main queue turn.
     * [CN] 同上，在下一次主队列循环中以选中的页面调用 `completion`。
     */
    @objc(cyl_popSelectTabBarChildViewControllerAtIndex:completion:)
    public func cyl_popSelectTabBarChildViewController(at index: UInt,
                                                        completion: CYLPopSelectCompletion?) {
        let selected = cyl_popSelectTabBarChildViewController(at: index)
        cyl_callOnMainQueue(completion, with: selected)
    }

    /**
     * [EN] Selects the leftmost tab whose content page is a `classType`; nil when there is none.
     * [CN] 选中内容页面为 `classType` 的最左侧 Tab；没有时返回 nil。
     */
    @objc(cyl_popSelectTabBarChildViewControllerForClassType:)
    @discardableResult
    public func cyl_popSelectTabBarChildViewController(forClassType classType: AnyClass) -> UIViewController? {
        let viewControllers = cyl_getViewControllerInsteadOfNavigation().cyl_popSelectTabBarController?.viewControllers ?? []
        guard let index = viewControllers.firstIndex(where: { $0.cyl_getViewControllerInsteadOfNavigation().isKind(of: classType) }) else {
            cyl_logInvalidTabIndex()
            return nil
        }
        return cyl_popSelectTabBarChildViewController(at: UInt(index))
    }

    /**
     * [EN] The same, calling `completion` with the selected page on the next main queue turn.
     * [CN] 同上，在下一次主队列循环中以选中的页面调用 `completion`。
     */
    @objc(cyl_popSelectTabBarChildViewControllerForClassType:completion:)
    public func cyl_popSelectTabBarChildViewController(forClassType classType: AnyClass,
                                                        completion: CYLPopSelectCompletion?) {
        let selected = cyl_popSelectTabBarChildViewController(forClassType: classType)
        cyl_callOnMainQueue(completion, with: selected)
    }

    /**
     * FIX: issue #408
     * [EN] Selects the tab with `identifier` (`CYLTabBarItemIdentifier`, else the default; the plus child view controller's
     *      is the plus button's), without animation; nil when no tab has it. Still right after tabs are added or removed.
     * [CN] 选中标识为 `identifier` 的 Tab（`CYLTabBarItemIdentifier`，未设置时为默认值；PlusButton 子控制器的标识即 PlusButton 的标识），
     *      无动画；找不到时返回 nil。增减 Tab 后依然准确。
     */
    @objc(cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier:)
    @discardableResult
    public func cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier identifier: String) -> UIViewController? {
        cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier: identifier, animated: false)
    }

    /**
     * [EN] The same, with `animated`.
     * [CN] 同上，带 `animated`。
     */
    @objc(cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier:animated:)
    @discardableResult
    public func cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier identifier: String,
                                                        animated: Bool) -> UIViewController? {
        // [EN] NSNotFound for an unknown identifier: rejected by the index version. [CN] 标识不存在时为 NSNotFound，由 index 版本拒绝。
        guard let tabBarController = cyl_getViewControllerInsteadOfNavigation().cyl_popSelectTabBarController else {
            return nil
        }
        return cyl_popSelectTabBarChildViewController(at: tabBarController.cyl_index(ofTabBarItemIdentifier: identifier),
                                                      animated: animated)
    }

    /**
     * [EN] The same, calling `completion` with the selected page on the next main queue turn.
     * [CN] 同上，在下一次主队列循环中以选中的页面调用 `completion`。
     */
    @objc(cyl_popSelectTabBarChildViewControllerForTabBarItemIdentifier:completion:)
    public func cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier identifier: String,
                                                        completion: CYLPopSelectCompletion?) {
        let selected = cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier: identifier)
        cyl_callOnMainQueue(completion, with: selected)
    }

    // MARK: Pushing or popping to a page

    /**
     * [EN] Pushes `viewController`, or pops back to a page of the same class already in the stack, as `callback` decides:
     *      it gets those pages and a completion handler (should pop, the page to pop to, whether to select a tab first and
     *      its index). A nil `callback` pushes.
     * [CN] push `viewController`，或 pop 回栈中已有的同类页面，由 `callback` 决定：它收到这些页面和一个 completion handler（是否 pop、pop
     *      回的页面、是否先选中某个 Tab 及其下标）。`callback` 为 nil 时直接 push。
     */
    @objc(cyl_pushOrPopToViewController:animated:callback:)
    public func cyl_pushOrPop(to viewController: UIViewController, animated: Bool, callback: CYLPushOrPopDecision?) {
        cyl_pushOrPop(to: viewController, animated: animated, popSelectIdentifier: nil, callback: callback)
    }

    /**
     * FIX: issue #408
     * [EN] The same, selecting the tab with `identifier` instead of the index the completion handler passes.
     * [CN] 同上，按 `identifier` 选中 Tab，而不是 completion handler 传入的下标。
     */
    @objc(cyl_pushOrPopToViewController:animated:tabBarItemIdentifier:callback:)
    public func cyl_pushOrPop(to viewController: UIViewController, animated: Bool, tabBarItemIdentifier identifier: String,
                              callback: CYLPushOrPopDecision?) {
        cyl_pushOrPop(to: viewController, animated: animated, popSelectIdentifier: identifier, callback: callback)
    }

    /**
     * [EN] Pushes `viewController` unless it, or a page of its class, is already on top of the stack (UIKit raises when the
     *      same instance is pushed twice).
     * [CN] push `viewController`，除非它已在栈中，或栈顶已是同类页面（同一实例重复 push 时 UIKit 会抛异常）。
     */
    @objc(cyl_pushViewController:animated:)
    public func cyl_push(_ viewController: UIViewController, animated: Bool) {
        let navigationController = cyl_getViewControllerInsteadOfNavigation().navigationController
        let stack = navigationController?.children ?? []
        if stack.contains(viewController) || stack.last?.isKind(of: type(of: viewController)) == true {
            return
        }
        navigationController?.pushViewController(viewController, animated: animated)
    }

    /**
     * [EN] Goes back, animated: pops, or dismisses a presented page that is the root of its stack.
     * [CN] 返回（带动画）：pop；以模态方式显示且为栈底的页面则 dismiss。
     */
    @objc(cyl_handleNavigationBackAction)
    public func cyl_handleNavigationBackAction() {
        cyl_handleNavigationBackAction(withAnimated: true)
    }

    /**
     * [EN] The same, with `animated`.
     * [CN] 同上，带 `animated`。
     */
    @objc(cyl_handleNavigationBackActionWithAnimated:)
    public func cyl_handleNavigationBackAction(withAnimated animated: Bool) {
        if presentationController == nil || (navigationController?.viewControllers.count ?? 0) > 1 {
            navigationController?.popViewController(animated: animated)
        } else {
            dismiss(animated: animated)
        }
    }

    // MARK: Private

    private var cyl_isPlusChildViewController: Bool {
        guard let plusChildViewController = CYLPlusButton.plusChildViewController(forOwner: self) else { return false }
        return plusChildViewController === self
    }

    /**
     * [EN] The tab bar controller `cyl_popSelect…` switches: the one `self` is in, of any style, else `cyl_tabBarController`
     *      (which alone finds only system styles).
     * [CN] `cyl_popSelect…` 切换的 TabBarController：`self` 所在的那个（任意样式），否则取 `cyl_tabBarController`（它只能找到系统样式）。
     */
    private var cyl_popSelectTabBarController: CYLTabBarController? {
        cyl_owningTabBarController() ?? cyl_tabBarController
    }

    /**
     * [EN] The stack `cyl_popSelect…` pops: the one `self` is in, only if it is inside `tabBarController` (popping an outer
     *      stack would remove the whole tab bar controller); else the selected tab's. Call it before switching tabs.
     * [CN] `cyl_popSelect…` 要 pop 的导航栈：`self` 所在的那个，且必须在 `tabBarController` 之内（pop 外层导航栈会移除整个 TabBarController）；
     *      否则为当前选中 Tab 的导航栈。需要在切换 Tab 之前调用。
     */
    private func cyl_popSelectNavigationController(in tabBarController: CYLTabBarController) -> UINavigationController? {
        if let navigationController, navigationController !== tabBarController.navigationController {
            return navigationController
        }
        return tabBarController.selectedViewController as? UINavigationController
    }

    /**
     * [EN] Deselects the plus button when another tab than the plus child view controller's is selected.
     * [CN] 选中的不是 PlusButton 子控制器所在的 Tab 时，取消 PlusButton 的选中状态。
     */
    private func cyl_deselectPlusButtonIfNeeded(in tabBarController: CYLTabBarController, forIndex index: Int) {
        guard let plusChildViewController = CYLPlusButton.plusChildViewController(forOwner: tabBarController),
              let viewControllers = tabBarController.viewControllers, index < viewControllers.count else {
            return
        }
        let plusButtonIndex = (tabBarController.cyl_tabBar as UIView?)?.cyl_plusButtonIndex() ?? 0
        if UInt(index) != plusButtonIndex && viewControllers[index] !== plusChildViewController {
            CYLPlusButton(forOwner: tabBarController)?.isSelected = false
        }
    }

    private func cyl_logInvalidTabIndex() {
#if DEBUG
        let reason = "The class type, index or navigation controller passed to `-cyl_popSelectTabBarChildViewController…` "
            + "is not a tab of the CYLTabBarController."
        NSLog(CYLLocalizedString("🔴类名与方法名：%@（在第%@行）, 描述：%@"), "\(type(of: self)) \(#function)" as NSString,
              "\(#line)" as NSString, reason as NSString)
#endif
    }

    private func cyl_callOnMainQueue(_ completion: CYLPopSelectCompletion?, with selected: UIViewController?) {
        DispatchQueue.main.async {
            completion?(selected)
        }
    }

    /**
     * [EN] The shared push-or-pop: `identifier` nil selects by the index the completion handler passes, else by identifier.
     * [CN] 共用的 push 或 pop 实现：`identifier` 为 nil 时按 completion handler 传入的下标选中，否则按标识。
     */
    private func cyl_pushOrPop(to viewController: UIViewController, animated: Bool, popSelectIdentifier identifier: String?,
                               callback: CYLPushOrPopDecision?) {
        // [EN] `self` may be the navigation controller itself, whose `navigationController` is nil: nothing is pushed then.
        // [CN] `self` 可能就是导航控制器本身，它的 `navigationController` 为 nil，此时什么都不会 push。
        let currentNavigationController = cyl_getViewControllerInsteadOfNavigation().navigationController
        guard let callback else {
            currentNavigationController?.pushViewController(viewController, animated: animated)
            return
        }
        let pushAfterSelecting: CYLPopSelectCompletion = { selected in
            // [EN] An invalid tab selects nothing (nil), and a tab may not be in a navigation controller: push onto the
            //      current stack then.
            // [CN] 无效 Tab 时什么都不选（nil），Tab 也可能不在导航控制器中：此时 push 到当前导航栈。
            let navigationController = selected?.navigationController ?? currentNavigationController
            navigationController?.pushViewController(viewController, animated: animated)
        }
        let sameClassViewControllers = cyl_otherViewControllersInStack(ofClassOf: viewController)
        let completionHandler: CYLPushOrPopHandler = { shouldPop, viewControllerPopTo, shouldPopSelect, index in
            DispatchQueue.main.async {
                // [EN] `-popToViewController:animated:` raises for a page that is not in the stack: push then.
                // [CN] `-popToViewController:animated:` 的目标不在栈中时会抛异常：此时改为 push。
                if shouldPop, !sameClassViewControllers.isEmpty, let viewControllerPopTo,
                   currentNavigationController?.viewControllers.contains(viewControllerPopTo) == true {
                    currentNavigationController?.popToViewController(viewControllerPopTo, animated: animated)
                    return
                }
                guard shouldPopSelect else {
                    currentNavigationController?.pushViewController(viewController, animated: animated)
                    return
                }
                if let identifier {
                    self.cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier: identifier, completion: pushAfterSelecting)
                } else {
                    self.cyl_popSelectTabBarChildViewController(at: index, completion: pushAfterSelecting)
                }
            }
        }
        callback(sameClassViewControllers, completionHandler)
    }

    /**
     * [EN] The pages of the current stack, other than this page, that are of `viewController`'s class.
     * [CN] 当前导航栈中除本页面以外、与 `viewController` 同类的页面。
     */
    private func cyl_otherViewControllersInStack(ofClassOf viewController: UIViewController) -> [UIViewController] {
        let contentViewController = cyl_getViewControllerInsteadOfNavigation()
        let stack = contentViewController.navigationController?.children ?? []
        guard stack.count >= 2 else { return [] }
        return stack.filter { $0 !== contentViewController && $0.isKind(of: type(of: viewController)) }
    }

    /**
     * [EN] Looks up the tab button: by the tab index, the plus button for a placeholder, the FlatDesign item's button, then
     *      the button of the page's (or its content page's) `tabBarItem`.
     * [CN] 查找 Tab 按钮：依次按 Tab 下标、占位页面对应的 PlusButton、扁平样式 item 的按钮、页面（或其内容页面）`tabBarItem` 的按钮。
     */
    private func cyl_lookUpTabButton() -> UIControl? {
        let tabIndex = cyl_tabIndex
        if tabIndex != NSNotFound, let items = cyl_tabBarController?.tabBar.items, tabIndex < items.count,
           let control = items[tabIndex].cyl_tabButton {
            return control
        }
        if tabIndex == NSNotFound || (cyl_tabBarController?.tabBar.items?.count ?? 0) <= tabIndex,
           cyl_isPlaceholder || cyl_getViewControllerInsteadOfNavigation().cyl_isPlaceholder {
            // [EN] The plus child view controller: its tab button is the plus button.
            // [CN] PlusButton 子控制器：其 Tab 按钮为 PlusButton。
            if let plusButton = CYLPlusButton(forOwner: self) {
                return plusButton
            }
        }
        if let control = CYLFlatDesignLookup.object(CYLFlatDesignLookup.tabBarItem(of: self), "tabBarButton") as? UIControl {
            return control
        }
        return tabBarItem.cyl_tabButton ?? cyl_getViewControllerInsteadOfNavigation().tabBarItem.cyl_tabButton
    }
}

// MARK: - UIViewController (CYLTabBarControllerExtentionDeprecated)

extension UIViewController {

    /**
     * [EN] Deprecated in 1.19.0: shows the red dot (ignored for the plus child view controller). Use `-cyl_showBadge`.
     * [CN] 1.19.0 起废弃：显示红点（PlusButton 子控制器忽略）。请使用 `-cyl_showBadge`。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol>, such as `-[UIViewController cyl_showBadgeValue:animationType:]` instead.")
    @objc(cyl_showTabBadgePoint)
    public func cyl_showTabBadgePoint() {
        if !cyl_isPlusChildViewController {
            cyl_showBadge()
        }
    }

    /**
     * [EN] Deprecated in 1.19.0: removes the red dot. Use `-cyl_clearBadge`.
     * [CN] 1.19.0 起废弃：移除红点。请使用 `-cyl_clearBadge`。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol>, such as `-[UIViewController cyl_clearBadge]` instead.")
    @objc(cyl_removeTabBadgePoint)
    public func cyl_removeTabBadgePoint() {
        if !cyl_isPlusChildViewController {
            cyl_clearBadge()
        }
    }

    /**
     * [EN] Deprecated in 1.19.0: YES if the red dot is shown. Use `-cyl_isShowBadge`.
     * [CN] 1.19.0 起废弃：红点显示时为 YES。请使用 `-cyl_isShowBadge`。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol>, such as `-[UIViewController cyl_isShowBadge]` instead.")
    @objc(cyl_isShowTabBadgePoint)
    public func cyl_isShowTabBadgePoint() -> Bool {
        !cyl_isPlusChildViewController && cyl_isShowBadge()
    }

    /**
     * [EN] Deprecated in 1.19.0: the red dot view of the tab button.
     * [CN] 1.19.0 起废弃：Tab 按钮的红点视图。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @objc(cyl_tabBadgePointView)
    public var cyl_tabBadgePointView: UIView? {
        @objc(cyl_tabBadgePointView) get {
            cyl_isPlusChildViewController ? nil : cyl_tabButton?.cyl_tabBadgePointView
        }
        @objc(cyl_setTabBadgePointView:) set {
            if !cyl_isPlusChildViewController, let newValue {
                cyl_tabButton?.cyl_tabBadgePointView = newValue
            }
        }
    }

    /**
     * [EN] Deprecated in 1.19.0: the red dot's offset; positive values move it right and down.
     * [CN] 1.19.0 起废弃：红点的偏移量；正值向右下偏移。
     */
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @objc(cyl_tabBadgePointViewOffset)
    public var cyl_tabBadgePointViewOffset: UIOffset {
        @objc(cyl_tabBadgePointViewOffset) get {
            cyl_isPlusChildViewController ? .zero : cyl_tabButton?.cyl_tabBadgePointViewOffset ?? .zero
        }
        @objc(cyl_setTabBadgePointViewOffset:) set {
            if !cyl_isPlusChildViewController {
                cyl_tabButton?.cyl_tabBadgePointViewOffset = newValue
            }
        }
    }
}

// MARK: - UIViewController (CYLTabBarControllerExtention) <CYLBadgeProtocol>
// [EN] The conformance is declared in UIViewController+CYLTabBarControllerExtention.h (a public Swift conformance to a module
//      protocol would make the generated header import the umbrella header, a cycle); the members are internal `@objc`.
// [CN] 协议遵循声明在 UIViewController+CYLTabBarControllerExtention.h 中（Swift 公开遵循模块内协议会让生成的头文件导入总头文件，形成循环）；
//      成员为 internal `@objc`。

extension UIViewController {

    /**
     * [EN] The view or item that hosts the badge of the page's tab (`kActualView` in Objective-C).
     * [CN] 承载页面所在 Tab 角标的视图或 item（Objective-C 中的 `kActualView`）。
     */
    private var cyl_badgeHost: NSObject? {
        cyl_getViewControllerInsteadOfNavigation().cyl_getActualBadgeSuperView() as? NSObject
    }

    private func cyl_forwardToBadgeHost(_ selectorName: String, _ object: Any? = nil) {
        cyl_badgeHost?.perform(NSSelectorFromString(selectorName), with: object)
    }

    private func cyl_badgeHostNumber(_ selectorName: String) -> NSNumber? {
        CYLFlatDesignLookup.object(cyl_badgeHost, selectorName) as? NSNumber
    }

    private func cyl_badgeHostValue(_ selectorName: String) -> NSValue? {
        CYLFlatDesignLookup.object(cyl_badgeHost, selectorName) as? NSValue
    }

    /**
     * [EN] VoiceOver reads a tab from its `UITabBarItem` (Liquid Glass builds its accessibility elements from it), not from the
     *      button the badge is added to, so the badge also goes into the item's `accessibilityValue`; nil clears it.
     * [CN] VoiceOver 根据 `UITabBarItem` 朗读 Tab（液态玻璃据此生成无障碍元素），而不是角标所在的按钮，因此角标也写入该 item 的
     *      `accessibilityValue`；传 nil 清除。
     */
    private func cyl_setBadgeAccessibilityValue(_ value: String?) {
        let tabViewController: UIViewController = navigationController?.viewControllers.first === self ? navigationController ?? self : self
        tabViewController.tabBarItem.accessibilityValue = cylBadgeAccessibilityDescriptionEntryPoint(value as NSString?) as String?
    }

    /**
     * [EN] The view or item that hosts the badge: the FlatDesign button's badge view, the tab button (Liquid Glass), else the
     *      badge super view of the tab button or of the navigation controller's item.
     * [CN] 承载角标的视图或 item：扁平样式按钮的角标视图、Tab 按钮（液态玻璃），否则为 Tab 按钮或导航控制器 item 的角标父视图。
     */
    @objc(cyl_getActualBadgeSuperView)
    func cyl_getActualBadgeSuperView() -> Any? {
        if cyl_isPlaceholder {
            return nil
        }
        let viewController = cyl_getViewControllerInsteadOfNavigation()
        if let flatDesignHost = cyl_flatDesignBadgeHost(of: viewController) {
            return flatDesignHost
        }
        let control = viewController.tabBarItem.cyl_tabButton
        let navigationItem = viewController.navigationController?.tabBarItem
        if CYLConstants.isLiquidGlassActive() {
            return control ?? navigationItem
        }
        if let control {
            // [EN] Laid out first, so the badge finds its position. [CN] 先布局，角标才能找到位置。
            control.layoutIfNeeded()
            return (control as UIView).cyl_getActualBadgeSuperView()
        }
        return navigationItem?.cyl_getActualBadgeSuperView()
    }

    /**
     * [EN] FlatDesign draws its own buttons: they host the badge even when the item still has a system tab button, off screen
     *      (e.g. a React Native or Flutter host's page that is not in a navigation controller).
     * [CN] 扁平样式绘制自己的按钮：即使 item 仍有系统 Tab 按钮（不在屏幕上，例如不在导航控制器中的 React Native 或 Flutter 宿主页面），
     *      角标也由扁平按钮承载。
     */
    private func cyl_flatDesignBadgeHost(of viewController: UIViewController) -> Any? {
        let tabBarController = CYLFlatDesignLookup.object(viewController, "cylflatdesign_tabBarController") as? CYLTabBarController
        guard CYLFlatDesignLookup.isKind(tabBarController?.cyl_tabBar, CYLFlatDesignLookup.tabBarClass) else {
            return nil
        }
        let item = CYLFlatDesignLookup.tabBarItem(of: viewController)
        if CYLFlatDesignLookup.isKind(item, CYLFlatDesignLookup.tabBarItemClass) {
            let button = CYLFlatDesignLookup.object(item, "tabBarButton")
            guard CYLFlatDesignLookup.isKind(button, CYLFlatDesignLookup.tabBarButtonClass) else { return nil }
            return CYLFlatDesignLookup.object(button, "actualBadgeSuperView")
        }
        if let itemControl = item as? UIControl {
            return (itemControl as UIView).cyl_getActualBadgeSuperView()
        }
        return nil
    }

    @objc(cyl_isReady)
    func cyl_isReady() -> Bool {
        true
    }

    @objc(cyl_performSelector:)
    func cyl_perform(_ aSelector: Selector) {
        cyl_perform(aSelector, with: nil, with: nil)
    }

    @objc(cyl_performSelector:withObject:)
    func cyl_perform(_ aSelector: Selector, with object: Any?) {
        cyl_perform(aSelector, with: object, with: nil)
    }

    @objc(cyl_performSelector:withObject:withObject:)
    func cyl_perform(_ aSelector: Selector, with object1: Any?, with object2: Any?) {
        _ = perform(aSelector, with: object1, with: object2)
    }

    /**
     * [EN] Shows a red dot on the page's tab, with no animation (ignored for the plus child view controller's tab).
     * [CN] 在页面所在 Tab 上显示红点，无动画（PlusButton 子控制器的 Tab 忽略）。
     */
    @objc(cyl_showBadge)
    func cyl_showBadge() {
        cyl_forwardToBadgeHost("cyl_showBadge")
        cyl_setBadgeAccessibilityValue("")
    }

    @objc(cyl_showBadgeValue:animationTypeValue:)
    func cyl_showBadgeValue(_ value: String, animationTypeValue: NSNumber) {
        cyl_badgeHost?.perform(NSSelectorFromString("cyl_showBadgeValue:animationTypeValue:"), with: value, with: animationTypeValue)
        cyl_setBadgeAccessibilityValue(value)
    }

    @objc(cyl_showBadgeValue:animationType:)
    func cyl_showBadgeValue(_ value: String, animationType: CYLBadgeAnimationType) {
        cyl_showBadgeValue(value, animationTypeValue: NSNumber(value: animationType.rawValue))
    }

    @objc(cyl_clearBadge)
    func cyl_clearBadge() {
        cyl_forwardToBadgeHost("cyl_clearBadge")
        cyl_setBadgeAccessibilityValue(nil)
    }

    @objc(cyl_resumeBadge)
    func cyl_resumeBadge() {
        cyl_forwardToBadgeHost("cyl_resumeBadge")
    }

    @objc(cyl_isShowBadge)
    func cyl_isShowBadge() -> Bool {
        (cyl_badgeHost as? CYLBadgeProtocol)?.cyl_isShowBadge() ?? false
    }

    @objc(cyl_isPauseBadge)
    func cyl_isPauseBadge() -> Bool {
        (cyl_badgeHost as? CYLBadgeProtocol)?.cyl_isPauseBadge() ?? false
    }

    /**
     * [EN] The badge view of the page's tab. [CN] 页面所在 Tab 的角标视图。
     */
    @objc(cyl_badge)
    public var cyl_badge: (UIView & CYLBadgeTextDisplaying)? {
        @objc(cyl_badge) get {
            let host = cyl_badgeHost
            return (host as? UIView)?.cyl_badge ?? (host as? UITabBarItem)?.cyl_badge
        }
        @objc(cyl_setBadge:) set { cyl_forwardToBadgeHost("cyl_setBadge:", newValue) }
    }

    @objc(cyl_badgeFont)
    var cyl_badgeFont: UIFont! {
        @objc(cyl_badgeFont) get { CYLFlatDesignLookup.object(cyl_badgeHost, "cyl_badgeFont") as? UIFont }
        @objc(cyl_setBadgeFont:) set { cyl_forwardToBadgeHost("cyl_setBadgeFont:", newValue) }
    }

    @objc(cyl_badgeBackgroundColor)
    var cyl_badgeBackgroundColor: UIColor! {
        @objc(cyl_badgeBackgroundColor) get { CYLFlatDesignLookup.object(cyl_badgeHost, "cyl_badgeBackgroundColor") as? UIColor }
        @objc(cyl_setBadgeBackgroundColor:) set { cyl_forwardToBadgeHost("cyl_setBadgeBackgroundColor:", newValue) }
    }

    @objc(cyl_badgeTextColor)
    var cyl_badgeTextColor: UIColor! {
        @objc(cyl_badgeTextColor) get { CYLFlatDesignLookup.object(cyl_badgeHost, "cyl_badgeTextColor") as? UIColor }
        @objc(cyl_setBadgeTextColor:) set { cyl_forwardToBadgeHost("cyl_setBadgeTextColor:", newValue) }
    }

    @objc(cyl_badgeAnimationType)
    var cyl_badgeAnimationType: CYLBadgeAnimationType {
        @objc(cyl_badgeAnimationType) get {
            CYLBadgeAnimationType(rawValue: cyl_badgeHostNumber("cyl_badgeAnimationTypeValue")?.uintValue ?? 0) ?? .none
        }
        @objc(cyl_setBadgeAnimationType:) set {
            cyl_forwardToBadgeHost("cyl_setBadgeAnimationTypeValue:", NSNumber(value: newValue.rawValue))
        }
    }

    @objc(cyl_badgeAnimationTypeValue)
    var cyl_badgeAnimationTypeValue: NSNumber {
        @objc(cyl_badgeAnimationTypeValue) get { NSNumber(value: cyl_badgeAnimationType.rawValue) }
        @objc(cyl_setBadgeAnimationTypeValue:) set {
            cyl_badgeAnimationType = CYLBadgeAnimationType(rawValue: newValue.uintValue) ?? .none
        }
    }

    @objc(cyl_badgeFrame)
    var cyl_badgeFrame: CGRect {
        @objc(cyl_badgeFrame) get { cyl_badgeHostValue("cyl_badgeFrameValue")?.cgRectValue ?? .zero }
        @objc(cyl_setBadgeFrame:) set { cyl_forwardToBadgeHost("cyl_setBadgeFrameValue:", NSValue(cgRect: newValue)) }
    }

    @objc(cyl_badgeFrameValue)
    var cyl_badgeFrameValue: NSValue {
        @objc(cyl_badgeFrameValue) get { NSValue(cgRect: cyl_badgeFrame) }
        @objc(cyl_setBadgeFrameValue:) set { cyl_badgeFrame = newValue.cgRectValue }
    }

    @objc(cyl_badgeCenterOffset)
    var cyl_badgeCenterOffset: CGPoint {
        @objc(cyl_badgeCenterOffset) get { cyl_badgeHostValue("cyl_badgeCenterOffsetValue")?.cgPointValue ?? .zero }
        @objc(cyl_setBadgeCenterOffset:) set {
            cyl_forwardToBadgeHost("cyl_setBadgeCenterOffsetValue:", NSValue(cgPoint: newValue))
        }
    }

    @objc(cyl_badgeCenterOffsetValue)
    var cyl_badgeCenterOffsetValue: NSValue {
        @objc(cyl_badgeCenterOffsetValue) get { NSValue(cgPoint: cyl_badgeCenterOffset) }
        @objc(cyl_setBadgeCenterOffsetValue:) set { cyl_badgeCenterOffset = newValue.cgPointValue }
    }

    @objc(cyl_badgeMaximumBadgeNumber)
    var cyl_badgeMaximumBadgeNumber: Int {
        @objc(cyl_badgeMaximumBadgeNumber) get { cyl_badgeHostNumber("cyl_badgeMaximumBadgeNumberValue")?.intValue ?? 0 }
        @objc(cyl_setBadgeMaximumBadgeNumber:) set {
            cyl_forwardToBadgeHost("cyl_setBadgeMaximumBadgeNumberValue:", NSNumber(value: newValue))
        }
    }

    @objc(cyl_badgeMaximumBadgeNumberValue)
    var cyl_badgeMaximumBadgeNumberValue: NSNumber {
        @objc(cyl_badgeMaximumBadgeNumberValue) get { NSNumber(value: cyl_badgeMaximumBadgeNumber) }
        @objc(cyl_setBadgeMaximumBadgeNumberValue:) set { cyl_badgeMaximumBadgeNumber = newValue.intValue }
    }

    @objc(cyl_badgeMargin)
    var cyl_badgeMargin: CGFloat {
        @objc(cyl_badgeMargin) get { CGFloat(cyl_badgeHostNumber("cyl_badgeMarginValue")?.doubleValue ?? 0) }
        @objc(cyl_setBadgeMargin:) set { cyl_forwardToBadgeHost("cyl_setBadgeMarginValue:", NSNumber(value: Double(newValue))) }
    }

    @objc(cyl_badgeMarginValue)
    var cyl_badgeMarginValue: NSNumber {
        @objc(cyl_badgeMarginValue) get { NSNumber(value: Double(cyl_badgeMargin)) }
        @objc(cyl_setBadgeMarginValue:) set { cyl_badgeMargin = CGFloat(newValue.doubleValue) }
    }

    @objc(cyl_badgeRadius)
    var cyl_badgeRadius: CGFloat {
        @objc(cyl_badgeRadius) get { CGFloat(cyl_badgeHostNumber("cyl_badgeRadiusValue")?.doubleValue ?? 0) }
        @objc(cyl_setBadgeRadius:) set { cyl_forwardToBadgeHost("cyl_setBadgeRadiusValue:", NSNumber(value: Double(newValue))) }
    }

    @objc(cyl_badgeRadiusValue)
    var cyl_badgeRadiusValue: NSNumber {
        @objc(cyl_badgeRadiusValue) get { NSNumber(value: Double(cyl_badgeRadius)) }
        @objc(cyl_setBadgeRadiusValue:) set { cyl_badgeRadius = CGFloat(newValue.doubleValue) }
    }

    @objc(cyl_badgeCornerRadius)
    var cyl_badgeCornerRadius: CGFloat {
        @objc(cyl_badgeCornerRadius) get { CGFloat(cyl_badgeHostNumber("cyl_badgeCornerRadiusValue")?.doubleValue ?? 0) }
        @objc(cyl_setBadgeCornerRadius:) set {
            cyl_forwardToBadgeHost("cyl_setBadgeCornerRadiusValue:", NSNumber(value: Double(newValue)))
        }
    }

    @objc(cyl_badgeCornerRadiusValue)
    var cyl_badgeCornerRadiusValue: NSNumber {
        @objc(cyl_badgeCornerRadiusValue) get { NSNumber(value: Double(cyl_badgeCornerRadius)) }
        @objc(cyl_setBadgeCornerRadiusValue:) set { cyl_badgeCornerRadius = CGFloat(newValue.doubleValue) }
    }

    /**
     * [EN] Forwarded to the badge host like the properties above (it was `@dynamic` with no implementation, and raised).
     * [CN] 与上面的属性一样转发给角标宿主（原先是 `@dynamic` 且没有实现，会抛异常）。
     */
    @objc(cyl_delayIfNeededForSeconds)
    var cyl_delayIfNeededForSeconds: CGFloat {
        @objc(cyl_delayIfNeededForSeconds) get { CGFloat(cyl_badgeHostNumber("cyl_delayIfNeededForSecondsValue")?.doubleValue ?? 0) }
        @objc(cyl_setDelayIfNeededForSeconds:) set {
            cyl_forwardToBadgeHost("cyl_setDelayIfNeededForSecondsValue:", NSNumber(value: Double(newValue)))
        }
    }

    @objc(cyl_delayIfNeededForSecondsValue)
    var cyl_delayIfNeededForSecondsValue: NSNumber {
        @objc(cyl_delayIfNeededForSecondsValue) get { NSNumber(value: Double(cyl_delayIfNeededForSeconds)) }
        @objc(cyl_setDelayIfNeededForSecondsValue:) set { cyl_delayIfNeededForSeconds = CGFloat(newValue.doubleValue) }
    }
}
