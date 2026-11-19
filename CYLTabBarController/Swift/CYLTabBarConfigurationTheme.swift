//
//  CYLTabBarConfigurationTheme.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Phase 3 of the class switch (docs/Swift-Migration.md): what CYLTabBarController+CYLConfiguration.m and the declarations of
//      `CYLTabBarTheme` / `CYLTabBarConfigurationTheme` in CYLTabBarController.h held, now that CYLTabBarController is a Swift
//      class: the theme protocol, the skins of a configuration file, and the initializers and class factories that build a tab
//      bar controller from a file, a route or a URL. Objective-C selectors and the Swift names apps see are unchanged.
// [CN] 类切换的第 3 阶段：CYLTabBarController+CYLConfiguration.m 以及 CYLTabBarController.h 中 `CYLTabBarTheme` / `CYLTabBarConfigurationTheme`
//      的声明，在 CYLTabBarController 成为 Swift 类之后迁移到这里：主题协议、配置文件的皮肤，以及由文件、路由或 URL 创建 TabBarController 的初始化方法
//      与类工厂方法。Objective-C selector 与 App 看到的 Swift 名称不变。

/**
 FIX: issue #216, #136
 [EN] A theme (skin) of the tab bar: what a theme object registered with `CYLThemeManager` adopts so that switching the theme
      restyles the tab bar in place, in every style (Liquid Glass, the system tab bar, FlatDesign), with no new tab bar and no new
      view controllers. Every method is optional; a method that is missing or returns nil gives the tab bar back what the app had
      set before the first theme changed it. See docs/Theme-Switching.md.
 [CN] TabBar 的主题（皮肤）：注册到 `CYLThemeManager` 的主题对象遵循该协议，切换主题时原地更新 TabBar 样式，适用于所有样式（液态玻璃、系统
      TabBar、扁平样式），不创建新的 TabBar 和控制器。所有方法都是可选的；未实现或返回 nil 时，TabBar 恢复为第一次应用主题之前 App 设置的样式。
      见 docs/Theme-Switching.md。
 */
@objc(CYLTabBarTheme)
public protocol CYLTabBarTheme: NSObjectProtocol {
    /**
     [EN] The titles and icons of the tabs in this theme, shaped like `tabBarItemsAttributes` (one entry per tab, none for the
          plus button): e.g. holiday icons.
     [CN] 该主题下各 Tab 的标题与图标，结构与 `tabBarItemsAttributes` 相同（每个 Tab 一项，PlusButton 没有）：例如节日图标。
     */
    @objc(cyl_tabBarItemsAttributesForTabBarController:)
    optional func cyl_tabBarItemsAttributes(for tabBarController: CYLTabBarController) -> [[String: Any]]?
    /**
     [EN] The plus button in this theme, with the keys of `-updatePlusButtonWithAttributes:`.
     [CN] 该主题下的 PlusButton，使用 `-updatePlusButtonWithAttributes:` 的键。
     */
    @objc(cyl_plusButtonAttributesForTabBarController:)
    optional func cyl_plusButtonAttributes(for tabBarController: CYLTabBarController) -> [String: Any]?
    /**
     [EN] The appearance of the tab bar in this theme, assigned to `tabBar.standardAppearance` and `scrollEdgeAppearance`;
          FlatDesign follows it. Return a new object with the theme's colors.
     [CN] 该主题下 TabBar 的外观，赋给 `tabBar.standardAppearance` 与 `scrollEdgeAppearance`；扁平样式随之更新。请返回带有该主题颜色的新对象。
     */
    @objc(cyl_tabBarAppearanceForTabBarController:)
    optional func cyl_tabBarAppearance(for tabBarController: CYLTabBarController) -> UITabBarAppearance?
    /**
     [EN] Anything else, after the items, the plus button and the appearance (the tint of the pages...).
     [CN] 在 Tab、PlusButton 与外观之后的其他设置（页面的着色等）。
     */
    @objc(cyl_customizeTabBarController:)
    optional func cyl_customize(_ tabBarController: CYLTabBarController)
}

