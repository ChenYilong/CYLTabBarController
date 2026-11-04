//
//  GalleryViewController.swift
//  CYLTabBarGallery
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

// [EN] The gallery list: one row per scene; tapping a row presents that tab bar. It is also the delegate of the system
//      UITabBarController scenes, whose "Photo" tab opens a dialog while looking selected.
// [CN] 图库列表：每个场景一行，点击某行展示对应的 TabBar。同时也是系统 UITabBarController 场景的代理：其 "Photo" Tab 显示为选中并
//      打开对话框。
final class GalleryViewController: UITableViewController, UITabBarControllerDelegate {

    let sectionTitleArray = ["Basic", "Embed", "Animation", "Irregular", "Customize click", "Remind", "Lottie", "New APIs"]

    let titleArray: [[String]] = [
        [
            "UITabBarController style",
            "CYLTabBarController like system style",
            "Mix styled and system items",
            "CYLTabBarController with Liquid Glass",
            "UITabBarController with 'More'",
            "CYLTabBarController with 'More'",
            "Mix styled and system items with 'More'",
            "Liquid Glass with 'More'",
            "UITabBarController with non-zero default index",
            "CYLTabBarController with non-zero default index",
            "Classic design on every system",
            "Liquid Glass with badges",
            "UITabBarController tab style",
        ],
        [
            "CYLTabBarController embeds UINavigationController",
            "UINavigationController embeds CYLTabBarController",
        ],
        [
            "Customize the selected color",
            "Spring animation",
            "Background color change",
            "With a pressed effect",
            "Suggest a click",
        ],
        [
            "A larger button in the middle",
        ],
        [
            "Custom action for the button click",
            "Add a special reminder bubble",
        ],
        [
            "System remind style",
            "Imitate system remind style",
            "Remind with animation",
            "Remind with animation (2)",
            "Customize remind style",
        ],
        [
            "Lottie",
        ],
        [
            "Reselect: pop to root, then scroll to top",
            "Press and reselect animations",
            "Custom action on a regular tab",
            "Per-tab colors, fonts and backgrounds",
            "Accessibility identifiers",
            "Centered tabs around a plus button",
            "Edge insets and gaps between tabs",
        ],
    ]

    let subtitleArray: [[String]] = [
        [
            "The system tab bar, for comparison",
            "Three tabs; full width on iOS 26 (FlatDesign)",
            "Tabs 1, 3 and 5 bounce; tabs 2 and 4 are plain",
            "\"Photo\" opens a dialog (cyl_customActionTabBarItemIdentifiers)",
            "Eight tabs; \"Photo\" opens a dialog (delegate)",
            "Eight tabs, full width",
            "Eight tabs; every other one bounces",
            "Eight tabs with Liquid Glass",
            "selectedIndex = 2 after presenting",
            "selectedIndex = 2 after presenting",
            "CYLTabBarStyleTypeFlatDesign, white bar; \"Photo\" opens a dialog",
            "New, 99+, a blue 1, a dot, none; the selected tab hides its badge",
            "UITab (iOS 18+), eight tabs, \"Favor\" selected; \"Photo\" opens a dialog",
        ],
        [
            "A navigation controller in every tab",
            "One navigation bar above the tab bar controller",
        ],
        [
            "CYLTabBarItemTitleColor / IconColor per tab",
            "A CYLTabButtonAnimation that bounces on select and reselect",
            "CYLTabBarItemBackgroundColor / SelectedBackgroundColor",
            "Larger icons that shrink while pressed (highlight hooks)",
            "The middle tab pulses every 3 s until it is selected",
        ],
        [
            "A raised round CYLPlusButton that responds inside its circle",
        ],
        [
            "The center button shows an action sheet instead of a page",
            "A bubble above \"Me\"; \"Photo\" opens a dialog",
        ],
        [
            "UITabBarItem badges on the system tab bar",
            "The same badges on CYLTabBarController",
            "The icon jumps when the badge appears (badge-changed hook)",
            "The badge scales in when it appears (badge-changed hook)",
            "A gray bubble instead of the red badge",
        ],
        [
            "The middle tab loops its Lottie animation until it is selected",
        ],
        [
            "cyl_reselectBehavior = PopToRootThenScrollToTop",
            "CYLTabButtonPressAnimation + a reselect turn",
            "cyl_customActionTabBarItemIdentifiers + cyl_customTabActionHandler",
            "Every tab has its own title color, font and background",
            "Each tab is app.tabBars.buttons[\"home\"] etc. in UI tests",
            "itemPositioning = Centered, itemWidth 64, itemSpacing 12",
            "cyl_itemEdgeInsets 16 pt + itemSpacing 2 pt; classic tab bar",
        ],
    ]

