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
        
        // 动态：选中颜色
        var activeColor: UIColor {
            switch self {
            case .normal:
                return .black
            case .roomStyle:
                return .white
            }
        }
        
        // 动态：TabBar 背景颜色
        var tabBarBackground: UIColor {
            switch self {
            case .normal:
                return .white
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
            case .home: return "首页"
            case .room: return "房间"
            case .chat: return "消息"
            case .mine: return "我的"
            }
        }
        
        // 2. 常态图标 (替换为你的占位图或实际图片名)
        func icon(for theme: Theme) -> AssetType {
            return .native("tabbar_icon_normal")
        }
        
        // 3. 选中图标 (替换为你的占位图或实际图片名)
        var activeIcon: AssetType {
            return .native("tabbar_icon_selected")
        }
        
        // 4. 动效配置：LottieResources/tabbar_<模块>_<主题>.json，例如 tabbar_home_normal.json
        func animation(for theme: Theme) -> AnimationSource? {
            return .native("tabbar_\(self)_\(theme)")
        }
        
        // 5. 控制器配置 (使用原生 UIViewController 占位)
        var controller: UIViewController {
            let vc = UIViewController()
            vc.view.backgroundColor = .white
            return vc
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
        buildArchitecture()
    }
    
    required init?(coder: NSCoder) {
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
            
            if let anim = module.animation(for: theme), let url = anim.resolvedURL {
                attrs[CYLTabBarLottieURL] = url
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
            flatTabBar.shadowImage = theme.shadowColor == .clear
                ? UIImage()
                : Self.solidImage(theme.shadowColor)
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
    override func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        // flatDesign 下点击时 selectedIndex 可能仍是旧值，用 VC 判断更准
        let root = viewController.cyl_getViewControllerInsteadOfNavigation()
        // 此处判断逻辑已根据 ViewController 标题解耦
        currentTheme = (root.navigationItem.title == "房间") ? .roomStyle : .normal
    }
    
    private static func solidImage(_ color: UIColor) -> UIImage {
        let size = CGSize(width: 1, height: 1)
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = true
        format.scale = UIScreen.main.scale
        let image = UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return image.resizableImage(withCapInsets: .zero, resizingMode: .stretch)
            .withRenderingMode(.alwaysOriginal)
    }
}
