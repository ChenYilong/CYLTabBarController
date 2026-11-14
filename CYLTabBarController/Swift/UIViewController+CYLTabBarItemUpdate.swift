//
//  UIViewController+CYLTabBarItemUpdate.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Rows, each one switching one thing on the tab, or back.
 * [CN] 每行切换 Tab 的一项，或恢复。
 */
@objc(CYLTabBarItemUpdateRow)
public enum CYLTabBarItemUpdateRow: Int {
    /**
     * [EN] `-updateTabBarItemForViewController:attributes:`. [CN] `-updateTabBarItemForViewController:attributes:`。
     */
    case title
    /**
     * [EN] `-setTabBarItemIconViewProvider:atIndex:`. [CN] `-setTabBarItemIconViewProvider:atIndex:`。
     */
    case iconView
    /**
     * [EN] `-setTabBarItemIconWithURL:selectedURL:size:atIndex:`. [CN] `-setTabBarItemIconWithURL:selectedURL:size:atIndex:`。
     */
    case networkIcon
    /**
     * [EN] The same, for every tab. [CN] 同上，作用于所有 Tab。
     */
    case allNetworkIcons
    /**
     * [EN] `-setTabBarItemIcon:selectedIcon:size:atIndex:`, local images, for every tab. [CN] 同上，本地图片，作用于所有 Tab。
     */
    case allLocalIcons
    /**
     * [EN] The same, with a GIF. [CN] 同上，使用 GIF。
     */
    case GIFIcon
    /**
     * [EN] `-updateTabBarItemsWithAttributes:`. [CN] `-updateTabBarItemsWithAttributes:`。
     */
    case allTitles
    /**
     * [EN] `-replaceViewControllerAtIndex:withViewController:attributes:`, issue #481. [CN] issue #481。
     */
    case replaceNeighbors
    /**
     * [EN] The number of rows. [CN] 行数。
     */
    case count
}

enum CYLTabBarItemUpdateKeys {
    static let initialAttributes = CYLUtilsKeys.key("cyl_tabBarItemUpdateInitialAttributes")
    static let titleUpdated = CYLUtilsKeys.key("cyl_tabBarItemUpdateTitleUpdated")
    static let activeIconRow = CYLUtilsKeys.key("cyl_tabBarItemUpdateActiveIconRow")
    static let allTitlesUpdated = CYLUtilsKeys.key("cyl_tabBarItemUpdateAllTitlesUpdated")
    static let allNetworkIcons = CYLUtilsKeys.key("cyl_tabBarItemUpdateAllNetworkIcons")
    static let allLocalIcons = CYLUtilsKeys.key("cyl_tabBarItemUpdateAllLocalIcons")
    static let plusButtonInitialAttributes = CYLUtilsKeys.key("cyl_tabBarItemUpdatePlusButtonInitialAttributes")
    static let replacedNeighbors = CYLUtilsKeys.key("cyl_tabBarItemUpdateReplacedNeighbors")
    static let cellIdentifier = "CYLTabBarItemUpdateCell"
    static let iconSize = CGSize(width: 24, height: 24)
}

/**
 * [EN] One neighbor tab replaced by `-cyl_didSelectTabBarItemUpdateRow:` (#481), to put back.
 * [CN] `-cyl_didSelectTabBarItemUpdateRow:` 替换的一个相邻 Tab（#481），用于恢复。
 */
final class CYLReplacedNeighbor: NSObject {
    let original: UIViewController
    let attributes: [String: Any]
    let replacement: UIViewController

    init(original: UIViewController, attributes: [String: Any], replacement: UIViewController) {
        self.original = original
        self.attributes = attributes
        self.replacement = replacement
    }
}

