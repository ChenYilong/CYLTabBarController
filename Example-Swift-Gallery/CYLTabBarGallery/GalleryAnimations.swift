//
//  GalleryAnimations.swift
//  CYLTabBarGallery
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

// [EN] The tab button animations of the gallery: select, reselect, highlight / dehighlight (pressed) and badge-changed. Most
//      implement `CYLTabButtonAnimation` with its underscore-free methods (`cylPlay…`, the Swift names of
//      `-cylPlaySelectAnimationWithTabButton:…` etc.); one is made of closures with `CYLTabButtonBlockAnimation`.
// [CN] 图库中的 Tab 按钮动画：选中、重复点击、按下 / 抬起、角标变化。多数用 `CYLTabButtonAnimation` 的无下划线方法（`cylPlay…`，即
//      `-cylPlaySelectAnimationWithTabButton:…` 等的 Swift 名）实现；其中一个用 `CYLTabButtonBlockAnimation` 由闭包组成。

/// [EN] A springy scale on select and on reselect. [CN] 选中与重复点击时的弹性缩放。
final class GalleryBounceAnimation: NSObject, CYLTabButtonAnimation {

    func cylPlaySelectAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {
        Gallery.playKeyframes(on: iconView, keyPath: "transform.scale", values: Gallery.bounceValues, duration: 0.6)
    }

    func cylPlayReselectAnimation(withTabButton button: UIControl, iconView: UIView, titleLabel: UILabel?) {
        cylPlaySelectAnimation(withTabButton: button, iconView: iconView, titleLabel: titleLabel)
    }
}

/// [EN] Icons drawn 15% larger; a press shrinks them to 80% and the release brings them back.
/// [CN] 图标放大 15% 显示；按下缩小到 80%，抬起后恢复。
final class GalleryHighlightableAnimation: NSObject, CYLTabButtonAnimation {

    static let largeScale: CGFloat = 1.15

    func cylPlaySelectAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {
        iconView.transform = CGAffineTransform(scaleX: Self.largeScale, y: Self.largeScale)
    }

    func cylPlayHighlightAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {
        UIView.animate(withDuration: 0.2) {
            iconView.transform = CGAffineTransform(scaleX: Self.largeScale * 0.8, y: Self.largeScale * 0.8)
        }
    }

    func cylPlayDehighlightAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {
        UIView.animate(withDuration: 0.2) {
            iconView.transform = CGAffineTransform(scaleX: Self.largeScale, y: Self.largeScale)
        }
    }
}

/// [EN] The built-in press animation (`CYLTabButtonPressAnimation`) plus a full turn on reselect.
/// [CN] 内置的按下动画（`CYLTabButtonPressAnimation`），加上重复点击时旋转一周。
final class GalleryPressAndReselectAnimation: CYLTabButtonBlockAnimation {

    /// [EN] Typed as the protocol, so its optional methods can be called. [CN] 声明为协议类型，才能调用其可选方法。
    private let press: CYLTabButtonAnimation = CYLTabButtonPressAnimation()

    override init() {
        super.init()
        let press = self.press
        highlightAnimation = { button, iconView, titleLabel in
            press.cyl_playHighlight?(withTabButton: button, iconView: iconView, titleLabel: titleLabel)
        }
        dehighlightAnimation = { button, iconView, titleLabel in
            press.cyl_playDehighlight?(withTabButton: button, iconView: iconView, titleLabel: titleLabel)
        }
        reselectAnimation = { _, iconView, _ in
            Gallery.playKeyframes(on: iconView, keyPath: "transform.rotation.z", values: [0, Double.pi, 2 * Double.pi], duration: 0.5)
        }
    }
}

/// [EN] What a tab does when its badge appears or changes (`UITabBarItem.badgeValue`); selecting it plays nothing, since
///      only the badge-changed method is implemented.
/// [CN] Tab 的角标出现或变化（`UITabBarItem.badgeValue`）时的动画；只实现了角标变化方法，因此选中时不播放动画。
final class GalleryBadgeAnimation: NSObject, CYLTabButtonAnimation {

    enum Style {
        /// [EN] The icon jumps. [CN] 图标跳动。
        case jumpingIcon
        /// [EN] The badge scales in. [CN] 角标缩放弹出。
        case scalingBadge
    }

    let style: Style

    init(style: Style) {
        self.style = style
        super.init()
    }

    func cylPlayBadgeChangedAnimation(withTabButton _: UIControl, iconView: UIView, badgeView: UIView?) {
        switch style {
        case .jumpingIcon:
            Gallery.playKeyframes(on: iconView, keyPath: "transform.translation.y", values: [0, -8, 4, -4, 3, -2, 0], duration: 0.6)
        case .scalingBadge:
            Gallery.playKeyframes(on: badgeView ?? iconView, keyPath: "transform.scale", values: Gallery.bounceValues, duration: 0.6)
        }
    }
}
