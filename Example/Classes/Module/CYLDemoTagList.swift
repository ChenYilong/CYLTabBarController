//
//  CYLDemoTagList.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController
import CollectionViewClassifyMenu

/**
 [EN] The demo sections (`UIViewController (CYLDemoSections)`) as a CollectionViewClassifyMenu tag list (docs/instructions/examples.md,
      "Demo lists that need sections use a ClassifyMenu tag list"): one tag per row (its main title and icon; the subtitle is the
      long-press callout), a titled header per section, tags as wide as their title, titles that wrap up to 3 lines, a More / Less
      icon as the last tag after 3 rows of tags, the library's Liquid Glass tag style and a clear list background, so the page's grouped
      background shows. A tap does what tapping the old row did. The badge samples are tags too: a round badge image before the title
      (`CYLTag.badgeText` / `badgeColor` / `badgeAccessibilityLabel`, drawn by `CYLTagDataSource.menuImageForItem(at:)`). The twin of HarmonyOS `demoTagText`, Android `DemoTagList.tagText` and the mini
      program `cylTagText`.
 [CN] 演示 section（`UIViewController (CYLDemoSections)`）以 CollectionViewClassifyMenu 的 TagList 显示：每行一个 Tag（主标题与图标；
      副标题为长按浮层），每个分组有标题，Tag 宽度随标题自适应，标题最多换行 3 行，超过 3 行 Tag 后最后一个 Tag 是 More / Less 图标，
      使用库的液态玻璃 Tag 样式与透明的列表背景，让页面的分组背景显示出来。点击 Tag 与点击原行效果相同。角标样例也是 Tag：
      标题前的圆形角标图片（`CYLTag.badgeText` / `badgeColor` / `badgeAccessibilityLabel`，由 `CYLTagDataSource.menuImageForItem(at:)` 绘制）。对应 HarmonyOS 的 `demoTagText`、Android 的 `DemoTagList.tagText` 与小程序的 `cylTagText`。
 */
@objc(CYLDemoTagList)
final class CYLDemoTagList: NSObject, CYLMenuDelegate {

    @objc static let titleMaxLines = 3
    @objc static let visibleRows = 3

    /**
     [EN] The badge of each badge sample, in the order of the core's samples (`UITableViewCell.cylBadgeTitle(forRow:)`; the rows repeat after the last one): the
          text the old row's badge showed ("" is the red dot: an empty, non-nil `CYLTag.badgeText` draws the 8 pt dot since ClassifyMenu 00b40e8d), and true when the old row had custom colors (purple). Every other badge is red.
     [CN] 每个角标样例的角标，顺序与核心的样例相同（`UITableViewCell.cylBadgeTitle(forRow:)`；超出最后一个后循环）：旧行角标显示的文字（"" 为红点），
          以及旧行是否使用自定义颜色（紫色）。其余角标为红色。
     */
    private static let badgeSamples: [(text: String, purple: Bool)] = [
        ("3", false), ("3", false), ("3", false), ("", false), ("3", false), ("new", false), ("3", false),
        ("3", false), ("3", false), ("3", false), ("", false), ("3", false),
        ("3", false), ("3", false), ("3", false), ("3", false), ("3", false), ("3", false),
        ("", false), ("8", false), ("99+", false), ("9+", false), ("new", false), ("NEW", false), ("hot", false),
        ("5", true), ("5", false), ("5", false), ("5", false), ("", false), ("5", false), ("new", false),
        ("5", false), ("5", false), ("5", false),
    ]

    private static let brackets = try! NSRegularExpression(pattern: "\\s*[（(]([^）)]*)[）)]")

    /**
     [EN] A tag's title is short: what a row's title says in brackets, "(…)" or "（…）", moves behind the row's subtitle (joined by " · ";
          shown on a long press). A title that is only brackets stays as it is. Returns the title and the subtitle ("" for none).
     [CN] Tag 的标题要短：行标题中括号「(…)」或「（…）」里的内容追加到行的副标题之后（以 " · " 连接，长按才显示）。只有括号的标题保持不变。
     */
    @objc static func tagText(title: String, subtitle: String?) -> [String] {
        let range = NSRange(title.startIndex..., in: title)
        let notes = brackets.matches(in: title, range: range).compactMap { match -> String? in
            guard let note = Range(match.range(at: 1), in: title) else { return nil }
            let text = title[note].trimmingCharacters(in: .whitespaces)
            return text.isEmpty ? nil : text
        }
        let stripped = brackets.stringByReplacingMatches(in: title, range: range, withTemplate: "")
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
        if stripped.isEmpty { return [title, subtitle ?? ""] }
        let parts = [subtitle].compactMap { $0 }.filter { !$0.isEmpty } + notes
        return [stripped, parts.joined(separator: " · ")]
    }

