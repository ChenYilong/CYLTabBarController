//
//  CYLTabBarController+CYLPageRegistry.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The associated object keys shared with CYLTabBarController.m, which reads and writes them too (selector-based
 *      keys, the same pointer on both sides).
 * [CN] 与 CYLTabBarController.m 共用的关联对象 key（它也会读写；基于 selector 的 key，两边是同一个指针）。
 */
enum CYLTabBarItemTitleKeys {
    /// [EN] The tab's normal title while its selected title shows (#433). [CN] 显示选中标题时 Tab 的普通标题（#433）。
    static let normalTitle = CYLUtilsKeys.key("cyl_tabBarItemNormalTitle")
    static let navigationTitleFollowsTabBarItemTitle = CYLUtilsKeys.key("cyl_navigationTitleFollowsTabBarItemTitle")
}

// MARK: - CYLTabBarController (CYLPageRegistry)

/**
 * [EN] `CYLTabBarController (CYLPageRegistry)`: the read-only view of the page registry state. Translated from
 *      Objective-C (docs/Swift-Migration.md, step 54). The state itself stays in the class extension of
 *      CYLTabBarController.m until the class moves; Swift reads it through `cylPrivate`.
 * [CN] `CYLTabBarController (CYLPageRegistry)`：页面注册表状态的只读接口。已从 Objective-C 翻译（docs/Swift-Migration.md，第 54 步）。
 *      状态本身仍在 CYLTabBarController.m 的类扩展中，直到该类迁移；Swift 通过 `cylPrivate` 读取。
 */
extension CYLTabBarController {

    @objc(cyl_pageRegistry)
    open var cyl_pageRegistry: (any CYLTabBarPageProviding)? {
        @objc(cyl_pageRegistry) get { cylPageRegistry() }
    }

    func cylPageRegistry() -> CYLTabBarPageProviding? {
        cylPrivate.cylPageRegistryState()
    }

    @objc(cyl_pageResolver)
    open var cyl_pageResolver: CYLTabBarPageProvider? {
        @objc(cyl_pageResolver) get { cylPageResolver() }
    }

    func cylPageResolver() -> CYLTabBarPageProvider? {
        cylPrivate.cylPageResolverState()
    }

    @objc(cyl_pageLookupOrder)
    open var cyl_pageLookupOrder: [String] {
        @objc(cyl_pageLookupOrder) get { cylPageLookupOrder() }
    }

    func cylPageLookupOrder() -> [String] {
        cylPrivate.cylPageLookupOrderState() ?? CYLTabBarPageRegistry.defaultPageLookupOrder
    }

    @objc(cyl_skippedTabs)
    open var cyl_skippedTabs: [CYLTabBarSkippedTab] {
        @objc(cyl_skippedTabs) get { cylSkippedTabs() }
    }

    func cylSkippedTabs() -> [CYLTabBarSkippedTab] {
        cylPrivate.cylSkippedTabsState() ?? []
    }

    @objc(cyl_pendingPages)
    open var cyl_pendingPages: [UIViewController] {
        @objc(cyl_pendingPages) get { cylPendingPages() }
    }

    func cylPendingPages() -> [UIViewController] {
        (viewControllers ?? []).filter { $0.cyl_isPendingPage }
    }

    @objc(cyl_pagesFromPageIdentifiers)
    open var cyl_pagesFromPageIdentifiers: Bool {
        @objc(cyl_pagesFromPageIdentifiers) get { cylPagesFromPageIdentifiers() }
    }

    func cylPagesFromPageIdentifiers() -> Bool {
        cylPrivate.cylPagesFromPageIdentifiersState()
    }
}

// MARK: - Asynchronous pages

/**
 * [EN] `CYLTabBarController (CYLPendingPages)` (docs/Tab-Page-Registry.md). Translated from Objective-C
 *      (docs/Swift-Migration.md, step 54); CYLTabBarController.m still declares the category, as it calls both methods.
 * [CN] `CYLTabBarController (CYLPendingPages)`（docs/Tab-Page-Registry.md）。已从 Objective-C 翻译（docs/Swift-Migration.md，第 54 步）；
 *      CYLTabBarController.m 仍声明该分类，因为它调用这两个方法。
 */
extension CYLTabBarController {

