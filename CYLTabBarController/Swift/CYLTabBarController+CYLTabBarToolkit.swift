//
//  CYLTabBarController+CYLTabBarToolkit.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The associated object keys of the tab bar customization toolkit. [CN] TabBar 自定义工具集的关联对象 key。
 */
enum CYLTabBarToolkitKeys {
    static let reselectBehavior = CYLUtilsKeys.key("cyl_reselectBehavior")
    static let customActionTabBarItemIdentifiers = CYLUtilsKeys.key("cyl_customActionTabBarItemIdentifiers")
    static let customTabActionSettings = CYLUtilsKeys.key("cyl_customTabActionSettings")
    static let customTabActionViewController = CYLUtilsKeys.key("cyl_customTabActionViewController")
    static let tabBarItemStyles = CYLUtilsKeys.key("cyl_tabBarItemStyles")
    static let fixesOpaqueTabBarSafeAreaInsets = CYLUtilsKeys.key("cyl_fixesOpaqueTabBarSafeAreaInsets")
    /// [EN] The bottom this library added to a page's `additionalSafeAreaInsets`. [CN] 本库为页面 `additionalSafeAreaInsets` 增加的底部值。
    static let opaqueTabBarAddedBottom = CYLUtilsKeys.key("cyl_opaqueTabBarAddedBottom")
    /// [EN] The page's safe area bottom when the library last wrote its inset. [CN] 本库上次写入时页面安全区域的底部值。
    static let opaqueTabBarSafeBottomAtWrite = CYLUtilsKeys.key("cyl_opaqueTabBarSafeBottomAtWrite")
}

/**
 * [EN] A weak reference stored as an associated object. [CN] 作为关联对象保存的弱引用。
 */
private final class CYLTabBarToolkitWeakBox: NSObject {
    weak var object: AnyObject?

    init(_ object: AnyObject) {
        self.object = object
    }
}

/**
 * [EN] The blocks of `CYLTabBarController (CYLCustomTabAction)`, typed: a block read back from an associated object does
 *      not cast to a Swift block type.
 * [CN] `CYLTabBarController (CYLCustomTabAction)` 的 block，带类型保存：从关联对象读回的 block 无法转换为 Swift 的 block 类型。
 */
private final class CYLCustomTabActionSettings: NSObject {
    var decider: (@convention(block) (CYLTabBarController, UIViewController) -> Bool)?
    var handler: (@convention(block) (CYLTabBarController, UIViewController) -> Void)?
}

/**
 * [EN] The keys of the styles set through `CYLTabBarController (CYLTabBarItemStyle)`. [CN] 通过 `CYLTabBarController (CYLTabBarItemStyle)` 设置的样式的 key。
 */
private enum CYLTabBarItemStyleKey {
    static let titleFont = "titleFont"
    static let selectedTitleFont = "selectedTitleFont"
    static let titleColor = "titleColor"
    static let selectedTitleColor = "selectedTitleColor"
    static let imageColor = "imageColor"
    static let selectedImageColor = "selectedImageColor"
    static let backgroundColor = "backgroundColor"
    static let shadowColor = "shadowColor"
}

/**
 * [EN] `attributes` with `value` for `key`, when there is a value. [CN] 有值时，将 `attributes` 中 `key` 设为 `value`。
 */
private func cylAttributes(_ attributes: [NSAttributedString.Key: Any]?, setting key: NSAttributedString.Key,
                           to value: Any?) -> [NSAttributedString.Key: Any] {
    var result = attributes ?? [:]
    if let value {
        result[key] = value
    }
    return result
}

// MARK: - CYLReselect (tapping the selected tab again)

/**
 * [EN] `CYLTabBarController (CYLReselect)` and its private part. Translated from Objective-C (docs/Swift-Migration.md,
 *      step 53). `CYLTabBarController` is still an Objective-C class, so the category stays declared in its headers and
 *      these members are internal `@objc` methods with the declared selectors.
 * [CN] `CYLTabBarController (CYLReselect)` 及其私有部分。已从 Objective-C 翻译（docs/Swift-Migration.md，第 53 步）。`CYLTabBarController`
 *      仍是 Objective-C 类，因此分类仍声明在其头文件中，这些成员是使用已声明 selector 的 internal `@objc` 方法。
 */