    init() {
        super.init(style: .insetGrouped)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Tab Bar Gallery"
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in _: UITableView) -> Int {
        return sectionTitleArray.count
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitleArray[section]
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titleArray[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell")
        cell.textLabel?.text = "\(indexPath.section + 1).\(indexPath.row + 1) \(titleArray[indexPath.section][indexPath.row])"
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = subtitleArray[indexPath.section][indexPath.row]
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // [EN] One function per section, so no switch grows past a handful of cases.
        // [CN] 每个分组一个函数，避免单个 switch 分支过多。
        let row = indexPath.row
        switch indexPath.section {
        case 0: presentBasicScene(at: row)
        case 1: present(row == 0 ? GalleryProvider.tabbarWithNavigationStyle() : GalleryProvider.navigationWithTabbarStyle(), animated: true)
        case 2: presentAnimationScene(at: row)
        case 3: present(GalleryProvider.customIrregularityStyle(), animated: true)
        case 4: present(row == 0 ? GalleryProvider.customIrregularityStyle() : GalleryProvider.customTipsStyle(), animated: true)
        case 5: presentRemindScene(at: row)
        case 6: present(GalleryProvider.lottieStyle(), animated: true)
        case 7: presentNewAPIScene(at: row)
        default: break
        }
    }

    private func presentBasicScene(at row: Int) {
        switch row {
        case 0: present(GalleryProvider.systemStyle(), animated: true)
        case 1: present(GalleryProvider.customStyle(), animated: true)
        case 2: present(GalleryProvider.mixtureStyle(), animated: true)
        case 3: present(GalleryProvider.customGlassStyle(), animated: true)
        case 4:
            let tabBarController = GalleryProvider.systemMoreStyle()
            tabBarController.delegate = self
            present(tabBarController, animated: true)
        case 5: present(GalleryProvider.customMoreStyle(), animated: true)
        case 6: present(GalleryProvider.mixtureMoreStyle(), animated: true)
        case 7: present(GalleryProvider.customGlassMoreStyle(), animated: true)
        case 8:
            let tabBarController = GalleryProvider.systemStyle()
            present(tabBarController, animated: true) { tabBarController.selectedIndex = 2 }
        case 9:
            let tabBarController = GalleryProvider.customStyle()
            present(tabBarController, animated: true) { tabBarController.selectedIndex = 2 }
        case 10: present(GalleryProvider.mandatoryOldDesignStyle(), animated: true)
        case 11: present(GalleryProvider.customGlassWithBadgeStyle(), animated: true)
        case 12:
            let tabBarController = GalleryProvider.systemTabStyle()
            tabBarController.delegate = self
            present(tabBarController, animated: true)
        default: break
        }
    }

    private func presentAnimationScene(at row: Int) {
        switch row {
        case 0: present(GalleryProvider.customColorStyle(), animated: true)
        case 1: present(GalleryProvider.customBouncesStyle(), animated: true)
        case 2: present(GalleryProvider.customBackgroundColorStyle(implies: false), animated: true)
        case 3: present(GalleryProvider.customHighlightableStyle(), animated: true)
        case 4: present(GalleryProvider.customBackgroundColorStyle(implies: true), animated: true)
        default: break
        }
    }

    private func presentRemindScene(at row: Int) {
        switch row {
        case 0: present(GalleryProvider.systemRemindStyle(), animated: true)
        case 1: present(GalleryProvider.customRemindStyle(), animated: true)
        case 2: present(GalleryProvider.customAnimateRemindStyle(), animated: true)
        case 3: present(GalleryProvider.customAnimateRemindStyle2(), animated: true)
        case 4: present(GalleryProvider.customAnimateRemindStyle3(), animated: true)
        default: break
        }
    }

    private func presentNewAPIScene(at row: Int) {
        switch row {
        case 0: present(GalleryProvider.reselectStyle(), animated: true)
        case 1: present(GalleryProvider.pressAndReselectStyle(), animated: true)
        case 2: present(GalleryProvider.customActionStyle(), animated: true)
        case 3: present(GalleryProvider.perTabStyle(), animated: true)
        case 4: present(GalleryProvider.accessibilityStyle(), animated: true)
        case 5: present(GalleryProvider.centeredStyle(), animated: true)
        case 6: present(GalleryProvider.edgeInsetsStyle(), animated: true)
        default: break
        }
    }

    // MARK: - System tab bars: "Photo" opens a dialog while looking selected

    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        guard viewController.tabBarItem.title == "Photo",
              let photoIndex = tabBarController.viewControllers?.firstIndex(of: viewController),
              tabBarController.selectedIndex != NSNotFound,
              photoIndex != tabBarController.selectedIndex else {
            return true
        }
        showPhotoAction(at: photoIndex, selectedIndex: tabBarController.selectedIndex, usesTabs: false, in: tabBarController)
        return false
    }

