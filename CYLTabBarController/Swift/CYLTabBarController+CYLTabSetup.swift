//
//  CYLTabBarController+CYLTabSetup.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/// [EN] Private: the reason of a left-out tab; the same key as in CYLTabBarController.m and the configuration.
/// [CN] 私有：被排除的 Tab 的原因；与 CYLTabBarController.m 及配置中的键相同。
private let CYLTabBarItemExclusionReasonKey = "_CYLTabBarItemExclusionReason"
/// [EN] Private: marks a tab left out by its platforms or minimum version; the same key as in CYLTabBarController.m.
/// [CN] 私有：标记因平台或最低版本被排除的 Tab；与 CYLTabBarController.m 中的键相同。
private let CYLTabBarItemExcludedKey = "_CYLTabBarItemExcluded"

/**
 [EN] Block 1 of the sections handed over by Mac-CYLTabBarController文件夹 (docs/Swift-Migration.md, step 126): setting the tabs up.
      `-setViewControllers:` and `-addChildViewController:` stay one-line overrides in CYLTabBarController.m that call
      `-cyl_setViewControllers:` / `-cyl_overrideAddChildViewController:` here (a Swift extension of an Objective-C class
      cannot override them); the ivars go through small storage setters next to them. The public methods
      (`-replaceViewControllerAtIndex:…`, `-tabBarItemAttributesAtIndex:`, `-reloadTabBarItemsWithAttributes:`,
      `-hasPlusChildViewController`, `-setTintColor:`) are declared in `CYLTabBarController (CYLTabSetup)`. Internal members
      with the Objective-C selectors. The FlatDesign part of `-setViewControllers:` is in
      CYLFlatDesignTabBar-ObjectiveC/Swift/CYLTabBarController+CYLFlatDesignTabSetup.swift, reached through `CYLFlatDesignTabSetup`.
 [CN] 另一会话移交的第 1 块（第 126 步）：设置 Tab。`-setViewControllers:` 与 `-addChildViewController:` 在 CYLTabBarController.m 中保留为
      一行的重写，调用这里的方法（Objective-C 类的 Swift 扩展无法重写它们）；实例变量通过旁边的存储 setter 写入。公开方法声明于
      `CYLTabBarController (CYLTabSetup)`。以 Objective-C selector 实现的内部成员。`-setViewControllers:` 的扁平样式部分位于扁平样式子库，
      通过 `CYLFlatDesignTabSetup` 调用。
 */
@objc protocol CYLFlatDesignTabSetup {
    /// [EN] Returns false when the FlatDesign tab bar is not in place (nothing else is set up). [CN] 扁平样式 TabBar 不存在时返回 false。
    @objc(cyl_flatDesignSetViewControllers:) optional func cylFlatDesignSetViewControllers(_ viewControllers: [UIViewController]) -> Bool
}

/// [EN] Storage setters and the classic tab item setup implemented in CYLTabBarController.m. [CN] 实现于 CYLTabBarController.m 的存储 setter 等。
@objc protocol CYLTabSetupStorage {
    @objc(cyl_setViewControllersStorage:) func cylSetViewControllersStorage(_ viewControllers: [UIViewController]?)
    @objc(cyl_setStoredTabBar:) func cylSetStoredTabBar(_ tabBar: UIView?)
    @objc(setPagesByPageIdentifier:) func cylSetPagesByPageIdentifierState(_ pagesByPageIdentifier: NSMutableDictionary?)
    @objc(setNeedsReloadItems:) func cylSetNeedsReloadItems(_ needsReloadItems: Bool)
    @objc(setCylDidRefreshSystemTabBarVisibility:) func cylSetDidRefreshSystemTabBarVisibility(_ value: Bool)
    // swiftlint:disable:next line_length
    @objc(addOneChildViewController:WithTitle:normalImageInfo:selectedImageInfo:titlePositionAdjustment:imagePositionAdjustment:imageInsets:lottieURL:lottieSizeValue:)
    func cylAddOneChildViewController(_ viewController: UIViewController, withTitle title: String?, normalImageInfo: Any?, selectedImageInfo: Any?,
                                      titlePositionAdjustment: UIOffset, imagePositionAdjustment: UIOffset, imageInsets: UIEdgeInsets,
                                      lottieURL: URL?, lottieSizeValue: NSValue?)
}

extension CYLTabBarController {