extension CYLTabBarController {

    @objc(cyl_reselectBehavior)
    func cylReselectBehavior() -> CYLTabBarReselectBehavior {
        let value = (objc_getAssociatedObject(self, CYLTabBarToolkitKeys.reselectBehavior) as? NSNumber)?.uintValue ?? 0
        return CYLTabBarReselectBehavior(rawValue: value)
    }

    @objc(setCyl_reselectBehavior:)
    func cylSetReselectBehavior(_ reselectBehavior: CYLTabBarReselectBehavior) {
        objc_setAssociatedObject(self, CYLTabBarToolkitKeys.reselectBehavior, NSNumber(value: reselectBehavior.rawValue),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        // [EN] As `cyl_tabBarItemGestureHandler` does: start recognizing the gestures. [CN] 与 `cyl_tabBarItemGestureHandler` 一样：开始识别手势。
        if isViewLoaded {
            cylInstallTabBarItemLongPressIfNeeded()
        }
    }

    /**
     * [EN] The view controller of a tab button (classic or Liquid Glass), nil for the plus button.
     * [CN] Tab 按钮对应的控制器，PlusButton 返回 nil。
     */
    @objc(cyl_viewControllerForTabControl:)
    func cylViewController(forTabControl control: UIControl?) -> UIViewController? {
        guard let control, !control.cyl_isPlusControl() else {
            return nil
        }
        let viewControllers = self.viewControllers ?? []
        if tabBarStyleType == .flatDesign {
            return cylFlatDesignViewController(forTabControl: control, in: viewControllers)
        }
        // [EN] Liquid Glass shows two buttons per tab; the selected layer's button stands for the normal one.
        // [CN] 液态玻璃中每个 Tab 有两个按钮；选中层的按钮对应普通层的按钮。
        var candidates: [UIControl] = [control]
        if control.cyl_isPlatterSelectedControl() {
            let normalControl = control.cyl_platterNormal()
            if normalControl !== control {
                candidates.append(normalControl)
            }
        }
        for viewController in viewControllers where !viewController.cyl_isPlaceholder {
            let contentViewController = viewController.cyl_getViewControllerInsteadOfNavigation()
            for candidate in candidates where viewController.tabBarItem.cyl_tabButton === candidate
                || viewController.cyl_tabButton === candidate || contentViewController.cyl_tabButton === candidate {
                return viewController
            }
        }
        // [EN] The classic tab bar numbers its buttons in `-cyl_bindTabControlActions` (system tab buttons only).
        // [CN] 经典 TabBar 在 `-cyl_bindTabControlActions` 中为按钮编号（只计系统 Tab 按钮）。
        if !CYLConstants.isLiquidGlassActive() {
            let index = control.cyl_tabBarChildViewControllerIndex
            if index >= 0 && index < viewControllers.count {
                let viewController = viewControllers[index]
                return viewController.cyl_isPlaceholder ? nil : viewController
            }
        }
        return nil
    }

    /**
     * [EN] FlatDesign: the item's button, matched by position (items and view controllers are aligned). The FlatDesign
     *      tab bar is an optional subspec, so its items are read at run time.
     * [CN] 扁平样式：按位置匹配 item 的按钮（items 与 viewControllers 一一对应）。扁平样式 TabBar 是可选子库，因此在运行时读取其 items。
     */
    private func cylFlatDesignViewController(forTabControl control: UIControl,
                                             in viewControllers: [UIViewController]) -> UIViewController? {
        guard responds(to: NSSelectorFromString("items")), let items = value(forKey: "items") as? [NSObject] else {
            return nil
        }
        for (index, item) in items.enumerated() where index < viewControllers.count {
            guard item.responds(to: NSSelectorFromString("tabBarButton")),
                  (item.value(forKey: "tabBarButton") as? UIControl) === control else {
                continue
            }
            let viewController = viewControllers[index]
            return viewController.cyl_isPlaceholder ? nil : viewController
        }
        return nil
    }

    /**
     * [EN] Runs `cyl_reselectBehavior` for a reselected tab. [CN] 为重复点击的 Tab 执行 `cyl_reselectBehavior`。
     */
    @objc(cyl_performReselectBehaviorForViewController:)
    func cylPerformReselectBehavior(for viewController: UIViewController) {
        let behavior = cylReselectBehavior()
        if behavior.isEmpty {
            return
        }
        if behavior.contains(.popToRoot), let navigationController = viewController as? UINavigationController,
           navigationController.viewControllers.count > 1 {
            navigationController.popToRootViewController(animated: true)
            // [EN] Popped: the next tap, at the root page, scrolls to the top. [CN] 已返回根页面：下次点击（在根页面）再滚动到顶部。
            return
        }
        // [EN] The same scroll view as the tab bar minimizing (CYLTabBarController+CYLTabBarMinimize.swift).
        // [CN] 与 TabBar 缩小所用的滚动视图相同（CYLTabBarController+CYLTabBarMinimize.swift）。
        if behavior.contains(.scrollToTop), let scrollView = cylTabBarMinimizeScrollView(for: viewController) {
            let topOffset = CGPoint(x: scrollView.contentOffset.x, y: -scrollView.adjustedContentInset.top)
            scrollView.setContentOffset(topOffset, animated: true)
        }
    }
}

// MARK: - CYLCustomTabAction (a tab that runs an action instead of being selected)

/**
 * [EN] `CYLTabBarController (CYLCustomTabAction)`. Translated from Objective-C (docs/Swift-Migration.md, step 53).
 * [CN] `CYLTabBarController (CYLCustomTabAction)`。已从 Objective-C 翻译（docs/Swift-Migration.md，第 53 步）。
 */
extension CYLTabBarController {

