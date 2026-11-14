//
//  CYLTabBarController+CYLTabBarControllerLookup.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Which tab bar controllers a lookup accepts; nil accepts any CYLTabBarController. [CN] 查找时接受哪些 TabBarController；nil 表示接受任意 CYLTabBarController。
 */
typealias CYLTabBarControllerLookupMatcher = (CYLTabBarController) -> Bool

/**
 * [EN] Every CYLTabBarController that has view controllers, held WEAKLY and ordered by when it last appeared: the last one is the most
 *      recently active. A controller joins at the bottom when it gets its view controllers, moves to the top in `-viewWillAppear:`, and
 *      drops out by itself when it is deallocated. This replaces "the root view controller" as the answer when nothing more specific is
 *      known: with several tab bar controllers (a pushed or presented one, #414), the root one is often not the one in use.
 * [CN] 所有已设置 viewControllers 的 CYLTabBarController，**弱引用** 保存，按最后一次显示的先后排序：最后一个就是最近活跃的。控制器在设置
 *      viewControllers 时加入到最底部，在 `-viewWillAppear:` 时移到最顶部，释放后自动移除。在没有更具体信息时，用它代替“根控制器”作为答案：
 *      存在多个 TabBarController 时（push 或 present 出来的，#414），根控制器往往不是正在使用的那个。
 */
enum CYLTabBarControllerActivationStack {
    private static let stack = NSPointerArray.weakObjects()
    private static let lock = NSLock()

    private static func pointer(of tabBarController: CYLTabBarController) -> UnsafeMutableRawPointer {
        Unmanaged.passUnretained(tabBarController).toOpaque()
    }

    /// [EN] Removes `tabBarController`, and the entries of deallocated controllers (their weak pointers are NULL).
    /// [CN] 移除 `tabBarController` 以及已释放控制器的条目（其弱指针为 NULL）。
    private static func remove(_ tabBarController: CYLTabBarController) {
        let target = pointer(of: tabBarController)
        for index in stride(from: stack.count - 1, through: 0, by: -1) {
            let entry = stack.pointer(at: index)
            if entry == nil || entry == target {
                stack.removePointer(at: index)
            }
        }
    }

    static func register(_ tabBarController: CYLTabBarController) {
        lock.lock()
        defer { lock.unlock() }
        let target = pointer(of: tabBarController)
        for index in 0..<stack.count where stack.pointer(at: index) == target {
            return  // already known: keep its place
        }
        stack.insertPointer(target, at: 0)
    }

    static func markActive(_ tabBarController: CYLTabBarController) {
        lock.lock()
        defer { lock.unlock() }
        remove(tabBarController)
        stack.addPointer(pointer(of: tabBarController))
    }

    static func mostRecent(context: String?, matching matcher: CYLTabBarControllerLookupMatcher?) -> CYLTabBarController? {
        lock.lock()
        defer { lock.unlock() }
        for index in stride(from: stack.count - 1, through: 0, by: -1) {
            guard let entry = stack.pointer(at: index) else { continue }
            let tabBarController = Unmanaged<CYLTabBarController>.fromOpaque(entry).takeUnretainedValue()
            if let context, tabBarController.cyl_context != context { continue }
            if let matcher, !matcher(tabBarController) { continue }
            return tabBarController
        }
        return nil
    }
}

/// [EN] `object` is a CYLTabBarController that `matcher` accepts (any one when `matcher` is nil). [CN] `object` 是 `matcher` 接受的 CYLTabBarController（`matcher` 为 nil 时任意一个）。
private func CYLTabBarControllerMatches(_ object: Any?, _ matcher: CYLTabBarControllerLookupMatcher?) -> CYLTabBarController? {
    guard let tabBarController = object as? CYLTabBarController else { return nil }
    if let matcher, !matcher(tabBarController) { return nil }
    return tabBarController
}

/**
 * [EN] The style family a lookup asks for: flat design (`CYLTabBarStyleTypeFlatDesign`), or the system styles (any other value: Default,
 *      System, LiquidGlass, as `-cyl_isSystemStyleTabBar` counts them).
 * [CN] 查找所要求的样式族：扁平样式（`CYLTabBarStyleTypeFlatDesign`），或系统样式（其他任何值：Default、System、LiquidGlass，与 `-cyl_isSystemStyleTabBar` 的统计一致）。
 */
