//
//  CYLGalleryViewController.swift
//  CYLTabBarController
//
//  Ported from Objective-C on 2026/11/11: the examples are Swift only.
//

import UIKit
import CYLTabBarController

/**
 * [EN] The tab bar gallery: one row per scene of `CYLGalleryProvider`; tapping a row presents that tab bar. See
 *      docs/Tab-Bar-Gallery.md. `@objc(...)` keeps the Objective-C name while the rest of the demo is ported.
 * [CN] TabBar 图库：`CYLGalleryProvider` 中的每个场景一行；点击某行展示对应的 TabBar。见 docs/Tab-Bar-Gallery.md。
 *      `@objc(...)` 在其余示例移植期间保留 Objective-C 类名。
 */
@objc(CYLGalleryViewController)
final class CYLGalleryViewController: UITableViewController {

    private static let cellIdentifier = "CYLGalleryCell"
    /**
     * [EN] Opens the launch scene only once per launch. [CN] 每次启动只打开一次启动场景。
     */
    private static var openedLaunchScene = false

    private var sections: [CYLGallerySection] = []

    /**
     * [EN] The scene number given at launch with `-CYLDemoGalleryScene 8.1` (section.row, as the list shows it), for
     *      screenshots and checks; nil without it. The home page opens the gallery and the gallery opens that scene once.
     * [CN] 启动时以 `-CYLDemoGalleryScene 8.1` 指定的场景编号（分组.行，与列表显示一致），用于截图与检查；没有时为 nil。
     *      首页打开图库，图库打开该场景，各一次。
     */
    @objc(cyl_launchSceneNumber)
    static var launchSceneNumber: String? {
        guard let number = UserDefaults.standard.string(forKey: "CYLDemoGalleryScene"), !number.isEmpty else {
            return nil
        }
        return number
    }

    @objc init() {
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = cylDemoLocalizedString("TabBar 场景展示")
        sections = CYLGalleryProvider.sections()
        // [EN] Pull to refresh, empty / no-network placeholders and the offline red bar (CYLTableViewPlaceHolder).
        // [CN] 下拉刷新、无数据 / 无网络占位图与断网红条（CYLTableViewPlaceHolder）。
        CYLDemoPlaceholder.install(on: tableView, in: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !Self.openedLaunchScene, let parts = Self.launchSceneNumber?.split(separator: "."), parts.count == 2,
              let section = Int(parts[0]).map({ $0 - 1 }), let row = Int(parts[1]).map({ $0 - 1 }) else {
            return
        }
        Self.openedLaunchScene = true
        guard sections.indices.contains(section), sections[section].scenes.indices.contains(row) else {
            return
        }
        tableView(tableView, didSelectRowAt: IndexPath(row: row, section: section))
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in _: UITableView) -> Int {
        sections.count
    }

    override func tableView(_: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    override func tableView(_: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].scenes.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: Self.cellIdentifier)
        let scene = sections[indexPath.section].scenes[indexPath.row]
        cell.textLabel?.text = "\(indexPath.section + 1).\(indexPath.row + 1) \(scene.title)"
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = scene.subtitle
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 0
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let scene = sections[indexPath.section].scenes[indexPath.row]
        let viewController = scene.builder()
        let didPresent = scene.didPresent
        if scene.pushes, let navigationController {
            viewController.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(viewController, animated: true)
            didPresent?(viewController)
            return
        }
        present(viewController, animated: true) {
            didPresent?(viewController)
        }
    }
}
