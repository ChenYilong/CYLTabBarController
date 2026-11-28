//
//  UIView+CYLDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
#if canImport(CYLAnimatedItem)
import CYLAnimatedItem
#endif

// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

extension UIView {
    /**
     [EN] Deprecated: renamed to `cylLocalizeTexts`.
     [CN] 已废弃：已改名为 `cylLocalizeTexts`。
     */
    @available(*, deprecated, renamed: "cylLocalizeTexts()")
    @nonobjc
    public func cyl_localizeTexts() { cylLocalizeTexts() }

    /**
     [EN] Deprecated: renamed to `cylReplaceTrackedSubview`.
     [CN] 已废弃：已改名为 `cylReplaceTrackedSubview`。
     */
    @available(*, deprecated, renamed: "cylReplaceTrackedSubview(_:withView:)")
    @nonobjc
    public func cyl_replaceTrackedSubview(_ view: UIView, withView newView: UIView) { cylReplaceTrackedSubview(view, withView: newView) }

    /**
     [EN] Deprecated: renamed to `cylIsTabBarItemAnimationView`.
     [CN] 已废弃：已改名为 `cylIsTabBarItemAnimationView`。
     */
    @available(*, deprecated, renamed: "cylIsTabBarItemAnimationView()")
    @nonobjc
    public func cyl_isTabBarItemAnimationView() -> Bool { cylIsTabBarItemAnimationView() }

    /**
     [EN] Deprecated: renamed to `cylIsPlusButton`.
     [CN] 已废弃：已改名为 `cylIsPlusButton`。
     */
    @available(*, deprecated, renamed: "cylIsPlusButton()")
    @nonobjc
    public func cyl_isPlusButton() -> Bool { cylIsPlusButton() }

    /**
     [EN] Deprecated: renamed to `cylIsRightToLeftLayout`.
     [CN] 已废弃：已改名为 `cylIsRightToLeftLayout`。
     */
    @available(*, deprecated, renamed: "cylIsRightToLeftLayout()")
    @nonobjc
    public func cyl_isRightToLeftLayout() -> Bool { cylIsRightToLeftLayout() }