private func CYLTabBarControllerMatcherForStyleType(_ styleType: CYLTabBarStyleType) -> CYLTabBarControllerLookupMatcher {
    let wantsFlatDesign = styleType == .flatDesign
    return { wantsFlatDesign == ($0.tabBarStyleType == .flatDesign) }
}

/// [EN] The reference set on `object` with `-cyl_setTabBarController:` or `-cylflatdesign_setTabBarController:`, if accepted. [CN] 通过 `-cyl_setTabBarController:` 或 `-cylflatdesign_setTabBarController:` 设置在 `object` 上的引用（被接受时）。
private func CYLTabBarControllerExplicitReference(_ object: NSObject, _ matcher: CYLTabBarControllerLookupMatcher?) -> CYLTabBarController? {
    // [EN] Weak references set by `-cyl_setTabBarController:` / `-cylflatdesign_setTabBarController:` (CYLUtils).
    // [CN] 由 `-cyl_setTabBarController:` / `-cylflatdesign_setTabBarController:` 设置的弱引用（CYLUtils）。
    if let found = CYLTabBarControllerMatches(object.cyl_weakAssociatedObject(forKey: CYLUtilsKeys.key("cyl_tabBarController")), matcher) {
        return found
    }
    // [EN] Only a build with FlatDesign ever sets the second one. [CN] 只有包含扁平样式的构建才会设置第二个引用。
    return CYLTabBarControllerMatches(object.cyl_weakAssociatedObject(forKey: CYLUtilsKeys.key("cylflatdesign_tabBarController")), matcher)
}

/**
 * [EN] The controller of a tab bar (system or flat design): its `delegate`, which the controller sets to itself. Known even before the tab
 *      bar is in the controller's view, where the responder chain could not reach it.
 * [CN] TabBar（系统或扁平样式）所属的控制器：其 `delegate`，由控制器设为自己。即使 TabBar 尚未加入控制器的 view（响应链此时到不了它）也能得到。
 */
private func CYLTabBarControllerOwningTabBar(_ responder: UIResponder) -> CYLTabBarController? {
    var delegate: Any?
    if let tabBar = responder as? UITabBar {
        delegate = tabBar.delegate
    } else if let flatDesignTabBar = NSClassFromString("CYLFlatDesignTabBar"), responder.isKind(of: flatDesignTabBar) {
        delegate = responder.value(forKey: "delegate")
    }
    return delegate as? CYLTabBarController
}

// MARK: - Tab item identifiers (issue #408)

extension CYLTabBarController {

    /// [EN] This tab bar controller's plus button (its own copy with several tab bar controllers), if any. [CN] 本 TabBarController 的 PlusButton（有多个 TabBarController 时是各自的一份），没有则为 nil。
    private var identifiedPlusButton: CYLPlusButton? {
        hasPlusButton() ? cylPrivate.cylContextPlusButton() : nil
    }

    /**
     * [EN] The identifier of one of this controller's tabs: the one set, else the default. [CN] 已设置的标识，否则为默认值。
     */
    @objc(cyl_tabBarItemIdentifierForViewController:)
    func cylTabBarItemIdentifier(for viewController: UIViewController?) -> String? {
        guard let viewController else { return nil }
        if let identifier = objc_getAssociatedObject(viewController, CYLUtilsKeys.key("cyl_tabBarItemIdentifier")) as? String {
            return identifier
        }
        return cyl_defaultTabBarItemIdentifier(for: viewController)
    }

    /**
     * [EN] Swift classes are named "Module.Class"; the module is dropped. [CN] Swift 类名形如「模块.类名」，去掉模块名。
     */
    @objc(cyl_defaultTabBarItemIdentifierForClass:)
    static func cylDefaultTabBarItemIdentifier(forClass aClass: AnyClass?) -> String {
        let name = aClass.map { NSStringFromClass($0) } ?? ""
        guard let dot = name.range(of: ".", options: .backwards) else { return name }
        return String(name[dot.upperBound...])
    }

