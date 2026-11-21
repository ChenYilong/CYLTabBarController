//
//  CYLBadgeProtocol.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Swift since docs/Swift-Migration.md step 115 (phase ③, group A of docs/Swift-Migration-Phase3.md): the badge enums and
//      `CYLBadgeProtocol` were declared in CYLBadgeProtocol.h, which now keeps only the animation key macros. Objective-C sees
//      them through the generated Swift interface, with the same names (`CYLBadgeAnimationTypeShake`, `-cyl_showBadge` …).
// [CN] 自第 115 步（第 ③ 阶段，docs/Swift-Migration-Phase3.md 的 A 组）起为 Swift：角标枚举与 `CYLBadgeProtocol` 原声明在
//      CYLBadgeProtocol.h 中，该文件现在只保留动画 key 的宏。Objective-C 通过生成的 Swift 接口看到它们，名称不变。

/**
 [EN] The kind of a badge. [CN] 角标的类型。
 */
@objc public enum CYLBadgeStyle: UInt {
    /** [EN] A red dot. [CN] 红点。 */
    case redDot = 1
    /** [EN] A number. [CN] 数字。 */
    case number
    /** [EN] The fixed text "new". [CN] 固定文字 "new"。 */
    case new
    /** [EN] Another fixed text. [CN] 其他固定文字。 */
    case other
}

/**
 [EN] The animation of a badge: `none` keeps it still; the `…Once` kinds play once, the others repeat.
 [CN] 角标的动画：`none` 保持静止；`…Once` 类型只播放一次，其余重复播放。
 */
@objc public enum CYLBadgeAnimationType: UInt {
    /** [EN] No animation. [CN] 没有动画。 */
    case none = 0
    /** [EN] Scale. [CN] 缩放。 */
    case scale
    /** [EN] Shake. [CN] 摇晃。 */
    case shake
    /** [EN] Bounce. [CN] 弹跳。 */
    case bounce
    /** [EN] Breathing light. [CN] 呼吸灯。 */
    case breathe
    /** [EN] Left to right, once. [CN] 从左到右，一次。 */
    case leftRightOnce
    /** [EN] Right to left, once. [CN] 从右到左，一次。 */
    case rightLeftOnce
    /** [EN] Fade in, once. [CN] 淡入，一次。 */
    case fadeInOnce
    /** [EN] Rolling, once. [CN] 滚动，一次。 */
    case rollingOnce
    /** [EN] Scale, once. [CN] 缩放，一次。 */
    case scaleOnce
}

// MARK: - Animation keys 动画 key

/**
 [EN] The layer animation key of an animation type, nil for `none` (the strings of the macros in CYLBadgeProtocol.h).
 [CN] 动画类型对应的图层动画 key，`none` 为 nil（与 CYLBadgeProtocol.h 中宏的字符串相同）。
 */
public func CYLBadgeAnimationKeyForType(_ animationType: CYLBadgeAnimationType) -> String? {
    switch animationType {
    case .scale: return "cyl.badge.scale"
    case .shake: return "cyl.badge.shake"
    case .bounce: return "cyl.badge.bounce"
    case .breathe: return "cyl.badge.breathe"
    case .leftRightOnce: return "cyl.badge.LeftRightOnce"
    case .rightLeftOnce: return "cyl.badge.RightLeftOnce"
    case .fadeInOnce: return "cyl.badge.FadeInOnce"
    case .rollingOnce: return "cyl.badge.RollingOnce"
    case .scaleOnce: return "cyl.badge.ScaleOnce"
    case .none: return nil
    @unknown default: return nil
    }
}

/**
 [EN] Whether an animation type repeats (scale, shake, bounce, breathe). [CN] 动画类型是否重复播放（缩放、摇晃、弹跳、呼吸）。
 */
public func CYLBadgeAnimationTypeRepeats(_ animationType: CYLBadgeAnimationType) -> Bool {
    [.scale, .shake, .bounce, .breathe].contains(animationType)
}

/**
 [EN] Every badge animation key, the rotation included. [CN] 所有角标动画 key，包括旋转。
 */
