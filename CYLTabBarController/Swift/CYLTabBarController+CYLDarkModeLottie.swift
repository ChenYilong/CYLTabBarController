//
//  CYLTabBarController+CYLDarkModeLottie.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * FIX: issue #442
 * [EN] Light / dark switches: the animation tints are applied again, the themes follow the new trait collection, and the
 *      tab animations that have a dark version (`CYLTabBarItemAnimationStyleRegistry`) are reloaded for the current style.
 *      `-traitCollectionDidChange:` stays in CYLTabBarController.m (an override in an extension of a public class would have
 *      to be public) and only calls `-cyl_traitCollectionDidChangeFrom:`. Internal Swift members with Objective-C selectors,
 *      declared in CYLTabBarController+CYLPrivate.h. Translated from Objective-C (docs/Swift-Migration.md, step 106).
 * [CN] 浅色 / 深色切换：重新应用动画着色，主题跟随新的 trait collection，有深色版本的 Tab 动画（`CYLTabBarItemAnimationStyleRegistry`）按当前样式
 *      重新加载。`-traitCollectionDidChange:` 留在 CYLTabBarController.m（在公开类的扩展中重写必须是 public），只调用
 *      `-cyl_traitCollectionDidChangeFrom:`。以 Objective-C selector 实现的内部 Swift 成员，声明于 CYLTabBarController+CYLPrivate.h。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 106 步）。
 */
extension CYLTabBarController {

    @objc(cyl_traitCollectionDidChangeFrom:)
    func cylTraitCollectionDidChange(from previousTraitCollection: UITraitCollection?) {
        cylSetNeedsApplyTabBarItemAnimationTintColors()
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        let current = traitCollection
        DispatchQueue.main.async {
            CYLThemeManagerCenter.updateThemes(for: current)
        }
        guard CYLTabBarItemAnimationStyleRegistry.shared.hasStyleVariants(), CYLTabBarItemAnimationCore.service != nil else { return }
        DispatchQueue.main.async { [weak self] in
            self?.cylReloadLottieAnimationViewsForCurrentStyle()
        }
    }

    @objc(cyl_reloadLottieAnimationViewsForCurrentStyle)
    func cylReloadLottieAnimationViewsForCurrentStyle() {
        guard CYLTabBarItemAnimationStyleRegistry.shared.hasStyleVariants() else { return }
        var views: [UIView] = [tabBar]
        // [EN] The stored tab bar only: the getter would create one. [CN] 只取已保存的 TabBar：getter 会创建新的 TabBar。
        if let stored = cylPrivate.cylStoredTabBar(), stored !== tabBar {
            views.append(stored)
        }
        let selector = NSSelectorFromString("cyl_reloadTabBarItemAnimationViewForCurrentStyle")
        while let view = views.popLast() {
            if view is UIControl, view.responds(to: selector) {
                _ = view.perform(selector)
            }
            views.append(contentsOf: view.subviews)
        }
    }
}
