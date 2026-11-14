//
//  CYLSettingsDemoRows.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The demo rows of the settings section (`UIViewController+CYLSettingsSection.swift`), part 1: title offset,
 *      `standardAppearance` themes, login state, plus button touchable area, `selectedIndex`, tap animation, long press and
 *      swipe. Each row has a cell and an action. Translated from Objective-C (docs/Swift-Migration.md, step 33); internal.
 * [CN] 设置分组（`UIViewController+CYLSettingsSection.swift`）的演示行，第 1 部分：标题偏移、`standardAppearance` 主题、登录状态、
 *      PlusButton 点击范围、`selectedIndex`、点击动画、长按与滑动。每行有一个 cell 与一个操作。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 33 步）；仅供内部使用。
 */
enum CYLSettingsDemo {

    /**
     * [EN] A subtitle cell with a bold title, a gray wrapping subtitle and an optional symbol, reused by identifier.
     * [CN] 带粗体标题、可换行灰色副标题与可选符号的副标题 cell，按标识复用。
     */
    static func subtitleCell(_ tableView: UITableView, _ identifier: String, symbol: String? = nil) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) {
            return cell
        }
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        cell.textLabel?.font = .boldSystemFont(ofSize: 15)
        cell.detailTextLabel?.textColor = .gray
        cell.detailTextLabel?.numberOfLines = 0
        if let symbol {
            cell.imageView?.image = UIImage(systemName: symbol)
        }
        return cell
    }

    static func flag(_ object: AnyObject, _ key: UnsafeRawPointer) -> Int? {
        (objc_getAssociatedObject(object, key) as? NSNumber)?.intValue
    }

    static func setValue(_ value: Any?, _ object: AnyObject, _ key: UnsafeRawPointer) {
        objc_setAssociatedObject(object, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // MARK: Title offset (FIX: issue #475)

    /**
     * [EN] The vertical title offsets the row cycles through. [CN] 该行依次切换的标题垂直偏移。
     */
    static let titleVerticalOffsets: [CGFloat] = [0, -4, 4]

    static func titlePositionAdjustmentCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLTitlePositionAdjustmentCell", symbol: "arrow.up.arrow.down")
        let offset = tabBarController?.titlePositionAdjustment ?? .zero
        cell.textLabel?.text = CYLLocalizedString("标题偏移（titlePositionAdjustment）")
        cell.detailTextLabel?.text = String(format: CYLLocalizedString("点击切换所有 Tab 标题的垂直偏移，当前：%@"),
                                            String(format: "(%g, %g)", offset.horizontal, offset.vertical))
        return cell
    }

    /**
     * [EN] Moves every tab title to the next offset with the public `-setTitlePositionAdjustment:`, applied at runtime in
     *      every style.
     * [CN] 通过公开的 `-setTitlePositionAdjustment:` 将所有 Tab 标题切换到下一个偏移，运行时对所有样式生效。
     */
    static func switchTitlePositionAdjustment(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController else { return }
        let current = tabBarController.titlePositionAdjustment.vertical
        let index = titleVerticalOffsets.firstIndex { abs($0 - current) < 0.5 }.map { ($0 + 1) % titleVerticalOffsets.count } ?? 0
        tabBarController.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: titleVerticalOffsets[index])
    }

    // MARK: standardAppearance themes

    /**
     * [EN] Demo themes for `tabBar.standardAppearance`; the same object styles the system tab bar (Liquid Glass and classic)
     *      and the FlatDesign tab bar (`-[CYLFlatDesignTabBar standardAppearance]`).
     * [CN] `tabBar.standardAppearance` 的演示主题；同一个对象同时作用于系统 TabBar（液态玻璃与经典样式）与扁平样式 TabBar
     *      （`-[CYLFlatDesignTabBar standardAppearance]`）。
     */
    enum AppearanceTheme: Int, CaseIterable {
        case original, dark, centeredCapsule, greenLine

        var name: String {
            switch self {
            case .original: return CYLLocalizedString("原始")
            case .dark: return CYLLocalizedString("深色")
            case .centeredCapsule: return CYLLocalizedString("居中胶囊")
            case .greenLine: return CYLLocalizedString("绿色描边")
            }
        }
    }

    static let appearanceThemeKey = CYLUtilsKeys.key("cyl_demoAppearanceTheme")
    static let originalStandardAppearanceKey = CYLUtilsKeys.key("cyl_demoOriginalStandardAppearance")
    static let originalScrollEdgeAppearanceKey = CYLUtilsKeys.key("cyl_demoOriginalScrollEdgeAppearance")

    /**
     * [EN] A capsule for `selectionIndicatorImage`: resizable and template, so `selectionIndicatorTintColor` colors it.
     * [CN] 用作 `selectionIndicatorImage` 的胶囊：可拉伸的模板图片，由 `selectionIndicatorTintColor` 着色。
     */
    static func capsuleImage() -> UIImage {
        let size = CGSize(width: 32, height: 32)
        return UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.black.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size).insetBy(dx: 2, dy: 4), cornerRadius: 12).fill()
        }.resizableImage(withCapInsets: UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)).withRenderingMode(.alwaysTemplate)
    }

    static func setItemColors(_ appearance: UITabBarAppearance, normal: UIColor, selected: UIColor) {
        for item in [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance] {
            item.normal.iconColor = normal
            item.normal.titleTextAttributes = [.foregroundColor: normal]
            item.selected.iconColor = selected
            item.selected.titleTextAttributes = [.foregroundColor: selected]
        }
    }

    static func appearance(for theme: AppearanceTheme) -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        switch theme {
        case .dark:
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(white: 0.08, alpha: 1)
            appearance.shadowColor = .clear
            setItemColors(appearance, normal: .lightGray, selected: .white)
            appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = .systemOrange
        case .centeredCapsule:
            appearance.stackedItemPositioning = .centered
            appearance.stackedItemWidth = 64
            appearance.stackedItemSpacing = 8
            appearance.selectionIndicatorImage = capsuleImage()
            appearance.selectionIndicatorTintColor = UIColor.systemPink.withAlphaComponent(0.2)
            setItemColors(appearance, normal: .systemGray, selected: .systemPink)
            appearance.stackedLayoutAppearance.normal.badgeBackgroundColor = .systemPurple
        case .greenLine:
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .systemBackground
            appearance.shadowColor = .systemGreen
            setItemColors(appearance, normal: .secondaryLabel, selected: .systemGreen)
            appearance.stackedLayoutAppearance.normal.badgePositionAdjustment = UIOffset(horizontal: 2, vertical: -2)
        case .original:
            break
        }
        return appearance
    }

    static func standardAppearanceCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLStandardAppearanceCell", symbol: "paintpalette")
        let theme = tabBarController.flatMap { flag($0, appearanceThemeKey) }.flatMap(AppearanceTheme.init(rawValue:)) ?? .original
        cell.textLabel?.text = CYLLocalizedString("standardAppearance 主题（液态玻璃与扁平样式共用）")
        cell.detailTextLabel?.text = String(format: CYLLocalizedString("点击切换 tabBar.standardAppearance，当前：%@"), theme.name)
        return cell
    }

    /**
     * [EN] Assigns the next theme to `tabBar.standardAppearance` and `scrollEdgeAppearance` (FlatDesign follows the system tab
     *      bar's appearance); "Original" puts back what the app had set.
     * [CN] 将下一个主题赋给 `tabBar.standardAppearance` 与 `scrollEdgeAppearance`（扁平样式跟随系统 TabBar 的 appearance）；“原始”恢复
     *      App 原先的设置。
     */
    static func switchStandardAppearance(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController else { return }
        let tabBar = tabBarController.tabBar
        if objc_getAssociatedObject(tabBarController, originalStandardAppearanceKey) == nil {
            setValue(tabBar.standardAppearance, tabBarController, originalStandardAppearanceKey)
            setValue(tabBar.scrollEdgeAppearance ?? NSNull(), tabBarController, originalScrollEdgeAppearanceKey)
        }
        let next = ((flag(tabBarController, appearanceThemeKey) ?? 0) + 1) % AppearanceTheme.allCases.count
        setValue(NSNumber(value: next), tabBarController, appearanceThemeKey)
        let theme = AppearanceTheme(rawValue: next) ?? .original
        if theme == .original {
            if let original = objc_getAssociatedObject(tabBarController, originalStandardAppearanceKey) as? UITabBarAppearance {
                tabBar.standardAppearance = original
            }
            tabBar.scrollEdgeAppearance = objc_getAssociatedObject(tabBarController, originalScrollEdgeAppearanceKey) as? UITabBarAppearance
        } else {
            let appearance = appearance(for: theme)
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    // MARK: Login state (issue #19)

    /**
     * [EN] The titles of the tabs that need login, joined for display. [CN] 需要登录的 Tab 的标题，拼接后用于显示。
     */
    static func loginRequiredTabTitles(_ tabBarController: CYLTabBarController?) -> String {
        guard let tabBarController else { return "" }
        let titles = (tabBarController.viewControllers ?? []).filter { tabBarController.cyl_isLoginRequired(for: $0) }.compactMap { viewController in
            (viewController.tabBarItem.title ?? viewController.cyl_getViewControllerInsteadOfNavigation().title).flatMap { $0.isEmpty ? nil : $0 }
        }
        return titles.joined(separator: CYLLocalizedString("、"))
    }

    /**
     * [EN] Fills the login state cell: icon, state, and which tabs need login. [CN] 填充登录状态 cell：图标、状态，以及需要登录的 Tab。
     */
    static func configureLoginStateCell(_ cell: UITableViewCell, _ tabBarController: CYLTabBarController?) {
        let loggedIn = tabBarController?.cyl_loggedIn ?? false
        cell.imageView?.image = UIImage(systemName: loggedIn ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.xmark")
        cell.textLabel?.text = loggedIn ? CYLLocalizedString("登录状态：已登录") : CYLLocalizedString("登录状态：未登录")
        let titles = loginRequiredTabTitles(tabBarController)
        if titles.isEmpty {
            cell.detailTextLabel?.text = CYLLocalizedString("打开开关表示已登录，关闭表示未登录（已缓存到本地）。当前没有需要登录的 Tab。")
        } else {
            cell.detailTextLabel?.text = String(format: CYLLocalizedString("打开开关表示已登录，关闭表示未登录（已缓存到本地）。未登录时点击「%@」会先弹出登录页，登录后自动切换到该 Tab；已登录时直接切换。"), titles)
        }
    }

    static func loginStateCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLLoginStateCell")
        let loginSwitch = cell.accessoryView as? CYLLoginStateSwitch ?? CYLLoginStateSwitch()
        cell.accessoryView = loginSwitch
        loginSwitch.tabBarController = tabBarController
        loginSwitch.cell = cell
        loginSwitch.isOn = tabBarController?.cyl_loggedIn ?? false
        configureLoginStateCell(cell, tabBarController)
        return cell
    }

    /**
     * [EN] A tap on the row flips the switch too. [CN] 点击该行同样会拨动开关。
     */
    static func toggleLoginState(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController else { return }
        tabBarController.cyl_loggedIn = !tabBarController.cyl_loggedIn
    }

    // MARK: Plus button touchable area (issue #91)

    static func touchableAreaCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let identifier = "CYLTouchableAreaCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? CYLTouchableAreaCell
            ?? CYLTouchableAreaCell(style: .default, reuseIdentifier: identifier)
        cell.tabBarController = tabBarController
        cell.reload()
        return cell
    }

    // MARK: selectedIndex and the plus button (FIX: issue #515)

    /**
     * [EN] A tap selects the next tab with `cyl_selectedIndexIgnoringPlusButton`; the text shows that index next to
     *      `selectedIndex`, which also counts the plus button's child view controller or placeholder.
     * [CN] 点击通过 `cyl_selectedIndexIgnoringPlusButton` 选中下一个 Tab；文字同时显示该下标与 `selectedIndex`（后者还会计入 PlusButton
     *      的子控制器或占位控制器）。
     */
    static func selectedIndexCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLSelectedIndexCell", symbol: "arrow.right.square")
        let indexText = tabBarController.map { $0.cyl_selectedIndexIgnoringPlusButton }.flatMap { $0 == NSNotFound ? nil : "\($0)" } ?? "-"
        let selectedIndexText = tabBarController.map { $0.selectedIndex }.flatMap { $0 == NSNotFound ? nil : "\($0)" } ?? "-"
        let selected = tabBarController?.selectedViewController
        let title = selected?.cyl_getViewControllerInsteadOfNavigation().tabBarItem.title ?? selected?.tabBarItem.title ?? "-"
        cell.textLabel?.text = CYLLocalizedString("selectedIndex 与 PlusButton（issue #515）")
        cell.detailTextLabel?.text = String(format: CYLLocalizedString("点击切换到下一个 Tab。不含 PlusButton 的下标：%1$@，selectedIndex：%2$@，当前：%3$@"),
                                            indexText, selectedIndexText, title)
        return cell
    }

    /**
     * [EN] Selects the next tab, by its index without the plus button. [CN] 按不含 PlusButton 的下标选中下一个 Tab。
     */
    static func selectNextTabIgnoringPlusButton(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController, !tabBarController.cyl_viewControllersIgnoringPlusButton.isEmpty else { return }
        let count = UInt(tabBarController.cyl_viewControllersIgnoringPlusButton.count)
        let current = tabBarController.cyl_selectedIndexIgnoringPlusButton
        tabBarController.cyl_selectedIndexIgnoringPlusButton = current == UInt(NSNotFound) ? 0 : (current + 1) % count
    }

    // MARK: Tap animation (FIX: issue #535)

    static let tapAnimationStepKey = CYLUtilsKeys.key("cyl_demoTapAnimationStep")

    /**
     * [EN] The steps after the built-in types: one tab only (`viewController.cyl_tabButtonAnimation`), an object for every
     *      tab (`cyl_defaultTabButtonAnimation`), then the animation classes with their properties set.
     * [CN] 内置类型之后的步骤：只设置一个 Tab（`viewController.cyl_tabButtonAnimation`）、所有 Tab 共用一个对象
     *      （`cyl_defaultTabButtonAnimation`），然后是设置了属性的动画类。
     */
    enum TapAnimationStep {
        static let oneTabRotation = CYLTabButtonTapAnimationType.fume.rawValue + 1
        static let defaultFrameAnimation = oneTabRotation + 1
        static let slowScale = oneTabRotation + 2
        static let slowZoomIn = oneTabRotation + 3
        static let starFireworks = oneTabRotation + 4
        static let curlUp = oneTabRotation + 5
        static let count = oneTabRotation + 6
    }

    static func tapAnimationTypeName(_ type: CYLTabButtonTapAnimationType) -> String {
        switch type {
        case .scale: return CYLLocalizedString("放大再缩小")
        case .zoomIn: return CYLLocalizedString("从小放大")
        case .bounce: return CYLLocalizedString("弹性")
        case .bounceWithFireworks: return CYLLocalizedString("弹性 + 烟花")
        case .rotation: return CYLLocalizedString("旋转")
        case .flip: return CYLLocalizedString("翻转")
        case .fume: return CYLLocalizedString("飘散")
        default: return CYLLocalizedString("无")
        }
    }

    static func currentTapAnimationStep(_ tabBarController: CYLTabBarController?) -> Int {
        guard let tabBarController else { return 0 }
        return flag(tabBarController, tapAnimationStepKey) ?? tabBarController.cyl_tabButtonTapAnimationType.rawValue
    }

    /**
     * [EN] Frames for `CYLTabButtonFrameAnimation`: dots that grow. [CN] `CYLTabButtonFrameAnimation` 的帧：逐渐变大的圆点。
     */
    static func frameImages() -> [UIImage] {
        (1...6).compactMap { index in
            let side = 6.0 * CGFloat(index)
            return UIImage.cyl_image(with: .systemOrange, size: CGSize(width: side, height: side), cornerRadius: side / 2)
        }
    }

    /**
     * [EN] The animation classes with their properties set. [CN] 设置了属性的动画类。
     */
    static func configuredTapAnimation(_ step: Int) -> CYLTabButtonAnimation? {
        switch step {
        case TapAnimationStep.slowScale:
            let animation = CYLTabButtonScaleAnimation()
            animation.duration = 1.2
            return animation
        case TapAnimationStep.slowZoomIn:
            let animation = CYLTabButtonZoomInAnimation()
            animation.duration = 1.2
            return animation
        case TapAnimationStep.starFireworks:
            let animation = CYLTabButtonBounceAnimation()
            animation.playsFireworks = true
            animation.fireworksImage = UIImage(systemName: "star.fill", withConfiguration: UIImage.SymbolConfiguration(pointSize: 8))?
                .withTintColor(.systemYellow, renderingMode: .alwaysOriginal)
            return animation
        case TapAnimationStep.curlUp:
            let animation = CYLTabButtonFlipAnimation()
            animation.direction = 5
            animation.disablesDeselectAnimation = true
            return animation
        default:
            return nil
        }
    }

    static func tapAnimationStepName(_ step: Int) -> String {
        switch step {
        case TapAnimationStep.oneTabRotation: return CYLLocalizedString("旋转（仅当前 Tab：viewController.cyl_tabButtonAnimation）")
        case TapAnimationStep.defaultFrameAnimation: return CYLLocalizedString("逐帧 + 烟花（所有 Tab：cyl_defaultTabButtonAnimation）")
        case TapAnimationStep.slowScale: return CYLLocalizedString("慢速放大再缩小（CYLTabButtonScaleAnimation.duration = 1.2）")
        case TapAnimationStep.slowZoomIn: return CYLLocalizedString("慢速从小放大（CYLTabButtonZoomInAnimation.duration = 1.2）")
        case TapAnimationStep.starFireworks: return CYLLocalizedString("弹性 + 星星烟花（CYLTabButtonBounceAnimation.fireworksImage）")
        case TapAnimationStep.curlUp: return CYLLocalizedString("向上卷页，取消选中无动画（CYLTabButtonFlipAnimation.direction = 5）")
        default: return tapAnimationTypeName(CYLTabButtonTapAnimationType(rawValue: step) ?? .none)
        }
    }

    static func tapAnimationCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLTabButtonTapAnimationCell", symbol: "sparkles")
        cell.textLabel?.text = CYLLocalizedString("Tab 点击动画（issue #535）")
        cell.detailTextLabel?.text = String(format: CYLLocalizedString("点击切换 Tab 与 PlusButton 的点击动画，当前：%@"),
                                            tapAnimationStepName(currentTapAnimationStep(tabBarController)))
        return cell
    }

    /**
     * [EN] Moves to the next tap animation step (the other two ways are reset first) and plays it on the selected tab.
     * [CN] 切换到下一个点击动画步骤（先清除另外两种设置），并在当前选中的 Tab 上播放。
     */
    static func switchTapAnimation(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController else { return }
        let next = (currentTapAnimationStep(tabBarController) + 1) % TapAnimationStep.count
        setValue(NSNumber(value: next), tabBarController, tapAnimationStepKey)
        tabBarController.cyl_defaultTabButtonAnimation = nil
        for viewController in tabBarController.viewControllers ?? [] {
            viewController.cyl_tabButtonAnimation = nil
        }
        switch next {
        case TapAnimationStep.oneTabRotation:
            tabBarController.cyl_tabButtonTapAnimationType = .none
            tabBarController.selectedViewController?.cyl_tabButtonAnimation = CYLTabButtonRotationAnimation()
        case TapAnimationStep.defaultFrameAnimation:
            tabBarController.cyl_tabButtonTapAnimationType = .none
            let frameAnimation = CYLTabButtonFrameAnimation()
            frameAnimation.images = frameImages()
            frameAnimation.playsFireworks = true
            tabBarController.cyl_defaultTabButtonAnimation = frameAnimation
        case TapAnimationStep.slowScale...:
            tabBarController.cyl_tabButtonTapAnimationType = .none
            tabBarController.cyl_defaultTabButtonAnimation = configuredTapAnimation(next)
        default:
            tabBarController.cyl_tabButtonTapAnimationType = CYLTabButtonTapAnimationType(rawValue: next) ?? .none
        }
        if let selectedTabButton = tabBarController.selectedViewController?.cyl_tabButton {
            tabBarController.cyl_playTabButtonAnimation(for: selectedTabButton)
        }
    }

    // MARK: Long press and swipe (FIX: issue #535)

    enum InteractionKind {
        case longPress, swipe
    }

    static func isInteractionOn(_ tabBarController: CYLTabBarController?, _ kind: InteractionKind) -> Bool {
        switch kind {
        case .swipe: return tabBarController?.cyl_swipeToSwitchTabEnabled ?? false
        case .longPress: return tabBarController?.cyl_didLongPressControlBlock != nil
        }
    }

    /**
     * [EN] Long press: the demo block shows the name of the pressed button. Swipe: `cyl_swipeToSwitchTabEnabled`.
     * [CN] 长按：演示 block 弹出被长按按钮的名称。滑动：`cyl_swipeToSwitchTabEnabled`。
     */
    static func applyInteraction(_ tabBarController: CYLTabBarController?, _ kind: InteractionKind, on: Bool) {
        guard let tabBarController else { return }
        switch kind {
        case .swipe:
            tabBarController.cyl_swipeToSwitchTabEnabled = on
        case .longPress:
            tabBarController.cyl_didLongPressControlBlock = on ? { pressedTabBarController, control in
                let alert = UIAlertController(title: String(format: CYLLocalizedString("长按了「%@」"), control.cyl_tabBarItemDisplayName),
                                              message: nil, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: CYLLocalizedString("取消"), style: .cancel))
                pressedTabBarController.present(alert, animated: true)
            } : nil
        }
    }

    static func interactionSwitchCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?, _ kind: InteractionKind) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLInteractionSwitchCell")
        let demoSwitch = cell.accessoryView as? CYLInteractionDemoSwitch ?? CYLInteractionDemoSwitch()
        cell.accessoryView = demoSwitch
        demoSwitch.tabBarController = tabBarController
        demoSwitch.kind = kind
        demoSwitch.isOn = isInteractionOn(tabBarController, kind)
        let isSwipe = kind == .swipe
        cell.imageView?.image = UIImage(systemName: isSwipe ? "hand.draw" : "hand.tap")
        cell.textLabel?.text = isSwipe ? CYLLocalizedString("左右滑动切换 Tab（issue #535）") : CYLLocalizedString("长按 Tab（issue #535）")
        cell.detailTextLabel?.text = isSwipe ? CYLLocalizedString("打开开关后在页面上左右滑动，切换到下一个或上一个 Tab。")
            : CYLLocalizedString("打开开关后长按任意 Tab 或 PlusButton，会弹出该按钮的标识。")
        return cell
    }

    /**
     * [EN] A tap on the row flips its switch. [CN] 点击该行同样会拨动开关。
     */
    static func toggleInteraction(_ tableView: UITableView?, _ indexPath: IndexPath, _ tabBarController: CYLTabBarController?,
                                  _ kind: InteractionKind) {
        let on = !isInteractionOn(tabBarController, kind)
        applyInteraction(tabBarController, kind, on: on)
        (tableView?.cellForRow(at: indexPath)?.accessoryView as? UISwitch)?.setOn(on, animated: true)
    }
}