    @objc(cyl_defaultTabBarItemIdentifierForViewController:)
    func cylDefaultTabBarItemIdentifier(for viewController: UIViewController?) -> String? {
        guard let viewController else { return nil }
        let tabs = viewControllers ?? []
        guard let index = tabs.firstIndex(where: { $0 === viewController || $0.cyl_getViewControllerInsteadOfNavigation() === viewController }) else {
            return nil
        }
        let tab = tabs[index]
        // [EN] The plus child view controller is the plus button's tab. [CN] PlusButton 子控制器即 PlusButton 对应的 Tab。
        if let plusChild = cylPrivate.cylContextPlusChildViewController(), tab.cyl_isEqual(to: plusChild), let plusButton = identifiedPlusButton {
            return plusButton.cyl_tabBarItemIdentifier
        }
        let contentClass: AnyClass = type(of: tab.cyl_getViewControllerInsteadOfNavigation())
        let identifier = CYLTabBarController.cylDefaultTabBarItemIdentifier(forClass: contentClass)
        // [EN] The next tabs of the same class: "_2", "_3"... [CN] 后续同类的 Tab 依次加 "_2"、"_3"……
        let occurrence = 1 + tabs[..<index].filter { type(of: $0.cyl_getViewControllerInsteadOfNavigation()) == contentClass }.count
        return occurrence == 1 ? identifier : "\(identifier)_\(occurrence)"
    }

    @objc(cyl_selectedTabBarItemIdentifier)
    func cylSelectedTabBarItemIdentifier() -> String? {
        cylTabBarItemIdentifier(for: selectedViewController)
    }

    @objc(cyl_indexOfTabBarItemIdentifier:)
    func cylIndex(ofTabBarItemIdentifier identifier: String?) -> UInt {
        guard let identifier, !identifier.isEmpty else { return UInt(NSNotFound) }
        let index = (viewControllers ?? []).firstIndex { cylTabBarItemIdentifier(for: $0) == identifier }
        return index.map { UInt($0) } ?? UInt(NSNotFound)
    }

    @objc(cyl_viewControllerWithTabBarItemIdentifier:)
    func cylViewController(withTabBarItemIdentifier identifier: String?) -> UIViewController? {
        let index = cylIndex(ofTabBarItemIdentifier: identifier)
        return index == UInt(NSNotFound) ? nil : viewControllers?[Int(index)]
    }

    @objc(cyl_selectTabBarItemWithIdentifier:)
    @discardableResult
    func cylSelectTabBarItem(withIdentifier identifier: String?) -> UIViewController? {
        let index = cylIndex(ofTabBarItemIdentifier: identifier)
        if index == UInt(NSNotFound) { return nil }
        selectedIndex = Int(index)
        return viewControllers?[Int(index)]
    }

    @objc(cyl_tabBarItemIdentifiers)
    func cylTabBarItemIdentifiers() -> [String] {
        var identifiers = (viewControllers ?? []).compactMap { cylTabBarItemIdentifier(for: $0) }
        if let plusIdentifier = identifiedPlusButton?.cyl_tabBarItemIdentifier, !identifiers.contains(plusIdentifier) {
            identifiers.append(plusIdentifier)
        }
        return identifiers
    }

    @objc(cyl_controlWithTabBarItemIdentifier:)
    func cylControl(withTabBarItemIdentifier identifier: String?) -> UIControl? {
        guard let identifier, !identifier.isEmpty else { return nil }
        if let plusButton = identifiedPlusButton, plusButton.cyl_tabBarItemIdentifier == identifier {
            return plusButton
        }
        return cylViewController(withTabBarItemIdentifier: identifier)?.cyl_tabButton
    }
}

// MARK: - Selected index without the plus button (issue #515)

extension CYLTabBarController {

    /**
     * [EN] YES for the plus button's child view controller or placeholder. FIX: placeholder count mismatch — the same test as the slot
     *      insertion, so `cyl_viewControllersIgnoringPlusButton` also leaves out a plus child view controller inside a navigation controller.
     * [CN] PlusButton 的子控制器或占位控制器时为 YES。FIX：占位导致的数量不匹配——与插入 slot 时使用同一判断，`cyl_viewControllersIgnoringPlusButton`
     *      也会去掉被导航控制器包裹的 PlusButton 子控制器。
     */
    @objc(cyl_isPlusButtonViewController:)
    func cylIsPlusButtonViewController(_ viewController: UIViewController) -> Bool {
        cylPrivate.cylIsPlusSlotViewController(viewController)
    }

