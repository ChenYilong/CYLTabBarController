//
//  UIBarButtonItem+CYLBadgeExtention.swift
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Badges on a bar button item (`UIBarButtonItem (CYLBadgeExtention)`). The item is not a view: the badge goes on the
 *      image or title inside its button. Translated from Objective-C (docs/Swift-Migration.md, step 24); every selector is
 *      kept. The `CYLBadgeProtocol` members are internal; the conformance is declared in UIBarButtonItem+CYLBadgeExtention.h
 *      (see UIView+CYLBadgeExtention.swift for why).
 *
 *      FIX: badge colors of bar button items on iOS 26+ (Liquid Glass). There the content of a bar button item is drawn
 *      monochrome in the bar's tint, and colors drawn by layers inside it are lost (Apple Developer Forums 794886, 795908),
 *      so the library's badge showed as a black dot on a light bar. With Liquid Glass active the badge is the system one
 *      (`UIBarButtonItem.Badge`, iOS 26), whose colors UIKit keeps: background `cyl_badgeBackgroundColor`, text
 *      `cyl_badgeTextColor`, font `cyl_badgeFont`. The value works as before: "" a dot, a number (capped at
 *      `cyl_badgeMaximumBadgeNumber`), "new" / "NEW" localized, any other text. The animation is applied to the system
 *      badge view when it can be found in the bar. Before iOS 26, and with `UIDesignRequiresCompatibility`, nothing changes.
 * [CN] 导航栏按钮上的角标（`UIBarButtonItem (CYLBadgeExtention)`）。item 不是视图：角标放在其按钮内的图片或标题上。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，第 24 步），保留所有 selector。`CYLBadgeProtocol` 的成员为 internal；遵守关系声明在
 *      UIBarButtonItem+CYLBadgeExtention.h（原因见 UIView+CYLBadgeExtention.swift）。
 *
 *      修复 iOS 26+（液态玻璃）上导航栏按钮角标的颜色：其内容按导航栏的 tint 以单色绘制，内部 layer 绘制的颜色会丢失，本库角标因此在浅色
 *      导航栏上显示为黑点。液态玻璃生效时改用系统角标（iOS 26 的 `UIBarButtonItem.Badge`），UIKit 会保留其颜色：背景色
 *      `cyl_badgeBackgroundColor`、文字颜色 `cyl_badgeTextColor`、字体 `cyl_badgeFont`。取值规则不变："" 为红点，数字（以
 *      `cyl_badgeMaximumBadgeNumber` 为上限），"new" / "NEW" 本地化，其他文字原样显示。能在导航栏中找到系统角标视图时为其添加动画。
 *      iOS 26 以前以及设置了 `UIDesignRequiresCompatibility` 时行为不变。
 */
enum CYLBarButtonItemBadgeSupport {
    static let font = CYLUtilsKeys.key("cyl_badgeFont")
    static let backgroundColor = CYLUtilsKeys.key("cyl_badgeBackgroundColor")
    static let textColor = CYLUtilsKeys.key("cyl_badgeTextColor")
    static let animationType = CYLUtilsKeys.key("cyl_badgeAnimationType")
    /**
     * [EN] The system badge hidden by `-cyl_clearBadge`, for `-cyl_resumeBadge`. [CN] `-cyl_clearBadge` 隐藏的系统角标，供恢复使用。
     */
    static let pausedSystemBadge = CYLUtilsKeys.key("cyl_resumeBadge")

