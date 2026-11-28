//
//  UIViewController+CYLDeprecatedNames.swift
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

extension UIViewController {
    /**
     [EN] Deprecated: renamed to `cylLanguageCell`.
     [CN] 已废弃：已改名为 `cylLanguageCell`。
     */
    @available(*, deprecated, renamed: "cylLanguageCell(for:)")
    @nonobjc
    public func cyl_languageCell(for tableView: UITableView) -> UITableViewCell { cylLanguageCell(for: tableView) }

    /**
     [EN] Deprecated: renamed to `cylPresentLanguagePicker`.
     [CN] 已废弃：已改名为 `cylPresentLanguagePicker`。
     */
    @available(*, deprecated, renamed: "cylPresentLanguagePicker()")
    @nonobjc
    public func cyl_presentLanguagePicker() { cylPresentLanguagePicker() }

    /**
     [EN] Deprecated: renamed to `cylShowNavigationBadge`.
     [CN] 已废弃：已改名为 `cylShowNavigationBadge`。
     */
    @available(*, deprecated, renamed: "cylShowNavigationBadge(value:animationType:backgroundColor:)")
    @discardableResult
    @nonobjc
    public func cyl_showNavigationBadge(value: String, animationType: CYLBadgeAnimationType, backgroundColor: UIColor?) -> UIBarButtonItem { cylShowNavigationBadge(value: value, animationType: animationType, backgroundColor: backgroundColor) }

    /**
     [EN] Deprecated: renamed to `cylAddBadgeHelperTable`.
     [CN] 已废弃：已改名为 `cylAddBadgeHelperTable`。
     */
    @available(*, deprecated, renamed: "cylAddBadgeHelperTable()")
    @nonobjc
    public func cyl_addBadgeHelperTable() { cylAddBadgeHelperTable() }

    /**
     [EN] Deprecated: renamed to `cylSampleConfigurationFilePaths`.
     [CN] 已废弃：已改名为 `cylSampleConfigurationFilePaths`。
     */
    @available(*, deprecated, renamed: "cylSampleConfigurationFilePaths()")
    @nonobjc
    public class func cyl_sampleConfigurationFilePaths() -> [String] { Self.cylSampleConfigurationFilePaths() }

    /**
     [EN] Deprecated: renamed to `cylConfigurationDemoCell`.
     [CN] 已废弃：已改名为 `cylConfigurationDemoCell`。
     */
    @available(*, deprecated, renamed: "cylConfigurationDemoCell(for:)")
    @nonobjc
    public func cyl_configurationDemoCell(for tableView: UITableView) -> UITableViewCell { cylConfigurationDemoCell(for: tableView) }

    /**
     [EN] Deprecated: renamed to `cylPresentConfigurationDemo`.
     [CN] 已废弃：已改名为 `cylPresentConfigurationDemo`。
     */
    @available(*, deprecated, renamed: "cylPresentConfigurationDemo()")
    @nonobjc
    public func cyl_presentConfigurationDemo() { cylPresentConfigurationDemo() }

    /**
     [EN] Deprecated: renamed to `cylConfigurationEdgeCaseSectionTitle`.
     [CN] 已废弃：已改名为 `cylConfigurationEdgeCaseSectionTitle`。
     */
    @available(*, deprecated, renamed: "cylConfigurationEdgeCaseSectionTitle()")
    @nonobjc
    public class func cyl_configurationEdgeCaseSectionTitle() -> String { Self.cylConfigurationEdgeCaseSectionTitle() }

    /**
     [EN] Deprecated: renamed to `cylConfigurationEdgeCaseRowCount`.
     [CN] 已废弃：已改名为 `cylConfigurationEdgeCaseRowCount`。
     */
    @available(*, deprecated, renamed: "cylConfigurationEdgeCaseRowCount()")
    @nonobjc
    public func cyl_configurationEdgeCaseRowCount() -> Int { cylConfigurationEdgeCaseRowCount() }

    /**
     [EN] Deprecated: renamed to `cylConfigurationEdgeCaseCell`.
     [CN] 已废弃：已改名为 `cylConfigurationEdgeCaseCell`。
     */
    @available(*, deprecated, renamed: "cylConfigurationEdgeCaseCell(for:row:)")
    @nonobjc
    public func cyl_configurationEdgeCaseCell(for tableView: UITableView, row: Int) -> UITableViewCell { cylConfigurationEdgeCaseCell(for: tableView, row: row) }

