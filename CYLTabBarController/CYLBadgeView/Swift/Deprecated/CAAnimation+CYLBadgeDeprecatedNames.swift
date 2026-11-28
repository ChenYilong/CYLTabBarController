//
//  CAAnimation+CYLBadgeDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

extension CAAnimation {
    /**
     [EN] Deprecated: renamed to `cylOpacityForeverAnimation`.
     [CN] 已废弃：已改名为 `cylOpacityForeverAnimation`。
     */
    @available(*, deprecated, renamed: "cylOpacityForeverAnimation(withDuration:)")
    @nonobjc
    public class func cyl_opacityForeverAnimation(withDuration duration: TimeInterval) -> CABasicAnimation { Self.cylOpacityForeverAnimation(withDuration: duration) }

    /**
     [EN] Deprecated: renamed to `cylOpacityTimesAnimationRepeatTimes`.
     [CN] 已废弃：已改名为 `cylOpacityTimesAnimationRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylOpacityTimesAnimationRepeatTimes(_:duration:)")
    @nonobjc
    public class func cyl_opacityTimesAnimationRepeatTimes(_ repeatTimes: Float, duration: TimeInterval) -> CABasicAnimation { Self.cylOpacityTimesAnimationRepeatTimes(repeatTimes, duration: duration) }

    /**
     [EN] Deprecated: renamed to `cylRotationAnimation`.
     [CN] 已废弃：已改名为 `cylRotationAnimation`。
     */
    @available(*, deprecated, renamed: "cylRotationAnimation(withDuration:degree:direction:repeatCount:)")
    @nonobjc
    public class func cyl_rotationAnimation(withDuration duration: TimeInterval, degree: CGFloat, direction axis: CYLAxis, repeatCount: Float) -> CABasicAnimation { Self.cylRotationAnimation(withDuration: duration, degree: degree, direction: axis, repeatCount: repeatCount) }

    /**
     [EN] Deprecated: renamed to `cylScale`.
     [CN] 已废弃：已改名为 `cylScale`。
     */
    @available(*, deprecated, renamed: "cylScale(fromScale:toScale:duration:repeatTimes:)")
    @nonobjc
    public class func cyl_scale(fromScale: CGFloat, toScale: CGFloat, duration: TimeInterval, repeatTimes: Float) -> CABasicAnimation { Self.cylScale(fromScale: fromScale, toScale: toScale, duration: duration, repeatTimes: repeatTimes) }

    /**
     [EN] Deprecated: renamed to `cylShakeAnimationRepeatTimes`.
     [CN] 已废弃：已改名为 `cylShakeAnimationRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylShakeAnimationRepeatTimes(_:duration:forObj:)")
    @nonobjc
    public class func cyl_shakeAnimationRepeatTimes(_ repeatTimes: Float, duration: TimeInterval, forObj obj: Any) -> CAKeyframeAnimation { Self.cylShakeAnimationRepeatTimes(repeatTimes, duration: duration, forObj: obj) }

    /**
     [EN] Deprecated: renamed to `cylBounceRepeatTimes`.
     [CN] 已废弃：已改名为 `cylBounceRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylBounceRepeatTimes(_:duration:forObj:)")
    @nonobjc
    public class func cyl_bounceRepeatTimes(_ repeatTimes: Float, duration: TimeInterval, forObj obj: Any) -> CAKeyframeAnimation { Self.cylBounceRepeatTimes(repeatTimes, duration: duration, forObj: obj) }

    /**
     [EN] Deprecated: renamed to `cylShakeAnimationRepeatTimes`.
     [CN] 已废弃：已改名为 `cylShakeAnimationRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylShakeAnimationRepeatTimes(_:duration:offset:)")
    @nonobjc
    public class func cyl_shakeAnimationRepeatTimes(_ repeatTimes: Float, duration: TimeInterval, offset: CGFloat) -> CAKeyframeAnimation { Self.cylShakeAnimationRepeatTimes(repeatTimes, duration: duration, offset: offset) }

    /**
     [EN] Deprecated: renamed to `cylBounceRepeatTimes`.
     [CN] 已废弃：已改名为 `cylBounceRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylBounceRepeatTimes(_:duration:offset:)")
    @nonobjc
    public class func cyl_bounceRepeatTimes(_ repeatTimes: Float, duration: TimeInterval, offset: CGFloat) -> CAKeyframeAnimation { Self.cylBounceRepeatTimes(repeatTimes, duration: duration, offset: offset) }

    /**
     [EN] Deprecated: renamed to `cylBadgeOnceScaleAnimationRepeatTimes`.
     [CN] 已废弃：已改名为 `cylBadgeOnceScaleAnimationRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylBadgeOnceScaleAnimationRepeatTimes(_:duration:)")
    @nonobjc
    public class func cyl_badge_once_scale_AnimationRepeatTimes(_ repeatTimes: Float, duration: TimeInterval) -> CABasicAnimation { Self.cylBadgeOnceScaleAnimationRepeatTimes(repeatTimes, duration: duration) }

    /**
     [EN] Deprecated: renamed to `cylBadgeOnceLeftRightAnimationMoveDistance`.
     [CN] 已废弃：已改名为 `cylBadgeOnceLeftRightAnimationMoveDistance`。
     */
    @available(*, deprecated, renamed: "cylBadgeOnceLeftRightAnimationMoveDistance(_:repeatTimes:duration:)")
    @nonobjc
    public class func cyl_badge_once_leftRight_AnimationMoveDistance(_ moveDistance: CGFloat, repeatTimes: Float, duration: TimeInterval) -> CABasicAnimation { Self.cylBadgeOnceLeftRightAnimationMoveDistance(moveDistance, repeatTimes: repeatTimes, duration: duration) }

