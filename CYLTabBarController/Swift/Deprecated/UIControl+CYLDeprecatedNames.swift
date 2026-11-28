//
//  UIControl+CYLDeprecatedNames.swift
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
#if canImport(CYLAnimatedItem)
import CYLAnimatedItem
#endif

// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

extension UIControl {
    /**
     [EN] Deprecated: renamed to `cylIsChildViewControllerPlusButton`.
     [CN] 已废弃：已改名为 `cylIsChildViewControllerPlusButton`。
     */
    @available(*, deprecated, renamed: "cylIsChildViewControllerPlusButton()")
    @nonobjc
    public func cyl_isChildViewControllerPlusButton() -> Bool { cylIsChildViewControllerPlusButton() }

    /**
     [EN] Deprecated: renamed to `cylIsSelected`.
     [CN] 已废弃：已改名为 `cylIsSelected`。
     */
    @available(*, deprecated, renamed: "cylIsSelected()")
    @nonobjc
    public func cyl_isSelected() -> Bool { cylIsSelected() }

    /**
     [EN] Deprecated: renamed to `cylIsPlusControl`.
     [CN] 已废弃：已改名为 `cylIsPlusControl`。
     */
    @available(*, deprecated, renamed: "cylIsPlusControl()")
    @nonobjc
    public func cyl_isPlusControl() -> Bool { cylIsPlusControl() }

    /**
     [EN] Deprecated: renamed to `cylReplaceTabImageView`.
     [CN] 已废弃：已改名为 `cylReplaceTabImageView`。
     */
    @available(*, deprecated, renamed: "cylReplaceTabImageView(withNewView:show:)")
    @nonobjc
    public func cyl_replaceTabImageView(withNewView newView: UIView, show: Bool) { cylReplaceTabImageView(withNewView: newView, show: show) }