/**
 * [EN] The switch of the login state row: on means logged in. It sets `cyl_loggedIn` and follows
 *      `CYLTabBarLoginStateDidChangeNotification`, so it stays right after logging in elsewhere.
 * [CN] 登录状态行的开关：打开表示已登录。它会设置 `cyl_loggedIn`，并监听 `CYLTabBarLoginStateDidChangeNotification`，在其他地方登录后也保持正确。
 */
final class CYLLoginStateSwitch: UISwitch {
    weak var tabBarController: CYLTabBarController?
    weak var cell: UITableViewCell?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(valueDidChange), for: .valueChanged)
        NotificationCenter.default.addObserver(self, selector: #selector(loginStateDidChange),
                                               name: .CYLTabBarLoginStateDidChange, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    @objc private func valueDidChange() {
        tabBarController?.cyl_loggedIn = isOn
    }

    @objc private func loginStateDidChange() {
        let loggedIn = tabBarController?.cyl_loggedIn ?? false
        if isOn != loggedIn {
            setOn(loggedIn, animated: true)
        }
        if let cell {
            CYLSettingsDemo.configureLoginStateCell(cell, tabBarController)
        }
    }
}

/**
 * FIX: issue #91
 * [EN] A switch shows the plus button's touchable area as a translucent overlay, and a slider multiplies it from 1x to 3x
 *      (`touchableAreaScale`). Every style; only with a plus button.
 * [CN] 开关以半透明覆盖层显示 PlusButton 的可点击区域，滑块按 1 至 3 倍扩大（`touchableAreaScale`）。适用于所有样式；仅在有 PlusButton 时可用。
 */