/// [EN] Private: the plus button slot's entry (`Swift/CYLTabBarController+CYLPlusSlot.swift`). [CN] 私有：PlusButton slot 的一项。
private let CYLTabBarItemPlusSlotPlaceholderKey = "CYLTabBarItemPlusSlotPlaceholder"

/**
 [EN] A skin of a configuration file (`CYLTabBarControllerThemes`): its named values, and the tab bar look they give (a
      `CYLTabBarTheme`). Colors in code can follow the same values: `CYLTabBarConfigurationTheme.colorNamed("accent")` is a color
      that follows the skin.
 [CN] 配置文件中的一个皮肤（`CYLTabBarControllerThemes`）：其命名值，以及这些值给出的 TabBar 外观（`CYLTabBarTheme`）。代码中的颜色也可以使用
      同样的值：`CYLTabBarConfigurationTheme.colorNamed("accent")` 是随皮肤变化的颜色。
 */
@objc(CYLTabBarConfigurationTheme)
open class CYLTabBarConfigurationTheme: NSObject, CYLTabBarTheme {

    /**
     [EN] The skin's identifier, e.g. "dark". [CN] 皮肤的标识，例如 "dark"。
     */
    @objc public let identifier: String

    /**
     [EN] The named values, with the base skin's values for the names this skin does not give. [CN] 命名值；本皮肤没有的名称使用基础皮肤的值。
     */
    @objc public let values: [String: Any]

    /// [EN] Per tab (its identifier, or its position without one): item key -> value name. [CN] 每个 Tab（其标识，没有时为位置）：item 键 -> 值名称。
    private let references: [AnyHashable: [String: String]]

    init(identifier: String, values: [String: Any], references: [AnyHashable: [String: String]]) {
        self.identifier = identifier
        self.values = values
        self.references = references
        super.init()
    }

    @available(*, unavailable)
    override init() {
        fatalError("Use the skins of a configuration file (CYLTabBarControllerThemes).")
    }

    /// [EN] The factory the configuration code calls (`CYLTabBarConfigurationThemeFactory`). [CN] 配置代码调用的工厂方法。
    @objc(cyl_themeWithIdentifier:values:references:)
    class func cylTheme(identifier: String, values: [String: Any], references: [AnyHashable: [String: String]]) -> CYLTabBarConfigurationTheme {
        CYLTabBarConfigurationTheme(identifier: identifier, values: values, references: references)
    }

    /**
     [EN] The value `name` as written in the file (a string, a number, a color from code), or nil.
     [CN] 文件中名为 `name` 的值（字符串、数字、代码中的颜色），没有时为 nil。
     */
    @objc(valueForName:)
    open func value(forName name: String) -> Any? {
        values[name]
    }

    /**
     [EN] The value `name` as a color ("#RRGGBB", "#RRGGBBAA", a UIColor), or nil.
     [CN] 名为 `name` 的值作为颜色（"#RRGGBB"、"#RRGGBBAA"、UIColor），否则为 nil。
     */
    @objc(colorForName:)
    open func color(forName name: String) -> UIColor? {
        CYLTabBarController.cylConfigurationColorValue(value(forName: name))
    }

    /**
     [EN] The value `name` as a font ("bold:15", "PingFangSC-Medium:12", a UIFont), or nil.
     [CN] 名为 `name` 的值作为字体（"bold:15"、"PingFangSC-Medium:12"、UIFont），否则为 nil。
     */
    @objc(fontForName:)
    open func font(forName name: String) -> UIFont? {
        value(forName: name).flatMap { CYLTabBarController.cylConfigurationFontValue($0) }
    }

    /**
     [EN] The value `name` as an image ("system:house", an image name, a UIImage), or nil.
     [CN] 名为 `name` 的值作为图片（"system:house"、图片名、UIImage），否则为 nil。
     */
    @objc(imageForName:)
    open func image(forName name: String) -> UIImage? {
        let value = value(forName: name)
        if let image = value as? UIImage {
            return image
        }
        guard let string = value as? String else { return nil }
        return CYLTabBarController.cylConfigurationImageValue(string) as? UIImage ?? UIImage(named: string)
    }

