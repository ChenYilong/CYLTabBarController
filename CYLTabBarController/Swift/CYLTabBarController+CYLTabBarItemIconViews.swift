//
//  CYLTabBarController+CYLTabBarItemIconViews.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if canImport(CYLBadge)
import CYLBadge
#endif
/**
 * [EN] The associated object keys of the views shown in place of a tab's icon.
 * [CN] 替换 Tab 图标显示的视图所用的关联对象 key。
 */
private enum CYLTabBarItemIconViewKeys {
    /// [EN] The providers by view controller, on the controller. [CN] 按子控制器保存的 provider，存于控制器上。
    static let providers = CYLUtilsKeys.key("cyl_tabBarItemIconViewProviders")
    /// [EN] The installed views by look (NO unselected, YES selected), on a tab button. [CN] 按样式保存的已安装视图，存于 Tab 按钮上。
    static let iconViews = CYLUtilsKeys.key("cyl_tabBarItemIconViews")
    /// [EN] The provider that made them, on a tab button. [CN] 创建这些视图的 provider，存于 Tab 按钮上。
    static let installedProvider = CYLUtilsKeys.key("cyl_tabBarItemIconViewsProvider")
}

/**
 * [EN] A view of yours in place of a tab's icon (issue #601, `-setTabBarItemIconViewProvider:atIndex:`), and the resting
 *      first frame of an animated tab image. Translated from Objective-C (docs/Swift-Migration.md, step 66);
 *      `CYLTabBarController+CYLPrivate.h` declares what CYLTabBarController.m calls.
 * [CN] 用你自己的视图替换 Tab 的图标（issue #601，`-setTabBarItemIconViewProvider:atIndex:`），以及动画 Tab 图片停在第一帧。已从
 *      Objective-C 翻译（docs/Swift-Migration.md，第 66 步）；`CYLTabBarController+CYLPrivate.h` 声明 CYLTabBarController.m 调用的方法。
 */
extension CYLTabBarController {

    typealias CYLIconViewProvider = @convention(block) (Bool) -> UIView?

    // MARK: - Resting animated images