    /**
     * [EN] Takes charge of the placeholders of asynchronous factories among the tabs: a pending one calls back when its
     *      page arrives, one that already finished (a factory that completed synchronously) is swapped on the next run loop
     *      turn, so `-setViewControllers:` is never re-entered.
     * [CN] 接管 Tab 中异步工厂的占位：尚未完成的在页面到达时回调；已完成的（工厂同步完成）在下一次 run loop 换入，避免重入
     *      `-setViewControllers:`。
     */
    @objc(cyl_adoptPendingPages)
    func cylAdoptPendingPages() {
        for viewController in viewControllers ?? [] {
            if viewController.cyl_isPendingPage {
                viewController.cyl_pageLoadHandler = { [weak self] placeholder in
                    self?.cylPlaceholderDidFinishLoading(placeholder)
                }
            } else if viewController.cyl_loadedPage != nil || viewController.cyl_pageLoadFailed {
                DispatchQueue.main.async { [weak self] in
                    self?.cylPlaceholderDidFinishLoading(viewController)
                }
            }
        }
    }

    /**
     * [EN] Why a delivered page cannot be the tab's page, or nil when it can. [CN] 交付的页面不能作为 Tab 页面的原因；可以时为 nil。
     */
    private func cylProblem(ofDeliveredPage page: UIViewController?, in viewControllers: [UIViewController]) -> String? {
        guard let page else {
            return "the asynchronous page factory delivered nil"
        }
        if page is UITabBarController {
            return "the delivered page is a tab bar controller (tab bars cannot be nested)"
        }
        if page.parent != nil || page.presentingViewController != nil {
            return "the delivered page already belongs to another container"
        }
        if viewControllers.contains(where: { $0 === page }) {
            return "the delivered page is already the page of another tab"
        }
        return nil
    }

    /**
     * [EN] The page of a placeholder arrived: it is swapped in at the placeholder's index (title, attributes and selection
     *      kept), or, when the factory delivered nil or a page that cannot be a tab, the tab is removed and listed in
     *      `cyl_skippedTabs`. The delegate is told either way.
     * [CN] 占位的页面已到达：在占位的下标换入（标题、属性与选中状态保留）；工厂交付 nil 或不能作为 Tab 的页面时，移除该 Tab 并记录到
     *      `cyl_skippedTabs`。两种情况都会通知代理。
     */
    @objc(cyl_placeholderDidFinishLoading:)
    func cylPlaceholderDidFinishLoading(_ placeholder: UIViewController) {
        var viewControllers = self.viewControllers ?? []
        guard let index = viewControllers.firstIndex(where: { $0 === placeholder }),
              placeholder.cyl_loadedPage != nil || placeholder.cyl_pageLoadFailed else {
            return
        }
        placeholder.cyl_pageLoadHandler = nil
        var page = placeholder.cyl_loadedPage
        let problem = cylProblem(ofDeliveredPage: page, in: viewControllers)
        let attributes = tabBarItemAttributes(at: UInt(index))
        let pageIdentifier = CYLTabBarPageRegistry.pageIdentifier(ofTab: attributes ?? [:])
        let pages = pageIdentifier.flatMap { cylPrivate.cylPagesByPageIdentifierState()?[$0] }
        let wasSelected = selectedIndex == index
        if let problem {
            viewControllers.remove(at: index)
            let attributesIndex = Int(cylTabBarItemsAttributesIndexOfViewController(at: UInt(index)))
            var tabBarItemsAttributes = self.tabBarItemsAttributes
            if attributesIndex < tabBarItemsAttributes.count {
                tabBarItemsAttributes.remove(at: attributesIndex)
                cylPrivate.cylReplaceTabBarItemsAttributesStorage(tabBarItemsAttributes)
            }
            let skipped = CYLTabBarSkippedTab(reason: .providerFailed, pageIdentifier: pageIdentifier,
                                              attributes: attributes, detail: problem)
            cylPrivate.cylSetSkippedTabsState((cylPrivate.cylSkippedTabsState() ?? []) + [skipped])
            pages?.removeObject(identicalTo: placeholder)
            #if DEBUG
            NSLog("🔴 CYLTabBarController: the tab is removed: %@.", skipped)
            #endif
            page = nil
        } else if let page {
            viewControllers[index] = page
            let content = (page as? UINavigationController)?.viewControllers.first ?? page
            if let title = attributes?[cylTabBarItemTitle] as? String, content.navigationItem.title == nil {
                content.navigationItem.title = title
            }
            if let pages {
                let pageIndex = pages.indexOfObjectIdentical(to: placeholder)
                if pageIndex != NSNotFound {
                    pages[pageIndex] = page
                }
            }
        }
        self.viewControllers = viewControllers
        let count = self.viewControllers?.count ?? 0
        if wasSelected && count > 0 {
            selectedIndex = min(index, count - 1)
        }
        let delegate = cylDelegate
        delegate?.cyl_tabBarController?(self, didLoadPage: page, forPlaceholder: placeholder, at: UInt(index))
    }
}