    /// [EN] The color `name` of `theme`, else of the first skin of the manager that has it, else clear. [CN] `theme` 中名为 `name` 的颜色，否则为管理器中第一个提供它的皮肤，否则为透明色。
    private static func cylColor(named name: String, in manager: CYLThemeManager, theme: Any?) -> UIColor {
        if let color = (theme as? CYLTabBarConfigurationTheme)?.color(forName: name) {
            return color
        }
        // [EN] Another kind of theme is current: the first skin of the file that has the color. [CN] 当前是其他类型的主题：使用文件中第一个提供该颜色的皮肤。
        for candidate in manager.themes {
            if let color = (candidate as? CYLTabBarConfigurationTheme)?.color(forName: name) {
                return color
            }
        }
        return .clear
    }

    /**
     [EN] A color that follows the skin of `CYLThemeManagerCenter.defaultThemeManager`: the value `name` of its current skin.
     [CN] 跟随 `CYLThemeManagerCenter.defaultThemeManager` 皮肤的颜色：其当前皮肤中名为 `name` 的值。
     */
    @objc(colorNamed:)
    open class func colorNamed(_ name: String) -> UIColor {
        UIColor.cyl_color(withName: name) { manager, _, theme in
            cylColor(named: name, in: manager, theme: theme)
        }
    }

    /**
     [EN] The same for the manager named `managerName` (`CYLTabBarControllerThemeManagerName`).
     [CN] 同上，用于名为 `managerName` 的管理器（`CYLTabBarControllerThemeManagerName`）。
     */
    @objc(colorNamed:themeManagerName:)
    open class func colorNamed(_ name: String, themeManagerName managerName: NSCopying & NSObjectProtocol) -> UIColor {
        UIColor.cyl_color(withName: name, themeManagerName: managerName) { manager, _, theme in
            cylColor(named: name, in: manager, theme: theme)
        }
    }

    // MARK: CYLTabBarTheme

    open func cyl_tabBarItemsAttributes(for tabBarController: CYLTabBarController) -> [[String: Any]]? {
        var items: [[String: Any]] = []
        var themed = false
        var position = 0
        for case let item as [AnyHashable: Any] in tabBarController.tabBarItemsAttributes {
            if (item[CYLTabBarItemPlusSlotPlaceholderKey] as? NSNumber)?.boolValue == true {
                continue
            }
            let identifier = CYLTabBarController.cylConfigurationStringValue(item[CYLTabBarItemIdentifier]) ?? ""
            let tabReferences = identifier.isEmpty ? references[NSNumber(value: position)] : references[identifier as NSString]
            position += 1
            var raw: [String: Any] = [:]
            for (key, valueName) in tabReferences ?? [:] {
                if let value = values[valueName] {
                    raw[key] = value
                }
            }
            themed = themed || !raw.isEmpty
            // [EN] An empty entry keeps that tab as it is. [CN] 空条目让该 Tab 保持不变。
            items.append(raw.isEmpty ? [:] : CYLTabBarController.cylNormalizedItemAttributes(raw as NSDictionary))
        }
        return themed ? items : nil
    }

