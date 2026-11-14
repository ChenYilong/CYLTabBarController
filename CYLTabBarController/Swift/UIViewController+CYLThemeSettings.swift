//
//  UIViewController+CYLThemeSettings.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] A demo theme: its colors and, for a holiday skin, its icons (Fluent Emoji, MIT License, Microsoft; see
 *      `cyl_theme_icons_LICENSE.txt`), or for the network skin, icons downloaded from the network and a title prefix.
 *      "Default" changes nothing, so the tab bar shows the app's own look again.
 * [CN] 演示主题：配色；节日皮肤还带有图标（Fluent Emoji，MIT 许可证，Microsoft；见 `cyl_theme_icons_LICENSE.txt`），网络皮肤带有从网络
 *      下载的图标与标题前缀。“默认”不做任何修改，TabBar 恢复 App 自己的外观。
 */
final class CYLDemoTheme: NSObject, CYLTabBarTheme {

    let identifier: String
    let tintColor: UIColor?
    let barColor: UIColor?
    let normalColor: UIColor?
    /**
     * [EN] The icon names of a holiday skin, used in turn for the tabs. [CN] 节日皮肤的图标名，依次用于各 Tab。
     */
    var iconNames: [String] = []
    /**
     * [EN] The network skin: each tab's icon URLs (unselected, selected), used in turn. [CN] 网络皮肤：每个 Tab 图标的 URL（未选中、选中），依次使用。
     */
    var iconURLs: [[String]] = []
    /**
     * [EN] The network skin: the plus button's image URLs (normal, selected). [CN] 网络皮肤：PlusButton 图片的 URL（普通、选中）。
     */
    var plusButtonIconURLs: [String] = []
    /**
     * [EN] The network skin: put before every tab title, e.g. "★". [CN] 网络皮肤：加在每个 Tab 标题前，例如“★”。
     */
    var titlePrefix: String?

    init(_ identifier: String, tint: UIColor? = nil, bar: UIColor? = nil, normal: UIColor? = nil, icons: [String] = []) {
        self.identifier = identifier
        tintColor = tint
        barColor = bar
        normalColor = normal
        iconNames = icons
    }

    /**
     * [EN] The name shown in the picker, in the app's language. [CN] 选择器中显示的名字，使用 App 语言。
     */
    var localizedName: String {
        let names: [String: String] = [
            "Grapefruit": "西柚", "Grass": "青草", "Pink Rose": "玫瑰粉", "Dark": "深色", "Spring Festival": "春节",
            "Christmas": "圣诞节", "Halloween": "万圣节", "Valentine's Day": "情人节", "Mid-Autumn": "中秋节", "Easter": "复活节",
            "New Year": "新年", "Summer": "夏日", "Birthday": "生日", "Space": "太空", "Ocean": "海洋", "Network": "网络图标",
        ]
        return CYLLocalizedString(names[identifier] ?? "默认")
    }

    /**
     * [EN] What the theme changes, for the theme list. [CN] 主题修改的内容，用于主题列表。
     */
    var localizedSummary: String {
        if !iconURLs.isEmpty {
            return CYLLocalizedString("网络图标、标题与配色")
        }
        return iconNames.isEmpty ? CYLLocalizedString("仅配色") : CYLLocalizedString("节日图标与配色")
    }

    /**
     * [EN] A theme icon in its own colors. The icons belong to the app: `Skins/<version>/<theme>/<icon>@3x.png` in the
     *      "Configurations" folder, read through a resource route (docs/Resource-Routes.md); the theme folder is the
     *      identifier in lowercase, without "'", with "-" for spaces. An app without the folder gets no icon.
     * [CN] 保持原色的主题图标。图标属于 App："Configurations" 文件夹中的 `Skins/<版本>/<主题>/<图标>@3x.png`，通过资源路由读取
     *      （docs/Resource-Routes.md）；主题文件夹为小写的标识，去掉 "'"，空格换成 "-"。没有该文件夹的 App 得不到图标。
     */
    func icon(named iconName: String) -> UIImage? {
        let folder = identifier.lowercased().replacingOccurrences(of: "'", with: "").replacingOccurrences(of: " ", with: "-")
        let route = "bundle:Configurations/Skins/1.0.0/\(folder)/\(iconName)@3x.png"
        guard let path = CYLResourceRoute.path(forRoute: route, baseDirectory: nil) else { return nil }
        return UIImage(contentsOfFile: path)?.withRenderingMode(.alwaysOriginal)
    }

    /**
     * [EN] The first icon, for the theme list. [CN] 第一个图标，用于主题列表。
     */
    var previewIcon: UIImage? {
        if !iconURLs.isEmpty {
            return UIImage(systemName: "icloud.and.arrow.down")?.withTintColor(tintColor ?? .systemBlue, renderingMode: .alwaysOriginal)
        }
        return iconNames.first.flatMap(icon(named:))
    }