    /**
     [EN] Deprecated: renamed to `cylBadgeOnceRightLeftAnimationMoveDistance`.
     [CN] 已废弃：已改名为 `cylBadgeOnceRightLeftAnimationMoveDistance`。
     */
    @available(*, deprecated, renamed: "cylBadgeOnceRightLeftAnimationMoveDistance(_:repeatTimes:duration:)")
    @nonobjc
    public class func cyl_badge_once_rightLeft_AnimationMoveDistance(_ moveDistance: CGFloat, repeatTimes: Float, duration: TimeInterval) -> CABasicAnimation { Self.cylBadgeOnceRightLeftAnimationMoveDistance(moveDistance, repeatTimes: repeatTimes, duration: duration) }

    /**
     [EN] Deprecated: renamed to `cylBadgeOnceRollingAnimationRepeatTimes`.
     [CN] 已废弃：已改名为 `cylBadgeOnceRollingAnimationRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylBadgeOnceRollingAnimationRepeatTimes(_:duration:)")
    @nonobjc
    public class func cyl_badge_once_rolling_AnimationRepeatTimes(_ repeatTimes: Float, duration: TimeInterval) -> CABasicAnimation { Self.cylBadgeOnceRollingAnimationRepeatTimes(repeatTimes, duration: duration) }

    /**
     [EN] Deprecated: renamed to `cylSpringAnimation`.
     [CN] 已废弃：已改名为 `cylSpringAnimation`。
     */
    @available(*, deprecated, renamed: "cylSpringAnimation(forDuration:)")
    @nonobjc
    public class func cyl_springAnimation(forDuration duration: TimeInterval) -> CAKeyframeAnimation { Self.cylSpringAnimation(forDuration: duration) }

    /**
     [EN] Deprecated: renamed to `cylOpacityForeverAnimation`.
     [CN] 已废弃：已改名为 `cylOpacityForeverAnimation`。
     */
    @available(*, deprecated, renamed: "cylOpacityForeverAnimation(_:)")
    @nonobjc
    public class func cyl_opacityForever_Animation(_ time: Float) -> CABasicAnimation { Self.cylOpacityForeverAnimation(time) }

    /**
     [EN] Deprecated: renamed to `cylOpacityTimesAnimation`.
     [CN] 已废弃：已改名为 `cylOpacityTimesAnimation`。
     */
    @available(*, deprecated, renamed: "cylOpacityTimesAnimation(_:durTimes:)")
    @nonobjc
    public class func cyl_opacityTimes_Animation(_ repeatTimes: Float, durTimes time: Float) -> CABasicAnimation { Self.cylOpacityTimesAnimation(repeatTimes, durTimes: time) }

    /**
     [EN] Deprecated: renamed to `cylRotation`.
     [CN] 已废弃：已改名为 `cylRotation`。
     */
    @available(*, deprecated, renamed: "cylRotation(_:degree:direction:repeatCount:)")
    @nonobjc
    public class func cyl_rotation(_ dur: Float, degree: Float, direction axis: CYLAxis, repeatCount: Int32) -> CABasicAnimation { Self.cylRotation(dur, degree: degree, direction: axis, repeatCount: repeatCount) }

    /**
     [EN] Deprecated: renamed to `cylScale`.
     [CN] 已废弃：已改名为 `cylScale`。
     */
    @available(*, deprecated, renamed: "cylScale(from:toScale:durTimes:rep:)")
    @nonobjc
    public class func cyl_scale(from fromScale: CGFloat, toScale: CGFloat, durTimes time: Float, rep repeatTimes: Float) -> CABasicAnimation { Self.cylScale(from: fromScale, toScale: toScale, durTimes: time, rep: repeatTimes) }

