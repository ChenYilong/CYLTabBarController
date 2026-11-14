//
//  CYLTabBarController+CYLTheme.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The same object, or equal ones (nil only matches nil). [CN] 同一对象或相等的对象（nil 只与 nil 匹配）。
 */
func CYLThemeSameValue(_ value: Any?, _ otherValue: Any?) -> Bool {
    switch (value, otherValue) {
    case (nil, nil):
        return true
    case let (value?, otherValue?):
        let first = value as AnyObject
        let second = otherValue as AnyObject
        return first === second || first.isEqual(second)
    default:
        return false
    }
}

/**
 * [EN] One value a theme changes, and what to give back: the single restore model of the tab attributes, the icon views and the
 *      plus button. It only decides; each caller reads and writes its own kind of value.
 *      1. Before a theme writes, `prepare(currentValue:)`: if the value is no longer what the last theme wrote, the app changed it,
 *         and that becomes the value to give back; otherwise the first value seen is kept.
 *      2. After the write (also asynchronous), `didInstall(_:)` with the value read back.
 *      3. When no theme sets it any more, `shouldRestore(currentValue:)`: YES with the value to write (nil when there was none)
 *         unless the app changed it meanwhile.
 * [CN] 主题修改的一个值，以及需要恢复的内容：Tab attributes、图标视图与 PlusButton 共用的唯一恢复模型。它只做判断；读写由调用方各自完成。
 *      1. 主题写入前调用 `prepare(currentValue:)`：如果当前值已不是上一个主题写入的值，说明 App 修改过，它成为要恢复的值；否则保留第一次看到的值。
 *      2. 写入后（包括异步写入）调用 `didInstall(_:)`，传入读回的值。
 *      3. 没有主题再设置它时调用 `shouldRestore(currentValue:)`：返回 YES 及要写回的值（原本没有时为 nil），除非 App 期间修改过。
 */
final class CYLThemeRestorableValue: NSObject {
    /// [EN] The value to give back; `NSNull` for none; nil before the first theme. [CN] 要恢复的值；没有时为 `NSNull`；第一个主题之前为 nil。
    var original: Any?
    /// [EN] What the last theme wrote, as read back; nil while it is still loading. [CN] 上一个主题写入的值（读回的值）；仍在加载时为 nil。
    var installed: Any?

    func prepare(currentValue current: Any?) {
        if installed != nil && !CYLThemeSameValue(current, installed) {
            original = current ?? NSNull()
            installed = nil
        }
        if original == nil {
            original = current ?? NSNull()
        }
    }

    func didInstall(_ value: Any?) {
        installed = value
    }

    func shouldRestore(currentValue current: Any?) -> (restore: Bool, original: Any?) {
        let originalValue: Any? = original is NSNull ? nil : original
        return (installed != nil && CYLThemeSameValue(current, installed), originalValue)
    }
}

/**
 * [EN] The restore records of the tab attributes of one tab, by key. [CN] 一个 Tab 的 attributes 恢复记录，按 key 保存。
 */
final class CYLThemeAttributeValues: NSObject {
    var values: [String: CYLThemeRestorableValue] = [:]
}

/**
 * [EN] What the theme side of a tab bar controller remembers, attached to it: the manager set with `cyl_themeManager`, the app's own
 *      appearances before the first theme changed them, whether the launch theme was applied, the count of applied themes (a value
 *      still loading for an older theme is dropped), and what a theme changed, to give back: the tab attributes by tab and key, the
 *      icon view provider by tab, the plus button by part.
 * [CN] TabBarController 换肤一侧记录的信息，附加在它上面：通过 `cyl_themeManager` 设置的管理器、第一个主题修改前 App 自己的外观、是否已应用启动
 *      主题、已应用主题的计数（为旧主题加载的值会被丢弃），以及主题修改过、需要恢复的内容：按 Tab 与 key 保存的 Tab attributes、按 Tab 保存的图标视图
 *      provider、按部分保存的 PlusButton。
 */
final class CYLThemeSettings: NSObject {
    var manager: CYLThemeManager?
    var originalStandardAppearance: UITabBarAppearance?
    var originalScrollEdgeAppearance: UITabBarAppearance?
    var launchThemeApplied = false
    var generation = 0
    let attributeRestorables = NSMapTable<UIViewController, CYLThemeAttributeValues>.weakToStrongObjects()
    let iconRestorables = NSMapTable<UIViewController, CYLThemeRestorableValue>.weakToStrongObjects()
    var plusButtonRestorables: [String: CYLThemeRestorableValue] = [:]
}

