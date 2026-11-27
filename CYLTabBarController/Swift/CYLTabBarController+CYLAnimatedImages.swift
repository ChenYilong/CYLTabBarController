//
//  CYLTabBarController+CYLAnimatedImages.swift
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
 * [EN] The associated object keys shared with CYLTabBarController.m (`CYLRestingTabBarItemImage` writes them; selector-based
 *      keys, the same pointer on both sides).
 * [CN] 与 CYLTabBarController.m 共用的关联对象 key（`CYLRestingTabBarItemImage` 写入；基于 selector 的 key，两边是同一个指针）。
 */
enum CYLAnimatedImageKeys {
    /// [EN] A tab item's animated image, resting on its first frame. [CN] Tab item 的动图，停在第一帧。
    static let image = CYLUtilsKeys.key("cyl_tabBarItemAnimatedImage")
    static let selectedImage = CYLUtilsKeys.key("cyl_tabBarItemAnimatedSelectedImage")
}

/**
 * [EN] Animated tab images (they rest until played, docs/GIF-Animation.md) and the template tint of the animation views.
 *      Translated from Objective-C (docs/Swift-Migration.md, step 65); `CYLTabBarController+CYLPrivate.h` declares the methods
 *      CYLTabBarController.m calls.
 * [CN] Tab 动图（播放前保持静止，docs/GIF-Animation.md）以及动画视图的模板着色。已从 Objective-C 翻译（docs/Swift-Migration.md，第 65 步）；
 *      `CYLTabBarController+CYLPrivate.h` 声明 CYLTabBarController.m 调用的方法。
 */
extension CYLTabBarController {

    // MARK: - Helpers

    /**
     * [EN] The color UIKit draws a template tab image in, from the tint the tab bar was set up with: selected, the
     *      appearance's selected icon color (the tab's own appearance, else the bar's), else `tintColor`; not selected, the appearance's normal icon color, else
     *      `unselectedItemTintColor`, else UIKit's default (the label color with Liquid Glass, system gray before).
     * [CN] UIKit 绘制模板 Tab 图片所用的颜色，来自 TabBar 设置的 tint：选中时为外观的选中图标颜色（先取 Tab 自己的外观，再取 TabBar 的），否则为 `tintColor`；未选中时为外观的普通图标颜色，
     *      否则为 `unselectedItemTintColor`，再否则为 UIKit 的默认值（液态玻璃下为 label 颜色，之前为系统灰色）。
     */
    private static func cylTemplateTintColor(_ tabBar: UITabBar, item: UITabBarItem?, selected: Bool) -> UIColor {
        // [EN] The tab's own appearance first: it holds `CYLTabBarItemIconColor` / `CYLTabBarItemSelectedIconColor` over a copy of the bar's (B35).
        // [CN] 先读 Tab 自己的外观：它在 TabBar 外观的副本上带有 `CYLTabBarItemIconColor` / `CYLTabBarItemSelectedIconColor`（B35）。
        let layout = (item?.standardAppearance ?? tabBar.standardAppearance).stackedLayoutAppearance
        if let iconColor = (selected ? layout.selected : layout.normal).iconColor {
            return iconColor
        }
        if selected {
            return tabBar.tintColor ?? .systemBlue
        }
        return tabBar.unselectedItemTintColor ?? (CYLConstants.isLiquidGlassActive() ? .label : .systemGray)
    }

    /**
     * [EN] The views under `view` that match, depth first. [CN] `view` 下符合条件的视图，深度优先。
     */
    private static func cylSubviews(of view: UIView, where matches: (UIView) -> Bool) -> [UIView] {
        view.subviews.flatMap { subview in (matches(subview) ? [subview] : []) + cylSubviews(of: subview, where: matches) }
    }

    /**
     * [EN] The icon views a tab draws itself (`-setTabBarItemIconViewProvider:atIndex:`, URL icons) that hold animation frames.
     * [CN] Tab 自己绘制的、带有动画帧的图标视图（`-setTabBarItemIconViewProvider:atIndex:`、URL 图标）。
     */
    private static func cylAnimatedIconViews(in view: UIView) -> [UIImageView] {
        cylSubviews(of: view) { (($0 as? UIImageView)?.animationImages?.count ?? 0) > 1 }.compactMap { $0 as? UIImageView }
    }

    /**
     * [EN] Plays `image`'s frames on `imageView` from the first one: once, or until stopped when `loops` is YES.
     * [CN] 在 `imageView` 上从第一帧播放 `image` 的各帧：播放一次，`loops` 为 YES 时一直播放到停止。
     */
    private static func cylPlayAnimatedImage(_ image: UIImage?, on imageView: UIImageView?, loops: Bool) {
        guard let imageView, let image, let frames = image.images, frames.count > 1 else {
            return
        }
        imageView.stopAnimating()
        imageView.animationImages = frames
        imageView.animationDuration = image.duration
        imageView.animationRepeatCount = loops ? 0 : 1
        imageView.startAnimating()
    }

    // MARK: - Tab buttons

    /**
     * [EN] The tab bar item a tab button belongs to, found through the view controllers instead of the button's position,
     *      so the plus button and tabs without animations never shift it. Nil for the plus button.
     * [CN] 通过子控制器（而不是按钮的位置）找到 Tab 按钮所属的 tabBarItem，PlusButton 与没有动画的 Tab 不会造成错位。PlusButton 返回 nil。
     */
    @objc(cyl_tabBarItemForTabButton:)
    func cylTabBarItem(forTabButton control: UIControl?) -> UITabBarItem? {
        guard let control, !control.cylIsPlusControl() else {
            return nil
        }
        return (viewControllers ?? []).first { viewController in
            !viewController.cyl_isPlaceholder && (viewController.tabBarItem.cyl_tabButton === control || viewController.cyl_tabButton === control)
        }?.tabBarItem
    }