    /**
     * [EN] An animated image given as a tab's image (`CYLTabBarItemImage` with `+[UIImage cyl_animatedImageWithGIFData:]`, a GIF
     *      `CYLTabBarItemImageURL`) rests on its first frame until the tab is played, like an animation (docs/GIF-Animation.md):
     *      the item keeps the animated image and shows its first frame. Any other image is returned as it is.
     * [CN] 作为 Tab 图片传入的动图与动画一样，在 Tab 被播放之前停在第一帧：tabBarItem 保存动图，显示其第一帧。其他图片原样返回。
     */
    @objc(cyl_restingTabBarItemImage:forItem:selected:)
    static func cylRestingTabBarItemImage(_ image: UIImage?, for item: UITabBarItem?, selected: Bool) -> UIImage? {
        guard let item else {
            return image
        }
        let key = selected ? CYLAnimatedImageKeys.selectedImage : CYLAnimatedImageKeys.image
        guard let image, let frames = image.images, frames.count > 1, let first = frames.first else {
            objc_setAssociatedObject(item, key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return image
        }
        objc_setAssociatedObject(item, key, image, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return first.withRenderingMode(image.renderingMode)
    }

    // MARK: - Providers and tab buttons

    /// [EN] The icon view providers by view controller (weak). [CN] 按子控制器（弱引用）保存的图标视图 provider。
    @objc(cyl_tabBarItemIconViewProviders)
    func cylTabBarItemIconViewProviders() -> NSMapTable<UIViewController, AnyObject> {
        if let providers = objc_getAssociatedObject(self, CYLTabBarItemIconViewKeys.providers) as? NSMapTable<UIViewController, AnyObject> {
            return providers
        }
        let providers = NSMapTable<UIViewController, AnyObject>.weakToStrongObjects()
        objc_setAssociatedObject(self, CYLTabBarItemIconViewKeys.providers, providers, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return providers
    }

    /**
     * [EN] The tab buttons of `viewController`: the tab button, and with Liquid Glass (not FlatDesign, which has no selected
     *      layer although `+isLiquidGlassActive` is YES on iOS 26) the one in the selected layer (lens).
     * [CN] `viewController` 的 Tab 按钮：Tab 按钮本身，液态玻璃下（不是扁平样式：iOS 26 上它也让 `+isLiquidGlassActive` 为 YES，但没有选中图层）
     *      还有选中图层（放大镜）中的那个。
     */
    @objc(cyl_tabButtonsOfViewController:)
    func cylTabButtons(of viewController: UIViewController) -> [UIControl] {
        let isFlatDesign = tabBarStyleType == .flatDesign
        guard let tabButton = isFlatDesign ? viewController.cyl_tabButton : viewController.tabBarItem.cyl_tabButton else {
            return []
        }
        let isLiquidGlassTabBar = !isFlatDesign && CYLConstants.isLiquidGlassActive()
        if isLiquidGlassTabBar, let selectedLayerButton = tabButton.cylPlatterSelected(), selectedLayerButton !== tabButton {
            return [tabButton, selectedLayerButton]
        }
        return [tabButton]
    }

    // MARK: - Updating the icon views

    /**
     * [EN] After layout and selection changes, on the next run loop: UIKit has updated the tab buttons by then.
     * [CN] 布局与选中变化后，在下一个 run loop 执行：此时 UIKit 已更新 Tab 按钮。
     */
    @objc(cyl_setNeedsUpdateTabBarItemIconViews)
    func cylSetNeedsUpdateTabBarItemIconViews() {
        guard cylTabBarItemIconViewProviders().count > 0 else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            self?.cylUpdateTabBarItemIconViews()
        }
    }

    /// [EN] Installs, removes or shows the icon views of every tab with a provider. [CN] 安装、移除或显示所有设置了 provider 的 Tab 的图标视图。
    @objc(cyl_updateTabBarItemIconViews)
    func cylUpdateTabBarItemIconViews() {
        for case let viewController as UIViewController in cylTabBarItemIconViewProviders().keyEnumerator().allObjects {
            cylUpdateTabBarItemIconViews(of: viewController)
        }
    }

    /**
     * [EN] Tells a tab button that is a CYLAnimatedItemView (FlatDesign) to keep its icon hidden, by key: Core does not import
     *      the component. Nothing for UIKit's tab buttons.
     * [CN] 告诉作为 CYLAnimatedItemView 的 Tab 按钮（扁平样式）保持图标隐藏，按 key 设置：Core 不导入该组件。UIKit 的 Tab 按钮不做处理。
     */
    private static func cylSetAnimatedItemIconHidden(_ tabButton: UIControl, _ hidden: Bool) {
        if tabButton.responds(to: NSSelectorFromString("setIconHidden:")) {
            tabButton.setValue(hidden, forKey: "iconHidden")
        }
    }

    @objc(cyl_updateTabBarItemIconViewsOfViewController:)
    func cylUpdateTabBarItemIconViews(of viewController: UIViewController) {
        // [EN] A block read back from the map table does not cast with `as?`. [CN] 从 map table 读回的 block 无法用 `as?` 转换。
        let providerObject = cylTabBarItemIconViewProviders().object(forKey: viewController)
        let provider = providerObject.map { unsafeBitCast($0, to: CYLIconViewProvider.self) }
        let tabButtons = cylTabButtons(of: viewController)
        let isSelected = viewController === selectedViewController
        for (index, tabButton) in tabButtons.enumerated() {
            cylUpdateIconViews(of: tabButton, provider: provider, providerObject: providerObject,
                               selectedLayer: tabButtons.count > 1 ? index == 1 : nil, isSelected: isSelected)
        }
    }

    /**
     * [EN] One tab button: the views of a new provider are installed (one look per Liquid Glass layer, both looks on other
     *      styles), those of a removed one taken away (the tab's own icon and badge come back), and the right look shown,
     *      under a cover hidden.
     * [CN] 单个 Tab 按钮：安装新 provider 的视图（液态玻璃每个图层一种样式，其他样式两种都有），移除已删除 provider 的视图（Tab 自身的图标与角标恢复），
     *      并显示正确的样式，有封面时隐藏。
     */
    private func cylUpdateIconViews(of tabButton: UIControl, provider: CYLIconViewProvider?, providerObject: AnyObject?,
                                    selectedLayer: Bool?, isSelected: Bool) {
        var iconViews = objc_getAssociatedObject(tabButton, CYLTabBarItemIconViewKeys.iconViews) as? [Bool: UIView]
        let installedProvider = objc_getAssociatedObject(tabButton, CYLTabBarItemIconViewKeys.installedProvider) as AnyObject?
        let lottieView = tabButton.cylTabBarItemAnimationView()
        // [EN] A cover over the tab button (e.g. a logo over the first tab) hides its other views, the tab's own icon too.
        // [CN] 覆盖 Tab 按钮的封面（如第一个 Tab 上的 Logo）会隐藏按钮中的其他视图，包括 Tab 自身的图标。
        let isCovered = tabButton.subviews.contains { $0.cyl_tabButtonCoverView && !$0.cylIsInvisiable() }
        if installedProvider !== providerObject {
            // [EN] Another provider, or none: remove the views of the previous one. [CN] 换了 provider 或已移除：移除之前的视图。
            iconViews?.values.forEach { $0.removeFromSuperview() }
            iconViews = nil
            objc_setAssociatedObject(tabButton, CYLTabBarItemIconViewKeys.iconViews, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(tabButton, CYLTabBarItemIconViewKeys.installedProvider, providerObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if provider == nil {
                // [EN] The tab's own icon and its badge come back, unless the cover hides them. [CN] Tab 自身的图标及其角标恢复，除非被封面隐藏。
                cylSetTabImageView(tabButton.cylTabImageView(), lottieView: lottieView, replacedByIconView: false)
                Self.cylSetAnimatedItemIconHidden(tabButton, false)
                if !isCovered {
                    tabButton.cylTabImageView()?.isHidden = lottieView != nil
                    lottieView?.isHidden = false
                }
                return
            }
        }
        guard let provider else {
            return
        }
        let views = iconViews ?? cylInstallIconViews(on: tabButton, provider: provider, selectedLayer: selectedLayer)
        guard !views.isEmpty else {
            return
        }
        // [EN] The tab's own icon stays hidden (the system may show it again when the tab changes); its badge stays visible
        //      above it. A CYLAnimatedItemView (FlatDesign) shows its icon again on its own updates unless told.
        // [CN] Tab 自身图标保持隐藏（切换 Tab 时系统可能重新显示它）；其角标仍显示在它上方。CYLAnimatedItemView（扁平样式）在自身更新时会重新显示图标，
        //      除非被告知。
        tabButton.cylTabImageView()?.isHidden = true
        lottieView?.isHidden = true
        Self.cylSetAnimatedItemIconHidden(tabButton, true)
        // [EN] Under a cover the badge stays as the cover left it (cleared). [CN] 有封面时角标保持封面设置的状态（已清除）。
        cylSetTabImageView(tabButton.cylTabImageView(), lottieView: lottieView, replacedByIconView: !isCovered)
        // [EN] Below the tab's own icon, or the subview of the tab button holding it (Liquid Glass), so the badge shown above
        //      that icon stays above this view too.
        // [CN] 位于 Tab 自身图标（或液态玻璃中包含它的 Tab 按钮子视图）之下，使该图标上方的角标也位于此视图之上。
        var iconHolder: UIView? = lottieView ?? tabButton.cylTabImageView()
        while let holder = iconHolder, holder.superview !== tabButton {
            iconHolder = holder.superview
        }
        if let iconHolder {
            views.values.filter { $0.superview === tabButton }.forEach { tabButton.insertSubview($0, belowSubview: iconHolder) }
        }
        if let unselectedView = views[false], let selectedView = views[true] {
            unselectedView.isHidden = isCovered || isSelected
            selectedView.isHidden = isCovered || !isSelected
        } else {
            views.values.forEach { $0.isHidden = isCovered }
        }
    }

    /**
     * [EN] Creates the views of `provider` on `tabButton`: on Liquid Glass one look per layer (`selectedLayer`), otherwise
     *      both looks on the same button.
     * [CN] 在 `tabButton` 上创建 `provider` 的视图：液态玻璃下每个图层一种样式（`selectedLayer`），否则两种样式都在同一个按钮上。
     */
    private func cylInstallIconViews(on tabButton: UIControl, provider: CYLIconViewProvider, selectedLayer: Bool?) -> [Bool: UIView] {
        var views: [Bool: UIView] = [:]
        for look in selectedLayer.map({ [$0] }) ?? [false, true] {
            guard let iconView = provider(look) else {
                continue
            }
            iconView.isUserInteractionEnabled = false
            iconView.cyl_tabBarItemIconView = true
            tabButton.cylReplaceTabImageView(withNewView: iconView, show: true)
            if iconView.superview === tabButton {
                views[look] = iconView
            }
        }
        objc_setAssociatedObject(tabButton, CYLTabBarItemIconViewKeys.iconViews, views, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return views
    }

    /**
     * [EN] Marks the tab's own icon as hidden for the view shown in its place, or not, and moves its badge accordingly: onto
     *      an overlay above it, or back into it.
     * [CN] 标记 Tab 自身的图标是否因替换显示而隐藏，并相应移动其角标：移到其上方的浮层，或移回图标中。
     */
    @objc(cyl_setTabImageView:lottieView:replacedByIconView:)
    func cylSetTabImageView(_ tabImageView: UIView?, lottieView: UIView?, replacedByIconView replaced: Bool) {
        for host in [tabImageView, lottieView].compactMap({ $0 }) where host.cyl_badgeHostReplacedByIconView != replaced {
            host.cyl_badgeHostReplacedByIconView = replaced
            host.cylRefreshBadge()
        }
    }
}

// MARK: - Tab notifications and icon setters (docs/Swift-Migration.md, step 67)

/**
 * [EN] `CYLTabBarController (CYLTabBarItemIcons)`: a tab's icon replaced at run time (issue #601), by a view of yours or by
 *      an image from any source, and the tab notifications. Translated from Objective-C (docs/Swift-Migration.md, step 67);
 *      the three public methods are declared in that category of CYLTabBarController.h, with their selectors unchanged.
 * [CN] `CYLTabBarController (CYLTabBarItemIcons)`：运行时替换 Tab 的图标（issue #601），使用你自己的视图或任意来源的图片，以及 Tab 通知。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 67 步）；三个公开方法声明在 CYLTabBarController.h 的该分类中，selector 不变。
 */
extension CYLTabBarController {

    /**
     * [EN] Posts a tab notification. The object is the tab's page; userInfo names exactly what changed: the tab bar
     *      controller, the tab's index, its entry in `viewControllers`, its identifier, its tab bar item (`cyl_tabBarItem` on
     *      FlatDesign), plus `extra`.
     * [CN] 发送 Tab 通知。object 为该 Tab 的页面；userInfo 精确指出变化的对象：TabBar 控制器、Tab 下标、它在 `viewControllers` 中的控制器、
     *      它的 ID、它的 tabBarItem（扁平样式为 `cyl_tabBarItem`），以及 `extra`。
     */
    @objc(cyl_postTabBarItemNotification:atIndex:extra:)
    func cylPostTabBarItemNotification(_ name: NSNotification.Name, at index: UInt, extra: [AnyHashable: Any]?) {
        let viewControllers = self.viewControllers ?? []
        guard Int(index) < viewControllers.count else {
            return
        }
        let viewController = viewControllers[Int(index)]
        let page = viewController.cylGetViewControllerInsteadOfNavigation()
        var userInfo: [AnyHashable: Any] = [
            cylTabBarControllerKey: self,
            cylTabBarItemIndexKey: NSNumber(value: index),
            cylTabBarItemViewControllerKey: viewController,
        ]
        // [EN] The tab's identifier (`CYLTabBarItemIdentifier`), more exact than its index. [CN] Tab 的 ID，比下标更精确。
        if let identifier = viewController.cyl_tabBarItemIdentifier ?? page.cyl_tabBarItemIdentifier, !identifier.isEmpty {
            userInfo[cylTabBarItemIdentifier] = identifier
        }
        // [EN] FlatDesign (an optional subspec): its own item, read at run time. [CN] 扁平样式（可选子库）：其自己的 item，在运行时读取。
        let flatItem = tabBarStyleType == .flatDesign ? CYLFlatDesignLookup.tabBarItem(of: viewController) : nil
        if let tabBarItem = flatItem ?? viewController.tabBarItem {
            userInfo[cylTabBarItemKey] = tabBarItem
        }
        extra?.forEach { userInfo[$0.key] = $0.value }
        NotificationCenter.default.post(name: name, object: page, userInfo: userInfo)
    }

    /**
     * [EN] The image of `icon`, on the main queue: a `UIImage` as it is; an `NSURL` or an `http(s)` string loaded through
     *      `CYLImageCache`; any other string by name or absolute path (`+[UIImage cyl_imageNamed:]`, #535). nil when there is none.
     * [CN] 在主队列返回 `icon` 对应的图片：`UIImage` 原样返回；`NSURL` 或 `http(s)` 字符串通过 `CYLImageCache` 加载；其他字符串按图片名或
     *      绝对路径加载（#535）。没有图片时为 nil。
     */
    @objc(cyl_loadTabBarItemIcon:completion:)
    static func cylLoadTabBarItemIcon(_ icon: Any?, completion: @escaping (UIImage?) -> Void) {
        if let image = icon as? UIImage {
            completion(image)
            return
        }
        var url = icon as? URL
        if let string = icon as? String, string.hasPrefix("http://") || string.hasPrefix("https://") {
            url = URL(string: string)
        }
        if let url {
            UIImage.cylLoad(with: url, completion: completion)
            return
        }
        completion((icon as? String).flatMap { UIImage.cylImageNamed($0) })
    }

    /// [EN] The tab at `index` takes icons: not the plus button's slot or page. [CN] 第 `index` 个 Tab 可以设置图标：不是 PlusButton 的位置或页面。
    private func cylIconTab(at index: UInt) -> UIViewController? {
        let viewControllers = self.viewControllers ?? []
        guard Int(index) < viewControllers.count else {
            return nil
        }
        let viewController = viewControllers[Int(index)]
        if viewController.cyl_isPlaceholder || viewController === cylPrivate.cylContextPlusChildViewController() {
            return nil
        }
        return viewController
    }

    @objc(setTabBarItemIconViewProvider:atIndex:)
    @discardableResult
    open func setTabBarItemIconViewProvider(_ provider: CYLTabBarItemIconViewProvider?, at index: UInt) -> Bool {
        guard let viewController = cylIconTab(at: index) else {
            return false
        }
        let providers = cylTabBarItemIconViewProviders()
        // [EN] The caller's own block object is stored (a block type, not a Swift closure, so it is not wrapped): the icon
        //      notification hands back the same provider, as before.
        // [CN] 保存调用方自己的 block 对象（参数为 block 类型而不是 Swift 闭包，因此不会被包装）：图标通知交回同一个 provider，与以前相同。
        let block = provider.map { $0 as AnyObject }
        if let block {
            providers.setObject(block, forKey: viewController)
        } else {
            providers.removeObject(forKey: viewController)
        }
        cylUpdateTabBarItemIconViews(of: viewController)
        // [EN] The tab bar lays its buttons out again, as when a tab is selected. [CN] TabBar 重新布局其按钮，与选中 Tab 时相同。
        tabBar.setNeedsLayout()
        cylSetNeedsUpdateTabBarItemIconViews()
        cylPostTabBarItemNotification(.cylTabBarItemIconDidChange, at: index,
                                      extra: block.map { [cylTabBarItemIconViewProviderKey: $0] })
        return true
    }

    @objc(setTabBarItemIconWithURL:selectedURL:size:atIndex:)
    @discardableResult
    open func setTabBarItemIconWith(_ url: URL, selectedURL: URL?, size: CGSize, at index: UInt) -> Bool {
        setTabBarItemIcon(url, selectedIcon: selectedURL, size: size, at: index)
    }

    /**
     * [EN] A tab's icon from any source (`+cyl_loadTabBarItemIcon:completion:`), shown with its own colors through an icon view
     *      provider; an animated icon rests on its first frame until a tap or Play all plays it.
     * [CN] 任意来源的 Tab 图标（`+cyl_loadTabBarItemIcon:completion:`），以原图颜色通过图标视图 provider 显示；动图图标停在第一帧，点击或「全部播放」时播放。
     */
    @objc(setTabBarItemIcon:selectedIcon:size:atIndex:)
    @discardableResult
    open func setTabBarItemIcon(_ icon: Any?, selectedIcon: Any?, size: CGSize, at index: UInt) -> Bool {
        // [EN] `icon` is optional so that a nil from Objective-C is refused (NO) instead of reaching Swift as a non-optional.
        // [CN] `icon` 为可选，使 Objective-C 传入的 nil 被拒绝（返回 NO），而不是以非可选值进入 Swift。
        guard let icon, let viewController = cylIconTab(at: index) else {
            return false
        }
        Self.cylLoadTabBarItemIcon(icon) { [weak self, weak viewController] image in
            guard let image else {
                return
            }
            let show: (UIImage?) -> Void = { selectedImage in
                // [EN] Still a tab of this controller (the view controllers may have changed meanwhile).
                // [CN] 仍是本控制器的 Tab（期间视图控制器可能已改变）。
                guard let self, let viewController, let currentIndex = self.viewControllers?.firstIndex(of: viewController) else {
                    return
                }
                let originalImage = image.withRenderingMode(.alwaysOriginal)
                let originalSelectedImage = (selectedImage ?? image).withRenderingMode(.alwaysOriginal)
                self.setTabBarItemIconViewProvider(Self.cylIconViewProvider(normal: originalImage, selected: originalSelectedImage, size: size),
                                                   at: UInt(currentIndex))
            }
            if let selectedIcon, !(selectedIcon as AnyObject).isEqual(icon) {
                Self.cylLoadTabBarItemIcon(selectedIcon, completion: show)
            } else {
                show(nil)
            }
        }
        return true
    }

    /**
     * [EN] The view of one look: an animated icon rests on its first frame (its frames play on a tap or Play all), at `size`
     *      or the placeholder size.
     * [CN] 一种样式的视图：动图图标停在第一帧（点击或「全部播放」时播放），尺寸为 `size` 或占位尺寸。
     */
    /// [EN] The provider showing `normal` or `selected` (a separate function: closures nest at most two deep). [CN] 显示 `normal` 或 `selected` 的 provider（单独的函数：闭包最多嵌套两层）。
    private static func cylIconViewProvider(normal: UIImage, selected: UIImage, size: CGSize) -> CYLTabBarItemIconViewProvider {
        { isSelected in cylIconView(isSelected ? selected : normal, size: size) }
    }

    private static func cylIconView(_ iconImage: UIImage, size: CGSize) -> UIImageView {
        let frames = iconImage.images ?? []
        let iconView = UIImageView(image: frames.count > 1 ? frames.first?.withRenderingMode(iconImage.renderingMode) : iconImage)
        if frames.count > 1 {
            iconView.animationImages = frames
            iconView.animationDuration = iconImage.duration
            iconView.animationRepeatCount = 1
        }
        iconView.contentMode = .scaleAspectFit
        let iconSize = size == .zero ? CGSize(width: cylTabBarItemImagePlaceholderWidth, height: cylTabBarItemImagePlaceholderHeight) : size
        iconView.frame = CGRect(origin: .zero, size: iconSize)
        return iconView
    }
}

// MARK: - The plus button updated in place (docs/Swift-Migration.md, step 68)

/**
 * [EN] `-updatePlusButtonWithAttributes:` (declared in the category `CYLTabBarController (CYLPlusButtonUpdate)`, same
 *      selector) and the helpers the in-place updates share. Translated from Objective-C (docs/Swift-Migration.md, step 68).
 * [CN] `-updatePlusButtonWithAttributes:`（声明在分类 `CYLTabBarController (CYLPlusButtonUpdate)` 中，selector 不变）以及原地更新共用的辅助方法。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 68 步）。
 */
extension CYLTabBarController {

    /// [EN] The image keys of an icon change. [CN] 图标变化涉及的图片 key。
    private static let cylIconKeys = [cylTabBarItemImage, cylTabBarItemSelectedImage, cylTabBarItemDarkImage, cylTabBarItemSelectedDarkImage,
                                      cylTabBarItemImageURL, cylTabBarItemSelectedImageURL, cylTabBarItemImageURLSize]

    /**
     * [EN] The image keys of `attributes` (an icon change), empty when there is none.
     * [CN] `attributes` 中的图片 key（图标变化），没有时为空。
     */
    @objc(cyl_iconAttributesOfAttributes:)
    static func cylIconAttributes(of attributes: [String: Any]) -> [String: Any] {
        attributes.filter { cylIconKeys.contains($0.key) }
    }

    /**
     * [EN] A page that follows its tab's title (`cyl_navigationTitleFollowsTabBarItemTitle`) takes a new non-empty title.
     * [CN] 跟随 Tab 标题的页面（`cyl_navigationTitleFollowsTabBarItemTitle`）使用新的非空标题。
     */
    @objc(cyl_applyNavigationTitleOfFollowingPage:title:)
    static func cylApplyNavigationTitle(ofFollowingPage viewController: UIViewController, title: String?) {
        let page = viewController.cylGetViewControllerInsteadOfNavigation()
        guard let title, !title.isEmpty, page.cyl_navigationTitleFollowsTabBarItemTitle else {
            return
        }
        page.navigationItem.title = title
    }

    /**
     * [EN] `image` drawn at `size` with its own colors, every frame of an animated one (fitted, aspect kept).
     * [CN] 按 `size` 以原图颜色绘制 `image`，动图的每一帧都绘制（保持比例适配）。
     */
    private static func cylImage(_ image: UIImage?, scaledTo size: CGSize) -> UIImage? {
        guard let image else {
            return nil
        }
        guard size.width > 0, size.height > 0, image.size != size else {
            return image.withRenderingMode(.alwaysOriginal)
        }
        let scale: (UIImage) -> UIImage = { frame in
            let ratio = min(size.width / frame.size.width, size.height / frame.size.height)
            let fitted = CGSize(width: frame.size.width * ratio, height: frame.size.height * ratio)
            return UIGraphicsImageRenderer(size: fitted).image { _ in frame.draw(in: CGRect(origin: .zero, size: fitted)) }
        }
        let frames = image.images ?? []
        let scaled = frames.count > 1 ? UIImage.animatedImage(with: frames.map(scale), duration: image.duration) : scale(image)
        return scaled?.withRenderingMode(.alwaysOriginal)
    }

    /**
     * [EN] A change of the plus button: its page (the plus child view controller), when it has one, follows a new title, and
     *      the tab notification is posted with `CYLPlusButtonKey`. The object is that page, or the plus button without one
     *      (no index or tab bar item then).
     * [CN] PlusButton 的变化：它有页面（PlusButton 子控制器）时，页面跟随新标题；发送带有 `CYLPlusButtonKey` 的 Tab 通知。object 为该页面，
     *      没有页面时为 PlusButton（此时没有下标与 tabBarItem）。
     */
    @objc(cyl_plusButton:didChangeWithNotification:info:)
    func cylPlusButton(_ plusButton: CYLPlusButton, didChangeWith name: NSNotification.Name, info: [AnyHashable: Any]) {
        var extra = info
        extra[cylPlusButtonKey] = plusButton
        let plusChild = cylPrivate.cylContextPlusChildViewController()
        if name == .cylTabBarItemTitleDidChange, let plusChild {
            Self.cylApplyNavigationTitle(ofFollowingPage: plusChild, title: info[cylTabBarItemTitle] as? String)
        }
        if let plusChild, let index = viewControllers?.firstIndex(of: plusChild) {
            cylPostTabBarItemNotification(name, at: UInt(index), extra: extra)
            return
        }
        extra[cylTabBarControllerKey] = self
        NotificationCenter.default.post(name: name, object: plusButton, userInfo: extra)
    }

    /**
     * [EN] Updates the plus button in place: its title (its page follows it, with the title notification), its images from any
     *      source, scaled to `CYLTabBarItemImageURLSize`, its current image size or the tab icon size (a downloaded image never
     *      keeps its own size, FIX: issue #601), plus the icon and change notifications.
     * [CN] 原地更新 PlusButton：标题（其页面跟随，并发送标题通知）、任意来源的图片，按 `CYLTabBarItemImageURLSize`、当前图片尺寸或 Tab 图标尺寸缩放
     *      （下载的图片不保留原始尺寸，FIX: issue #601），以及图标通知与变化通知。
     */
    @objc(updatePlusButtonWithAttributes:)
    @discardableResult
    open func updatePlusButton(attributes: [String : Any] = [:]) -> Bool {
        guard let plusButton = CYLPlusButton(forOwner: self), !attributes.isEmpty else {
            return false
        }
        if let title = attributes[cylTabBarItemTitle] as? String {
            let oldTitle = plusButton.cyl_title()
            plusButton.cyl_updateTitle(title, image: nil, selectedImage: nil)
            // [EN] The plus button's page follows its title like any tab. [CN] PlusButton 的页面与其他 Tab 一样跟随其标题。
            var titleInfo: [AnyHashable: Any] = [cylTabBarItemTitle: title, cylTabBarItemChangedAttributesKey: [cylTabBarItemTitle: title]]
            titleInfo[cylTabBarItemOldTitleKey] = oldTitle
            cylPlusButton(plusButton, didChangeWith: .cylTabBarItemTitleDidChange, info: titleInfo)
        }
        let iconAttributes = Self.cylIconAttributes(of: attributes)
        if attributes[cylTabBarItemImage] != nil || attributes[cylTabBarItemSelectedImage] != nil ||
            attributes[cylTabBarItemImageURL] != nil || attributes[cylTabBarItemSelectedImageURL] != nil {
            cylPlusButton(plusButton, didChangeWith: .cylTabBarItemIconDidChange, info: [cylTabBarItemChangedAttributesKey: iconAttributes])
        }
        cylPlusButton(plusButton, didChangeWith: .cylTabBarItemDidChange, info: [cylTabBarItemChangedAttributesKey: attributes])
        let icon = attributes[cylTabBarItemImageURL] ?? attributes[cylTabBarItemImage]
        let selectedIcon = attributes[cylTabBarItemSelectedImageURL] ?? attributes[cylTabBarItemSelectedImage]
        var size = (attributes[cylTabBarItemImageURLSize] as? NSValue)?.cgSizeValue ?? plusButton.image(for: .normal)?.size ?? .zero
        // FIX: issue #601
        // [EN] Never left unscaled: a downloaded image keeps its own size (a 512 px icon is about 170 pt), which resizes the
        //      plus button and moves it. Without a size, the image view's, else the tab icon's.
        // [CN] 不保留原始尺寸：下载的图片会保持自身尺寸（512 px 的图标约 170 pt），导致 PlusButton 尺寸变化并移位。没有尺寸时使用图片视图的尺寸，
        //      否则使用 Tab 图标的尺寸。
        if size.width <= 0 || size.height <= 0 {
            size = plusButton.imageView?.bounds.size ?? .zero
        }
        if size.width <= 0 || size.height <= 0 {
            size = CGSize(width: cylTabBarItemImagePlaceholderWidth, height: cylTabBarItemImagePlaceholderHeight)
        }
        if let icon {
            Self.cylLoadTabBarItemIcon(icon) { [weak self, weak plusButton] image in
                plusButton?.cyl_updateTitle(nil, image: Self.cylImage(image, scaledTo: size), selectedImage: nil)
                // [EN] A downloaded image arrives after the layout of the theme change. [CN] 下载的图片在换肤的布局之后才到达。
                self?.cylLayOutPlusButtonInLiquidGlassLayers()
            }
        }
        if let selectedIcon {
            Self.cylLoadTabBarItemIcon(selectedIcon) { [weak plusButton] image in
                plusButton?.cyl_updateTitle(nil, image: nil, selectedImage: Self.cylImage(image, scaledTo: size))
            }
        }
        return true
    }
}
