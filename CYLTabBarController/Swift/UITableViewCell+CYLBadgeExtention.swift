//
//  UITableViewCell+CYLBadgeExtention.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Row height that leaves room around the icon for its badge (the Objective-C header has a macro of the same name).
 * [CN] 行高：为图标四周的角标留出空间（Objective-C 头文件中有同名宏）。
 */
public let CYLBadgeRowHeight: CGFloat = 60

/**
 * [EN] One badge sample: its title, the core API behind it (shown after the title), the badge value and what the row
 *      changes. Translated from Objective-C (docs/Swift-Migration.md, step 34).
 * [CN] 一个角标样例：标题、实现它的核心 API（显示在标题后）、角标的值以及该行修改的内容。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 34 步）。
 */
struct CYLBadgeSample {

    /**
     * [EN] An animation built with a `CAAnimation+CYLBadgeExtention` factory (not by an animation type).
     * [CN] 由 `CAAnimation+CYLBadgeExtention` 工厂方法创建的动画（不是通过动画类型）。
     */
    enum FactoryAnimation {
        case rotationForever, springForever, shakeThreeTimes, bounceThreeTimes, scaleThreeTimes, blinkThreeTimes, flipTwice, springOnce

        /**
         * [EN] The animation, sized for `badge`. [CN] 按 `badge` 的尺寸创建的动画。
         */
        func animation(for badge: UIView) -> CAAnimation {
            let size = badge.bounds.size
            switch self {
            case .rotationForever:
                return CAAnimation.cyl_rotationAnimation(withDuration: 2, degree: 2 * .pi, direction: .Z, repeatCount: .greatestFiniteMagnitude)
            case .springForever:
                let animation = CAAnimation.cyl_springAnimation(forDuration: 1)
                animation.repeatCount = .greatestFiniteMagnitude
                return animation
            case .shakeThreeTimes: return CAAnimation.cyl_shakeAnimationRepeatTimes(3, duration: 1, offset: size.width / 4)
            case .bounceThreeTimes: return CAAnimation.cyl_bounceRepeatTimes(3, duration: 1, offset: size.height / 4)
            case .scaleThreeTimes: return CAAnimation.cyl_scale(fromScale: 1.4, toScale: 0.6, duration: 1, repeatTimes: 3)
            case .blinkThreeTimes: return CAAnimation.cyl_opacityTimesAnimationRepeatTimes(3, duration: 0.8)
            case .flipTwice: return CAAnimation.cyl_rotationAnimation(withDuration: 1, degree: .pi, direction: .Y, repeatCount: 2)
            case .springOnce: return CAAnimation.cyl_springAnimation(forDuration: 0.6)
            }
        }
    }

    /**
     * [EN] A corner other than the default top-right one. [CN] 默认右上角以外的角。
     */
    enum Position {
        case topLeft, bottomLeft, bottomRight

        /**
         * [EN] The center offset that moves the badge from the icon's top-right corner to this corner.
         * [CN] 把角标从图标右上角移到该角的中心偏移。
         */
        var centerOffset: CGPoint {
            let toLeft = -(CYLBadgeSample.iconSide + 4)
            switch self {
            case .topLeft: return CGPoint(x: toLeft, y: 0)
            case .bottomLeft: return CGPoint(x: toLeft, y: CYLBadgeSample.iconSide)
            case .bottomRight: return CGPoint(x: 0, y: CYLBadgeSample.iconSide)
            }
        }
    }

    var title: String
    var api = ""
    var value = ""
    var animationType = CYLBadgeAnimationType.none
    var factoryAnimation: FactoryAnimation?
    var maximum: Int?
    var customColors = false
    var customFont = false
    var border = false
    var dynamicBorder = false
    var radius: CGFloat?
    var margin: CGFloat?
    var cornerRadius: CGFloat?
    var respectsReduceMotion = false
    var position: Position?

    static let iconSide: CGFloat = 30
    static let animationKey = "cyl.badge.helper"
    static let cellIdentifier = "CYLBadgeHelperCell"