    /**
     * [EN] The attributes of each real tab, in order: one entry per tab, none for the plus button's page or a placeholder.
     * [CN] 每个真实 Tab 的 attributes，按顺序：每个 Tab 一项，PlusButton 的页面与占位控制器不占项。
     */
    private static func realTabsAttributes(_ tabBarController: CYLTabBarController) -> [[String: Any]] {
        let viewControllers = tabBarController.viewControllers ?? []
        return tabBarController.cyl_viewControllersIgnoringPlusButton.map { viewController in
            viewControllers.firstIndex(of: viewController).flatMap { tabBarController.tabBarItemAttributes(at: UInt($0)) } ?? [:]
        }
    }

    /**
     * [EN] `image` drawn at 45% opacity: the unselected look of a full color icon. [CN] 以 45% 不透明度绘制的 `image`：全彩图标的未选中样式。
     */
    private static func faded(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        return UIGraphicsImageRenderer(size: image.size, format: format).image { _ in
            image.draw(at: .zero, blendMode: .normal, alpha: 0.45)
        }.withRenderingMode(.alwaysOriginal)
    }

    // MARK: CYLTabBarTheme

    /**
     * [EN] A holiday skin: its icons in turn on every tab (selected: full color; unselected: faded); the network skin: its
     *      icons and prefixed titles; a color theme, or icons that cannot be loaded: nil, the app's own icons.
     * [CN] 节日皮肤：依次为每个 Tab 设置其图标（选中：全彩；未选中：半透明）；网络皮肤：其图标与加前缀的标题；配色主题或图标无法加载：
     *      nil，使用 App 自己的图标。
     */
    func cyl_tabBarItemsAttributes(for tabBarController: CYLTabBarController) -> [[String: Any]]? {
        if !iconURLs.isEmpty {
            return networkItemsAttributes(for: tabBarController)
        }
        guard !iconNames.isEmpty else { return nil }
        var itemsAttributes: [[String: Any]] = []
        for index in 0..<Self.realTabsAttributes(tabBarController).count {
            guard let selectedImage = icon(named: iconNames[index % iconNames.count]) else { return nil }
            itemsAttributes.append([CYLTabBarItemImage: Self.faded(selectedImage), CYLTabBarItemSelectedImage: selectedImage])
        }
        return itemsAttributes
    }

    /**
     * [EN] The network skin: every tab's title with the prefix (a prefix added before is removed first: the tab bar remembers
     *      the titles a theme set), and its icons downloaded from the network, cached after the first time.
     * [CN] 网络皮肤：每个 Tab 的标题加上前缀（先去掉之前加上的前缀：TabBar 会记录主题设置过的标题），图标从网络下载，第一次之后读取缓存。
     */
    private func networkItemsAttributes(for tabBarController: CYLTabBarController) -> [[String: Any]] {
        let prefix = (titlePrefix ?? "") + " "
        return Self.realTabsAttributes(tabBarController).enumerated().map { index, current in
            let urls = iconURLs[index % iconURLs.count]
            var attributes: [String: Any] = [
                CYLTabBarItemImageURLSize: NSValue(cgSize: CGSize(width: 24, height: 24)),
            ]
            attributes[CYLTabBarItemImageURL] = urls.first
            attributes[CYLTabBarItemSelectedImageURL] = urls.last
            if var title = current[CYLTabBarItemTitle] as? String, !title.isEmpty {
                while !(titlePrefix ?? "").isEmpty && title.hasPrefix(prefix) {
                    title.removeFirst(prefix.count)
                }
                attributes[CYLTabBarItemTitle] = prefix + title
            }
            return attributes
        }
    }

    /**
     * [EN] The plus button: a holiday skin puts its last icon on it, the network skin downloads its images; a color theme
     *      leaves it alone.
     * [CN] PlusButton：节日皮肤使用其最后一个图标，网络皮肤从网络下载图片；配色主题不修改。
     */
    func cyl_plusButtonAttributes(for tabBarController: CYLTabBarController) -> [String: Any]? {
        if let first = plusButtonIconURLs.first, let last = plusButtonIconURLs.last {
            return [CYLTabBarItemImageURL: first, CYLTabBarItemSelectedImageURL: last]
        }
        guard let icon = iconNames.last.flatMap(icon(named:)) else { return nil }
        return [CYLTabBarItemImage: icon, CYLTabBarItemSelectedImage: icon]
    }

