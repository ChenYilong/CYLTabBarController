//
//  UITabBarItem+CYLBadgeExtention.swift
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Badges on a tab bar item (`UITabBarItem (CYLBadgeExtention)`): the item is not a view, so every badge call goes to
 *      the badge host of its tab button, in both Liquid Glass layers. Translated from Objective-C (docs/Swift-Migration.md,
 *      step 23); every selector is kept. It works with and without Core (the `CYLBadgeView` subspec alone): Core's helpers
 *      (`-cyl_imageView`, `-cyl_tabLabel`, the platter layers) are called by selector, only when Core is part of the build.
 *      The `CYLBadgeProtocol` members are internal; the conformance is declared in UITabBarItem+CYLBadgeExtention.h (see
 *      UIView+CYLBadgeExtention.swift for why).
 * [CN] TabBarItem 上的角标（`UITabBarItem (CYLBadgeExtention)`）：item 不是视图，因此每个角标调用都转给其 Tab 按钮的角标宿主，并作用于
 *      液态玻璃的两个图层。已从 Objective-C 翻译（docs/Swift-Migration.md，第 23 步），保留所有 selector。有无 Core 都可使用（单独的
 *      `CYLBadgeView` 子库）：Core 的方法（`-cyl_imageView`、`-cyl_tabLabel`、platter 图层）只在 Core 参与编译时通过 selector 调用。
 *      `CYLBadgeProtocol` 的成员为 internal；遵守关系声明在 UITabBarItem+CYLBadgeExtention.h（原因见 UIView+CYLBadgeExtention.swift）。
 */
enum CYLTabBarItemBadgeSupport {
    static let delayIfNeededForSeconds = CYLUtilsKeys.key("cyl_delayIfNeededForSeconds")
    /**
     * [EN] The selector name is the key, as in Objective-C. [CN] 与 Objective-C 一样以 selector 名称为 key。
     */
    static let lastBadgeButton = CYLUtilsKeys.key("cyl_moveBadgeToCurrentTabButtonIfNeeded")

    /**
     * [EN] `CYL_BADGE_CORE_AVAILABLE` in Objective-C: Core (the tab bar) is part of the build.
     * [CN] Objective-C 中的 `CYL_BADGE_CORE_AVAILABLE`：Core（TabBar）参与编译。
     */
    static let isCoreAvailable = NSClassFromString("CYLTabBarController") != nil

    /**
     * [EN] Calls a Core method that returns an object, by selector; nil without Core. [CN] 通过 selector 调用返回对象的 Core 方法；没有 Core 时为 nil。
     */
    static func object<T>(_ receiver: NSObject?, _ selectorName: String) -> T? {
        let selector = NSSelectorFromString(selectorName)
        guard let receiver, receiver.responds(to: selector) else {
            return nil
        }
        return receiver.perform(selector)?.takeUnretainedValue() as? T
    }

    /**
     * [EN] Calls a Core method that returns a Boolean, by selector; false without Core. [CN] 通过 selector 调用返回布尔值的 Core 方法。
     */
    static func bool(_ receiver: NSObject, _ selectorName: String) -> Bool {
        let selector = NSSelectorFromString(selectorName)
        guard receiver.responds(to: selector), let method = receiver.method(for: selector) else {
            return false
        }
        typealias BoolGetter = @convention(c) (AnyObject, Selector) -> Bool
        return unsafeBitCast(method, to: BoolGetter.self)(receiver, selector)
    }

    /**
     * [EN] Without Core: the icon inside a tab button, where the badge goes; the button itself when there is none.
     * [CN] 没有 Core 时：角标所在的 Tab 图标；没有时为按钮本身。
     */
    static func iconView(in view: UIView) -> UIView {
        for subview in view.subviews {
            if subview is UIImageView && !subview.isHidden && subview.frame.size.width > 0 {
                return subview
            }
            let iconView = iconView(in: subview)
            if iconView !== subview {
                return iconView
            }
        }
        return view
    }
}

extension UITabBarItem {

    /**
     * [EN] The view that holds this item's badge (`CYL_ACTUAL_BARBUTTON` in Objective-C).
     * [CN] 承载本 item 角标的视图（Objective-C 中的 `CYL_ACTUAL_BARBUTTON`）。
     */
    private var cyl_actualBadgeView: UIView? {
        cyl_getActualBadgeSuperView() as? UIView
    }