    var cylTabSetupStorage: CYLTabSetupStorage {
        unsafeBitCast(self as AnyObject, to: CYLTabSetupStorage.self)
    }

    private var cylFlatDesignTabSetup: CYLFlatDesignTabSetup {
        unsafeBitCast(self as AnyObject, to: CYLFlatDesignTabSetup.self)
    }

    // MARK: - Public (CYLTabBarController (CYLTabSetup))

    /// [EN] The tab bar's tint color; no effect with FlatDesign. [CN] TabBar 的 tintColor；扁平样式下无效。
    @objc(setTintColor:)
    func cylSetTintColor(_ tintColor: UIColor?) {
        guard tabBarStyleType != .flatDesign else { return }
        cyl_tabBar?.tintColor = tintColor
    }

    /// [EN] Whether the plus button has a child view controller in this controller (bound by `context`, see `-hasPlusButton`).
    /// [CN] PlusButton 在本控制器中是否有子控制器（通过 `context` 绑定，见 `-hasPlusButton`）。
    @objc(hasPlusChildViewController)
    func cylHasPlusChildViewController() -> Bool {
        cylPrivate.cylContextPlusChildViewController() != nil
    }

    /**
     [EN] Index into `tabBarItemsAttributes` of the tab at `index` in `viewControllers`. FIX: placeholder count mismatch —
          guarded by the data: with a slot entry the attributes match `viewControllers` one to one; without one, tabs after
          the slot (placeholder or plus child) are one entry earlier.
     [CN] `viewControllers` 中第 `index` 个 Tab 在 `tabBarItemsAttributes` 中的索引。FIX：按数据判断：有 slot 项时一一对应；没有时，slot
          之后的 Tab 对应的属性前移一项。
     */
    @objc(cyl_tabBarItemsAttributesIndexOfViewControllerAtIndex:)
    func cylTabBarItemsAttributesIndexOfViewController(at index: UInt) -> UInt {
        if cylTabBarItemsAttributesIncludePlusSlot() {
            return index
        }
        let slotIndex = cylPlusSlotIndexInViewControllers()
        return (slotIndex != NSNotFound && slotIndex < Int(index)) ? index - 1 : index
    }

    /// [EN] The attributes of the tab at `index`; nil for the plus button's tab or when there is none.
    /// [CN] 第 `index` 个 Tab 的属性；PlusButton 的 Tab 或没有对应项时为 nil。
    @objc(tabBarItemAttributesAtIndex:)
    func cylTabBarItemAttributes(at index: UInt) -> [String: Any]? {
        let tabs = viewControllers ?? []
        guard Int(index) < tabs.count else { return nil }
        let viewController = tabs[Int(index)]
        if viewController.cyl_isPlaceholder || viewController === cylPrivate.cylContextPlusChildViewController() {
            return nil
        }
        let attributesIndex = Int(cylTabBarItemsAttributesIndexOfViewController(at: index))
        let attributes = tabBarItemsAttributes
        return attributesIndex < attributes.count ? attributes[attributesIndex] as? [String: Any] : nil
    }

    /// [EN] As a new set of tabs: the tab buttons, Lottie views, covers and badges are set up again.
    /// [CN] 与重新设置一组 Tab 相同：Tab 按钮、Lottie 视图、封面与角标重新设置。
    private func cylResetTabBarItemContent() {
        cylRearmViewDidLayoutSubviewsBlockInvokeOnce()
        cylPrivate.cylSetTabBarItemAnimationViewAdded(false)
        cylPrivate.cylTabBarItemAnimationURLs().removeAllObjects()
        cylPrivate.cylTabBarItemAnimationSizes().removeAllObjects()
    }

