//
//  CYLSettingsDemoTableViewController.swift
//  CYLTabBarController demos
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit

/*!
 * [EN] The tab bar style of a demo, chosen from the navigation bar: FlatDesign, or the system's (Liquid Glass on iOS 26 and
 *      later, the classic tab bar before), so the same animated tabs can be compared in all three. A demo gives its tab bar
 *      `styleType` when it creates it, and sets `rebuildRootViewController` to show the button. The launch argument
 *      `-CYLDemoTabBarFlatDesign YES` chooses FlatDesign too.
 * [CN] Demo 的 TabBar 样式，在导航栏中选择：扁平样式，或系统样式（iOS 26 及以后为液态玻璃，之前为经典 TabBar），以便在三种样式下对比相同的动画 Tab。Demo 在
 *      创建 TabBar 时传入 `styleType`，并设置 `rebuildRootViewController` 以显示按钮。启动参数 `-CYLDemoTabBarFlatDesign YES` 同样选择扁平样式。
 */
enum CYLDemoTabBarStyle {
    private static let defaultsKey = "CYLDemoTabBarFlatDesign"
    static var rebuildRootViewController: (() -> Void)?

    static var isFlatDesign: Bool {
        get { UserDefaults.standard.bool(forKey: defaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: defaultsKey) }
    }

    static var styleType: CYLTabBarStyleType {
        isFlatDesign ? .flatDesign : .default
    }

    fileprivate static var switchTitle: String {
        if !isFlatDesign {
            return "Flat Design"
        }
        return CYLConstants.isLiquidGlassActive() ? "Liquid Glass" : "Classic"
    }
}

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
        // [EN] The skin row shows the current theme, and a theme is picked while this list stays on screen (#216).
        // [CN] 换肤行显示当前主题，而选择主题时本列表一直在屏幕上（#216）。
        view.cyl_themeDidChangeBlock = { [weak self] in
            self?.reloadGroups()
        }
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        addTabBarStyleSwitch()
    }

    /// [EN] Only in the demos that can rebuild their tab bar in the other style. A list shown inside a page (Example-PAG) adds it
    ///      to that page's navigation bar, next to the page's own buttons.
    /// [CN] 仅在能以另一种样式重建 TabBar 的 Demo 中显示。显示在页面内部的列表（Example-PAG）把它添加到该页面的导航栏，排在页面自己的按钮旁边。
    private func addTabBarStyleSwitch() {
        guard CYLDemoTabBarStyle.rebuildRootViewController != nil else { return }
        let host = parent.flatMap { $0 is UINavigationController ? nil : $0 } ?? self
        let item = UIBarButtonItem(title: CYLDemoTabBarStyle.switchTitle, style: .plain, target: self, action: #selector(switchTabBarStyle))
        var items = host.navigationItem.rightBarButtonItems ?? []
        items.removeAll { $0.action == #selector(switchTabBarStyle) }
        host.navigationItem.rightBarButtonItems = items + [item]
    }

    @objc private func switchTabBarStyle() {
        // [EN] Stay on this tab: its list holds the button that switches back. [CN] 停留在当前 Tab：它的列表上有切换回去的按钮。
        let selectedIndex = tabBarController?.selectedIndex
        let window = view.window
        CYLDemoTabBarStyle.isFlatDesign.toggle()
        CYLDemoTabBarStyle.rebuildRootViewController?()
        if let selectedIndex = selectedIndex, let rebuilt = window?.rootViewController as? UITabBarController {
            rebuilt.selectedIndex = selectedIndex
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // [EN] Rows show state that other tabs can change (login, titles, icons). [CN] 各行显示的状态可能被其他 Tab 修改（登录、标题、图标）。
        reloadGroups()
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
