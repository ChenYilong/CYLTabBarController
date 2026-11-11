//
//  CYLDemoPlaceholder.swift
//  CYLTabBarController examples
//
//  Created on 2026/11/11: every example scroll view uses CYLTableViewPlaceHolder (AGENTS.md,
//  "Depending on CYLTableViewPlaceHolder").
//

import UIKit
import CYLTableViewPlaceHolder

/**
 * [EN] The animation library a scroll view's refresh icon and empty placeholder use. Every kind is used by some example
 *      list, so the demo shows every animation type of CYLTableViewPlaceHolder (its `LottieSwift`, `PAG`, `Rive` and `GIF`
 *      subspecs); the files come from its core bundle.
 * [CN] 滚动视图的刷新图标与空数据占位图所用的动画库。每种都有示例列表使用，因此示例展示了 CYLTableViewPlaceHolder 的全部动画类型（其
 *      `LottieSwift`、`PAG`、`Rive` 与 `GIF` 子规格）；文件来自其核心资源包。
 */
@objc(CYLDemoPlaceholderAnimation)
enum CYLDemoPlaceholderAnimation: Int {
    case lottie
    case pag
    case rive
    case gif

    /**
     * [EN] The file extension of the kind. [CN] 该类型的文件扩展名。
     */
    var fileExtension: String {
        switch self {
        case .lottie: return "json"
        case .pag: return "pag"
        case .rive: return "riv"
        case .gif: return "gif"
        }
    }

    /**
     * [EN] Preferred empty-list animations, the first one bundled wins. [CN] 首选的空列表动画，取第一个存在的文件。
     */
    var placeholderFileNames: [String] {
        switch self {
        case .lottie: return ["CYLPlaceholderEmpty.json", "CYLPlaceholderNoMessages.json"]
        case .pag: return ["CYLPlaceholderNoFavorites.pag", "CYLPlaceholderLoading.pag"]
        case .rive: return ["CYLPlaceholderNoOrders.riv", "CYLPlaceholderNoReviews.riv", "CYLPlaceholderLoading.riv"]
        case .gif: return ["CYLPlaceholderNoFavorites.gif", "CYLPlaceholderUploading.gif"]
        }
    }

    /**
     * [EN] Preferred refresh icons, the first one bundled wins; any refresh icon of the kind otherwise.
     * [CN] 首选的刷新图标，取第一个存在的文件；都没有时取该类型的任意刷新图标。
     */
    var refreshIconFileNames: [String] {
        switch self {
        case .lottie: return ["CYLPlaceholderRefresh.json"]
        case .pag: return ["CYLPlaceholderPullHint.pag", "CYLPlaceholderLoading.pag"]
        case .rive: return ["CYLPlaceholderPullToRefresh.riv"]
        case .gif: return []
        }
    }
}

/**
 * [EN] Gives an example scroll view what every example list has, with CYLTableViewPlaceHolder (written after its
 *      `Examples/Example-Scenarios`): pull to refresh with an animated icon (`cyl_header`), an animated empty-data
 *      placeholder, a no-network placeholder while offline, and the red status bar at the top of the page while offline
 *      (`cyl_showsStatusViewWhenOffline`). Call it once, in `viewDidLoad`.
 * [CN] 用 CYLTableViewPlaceHolder 为示例中的滚动视图提供所有示例列表都具备的功能（参照其 `Examples/Example-Scenarios`）：带动画图标的
 *      下拉刷新（`cyl_header`）、带动画的无数据占位图、断网时的无网络占位图，以及断网时页面顶部的红色状态条（`cyl_showsStatusViewWhenOffline`）。
 *      在 `viewDidLoad` 中调用一次。
 */
@objc(CYLDemoPlaceholder)
final class CYLDemoPlaceholder: NSObject {

