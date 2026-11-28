//
//  CYLConstants+Keys+CYLDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation
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

/**
 [EN] Deprecated: renamed to `cylTabBarItemTitle`.
 [CN] 已废弃：已改名为 `cylTabBarItemTitle`。
 */
@available(*, deprecated, renamed: "cylTabBarItemTitle")
public let CYLTabBarItemTitle = cylTabBarItemTitle

/**
 [EN] Deprecated: renamed to `cylTabBarItemSelectedTitle`.
 [CN] 已废弃：已改名为 `cylTabBarItemSelectedTitle`。
 */
@available(*, deprecated, renamed: "cylTabBarItemSelectedTitle")
public let CYLTabBarItemSelectedTitle = cylTabBarItemSelectedTitle

/**
 [EN] Deprecated: renamed to `cylTabBarItemImage`.
 [CN] 已废弃：已改名为 `cylTabBarItemImage`。
 */
@available(*, deprecated, renamed: "cylTabBarItemImage")
public let CYLTabBarItemImage = cylTabBarItemImage

/**
 [EN] Deprecated: renamed to `cylTabBarItemSelectedImage`.
 [CN] 已废弃：已改名为 `cylTabBarItemSelectedImage`。
 */
@available(*, deprecated, renamed: "cylTabBarItemSelectedImage")
public let CYLTabBarItemSelectedImage = cylTabBarItemSelectedImage

/**
 [EN] Deprecated: renamed to `cylTabBarItemDarkImage`.
 [CN] 已废弃：已改名为 `cylTabBarItemDarkImage`。
 */
@available(*, deprecated, renamed: "cylTabBarItemDarkImage")
public let CYLTabBarItemDarkImage = cylTabBarItemDarkImage

/**
 [EN] Deprecated: renamed to `cylTabBarItemSelectedDarkImage`.
 [CN] 已废弃：已改名为 `cylTabBarItemSelectedDarkImage`。
 */
@available(*, deprecated, renamed: "cylTabBarItemSelectedDarkImage")
public let CYLTabBarItemSelectedDarkImage = cylTabBarItemSelectedDarkImage

/**
 [EN] Deprecated: renamed to `cylTabBarItemImageURL`.
 [CN] 已废弃：已改名为 `cylTabBarItemImageURL`。
 */
@available(*, deprecated, renamed: "cylTabBarItemImageURL")
public let CYLTabBarItemImageURL = cylTabBarItemImageURL

/**
 [EN] Deprecated: renamed to `cylTabBarItemSelectedImageURL`.
 [CN] 已废弃：已改名为 `cylTabBarItemSelectedImageURL`。
 */
@available(*, deprecated, renamed: "cylTabBarItemSelectedImageURL")
public let CYLTabBarItemSelectedImageURL = cylTabBarItemSelectedImageURL

/**
 [EN] Deprecated: renamed to `cylTabBarItemImageURLSize`.
 [CN] 已废弃：已改名为 `cylTabBarItemImageURLSize`。
 */
@available(*, deprecated, renamed: "cylTabBarItemImageURLSize")
public let CYLTabBarItemImageURLSize = cylTabBarItemImageURLSize

/**
 [EN] Deprecated: renamed to `cylTabBarAnimationURL`.
 [CN] 已废弃：已改名为 `cylTabBarAnimationURL`。
 */
@available(*, deprecated, renamed: "cylTabBarAnimationURL")
public let CYLTabBarAnimationURL = cylTabBarAnimationURL

/**
 [EN] Deprecated: renamed to `cylTabBarAnimationFilePath`.
 [CN] 已废弃：已改名为 `cylTabBarAnimationFilePath`。
 */
@available(*, deprecated, renamed: "cylTabBarAnimationFilePath")
public let CYLTabBarAnimationFilePath = cylTabBarAnimationFilePath

/**
 [EN] Deprecated: renamed to `cylTabBarAnimationSize`.
 [CN] 已废弃：已改名为 `cylTabBarAnimationSize`。
 */
@available(*, deprecated, renamed: "cylTabBarAnimationSize")
public let CYLTabBarAnimationSize = cylTabBarAnimationSize

/**
 [EN] Deprecated: renamed to `cylTabBarAnimationDarkURL`.
 [CN] 已废弃：已改名为 `cylTabBarAnimationDarkURL`。
 */
@available(*, deprecated, renamed: "cylTabBarAnimationDarkURL")
public let CYLTabBarAnimationDarkURL = cylTabBarAnimationDarkURL