    /**
     [EN] Deprecated: renamed to `cylRunConfigurationEdgeCase`.
     [CN] 已废弃：已改名为 `cylRunConfigurationEdgeCase`。
     */
    @available(*, deprecated, renamed: "cylRunConfigurationEdgeCase(atRow:)")
    @nonobjc
    public func cyl_runConfigurationEdgeCase(atRow row: Int) { cylRunConfigurationEdgeCase(atRow: row) }

    /**
     [EN] Deprecated: renamed to `cylMemoryWarningCell`.
     [CN] 已废弃：已改名为 `cylMemoryWarningCell`。
     */
    @available(*, deprecated, renamed: "cylMemoryWarningCell(for:)")
    @nonobjc
    public func cyl_memoryWarningCell(for tableView: UITableView) -> UITableViewCell { cylMemoryWarningCell(for: tableView) }

    /**
     [EN] Deprecated: renamed to `cylSimulateMemoryWarningAndShowResult`.
     [CN] 已废弃：已改名为 `cylSimulateMemoryWarningAndShowResult`。
     */
    @available(*, deprecated, renamed: "cylSimulateMemoryWarningAndShowResult()")
    @nonobjc
    public func cyl_simulateMemoryWarningAndShowResult() { cylSimulateMemoryWarningAndShowResult() }

    /**
     [EN] Deprecated: renamed to `cylDisableInteractivePopGestureRecognizer`.
     [CN] 已废弃：已改名为 `cylDisableInteractivePopGestureRecognizer`。
     */
    @available(*, deprecated, renamed: "cylDisableInteractivePopGestureRecognizer()")
    @nonobjc
    public func cyl_disableInteractivePopGestureRecognizer() { cylDisableInteractivePopGestureRecognizer() }

    /**
     [EN] Deprecated: renamed to `cylEnableInteractivePopGestureRecognizer`.
     [CN] 已废弃：已改名为 `cylEnableInteractivePopGestureRecognizer`。
     */
    @available(*, deprecated, renamed: "cylEnableInteractivePopGestureRecognizer()")
    @nonobjc
    public func cyl_enableInteractivePopGestureRecognizer() { cylEnableInteractivePopGestureRecognizer() }

    /**
     [EN] Deprecated: renamed to `cylResetInteractivePopGestureRecognizer`.
     [CN] 已废弃：已改名为 `cylResetInteractivePopGestureRecognizer`。
     */
    @available(*, deprecated, renamed: "cylResetInteractivePopGestureRecognizer()")
    @nonobjc
    public func cyl_resetInteractivePopGestureRecognizer() { cylResetInteractivePopGestureRecognizer() }

    /**
     [EN] Deprecated: renamed to `cylHideNavigationBarSeparatorIfNeeded`.
     [CN] 已废弃：已改名为 `cylHideNavigationBarSeparatorIfNeeded`。
     */
    @available(*, deprecated, renamed: "cylHideNavigationBarSeparatorIfNeeded()")
    @nonobjc
    public func cyl_hideNavigationBarSeparatorIfNeeded() { cylHideNavigationBarSeparatorIfNeeded() }

    /**
     [EN] Deprecated: renamed to `cylShouldNavigationBarVisible`.
     [CN] 已废弃：已改名为 `cylShouldNavigationBarVisible`。
     */
    @available(*, deprecated, renamed: "cylShouldNavigationBarVisible()")
    @nonobjc
    public func cyl_shouldNavigationBarVisible() -> Bool { cylShouldNavigationBarVisible() }

    /**
     [EN] Deprecated: renamed to `cylSetNavigationBarVisibleIfNeeded`.
     [CN] 已废弃：已改名为 `cylSetNavigationBarVisibleIfNeeded`。
     */
    @available(*, deprecated, renamed: "cylSetNavigationBarVisibleIfNeeded(_:)")
    @nonobjc
    public func cyl_setNavigationBarVisibleIfNeeded(_ animated: Bool) { cylSetNavigationBarVisibleIfNeeded(animated) }

