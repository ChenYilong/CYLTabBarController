//
//  CYLBadgeTagTableViewController.swift
//  CYLTabBarController-Swift
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/**
 [EN] The "Badge" page of Example-Swift-04 as a CollectionViewClassifyMenu tag list (docs/instructions/examples.md, "Demo lists that need sections use a
      ClassifyMenu tag list"). It was the library's `CYLBadgeHelperTableViewController`, a plain list of settings rows and badge samples; it is that page
      still (the title and `didSelectRowHandler` are the library's) with these differences: the table is inset grouped, its first row is the tag list
      (`CYLDemoTagList`, shared with the Objective-C example through `Example-Shared/CYLDemoTagList.swift`), and the sections of the tag list are the
      library's settings groups (`cylSettingsGroups()`), plus the badge samples as one more section. A tag is a plain row: its main title and icon, its subtitle as the
      long-press callout, and a tap does what tapping the row did. Rows that are not plain (a switch, a slider or an arrow: the language, the login
      state, the plus button's touchable area) stay rows in the second section of the table, below the tag list.
 [CN] Example-Swift-04 的 “Badge” 页面，以 CollectionViewClassifyMenu 的 TagList 显示（docs/instructions/examples.md）。原来是库的
      `CYLBadgeHelperTableViewController`（设置行与角标样例的普通列表）；现在仍是该页面（标题与 `didSelectRowHandler` 沿用库的），区别是：表格为圆角分组样式，
      第一行是 TagList（`CYLDemoTagList`，通过 `Example-Shared/CYLDemoTagList.swift` 与 Objective-C 示例共用），TagList 的分组是库的设置分组
      （`cylSettingsGroups()`），再加上角标样例一组。Tag 即普通行：主标题与图标，副标题为长按浮层，点击效果与点击原行相同。带开关、滑块或箭头的
      行（语言、登录状态、PlusButton 可点击区域）不是普通行，仍作为行放在表格第二个 section，位于 TagList 之下。
 */
final class CYLBadgeTagTableViewController: CYLBadgeHelperTableViewController, CYLDemoTagSectionSource {

    /// [EN] The tag list's sections: a settings group with its plain rows (settings row numbers). [CN] TagList 的分组：一个设置分组及其普通行（设置行号）。
    private struct Layout {
        var sections: [(title: String, rows: [Int])] = []
        /// [EN] The settings rows that stay table rows. [CN] 仍作为表格行的设置行。
        var tableRows: [Int] = []
    }

    /// [EN] Makes and runs the rows for the tag list; it has no window, so a row never reloads the real table. [CN] 为 TagList 生成并执行各行；它没有 window，行不会刷新真正的表格。
    private let scratchTable = UITableView(frame: .zero, style: .insetGrouped)
    private lazy var layout = makeLayout()
    private var demoTagList: CYLDemoTagList?

    /// [EN] The section of the table that holds the tag list's single row; the rows that are not plain follow in the next section. [CN] 表格中只含 TagList 一行的 section；非普通行在下一个 section。
    private let tagListSection = 0
    private let tableRowsSection = 1

    init() {
        // [EN] Inset grouped, as every table of the examples (docs/instructions/examples.md). [CN] 圆角分组，与所有示例的表格一致。
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) is not supported") }

    override func viewDidLoad() {
        super.viewDidLoad()
        // [EN] The badge samples are tags too: a scratch cell supplies each one's title and subtitle. A tap does what tapping the old row did: the
        //      library's handler (the old row's index path was in section 1), then a simulated memory warning; the tag list clears the tag's badge first, as the old row's tap cleared its badge.
        // [CN] 角标样例也是 Tag：用临时 cell 提供标题与副标题。点击效果与点击原行相同：调用库的回调（原行的 indexPath 在第 1 组），然后模拟内存警告
        //      ；TagList 会先清除该 Tag 的角标，与点击原行清除其角标相同。
        demoTagList = CYLDemoTagList.install(on: tableView, host: self, source: self, badgeRowCount: UITableViewCell.cylBadgeStyleCount(), badgeCell: { [weak self] row in
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.textLabel?.text = UITableViewCell.cylBadgeTitle(forRow: row)
            cell.detailTextLabel?.text = String(format: cylDemoLocalizedString("%@ CYLTabBarController on iOS %@"), self?.navigationItem.title ?? "",
                                                "\(Float(UIDevice.current.systemVersion) ?? 0)")
            return cell
        }, didSelectBadgeRow: { [weak self] row in
            self?.didSelectRowHandler?(IndexPath(row: row, section: 1))
            CYLTabBarController.cylSimulateMemoryWarning()
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        demoTagList?.reload()
        if !layout.tableRows.isEmpty {
            tableView.reloadSections(IndexSet(integer: tableRowsSection), with: .none)
        }
    }

    // MARK: - Layout

    /// [EN] A plain row has no switch, slider or arrow: nothing but its title, subtitle, icon and maybe a checkmark. [CN] 普通行没有开关、滑块或箭头：只有标题、副标题、图标，也可能有勾号。
    private func isPlain(_ cell: UITableViewCell) -> Bool {
        cell.accessoryView == nil && (cell.accessoryType == .none || cell.accessoryType == .checkmark)
    }

    private func makeLayout() -> Layout {
        var result = Layout()
        for number in cylSettingsGroups() {
            guard let group = CYLSettingsGroup(rawValue: number.intValue) else { continue }
            var plainRows: [Int] = []
            for row in cylSettingsRows(in: group).map(\.intValue) {
                if isPlain(cylSettingsCell(for: scratchTable, row: row)) {
                    plainRows.append(row)
                } else {
                    result.tableRows.append(row)
                }
            }
            if !plainRows.isEmpty { result.sections.append((title: cylTitle(for: group), rows: plainRows)) }
        }
        return result
    }

    // MARK: - CYLDemoTagSectionSource

    func demoSectionCount() -> Int { layout.sections.count }

    func demoRowCount(inSection section: Int) -> Int { layout.sections[section].rows.count }

    func demoTitle(forSection section: Int) -> String? { layout.sections[section].title }

    func demoCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        cylSettingsCell(for: tableView, row: layout.sections[indexPath.section].rows[indexPath.row])
    }

    func demoDidSelectRow(at indexPath: IndexPath, in _: UITableView) {
        cylDidSelectSettingsRow(layout.sections[indexPath.section].rows[indexPath.row])
    }

    // MARK: - UITableViewDataSource / UITableViewDelegate

    override func numberOfSections(in _: UITableView) -> Int {
        layout.tableRows.isEmpty ? 1 : 2
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == tagListSection ? 1 : layout.tableRows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == tagListSection, let demoTagList {
            return demoTagList.cell
        }
        return cylSettingsCell(for: tableView, row: layout.tableRows[indexPath.row])
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == tableRowsSection else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        // [EN] The row runs without the table (it would reload its own index path in the settings section, which this table does not have). A switch row
        //      follows its notification by itself, so only the other rows are reloaded. [CN] 该行不传表格执行（否则它会刷新自己在设置分组中的 indexPath，而本表格没有该分组）。
        //      开关行会自行跟随通知更新，所以只刷新其他行。
        let cell = tableView.cellForRow(at: indexPath)
        cylDidSelectSettingsRow(layout.tableRows[indexPath.row])
        if cell?.accessoryView == nil {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
}