public func CYLBadgeAllAnimationKeys() -> [String] {
    ["cyl.badge.scale", "cyl.badge.shake", "cyl.badge.bounce", "cyl.badge.breathe", "cyl.badge.rotate", "cyl.badge.LeftRightOnce",
     "cyl.badge.RightLeftOnce", "cyl.badge.FadeInOnce", "cyl.badge.RollingOnce", "cyl.badge.ScaleOnce"]
}

// MARK: - CYLBadgeProtocol

/**
 [EN] The badge API of views, tab items, bar button items and view controllers: the badge's look (font, colors, frame, offset,
      radius, margin, corner radius, maximum number, animation) and showing, clearing and resuming it. The `…Value` properties
      are the same values boxed, for key-value coding and the configuration file.
 [CN] 视图、TabBarItem、导航栏按钮与视图控制器的角标 API：角标外观（字体、颜色、frame、偏移、半径、边距、圆角、最大数字、动画）以及显示、清除与
      恢复角标。`…Value` 属性是同样的值的包装形式，用于 KVC 与配置文件。
 */
@objc public protocol CYLBadgeProtocol: NSObjectProtocol {

    /** [EN] The text font; nil resets it. [CN] 文字字体；设为 nil 恢复默认。 */
    var cyl_badgeFont: UIFont! { @objc(cyl_badgeFont) get @objc(cyl_setBadgeFont:) set }

    /** [EN] The background color; nil resets it. [CN] 背景色；设为 nil 恢复默认。 */
    var cyl_badgeBackgroundColor: UIColor! { @objc(cyl_badgeBackgroundColor) get @objc(cyl_setBadgeBackgroundColor:) set }

    /** [EN] The text color; nil resets it. [CN] 文字颜色；设为 nil 恢复默认。 */
    var cyl_badgeTextColor: UIColor! { @objc(cyl_badgeTextColor) get @objc(cyl_setBadgeTextColor:) set }

    /** [EN] The frame. [CN] frame。 */
    var cyl_badgeFrame: CGRect { @objc(cyl_badgeFrame) get @objc(cyl_setBadgeFrame:) set }

    /** [EN] `cyl_badgeFrame` boxed. [CN] `cyl_badgeFrame` 的包装形式。 */
    var cyl_badgeFrameValue: NSValue { @objc(cyl_badgeFrameValue) get @objc(cyl_setBadgeFrameValue:) set }

    /**
     [EN] The offset of the center: a negative x moves it left, a positive y moves it down.
     [CN] 中心的偏移：x 为负向左，y 为正向下。
     */
    var cyl_badgeCenterOffset: CGPoint { @objc(cyl_badgeCenterOffset) get @objc(cyl_setBadgeCenterOffset:) set }

    /** [EN] `cyl_badgeCenterOffset` boxed. [CN] `cyl_badgeCenterOffset` 的包装形式。 */
    var cyl_badgeCenterOffsetValue: NSValue { @objc(cyl_badgeCenterOffsetValue) get @objc(cyl_setBadgeCenterOffsetValue:) set }

    /** [EN] The animation. [CN] 动画。 */
    var cyl_badgeAnimationType: CYLBadgeAnimationType { @objc(cyl_badgeAnimationType) get @objc(cyl_setBadgeAnimationType:) set }

    /** [EN] `cyl_badgeAnimationType` boxed. [CN] `cyl_badgeAnimationType` 的包装形式。 */
    var cyl_badgeAnimationTypeValue: NSNumber { @objc(cyl_badgeAnimationTypeValue) get @objc(cyl_setBadgeAnimationTypeValue:) set }

    /** [EN] The largest number shown as is (above it: "99+"…). [CN] 原样显示的最大数字（超过时显示 "99+" 等）。 */
    var cyl_badgeMaximumBadgeNumber: Int { @objc(cyl_badgeMaximumBadgeNumber) get @objc(cyl_setBadgeMaximumBadgeNumber:) set }

    /** [EN] `cyl_badgeMaximumBadgeNumber` boxed. [CN] `cyl_badgeMaximumBadgeNumber` 的包装形式。 */
    var cyl_badgeMaximumBadgeNumberValue: NSNumber {
        @objc(cyl_badgeMaximumBadgeNumberValue) get @objc(cyl_setBadgeMaximumBadgeNumberValue:) set
    }

    /** [EN] The radius of a red dot. [CN] 红点的半径。 */
    var cyl_badgeRadius: CGFloat { @objc(cyl_badgeRadius) get @objc(cyl_setBadgeRadius:) set }

