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
     * [EN] Options some bundled placeholder files need to play, by file name (CYLTableViewPlaceHolder's
     *      `CYLScenarioAnimationOptions`). [CN] 部分资源包占位动画播放所需的选项，按文件名（CYLTableViewPlaceHolder 的
     *      `CYLScenarioAnimationOptions`）。
     */
    var placeholderAnimationOptions: [String: [String: String]] {
        switch self {
        case .rive: return ["CYLPlaceholderLoading.riv": ["legacy": "1"]]
        case .lottie, .pag, .gif: return [:]
        }
    }

    /**
     * [EN] Preferred refresh icons for the idle and pulling states (the first one bundled wins); any refresh icon of the
     *      kind otherwise. Refresh-themed files only (`CYLRefreshAnimationHeader.bundledIconAnimationFileNames`).
     * [CN] 空闲与下拉状态的首选刷新图标（取第一个存在的文件）；都没有时取该类型的任意刷新图标。只用刷新主题的文件
     *      （`CYLRefreshAnimationHeader.bundledIconAnimationFileNames`）。
     */
    var refreshIconFileNames: [String] {
        switch self {
        case .lottie: return ["CYLRefreshPullArrow.json", "CYLPlaceholderRefresh.json"]
        case .pag: return ["CYLPlaceholderProgress.pag"]
        case .rive: return ["CYLRefreshIcon.riv"]
        case .gif: return ["CYLRefreshArrows.gif"]
        }
    }

    /**
     * [EN] Preferred refresh icons while refreshing; the idle icon stays when none is bundled.
     * [CN] 刷新中状态的首选刷新图标；都没有时沿用空闲状态的图标。
     */
    var refreshingIconFileNames: [String] {
        switch self {
        case .lottie: return ["CYLRefreshMaterialSpinner.json", "CYLRefreshSpinnerRing.json"]
        case .pag, .rive: return []
        case .gif: return ["CYLRefreshRing.gif"]
        }
    }
}

/**
 * [EN] Gives an example scroll view what every example list has, with CYLTableViewPlaceHolder (written after its
 *      `Examples/Example-Scenarios`): pull to refresh with an animated icon (`cyl_header`, a `CYLRefreshAnimationHeader`),
 *      an animated empty-data placeholder, a no-network placeholder while offline, and the red status bar at the top of
 *      the page while offline (`cyl_showsStatusViewWhenOffline`). Call it once, in `viewDidLoad`.
 * [CN] 用 CYLTableViewPlaceHolder 为示例中的滚动视图提供所有示例列表都具备的功能（参照其 `Examples/Example-Scenarios`）：带动画图标的
 *      下拉刷新（`cyl_header`，即 `CYLRefreshAnimationHeader`）、带动画的无数据占位图、断网时的无网络占位图，以及断网时页面顶部的
 *      红色状态条（`cyl_showsStatusViewWhenOffline`）。
 *      在 `viewDidLoad` 中调用一次。
 */
@objc(CYLDemoPlaceholder)
final class CYLDemoPlaceholder: NSObject {