    /**
     [EN] Deprecated: renamed to `cylIsTabButton`.
     [CN] 已废弃：已改名为 `cylIsTabButton`。
     */
    @available(*, deprecated, renamed: "cylIsTabButton()")
    @nonobjc
    public func cyl_isTabButton() -> Bool { cylIsTabButton() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterView`.
     [CN] 已废弃：已改名为 `cylIsPlatterView`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterView()")
    @nonobjc
    public func cyl_isPlatterView() -> Bool { cylIsPlatterView() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterPortalView`.
     [CN] 已废弃：已改名为 `cylIsPlatterPortalView`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterPortalView()")
    @nonobjc
    public func cyl_isPlatterPortalView() -> Bool { cylIsPlatterPortalView() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterContentView`.
     [CN] 已废弃：已改名为 `cylIsPlatterContentView`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterContentView()")
    @nonobjc
    public func cyl_isPlatterContentView() -> Bool { cylIsPlatterContentView() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterSelectedContentView`.
     [CN] 已废弃：已改名为 `cylIsPlatterSelectedContentView`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterSelectedContentView()")
    @nonobjc
    public func cyl_isPlatterSelectedContentView() -> Bool { cylIsPlatterSelectedContentView() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterVisualProviderFloatingSelectedContentView`.
     [CN] 已废弃：已改名为 `cylIsPlatterVisualProviderFloatingSelectedContentView`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterVisualProviderFloatingSelectedContentView()")
    @nonobjc
    public func cyl_isPlatterVisualProviderFloatingSelectedContentView() -> Bool { cylIsPlatterVisualProviderFloatingSelectedContentView() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterLiquidLensView`.
     [CN] 已废弃：已改名为 `cylIsPlatterLiquidLensView`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterLiquidLensView()")
    @nonobjc
    public func cyl_isPlatterLiquidLensView() -> Bool { cylIsPlatterLiquidLensView() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterLiquidLensClearGlassView`.
     [CN] 已废弃：已改名为 `cylIsPlatterLiquidLensClearGlassView`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterLiquidLensClearGlassView()")
    @nonobjc
    public func cyl_isPlatterLiquidLensClearGlassView() -> Bool { cylIsPlatterLiquidLensClearGlassView() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterLiquidLensTabSelectionView`.
     [CN] 已废弃：已改名为 `cylIsPlatterLiquidLensTabSelectionView`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterLiquidLensTabSelectionView()")
    @nonobjc
    public func cyl_isPlatterLiquidLensTabSelectionView() -> Bool { cylIsPlatterLiquidLensTabSelectionView() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterLiquidLensBackdropView`.
     [CN] 已废弃：已改名为 `cylIsPlatterLiquidLensBackdropView`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterLiquidLensBackdropView()")
    @nonobjc
    public func cyl_isPlatterLiquidLensBackdropView() -> Bool { cylIsPlatterLiquidLensBackdropView() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterDestOutView`.
     [CN] 已废弃：已改名为 `cylIsPlatterDestOutView`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterDestOutView()")
    @nonobjc
    public func cyl_isPlatterDestOutView() -> Bool { cylIsPlatterDestOutView() }

    /**
     [EN] Deprecated: renamed to `cylIsTabImageView`.
     [CN] 已废弃：已改名为 `cylIsTabImageView`。
     */
    @available(*, deprecated, renamed: "cylIsTabImageView()")
    @nonobjc
    public func cyl_isTabImageView() -> Bool { cylIsTabImageView() }

    /**
     [EN] Deprecated: renamed to `cylIsTabLabel`.
     [CN] 已废弃：已改名为 `cylIsTabLabel`。
     */
    @available(*, deprecated, renamed: "cylIsTabLabel()")
    @nonobjc
    public func cyl_isTabLabel() -> Bool { cylIsTabLabel() }

    /**
     [EN] Deprecated: renamed to `cylIsButtonLabel`.
     [CN] 已废弃：已改名为 `cylIsButtonLabel`。
     */
    @available(*, deprecated, renamed: "cylIsButtonLabel()")
    @nonobjc
    public func cyl_isButtonLabel() -> Bool { cylIsButtonLabel() }

    /**
     [EN] Deprecated: renamed to `cylIsTabBadgeView`.
     [CN] 已废弃：已改名为 `cylIsTabBadgeView`。
     */
    @available(*, deprecated, renamed: "cylIsTabBadgeView()")
    @nonobjc
    public func cyl_isTabBadgeView() -> Bool { cylIsTabBadgeView() }

    /**
     [EN] Deprecated: renamed to `cylIsTabBackgroundView`.
     [CN] 已废弃：已改名为 `cylIsTabBackgroundView`。
     */
    @available(*, deprecated, renamed: "cylIsTabBackgroundView()")
    @nonobjc
    public func cyl_isTabBackgroundView() -> Bool { cylIsTabBackgroundView() }

    /**
     [EN] Deprecated: renamed to `cylIsLottieAnimationView`.
     [CN] 已废弃：已改名为 `cylIsLottieAnimationView`。
     */
    @available(*, deprecated, renamed: "cylIsLottieAnimationView()")
    @nonobjc
    public func cyl_isLottieAnimationView() -> Bool { cylIsLottieAnimationView() }

    /**
     [EN] Deprecated: renamed to `cylImageView`.
     [CN] 已废弃：已改名为 `cylImageView`。
     */
    @available(*, deprecated, renamed: "cylImageView()")
    @nonobjc
    public func cyl_imageView() -> UIImageView? { cylImageView() }

    /**
     [EN] Deprecated: renamed to `cylTabImageView`.
     [CN] 已废弃：已改名为 `cylTabImageView`。
     */
    @available(*, deprecated, renamed: "cylTabImageView()")
    @nonobjc
    public func cyl_tabImageView() -> UIImageView? { cylTabImageView() }

    /**
     [EN] Deprecated: renamed to `cylSwappableImageViewViewInTabBarButton`.
     [CN] 已废弃：已改名为 `cylSwappableImageViewViewInTabBarButton`。
     */
    @available(*, deprecated, renamed: "cylSwappableImageViewViewInTabBarButton()")
    @nonobjc
    public func cyl_swappableImageViewViewInTabBarButton() -> UIImageView? { cylSwappableImageViewViewInTabBarButton() }

    /**
     [EN] Deprecated: renamed to `cylImageViewInTabBarButton`.
     [CN] 已废弃：已改名为 `cylImageViewInTabBarButton`。
     */
    @available(*, deprecated, renamed: "cylImageViewInTabBarButton()")
    @nonobjc
    public func cyl_imageViewInTabBarButton() -> UIImageView? { cylImageViewInTabBarButton() }

    /**
     [EN] Deprecated: renamed to `cylAllSubviews`.
     [CN] 已废弃：已改名为 `cylAllSubviews`。
     */
    @available(*, deprecated, renamed: "cylAllSubviews()")
    @nonobjc
    public func cyl_allSubviews() -> [Any] { cylAllSubviews() }

    /**
     [EN] Deprecated: renamed to `cylTabBadgeView`.
     [CN] 已废弃：已改名为 `cylTabBadgeView`。
     */
    @available(*, deprecated, renamed: "cylTabBadgeView()")
    @nonobjc
    public func cyl_tabBadgeView() -> UIView? { cylTabBadgeView() }

    /**
     [EN] Deprecated: renamed to `cylTabLabel`.
     [CN] 已废弃：已改名为 `cylTabLabel`。
     */
    @available(*, deprecated, renamed: "cylTabLabel()")
    @nonobjc
    public func cyl_tabLabel() -> UILabel? { cylTabLabel() }

    /**
     [EN] Deprecated: renamed to `cylTabEffectView`.
     [CN] 已废弃：已改名为 `cylTabEffectView`。
     */
    @available(*, deprecated, renamed: "cylTabEffectView()")
    @nonobjc
    public func cyl_tabEffectView() -> UIVisualEffectView? { cylTabEffectView() }

    /**
     [EN] Deprecated: renamed to `cylTabShadowImageView`.
     [CN] 已废弃：已改名为 `cylTabShadowImageView`。
     */
    @available(*, deprecated, renamed: "cylTabShadowImageView()")
    @nonobjc
    public func cyl_tabShadowImageView() -> UIImageView? { cylTabShadowImageView() }

    /**
     [EN] Deprecated: renamed to `cylTabBackgroundView`.
     [CN] 已废弃：已改名为 `cylTabBackgroundView`。
     */
    @available(*, deprecated, renamed: "cylTabBackgroundView()")
    @nonobjc
    public func cyl_tabBackgroundView() -> UIView? { cylTabBackgroundView() }

    /**
     [EN] Deprecated: renamed to `cylContentView`.
     [CN] 已废弃：已改名为 `cylContentView`。
     */
    @available(*, deprecated, renamed: "cylContentView()")
    @nonobjc
    public func cyl_contentView() -> UIView! { cylContentView() }

    /**
     [EN] Deprecated: renamed to `cylAddPlatterViewThenBringSubview`.
     [CN] 已废弃：已改名为 `cylAddPlatterViewThenBringSubview`。
     */
    @available(*, deprecated, renamed: "cylAddPlatterViewThenBringSubview(toFront:)")
    @nonobjc
    public func cyl_addPlatterViewThenBringSubview(toFront view: UIView) { cylAddPlatterViewThenBringSubview(toFront: view) }

    /**
     [EN] Deprecated: renamed to `cylIsViewAdded`.
     [CN] 已废弃：已改名为 `cylIsViewAdded`。
     */
    @available(*, deprecated, renamed: "cylIsViewAdded(toPlatterView:)")
    @nonobjc
    public func cyl_isViewAdded(toPlatterView view: UIView) -> Bool { cylIsViewAdded(toPlatterView: view) }

    /**
     [EN] Deprecated: renamed to `cylBringSubview`.
     [CN] 已废弃：已改名为 `cylBringSubview`。
     */
    @available(*, deprecated, renamed: "cylBringSubview(toFront:)")
    @nonobjc
    public func cyl_bringSubview(toFront view: UIView) { cylBringSubview(toFront: view) }

    /**
     [EN] Deprecated: renamed to `cylBringSubview`.
     [CN] 已废弃：已改名为 `cylBringSubview`。
     */
    @available(*, deprecated, renamed: "cylBringSubview(toTop:)")
    @nonobjc
    public func cyl_bringSubview(toTop view: UIView) { cylBringSubview(toTop: view) }

    /**
     [EN] Deprecated: renamed to `cylTakeSnapshot`.
     [CN] 已废弃：已改名为 `cylTakeSnapshot`。
     */
    @available(*, deprecated, renamed: "cylTakeSnapshot()")
    @nonobjc
    public func cyl_takeSnapshot() -> UIImage? { cylTakeSnapshot() }

    /**
     [EN] Deprecated: renamed to `cylTakeSnapshot`.
     [CN] 已废弃：已改名为 `cylTakeSnapshot`。
     */
    @available(*, deprecated, renamed: "cylTakeSnapshot(withoutViews:)")
    @nonobjc
    public func cyl_takeSnapshot(withoutViews hideViews: [UIView]) -> UIImage? { cylTakeSnapshot(withoutViews: hideViews) }

    /**
     [EN] Deprecated: renamed to `cylMarkAsInserted`.
     [CN] 已废弃：已改名为 `cylMarkAsInserted`。
     */
    @available(*, deprecated, renamed: "cylMarkAsInserted(forTabControl:)")
    @nonobjc
    public func cyl_markAsInserted(forTabControl control: UIControl?) { cylMarkAsInserted(forTabControl: control) }

    /**
     [EN] Deprecated: renamed to `cylInsertedTabControlViews`.
     [CN] 已废弃：已改名为 `cylInsertedTabControlViews`。
     */
    @available(*, deprecated, renamed: "cylInsertedTabControlViews()")
    @nonobjc
    public class func cyl_insertedTabControlViews() -> [UIView] { Self.cylInsertedTabControlViews() }

    /**
     [EN] Deprecated: renamed to `cylTabBadgeBackgroundView`.
     [CN] 已废弃：已改名为 `cylTabBadgeBackgroundView`。
     */
    @available(*, deprecated, renamed: "cylTabBadgeBackgroundView()")
    @available(*, deprecated, message: "Deprecated in 1.6.0. Use `+[CYLPlusButton cyl_tabBackgroundView]` instead.")
    @nonobjc
    public func cyl_tabBadgeBackgroundView() -> UIView? { cylTabBadgeBackgroundView() }

    /**
     [EN] Deprecated: renamed to `cylTabBadgeBackgroundSeparator`.
     [CN] 已废弃：已改名为 `cylTabBadgeBackgroundSeparator`。
     */
    @available(*, deprecated, renamed: "cylTabBadgeBackgroundSeparator()")
    @available(*, deprecated, message: "Deprecated in 1.6.0. Use `+[CYLPlusButton cyl_tabShadowImageView]` instead.")
    @nonobjc
    public func cyl_tabBadgeBackgroundSeparator() -> UIView? { cylTabBadgeBackgroundSeparator() }

    /**
     [EN] Deprecated: renamed to `cylTabBadgePointView`.
     [CN] 已废弃：已改名为 `cylTabBadgePointView`。
     */
    @available(*, deprecated, renamed: "cylTabBadgePointView(withClolor:radius:)")
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @nonobjc
    public class func cyl_tabBadgePointView(withClolor color: UIColor, radius: CGFloat) -> UIView { Self.cylTabBadgePointView(withClolor: color, radius: radius) }

    /**
     [EN] Deprecated: renamed to `cylPlusButtonIndex`.
     [CN] 已废弃：已改名为 `cylPlusButtonIndex`。
     */
    @available(*, deprecated, renamed: "cylPlusButtonIndex()")
    @nonobjc
    public func cyl_plusButtonIndex() -> UInt { cylPlusButtonIndex() }

    /**
     [EN] Deprecated: renamed to `cylPlusButtonWidth`.
     [CN] 已废弃：已改名为 `cylPlusButtonWidth`。
     */
    @available(*, deprecated, renamed: "cylPlusButtonWidth()")
    @nonobjc
    public func cyl_plusButtonWidth() -> CGFloat { cylPlusButtonWidth() }
}