    /**
     * [EN] YES when bar button item badges are the system ones: iOS 26+ with Liquid Glass active.
     * [CN] bar button item 的角标使用系统角标：iOS 26+ 且液态玻璃生效。
     */
    static var usesSystemBadge: Bool {
        if #available(iOS 26.0, *) {
            return CYLUtils.isLiquidGlassActive()
        }
        return false
    }

    /**
     * [EN] The system badge for `value`, with the library's rules; nil hides it. [CN] 按本库规则生成的系统角标；nil 表示隐藏。
     */
    @available(iOS 26.0, *)
    @MainActor
    static func systemBadge(for value: String, maximumBadgeNumber: Int) -> UIBarButtonItem.Badge? {
        if value.isEmpty {
            return .indicator()
        }
        if value.allSatisfy({ $0.isASCII && $0.isNumber }) {
            let number = (value as NSString).integerValue
            if number <= 0 {
                return nil
            }
            let maximum = max(1, maximumBadgeNumber)
            return .string(number > maximum ? "\(maximum)+" : "\(number)")
        }
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }
        return .string(value == "new" || value == "NEW" ? CYLLocalizedString(value) : value)
    }

    /**
     * [EN] The system badge view inside `view`: a view whose class name has "Badge" and is not one of the library's.
     * [CN] `view` 中的系统角标视图：类名包含 "Badge" 且不是本库的视图。
     */
    static func systemBadgeView(in view: UIView, itemFrameInWindow: CGRect) -> UIView? {
        for subview in view.subviews {
            let className = NSStringFromClass(type(of: subview))
            if className.contains("Badge") && !className.hasPrefix("CYL") && !subview.isHidden {
                let frameInWindow = subview.convert(subview.bounds, to: nil)
                if itemFrameInWindow.isEmpty || frameInWindow.insetBy(dx: -8, dy: -8).intersects(itemFrameInWindow) {
                    return subview
                }
            }
            if let badgeView = systemBadgeView(in: subview, itemFrameInWindow: itemFrameInWindow) {
                return badgeView
            }
        }
        return nil
    }

    /**
     * [EN] Applies `animationType` to the system badge view once the bar has laid it out.
     * [CN] 导航栏布局出系统角标视图后为其添加动画。
     */
    @MainActor
    static func animateSystemBadge(of item: UIBarButtonItem, host: UIView?, animationType: CYLBadgeAnimationType) {
        if animationType == .none {
            return
        }
        if (host?.cyl_badgeRespectsReduceMotion ?? true) && UIAccessibility.isReduceMotionEnabled {
            return
        }
        DispatchQueue.main.async { [weak item] in
            let itemView = item?.cyl_view()
            // [EN] The bar that holds the item; its badge may be outside the item's own view.
            // [CN] item 所在的 bar；系统角标可能不在 item 自身的视图中。
            var barView = itemView
            while let current = barView, let superview = current.superview, !(current is UINavigationBar), !(current is UIToolbar) {
                barView = superview
            }
            barView?.layoutIfNeeded()
            let itemFrameInWindow = itemView.map { $0.convert($0.bounds, to: nil) } ?? .zero
            guard let badgeView = itemView.flatMap({ systemBadgeView(in: $0, itemFrameInWindow: itemFrameInWindow) })
                    ?? barView.flatMap({ systemBadgeView(in: $0, itemFrameInWindow: itemFrameInWindow) }) else {
                return
            }
            CYLBadgeAllAnimationKeys().forEach { badgeView.layer.removeAnimation(forKey: $0) }
            if let animation = cylBadgeAnimationForTypeEntryPoint(animationType, badgeView.bounds.size),
               let key = CYLBadgeAnimationKeyForType(animationType) {
                badgeView.layer.add(animation, forKey: key)
            }
        }
    }
}

extension UIBarButtonItem {

    /**
     * [EN] The view that holds this item's badge (`CYL_ACTUAL_BARBUTTON` in Objective-C).
     * [CN] 承载本 item 角标的视图（Objective-C 中的 `CYL_ACTUAL_BARBUTTON`）。
     */
    private var cyl_actualBadgeView: UIView? {
        cyl_getActualBadgeSuperView() as? UIView
    }

    // MARK: Public methods

    @objc(cyl_isReady)
    dynamic func cyl_isReady() -> Bool {
        // [EN] The system badge (iOS 26+) needs no laid-out view. [CN] 系统角标（iOS 26+）不依赖已布局的视图。
        if CYLBarButtonItemBadgeSupport.usesSystemBadge {
            return true
        }
        return (cyl_actualBadgeView?.frame.size.width ?? 0) > 10
    }

