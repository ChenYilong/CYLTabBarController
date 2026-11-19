//
//  CYLTabBarController+CYLTabBarItemUpdate.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The FlatDesign side of the in-place update, implemented in the FlatDesign subspec
 *      (CYLFlatDesignTabBar-ObjectiveC/Swift/CYLTabBarController+CYLFlatDesign.swift). Optional: without that subspec nothing
 *      answers, and the calls return nil, as the `#if CYL_FLATDESIGN_AVAILABLE` blocks they replace did nothing.
 * [CN] 原地更新的扁平样式部分，由扁平样式子库实现。可选：没有该子库时无人响应，调用返回 nil，与它们取代的 `#if CYL_FLATDESIGN_AVAILABLE` 代码块相同。
 */
@objc protocol CYLFlatDesignTabBarItemUpdating {
    /// [EN] Sets what is given on the tab's FlatDesign item; NO when the tab has none. [CN] 设置该 Tab 扁平样式 item 的给定属性；没有该 item 时返回 NO。
    @objc(cyl_flatDesignUpdateTabBarItemOfViewController:title:image:selectedImage:)
    optional func cylFlatDesignUpdateTabBarItem(of viewController: UIViewController, title: String?, image: UIImage?,
                                                selectedImage: UIImage?) -> Bool
    /// [EN] The tab's FlatDesign item plays `URL`. [CN] 该 Tab 的扁平样式 item 播放 `URL`。
    @objc(cyl_flatDesignSetAnimationURL:ofViewController:)
    optional func cylFlatDesignSetAnimationURL(_ URL: URL, of viewController: UIViewController)
}

/**
 * [EN] The keys of the selected title (FIX: issue #433), selector-based, shared with CYLTabBarController.m.
 * [CN] 选中标题的 key（FIX: issue #433），基于 selector，与 CYLTabBarController.m 共用。
 */
private enum CYLSelectedTitleKeys {
    static let selectedTitle = CYLUtilsKeys.key("cyl_tabBarItemSelectedTitle")
    static let normalTitle = CYLUtilsKeys.key("cyl_tabBarItemNormalTitle")
}

// MARK: - Selected title (FIX: issue #433)

/**
 * FIX: issue #433
 * [EN] Remembers the tab's `CYLTabBarItemSelectedTitle` and its normal title on the view controller, or forgets them when the
 *      attributes have no selected title (tabs set up again without it). C name kept for CYLTabBarController.m.
 * [CN] 在控制器上记录 Tab 的 `CYLTabBarItemSelectedTitle` 与普通标题；属性中没有选中标题时清除。保留 C 名称供 CYLTabBarController.m 使用。
 */
