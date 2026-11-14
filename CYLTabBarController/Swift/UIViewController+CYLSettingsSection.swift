//
//  UIViewController+CYLSettingsSection.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The groups of the settings section, in display order. [CN] 设置分组中的各组，按显示顺序。
 */
@objc(CYLSettingsGroup)
public enum CYLSettingsGroup: Int, CaseIterable {
    /**
     * [EN] Language, memory warning, and rows a newer version adds. [CN] 语言、内存警告，以及新版本新增的行。
     */
    case general
    /**
     * [EN] Title offset, standardAppearance, scroll minimize. [CN] 标题偏移、standardAppearance、滚动缩小。
     */
    case tabBarAppearance
    /**
     * [EN] In-place tab item updates (#601). [CN] 原地更新 Tab（#601）。
     */
    case tabBarItemUpdate
    /**
     * [EN] Replace pages (#481), selectedIndex (#515), login (#19). [CN] 替换页面、selectedIndex、登录。
     */
    case pagesSelectionLogin
    /**
     * [EN] The plus button's touchable area (#91), an image set later. [CN] PlusButton 可点击区域（#91）、之后才加载的图片。
     */
    case plusButton
    /**
     * [EN] Tap animation, sound, long press, swipe (#535, #118). [CN] 点击动画、声音、长按、滑动。
     */
    case tabInteractions
    /**
     * [EN] No base class, CYLUtils helpers (#535). [CN] 无需继承基类、CYLUtils 工具方法。
     */
    case helpers
    /**
     * [EN] A tab bar controller from a configuration file, and the simulated failures. [CN] 由配置文件创建 TabBarController，以及模拟意外情况。
     */
    case configuration
}

/**
 * [EN] The rows of the settings section; the simulated configuration failures, then the tab item update rows follow.
 * [CN] 设置分组的行；其后是配置文件模拟意外情况，然后是更新 Tab 的若干行。
 */
enum CYLSettingsRow: Int {
    case language, memoryWarning, titlePositionAdjustment, standardAppearance, loginState, plusButtonTouchableArea
    case selectedIndexIgnoringPlusButton, tabBarMinimizeBehavior, tabButtonTapAnimation, tabButtonLongPress, swipeToSwitchTab
    case outsideSuperviewBounds, bundleImage, navigationWithoutBaseClass, slideTransition, tapFeedback, gestureTiming
    case switchAdjacentTab, utilsHelpers, plusButtonLateImage, theme, scrollHideSimulation, configurationFile, configurationEdgeCase
}

/**
 * [EN] `UIViewController (CYLSettingsSection)`: the settings section every demo list shows (language, memory warning, tab
 *      bar appearance, in-place updates, plus button, interactions, helpers, configuration files), as one section or as
 *      groups. Translated from Objective-C (docs/Swift-Migration.md, step 33); selectors and Swift names kept.
 * [CN] `UIViewController (CYLSettingsSection)`：每个演示列表都显示的设置分组（语言、内存警告、TabBar 外观、原地更新、PlusButton、交互、工具方法、
 *      配置文件），可作为一个 section 或多个分组显示。已从 Objective-C 翻译（docs/Swift-Migration.md，第 33 步）；selector 与 Swift 名称不变。
 */
extension UIViewController {

    private var cyl_settingsTabBarController: CYLTabBarController? {
        cyl_owningTabBarController() ?? cyl_tabBarController
    }

    /**
     * [EN] The first in-place update row, after the simulated failures. [CN] 第一个原地更新行，位于模拟意外情况之后。
     */
    private var cyl_settingsTabBarItemUpdateStart: Int {
        CYLSettingsRow.configurationEdgeCase.rawValue + cyl_configurationEdgeCaseRowCount()
    }

    /**
     * [EN] The number of rows of the settings section. [CN] 设置分组的行数。
     */
    @objc(cyl_settingsRowCount)
    public func cyl_settingsRowCount() -> Int {
        cyl_settingsTabBarItemUpdateStart + cyl_tabBarItemUpdateRowCount()
    }