    open func cyl_tabBarAppearance(for tabBarController: CYLTabBarController) -> UITabBarAppearance? {
        let background = color(forName: CYLTabBarBackgroundColor)
        let shadow = color(forName: CYLTabBarShadowColor)
        let titleColor = color(forName: CYLTabBarItemTitleColor)
        let selectedTitleColor = color(forName: CYLTabBarItemSelectedTitleColor)
        let iconColor = color(forName: CYLTabBarItemIconColor)
        let selectedIconColor = color(forName: CYLTabBarItemSelectedIconColor)
        let titleFont = font(forName: CYLTabBarItemTitleFont)
        let selectedTitleFont = font(forName: CYLTabBarItemSelectedTitleFont) ?? titleFont
        let backgroundImage = image(forName: CYLTabBarBackgroundImage)
        let shadowImage = image(forName: CYLTabBarShadowImage)
        let positioning = CYLTabBarController.cylConfigurationStringValue(value(forName: CYLTabBarStackedItemPositioning))?.lowercased() ?? ""
        let itemWidth = (value(forName: CYLTabBarStackedItemWidth) as? NSNumber)?.doubleValue
            ?? (value(forName: CYLTabBarStackedItemWidth) as? NSString)?.doubleValue
        let itemSpacing = (value(forName: CYLTabBarStackedItemSpacing) as? NSNumber)?.doubleValue
            ?? (value(forName: CYLTabBarStackedItemSpacing) as? NSString)?.doubleValue
        let layout = !positioning.isEmpty || itemWidth != nil || itemSpacing != nil
        let hasValue: [Any?] = [background, shadow, titleColor, selectedTitleColor, iconColor, selectedIconColor, titleFont, selectedTitleFont,
                                backgroundImage, shadowImage]
        guard layout || hasValue.contains(where: { $0 != nil }) else {
            // [EN] No bar-wide values: the app's own appearance stays. [CN] 没有整个 TabBar 的值：保留 App 自己的外观。
            return nil
        }
        let appearance = UITabBarAppearance()
        // [EN] A background color asks for an opaque bar: over the default (blurred) background, Liquid Glass did not show it.
        // [CN] 背景色需要不透明的 TabBar：在默认（模糊）背景上，液态玻璃不显示该颜色。
        if let background {
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = background
        } else {
            appearance.configureWithDefaultBackground()
        }
        if let shadow { appearance.shadowColor = shadow }
        if let backgroundImage { appearance.backgroundImage = backgroundImage }
        if let shadowImage { appearance.shadowImage = shadowImage }
        // [EN] How the items share the width: the system and the FlatDesign tab bars both read these. [CN] 各 Item 如何分配宽度：系统与扁平样式 TabBar 都会读取。
        switch positioning {
        case "centered": appearance.stackedItemPositioning = .centered
        case "fill": appearance.stackedItemPositioning = .fill
        case "automatic": appearance.stackedItemPositioning = .automatic
        case "": break
        default: CYLTabBarController.cylLogInvalidConfigurationValue(positioning, forKey: CYLTabBarStackedItemPositioning)
        }
        if let itemWidth { appearance.stackedItemWidth = max(itemWidth, 0) }
        if let itemSpacing { appearance.stackedItemSpacing = max(itemSpacing, 0) }
        appearance.cyl_applyItemAppearance { itemAppearance in
            var normal = itemAppearance.normal.titleTextAttributes
            if let titleColor { normal[.foregroundColor] = titleColor }
            if let titleFont { normal[.font] = titleFont }
            itemAppearance.normal.titleTextAttributes = normal
            var selected = itemAppearance.selected.titleTextAttributes
            if let selectedTitleColor { selected[.foregroundColor] = selectedTitleColor }
            if let selectedTitleFont { selected[.font] = selectedTitleFont }
            itemAppearance.selected.titleTextAttributes = selected
            if let iconColor { itemAppearance.normal.iconColor = iconColor }
            if let selectedIconColor { itemAppearance.selected.iconColor = selectedIconColor }
        }
        return appearance
    }
}

// MARK: - Initializers and class factories from a configuration file

extension CYLTabBarController {

    /**
     [EN] A tab bar controller from a configuration file (JSON, YAML, plist, protobuf; see docs/Configuration-File.md), on the
          main thread only (E1). Throws when the file cannot be read or a tab has no page.
     [CN] 由配置文件（JSON、YAML、plist、protobuf，见 docs/Configuration-File.md）创建 TabBarController，只能在主线程调用（E1）。文件无法读取
          或某个 Tab 没有页面时抛出错误。
     */
    @objc(initWithConfigurationFile:error:)
    public convenience init(configurationFile filePath: String) throws {
        guard Thread.isMainThread else {
            // [EN] UIKit objects only on the main thread (E1). [CN] UIKit 对象只能在主线程创建（E1）。
            throw CYLTabBarController.cylConfigurationMainThreadError()
        }
        let configuration = try Self.configuration(withContentsOfFile: filePath)
        self.init(configuration: configuration)
        if let pagesError = CYLTabBarController.cylConfigurationPagesError(for: self) {
            throw pagesError
        }
    }

