//
//  UIViewController+CYLNavigationControllerExtention.swift
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] `UIViewController (CYLNavigationControllerExtention)`: per page navigation settings (hidden navigation bar, hidden
 *      separator, disabled pop gesture, hidden outer navigation bars), applied by CYLBaseViewController /
 *      CYLBaseTableViewController or, without a base class, by `cyl_automaticNavigationSettingEnabled`. Translated from
 *      Objective-C (docs/Swift-Migration.md, step 28); every declared selector is kept. Removed, as dead code nothing declared
 *      or called: the tab bar show/hide helpers (`-cyl_setTabBarVisible:animated:completion:`, `-cyl_changeTabbarStatusIfNeeded`
 *      and the methods around them) and the empty `-cyl_resetTabBarHidden`.
 * [CN] `UIViewController (CYLNavigationControllerExtention)`：按页面设置导航（隐藏导航栏、隐藏分割线、禁用返回手势、隐藏外层导航栏），由
 *      CYLBaseViewController / CYLBaseTableViewController 执行，或无需基类、由 `cyl_automaticNavigationSettingEnabled` 执行。已从
 *      Objective-C 翻译（docs/Swift-Migration.md，第 28 步），保留所有已声明的 selector。删除了没有声明、也没有调用方的死代码：TabBar
 *      显示/隐藏辅助方法（`-cyl_setTabBarVisible:animated:completion:`、`-cyl_changeTabbarStatusIfNeeded` 及其相关方法）与空方法
 *      `-cyl_resetTabBarHidden`。
 */
enum CYLNavigationSettingKeys {
    static let hidesAncestorNavigationBars = CYLUtilsKeys.key("cyl_hidesAncestorNavigationBars")
    static let disablePopGestureRecognizer = CYLUtilsKeys.key("cyl_disablePopGestureRecognizer")
    static let hideNavigationBarSeparator = CYLUtilsKeys.key("cyl_hideNavigationBarSeparator")
    static let navigationBarHidden = CYLUtilsKeys.key("cyl_navigationBarHidden")
    static let hidesBottomBarWhenPushed = CYLUtilsKeys.key("cyl_hidesBottomBarWhenPushed")
    /**
     * [EN] Set on an outer navigation controller whose bar was hidden by `cyl_hidesAncestorNavigationBars`.
     * [CN] 设置在因 `cyl_hidesAncestorNavigationBars` 而隐藏导航栏的外层导航控制器上。
     */
    static let ancestorBarHiddenHere = CYLUtilsKeys.key("cyl_hideAncestorNavigationBarsIfNeeded:")

    /**
     * FIX: issue #535
     * [EN] See `cyl_automaticNavigationSettingEnabled`. [CN] 见 `cyl_automaticNavigationSettingEnabled`。
     */
    static var automaticNavigationSettingEnabled = false