    func cyl_tabBarAppearance(for tabBarController: CYLTabBarController) -> UITabBarAppearance? {
        guard let tintColor else { return nil }
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        if let barColor {
            appearance.backgroundColor = barColor
        }
        let normalColor = normalColor ?? .systemGray
        for itemAppearance in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            itemAppearance.normal.iconColor = normalColor
            itemAppearance.normal.titleTextAttributes = [.foregroundColor: normalColor]
            itemAppearance.selected.iconColor = tintColor
            itemAppearance.selected.titleTextAttributes = [.foregroundColor: tintColor]
            itemAppearance.normal.badgeBackgroundColor = tintColor
        }
        return appearance
    }

    /**
     * [EN] Set once a skin set the page tint: Default then undoes it, and otherwise keeps the app's own colors at launch.
     * [CN] 皮肤设置过页面 tint 后为 YES：此后“默认”会撤销它，否则启动时保留 App 自己的颜色。
     */
    private static var skinColorsSet = false

    /**
     * [EN] The rest of the skin: the tint of every page (navigation bar buttons, switches...), nil for Default.
     * [CN] 皮肤的其余部分：所有页面的 tint（导航栏按钮、开关等），默认主题为 nil。
     */
    func cyl_customize(_ tabBarController: CYLTabBarController) {
        guard tintColor != nil || Self.skinColorsSet else { return }
        Self.skinColorsSet = tintColor != nil
        tabBarController.view.tintColor = tintColor
    }
}

/**
 * [EN] The demo themes and the settings around them. [CN] 演示主题及其相关设置。
 */
enum CYLDemoThemes {

    static let identifierDefaultsKey = "CYLDemoThemeIdentifier"
    static let followsSystemDefaultsKey = "CYLDemoThemeFollowsSystem"
    static let defaultIdentifier = "Default"
    static let darkIdentifier = "Dark"