    private static var cachedSamples: [CYLBadgeSample] = []
    private static var cachedLanguage: String?

    /**
     * [EN] Every badge style and animation, in display order: top-right and animated (forever, a few times, once); top-right
     *      and not animated (styles, appearance options); the other corners. Rebuilt when the language changes.
     * [CN] 所有角标样式与动画，按显示顺序：右上角带动画（无限循环、重复几次、播放一次）；右上角无动画（样式、外观选项）；其他角。语言变化时重建。
     */
    static var all: [CYLBadgeSample] {
        let language = CYLLocalizationLanguage()
        if cachedSamples.isEmpty || cachedLanguage != language {
            cachedLanguage = language
            cachedSamples = makeAll()
        }
        return cachedSamples
    }

    private static func makeAll() -> [CYLBadgeSample] {
        func title(_ key: String) -> String { CYLLocalizedString(key) }
        return [
            // [EN] 1.1 Animations that repeat forever: `CYLBadgeAnimationType`. [CN] 1.1 无限循环的动画：`CYLBadgeAnimationType`。
            CYLBadgeSample(title: title("Scale (forever)"), api: "CYLBadgeAnimationTypeScale", value: "3", animationType: .scale),
            CYLBadgeSample(title: title("Shake (forever)"), api: "CYLBadgeAnimationTypeShake", value: "3", animationType: .shake),
            CYLBadgeSample(title: title("Bounce (forever)"), api: "CYLBadgeAnimationTypeBounce", value: "3", animationType: .bounce),
            CYLBadgeSample(title: title("Breathe (forever)"), api: "CYLBadgeAnimationTypeBreathe", animationType: .breathe),
            CYLBadgeSample(title: title("Shake, stops with Reduce Motion"), api: "cyl_badgeRespectsReduceMotion", value: "3",
                           animationType: .shake, respectsReduceMotion: true),
            // [EN] 1.2 Forever, by the `CAAnimation+CYLBadgeExtention` factories. [CN] 1.2 无限循环，由 `CAAnimation+CYLBadgeExtention` 工厂方法创建。
            CYLBadgeSample(title: title("Rotation (forever)"), api: "cyl_rotationAnimationWithDuration:", value: "new", factoryAnimation: .rotationForever),
            CYLBadgeSample(title: title("Spring (forever)"), api: "cyl_springAnimationForDuration:", value: "3", factoryAnimation: .springForever),
            // [EN] 1.3 Animations that repeat a few times. [CN] 1.3 重复几次的动画。
            CYLBadgeSample(title: title("Shake ×3 (cyl_shakeAnimationRepeatTimes)"), value: "3", factoryAnimation: .shakeThreeTimes),
            CYLBadgeSample(title: title("Bounce ×3 (cyl_bounceAnimationRepeatTimes)"), value: "3", factoryAnimation: .bounceThreeTimes),
            CYLBadgeSample(title: title("Scale ×3"), api: "cyl_scaleAnimationFromScale:", value: "3", factoryAnimation: .scaleThreeTimes),
            CYLBadgeSample(title: title("Blink ×3"), api: "cyl_opacityTimesAnimationRepeatTimes:", factoryAnimation: .blinkThreeTimes),
            CYLBadgeSample(title: title("Flip ×2"), api: "cyl_rotationAnimationWithDuration:", value: "3", factoryAnimation: .flipTwice),
            // [EN] 1.4 Animations that play once. [CN] 1.4 只播放一次的动画。
            CYLBadgeSample(title: title("Left to right once"), api: "CYLBadgeAnimationTypeLeftRightOnce", value: "3", animationType: .leftRightOnce),
            CYLBadgeSample(title: title("Right to left once"), api: "CYLBadgeAnimationTypeRightLeftOnce", value: "3", animationType: .rightLeftOnce),
            CYLBadgeSample(title: title("Fade in once"), api: "CYLBadgeAnimationTypeFadeInOnce", value: "3", animationType: .fadeInOnce),
            CYLBadgeSample(title: title("Rolling once"), api: "CYLBadgeAnimationTypeRollingOnce", value: "3", animationType: .rollingOnce),
            CYLBadgeSample(title: title("Scale once"), api: "CYLBadgeAnimationTypeScaleOnce", value: "3", animationType: .scaleOnce),
            CYLBadgeSample(title: title("Spring once"), api: "cyl_springAnimationForDuration:", value: "3", factoryAnimation: .springOnce),
            // [EN] 2.1 Styles, no animation. [CN] 2.1 样式，无动画。
            CYLBadgeSample(title: title("Red dot"), api: "cyl_showBadge"),
            CYLBadgeSample(title: title("Number"), api: "cyl_showBadgeValue:", value: "8"),
            CYLBadgeSample(title: title("Number above maximum"), api: "cyl_badgeMaximumBadgeNumber", value: "100"),
            CYLBadgeSample(title: title("Custom maximum (9)"), api: "cyl_badgeMaximumBadgeNumber", value: "10", maximum: 9),
            CYLBadgeSample(title: title("New"), api: "cyl_showBadgeValue:@\"new\"", value: "new"),
            CYLBadgeSample(title: title("NEW"), api: "cyl_showBadgeValue:@\"NEW\"", value: "NEW"),
            CYLBadgeSample(title: title("Other text"), api: "cyl_showBadgeValue:", value: title("hot")),
            // [EN] 2.2 Appearance, no animation. [CN] 2.2 外观，无动画。
            CYLBadgeSample(title: title("Custom colors"), api: "cyl_badgeBackgroundColor / cyl_badgeTextColor", value: "5", customColors: true),
            CYLBadgeSample(title: title("Custom font"), api: "cyl_badgeFont", value: "5", customFont: true),
            CYLBadgeSample(title: title("Border"), api: "cyl_badgeBorderColor / cyl_badgeBorderWidth", value: "5", border: true),
            CYLBadgeSample(title: title("Border following Dark Mode"), api: "cyl_badgeBorderColor", value: "5", dynamicBorder: true),
            CYLBadgeSample(title: title("Red dot radius"), api: "cyl_badgeRadius", radius: 6),
            CYLBadgeSample(title: title("Margin"), api: "cyl_badgeMargin", value: "5", margin: 14),
            CYLBadgeSample(title: title("Corner radius"), api: "cyl_badgeCornerRadius", value: "new", cornerRadius: 3),
            // [EN] 3. Other corners. [CN] 3. 其他角。
            CYLBadgeSample(title: title("Top left"), api: "cyl_badgeCenterOffset", value: "5", position: .topLeft),
            CYLBadgeSample(title: title("Bottom left"), api: "cyl_badgeCenterOffset", value: "5", position: .bottomLeft),
            CYLBadgeSample(title: title("Bottom right"), api: "cyl_badgeCenterOffset", value: "5", position: .bottomRight),
        ]
    }