// MARK: - UIViewController (CYLTabBarItemTitleSupport)

/**
 * [EN] `UIViewController (CYLTabBarItemTitleSupport)`. Translated from Objective-C (docs/Swift-Migration.md, step 54);
 *      the category stays declared in CYLTabBarController.h, whose macros use it.
 * [CN] `UIViewController (CYLTabBarItemTitleSupport)`。已从 Objective-C 翻译（docs/Swift-Migration.md，第 54 步）；该分类仍声明在
 *      CYLTabBarController.h 中，其中的宏会用到它。
 */
extension UIViewController {

    /**
     * [EN] The title of this view controller's tab: the plus button's title for its page, else the normal title (also while the
     *      selected title shows), the FlatDesign item's title, or the tab bar item's. nil without one.
     * [CN] 本视图控制器所在 Tab 的标题：PlusButton 的页面为 PlusButton 的标题，否则为普通标题（显示选中标题时也是）、扁平样式 item 的标题或
     *      TabBarItem 的标题；没有时为 nil。
     */
    @objc(cyl_tabBarItemTitle)
    open var cyl_tabBarItemTitle: String? {
        let tab: UIViewController = navigationController?.viewControllers.first === self ? (navigationController ?? self) : self
        // [EN] The plus button's page: the plus button's title. [CN] PlusButton 的页面：PlusButton 的标题。
        if let tabBarController = tab.cylTabBarController, tab === tabBarController.cylPrivate.cylContextPlusChildViewController() {
            return CYLPlusButton.cylPlusButton(forOwner: tabBarController)?.cyl_title()
        }
        // [EN] The normal title, also while the selected title shows (#433). [CN] 普通标题，显示选中标题时也是（#433）。
        if let normalTitle = objc_getAssociatedObject(tab, CYLTabBarItemTitleKeys.normalTitle) as? String, !normalTitle.isEmpty {
            return normalTitle
        }
        // [EN] FlatDesign (an optional subspec): the title of the tab's own item, read at run time.
        // [CN] 扁平样式（可选子库）：Tab 自己的 item 的标题，在运行时读取。
        if tab.cylTabBarController?.tabBarStyleType == .flatDesign, tab.responds(to: NSSelectorFromString("cyl_tabBarItem")),
           let item = tab.value(forKey: "cyl_tabBarItem") as? NSObject, let flatTitle = item.value(forKey: "title") as? String,
           !flatTitle.isEmpty {
            return flatTitle
        }
        guard let title = tab.tabBarItem.title, !title.isEmpty else {
            return nil
        }
        return title
    }

    /**
     * [EN] Whether the navigation title follows the tab's title (kept in step when the title changes).
     * [CN] 导航栏标题是否跟随 Tab 标题（标题变化时保持一致）。
     */
    @objc(cyl_navigationTitleFollowsTabBarItemTitle)
    open var cyl_navigationTitleFollowsTabBarItemTitle: Bool {
        @objc(cyl_navigationTitleFollowsTabBarItemTitle) get {
            (objc_getAssociatedObject(self, CYLTabBarItemTitleKeys.navigationTitleFollowsTabBarItemTitle) as? NSNumber)?.boolValue ?? false
        }
        @objc(setCyl_navigationTitleFollowsTabBarItemTitle:) set {
            objc_setAssociatedObject(self, CYLTabBarItemTitleKeys.navigationTitleFollowsTabBarItemTitle, NSNumber(value: newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue, let title = cyl_tabBarItemTitle {
                navigationItem.title = title
            }
        }
    }
}
