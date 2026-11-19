//
//  CYLTabBarController+CYLTabBarItemIconViews.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

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

    private typealias CYLIconViewProvider = @convention(block) (Bool) -> UIView?

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
        if isLiquidGlassTabBar, let selectedLayerButton = tabButton.cyl_platterSelected(), selectedLayerButton !== tabButton {
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
        let lottieView = tabButton.cyl_tabBarItemAnimationView()
        // [EN] A cover over the tab button (e.g. a logo over the first tab) hides its other views, the tab's own icon too.
        // [CN] 覆盖 Tab 按钮的封面（如第一个 Tab 上的 Logo）会隐藏按钮中的其他视图，包括 Tab 自身的图标。
        let isCovered = tabButton.subviews.contains { $0.cyl_tabButtonCoverView && !$0.cyl_isInvisiable() }
        if installedProvider !== providerObject {
            // [EN] Another provider, or none: remove the views of the previous one. [CN] 换了 provider 或已移除：移除之前的视图。
            iconViews?.values.forEach { $0.removeFromSuperview() }
            iconViews = nil
            objc_setAssociatedObject(tabButton, CYLTabBarItemIconViewKeys.iconViews, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(tabButton, CYLTabBarItemIconViewKeys.installedProvider, providerObject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if provider == nil {
                // [EN] The tab's own icon and its badge come back, unless the cover hides them. [CN] Tab 自身的图标及其角标恢复，除非被封面隐藏。
                cylSetTabImageView(tabButton.cyl_tabImageView(), lottieView: lottieView, replacedByIconView: false)
                Self.cylSetAnimatedItemIconHidden(tabButton, false)
                if !isCovered {
                    tabButton.cyl_tabImageView()?.isHidden = lottieView != nil
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
        tabButton.cyl_tabImageView()?.isHidden = true
        lottieView?.isHidden = true
        Self.cylSetAnimatedItemIconHidden(tabButton, true)
        // [EN] Under a cover the badge stays as the cover left it (cleared). [CN] 有封面时角标保持封面设置的状态（已清除）。
        cylSetTabImageView(tabButton.cyl_tabImageView(), lottieView: lottieView, replacedByIconView: !isCovered)
        // [EN] Below the tab's own icon, or the subview of the tab button holding it (Liquid Glass), so the badge shown above
        //      that icon stays above this view too.
        // [CN] 位于 Tab 自身图标（或液态玻璃中包含它的 Tab 按钮子视图）之下，使该图标上方的角标也位于此视图之上。
        var iconHolder: UIView? = lottieView ?? tabButton.cyl_tabImageView()
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
            tabButton.cyl_replaceTabImageView(withNewView: iconView, show: true)
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
            host.cyl_refreshBadge()
        }
    }
}