/**
 [EN] Deprecated: renamed to `cylTabBarAnimationDarkFilePath`.
 [CN] 已废弃：已改名为 `cylTabBarAnimationDarkFilePath`。
 */
@available(*, deprecated, renamed: "cylTabBarAnimationDarkFilePath")
public let CYLTabBarAnimationDarkFilePath = cylTabBarAnimationDarkFilePath

/**
 [EN] Deprecated: renamed to `cylTabBarAnimationDarkColors`.
 [CN] 已废弃：已改名为 `cylTabBarAnimationDarkColors`。
 */
@available(*, deprecated, renamed: "cylTabBarAnimationDarkColors")
public let CYLTabBarAnimationDarkColors = cylTabBarAnimationDarkColors

/**
 [EN] Deprecated: renamed to `cylTabBarAnimationColors`.
 [CN] 已废弃：已改名为 `cylTabBarAnimationColors`。
 */
@available(*, deprecated, renamed: "cylTabBarAnimationColors")
public let CYLTabBarAnimationColors = cylTabBarAnimationColors

/**
 [EN] Deprecated: renamed to `cylTabBarItemImageInsets`.
 [CN] 已废弃：已改名为 `cylTabBarItemImageInsets`。
 */
@available(*, deprecated, renamed: "cylTabBarItemImageInsets")
public let CYLTabBarItemImageInsets = cylTabBarItemImageInsets

/**
 [EN] Deprecated: renamed to `cylTabBarItemTitlePositionAdjustment`.
 [CN] 已废弃：已改名为 `cylTabBarItemTitlePositionAdjustment`。
 */
@available(*, deprecated, renamed: "cylTabBarItemTitlePositionAdjustment")
public let CYLTabBarItemTitlePositionAdjustment = cylTabBarItemTitlePositionAdjustment

/**
 [EN] Deprecated: renamed to `cylTabBarItemImagePositionAdjustment`.
 [CN] 已废弃：已改名为 `cylTabBarItemImagePositionAdjustment`。
 */
@available(*, deprecated, renamed: "cylTabBarItemImagePositionAdjustment")
public let CYLTabBarItemImagePositionAdjustment = cylTabBarItemImagePositionAdjustment

/**
 [EN] Deprecated: renamed to `cylTabBarItemIdentifier`.
 [CN] 已废弃：已改名为 `cylTabBarItemIdentifier`。
 */
@available(*, deprecated, renamed: "cylTabBarItemIdentifier")
public let CYLTabBarItemIdentifier = cylTabBarItemIdentifier