    /** [EN] `cyl_badgeRadius` boxed. [CN] `cyl_badgeRadius` 的包装形式。 */
    var cyl_badgeRadiusValue: NSNumber { @objc(cyl_badgeRadiusValue) get @objc(cyl_setBadgeRadiusValue:) set }

    /** [EN] The horizontal margin around the text. [CN] 文字左右的边距。 */
    var cyl_badgeMargin: CGFloat { @objc(cyl_badgeMargin) get @objc(cyl_setBadgeMargin:) set }

    /** [EN] `cyl_badgeMargin` boxed. [CN] `cyl_badgeMargin` 的包装形式。 */
    var cyl_badgeMarginValue: NSNumber { @objc(cyl_badgeMarginValue) get @objc(cyl_setBadgeMarginValue:) set }

    /** [EN] The corner radius. [CN] 圆角半径。 */
    var cyl_badgeCornerRadius: CGFloat { @objc(cyl_badgeCornerRadius) get @objc(cyl_setBadgeCornerRadius:) set }

    /** [EN] `cyl_badgeCornerRadius` boxed. [CN] `cyl_badgeCornerRadius` 的包装形式。 */
    var cyl_badgeCornerRadiusValue: NSNumber { @objc(cyl_badgeCornerRadiusValue) get @objc(cyl_setBadgeCornerRadiusValue:) set }

    /** [EN] How long to wait for the host before showing the badge. [CN] 显示角标前等待宿主就绪的时间。 */
    var cyl_delayIfNeededForSeconds: CGFloat { @objc(cyl_delayIfNeededForSeconds) get @objc(cyl_setDelayIfNeededForSeconds:) set }

    /** [EN] Whether a badge is shown. [CN] 是否显示了角标。 */
    @objc(cyl_isShowBadge) func cyl_isShowBadge() -> Bool

    /** [EN] Shows a red dot. [CN] 显示红点。 */
    @objc(cyl_showBadge) func cyl_showBadge()

    /**
     [EN] Shows `value` ("" for a red dot, a number, a text) with an animation.
     [CN] 以动画显示 `value`（"" 为红点，数字或文字）。
     */
    @objc(cyl_showBadgeValue:animationType:) func cyl_showBadgeValue(_ value: String, animationType: CYLBadgeAnimationType)

    /** [EN] Hides the badge. [CN] 隐藏角标。 */
    @objc(cyl_clearBadge) func cyl_clearBadge()

    /** [EN] Shows a hidden badge again. [CN] 重新显示隐藏的角标。 */
    @objc(cyl_resumeBadge) func cyl_resumeBadge()

    /** [EN] Whether the badge is hidden for now. [CN] 角标是否暂时隐藏。 */
    @objc(cyl_isPauseBadge) func cyl_isPauseBadge() -> Bool

    /** [EN] The view the badge is added to. [CN] 角标添加到的视图。 */
    @objc(cyl_getActualBadgeSuperView) func cyl_getActualBadgeSuperView() -> Any?

    /** [EN] Whether the host can show a badge now. [CN] 宿主现在是否可以显示角标。 */
    @objc(cyl_isReady) func cyl_isReady() -> Bool

    /** [EN] Performs `aSelector` once the host is ready. [CN] 宿主就绪后执行 `aSelector`。 */
    @objc(cyl_performSelector:) func cyl_perform(_ aSelector: Selector)

    /** [EN] Same, with one argument. [CN] 同上，携带一个参数。 */
    @objc(cyl_performSelector:withObject:) func cyl_perform(_ aSelector: Selector, with object: Any?)

    /** [EN] Same, with two arguments. [CN] 同上，携带两个参数。 */
    @objc(cyl_performSelector:withObject:withObject:) func cyl_perform(_ aSelector: Selector, with object1: Any?, with object2: Any?)

    /** [EN] `cyl_delayIfNeededForSeconds` boxed. [CN] `cyl_delayIfNeededForSeconds` 的包装形式。 */
    @objc optional var cyl_delayIfNeededForSecondsValue: NSNumber {
        @objc(cyl_delayIfNeededForSecondsValue) get @objc(cyl_setDelayIfNeededForSecondsValue:) set
    }
}