enum CYLThemeKeys {
    static let settings = CYLUtilsKeys.key("cyl_themeSettings")
    /// [EN] The three parts of the plus button a theme can change. [CN] 主题可以修改的 PlusButton 三个部分。
    static let plusPartTitle = "title"
    static let plusPartImage = "image"
    static let plusPartSelectedImage = "selectedImage"
    /// [EN] The icon keys of `tabBarItemsAttributes`. [CN] `tabBarItemsAttributes` 中与图标有关的 key。
    static let iconAttributeKeys = [CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLTabBarItemDarkImage, CYLTabBarItemSelectedDarkImage,
                                    CYLTabBarItemImageURL, CYLTabBarItemSelectedImageURL, CYLTabBarItemImageURLSize]
}

/// [EN] `attributes` without its icon keys. [CN] 去掉图标 key 的 `attributes`。
private func CYLThemeAttributesWithoutIcons(_ attributes: [String: Any]?) -> [String: Any] {
    var withoutIcons = attributes ?? [:]
    for key in CYLThemeKeys.iconAttributeKeys {
        withoutIcons.removeValue(forKey: key)
    }
    return withoutIcons
}

/// [EN] What the plus button shows now for `part`. [CN] PlusButton 当前显示的 `part`。
private func CYLThemePlusButtonCurrentPart(_ plusButton: CYLPlusButton, _ part: String) -> Any? {
    if part == CYLThemeKeys.plusPartTitle {
        return plusButton.cyl_title
    }
    return plusButton.image(for: part == CYLThemeKeys.plusPartImage ? .normal : .selected)
}

/**
 * [EN] `CYLTabBarController (CYLTheme)`: FIX: issue #216 — the tab bar's side of theme switching (`CYLTabBarTheme`): applying a theme in
 *      place, restoring the app's own look, the launch theme, the injectable manager, and the animation colors that follow the theme
 *      (#216 + #604). Translated from Objective-C (docs/Swift-Migration.md, step 39). `CYLTabBarController` is still an Objective-C
 *      class, so the declarations stay in `CYLTabBarController.h` and these members are internal `@objc` methods with the declared selectors.
 * [CN] `CYLTabBarController (CYLTheme)`：FIX: issue #216 — 换肤在 TabBar 这一侧的实现（`CYLTabBarTheme`）：原地应用主题、恢复 App 自己的外观、
 *      启动时的主题、可注入的管理器，以及跟随主题的动画颜色（#216 + #604）。已从 Objective-C 翻译（docs/Swift-Migration.md，第 39 步）。
 *      `CYLTabBarController` 仍是 Objective-C 类，因此声明仍在 `CYLTabBarController.h` 中，这些成员是使用已声明 selector 的 internal `@objc` 方法。
 */
extension CYLTabBarController {