/**
 [EN] Deprecated: renamed to `cylTabBarControllerViewControllers`.
 [CN] 已废弃：已改名为 `cylTabBarControllerViewControllers`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerViewControllers")
public let CYLTabBarControllerViewControllers = cylTabBarControllerViewControllers

/**
 [EN] Deprecated: renamed to `cylTabBarControllerTabBarItemsAttributes`.
 [CN] 已废弃：已改名为 `cylTabBarControllerTabBarItemsAttributes`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerTabBarItemsAttributes")
public let CYLTabBarControllerTabBarItemsAttributes = cylTabBarControllerTabBarItemsAttributes

/**
 [EN] Deprecated: renamed to `cylTabBarControllerImageInsets`.
 [CN] 已废弃：已改名为 `cylTabBarControllerImageInsets`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerImageInsets")
public let CYLTabBarControllerImageInsets = cylTabBarControllerImageInsets

/**
 [EN] Deprecated: renamed to `cylTabBarControllerTitlePositionAdjustment`.
 [CN] 已废弃：已改名为 `cylTabBarControllerTitlePositionAdjustment`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerTitlePositionAdjustment")
public let CYLTabBarControllerTitlePositionAdjustment = cylTabBarControllerTitlePositionAdjustment

/**
 [EN] Deprecated: renamed to `cylTabBarControllerStyleType`.
 [CN] 已废弃：已改名为 `cylTabBarControllerStyleType`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerStyleType")
public let CYLTabBarControllerStyleType = cylTabBarControllerStyleType

/**
 [EN] Deprecated: renamed to `cylTabBarControllerContext`.
 [CN] 已废弃：已改名为 `cylTabBarControllerContext`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerContext")
public let CYLTabBarControllerContext = cylTabBarControllerContext

/**
 [EN] Deprecated: renamed to `cylTabBarControllerPageRegistry`.
 [CN] 已废弃：已改名为 `cylTabBarControllerPageRegistry`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerPageRegistry")
public let CYLTabBarControllerPageRegistry = cylTabBarControllerPageRegistry

/**
 [EN] Deprecated: renamed to `cylTabBarControllerPageResolver`.
 [CN] 已废弃：已改名为 `cylTabBarControllerPageResolver`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerPageResolver")
public let CYLTabBarControllerPageResolver = cylTabBarControllerPageResolver

/**
 [EN] Deprecated: renamed to `cylTabBarControllerPageLookupOrder`.
 [CN] 已废弃：已改名为 `cylTabBarControllerPageLookupOrder`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerPageLookupOrder")
public let CYLTabBarControllerPageLookupOrder = cylTabBarControllerPageLookupOrder

/**
 [EN] Deprecated: renamed to `cylTabBarControllerAutomaticPageRegistration`.
 [CN] 已废弃：已改名为 `cylTabBarControllerAutomaticPageRegistration`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerAutomaticPageRegistration")
public let CYLTabBarControllerAutomaticPageRegistration = cylTabBarControllerAutomaticPageRegistration

/**
 [EN] Deprecated: renamed to `cylTabBarControllerTabBarItemAnimationSpeed`.
 [CN] 已废弃：已改名为 `cylTabBarControllerTabBarItemAnimationSpeed`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerTabBarItemAnimationSpeed")
public let CYLTabBarControllerTabBarItemAnimationSpeed = cylTabBarControllerTabBarItemAnimationSpeed

/**
 [EN] Deprecated: renamed to `cylTabBarControllerPlusButton`.
 [CN] 已废弃：已改名为 `cylTabBarControllerPlusButton`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerPlusButton")
public let CYLTabBarControllerPlusButton = cylTabBarControllerPlusButton

/**
 [EN] Deprecated: renamed to `cylTabBarControllerPlusButtonAction`.
 [CN] 已废弃：已改名为 `cylTabBarControllerPlusButtonAction`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerPlusButtonAction")
public let CYLTabBarControllerPlusButtonAction = cylTabBarControllerPlusButtonAction

/**
 [EN] Deprecated: renamed to `cylPlusButtonBackgroundImage`.
 [CN] 已废弃：已改名为 `cylPlusButtonBackgroundImage`。
 */
@available(*, deprecated, renamed: "cylPlusButtonBackgroundImage")
public let CYLPlusButtonBackgroundImage = cylPlusButtonBackgroundImage

/**
 [EN] Deprecated: renamed to `cylPlusButtonIndexInTabBar`.
 [CN] 已废弃：已改名为 `cylPlusButtonIndexInTabBar`。
 */
@available(*, deprecated, renamed: "cylPlusButtonIndexInTabBar")
public let CYLPlusButtonIndexInTabBar = cylPlusButtonIndexInTabBar

/**
 [EN] Deprecated: renamed to `cylPlusButtonCenterYMultiplier`.
 [CN] 已废弃：已改名为 `cylPlusButtonCenterYMultiplier`。
 */
@available(*, deprecated, renamed: "cylPlusButtonCenterYMultiplier")
public let CYLPlusButtonCenterYMultiplier = cylPlusButtonCenterYMultiplier

/**
 [EN] Deprecated: renamed to `cylPlusButtonCenterYOffset`.
 [CN] 已废弃：已改名为 `cylPlusButtonCenterYOffset`。
 */
@available(*, deprecated, renamed: "cylPlusButtonCenterYOffset")
public let CYLPlusButtonCenterYOffset = cylPlusButtonCenterYOffset

/**
 [EN] Deprecated: renamed to `cylPlusButtonAlignsTitle`.
 [CN] 已废弃：已改名为 `cylPlusButtonAlignsTitle`。
 */
@available(*, deprecated, renamed: "cylPlusButtonAlignsTitle")
public let CYLPlusButtonAlignsTitle = cylPlusButtonAlignsTitle

/**
 [EN] Deprecated: renamed to `cylPlusButtonKeepsTitleVisible`.
 [CN] 已废弃：已改名为 `cylPlusButtonKeepsTitleVisible`。
 */
@available(*, deprecated, renamed: "cylPlusButtonKeepsTitleVisible")
public let CYLPlusButtonKeepsTitleVisible = cylPlusButtonKeepsTitleVisible

/**
 [EN] Deprecated: renamed to `cylPlusButtonShowsSelection`.
 [CN] 已废弃：已改名为 `cylPlusButtonShowsSelection`。
 */
@available(*, deprecated, renamed: "cylPlusButtonShowsSelection")
public let CYLPlusButtonShowsSelection = cylPlusButtonShowsSelection