    /**
     [EN] Reloads the tabs with new attributes (view controllers are set again). Created from page IDs: the new tabs get their
          pages from the same sources (docs/Tab-Page-Registry.md).
     [CN] 使用新的属性重新加载 Tab（重新设置 viewControllers）。由页面 ID 创建时，新的 Tab 从同样的来源获得页面。
     */
    @objc(reloadTabBarItemsWithAttributes:)
    func cylReloadTabBarItems(withAttributes attributes: [[AnyHashable: Any]]) {
        guard tabBarStyleType != .flatDesign else { return }
        var newAttributes = attributes
        var resolvedPages: [UIViewController]?
        if cylPrivate.cylPagesFromPageIdentifiersState() {
            let keptTabs = NSMutableArray()
            resolvedPages = cylPagesOfReloadedTabs(attributes, keptTabs: keptTabs)
            newAttributes = keptTabs.compactMap { $0 as? [AnyHashable: Any] }
        }
        cylPrivate.cylReplaceTabBarItemsAttributesStorage(newAttributes)
        cylResetTabBarItemContent()
        var index = selectedIndex
        let current = viewControllers ?? []
        // FIX: issue #618 — `selectedIndex` is not always a valid index (NSNotFound, or an extra tab UIKit created).
        var selected: UIViewController? = (index >= 0 && index < current.count) ? current[index] : nil
        var superView = selected?.view.superview
        var tabs = resolvedPages ?? current
        if resolvedPages != nil, let page = selected, !tabs.contains(where: { $0 === page }) {
            // [EN] The selected tab is gone: select the first one. [CN] 选中的 Tab 已不存在：选中第一个。
            selected = nil
            superView = nil
            index = 0
        }
        if resolvedPages == nil, let plusChild = cylPrivate.cylContextPlusChildViewController(),
           let plusChildIndex = tabs.firstIndex(of: plusChild) {
            // FIX: issue #515 — remove the plus child view controller itself, wherever it is. [CN] 直接移除 PlusButton 子控制器本身。
            tabs.remove(at: plusChildIndex)
        }
        viewControllers = tabs
        cylAdoptPendingPages()
        // FIX: issue #433
        cylSetNeedsUpdateTabBarItemSelectedTitles(self)
        view.setNeedsLayout()
        if resolvedPages == nil || (index >= 0 && index < (viewControllers?.count ?? 0)) {
            selectedIndex = index
        }
        if let superView, let selected {
            superView.addSubview(selected.view)
        }
    }

    /**
     FIX: issue #481
     [EN] Replaces the view controller of the tab at `index` (see the header). NO when there is no such tab, it is the plus
          button's, or `viewController` is already one of the tabs.
     [CN] 替换第 `index` 个 Tab 的视图控制器（见头文件）。没有该 Tab、是 PlusButton 的 Tab，或 `viewController` 已是某个 Tab 时返回 NO。
     */
    @objc(replaceViewControllerAtIndex:withViewController:attributes:)
    func cylReplaceViewController(at index: UInt, with viewController: UIViewController?, attributes: [String: Any]?) -> Bool {
        let current = viewControllers ?? []
        guard Int(index) < current.count, let viewController, !current.contains(viewController) else { return false }
        let oldViewController = current[Int(index)]
        let plusChild = cylPrivate.cylContextPlusChildViewController()
        if oldViewController.cyl_isPlaceholder || oldViewController === plusChild {
            return false
        }
        let selectedViewController = self.selectedViewController
        // [EN] The shape the controller was created with: no entry for the plus button's tab, which `-setViewControllers:`
        //      inserts again. [CN] 与创建时相同的结构：不含 PlusButton 的 Tab，`-setViewControllers:` 会重新插入它。
        var tabs: [UIViewController] = []
        var tabAttributesList: [[AnyHashable: Any]] = []
        for (tabIndex, tab) in current.enumerated() {
            if tab.cyl_isPlaceholder || tab === plusChild { continue }
            var tabViewController = tab
            var tabAttributes: [AnyHashable: Any] = cylTabBarItemAttributes(at: UInt(tabIndex)) ?? [:]
            if tabIndex == Int(index) {
                // [EN] The new tab's own entry; nil keeps the old one. [CN] 使用新 Tab 自己的属性；为 nil 时保留旧的。
                tabViewController = viewController
                tabAttributes = attributes.map { $0 as [AnyHashable: Any] } ?? tabAttributes
            }
            tabs.append(tabViewController)
            tabAttributesList.append(tabAttributes)
        }
        plusChild?.cyl_plusViewControllerEverAdded = false
        cylPrivate.cylReplaceTabBarItemsAttributesStorage(tabAttributesList)
        cylResetTabBarItemContent()
        // [EN] As a new set of tabs (#608). [CN] 与重新设置一组 Tab 相同（#608）。
        viewControllers = tabs
        // FIX: issue #433
        cylSetNeedsUpdateTabBarItemSelectedTitles(self)
        // [EN] UIKit's list was cleared (#608): hand UIKit's own setter the same tabs, so it builds their tab items again.
        // [CN] UIKit 的 Tab 列表被清空（#608）：把同样的 Tab 交给 UIKit 自身的 setter，使其重新生成 TabBarItem。
        let uiKitTabs = super.viewControllers
        if tabBarStyleType != .flatDesign && (tabBar.items?.count ?? 0) != (uiKitTabs?.count ?? 0) {
            super.setViewControllers(uiKitTabs, animated: false)
        }
        let viewControllerToSelect = selectedViewController === oldViewController ? viewController : selectedViewController
        if let viewControllerToSelect, let newIndex = (viewControllers ?? []).firstIndex(of: viewControllerToSelect) {
            // [EN] The selected page's view was removed: go through another tab first so the page is shown again.
            // [CN] 选中页面的视图已被移除：先选中另一个 Tab，再选回来以重新显示。
            if selectedIndex == newIndex && (viewControllers?.count ?? 0) > 1 {
                super.selectedIndex = newIndex == 0 ? 1 : 0
            }
            selectedIndex = newIndex
        }
        view.setNeedsLayout()
        return true
    }