    private static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
        UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
    }

    /**
     * [EN] The demo themes, in the picker's order: five color themes, eleven holiday skins, then the network skin, which
     *      changes everything a theme can (prefixed titles, icons and plus button images from the network, colors).
     * [CN] 演示主题，按选择器中的顺序：五个配色主题、十一个节日皮肤，然后是网络皮肤，它修改主题能修改的所有内容（加前缀的标题、来自网络的
     *      图标与 PlusButton 图片、配色）。
     */
    static let all: [CYLDemoTheme] = {
        let network = CYLDemoTheme("Network", tint: rgb(0, 122, 255), bar: rgb(242, 247, 255), normal: rgb(120, 134, 156))
        let base = "https://cdn-icons-png.flaticon.com/512/"
        network.titlePrefix = "★"
        network.iconURLs = [
            [base + "1946/1946488.png", base + "1946/1946436.png"],
            [base + "2099/2099085.png", base + "2099/2099085.png"],
            [base + "2099/2099100.png", base + "2099/2099100.png"],
            [base + "1077/1077063.png", base + "1077/1077114.png"],
        ]
        network.plusButtonIconURLs = [base + "992/992651.png", base + "1828/1828817.png"]
        return [
            CYLDemoTheme(defaultIdentifier),
            CYLDemoTheme("Grapefruit", tint: rgb(239, 83, 98)),
            CYLDemoTheme("Grass", tint: rgb(110, 180, 60)),
            CYLDemoTheme("Pink Rose", tint: rgb(238, 133, 193)),
            CYLDemoTheme(darkIdentifier, tint: rgb(39, 192, 243), bar: rgb(18, 18, 20), normal: rgb(142, 142, 147)),
            CYLDemoTheme("Spring Festival", tint: rgb(255, 213, 79), bar: rgb(196, 30, 58), normal: rgb(255, 205, 210),
                         icons: ["red_envelope", "firecracker", "red_paper_lantern", "dragon", "fireworks"]),
            CYLDemoTheme("Christmas", tint: rgb(255, 214, 102), bar: rgb(22, 101, 52), normal: rgb(200, 230, 201),
                         icons: ["christmas_tree", "wrapped_gift", "snowman", "bell", "star"]),
            CYLDemoTheme("Halloween", tint: rgb(255, 145, 0), bar: rgb(38, 20, 58), normal: rgb(179, 157, 219),
                         icons: ["jack_o_lantern", "ghost", "bat", "spider", "candy"]),
            CYLDemoTheme("Valentine's Day", tint: rgb(233, 30, 99), bar: rgb(255, 235, 240), normal: rgb(173, 120, 140),
                         icons: ["heart_with_ribbon", "rose", "love_letter", "chocolate_bar", "ring"]),
            CYLDemoTheme("Mid-Autumn", tint: rgb(255, 193, 7), bar: rgb(26, 35, 76), normal: rgb(159, 168, 218),
                         icons: ["moon_cake", "full_moon", "rabbit", "teacup_without_handle", "crescent_moon"]),
            CYLDemoTheme("Easter", tint: rgb(124, 179, 66), bar: rgb(255, 250, 225), normal: rgb(161, 136, 127),
                         icons: ["hatching_chick", "egg", "rabbit_face", "tulip", "basket"]),
            CYLDemoTheme("New Year", tint: rgb(255, 215, 64), bar: rgb(20, 20, 40), normal: rgb(144, 164, 174),
                         icons: ["party_popper", "confetti_ball", "clinking_glasses", "sparkler", "alarm_clock"]),
            CYLDemoTheme("Summer", tint: rgb(0, 151, 167), bar: rgb(255, 248, 225), normal: rgb(141, 110, 99),
                         icons: ["beach_with_umbrella", "watermelon", "palm_tree", "tropical_drink", "sun"]),
            CYLDemoTheme("Birthday", tint: rgb(236, 64, 122), bar: rgb(255, 243, 224), normal: rgb(149, 117, 205),
                         icons: ["birthday_cake", "balloon", "candle", "teddy_bear", "wrapped_gift"]),
            CYLDemoTheme("Space", tint: rgb(128, 222, 234), bar: rgb(13, 17, 38), normal: rgb(121, 134, 203),
                         icons: ["rocket", "ringed_planet", "flying_saucer", "glowing_star", "comet"]),
            CYLDemoTheme("Ocean", tint: rgb(255, 255, 255), bar: rgb(1, 87, 155), normal: rgb(129, 212, 250),
                         icons: ["spouting_whale", "tropical_fish", "spiral_shell", "crab", "water_wave"]),
            network,
        ]
    }()

    static var manager: CYLThemeManager {
        CYLThemeManagerCenter.defaultThemeManager
    }

    static var current: CYLDemoTheme {
        manager.currentTheme as? CYLDemoTheme ?? all[0]
    }

    static var followsSystem: Bool {
        manager.respondsSystemStyleAutomatically
    }

    /**
     * [EN] Follows the system Dark Mode: Dark in dark, otherwise back to Default from Dark, or the theme already chosen.
     * [CN] 跟随系统深色模式：深色时为“深色”，浅色时从“深色”回到“默认”，否则保持已选主题。
     */
    static func setFollowsSystem(_ followsSystem: Bool) {
        manager.identifierForTrait = { trait in
            if trait.userInterfaceStyle == .dark {
                return darkIdentifier as NSString
            }
            if (manager.currentThemeIdentifier as? String) == darkIdentifier {
                return defaultIdentifier as NSString
            }
            return manager.currentThemeIdentifier
        }
        manager.respondsSystemStyleAutomatically = followsSystem
        UserDefaults.standard.set(followsSystem, forKey: followsSystemDefaultsKey)
    }

    /**
     * [EN] Applies `theme`; a theme picked by hand stops following the system. [CN] 应用 `theme`；手动选择主题后不再跟随系统。
     */
    static func apply(_ theme: CYLDemoTheme) {
        if followsSystem {
            setFollowsSystem(false)
        }
        manager.currentThemeIdentifier = theme.identifier as NSString
    }

    /**
     * [EN] A round swatch of a color theme's tint, for the theme list. [CN] 配色主题 tint 的圆形色块，用于主题列表。
     */
    static func swatch(_ color: UIColor) -> UIImage {
        let size = CGSize(width: 25, height: 25)
        return UIGraphicsImageRenderer(size: size).image { _ in
            color.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 2)).fill()
        }.withRenderingMode(.alwaysOriginal)
    }

    static func listIcon(of theme: CYLDemoTheme) -> UIImage {
        theme.previewIcon ?? swatch(theme.tintColor ?? .lightGray)
    }

    /**
     * [EN] Installs the themes once, restores the saved one (only when no theme is current: the app may use the default
     *      manager with themes of its own), saves every change, and runs the launch arguments of the screenshot scripts.
     * [CN] 一次性注册主题，恢复保存的主题（仅在没有当前主题时：App 可能用默认管理器管理自己的主题），保存每次切换，并执行截图脚本的启动参数。
     */
    static let setUp: Void = {
        for theme in all where manager.theme(forIdentifier: theme.identifier as NSString) == nil {
            manager.addThemeIdentifier(theme.identifier as NSString, theme: theme)
        }
        let defaults = UserDefaults.standard
        if manager.currentThemeIdentifier == nil {
            let saved = defaults.string(forKey: identifierDefaultsKey)
            let hasSaved = saved.map { manager.theme(forIdentifier: $0 as NSString) != nil } ?? false
            manager.currentThemeIdentifier = (hasSaved ? saved! : defaultIdentifier) as NSString
        }
        NotificationCenter.default.addObserver(forName: .CYLThemeDidChange, object: nil, queue: nil) { notification in
            guard let changed = notification.object as? CYLThemeManager, changed.name.isEqual(CYLThemeManagerNameDefault),
                  let identifier = changed.currentThemeIdentifier as? String else {
                return
            }
            UserDefaults.standard.set(identifier, forKey: identifierDefaultsKey)
        }
        if defaults.bool(forKey: followsSystemDefaultsKey) {
            setFollowsSystem(true)
        }
        CYLPlusChildThemeTest.runIfAsked()
    }()
}

