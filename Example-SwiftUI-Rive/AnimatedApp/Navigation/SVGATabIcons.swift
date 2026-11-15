//
//  SVGATabIcons.swift
//  AnimatedApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/**
 * FIX: issue #415
 * [EN] Where the tab icons of Example-SwiftUI-Rive and Example-Rive come from, one for one with the Rive tab icons (TabItems.swift,
 *      shared the same way): the course's Rive artboards (`CYLTabBarRiveURL`), SVGA files given with the SVGA initialization
 *      keys in code (`CYLTabBarSVGAURL`, `CYLTabBarSVGASize`), or SVGA files given in each app's configuration file
 *      (`CYLTabBarSVGAFilePath`, cyl_tabbar_configuration_svga.json, `+tabBarControllerWithConfigurationFile:error:`). Chosen
 *      on the Bell page and kept across launches; changing it rebuilds the tab bar (`rebuildTabBar`). The SVGA files:
 *      SVGAPlayer-iOS, SVGAPlayer-Android and SVGAPlayer-Web samples (Apache 2.0, SVGAAssets/NOTICE.md).
 * [CN] Example-SwiftUI-Rive 与 Example-Rive 的 Tab 图标来源，与 Rive Tab 图标（TabItems.swift，同样共用）一一对应：课程的 Rive 画板（`CYLTabBarRiveURL`）、
 *      在代码中用 SVGA 初始化 key（`CYLTabBarSVGAURL`、`CYLTabBarSVGASize`）提供的 SVGA 文件，或在各 App 的配置文件中（`CYLTabBarSVGAFilePath`，
 *      cyl_tabbar_configuration_svga.json，`+tabBarControllerWithConfigurationFile:error:`）提供的 SVGA 文件。在 Bell 页面选择，重启后保持；切换时重建
 *      TabBar（`rebuildTabBar`）。SVGA 文件来自 SVGAPlayer-iOS、SVGAPlayer-Android 与 SVGAPlayer-Web 的示例（Apache 2.0，见 SVGAAssets/NOTICE.md）。
 */
enum CYLDemoTabIconSource: Int, CaseIterable {
    case rive
    case svgaKeys
    case svgaConfigurationFile

    private static let defaultsKey = "CYLDemoTabIconSource"

    /** [EN] Set by each app: rebuilds its tab bar with the current source. [CN] 由各 App 设置：用当前来源重建 TabBar。 */
    static var rebuildTabBar: (() -> Void)?

    /**
     * [EN] The source in use; the launch argument `-CYLDemoTabIconSource 0|1|2` (screenshots, UI tests) also sets it.
     * [CN] 当前使用的来源；启动参数 `-CYLDemoTabIconSource 0|1|2`（截图、UI 测试）也可以设置。
     */
    static var current: CYLDemoTabIconSource {
        get { CYLDemoTabIconSource(rawValue: UserDefaults.standard.integer(forKey: defaultsKey)) ?? .rive }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey) }
    }

    var next: CYLDemoTabIconSource {
        CYLDemoTabIconSource(rawValue: (rawValue + 1) % Self.allCases.count) ?? .rive
    }

    /** [EN] The name shown on the Bell page's switch. [CN] Bell 页面切换按钮上显示的名称。 */
    var localizedName: String {
        switch self {
        case .rive: return "Rive"
        case .svgaKeys: return cylDemoLocalizedString("SVGA（初始化 Key）")
        case .svgaConfigurationFile: return cylDemoLocalizedString("SVGA（配置文件）")
        }
    }

    /** [EN] The title of the switch on the Bell page. [CN] Bell 页面切换按钮的标题。 */
    static var switchTitle: String {
        String(format: cylDemoLocalizedString("Tab 图标来源：%@"), current.localizedName)
    }
}

extension Tab {
    /** [EN] The SVGA file of each tab, in place of its Rive artboard. [CN] 每个 Tab 的 SVGA 文件，代替其 Rive 画板。 */
    var svgaFileName: String {
        switch self {
        case .chat: return "tab_chat"
        case .search: return "tab_search"
        case .timer: return "tab_activity"
        case .bell: return "tab_list"
        case .user: return "tab_profile"
        }
    }

    /**
     * [EN] The tab's attributes with its SVGA icon, given with the SVGA initialization keys, instead of the Rive one.
     * [CN] 使用 SVGA 初始化 key 提供 SVGA 图标、代替 Rive 图标的 Tab 属性。
     */
    var svgaAttributes: [AnyHashable: Any] {
        var attributes = self.attributes
        attributes[CYLTabBarRiveURL] = nil
        attributes[CYLTabBarRiveSize] = nil
        attributes[CYLTabBarSVGAURL] = Bundle.main.url(forResource: svgaFileName, withExtension: "svga")
        attributes[CYLTabBarSVGASize] = NSValue(cgSize: CGSize(width: 32, height: 32))
        return attributes
    }

    /** [EN] The page identifier of the tab in the SVGA configuration files. [CN] 该 Tab 在 SVGA 配置文件中的页面标识。 */
    var svgaPageIdentifier: String {
        "svga-\(rawValue)"
    }
}

/**
 * [EN] Registers the pages the SVGA configuration files name (`CYLTabBarItemPageIdentifier`): each app passes the pages of
 *      its Rive tabs.
 * [CN] 注册 SVGA 配置文件引用的页面（`CYLTabBarItemPageIdentifier`）：各 App 传入其 Rive Tab 的页面。
 */
enum CYLDemoSVGAConfigurationPages {
    private static var isRegistered = false

    static func registerIfNeeded(page: @escaping (Tab) -> UIViewController) {
        guard !isRegistered else { return }
        isRegistered = true
        for tab in Tab.allCases {
            CYLTabBarPageRegistry.shared.register(factory: { _ in page(tab) }, forPageIdentifier: tab.svgaPageIdentifier)
        }
    }
}
