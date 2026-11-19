//
//  CYLTabBarController+CYLSetUp.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] A block or closure stored in a configuration dictionary. A Swift closure casts with `as?`; an Objective-C block (what an
 *      Objective-C app puts there) does not, so it is taken as the block object it is and wrapped.
 * [CN] 存放在配置字典中的 block 或闭包。Swift 闭包可用 `as?` 转换；Objective-C block（Objective-C App 放入的）不行，因此把它当作 block 对象取出并包装。
 */
private func cylConfigurationPageProvider(_ value: Any?) -> CYLTabBarPageProvider? {
    guard let value else {
        return nil
    }
    if let closure = value as? CYLTabBarPageProvider {
        return closure
    }
    guard let object = value as AnyObject?, object.isKind(of: NSClassFromString("NSBlock") ?? NSObject.self) else {
        return nil
    }
    typealias CYLPageProviderBlock = @convention(block) (String, [String: Any]) -> UIViewController?
    let block = unsafeBitCast(object, to: CYLPageProviderBlock.self)
    return { block($0, $1) }
}

private func cylConfigurationPlusButtonAction(_ value: Any?) -> ((CYLPlusButton) -> Void)? {
    guard let value else {
        return nil
    }
    if let closure = value as? ((CYLPlusButton) -> Void) {
        return closure
    }
    guard let object = value as AnyObject?, object.isKind(of: NSClassFromString("NSBlock") ?? NSObject.self) else {
        return nil
    }
    typealias CYLPlusButtonActionBlock = @convention(block) (CYLPlusButton) -> Void
    let block = unsafeBitCast(object, to: CYLPlusButtonActionBlock.self)
    return { block($0) }
}

/**
 * [EN] The body of the designated initializer and the members that depend on the style, translated from Objective-C
 *      (`-initWithConfiguration:`, `-setTabBarStyleType:`, `-noNeedUIDesignCompatibility`; docs/Swift-Migration.md, the class switch).
 * [CN] 指定初始化方法的主体以及依赖样式的成员，已从 Objective-C 翻译（`-initWithConfiguration:`、`-setTabBarStyleType:`、`-noNeedUIDesignCompatibility`；
 *      docs/Swift-Migration.md，类迁移）。
 */
extension CYLTabBarController {

    /**
     * [EN] The order the pages of a configuration are looked up in: its own order, without the automatic registration when the
     *      configuration switches it off.
     * [CN] 配置中页面的查找顺序：配置自己的顺序；配置关闭自动注册时去掉自动注册。
     */
    private static func cylPageLookupOrder(of normalized: [String: Any]) -> [String] {
        var order = (normalized[CYLTabBarControllerPageLookupOrder] as? [String]) ?? CYLTabBarPageRegistry.defaultPageLookupOrder
        if let automatic = normalized[CYLTabBarControllerAutomaticPageRegistration] as? NSNumber, !automatic.boolValue {
            order.removeAll { $0 == CYLTabBarPageSourceAutomaticRegistration }
        }
        return order
    }