/**
 * [EN] The launch arguments of scripts/theme-screenshots.sh and scripts/plus-child-theme-test.sh: `-CYLDemoThemeSwitchTo
 *      <identifier>` switches to that theme after `-CYLDemoThemeSwitchDelay` seconds (default 4), as a tap on the skin
 *      button does. With `-CYLDemoSelectIndex <n>`, the plus child theme test runs instead (docs/Plus-Child-Theme-Switching-Test.md):
 *      tab n is selected 2 s after launch, the plus button's stand-in in the Liquid Glass selected layer is checked before
 *      and after the switch, and after each state to photograph the app waits for the script's `tmp/ack-<step>` (at most 30 s).
 * [CN] scripts/theme-screenshots.sh 与 scripts/plus-child-theme-test.sh 的启动参数：`-CYLDemoThemeSwitchTo <identifier>` 在
 *      `-CYLDemoThemeSwitchDelay` 秒后（默认 4）切换到该主题，与点击换肤按钮相同。带 `-CYLDemoSelectIndex <n>` 时改为执行 PlusButton
 *      子控制器换肤测试（docs/Plus-Child-Theme-Switching-Test.md）：启动 2 秒后选中第 n 个 Tab，在切换前后检查液态玻璃选中图层中的 PlusButton
 *      替身，每个需要截图的状态之后等待脚本创建 `tmp/ack-<步骤>`（最多 30 秒）。
 */
enum CYLPlusChildThemeTest {

    static func runIfAsked() {
        let defaults = UserDefaults.standard
        let switchIdentifier = defaults.string(forKey: "CYLDemoThemeSwitchTo") ?? ""
        let switchTheme = {
            if let theme = CYLDemoThemes.all.first(where: { $0.identifier == switchIdentifier }) {
                CYLDemoThemes.apply(theme)
            }
        }
        guard defaults.object(forKey: "CYLDemoSelectIndex") != nil else {
            if !switchIdentifier.isEmpty {
                let delay = defaults.object(forKey: "CYLDemoThemeSwitchDelay") != nil ? defaults.double(forKey: "CYLDemoThemeSwitchDelay") : 4
                after(delay, switchTheme)
            }
            return
        }
        let selectIndex = defaults.integer(forKey: "CYLDemoSelectIndex")
        log("plus child theme test: launch theme=\(String(describing: CYLDemoThemes.manager.currentThemeIdentifier))")
        after(2) {
            if let tabBarController = CYLTabBarController.cyl_active(), selectIndex >= 0,
               selectIndex < (tabBarController.viewControllers?.count ?? 0) {
                tabBarController.selectedIndex = selectIndex
            }
            after(3) {
                checkAndPhotograph("before") {
                    guard !switchIdentifier.isEmpty else {
                        log("plus child theme test: done")
                        return
                    }
                    switchTheme()
                    after(3) {
                        checkAndPhotograph("after") { log("plus child theme test: done") }
                    }
                }
            }
        }
    }

