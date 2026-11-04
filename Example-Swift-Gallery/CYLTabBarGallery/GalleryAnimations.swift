//
//  GalleryAnimations.swift
//  CYLTabBarGallery
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

// [EN] The tab button animations of the gallery, built from closures with `CYLTabButtonBlockAnimation`: select, reselect,
//      highlight / dehighlight (pressed) and badge-changed. No protocol method is written in Swift.
// [CN] 图库中的 Tab 按钮动画，用 `CYLTabButtonBlockAnimation` 由闭包组成：选中、重复点击、按下 / 抬起、角标变化。Swift 中无需编写协议方法。

/// [EN] A springy scale on select and on reselect. [CN] 选中与重复点击时的弹性缩放。
final class GalleryBounceAnimation: CYLTabButtonBlockAnimation {

    override init() {
        super.init()
        let bounce: CYLTabButtonAnimationBlock = { _, iconView, _ in
            Gallery.playKeyframes(on: iconView, keyPath: "transform.scale", values: Gallery.bounceValues, duration: 0.6)
        }
        selectAnimation = bounce
        reselectAnimation = bounce
    }
}

/// [EN] Icons drawn 15% larger; a press shrinks them to 80% and the release brings them back.
/// [CN] 图标放大 15% 显示；按下缩小到 80%，抬起后恢复。
final class GalleryHighlightableAnimation: CYLTabButtonBlockAnimation {

    static let largeScale: CGFloat = 1.15

    override init() {
        super.init()
        let largeScale = Self.largeScale
        selectAnimation = { _, iconView, _ in
            iconView.transform = CGAffineTransform(scaleX: largeScale, y: largeScale)
        }
        highlightAnimation = { _, iconView, _ in
            UIView.animate(withDuration: 0.2) {
                iconView.transform = CGAffineTransform(scaleX: largeScale * 0.8, y: largeScale * 0.8)
            }
        }
        dehighlightAnimation = { _, iconView, _ in
            UIView.animate(withDuration: 0.2) {
                iconView.transform = CGAffineTransform(scaleX: largeScale, y: largeScale)
            }
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
            press.cyl_playHighlightAnimation?(withTabButton: button, iconView: iconView, titleLabel: titleLabel)
        }
        dehighlightAnimation = { button, iconView, titleLabel in
            press.cyl_playDehighlightAnimation?(withTabButton: button, iconView: iconView, titleLabel: titleLabel)
        }
        reselectAnimation = { _, iconView, _ in
            Gallery.playKeyframes(on: iconView, keyPath: "transform.rotation.z", values: [0, Double.pi, 2 * Double.pi], duration: 0.5)
        }
    }
}

/// [EN] What a tab does when its badge appears or changes (`UITabBarItem.badgeValue`); selecting it plays nothing.
/// [CN] Tab 的角标出现或变化（`UITabBarItem.badgeValue`）时的动画；选中时不播放动画。
final class GalleryBadgeAnimation: CYLTabButtonBlockAnimation {

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
        switch style {
        case .jumpingIcon:
            badgeChangedAnimation = { _, iconView, _ in
                Gallery.playKeyframes(on: iconView, keyPath: "transform.translation.y", values: [0, -8, 4, -4, 3, -2, 0], duration: 0.6)
            }
        case .scalingBadge:
            badgeChangedAnimation = { _, iconView, badgeView in
                Gallery.playKeyframes(on: badgeView ?? iconView, keyPath: "transform.scale", values: Gallery.bounceValues, duration: 0.6)
            }
        }
    }
}