/**
 [EN] Deprecated: renamed to `cylPlusButtonSize`.
 [CN] 已废弃：已改名为 `cylPlusButtonSize`。
 */
@available(*, deprecated, renamed: "cylPlusButtonSize")
public let CYLPlusButtonSize = cylPlusButtonSize

/**
 [EN] Deprecated: renamed to `cylPlusButtonImageSize`.
 [CN] 已废弃：已改名为 `cylPlusButtonImageSize`。
 */
@available(*, deprecated, renamed: "cylPlusButtonImageSize")
public let CYLPlusButtonImageSize = cylPlusButtonImageSize

/**
 [EN] Deprecated: renamed to `cylTabBarControllerUserInterfaceStyle`.
 [CN] 已废弃：已改名为 `cylTabBarControllerUserInterfaceStyle`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerUserInterfaceStyle")
public let CYLTabBarControllerUserInterfaceStyle = cylTabBarControllerUserInterfaceStyle

/**
 [EN] Deprecated: renamed to `cylTabBarControllerTabButtonTapAnimation`.
 [CN] 已废弃：已改名为 `cylTabBarControllerTabButtonTapAnimation`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerTabButtonTapAnimation")
public let CYLTabBarControllerTabButtonTapAnimation = cylTabBarControllerTabButtonTapAnimation

/**
 [EN] Deprecated: renamed to `cylTabBarControllerSwipeToSwitchTab`.
 [CN] 已废弃：已改名为 `cylTabBarControllerSwipeToSwitchTab`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerSwipeToSwitchTab")
public let CYLTabBarControllerSwipeToSwitchTab = cylTabBarControllerSwipeToSwitchTab

/**
 [EN] Deprecated: renamed to `cylTabBarControllerLoginRequiredTabBarItemIdentifiers`.
 [CN] 已废弃：已改名为 `cylTabBarControllerLoginRequiredTabBarItemIdentifiers`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerLoginRequiredTabBarItemIdentifiers")
public let CYLTabBarControllerLoginRequiredTabBarItemIdentifiers = cylTabBarControllerLoginRequiredTabBarItemIdentifiers

/**
 [EN] Deprecated: renamed to `cylTabBarControllerUnloadsUnselectedViewsOnMemoryWarning`.
 [CN] 已废弃：已改名为 `cylTabBarControllerUnloadsUnselectedViewsOnMemoryWarning`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerUnloadsUnselectedViewsOnMemoryWarning")
public let CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning = cylTabBarControllerUnloadsUnselectedViewsOnMemoryWarning

/**
 [EN] Deprecated: renamed to `cylTabBarControllerKeepsLoadedTabBarItemIdentifiers`.
 [CN] 已废弃：已改名为 `cylTabBarControllerKeepsLoadedTabBarItemIdentifiers`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerKeepsLoadedTabBarItemIdentifiers")
public let CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers = cylTabBarControllerKeepsLoadedTabBarItemIdentifiers

/**
 [EN] Deprecated: renamed to `cylTabBarControllerThemes`.
 [CN] 已废弃：已改名为 `cylTabBarControllerThemes`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerThemes")
public let CYLTabBarControllerThemes = cylTabBarControllerThemes

/**
 [EN] Deprecated: renamed to `cylTabBarControllerThemeIdentifier`.
 [CN] 已废弃：已改名为 `cylTabBarControllerThemeIdentifier`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerThemeIdentifier")
public let CYLTabBarControllerThemeIdentifier = cylTabBarControllerThemeIdentifier

/**
 [EN] Deprecated: renamed to `cylTabBarControllerDarkThemeIdentifier`.
 [CN] 已废弃：已改名为 `cylTabBarControllerDarkThemeIdentifier`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerDarkThemeIdentifier")
public let CYLTabBarControllerDarkThemeIdentifier = cylTabBarControllerDarkThemeIdentifier

/**
 [EN] Deprecated: renamed to `cylTabBarControllerThemeManagerName`.
 [CN] 已废弃：已改名为 `cylTabBarControllerThemeManagerName`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerThemeManagerName")
public let CYLTabBarControllerThemeManagerName = cylTabBarControllerThemeManagerName

/**
 [EN] Deprecated: renamed to `cylTabBarControllerLocalization`.
 [CN] 已废弃：已改名为 `cylTabBarControllerLocalization`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerLocalization")
public let CYLTabBarControllerLocalization = cylTabBarControllerLocalization

/**
 [EN] Deprecated: renamed to `cylTabBarControllerConfigurationRoute`.
 [CN] 已废弃：已改名为 `cylTabBarControllerConfigurationRoute`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerConfigurationRoute")
public let CYLTabBarControllerConfigurationRoute = cylTabBarControllerConfigurationRoute

/**
 [EN] Deprecated: renamed to `cylTabBarControllerManifestRoute`.
 [CN] 已废弃：已改名为 `cylTabBarControllerManifestRoute`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerManifestRoute")
public let CYLTabBarControllerManifestRoute = cylTabBarControllerManifestRoute

/**
 [EN] Deprecated: renamed to `cylTabBarLocalizationTableName`.
 [CN] 已废弃：已改名为 `cylTabBarLocalizationTableName`。
 */