final class CYLTouchableAreaCell: UITableViewCell {
    weak var tabBarController: CYLTabBarController?
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let scaleSlider = UISlider()
    private let overlaySwitch = UISwitch()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.numberOfLines = 0
        summaryLabel.font = .systemFont(ofSize: 14)
        // [EN] As the other rows' subtitles: a brighter gray in Dark Mode. [CN] 与其他行的副标题一致：深色模式下为更亮的灰色。
        summaryLabel.textColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.80, alpha: 1) : .secondaryLabel }
        summaryLabel.numberOfLines = 0
        scaleSlider.minimumValue = 1
        scaleSlider.maximumValue = 3
        scaleSlider.addTarget(self, action: #selector(scaleDidChange), for: .valueChanged)
        overlaySwitch.addTarget(self, action: #selector(overlayDidChange), for: .valueChanged)
        accessoryView = overlaySwitch
        let stackView = UIStackView(arrangedSubviews: [titleLabel, summaryLabel, scaleSlider])
        stackView.axis = .vertical
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        let margins = contentView.layoutMarginsGuide
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: margins.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: margins.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: margins.bottomAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    private var plusButton: CYLPlusButton? {
        guard let tabBarController, tabBarController.hasPlusButton() else { return nil }
        return CYLPlusButton(forOwner: tabBarController)
    }

    func reload() {
        let plusButton = plusButton
        titleLabel.text = CYLLocalizedString("PlusButton 点击范围（issue #91）")
        // [EN] Accessibility: the slider reads as the row's title, with the scale as its value. [CN] 无障碍：滑块读作本行标题，倍数作为其值。
        scaleSlider.accessibilityLabel = titleLabel.text
        scaleSlider.isEnabled = plusButton != nil
        overlaySwitch.isEnabled = plusButton != nil
        guard let plusButton else {
            summaryLabel.text = CYLLocalizedString("当前 TabBar 没有 PlusButton")
            scaleSlider.value = 1
            overlaySwitch.isOn = false
            return
        }
        scaleSlider.value = Float(plusButton.touchableAreaScale)
        overlaySwitch.isOn = plusButton.showsTouchableArea
        let scaleText = String(format: "%.1f", plusButton.touchableAreaScale)
        scaleSlider.accessibilityValue = scaleText + "×"
        summaryLabel.text = String(format: CYLLocalizedString("打开开关以半透明红色显示可点击区域，关闭恢复正常；拖动滑块按倍数扩大点击范围，当前：%@ 倍"), scaleText)
    }

    @objc private func scaleDidChange() {
        // [EN] Steps of 0.1. [CN] 以 0.1 为步长。
        plusButton?.touchableAreaScale = (CGFloat(scaleSlider.value) * 10).rounded() / 10
        reload()
    }

    @objc private func overlayDidChange() {
        plusButton?.showsTouchableArea = overlaySwitch.isOn
        reload()
    }
}

/**
 * [EN] The switch of the long press and swipe rows. [CN] 长按与滑动两行的开关。
 */
final class CYLInteractionDemoSwitch: UISwitch {
    weak var tabBarController: CYLTabBarController?
    var kind = CYLSettingsDemo.InteractionKind.longPress

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(valueDidChange), for: .valueChanged)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    @objc private func valueDidChange() {
        CYLSettingsDemo.applyInteraction(tabBarController, kind, on: isOn)
    }
}