    private weak var host: UIViewController?
    private weak var tableView: UITableView?
    /// [EN] The demo rows are made and run with this table: it has no window, so the rows never reload the real table. [CN] 演示行用这个表格生成与执行：它没有 window，行不会刷新真正的表格。
    private let sourceTable = UITableView(frame: .zero, style: .insetGrouped)
    /// [EN] The table's row 0 of section 0. [CN] 表格第 0 个 section 的唯一一行。
    @objc let cell = CYLDemoTagListCell()
    private var signature: String?
    private var rowCounts: [Int] = []
    private var badgeRowCount = 0
    private var badgeCell: ((Int) -> UITableViewCell)?
    private var didSelectBadgeRow: ((Int) -> Void)?

    /// [EN] Makes the tag list; the host's table shows `cell` as the only row of its first section. [CN] 生成 TagList；宿主的表格把 `cell` 作为第一个 section 的唯一一行显示。
    @discardableResult
    @objc(installOnTableView:host:badgeRowCount:badgeCell:didSelectBadgeRow:)
    static func install(on tableView: UITableView, host: UIViewController, badgeRowCount: Int, badgeCell: @escaping (Int) -> UITableViewCell,
                        didSelectBadgeRow: @escaping (Int) -> Void) -> CYLDemoTagList {
        let list = CYLDemoTagList()
        list.badgeRowCount = badgeRowCount
        list.badgeCell = badgeCell
        list.didSelectBadgeRow = didSelectBadgeRow
        // [EN] The page behind the glass is a gradient (light and dark), so the glass has colors to bend and blur. [CN] 玻璃之后的页面是渐变色（浅色与深色），玻璃才有可折射、可模糊的颜色。
        tableView.backgroundView = CYLDemoGradientView()
        list.host = host
        list.tableView = tableView
        list.cell.tableView = tableView
        list.cell.list.menuDelegate = list
        // [EN] A skin picked from the menu or the sheet changes the rows' subtitles. [CN] 从菜单或弹出列表选择皮肤会改变各行的副标题。
        host.view.cyl_themeDidChangeBlock = { [weak list] in list?.reload() }
        list.reload()
        return list
    }

    /// [EN] Builds the tags again when a row's title, subtitle or checkmark changed; the sections the user expanded stay expanded. [CN] 行的标题、副标题或勾号变化时重新生成 Tag；用户已展开的分组保持展开。
    @objc func reload() {
        guard let host else { return }
        let sectionCount = host.cyl_demoSectionCount()
        var sections: [[String: Any]] = []
        var counts: [Int] = []
        for section in 0..<sectionCount {
            let rows = host.cyl_demoRowCount(inSection: section)
            counts.append(rows)
            let items: [[String: Any]] = (0..<rows).map { row in
                Self.item(from: host.cyl_demoCell(for: sourceTable, indexPath: IndexPath(row: row, section: section)), identifier: "\(section)-\(row)")
            }
            sections.append([CYLTagSectionKey.title: host.cyl_demoTitle(forSection: section) ?? "", CYLTagSectionKey.items: items])
        }
        // [EN] The badge samples are tags too (docs/instructions/examples.md): the sample's title, its page and a badge image before the title. [CN] 角标样例也是 Tag（docs/instructions/examples.md）：样例的标题、页面，以及标题前的角标图片。
        if let badgeCell, badgeRowCount > 0 {
            counts.append(badgeRowCount)
            sections.append([CYLTagSectionKey.title: cylDemoLocalizedString("角标"),
                             CYLTagSectionKey.items: (0..<badgeRowCount).map { Self.badgeItem(from: badgeCell($0), row: $0) }])
        }
        let newSignature = sections.map { section in
            let items = (section[CYLTagSectionKey.items] as? [[String: Any]]) ?? []
            return ((section[CYLTagSectionKey.title] as? String) ?? "") + "|" + items.map {
                "\($0[CYLTagItemKey.title] ?? "")-\($0[CYLTagItemKey.subtitle] ?? "")"
            }.joined(separator: "|")
        }.joined(separator: "||")
        guard newSignature != signature else { return }
        let expanded = (0..<sectionCount).filter { signature != nil && cell.list.isSectionExpanded($0) }
        signature = newSignature
        rowCounts = counts
        cell.list.applyConfiguration(Self.configuration(sections: sections))
        expanded.forEach { cell.list.setExpanded(true, forSection: $0, animated: false) }
        cell.setNeedsLayout()
    }