@available(*, deprecated, renamed: "cylTabBarLocalizationTableName")
public let CYLTabBarLocalizationTableName = cylTabBarLocalizationTableName

/**
 [EN] Deprecated: renamed to `cylTabBarLocalizationPath`.
 [CN] 已废弃：已改名为 `cylTabBarLocalizationPath`。
 */
@available(*, deprecated, renamed: "cylTabBarLocalizationPath")
public let CYLTabBarLocalizationPath = cylTabBarLocalizationPath

/**
 [EN] Deprecated: renamed to `cylTabBarLocalizationBundleName`.
 [CN] 已废弃：已改名为 `cylTabBarLocalizationBundleName`。
 */
@available(*, deprecated, renamed: "cylTabBarLocalizationBundleName")
public let CYLTabBarLocalizationBundleName = cylTabBarLocalizationBundleName

/**
 [EN] Deprecated: renamed to `cylTabBarThemeIdentifier`.
 [CN] 已废弃：已改名为 `cylTabBarThemeIdentifier`。
 */
@available(*, deprecated, renamed: "cylTabBarThemeIdentifier")
public let CYLTabBarThemeIdentifier = cylTabBarThemeIdentifier

/**
 [EN] Deprecated: renamed to `cylTabBarThemeValues`.
 [CN] 已废弃：已改名为 `cylTabBarThemeValues`。
 */
@available(*, deprecated, renamed: "cylTabBarThemeValues")
public let CYLTabBarThemeValues = cylTabBarThemeValues

/**
 [EN] Deprecated: renamed to `cylTabBarBackgroundColor`.
 [CN] 已废弃：已改名为 `cylTabBarBackgroundColor`。
 */
@available(*, deprecated, renamed: "cylTabBarBackgroundColor")
public let CYLTabBarBackgroundColor = cylTabBarBackgroundColor

/**
 [EN] Deprecated: renamed to `cylTabBarShadowColor`.
 [CN] 已废弃：已改名为 `cylTabBarShadowColor`。
 */
@available(*, deprecated, renamed: "cylTabBarShadowColor")
public let CYLTabBarShadowColor = cylTabBarShadowColor

/**
 [EN] Deprecated: renamed to `cylTabBarBackgroundImage`.
 [CN] 已废弃：已改名为 `cylTabBarBackgroundImage`。
 */
@available(*, deprecated, renamed: "cylTabBarBackgroundImage")
public let CYLTabBarBackgroundImage = cylTabBarBackgroundImage

/**
 [EN] Deprecated: renamed to `cylTabBarShadowImage`.
 [CN] 已废弃：已改名为 `cylTabBarShadowImage`。
 */
@available(*, deprecated, renamed: "cylTabBarShadowImage")
public let CYLTabBarShadowImage = cylTabBarShadowImage

/**
 [EN] Deprecated: renamed to `cylTabBarStackedItemPositioning`.
 [CN] 已废弃：已改名为 `cylTabBarStackedItemPositioning`。
 */
@available(*, deprecated, renamed: "cylTabBarStackedItemPositioning")
public let CYLTabBarStackedItemPositioning = cylTabBarStackedItemPositioning

/**
 [EN] Deprecated: renamed to `cylTabBarStackedItemWidth`.
 [CN] 已废弃：已改名为 `cylTabBarStackedItemWidth`。
 */
@available(*, deprecated, renamed: "cylTabBarStackedItemWidth")
public let CYLTabBarStackedItemWidth = cylTabBarStackedItemWidth

/**
 [EN] Deprecated: renamed to `cylTabBarStackedItemSpacing`.
 [CN] 已废弃：已改名为 `cylTabBarStackedItemSpacing`。
 */