    static func sample(forRow row: Int) -> CYLBadgeSample {
        all[max(row, 0) % all.count]
    }

    /**
     * [EN] The sample icon drawn at 30 x 30 pt with rounded corners, which leaves 15 pt above and below it in a 60 pt row:
     *      the badge sits on a corner of the icon and needs that room, animations included.
     * [CN] 以 30 x 30 pt 绘制的圆角示例图标，在 60 pt 的行中上下各留 15 pt：角标位于图标的一角，需要这些空间（包括动画）。
     */
    static let icon: UIImage = {
        let image = UIImage(named: "cyl_badge_sample_icon", in: CYLResourceBundle(), compatibleWith: nil)
        let rect = CGRect(x: 0, y: 0, width: iconSide, height: iconSide)
        return UIGraphicsImageRenderer(size: rect.size).image { _ in
            UIBezierPath(roundedRect: rect, cornerRadius: 6).addClip()
            image?.draw(in: rect)
        }
    }()

    /**
     * [EN] A border color that follows Dark Mode: black in light mode, white in dark mode. [CN] 跟随深色模式的边框颜色：浅色为黑，深色为白。
     */
    static let dynamicBorderColor = UIColor { $0.userInterfaceStyle == .dark ? .white : .black }

    /**
     * [EN] Subtitles: `secondaryLabel` in light mode; a brighter gray in Dark Mode, where it is hard to read on black.
     * [CN] 副标题：浅色模式为 `secondaryLabel`；深色模式为更亮的灰色（`secondaryLabel` 在黑色背景上不易辨认）。
     */
    static let subtitleColor = UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 0.80, alpha: 1) : .secondaryLabel }

    /**
     * [EN] Whether `color` is one of the fixed default text colors (black or gray), which do not adapt to Dark Mode.
     * [CN] `color` 是否为固定的默认文字颜色（黑色或灰色），这些颜色不会适配深色模式。
     */
    static func isFixedDefaultTextColor(_ color: UIColor?) -> Bool {
        guard let color else { return true }
        return [UIColor.black, .gray, .darkGray, .lightGray, .darkText].contains(color)
    }
}