/**
 * FIX: issue #601
 * [EN] `UIViewController (CYLTabBarItemUpdate)`: rows that try the in-place tab item updates of `CYLTabBarController`, in
 *      every style, on the tab of this view controller. Each row switches one thing, and back on a second tap, to the
 *      `tabBarItemsAttributes` given at initialization. Part of the settings section (`UIViewController+CYLSettingsSection.h`).
 *      Translated from Objective-C (docs/Swift-Migration.md, step 29); selectors kept.
 * [CN] `UIViewController (CYLTabBarItemUpdate)`：试用 `CYLTabBarController` 原地更新 Tab 的若干行，适用于所有样式，作用于当前页面所在的
 *      Tab。每行切换一项，再点一次恢复为初始化时传入的 `tabBarItemsAttributes`。属于设置分组（`UIViewController+CYLSettingsSection.h`）。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 29 步），selector 不变。
 */
extension UIViewController {

    /**
     * [EN] Number of the rows. [CN] 行数。
     */
    @objc(cyl_tabBarItemUpdateRowCount)
    public func cyl_tabBarItemUpdateRowCount() -> Int {
        CYLTabBarItemUpdateRow.count.rawValue
    }

    /**
     * [EN] Cell of row `row`, in the app's language. [CN] 第 `row` 行的 cell，使用 App 语言。
     */
    @objc(cyl_tabBarItemUpdateCellForTableView:row:)
    public func cyl_tabBarItemUpdateCell(for tableView: UITableView, row: Int) -> UITableViewCell {
        let identifier = CYLTabBarItemUpdateKeys.cellIdentifier
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            cell.textLabel?.font = .boldSystemFont(ofSize: 15)
            cell.detailTextLabel?.textColor = .gray
            return cell
        }()
        let (title, subtitle, symbolName) = Self.cyl_tabBarItemUpdateTexts(of: CYLTabBarItemUpdateRow(rawValue: row) ?? .allTitles)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = subtitle
        cell.imageView?.image = UIImage(systemName: symbolName)
        cell.accessoryType = cyl_isTabBarItemUpdateRowActive(row) ? .checkmark : .none
        return cell
    }

    /**
     * [EN] Runs row `row`: switches its change on this view controller's tab, or back.
     * [CN] 执行第 `row` 行：对当前页面所在的 Tab 应用该项更改，或恢复。
     */
    @objc(cyl_didSelectTabBarItemUpdateRow:)
    public func cyl_didSelectTabBarItemUpdateRow(_ row: Int) {
        let tabViewController = cyl_tabBarItemUpdateTabViewController
        guard let tabBarController = cyl_tabBarItemUpdateTabBarController,
              let index = tabBarController.viewControllers?.firstIndex(of: tabViewController) else {
            return
        }
        _ = cyl_initialTabBarItemsAttributes(of: tabBarController)
        _ = cyl_initialPlusButtonAttributes(of: tabBarController)
        let updateRow = CYLTabBarItemUpdateRow(rawValue: row) ?? .allTitles
        switch updateRow {
        case .title:
            cyl_toggleTitle(of: tabViewController, in: tabBarController)
        case .iconView, .networkIcon, .GIFIcon:
            cyl_toggleIconRow(updateRow, of: tabViewController, at: index, in: tabBarController)
        case .allNetworkIcons, .allLocalIcons:
            cyl_toggleAllIconsRow(updateRow, in: tabBarController)
        case .replaceNeighbors:
            cyl_toggleReplacedNeighborsOfTab(at: index, in: tabBarController)
        case .allTitles, .count:
            cyl_toggleAllTitles(in: tabBarController)
        }
    }

    // MARK: Rows

    private static func cyl_tabBarItemUpdateTexts(of row: CYLTabBarItemUpdateRow) -> (String, String, String) {
        switch row {
        case .title:
            return (CYLLocalizedString("更换 Tab 标题"), CYLLocalizedString("原地更换当前页 Tab 的标题，再点恢复"), "textformat")
        case .iconView:
            return (CYLLocalizedString("切换 Tab 图标"), CYLLocalizedString("用自定义视图替换当前页 Tab 的图标，再点恢复"), "star")
        case .networkIcon:
            return (CYLLocalizedString("下载网络图标"), CYLLocalizedString("从网络下载当前页 Tab 的图标（带缓存），再点恢复"),
                    "icloud.and.arrow.down")
        case .allNetworkIcons:
            return (CYLLocalizedString("批量下载网络图标"), CYLLocalizedString("下载并更新所有 Tab 的图标，再点恢复"),
                    "square.and.arrow.down.on.square")
        case .allLocalIcons:
            return (CYLLocalizedString("批量使用本地图标"),
                    CYLLocalizedString("用本地图片（图片名、文件路径、UIImage、文件 URL）更新所有 Tab 的图标，再点恢复"), "photo.on.rectangle")
        case .GIFIcon:
            return (CYLLocalizedString("GIF 动图图标"), CYLLocalizedString("当前页 Tab 显示 GIF 动图，再点恢复"), "sparkles")
        case .replaceNeighbors:
            return (CYLLocalizedString("替换相邻 Tab 的页面"), CYLLocalizedString("把当前 Tab 两侧的 Tab 换成其他页面（issue #481），再点恢复"),
                    "arrow.left.arrow.right")
        case .allTitles, .count:
            return (CYLLocalizedString("批量更换标题"), CYLLocalizedString("一次更新所有 Tab 的标题，再点恢复"), "list.bullet")
        }
    }

    private func cyl_isTabBarItemUpdateRowActive(_ row: Int) -> Bool {
        let tabViewController = cyl_tabBarItemUpdateTabViewController
        let tabBarController = cyl_tabBarItemUpdateTabBarController
        switch CYLTabBarItemUpdateRow(rawValue: row) ?? .allTitles {
        case .title:
            return Self.cyl_flag(tabViewController, CYLTabBarItemUpdateKeys.titleUpdated)
        case .iconView, .networkIcon, .GIFIcon:
            return (objc_getAssociatedObject(tabViewController, CYLTabBarItemUpdateKeys.activeIconRow) as? NSNumber)?.intValue == row
        case .allNetworkIcons:
            return Self.cyl_flag(tabBarController, CYLTabBarItemUpdateKeys.allNetworkIcons)
        case .allLocalIcons:
            return Self.cyl_flag(tabBarController, CYLTabBarItemUpdateKeys.allLocalIcons)
        case .replaceNeighbors:
            return tabBarController.map { objc_getAssociatedObject($0, CYLTabBarItemUpdateKeys.replacedNeighbors) != nil } ?? false
        case .allTitles, .count:
            return Self.cyl_flag(tabBarController, CYLTabBarItemUpdateKeys.allTitlesUpdated)
        }
    }

    /**
     * [EN] The title: "Purchased courses"; tapped again, the title given at initialization.
     * [CN] 标题：“已购课程”；再次点击，恢复为初始化时的标题。
     */
    private func cyl_toggleTitle(of tabViewController: UIViewController, in tabBarController: CYLTabBarController) {
        let isUpdated = Self.cyl_flag(tabViewController, CYLTabBarItemUpdateKeys.titleUpdated)
        let title = isUpdated ? cyl_initialTitle(of: tabViewController, in: tabBarController) : CYLLocalizedString("已购课程")
        if tabBarController.updateTabBarItem(for: tabViewController, attributes: [CYLTabBarItemTitle: title ?? ""]) {
            Self.cyl_setFlag(tabViewController, CYLTabBarItemUpdateKeys.titleUpdated, !isUpdated)
        }
    }

    /**
     * [EN] The icon of this row; the same row again, the icon given at initialization.
     * [CN] 该行的图标；再次点击同一行，恢复为初始化时的图标。
     */
    private func cyl_toggleIconRow(_ row: CYLTabBarItemUpdateRow, of tabViewController: UIViewController, at index: Int,
                                   in tabBarController: CYLTabBarController) {
        let key = CYLTabBarItemUpdateKeys.activeIconRow
        if (objc_getAssociatedObject(tabViewController, key) as? NSNumber)?.intValue == row.rawValue {
            cyl_restoreInitialIcon(of: tabViewController, at: index, in: tabBarController)
            objc_setAssociatedObject(tabViewController, key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        let isSet: Bool
        switch row {
        case .iconView:
            // [EN] Any view works here, e.g. a `UIImageView` loaded by SDWebImage or Kingfisher. [CN] 这里可以是任意视图。
            isSet = tabBarController.setTabBarItemIconViewProvider({ selected in
                let iconView = UIImageView(image: UIImage(systemName: selected ? "star.fill" : "star"))
                iconView.tintColor = selected ? .systemOrange : .systemGray
                iconView.contentMode = .scaleAspectFit
                iconView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
                return iconView
            }, at: UInt(index))
        case .networkIcon:
            // [EN] Downloaded once, then from the cache; the tab keeps its icon until the images are ready.
            // [CN] 只下载一次，之后读取缓存；图片就绪前 Tab 保持自身图标。
            let base = "https://cdn-icons-png.flaticon.com/512/3132/"
            isSet = URL(string: base + "3132732.png").map {
                tabBarController.setTabBarItemIconWith($0, selectedURL: URL(string: base + "3132779.png"),
                                                       size: CYLTabBarItemUpdateKeys.iconSize, at: UInt(index))
            } ?? false
        default:
            // [EN] Any URL, a file one here. [CN] 任何 URL 都可以，这里使用本地文件 URL。
            let gifURL = CYLResourceBundle().url(forResource: "cyl_tab_sample_animated", withExtension: "gif")
            isSet = gifURL.map {
                tabBarController.setTabBarItemIconWith($0, selectedURL: nil, size: CYLTabBarItemUpdateKeys.iconSize, at: UInt(index))
            } ?? false
        }
        if isSet {
            objc_setAssociatedObject(tabViewController, key, NSNumber(value: row.rawValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] Every tab's title with a star (one entry per tab, none for the plus button), and the plus button's; tapped again,
     *      the titles given at initialization.
     * [CN] 所有 Tab 的标题加上星号（每个 Tab 一项，PlusButton 不占项），PlusButton 的标题也一样；再次点击，恢复为初始化时的标题。
     */
    private func cyl_toggleAllTitles(in tabBarController: CYLTabBarController) {
        let isUpdated = Self.cyl_flag(tabBarController, CYLTabBarItemUpdateKeys.allTitlesUpdated)
        let attributes: [[String: Any]] = cyl_realTabs(of: tabBarController).map { _, viewController in
            let title: String?
            if isUpdated {
                title = cyl_initialTitle(of: viewController, in: tabBarController)
                // [EN] Every title is the initial one again, also the one of "Change tab title". [CN] 所有标题都已恢复。
                Self.cyl_setFlag(viewController, CYLTabBarItemUpdateKeys.titleUpdated, false)
            } else {
                title = "★ " + (cyl_title(of: viewController, in: tabBarController) ?? "")
            }
            return [CYLTabBarItemTitle: title ?? ""]
        }
        tabBarController.updateTabBarItems(withAttributes: attributes)
        let plusTitle = CYLPlusButton(forOwner: tabBarController)?.cyl_title()
        let initialPlusTitle = cyl_initialPlusButtonAttributes(of: tabBarController)[CYLTabBarItemTitle]
        if isUpdated, let initialPlusTitle {
            tabBarController.updatePlusButton(attributes: [CYLTabBarItemTitle: initialPlusTitle])
        } else if !isUpdated, let plusTitle {
            tabBarController.updatePlusButton(attributes: [CYLTabBarItemTitle: "★ " + plusTitle])
        }
        Self.cyl_setFlag(tabBarController, CYLTabBarItemUpdateKeys.allTitlesUpdated, !isUpdated)
    }

    /**
     * [EN] The icons of every tab, in order (repeated past the fourth), unselected then selected: from the network, or local,
     *      one kind of source per tab (an image name, a file path, a `UIImage`, a file URL of a GIF); a missing local image
     *      falls back to a symbol.
     * [CN] 每个 Tab 的图标，按顺序（超过 4 个时循环），先未选中后选中：来自网络，或来自本地，每个 Tab 一种来源（图片名、文件路径、`UIImage`、
     *      GIF 文件 URL）；缺少本地图片时改用系统符号。
     */
    private func cyl_icons(ofAllIconsRow row: CYLTabBarItemUpdateRow) -> [[Any]] {
        if row == .allNetworkIcons {
            let base = "https://cdn-icons-png.flaticon.com/512/"
            return [
                [base + "1946/1946488.png", base + "1946/1946436.png"],
                [base + "2099/2099085.png", base + "2099/2099085.png"],
                [base + "2099/2099100.png", base + "2099/2099100.png"],
                [base + "1077/1077063.png", base + "1077/1077114.png"],
            ]
        }
        func symbol(_ name: String, _ color: UIColor) -> Any {
            UIImage(systemName: name)?.withTintColor(color, renderingMode: .alwaysOriginal) ?? name
        }
        // [EN] An image name, as `CYLTabBarItemImage`. [CN] 图片名，与 `CYLTabBarItemImage` 相同。
        let named: Any = UIImage(named: "img_tab_home_0") != nil ? "img_tab_home_0" : symbol("house", .systemGray)
        let namedSelected: Any = UIImage(named: "img_tab_home_1") != nil ? "img_tab_home_1" : symbol("house.fill", .systemOrange)
        // [EN] The absolute path of a file (#535). [CN] 文件的绝对路径（#535）。
        let path: Any = Bundle.main.path(forResource: "img_tab_message_0", ofType: "png") ?? symbol("envelope", .systemGray)
        let pathSelected: Any = Bundle.main.path(forResource: "img_tab_message_1", ofType: "png") ?? symbol("envelope.fill", .systemOrange)
        // [EN] A file URL of a GIF, in the library's resource bundle. [CN] 本库资源包中 GIF 的文件 URL。
        let fileURL: Any = CYLResourceBundle().url(forResource: "cyl_tab_sample_animated", withExtension: "gif") ?? symbol("sparkles", .systemPurple)
        return [
            [named, namedSelected],
            [path, pathSelected],
            [symbol("heart", .systemGray), symbol("heart.fill", .systemRed)],
            [fileURL, fileURL],
        ]
    }

    /**
     * [EN] Updates the icon of every tab with the icons of `row` (`-setTabBarItemIcon:selectedIcon:size:atIndex:`), and the
     *      plus button's unless its picture is its background image; tapped again, the icons given at initialization. One of
     *      the two rows at a time.
     * [CN] 用 `row` 的图标更新所有 Tab 的图标（`-setTabBarItemIcon:selectedIcon:size:atIndex:`），以背景图为图片的 PlusButton 以外也更新
     *      PlusButton；再次点击，恢复为初始化时的图标。两行同一时间只有一行生效。
     */
    private func cyl_toggleAllIconsRow(_ row: CYLTabBarItemUpdateRow, in tabBarController: CYLTabBarController) {
        let key = row == .allNetworkIcons ? CYLTabBarItemUpdateKeys.allNetworkIcons : CYLTabBarItemUpdateKeys.allLocalIcons
        let otherKey = row == .allNetworkIcons ? CYLTabBarItemUpdateKeys.allLocalIcons : CYLTabBarItemUpdateKeys.allNetworkIcons
        let isActive = Self.cyl_flag(tabBarController, key)
        let icons = cyl_icons(ofAllIconsRow: row)
        for (tabIndex, (index, viewController)) in cyl_realTabs(of: tabBarController).enumerated() {
            // [EN] Replaces this tab's own icon row as well. [CN] 同时取代该 Tab 单独设置的图标行。
            objc_setAssociatedObject(viewController, CYLTabBarItemUpdateKeys.activeIconRow, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if isActive {
                cyl_restoreInitialIcon(of: viewController, at: index, in: tabBarController)
            } else {
                let tabIcons = icons[tabIndex % icons.count]
                tabBarController.setTabBarItemIcon(tabIcons[0], selectedIcon: tabIcons[1], size: CYLTabBarItemUpdateKeys.iconSize,
                                                   at: UInt(index))
            }
        }
        let plusButton = CYLPlusButton(forOwner: tabBarController)
        let drawsTitleOverBackgroundImage = (plusButton?.value(forKey: "cyl_drawsTitleOverBackgroundImage") as? Bool) ?? false
        if !drawsTitleOverBackgroundImage {
            cyl_updatePlusButtonIcons(ofAllIconsRow: row, restoring: isActive, in: tabBarController)
        }
        Self.cyl_setFlag(tabBarController, key, !isActive)
        Self.cyl_setFlag(tabBarController, otherKey, false)
    }

    private func cyl_updatePlusButtonIcons(ofAllIconsRow row: CYLTabBarItemUpdateRow, restoring: Bool,
                                           in tabBarController: CYLTabBarController) {
        if restoring {
            var imageAttributes = cyl_initialPlusButtonAttributes(of: tabBarController)
            imageAttributes[CYLTabBarItemTitle] = nil
            if !imageAttributes.isEmpty {
                tabBarController.updatePlusButton(attributes: imageAttributes)
            }
            return
        }
        let icons: [Any]
        if row == .allNetworkIcons {
            icons = ["https://cdn-icons-png.flaticon.com/512/992/992651.png", "https://cdn-icons-png.flaticon.com/512/1828/1828817.png"]
        } else {
            icons = ["plus.circle", "plus.circle.fill"].map {
                UIImage(systemName: $0)?.withTintColor(.systemOrange, renderingMode: .alwaysOriginal) as Any
            }
        }
        tabBarController.updatePlusButton(attributes: [CYLTabBarItemImageURL: icons[0], CYLTabBarItemSelectedImageURL: icons[1]])
    }

    /**
     * FIX: issue #481
     * [EN] The nearest real tabs on each side of the tab at `index` show other pages, with their own title and icon; tapped
     *      again, the original pages and tab items come back.
     * [CN] 第 `index` 个 Tab 两侧最近的真实 Tab 显示其他页面，使用各自的标题和图标；再次点击，恢复原来的页面和 TabBarItem。
     */
    private func cyl_toggleReplacedNeighborsOfTab(at index: Int, in tabBarController: CYLTabBarController) {
        let key = CYLTabBarItemUpdateKeys.replacedNeighbors
        if let replaced = objc_getAssociatedObject(tabBarController, key) as? [CYLReplacedNeighbor] {
            for entry in replaced {
                if let replacedIndex = tabBarController.viewControllers?.firstIndex(of: entry.replacement) {
                    tabBarController.replaceViewController(at: UInt(replacedIndex), with: entry.original, attributes: entry.attributes)
                }
            }
            objc_setAssociatedObject(tabBarController, key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            cyl_redecorate(tabBarController)
            return
        }
        var entries: [CYLReplacedNeighbor] = []
        for (side, (name, symbolName, step)) in [("A", "a.circle", -1), ("B", "b.circle", 1)].enumerated() {
            guard let neighborIndex = cyl_realTabIndex(nextTo: index, step: step, in: tabBarController),
                  let original = tabBarController.viewControllers?[neighborIndex] else {
                continue
            }
            let originalAttributes = tabBarController.tabBarItemAttributes(at: UInt(neighborIndex)) ?? [:]
            let title = String(format: CYLLocalizedString("替换页 %@"), name)
            let page = UIViewController()
            page.title = title
            page.view.backgroundColor = side == 0 ? .systemTeal : .systemPink
            let replacement = UINavigationController(rootViewController: page)
            var attributes: [String: Any] = [CYLTabBarItemTitle: title]
            attributes[CYLTabBarItemImage] = UIImage(systemName: symbolName)
            attributes[CYLTabBarItemSelectedImage] = UIImage(systemName: symbolName + ".fill")
            if tabBarController.replaceViewController(at: UInt(neighborIndex), with: replacement, attributes: attributes) {
                entries.append(CYLReplacedNeighbor(original: original, attributes: originalAttributes, replacement: replacement))
            }
        }
        if !entries.isEmpty {
            objc_setAssociatedObject(tabBarController, key, entries, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        cyl_redecorate(tabBarController)
    }

    /**
     * [EN] The tab buttons are new after a replacement: once they exist (`-performWhenTabBarItemsReady:`, issue #22), the
     *      app's decorations are added again, when the tab bar controller has `-cyl_demo_decorateTabBarController:`.
     * [CN] 替换后 Tab 按钮是新的：在其创建后（`-performWhenTabBarItemsReady:`，issue #22），若 TabBarController 实现了
     *      `-cyl_demo_decorateTabBarController:`，重新添加 App 的装饰。
     */
    private func cyl_redecorate(_ tabBarController: CYLTabBarController) {
        let decorate = NSSelectorFromString("cyl_demo_decorateTabBarController:")
        guard tabBarController.responds(to: decorate) else { return }
        tabBarController.perform(whenTabBarItemsReady: { readyTabBarController in
            _ = readyTabBarController.perform(decorate, with: readyTabBarController)
        })
    }

    // MARK: Helpers

    private static func cyl_flag(_ object: AnyObject?, _ key: UnsafeRawPointer) -> Bool {
        guard let object else { return false }
        return (objc_getAssociatedObject(object, key) as? NSNumber)?.boolValue ?? false
    }

    private static func cyl_setFlag(_ object: AnyObject, _ key: UnsafeRawPointer, _ value: Bool) {
        objc_setAssociatedObject(object, key, value ? NSNumber(value: true) : nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /**
     * [EN] The tabs with their index, without the plus button's page and placeholders.
     * [CN] 各 Tab 及其下标，不含 PlusButton 的页面与占位页面。
     */
    private func cyl_realTabs(of tabBarController: CYLTabBarController) -> [(Int, UIViewController)] {
        let plusChildViewController = CYLPlusButton.plusChildViewController(forOwner: tabBarController)
        return (tabBarController.viewControllers ?? []).enumerated().filter { _, viewController in
            !viewController.cyl_isPlaceholder && viewController !== plusChildViewController
        }.map { ($0.offset, $0.element) }
    }

    /**
     * [EN] The nearest real tab from `index` in direction `step`; nil when none.
     * [CN] 从 `index` 沿 `step` 方向最近的真实 Tab；没有时为 nil。
     */
    private func cyl_realTabIndex(nextTo index: Int, step: Int, in tabBarController: CYLTabBarController) -> Int? {
        let realIndexes = Set(cyl_realTabs(of: tabBarController).map { $0.0 })
        let count = tabBarController.viewControllers?.count ?? 0
        return stride(from: index + step, to: step < 0 ? -1 : count, by: step).first { realIndexes.contains($0) }
    }

    /**
     * [EN] The `tabBarItemsAttributes` given at initialization, per tab, copied before the first change (the tab bar
     *      controller merges each update into them).
     * [CN] 初始化时传入的 `tabBarItemsAttributes`，按 Tab 保存，在第一次修改前复制（TabBarController 会把每次更新合并进去）。
     */
    private func cyl_initialTabBarItemsAttributes(of tabBarController: CYLTabBarController) -> NSMapTable<UIViewController, NSDictionary> {
        let key = CYLTabBarItemUpdateKeys.initialAttributes
        if let attributes = objc_getAssociatedObject(tabBarController, key) as? NSMapTable<UIViewController, NSDictionary> {
            return attributes
        }
        let attributes = NSMapTable<UIViewController, NSDictionary>.weakToStrongObjects()
        for (index, viewController) in (tabBarController.viewControllers ?? []).enumerated() {
            if let tabAttributes = tabBarController.tabBarItemAttributes(at: UInt(index)) {
                attributes.setObject(tabAttributes as NSDictionary, forKey: viewController)
            }
        }
        objc_setAssociatedObject(tabBarController, key, attributes, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return attributes
    }

    /**
     * [EN] The plus button's title and images before the first change (`-updatePlusButtonWithAttributes:` keys).
     * [CN] 第一次修改前 PlusButton 的标题与图片（`-updatePlusButtonWithAttributes:` 的 key）。
     */
    private func cyl_initialPlusButtonAttributes(of tabBarController: CYLTabBarController) -> [String: Any] {
        let key = CYLTabBarItemUpdateKeys.plusButtonInitialAttributes
        if let attributes = objc_getAssociatedObject(tabBarController, key) as? [String: Any] {
            return attributes
        }
        guard let plusButton = CYLPlusButton(forOwner: tabBarController) else { return [:] }
        var attributes: [String: Any] = [:]
        attributes[CYLTabBarItemTitle] = plusButton.cyl_title()
        attributes[CYLTabBarItemImage] = plusButton.image(for: .normal)
        attributes[CYLTabBarItemSelectedImage] = plusButton.image(for: .selected)
        objc_setAssociatedObject(tabBarController, key, attributes, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return attributes
    }

    private func cyl_initialTitle(of tabViewController: UIViewController, in tabBarController: CYLTabBarController) -> String? {
        let attributes = cyl_initialTabBarItemsAttributes(of: tabBarController).object(forKey: tabViewController)
        return attributes?[CYLTabBarItemTitle] as? String ?? cyl_title(of: tabViewController, in: tabBarController)
    }

    /**
     * [EN] The tab's initial icon back: its network icons when it had `CYLTabBarItemImageURL`, else its own (nil provider).
     * [CN] 恢复 Tab 的初始图标：有 `CYLTabBarItemImageURL` 时为网络图标，否则为 Tab 自身的图标（provider 传 nil）。
     */
    private func cyl_restoreInitialIcon(of tabViewController: UIViewController, at index: Int, in tabBarController: CYLTabBarController) {
        let attributes = cyl_initialTabBarItemsAttributes(of: tabBarController).object(forKey: tabViewController)
        var urlAttributes: [String: Any] = [:]
        for key in [CYLTabBarItemImageURL, CYLTabBarItemSelectedImageURL, CYLTabBarItemImageURLSize] {
            urlAttributes[key] = attributes?[key]
        }
        if urlAttributes[CYLTabBarItemImageURL] != nil {
            tabBarController.updateTabBarItem(at: UInt(index), attributes: urlAttributes)
        } else {
            tabBarController.setTabBarItemIconViewProvider(nil, at: UInt(index))
        }
    }

    private var cyl_tabBarItemUpdateTabBarController: CYLTabBarController? {
        cyl_owningTabBarController() ?? cyl_tabBarController
    }

    /**
     * [EN] The tab of this page: its navigation controller, or itself. [CN] 当前页面所在的 Tab：其导航控制器或自身。
     */
    private var cyl_tabBarItemUpdateTabViewController: UIViewController {
        navigationController ?? self
    }

    /**
     * [EN] The title a tab shows: FlatDesign shows `cyl_tabBarItem` (reached by selector), the other styles `tabBarItem`.
     * [CN] Tab 显示的标题：扁平样式显示 `cyl_tabBarItem`（通过 selector 访问），其他样式显示 `tabBarItem`。
     */
    private func cyl_title(of tabViewController: UIViewController, in tabBarController: CYLTabBarController) -> String? {
        if tabBarController.tabBarStyleType == .flatDesign,
           let item = CYLFlatDesignLookup.tabBarItem(of: tabViewController) {
            return item.value(forKey: "title") as? String
        }
        return tabViewController.tabBarItem.title
    }
}