    /**
     [EN] Deprecated: renamed to `cylSetNavigationBarHiddenIfNeeded`.
     [CN] 已废弃：已改名为 `cylSetNavigationBarHiddenIfNeeded`。
     */
    @available(*, deprecated, renamed: "cylSetNavigationBarHiddenIfNeeded(_:)")
    @nonobjc
    public func cyl_setNavigationBarHiddenIfNeeded(_ animated: Bool) { cylSetNavigationBarHiddenIfNeeded(animated) }

    /**
     [EN] Deprecated: renamed to `cylViewWillAppearNavigationSetting`.
     [CN] 已废弃：已改名为 `cylViewWillAppearNavigationSetting`。
     */
    @available(*, deprecated, renamed: "cylViewWillAppearNavigationSetting(_:)")
    @nonobjc
    public func cyl_viewWillAppearNavigationSetting(_ animated: Bool) { cylViewWillAppearNavigationSetting(animated) }

    /**
     [EN] Deprecated: renamed to `cylViewWillDisappearNavigationSetting`.
     [CN] 已废弃：已改名为 `cylViewWillDisappearNavigationSetting`。
     */
    @available(*, deprecated, renamed: "cylViewWillDisappearNavigationSetting(_:)")
    @nonobjc
    public func cyl_viewWillDisappearNavigationSetting(_ animated: Bool) { cylViewWillDisappearNavigationSetting(animated) }

    /**
     [EN] Deprecated: renamed to `cylViewDidDisappearNavigationSetting`.
     [CN] 已废弃：已改名为 `cylViewDidDisappearNavigationSetting`。
     */
    @available(*, deprecated, renamed: "cylViewDidDisappearNavigationSetting(_:)")
    @nonobjc
    public func cyl_viewDidDisappearNavigationSetting(_ animated: Bool) { cylViewDidDisappearNavigationSetting(animated) }

    /**
     [EN] Deprecated: renamed to `cylViewDidAppearNavigationSetting`.
     [CN] 已废弃：已改名为 `cylViewDidAppearNavigationSetting`。
     */
    @available(*, deprecated, renamed: "cylViewDidAppearNavigationSetting(_:)")
    @nonobjc
    public func cyl_viewDidAppearNavigationSetting(_ p0: Bool) { cylViewDidAppearNavigationSetting(p0) }

    /**
     [EN] Deprecated: renamed to `cylDeallocNavigationSetting`.
     [CN] 已废弃：已改名为 `cylDeallocNavigationSetting`。
     */
    @available(*, deprecated, renamed: "cylDeallocNavigationSetting()")
    @nonobjc
    public func cyl_deallocNavigationSetting() { cylDeallocNavigationSetting() }

    /**
     [EN] Deprecated: renamed to `cylScrollHideSimulationRowCount`.
     [CN] 已废弃：已改名为 `cylScrollHideSimulationRowCount`。
     */
    @available(*, deprecated, renamed: "cylScrollHideSimulationRowCount()")
    @nonobjc
    public func cyl_scrollHideSimulationRowCount() -> Int { cylScrollHideSimulationRowCount() }

    /**
     [EN] Deprecated: renamed to `cylScrollHideSimulationCell`.
     [CN] 已废弃：已改名为 `cylScrollHideSimulationCell`。
     */
    @available(*, deprecated, renamed: "cylScrollHideSimulationCell(for:row:)")
    @nonobjc
    public func cyl_scrollHideSimulationCell(for tableView: UITableView, row: Int) -> UITableViewCell { cylScrollHideSimulationCell(for: tableView, row: row) }

    /**
     [EN] Deprecated: renamed to `cylDidSelectScrollHideSimulationRow`.
     [CN] 已废弃：已改名为 `cylDidSelectScrollHideSimulationRow`。
     */
    @available(*, deprecated, renamed: "cylDidSelectScrollHideSimulationRow(_:)")
    @nonobjc
    public func cyl_didSelectScrollHideSimulationRow(_ row: Int) { cylDidSelectScrollHideSimulationRow(row) }

    /**
     [EN] Deprecated: renamed to `cylPresentScrollHideSimulationMenu`.
     [CN] 已废弃：已改名为 `cylPresentScrollHideSimulationMenu`。
     */
    @available(*, deprecated, renamed: "cylPresentScrollHideSimulationMenu()")
    @nonobjc
    public func cyl_presentScrollHideSimulationMenu() { cylPresentScrollHideSimulationMenu() }

