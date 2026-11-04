//
//  GalleryAnimations.swift
//  CYLTabBarGallery
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

// [EN] The tab button animations of the gallery, through `CYLTabButtonAnimation`: select, reselect, highlight /
//      dehighlight (pressed) and badge-changed. The `@objc(...)` names pin the Objective-C selectors the library calls.
// [CN] 图库中的 Tab 按钮动画，基于 `CYLTabButtonAnimation`：选中、重复点击、按下 / 抬起、角标变化。`@objc(...)` 固定本库调用的
//      Objective-C 方法名。

/// [EN] A springy scale on select and on reselect. [CN] 选中与重复点击时的弹性缩放。
final class GalleryBounceAnimation: NSObject, CYLTabButtonAnimation {

    @objc(cyl_playSelectAnimationWithTabButton:iconView:titleLabel:)
    func cyl_playSelectAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {  // NOSONAR swift:S100: Swift import name of the Objective-C protocol method, kept so it matches the requirement.
        Gallery.playKeyframes(on: iconView, keyPath: "transform.scale", values: Gallery.bounceValues, duration: 0.6)
    }

    @objc(cyl_playReselectAnimationWithTabButton:iconView:titleLabel:)
    func cyl_playReselectAnimation(withTabButton button: UIControl, iconView: UIView, titleLabel: UILabel?) {  // NOSONAR swift:S100: Swift import name of the Objective-C protocol method, kept so it matches the requirement.
        cyl_playSelectAnimation(withTabButton: button, iconView: iconView, titleLabel: titleLabel)
    }
}

/// [EN] Icons drawn 15% larger; a press shrinks them to 80% and the release brings them back.
/// [CN] 图标放大 15% 显示；按下缩小到 80%，抬起后恢复。
final class GalleryHighlightableAnimation: NSObject, CYLTabButtonAnimation {

    static let largeScale: CGFloat = 1.15

    @objc(cyl_playSelectAnimationWithTabButton:iconView:titleLabel:)
    func cyl_playSelectAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {  // NOSONAR swift:S100: Swift import name of the Objective-C protocol method, kept so it matches the requirement.
        iconView.transform = CGAffineTransform(scaleX: Self.largeScale, y: Self.largeScale)
    }

    @objc(cyl_playHighlightAnimationWithTabButton:iconView:titleLabel:)
    func cyl_playHighlightAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {  // NOSONAR swift:S100: Swift import name of the Objective-C protocol method, kept so it matches the requirement.
        UIView.animate(withDuration: 0.2) {
            iconView.transform = CGAffineTransform(scaleX: Self.largeScale * 0.8, y: Self.largeScale * 0.8)
        }
    }

    @objc(cyl_playDehighlightAnimationWithTabButton:iconView:titleLabel:)
    func cyl_playDehighlightAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {  // NOSONAR swift:S100: Swift import name of the Objective-C protocol method, kept so it matches the requirement.
        UIView.animate(withDuration: 0.2) {
            iconView.transform = CGAffineTransform(scaleX: Self.largeScale, y: Self.largeScale)
        }
    }
}

/// [EN] Press animation plus a full turn on reselect. [CN] 按下动画，加上重复点击时旋转一周。
final class GalleryPressAndReselectAnimation: CYLTabButtonPressAnimation {

    @objc(cyl_playReselectAnimationWithTabButton:iconView:titleLabel:)
    func cyl_playReselectAnimation(withTabButton _: UIControl, iconView: UIView, titleLabel _: UILabel?) {  // NOSONAR swift:S100: Swift import name of the Objective-C protocol method, kept so it matches the requirement.
        Gallery.playKeyframes(on: iconView, keyPath: "transform.rotation.z", values: [0, Double.pi, 2 * Double.pi], duration: 0.5)
    }
}

/// [EN] What a tab does when its badge appears or changes (`UITabBarItem.badgeValue`).
/// [CN] Tab 的角标出现或变化（`UITabBarItem.badgeValue`）时的动画。
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

    @objc(cyl_playSelectAnimationWithTabButton:iconView:titleLabel:)
    func cyl_playSelectAnimation(withTabButton _: UIControl, iconView _: UIView, titleLabel _: UILabel?) {  // NOSONAR swift:S100: Swift import name of the Objective-C protocol method, kept so it matches the requirement.
        // [EN] Intentionally empty: this animation only reacts to badge changes; selecting the tab plays nothing.
        // [CN] 有意留空：此动画只响应角标变化，选中 Tab 时不播放任何动画。
    }

    @objc(cyl_playBadgeChangedAnimationWithTabButton:iconView:badgeView:)
    func cyl_playBadgeChangedAnimation(withTabButton _: UIControl, iconView: UIView, badgeView: UIView?) {  // NOSONAR swift:S100: Swift import name of the Objective-C protocol method, kept so it matches the requirement.
        switch style {
        case .jumpingIcon:
            Gallery.playKeyframes(on: iconView, keyPath: "transform.translation.y", values: [0, -8, 4, -4, 3, -2, 0], duration: 0.6)
        case .scalingBadge:
            Gallery.playKeyframes(on: badgeView ?? iconView, keyPath: "transform.scale", values: Gallery.bounceValues, duration: 0.6)
        }
    }
}