    /**
     * [EN] Installs refresh, placeholders and the offline bar on `scrollView`, shown by `viewController`, with the
     *      animations of `animation`. `refresh` loads the data and calls its completion; without it, a refresh reloads the
     *      list after a short delay. A header the list already has is replaced by an animation header with its block.
     * [CN] 为 `viewController` 显示的 `scrollView` 安装刷新、占位图与断网状态条，使用 `animation` 类型的动画。`refresh` 加载数据并调用其
     *      完成回调；未提供时，刷新会在短暂延迟后重新加载列表。列表已有的刷新头替换为保留其回调的动画刷新头。
     */
    @objc(installOnScrollView:viewController:animation:refresh:)
    static func install(on scrollView: UIScrollView, in viewController: UIViewController,
                        animation: CYLDemoPlaceholderAnimation = .lottie,
                        refresh: ((@escaping () -> Void) -> Void)? = nil) {
        CYLPlaceholderNetworkMonitor.shared.startMonitoring()
        installPlaceholder(on: scrollView, animation: animation)
        // [EN] Launch argument `-CYLDemoHoldRefresh YES` (screenshots, UI tests): every list starts refreshing and stays
        //      in that state, so its refresh icon can be captured.
        // [CN] 启动参数 `-CYLDemoHoldRefresh YES`（截图、UI 测试）：每个列表开始刷新并保持刷新状态，便于截取刷新图标。
        let holdsRefresh = UserDefaults.standard.bool(forKey: "CYLDemoHoldRefresh")
        if holdsRefresh {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak scrollView] in
                scrollView?.cyl_header?.beginRefreshing()
            }
        }
        let listRefreshingBlock: CYLRefreshComponentAction = scrollView.cyl_header?.refreshingBlock ?? { [weak scrollView] in
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
        let refreshingBlock: CYLRefreshComponentAction = holdsRefresh ? {} : listRefreshingBlock
        // [EN] The animated refresh header first: a list's own header keeps its block and becomes an animation header.
        //      The arrow and spinner header stays only when no refresh icon of the kind is bundled.
        // [CN] 优先使用动画刷新头：列表自带的刷新头保留其回调，换成动画刷新头。资源包中没有该类型的刷新图标时才保留箭头与菊花刷新头。
        if let header = animationHeader(for: animation, refreshingBlock: refreshingBlock) {
            scrollView.cyl_header = header
        } else if scrollView.cyl_header == nil {
            scrollView.cyl_header = CYLRefreshNormalHeader(refreshingBlock: refreshingBlock)
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
     * [EN] A second tap on the selected tab: scrolls the page's list back to the top and starts its pull to refresh
     *      (`cyl_header`). Returns NO when the page has no list with a refresh header.
     * [CN] 再次点击已选中的 Tab：把页面的列表滚动回顶部并开始下拉刷新（`cyl_header`）。页面中没有带刷新头的列表时返回 NO。
     */
    @objc(refreshListOfViewController:)
    @discardableResult
    static func refreshList(of viewController: UIViewController) -> Bool {
        guard viewController.isViewLoaded else {
            return false
        }
        var views: [UIView] = [viewController.view]
        while !views.isEmpty {
            let view = views.removeFirst()
            if let scrollView = view as? UIScrollView, let header = scrollView.cyl_header {
                if !header.isRefreshing {
                    scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -scrollView.adjustedContentInset.top),
                                                animated: false)
                    header.beginRefreshing()
                }
                return true
            }
            views.append(contentsOf: view.subviews)
        }
        return false
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
            // [EN] Bundled Rive files without a view model play through Rive's legacy runtime, as in CYLTableViewPlaceHolder's
            //      scenarios (`CYLScenarioAnimationOptions`); without it the file never loaded and the static image stayed.
            // [CN] 资源包中没有 view model 的 Rive 文件通过 Rive 的旧版运行时播放，与 CYLTableViewPlaceHolder 场景示例相同
            //      （`CYLScenarioAnimationOptions`）；以前没有该选项，文件无法加载，一直显示静态图。
            if let options = animation.placeholderAnimationOptions[name] {
                attributes[CYLPlaceholderItemAnimationOptions] = options
            }
        }
        return (try? CYLPlaceholderView(itemAttributes: attributes, imageBundle: nil))
            ?? CYLPlaceholderView(style: .empty, message: .empty)
    }

    /**
     * [EN] A `CYLRefreshAnimationHeader` with the refresh icons of `animation` at the library's default size, or nil when
     *      no refresh icon of the kind is bundled.
     * [CN] 使用 `animation` 类型刷新图标（库的默认尺寸）的 `CYLRefreshAnimationHeader`；资源包中没有该类型的刷新图标时返回 nil。
     */
    private static func animationHeader(for animation: CYLDemoPlaceholderAnimation,
                                        refreshingBlock: @escaping CYLRefreshComponentAction) -> CYLRefreshAnimationHeader? {
        let names = CYLRefreshAnimationHeader.bundledIconAnimationFileNames
        guard let idleName = firstBundled(animation.refreshIconFileNames, in: names)
            ?? names.first(where: { ($0 as NSString).pathExtension == animation.fileExtension }) else {
            return nil
        }
        let header = CYLRefreshAnimationHeader(refreshingBlock: refreshingBlock)
        let size = CGSize(width: 30, height: 30)
        header.setIconAnimation(bundled: idleName, size: size, for: .idle)
        if let refreshingName = firstBundled(animation.refreshingIconFileNames, in: names) {
            header.setIconAnimation(bundled: refreshingName, size: size, for: .refreshing)
        }
        return header
    }

    /**
     * [EN] `-CYLDemoPlaceholderPreview lottie|pag|rive|gif` (screenshots): presents the empty-list placeholder of that kind
     *      full screen over `viewController` (the example lists always have data, so the placeholder never shows on its own).
     *      Returns whether it was presented.
     * [CN] `-CYLDemoPlaceholderPreview lottie|pag|rive|gif`（截图用）：在 `viewController` 上全屏展示该类型的空列表占位图（示例列表总有数据，
     *      占位图不会自己出现）。返回是否已展示。
     */
    @objc(presentPlaceholderPreviewIfRequestedFrom:)
    @discardableResult
    static func presentPlaceholderPreviewIfRequested(from viewController: UIViewController) -> Bool {
        let kinds: [String: CYLDemoPlaceholderAnimation] = ["lottie": .lottie, "pag": .pag, "rive": .rive, "gif": .gif]
        guard let name = UserDefaults.standard.string(forKey: "CYLDemoPlaceholderPreview"), let kind = kinds[name] else {
            return false
        }
        let preview = UIViewController()
        preview.view.backgroundColor = .systemBackground
        let placeholder = placeholderView(animation: kind)
        placeholder.frame = preview.view.bounds
        placeholder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        preview.view.addSubview(placeholder)
        preview.modalPresentationStyle = .fullScreen
        viewController.present(preview, animated: false)
        return true
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