    /**
     * [EN] Shows a red dot badge, with no animation; waits 0.5 s for a bar button that is not laid out yet.
     * [CN] 显示红点角标，无动画；bar button 尚未布局时等待 0.5 秒。
     */
    @objc(cyl_showBadge)
    dynamic func cyl_showBadge() {
        if CYLBarButtonItemBadgeSupport.usesSystemBadge {
            cyl_showBadgeValue("", animationType: .none)
            return
        }
        swizzling_willMoveToSuperview()
        DispatchQueue.main.asyncAfter(deadline: .now() + (cyl_isReady() ? 0 : 0.5)) { [self] in
            cyl_actualBadgeView?.cyl_showBadge()
        }
    }

    @objc(cyl_showBadgeValue:animationType:)
    dynamic func cyl_showBadgeValue(_ value: String, animationType: CYLBadgeAnimationType) {
        if #available(iOS 26.0, *), CYLBarButtonItemBadgeSupport.usesSystemBadge {
            let host = cyl_actualBadgeView
            // [EN] The library's own badge would be drawn monochrome here, so it is not shown.
            // [CN] 本库自己的角标在这里会被单色绘制，因此不显示。
            host?.cyl_clearBadge()
            objc_setAssociatedObject(self, CYLBarButtonItemBadgeSupport.pausedSystemBadge, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            objc_setAssociatedObject(self, CYLBarButtonItemBadgeSupport.animationType, NSNumber(value: animationType.rawValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            let maximumBadgeNumber = host?.cyl_badgeMaximumBadgeNumber ?? CYLBadgeAppearance.global.maximumBadgeNumber
            var badge = CYLBarButtonItemBadgeSupport.systemBadge(for: value, maximumBadgeNumber: maximumBadgeNumber)
            badge?.backgroundColor = cyl_badgeBackgroundColor
            badge?.foregroundColor = cyl_badgeTextColor
            badge?.font = cyl_badgeFont
            self.badge = badge
            if badge != nil {
                CYLBarButtonItemBadgeSupport.animateSystemBadge(of: self, host: host, animationType: animationType)
            }
            return
        }
        swizzling_willMoveToSuperview()
        DispatchQueue.main.asyncAfter(deadline: .now() + (cyl_isReady() ? 0 : 0.5)) { [self] in
            cyl_actualBadgeView?.cyl_showBadgeValue(value, animationType: animationType)
        }
    }

    /**
     * [EN] Shows `value` with `animationType`, after setting the badge's background color when one is given.
     * [CN] 以 `animationType` 显示 `value`；传入背景色时先设置角标背景色。
     *
     * [EN] Internal: declared in UIBarButtonItem+CYLBadgeExtention.h, as `CYLBadgeAnimationType` in a public Swift signature makes
     *      the generated header import the umbrella header.
     * [CN] internal：声明在 UIBarButtonItem+CYLBadgeExtention.h，因为公开 Swift 签名中的 `CYLBadgeAnimationType` 会让生成的头文件导入伞头文件。
     */
    @objc(cyl_showBadgeValue:animationType:backgroundColor:)
    dynamic func cyl_showBadgeValue(_ value: String, animationType: CYLBadgeAnimationType, backgroundColor: UIColor?) {
        if let backgroundColor {
            cyl_badgeBackgroundColor = backgroundColor
        }
        cyl_showBadgeValue(value, animationType: animationType)
    }

    @objc(cyl_clearBadge)
    dynamic func cyl_clearBadge() {
        if #available(iOS 26.0, *), let badge = self.badge {
            // [EN] Kept for `-cyl_resumeBadge`. [CN] 保留，供 `-cyl_resumeBadge` 恢复。
            objc_setAssociatedObject(self, CYLBarButtonItemBadgeSupport.pausedSystemBadge, badge, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.badge = nil
        }
        cyl_actualBadgeView?.cyl_clearBadge()
    }

    @objc(cyl_resumeBadge)
    dynamic func cyl_resumeBadge() {
        if #available(iOS 26.0, *),
           let pausedBadge = objc_getAssociatedObject(self, CYLBarButtonItemBadgeSupport.pausedSystemBadge) as? UIBarButtonItem.Badge,
           self.badge == nil {
            self.badge = pausedBadge
            objc_setAssociatedObject(self, CYLBarButtonItemBadgeSupport.pausedSystemBadge, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            CYLBarButtonItemBadgeSupport.animateSystemBadge(of: self, host: cyl_actualBadgeView, animationType: cyl_badgeAnimationType)
            return
        }
        cyl_actualBadgeView?.cyl_resumeBadge()
    }

    @objc(cyl_isPauseBadge)
    dynamic func cyl_isPauseBadge() -> Bool {
        if #available(iOS 26.0, *), self.badge == nil,
           objc_getAssociatedObject(self, CYLBarButtonItemBadgeSupport.pausedSystemBadge) != nil {
            return true
        }
        return cyl_actualBadgeView?.cyl_isPauseBadge() ?? false
    }

    @objc(cyl_isShowBadge)
    dynamic func cyl_isShowBadge() -> Bool {
        if #available(iOS 26.0, *), self.badge != nil {
            return true
        }
        return cyl_actualBadgeView?.cyl_isShowBadge() ?? false
    }

    // MARK: Private methods

    /**
     * [EN] Runs `block` with the view that shows the badge: now when the bar button is laid out, else after the same 0.5 s
     *      that `-cyl_showBadgeValue:animationType:` waits, so a style set in `-viewDidLoad` is not lost and is applied
     *      before the badge shows.
     * [CN] 用显示角标的视图执行 `block`：bar button 已布局时立即执行，否则与 `-cyl_showBadgeValue:animationType:` 一样延迟 0.5 秒，
     *      因此在 `-viewDidLoad` 中设置的样式不会丢失，并在角标显示之前生效。
     */
    private func cyl_performWithBadgeSuperView(_ block: @escaping (UIView) -> Void) {
        if cyl_isReady() {
            if let view = cyl_actualBadgeView {
                block(view)
            }
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            if let view = self?.cyl_actualBadgeView {
                block(view)
            }
        }
    }

    /**
     * [EN] The image or title inside the item's button (`_UIModernBarButton`), else the button itself.
     * [CN] item 按钮（`_UIModernBarButton`）中的图片或标题，否则为按钮本身。
     */
    @objc(cyl_getActualBadgeSuperView)
    dynamic func cyl_getActualBadgeSuperView() -> Any? {
        let contentView = cyl_view()?.cyl_findBarButtonContentView()
        var actualBadgeSuperView: UIView? = contentView
        if let button = contentView as? UIButton {
            if let imageView = button.imageView, imageView.frame.size.width > 10 {
                actualBadgeSuperView = imageView
            } else if let titleLabel = button.titleLabel, titleLabel.frame.size.width > 10 {
                actualBadgeSuperView = titleLabel
            }
        }
        // [EN] Auto Layout needs `-layoutIfNeeded` before the frame has a value. [CN] 自动布局需要先 `-layoutIfNeeded` 才有 frame。
        actualBadgeSuperView?.layoutIfNeeded()
        return actualBadgeSuperView
    }

    @objc(cyl_performSelector:)
    dynamic func cyl_perform(_ aSelector: Selector) {
        cyl_perform(aSelector, with: nil, with: nil)
    }

    @objc(cyl_performSelector:withObject:)
    dynamic func cyl_perform(_ aSelector: Selector, with object: Any?) {
        cyl_perform(aSelector, with: object, with: nil)
    }

    @objc(cyl_performSelector:withObject:withObject:)
    dynamic func cyl_perform(_ aSelector: Selector, with object1: Any?, with object2: Any?) {
        _ = perform(aSelector, with: object1, with: object2)
    }

    /**
     * [EN] 0 when the bar button is laid out, else 0.5 s, the delay the badge methods wait (a `CGFloat`, as the protocol
     *      declares). Setting it does nothing: the delay follows `-cyl_isReady`.
     * [CN] bar button 已布局时为 0，否则为 0.5 秒，即角标方法等待的时间（与协议声明一致的 `CGFloat`）。设置无效：延迟由 `-cyl_isReady` 决定。
     */
    @objc(cyl_delayIfNeededForSeconds)
    dynamic var cyl_delayIfNeededForSeconds: CGFloat {
        @objc(cyl_delayIfNeededForSeconds) get { cyl_isReady() ? 0 : 0.5 }
        @objc(cyl_setDelayIfNeededForSeconds:) set { _ = newValue }
    }

    @objc(cyl_delayIfNeededForSecondsValue)
    dynamic var cyl_delayIfNeededForSecondsValue: NSNumber {
        @objc(cyl_delayIfNeededForSecondsValue) get { NSNumber(value: Double(cyl_delayIfNeededForSeconds)) }
        @objc(cyl_setDelayIfNeededForSecondsValue:) set { cyl_delayIfNeededForSeconds = CGFloat(newValue.doubleValue) }
    }

    // MARK: Setters and getters

    /**
     * [EN] The badge view of the item's badge host. [CN] item 角标宿主的角标视图。
     */
    @objc(cyl_badge)
    public dynamic var cyl_badge: (UIView & CYLBadgeTextDisplaying)? {
        @objc(cyl_badge) get { cyl_actualBadgeView?.cyl_badge }
        @objc(cyl_setBadge:) set { cyl_performWithBadgeSuperView { $0.cyl_badge = newValue } }
    }

    // [EN] The font and colors are remembered on the item too, for the system badge (iOS 26+) and before the bar button is
    //      laid out.
    // [CN] 字体与颜色同时保存在 item 上，供系统角标（iOS 26+）以及 bar button 尚未布局时使用。
    @objc(cyl_badgeFont)
    dynamic var cyl_badgeFont: UIFont! {
        @objc(cyl_badgeFont) get {
            objc_getAssociatedObject(self, CYLBarButtonItemBadgeSupport.font) as? UIFont
                ?? cyl_actualBadgeView?.cyl_badgeFont ?? CYLBadgeAppearance.global.font
        }
        @objc(cyl_setBadgeFont:) set {
            objc_setAssociatedObject(self, CYLBarButtonItemBadgeSupport.font, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            cyl_performWithBadgeSuperView { $0.cyl_badgeFont = newValue }
        }
    }

    @objc(cyl_badgeBackgroundColor)
    dynamic var cyl_badgeBackgroundColor: UIColor! {
        @objc(cyl_badgeBackgroundColor) get {
            objc_getAssociatedObject(self, CYLBarButtonItemBadgeSupport.backgroundColor) as? UIColor
                ?? cyl_actualBadgeView?.cyl_badgeBackgroundColor ?? CYLBadgeAppearance.global.backgroundColor
        }
        @objc(cyl_setBadgeBackgroundColor:) set {
            objc_setAssociatedObject(self, CYLBarButtonItemBadgeSupport.backgroundColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            cyl_performWithBadgeSuperView { $0.cyl_badgeBackgroundColor = newValue }
        }
    }

    @objc(cyl_badgeTextColor)
    dynamic var cyl_badgeTextColor: UIColor! {
        @objc(cyl_badgeTextColor) get {
            objc_getAssociatedObject(self, CYLBarButtonItemBadgeSupport.textColor) as? UIColor
                ?? cyl_actualBadgeView?.cyl_badgeTextColor ?? CYLBadgeAppearance.global.textColor
        }
        @objc(cyl_setBadgeTextColor:) set {
            objc_setAssociatedObject(self, CYLBarButtonItemBadgeSupport.textColor, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            cyl_performWithBadgeSuperView { $0.cyl_badgeTextColor = newValue }
        }
    }

    @objc(cyl_badgeAnimationType)
    dynamic var cyl_badgeAnimationType: CYLBadgeAnimationType {
        @objc(cyl_badgeAnimationType) get {
            // [EN] The system badge (iOS 26+) has no view of the library to keep it in. [CN] 系统角标没有本库的视图来保存它。
            if CYLBarButtonItemBadgeSupport.usesSystemBadge,
               let value = objc_getAssociatedObject(self, CYLBarButtonItemBadgeSupport.animationType) as? NSNumber {
                return CYLBadgeAnimationType(rawValue: value.uintValue) ?? .none
            }
            return cyl_actualBadgeView?.cyl_badgeAnimationType ?? .none
        }
        @objc(cyl_setBadgeAnimationType:) set {
            objc_setAssociatedObject(self, CYLBarButtonItemBadgeSupport.animationType, NSNumber(value: newValue.rawValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            cyl_performWithBadgeSuperView { $0.cyl_badgeAnimationType = newValue }
        }
    }

    @objc(cyl_badgeAnimationTypeValue)
    dynamic var cyl_badgeAnimationTypeValue: NSNumber {
        @objc(cyl_badgeAnimationTypeValue) get { NSNumber(value: cyl_badgeAnimationType.rawValue) }
        @objc(cyl_setBadgeAnimationTypeValue:) set {
            cyl_badgeAnimationType = CYLBadgeAnimationType(rawValue: newValue.uintValue) ?? .none
        }
    }

    @objc(cyl_badgeFrame)
    dynamic var cyl_badgeFrame: CGRect {
        @objc(cyl_badgeFrame) get { cyl_actualBadgeView?.cyl_badgeFrame ?? .zero }
        @objc(cyl_setBadgeFrame:) set { cyl_performWithBadgeSuperView { $0.cyl_badgeFrame = newValue } }
    }

    @objc(cyl_badgeFrameValue)
    dynamic var cyl_badgeFrameValue: NSValue {
        @objc(cyl_badgeFrameValue) get { NSValue(cgRect: cyl_badgeFrame) }
        @objc(cyl_setBadgeFrameValue:) set { cyl_badgeFrame = newValue.cgRectValue }
    }

    @objc(cyl_badgeCenterOffset)
    dynamic var cyl_badgeCenterOffset: CGPoint {
        @objc(cyl_badgeCenterOffset) get { cyl_actualBadgeView?.cyl_badgeCenterOffset ?? .zero }
        @objc(cyl_setBadgeCenterOffset:) set { cyl_performWithBadgeSuperView { $0.cyl_badgeCenterOffset = newValue } }
    }

    @objc(cyl_badgeCenterOffsetValue)
    dynamic var cyl_badgeCenterOffsetValue: NSValue {
        @objc(cyl_badgeCenterOffsetValue) get { NSValue(cgPoint: cyl_badgeCenterOffset) }
        @objc(cyl_setBadgeCenterOffsetValue:) set { cyl_badgeCenterOffset = newValue.cgPointValue }
    }

    @objc(cyl_badgeMaximumBadgeNumber)
    dynamic var cyl_badgeMaximumBadgeNumber: Int {
        @objc(cyl_badgeMaximumBadgeNumber) get { cyl_actualBadgeView?.cyl_badgeMaximumBadgeNumber ?? 0 }
        @objc(cyl_setBadgeMaximumBadgeNumber:) set { cyl_performWithBadgeSuperView { $0.cyl_badgeMaximumBadgeNumber = newValue } }
    }

    @objc(cyl_badgeMaximumBadgeNumberValue)
    dynamic var cyl_badgeMaximumBadgeNumberValue: NSNumber {
        @objc(cyl_badgeMaximumBadgeNumberValue) get { NSNumber(value: cyl_badgeMaximumBadgeNumber) }
        @objc(cyl_setBadgeMaximumBadgeNumberValue:) set { cyl_badgeMaximumBadgeNumber = newValue.intValue }
    }

    @objc(cyl_badgeMargin)
    dynamic var cyl_badgeMargin: CGFloat {
        @objc(cyl_badgeMargin) get { cyl_actualBadgeView?.cyl_badgeMargin ?? 0 }
        @objc(cyl_setBadgeMargin:) set { cyl_performWithBadgeSuperView { $0.cyl_badgeMargin = newValue } }
    }

    @objc(cyl_badgeMarginValue)
    dynamic var cyl_badgeMarginValue: NSNumber {
        @objc(cyl_badgeMarginValue) get { NSNumber(value: Double(cyl_badgeMargin)) }
        @objc(cyl_setBadgeMarginValue:) set { cyl_badgeMargin = CGFloat(newValue.doubleValue) }
    }

    @objc(cyl_badgeRadius)
    dynamic var cyl_badgeRadius: CGFloat {
        @objc(cyl_badgeRadius) get { cyl_actualBadgeView?.cyl_badgeRadius ?? 0 }
        @objc(cyl_setBadgeRadius:) set { cyl_performWithBadgeSuperView { $0.cyl_badgeRadius = newValue } }
    }

    @objc(cyl_badgeRadiusValue)
    dynamic var cyl_badgeRadiusValue: NSNumber {
        @objc(cyl_badgeRadiusValue) get { NSNumber(value: Double(cyl_badgeRadius)) }
        @objc(cyl_setBadgeRadiusValue:) set { cyl_badgeRadius = CGFloat(newValue.doubleValue) }
    }

    @objc(cyl_badgeCornerRadius)
    dynamic var cyl_badgeCornerRadius: CGFloat {
        @objc(cyl_badgeCornerRadius) get { cyl_actualBadgeView?.cyl_badgeCornerRadius ?? 0 }
        @objc(cyl_setBadgeCornerRadius:) set { cyl_performWithBadgeSuperView { $0.cyl_badgeCornerRadius = newValue } }
    }

    @objc(cyl_badgeCornerRadiusValue)
    dynamic var cyl_badgeCornerRadiusValue: NSNumber {
        @objc(cyl_badgeCornerRadiusValue) get { NSNumber(value: Double(cyl_badgeCornerRadius)) }
        @objc(cyl_setBadgeCornerRadiusValue:) set { cyl_badgeCornerRadius = CGFloat(newValue.doubleValue) }
    }

    /**
     * [EN] Meant to swizzle `-[_UIButtonBarButton willMoveToSuperview:]` with `-[UIView cyl_willMoveToSuperview:]`, once. As in
     *      the Objective-C original, it looks the replacement up on `UIBarButtonItem`, which does not have it, so nothing is
     *      exchanged. TODO (2026-11-13): decide whether to fix it; exchanging with `UIView`'s method would affect every view.
     * [CN] 本意是一次性把 `-[_UIButtonBarButton willMoveToSuperview:]` 与 `-[UIView cyl_willMoveToSuperview:]` 交换。与 Objective-C
     *      原实现相同，它在 `UIBarButtonItem` 上查找替换方法，而该类没有这个方法，因此不会交换任何实现。TODO（2026-11-13）：决定是否修复；
     *      与 `UIView` 的方法交换会影响所有视图。
     */
    @objc(swizzling_willMoveToSuperview)
    dynamic func swizzling_willMoveToSuperview() {
        _ = CYLBarButtonItemBadgeSupport.willMoveToSuperviewSwizzle
    }
}

extension CYLBarButtonItemBadgeSupport {
    static let willMoveToSuperviewSwizzle: Void = {
        guard let buttonBarButtonClass = NSClassFromString("_UIButtonBarButton"),
              let originalMethod = class_getInstanceMethod(buttonBarButtonClass, #selector(UIView.willMove(toSuperview:))),
              let swizzledMethod = class_getInstanceMethod(UIBarButtonItem.self, NSSelectorFromString("cyl_willMoveToSuperview:")) else {
            return
        }
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }()
}