    /**
     [EN] Deprecated: renamed to `cylRunScrollHideSelfTest`.
     [CN] 已废弃：已改名为 `cylRunScrollHideSelfTest`。
     */
    @available(*, deprecated, renamed: "cylRunScrollHideSelfTest()")
    @nonobjc
    public func cyl_runScrollHideSelfTest() { cylRunScrollHideSelfTest() }

    /**
     [EN] Deprecated: renamed to `cylSettingsRowCount`.
     [CN] 已废弃：已改名为 `cylSettingsRowCount`。
     */
    @available(*, deprecated, renamed: "cylSettingsRowCount()")
    @nonobjc
    public func cyl_settingsRowCount() -> Int { cylSettingsRowCount() }

    /**
     [EN] Deprecated: renamed to `cylSettingsCell`.
     [CN] 已废弃：已改名为 `cylSettingsCell`。
     */
    @available(*, deprecated, renamed: "cylSettingsCell(for:at:)")
    @nonobjc
    public func cyl_settingsCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell { cylSettingsCell(for: tableView, at: indexPath) }

    /**
     [EN] Deprecated: renamed to `cylSettingsGroups`.
     [CN] 已废弃：已改名为 `cylSettingsGroups`。
     */
    @available(*, deprecated, renamed: "cylSettingsGroups()")
    @nonobjc
    public func cyl_settingsGroups() -> [NSNumber] { cylSettingsGroups() }

    /**
     [EN] Deprecated: renamed to `cylTitle`.
     [CN] 已废弃：已改名为 `cylTitle`。
     */
    @available(*, deprecated, renamed: "cylTitle(for:)")
    @nonobjc
    public func cyl_title(for group: CYLSettingsGroup) -> String { cylTitle(for: group) }

    /**
     [EN] Deprecated: renamed to `cylSettingsRows`.
     [CN] 已废弃：已改名为 `cylSettingsRows`。
     */
    @available(*, deprecated, renamed: "cylSettingsRows(in:)")
    @nonobjc
    public func cyl_settingsRows(in group: CYLSettingsGroup) -> [NSNumber] { cylSettingsRows(in: group) }

    /**
     [EN] Deprecated: renamed to `cylSettingsCell`.
     [CN] 已废弃：已改名为 `cylSettingsCell`。
     */
    @available(*, deprecated, renamed: "cylSettingsCell(for:row:)")
    @nonobjc
    public func cyl_settingsCell(for tableView: UITableView, row: Int) -> UITableViewCell { cylSettingsCell(for: tableView, row: row) }

    /**
     [EN] Deprecated: renamed to `cylDidSelectSettingsRow`.
     [CN] 已废弃：已改名为 `cylDidSelectSettingsRow`。
     */
    @available(*, deprecated, renamed: "cylDidSelectSettingsRow(_:)")
    @nonobjc
    public func cyl_didSelectSettingsRow(_ row: Int) { cylDidSelectSettingsRow(row) }

    /**
     [EN] Deprecated: renamed to `cylDidSelectSettingsRow`.
     [CN] 已废弃：已改名为 `cylDidSelectSettingsRow`。
     */
    @available(*, deprecated, renamed: "cylDidSelectSettingsRow(at:in:)")
    @nonobjc
    public func cyl_didSelectSettingsRow(at indexPath: IndexPath, in tableView: UITableView) { cylDidSelectSettingsRow(at: indexPath, in: tableView) }

    /**
     [EN] Deprecated: renamed to `cylIsSystemStyleTabBar`.
     [CN] 已废弃：已改名为 `cylIsSystemStyleTabBar`。
     */
    @available(*, deprecated, renamed: "cylIsSystemStyleTabBar()")
    @nonobjc
    public func cyl_isSystemStyleTabBar() -> Bool { cylIsSystemStyleTabBar() }

    /**
     [EN] Deprecated: renamed to `cylIsFlatDesignStyleTabBar`.
     [CN] 已废弃：已改名为 `cylIsFlatDesignStyleTabBar`。
     */
    @available(*, deprecated, renamed: "cylIsFlatDesignStyleTabBar()")
    @nonobjc
    public func cyl_isFlatDesignStyleTabBar() -> Bool { cylIsFlatDesignStyleTabBar() }

    /**
     [EN] Deprecated: renamed to `cylVisiableTabButton`.
     [CN] 已废弃：已改名为 `cylVisiableTabButton`。
     */
    @available(*, deprecated, renamed: "cylVisiableTabButton()")
    @nonobjc
    public func cyl_visiableTabButton() -> UIControl? { cylVisiableTabButton() }