    // MARK: - Pages of reloaded tabs (docs/Tab-Page-Registry.md)

    /**
     [EN] The tabs that may get a page: placeholders for invalid tabs (B4) and tabs left out by their platforms or minimum
          version (B22) are reported in `skipped` instead. Also called by `-initWithConfiguration:`.
     [CN] 可以获得页面的 Tab：无效 Tab 的占位（B4）与因平台或最低版本被排除的 Tab（B22）记录到 `skipped` 中。`-initWithConfiguration:` 也调用。
     */
    @objc(cyl_resolvableTabs:skipped:)
    static func cylResolvableTabs(_ items: [Any], skipped: NSMutableArray) -> [[String: Any]] {
        var tabs: [[String: Any]] = []
        for item in items {
            guard let attributes = item as? [String: Any], !attributes.isEmpty else {
                skipped.add(CYLTabBarSkippedTab.skippedTab(with: .invalidTab, pageIdentifier: nil, attributes: nil,
                                                           detail: "a placeholder for a tab that is not a dictionary"))
                continue
            }
            if (attributes[CYLTabBarItemExcludedKey] as? NSNumber)?.boolValue == true {
                skipped.add(CYLTabBarSkippedTab.skippedTab(with: .excluded, pageIdentifier: CYLTabBarPageRegistry.pageIdentifier(ofTab: attributes),
                                                           attributes: attributes, detail: attributes[CYLTabBarItemExclusionReasonKey] as? String))
                continue
            }
            tabs.append(attributes)
        }
        return tabs
    }

    /// [EN] The pages by page ID, in tab order (one ID may have several pages). Also called by `-initWithConfiguration:`.
    /// [CN] 按页面 ID 分组的页面（按 Tab 顺序；一个 ID 可以有多个页面）。`-initWithConfiguration:` 也调用。
    @objc(cyl_pagesByPageIdentifierOfPages:tabs:)
    static func cylPagesByPageIdentifier(ofPages pages: [UIViewController], tabs: [[String: Any]]) -> NSMutableDictionary {
        let pagesByIdentifier = NSMutableDictionary()
        for (page, tab) in zip(pages, tabs) {
            guard let pageIdentifier = CYLTabBarPageRegistry.pageIdentifier(ofTab: tab) else { continue }
            let list = pagesByIdentifier[pageIdentifier] as? NSMutableArray ?? NSMutableArray()
            list.add(page)
            pagesByIdentifier[pageIdentifier] = list
        }
        return pagesByIdentifier
    }