@available(*, deprecated, renamed: "cylTabBarStackedItemSpacing")
public let CYLTabBarStackedItemSpacing = cylTabBarStackedItemSpacing

/**
 [EN] Deprecated: renamed to `cylTabBarItemPageIdentifier`.
 [CN] 已废弃：已改名为 `cylTabBarItemPageIdentifier`。
 */
@available(*, deprecated, renamed: "cylTabBarItemPageIdentifier")
public let CYLTabBarItemPageIdentifier = cylTabBarItemPageIdentifier

/**
 [EN] Deprecated: renamed to `cylTabBarItemPageParameters`.
 [CN] 已废弃：已改名为 `cylTabBarItemPageParameters`。
 */
@available(*, deprecated, renamed: "cylTabBarItemPageParameters")
public let CYLTabBarItemPageParameters = cylTabBarItemPageParameters

/**
 [EN] Deprecated: renamed to `cylTabBarItemPlatforms`.
 [CN] 已废弃：已改名为 `cylTabBarItemPlatforms`。
 */
@available(*, deprecated, renamed: "cylTabBarItemPlatforms")
public let CYLTabBarItemPlatforms = cylTabBarItemPlatforms

/**
 [EN] Deprecated: renamed to `cylTabBarItemMinimumAppVersion`.
 [CN] 已废弃：已改名为 `cylTabBarItemMinimumAppVersion`。
 */
@available(*, deprecated, renamed: "cylTabBarItemMinimumAppVersion")
public let CYLTabBarItemMinimumAppVersion = cylTabBarItemMinimumAppVersion

/**
 [EN] Deprecated: renamed to `cylTabBarAnimationOptions`.
 [CN] 已废弃：已改名为 `cylTabBarAnimationOptions`。
 */
@available(*, deprecated, renamed: "cylTabBarAnimationOptions")
public let CYLTabBarAnimationOptions = cylTabBarAnimationOptions

/**
 [EN] Deprecated: renamed to `cylTabBarItemTitleColor`.
 [CN] 已废弃：已改名为 `cylTabBarItemTitleColor`。
 */
@available(*, deprecated, renamed: "cylTabBarItemTitleColor")
public let CYLTabBarItemTitleColor = cylTabBarItemTitleColor

/**
 [EN] Deprecated: renamed to `cylTabBarItemSelectedTitleColor`.
 [CN] 已废弃：已改名为 `cylTabBarItemSelectedTitleColor`。
 */
@available(*, deprecated, renamed: "cylTabBarItemSelectedTitleColor")
public let CYLTabBarItemSelectedTitleColor = cylTabBarItemSelectedTitleColor

/**
 [EN] Deprecated: renamed to `cylTabBarItemIconColor`.
 [CN] 已废弃：已改名为 `cylTabBarItemIconColor`。
 */
@available(*, deprecated, renamed: "cylTabBarItemIconColor")
public let CYLTabBarItemIconColor = cylTabBarItemIconColor

/**
 [EN] Deprecated: renamed to `cylTabBarItemSelectedIconColor`.
 [CN] 已废弃：已改名为 `cylTabBarItemSelectedIconColor`。
 */
@available(*, deprecated, renamed: "cylTabBarItemSelectedIconColor")
public let CYLTabBarItemSelectedIconColor = cylTabBarItemSelectedIconColor

/**
 [EN] Deprecated: renamed to `cylTabBarItemIconRenderingMode`.
 [CN] 已废弃：已改名为 `cylTabBarItemIconRenderingMode`。
 */
@available(*, deprecated, renamed: "cylTabBarItemIconRenderingMode")
public let CYLTabBarItemIconRenderingMode = cylTabBarItemIconRenderingMode

/**
 [EN] Deprecated: renamed to `cylTabBarControllerIconRenderingMode`.
 [CN] 已废弃：已改名为 `cylTabBarControllerIconRenderingMode`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerIconRenderingMode")
public let CYLTabBarControllerIconRenderingMode = cylTabBarControllerIconRenderingMode

/**
 [EN] Deprecated: renamed to `cylTabBarControllerIconColor`.
 [CN] 已废弃：已改名为 `cylTabBarControllerIconColor`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerIconColor")
public let CYLTabBarControllerIconColor = cylTabBarControllerIconColor

/**
 [EN] Deprecated: renamed to `cylTabBarControllerSelectedIconColor`.
 [CN] 已废弃：已改名为 `cylTabBarControllerSelectedIconColor`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerSelectedIconColor")
public let CYLTabBarControllerSelectedIconColor = cylTabBarControllerSelectedIconColor

/**
 [EN] Deprecated: renamed to `cylTabBarItemSelectedBackgroundColor`.
 [CN] 已废弃：已改名为 `cylTabBarItemSelectedBackgroundColor`。
 */
