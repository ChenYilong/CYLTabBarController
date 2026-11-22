//
//  UITableViewCell+CYLDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

extension UITableViewCell {
    /**
     [EN] Deprecated: renamed to `cylShowBadge`.
     [CN] 已废弃：已改名为 `cylShowBadge`。
     */
    @available(*, deprecated, renamed: "cylShowBadge(forRow:)")
    @nonobjc
    public func cyl_showBadge(forRow row: Int) { cylShowBadge(forRow: row) }

    /**
     [EN] Deprecated: renamed to `cylBadgeTitle`.
     [CN] 已废弃：已改名为 `cylBadgeTitle`。
     */
    @available(*, deprecated, renamed: "cylBadgeTitle(forRow:)")
    @nonobjc
    public class func cyl_badgeTitle(forRow row: Int) -> String { Self.cylBadgeTitle(forRow: row) }

    /**
     [EN] Deprecated: renamed to `cylBadgeStyleCount`.
     [CN] 已废弃：已改名为 `cylBadgeStyleCount`。
     */
    @available(*, deprecated, renamed: "cylBadgeStyleCount()")
    @nonobjc
    public class func cyl_badgeStyleCount() -> Int { Self.cylBadgeStyleCount() }

    /**
     [EN] Deprecated: renamed to `cylWrapsTextLabels`.
     [CN] 已废弃：已改名为 `cylWrapsTextLabels`。
     */
    @available(*, deprecated, renamed: "cylWrapsTextLabels()")
    @nonobjc
    public func cyl_wrapsTextLabels() { cylWrapsTextLabels() }

    /**
     [EN] Deprecated: renamed to `cylSetUpAutomaticRowHeight`.
     [CN] 已废弃：已改名为 `cylSetUpAutomaticRowHeight`。
     */
    @available(*, deprecated, renamed: "cylSetUpAutomaticRowHeight(for:)")
    @nonobjc
    public class func cyl_setUpAutomaticRowHeight(for tableView: UITableView) { Self.cylSetUpAutomaticRowHeight(for: tableView) }
}