    @objc(cyl_setBadgeValue:)
    dynamic func cyl_setBadgeValue(_ badgeValue: String) {
        // [EN] No longer required (the deprecated system badge point), kept for apps that still add one.
        // [CN] 已不再必需（废弃的系统角标点），为仍在添加它的 App 保留。
        let removeSelector = NSSelectorFromString("cyl_removeTabBadgePoint")
        if let tabButton = cyl_tabButton, tabButton.responds(to: removeSelector) {
            _ = tabButton.perform(removeSelector)
        }
        cyl_clearBadge()
        // [EN] FIX: this used to call itself and never return. [CN] 之前这里调用自身，导致无限递归。
        cyl_showBadgeValue(badgeValue, animationType: .none)
    }

    @objc(cyl_delayIfNeededForSeconds)
    dynamic var cyl_delayIfNeededForSeconds: CGFloat {
        @objc(cyl_delayIfNeededForSeconds) get {
            (objc_getAssociatedObject(self, CYLTabBarItemBadgeSupport.delayIfNeededForSeconds) as? NSNumber)
                .map { CGFloat($0.doubleValue) } ?? 0
        }
        @objc(cyl_setDelayIfNeededForSeconds:) set {
            objc_setAssociatedObject(self, CYLTabBarItemBadgeSupport.delayIfNeededForSeconds, NSNumber(value: Double(newValue)),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    @objc(cyl_delayIfNeededForSecondsValue)
    dynamic var cyl_delayIfNeededForSecondsValue: NSNumber {
        @objc(cyl_delayIfNeededForSecondsValue) get { NSNumber(value: Double(cyl_delayIfNeededForSeconds)) }
        @objc(cyl_setDelayIfNeededForSecondsValue:) set { cyl_delayIfNeededForSeconds = CGFloat(newValue.doubleValue) }
    }

    // MARK: Public methods

    /**
     * [EN] Shows a red dot badge, with no animation. [CN] 显示红点角标，无动画。
     */
    @objc(cyl_showBadge)
    dynamic func cyl_showBadge() {
        cyl_perform(NSSelectorFromString("cyl_showBadge"))
    }

    @objc(cyl_showBadgeValue:animationTypeValue:)
    dynamic func cyl_showBadgeValue(_ value: String, animationTypeValue: NSNumber) {
        cyl_perform(NSSelectorFromString("cyl_showBadgeValue:animationTypeValue:"), with: value, with: animationTypeValue)
    }

    @objc(cyl_showBadgeValue:animationType:)
    dynamic func cyl_showBadgeValue(_ value: String, animationType: CYLBadgeAnimationType) {
        cyl_showBadgeValue(value, animationTypeValue: NSNumber(value: animationType.rawValue))
    }

    @objc(cyl_clearBadge)
    dynamic func cyl_clearBadge() {
        cyl_perform(NSSelectorFromString("cyl_clearBadge"))
    }

    @objc(cyl_resumeBadge)
    dynamic func cyl_resumeBadge() {
        cyl_perform(NSSelectorFromString("cyl_resumeBadge"))
    }

    @objc(cyl_isShowBadge)
    dynamic func cyl_isShowBadge() -> Bool {
        cyl_actualBadgeView?.cyl_isShowBadge() ?? false
    }

    @objc(cyl_isPauseBadge)
    dynamic func cyl_isPauseBadge() -> Bool {
        cyl_actualBadgeView?.cyl_isPauseBadge() ?? false
    }

    // MARK: Private methods

    /**
     * [EN] The view inside the item's tab button that holds its badge: with Core, the button's badge host (icon, Lottie view
     *      or anchor); without Core, the first visible image view. On Liquid Glass, the tab button itself (its badge methods
     *      then reach both layers).
     * [CN] 本 item 的 Tab 按钮中承载角标的视图：有 Core 时为按钮的角标宿主（图标、Lottie 视图或锚点）；没有 Core 时为第一个可见的图片视图。
     *      液态玻璃下为 Tab 按钮本身（其角标方法会作用于两个图层）。
     */
    @objc(cyl_getActualBadgeSuperView)
    dynamic func cyl_getActualBadgeSuperView() -> Any? {
        let tabButton = cyl_tabButton
        if let tabButton {
            let host: Any? = CYLTabBarItemBadgeSupport.isCoreAvailable
                ? (tabButton as UIView).cyl_getActualBadgeSuperView()
                : CYLTabBarItemBadgeSupport.iconView(in: tabButton)
            if !CYLUtils.isLiquidGlassActive() {
                return host
            }
        }
        return tabButton
    }

    @objc(cyl_getActualBadgeSuperViewFromControl:)
    dynamic func cyl_getActualBadgeSuperView(fromControl tabButton: UIControl) -> UIView? {
        (tabButton as UIView).cyl_getActualBadgeSuperView() as? UIView
    }

    @objc(cyl_performSelector:)
    dynamic func cyl_perform(_ aSelector: Selector) {
        cyl_perform(aSelector, with: nil, with: nil)
    }

    @objc(cyl_performSelector:withObject:)
    dynamic func cyl_perform(_ aSelector: Selector, with object: Any?) {
        cyl_perform(aSelector, with: object, with: nil)
    }

    /**
     * [EN] Sends a badge message to the item's badge host. On Liquid Glass, to the host in the normal layer and to its
     *      counterpart in the selected layer (#481); otherwise to the tab button, remembered for
     *      `-cyl_moveBadgeToCurrentTabButtonIfNeeded`. Without Core there is no platter to mirror.
     * [CN] 把角标消息发给 item 的角标宿主。液态玻璃下同时发给普通图层中的宿主及其在选中图层中的对应宿主（#481）；否则发给 Tab 按钮，
     *      并记录下来供 `-cyl_moveBadgeToCurrentTabButtonIfNeeded` 使用。没有 Core 时没有需要同步的 platter。
     */
    @objc(cyl_performSelector:withObject:withObject:)
    dynamic func cyl_perform(_ aSelector: Selector, with object1: Any?, with object2: Any?) {
        if !CYLTabBarItemBadgeSupport.isCoreAvailable {
            _ = (cyl_actualBadgeView as NSObject?)?.perform(aSelector, with: object1, with: object2)
            return
        }
        guard let tabButton = cyl_tabButton, CYLUtils.isLiquidGlassActive() else {
            if let tabButton = cyl_tabButton {
                objc_setAssociatedObject(self, CYLTabBarItemBadgeSupport.lastBadgeButton, tabButton, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                _ = tabButton.perform(aSelector, with: object1, with: object2)
            }
            return
        }
        let isSelectedLayer = CYLTabBarItemBadgeSupport.bool(tabButton, "cyl_isPlatterSelectedControl")
        let counterpart: UIControl? = CYLTabBarItemBadgeSupport.object(
            tabButton, isSelectedLayer ? "cyl_platterNormalControl" : "cyl_platterSelectedControl")
        for control in [tabButton, counterpart].compactMap({ $0 }) {
            _ = (cyl_getActualBadgeSuperView(fromControl: control) as NSObject?)?.perform(aSelector, with: object1, with: object2)
        }
    }

    /**
     * [EN] Classic style (not Liquid Glass): UIKit replaces a tab button when its item changes, even for a new `title`
     *      (iOS 17), and the badge shown on the old button went away with it. Called on every layout of `CYLTabBar`: when the
     *      button that showed this item's badge is no longer the current one, the badge's settings move to the current
     *      button and the badge is shown there again, with the same value and animation. Liquid Glass keeps its badges.
     * [CN] 经典样式（非液态玻璃）：item 变化时 UIKit 会替换 Tab 按钮，即使只是修改 `title`（iOS 17），旧按钮上显示的角标随之消失。
     *      `CYLTabBar` 每次布局时调用：显示该 item 角标的按钮不再是当前按钮时，把角标的设置移到当前按钮并重新显示，值与动画不变。
     *      液态玻璃会保留自己的角标。
     */
    @objc(cyl_moveBadgeToCurrentTabButtonIfNeeded)
    public dynamic func cyl_moveBadgeToCurrentTabButtonIfNeeded() {
        guard CYLTabBarItemBadgeSupport.isCoreAvailable,
              let oldButton = objc_getAssociatedObject(self, CYLTabBarItemBadgeSupport.lastBadgeButton) as? UIControl,
              let currentButton = cyl_tabButton, oldButton !== currentButton, !CYLUtils.isLiquidGlassActive(),
              let oldHost = (oldButton as UIView).cyl_getActualBadgeSuperView() as? UIView,
              let newHost = (currentButton as UIView).cyl_getActualBadgeSuperView() as? UIView else {
            return
        }
        objc_setAssociatedObject(self, CYLTabBarItemBadgeSupport.lastBadgeButton, currentButton, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        guard let badge = oldHost.cyl_badge, oldHost.cyl_isShowBadge() else {
            return
        }
        newHost.cyl_badgeFont = oldHost.cyl_badgeFont
        newHost.cyl_badgeBackgroundColor = oldHost.cyl_badgeBackgroundColor
        newHost.cyl_badgeTextColor = oldHost.cyl_badgeTextColor
        newHost.cyl_badgeBorderColor = oldHost.cyl_badgeBorderColor
        newHost.cyl_badgeBorderWidth = oldHost.cyl_badgeBorderWidth
        newHost.cyl_badgeRespectsReduceMotion = oldHost.cyl_badgeRespectsReduceMotion
        newHost.cyl_badgeFrameValue = oldHost.cyl_badgeFrameValue
        newHost.cyl_badgeCenterOffsetValue = oldHost.cyl_badgeCenterOffsetValue
        newHost.cyl_badgeMaximumBadgeNumberValue = oldHost.cyl_badgeMaximumBadgeNumberValue
        newHost.cyl_badgeRadiusValue = oldHost.cyl_badgeRadiusValue
        newHost.cyl_badgeMarginValue = oldHost.cyl_badgeMarginValue
        newHost.cyl_badgeCornerRadiusValue = oldHost.cyl_badgeCornerRadiusValue
        let animationTypeValue = oldHost.cyl_badgeAnimationTypeValue
        oldHost.cyl_clearBadge()
        cyl_showBadgeValue(badge.text ?? "", animationTypeValue: animationTypeValue)
    }

    /**
     * FIX: issue #535
     * [EN] YES once the item's image view or title label has been laid out (width > 10); without Core it asks the tab button.
     * [CN] 该 item 的图片视图或标题 Label 完成布局（宽度大于 10）后为 YES；没有 Core 时询问 Tab 按钮。
     */
    @objc(cyl_isReady)
    dynamic func cyl_isReady() -> Bool {
        guard CYLTabBarItemBadgeSupport.isCoreAvailable else {
            return (cyl_tabButton as UIView?)?.cyl_isReady() ?? false
        }
        let imageView: UIView? = CYLTabBarItemBadgeSupport.object(self, "cyl_imageView")
        let tabLabel: UIView? = CYLTabBarItemBadgeSupport.object(cyl_view(), "cyl_tabLabel")
        return (imageView?.frame.size.width ?? 0) > 10 || (tabLabel?.frame.size.width ?? 0) > 10
    }

    // MARK: Setters and getters

    // FIX: issue #481
    // [EN] The setters go through `-cyl_performSelector:withObject:`: with Liquid Glass they reach the badge host of the
    //      normal layer and of its counterpart in the selected layer. Values that are not objects use the `…Value:` setters.
    // [CN] setter 通过 `-cyl_performSelector:withObject:` 设置：液态玻璃下同时作用于普通图层及其在选中图层中的对应宿主。非对象的值使用
    //      `…Value:` setter。

    /**
     * [EN] The badge view of the item's badge host. [CN] item 角标宿主的角标视图。
     */
    @objc(cyl_badge)
    public dynamic var cyl_badge: (UIView & CYLBadgeTextDisplaying)? {
        @objc(cyl_badge) get { cyl_actualBadgeView?.cyl_badge }
        @objc(cyl_setBadge:) set { cyl_actualBadgeView?.cyl_badge = newValue }
    }

    @objc(cyl_badgeFont)
    dynamic var cyl_badgeFont: UIFont! {
        @objc(cyl_badgeFont) get { cyl_actualBadgeView?.cyl_badgeFont }
        @objc(cyl_setBadgeFont:) set { cyl_perform(NSSelectorFromString("cyl_setBadgeFont:"), with: newValue) }
    }

    @objc(cyl_badgeBackgroundColor)
    dynamic var cyl_badgeBackgroundColor: UIColor! {
        @objc(cyl_badgeBackgroundColor) get { cyl_actualBadgeView?.cyl_badgeBackgroundColor }
        @objc(cyl_setBadgeBackgroundColor:) set { cyl_perform(NSSelectorFromString("cyl_setBadgeBackgroundColor:"), with: newValue) }
    }

    @objc(cyl_badgeTextColor)
    dynamic var cyl_badgeTextColor: UIColor! {
        @objc(cyl_badgeTextColor) get { cyl_actualBadgeView?.cyl_badgeTextColor }
        @objc(cyl_setBadgeTextColor:) set { cyl_perform(NSSelectorFromString("cyl_setBadgeTextColor:"), with: newValue) }
    }

    @objc(cyl_badgeAnimationType)
    dynamic var cyl_badgeAnimationType: CYLBadgeAnimationType {
        @objc(cyl_badgeAnimationType) get { cyl_actualBadgeView?.cyl_badgeAnimationType ?? .none }
        @objc(cyl_setBadgeAnimationType:) set {
            cyl_perform(NSSelectorFromString("cyl_setBadgeAnimationTypeValue:"), with: NSNumber(value: newValue.rawValue))
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
        @objc(cyl_setBadgeFrame:) set {
            cyl_perform(NSSelectorFromString("cyl_setBadgeFrameValue:"), with: NSValue(cgRect: newValue))
        }
    }

    @objc(cyl_badgeFrameValue)
    dynamic var cyl_badgeFrameValue: NSValue {
        @objc(cyl_badgeFrameValue) get { NSValue(cgRect: cyl_badgeFrame) }
        @objc(cyl_setBadgeFrameValue:) set { cyl_badgeFrame = newValue.cgRectValue }
    }

    @objc(cyl_badgeCenterOffset)
    dynamic var cyl_badgeCenterOffset: CGPoint {
        @objc(cyl_badgeCenterOffset) get { cyl_actualBadgeView?.cyl_badgeCenterOffset ?? .zero }
        @objc(cyl_setBadgeCenterOffset:) set {
            cyl_perform(NSSelectorFromString("cyl_setBadgeCenterOffsetValue:"), with: NSValue(cgPoint: newValue))
        }
    }

    @objc(cyl_badgeCenterOffsetValue)
    dynamic var cyl_badgeCenterOffsetValue: NSValue {
        @objc(cyl_badgeCenterOffsetValue) get { NSValue(cgPoint: cyl_badgeCenterOffset) }
        @objc(cyl_setBadgeCenterOffsetValue:) set { cyl_badgeCenterOffset = newValue.cgPointValue }
    }

    @objc(cyl_badgeMaximumBadgeNumber)
    dynamic var cyl_badgeMaximumBadgeNumber: Int {
        @objc(cyl_badgeMaximumBadgeNumber) get { cyl_actualBadgeView?.cyl_badgeMaximumBadgeNumber ?? 0 }
        @objc(cyl_setBadgeMaximumBadgeNumber:) set {
            cyl_perform(NSSelectorFromString("cyl_setBadgeMaximumBadgeNumberValue:"), with: NSNumber(value: newValue))
        }
    }

    @objc(cyl_badgeMaximumBadgeNumberValue)
    dynamic var cyl_badgeMaximumBadgeNumberValue: NSNumber {
        @objc(cyl_badgeMaximumBadgeNumberValue) get { NSNumber(value: cyl_badgeMaximumBadgeNumber) }
        @objc(cyl_setBadgeMaximumBadgeNumberValue:) set { cyl_badgeMaximumBadgeNumber = newValue.intValue }
    }

    @objc(cyl_badgeMargin)
    dynamic var cyl_badgeMargin: CGFloat {
        @objc(cyl_badgeMargin) get { cyl_actualBadgeView?.cyl_badgeMargin ?? 0 }
        @objc(cyl_setBadgeMargin:) set {
            cyl_perform(NSSelectorFromString("cyl_setBadgeMarginValue:"), with: NSNumber(value: Double(newValue)))
        }
    }

    @objc(cyl_badgeMarginValue)
    dynamic var cyl_badgeMarginValue: NSNumber {
        @objc(cyl_badgeMarginValue) get { NSNumber(value: Double(cyl_badgeMargin)) }
        @objc(cyl_setBadgeMarginValue:) set { cyl_badgeMargin = CGFloat(newValue.doubleValue) }
    }

    @objc(cyl_badgeRadius)
    dynamic var cyl_badgeRadius: CGFloat {
        @objc(cyl_badgeRadius) get { cyl_actualBadgeView?.cyl_badgeRadius ?? 0 }
        @objc(cyl_setBadgeRadius:) set {
            cyl_perform(NSSelectorFromString("cyl_setBadgeRadiusValue:"), with: NSNumber(value: Double(newValue)))
        }
    }

    @objc(cyl_badgeRadiusValue)
    dynamic var cyl_badgeRadiusValue: NSNumber {
        @objc(cyl_badgeRadiusValue) get { NSNumber(value: Double(cyl_badgeRadius)) }
        @objc(cyl_setBadgeRadiusValue:) set { cyl_badgeRadius = CGFloat(newValue.doubleValue) }
    }

    @objc(cyl_badgeCornerRadius)
    dynamic var cyl_badgeCornerRadius: CGFloat {
        @objc(cyl_badgeCornerRadius) get { cyl_actualBadgeView?.cyl_badgeCornerRadius ?? 0 }
        @objc(cyl_setBadgeCornerRadius:) set {
            cyl_perform(NSSelectorFromString("cyl_setBadgeCornerRadiusValue:"), with: NSNumber(value: Double(newValue)))
        }
    }

    @objc(cyl_badgeCornerRadiusValue)
    dynamic var cyl_badgeCornerRadiusValue: NSNumber {
        @objc(cyl_badgeCornerRadiusValue) get { NSNumber(value: Double(cyl_badgeCornerRadius)) }
        @objc(cyl_setBadgeCornerRadiusValue:) set { cyl_badgeCornerRadius = CGFloat(newValue.doubleValue) }
    }
}