@available(*, deprecated, renamed: "cylTabBarItemSelectedBackgroundColor")
public let CYLTabBarItemSelectedBackgroundColor = cylTabBarItemSelectedBackgroundColor

/**
 [EN] Deprecated: renamed to `cylTabBarItemBackgroundColor`.
 [CN] 已废弃：已改名为 `cylTabBarItemBackgroundColor`。
 */
@available(*, deprecated, renamed: "cylTabBarItemBackgroundColor")
public let CYLTabBarItemBackgroundColor = cylTabBarItemBackgroundColor

/**
 [EN] Deprecated: renamed to `cylTabBarItemTitleFont`.
 [CN] 已废弃：已改名为 `cylTabBarItemTitleFont`。
 */
@available(*, deprecated, renamed: "cylTabBarItemTitleFont")
public let CYLTabBarItemTitleFont = cylTabBarItemTitleFont

/**
 [EN] Deprecated: renamed to `cylTabBarItemSelectedTitleFont`.
 [CN] 已废弃：已改名为 `cylTabBarItemSelectedTitleFont`。
 */
@available(*, deprecated, renamed: "cylTabBarItemSelectedTitleFont")
public let CYLTabBarItemSelectedTitleFont = cylTabBarItemSelectedTitleFont

/**
 [EN] Deprecated: renamed to `cylTabBarItemAccessibilityIdentifier`.
 [CN] 已废弃：已改名为 `cylTabBarItemAccessibilityIdentifier`。
 */
@available(*, deprecated, renamed: "cylTabBarItemAccessibilityIdentifier")
public let CYLTabBarItemAccessibilityIdentifier = cylTabBarItemAccessibilityIdentifier

/**
 [EN] Deprecated: renamed to `cylTabBarItemAccessibilityLabel`.
 [CN] 已废弃：已改名为 `cylTabBarItemAccessibilityLabel`。
 */
@available(*, deprecated, renamed: "cylTabBarItemAccessibilityLabel")
public let CYLTabBarItemAccessibilityLabel = cylTabBarItemAccessibilityLabel

/**
 [EN] Deprecated: renamed to `cylTabBarItemAccessibilityHint`.
 [CN] 已废弃：已改名为 `cylTabBarItemAccessibilityHint`。
 */
@available(*, deprecated, renamed: "cylTabBarItemAccessibilityHint")
public let CYLTabBarItemAccessibilityHint = cylTabBarItemAccessibilityHint

/**
 [EN] Deprecated: renamed to `cylTabBarItemWidthDidChangeNotification`.
 [CN] 已废弃：已改名为 `cylTabBarItemWidthDidChangeNotification`。
 */
@available(*, deprecated, renamed: "cylTabBarItemWidthDidChangeNotification")
public let CYLTabBarItemWidthDidChangeNotification = cylTabBarItemWidthDidChangeNotification

/**
 [EN] Deprecated: renamed to `cylTabBarControllerKey`.
 [CN] 已废弃：已改名为 `cylTabBarControllerKey`。
 */
@available(*, deprecated, renamed: "cylTabBarControllerKey")
public let CYLTabBarControllerKey = cylTabBarControllerKey

/**
 [EN] Deprecated: renamed to `cylTabBarItemViewControllerKey`.
 [CN] 已废弃：已改名为 `cylTabBarItemViewControllerKey`。
 */
@available(*, deprecated, renamed: "cylTabBarItemViewControllerKey")
public let CYLTabBarItemViewControllerKey = cylTabBarItemViewControllerKey

/**
 [EN] Deprecated: renamed to `cylTabBarItemKey`.
 [CN] 已废弃：已改名为 `cylTabBarItemKey`。
 */
@available(*, deprecated, renamed: "cylTabBarItemKey")
public let CYLTabBarItemKey = cylTabBarItemKey

/**
 [EN] Deprecated: renamed to `cylPlusButtonKey`.
 [CN] 已废弃：已改名为 `cylPlusButtonKey`。
 */
@available(*, deprecated, renamed: "cylPlusButtonKey")
public let CYLPlusButtonKey = cylPlusButtonKey

/**
 [EN] Deprecated: renamed to `cylTabBarItemOldTitleKey`.
 [CN] 已废弃：已改名为 `cylTabBarItemOldTitleKey`。
 */