    /**
     * [EN] The cell of a row; every row shows its whole text, wrapped. [CN] 某行的 cell；每行完整显示文字（换行）。
     */
    @objc(cyl_settingsCellForTableView:atIndexPath:)
    public func cyl_settingsCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = cyl_settingsRowCell(for: tableView, row: indexPath.row)
        cell.cyl_wrapsTextLabels()
        return cell
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func cyl_settingsRowCell(for tableView: UITableView, row: Int) -> UITableViewCell {
        let tabBarController = cyl_settingsTabBarController
        let updateStart = cyl_settingsTabBarItemUpdateStart
        if row >= updateStart {
            return cyl_tabBarItemUpdateCell(for: tableView, row: row - updateStart)
        }
        if row >= CYLSettingsRow.configurationEdgeCase.rawValue {
            return cyl_configurationEdgeCaseCell(for: tableView, row: row - CYLSettingsRow.configurationEdgeCase.rawValue)
        }
        typealias Demo = CYLSettingsDemo
        switch CYLSettingsRow(rawValue: row) ?? .language {
        case .memoryWarning: return cyl_memoryWarningCell(for: tableView)
        case .titlePositionAdjustment: return Demo.titlePositionAdjustmentCell(tableView, tabBarController)
        case .standardAppearance: return Demo.standardAppearanceCell(tableView, tabBarController)
        case .loginState: return Demo.loginStateCell(tableView, tabBarController)
        case .plusButtonTouchableArea: return Demo.touchableAreaCell(tableView, tabBarController)
        case .selectedIndexIgnoringPlusButton: return Demo.selectedIndexCell(tableView, tabBarController)
        case .tabButtonTapAnimation: return Demo.tapAnimationCell(tableView, tabBarController)
        case .tabButtonLongPress: return Demo.interactionSwitchCell(tableView, tabBarController, .longPress)
        case .swipeToSwitchTab: return Demo.interactionSwitchCell(tableView, tabBarController, .swipe)
        case .outsideSuperviewBounds: return Demo.outsideBoundsCell(tableView)
        case .bundleImage: return Demo.bundleImageCell(tableView)
        case .navigationWithoutBaseClass: return Demo.navigationSettingCell(tableView)
        case .slideTransition: return Demo.slideTransitionCell(tableView)
        case .tapFeedback: return Demo.tapFeedbackCell(tableView, tabBarController)
        case .gestureTiming: return Demo.gestureTimingCell(tableView, tabBarController)
        case .switchAdjacentTab: return Demo.switchAdjacentTabCell(tableView, tabBarController)
        case .utilsHelpers: return Demo.utilsHelpersCell(tableView, tabBarController)
        case .tabBarMinimizeBehavior: return Demo.tabBarMinimizeCell(tableView, tabBarController)
        case .plusButtonLateImage: return Demo.lateImageCell(tableView)
        case .theme: return cyl_themeSettingsCell(for: tableView)
        case .scrollHideSimulation: return Demo.scrollHideSimulationMenuCell(tableView)
        case .configurationFile: return cyl_configurationDemoCell(for: tableView)
        case .language, .configurationEdgeCase: return cyl_languageCell(for: tableView)
        }
    }

    // MARK: Groups

    /**
     * [EN] The rows each group places, in display order. [CN] 每个分组放置的行，按显示顺序。
     */
    private func cyl_placedSettingsRows(in group: CYLSettingsGroup) -> [Int] {
        let update = cyl_settingsTabBarItemUpdateStart
        func rows(_ rows: CYLSettingsRow...) -> [Int] { rows.map(\.rawValue) }
        func updates(_ rows: CYLTabBarItemUpdateRow...) -> [Int] { rows.map { update + $0.rawValue } }
        switch group {
        case .general:
            return rows(.language, .memoryWarning)
        case .tabBarAppearance:
            return rows(.titlePositionAdjustment, .standardAppearance, .theme, .tabBarMinimizeBehavior, .scrollHideSimulation)
        case .tabBarItemUpdate:
            return updates(.title, .iconView, .networkIcon, .allNetworkIcons, .allLocalIcons, .GIFIcon, .allTitles)
        case .pagesSelectionLogin:
            return updates(.replaceNeighbors) + rows(.selectedIndexIgnoringPlusButton, .loginState)
        case .plusButton:
            return rows(.plusButtonTouchableArea, .plusButtonLateImage)
        case .tabInteractions:
            return rows(.tabButtonTapAnimation, .tapFeedback, .tabButtonLongPress, .gestureTiming, .swipeToSwitchTab,
                        .switchAdjacentTab, .slideTransition)
        case .helpers:
            return rows(.navigationWithoutBaseClass, .outsideSuperviewBounds, .bundleImage, .utilsHelpers)
        case .configuration:
            // [EN] The configuration file row, then one row per simulated failure. [CN] 配置文件行，然后每个模拟意外情况一行。
            return rows(.configurationFile) + Array(CYLSettingsRow.configurationEdgeCase.rawValue..<update)
        }
    }