    /// [EN] A tag from a row's cell: its main title and icon, its subtitle (and a checkmark) as the callout. [CN] 由一行的 cell 生成 Tag：主标题与图标，副标题（及勾号）为浮层。
    private static func item(from cell: UITableViewCell, identifier: String) -> [String: Any] {
        let mark = cell.accessoryType == .checkmark ? "✓" : nil
        let text = tagText(title: cell.textLabel?.text ?? "",
                           subtitle: [mark, cell.detailTextLabel?.text].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · "))
        var item: [String: Any] = [CYLTagItemKey.identifier: identifier, CYLTagItemKey.title: text[0]]
        if !text[1].isEmpty { item[CYLTagItemKey.subtitle] = text[1] }
        if let image = cell.imageView?.image { item[CYLTagItemKey.image] = image }
        return item
    }

    /// [EN] A badge sample's tag: like `item(from:)` but without the row's icon; the badge (`CYLTag.badgeText`, `badgeColor`, `badgeAccessibilityLabel`) is the image before the title. [CN] 角标样例的 Tag：与 `item(from:)` 相同但不用行图标；角标（`CYLTag.badgeText`、`badgeColor`、`badgeAccessibilityLabel`）是标题前的图片。
    private static func badgeItem(from cell: UITableViewCell, row: Int) -> [String: Any] {
        var result = item(from: cell, identifier: "badge-\(row)")
        result.removeValue(forKey: CYLTagItemKey.image)
        let sample = badgeSamples[row % badgeSamples.count]
        let tag = CYLTag(title: result[CYLTagItemKey.title] as? String ?? "")
        tag.badgeText = sample.text
        tag.badgeColor = sample.purple ? .systemPurple : .systemRed
        tag.badgeAccessibilityLabel = cylBadgeAccessibilityDescriptionEntryPoint(sample.text as NSString) as String?
        let source = CYLTagDataSource(tags: [tag])
        source.baseStyle = CYLMenuStyle(configuration: styleConfiguration)
        if let image = source.menuImageForItem(at: IndexPath(item: 0, section: 0)) { result[CYLTagItemKey.image] = image }
        return result
    }

    private static let styleConfiguration: [String: Any] = [
        // [EN] `leading`: a wrapped title starts at the leading margin, not centered. [CN] `leading`：换行的标题从起始边距开始，不居中。
        CYLMenuStyleKey.titleMaxLines: titleMaxLines, CYLMenuStyleKey.contentAlignment: "leading", CYLMenuStyleKey.backgroundStyle: "liquidGlass",
        CYLMenuStyleKey.backgroundColor: "#00000000",
        // [EN] Each section is a Liquid Glass card (pin bbe56951 or newer). [CN] 每个分组是一张液态玻璃卡片（pin bbe56951 或更新）。
        CYLMenuStyleKey.sectionStyle: "insetGrouped",
        // [EN] No side inset: the cards line up with the table's own rounded sections (the cell is already inset). [CN] 左右无边距：卡片与表格自己的圆角分组对齐（cell 本身已有边距）。
        CYLMenuStyleKey.sectionInsets: "{10, 0, 10, 0}", CYLMenuStyleKey.sectionBackgroundStyle: "liquidGlass",
    ]

    /// [EN] The tag list configuration of `sections`. [CN] `sections` 的 TagList 配置。
    static func configuration(sections: [[String: Any]]) -> [String: Any] {
        [
            // [EN] `none`: a tap selects nothing but still reports the item, so the host runs the row's action. [CN] `none`：点击不选中，仍回调条目，由宿主执行该行的动作。
            CYLTagListKey.selectionMode: "none",
            CYLTagListKey.scrollEnabled: false,
            CYLTagListKey.longPressAction: "callout",
            CYLTagListKey.defaultVisibleRows: visibleRows,
            CYLTagListKey.foldControl: [CYLMenuFoldControlKey.position: "tail", CYLMenuFoldControlKey.content: "icon"],
            // [EN] Liquid Glass tags; a clear list background so the page's grouped background shows (the default is a fixed white, and the header texts follow dark mode). [CN] 液态玻璃 Tag；列表背景透明，显示页面的分组背景（默认是固定白色，而标题文字会随深色模式变化）。
            CYLTagListKey.style: styleConfiguration,
            CYLTagListKey.sections: sections,
        ]
    }

    // MARK: - CYLMenuDelegate

    func menu(_ menu: Any, didSelectItemAt indexPath: IndexPath) {
        guard let host, indexPath.section < rowCounts.count, indexPath.item < rowCounts[indexPath.section] else { return }
        if indexPath.section == host.cyl_demoSectionCount() {
            didSelectBadgeRow?(indexPath.item)
            return
        }
        host.cyl_demoDidSelectRow(at: indexPath, in: sourceTable)
        // [EN] The row may change a title or a checkmark (a skin, a switch). [CN] 该行可能改变标题或勾号（皮肤、开关）。
        DispatchQueue.main.async { [weak self] in self?.reload() }
    }

    func menu(_ menu: Any, didChangeContentHeight height: CGFloat) {
        cell.setNeedsLayout()
    }
}

/// [EN] The one table cell that holds the tag list and follows its height; clear, so the page's grouped background shows. [CN] 容纳 TagList 并跟随其高度的唯一表格 cell；背景透明，显示页面的分组背景。
@objc(CYLDemoTagListCell)
final class CYLDemoTagListCell: UITableViewCell {
    let list = CYLTagListView(frame: .zero)
    weak var tableView: UITableView?
    private var heightConstraint: NSLayoutConstraint!