    typealias CYLCustomTabActionDecider = @convention(block) (CYLTabBarController, UIViewController) -> Bool
    typealias CYLCustomTabActionHandler = @convention(block) (CYLTabBarController, UIViewController) -> Void

    @objc(cyl_customActionTabBarItemIdentifiers)
    func cylCustomActionTabBarItemIdentifiers() -> [String]? {
        objc_getAssociatedObject(self, CYLTabBarToolkitKeys.customActionTabBarItemIdentifiers) as? [String]
    }

    @objc(setCyl_customActionTabBarItemIdentifiers:)
    func cylSetCustomActionTabBarItemIdentifiers(_ identifiers: [String]?) {
        objc_setAssociatedObject(self, CYLTabBarToolkitKeys.customActionTabBarItemIdentifiers, identifiers, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    private var cylCustomTabActionSettings: CYLCustomTabActionSettings {
        if let settings = objc_getAssociatedObject(self, CYLTabBarToolkitKeys.customTabActionSettings) as? CYLCustomTabActionSettings {
            return settings
        }
        let settings = CYLCustomTabActionSettings()
        objc_setAssociatedObject(self, CYLTabBarToolkitKeys.customTabActionSettings, settings, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return settings
    }

    @objc(cyl_shouldPerformCustomTabActionHandler)
    func cylShouldPerformCustomTabActionHandler() -> CYLCustomTabActionDecider? {
        cylCustomTabActionSettings.decider
    }

    @objc(setCyl_shouldPerformCustomTabActionHandler:)
    func cylSetShouldPerformCustomTabActionHandler(_ handler: CYLCustomTabActionDecider?) {
        cylCustomTabActionSettings.decider = handler
    }

    @objc(cyl_customTabActionHandler)
    func cylCustomTabActionHandler() -> CYLCustomTabActionHandler? {
        cylCustomTabActionSettings.handler
    }

    @objc(setCyl_customTabActionHandler:)
    func cylSetCustomTabActionHandler(_ handler: CYLCustomTabActionHandler?) {
        cylCustomTabActionSettings.handler = handler
    }

    @objc(cyl_isCustomActionTabViewController:)
    func cylIsCustomActionTab(_ viewController: UIViewController?) -> Bool {
        guard let viewController, !viewController.cyl_isPlaceholder else {
            return false
        }
        if let decider = cylShouldPerformCustomTabActionHandler() {
            return decider(self, viewController)
        }
        if let delegate = cylDelegate,
           let decision = delegate.tabBarController?(self, shouldPerformCustomActionFor: viewController) {
            return decision
        }
        guard let identifier = viewController.cyl_tabBarItemIdentifier, !identifier.isEmpty else {
            return false
        }
        return cylCustomActionTabBarItemIdentifiers()?.contains(identifier) ?? false
    }

    @objc(cyl_performCustomTabActionIfNeededForViewController:)
    func cylPerformCustomTabActionIfNeeded(for viewController: UIViewController) -> Bool {
        guard cylIsCustomActionTab(viewController) else {
            return false
        }
        // [EN] One tap reaches here up to twice (`-tabBarController:shouldSelectViewController:`, then the tab button's action):
        //      run the action only once per run loop turn.
        // [CN] 一次点击最多到达这里两次（`-tabBarController:shouldSelectViewController:`，然后是 Tab 按钮的事件）：每个 runloop 只执行一次。
        let current = objc_getAssociatedObject(self, CYLTabBarToolkitKeys.customTabActionViewController) as? CYLTabBarToolkitWeakBox
        if current?.object === viewController {
            return true
        }
        objc_setAssociatedObject(self, CYLTabBarToolkitKeys.customTabActionViewController, CYLTabBarToolkitWeakBox(viewController),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            objc_setAssociatedObject(self, CYLTabBarToolkitKeys.customTabActionViewController, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        if let handler = cylCustomTabActionHandler() {
            handler(self, viewController)
            return true
        }
        (cylDelegate)?.tabBarController?(self, performCustomActionFor: viewController)
        return true
    }
}

// MARK: - Item styles in one place

/**
 * [EN] `CYLTabBarController (CYLTabBarItemStyle)`, except the initializers and `-cyl_didInitialize`, which stay with the
 *      class (Swift extensions cannot override initializers). Translated from Objective-C (docs/Swift-Migration.md, step 53).
 * [CN] `CYLTabBarController (CYLTabBarItemStyle)`，初始化方法与 `-cyl_didInitialize` 除外，它们留在类中（Swift extension 不能重写初始化方法）。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 53 步）。
 */
extension CYLTabBarController {

    private var cylTabBarItemStyles: NSMutableDictionary {
        if let styles = objc_getAssociatedObject(self, CYLTabBarToolkitKeys.tabBarItemStyles) as? NSMutableDictionary {
            return styles
        }
        let styles = NSMutableDictionary()
        objc_setAssociatedObject(self, CYLTabBarToolkitKeys.tabBarItemStyles, styles, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return styles
    }

    private func cylSetTabBarItemStyle(_ value: Any?, forKey key: String) {
        cylTabBarItemStyles[key] = value
        cylApplyTabBarItemStyles()
    }

    private func cylTabBarItemStyle<T>(_ key: String) -> T? {
        cylTabBarItemStyles[key] as? T
    }

    @objc(cyl_tabBarItemTitleFont) func cylTabBarItemTitleFont() -> UIFont? { cylTabBarItemStyle(CYLTabBarItemStyleKey.titleFont) }
    @objc(setCyl_tabBarItemTitleFont:) func cylSetTabBarItemTitleFont(_ font: UIFont?) {
        cylSetTabBarItemStyle(font, forKey: CYLTabBarItemStyleKey.titleFont)
    }
    @objc(cyl_tabBarItemSelectedTitleFont) func cylTabBarItemSelectedTitleFont() -> UIFont? {
        cylTabBarItemStyle(CYLTabBarItemStyleKey.selectedTitleFont)
    }
    @objc(setCyl_tabBarItemSelectedTitleFont:) func cylSetTabBarItemSelectedTitleFont(_ font: UIFont?) {
        cylSetTabBarItemStyle(font, forKey: CYLTabBarItemStyleKey.selectedTitleFont)
    }
    @objc(cyl_tabBarItemTitleColor) func cylTabBarItemTitleColor() -> UIColor? { cylTabBarItemStyle(CYLTabBarItemStyleKey.titleColor) }
    @objc(setCyl_tabBarItemTitleColor:) func cylSetTabBarItemTitleColor(_ color: UIColor?) {
        cylSetTabBarItemStyle(color, forKey: CYLTabBarItemStyleKey.titleColor)
    }
    @objc(cyl_tabBarItemSelectedTitleColor) func cylTabBarItemSelectedTitleColor() -> UIColor? {
        cylTabBarItemStyle(CYLTabBarItemStyleKey.selectedTitleColor)
    }
    @objc(setCyl_tabBarItemSelectedTitleColor:) func cylSetTabBarItemSelectedTitleColor(_ color: UIColor?) {
        cylSetTabBarItemStyle(color, forKey: CYLTabBarItemStyleKey.selectedTitleColor)
    }
    @objc(cyl_tabBarItemImageColor) func cylTabBarItemImageColor() -> UIColor? { cylTabBarItemStyle(CYLTabBarItemStyleKey.imageColor) }
    @objc(setCyl_tabBarItemImageColor:) func cylSetTabBarItemImageColor(_ color: UIColor?) {
        cylSetTabBarItemStyle(color, forKey: CYLTabBarItemStyleKey.imageColor)
    }
    @objc(cyl_tabBarItemSelectedImageColor) func cylTabBarItemSelectedImageColor() -> UIColor? {
        cylTabBarItemStyle(CYLTabBarItemStyleKey.selectedImageColor)
    }
    @objc(setCyl_tabBarItemSelectedImageColor:) func cylSetTabBarItemSelectedImageColor(_ color: UIColor?) {
        cylSetTabBarItemStyle(color, forKey: CYLTabBarItemStyleKey.selectedImageColor)
    }
    @objc(cyl_tabBarBackgroundColor) func cylTabBarBackgroundColor() -> UIColor? { cylTabBarItemStyle(CYLTabBarItemStyleKey.backgroundColor) }
    @objc(setCyl_tabBarBackgroundColor:) func cylSetTabBarBackgroundColor(_ color: UIColor?) {
        cylSetTabBarItemStyle(color, forKey: CYLTabBarItemStyleKey.backgroundColor)
    }
    @objc(cyl_tabBarShadowColor) func cylTabBarShadowColor() -> UIColor? { cylTabBarItemStyle(CYLTabBarItemStyleKey.shadowColor) }
    @objc(setCyl_tabBarShadowColor:) func cylSetTabBarShadowColor(_ color: UIColor?) {
        cylSetTabBarItemStyle(color, forKey: CYLTabBarItemStyleKey.shadowColor)
    }

    /**
     * [EN] Writes the stored styles into the tab bar's appearances. [CN] 把保存的样式写入 TabBar 的 appearance。
     */
    @objc(cyl_applyTabBarItemStyles)
    func cylApplyTabBarItemStyles() {
        let styles = cylTabBarItemStyles
        if styles.count == 0 {
            return
        }
        let titleFont: UIFont? = cylTabBarItemStyle(CYLTabBarItemStyleKey.titleFont)
        let selectedTitleFont: UIFont? = cylTabBarItemStyle(CYLTabBarItemStyleKey.selectedTitleFont) ?? titleFont
        let titleColor: UIColor? = cylTabBarItemStyle(CYLTabBarItemStyleKey.titleColor)
        let selectedTitleColor: UIColor? = cylTabBarItemStyle(CYLTabBarItemStyleKey.selectedTitleColor)
        let imageColor: UIColor? = cylTabBarItemStyle(CYLTabBarItemStyleKey.imageColor)
        let selectedImageColor: UIColor? = cylTabBarItemStyle(CYLTabBarItemStyleKey.selectedImageColor)
        let backgroundColor: UIColor? = cylTabBarItemStyle(CYLTabBarItemStyleKey.backgroundColor)
        let shadowColor: UIColor? = cylTabBarItemStyle(CYLTabBarItemStyleKey.shadowColor)
        let apply: (UITabBarAppearance) -> Void = { appearance in
            if let backgroundColor {
                appearance.backgroundColor = backgroundColor
            }
            if let shadowColor {
                appearance.shadowColor = shadowColor
            }
            appearance.cyl_applyItemAppearance { itemAppearance in
                let normal = cylAttributes(itemAppearance.normal.titleTextAttributes, setting: .font, to: titleFont)
                itemAppearance.normal.titleTextAttributes = cylAttributes(normal, setting: .foregroundColor, to: titleColor)
                let selected = cylAttributes(itemAppearance.selected.titleTextAttributes, setting: .font, to: selectedTitleFont)
                itemAppearance.selected.titleTextAttributes = cylAttributes(selected, setting: .foregroundColor, to: selectedTitleColor)
                if let imageColor {
                    itemAppearance.normal.iconColor = imageColor
                }
                if let selectedImageColor {
                    itemAppearance.selected.iconColor = selectedImageColor
                }
            }
        }
        let tabBar = self.tabBar
        let standardAppearance = tabBar.standardAppearance.copy()
        apply(standardAppearance)
        tabBar.standardAppearance = standardAppearance
        if let scrollEdgeAppearance = tabBar.scrollEdgeAppearance?.copy() {
            apply(scrollEdgeAppearance)
            tabBar.scrollEdgeAppearance = scrollEdgeAppearance
        }
        cylSyncTabBarAppearances()
    }
}

// MARK: - Opaque tab bar safe area

/**
 * [EN] `CYLTabBarController (CYLOpaqueTabBarSafeArea)`. Translated from Objective-C (docs/Swift-Migration.md, step 53).
 * [CN] `CYLTabBarController (CYLOpaqueTabBarSafeArea)`。已从 Objective-C 翻译（docs/Swift-Migration.md，第 53 步）。
 */
extension CYLTabBarController {

    @objc(cyl_fixesOpaqueTabBarSafeAreaInsets)
    func cylFixesOpaqueTabBarSafeAreaInsets() -> Bool {
        (objc_getAssociatedObject(self, CYLTabBarToolkitKeys.fixesOpaqueTabBarSafeAreaInsets) as? NSNumber)?.boolValue ?? true
    }

    @objc(setCyl_fixesOpaqueTabBarSafeAreaInsets:)
    func cylSetFixesOpaqueTabBarSafeAreaInsets(_ fixes: Bool) {
        objc_setAssociatedObject(self, CYLTabBarToolkitKeys.fixesOpaqueTabBarSafeAreaInsets, NSNumber(value: fixes),
                                 .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        cylFixOpaqueTabBarSafeAreaInsetsIfNeeded()
    }

    /**
     * [EN] UIKit bug: a page that extends under an opaque tab bar (`tabBar.translucent = NO` with
     *      `extendedLayoutIncludesOpaqueBars = YES`) gets a bottom safe area that leaves the tab bar out, so the end of its
     *      scroll view stays under the bar. The page now shown in the selected tab gets the missing part in its
     *      `additionalSafeAreaInsets.bottom`, on top of the app's own value, which is kept. Self correcting: when UIKit gets
     *      it right the missing part is 0 and nothing changes, and a part added before is taken back when the page is no
     *      longer affected. Only the page itself, never its child view controllers. Not FlatDesign, which sets the safe
     *      area itself.
     * [CN] UIKit bug：延伸到不透明 TabBar 下方的页面（`tabBar.translucent = NO` 且 `extendedLayoutIncludesOpaqueBars = YES`）得到的底部安全区域
     *      没有包含 TabBar，滚动视图的末尾因此被 TabBar 遮挡。选中 Tab 当前显示的页面会在其 `additionalSafeAreaInsets.bottom` 中补上缺少的部分，
     *      App 自己设置的值保留不变。可自我修正：UIKit 计算正确时缺少的部分为 0，不做任何修改；页面不再受影响时撤回之前补上的部分。只作用于页面本身，
     *      不作用于其子控制器。扁平样式自行设置安全区域，不做处理。
     */
    @objc(cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded)
    func cylFixOpaqueTabBarSafeAreaInsetsIfNeeded() {
        guard tabBarStyleType != .flatDesign, isViewLoaded, view.window != nil else {
            return
        }
        let navigationController = selectedViewController as? UINavigationController
        guard let page = navigationController?.topViewController ?? selectedViewController,
              page.isViewLoaded, page.view.window != nil else {
            return
        }
        let tabBar = self.tabBar
        var pageHidesTabBar = false
        for viewController in navigationController?.viewControllers ?? [] {
            if viewController.hidesBottomBarWhenPushed && viewController !== navigationController?.viewControllers.first {
                pageHidesTabBar = true
            }
            if viewController === page {
                break
            }
        }
        let affected = cylFixesOpaqueTabBarSafeAreaInsets() && !tabBar.isTranslucent && page.extendedLayoutIncludesOpaqueBars
            && page.edgesForExtendedLayout.contains(.bottom) && !pageHidesTabBar
            && !tabBar.isHidden && tabBar.alpha > 0.01 && tabBar.window != nil
        let addedBottom = CGFloat((objc_getAssociatedObject(page, CYLTabBarToolkitKeys.opaqueTabBarAddedBottom) as? NSNumber)?.doubleValue ?? 0)
        var additionalInsets = page.additionalSafeAreaInsets
        // [EN] Written, but the page has not been laid out with it yet: its safe area is stale, which would add the part again.
        // [CN] 已写入，但页面尚未据此重新布局：此时的安全区域是旧值，会把缺少的部分再加一次。
        if let safeBottomAtWrite = objc_getAssociatedObject(page, CYLTabBarToolkitKeys.opaqueTabBarSafeBottomAtWrite) as? NSNumber,
           abs(page.view.safeAreaInsets.bottom - CGFloat(safeBottomAtWrite.doubleValue)) < 0.5, addedBottom > 0 {
            return
        }
        let appBottom = additionalInsets.bottom - addedBottom
        var neededBottom: CGFloat = 0
        if affected {
            let pageRect = page.view.convert(page.view.bounds, to: view)
            let barRect = tabBar.convert(tabBar.bounds, to: view)
            let coveredBottom = max(pageRect.maxY - barRect.minY, 0)
            // [EN] What UIKit gives without any additional inset. [CN] 不含任何 additional inset 时 UIKit 给出的值。
            let systemBottom = page.view.safeAreaInsets.bottom - additionalInsets.bottom
            neededBottom = max(coveredBottom - systemBottom - appBottom, 0)
        }
        if abs(neededBottom - addedBottom) < 0.5 {
            return
        }
        let safeBottomBeforeWrite = page.view.safeAreaInsets.bottom
        additionalInsets.bottom = appBottom + neededBottom
        page.additionalSafeAreaInsets = additionalInsets
        objc_setAssociatedObject(page, CYLTabBarToolkitKeys.opaqueTabBarAddedBottom,
                                 neededBottom > 0 ? NSNumber(value: Double(neededBottom)) : nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(page, CYLTabBarToolkitKeys.opaqueTabBarSafeBottomAtWrite,
                                 neededBottom > 0 ? NSNumber(value: Double(safeBottomBeforeWrite)) : nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