    @objc(cyl_viewControllersIgnoringPlusButton)
    func cylViewControllersIgnoringPlusButton() -> [UIViewController] {
        (viewControllers ?? []).filter { !cylIsPlusButtonViewController($0) }
    }

    @objc(cyl_selectedIndexForIndexIgnoringPlusButton:)
    func cylSelectedIndex(forIndexIgnoringPlusButton index: UInt) -> UInt {
        let candidates = cylViewControllersIgnoringPlusButton()
        guard Int(index) < candidates.count, let found = viewControllers?.firstIndex(of: candidates[Int(index)]) else {
            return UInt(NSNotFound)
        }
        return UInt(found)
    }

    @objc(cyl_selectedIndexIgnoringPlusButton)
    func cylSelectedIndexIgnoringPlusButton() -> UInt {
        guard let selected = selectedViewController, let index = cylViewControllersIgnoringPlusButton().firstIndex(of: selected) else {
            return UInt(NSNotFound)
        }
        return UInt(index)
    }

    @objc(cyl_setSelectedIndexIgnoringPlusButton:)
    func cylSetSelectedIndexIgnoringPlusButton(_ index: UInt) {
        let selected = cylSelectedIndex(forIndexIgnoringPlusButton: index)
        if selected == UInt(NSNotFound) { return }
        selectedIndex = Int(selected)
    }
}

// MARK: - The active tab bar controller

/// [EN] Every control under `view` that hosts an animation view: the tab buttons of any style (Liquid Glass has a normal and a selected one per tab, flat design has its own buttons). [CN] `view` 下所有带动画视图的控件：各样式的 Tab 按钮（液态玻璃每个 Tab 有普通与选中两个，扁平样式有自己的按钮）。
private func CYLCollectAnimatedTabButtons(_ view: UIView, _ tabButtons: inout [UIControl]) {
    for subview in view.subviews {
        if let control = subview as? UIControl, control.cyl_tabBarItemAnimationView() != nil {
            tabButtons.append(control)
            continue
        }
        CYLCollectAnimatedTabButtons(subview, &tabButtons)
    }
}

/// [EN] One line per tab: badge shown or not, then each Lottie view's `animationSpeed`. [CN] 每个 Tab 一行：是否显示角标，然后是每个 Lottie 视图的 `animationSpeed`。
private func CYLTabBarStateDescription(_ tabBarController: CYLTabBarController?) -> String {
    guard let tabBarController else { return "no active CYLTabBarController" }
    var description = "\(NSStringFromClass(type(of: tabBarController))) (\(tabBarController.cyl_context ?? "default context"))"
    for (index, viewController) in (tabBarController.viewControllers ?? []).enumerated() {
        description += "\n  tab \(index): badge \(viewController.cyl_isShowBadge() ? "shown" : "hidden")"
    }
    var tabButtons: [UIControl] = []
    CYLCollectAnimatedTabButtons(tabBarController.cyl_tabBar ?? tabBarController.tabBar, &tabButtons)
    for tabButton in tabButtons {
        let lottieView = tabButton.cyl_tabBarItemAnimationView()
        let speed: Any = lottieView?.responds(to: NSSelectorFromString("animationSpeed")) == true ? (lottieView?.value(forKey: "animationSpeed") ?? "?") : "?"
        let x = tabButton.convert(tabButton.bounds, to: nil).minX
        description += "\n  Lottie view in \(NSStringFromClass(type(of: tabButton))) at x = \(String(format: "%.0f", x)): animationSpeed \(speed)"
    }
    if tabButtons.isEmpty {
        description += "\n  no Lottie views (Lottie not integrated or not configured)"
    }
    return description
}

extension CYLTabBarController {

    @objc(cyl_registerTabBarController:)
    static func cylRegister(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController else { return }
        CYLTabBarControllerActivationStack.register(tabBarController)
    }

    @objc(cyl_markTabBarControllerActive:)
    static func cylMarkActive(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController else { return }
        CYLTabBarControllerActivationStack.markActive(tabBarController)
    }