    /**
     [EN] Deprecated: renamed to `cylShakeAnimationRepeatTimes`.
     [CN] 已废弃：已改名为 `cylShakeAnimationRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylShakeAnimationRepeatTimes(_:durTimes:forObj:)")
    @nonobjc
    public class func cyl_shake_AnimationRepeatTimes(_ repeatTimes: Float, durTimes time: Float, forObj obj: Any) -> CAKeyframeAnimation { Self.cylShakeAnimationRepeatTimes(repeatTimes, durTimes: time, forObj: obj) }

    /**
     [EN] Deprecated: renamed to `cylBounceAnimationRepeatTimes`.
     [CN] 已废弃：已改名为 `cylBounceAnimationRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylBounceAnimationRepeatTimes(_:durTimes:forObj:)")
    @nonobjc
    public class func cyl_bounce_AnimationRepeatTimes(_ repeatTimes: Float, durTimes time: Float, forObj obj: Any) -> CAKeyframeAnimation { Self.cylBounceAnimationRepeatTimes(repeatTimes, durTimes: time, forObj: obj) }

    /**
     [EN] Deprecated: renamed to `cylBadgeOnceScaleAnimationRepeatTimes`.
     [CN] 已废弃：已改名为 `cylBadgeOnceScaleAnimationRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylBadgeOnceScaleAnimationRepeatTimes(_:durTimes:)")
    @nonobjc
    public class func cyl_badge_once_scale_AnimationRepeatTimes(_ repeatTimes: Float, durTimes time: Float) -> CABasicAnimation { Self.cylBadgeOnceScaleAnimationRepeatTimes(repeatTimes, durTimes: time) }

    /**
     [EN] Deprecated: renamed to `cylBadgeOnceLeftRightAnimationMoveDistance`.
     [CN] 已废弃：已改名为 `cylBadgeOnceLeftRightAnimationMoveDistance`。
     */
    @available(*, deprecated, renamed: "cylBadgeOnceLeftRightAnimationMoveDistance(_:repeatTimes:durTimes:)")
    @nonobjc
    public class func cyl_badge_once_leftRight_AnimationMoveDistance(_ moveDistance: CGFloat, repeatTimes: Float, durTimes time: Float) -> CABasicAnimation { Self.cylBadgeOnceLeftRightAnimationMoveDistance(moveDistance, repeatTimes: repeatTimes, durTimes: time) }

    /**
     [EN] Deprecated: renamed to `cylBadgeOnceRightLeftAnimationMoveDistance`.
     [CN] 已废弃：已改名为 `cylBadgeOnceRightLeftAnimationMoveDistance`。
     */
    @available(*, deprecated, renamed: "cylBadgeOnceRightLeftAnimationMoveDistance(_:repeatTimes:durTimes:)")
    @nonobjc
    public class func cyl_badge_once_rightLeft_AnimationMoveDistance(_ moveDistance: CGFloat, repeatTimes: Float, durTimes time: Float) -> CABasicAnimation { Self.cylBadgeOnceRightLeftAnimationMoveDistance(moveDistance, repeatTimes: repeatTimes, durTimes: time) }

    /**
     [EN] Deprecated: renamed to `cylBadgeOnceRollingAnimationRepeatTimes`.
     [CN] 已废弃：已改名为 `cylBadgeOnceRollingAnimationRepeatTimes`。
     */
    @available(*, deprecated, renamed: "cylBadgeOnceRollingAnimationRepeatTimes(_:durTimes:)")
    @nonobjc
    public class func cyl_badge_once_rolling_AnimationRepeatTimes(_ repeatTimes: Float, durTimes time: Float) -> CABasicAnimation { Self.cylBadgeOnceRollingAnimationRepeatTimes(repeatTimes, durTimes: time) }
}

extension CAAnimation {
    /**
     [EN] Deprecated: renamed to `cylBadgeOnceFade`.
     [CN] 已废弃：已改名为 `cylBadgeOnceFade`。
     */
    @available(*, deprecated, renamed: "cylBadgeOnceFade(inAnimationRepeatTimes:duration:)")
    @nonobjc
    public class func cyl_badge_once_fade(in_AnimationRepeatTimes repeatTimes: Float, duration: TimeInterval) -> CABasicAnimation { Self.cylBadgeOnceFade(inAnimationRepeatTimes: repeatTimes, duration: duration) }

    /**
     [EN] Deprecated: renamed to `cylBadgeOnceFade`.
     [CN] 已废弃：已改名为 `cylBadgeOnceFade`。
     */
    @available(*, deprecated, renamed: "cylBadgeOnceFade(inAnimationRepeatTimes:durTimes:)")
    @nonobjc
    public class func cyl_badge_once_fade(in_AnimationRepeatTimes repeatTimes: Float, durTimes time: Float) -> CABasicAnimation { Self.cylBadgeOnceFade(inAnimationRepeatTimes: repeatTimes, durTimes: time) }
}