    /**
     * [EN] Exchanges the four appearance methods of UIViewController with the `cyl_automaticNavigation…` ones, once.
     * [CN] 一次性把 UIViewController 的四个出现/消失方法与 `cyl_automaticNavigation…` 方法交换。
     */
    static let installAutomaticNavigationSetting: Void = {
        let pairs: [(Selector, Selector)] = [
            (#selector(UIViewController.viewWillAppear(_:)), #selector(UIViewController.cyl_automaticNavigationViewWillAppear(_:))),
            (#selector(UIViewController.viewDidAppear(_:)), #selector(UIViewController.cyl_automaticNavigationViewDidAppear(_:))),
            (#selector(UIViewController.viewWillDisappear(_:)), #selector(UIViewController.cyl_automaticNavigationViewWillDisappear(_:))),
            (#selector(UIViewController.viewDidDisappear(_:)), #selector(UIViewController.cyl_automaticNavigationViewDidDisappear(_:))),
        ]
        for (original, swizzled) in pairs {
            if let originalMethod = class_getInstanceMethod(UIViewController.self, original),
               let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzled) {
                method_exchangeImplementations(originalMethod, swizzledMethod)
            }
        }
    }()

    /**
     * [EN] The page shown inside `viewController`: the top of a navigation stack, the selected tab, recursively.
     * [CN] `viewController` 中正在显示的页面：逐层取导航栈顶与选中的 Tab。
     */
    static func visibleLeafViewController(_ viewController: UIViewController) -> UIViewController {
        var current = viewController
        while true {
            let next = (current as? UINavigationController)?.topViewController ?? (current as? UITabBarController)?.selectedViewController
            guard let next, next !== current else { return current }
            current = next
        }
    }
}

extension UIViewController {

    // MARK: Settings

    private func cyl_bool(_ key: UnsafeRawPointer) -> Bool {
        (objc_getAssociatedObject(self, key) as? NSNumber)?.boolValue ?? false
    }

    private func cyl_setBool(_ value: Bool, _ key: UnsafeRawPointer) {
        objc_setAssociatedObject(self, key, NSNumber(value: value), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /**
     * [EN] Disables the pop gesture on this page. Applied by `-cyl_viewDidAppearNavigationSetting:`.
     * [CN] 在本页面禁用返回手势。由 `-cyl_viewDidAppearNavigationSetting:` 执行。
     */
    @objc(cyl_disablePopGestureRecognizer)
    public var cyl_disablePopGestureRecognizer: Bool {
        @objc(cyl_disablePopGestureRecognizer) get { cyl_bool(CYLNavigationSettingKeys.disablePopGestureRecognizer) }
        @objc(cyl_setDisablePopGestureRecognizer:) set { cyl_setBool(newValue, CYLNavigationSettingKeys.disablePopGestureRecognizer) }
    }

    /**
     * [EN] Hides the navigation bar's bottom separator on this page. Applied by `-cyl_viewWillAppearNavigationSetting:`.
     * [CN] 在本页面隐藏导航栏底部分割线。由 `-cyl_viewWillAppearNavigationSetting:` 执行。
     */
    @objc(cyl_hideNavigationBarSeparator)
    public var cyl_hideNavigationBarSeparator: Bool {
        @objc(cyl_hideNavigationBarSeparator) get { cyl_bool(CYLNavigationSettingKeys.hideNavigationBarSeparator) }
        @objc(cyl_setHideNavigationBarSeparator:) set { cyl_setBool(newValue, CYLNavigationSettingKeys.hideNavigationBarSeparator) }
    }

    /**
     * [EN] Hides the navigation bar on this page, and shows it again when the next page does not hide it.
     * [CN] 在本页面隐藏导航栏，下一个页面不隐藏时恢复显示。
     */
    @objc(cyl_navigationBarHidden)
    public var cyl_navigationBarHidden: Bool {
        @objc(cyl_navigationBarHidden) get { cyl_bool(CYLNavigationSettingKeys.navigationBarHidden) }
        @objc(cyl_setNavigationBarHidden:) set { cyl_setBool(newValue, CYLNavigationSettingKeys.navigationBarHidden) }
    }

    /**
     * [EN] `hidesBottomBarWhenPushed`, also remembered here. [CN] `hidesBottomBarWhenPushed`，同时记录在这里。
     */
    @objc(cyl_hidesBottomBarWhenPushed)
    public var cyl_hidesBottomBarWhenPushed: Bool {
        @objc(cyl_hidesBottomBarWhenPushed) get { cyl_bool(CYLNavigationSettingKeys.hidesBottomBarWhenPushed) }
        @objc(cyl_setHidesBottomBarWhenPushed:) set {
            hidesBottomBarWhenPushed = newValue
            cyl_setBool(newValue, CYLNavigationSettingKeys.hidesBottomBarWhenPushed)
        }
    }

    /**
     * FIX: issue #535
     * [EN] Also hides the navigation bars of the navigation controllers around this one (e.g. a pushed tab bar controller),
     *      and shows them again when no visible page asks for it (only the bars hidden this way). Default NO.
     * [CN] 同时隐藏外层导航控制器的导航栏（例如被 push 的 TabBarController），没有可见页面再要求时恢复显示（只恢复以这种方式隐藏的）。默认 NO。
     */
    @objc(cyl_hidesAncestorNavigationBars)
    public var cyl_hidesAncestorNavigationBars: Bool {
        @objc(cyl_hidesAncestorNavigationBars) get { cyl_bool(CYLNavigationSettingKeys.hidesAncestorNavigationBars) }
        @objc(cyl_setHidesAncestorNavigationBars:) set { cyl_setBool(newValue, CYLNavigationSettingKeys.hidesAncestorNavigationBars) }
    }

    /**
     * FIX: issue #535
     * [EN] YES makes the properties above work in any view controller, without CYLBaseViewController: the library applies them
     *      after the four appearance methods for the pages that set one of them and are in a navigation controller. The base
     *      classes are not called twice. Default NO.
     * [CN] 设为 YES 后，上面的属性在任何控制器中都生效，无需继承 CYLBaseViewController：本库在四个出现/消失方法之后，为设置了其中任一属性、
     *      且位于导航控制器中的页面执行它们。基类不会被重复调用。默认 NO。
     */
    @objc(cyl_automaticNavigationSettingEnabled)
    public class var cyl_automaticNavigationSettingEnabled: Bool {
        @objc(cyl_automaticNavigationSettingEnabled) get { CYLNavigationSettingKeys.automaticNavigationSettingEnabled }
        @objc(cyl_setAutomaticNavigationSettingEnabled:) set {
            CYLNavigationSettingKeys.automaticNavigationSettingEnabled = newValue
            // [EN] Installed the first time it is turned on; turning it off only skips the calls.
            // [CN] 第一次开启时安装；关闭后只是不再调用。
            if newValue {
                CYLNavigationSettingKeys.installAutomaticNavigationSetting
            }
        }
    }

    // MARK: The pop gesture

    private func cyl_setPopGestureDelegate(_ delegate: Any?, enabled: Bool?) {
        guard let navigationController else { return }
        var recognizers: [UIGestureRecognizer] = [navigationController.interactivePopGestureRecognizer].compactMap { $0 }
        if #available(iOS 26.0, *) {
            recognizers += [navigationController.interactiveContentPopGestureRecognizer].compactMap { $0 }
        }
        for recognizer in recognizers {
            // [EN] Set through the selector: the page is not required to conform to UIGestureRecognizerDelegate.
            // [CN] 通过 selector 设置：页面不必遵循 UIGestureRecognizerDelegate。
            recognizer.perform(NSSelectorFromString("setDelegate:"), with: delegate)
            if let enabled {
                recognizer.isEnabled = enabled
            }
        }
    }

    /**
     * [EN] Disables the interactive pop gesture during the swipe-back transition. Call in `viewWillDisappear` / `dealloc`.
     * [CN] 在左滑返回的过渡期间禁用 interactivePopGestureRecognizer，请在 viewWillDisappear / dealloc 中调用。
     */
    @objc(cyl_disableInteractivePopGestureRecognizer)
    public func cyl_disableInteractivePopGestureRecognizer() {
        cyl_setPopGestureDelegate(nil, enabled: nil)
    }

    /**
     * [EN] Re-enables the interactive pop gesture after the swipe-back ends. Call in `viewDidDisappear`.
     * [CN] 左滑返回结束后重新启用 interactivePopGestureRecognizer，请在 viewDidDisappear 中调用。
     */
    @objc(cyl_enableInteractivePopGestureRecognizer)
    public func cyl_enableInteractivePopGestureRecognizer() {
        cyl_setPopGestureDelegate(self, enabled: true)
    }

    /**
     * [EN] Enables or disables the pop gesture: disabled when `cyl_disablePopGestureRecognizer` is YES or this is the root
     *      page. Call in `viewDidAppear`.
     * [CN] 重新设置返回手势：cyl_disablePopGestureRecognizer 为 YES 或当前为栈底页面时禁用，否则启用。请在 viewDidAppear 中调用。
     */
    @objc(cyl_resetInteractivePopGestureRecognizer)
    public func cyl_resetInteractivePopGestureRecognizer() {
        guard let navigationController else { return }
        let enabled = !cyl_disablePopGestureRecognizer && navigationController.viewControllers.count != 1
        navigationController.interactivePopGestureRecognizer?.isEnabled = enabled
        if #available(iOS 26.0, *) {
            navigationController.interactiveContentPopGestureRecognizer?.isEnabled = enabled
        }
    }

    // MARK: The navigation bar

    /**
     * [EN] Hides the navigation bar's bottom separator when `cyl_hideNavigationBarSeparator` is YES. Call in `viewWillAppear`.
     * [CN] 当 cyl_hideNavigationBarSeparator 为 YES 时隐藏导航栏底部分割线，请在 viewWillAppear 中调用。
     */
    @objc(cyl_hideNavigationBarSeparatorIfNeeded)
    public func cyl_hideNavigationBarSeparatorIfNeeded() {
        guard cyl_hideNavigationBarSeparator, let navigationBar = navigationController?.navigationBar else { return }
        navigationBar.shadowImage = UIImage()
        navigationBar.isTranslucent = false
    }

    /**
     * [EN] YES if the navigation bar should be shown again when this page disappears: on push the next page is already in
     *      the stack, on pop this page is already removed; NO when the page shown next hides it as well.
     * [CN] 本页面消失时是否应恢复显示导航栏：push 时下一个页面已在栈中，pop 时本页面已被移除；接下来显示的页面同样隐藏导航栏时为 NO。
     */
    @objc(cyl_shouldNavigationBarVisible)
    public func cyl_shouldNavigationBarVisible() -> Bool {
        guard let viewControllers = navigationController?.viewControllers, !viewControllers.isEmpty else { return true }
        let nextViewController: UIViewController
        if let index = viewControllers.firstIndex(of: self) {
            // [EN] The last one: the first push or a presentation, nothing to do. [CN] 最后一个：首次 push 或 present，无需处理。
            guard index < viewControllers.count - 1 else { return true }
            nextViewController = viewControllers[index + 1]
        } else {
            nextViewController = viewControllers[viewControllers.count - 1]
        }
        return cyl_navigationBarHidden != nextViewController.cyl_navigationBarHidden
    }

    /**
     * [EN] Shows the navigation bar again if this page hid it and it should become visible. Call in `viewWillDisappear`.
     * [CN] 若本页面隐藏了导航栏且需要恢复，则重新显示导航栏，请在 viewWillDisappear 中调用。
     */
    @objc(cyl_setNavigationBarVisibleIfNeeded:)
    public func cyl_setNavigationBarVisibleIfNeeded(_ animated: Bool) {
        if cyl_navigationBarHidden && cyl_shouldNavigationBarVisible() {
            navigationController?.setNavigationBarHidden(false, animated: animated)
        }
    }

    /**
     * [EN] Hides the navigation bar when `cyl_navigationBarHidden` is YES. Call in `viewWillAppear`.
     * [CN] 当 cyl_navigationBarHidden 为 YES 时隐藏导航栏，请在 viewWillAppear 中调用。
     */
    @objc(cyl_setNavigationBarHiddenIfNeeded:)
    public func cyl_setNavigationBarHiddenIfNeeded(_ animated: Bool) {
        if cyl_navigationBarHidden {
            navigationController?.setNavigationBarHidden(true, animated: animated)
        }
    }

    // MARK: All-in-one settings

    /**
     * [EN] All-in-one setup for `viewWillAppear`: hides the separator, the navigation bar and the outer bars if needed.
     * [CN] viewWillAppear 中的一站式设置：按需隐藏分割线、导航栏与外层导航栏。
     */
    @objc(cyl_viewWillAppearNavigationSetting:)
    public func cyl_viewWillAppearNavigationSetting(_ animated: Bool) {
        cyl_hideNavigationBarSeparatorIfNeeded()
        cyl_setNavigationBarHiddenIfNeeded(animated)
        cyl_hideAncestorNavigationBarsIfNeeded(animated)
    }

    /**
     * [EN] All-in-one setup for `viewWillDisappear`: disables the pop gesture and restores the navigation bar if needed.
     * [CN] viewWillDisappear 中的一站式设置：禁用返回手势，并按需恢复导航栏。
     */
    @objc(cyl_viewWillDisappearNavigationSetting:)
    public func cyl_viewWillDisappearNavigationSetting(_ animated: Bool) {
        cyl_disableInteractivePopGestureRecognizer()
        cyl_setNavigationBarVisibleIfNeeded(animated)
    }

    /**
     * [EN] All-in-one setup for `viewDidDisappear`: re-enables the pop gesture and shows the outer bars again if needed.
     * [CN] viewDidDisappear 中的一站式设置：重新启用返回手势，并按需恢复外层导航栏。
     */
    @objc(cyl_viewDidDisappearNavigationSetting:)
    public func cyl_viewDidDisappearNavigationSetting(_ animated: Bool) {
        cyl_enableInteractivePopGestureRecognizer()
        cyl_showAncestorNavigationBarsIfNeeded(animated)
    }

    /**
     * [EN] All-in-one setup for `viewDidAppear`: resets the pop gesture state.
     * [CN] viewDidAppear 中的一站式设置：重置返回手势状态。
     */
    @objc(cyl_viewDidAppearNavigationSetting:)
    public func cyl_viewDidAppearNavigationSetting(_ animated: Bool) {
        cyl_resetInteractivePopGestureRecognizer()
    }

    /**
     * [EN] All-in-one setup for `dealloc`: disables the pop gesture.
     * [CN] dealloc 中的一站式设置：禁用返回手势。
     */
    @objc(cyl_deallocNavigationSetting)
    public func cyl_deallocNavigationSetting() {
        cyl_disableInteractivePopGestureRecognizer()
    }

    // MARK: Outer navigation bars (FIX: issue #535)

    /**
     * [EN] The navigation controllers that contain this one's, innermost first.
     * [CN] 包含本页面所在导航控制器的外层导航控制器，由内向外。
     */
    private var cyl_ancestorNavigationControllers: [UINavigationController] {
        var result: [UINavigationController] = []
        var current = navigationController?.navigationController
        while let navigationController = current, !result.contains(navigationController) {
            result.append(navigationController)
            current = navigationController.navigationController
        }
        return result
    }

    private func cyl_hideAncestorNavigationBarsIfNeeded(_ animated: Bool) {
        guard cyl_hidesAncestorNavigationBars else { return }
        for navigationController in cyl_ancestorNavigationControllers where !navigationController.isNavigationBarHidden {
            // [EN] Remember that this bar was hidden here, so only it is shown again. [CN] 记录该导航栏是在这里隐藏的，之后只恢复它。
            objc_setAssociatedObject(navigationController, CYLNavigationSettingKeys.ancestorBarHiddenHere, NSNumber(value: true),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            navigationController.setNavigationBarHidden(true, animated: animated)
        }
    }

    private func cyl_showAncestorNavigationBarsIfNeeded(_ animated: Bool) {
        guard cyl_hidesAncestorNavigationBars else { return }
        for navigationController in cyl_ancestorNavigationControllers {
            let hiddenHere = (objc_getAssociatedObject(navigationController, CYLNavigationSettingKeys.ancestorBarHiddenHere) as? NSNumber)?.boolValue ?? false
            // [EN] Kept hidden while the page now shown inside asks for it (e.g. another such tab).
            // [CN] 当前显示的内层页面仍要求隐藏时保持隐藏（例如另一个同样设置的 Tab）。
            guard hiddenHere, !CYLNavigationSettingKeys.visibleLeafViewController(navigationController).cyl_hidesAncestorNavigationBars else {
                continue
            }
            objc_setAssociatedObject(navigationController, CYLNavigationSettingKeys.ancestorBarHiddenHere, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            navigationController.setNavigationBarHidden(false, animated: animated)
        }
    }

    // MARK: Automatic navigation settings (FIX: issue #535)

    /**
     * [EN] YES when the automatic calls apply: turned on, not a base class (they call the methods themselves), one of the
     *      properties set, and inside a navigation controller (also a tab of a pushed tab bar controller).
     * [CN] 自动调用生效时为 YES：已开启、不是基类（基类自己调用）、设置了其中任一属性，且位于导航控制器中（包括被 push 的 TabBarController 的 Tab）。
     */
    private var cyl_needsAutomaticNavigationSetting: Bool {
        guard CYLNavigationSettingKeys.automaticNavigationSettingEnabled,
              !(self is CYLBaseViewController), !(self is CYLBaseTableViewController) else {
            return false
        }
        guard cyl_navigationBarHidden || cyl_hideNavigationBarSeparator || cyl_disablePopGestureRecognizer
                || cyl_hidesAncestorNavigationBars else {
            return false
        }
        return navigationController != nil
    }

    // [EN] After the exchange these run as the UIViewController methods; calling the same selector (dynamic) runs the original.
    // [CN] 交换后它们作为 UIViewController 的方法执行；调用同名 selector（dynamic）即调用原实现。

    @objc(cyl_automaticNavigationViewWillAppear:)
    dynamic func cyl_automaticNavigationViewWillAppear(_ animated: Bool) {
        cyl_automaticNavigationViewWillAppear(animated)
        if cyl_needsAutomaticNavigationSetting {
            cyl_viewWillAppearNavigationSetting(animated)
        }
    }

    @objc(cyl_automaticNavigationViewDidAppear:)
    dynamic func cyl_automaticNavigationViewDidAppear(_ animated: Bool) {
        cyl_automaticNavigationViewDidAppear(animated)
        if cyl_needsAutomaticNavigationSetting {
            cyl_viewDidAppearNavigationSetting(animated)
        }
    }

    @objc(cyl_automaticNavigationViewWillDisappear:)
    dynamic func cyl_automaticNavigationViewWillDisappear(_ animated: Bool) {
        cyl_automaticNavigationViewWillDisappear(animated)
        if cyl_needsAutomaticNavigationSetting {
            cyl_viewWillDisappearNavigationSetting(animated)
        }
    }

    @objc(cyl_automaticNavigationViewDidDisappear:)
    dynamic func cyl_automaticNavigationViewDidDisappear(_ animated: Bool) {
        cyl_automaticNavigationViewDidDisappear(animated)
        if cyl_needsAutomaticNavigationSetting {
            cyl_viewDidDisappearNavigationSetting(animated)
        }
    }
}