    private static func after(_ seconds: TimeInterval, _ block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: block)
    }

    /**
     * [EN] A line to the console, and appended at once to `tmp/plus-child-theme-test.log` in the data container, which the
     *      script reads (the console stream of `simctl launch --console-pty` reached it only when the app closed).
     * [CN] 一行输出：写到控制台，并立即追加到数据容器中的 `tmp/plus-child-theme-test.log`，供脚本读取（`simctl launch --console-pty` 的
     *      控制台输出直到 App 关闭才传到脚本）。
     */
    static func log(_ line: String) {
        NSLog("%@", line)
        let path = (NSTemporaryDirectory() as NSString).appendingPathComponent("plus-child-theme-test.log")
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }
        guard let file = FileHandle(forWritingAtPath: path) else { return }
        file.seekToEndOfFile()
        file.write(Data((line + "\n").utf8))
        file.closeFile()
    }

    /**
     * [EN] Runs `block` once tmp/ack-<step> exists, or after 30 s. [CN] tmp/ack-<步骤> 出现后（或 30 秒后）执行 `block`。
     */
    private static func waitForAck(_ step: String, tries: Int = 0, _ block: @escaping () -> Void) {
        let path = (NSTemporaryDirectory() as NSString).appendingPathComponent("ack-" + step)
        if FileManager.default.fileExists(atPath: path) || tries >= 120 {
            if tries >= 120 {
                log("plus child theme test: no ack for \(step) after 30 s")
            }
            block()
            return
        }
        after(0.25) { waitForAck(step, tries: tries + 1, block) }
    }

    /**
     * [EN] A check and its screenshot, then the stand-in alone (real plus button hidden) and its screenshot.
     * [CN] 检查并截图，然后只看替身（隐藏真实 PlusButton）并截图。
     */
    private static func checkAndPhotograph(_ phase: String, next: @escaping () -> Void) {
        let plusButton = checkStandIn(phase)
        waitForAck(phase) {
            guard let plusButton else {
                next()
                return
            }
            let alpha = plusButton.alpha
            plusButton.alpha = 0
            after(0.5) {
                log("plus child theme test: stand-in only \(phase)")
                waitForAck("stand-in-only-" + phase) {
                    plusButton.alpha = alpha
                    after(1, next)
                }
            }
        }
    }

    private static func sameImage(_ image: UIImage?, _ otherImage: UIImage?) -> Bool {
        guard let image, let otherImage else { return false }
        if image === otherImage || image.isEqual(otherImage) {
            return true
        }
        guard let data = image.pngData() else { return false }
        return data == otherImage.pngData()
    }

    private static func frameInWindow(_ view: UIView?) -> String {
        guard let view else { return NSCoder.string(for: CGRect.zero) }
        return NSCoder.string(for: view.convert(view.bounds, to: nil))
    }

    /**
     * [EN] With the plus child view controller selected on Liquid Glass, the plus button's stand-in in the selected layer
     *      must show the plus button's own normal image; an image the plus button no longer has is the stale, blurred
     *      stand-in. Logs "plus child theme test: PASS|FAIL|SKIP <phase> …" and geometry details; returns the plus button
     *      when its stand-in is shown.
     * [CN] 在液态玻璃上选中 PlusButton 子控制器时，选中图层中的 PlusButton 替身必须显示 PlusButton 自己的普通状态图片；显示 PlusButton
     *      已经没有的图片，就是过期、模糊的替身。输出 "plus child theme test: PASS|FAIL|SKIP <阶段> …" 及几何信息；替身已显示时返回 PlusButton。
     */
    private static func checkStandIn(_ phase: String) -> UIButton? {
        let tabBarController = CYLTabBarController.cyl_active()
        let theme = String(describing: CYLDemoThemes.manager.currentThemeIdentifier)
        guard let tabBarController, let plusButton = CYLPlusButton(forOwner: tabBarController) else {
            log("plus child theme test: SKIP \(phase) theme=\(theme): no plus button")
            return nil
        }
        // [EN] Liquid Glass and not FlatDesign, which has no selected layer even when Liquid Glass is active.
        // [CN] 液态玻璃且不是扁平样式：扁平样式即使在液态玻璃激活时也没有选中图层。
        guard tabBarController.tabBarStyleType != .flatDesign, CYLConstants.isLiquidGlassActive() else {
            log("plus child theme test: SKIP \(phase) theme=\(theme): no stand-in outside the Liquid Glass tab bar")
            return nil
        }
        // [EN] `selectedContentView` is a `CYLPlusButtonSubclassing` property: read by selector. [CN] 属于 `CYLPlusButtonSubclassing`：通过 selector 读取。
        guard let standIn = CYLFlatDesignLookup.object(plusButton, "selectedContentView") as? UIButton, standIn !== plusButton,
              standIn.window != nil else {
            log("plus child theme test: FAIL \(phase) theme=\(theme) selectedIndex=\(tabBarController.selectedIndex): the stand-in is not shown")
            return nil
        }
        let shown = standIn.currentImage
        // [EN] One picture on Liquid Glass with a plus child: the plus button's normal image (docs/PlusButton.md).
        // [CN] 液态玻璃且有 PlusButton 子控制器时只有一张图片：PlusButton 的普通状态图片（docs/PlusButton.md）。
        let normalImage = plusButton.image(for: .normal)
        let matches = sameImage(shown, normalImage) && sameImage(plusButton.currentImage, normalImage)
        log("plus child theme test: \(matches ? "PASS" : "FAIL") \(phase) theme=\(theme) selectedIndex=\(tabBarController.selectedIndex) "
            + "standIn=\(NSCoder.string(for: shown?.size ?? .zero)) plusButton=\(NSCoder.string(for: plusButton.currentImage?.size ?? .zero))")
        logGeometry(phase, standIn: standIn, plusButton: plusButton, shown: shown, tabBar: tabBarController.tabBar)
        return plusButton
    }

    private static func logGeometry(_ phase: String, standIn: UIButton, plusButton: UIButton, shown: UIImage?, tabBar: UIView) {
        var view = standIn.superview
        while let current = view, current !== tabBar.superview {
            if current.layer.mask != nil || current.clipsToBounds || current.layer.masksToBounds {
                log("plus child theme test: info \(phase) clip=\(type(of: current)) frame=\(frameInWindow(current)) "
                    + String(format: "cornerRadius=%.1f", current.layer.cornerRadius) + " layerMask=\(current.layer.mask != nil ? 1 : 0)")
                break
            }
            view = current.superview
        }
        log("plus child theme test: info \(phase) selectedLayerTabButton=\(frameInWindow(standIn.superview))")
        // [EN] The views of the tab bar whose class names say selection, lens, indicator or highlight (at most 12).
        // [CN] TabBar 中类名含 selection、lens、indicator 或 highlight 的视图（最多 12 个）。
        var pending: [UIView] = [tabBar]
        var logged = 0
        while !pending.isEmpty && logged < 12 {
            let current = pending.removeFirst()
            pending += current.subviews
            let className = NSStringFromClass(type(of: current)).lowercased()
            if ["selection", "lens", "indicator", "highlight"].contains(where: className.contains) {
                log("plus child theme test: info \(phase) view=\(type(of: current)) frame=\(frameInWindow(current)) hidden=\(current.isHidden ? 1 : 0) "
                    + String(format: "alpha=%.2f", current.alpha))
                logged += 1
            }
        }
        let standInVisible = sequence(first: standIn as UIView, next: { $0.superview }).allSatisfy { !$0.isHidden && $0.alpha >= 0.01 }
        let imageView = standIn.imageView
        log("plus child theme test: info \(phase) standInFrame=\(frameInWindow(standIn)) plusButtonFrame=\(frameInWindow(plusButton)) "
            + "visible=\(standInVisible ? 1 : 0) configuration=\(standIn.configuration != nil ? 1 : 0) highlighted=\(standIn.isHighlighted ? 1 : 0) "
            + "imageViewImageIsCurrent=\(sameImage(imageView?.image, shown) ? 1 : 0) imageViewFrame=\(NSCoder.string(for: imageView?.frame ?? .zero)) "
            + "imageViewHidden=\(imageView?.isHidden == true ? 1 : 0) "
            + String(format: "imageViewAlpha=%.2f imageScale=%.1f plusImageScale=%.1f ", imageView?.alpha ?? 0, imageView?.image?.scale ?? 0,
                     plusButton.currentImage?.scale ?? 0)
            + "standInSuperview=\(standIn.superview.map { String(describing: type(of: $0)) } ?? "nil")")
        let hiddenBy = sequence(first: plusButton as UIView, next: { $0.superview }).first { $0.isHidden || $0.alpha < 0.01 }.map {
            "\(type(of: $0))(hidden=\($0.isHidden ? 1 : 0) " + String(format: "alpha=%.2f)", $0.alpha)
        } ?? "nothing"
        log("plus child theme test: info \(phase) plusButton hiddenBy=\(hiddenBy) window=\(plusButton.window != nil ? 1 : 0) "
            + "superview=\(plusButton.superview.map { String(describing: type(of: $0)) } ?? "nil") selected=\(plusButton.isSelected ? 1 : 0) "
            + "highlighted=\(plusButton.isHighlighted ? 1 : 0) imageViewHidden=\(plusButton.imageView?.isHidden == true ? 1 : 0) "
            + String(format: "imageViewAlpha=%.2f ", plusButton.imageView?.alpha ?? 0)
            + "imageViewFrame=\(NSCoder.string(for: plusButton.imageView?.frame ?? .zero)) "
            + String(format: "layerOpacity=%.2f", plusButton.layer.opacity))
    }
}