    /**
     [EN] Deprecated: renamed to `cylIsEqual`.
     [CN] 已废弃：已改名为 `cylIsEqual`。
     */
    @available(*, deprecated, renamed: "cylIsEqual(to:)")
    @nonobjc
    public func cyl_isEqual(to compairedViewController: UIViewController) -> Bool { cylIsEqual(to: compairedViewController) }

    /**
     [EN] Deprecated: renamed to `cylAddChildViewController`.
     [CN] 已废弃：已改名为 `cylAddChildViewController`。
     */
    @available(*, deprecated, renamed: "cylAddChildViewController(_:)")
    @nonobjc
    public func cyl_addChildViewController(_ childController: Any) { cylAddChildViewController(childController) }

    /**
     [EN] Deprecated: renamed to `cylPopSelectTabBarChildViewController`.
     [CN] 已废弃：已改名为 `cylPopSelectTabBarChildViewController`。
     */
    @available(*, deprecated, renamed: "cylPopSelectTabBarChildViewController(at:)")
    @discardableResult
    @nonobjc
    public func cyl_popSelectTabBarChildViewController(at index: UInt) -> UIViewController? { cylPopSelectTabBarChildViewController(at: index) }

    /**
     [EN] Deprecated: renamed to `cylPopSelectTabBarChildViewController`.
     [CN] 已废弃：已改名为 `cylPopSelectTabBarChildViewController`。
     */
    @available(*, deprecated, renamed: "cylPopSelectTabBarChildViewController(at:animated:)")
    @discardableResult
    @nonobjc
    public func cyl_popSelectTabBarChildViewController(at index: UInt, animated: Bool) -> UIViewController? { cylPopSelectTabBarChildViewController(at: index, animated: animated) }

    /**
     [EN] Deprecated: renamed to `cylPopSelectTabBarChildViewController`.
     [CN] 已废弃：已改名为 `cylPopSelectTabBarChildViewController`。
     */
    @available(*, deprecated, renamed: "cylPopSelectTabBarChildViewController(at:completion:)")
    @nonobjc
    public func cyl_popSelectTabBarChildViewController(at index: UInt, completion: CYLPopSelectCompletion?) { cylPopSelectTabBarChildViewController(at: index, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylPopSelectTabBarChildViewController`.
     [CN] 已废弃：已改名为 `cylPopSelectTabBarChildViewController`。
     */
    @available(*, deprecated, renamed: "cylPopSelectTabBarChildViewController(forClassType:)")
    @discardableResult
    @nonobjc
    public func cyl_popSelectTabBarChildViewController(forClassType classType: AnyClass) -> UIViewController? { cylPopSelectTabBarChildViewController(forClassType: classType) }

    /**
     [EN] Deprecated: renamed to `cylPopSelectTabBarChildViewController`.
     [CN] 已废弃：已改名为 `cylPopSelectTabBarChildViewController`。
     */
    @available(*, deprecated, renamed: "cylPopSelectTabBarChildViewController(forClassType:completion:)")
    @nonobjc
    public func cyl_popSelectTabBarChildViewController(forClassType classType: AnyClass, completion: CYLPopSelectCompletion?) { cylPopSelectTabBarChildViewController(forClassType: classType, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylPopSelectTabBarChildViewController`.
     [CN] 已废弃：已改名为 `cylPopSelectTabBarChildViewController`。
     */
    @available(*, deprecated, renamed: "cylPopSelectTabBarChildViewController(forTabBarItemIdentifier:)")
    @discardableResult
    @nonobjc
    public func cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier identifier: String) -> UIViewController? { cylPopSelectTabBarChildViewController(forTabBarItemIdentifier: identifier) }

    /**
     [EN] Deprecated: renamed to `cylPopSelectTabBarChildViewController`.
     [CN] 已废弃：已改名为 `cylPopSelectTabBarChildViewController`。
     */
    @available(*, deprecated, renamed: "cylPopSelectTabBarChildViewController(forTabBarItemIdentifier:animated:)")
    @discardableResult
    @nonobjc
    public func cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier identifier: String, animated: Bool) -> UIViewController? { cylPopSelectTabBarChildViewController(forTabBarItemIdentifier: identifier, animated: animated) }

