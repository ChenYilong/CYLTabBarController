//
//  CYLSettingsDemoRows+Interaction.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The demo rows of the settings section, part 3: tap sound and haptics, long press and double tap timing, switching to
 *      the adjacent tab, the CYLUtils helpers, minimizing on scroll and the scroll hiding simulations row. Translated from
 *      Objective-C (docs/Swift-Migration.md, step 33); internal.
 * [CN] 设置分组的演示行，第 3 部分：点击声音与触感、长按与双击时间、切换到相邻 Tab、CYLUtils 工具方法、滚动时缩小以及滚动隐藏模拟行。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 33 步）；仅供内部使用。
 */
extension CYLSettingsDemo {

    /**
     * [EN] A plain subtitle cell with a symbol, reused by identifier. [CN] 带符号的普通副标题 cell，按标识复用。
     */
    static func plainCell(_ tableView: UITableView, _ identifier: String, symbol: String) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: identifier) {
            return cell
        }
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: identifier)
        cell.imageView?.image = UIImage(systemName: symbol)
        return cell
    }

    // MARK: Tap sound and haptic feedback (FIX: issue #535)

    /**
     * [EN] The steps of the tap feedback row: off, the default click, a custom sound file, haptics of three strengths, then
     *      sound and haptic together.
     * [CN] 点击反馈行的步骤：关闭、默认点击声、自定义音频文件、三种强度的触感反馈、声音与触感同时开启。
     */
    enum TapFeedbackStep: Int, CaseIterable {
        case off, defaultSound, customSound, lightHaptic, mediumHaptic, heavyHaptic, soundAndHaptic

        var name: String {
            switch self {
            case .off: return CYLLocalizedString("无")
            case .defaultSound: return CYLLocalizedString("默认点击声")
            case .customSound: return CYLLocalizedString("自定义音频文件（cyl_tabButtonTapSoundURL）")
            case .lightHaptic: return CYLLocalizedString("轻触感反馈")
            case .mediumHaptic: return CYLLocalizedString("中等触感反馈")
            case .heavyHaptic: return CYLLocalizedString("重触感反馈")
            case .soundAndHaptic: return CYLLocalizedString("点击声 + 触感反馈")
            }
        }
    }

    static let tapFeedbackStepKey = CYLUtilsKeys.key("cyl_demoTapFeedbackStep")

    /**
     * [EN] A system sound file for the custom sound step, nil when the system does not have it. [CN] 自定义声音步骤使用的系统音频文件，系统中没有时为 nil。
     */
    static var customTapSoundURL: URL? {
        let path = "/System/Library/Audio/UISounds/Tock.caf"
        return FileManager.default.fileExists(atPath: path) ? URL(fileURLWithPath: path) : nil
    }

    static func tapFeedbackStep(_ tabBarController: CYLTabBarController?) -> TapFeedbackStep {
        tabBarController.flatMap { flag($0, tapFeedbackStepKey) }.flatMap(TapFeedbackStep.init(rawValue:)) ?? .off
    }

    static func tapFeedbackCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let cell = plainCell(tableView, "CYLTapFeedbackCell", symbol: "speaker.wave.2")
        cell.textLabel?.text = CYLLocalizedString("Tab 点击声音与触感反馈（issue #535）")
        cell.detailTextLabel?.text = String(format: CYLLocalizedString("点击切换，然后点击任意 Tab 或 PlusButton 试听。触感反馈只在真机上振动。当前：%@"),
                                            tapFeedbackStep(tabBarController).name)
        return cell
    }

    /**
     * [EN] Moves to the next step and plays it once at once. [CN] 切换到下一步，并立即播放一次。
     */
    static func switchTapFeedback(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController else { return }
        let step = TapFeedbackStep(rawValue: (tapFeedbackStep(tabBarController).rawValue + 1) % TapFeedbackStep.allCases.count) ?? .off
        setValue(NSNumber(value: step.rawValue), tabBarController, tapFeedbackStepKey)
        tabBarController.cyl_tabButtonTapSoundEnabled = [.defaultSound, .customSound, .soundAndHaptic].contains(step)
        tabBarController.cyl_tabButtonTapSoundURL = step == .customSound ? customTapSoundURL : nil
        switch step {
        case .lightHaptic: tabBarController.cyl_tabButtonHapticFeedbackStyle = .light
        case .heavyHaptic: tabBarController.cyl_tabButtonHapticFeedbackStyle = .heavy
        default: tabBarController.cyl_tabButtonHapticFeedbackStyle = .medium
        }
        tabBarController.cyl_tabButtonHapticFeedbackEnabled = step.rawValue >= TapFeedbackStep.lightHaptic.rawValue
        tabBarController.cyl_playTabButtonTapFeedback()
    }

    // MARK: Long press and double tap timing (FIX: issue #535 / #152)

    /**
     * [EN] The long press durations and double tap intervals the row cycles through, the default first.
     * [CN] 该行依次切换的长按时长与双击间隔，第一个为默认值。
     */
    static let longPressDurations: [TimeInterval] = [0.5, 1.0, 0.25]
    static let doubleTapIntervals: [TimeInterval] = [0.35, 0.6, 0.25]

    static func gestureTimingCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let cell = plainCell(tableView, "CYLGestureTimingCell", symbol: "timer")
        cell.textLabel?.text = CYLLocalizedString("长按时长与双击间隔（issue #535 / #152）")
        // [EN] Both long press properties are read, to show they are one value. [CN] 读取两个长按属性，说明它们是同一个值。
        cell.detailTextLabel?.text = String(format: CYLLocalizedString("点击切换。cyl_tabBarItemLongPressDuration：%@ 秒，cyl_tabButtonLongPressMinimumDuration：%@ 秒，cyl_tabBarItemDoubleTapInterval：%@ 秒"),
                                            NSNumber(value: tabBarController?.cyl_tabBarItemLongPressDuration ?? 0),
                                            NSNumber(value: tabBarController?.cyl_tabButtonLongPressMinimumDuration ?? 0),
                                            NSNumber(value: tabBarController?.cyl_tabBarItemDoubleTapInterval ?? 0))
        return cell
    }

    /**
     * [EN] The next pair of values; the two long press setters take turns, since they set one value.
     * [CN] 切换到下一组值；两个长按 setter 轮流使用，因为它们设置的是同一个值。
     */
    static func switchGestureTiming(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController else { return }
        let current = longPressDurations.firstIndex { abs($0 - tabBarController.cyl_tabBarItemLongPressDuration) < 0.001 } ?? 0
        let next = (current + 1) % longPressDurations.count
        if next % 2 == 0 {
            tabBarController.cyl_tabBarItemLongPressDuration = longPressDurations[next]
        } else {
            tabBarController.cyl_tabButtonLongPressMinimumDuration = longPressDurations[next]
        }
        tabBarController.cyl_tabBarItemDoubleTapInterval = doubleTapIntervals[next]
    }

    // MARK: Switch to the adjacent tab (FIX: issue #535)

    static let switchAdjacentResultKey = CYLUtilsKeys.key("cyl_demoSwitchAdjacentResult")

    static func switchAdjacentTabCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let identifier = "CYLSwitchAdjacentTabCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) as? CYLSwitchAdjacentTabCell
            ?? CYLSwitchAdjacentTabCell(style: .subtitle, reuseIdentifier: identifier)
        cell.tabBarController = tabBarController
        cell.reload()
        return cell
    }

    // MARK: CYLUtils helpers (FIX: issue #535)

    static let utilsHelpersResultKey = CYLUtilsKeys.key("cyl_demoUtilsHelpersResult")
    static let weakObjectKey = CYLUtilsKeys.key("cyl_demoWeakObject")

    static func utilsHelpersCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let cell = plainCell(tableView, "CYLUtilsHelpersCell", symbol: "wrench.and.screwdriver")
        let result = tabBarController.flatMap { objc_getAssociatedObject($0, utilsHelpersResultKey) as? String }
        cell.textLabel?.text = CYLLocalizedString("CYLUtils 弱引用关联对象与查找按钮（issue #535）")
        cell.detailTextLabel?.text = result ?? CYLLocalizedString("点击运行：cyl_setWeakAssociatedObject:forKey: 在对象释放后返回 nil；cyl_nearestControlBelowView: 从选中 Tab 的图标找到它的按钮。")
        return cell
    }

    /**
     * [EN] Runs the two CYLUtils helpers and keeps their results for the row: a weak associated object is there while its
     *      object lives and nil after it is released; from the deepest view inside the selected tab button,
     *      `-cyl_nearestControlBelowView:` finds that button.
     * [CN] 运行两个 CYLUtils 工具方法并保存结果供该行显示：弱引用关联对象在对象存活时存在，释放后为 nil；从选中 Tab 按钮内最深的视图出发，
     *      `-cyl_nearestControlBelowView:` 找到该按钮。
     */
    static func runUtilsHelpers(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController else { return }
        var whileAlive = false
        autoreleasepool {
            let object = NSObject()
            tabBarController.cyl_setWeakAssociatedObject(object, forKey: weakObjectKey)
            whileAlive = tabBarController.cyl_weakAssociatedObject(forKey: weakObjectKey) as AnyObject? === object
        }
        let afterRelease = tabBarController.cyl_weakAssociatedObject(forKey: weakObjectKey) == nil
        let tabButton = tabBarController.selectedViewController?.cyl_tabButton
        // [EN] The deepest first subview, e.g. the icon's image view. [CN] 最深的第一个子视图，例如图标的图片视图。
        var innerView: UIView? = tabButton
        while let first = innerView?.subviews.first {
            innerView = first
        }
        let foundControl = innerView?.cyl_nearestControl(below: tabBarController.tabBar)
        let found: String
        if tabButton == nil {
            found = "-"
        } else if foundControl === tabButton {
            found = "YES"
        } else {
            found = foundControl.map { NSStringFromClass(type(of: $0)) } ?? "nil"
        }
        let result = String(format: CYLLocalizedString("弱引用：存活时取到 %@，释放后为 nil %@。从 %@ 找到选中的 Tab 按钮：%@"),
                            whileAlive ? "YES" : "NO", afterRelease ? "YES" : "NO",
                            innerView.map { NSStringFromClass(type(of: $0)) } ?? "-", found)
        objc_setAssociatedObject(tabBarController, utilsHelpersResultKey, result, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    // MARK: Minimize / hide the tab bar on scroll (issue #13)

    /**
     * [EN] The name of a CYLTabBarMinimizeBehavior, as in code. [CN] CYLTabBarMinimizeBehavior 的名称，与代码中一致。
     */
    static func minimizeBehaviorName(_ behavior: CYLTabBarMinimizeBehavior) -> String {
        switch behavior {
        case .never: return "Never"
        case .onScrollDown: return "OnScrollDown"
        case .onScrollUp: return "OnScrollUp"
        default: return "Automatic"
        }
    }

    static func tabBarMinimizeCell(_ tableView: UITableView, _ tabBarController: CYLTabBarController?) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLTabBarMinimizeCell", symbol: "arrow.up.and.down")
        let behaviorName = tabBarController.map { minimizeBehaviorName($0.cyl_tabBarMinimizeBehavior) } ?? "-"
        cell.textLabel?.text = CYLLocalizedString("滚动时缩小 / 隐藏 TabBar（issue #13）")
        cell.detailTextLabel?.text = String(format: CYLLocalizedString("点击切换滚动行为。当前：%@。液态玻璃（iOS 26+）由系统缩小 TabBar；扁平样式与经典样式（iOS 25 及以前、iOS 26 UI 兼容模式）隐藏 TabBar。"),
                                            behaviorName)
        return cell
    }

    /**
     * [EN] Sets the next behavior: Automatic → OnScrollDown → OnScrollUp → Never → Automatic.
     * [CN] 切换到下一个行为：Automatic → OnScrollDown → OnScrollUp → Never → Automatic。
     */
    static func switchTabBarMinimizeBehavior(_ tabBarController: CYLTabBarController?) {
        guard let tabBarController else { return }
        switch tabBarController.cyl_tabBarMinimizeBehavior {
        case .automatic: tabBarController.cyl_tabBarMinimizeBehavior = .onScrollDown
        case .onScrollDown: tabBarController.cyl_tabBarMinimizeBehavior = .onScrollUp
        case .onScrollUp: tabBarController.cyl_tabBarMinimizeBehavior = .never
        default: tabBarController.cyl_tabBarMinimizeBehavior = .automatic
        }
    }

    /**
     * [EN] Issue #13: the settings row that lists the scroll hiding simulations. [CN] issue #13：列出滚动隐藏模拟的设置行。
     */
    static func scrollHideSimulationMenuCell(_ tableView: UITableView) -> UITableViewCell {
        let cell = subtitleCell(tableView, "CYLScrollHideSimulationMenuCell", symbol: "exclamationmark.triangle")
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.text = CYLLocalizedString("滚动隐藏：模拟意外情况（issue #13）")
        cell.detailTextLabel?.text = CYLLocalizedString("选择一种意外情况，1.5 秒后触发。请先向下滚动隐藏 TabBar。")
        return cell
    }
}