    /**
     [EN] Deprecated: renamed to `cylReplaceTabImageView`.
     [CN] 已废弃：已改名为 `cylReplaceTabImageView`。
     */
    @available(*, deprecated, renamed: "cylReplaceTabImageView(withNewView:offset:show:completion:)")
    @nonobjc
    public func cyl_replaceTabImageView(withNewView newView: UIView, offset: UIOffset, show: Bool, completion: CYLTabButtonReplaceCompletion?) { cylReplaceTabImageView(withNewView: newView, offset: offset, show: show, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylReplaceTabButton`.
     [CN] 已废弃：已改名为 `cylReplaceTabButton`。
     */
    @available(*, deprecated, renamed: "cylReplaceTabButton(withNewView:show:)")
    @nonobjc
    public func cyl_replaceTabButton(withNewView newView: UIView, show: Bool) { cylReplaceTabButton(withNewView: newView, show: show) }

    /**
     [EN] Deprecated: renamed to `cylReplaceTabButton`.
     [CN] 已废弃：已改名为 `cylReplaceTabButton`。
     */
    @available(*, deprecated, renamed: "cylReplaceTabButton(withNewView:offset:show:completion:)")
    @nonobjc
    public func cyl_replaceTabButton(withNewView newView: UIView, offset: UIOffset, show: Bool, completion: CYLTabButtonReplaceCompletion?) { cylReplaceTabButton(withNewView: newView, offset: offset, show: show, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylCoverTabImageViewOrTabButton`.
     [CN] 已废弃：已改名为 `cylCoverTabImageViewOrTabButton`。
     */
    @available(*, deprecated, renamed: "cylCoverTabImageViewOrTabButton(_:newView:offset:show:delayIfNeededForSeconds:completion:)")
    @nonobjc
    public func cyl_coverTabImageViewOrTabButton(_ isTabButton: Bool, newView: UIView, offset: UIOffset, show: Bool, delayIfNeededForSeconds delay: CGFloat, completion: CYLTabButtonReplaceCompletion?) { cylCoverTabImageViewOrTabButton(isTabButton, newView: newView, offset: offset, show: show, delayIfNeededForSeconds: delay, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylCoverSeclectContentTabImageViewOrTabButton`.
     [CN] 已废弃：已改名为 `cylCoverSeclectContentTabImageViewOrTabButton`。
     */
    @available(*, deprecated, renamed: "cylCoverSeclectContentTabImageViewOrTabButton(_:newView:offset:show:delayIfNeededForSeconds:completion:)")
    @nonobjc
    public func cyl_coverSeclectContentTabImageViewOrTabButton(_ isTabButton: Bool, newView: UIView, offset: UIOffset, show: Bool, delayIfNeededForSeconds delay: CGFloat, completion: CYLTabButtonReplaceCompletion?) { cylCoverSeclectContentTabImageViewOrTabButton(isTabButton, newView: newView, offset: offset, show: show, delayIfNeededForSeconds: delay, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylCoverVisiableTabImageViewOrTabButton`.
     [CN] 已废弃：已改名为 `cylCoverVisiableTabImageViewOrTabButton`。
     */
    @available(*, deprecated, renamed: "cylCoverVisiableTabImageViewOrTabButton(_:newView:offset:show:delayIfNeededForSeconds:completion:)")
    @nonobjc
    public func cyl_coverVisiableTabImageViewOrTabButton(_ isTabButton: Bool, newView: UIView, offset: UIOffset, show: Bool, delayIfNeededForSeconds delay: CGFloat, completion: CYLTabButtonReplaceCompletion?) { cylCoverVisiableTabImageViewOrTabButton(isTabButton, newView: newView, offset: offset, show: show, delayIfNeededForSeconds: delay, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylCoverVisiableTabImageViewOrTabButton`.
     [CN] 已废弃：已改名为 `cylCoverVisiableTabImageViewOrTabButton`。
     */
    @available(*, deprecated, renamed: "cylCoverVisiableTabImageViewOrTabButton(_:contentNewView:seclectContentNewView:offset:show:delayIfNeededForSeconds:completion:)")
    @nonobjc
    public func cyl_coverVisiableTabImageViewOrTabButton(_ isTabButton: Bool, contentNewView: UIView, seclectContentNewView: UIView, offset: UIOffset, show: Bool, delayIfNeededForSeconds delay: CGFloat, completion: CYLTabButtonReplaceCompletion?) { cylCoverVisiableTabImageViewOrTabButton(isTabButton, contentNewView: contentNewView, seclectContentNewView: seclectContentNewView, offset: offset, show: show, delayIfNeededForSeconds: delay, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterSelectedControl`.
     [CN] 已废弃：已改名为 `cylIsPlatterSelectedControl`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterSelectedControl()")
    @nonobjc
    public func cyl_isPlatterSelectedControl() -> Bool { cylIsPlatterSelectedControl() }

    /**
     [EN] Deprecated: renamed to `cylPlatterSelected`.
     [CN] 已废弃：已改名为 `cylPlatterSelected`。
     */
    @available(*, deprecated, renamed: "cylPlatterSelected()")
    @nonobjc
    public func cyl_platterSelected() -> UIControl? { cylPlatterSelected() }

    /**
     [EN] Deprecated: renamed to `cylIsPlatterNormalControl`.
     [CN] 已废弃：已改名为 `cylIsPlatterNormalControl`。
     */
    @available(*, deprecated, renamed: "cylIsPlatterNormalControl()")
    @nonobjc
    public func cyl_isPlatterNormalControl() -> Bool { cylIsPlatterNormalControl() }

    /**
     [EN] Deprecated: renamed to `cylPlatterNormal`.
     [CN] 已废弃：已改名为 `cylPlatterNormal`。
     */
    @available(*, deprecated, renamed: "cylPlatterNormal()")
    @nonobjc
    public func cyl_platterNormal() -> UIControl { cylPlatterNormal() }

    /**
     [EN] Deprecated: renamed to `cylHideControl`.
     [CN] 已废弃：已改名为 `cylHideControl`。
     */
    @available(*, deprecated, renamed: "cylHideControl()")
    @nonobjc
    public func cyl_hideControl() { cylHideControl() }

    /**
     [EN] Deprecated: renamed to `cylLottieAnimationView`.
     [CN] 已废弃：已改名为 `cylLottieAnimationView`。
     */
    @available(*, deprecated, renamed: "cylLottieAnimationView()")
    @available(*, deprecated, message: "Use -cyl_tabBarItemAnimationView")
    @nonobjc
    public func cyl_lottieAnimationView() -> UIView? { cylLottieAnimationView() }

    /**
     [EN] Deprecated: renamed to `cylIsLottieReady`.
     [CN] 已废弃：已改名为 `cylIsLottieReady`。
     */
    @available(*, deprecated, renamed: "cylIsLottieReady()")
    @available(*, deprecated, message: "Use -cyl_isTabBarItemAnimationReady")
    @nonobjc
    public func cyl_isLottieReady() -> Bool { cylIsLottieReady() }

    /**
     [EN] Deprecated: renamed to `cylAddLottieImage`.
     [CN] 已废弃：已改名为 `cylAddLottieImage`。
     */
    @available(*, deprecated, renamed: "cylAddLottieImage(withLottieURL:size:contentMode:)")
    @available(*, deprecated, message: "Use -cyl_addTabBarItemAnimationWithURL:size:contentMode:")
    @nonobjc
    public func cyl_addLottieImage(withLottieURL lottieURL: URL?, size: CGSize, contentMode: UIView.ContentMode) { cylAddLottieImage(withLottieURL: lottieURL, size: size, contentMode: contentMode) }

    /**
     [EN] Deprecated: renamed to `cylAddLottieImage`.
     [CN] 已废弃：已改名为 `cylAddLottieImage`。
     */
    @available(*, deprecated, renamed: "cylAddLottieImage(withLottieFilePath:size:contentMode:)")
    @available(*, deprecated, message: "Use -cyl_addTabBarItemAnimationWithURL:size:contentMode: with a file URL")
    @nonobjc
    public func cyl_addLottieImage(withLottieFilePath lottieFilePath: String, size: CGSize, contentMode: UIView.ContentMode) { cylAddLottieImage(withLottieFilePath: lottieFilePath, size: size, contentMode: contentMode) }

    /**
     [EN] Deprecated: renamed to `cylAddLottieImage`.
     [CN] 已废弃：已改名为 `cylAddLottieImage`。
     */
    @available(*, deprecated, renamed: "cylAddLottieImage(withLottieURL:size:contentMode:animationSpeed:)")
    @available(*, deprecated, message: "Use -cyl_addTabBarItemAnimationWithURL:size:contentMode:animationSpeed:")
    @nonobjc
    public func cyl_addLottieImage(withLottieURL lottieURL: URL?, size: CGSize, contentMode: UIView.ContentMode, animationSpeed: CGFloat) { cylAddLottieImage(withLottieURL: lottieURL, size: size, contentMode: contentMode, animationSpeed: animationSpeed) }

    /**
     [EN] Deprecated: renamed to `cylSetLottieAnimationSpeed`.
     [CN] 已废弃：已改名为 `cylSetLottieAnimationSpeed`。
     */
    @available(*, deprecated, renamed: "cylSetLottieAnimationSpeed(_:)")
    @available(*, deprecated, message: "Use -cyl_setTabBarItemAnimationSpeed:")
    @nonobjc
    public func cyl_setLottieAnimationSpeed(_ animationSpeed: CGFloat) { cylSetLottieAnimationSpeed(animationSpeed) }

    /**
     [EN] Deprecated: renamed to `cylReloadLottieAnimationViewForCurrentStyle`.
     [CN] 已废弃：已改名为 `cylReloadLottieAnimationViewForCurrentStyle`。
     */
    @available(*, deprecated, renamed: "cylReloadLottieAnimationViewForCurrentStyle()")
    @available(*, deprecated, message: "Use -cyl_reloadTabBarItemAnimationViewForCurrentStyle")
    @nonobjc
    public func cyl_reloadLottieAnimationViewForCurrentStyle() { cylReloadLottieAnimationViewForCurrentStyle() }

    /**
     [EN] Deprecated: renamed to `cylAnimationLottieImage`.
     [CN] 已废弃：已改名为 `cylAnimationLottieImage`。
     */
    @available(*, deprecated, renamed: "cylAnimationLottieImage(withLottieURL:size:defaultSelected:contentMode:)")
    @available(*, deprecated, message: "Use -cyl_playTabBarItemAnimationWithURL:size:defaultSelected:contentMode:")
    @nonobjc
    public func cyl_animationLottieImage(withLottieURL lottieURL: URL, size: CGSize, defaultSelected: Bool, contentMode: UIView.ContentMode) { cylAnimationLottieImage(withLottieURL: lottieURL, size: size, defaultSelected: defaultSelected, contentMode: contentMode) }

    /**
     [EN] Deprecated: renamed to `cylStopAnimationOfLottieView`.
     [CN] 已废弃：已改名为 `cylStopAnimationOfLottieView`。
     */
    @available(*, deprecated, renamed: "cylStopAnimationOfLottieView()")
    @available(*, deprecated, message: "Use -cyl_stopTabBarItemAnimation")
    @nonobjc
    public func cyl_stopAnimationOfLottieView() { cylStopAnimationOfLottieView() }

    /**
     [EN] Deprecated: renamed to `cylShowTabBadgePoint`.
     [CN] 已废弃：已改名为 `cylShowTabBadgePoint`。
     */
    @available(*, deprecated, renamed: "cylShowTabBadgePoint()")
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @nonobjc
    public func cyl_showTabBadgePoint() { cylShowTabBadgePoint() }

    /**
     [EN] Deprecated: renamed to `cylRemoveTabBadgePoint`.
     [CN] 已废弃：已改名为 `cylRemoveTabBadgePoint`。
     */
    @available(*, deprecated, renamed: "cylRemoveTabBadgePoint()")
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @nonobjc
    public func cyl_removeTabBadgePoint() { cylRemoveTabBadgePoint() }

    /**
     [EN] Deprecated: renamed to `cylIsShowTabBadgePoint`.
     [CN] 已废弃：已改名为 `cylIsShowTabBadgePoint`。
     */
    @available(*, deprecated, renamed: "cylIsShowTabBadgePoint()")
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.")
    @nonobjc
    public func cyl_isShowTabBadgePoint() -> Bool { cylIsShowTabBadgePoint() }

    /**
     [EN] Deprecated: renamed to `cylTabBarItemAnimationView`.
     [CN] 已废弃：已改名为 `cylTabBarItemAnimationView`。
     */
    @available(*, deprecated, renamed: "cylTabBarItemAnimationView()")
    @nonobjc
    public func cyl_tabBarItemAnimationView() -> UIView? { cylTabBarItemAnimationView() }

    /**
     [EN] Deprecated: renamed to `cylIsTabBarItemAnimationReady`.
     [CN] 已废弃：已改名为 `cylIsTabBarItemAnimationReady`。
     */
    @available(*, deprecated, renamed: "cylIsTabBarItemAnimationReady()")
    @nonobjc
    public func cyl_isTabBarItemAnimationReady() -> Bool { cylIsTabBarItemAnimationReady() }

    /**
     [EN] Deprecated: renamed to `cylAddTabBarItemAnimation`.
     [CN] 已废弃：已改名为 `cylAddTabBarItemAnimation`。
     */
    @available(*, deprecated, renamed: "cylAddTabBarItemAnimation(with:size:contentMode:)")
    @nonobjc
    public func cyl_addTabBarItemAnimation(with url: URL?, size: CGSize, contentMode: UIView.ContentMode) { cylAddTabBarItemAnimation(with: url, size: size, contentMode: contentMode) }

    /**
     [EN] Deprecated: renamed to `cylAddTabBarItemAnimation`.
     [CN] 已废弃：已改名为 `cylAddTabBarItemAnimation`。
     */
    @available(*, deprecated, renamed: "cylAddTabBarItemAnimation(with:size:contentMode:animationSpeed:)")
    @nonobjc
    public func cyl_addTabBarItemAnimation(with url: URL?, size: CGSize, contentMode: UIView.ContentMode, animationSpeed: CGFloat) { cylAddTabBarItemAnimation(with: url, size: size, contentMode: contentMode, animationSpeed: animationSpeed) }

    /**
     [EN] Deprecated: renamed to `cylSetTabBarItemAnimationSpeed`.
     [CN] 已废弃：已改名为 `cylSetTabBarItemAnimationSpeed`。
     */
    @available(*, deprecated, renamed: "cylSetTabBarItemAnimationSpeed(_:)")
    @nonobjc
    public func cyl_setTabBarItemAnimationSpeed(_ animationSpeed: CGFloat) { cylSetTabBarItemAnimationSpeed(animationSpeed) }

    /**
     [EN] Deprecated: renamed to `cylSetTabBarItemAnimationLoops`.
     [CN] 已废弃：已改名为 `cylSetTabBarItemAnimationLoops`。
     */
    @available(*, deprecated, renamed: "cylSetTabBarItemAnimationLoops(_:)")
    @nonobjc
    public func cyl_setTabBarItemAnimationLoops(_ loops: Bool) { cylSetTabBarItemAnimationLoops(loops) }

    /**
     [EN] Deprecated: renamed to `cylRestartTabBarItemAnimation`.
     [CN] 已废弃：已改名为 `cylRestartTabBarItemAnimation`。
     */
    @available(*, deprecated, renamed: "cylRestartTabBarItemAnimation()")
    @nonobjc
    public func cyl_restartTabBarItemAnimation() { cylRestartTabBarItemAnimation() }

    /**
     [EN] Deprecated: renamed to `cylReloadTabBarItemAnimationViewForCurrentStyle`.
     [CN] 已废弃：已改名为 `cylReloadTabBarItemAnimationViewForCurrentStyle`。
     */
    @available(*, deprecated, renamed: "cylReloadTabBarItemAnimationViewForCurrentStyle()")
    @nonobjc
    public func cyl_reloadTabBarItemAnimationViewForCurrentStyle() { cylReloadTabBarItemAnimationViewForCurrentStyle() }

    /**
     [EN] Deprecated: renamed to `cylReplaceTabBarItemAnimation`.
     [CN] 已废弃：已改名为 `cylReplaceTabBarItemAnimation`。
     */
    @available(*, deprecated, renamed: "cylReplaceTabBarItemAnimation(with:size:contentMode:)")
    @nonobjc
    public func cyl_replaceTabBarItemAnimation(with url: URL, size: CGSize, contentMode: UIView.ContentMode) { cylReplaceTabBarItemAnimation(with: url, size: size, contentMode: contentMode) }

    /**
     [EN] Deprecated: renamed to `cylRefreshTabBarItemAnimationColors`.
     [CN] 已废弃：已改名为 `cylRefreshTabBarItemAnimationColors`。
     */
    @available(*, deprecated, renamed: "cylRefreshTabBarItemAnimationColors()")
    @nonobjc
    public func cyl_refreshTabBarItemAnimationColors() { cylRefreshTabBarItemAnimationColors() }

    /**
     [EN] Deprecated: renamed to `cylPlayTabBarItemAnimation`.
     [CN] 已废弃：已改名为 `cylPlayTabBarItemAnimation`。
     */
    @available(*, deprecated, renamed: "cylPlayTabBarItemAnimation(with:size:defaultSelected:contentMode:)")
    @nonobjc
    public func cyl_playTabBarItemAnimation(with url: URL, size: CGSize, defaultSelected: Bool, contentMode: UIView.ContentMode) { cylPlayTabBarItemAnimation(with: url, size: size, defaultSelected: defaultSelected, contentMode: contentMode) }

    /**
     [EN] Deprecated: renamed to `cylStopTabBarItemAnimation`.
     [CN] 已废弃：已改名为 `cylStopTabBarItemAnimation`。
     */
    @available(*, deprecated, renamed: "cylStopTabBarItemAnimation()")
    @nonobjc
    public func cyl_stopTabBarItemAnimation() { cylStopTabBarItemAnimation() }
}