    @objc(cyl_tabBarControllerForContext:matching:)
    static func cylTabBarController(forContext context: String?, matching matcher: (@convention(block) (CYLTabBarController) -> Bool)?) -> CYLTabBarController? {
        CYLTabBarControllerActivationStack.mostRecent(context: context, matching: matcher)
    }

    @objc(cyl_tabBarControllerForContext:)
    static func cylTabBarController(forContext context: String?) -> CYLTabBarController? {
        CYLTabBarControllerActivationStack.mostRecent(context: context, matching: nil)
    }

    /// [EN] The most recently active one is the context lookup without a context. [CN] 最近活跃的就是不带 context 的查找。
    @objc(cyl_activeTabBarController)
    static func cylActiveTabBarController() -> CYLTabBarController? {
        cylTabBarController(forContext: nil)
    }

    @objc(cyl_simulateMemoryWarning)
    static func cylSimulateMemoryWarning() {
        cylSimulateMemoryWarning(for: cylActiveTabBarController())
    }

    @objc(cyl_simulateMemoryWarningForTabBarController:)
    static func cylSimulateMemoryWarning(for tabBarController: CYLTabBarController?) {
        let application = UIApplication.shared
        NotificationCenter.default.post(name: UIApplication.didReceiveMemoryWarningNotification, object: application)
        application.delegate?.applicationDidReceiveMemoryWarning?(application)
        // [EN] A real memory warning also calls `-didReceiveMemoryWarning` on the view controllers; the notification does not.
        // [CN] 真实的内存警告还会对各个控制器调用 `-didReceiveMemoryWarning`；通知不会。
        tabBarController?.didReceiveMemoryWarning()
        // [EN] Log on the next run loop pass, after whatever the warning released has been released. [CN] 在下一个 runloop 记录日志，此时警告释放的内容已被释放。
        DispatchQueue.main.async { [weak tabBarController] in
            NSLog("⚠️ Simulated memory warning (issues #426, #428). Tab bar state afterwards:\n%@", CYLTabBarStateDescription(tabBarController))
        }
    }
}

// MARK: - cyl_tabBarController of every object

extension NSObject {

    @objc(cyl_setTabBarController:)
    func cylSetTabBarController(_ tabBarController: CYLTabBarController?) {
        cyl_setWeakAssociatedObject(tabBarController, forKey: CYLUtilsKeys.key("cyl_tabBarController"))
    }