    /**
     * [EN] Installs refresh, placeholders and the offline bar on `scrollView`, shown by `viewController`, with the
     *      animations of `animation`. `refresh` loads the data and calls its completion; without it, a refresh reloads the
     *      list after a short delay. A header the list already has keeps its block and gets the animated icon.
     * [CN] 为 `viewController` 显示的 `scrollView` 安装刷新、占位图与断网状态条，使用 `animation` 类型的动画。`refresh` 加载数据并调用其
     *      完成回调；未提供时，刷新会在短暂延迟后重新加载列表。列表已有的刷新头保留其回调，并换上动画图标。
     */
    @objc(installOnScrollView:viewController:animation:refresh:)
    static func install(on scrollView: UIScrollView, in viewController: UIViewController,
                        animation: CYLDemoPlaceholderAnimation = .lottie,
                        refresh: ((@escaping () -> Void) -> Void)? = nil) {
        CYLPlaceholderNetworkMonitor.shared.startMonitoring()
        installPlaceholder(on: scrollView, animation: animation)
        if scrollView.cyl_header == nil {
            scrollView.cyl_header = CYLRefreshNormalHeader { [weak scrollView] in
                let finish = {
                    reload(scrollView)
                    scrollView?.cyl_header?.endRefreshing()
                }
                if let refresh {
                    refresh(finish)
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: finish)
                }
            }
        }
        // [EN] The animated refresh icon first; the arrow and spinner stay when no file of the kind is bundled.
        // [CN] 优先使用动画刷新图标；资源包中没有该类型的文件时保留箭头与菊花。
        if let header = scrollView.cyl_header, let iconName = refreshIconFileName(for: animation) {
            _ = header.setIconAnimation(bundled: iconName, size: CGSize(width: 28, height: 28), for: .idle)
        }
        // [EN] The red bar at the top while the network is not reachable, removed when it is again.
        // [CN] 网络不可用时页面顶部显示红色状态条，恢复后移除。
        viewController.cyl_placeholderScrollView = scrollView
        viewController.cyl_showsStatusViewWhenOffline = true
        // [EN] The placeholder switches between "no data" and "no network" when the network changes.
        // [CN] 网络变化时，占位图在「无数据」与「无网络」之间切换。
        NotificationCenter.default.addObserver(forName: CYLPlaceholderNetworkMonitor.statusDidChangeNotification, object: nil,
                                               queue: .main) { [weak scrollView] _ in
            reload(scrollView)
        }
    }

    /**
     * [EN] The same with the Lottie animations. [CN] 同上，使用 Lottie 动画。
     */
    @objc(installOnScrollView:viewController:refresh:)
    static func install(on scrollView: UIScrollView, in viewController: UIViewController,
                        refresh: ((@escaping () -> Void) -> Void)?) {
        install(on: scrollView, in: viewController, animation: .lottie, refresh: refresh)
    }

    /**
     * [EN] The placeholder of the current state: no network while offline, otherwise the animated empty list, initialized
     *      as in CYLTableViewPlaceHolder's scenario example (item attributes with a fallback style; the static image shows
     *      until the animation is ready, or when it cannot play).
     * [CN] 当前状态的占位图：断网时为无网络，否则为带动画的空列表，初始化方式与 CYLTableViewPlaceHolder 的场景示例相同（item 属性加回退样式；
     *      动画就绪之前或无法播放时显示静态图）。
     */
    @objc(placeholderViewWithAnimation:)
    static func placeholderView(animation: CYLDemoPlaceholderAnimation) -> UIView {
        if CYLPlaceholderNetworkMonitor.shared.networkStatus == .notReachable {
            return CYLPlaceholderView(style: .noInternet, message: .noInternet)
        }
        var attributes: [String: Any] = [CYLPlaceholderItemStyle: CYLPlaceholderStyle.empty.rawValue,
                                         CYLPlaceholderItemAnimationSize: [180, 180]]
        if let title = CYLPlaceholderView.localizedText(for: .empty) {
            attributes[CYLPlaceholderItemTitle] = title
        }
        if let name = firstBundled(animation.placeholderFileNames, in: CYLPlaceholderView.bundledAnimationFileNames()),
           let path = CYLPlaceholderView.path(forBundledAnimation: name) {
            attributes[CYLPlaceholderItemAnimationFilePath] = path
        }
        return (try? CYLPlaceholderView(itemAttributes: attributes, imageBundle: nil))
            ?? CYLPlaceholderView(style: .empty, message: .empty)
    }

    private static func refreshIconFileName(for animation: CYLDemoPlaceholderAnimation) -> String? {
        let names = CYLRefreshComponent.bundledIconAnimationFileNames
        return firstBundled(animation.refreshIconFileNames, in: names)
            ?? names.first { ($0 as NSString).pathExtension == animation.fileExtension && $0.hasPrefix("CYLRefresh") }
            ?? names.first { ($0 as NSString).pathExtension == animation.fileExtension }
    }

    private static func firstBundled(_ preferred: [String], in bundled: [String]) -> String? {
        preferred.first { bundled.contains($0) }
    }

    private static func installPlaceholder(on scrollView: UIScrollView, animation: CYLDemoPlaceholderAnimation) {
        if let tableView = scrollView as? UITableView {
            tableView.cyl_placeholderViewBlock { _ in placeholderView(animation: animation) }
        } else if let collectionView = scrollView as? UICollectionView {
            collectionView.cyl_placeholderViewBlock { _ in placeholderView(animation: animation) }
        }
    }

    private static func reload(_ scrollView: UIScrollView?) {
        if let tableView = scrollView as? UITableView {
            tableView.reloadData()
        } else if let collectionView = scrollView as? UICollectionView {
            collectionView.reloadData()
        }
    }
}