    /**
     [EN] The pages of reloaded tabs on a controller created from page IDs: the attributes are normalized like a configuration,
          a tab reuses an existing page of its page ID when one is left (in tab order), the other tabs are resolved through
          the controller's sources, and `cyl_skippedTabs` is replaced.
     [CN] 由页面 ID 创建的控制器重新加载的 Tab 的页面：属性像配置一样规范化，页面 ID 还有剩余已有页面的 Tab 复用它（按 Tab 顺序），其余 Tab
          通过控制器的页面来源解析，`cyl_skippedTabs` 被替换。
     */
    @objc(cyl_pagesOfReloadedTabs:keptTabs:)
    func cylPagesOfReloadedTabs(_ tabBarItemsAttributes: [[AnyHashable: Any]], keptTabs: NSMutableArray) -> [UIViewController] {
        let normalized = CYLTabBarController.cyl_normalizedConfiguration([CYLTabBarControllerTabBarItemsAttributes: tabBarItemsAttributes])
        let skipped = NSMutableArray()
        // [EN] Dictionary objects, not Swift copies: a resolved tab is matched by identity, as the provider keeps it.
        // [CN] 使用字典对象而不是 Swift 副本：已解析的 Tab 按对象身份匹配。
        let tabs = CYLTabBarController.cylResolvableTabs(normalized[CYLTabBarControllerTabBarItemsAttributes] as? [Any] ?? [], skipped: skipped)
            .map { $0 as NSDictionary }
        var available: [String: [UIViewController]] = [:]
        for (pageIdentifier, pages) in cylPrivate.cylPagesByPageIdentifierState() ?? [:] {
            available[pageIdentifier] = pages.compactMap { $0 as? UIViewController }
        }
        // [EN] One entry per tab: the reused page, or nil for a tab to resolve. [CN] 每个 Tab 一项：复用的页面，或待解析时为 nil。
        var reusedPages: [UIViewController?] = []
        var tabsToResolve: [NSDictionary] = []
        for tab in tabs {
            if let pageIdentifier = CYLTabBarPageRegistry.pageIdentifier(ofTab: tab as? [String: Any] ?? [:]),
               let page = available[pageIdentifier]?.first {
                available[pageIdentifier]?.removeFirst()
                reusedPages.append(page)
            } else {
                reusedPages.append(nil)
                tabsToResolve.append(tab)
            }
        }
        let keptNewTabs = NSMutableArray()
        let newPages = CYLTabBarPageRegistry.pages(ofTabs: tabsToResolve, registry: cylPrivate.cylPageRegistryState(),
                                                   resolver: cylPrivate.cylPageResolverState(), lookupOrder: cylPrivate.cylPageLookupOrderState(),
                                                   keptTabs: keptNewTabs, skipped: skipped)
        var pages: [UIViewController] = []
        var keptTabList: [NSDictionary] = []
        var newIndex = 0
        for (index, tab) in tabs.enumerated() {
            if let reused = reusedPages[index] {
                pages.append(reused)
                keptTabList.append(tab)
            } else if newIndex < keptNewTabs.count, (keptNewTabs[newIndex] as AnyObject) === tab {
                let page = newPages[newIndex]
                newIndex += 1
                if reusedPages.contains(where: { $0 === page }) {
                    // [EN] A provider returned a page another tab keeps. [CN] 提供者返回了其他 Tab 继续使用的页面。
                    let attributes = tab as? [String: Any]
                    skipped.add(CYLTabBarSkippedTab.skippedTab(with: .providerFailed, pageIdentifier: CYLTabBarPageRegistry.pageIdentifier(ofTab: attributes ?? [:]),
                                                               attributes: attributes, detail: "the page is already the page of another tab"))
                    continue
                }
                pages.append(page)
                keptTabList.append(tab)
            }
        }
        keptTabs.addObjects(from: keptTabList)
        cylTabSetupStorage.cylSetPagesByPageIdentifierState(CYLTabBarController.cylPagesByPageIdentifier(ofPages: pages, tabs: keptTabList.map { $0 as? [String: Any] ?? [:] }))
        cylPrivate.cylSetSkippedTabsState(skipped.compactMap { $0 as? CYLTabBarSkippedTab })
        return pages
    }

    // MARK: - The system tab bar replaced by CYLTabBar

    /// [EN] Replaces the system tab bar with CYLTabBar (viewDidLoad); FlatDesign sets its tab bar in `-setViewControllers:`.
    /// [CN] 用 CYLTabBar 替换系统 TabBar（viewDidLoad 中）；扁平样式在 `-setViewControllers:` 中设置其 TabBar。
    @objc(setUpDefaultStyleTabBar)
    func cylSetUpDefaultStyleTabBar() {
        guard tabBarStyleType != .flatDesign else { return }
        cylSetUpTabBar(nil)
    }

    /**
     [EN] Sets `tabBar` (a new CYLTabBar when nil) through KVC. `-cyl_setValue:forKey:` checks the key first, which replaces the
          former `@try` (Swift cannot catch an Objective-C exception).
     [CN] 通过 KVC 设置 `tabBar`（为 nil 时新建 CYLTabBar）。`-cyl_setValue:forKey:` 会先检查键，代替原来的 `@try`（Swift 无法捕获 Objective-C 异常）。
     */
    @objc(setUpTabBar:)
    func cylSetUpTabBar(_ tabBar: UIView?) {
        guard tabBarStyleType != .flatDesign else { return }
        let newTabBar: UIView
        if let tabBar {
            newTabBar = tabBar
        } else {
            let created = CYLTabBar()
            created.cylSetTabBarController(self)
            cylTabSetupStorage.cylSetStoredTabBar(created)
            newTabBar = created
        }
        cyl_setValue(newTabBar, forKey: "tabBar")
        cylSetUpIPAD(for: newTabBar)
    }

