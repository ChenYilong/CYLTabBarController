//
//  CYLHomeViewController.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/// [EN] The gallery is opened once at launch with `-CYLDemoGalleryScene`. [CN] 使用 `-CYLDemoGalleryScene` 时启动后只打开一次图库。
private var cYLHomeDidOpenLaunchGallery = false

/**
 [EN] The "Home" tab of the Objective-C example (Swift since docs/Swift-Migration.md step 112): buttons to rebuild the tab bar in
      the FlatDesign or Liquid Glass style and to pick a skin (#216), the tab bar gallery, badge rows; a row or a tap pushes a
      page. Every other example's first tab imitates this page (AGENTS.md).
 [CN] Objective-C 示例的「首页」Tab（自第 112 步起为 Swift）：以扁平或液态玻璃样式重建 TabBar、换肤（#216）的按钮，TabBar 图库，角标行；
      点击一行或屏幕推入一个页面。其他示例的第一个 Tab 都模仿本页（AGENTS.md）。
 */
@objc(CYLHomeViewController)
class CYLHomeViewController: CYLDemoBadgeTableViewController, UITabBarControllerDelegate {

    /// [EN] The tab bar's bottom scroll edge effect (iOS 26). [CN] TabBar 底部的滚动边缘效果（iOS 26）。
    private var bottomEdgeInteraction: UIInteraction?

    override var placeholderAnimation: CYLDemoPlaceholderAnimation { .lottie }

    override var minimumBadgeRowCount: Int { 30 }

    /// [EN] The gallery section, then the badge rows. [CN] 图库一组，然后是角标行。
    override var pageSectionCount: Int { 1 }

    private var gallerySection: Int { tagListSectionCount }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // [EN] `-CYLDemoGalleryScene 8.1`: opens the gallery once at launch, which opens that scene (screenshots).
        // [CN] `-CYLDemoGalleryScene 8.1`：启动时打开一次图库，再由图库打开该场景（用于截图）。
        if !cYLHomeDidOpenLaunchGallery, CYLGalleryViewController.launchSceneNumber != nil, let navigationController {
            cYLHomeDidOpenLaunchGallery = true
            navigationController.pushViewController(CYLGalleryViewController(), animated: false)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: cylDemoLocalizedString("FlatDesign"), style: .plain, target: self,
                                                           action: #selector(flatDesignTabBar(_:)))
        let liquidGlassItem = UIBarButtonItem(title: cylDemoLocalizedString("LiquidGlass"), style: .plain, target: self, action: #selector(refreshTabBar(_:)))
        // [EN] Issue #216: the skin button opens the theme picker. [CN] Issue #216：换肤按钮打开主题选择器。
        let themeItem = UIBarButtonItem(title: cylDemoLocalizedString("换肤"), style: .plain, target: self, action: #selector(showThemePicker(_:)))
        navigationItem.rightBarButtonItems = [liquidGlassItem, themeItem]
        // [EN] #425: the badge style comes from CYLBadgeAppearance; animated navigation item badges in a random color.
        // [CN] #425：角标样式来自 CYLBadgeAppearance；导航栏按钮的动画角标，使用随机颜色。
        liquidGlassItem.cylShowBadgeValue("", animationType: .shake, backgroundColor: .cyl_randomColor)
        navigationItem.leftBarButtonItem?.cylShowBadgeValue("", animationType: .breathe, backgroundColor: .cyl_randomColor)
        if #available(iOS 26.0, *) {
            let interaction = UIScrollEdgeElementContainerInteraction()
            interaction.scrollView = tableView
            interaction.edge = .bottom
            cylTabBarController?.tabBar.addInteraction(interaction)
            bottomEdgeInteraction = interaction
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // FIX: issue #653
        // [EN] A vertical tab bar (folded iPhone Duo, iOS 27.1) is a full-height column: a bottom edge effect tied to it would
        //      blur the whole list, so it is used only while the tab bar is horizontal.
        // [CN] 竖向 TabBar（iPhone Duo 折叠，iOS 27.1）是整列高度：底部边缘效果会模糊整个列表，因此只在横向时启用。
        guard #available(iOS 26.0, *), let interaction = bottomEdgeInteraction as? UIScrollEdgeElementContainerInteraction else { return }
        let tabBarSize = cylTabBarController?.tabBar.bounds.size ?? .zero
        let scrollView: UIScrollView? = tabBarSize.height > tabBarSize.width ? nil : tableView
        if interaction.scrollView !== scrollView {
            interaction.scrollView = scrollView
        }
    }

    /// [EN] Issue #216: the skin (theme) picker. [CN] Issue #216：换肤（主题）选择器。
    @objc private func showThemePicker(_ _: Any?) {
        cylPresentThemePicker(from: nil) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    /// [EN] A new Liquid Glass tab bar with the registered plus button's context. [CN] 使用已注册 PlusButton 的 context 新建液态玻璃 TabBar。
    @objc private func refreshTabBar(_ _: Any?) {
        CYLPlusButtonSubclass.register()
        CYLMainRootViewController.current()?.createNewTabBar(withContext: NSStringFromClass(CYLTabBarController.self))
    }

    @objc private func flatDesignTabBar(_ _: Any?) {
        CYLMainRootViewController.current()?.createFlatDesignTabBar()
    }

    override func pageCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == gallerySection else { return super.pageCell(for: tableView, at: indexPath) }
        let cell = tableView.dequeueReusableCell(withIdentifier: "GalleryCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "GalleryCell")
        cell.textLabel?.text = cylDemoLocalizedString("打开 TabBar 场景展示")
        cell.detailTextLabel?.text = cylDemoLocalizedString("每个场景都是用公开 API 构建的 TabBar：样式、动画、提醒、Lottie 以及较新的 Tab API")
        cell.cylWrapsTextLabels()
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == gallerySection ? "Tab Bar Gallery" : super.tableView(tableView, titleForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == gallerySection ? 1 : super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func didSelectPageRow(at indexPath: IndexPath) {
        if indexPath.section == gallerySection {
            navigationController?.pushViewController(CYLGalleryViewController(), animated: true)
            return
        }
        // [EN] Sets the navigation bar title. [CN] 设置导航栏标题。
        navigationItem.title = String(format: cylDemoLocalizedString("首页(%@)"), "\(indexPath.row)")
        pushToNewViewController()
    }

    override func touchesBegan(_ _: Set<UITouch>, with _: UIEvent?) {
        pushToNewViewController()
    }

    private func pushToNewViewController() {
        let viewController = CYLBaseViewController()
        viewController.view.backgroundColor = .orange
        viewController.cyl_navigationBarHidden = true
        viewController.cyl_disablePopGestureRecognizer = false
        navigationController?.pushViewController(viewController, animated: true)
    }
}