    /**
     * [EN] The groups that have rows, in display order (`CYLSettingsGroup` values). [CN] 有行的分组，按显示顺序（`CYLSettingsGroup` 值）。
     */
    @objc(cyl_settingsGroups)
    public func cyl_settingsGroups() -> [NSNumber] {
        CYLSettingsGroup.allCases.filter { !cyl_settingsRows(in: $0).isEmpty }.map { NSNumber(value: $0.rawValue) }
    }

    /**
     * [EN] The title of `group`, in the app's language. [CN] `group` 的标题，使用 App 语言。
     */
    @objc(cyl_titleForSettingsGroup:)
    public func cyl_title(for group: CYLSettingsGroup) -> String {
        switch group {
        case .general: return CYLLocalizedString("通用")
        case .tabBarAppearance: return CYLLocalizedString("TabBar 外观")
        case .tabBarItemUpdate: return CYLLocalizedString("原地更新 Tab")
        case .pagesSelectionLogin: return CYLLocalizedString("Tab 页面、选中与登录")
        case .plusButton: return "PlusButton"
        case .tabInteractions: return CYLLocalizedString("Tab 交互")
        case .helpers: return CYLLocalizedString("无需继承基类与工具方法")
        case .configuration: return CYLLocalizedString("配置文件")
        }
    }

    /**
     * [EN] The rows of `group` (row numbers of the settings section); rows no group places (a newer row) stay visible in the
     *      general group.
     * [CN] `group` 中的行（设置分组中的行号）；未被任何分组归类的行（新增的行）放在“通用”分组中，保证可见。
     */
    @objc(cyl_settingsRowsInGroup:)
    public func cyl_settingsRows(in group: CYLSettingsGroup) -> [NSNumber] {
        let rowCount = cyl_settingsRowCount()
        var rows = cyl_placedSettingsRows(in: group).filter { $0 < rowCount }
        if group == .general {
            let placed = Set(CYLSettingsGroup.allCases.flatMap(cyl_placedSettingsRows(in:)))
            rows += (0..<rowCount).filter { !placed.contains($0) }
        }
        return rows.map { NSNumber(value: $0) }
    }

    /**
     * [EN] The cell of settings row `row`, for a grouped list. [CN] 设置行 `row` 的 cell，用于分组列表。
     */
    @objc(cyl_settingsCellForTableView:row:)
    public func cyl_settingsCell(for tableView: UITableView, row: Int) -> UITableViewCell {
        cyl_settingsCell(for: tableView, at: IndexPath(row: row, section: Int(CYLSettingsSection)))
    }

    /**
     * [EN] Runs settings row `row`, for a grouped list: the rows reload their own index paths in the settings section, which a
     *      grouped list does not have, so the row runs without a table view and the caller reloads.
     * [CN] 执行设置行 `row`，用于分组列表：各行会刷新其在设置分组中的 indexPath，而分组列表中没有该分组，因此不传列表执行，由调用方刷新。
     */
    @objc(cyl_didSelectSettingsRow:)
    public func cyl_didSelectSettingsRow(_ row: Int) {
        cyl_runSettingsRow(at: IndexPath(row: row, section: Int(CYLSettingsSection)), in: nil)
    }