@available(*, deprecated, renamed: "cylTabBarItemOldTitleKey")
public let CYLTabBarItemOldTitleKey = cylTabBarItemOldTitleKey

/**
 [EN] Deprecated: renamed to `cylTabBarItemChangedAttributesKey`.
 [CN] 已废弃：已改名为 `cylTabBarItemChangedAttributesKey`。
 */
@available(*, deprecated, renamed: "cylTabBarItemChangedAttributesKey")
public let CYLTabBarItemChangedAttributesKey = cylTabBarItemChangedAttributesKey

/**
 [EN] Deprecated: renamed to `cylTabBarItemIndexKey`.
 [CN] 已废弃：已改名为 `cylTabBarItemIndexKey`。
 */
@available(*, deprecated, renamed: "cylTabBarItemIndexKey")
public let CYLTabBarItemIndexKey = cylTabBarItemIndexKey

/**
 [EN] Deprecated: renamed to `cylTabBarItemIconViewProviderKey`.
 [CN] 已废弃：已改名为 `cylTabBarItemIconViewProviderKey`。
 */
@available(*, deprecated, renamed: "cylTabBarItemIconViewProviderKey")
public let CYLTabBarItemIconViewProviderKey = cylTabBarItemIconViewProviderKey

/**
 [EN] Deprecated: renamed to `cylTabBarThemeKey`.
 [CN] 已废弃：已改名为 `cylTabBarThemeKey`。
 */
@available(*, deprecated, renamed: "cylTabBarThemeKey")
public let CYLTabBarThemeKey = cylTabBarThemeKey

/**
 [EN] Deprecated: renamed to `cylTabBarItemIndexesKey`.
 [CN] 已废弃：已改名为 `cylTabBarItemIndexesKey`。
 */
@available(*, deprecated, renamed: "cylTabBarItemIndexesKey")
public let CYLTabBarItemIndexesKey = cylTabBarItemIndexesKey

/**
 [EN] Deprecated: renamed to `cylTabBarItemIdentifiersKey`.
 [CN] 已废弃：已改名为 `cylTabBarItemIdentifiersKey`。
 */
@available(*, deprecated, renamed: "cylTabBarItemIdentifiersKey")
public let CYLTabBarItemIdentifiersKey = cylTabBarItemIdentifiersKey

/**
 [EN] Deprecated: renamed to `cylTabBarHostBadgeValue`.
 [CN] 已废弃：已改名为 `cylTabBarHostBadgeValue`。
 */
@available(*, deprecated, renamed: "cylTabBarHostBadgeValue")
public let CYLTabBarHostBadgeValue = cylTabBarHostBadgeValue

/**
 [EN] Deprecated: renamed to `cylTabBarHostBadgeColor`.
 [CN] 已废弃：已改名为 `cylTabBarHostBadgeColor`。
 */
@available(*, deprecated, renamed: "cylTabBarHostBadgeColor")
public let CYLTabBarHostBadgeColor = cylTabBarHostBadgeColor

/**
 [EN] Deprecated: renamed to `cylTabBarHostBadgeAnimation`.
 [CN] 已废弃：已改名为 `cylTabBarHostBadgeAnimation`。
 */
@available(*, deprecated, renamed: "cylTabBarHostBadgeAnimation")
public let CYLTabBarHostBadgeAnimation = cylTabBarHostBadgeAnimation

/**
 [EN] Deprecated: renamed to `cylTabBarHostBadgeRadius`.
 [CN] 已废弃：已改名为 `cylTabBarHostBadgeRadius`。
 */
@available(*, deprecated, renamed: "cylTabBarHostBadgeRadius")
public let CYLTabBarHostBadgeRadius = cylTabBarHostBadgeRadius

/**
 [EN] Deprecated: renamed to `cylTabBarHostBadgeCenterOffset`.
 [CN] 已废弃：已改名为 `cylTabBarHostBadgeCenterOffset`。
 */
@available(*, deprecated, renamed: "cylTabBarHostBadgeCenterOffset")
public let CYLTabBarHostBadgeCenterOffset = cylTabBarHostBadgeCenterOffset

/**
 [EN] Deprecated: renamed to `cylSampleConfigurationURLString`.
 [CN] 已废弃：已改名为 `cylSampleConfigurationURLString`。
 */
@available(*, deprecated, renamed: "cylSampleConfigurationURLString")
public let CYLSampleConfigurationURLString = cylSampleConfigurationURLString
