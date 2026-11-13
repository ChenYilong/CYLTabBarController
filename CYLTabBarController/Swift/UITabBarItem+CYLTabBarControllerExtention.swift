//
//  UITabBarItem+CYLTabBarControllerExtention.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The tab button of an item, its animation file and size, its image position and its double tap and layout blocks.
 *      Translated from Objective-C (docs/Swift-Migration.md, branch swift-core); Objective-C callers get the declarations
 *      from `CYLSwiftInterface.h`; the Swift names are the ones Clang imported.
 * [CN] TabBarItem 的 Tab 按钮、动画文件与尺寸、图片位置以及双击与布局 block。已从 Objective-C 翻译（docs/Swift-Migration.md，
 *      swift-core 分支）；Objective-C 调用方从 `CYLSwiftInterface.h` 获得声明；Swift 名称与 Clang 原先导入的名称相同。
 */
extension UITabBarItem {

    private static var animationURLKey: UInt8 = 0
    private static var animationSizeValueKey: UInt8 = 0

    // MARK: - Animation file

    /**
     * [EN] The animation file of the item (Lottie, PAG, Rive or GIF).
     * [CN] TabBarItem 的动画文件（Lottie、PAG、Rive 或 GIF）。
     */
    @objc public var cyl_tabBarItemAnimationURL: URL? {
        @objc(cyl_tabBarItemAnimationURL) get {
            objc_getAssociatedObject(self, &UITabBarItem.animationURLKey) as? URL
        }
        @objc(cyl_setTabBarItemAnimationURL:) set {
            objc_setAssociatedObject(self, &UITabBarItem.animationURLKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] The animation size of the item.
     * [CN] TabBarItem 的动画尺寸。
     */
    @objc public var cyl_tabBarItemAnimationSizeValue: NSValue? {
        @objc(cyl_tabBarItemAnimationSizeValue) get {
            objc_getAssociatedObject(self, &UITabBarItem.animationSizeValueKey) as? NSValue
        }
        @objc(cyl_setTabBarItemAnimationSizeValue:) set {
            objc_setAssociatedObject(self, &UITabBarItem.animationSizeValueKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] Deprecated: `cyl_tabBarItemAnimationURL`.
     * [CN] 已废弃：请使用 `cyl_tabBarItemAnimationURL`。
     */
    @available(*, deprecated, message: "Use cyl_tabBarItemAnimationURL")
    @objc public var cyl_lottieURL: URL! {
        @objc(cyl_lottieURL) get { cyl_tabBarItemAnimationURL }
        @objc(cyl_setLottieURL:) set { cyl_tabBarItemAnimationURL = newValue }
    }

    /**
     * [EN] Deprecated: `cyl_tabBarItemAnimationSizeValue`.
     * [CN] 已废弃：请使用 `cyl_tabBarItemAnimationSizeValue`。
     */
    @available(*, deprecated, message: "Use cyl_tabBarItemAnimationSizeValue")
    @objc public var cyl_lottieSizeValue: NSValue! {
        @objc(cyl_lottieSizeValue) get { cyl_tabBarItemAnimationSizeValue }
        @objc(cyl_setLottieSizeValue:) set { cyl_tabBarItemAnimationSizeValue = newValue }
    }

    // MARK: - Image

    /**
     * [EN] An extra offset of the item's image.
     * [CN] TabBarItem 图片的额外偏移。
     */
    @objc public var cyl_imagePositionAdjustment: UIOffset {
        @objc(cyl_imagePositionAdjustment) get {
            (objc_getAssociatedObject(self, UITabBarItem.positionKey) as? NSValue)?.uiOffsetValue ?? .zero
        }
        @objc(cyl_setImagePositionAdjustment:) set {
            objc_setAssociatedObject(self, UITabBarItem.positionKey, NSValue(uiOffset: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] The image view of the item's tab button.
     * [CN] TabBarItem 的 Tab 按钮中的图片视图。
     */
    @objc(cyl_imageView)
    public func cyl_imageView() -> UIImageView? {
        cyl_view()?.cyl_tabImageView()
    }

    /**
     * [EN] Same as `cyl_imageView()`.
     * [CN] 与 `cyl_imageView()` 相同。
     */
    @objc(cyl_imageViewInTabBarButton)
    public func cyl_imageViewInTabBarButton() -> UIImageView? {
        cyl_view()?.cyl_tabImageView()
    }

    // MARK: - Tab buttons

    /**
     * [EN] With Liquid Glass, the item's button in the platter's selected layer; nil otherwise.
     * [CN] 液态玻璃下，TabBarItem 在 platter 选中层中的按钮；否则为 nil。
     */
    @objc public var cyl_selectedTabButton: UIControl? {
        guard CYLConstants.isLiquidGlassActive(), let view = cyl_view(),
              let index = view.superview?.subviews.firstIndex(of: view),
              let platterView = cyl_tabBarController?.tabBar.cyl_platterView, platterView.cyl_isPlatterView(),
              let selectedContentView = platterView.subviews.first, selectedContentView.cyl_isPlatterSelectedContentView(),
              index < selectedContentView.subviews.count else {
            return nil
        }
        return selectedContentView.subviews[index] as? UIControl
    }

    /**
     * [EN] The button the user sees: the selected layer's button with Liquid Glass, else the tab button.
     * [CN] 用户看到的按钮：液态玻璃下为选中层的按钮，否则为 Tab 按钮。
     */
    @objc public var cyl_visiableTabButton: UIControl! {
        CYLConstants.isLiquidGlassActive() ? cyl_selectedTabButton : cyl_tabButton
    }

    // MARK: - Blocks

    /**
     * [EN] Called when the item's tab is tapped twice.
     * [CN] TabBarItem 的 Tab 被双击时调用。
     */
    @objc public var cyl_doubleTapBlock: (@convention(block) (UITabBarItem, Int) -> Void)? {
        @objc(cyl_doubleTapBlock) get {
            objc_getAssociatedObject(self, UITabBarItem.doubleTapKey).map {
                unsafeBitCast($0 as AnyObject, to: (@convention(block) (UITabBarItem, Int) -> Void).self)
            }
        }
        @objc(cyl_setDoubleTapBlock:) set {
            objc_setAssociatedObject(self, UITabBarItem.doubleTapKey, newValue.map { unsafeBitCast($0, to: AnyObject.self) },
                                     .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }

    /**
     * [EN] Called after the item's tab button laid out its subviews.
     * [CN] TabBarItem 的 Tab 按钮布局子视图后调用。
     */
    @objc public var cyl_viewDidLayoutSubviewsBlock: (@convention(block) (UITabBarItem, UIView) -> Void)? {
        @objc(cyl_viewDidLayoutSubviewsBlock) get {
            objc_getAssociatedObject(self, UITabBarItem.layoutKey).map {
                unsafeBitCast($0 as AnyObject, to: (@convention(block) (UITabBarItem, UIView) -> Void).self)
            }
        }
        @objc(cyl_setViewDidLayoutSubviewsBlock:) set {
            objc_setAssociatedObject(self, UITabBarItem.layoutKey, newValue.map { unsafeBitCast($0, to: AnyObject.self) },
                                     .OBJC_ASSOCIATION_COPY_NONATOMIC)
            cyl_tabButton?.superview?.setNeedsLayout()
        }
    }

    // [EN] The selector keys the Objective-C version used. [CN] 与 Objective-C 版本相同的 selector key。
    private static let positionKey = CYLUtilsKeys.key("cyl_imagePositionAdjustment")
    private static let doubleTapKey = CYLUtilsKeys.key("cyl_doubleTapBlock")
    private static let layoutKey = CYLUtilsKeys.key("cyl_viewDidLayoutSubviewsBlock")
}

/**
 * [EN] Applying one change to every item appearance of a tab bar appearance.
 * [CN] 将同一修改应用到 TabBar 外观的每种 item 外观。
 */
extension UITabBarAppearance {

    /**
     * [EN] Calls `block` with the stacked, inline and compact inline item appearances.
     * [CN] 依次以 stacked、inline 与 compact inline 三种 item 外观调用 `block`。
     */
    @objc(cyl_applyItemAppearanceWithBlock:)
    public func cyl_applyItemAppearance(_ block: (UITabBarItemAppearance) -> Void) {
        block(stackedLayoutAppearance)
        block(inlineLayoutAppearance)
        block(compactInlineLayoutAppearance)
    }
}