/**
 * [EN] Two buttons that call `-cyl_switchToAdjacentTabWithStep:animated:` with -1 and 1; the result (YES or NO, e.g. at the
 *      last tab) is shown when coming back.
 * [CN] 两个按钮分别以 -1 与 1 调用 `-cyl_switchToAdjacentTabWithStep:animated:`；返回时显示结果（YES 或 NO，例如已是最后一个 Tab）。
 */
final class CYLSwitchAdjacentTabCell: UITableViewCell {
    weak var tabBarController: CYLTabBarController?

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        imageView?.image = UIImage(systemName: "arrow.left.arrow.right")
        let buttons = [(-1, "◀︎"), (1, "▶︎")].map { step, title -> UIButton in
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.accessibilityLabel = "cyl_switchToAdjacentTab \(step)"
            button.tag = step
            button.titleLabel?.font = .systemFont(ofSize: 22)
            button.addTarget(self, action: #selector(switchTab(_:)), for: .touchUpInside)
            return button
        }
        let stackView = UIStackView(arrangedSubviews: buttons)
        stackView.spacing = 4
        stackView.distribution = .fillEqually
        stackView.frame = CGRect(x: 0, y: 0, width: 88, height: 44)
        accessoryView = stackView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    @objc private func switchTab(_ sender: UIButton) {
        guard let tabBarController else { return }
        let switched = tabBarController.cyl_switchToAdjacentTab(withStep: sender.tag, animated: true)
        CYLSettingsDemo.setValue(NSNumber(value: switched), tabBarController, CYLSettingsDemo.switchAdjacentResultKey)
        reload()
    }

    func reload() {
        let result = tabBarController.flatMap { objc_getAssociatedObject($0, CYLSettingsDemo.switchAdjacentResultKey) as? NSNumber }
        textLabel?.text = CYLLocalizedString("切换到上一个 / 下一个 Tab（issue #535）")
        let resultText = result.map { $0.boolValue ? "YES" : "NO" } ?? "-"
        detailTextLabel?.text = String(format: CYLLocalizedString("点击右侧箭头调用 cyl_switchToAdjacentTabWithStep:-1 / 1，与滑动相同会跳过 PlusButton 并检查登录。上次返回：%@"),
                                       resultText)
    }
}
