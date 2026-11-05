//
//  CYLSettingsDemoTableViewController.swift
//  CYLTabBarController demos
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit

/*!
 * [EN] The ObjC demo's test list in pure Swift: every settings row of the library (language, appearance, in-place tab item
 *      updates, pages and login, the plus button, tab interactions, helpers), grouped like Settings. The rows, their cells
 *      and their actions come from the library (`UIViewController (CYLSettingsSection)`), so this list only lays them out.
 *      Shared by the Swift demos (Example-Rive, Example-SwiftUI-Rive, Example-Pag). Optional `headerView` goes above the
 *      rows, e.g. a demo of the page's own feature.
 * [CN] ObjC Demo 测试列表的纯 Swift 版本：库中所有设置行（语言、外观、原地更新 Tab、页面与登录、PlusButton、Tab 交互、工具方法），像系统设置一样分组。
 *      行、cell 与点击后的操作都来自库（`UIViewController (CYLSettingsSection)`），本列表只负责布局。由各 Swift Demo 共用（Example-Rive、
 *      Example-SwiftUI-Rive、Example-Pag）。可选的 `headerView` 显示在各行上方，例如该页面自身功能的演示。
 */
class CYLSettingsDemoTableViewController: UITableViewController {

    /// [EN] Shown above the rows. [CN] 显示在各行上方。
    var headerView: UIView? {
        didSet { layoutHeaderView() }
    }

    /// [EN] The library's groups that have rows, read once per reload. [CN] 有行的库分组，每次刷新时读取。
    private var groups: [CYLSettingsGroup] = []

    init() {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UITableViewCell.cyl_setUpAutomaticRowHeight(for: tableView)
        reloadGroups()
        layoutHeaderView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // [EN] Rows show state that other tabs can change (login, titles, icons). [CN] 各行显示的状态可能被其他 Tab 修改（登录、标题、图标）。
        reloadGroups()
    }

    // [EN] The skin row shows the current theme, and a theme is picked while this list stays on screen (#216).
    // [CN] 换肤行显示当前主题，而选择主题时本列表一直在屏幕上（#216）。
    override func cyl_themeDidChange(by manager: CYLThemeManager, identifier: (any NSCopying & NSObjectProtocol)?, theme: NSObject?) {
        super.cyl_themeDidChange(by: manager, identifier: identifier, theme: theme)
        if isViewLoaded {
            reloadGroups()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutHeaderView()
    }

    private func reloadGroups() {
        groups = cyl_settingsGroups().compactMap { CYLSettingsGroup(rawValue: $0.intValue) }
        tableView.reloadData()
    }

    /// [EN] A table header keeps the frame it is given: size it to fit the table's width. Called from
    ///      `viewDidLayoutSubviews`, so it changes the header only when something changed: setting it lays the table out
    ///      again, which would call this again, forever.
    /// [CN] 表头保持设置的 frame：按列表宽度计算其大小。由 `viewDidLayoutSubviews` 调用，因此只在有变化时才修改表头：设置表头会让列表
    ///      重新布局并再次调用这里，导致无限循环。
    private func layoutHeaderView() {
        guard isViewLoaded else { return }
        guard let headerView = headerView else {
            if tableView.tableHeaderView != nil {
                tableView.tableHeaderView = nil
            }
            return
        }
        let width = tableView.bounds.width
        let height = headerView.systemLayoutSizeFitting(CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
                                                        withHorizontalFittingPriority: .required,
                                                        verticalFittingPriority: .fittingSizeLevel).height
        if tableView.tableHeaderView !== headerView || headerView.frame.size != CGSize(width: width, height: height) {
            headerView.frame = CGRect(x: 0, y: 0, width: width, height: height)
            tableView.tableHeaderView = headerView
        }
    }

    private func settingsRow(at indexPath: IndexPath) -> Int {
        cyl_settingsRows(in: groups[indexPath.section])[indexPath.row].intValue
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in _: UITableView) -> Int {
        groups.count
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        cyl_settingsRows(in: groups[section]).count
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        cyl_title(for: groups[section])
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cyl_settingsCell(for: tableView, row: settingsRow(at: indexPath))
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        cyl_didSelectSettingsRow(settingsRow(at: indexPath))
        // [EN] The row may have switched a tab, so this list may no longer be on screen. [CN] 该行可能已切换 Tab，本列表可能已不在屏幕上。
        if tableView.window != nil {
            tableView.reloadData()
        }
    }
}