    /**
     * [EN] Sets the tab bar controller up from a configuration, in the order that matters: the style first (it decides how
     *      `viewControllers` is read), the tab bar, the context (the plus button lookup), the tabs (excluded ones are skipped and
     *      recorded), then the options. Pages named by identifier are resolved before the plus button is registered.
     * [CN] 根据配置设置 TabBarController，顺序很重要：先样式（它决定如何读取 `viewControllers`）、TabBar、context（PlusButton 的查找），然后是各个 Tab
     *      （被排除的 Tab 会被跳过并记录），最后是各选项。按标识命名的页面先于 PlusButton 的注册被解析。
     */
    func cylSetUp(withConfiguration configuration: [String: Any]) {
        #if DEBUG || BETA
        if !Thread.isMainThread {
            NSLog("🔴 CYLTabBarController: created off the main thread; UIKit objects must be created on the main thread.")
        }
        #endif
        let normalized = CYLTabBarController.cyl_normalizedConfiguration(configuration)
        var tabBarItemsAttributes = (normalized[CYLTabBarControllerTabBarItemsAttributes] as? [[String: Any]]) ?? []
        var viewControllers = normalized[CYLTabBarControllerViewControllers] as? [UIViewController]
        let keepsEmpty = (normalized["_CYLTabBarControllerKeepsEmptyViewControllers"] as? NSNumber)?.boolValue ?? false
        if viewControllers?.isEmpty == true && !keepsEmpty {
            viewControllers = nil
        }
        let viewControllersFromCode = viewControllers != nil
        let skippedTabs = NSMutableArray()
        var pageRegistry: CYLTabBarPageProviding?
        var pageResolver: CYLTabBarPageProvider?
        var pageLookupOrder: [String]?
        if !viewControllersFromCode {
            pageRegistry = normalized[CYLTabBarControllerPageRegistry] as? CYLTabBarPageProviding
            pageResolver = cylConfigurationPageProvider(normalized[CYLTabBarControllerPageResolver])
            pageLookupOrder = Self.cylPageLookupOrder(of: normalized)
            let keptItems = NSMutableArray()
            viewControllers = CYLTabBarPageRegistry.pages(
                ofTabs: Self.cylResolvableTabs(tabBarItemsAttributes, skipped: skippedTabs), registry: pageRegistry, resolver: pageResolver,
                lookupOrder: pageLookupOrder, keptTabs: keptItems, skipped: skippedTabs)
            tabBarItemsAttributes = (keptItems as? [[String: Any]]) ?? []
        }
        let imageInsets = (normalized[CYLTabBarControllerImageInsets] as? NSValue)?.uiEdgeInsetsValue ?? .zero
        let titlePositionAdjustment = (normalized[CYLTabBarControllerTitlePositionAdjustment] as? NSValue)?.uiOffsetValue ?? .zero
        let styleType = CYLTabBarStyleType(rawValue: (normalized[CYLTabBarControllerStyleType] as? NSNumber)?.intValue ?? 0) ?? .default
        let context = normalized[CYLTabBarControllerContext] as? String
        var plusButtonShowsSelection = false
        if var plusButtonAttributes = normalized[CYLTabBarControllerPlusButton] as? [String: Any] {
            plusButtonShowsSelection = (plusButtonAttributes[CYLPlusButtonShowsSelection] as? NSNumber)?.boolValue ?? false
            // [EN] The plus button's page by identifier: resolved like a tab's page. [CN] 按标识指定的 PlusButton 页面：与 Tab 的页面一样解析。
            if let plusPageIdentifier = plusButtonAttributes[CYLTabBarItemPageIdentifier] as? String, !plusPageIdentifier.isEmpty {
                let pages = CYLTabBarPageRegistry.pages(
                    ofTabs: [[CYLTabBarItemPageIdentifier: plusPageIdentifier]],
                    registry: normalized[CYLTabBarControllerPageRegistry] as? CYLTabBarPageProviding,
                    resolver: cylConfigurationPageProvider(normalized[CYLTabBarControllerPageResolver]),
                    lookupOrder: Self.cylPageLookupOrder(of: normalized), keptTabs: nil, skipped: nil)
                if let page = pages.first {
                    if (page.title ?? "").isEmpty, let plusTitle = plusButtonAttributes[CYLTabBarItemTitle] as? String, !plusTitle.isEmpty {
                        page.title = plusTitle
                    }
                    plusButtonAttributes[CYLConfigurationPlusButtonPageKey] = page
                    if plusButtonAttributes[CYLPlusButtonIndexInTabBar] == nil {
                        plusButtonAttributes[CYLPlusButtonIndexInTabBar] = tabBarItemsAttributes.count / 2
                    }
                }
            }
            CYLPlusButton.cyl_register(attributes: plusButtonAttributes,
                                       action: cylConfigurationPlusButtonAction(normalized[CYLTabBarControllerPlusButtonAction]), context: context)
        }

        self.imageInsets = imageInsets
        self.titlePositionAdjustment = titlePositionAdjustment
        self.tabBarItemsAttributes = tabBarItemsAttributes
        if plusButtonShowsSelection {
            objc_setAssociatedObject(self, CYLUtilsKeys.key("cyl_plusButtonShowsSelection"), NSNumber(value: true), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        pagesFromPageIdentifiers = !viewControllersFromCode
        self.pageRegistry = pageRegistry
        self.pageResolver = pageResolver
        self.pageLookupOrder = pageLookupOrder
        pagesByPageIdentifier = viewControllersFromCode ? nil
            : Self.cylPagesByPageIdentifier(ofPages: viewControllers ?? [], tabs: tabBarItemsAttributes)
        cylRecordDefaultStandardAppearance()
        // [EN] Step 1, with the setter: before `viewControllers`, which reads the style. [CN] 步骤 1，必须用 setter：在读取样式的 `viewControllers` 之前。
        cylSetTabBarStyleType(styleType)
        _ = cyl_tabBar
        // [EN] Step 2, with the setter: before `viewControllers`, which reads the context (the style and the plus button lookup). [CN] 步骤 2，必须用 setter：在 `viewControllers` 之前。
        cylApplyContext(context)
        if viewControllersFromCode {
            viewControllers = cylViewControllersByRemovingPlusSlot(viewControllers)
            var keptItems: [[String: Any]] = []
            var keptViewControllers: [UIViewController] = []
            let vcs = viewControllers ?? []
            for index in 0..<max(tabBarItemsAttributes.count, vcs.count) {
                let item = index < tabBarItemsAttributes.count ? tabBarItemsAttributes[index] : nil
                if let item, (item[CYLConfigurationValues.excludedKey] as? NSNumber)?.boolValue == true {
                    skippedTabs.add(CYLTabBarSkippedTab.skippedTab(
                        with: .excluded, pageIdentifier: CYLTabBarPageRegistry.pageIdentifier(ofTab: item), attributes: item,
                        detail: item[CYLConfigurationValues.exclusionReasonKey] as? String))
                    continue
                }
                if let item { keptItems.append(item) }
                if index < vcs.count { keptViewControllers.append(vcs[index]) }
            }
            tabBarItemsAttributes = keptItems
            viewControllers = keptViewControllers
            self.tabBarItemsAttributes = keptItems
        }
        self.skippedTabs = (skippedTabs as? [CYLTabBarSkippedTab]) ?? []
        // [EN] Step 3, with the setter: after the style (the flat tab bar uses KVC). [CN] 步骤 3，必须用 setter：在样式之后（扁平 TabBar 使用 KVC）。
        self.viewControllers = viewControllers
        cylAdoptPendingPages()
        if let animationSpeed = normalized[CYLTabBarControllerTabBarItemAnimationSpeed] as? NSNumber {
            tabBarItemAnimationSpeed = CGFloat(animationSpeed.doubleValue)
        }
        if let userInterfaceStyle = normalized[CYLTabBarControllerUserInterfaceStyle] as? NSNumber {
            overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: userInterfaceStyle.intValue) ?? .unspecified
        }
        if let tapAnimation = normalized[CYLTabBarControllerTabButtonTapAnimation] as? NSNumber {
            cyl_tabButtonTapAnimationType = CYLTabButtonTapAnimationType(rawValue: tapAnimation.intValue) ?? .none
        }
        if let swipeToSwitchTab = normalized[CYLTabBarControllerSwipeToSwitchTab] as? NSNumber {
            cyl_swipeToSwitchTabEnabled = swipeToSwitchTab.boolValue
        }
        if let loginRequired = normalized[CYLTabBarControllerLoginRequiredTabBarItemIdentifiers] as? [String] {
            cyl_loginRequiredTabBarItemIdentifiers = loginRequired
        }
        if let unloads = normalized[CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning] as? NSNumber {
            unloadsUnselectedViewsOnMemoryWarning = unloads.boolValue
        }
        if let keepsLoaded = normalized[CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers] as? [String] {
            cyl_keepsLoadedTabBarItemIdentifiers = keepsLoaded
        }
        cylApplyConfigurationThemes(normalized)
    }

    /**
     * [EN] The style: on iOS 27, the default style becomes FlatDesign when the app asks for the compatibility design
     *      (`UIDesignRequiresCompatibility`); FlatDesign is the only style that needs it.
     * [CN] 样式：iOS 27 上，App 要求兼容设计（`UIDesignRequiresCompatibility`）时，默认样式变为扁平样式；只有扁平样式需要它。
     */
    func cylSetTabBarStyleType(_ requested: CYLTabBarStyleType) {
        var styleType = requested
        if #available(iOS 27.0, *), styleType == .default,
           (Bundle.main.object(forInfoDictionaryKey: "UIDesignRequiresCompatibility") as? NSNumber)?.boolValue == true {
            styleType = .flatDesign
        }
        noNeedUIDesignCompatibility = styleType != .flatDesign
        tabBarStyleType = styleType
    }

    // MARK: - Adding a tab (system styles)

    /**
     * [EN] Adds the tab of `viewController` in the system styles (classic, Liquid Glass): title, resting images, the per-tab image
     *      insets and offsets (which win over the controller's and are remembered on the item, #475, #95), the animation file, then the
     *      view controller as a child. The FlatDesign counterpart is `-addOneChildViewController:idx:WithTitle:…`.
     * [CN] 在系统样式（经典、液态玻璃）下添加 `viewController` 的 Tab：标题、静止图片、单个 Tab 的图片内边距与偏移（优先于控制器的设置，并记录在 item 上，#475、#95）、
     *      动画文件，最后把控制器作为子控制器添加。扁平样式的对应方法是 `-addOneChildViewController:idx:WithTitle:…`。
     */
    @objc(addOneChildViewController:WithTitle:normalImageInfo:selectedImageInfo:titlePositionAdjustment:imagePositionAdjustment:imageInsets:lottieURL:lottieSizeValue:)
    func cylAddOneChildViewController(_ viewController: UIViewController, withTitle title: String?, normalImageInfo: Any?, selectedImageInfo: Any?,
                                      titlePositionAdjustment: UIOffset, imagePositionAdjustment: UIOffset, imageInsets: UIEdgeInsets,
                                      lottieURL: URL?, lottieSizeValue: NSValue?) {
        guard tabBarStyleType != .flatDesign else {
            return
        }
        let contentTabBarItem = viewController.cyl_getViewControllerInsteadOfNavigation().tabBarItem
        viewController.tabBarItem.title = title
        contentTabBarItem?.title = title
        let normalImage = normalImageInfo.flatMap { UIImage.cyl_imageNamed($0) }
        viewController.tabBarItem.image = Self.cylRestingTabBarItemImage(normalImage, for: viewController.tabBarItem, selected: false)
        let selectedImage = selectedImageInfo.flatMap { UIImage.cyl_imageNamed($0) }
        viewController.tabBarItem.selectedImage = Self.cylRestingTabBarItemImage(selectedImage, for: viewController.tabBarItem, selected: true)
        viewController.tabBarItem.imageInsets = imageInsets == .zero ? self.imageInsets : imageInsets
        CYLRememberItemImageInsets(viewController.tabBarItem, imageInsets)
        let offset = titlePositionAdjustment == .zero ? self.titlePositionAdjustment : titlePositionAdjustment
        CYLRememberItemTitlePositionAdjustment(viewController.tabBarItem, titlePositionAdjustment)
        cylApplyTitlePositionAdjustment(offset, to: viewController.tabBarItem)
        viewController.tabBarItem.cyl_imagePositionAdjustment = imagePositionAdjustment == .zero ? self.imagePositionAdjustment : imagePositionAdjustment
        if let lottieURL {
            tabBarItemAnimationURLs.add(lottieURL)
            viewController.tabBarItem.cyl_tabBarItemAnimationURL = lottieURL
            contentTabBarItem?.cyl_tabBarItemAnimationURL = lottieURL
            if let size = CYLConstants.cyl_tabBarItemAnimationSizeValue(lottieSizeValue, fromNormalImage: normalImage) {
                tabBarItemAnimationSizes.add(size)
                viewController.tabBarItem.cyl_tabBarItemAnimationSizeValue = size
                contentTabBarItem?.cyl_tabBarItemAnimationSizeValue = size
            }
        }
        addChild(viewController)
    }
}