    private var cyl_themeSettings: CYLThemeSettings {
        if let settings = objc_getAssociatedObject(self, CYLThemeKeys.settings) as? CYLThemeSettings {
            return settings
        }
        let settings = CYLThemeSettings()
        objc_setAssociatedObject(self, CYLThemeKeys.settings, settings, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return settings
    }

    /**
     * [EN] The tab bar's manager (`cyl_themeManager`) drives the tab bar; another manager (e.g. the themes of one page) only with a tab bar
     *      theme (the callback itself is overridden in `CYLTabBarController.m`, see there). The animation colors (`CYLTabBarAnimationColors`) may hold theme colors of any manager: resolved again every time.
     * [CN] TabBar 的管理器（`cyl_themeManager`）决定 TabBar 外观；其他管理器（例如某个页面自己的主题）仅在其主题为 TabBar 主题时生效。
     *      动画颜色（`CYLTabBarAnimationColors`）可能是任意管理器的主题颜色：每次都重新解析。
     */
    @objc(cyl_tabBarThemeDidChangeByManager:theme:)
    func cylTabBarThemeDidChange(by manager: CYLThemeManager?, theme: NSObject?) {
        let isTabBarManager = manager === cylThemeManager()
        if isTabBarManager || theme is CYLTabBarTheme {
            cylApplyTabBarTheme(theme)
        }
        cylRefreshTabBarItemAnimationColors()
    }

    @objc(cyl_themeManager)
    func cylThemeManager() -> CYLThemeManager {
        cyl_themeSettings.manager ?? CYLThemeManagerCenter.defaultThemeManager
    }

    @objc(setCyl_themeManager:)
    func cylSetThemeManager(_ themeManager: CYLThemeManager?) {
        cyl_themeSettings.manager = themeManager
    }

    /**
     * FIX: issue #216
     * [EN] Every tab button applies the colors of its animation again (`CYLTabBarAnimationColors` resolved for the new theme). Only with an
     *      animation library; a tab without registered colors does nothing.
     * [CN] 每个 Tab 按钮重新应用其动画的颜色（按新主题解析的 `CYLTabBarAnimationColors`）。仅在有动画库时；没有注册颜色的 Tab 不做处理。
     */
    private func cylRefreshTabBarItemAnimationColors() {
        guard CYLTabBarItemAnimationCore.service != nil, isViewLoaded else { return }
        for viewController in viewControllers ?? [] {
            for tabButton in cylPrivate.cylTabButtons(of: viewController) {
                tabButton.cyl_refreshTabBarItemAnimationColors()
            }
        }
    }

    /**
     * [EN] Once, when first shown: the theme chosen at launch. [CN] 首次显示时执行一次：应用启动时选择的主题。
     */
    @objc(cyl_applyLaunchTabBarThemeIfNeeded)
    func cylApplyLaunchTabBarThemeIfNeeded() {
        let settings = cyl_themeSettings
        if settings.launchThemeApplied { return }
        settings.launchThemeApplied = true
        // [EN] Styles set before the tab bar was replaced by the library's own (CYLTabBar) are written into the bar shown now.
        // [CN] 在 TabBar 被替换为本库的 CYLTabBar 之前设置的样式，写入当前显示的 TabBar。
        cylPrivate.cylApplyTabBarItemStyles()
        // [EN] Nothing to restore yet: only a tab bar theme changes anything here.
        // [CN] 此时尚无需恢复：只有 TabBar 主题才需要处理。
        if let theme = cylThemeManager().currentTheme, theme is CYLTabBarTheme {
            cylApplyTabBarTheme(theme)
        }
    }

    @objc(cyl_applyTabBarTheme:)
    func cylApplyTabBarTheme(_ theme: Any?) {
        let settings = cyl_themeSettings
        settings.launchThemeApplied = true
        settings.generation += 1
        let generation = settings.generation
        let tabBarTheme = theme as? CYLTabBarTheme
        let itemsAttributes = tabBarTheme?.cyl_tabBarItemsAttributes?(for: self)
        let tabAttributes = themeAttributesByTab(ofItemsAttributes: itemsAttributes)
        // [EN] Titles and the other keys, in place (`-updateTabBarItemAtIndex:attributes:`, issue #601).
        // [CN] 原地更新标题与其他 key（`-updateTabBarItemAtIndex:attributes:`，issue #601）。
        applyThemeTabAttributes(tabAttributes)
        // [EN] The icons, as views in place of each tab's icon (`-setTabBarItemIcon:selectedIcon:size:atIndex:`).
        // [CN] 图标：以视图替换每个 Tab 的图标（`-setTabBarItemIcon:selectedIcon:size:atIndex:`）。
        applyThemeIcons(ofTabAttributes: tabAttributes, generation: generation)
        // [EN] The plus button's title and images (`-updatePlusButtonWithAttributes:`).
        // [CN] PlusButton 的标题与图片（`-updatePlusButtonWithAttributes:`）。
        applyThemePlusButtonAttributes(tabBarTheme?.cyl_plusButtonAttributes?(for: self), generation: generation)
        // [EN] The appearance: a new object for every theme, so every style (FlatDesign included) applies it.
        // [CN] 外观：每个主题都是新对象，因此所有样式（包括扁平样式）都会应用。
        let tabBar = self.tabBar
        let appearance = tabBarTheme?.cyl_tabBarAppearance?(for: self)
        if let appearance {
            if settings.originalStandardAppearance == nil {
                settings.originalStandardAppearance = tabBar.standardAppearance
                settings.originalScrollEdgeAppearance = tabBar.scrollEdgeAppearance
            }
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance.copy()
        } else if let original = settings.originalStandardAppearance {
            tabBar.standardAppearance = original
            tabBar.scrollEdgeAppearance = settings.originalScrollEdgeAppearance
            settings.originalStandardAppearance = nil
            settings.originalScrollEdgeAppearance = nil
        }
        // [EN] Bring the title offset copies (issue #475) and the flat design tab bar up to date now.
        // [CN] 立即更新标题偏移副本（issue #475）与扁平样式 TabBar。
        cylPrivate.cylSyncTabBarAppearances()
        tabBarTheme?.cyl_customize?(self)
        // [EN] Styles set in one place win over the theme's appearance. [CN] 在一处设置的样式优先于主题的外观。
        cylPrivate.cylApplyTabBarItemStyles()
        // [EN] What the app adds to the tab buttons in its one-time layout block (`-setViewDidLayoutSubViewsBlockInvokeOnce:block:`, e.g. a
        //      cover over a tab, badges) is added again after the next layout: before, a theme switch left that block marked as run, and what
        //      UIKit dropped from the tab buttons never came back. Scope: every style. The block itself decides what to add; the theme's own
        //      icons do not depend on it: they are views in place of each icon, in both layers on Liquid Glass, and are installed again after
        //      every layout (#601).
        // [CN] App 在只执行一次的布局 block（`-setViewDidLayoutSubViewsBlockInvokeOnce:block:`，如 Tab 上的封面、角标）中添加到 Tab 按钮的内容，
        //      在下一次布局后重新添加：之前换肤后该 block 仍被标记为已执行，UIKit 从 Tab 按钮中丢弃的内容不会再出现。范围：所有样式。添加什么由
        //      block 自己决定；主题自身的图标不依赖它：它们是替换每个图标的视图，液态玻璃下两个图层都有，每次布局后都会重新安装（#601）。
        cylPrivate.cylRearmViewDidLayoutSubviewsBlockInvokeOnce()
        // [EN] Liquid Glass only: the next layout pass puts the stand-in on the plus button's new image and position (`-viewDidLayoutSubviews`).
        // [CN] 仅液态玻璃：每次换肤后，替身跟随 PlusButton 的新图片与新位置。
        if tabBarStyleType != .flatDesign && CYLConstants.isLiquidGlassActive() && isViewLoaded {
            view.setNeedsLayout()
        }
        // [EN] The skin is applied: tabs (and the navigation titles that follow them), plus button, appearance. Every tab by default (the plus
        //      button's tab and placeholders excepted).
        // [CN] 皮肤已应用：Tab（以及跟随它们的导航栏标题）、PlusButton、外观。默认为全部 Tab（PlusButton 的 Tab 与占位除外）。
        let indexes = NSMutableIndexSet()
        var identifiers: [String] = []
        for (index, viewController) in (viewControllers ?? []).enumerated()
        where !cylPrivate.cylIsPlusSlotViewController(viewController) && !viewController.cyl_isPlaceholder {
            indexes.add(index)
            let identifier = viewController.cyl_tabBarItemIdentifier ?? viewController.cyl_getViewControllerInsteadOfNavigation().cyl_tabBarItemIdentifier ?? ""
            if !identifier.isEmpty {
                identifiers.append(identifier)
            }
        }
        var userInfo: [String: Any] = ["CYLTabBarItemIndexesKey": indexes.copy(), "CYLTabBarItemIdentifiersKey": identifiers]
        if let theme {
            userInfo["CYLTabBarThemeKey"] = theme
        }
        NotificationCenter.default.post(name: NSNotification.Name("CYLTabBarControllerThemeDidApplyNotification"), object: self, userInfo: userInfo)
    }

    /// [EN] YES while no other theme was applied after the one counted `generation`. [CN] 计数为 `generation` 的主题之后没有应用其他主题时为 YES。
    private func isCurrentThemeGeneration(_ generation: Int) -> Bool {
        cyl_themeSettings.generation == generation
    }

    /**
     * [EN] The theme's attributes by tab: one entry per tab, none for the plus button's tab or a placeholder (as
     *      `-updateTabBarItemsWithAttributes:`).
     * [CN] 按 Tab 保存的主题 attributes：每个 Tab 一项，PlusButton 的 Tab 与占位控制器不占项（与 `-updateTabBarItemsWithAttributes:` 相同）。
     */
    private func themeAttributesByTab(ofItemsAttributes itemsAttributes: [[String: Any]]?) -> NSMapTable<UIViewController, NSDictionary> {
        let tabAttributes = NSMapTable<UIViewController, NSDictionary>.weakToStrongObjects()
        let itemsAttributes = itemsAttributes ?? []
        var attributesIndex = 0
        for viewController in viewControllers ?? [] {
            if attributesIndex >= itemsAttributes.count { break }
            // [EN] The same slot test as `-updateTabBarItemsWithAttributes:` (a plus child inside a navigation controller too).
            // [CN] 与 `-updateTabBarItemsWithAttributes:` 相同的 slot 判断（也包括被导航控制器包裹的 PlusButton 子控制器）。
            if cylPrivate.cylIsPlusSlotViewController(viewController) { continue }
            tabAttributes.setObject(itemsAttributes[attributesIndex] as NSDictionary, forKey: viewController)
            attributesIndex += 1
        }
        return tabAttributes
    }

    private func viewControllers(of table: NSMapTable<UIViewController, NSDictionary>) -> [UIViewController] {
        table.keyEnumerator().allObjects.compactMap { $0 as? UIViewController }
    }

    /**
     * [EN] Titles and every other key except the icons, one restore record per tab and key: a key the new theme does not give gets its value
     *      back (removed when the app had none), unless the app changed it meanwhile. One update per tab.
     * [CN] 标题与图标以外的其他 key，每个 Tab 的每个 key 一条恢复记录：新主题未提供的 key 恢复原值（App 原本没有时移除），除非 App 期间修改过。
     *      每个 Tab 只更新一次。
     */
    private func applyThemeTabAttributes(_ tabAttributes: NSMapTable<UIViewController, NSDictionary>) {
        let restorables = cyl_themeSettings.attributeRestorables
        var affected = restorables.keyEnumerator().allObjects.compactMap { $0 as? UIViewController }
        for viewController in viewControllers(of: tabAttributes) where !affected.contains(viewController) {
            affected.append(viewController)
        }
        for viewController in affected {
            guard let index = viewControllers?.firstIndex(of: viewController) else {
                restorables.removeObject(forKey: viewController)
                continue
            }
            let current = tabBarItemAttributes(at: UInt(index)) ?? [:]
            let themeValues = CYLThemeAttributesWithoutIcons(tabAttributes.object(forKey: viewController) as? [String: Any])
            let record = restorables.object(forKey: viewController) ?? CYLThemeAttributeValues()
            var toWrite: [String: Any] = [:]
            var toRemove: [String] = []
            for key in Array(record.values.keys) where themeValues[key] == nil {
                let result = record.values[key]?.shouldRestore(currentValue: current[key])
                if let result, result.restore {
                    if let original = result.original {
                        toWrite[key] = original
                    } else {
                        toRemove.append(key)
                    }
                }
                record.values.removeValue(forKey: key)
            }
            for (key, themeValue) in themeValues {
                let value = record.values[key] ?? CYLThemeRestorableValue()
                record.values[key] = value
                value.prepare(currentValue: current[key])
                toWrite[key] = themeValue
            }
            if !toWrite.isEmpty {
                updateTabBarItem(at: UInt(index), attributes: toWrite)
            }
            if !toRemove.isEmpty {
                cylPrivate.cylThemeRemoveTabBarItemAttributeKeys(toRemove, atIndex: UInt(index))
            }
            let written = tabBarItemAttributes(at: UInt(index)) ?? [:]
            for (key, themeValue) in themeValues {
                record.values[key]?.didInstall(written[key] ?? themeValue)
            }
            if !record.values.isEmpty {
                restorables.setObject(record, forKey: viewController)
            } else {
                restorables.removeObject(forKey: viewController)
            }
        }
    }

    /**
     * [EN] The theme's icons, with the mechanism of `-setTabBarItemIcon:selectedIcon:size:atIndex:` (the "change all local icons" and "change
     *      all network icons" demo rows): a view in place of each tab's icon, in every style (Liquid Glass, its selected layer included, the
     *      system tab bar, FlatDesign), also over a Lottie icon, drawn with its own colors. Setting `tabBarItem.image` did not show on Liquid
     *      Glass with Lottie icons, and made UIKit rebuild the tab buttons.
     *      - The icon of an entry: `CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL` (with `CYLTabBarItemImageURLSize`) win; else
     *        `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage`, combined with their dark images.
     *      - One restore record per tab (the icon view provider): a tab the new theme gives no icon gets its own back, as does a tab whose icon
     *        could not be loaded, unless the app replaced the theme's icon meanwhile.
     *      - Icons are loaded first (network ones asynchronously) and shown only if no other theme came in between.
     * [CN] 主题图标，使用 `-setTabBarItemIcon:selectedIcon:size:atIndex:` 的机制（演示中的“批量使用本地图标”“批量下载网络图标”行）：以视图替换每个 Tab 的
     *      图标，适用于所有样式（液态玻璃，包括其选中图层；系统 TabBar；扁平样式），也能覆盖 Lottie 图标，按原图颜色绘制。原来设置 `tabBarItem.image` 的
     *      方式在使用 Lottie 图标的液态玻璃上不显示，并会让 UIKit 重建 Tab 按钮。
     *      - 每项的图标：`CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL`（及 `CYLTabBarItemImageURLSize`）优先；否则为 `CYLTabBarItemImage` /
     *        `CYLTabBarItemSelectedImage`，并与其深色图片合成。
     *      - 每个 Tab 一条恢复记录（图标视图 provider）：新主题未提供图标的 Tab、图标加载失败的 Tab 恢复自己的图标，除非 App 期间替换了主题图标。
     *      - 先加载图标（网络图标为异步），只有期间没有切换到其他主题时才显示。
     */
    private func applyThemeIcons(ofTabAttributes tabAttributes: NSMapTable<UIViewController, NSDictionary>, generation: Int) {
        let restorables = cyl_themeSettings.iconRestorables
        let providers = cylPrivate.cylTabBarItemIconViewProviders()
        var themeIcons: [(viewController: UIViewController, icon: Any, selectedIcon: Any?, size: NSValue?)] = []
        for viewController in viewControllers(of: tabAttributes) {
            let attributes = tabAttributes.object(forKey: viewController) as? [String: Any] ?? [:]
            var icon = attributes[CYLTabBarItemImageURL]
            var selectedIcon = attributes[CYLTabBarItemSelectedImageURL]
            let sizeValue = attributes[CYLTabBarItemImageURLSize] as? NSValue
            if icon == nil {
                let image = attributes[CYLTabBarItemImage]
                let selectedImage = attributes[CYLTabBarItemSelectedImage]
                // [EN] With a dark image, the combined image (names and UIImages); else the source as it is.
                // [CN] 有深色图片时为合成后的图片（图片名与 UIImage）；否则原样使用该来源。
                icon = attributes[CYLTabBarItemDarkImage] != nil ? UIImage.cyl_image(withImageInfo: image, darkImageInfo: attributes[CYLTabBarItemDarkImage]) : image
                selectedIcon = attributes[CYLTabBarItemSelectedDarkImage] != nil
                    ? UIImage.cyl_image(withImageInfo: selectedImage, darkImageInfo: attributes[CYLTabBarItemSelectedDarkImage]) : selectedImage
                if icon == nil {
                    icon = selectedIcon
                }
            }
            guard let icon else { continue }
            themeIcons.append((viewController, icon, selectedIcon, sizeValue))
        }
        // [EN] Tabs without an icon in this theme. [CN] 本主题中没有图标的 Tab。
        for viewController in restorables.keyEnumerator().allObjects.compactMap({ $0 as? UIViewController })
        where !themeIcons.contains(where: { $0.viewController === viewController }) {
            restoreThemeIcon(of: viewController)
        }
        for entry in themeIcons {
            let viewController = entry.viewController
            let value = restorables.object(forKey: viewController) ?? CYLThemeRestorableValue()
            restorables.setObject(value, forKey: viewController)
            value.prepare(currentValue: providers.object(forKey: viewController))
            let tabIcon = entry
            CYLTabBarController.cylPrivateClass.cylLoadTabBarItemIcon(tabIcon.icon) { [weak self, weak viewController] image in
                let show: (UIImage?) -> Void = { selectedImage in
                    // [EN] Dropped when another theme came in between, or the tab is gone. [CN] 期间切换了其他主题或 Tab 已不存在时丢弃。
                    guard let self, let viewController, self.isCurrentThemeGeneration(generation) else { return }
                    let index = self.viewControllers?.firstIndex(of: viewController)
                    let size = tabIcon.size?.cgSizeValue ?? .zero
                    // [EN] Not loaded (e.g. a failed download): the tab's own icon again. [CN] 未能加载（例如下载失败）：恢复 Tab 自己的图标。
                    guard let image, let index, self.setTabBarItemIcon(image, selectedIcon: selectedImage, size: size, at: UInt(index)) else {
                        self.restoreThemeIcon(of: viewController)
                        return
                    }
                    value.didInstall(self.cylPrivate.cylTabBarItemIconViewProviders().object(forKey: viewController))
                }
                if image == nil || tabIcon.selectedIcon == nil || CYLThemeSameValue(tabIcon.selectedIcon, tabIcon.icon) {
                    show(nil)
                } else {
                    CYLTabBarController.cylPrivateClass.cylLoadTabBarItemIcon(tabIcon.selectedIcon, completion: show)
                }
            }
        }
    }

    /// [EN] Gives `viewController` its own icon back, unless the app replaced the theme's icon. [CN] 恢复 `viewController` 自己的图标，除非 App 替换了主题图标。
    private func restoreThemeIcon(of viewController: UIViewController) {
        let restorables = cyl_themeSettings.iconRestorables
        guard let value = restorables.object(forKey: viewController) else { return }
        restorables.removeObject(forKey: viewController)
        let current = cylPrivate.cylTabBarItemIconViewProviders().object(forKey: viewController)
        if let index = viewControllers?.firstIndex(of: viewController) {
            let result = value.shouldRestore(currentValue: current)
            if result.restore {
                let provider = result.original.map { unsafeBitCast($0 as AnyObject, to: (@convention(block) (Bool) -> UIView?).self) }
                setTabBarItemIconViewProvider(provider, at: UInt(index))
            }
        }
    }

    /**
     * [EN] The theme's plus button, through `-updatePlusButtonWithAttributes:` (as the "change all titles" and "change all network icons" demo
     *      rows), one restore record per part: the title, the image, the selected image. A part the new theme does not give, or an image that
     *      could not be loaded, gets its own value back, unless the app changed it. An image the plus button never had is removed, and a selected
     *      image it never had becomes its normal image (a button without a selected image shows its normal one); a title it never had becomes "".
     *      A button whose picture is its background image (`-cyl_drawsTitleOverBackgroundImage`) takes no image from a theme.
     * [CN] 主题中的 PlusButton，通过 `-updatePlusButtonWithAttributes:`（与演示中“批量更换标题”“批量下载网络图标”行相同），每个部分一条恢复记录：标题、
     *      图片、选中图片。新主题未提供的部分、未能加载的图片恢复为它自己的内容，除非 App 修改过。PlusButton 原本没有的图片会被移除，原本没有的选中图片恢复
     *      为普通图片（按钮没有选中图片时显示普通图片）；原本没有的标题恢复为 ""。以背景图为图片的按钮（`-cyl_drawsTitleOverBackgroundImage`）不接受主题的图片。
     */
    private func applyThemePlusButtonAttributes(_ attributes: [String: Any]?, generation: Int) {
        guard let plusButton = CYLPlusButton(forOwner: self) else { return }
        plusButton.cylPrivate.cylSetBackgroundImageDidChangeHandler { [weak self] in
            self?.plusButtonBackgroundImageDidChange()
        }
        var themeParts: [String: Any] = [:]
        themeParts[CYLThemeKeys.plusPartTitle] = attributes?[CYLTabBarItemTitle]
        // [EN] A button whose picture is its background keeps it: an icon of a theme would sit beside the title, over the picture.
        // [CN] 以背景图为图片的按钮保持原样：主题图标会盖在图片上、挤在标题旁边。
        let takesThemeImages = !plusButton.cylPrivate.cylDrawsTitleOverBackgroundImage()
        if takesThemeImages {
            themeParts[CYLThemeKeys.plusPartImage] = attributes?[CYLTabBarItemImageURL] ?? attributes?[CYLTabBarItemImage]
            themeParts[CYLThemeKeys.plusPartSelectedImage] = attributes?[CYLTabBarItemSelectedImageURL] ?? attributes?[CYLTabBarItemSelectedImage]
        }
        let sizeValue = attributes?[CYLTabBarItemImageURLSize] as? NSValue
        for part in [CYLThemeKeys.plusPartTitle, CYLThemeKeys.plusPartImage, CYLThemeKeys.plusPartSelectedImage] {
            guard let themeValue = themeParts[part] else {
                restoreThemePlusButtonPart(part)
                continue
            }
            let value = cyl_themeSettings.plusButtonRestorables[part] ?? CYLThemeRestorableValue()
            cyl_themeSettings.plusButtonRestorables[part] = value
            value.prepare(currentValue: CYLThemePlusButtonCurrentPart(plusButton, part))
            if part == CYLThemeKeys.plusPartTitle {
                if updatePlusButton(attributes: [CYLTabBarItemTitle: themeValue]) {
                    value.didInstall(CYLThemePlusButtonCurrentPart(plusButton, part) ?? themeValue)
                }
                continue
            }
            CYLTabBarController.cylPrivateClass.cylLoadTabBarItemIcon(themeValue) { [weak self, weak plusButton] image in
                // [EN] Dropped when another theme came in between. [CN] 期间切换了其他主题时丢弃。
                guard let self, let plusButton, self.isCurrentThemeGeneration(generation) else { return }
                // [EN] A background image arrived while the icon was loading: the button takes no theme image any more.
                // [CN] 图标加载期间背景图片已到：按钮不再接受主题图片。
                if plusButton.cylPrivate.cylDrawsTitleOverBackgroundImage() { return }
                guard let image else {
                    self.restoreThemePlusButtonPart(part)
                    return
                }
                var imageAttributes: [String: Any] = [part == CYLThemeKeys.plusPartImage ? CYLTabBarItemImage : CYLTabBarItemSelectedImage: image]
                if let sizeValue {
                    imageAttributes[CYLTabBarItemImageURLSize] = sizeValue
                }
                if self.updatePlusButton(attributes: imageAttributes) {
                    value.didInstall(CYLThemePlusButtonCurrentPart(plusButton, part))
                }
            }
        }
    }

    /**
     * FIX: issue #216
     * [EN] A background image that arrives after the theme: a button whose picture is its background image takes no image from a theme, but
     *      while the background was loading the button only looked empty and took one, so the theme's icon was drawn over the new picture. The
     *      theme's images go when the button has no image of its own, so it ends like a button that had the background image at launch.
     * [CN] 主题之后才到的背景图片：以背景图为图片的按钮不接受主题图片，但背景图片加载期间按钮看起来只是没有图片，于是接受了主题图片，主题图标因此盖在新图片上。
     *      按钮没有自己的图片时移除主题图片，最终与启动时就有背景图片的按钮一致。
     */
    private func plusButtonBackgroundImageDidChange() {
        let restorables = cyl_themeSettings.plusButtonRestorables
        for part in [CYLThemeKeys.plusPartImage, CYLThemeKeys.plusPartSelectedImage] {
            guard let record = restorables[part] else { continue }
            let hadOwnImage = (record.original as? UIImage).map { $0.size.width > 0 } ?? false
            if !hadOwnImage {
                restoreThemePlusButtonPart(part)
            }
        }
    }

    /// [EN] Puts the plus button's own `part` back, unless the app changed it. [CN] 恢复 PlusButton 自己的 `part`，除非 App 修改过。
    private func restoreThemePlusButtonPart(_ part: String) {
        let settings = cyl_themeSettings
        guard let value = settings.plusButtonRestorables[part], let plusButton = CYLPlusButton(forOwner: self) else { return }
        settings.plusButtonRestorables.removeValue(forKey: part)
        let result = value.shouldRestore(currentValue: CYLThemePlusButtonCurrentPart(plusButton, part))
        guard result.restore else { return }
        if part == CYLThemeKeys.plusPartTitle {
            plusButton.cyl_updateTitle((result.original as? String) ?? "", image: nil, selectedImage: nil)
        } else if part == CYLThemeKeys.plusPartImage {
            if let original = result.original as? UIImage {
                plusButton.cyl_updateTitle(nil, image: original, selectedImage: nil)
            } else {
                // [EN] It had no image of its own. [CN] 它原本没有图片。
                plusButton.cylPrivate.cylRemoveImage()
            }
        } else {
            // [EN] No selected image of its own: the normal one, as a button without a selected image shows.
            // [CN] 原本没有选中图片：使用普通图片，与没有选中图片的按钮显示一致。
            if let selectedImage = (result.original as? UIImage) ?? plusButton.image(for: .normal) {
                plusButton.cyl_updateTitle(nil, image: nil, selectedImage: selectedImage)
            }
        }
    }
}
