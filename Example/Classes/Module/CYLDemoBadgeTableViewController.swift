//
//  CYLDemoBadgeTableViewController.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController
import CYLTableViewPlaceHolder

/**
 [EN] What the four tab pages of the Objective-C example share (docs/Swift-Migration.md, step 112): inset grouped sections, the
      shared demo sections first (`UIViewController (CYLDemoSections)`), then this page's badge rows; pull to refresh and the
      placeholders (CYLTableViewPlaceHolder). The pages were four Objective-C copies of this code; Swift now, because
      `CYLBaseTableViewController` becomes an `open` Swift class in phase ②.
 [CN] Objective-C 示例四个 Tab 页面的共同部分（docs/Swift-Migration.md，第 112 步）：圆角分组样式，先显示共用的演示 section
      （`UIViewController (CYLDemoSections)`），再显示本页的角标行；下拉刷新与占位图（CYLTableViewPlaceHolder）。原为四份相同的
      Objective-C 代码；改为 Swift，因为第 ② 阶段 `CYLBaseTableViewController` 将成为 `open` 的 Swift 类。
 */
class CYLDemoBadgeTableViewController: CYLBaseTableViewController {

    /// [EN] The placeholder animation of this page. [CN] 本页占位图的动画类型。
    var placeholderAnimation: CYLDemoPlaceholderAnimation { .lottie }

    /// [EN] At least this many badge rows (every badge style has one). [CN] 至少这么多角标行（每种角标样式一行）。
    var minimumBadgeRowCount: Int { 15 }

    /// [EN] This page's own table sections after the tag list section (the badge samples are tags). [CN] TagList 一组之后本页自己的表格 section 数（角标样例是 Tag）。
    var pageSectionCount: Int { 0 }

    /// [EN] The demo sections are one tag list (`CYLDemoTagList`) in the first section of the table. [CN] 演示 section 是表格第一个 section 中的一个 TagList（`CYLDemoTagList`）。
    final var tagListSectionCount: Int { 1 }

    /// [EN] The demo sections' tag list. [CN] 演示 section 的 TagList。
    private var demoTagList: CYLDemoTagList?

    init() {
        // [EN] Inset grouped sections with rounded corners, as in the Settings app. [CN] 与系统“设置”相同的圆角分组样式。
        super.init(style: .insetGrouped)
    }

    override init(style: UITableView.Style) {
        super.init(style: style)
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        UITableViewCell.cylSetUpAutomaticRowHeight(for: tableView)
        // [EN] The grouped background, so the rounded sections stand out. [CN] 分组背景色，使圆角分组清晰可见。
        view.backgroundColor = .systemGroupedBackground
        tableView.cyl_header = CYLRefreshNormalHeader(refreshingBlock: { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.tableView.cyl_header?.endRefreshing()
            }
        })
        // [EN] Pull to refresh, empty / no-network placeholders and the offline red bar.
        // [CN] 下拉刷新、无数据 / 无网络占位图与断网红条。
        CYLDemoPlaceholder.install(on: tableView, in: self, animation: placeholderAnimation, refresh: nil)
        // [EN] The badge samples are tags: a scratch cell supplies each one's title and subtitle, a tap does what tapping the row did. [CN] 角标样例是 Tag：用临时 cell 提供标题与副标题，点击效果与点击原行相同。
        let badgeSection = tagListSectionCount + pageSectionCount
        demoTagList = CYLDemoTagList.install(on: tableView, host: self, badgeRowCount: max(minimumBadgeRowCount, UITableViewCell.cylBadgeStyleCount()),
                                             badgeCell: { [weak self] row in
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            self?.configure(cell, for: IndexPath(row: row, section: badgeSection))
            return cell
        }, didSelectBadgeRow: { [weak self] row in
            self?.didSelectPageRow(at: IndexPath(row: row, section: badgeSection))
        })
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        demoTagList?.reload()
    }

    /// [EN] Refreshes the list for a second. [CN] 刷新列表一秒钟。
    @objc func refresh() {
        tableView.cyl_header?.beginRefreshing()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.tableView.cyl_header?.endRefreshing()
        }
    }

    /// [EN] A badge row: the badge sample as the title, the page as the subtitle; both wrap. [CN] 角标行：角标样例为主标题，页面为副标题；均可换行。
    func configure(_ cell: UITableViewCell, for indexPath: IndexPath) {
        cell.cylShowBadge(forRow: indexPath.row)
        cell.textLabel?.text = UITableViewCell.cylBadgeTitle(forRow: indexPath.row)
        cell.detailTextLabel?.text = String(format: cylDemoLocalizedString("%@ CYLTabBarController on iOS %@"), title ?? "",
                                            "\(Float(UIDevice.current.systemVersion) ?? 0)")
        cell.cylWrapsTextLabels()
    }

    /// [EN] A row of this page (not of the demo sections). [CN] 本页的行（不属于演示 section）。
    func pageCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "Cell")
        configure(cell, for: indexPath)
        return cell
    }

    /// [EN] A tap on a row of this page (not of the demo sections). [CN] 点击本页的行（不属于演示 section）。
    func didSelectPageRow(at _: IndexPath) {
        // [EN] This page has no rows of its own to act on. [CN] 本页没有需要处理的自有行。
    }

    // MARK: - UITableViewDataSource / UITableViewDelegate

    override func numberOfSections(in _: UITableView) -> Int {
        tagListSectionCount + pageSectionCount
    }

    override func tableView(_ _: UITableView, titleForHeaderInSection section: Int) -> String? {
        nil
    }

    override func tableView(_ _: UITableView, numberOfRowsInSection section: Int) -> Int {
        section < tagListSectionCount ? 1 : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section < tagListSectionCount, let demoTagList {
            return demoTagList.cell
        }
        return pageCell(for: tableView, at: indexPath)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section >= tagListSectionCount else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        didSelectPageRow(at: indexPath)
    }
}