    @available(iOS 18.0, *)
    func tabBarController(_ tabBarController: UITabBarController, shouldSelectTab tab: UITab) -> Bool {
        guard tab.title == "Photo",
              let photoIndex = tabBarController.tabs.firstIndex(of: tab),
              let selectedTab = tabBarController.selectedTab,
              let currentIndex = tabBarController.tabs.firstIndex(of: selectedTab),
              photoIndex != currentIndex else {
            return true
        }
        showPhotoAction(at: photoIndex, selectedIndex: currentIndex, usesTabs: true, in: tabBarController)
        return false
    }

    /// [EN] Swaps the two tabs' pages (each keeps its title and icon), selects "Photo", and restores after the dialog.
    /// [CN] 交换两个 Tab 的页面（各自保持标题与图标），选中 "Photo"，对话框关闭后恢复。
    private func showPhotoAction(at photoIndex: Int, selectedIndex currentIndex: Int, usesTabs: Bool,
                                in tabBarController: UITabBarController) {
        DispatchQueue.main.async { [weak self, weak tabBarController] in
            guard let self = self, let tabBarController = tabBarController else {
                return
            }
            self.swapTab(at: currentIndex, with: photoIndex, usesTabs: usesTabs, in: tabBarController)
            tabBarController.selectedIndex = photoIndex
            Gallery.presentMoreFeatures(from: tabBarController) { [weak self, weak tabBarController] in
                guard let self = self, let tabBarController = tabBarController else {
                    return
                }
                self.swapTab(at: currentIndex, with: photoIndex, usesTabs: usesTabs, in: tabBarController)
                tabBarController.selectedIndex = currentIndex
            }
        }
    }

    private func swapTab(at first: Int, with second: Int, usesTabs: Bool, in tabBarController: UITabBarController) {
        if #available(iOS 18.0, *), usesTabs {
            var tabs = tabBarController.tabs
            guard tabs.indices.contains(first), tabs.indices.contains(second) else {
                return
            }
            tabs.swapAt(first, second)
            tabBarController.tabs = tabs
            let firstTab = tabs[first]
            let secondTab = tabs[second]
            (firstTab.title, secondTab.title) = (secondTab.title, firstTab.title)
            (firstTab.image, secondTab.image) = (secondTab.image, firstTab.image)
            return
        }
        guard var viewControllers = tabBarController.viewControllers,
              viewControllers.indices.contains(first), viewControllers.indices.contains(second) else {
            return
        }
        // [EN] New items (copies) first, so no two pages share one item while the bar is rebuilt.
        // [CN] 先换上新的 item（拷贝），避免重建 TabBar 时两个页面共用同一个 item。
        let firstItem = viewControllers[first].tabBarItem
        let secondItem = viewControllers[second].tabBarItem
        viewControllers[first].tabBarItem = UITabBarItem(title: secondItem?.title, image: secondItem?.image,
                                                         selectedImage: secondItem?.selectedImage)
        viewControllers[second].tabBarItem = UITabBarItem(title: firstItem?.title, image: firstItem?.image,
                                                          selectedImage: firstItem?.selectedImage)
        viewControllers.swapAt(first, second)
        tabBarController.setViewControllers(viewControllers, animated: false)
    }
}