/**
 * FIX: issue #216
 * [EN] `UIViewController (CYLThemeSettings)`: the theme (skin) settings of the demo, on the default theme manager: a picker
 *      cell, an action sheet, a menu and a theme list section. Translated from Objective-C (docs/Swift-Migration.md, step 30);
 *      selectors kept.
 * [CN] `UIViewController (CYLThemeSettings)`：演示的换肤设置，作用于默认主题管理器：选择器 cell、action sheet、菜单与主题列表分组。已从
 *      Objective-C 翻译（docs/Swift-Migration.md，第 30 步），selector 不变。
 */
extension UIViewController {

    /**
     * [EN] Installs the demo themes on the default theme manager, once, and restores the saved theme.
     * [CN] 一次性在默认主题管理器上注册演示主题，并恢复保存的主题。
     */
    @objc(cyl_setUpThemeSettings)
    public class func cyl_setUpThemeSettings() {
        CYLDemoThemes.setUp
    }

    /**
     * [EN] The cell that opens the theme picker, with the current theme. [CN] 打开主题选择器的 cell，显示当前主题。
     */
    @objc(cyl_themeSettingsCellForTableView:)
    public func cyl_themeSettingsCell(for tableView: UITableView) -> UITableViewCell {
        UIViewController.cyl_setUpThemeSettings()
        let identifier = "CYLThemeSettingsCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            cell.textLabel?.font = .boldSystemFont(ofSize: 15)
            cell.detailTextLabel?.textColor = .gray
            cell.detailTextLabel?.numberOfLines = 0
            cell.imageView?.image = UIImage(systemName: "paintbrush")
            return cell
        }()
        var themeName = CYLDemoThemes.current.localizedName
        if CYLDemoThemes.followsSystem {
            themeName += " · " + CYLLocalizedString("跟随系统深色模式")
        }
        cell.textLabel?.text = CYLLocalizedString("换肤（主题，issue #216）")
        cell.detailTextLabel?.text = String(format: CYLLocalizedString("点击选择主题：TabBar 的背景、图标与文字颜色原地切换，所有 TabBar 样式均适用。当前：%@"),
                                            themeName)
        return cell
    }

    /**
     * [EN] Presents the theme picker as an action sheet (a popover on iPad, from `sourceView`); `completion` runs after a choice.
     * [CN] 以 action sheet 显示主题选择器（iPad 上从 `sourceView` 弹出）；选择后执行 `completion`。
     */
    @objc(cyl_presentThemePickerFromView:completion:)
    public func cyl_presentThemePicker(from sourceView: UIView?, completion: (() -> Void)?) {
        UIViewController.cyl_setUpThemeSettings()
        let picker = UIAlertController(title: CYLLocalizedString("选择主题"), message: nil, preferredStyle: .actionSheet)
        let currentIdentifier = CYLDemoThemes.current.identifier
        for theme in CYLDemoThemes.all {
            let title = theme.identifier == currentIdentifier ? "✓ " + theme.localizedName : theme.localizedName
            picker.addAction(UIAlertAction(title: title, style: .default) { _ in
                CYLDemoThemes.apply(theme)
                completion?()
            })
        }
        let followsSystem = CYLDemoThemes.followsSystem
        let followTitle = CYLLocalizedString("跟随系统深色模式")
        picker.addAction(UIAlertAction(title: followsSystem ? "✓ " + followTitle : followTitle, style: .default) { _ in
            CYLDemoThemes.setFollowsSystem(!followsSystem)
            completion?()
        })
        picker.addAction(UIAlertAction(title: CYLLocalizedString("取消"), style: .cancel))
        // [EN] iPad shows an action sheet as a popover. [CN] iPad 上 action sheet 以弹出框显示。
        if let popover = picker.popoverPresentationController {
            let anchorView = sourceView ?? view!
            popover.sourceView = anchorView
            popover.sourceRect = sourceView != nil ? anchorView.bounds : CGRect(x: anchorView.bounds.midX, y: anchorView.bounds.midY, width: 1, height: 1)
        }
        present(picker, animated: true)
    }

    /**
     * [EN] The theme menu, built again every time it opens, so the checkmark follows the current theme.
     * [CN] 主题菜单，每次打开时重新生成，勾号随当前主题变化。
     */
    @objc(cyl_themeMenuWithCompletion:)
    public func cyl_themeMenu(withCompletion completion: (() -> Void)?) -> UIMenu {
        UIViewController.cyl_setUpThemeSettings()
        let deferred = UIDeferredMenuElement.uncached { provide in
            provide(UIViewController.cyl_themeMenuElements(completion))
        }
        return UIMenu(title: CYLLocalizedString("选择主题"), children: [deferred])
    }

    private static func cyl_themeMenuElements(_ completion: (() -> Void)?) -> [UIMenuElement] {
        let currentIdentifier = CYLDemoThemes.current.identifier
        let themeActions: [UIMenuElement] = CYLDemoThemes.all.map { theme in
            let action = UIAction(title: theme.localizedName, image: CYLDemoThemes.listIcon(of: theme)) { _ in
                CYLDemoThemes.apply(theme)
                completion?()
            }
            action.state = theme.identifier == currentIdentifier ? .on : .off
            return action
        }
        let followsSystem = CYLDemoThemes.followsSystem
        let followAction = UIAction(title: CYLLocalizedString("跟随系统深色模式"), image: UIImage(systemName: "circle.lefthalf.filled")) { _ in
            CYLDemoThemes.setFollowsSystem(!followsSystem)
            completion?()
        }
        followAction.state = followsSystem ? .on : .off
        return [UIMenu(title: "", options: .displayInline, children: themeActions),
                UIMenu(title: "", options: .displayInline, children: [followAction])]
    }

    // MARK: Theme list section

    /**
     * [EN] The title of the theme list section, with the number of themes. [CN] 主题列表分组的标题，含主题数量。
     */
    @objc(cyl_themeListSectionTitle)
    public func cyl_themeListSectionTitle() -> String {
        String(format: CYLLocalizedString("换肤：节日与配色主题（%@ 种）"), NSNumber(value: CYLDemoThemes.all.count))
    }

    /**
     * [EN] The number of themes. [CN] 主题数量。
     */
    @objc(cyl_themeListRowCount)
    public func cyl_themeListRowCount() -> Int {
        CYLDemoThemes.all.count
    }

    /**
     * [EN] The cell of theme `row`: name, summary, icon or swatch, a checkmark on the current theme.
     * [CN] 第 `row` 个主题的 cell：名字、说明、图标或色块，当前主题带勾号。
     */
    @objc(cyl_themeListCellForTableView:row:)
    public func cyl_themeListCell(for tableView: UITableView, row: Int) -> UITableViewCell {
        UIViewController.cyl_setUpThemeSettings()
        let identifier = "CYLThemeListCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
            cell.textLabel?.font = .boldSystemFont(ofSize: 15)
            cell.detailTextLabel?.textColor = .gray
            return cell
        }()
        guard CYLDemoThemes.all.indices.contains(row) else { return cell }
        let theme = CYLDemoThemes.all[row]
        cell.textLabel?.text = theme.localizedName
        cell.detailTextLabel?.text = theme.localizedSummary
        cell.imageView?.image = CYLDemoThemes.listIcon(of: theme)
        cell.accessoryType = theme.identifier == CYLDemoThemes.current.identifier ? .checkmark : .none
        return cell
    }

    /**
     * [EN] Applies theme `row`. [CN] 应用第 `row` 个主题。
     */
    @objc(cyl_didSelectThemeListRow:)
    public func cyl_didSelectThemeListRow(_ row: Int) {
        UIViewController.cyl_setUpThemeSettings()
        guard CYLDemoThemes.all.indices.contains(row) else { return }
        CYLDemoThemes.apply(CYLDemoThemes.all[row])
    }
}
