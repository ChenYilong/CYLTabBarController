//
//  CYLTabBar+CYLDeprecatedNames.swift
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

extension CYLTabBar {
    /**
     [EN] Deprecated: renamed to `cylSelectedIndex`.
     [CN] 已废弃：已改名为 `cylSelectedIndex`。
     */
    @available(*, deprecated, renamed: "cylSelectedIndex()")
    @nonobjc
    public func cyl_selectedIndex() -> Int { cylSelectedIndex() }

    /**
     [EN] Deprecated: renamed to `cylVisibleControls`.
     [CN] 已废弃：已改名为 `cylVisibleControls`。
     */
    @available(*, deprecated, renamed: "cylVisibleControls()")
    @nonobjc
    public func cyl_visibleControls() -> [UIControl]? { cylVisibleControls() }

    /**
     [EN] Deprecated: renamed to `cylSubTabBarButtons`.
     [CN] 已废弃：已改名为 `cylSubTabBarButtons`。
     */
    @available(*, deprecated, renamed: "cylSubTabBarButtons()")
    @nonobjc
    public func cyl_subTabBarButtons() -> [UIControl] { cylSubTabBarButtons() }

    /**
     [EN] Deprecated: renamed to `cylSubTabBarButtonsWithoutPlusButton`.
     [CN] 已废弃：已改名为 `cylSubTabBarButtonsWithoutPlusButton`。
     */
    @available(*, deprecated, renamed: "cylSubTabBarButtonsWithoutPlusButton()")
    @nonobjc
    public func cyl_subTabBarButtonsWithoutPlusButton() -> [UIControl] { cylSubTabBarButtonsWithoutPlusButton() }

    /**
     [EN] Deprecated: renamed to `cylTabBarButton`.
     [CN] 已废弃：已改名为 `cylTabBarButton`。
     */
    @available(*, deprecated, renamed: "cylTabBarButton(withTabIndex:)")
    @nonobjc
    public func cyl_tabBarButton(withTabIndex tabIndex: UInt) -> UIControl! { cylTabBarButton(withTabIndex: tabIndex) }

    /**
     [EN] Deprecated: renamed to `cylNormalContentControl`.
     [CN] 已废弃：已改名为 `cylNormalContentControl`。
     */
    @available(*, deprecated, renamed: "cylNormalContentControl(fromSelectedContentControl:)")
    @nonobjc
    public func cyl_normalContentControl(fromSelectedContentControl control: UIControl) -> UIControl? { cylNormalContentControl(fromSelectedContentControl: control) }

    /**
     [EN] Deprecated: renamed to `cylSelectedContentControl`.
     [CN] 已废弃：已改名为 `cylSelectedContentControl`。
     */
    @available(*, deprecated, renamed: "cylSelectedContentControl(fromContentControl:)")
    @nonobjc
    public func cyl_selectedContentControl(fromContentControl control: UIControl?) -> UIControl? { cylSelectedContentControl(fromContentControl: control) }

    /**
     [EN] Deprecated: renamed to `animationLottieImage`.
     [CN] 已废弃：已改名为 `animationLottieImage`。
     */
    @available(*, deprecated, renamed: "animationLottieImage(withSelectedControl:lottieURL:size:defaultSelected:contentMode:)")
    @nonobjc
    public func cyl_animationLottieImage(withSelectedControl selectedControl: UIControl?, lottieURL: URL?, size: CGSize, defaultSelected: Bool, contentMode: UIView.ContentMode) { animationLottieImage(withSelectedControl: selectedControl, lottieURL: lottieURL, size: size, defaultSelected: defaultSelected, contentMode: contentMode) }

    /**
     [EN] Deprecated: renamed to `cylStopAnimationOfAllLottieView`.
     [CN] 已废弃：已改名为 `cylStopAnimationOfAllLottieView`。
     */
    @available(*, deprecated, renamed: "cylStopAnimationOfAllLottieView()")
    @nonobjc
    public func cyl_stopAnimationOfAllLottieView() { cylStopAnimationOfAllLottieView() }

    /**
     [EN] Deprecated: renamed to `cylOriginalTabBarButtons`.
     [CN] 已废弃：已改名为 `cylOriginalTabBarButtons`。
     */
    @available(*, deprecated, renamed: "cylOriginalTabBarButtons()")
    @nonobjc
    public func cyl_originalTabBarButtons() -> [Any] { cylOriginalTabBarButtons() }

    /**
     [EN] Deprecated: renamed to `cylHasPlusChildViewController`.
     [CN] 已废弃：已改名为 `cylHasPlusChildViewController`。
     */
    @available(*, deprecated, renamed: "cylHasPlusChildViewController()")
    @nonobjc
    public func cyl_hasPlusChildViewController() -> Bool { cylHasPlusChildViewController() }

    /**
     [EN] Deprecated: renamed to `cylCachedXOffset`.
     [CN] 已废弃：已改名为 `cylCachedXOffset`。
     */
    @available(*, deprecated, renamed: "cylCachedXOffset(withIndex:)")
    @nonobjc
    public func cyl_cachedXOffset(withIndex index: CGFloat) -> CGFloat { cylCachedXOffset(withIndex: index) }

    /**
     [EN] Deprecated: renamed to `cylCachedWidthOffset`.
     [CN] 已废弃：已改名为 `cylCachedWidthOffset`。
     */
    @available(*, deprecated, renamed: "cylCachedWidthOffset(withIndex:)")
    @nonobjc
    public func cyl_cachedWidthOffset(withIndex index: CGFloat) -> CGFloat { cylCachedWidthOffset(withIndex: index) }

    /**
     [EN] Deprecated: renamed to `cylShouldUpdateHiddenStatueForPlusButtonLabel`.
     [CN] 已废弃：已改名为 `cylShouldUpdateHiddenStatueForPlusButtonLabel`。
     */
    @available(*, deprecated, renamed: "cylShouldUpdateHiddenStatueForPlusButtonLabel()")
    @nonobjc
    public func cyl_shouldUpdateHiddenStatueForPlusButtonLabel() -> Bool { cylShouldUpdateHiddenStatueForPlusButtonLabel() }

    /**
     [EN] Deprecated: renamed to `cylItemEdgeInsets`.
     [CN] 已废弃：已改名为 `cylItemEdgeInsets`。
     */
    @available(*, deprecated, renamed: "cylItemEdgeInsets")
    @nonobjc
    public var cyl_itemEdgeInsets: UIEdgeInsets {
        get { cylItemEdgeInsets }
        set { cylItemEdgeInsets = newValue }
    }

    /**
     [EN] Deprecated: renamed to `reloadTabButtons`.
     [CN] 已废弃：已改名为 `reloadTabButtons`。
     */
    @available(*, deprecated, renamed: "reloadTabButtons()")
    @nonobjc
    public func cyl_reloadTabButtons() { reloadTabButtons() }
}