    /**
     * [EN] The one lookup behind `-cyl_tabBarController` (system styles), `-cylflatdesign_tabBarController` (flat design),
     *      `-cyl_tabBarControllerForStyleType:` and `-cyl_owningTabBarController` (any style, which the plus button registry uses to find an
     *      object's context). `matcher` picks which controllers count (nil: any). In order:
     *      0. a tab bar controller that counts is its own;
     *      1. a reference set explicitly with `-cyl_setTabBarController:` or `-cylflatdesign_setTabBarController:`;
     *      2. where the object is: a view goes up its responder chain, through the tab bar it is in (its `delegate`), to the view controller
     *         that owns it; a view controller goes up its parents. So a tab button, the plus button or a view in a tab finds its own
     *         controller, not the root one;
     *      3. if `fallsBackToActive`, the most recently active one (`+cyl_activeTabBarController`), then the root view controller, as before.
     * [CN] `-cyl_tabBarController`（系统样式）、`-cylflatdesign_tabBarController`（扁平样式）、`-cyl_tabBarControllerForStyleType:` 和
     *      `-cyl_owningTabBarController`（任意样式，PlusButton 注册表用它确定对象的 context）共用的查找。`matcher` 决定哪些控制器符合（nil 表示任意）。顺序：
     *      0. 符合条件的 TabBarController 就是它自己；
     *      1. 通过 `-cyl_setTabBarController:` 或 `-cylflatdesign_setTabBarController:` 显式设置的引用；
     *      2. 对象所在的位置：View 沿响应链向上，经过它所在的 TabBar（其 `delegate`），到拥有它的 ViewController；ViewController 沿父控制器链向上。
     *         因此 Tab 按钮、PlusButton 或 Tab 页面内的 View 找到的是自己的控制器，而不是根控制器；
     *      3. 若 `fallsBackToActive`，取最近活跃的那个（`+cyl_activeTabBarController`），最后才是根控制器（与以前一致）。
     */
    func cylTabBarController(matching matcher: CYLTabBarControllerLookupMatcher?, fallsBackToActive: Bool) -> CYLTabBarController? {
        // [EN] 0. A tab bar controller it accepts is its own: `-visiableTabBarSize` and the `CYL_IS_IPHONE_X` /
        //      `CYL_NoNeed_UIDesignRequiresCompatibility` macros ask `self.cyl_tabBarController` from inside it. Asking an ancestor or the root
        //      instead gave a pushed tab bar controller the outer one's values.
        // [CN] 匹配的 TabBarController 就是它自己：`-visiableTabBarSize` 和 `CYL_IS_IPHONE_X` 等宏在控制器内部使用 `self.cyl_tabBarController`。
        //      以前取的是上层或根控制器，push 出来的 TabBarController 会拿到外层的值。
        if let own = CYLTabBarControllerMatches(self, matcher) {
            return own
        }
        // 1. An explicit reference.
        if let reference = CYLTabBarControllerExplicitReference(self, matcher) {
            return reference
        }
        // [EN] 2. Where it is. A view: up its responder chain, through the tab bar it is in (whose `delegate` is the controller), to the view
        //      controller that owns it. A view controller, or that one: up its parents.
        var viewController: UIViewController?
        if let controller = self as? UIViewController {
            viewController = controller.parent
        } else if let view = self as? UIView {
            var responder: UIResponder? = view
            while let current = responder, !(current is UIViewController) {
                if let owning = CYLTabBarControllerMatches(CYLTabBarControllerOwningTabBar(current), matcher) {
                    return owning
                }
                responder = current.next
            }
            viewController = responder as? UIViewController
        }
        while let current = viewController {
            if let found = CYLTabBarControllerMatches(current, matcher) {
                return found
            }
            if let reference = CYLTabBarControllerExplicitReference(current, matcher) {
                return reference
            }
            viewController = current.parent
        }
        if !fallsBackToActive {
            return nil
        }
        // [EN] 3. Nothing more specific: the most recently active one, not a singleton-like root; the root only when none is known.
        // [CN] 没有更具体的信息：取最近活跃的那个，而不是类似单例的根控制器；只有查不到时才取根控制器。
        if let active = CYLTabBarControllerActivationStack.mostRecent(context: nil, matching: matcher) {
            return active
        }
        // [EN] The window's root, not `CYLGetRootViewController()`: that is the topmost presented one, e.g. an alert.
        // [CN] 取 window 的根控制器，而不是 `CYLGetRootViewController()`：后者是最上层 present 的控制器，例如 alert。
        let root = CYLGetRootWindow()?.rootViewController?.cyl_getViewControllerInsteadOfNavigation()
        return CYLTabBarControllerMatches(root, matcher)
    }

    @objc(cyl_owningTabBarController)
    func cylOwningTabBarController() -> CYLTabBarController? {
        // [EN] Only where it is: callers decide what to fall back to (the plus button registry must not take another controller's context for a
        //      tab bar that is not attached yet).
        // [CN] 只看对象所在的位置：回退到什么由调用方决定（PlusButton 注册表不能把其他控制器的 context 当作尚未加入的 TabBar 的 context）。
        cylTabBarController(matching: nil, fallsBackToActive: false)
    }

    @objc(cyl_tabBarControllerForStyleType:)
    func cylTabBarController(forStyleType styleType: CYLTabBarStyleType) -> CYLTabBarController? {
        cylTabBarController(matching: CYLTabBarControllerMatcherForStyleType(styleType), fallsBackToActive: true)
    }

    /**
     * [EN] System styles (everything but flat design). Falls back to the most recently active one, then the root, as the root fallback did
     *      before (#414: with several tab bar controllers the root one is often not the one in use).
     * [CN] 系统样式（除扁平样式外）。回退到最近活跃的那个，最后才是根控制器（#414：存在多个 TabBarController 时根控制器往往不是正在使用的那个）。
     */
    @objc(cyl_tabBarController)
    func cylTabBarController() -> CYLTabBarController? {
        cylTabBarController(forStyleType: .default)
    }
}