    /// [EN] Pins the tab bar to the bottom on iPadOS 18 and later. [CN] iPadOS 18 及以上把 TabBar 固定在底部。
    @objc(setUpIPADForTabBar:)
    func cylSetUpIPAD(for tabBar: UIView) {
        guard tabBarStyleType != .flatDesign, #available(iOS 18.0, *), UIDevice.current.userInterfaceIdiom == .pad else { return }
        mode = .tabBar
        traitOverrides.horizontalSizeClass = .compact
        view.addSubview(tabBar)
        let tabContainerClassName = "_UITab" + "Container" + "View"
        var setupSuccess = false
        for subview in view.subviews where NSStringFromClass(type(of: subview)) == tabContainerClassName {
            subview.isHidden = true
            setupSuccess = true
        }
        if !setupSuccess, let stored = cyl_tabBar {
            // [EN] Guards against future class name changes. [CN] 防止未来类名变动。
            stored.removeFromSuperview()
            view.addSubview(stored)
        }
    }

    // MARK: - Overrides (called by the one-line overrides in CYLTabBarController.m)

    /// [EN] `-addChildViewController:` after the Objective-C override called super: the #618 diagnostics. [CN] `-addChildViewController:`：调用 super，再做 #618 诊断。
    @objc(cyl_overrideAddChildViewController:)
    func cylOverrideAddChildViewController(_ childController: UIViewController) {
        #if DEBUG || BETA
        cylLogChildViewControllerThatIsNotATabIfNeeded(childController)
        #endif
    }

    /**
     [EN] `-setViewControllers:`. The classic style and Liquid Glass install each tab with `-addChildViewController:` (CYL's own
          list, `@synthesize viewControllers = _viewControllers`); FlatDesign in the FlatDesign subspec. Then the tab icons
          of `CYLTabBarItemImageURL` are loaded (issue #601).
     [CN] `-setViewControllers:`。经典样式与液态玻璃用 `-addChildViewController:` 添加每个 Tab（CYL 自己的数组）；扁平样式由扁平样式子库处理。
          之后加载 `CYLTabBarItemImageURL` 的 Tab 图标（issue #601）。
     */
    @objc(cyl_setViewControllers:)
    func cylSetViewControllers(_ newViewControllers: [UIViewController]?) {
        let newTabs = newViewControllers ?? []
        // [EN] Known from now on (`+cyl_tabBarControllerForContext:`); not on a tear-down (nil / empty), when no weak
        //      reference may be formed. [CN] 从现在起可以被查到；销毁过程中（nil / 空数组）不记录，此时不能再建立弱引用。
        if !newTabs.isEmpty {
            CYLTabBarController.cylRegister(self)
        }
        if tabBarStyleType != .flatDesign {
            guard cylSetClassicViewControllers(newTabs) else { return }
        } else if cylFlatDesignTabSetup.cylFlatDesignSetViewControllers?(newTabs) == false {
            return
        }
        cylLoadTabBarItemImageURLs()
    }

