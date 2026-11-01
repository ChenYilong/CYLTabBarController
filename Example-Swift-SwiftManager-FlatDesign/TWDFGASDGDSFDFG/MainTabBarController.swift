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
            return BadgeDemoViewController()
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

// MARK: - Badge demo

private let cellIdentifier = "cell"

/// The app icon drawn at 40 x 40 pt with rounded corners. At full size it fills the row, and the badge, which sits on
/// the icon's top-right corner, ends up under the row above.
private let demoIcon: UIImage? = {
    guard let image = UIImage(named: "DemoIcon") else { return nil }
    let rect = CGRect(x: 0, y: 0, width: 40, height: 40)
    return UIGraphicsImageRenderer(size: rect.size).image { _ in
        UIBezierPath(roundedRect: rect, cornerRadius: 8).addClip()
        image.draw(in: rect)
    }
}()

/// Row height that leaves room above the icon for its badge.
private let demoRowHeight: CGFloat = 60

private struct BadgeDemoItem {
    var title: String
    var value: String
    var animation: CYLBadgeAnimationType = .none
    var maximum = 99
    var colored = false
    var bordered = false
    var offset = false
    var radius: CGFloat = 0
    var cornerRadius: CGFloat = 0
}

/// How to use the badge, on any UIView (here the cell's image view), UIBarButtonItem or UIViewController:
///   view.cyl_showBadgeValue("", animationType: .none)   // red dot
///   view.cyl_showBadgeValue("8", animationType: .shake) // number / text, with an animation
///   view.cyl_clearBadge()                               // hide it
/// Set colors, border, offset and radius BEFORE calling cyl_showBadgeValue.
/// Every badge style and animation, one per row.
private let badgeDemoItems: [BadgeDemoItem] = [
    // Styles
    BadgeDemoItem(title: "Red dot", value: ""),
    BadgeDemoItem(title: "Number", value: "8"),
    BadgeDemoItem(title: "Number above maximum", value: "100", maximum: 99),
    BadgeDemoItem(title: "New", value: "new"),
    BadgeDemoItem(title: "Other text", value: "hot"),
    // Appearance
    BadgeDemoItem(title: "Custom colors", value: "5", colored: true),
    BadgeDemoItem(title: "Border", value: "5", bordered: true),
    BadgeDemoItem(title: "Center offset", value: "", offset: true),
    BadgeDemoItem(title: "Red dot radius", value: "", radius: 6),
    BadgeDemoItem(title: "Corner radius", value: "new", cornerRadius: 3),
    // Repeating animations
    BadgeDemoItem(title: "Scale", value: "3", animation: .scale),
    BadgeDemoItem(title: "Shake", value: "3", animation: .shake),
    BadgeDemoItem(title: "Bounce", value: "3", animation: .bounce),
    BadgeDemoItem(title: "Breathe", value: "", animation: .breathe),
    // Once animations
    BadgeDemoItem(title: "Left to right once", value: "3", animation: .leftRightOnce),
    BadgeDemoItem(title: "Right to left once", value: "3", animation: .rightLeftOnce),
    BadgeDemoItem(title: "Fade in once", value: "3", animation: .fadeInOnce),
    BadgeDemoItem(title: "Rolling once", value: "3", animation: .rollingOnce),
    BadgeDemoItem(title: "Scale once", value: "3", animation: .scaleOnce),
]

final class BadgeDemoViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Badge"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        self.tableView.rowHeight = demoRowHeight
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return badgeDemoItems.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let item = badgeDemoItems[indexPath.row]
        cell.textLabel?.text = "\(indexPath.row + 1). \(item.title)"
        cell.showBadgeDemo(item)
        return cell
    }

    /// Tap a row to clear its badge.
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.cellForRow(at: indexPath)?.imageView?.cyl_clearBadge()
    }
}

private extension UITableViewCell {

    /// Shows the demo icon in the cell and a badge on it.
    func showBadgeDemo(_ item: BadgeDemoItem) {
        guard let iconView = imageView else { return }
        iconView.image = demoIcon
        iconView.clipsToBounds = false

        // Cells are reused: clear the badge and reset every option before the next one.
        iconView.cyl_clearBadge()
        iconView.cyl_badgeBackgroundColor = item.colored ? .purple : .red
        iconView.cyl_badgeTextColor = item.colored ? .yellow : .white
        iconView.cyl_badgeBorderColor = item.bordered ? .white : nil
        iconView.cyl_badgeBorderWidth = item.bordered ? 2 : 0
        iconView.cyl_badgeCenterOffset = item.offset ? CGPoint(x: -8, y: 8) : .zero
        iconView.cyl_badgeMaximumBadgeNumber = item.maximum
        iconView.cyl_badgeRadius = item.radius
        iconView.cyl_badgeCornerRadius = item.cornerRadius
        // Options must be set before showing the badge.
        iconView.cyl_showBadgeValue(item.value, animationType: item.animation)
    }
}