    init() {
        super.init(style: .default, reuseIdentifier: nil)
        backgroundColor = .clear
        backgroundConfiguration = .clear()
        selectionStyle = .none
        accessibilityIdentifier = "cyl-demo-tag-list"
        list.backgroundColor = .clear
        list.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(list)
        heightConstraint = list.heightAnchor.constraint(equalToConstant: 44)
        // [EN] Below 1000 so a width that is not known yet never breaks the layout. [CN] 低于 1000，尚未确定宽度时不会破坏布局。
        heightConstraint.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            list.topAnchor.constraint(equalTo: contentView.topAnchor),
            list.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            list.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            heightConstraint,
        ])
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = contentView.bounds.width
        guard width > 0 else { return }
        let height = ceil(max(list.heightThatFitsWidth(width), list.contentHeight))
        guard height > 0, abs(heightConstraint.constant - height) > 0.5 else { return }
        heightConstraint.constant = height
        // [EN] The table measures its rows again (after this layout pass). [CN] 表格重新测量各行（在本次布局之后）。
        DispatchQueue.main.async { [weak tableView] in tableView?.performBatchUpdates(nil) }
    }
}

/// [EN] The gradient page behind the tag list (light and dark variants), in one place for every page of the example. [CN] TagList 之后的渐变页面（浅色与深色），全部页面共用一处。
final class CYLDemoGradientView: UIView {
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        layer.addSublayer(gradient)
        updateColors()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    override func traitCollectionDidChange(_ previous: UITraitCollection?) {
        super.traitCollectionDidChange(previous)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previous) { updateColors() }
    }

    private func updateColors() {
        let hexes = traitCollection.userInterfaceStyle == .dark ? [0x5B2A3C, 0x1F4A63, 0x3B2D5C] : [0xFFB199, 0x7EC8E3, 0xC3AED6]
        gradient.colors = hexes.map { UIColor(red: CGFloat(($0 >> 16) & 0xFF) / 255, green: CGFloat(($0 >> 8) & 0xFF) / 255, blue: CGFloat($0 & 0xFF) / 255, alpha: 1).cgColor }
    }
}