    /**
     * [EN] Runs a row of the settings section, and deselects and reloads it. [CN] 执行设置分组中的某行，并取消选中、刷新该行。
     */
    @objc(cyl_didSelectSettingsRowAtIndexPath:inTableView:)
    public func cyl_didSelectSettingsRow(at indexPath: IndexPath, in tableView: UITableView) {
        cyl_runSettingsRow(at: indexPath, in: tableView)
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func cyl_runSettingsRow(at indexPath: IndexPath, in tableView: UITableView?) {
        tableView?.deselectRow(at: indexPath, animated: true)
        let tabBarController = cyl_settingsTabBarController
        let row = indexPath.row
        let reload = { tableView?.reloadRows(at: [indexPath], with: .none) }
        let updateStart = cyl_settingsTabBarItemUpdateStart
        if row >= updateStart {
            cyl_didSelectTabBarItemUpdateRow(row - updateStart)
            // [EN] The rows show which changes are on (a checkmark). [CN] 各行用勾号显示已应用的更改。
            tableView?.reloadRows(at: (updateStart..<cyl_settingsRowCount()).map { IndexPath(row: $0, section: indexPath.section) }, with: .none)
            return
        }
        if row >= CYLSettingsRow.configurationEdgeCase.rawValue {
            cyl_runConfigurationEdgeCase(atRow: row - CYLSettingsRow.configurationEdgeCase.rawValue)
            return
        }
        typealias Demo = CYLSettingsDemo
        switch CYLSettingsRow(rawValue: row) ?? .language {
        case .memoryWarning:
            cyl_simulateMemoryWarningAndShowResult()
        case .titlePositionAdjustment:
            Demo.switchTitlePositionAdjustment(tabBarController)
            reload()
        case .standardAppearance:
            Demo.switchStandardAppearance(tabBarController)
            reload()
        case .loginState:
            // [EN] The switch and the text follow the notification, so the row is not reloaded (the switch animates).
            // [CN] 开关与文字随通知更新，因此不重新加载该行（开关会带动画切换）。
            Demo.toggleLoginState(tabBarController)
        case .plusButtonTouchableArea, .outsideSuperviewBounds, .bundleImage, .switchAdjacentTab:
            // [EN] These rows act through their own controls; a tap on the row does nothing. [CN] 这些行通过自身的控件生效，点击该行不做处理。
            break
        case .selectedIndexIgnoringPlusButton:
            // [EN] The tab changes, so this list may disappear; reload the row only while it is still shown.
            // [CN] Tab 切换后本列表可能已不可见；仅在仍显示时刷新该行。
            Demo.selectNextTabIgnoringPlusButton(tabBarController)
            if tableView?.window != nil {
                reload()
            }
        case .tabBarMinimizeBehavior:
            Demo.switchTabBarMinimizeBehavior(tabBarController)
            reload()
        case .tabButtonTapAnimation:
            Demo.switchTapAnimation(tabBarController)
            reload()
        case .tabButtonLongPress:
            Demo.toggleInteraction(tableView, indexPath, tabBarController, .longPress)
        case .swipeToSwitchTab:
            Demo.toggleInteraction(tableView, indexPath, tabBarController, .swipe)
        case .navigationWithoutBaseClass:
            let page = CYLNavigationSettingDemoViewController()
            page.hidesBottomBarWhenPushed = true
            if let navigationController {
                navigationController.pushViewController(page, animated: true)
            } else {
                present(UINavigationController(rootViewController: page), animated: true)
            }
        case .plusButtonLateImage:
            Demo.showLateImageDemo(from: self, tableView, indexPath)
        case .slideTransition:
            let demo = CYLSlideTransitionDemoTabBarController()
            demo.modalPresentationStyle = .fullScreen
            present(demo, animated: true)
        case .tapFeedback:
            Demo.switchTapFeedback(tabBarController)
            reload()
        case .gestureTiming:
            Demo.switchGestureTiming(tabBarController)
            reload()
        case .utilsHelpers:
            Demo.runUtilsHelpers(tabBarController)
            reload()
        case .theme:
            // [EN] The row shows the theme picked. [CN] 该行显示所选主题。
            cyl_presentThemePicker(from: tableView?.cellForRow(at: indexPath)) { [weak tableView] in
                if let tableView, tableView.window != nil, indexPath.row < tableView.numberOfRows(inSection: indexPath.section) {
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        case .scrollHideSimulation:
            cyl_presentScrollHideSimulationMenu()
        case .configurationFile:
            cyl_presentConfigurationDemo()
        case .language, .configurationEdgeCase:
            cyl_presentLanguagePicker()
        }
    }
}
