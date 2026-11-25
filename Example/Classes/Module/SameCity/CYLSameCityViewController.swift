//
//  CYLSameCityViewController.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/// [EN] The launch screen is opened once. [CN] 启动页面只打开一次。
private var cYLSameCityDidOpenLaunchScreen = false

/**
 [EN] The "Nearby" tab of the Objective-C example (Swift since docs/Swift-Migration.md step 112): the "Default tint" row (the page
      `CYLDefaultTintViewController`, one to one with the HarmonyOS example's row), then badge rows; a badge row pushes the details
      page without the navigation bar.
 [CN] Objective-C 示例的「同城」Tab（自第 112 步起为 Swift）：「Default tint」行（页面 `CYLDefaultTintViewController`，与鸿蒙示例的行一一
      对应），然后是角标行；点击角标行推入没有导航栏的详情页。
 */
@objc(CYLSameCityViewController)
class CYLSameCityViewController: CYLDemoBadgeTableViewController {

    override var placeholderAnimation: CYLDemoPlaceholderAnimation { .pag }

    /// [EN] The default tint section, then the badge rows. [CN] 默认着色一组，然后是角标行。
    override var pageSectionCount: Int { 2 }

    private var defaultTintSection: Int { cyl_demoSectionCount() }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // [EN] `-cylScreen default-tint` (with `-CYLDemoSelectedTab city`): opens the page once at launch (screenshots).
        // [CN] `-cylScreen default-tint`（与 `-CYLDemoSelectedTab city` 一起使用）：启动时打开一次该页面（用于截图）。
        if !cYLSameCityDidOpenLaunchScreen, CYLDefaultTintViewController.isRequestedAtLaunch {
            cYLSameCityDidOpenLaunchScreen = true
            navigationController?.pushViewController(CYLDefaultTintViewController(), animated: false)
        }
    }

    override func pageCell(for tableView: UITableView, at indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section == defaultTintSection else { return super.pageCell(for: tableView, at: indexPath) }
        let cell = tableView.dequeueReusableCell(withIdentifier: "DefaultTintCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "DefaultTintCell")
        cell.textLabel?.text = cylDemoLocalizedString("Default tint")
        cell.detailTextLabel?.text = cylDemoLocalizedString("A one-color file takes the built-in tint of its state and color mode; a multi-color file keeps its colors")
        cell.accessibilityIdentifier = "cyl-default-tint"
        cell.cylWrapsTextLabels()
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == defaultTintSection ? cylDemoLocalizedString("Default tint") : super.tableView(tableView, titleForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == defaultTintSection ? 1 : super.tableView(tableView, numberOfRowsInSection: section)
    }

    override func didSelectPageRow(at indexPath: IndexPath) {
        if indexPath.section == defaultTintSection {
            navigationController?.pushViewController(CYLDefaultTintViewController(), animated: true)
            return
        }
        let viewController = CYLDetailsViewController()
        viewController.cyl_navigationBarHidden = true
        viewController.cyl_disablePopGestureRecognizer = true
        navigationController?.pushViewController(viewController, animated: true)
    }
}
