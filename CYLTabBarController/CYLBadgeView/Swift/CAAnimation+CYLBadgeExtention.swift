//
//  CAAnimation+CYLBadgeExtention.swift
//  CYLBadgeView
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] A rotation axis. Translated from Objective-C (docs/Swift-Migration.md); Objective-C sees `CYLAxisX` … through
 *      `CYLSwiftInterface.h`.
 * [CN] 旋转轴。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 通过 `CYLSwiftInterface.h` 看到 `CYLAxisX` …。
 */
@objc public enum CYLAxis: UInt {
    /**
     * [EN] The x axis.
     * [CN] x 轴。
     */
    case X = 0
    /**
     * [EN] The y axis.
     * [CN] y 轴。
     */
    case Y
    /**
     * [EN] The z axis.
     * [CN] z 轴。
     */
    case Z
}

/**
 * [EN] The badge animations. Translated from Objective-C (docs/Swift-Migration.md); Objective-C callers get the
 *      declarations from `CYLSwiftInterface.h`; the Swift names are the ones Clang imported (some read oddly, such as
 *      `cyl_badge_once_fade(in_AnimationRepeatTimes:durTimes:)`, and are kept for compatibility).
 * [CN] 角标动画。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 调用方从 `CYLSwiftInterface.h` 获得声明；Swift 名称与
 *      Clang 原先导入的名称相同（有些读起来不自然，例如 `cyl_badge_once_fade(in_AnimationRepeatTimes:durTimes:)`，为兼容而保留）。
 */
extension CAAnimation {

    // MARK: - Opacity, rotation, scale