@_cdecl("CYLRememberTabBarItemSelectedTitle")
func cylRememberTabBarItemSelectedTitle(_ viewController: UIViewController?, _ attributes: NSDictionary?, _ normalTitle: NSString?) {
    guard let viewController else {
        return
    }
    let selectedTitle = attributes?[CYLTabBarItemSelectedTitle] as? String
    objc_setAssociatedObject(viewController, CYLSelectedTitleKeys.selectedTitle, selectedTitle, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    objc_setAssociatedObject(viewController, CYLSelectedTitleKeys.normalTitle, selectedTitle != nil ? ((normalTitle as String?) ?? "") : nil,
                             .OBJC_ASSOCIATION_COPY_NONATOMIC)
}

/**
 * FIX: issue #433
 * [EN] Shows the selected title on the selected tab and the normal title on the others. Idempotent and cheap: only tabs that
 *      have a `CYLTabBarItemSelectedTitle` are touched, and a title is set only when it changes. FlatDesign sets the title of
 *      its own item; the classic style and Liquid Glass set `tabBarItem.title` (and the navigation controller's root's).
 * [CN] 选中的 Tab 显示选中标题，其他 Tab 显示普通标题。可重复调用、开销很小：只处理设置了 `CYLTabBarItemSelectedTitle` 的 Tab，标题变化时才设置。
 *      FlatDesign 设置其自身 item 的标题；经典样式与液态玻璃设置 `tabBarItem.title`（以及导航控制器根控制器的）。
 */
@_cdecl("CYLApplyTabBarItemSelectedTitles")
func cylApplyTabBarItemSelectedTitles(_ tabBarController: CYLTabBarController?) {
    guard let tabBarController else {
        return
    }
    let selectedViewController = tabBarController.selectedViewController
    let flatDesign = tabBarController.tabBarStyleType == .flatDesign
    for viewController in tabBarController.viewControllers ?? [] {
        guard let selectedTitle = objc_getAssociatedObject(viewController, CYLSelectedTitleKeys.selectedTitle) as? String else {
            continue
        }
        let normalTitle = objc_getAssociatedObject(viewController, CYLSelectedTitleKeys.normalTitle) as? String ?? ""
        let title = viewController === selectedViewController ? selectedTitle : normalTitle
        if flatDesign {
            _ = tabBarController.cylFlatDesignUpdating.cylFlatDesignUpdateTabBarItem?(of: viewController, title: title, image: nil,
                                                                                      selectedImage: nil)
            continue
        }
        if viewController.tabBarItem.title != title {
            viewController.tabBarItem.title = title
        }
        let contentViewController = viewController.cyl_getViewControllerInsteadOfNavigation()
        if contentViewController !== viewController, contentViewController.tabBarItem.title != title {
            contentViewController.tabBarItem.title = title
        }
    }
}

// MARK: - Icon rendering mode (FIX: issue #787)

/**
 * [EN] The animation file a tab's attributes give under the generic keys or any type's own keys, whether or not that type's
 *      engine is in the build (`CYLAnimationAttributesValue()` of the CYLAnimatedItem pod). C name kept for CYLTabBarController.m.
 * [CN] Tab 属性通过通用 key 或任一类型自己的 key 给出的动画文件，与该类型的引擎是否参与构建无关。保留 C 名称供 CYLTabBarController.m 使用。
 */
@_cdecl("CYLTabBarItemAnimationURLOfAnyType")
func cylTabBarItemAnimationURLOfAnyType(_ attributes: NSDictionary?) -> NSURL? {
    let dictionary = attributes as? [AnyHashable: Any]
    let value = CYLAnimationAttributesValue(dictionary, CYLTabBarAnimationURL)
    if let URL = value as? URL {
        return URL as NSURL
    }
    if let string = value as? String, !string.isEmpty {
        return NSURL(string: string)
    }
    if let path = CYLAnimationAttributesValue(dictionary, CYLTabBarAnimationFilePath) as? String, !path.isEmpty {
        return NSURL(fileURLWithPath: path)
    }
    return nil
}

extension CYLTabBarController {

    var cylFlatDesignUpdating: CYLFlatDesignTabBarItemUpdating {
        unsafeBitCast(self, to: CYLFlatDesignTabBarItemUpdating.self)
    }

    /**
     * FIX: issue #787
     * [EN] `image` in `renderingMode`, keeping its dark image: `-imageWithRenderingMode:` alone returns the current appearance
     *      only, so a tab with `CYLTabBarItemDarkImage` stayed light in Dark Mode. Both appearances are converted and combined.
     * [CN] 以 `renderingMode` 返回 `image`，并保留其深色图片：单独调用 `-imageWithRenderingMode:` 只返回当前外观的那张。两种外观分别转换后重新合成。
     */
    private static func cylImage(_ image: UIImage, renderingMode: UIImage.RenderingMode) -> UIImage {
        let asset = image.imageAsset
        if let light = asset?.image(with: UITraitCollection(userInterfaceStyle: .light)),
           let dark = asset?.image(with: UITraitCollection(userInterfaceStyle: .dark)), light != dark,
           let combined = UIImage.cyl_image(withLight: light.withRenderingMode(renderingMode), dark: dark.withRenderingMode(renderingMode)) {
            return combined
        }
        return image.withRenderingMode(renderingMode)
    }

    /**
     * FIX: issue #787
     * [EN] A tab's images in its `CYLTabBarItemIconRenderingMode`: "template" makes both images templates (the selected one falls
     *      back to the normal one, so one image is enough), "original" keeps their colors; otherwise the image infos are
     *      returned as they are. Returns `@[normal, selected]`, `NSNull` for a missing one.
     * [CN] 按 Tab 的 `CYLTabBarItemIconRenderingMode` 处理其图片："template" 把两张图片都设为模板（没有选中图片时使用普通图片），"original"
     *      保持原色；否则原样返回。返回 `@[normal, selected]`，缺少的一项为 `NSNull`。
     */
    @objc(cyl_imageInfosOfAttributes:applyingIconRenderingModeToImageInfo:selectedImageInfo:)
    static func cylImageInfos(of attributes: [String: Any], applyingIconRenderingModeTo normalInfo: Any?, selectedImageInfo selectedInfo: Any?) -> [Any] {
        var normal: Any? = normalInfo
        var selected: Any? = selectedInfo
        let renderingMode: UIImage.RenderingMode
        switch attributes[CYLTabBarItemIconRenderingMode] as? String {
        case "template": renderingMode = .alwaysTemplate
        case "original": renderingMode = .alwaysOriginal
        default: return [normal ?? NSNull(), selected ?? NSNull()]
        }
        let normalImage = normal.flatMap { UIImage.cyl_imageNamed($0) }
        var selectedImage = selected.flatMap { UIImage.cyl_imageNamed($0) }
        if selectedImage == nil && renderingMode == .alwaysTemplate {
            selectedImage = normalImage
        }
        if let normalImage {
            normal = cylImage(normalImage, renderingMode: renderingMode)
        }
        if let selectedImage {
            selected = cylImage(selectedImage, renderingMode: renderingMode)
        }
        return [normal ?? NSNull(), selected ?? NSNull()]
    }
}

// MARK: - Update a tab item in place (issue #601)

/**
 * [EN] In-place updates of a tab's attributes (title, selected title, images, colors, network icons, animation), translated
 *      from Objective-C (docs/Swift-Migration.md, step 73). Selectors are unchanged; the public methods are declared in the
 *      category `CYLTabBarController (CYLTabBarItemUpdate)` of CYLTabBarController.h.
 * [CN] Tab 属性的原地更新（标题、选中标题、图片、颜色、网络图标、动画），已从 Objective-C 翻译（docs/Swift-Migration.md，第 73 步）。selector 不变；
 *      公开方法声明在 CYLTabBarController.h 的 `CYLTabBarController (CYLTabBarItemUpdate)` 分类中。
 */
extension CYLTabBarController {

    private static let cylPlusSlotPlaceholderKey = "CYLTabBarItemPlusSlotPlaceholder"

    /// [EN] The app's tab item attributes as stored. [CN] 存储的 Tab item 属性。
    private var cylStoredTabBarItemsAttributes: [[AnyHashable: Any]] {
        (tabBarItemsAttributes as [Any]? ?? []).compactMap { $0 as? [AnyHashable: Any] }
    }

    @objc(updateTabBarItemForViewController:attributes:)
    @discardableResult
    open func updateTabBarItem(for viewController: UIViewController, attributes: [String : Any] = [:]) -> Bool {
        let viewControllers = self.viewControllers ?? []
        var index = viewControllers.firstIndex { $0 === viewController }
        if index == nil {
            index = viewControllers.firstIndex { $0.cyl_getViewControllerInsteadOfNavigation() === viewController }
        }
        guard let index else {
            return false
        }
        return updateTabBarItem(at: UInt(index), attributes: attributes)
    }

    /**
     * [EN] FIX: placeholder count mismatch — one entry per tab, none for the slot: an array read back from
     *      `tabBarItemsAttributes` (Liquid Glass, FlatDesign) carries the slot's own entry, which used to be given to the tab
     *      after the slot, and every later tab took the entry before its own.
     * [CN] FIX：占位导致的数量不匹配——每个 Tab 一项，slot 不占项：从 `tabBarItemsAttributes` 读回的数组带有 slot 自己的一项，以前会被分给 slot
     *      之后的 Tab，之后每个 Tab 都取到前一个 Tab 的属性。
     */
    @objc(updateTabBarItemsWithAttributes:)
    open func updateTabBarItems(withAttributes tabBarItemsAttributes: [[String : Any]]) {
        let entries = tabBarItemsAttributes.filter { ($0[Self.cylPlusSlotPlaceholderKey] as? NSNumber)?.boolValue != true }
        var attributesIndex = 0
        for (index, viewController) in (viewControllers ?? []).enumerated() where attributesIndex < entries.count {
            // [EN] The plus button's tab has no entry. [CN] PlusButton 的 Tab 不占项。
            if cylPrivate.cylIsPlusSlotViewController(viewController) {
                continue
            }
            updateTabBarItem(at: UInt(index), attributes: entries[attributesIndex])
            attributesIndex += 1
        }
    }

    @objc(updateTabBarItemAtIndex:attributes:)
    @discardableResult
    open func updateTabBarItem(at index: UInt, attributes: [String : Any] = [:]) -> Bool {
        let count = UInt(viewControllers?.count ?? 0)
        let oldTitle = index < count ? tabBarItemAttributes(at: index)?[CYLTabBarItemTitle] : nil
        guard cylApplyTabBarItemUpdate(at: index, attributes: attributes) else {
            return false
        }
        // [EN] After the tab shows the change: the title and icon notifications for their keys, then one for every change.
        // [CN] Tab 显示变化之后：标题与图标 key 分别发送标题、图标通知，然后每次变化发送一次通用通知。
        if attributes[CYLTabBarItemTitle] != nil || attributes[CYLTabBarItemSelectedTitle] != nil {
            let current = tabBarItemAttributes(at: index) ?? [:]
            var titleInfo: [AnyHashable: Any] = [CYLTabBarItemTitle: current[CYLTabBarItemTitle] ?? ""]
            titleInfo[CYLTabBarItemSelectedTitle] = current[CYLTabBarItemSelectedTitle]
            titleInfo[CYLTabBarItemOldTitleKey] = oldTitle
            titleInfo[CYLTabBarItemChangedAttributesKey] = attributes.filter { $0.key == CYLTabBarItemTitle || $0.key == CYLTabBarItemSelectedTitle }
            cylPostTabBarItemNotification(.CYLTabBarItemTitleDidChange, at: index, extra: titleInfo)
        }
        let iconAttributes = Self.cylIconAttributes(of: attributes)
        if !iconAttributes.isEmpty {
            cylPostTabBarItemNotification(.CYLTabBarItemIconDidChange, at: index, extra: [CYLTabBarItemChangedAttributesKey: iconAttributes])
        }
        cylPostTabBarItemNotification(.CYLTabBarItemDidChange, at: index, extra: [CYLTabBarItemChangedAttributesKey: attributes])
        return true
    }

    /**
     * FIX: issue #216
     * [EN] The animation keys of an in-place update: the new file is bound to its library and its colors are registered (as at
     *      setup), the tab items and `tabBarItemAnimationURLs` learn the new file, and every tab button of the tab (two with
     *      Liquid Glass) swaps its animation view, keeping the playback state. Without an animation library the keys are
     *      logged and ignored.
     * [CN] 原地更新中的动画 key：新文件绑定到其动画库并注册颜色（与初始设置相同），Tab item 与 `tabBarItemAnimationURLs` 记录新文件，该 Tab 的每个按钮
     *      （液态玻璃为两个）替换动画视图并保留播放状态。没有动画库时打印日志并忽略。
     */
    private func cylUpdateAnimation(of viewController: UIViewController, attributes: [String: Any], newAttributes: [String: Any]) {
        // [EN] The generic keys and every library's aliases share these prefixes. [CN] 通用 key 与各动画库的别名都以这些前缀开头。
        let prefixes = ["CYLTabBarAnimation", "CYLTabBarLottie", "CYLTabBarPAG", "CYLTabBarRive"]
        guard attributes.keys.contains(where: { key in prefixes.contains { key.hasPrefix($0) } }) else {
            return
        }
        guard cylTabBarItemAnimationGetServiceEntryPoint() != nil else {
            CYLAnimationWarnMissingEngine(newAttributes, cylTabBarItemAnimationURLOfAnyType(newAttributes as NSDictionary) as URL?)
            NSLog("[CYL #216] tab bar item attributes carry an animation key (%@) but no animation library is linked: add pod 'CYLTabBarController/Lottie', 'CYLTabBarController/PAG' or 'CYLTabBarController/Rive'. The key is ignored and the tab keeps its image.",
                  attributes.keys.joined(separator: ", "))
            return
        }
        var animationFilePath: NSString?
        guard let animationURL = cylTabBarItemAnimationURLFromAttributesEntryPoint(newAttributes as NSDictionary, &animationFilePath) as URL? else {
            // [EN] `CYLTabBarAnimationFilePath` is a full path: a bare file name finds nothing.
            // [CN] `CYLTabBarAnimationFilePath` 是完整路径：只写文件名时找不到文件。
            NSLog("[CYL #216] no animation file found at \"%@\": CYLTabBarAnimationFilePath is a full path; use CYLTabBarItemAttributesAddingAnimationFile() for a file name in a bundle.",
                  (animationFilePath as String?) ?? "")
            return
        }
        let sizeValue = cylTabBarItemAttributesAnimationValueEntryPoint(newAttributes as NSDictionary, CYLTabBarAnimationSize as NSString) as? NSValue
        let tabBarItem = viewController.tabBarItem!
        let rootTabBarItem = viewController.cyl_getViewControllerInsteadOfNavigation().tabBarItem
        let urls = cylPrivate.cylTabBarItemAnimationURLs()
        let sizes = cylPrivate.cylTabBarItemAnimationSizes()
        let oldURL = tabBarItem.cyl_tabBarItemAnimationURL ?? rootTabBarItem?.cyl_tabBarItemAnimationURL
        let oldIndex = oldURL.map { urls.index(of: $0) } ?? NSNotFound
        if oldIndex != NSNotFound {
            urls[oldIndex] = animationURL
            if let sizeValue, oldIndex < sizes.count {
                sizes[oldIndex] = sizeValue
            }
        } else {
            urls.add(animationURL)
            if let sizeValue {
                sizes.add(sizeValue)
            }
        }
        var items = [tabBarItem]
        if let rootTabBarItem, rootTabBarItem !== tabBarItem {
            items.append(rootTabBarItem)
        }
        for item in items {
            item.cyl_tabBarItemAnimationURL = animationURL
            if let sizeValue {
                item.cyl_tabBarItemAnimationSizeValue = sizeValue
            }
        }
        cylFlatDesignUpdating.cylFlatDesignSetAnimationURL?(animationURL, of: viewController)
        let size = sizeValue?.cgSizeValue ?? tabBarItem.cyl_tabBarItemAnimationSizeValue?.cgSizeValue ?? .zero
        for tabButton in cylTabButtons(of: viewController) {
            tabButton.cyl_replaceTabBarItemAnimation(with: animationURL, size: size, contentMode: tabBarItemAnimationViewContentMode())
        }
    }

    /**
     * [EN] The in-place update itself; `-updateTabBarItemAtIndex:attributes:` posts the notifications.
     * [CN] 原地更新本身；通知由 `-updateTabBarItemAtIndex:attributes:` 发送。
     */
    private func cylApplyTabBarItemUpdate(at index: UInt, attributes: [String: Any]) -> Bool {
        let viewControllers = self.viewControllers ?? []
        guard index < UInt(viewControllers.count), !attributes.isEmpty else {
            return false
        }
        let viewController = viewControllers[Int(index)]
        // [EN] The plus button's tab shows the plus button; a placeholder has nothing to show.
        // [CN] PlusButton 的 Tab 显示 PlusButton；占位没有内容可显示。
        if viewController.cyl_isPlaceholder || viewController === cylPrivate.cylContextPlusChildViewController() {
            return false
        }
        var stored = cylStoredTabBarItemsAttributes
        let attributesIndex = Int(cylTabBarItemsAttributesIndexOfViewController(at: index))
        var newAttributes: [String: Any] = [:]
        if attributesIndex < stored.count {
            for (key, value) in stored[attributesIndex] {
                if let key = key as? String { newAttributes[key] = value }
            }
        }
        newAttributes.merge(attributes) { _, new in new }
        // [EN] FIX: placeholder count mismatch — a tab's entry never takes the slot's marker, or it would be taken for the slot's
        //      entry and removed on the next `-setViewControllers:`.
        // [CN] FIX：占位导致的数量不匹配——Tab 的属性永远不带 slot 的标记，否则会被当成 slot 的属性，在下一次 `-setViewControllers:` 时被移除。
        newAttributes.removeValue(forKey: Self.cylPlusSlotPlaceholderKey)
        if attributesIndex < stored.count {
            stored[attributesIndex] = newAttributes
            cylPrivate.cylReplaceTabBarItemsAttributesStorage(stored)
        }
        // FIX: issue #433
        // [EN] A new normal or selected title is remembered, so a later selection change shows the new ones.
        // [CN] 记录新的普通标题或选中标题，之后切换选中时显示新的标题。
        let updatesSelectedTitle = attributes[CYLTabBarItemTitle] != nil || attributes[CYLTabBarItemSelectedTitle] != nil
        if updatesSelectedTitle {
            cylRememberTabBarItemSelectedTitle(viewController, newAttributes as NSDictionary, newAttributes[CYLTabBarItemTitle] as? NSString)
        }
        // [EN] Per-tab colors are applied on the next layout pass. [CN] 单个 Tab 的颜色在下一次布局时生效。
        let colorKeys = [CYLTabBarItemTitleColor, CYLTabBarItemSelectedTitleColor, CYLTabBarItemIconColor, CYLTabBarItemSelectedIconColor,
                         CYLTabBarItemSelectedBackgroundColor, CYLTabBarItemBackgroundColor, CYLTabBarItemTitleFont, CYLTabBarItemSelectedTitleFont]
        if isViewLoaded && colorKeys.contains(where: { attributes[$0] != nil }) {
            view.setNeedsLayout()
            cylUpdateSelectedBackgroundColorsOfTabButtons()
        }

        // [EN] As when the tab was set up (`-setViewControllers:`), so a dark image is combined with its light one (#620).
        // [CN] 与设置 Tab 时相同（`-setViewControllers:`），深色图片与浅色图片合成（#620）。
        let title = attributes[CYLTabBarItemTitle] as? String
        // FIX: issue #787 — a new rendering mode alone redraws both images. [CN] 只更新渲染方式时也重新绘制两张图片。
        let updatesRenderingMode = attributes[CYLTabBarItemIconRenderingMode] != nil
        let updatesImage = attributes[CYLTabBarItemImage] != nil || attributes[CYLTabBarItemDarkImage] != nil || updatesRenderingMode
        let updatesSelectedImage = attributes[CYLTabBarItemSelectedImage] != nil || attributes[CYLTabBarItemSelectedDarkImage] != nil || updatesRenderingMode
        var image: UIImage? = updatesImage
            ? UIImage.cyl_imageNamed(UIImage.cyl_image(withImageInfo: newAttributes[CYLTabBarItemImage], darkImageInfo: newAttributes[CYLTabBarItemDarkImage]))
            : nil
        var selectedImage: UIImage? = updatesSelectedImage
            ? UIImage.cyl_imageNamed(UIImage.cyl_image(withImageInfo: newAttributes[CYLTabBarItemSelectedImage],
                                                       darkImageInfo: newAttributes[CYLTabBarItemSelectedDarkImage]))
            : nil
        if updatesImage || updatesSelectedImage {
            // FIX: issue #787 — the tab's rendering mode applies to images updated in place too.
            let infos = Self.cylImageInfos(of: newAttributes, applyingIconRenderingModeTo: image, selectedImageInfo: selectedImage)
            image = infos[0] as? UIImage
            selectedImage = infos[1] as? UIImage
        }

        // FIX: issue #216 — an animation key (e.g. from a `CYLTabBarTheme`) replaces the tab's animation in place, in every style.
        cylUpdateAnimation(of: viewController, attributes: attributes, newAttributes: newAttributes)

        let loadsImageURLs = attributes[CYLTabBarItemImageURL] != nil || attributes[CYLTabBarItemSelectedImageURL] != nil
            || attributes[CYLTabBarItemImageURLSize] != nil
        if tabBarStyleType == .flatDesign {
            // [EN] Each change posts `CYLFlatDesignTabBarItemDidChange`, and its button lays itself out again.
            // [CN] 每次变化都会发送 `CYLFlatDesignTabBarItemDidChange`，其按钮随之重新布局。
            guard cylFlatDesignUpdating.cylFlatDesignUpdateTabBarItem?(of: viewController, title: title, image: image,
                                                                     selectedImage: selectedImage) == true else {
                return false
            }
            if let title {
                Self.cylApplyNavigationTitle(ofFollowingPage: viewController, title: title)
            }
            // FIX: issue #433 — the selected tab shows its selected title. [CN] 选中的 Tab 显示选中标题。
            if updatesSelectedTitle {
                cylApplyTabBarItemSelectedTitles(self)
            }
            if loadsImageURLs {
                cylLoadImageURLs(ofAttributes: newAttributes, at: index)
            }
            return true
        }
        // [EN] Liquid Glass and the system tab bar: `UITabBarItem` redraws its tab when a property changes.
        // [CN] 液态玻璃与系统 TabBar：`UITabBarItem` 的属性变化时会重绘其 Tab。
        var tabBarItems: [UITabBarItem] = [viewController.tabBarItem]
        if let rootTabBarItem = viewController.cyl_getViewControllerInsteadOfNavigation().tabBarItem, rootTabBarItem !== viewController.tabBarItem {
            tabBarItems.append(rootTabBarItem)
        }
        for tabBarItem in tabBarItems {
            if let title { tabBarItem.title = title }
            if let image { tabBarItem.image = Self.cylRestingTabBarItemImage(image, for: tabBarItem, selected: false) }
            if let selectedImage { tabBarItem.selectedImage = Self.cylRestingTabBarItemImage(selectedImage, for: tabBarItem, selected: true) }
        }
        if let title {
            Self.cylApplyNavigationTitle(ofFollowingPage: viewController, title: title)
        }
        // FIX: issue #433 — the selected tab shows its selected title. [CN] 选中的 Tab 显示选中标题。
        if updatesSelectedTitle {
            cylApplyTabBarItemSelectedTitles(self)
        }
        // FIX: issue #257, #522
        // [EN] An image-only tab that gets a title is no longer image-only: undo the automatic adjustment, or the title stays off
        //      screen. A tab whose title becomes empty gets it again.
        // [CN] 纯图标 Tab 设置标题后就不再是纯图标 Tab：撤销自动调整，否则标题会一直在屏幕外。标题被清空的 Tab 重新获得自动调整。
        if let title {
            if !title.isEmpty {
                cylRestoreImageOnlyTabItems(tabBarItems)
            } else if let tabBar = cyl_tabBar as? CYLTabBar, tabBar.tabImageViewDefaultOffset != 0 {
                offsetTabBarTabImageView(toFit: tabBar.tabImageViewDefaultOffset)
            }
        }
        // [EN] Liquid Glass may keep the tab buttons' previous layout until a tab is tapped: reload them as a tap does.
        // [CN] 液态玻璃可能保持 Tab 按钮原来的布局，直到点击某个 Tab：像点击一样重新加载它们。
        (tabBar as? CYLTabBar)?.cyl_reloadTabButtons()
        // [EN] Icons from the network replace the images once downloaded. [CN] 网络图标下载完成后覆盖图片。
        if loadsImageURLs {
            cylLoadImageURLs(ofAttributes: newAttributes, at: index)
        }
        return true
    }

    /**
     * FIX: issue #216
     * [EN] Removes `keys` from the attributes of the tab at `index`: a key a theme added that the app did not have. A title
     *      becomes empty again (an image-only tab), a selected title stops overriding the title, and colors and fonts fall back
     *      on the next layout pass.
     * [CN] 从第 `index` 个 Tab 的 attributes 中移除 `keys`：主题添加、App 原本没有的 key。标题恢复为空（纯图标 Tab），选中标题不再覆盖标题，颜色与字体
     *      在下一次布局时回退。
     */
    @objc(cyl_themeRemoveTabBarItemAttributeKeys:atIndex:)
    func cylThemeRemoveTabBarItemAttributeKeys(_ keys: [String], atIndex index: UInt) {
        let viewControllers = self.viewControllers ?? []
        guard index < UInt(viewControllers.count), !keys.isEmpty else {
            return
        }
        let attributesIndex = Int(cylTabBarItemsAttributesIndexOfViewController(at: index))
        guard attributesIndex < cylStoredTabBarItemsAttributes.count else {
            return
        }
        if keys.contains(CYLTabBarItemTitle) {
            updateTabBarItem(at: index, attributes: [CYLTabBarItemTitle: ""])
        }
        var stored = cylStoredTabBarItemsAttributes
        var attributes = stored[attributesIndex]
        keys.forEach { attributes.removeValue(forKey: $0) }
        stored[attributesIndex] = attributes
        cylPrivate.cylReplaceTabBarItemsAttributesStorage(stored)
        if keys.contains(CYLTabBarItemSelectedTitle) {
            cylRememberTabBarItemSelectedTitle(viewControllers[Int(index)], attributes as NSDictionary, attributes[CYLTabBarItemTitle] as? NSString)
            cylApplyTabBarItemSelectedTitles(self)
        }
        if isViewLoaded {
            view.setNeedsLayout()
            cylUpdateSelectedBackgroundColorsOfTabButtons()
        }
    }
}