    /**
     [EN] `init(configurationFile:)` with a resource route (see `configuration(withRoute:)`).
     [CN] 使用资源路由的 `init(configurationFile:)`（见 `configuration(withRoute:)`）。
     */
    @objc(initWithConfigurationRoute:error:)
    public convenience init(configurationRoute route: String) throws {
        try self.init(configurationFile: try CYLTabBarController.cylPathOfConfigurationRoute(route))
    }

    /// [EN] A tab bar controller of the receiving class from a loaded configuration, or the error. [CN] 由加载的配置创建接收者类的 TabBarController，或返回错误。
    private class func cylTabBarController(withLoadedConfiguration configuration: [String: Any]) throws -> Self {
        let tabBarController = self.init(configuration: configuration)
        if let pagesError = CYLTabBarController.cylConfigurationPagesError(for: tabBarController) {
            throw pagesError
        }
        return tabBarController
    }

    /**
     [EN] Convenience constructor for `init(configurationFile:)`; builds the class it is called on.
     [CN] `init(configurationFile:)` 的便利构造方法；创建调用它的类。
     */
    @objc(tabBarControllerWithConfigurationFile:error:)
    open class func tabBarController(withConfigurationFile filePath: String) throws -> Self {
        guard Thread.isMainThread else { throw CYLTabBarController.cylConfigurationMainThreadError() }
        return try cylTabBarController(withLoadedConfiguration: try configuration(withContentsOfFile: filePath))
    }

    /**
     [EN] Convenience constructor for `init(configurationRoute:)`; builds the class it is called on.
     [CN] `init(configurationRoute:)` 的便利构造方法；创建调用它的类。
     */
    @objc(tabBarControllerWithConfigurationRoute:error:)
    open class func tabBarController(withConfigurationRoute route: String) throws -> Self {
        try tabBarController(withConfigurationFile: try CYLTabBarController.cylPathOfConfigurationRoute(route))
    }

    /// [EN] The completion of the asynchronous factories with a tab bar controller of the receiving class. [CN] 异步工厂方法的回调，带接收者类的 TabBarController。
    private class func cylFinishLoading(_ configuration: [String: Any]?, _ error: Error?,
                                        _ completion: @escaping CYLTabBarControllerConfigurationCompletion) {
        guard let configuration else {
            completion(nil, error)
            return
        }
        do {
            completion(try cylTabBarController(withLoadedConfiguration: configuration), nil)
        } catch {
            completion(nil, error)
        }
    }

    /**
     [EN] `load(withConfigurationURL:completion:)` with a request of your own. The completion runs on the main queue.
     [CN] 使用自定义请求的 `load(withConfigurationURL:completion:)`。回调在主队列执行。
     */
    @objc(loadTabBarControllerWithConfigurationURLRequest:completion:)
    @discardableResult
    open class func load(withConfigurationURLRequest request: URLRequest,
                         completion: @escaping CYLTabBarControllerConfigurationCompletion) -> URLSessionDataTask? {
        loadConfiguration(with: request) { configuration, error in
            cylFinishLoading(configuration, error, completion)
        }
    }

    /**
     [EN] A tab bar controller of the receiving class from a configuration file at `URL` (a remote file, or a local one), on the
          main queue: the tab bar controller, or nil and the error.
     [CN] 由 `URL` 处的配置文件（远程或本地文件）创建接收者类的 TabBarController，在主队列回调：TabBarController，或 nil 与错误。
     */
    @objc(loadTabBarControllerWithConfigurationURL:completion:)
    @discardableResult
    open class func load(withConfigurationURL url: URL,
                         completion: @escaping CYLTabBarControllerConfigurationCompletion) -> URLSessionDataTask? {
        loadConfiguration(with: url) { configuration, error in
            cylFinishLoading(configuration, error, completion)
        }
    }
}