    /**
     * [EN] Fades between 1 and 0.1 forever.
     * [CN] 在 1 与 0.1 之间无限循环淡入淡出。
     */
    @objc(cyl_opacityForeverAnimationWithDuration:)
    public class func cyl_opacityForeverAnimation(withDuration duration: TimeInterval) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = NSNumber(value: 1.0 as Float)
        animation.toValue = NSNumber(value: 0.1 as Float)
        animation.autoreverses = true
        animation.duration = duration
        animation.repeatCount = .greatestFiniteMagnitude
        animation.isRemovedOnCompletion = false
        animation.timingFunction = CAMediaTimingFunction(name: .linear)
        animation.fillMode = .forwards
        return animation
    }

    /**
     * [EN] Fades between 1 and 0.4 a number of times.
     * [CN] 在 1 与 0.4 之间淡入淡出若干次。
     */
    @objc(cyl_opacityTimesAnimationRepeatTimes:duration:)
    public class func cyl_opacityTimesAnimationRepeatTimes(_ repeatTimes: Float, duration: TimeInterval) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = NSNumber(value: 1.0 as Float)
        animation.toValue = NSNumber(value: 0.4 as Float)
        animation.repeatCount = repeatTimes
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        animation.autoreverses = true
        return animation
    }

    /**
     * [EN] Rotates by `degree` (radians) around an axis, cumulatively.
     * [CN] 绕某个轴累计旋转 `degree`（弧度）。
     */
    @objc(cyl_rotationAnimationWithDuration:degree:direction:repeatCount:)
    public class func cyl_rotationAnimation(withDuration duration: TimeInterval, degree: CGFloat, direction axis: CYLAxis,
                                            repeatCount: Float) -> CABasicAnimation {
        let keyPaths = ["transform.rotation.x", "transform.rotation.y", "transform.rotation.z"]
        let animation = CABasicAnimation(keyPath: keyPaths[Int(axis.rawValue)])
        animation.fromValue = NSNumber(value: 0 as Float)
        animation.toValue = NSNumber(value: Double(degree))
        animation.duration = duration
        animation.autoreverses = false
        animation.isCumulative = true
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.repeatCount = repeatCount
        return animation
    }

    /**
     * [EN] Scales between two values, back and forth.
     * [CN] 在两个比例之间来回缩放。
     */
    @objc(cyl_scaleAnimationFromScale:toScale:duration:repeatTimes:)
    public class func cyl_scale(fromScale: CGFloat, toScale: CGFloat, duration: TimeInterval,
                                repeatTimes: Float) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = NSNumber(value: Double(fromScale))
        animation.toValue = NSNumber(value: Double(toScale))
        animation.duration = duration
        animation.autoreverses = true
        animation.repeatCount = repeatTimes
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        return animation
    }

    // MARK: - Shake and bounce of a layer's position

    /**
     * [EN] Shakes a layer (`obj`) left and right by a quarter of its width.
     * [CN] 让图层（`obj`）左右摇晃其宽度的四分之一。
     */
    @objc(cyl_shakeAnimationRepeatTimes:duration:forObj:)
    public class func cyl_shakeAnimationRepeatTimes(_ repeatTimes: Float, duration: TimeInterval,
                                                    forObj obj: Any) -> CAKeyframeAnimation {
        positionAnimation(repeatTimes, duration, obj) { position, size in
            let offset = size.width / 4
            return [position, CGPoint(x: position.x - offset, y: position.y), position,
                    CGPoint(x: position.x + offset, y: position.y), position]
        }
    }

    /**
     * [EN] Bounces a layer (`obj`) up and down by a quarter of its height.
     * [CN] 让图层（`obj`）上下弹跳其高度的四分之一。
     */
    @objc(cyl_bounceAnimationRepeatTimes:duration:forObj:)
    public class func cyl_bounceRepeatTimes(_ repeatTimes: Float, duration: TimeInterval,
                                            forObj obj: Any) -> CAKeyframeAnimation {
        positionAnimation(repeatTimes, duration, obj) { position, size in
            let offset = size.height / 4
            return [position, CGPoint(x: position.x, y: position.y - offset), position,
                    CGPoint(x: position.x, y: position.y + offset), position]
        }
    }

    // MARK: - Relative shake and bounce

    /**
     * [EN] Shakes by `offset` points, relative to wherever the layer is (`transform.translation.x`).
     * [CN] 相对于图层当前位置左右摇晃 `offset` 点（`transform.translation.x`）。
     */
    @objc(cyl_shakeAnimationRepeatTimes:duration:offset:)
    public class func cyl_shakeAnimationRepeatTimes(_ repeatTimes: Float, duration: TimeInterval,
                                                    offset: CGFloat) -> CAKeyframeAnimation {
        translationAnimation("transform.translation.x", repeatTimes, duration, offset)
    }

    /**
     * [EN] Bounces by `offset` points, relative to wherever the layer is (`transform.translation.y`).
     * [CN] 相对于图层当前位置上下弹跳 `offset` 点（`transform.translation.y`）。
     */
    @objc(cyl_bounceAnimationRepeatTimes:duration:offset:)
    public class func cyl_bounceRepeatTimes(_ repeatTimes: Float, duration: TimeInterval,
                                            offset: CGFloat) -> CAKeyframeAnimation {
        translationAnimation("transform.translation.y", repeatTimes, duration, offset)
    }

    // MARK: - One-time badge animations

    /**
     * [EN] Scales in from 2.7 to 1.
     * [CN] 从 2.7 倍缩放到 1 倍。
     */
    @objc(cyl_badge_once_scale_AnimationRepeatTimes:duration:)
    public class func cyl_badge_once_scale_AnimationRepeatTimes(_ repeatTimes: Float,
                                                                duration: TimeInterval) -> CABasicAnimation {
        onceAnimation("transform.scale", from: 2.7, to: 1, repeatTimes, duration, .easeInEaseOut)
    }

    /**
     * [EN] Slides in from the left by `moveDistance`.
     * [CN] 从左侧滑入 `moveDistance`。
     */
    @objc(cyl_badge_once_leftRight_AnimationMoveDistance:repeatTimes:duration:)
    public class func cyl_badge_once_leftRight_AnimationMoveDistance(_ moveDistance: CGFloat, repeatTimes: Float,
                                                                     duration: TimeInterval) -> CABasicAnimation {
        onceAnimation("transform.translation.x", from: -Double(moveDistance), to: 0, repeatTimes, duration, .easeOut)
    }

    /**
     * [EN] Slides in from the right by `moveDistance`.
     * [CN] 从右侧滑入 `moveDistance`。
     */
    @objc(cyl_badge_once_rightLeft_AnimationMoveDistance:repeatTimes:duration:)
    public class func cyl_badge_once_rightLeft_AnimationMoveDistance(_ moveDistance: CGFloat, repeatTimes: Float,
                                                                     duration: TimeInterval) -> CABasicAnimation {
        onceAnimation("transform.translation.x", from: Double(moveDistance), to: 0, repeatTimes, duration, .easeOut)
    }

    /**
     * [EN] Fades in from 0 to 1.
     * [CN] 从 0 淡入到 1。
     */
    @objc(cyl_badge_once_fadeIn_AnimationRepeatTimes:duration:)
    public class func cyl_badge_once_fade(in_AnimationRepeatTimes repeatTimes: Float,
                                          duration: TimeInterval) -> CABasicAnimation {
        onceAnimation("opacity", from: 0, to: 1, repeatTimes, duration, .easeIn)
    }

    /**
     * [EN] Rolls in by half a turn.
     * [CN] 旋转半圈进入。
     */
    @objc(cyl_badge_once_rolling_AnimationRepeatTimes:duration:)
    public class func cyl_badge_once_rolling_AnimationRepeatTimes(_ repeatTimes: Float,
                                                                  duration: TimeInterval) -> CABasicAnimation {
        onceAnimation("transform.rotation.z", from: Double.pi, to: 0, repeatTimes, duration, .easeInEaseOut)
    }

    /**
     * [EN] A spring of the scale (0.85, 1.15, 0.9, 1) over `duration`.
     * [CN] 在 `duration` 内的缩放弹簧效果（0.85、1.15、0.9、1）。
     */
    @objc(cyl_springAnimationForDuration:)
    public class func cyl_springAnimation(forDuration duration: TimeInterval) -> CAKeyframeAnimation {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [0.85, 1.15, 0.9, 1.0]
        animation.keyTimes = [0.0, 0.15, 0.3, 0.45].map { NSNumber(value: $0 / duration) }
        animation.duration = duration
        return animation
    }

    // MARK: - Original signatures (kept for compatibility)

    /**
     * [EN] Kept for compatibility: `cyl_opacityForeverAnimation(withDuration:)`.
     * [CN] 为兼容保留：`cyl_opacityForeverAnimation(withDuration:)`。
     */
    @objc(cyl_opacityForever_Animation:)
    public class func cyl_opacityForever_Animation(_ time: Float) -> CABasicAnimation {
        cyl_opacityForeverAnimation(withDuration: TimeInterval(time))
    }

    /**
     * [EN] Kept for compatibility: `cyl_opacityTimesAnimationRepeatTimes(_:duration:)`.
     * [CN] 为兼容保留：`cyl_opacityTimesAnimationRepeatTimes(_:duration:)`。
     */
    @objc(cyl_opacityTimes_Animation:durTimes:)
    public class func cyl_opacityTimes_Animation(_ repeatTimes: Float, durTimes time: Float) -> CABasicAnimation {
        cyl_opacityTimesAnimationRepeatTimes(repeatTimes, duration: TimeInterval(time))
    }

    /**
     * [EN] Kept for compatibility: `cyl_rotationAnimation(withDuration:degree:direction:repeatCount:)`.
     * [CN] 为兼容保留：`cyl_rotationAnimation(withDuration:degree:direction:repeatCount:)`。
     */
    @objc(cyl_rotation:degree:direction:repeatCount:)
    public class func cyl_rotation(_ dur: Float, degree: Float, direction axis: CYLAxis,
                                   repeatCount: Int32) -> CABasicAnimation {
        cyl_rotationAnimation(withDuration: TimeInterval(dur), degree: CGFloat(degree), direction: axis,
                              repeatCount: Float(repeatCount))
    }

    /**
     * [EN] Kept for compatibility: `cyl_scale(fromScale:toScale:duration:repeatTimes:)`.
     * [CN] 为兼容保留：`cyl_scale(fromScale:toScale:duration:repeatTimes:)`。
     */
    @objc(cyl_scaleFrom:toScale:durTimes:rep:)
    public class func cyl_scale(from fromScale: CGFloat, toScale: CGFloat, durTimes time: Float,
                                rep repeatTimes: Float) -> CABasicAnimation {
        cyl_scale(fromScale: fromScale, toScale: toScale, duration: TimeInterval(time), repeatTimes: repeatTimes)
    }

    /**
     * [EN] Kept for compatibility: `cyl_shakeAnimationRepeatTimes(_:duration:forObj:)`.
     * [CN] 为兼容保留：`cyl_shakeAnimationRepeatTimes(_:duration:forObj:)`。
     */
    @objc(cyl_shake_AnimationRepeatTimes:durTimes:forObj:)
    public class func cyl_shake_AnimationRepeatTimes(_ repeatTimes: Float, durTimes time: Float,
                                                     forObj obj: Any) -> CAKeyframeAnimation {
        cyl_shakeAnimationRepeatTimes(repeatTimes, duration: TimeInterval(time), forObj: obj)
    }

    /**
     * [EN] Kept for compatibility: `cyl_bounceRepeatTimes(_:duration:forObj:)`.
     * [CN] 为兼容保留：`cyl_bounceRepeatTimes(_:duration:forObj:)`。
     */
    @objc(cyl_bounce_AnimationRepeatTimes:durTimes:forObj:)
    public class func cyl_bounce_AnimationRepeatTimes(_ repeatTimes: Float, durTimes time: Float,
                                                      forObj obj: Any) -> CAKeyframeAnimation {
        cyl_bounceRepeatTimes(repeatTimes, duration: TimeInterval(time), forObj: obj)
    }

    /**
     * [EN] Kept for compatibility: `cyl_badge_once_scale_AnimationRepeatTimes(_:duration:)`.
     * [CN] 为兼容保留：`cyl_badge_once_scale_AnimationRepeatTimes(_:duration:)`。
     */
    @objc(cyl_badge_once_scale_AnimationRepeatTimes:durTimes:)
    public class func cyl_badge_once_scale_AnimationRepeatTimes(_ repeatTimes: Float,
                                                                durTimes time: Float) -> CABasicAnimation {
        cyl_badge_once_scale_AnimationRepeatTimes(repeatTimes, duration: TimeInterval(time))
    }

    /**
     * [EN] Kept for compatibility: `cyl_badge_once_leftRight_AnimationMoveDistance(_:repeatTimes:duration:)`.
     * [CN] 为兼容保留：`cyl_badge_once_leftRight_AnimationMoveDistance(_:repeatTimes:duration:)`。
     */
    @objc(cyl_badge_once_leftRight_AnimationMoveDistance:repeatTimes:durTimes:)
    public class func cyl_badge_once_leftRight_AnimationMoveDistance(_ moveDistance: CGFloat, repeatTimes: Float,
                                                                     durTimes time: Float) -> CABasicAnimation {
        cyl_badge_once_leftRight_AnimationMoveDistance(moveDistance, repeatTimes: repeatTimes, duration: TimeInterval(time))
    }

    /**
     * [EN] Kept for compatibility: `cyl_badge_once_rightLeft_AnimationMoveDistance(_:repeatTimes:duration:)`.
     * [CN] 为兼容保留：`cyl_badge_once_rightLeft_AnimationMoveDistance(_:repeatTimes:duration:)`。
     */
    @objc(cyl_badge_once_rightLeft_AnimationMoveDistance:repeatTimes:durTimes:)
    public class func cyl_badge_once_rightLeft_AnimationMoveDistance(_ moveDistance: CGFloat, repeatTimes: Float,
                                                                     durTimes time: Float) -> CABasicAnimation {
        cyl_badge_once_rightLeft_AnimationMoveDistance(moveDistance, repeatTimes: repeatTimes, duration: TimeInterval(time))
    }

    /**
     * [EN] Kept for compatibility: `cyl_badge_once_fade(in_AnimationRepeatTimes:duration:)`.
     * [CN] 为兼容保留：`cyl_badge_once_fade(in_AnimationRepeatTimes:duration:)`。
     */
    @objc(cyl_badge_once_fadeIn_AnimationRepeatTimes:durTimes:)
    public class func cyl_badge_once_fade(in_AnimationRepeatTimes repeatTimes: Float,
                                          durTimes time: Float) -> CABasicAnimation {
        cyl_badge_once_fade(in_AnimationRepeatTimes: repeatTimes, duration: TimeInterval(time))
    }

    /**
     * [EN] Kept for compatibility: `cyl_badge_once_rolling_AnimationRepeatTimes(_:duration:)`.
     * [CN] 为兼容保留：`cyl_badge_once_rolling_AnimationRepeatTimes(_:duration:)`。
     */
    @objc(cyl_badge_once_rolling_AnimationRepeatTimes:durTimes:)
    public class func cyl_badge_once_rolling_AnimationRepeatTimes(_ repeatTimes: Float,
                                                                  durTimes time: Float) -> CABasicAnimation {
        cyl_badge_once_rolling_AnimationRepeatTimes(repeatTimes, duration: TimeInterval(time))
    }

    // MARK: - Private

    private class func positionAnimation(_ repeatTimes: Float, _ duration: TimeInterval, _ obj: Any,
                                         _ points: (CGPoint, CGSize) -> [CGPoint]) -> CAKeyframeAnimation {
        assert(obj is CALayer, "invalid target")
        let layer = obj as? CALayer
        let animation = CAKeyframeAnimation()
        animation.keyPath = "position"
        animation.values = points(layer?.position ?? .zero, layer?.bounds.size ?? .zero).map { NSValue(cgPoint: $0) }
        animation.repeatCount = repeatTimes
        animation.duration = duration
        animation.fillMode = .forwards
        return animation
    }

    private class func translationAnimation(_ keyPath: String, _ repeatTimes: Float, _ duration: TimeInterval,
                                            _ offset: CGFloat) -> CAKeyframeAnimation {
        let safeOffset = offset.isFinite ? Double(offset) : 0
        let animation = CAKeyframeAnimation(keyPath: keyPath)
        animation.values = [0, -safeOffset, 0, safeOffset, 0]
        animation.repeatCount = repeatTimes.isNaN ? 0 : max(0, repeatTimes)
        animation.duration = (!duration.isFinite || duration <= 0) ? 1 : max(0.01, duration)
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        return animation
    }

    private class func onceAnimation(_ keyPath: String, from: Double, to: Double, _ repeatTimes: Float,
                                     _ duration: TimeInterval, _ timing: CAMediaTimingFunctionName) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = NSNumber(value: from)
        animation.toValue = NSNumber(value: to)
        animation.repeatCount = repeatTimes
        animation.duration = duration
        animation.isRemovedOnCompletion = false
        animation.fillMode = .forwards
        animation.timingFunction = CAMediaTimingFunction(name: timing)
        return animation
    }
}