/**
 * [EN] `UITableViewCell (CYLBadgeExtention)`: badge samples shared by all the example apps, every badge style and animation,
 *      one per row. Selectors kept.
 * [CN] `UITableViewCell (CYLBadgeExtention)`：所有示例工程共用的角标样例，每行一种角标样式或动画。selector 不变。
 */
extension UITableViewCell {

    /**
     * [EN] Shows the icon in the cell and a badge on it; style and animation change with the row.
     * [CN] 在 cell 上显示图标及其角标，样式和动画随行号变化。
     */
    @objc(cyl_showBadgeForRow:)
    public func cyl_showBadge(forRow row: Int) {
        let sample = CYLBadgeSample.sample(forRow: row)
        // [EN] A long sample title is cut in the middle, so the API name at its end stays readable.
        // [CN] 过长的样例标题从中间截断，保证末尾的 API 名称可读。
        detailTextLabel?.lineBreakMode = .byTruncatingMiddle
        guard let iconView: UIView = imageView else { return }
        imageView?.image = CYLBadgeSample.icon
        iconView.clipsToBounds = false
        // [EN] Lay out the icon now, so the badge is created right away and a factory animation can be added to it.
        // [CN] 立即布局图标，角标随即创建，才能给它添加工厂动画。
        layoutIfNeeded()
        // [EN] Cells are reused: clear the badge, stop the previous row's animation, and drop its options so they follow
        //      `CYLBadgeAppearance` again (#425); then set only what this row changes, before showing the badge.
        // [CN] cell 会复用：清除角标、停止上一行的动画，并丢弃其选项，使之重新跟随 `CYLBadgeAppearance`（#425）；然后只设置本行修改的内容，
        //      再显示角标。
        iconView.cyl_badge?.layer.removeAllAnimations()
        iconView.cyl_clearBadge()
        iconView.cyl_resetBadgeAppearance()
        if sample.customColors {
            iconView.cyl_badgeBackgroundColor = .purple
            iconView.cyl_badgeTextColor = .yellow
        }
        if sample.customFont {
            iconView.cyl_badgeFont = .italicSystemFont(ofSize: 12)
        }
        if sample.border || sample.dynamicBorder {
            iconView.cyl_badgeBorderColor = sample.border ? .white : CYLBadgeSample.dynamicBorderColor
            iconView.cyl_badgeBorderWidth = 2
        }
        if let position = sample.position {
            iconView.cyl_badgeCenterOffset = position.centerOffset
        }
        if let radius = sample.radius {
            iconView.cyl_badgeRadius = radius
        }
        if let margin = sample.margin {
            iconView.cyl_badgeMargin = margin
        }
        if let cornerRadius = sample.cornerRadius {
            iconView.cyl_badgeCornerRadius = cornerRadius
        }
        if let maximum = sample.maximum {
            iconView.cyl_badgeMaximumBadgeNumber = maximum
        }
        iconView.cyl_badgeRespectsReduceMotion = sample.respectsReduceMotion
        iconView.cyl_showBadgeValue(sample.value, animationType: sample.animationType)
        if let badge = iconView.cyl_badge, let factoryAnimation = sample.factoryAnimation {
            badge.layer.add(factoryAnimation.animation(for: badge), forKey: CYLBadgeSample.animationKey)
        }
    }

