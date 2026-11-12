//
//  UIView+CYLUtils.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Translated from Objective-C (docs/Swift-Migration.md); Objective-C callers keep the declarations in
 *      `UIView+CYLUtils.h`.
 * [CN] 已从 Objective-C 翻译为 Swift（docs/Swift-Migration.md）；Objective-C 调用方继续使用 `UIView+CYLUtils.h` 中的声明。
 */
extension UIView {

    /**
     * [EN] Hides (or shows) the view and turns its interaction off (or on), with its opacity and alpha.
     * [CN] 隐藏（或显示）视图，同时关闭（或开启）交互，并设置 opaque 与 alpha。
     */
    @objc(cyl_setHidden:)
    public func cyl_setHidden(_ hidden: Bool) { // NOSONAR: kept API name
        isOpaque = !hidden
        isHidden = hidden
        alpha = hidden ? 0 : 1
        isUserInteractionEnabled = !hidden
    }

    /**
     * [EN] Whether the view cannot be seen: hidden, transparent, without a superview or with a zero size.
     * [CN] 视图是否不可见：隐藏、透明、没有父视图或尺寸为零。
     */
    @objc(cyl_isInvisiable)
    public func cyl_isInvisiable() -> Bool { // NOSONAR: kept API name
        isHidden || alpha <= 0.01 || superview == nil || frame.size == .zero
    }

    /**
     * [EN] Whether the view cannot respond to touches: invisible, not interactive, or a placeholder.
     * [CN] 视图是否无法响应触摸：不可见、关闭了交互或是占位视图。
     */
    @objc(cyl_canNotResponseEvent)
    public func cyl_canNotResponseEvent() -> Bool { // NOSONAR: kept API name
        cyl_isInvisiable() || !isUserInteractionEnabled || cyl_isPlaceholder
    }

    /**
     * [EN] Scales the view up, down and back (0.5 s), then calls `completion`.
     * [CN] 将视图放大、缩小再复原（0.5 秒），然后调用 `completion`。
     */
    @objc(cyl_addScaleBounceAnimationWithCompletion:)
    public func cyl_addScaleBounceAnimation(completion: ((Bool) -> Void)?) { // NOSONAR: kept API name
        transform = .identity
        UIView.animateKeyframes(withDuration: 0.5, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 1.0 / 3.0) {
                self.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
            }
            UIView.addKeyframe(withRelativeStartTime: 1.0 / 3.0, relativeDuration: 1.0 / 3.0) {
                self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }
            UIView.addKeyframe(withRelativeStartTime: 2.0 / 3.0, relativeDuration: 1.0 / 3.0) {
                self.transform = .identity
            }
        }, completion: completion)
    }

    /**
     * [EN] The receiver or its nearest ancestor that is a `UIControl`, searching up to `stopView` (not included).
     * [CN] 接收者或其最近的 `UIControl` 祖先视图，向上查找到 `stopView` 为止（不含）。
     */
    @objc(cyl_nearestControlBelowView:)
    public func cyl_nearestControl(below stopView: UIView?) -> UIControl? { // NOSONAR: kept API name
        var view: UIView? = self
        while let current = view, current !== stopView {
            if let control = current as? UIControl {
                return control
            }
            view = current.superview
        }
        return nil
    }
}