    /**
     [EN] Deprecated: renamed to `cylPopSelectTabBarChildViewController`.
     [CN] 已废弃：已改名为 `cylPopSelectTabBarChildViewController`。
     */
    @available(*, deprecated, renamed: "cylPopSelectTabBarChildViewController(forTabBarItemIdentifier:completion:)")
    @nonobjc
    public func cyl_popSelectTabBarChildViewController(forTabBarItemIdentifier identifier: String, completion: CYLPopSelectCompletion?) { cylPopSelectTabBarChildViewController(forTabBarItemIdentifier: identifier, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylPushOrPop`.
     [CN] 已废弃：已改名为 `cylPushOrPop`。
     */
    @available(*, deprecated, renamed: "cylPushOrPop(to:animated:callback:)")
    @nonobjc
    public func cyl_pushOrPop(to viewController: UIViewController, animated: Bool, callback: CYLPushOrPopDecision?) { cylPushOrPop(to: viewController, animated: animated, callback: callback) }

    /**
     [EN] Deprecated: renamed to `cylPushOrPop`.
     [CN] 已废弃：已改名为 `cylPushOrPop`。
     */
    @available(*, deprecated, renamed: "cylPushOrPop(to:animated:tabBarItemIdentifier:callback:)")
    @nonobjc
    public func cyl_pushOrPop(to viewController: UIViewController, animated: Bool, tabBarItemIdentifier identifier: String, callback: CYLPushOrPopDecision?) { cylPushOrPop(to: viewController, animated: animated, tabBarItemIdentifier: identifier, callback: callback) }

    /**
     [EN] Deprecated: renamed to `cylPush`.
     [CN] 已废弃：已改名为 `cylPush`。
     */
    @available(*, deprecated, renamed: "cylPush(_:animated:)")
    @nonobjc
    public func cyl_push(_ viewController: UIViewController, animated: Bool) { cylPush(viewController, animated: animated) }

    /**
     [EN] Deprecated: renamed to `cylHandleNavigationBackAction`.
     [CN] 已废弃：已改名为 `cylHandleNavigationBackAction`。
     */
    @available(*, deprecated, renamed: "cylHandleNavigationBackAction()")
    @nonobjc
    public func cyl_handleNavigationBackAction() { cylHandleNavigationBackAction() }

    /**
     [EN] Deprecated: renamed to `cylHandleNavigationBackAction`.
     [CN] 已废弃：已改名为 `cylHandleNavigationBackAction`。
     */
    @available(*, deprecated, renamed: "cylHandleNavigationBackAction(withAnimated:)")
    @nonobjc
    public func cyl_handleNavigationBackAction(withAnimated animated: Bool) { cylHandleNavigationBackAction(withAnimated: animated) }

    /**
     [EN] Deprecated: renamed to `cylShowTabBadgePoint`.
     [CN] 已废弃：已改名为 `cylShowTabBadgePoint`。
     */
    @available(*, deprecated, renamed: "cylShowTabBadgePoint()")
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol>, such as `-[UIViewController cyl_showBadgeValue:animationType:]` instead.")
    @nonobjc
    public func cyl_showTabBadgePoint() { cylShowTabBadgePoint() }

    /**
     [EN] Deprecated: renamed to `cylRemoveTabBadgePoint`.
     [CN] 已废弃：已改名为 `cylRemoveTabBadgePoint`。
     */
    @available(*, deprecated, renamed: "cylRemoveTabBadgePoint()")
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol>, such as `-[UIViewController cyl_clearBadge]` instead.")
    @nonobjc
    public func cyl_removeTabBadgePoint() { cylRemoveTabBadgePoint() }

    /**
     [EN] Deprecated: renamed to `cylIsShowTabBadgePoint`.
     [CN] 已废弃：已改名为 `cylIsShowTabBadgePoint`。
     */
    @available(*, deprecated, renamed: "cylIsShowTabBadgePoint()")
    @available(*, deprecated, message: "Deprecated in 1.19.0. Use method in <CYLBadgeProtocol>, such as `-[UIViewController cyl_isShowBadge]` instead.")
    @nonobjc
    public func cyl_isShowTabBadgePoint() -> Bool { cylIsShowTabBadgePoint() }

    /**
     [EN] Deprecated: renamed to `cylTabBarItemUpdateRowCount`.
     [CN] 已废弃：已改名为 `cylTabBarItemUpdateRowCount`。
     */
    @available(*, deprecated, renamed: "cylTabBarItemUpdateRowCount()")
    @nonobjc
    public func cyl_tabBarItemUpdateRowCount() -> Int { cylTabBarItemUpdateRowCount() }

    /**
     [EN] Deprecated: renamed to `cylTabBarItemUpdateCell`.
     [CN] 已废弃：已改名为 `cylTabBarItemUpdateCell`。
     */
    @available(*, deprecated, renamed: "cylTabBarItemUpdateCell(for:row:)")
    @nonobjc
    public func cyl_tabBarItemUpdateCell(for tableView: UITableView, row: Int) -> UITableViewCell { cylTabBarItemUpdateCell(for: tableView, row: row) }

    /**
     [EN] Deprecated: renamed to `cylDidSelectTabBarItemUpdateRow`.
     [CN] 已废弃：已改名为 `cylDidSelectTabBarItemUpdateRow`。
     */
    @available(*, deprecated, renamed: "cylDidSelectTabBarItemUpdateRow(_:)")
    @nonobjc
    public func cyl_didSelectTabBarItemUpdateRow(_ row: Int) { cylDidSelectTabBarItemUpdateRow(row) }

    /**
     [EN] Deprecated: renamed to `cylSetUpThemeSettings`.
     [CN] 已废弃：已改名为 `cylSetUpThemeSettings`。
     */
    @available(*, deprecated, renamed: "cylSetUpThemeSettings()")
    @nonobjc
    public class func cyl_setUpThemeSettings() { Self.cylSetUpThemeSettings() }

    /**
     [EN] Deprecated: renamed to `cylThemeSettingsCell`.
     [CN] 已废弃：已改名为 `cylThemeSettingsCell`。
     */
    @available(*, deprecated, renamed: "cylThemeSettingsCell(for:)")
    @nonobjc
    public func cyl_themeSettingsCell(for tableView: UITableView) -> UITableViewCell { cylThemeSettingsCell(for: tableView) }

    /**
     [EN] Deprecated: renamed to `cylPresentThemePicker`.
     [CN] 已废弃：已改名为 `cylPresentThemePicker`。
     */
    @available(*, deprecated, renamed: "cylPresentThemePicker(from:completion:)")
    @nonobjc
    public func cyl_presentThemePicker(from sourceView: UIView?, completion: (() -> Void)?) { cylPresentThemePicker(from: sourceView, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylThemeMenu`.
     [CN] 已废弃：已改名为 `cylThemeMenu`。
     */
    @available(*, deprecated, renamed: "cylThemeMenu(withCompletion:)")
    @nonobjc
    public func cyl_themeMenu(withCompletion completion: (() -> Void)?) -> UIMenu { cylThemeMenu(withCompletion: completion) }

    /**
     [EN] Deprecated: renamed to `cylThemeListSectionTitle`.
     [CN] 已废弃：已改名为 `cylThemeListSectionTitle`。
     */
    @available(*, deprecated, renamed: "cylThemeListSectionTitle()")
    @nonobjc
    public func cyl_themeListSectionTitle() -> String { cylThemeListSectionTitle() }

    /**
     [EN] Deprecated: renamed to `cylThemeListRowCount`.
     [CN] 已废弃：已改名为 `cylThemeListRowCount`。
     */
    @available(*, deprecated, renamed: "cylThemeListRowCount()")
    @nonobjc
    public func cyl_themeListRowCount() -> Int { cylThemeListRowCount() }

    /**
     [EN] Deprecated: renamed to `cylThemeListCell`.
     [CN] 已废弃：已改名为 `cylThemeListCell`。
     */
    @available(*, deprecated, renamed: "cylThemeListCell(for:row:)")
    @nonobjc
    public func cyl_themeListCell(for tableView: UITableView, row: Int) -> UITableViewCell { cylThemeListCell(for: tableView, row: row) }

    /**
     [EN] Deprecated: renamed to `cylDidSelectThemeListRow`.
     [CN] 已废弃：已改名为 `cylDidSelectThemeListRow`。
     */
    @available(*, deprecated, renamed: "cylDidSelectThemeListRow(_:)")
    @nonobjc
    public func cyl_didSelectThemeListRow(_ row: Int) { cylDidSelectThemeListRow(row) }
}