    /// [EN] Every tab button, the selected-state layer's too. [CN] 所有 Tab 按钮，包括选中态图层中的。
    @objc(cyl_allTabButtonsForAnimatedImages)
    func cylAllTabButtonsForAnimatedImages() -> [UIControl] {
        guard let tabBar = cyl_tabBar as? CYLTabBar else {
            return []
        }
        return (tabBar.cylVisibleControls() ?? []) + (tabBar.cylPlatterSelectedContentViews() ?? [])
    }

    // MARK: - Animated images

    /**
     * [EN] Plays the animated images of a tab button (docs/GIF-Animation.md): the tab item's image shown by UIKit, and the
     *      tab's own icon views. They rest on their first frame otherwise.
     * [CN] 播放 Tab 按钮的动图：UIKit 显示的 tabBarItem 图片，以及 Tab 自己的图标视图。其他时候停在第一帧。
     */
    @objc(cyl_playAnimatedImagesOfTabButton:)
    func cylPlayAnimatedImages(ofTabButton control: UIControl?) {
        guard let control, !control.cylIsPlusControl() else {
            return
        }
        var animatedImage: UIImage?
        if let item = cylTabBarItem(forTabButton: control) {
            let selected = item === selectedViewController?.tabBarItem
            animatedImage = objc_getAssociatedObject(item, selected ? CYLAnimatedImageKeys.selectedImage : CYLAnimatedImageKeys.image) as? UIImage
                ?? objc_getAssociatedObject(item, CYLAnimatedImageKeys.image) as? UIImage
        }
        let tabImageView = control.cylTabImageView()
        Self.cylPlayAnimatedImage(animatedImage, on: tabImageView, loops: tabBarItemAnimationLoops)
        for iconView in Self.cylAnimatedIconViews(in: control) where !(iconView === tabImageView && animatedImage != nil) {
            iconView.stopAnimating()
            iconView.animationRepeatCount = tabBarItemAnimationLoops ? 0 : 1
            iconView.startAnimating()
        }
    }

    /**
     * [EN] The animated images after `tabBarItemAnimationLoops` changed: off stops them on their resting frame, on plays the
     *      selected tab's. Called by the setter in CYLTabBarController.m.
     * [CN] `tabBarItemAnimationLoops` 变化后的动图：关闭时停在静止帧，开启时播放选中的 Tab。由 CYLTabBarController.m 中的 setter 调用。
     */
    @objc(cyl_applyAnimatedImagesLoops:)
    func cylApplyAnimatedImagesLoops(_ loops: Bool) {
        for control in cylAllTabButtonsForAnimatedImages() {
            var iconViews = Self.cylAnimatedIconViews(in: control)
            if let tabImageView = control.cylTabImageView(), (tabImageView.animationImages?.count ?? 0) > 1,
               !iconViews.contains(where: { $0 === tabImageView }) {
                iconViews.append(tabImageView)
            }
            if !loops {
                iconViews.forEach { $0.stopAnimating() }
            }
            if loops && control.isSelected {
                cylPlayAnimatedImages(ofTabButton: control)
            }
        }
    }

    // MARK: - Template tint of the animation views

    /**
     * [EN] Gives every tab's animation view the tab's current title color (`CYLTabBarAnimationOptionTint` "title") and the
     *      tab's state (a fixed tint only on the unselected tab): the tab bar's tint when selected, its unselected tint
     *      otherwise, as UIKit draws a template image. Next run loop, once UIKit has set the colors for the new selection.
     * [CN] 把每个 Tab 当前的标题颜色（`CYLTabBarAnimationOptionTint` 为 "title"）与状态（固定着色只用于未选中的 Tab）交给其动画视图：选中时为 TabBar
     *      的 tint，否则为未选中 tint，与 UIKit 绘制模板图片相同。在下一个 runloop 执行，此时 UIKit 已为新的选中状态设置好颜色。
     */
    @objc(cyl_setNeedsApplyTabBarItemAnimationTintColors)
    func cylSetNeedsApplyTabBarItemAnimationTintColors() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let tabBar = self.cyl_tabBar as? CYLTabBar else {
                return
            }
            let tint = NSSelectorFromString("cyl_applyAnimationViewTintColor:")
            let tintWithState = NSSelectorFromString("cyl_applyAnimationViewTintColor:selected:")
            let selectedLayer = tabBar.cylPlatterSelectedContentViews() ?? []
            for control in self.cylAllTabButtonsForAnimatedImages() {
                let views = Self.cylSubviews(of: control) { $0.responds(to: tint) }
                guard !views.isEmpty else {
                    continue
                }
                let item = self.cylTabBarItem(forTabButton: control)
                let selected = (item != nil && item === self.selectedViewController?.tabBarItem) ||
                    selectedLayer.contains { $0 === control }
                let color = Self.cylTemplateTintColor(tabBar, item: item, selected: selected)
                for view in views {
                    if view.responds(to: tintWithState) {
                        typealias CYLTintWithState = @convention(c) (AnyObject, Selector, UIColor?, Bool) -> Void
                        unsafeBitCast(view.method(for: tintWithState), to: CYLTintWithState.self)(view, tintWithState, color, selected)
                    } else {
                        _ = view.perform(tint, with: color)
                    }
                }
            }
        }
    }
}