    /**
     * [EN] Title of the badge sample on `row`, followed by the core API that produces it, e.g. "20. Number
     *      (cyl_showBadgeValue:)"; a title that already names its API is left as it is.
     * [CN] 第 `row` 行角标样例的标题，后面附上实现该效果的核心 API，例如“20. 数字 (cyl_showBadgeValue:)”；标题中已含 API 名称时不再附加。
     */
    @objc(cyl_badgeTitleForRow:)
    public class func cyl_badgeTitle(forRow row: Int) -> String {
        let sample = CYLBadgeSample.sample(forRow: row)
        let title = sample.api.isEmpty || sample.title.contains(sample.api) ? sample.title : "\(sample.title) (\(sample.api))"
        return "\(row + 1). \(title)"
    }

    /**
     * [EN] Number of different badge samples. [CN] 角标样例的种数。
     */
    @objc(cyl_badgeStyleCount)
    public class func cyl_badgeStyleCount() -> Int {
        CYLBadgeSample.all.count
    }

    /**
     * [EN] Lets the title and the subtitle wrap onto as many lines as they need, never truncated. Also Dark Mode and
     *      contrast: fixed black or gray text becomes the semantic label colors (a custom color is kept); the title is a
     *      semibold 16 pt and the subtitle 14 pt, both following Dynamic Type. Use it with
     *      `+cyl_setUpAutomaticRowHeightForTableView:`.
     * [CN] 标题与副标题按需换行，不会截断。同时处理深色模式与对比度：固定的黑色或灰色文字改为语义化的标签颜色（自定义颜色保留）；标题为
     *      16 pt 半粗体、副标题为 14 pt，均跟随动态字体。与 `+cyl_setUpAutomaticRowHeightForTableView:` 一起使用。
     */
    @objc(cyl_wrapsTextLabels)
    public func cyl_wrapsTextLabels() {
        for label in [textLabel, detailTextLabel] {
            label?.numberOfLines = 0
            label?.lineBreakMode = .byWordWrapping
            label?.adjustsFontForContentSizeCategory = true
        }
        if CYLBadgeSample.isFixedDefaultTextColor(textLabel?.textColor) {
            textLabel?.textColor = .label
        }
        if CYLBadgeSample.isFixedDefaultTextColor(detailTextLabel?.textColor) || detailTextLabel?.textColor == .secondaryLabel {
            detailTextLabel?.textColor = CYLBadgeSample.subtitleColor
        }
        textLabel?.font = UIFontMetrics(forTextStyle: .subheadline).scaledFont(for: .systemFont(ofSize: 16, weight: .semibold))
        detailTextLabel?.font = UIFontMetrics(forTextStyle: .footnote).scaledFont(for: .systemFont(ofSize: 14))
    }

    /**
     * [EN] Rows as high as their wrapped text (`-cyl_wrapsTextLabels`), estimated at `CYLBadgeRowHeight`.
     * [CN] 行高随换行后的文字变化（`-cyl_wrapsTextLabels`），预估行高为 `CYLBadgeRowHeight`。
     */
    @objc(cyl_setUpAutomaticRowHeightForTableView:)
    public class func cyl_setUpAutomaticRowHeight(for tableView: UITableView) {
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = CYLBadgeRowHeight
    }
}

extension UIViewController {