    /// [EN] The classic style and Liquid Glass; false when `-setViewControllers:` stops here. [CN] 经典样式与液态玻璃；在此结束时返回 false。
    private func cylSetClassicViewControllers(_ newTabs: [UIViewController]) -> Bool {
        let oldTabs = viewControllers ?? []
        if !oldTabs.isEmpty {
            for tab in oldTabs {
                tab.willMove(toParent: nil)
                tab.view.removeFromSuperview()
                tab.removeFromParent()
            }
            if cylHasPlusChildViewController() && !cyl_isPlusViewControllerAdded(oldTabs),
               let plusChild = cylPrivate.cylContextPlusChildViewController() {
                plusChild.willMove(toParent: nil)
                plusChild.view.removeFromSuperview()
                plusChild.removeFromParent()
            }
            // FIX: issue #608 — clear UIKit's tab list too, so the new tabs are installed as on the first assignment (the
            // old items crashed the next tap on iOS 16: "No view controller matches the UITabBarItem").
            // [CN] 同时清空 UIKit 的 Tab 列表，让新 Tab 与首次赋值时一样安装（旧的 item 曾使 iOS 16 下一次点击崩溃）。
            super.setViewControllers(nil, animated: false)
        }
        guard !newTabs.isEmpty else {
            for tab in oldTabs {
                tab.cyl_getViewControllerInsteadOfNavigation().cylSetTabBarController(nil)
                tab.cylSetTabBarController(nil)
            }
            cylTabSetupStorage.cylSetViewControllersStorage(nil)
            return false
        }
        cylTabSetupStorage.cylSetViewControllersStorage(cylViewControllersAligningPlusSlot(with: newTabs))
        #if DEBUG || BETA
        cylLogTabBarItemsAttributesMismatchIfNeeded()
        #endif
        // [EN] The app's own tabs: a slot carried by the array (a re-assignment) is not a tab. [CN] App 自己的 Tab：数组自带的 slot 不算。
        cyl_tabBar?.cyl_tabbarItemsCount = UInt(cylViewControllersByRemovingPlusSlot(newTabs).count)
        guard let tabBar = cyl_tabBar as? CYLTabBar else {
            cylHandTabsToUIKitIfMoreThanFive()
            return false
        }
        tabBar.cyl_tabBarItemWidth = (tabBar.cyl_boundsSize().width - tabBar.cyl_plusButtonWidth()) / CGFloat(tabBar.cyl_tabbarItemsCount)
        var idx: UInt = 0
        for viewController in viewControllers ?? [] {
            // FIX: issue #604 — one place reads a tab item's attributes, for every style. [CN] 所有样式共用同一处读取属性的代码。
            let setup = cylTabBarItemSetup(for: viewController, idx: idx)
            idx = setup.idx
            var normalImageInfo = setup.normalImageInfo
            var selectedImageInfo = setup.selectedImageInfo
            // [EN] A placeholder without its own slot entry keeps the placeholder image. [CN] 没有自己 slot 项的占位保留占位图片。
            if viewController.cyl_isPlaceholder && !cylTabBarItemsAttributesIncludePlusSlot() {
                normalImageInfo = UIImage.cyl_tabItemPlaceholder()
                selectedImageInfo = UIImage.cyl_tabItemPlaceholder()
            }
            cylTabSetupStorage.cylAddOneChildViewController(viewController, withTitle: setup.title, normalImageInfo: normalImageInfo,
                                                            selectedImageInfo: selectedImageInfo, titlePositionAdjustment: setup.titlePositionAdjustment,
                                                            imagePositionAdjustment: setup.imagePositionAdjustment, imageInsets: setup.imageInsets,
                                                            lottieURL: setup.animationURL, lottieSizeValue: setup.animationSizeValue)
            let content = viewController.cyl_getViewControllerInsteadOfNavigation()
            let bound: [Any?] = [viewController, content, viewController.cyl_getActualBadgeSuperView(), content.cyl_getActualBadgeSuperView(),
                                 viewController.tabBarItem.cyl_getActualBadgeSuperView(), content.tabBarItem.cyl_getActualBadgeSuperView()]
            for object in bound {
                (object as? NSObject)?.cylSetTabBarController(self)
            }
            idx += 1
        }
        cylHandTabsToUIKitIfMoreThanFive()
        return true
    }

    /**
     [EN] FIX: more than five tabs showed only the first five on the classic style and Liquid Glass, with no "More": UIKit builds
          "More" only in `-setViewControllers:` and only for view controllers that are not children yet, so the children are
          taken out and handed to UIKit; `viewControllers` (CYL's own list) is empty meanwhile, else UIKit sees no change.
     [CN] FIX：超过 5 个 Tab 时经典样式与液态玻璃只显示前 5 个且没有「More」：UIKit 只在 `-setViewControllers:` 中、且只为还不是子控制器的控制器
          生成「More」，因此先移除子控制器再交给 UIKit；期间 `viewControllers`（CYL 自己的数组）为空，否则 UIKit 认为没有变化。
     */
    private func cylHandTabsToUIKitIfMoreThanFive() {
        let tabs = viewControllers ?? []
        guard tabs.count > 5 else { return }
        for tab in tabs where tab.parent === self {
            tab.willMove(toParent: nil)
            tab.removeFromParent()
        }
        cylTabSetupStorage.cylSetViewControllersStorage(nil)
        super.setViewControllers(tabs, animated: false)
        cylTabSetupStorage.cylSetViewControllersStorage(tabs)
    }

