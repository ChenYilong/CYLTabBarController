//
//  MainTabBarController.swift
//  TWDFGASDGDSFDFG
//
//  Created by River on 2026/9/30.
//

import UIKit
import CYLTabBarController

// MARK: - Resource Definitions

/// 静态资源类型
public enum AssetType {
    case native(String) // 对应原 bundle
    case web(String)    // 对应原 online
    case disk(String)   // 对应原 localFile
    
    var identifier: String {
        switch self {
        case .native(let name): return name
        case .web(let url), .disk(let url): return url
        }
    }
}

/// 动效资源类型(lottie 动画)
public enum AnimationSource {
    case native(String)
    case web(String)
    case disk(String)
    
    var resolvedURL: URL? {
        switch self {
        case .native(let name):
            return Bundle.main.url(forResource: name, withExtension: "json")
        case .web(let link):
            return URL(string: link)
        case .disk(let path):
            return path.hasPrefix("file://") ? URL(string: path) : URL(fileURLWithPath: path)
        }
    }
}

class MainTabBarController: CYLTabBarController, CYLFlatDesignUITabBarControllerDelegate {

    // #535: the plus button's badge, shared by every Swift demo (Example-Shared/CYLPlusButtonBadgeDemo.swift).
    // #535：PlusButton 的角标，所有 Swift Demo 共用（Example-Shared/CYLPlusButtonBadgeDemo.swift）。
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        demoShowPlusButtonBadgeAfterLayout()
    }

    
    // MARK: - Theme Design
    private enum Theme {
        case normal
        case roomStyle
        
        // 动态：常态颜色
        var normalColor: UIColor {
            switch self {
            case .normal, .roomStyle:
                return .gray
            }
        }
        
        // 动态：选中颜色。Dark Mode (#620): the normal theme follows the system style, e.g. black on light, white on dark.
        var activeColor: UIColor {
            switch self {
            case .normal:
                return UIColor.cyl_color(withLight: .black, dark: .white)
            case .roomStyle:
                return .white
            }
        }
        
        // 动态：TabBar 背景颜色
        var tabBarBackground: UIColor {
            switch self {
            case .normal:
                return UIColor.cyl_color(withLight: .white, dark: .black)
            case .roomStyle:
                return .black
            }
        }
        
        // 动态：常态字体
        var normalFont: UIFont {
            switch self {
            case .normal, .roomStyle:
                return UIFont.systemFont(ofSize: 9, weight: .medium)
            }
        }
        
        // 动态：选中字体
        var activeFont: UIFont {
            switch self {
            case .normal, .roomStyle:
                return UIFont.systemFont(ofSize: 9, weight: .medium)
            }
        }
        
        // 下划线颜色
        var shadowColor: UIColor {
            switch self {
            case .normal:
                return UIColor.lightGray.withAlphaComponent(0.5)
            case .roomStyle:
                return .clear
            }
        }
        
        // 动态：Lottie 动效尺寸
        var lottieSize: CGSize {
            switch self {
            case .normal, .roomStyle:
                return CGSize(width: 33, height: 33)
            }
        }
    }
    
    // 当前 TabBar 主题状态，属性观察器自动刷新 UI
    private var currentTheme: Theme = .normal {
        didSet {
            guard currentTheme != oldValue else { return }
            applyTheme(theme: currentTheme)
            buildTabBars(theme: currentTheme)
        }
    }
    
    // MARK: - Modules
    
    private enum Module: CaseIterable {
        case home, room, chat, mine
        
        // 1. 标题配置
        var title: String {
            switch self {
            case .home: return CYLLocalizedString("首页")
            case .room: return CYLLocalizedString("房间")
            case .chat: return CYLLocalizedString("消息")
            case .mine: return CYLLocalizedString("我的")
            }
        }
        
        // 2. 常态图标 (替换为你的占位图或实际图片名)
        // Dark Mode (#620): "home_normal" also loads home_normal_dark (naming convention), account_normal has its own Dark
        // appearance, the chat tab names its dark image below. 深色模式：见 README「适配深色模式」。
        private var iconName: String {
            switch self {
            case .home: return "home"
            case .room: return "mycity"
            case .chat: return "message"
            case .mine: return "account"
            }
        }

        func icon(for _: Theme) -> AssetType {
            return .native("\(iconName)_normal")
        }

        // 2.1 深色模式常态图标，nil 表示沿用 Asset Catalog 的 Dark 外观或命名规范
        var darkIcon: AssetType? {
            return self == .chat ? .native("message_normal_night") : nil
        }
        
        // 3. 选中图标 (替换为你的占位图或实际图片名)
        var activeIcon: AssetType {
            return .native("\(iconName)_highlight")
        }
        
        // 4. 动效配置：LottieResources/tabbar_<模块>_<主题>.json，例如 tabbar_home_normal.json
        func animation(for theme: Theme) -> AnimationSource? {
            return .native("tabbar_\(self)_\(theme)")
        }

        // 4.1 深色模式动效（#442）：LottieResources/tabbar_<模块>_<主题>_dark.json，不存在时沿用上面的动效
        func darkAnimation(for theme: Theme) -> AnimationSource? {
            return .native("tabbar_\(self)_\(theme)_dark")
        }
        
        // 5. 控制器配置 (使用原生 UIViewController 占位)
        var controller: UIViewController {
            return self == .home ? HomeViewController() : CYLBadgeHelperTableViewController()
        }
    }

    // MARK: - Lifecycle
    
    init() {
        super.init(nibName: nil, bundle: nil)
        self.delegate = self
        // flatDesign 必须在 setViewControllers 之前；且需先触发 cyl_tabBar 创建扁平 TabBar
        // flatDesign 的 setTabBarHeight 要求 cyl_tabBar 已是 CYLFlatDesignTabBar，否则会直接 return
        tabBarStyleType = .flatDesign
        _ = cyl_tabBar
        tabBarHeight = 60
        lottieAnimationSpeed = 1.5 // Issue #428: Lottie tab icons at 1.5x (no effect without Lottie) Lottie 图标 1.5 倍速
        buildArchitecture()
    }
    
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Build Infrastructure
    
    private func buildArchitecture() {
        
        // 构建 Tab 属性字典
        buildTabBars(theme: currentTheme)
        
        // 构建 Controllers (使用原生 UINavigationController)
        viewControllers = Module.allCases.map { module in
            let vc = module.controller
            vc.navigationItem.title = module.title
            return UINavigationController(rootViewController: vc)
        }
        
        // 初始化应用主题
        applyTheme(theme: currentTheme)
    }
    
    private func buildTabBars(theme: Theme) {
        tabBarItemsAttributes = Module.allCases.map { module in
            var attrs: [String: Any] = [
                CYLTabBarItemTitle: module.title,
                CYLTabBarItemImage: module.icon(for: theme).identifier,
                CYLTabBarItemSelectedImage: module.activeIcon.identifier,
                CYLTabBarItemImagePositionAdjustment: NSValue(uiOffset: UIOffset(horizontal: 0, vertical: 1.5)),
                CYLTabBarItemTitlePositionAdjustment: NSValue(uiOffset: UIOffset(horizontal: 0, vertical: -1.5))
            ]
            if let darkIcon = module.darkIcon {
                attrs[CYLTabBarItemDarkImage] = darkIcon.identifier
            }
            
            if let anim = module.animation(for: theme), let url = anim.resolvedURL {
                attrs[CYLTabBarLottieURL] = url
                if let darkURL = module.darkAnimation(for: theme)?.resolvedURL {
                    attrs[CYLTabBarLottieDarkURL] = darkURL
                }
                attrs[CYLTabBarLottieSize] = NSValue(cgSize: theme.lottieSize)
            }
            return attrs
        }
        reloadTabBarItems(withAttributes: tabBarItemsAttributes)
    }
    
    // MARK: - Appearance
    
    private func applyTheme(theme: Theme) {
        let normalAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: theme.normalColor,
            .font: theme.normalFont
        ]
        let activeAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: theme.activeColor,
            .font: theme.activeFont
        ]
        
        // flatDesign 实际显示的是 cyl_tabBar，系统 tabBar 已被隐藏，appearance 无效
        if let flatTabBar = cyl_tabBar as? CYLFlatDesignTabBar {
            flatTabBar.tintColor = theme.activeColor
            flatTabBar.backgroundImage = UIImage()
            flatTabBar.barTintColor = theme.tabBarBackground
            flatTabBar.backgroundColor = theme.tabBarBackground
            // A 1-pt line from the library; a dynamic color would give an image that follows Dark Mode too.
            flatTabBar.shadowImage = theme.shadowColor == .clear
                ? UIImage()
                : UIImage.cyl_image(with: theme.shadowColor, size: CGSize(width: 1, height: 1)) ?? UIImage()
            viewControllers?.forEach { vc in
                let item = vc.cyl_getViewControllerInsteadOfNavigation().cyl_tabBarItem
                item?.setTitleTextAttributes(normalAttrs, for: .normal)
                item?.setTitleTextAttributes(activeAttrs, for: .selected)
            }
            return
        }
        
        tabBar.tintColor = theme.activeColor
        tabBar.unselectedItemTintColor = theme.normalColor
        
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = theme.tabBarBackground
        appearance.shadowColor = theme.shadowColor
            
        let itemState = UITabBarItemAppearance()
        itemState.normal.titleTextAttributes = normalAttrs
        itemState.selected.titleTextAttributes = activeAttrs
            
        appearance.stackedLayoutAppearance = itemState
        appearance.inlineLayoutAppearance = itemState
        appearance.compactInlineLayoutAppearance = itemState
            
        tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBar.scrollEdgeAppearance = appearance
        }
    }
    
    // MARK: - Delegate

    /// #610 / #408: called for every tab button and for the plus button in the flat design style too; the identifier
    /// (a default, the class name, when none is set) tells which one was tapped.
    /// 扁平样式下点击每个 Tab 按钮和 PlusButton 也会调用；用标识（未设置时为默认值，即类名）区分是哪一个。
    override func tabBarController(_ _: CYLTabBarController, didSelect control: UIControl) {
        demoPlusButtonDidTap(control)
        NSLog("[#610] flat design tapped \"%@\" (%@)", control.cyl_tabBarItemIdentifier ?? "nil", control.cyl_isPlusButton() ? "plus button" : "tab button")
    }

    override func tabBarController(_ _: UITabBarController, didSelect viewController: UIViewController) {
        // flatDesign 下点击时 selectedIndex 可能仍是旧值，用 VC 判断更准
        let root = viewController.cyl_getViewControllerInsteadOfNavigation()
        // 此处判断逻辑已根据 ViewController 标题解耦
        currentTheme = (root.navigationItem.title == CYLLocalizedString("房间")) ? .roomStyle : .normal
    }
}

/// The home page: the badge samples, plus an animated badge in a random color on the navigation bar.
/// 首页：角标样例列表，以及导航栏上随机颜色的动画角标。
private final class HomeViewController: CYLBadgeHelperTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // No navigation bar button here: a bell button is added first. 没有导航栏按钮：先添加铃铛按钮。
        cyl_showNavigationBadge(value: "99", animationType: .scale, backgroundColor: UIColor.cyl_randomColor)
    }
}