    /**
     * [EN] Shows `value` ("" for a red dot) on `navigationItem.rightBarButtonItem`; when there is none, a bell button with no
     *      action is added first. Declared in UITableViewCell+CYLBadgeExtention.h, since its signature has an Objective-C enum
     *      of this module.
     * [CN] 在 `navigationItem.rightBarButtonItem` 上显示 `value`（"" 为红点）；没有右侧按钮时先添加一个没有点击事件的铃铛按钮。由于签名中含
     *      本模块的 Objective-C 枚举，声明位于 UITableViewCell+CYLBadgeExtention.h。
     */
    @objc(cyl_showNavigationBadgeValue:animationType:backgroundColor:)
    func cyl_showNavigationBadgeValue(_ value: String, animationType: CYLBadgeAnimationType, backgroundColor: UIColor?) -> UIBarButtonItem {
        let item = navigationItem.rightBarButtonItem ?? {
            let item = UIBarButtonItem(image: UIImage(systemName: "bell"), style: .plain, target: nil, action: nil)
            navigationItem.rightBarButtonItem = item
            return item
        }()
        item.cyl_showBadgeValue(value, animationType: animationType, backgroundColor: backgroundColor)
        return item
    }

    /**
     * [EN] Adds a `CYLBadgeHelperTableViewController` as a child that fills this view controller's view.
     * [CN] 添加一个铺满当前视图的 `CYLBadgeHelperTableViewController` 子控制器。
     */
    @objc(cyl_addBadgeHelperTable)
    public func cyl_addBadgeHelperTable() {
        let badgeHelper = CYLBadgeHelperTableViewController(style: .plain)
        addChild(badgeHelper)
        badgeHelper.view.frame = view.bounds
        badgeHelper.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(badgeHelper.view)
        badgeHelper.didMove(toParent: self)
    }
}

/**
 * [EN] Table of every badge sample, one per row: section 0 holds the settings rows (`CYLSettingsSection`), the samples are
 *      in section 1. A tap on a sample clears its badge, calls `didSelectRowHandler`, and simulates a memory warning
 *      (`+[CYLTabBarController cyl_simulateMemoryWarning]`, issues #426 and #428: the tab icons keep their speed and the
 *      badges stay).
 * [CN] 列出全部角标样例的列表，每行一个：第 0 组为设置行（`CYLSettingsSection`），样例在第 1 组。点击样例会清除其角标、调用
 *      `didSelectRowHandler`，并模拟内存警告（`+[CYLTabBarController cyl_simulateMemoryWarning]`，issue #426、#428：Tab 图标保持速度，角标保留）。
 */
@objc(CYLBadgeHelperTableViewController)
open class CYLBadgeHelperTableViewController: UITableViewController {

    /**
     * [EN] Called after a badge row is tapped (its badge cleared), e.g. to push a page; the row is `indexPath.row`.
     * [CN] 点击角标行（并清除角标）后调用，例如用于 push 新页面；行号为 `indexPath.row`。
     */
    @objc open var didSelectRowHandler: ((IndexPath) -> Void)?

    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = CYLLocalizedString("Badge")
        UITableViewCell.cyl_setUpAutomaticRowHeight(for: tableView)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: CYLBadgeSample.cellIdentifier)
    }

    override open func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == Int(CYLSettingsSection) ? cyl_settingsRowCount() : UITableViewCell.cyl_badgeStyleCount()
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == Int(CYLSettingsSection) {
            return cyl_settingsCell(for: tableView, at: indexPath)
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: CYLBadgeSample.cellIdentifier, for: indexPath)
        cell.textLabel?.text = UITableViewCell.cyl_badgeTitle(forRow: indexPath.row)
        cell.cyl_wrapsTextLabels()
        cell.cyl_showBadge(forRow: indexPath.row)
        return cell
    }

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == Int(CYLSettingsSection) {
            cyl_didSelectSettingsRow(at: indexPath, in: tableView)
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        (tableView.cellForRow(at: indexPath)?.imageView as UIView?)?.cyl_clearBadge()
        didSelectRowHandler?(indexPath)
        CYLTabBarController.cyl_simulateMemoryWarning()
    }
}