    // MARK: - Tab icons from URLs (issue #601)

    /// [EN] Every tab with `CYLTabBarItemImageURL` shows the downloaded icons once ready. [CN] 带 `CYLTabBarItemImageURL` 的 Tab 下载完成后显示图标。
    private func cylLoadTabBarItemImageURLs() {
        let attributes = tabBarItemsAttributes
        for index in 0..<(viewControllers ?? []).count {
            let attributesIndex = Int(cylTabBarItemsAttributesIndexOfViewController(at: UInt(index)))
            if attributesIndex < attributes.count, let tabAttributes = attributes[attributesIndex] as? [String: Any] {
                cylLoadImageURLs(ofAttributes: tabAttributes, at: UInt(index))
            }
        }
    }

    /// [EN] The same sources as `-setTabBarItemIcon:selectedIcon:size:atIndex:`: a URL, and also a local image.
    /// [CN] 与 `-setTabBarItemIcon:selectedIcon:size:atIndex:` 相同的来源：URL，也可以是本地图片。
    @objc(cyl_loadImageURLsOfAttributes:atIndex:)
    @discardableResult
    func cylLoadImageURLs(ofAttributes attributes: [String: Any], at index: UInt) -> Bool {
        guard let icon = attributes[CYLTabBarItemImageURL] else { return false }
        let size = (attributes[CYLTabBarItemImageURLSize] as? NSValue)?.cgSizeValue ?? .zero
        return setTabBarItemIcon(icon, selectedIcon: attributes[CYLTabBarItemSelectedImageURL], size: size, at: index)
    }

    // MARK: - FIX: issue #618, diagnostics only (DEBUG / BETA builds)

    #if DEBUG || BETA
    /**
     [EN] A child added to the tab bar controller outside `viewControllers` (app code, or a player during rotation) can become
          an extra, untitled tab when UIKit rebuilds the tab bar, and tapping it crashes inside UIKit. CYL cannot refuse the
          child, so it reports it.
     [CN] 不通过 `viewControllers` 添加到 TabBarController 的子控制器（App 代码，或横屏时的播放器）可能在 UIKit 重建 TabBar 时变成多出的无标题 Tab，
          点击后在 UIKit 内部崩溃。CYL 不能拒绝该子控制器，因此在此提示。
     */
    private func cylLogChildViewControllerThatIsNotATabIfNeeded(_ childController: UIViewController) {
        guard tabBarStyleType != .flatDesign, !(viewControllers ?? []).contains(childController),
              childController !== cylPrivate.cylContextPlusChildViewController(), !childController.cyl_isPlaceholder else { return }
        // [EN] UIKit's own controllers ("More", the iPad sidebar), matched by class name so `moreNavigationController` is never
        //      created from here. [CN] UIKit 自己的控制器（「More」、iPad 侧边栏），按类名判断，避免在此创建 `moreNavigationController`。
        let className = NSStringFromClass(type(of: childController))
        guard !className.hasPrefix("_"), !className.hasPrefix("UI") else { return }
        NSLog("🔴[CYL #618] %@ was added to %@ with -addChildViewController:, not through `viewControllers`. UIKit can turn it into an extra, untitled tab (e.g. after a rotation), and tapping that tab crashes. Present it, or push it from a tab's navigation controller, instead. See https://github.com/ChenYilong/CYLTabBarController/issues/618",
              className, NSStringFromClass(type(of: self)))
    }

    /// [EN] `tabBarItemsAttributes` must have one entry per tab (the slot not counted). [CN] 每个 Tab 必须恰好一项属性（slot 不计）。
    private func cylLogTabBarItemsAttributesMismatchIfNeeded() {
        guard !tabBarItemsAttributes.isEmpty else { return }
        let attributesCount = cylTabBarItemsAttributesByRemovingPlusSlot(tabBarItemsAttributes)?.count ?? 0
        let tabCount = cylViewControllersByRemovingPlusSlot(viewControllers).count
        guard attributesCount != tabCount else { return }
        NSLog("🔴[CYL #618] tabBarItemsAttributes has %lu entries for %lu tab view controllers (the plus button's view controller not counted). Each tab needs exactly one entry; a mismatch shows tabs without a view controller, and tapping one can crash. See https://github.com/ChenYilong/CYLTabBarController/issues/618",
              attributesCount, tabCount)
    }
    #endif
}
