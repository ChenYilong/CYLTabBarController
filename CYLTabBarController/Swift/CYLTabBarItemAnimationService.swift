//
//  CYLTabBarItemAnimationService.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Internal (not for apps): the dark mode and color variants of tab item animation files. Translated from Objective-C
 *      (docs/Swift-Migration.md); every selector is kept, so the Objective-C adopters are unchanged. Public only because a
 *      framework's generated Objective-C header exports public declarations only.
 * [CN] 内部使用（不供 App 使用）：TabBarItem 动画文件的深色模式与颜色变体。已从 Objective-C 翻译（docs/Swift-Migration.md）；所有
 *      selector 保持不变，Objective-C 的遵守者无需修改。之所以为 public，只是因为 framework 生成的 Objective-C 头文件只导出 public 声明。
 */
@objc(CYLTabBarItemAnimationStyleSource)
public protocol CYLTabBarItemAnimationStyleSource: NSObjectProtocol {
    /**
     * [EN] Whether any animation has a dark or color variant.
     * [CN] 是否有任何动画带有深色或颜色变体。
     */
    @objc(hasStyleVariants) func hasStyleVariants() -> Bool
    /**
     * [EN] Whether the animation at `URL` has a variant.
     * [CN] `URL` 处的动画是否带有变体。
     */
    @objc(hasStyleVariantForURL:) func hasStyleVariant(for URL: URL?) -> Bool
    /**
     * [EN] The file of the animation at `URL` for a trait collection (its dark file in dark mode).
     * [CN] `URL` 处的动画在某特征集合下对应的文件（深色模式下为其深色文件）。
     */
    @objc(URL:forTraitCollection:) func url(_ URL: URL?, for traitCollection: UITraitCollection?) -> URL?
    /**
     * [EN] The dark mode colors of the animation at `URL`.
     * [CN] `URL` 处动画的深色模式颜色。
     */
    @objc(darkColorsForURL:) func darkColors(for URL: URL?) -> [String: UIColor]?
    /**
     * [EN] The colors of the animation at `URL` in every mode.
     * [CN] `URL` 处动画在所有模式下的颜色。
     */
    @objc(colorsForURL:) optional func colors(for URL: URL?) -> [String: UIColor]?
}

/**
 * [EN] Internal (not for apps): what the tab bar offers an animation library to place its view in a tab button.
 * [CN] 内部使用（不供 App 使用）：TabBar 提供给动画库、用于把动画视图放入 Tab 按钮的功能。
 */
@objc(CYLTabBarItemAnimationHost)
public protocol CYLTabBarItemAnimationHost: NSObjectProtocol {
    /**
     * [EN] Whether `control` is the plus button.
     * [CN] `control` 是否为 PlusButton。
     */
    @objc(isPlusControl:) func isPlusControl(_ control: UIControl) -> Bool
    /**
     * [EN] Whether `animationView` is in place in `control`.
     * [CN] `animationView` 是否已在 `control` 中就位。
     */
    @objc(isAnimationView:readyInControl:) func isAnimationView(_ animationView: UIView?, readyIn control: UIControl) -> Bool
    /**
     * [EN] The animation size when the attributes give none.
     * [CN] 属性未给出尺寸时的动画尺寸。
     */
    @objc(defaultAnimationSize) func defaultAnimationSize() -> CGSize
    /**
     * [EN] Puts `animationView` in `control`, instead of its icon.
     * [CN] 将 `animationView` 放入 `control`，替代其图标。
     */
    @objc(showAnimationView:inControl:) func showAnimationView(_ animationView: UIView, in control: UIControl)
    /**
     * [EN] Replaces a subview the tab bar keeps track of.
     * [CN] 替换 TabBar 跟踪的子视图。
     */
    @objc(replaceTrackedSubview:withView:inSuperview:)
    func replaceTrackedSubview(_ view: UIView, with newView: UIView, inSuperview superview: UIView)
    /**
     * [EN] An animation view was added to `control`.
     * [CN] 已向 `control` 添加动画视图。
     */
    @objc(animationViewDidAddInControl:) func animationViewDidAdd(in control: UIControl)
    /**
     * [EN] The animation of `control` is about to play.
     * [CN] `control` 的动画即将播放。
     */
    @objc(animationWillPlayInControl:) func animationWillPlay(in control: UIControl)
}

/**
 * [EN] Internal (not for apps): the animation library behind tab item animations (Lottie, PAG, Rive, GIF).
 * [CN] 内部使用（不供 App 使用）：TabBarItem 动画背后的动画库（Lottie、PAG、Rive、GIF）。
 */
@objc(CYLTabBarItemAnimationService)
public protocol CYLTabBarItemAnimationService: NSObjectProtocol {
    /**
     * [EN] The animation view in `control`.
     * [CN] `control` 中的动画视图。
     */
    @objc(animationViewInControl:) func animationView(in control: UIControl) -> UIView?
    /**
     * [EN] Whether `view` is an animation view of this library.
     * [CN] `view` 是否为本动画库的动画视图。
     */
    @objc(isAnimationView:) func isAnimationView(_ view: UIView) -> Bool
    /**
     * [EN] Whether the animation of `control` is loaded.
     * [CN] `control` 的动画是否已加载。
     */
    @objc(isAnimationReadyInControl:) func isAnimationReady(in control: UIControl) -> Bool
    /**
     * [EN] Adds the animation at `URL` to `control`.
     * [CN] 向 `control` 添加 `URL` 处的动画。
     */
    @objc(addAnimationWithURL:size:contentMode:animationSpeed:toControl:)
    func addAnimation(with URL: URL?, size: CGSize, contentMode: UIView.ContentMode, animationSpeed: CGFloat,
                      to control: UIControl)
    /**
     * [EN] Changes the speed of the animation of `control`.
     * [CN] 修改 `control` 动画的速度。
     */
    @objc(setAnimationSpeed:inControl:) func setAnimationSpeed(_ animationSpeed: CGFloat, in control: UIControl)
    /**
     * [EN] Reloads the animation of `control` for the current light / dark style.
     * [CN] 按当前浅色/深色风格重新加载 `control` 的动画。
     */
    @objc(reloadAnimationForCurrentStyleInControl:) func reloadAnimationForCurrentStyle(in control: UIControl)
    /**
     * [EN] Plays the animation at `URL` in `control`.
     * [CN] 在 `control` 中播放 `URL` 处的动画。
     */
    @objc(playAnimationWithURL:size:defaultSelected:contentMode:inControl:)
    func playAnimation(with URL: URL, size: CGSize, defaultSelected: Bool, contentMode: UIView.ContentMode,
                       in control: UIControl)
    /**
     * [EN] Stops the animation of `control`.
     * [CN] 停止 `control` 的动画。
     */
    @objc(stopAnimationInControl:) func stopAnimation(in control: UIControl)
    /**
     * [EN] The library's own attribute key for a generic one, when the attributes use it.
     * [CN] 属性中使用的、与通用键对应的本动画库自己的属性键。
     */
    @objc(attributeKeyForGenericKey:inAttributes:)
    func attributeKey(forGenericKey genericKey: String, inAttributes attributes: [AnyHashable: Any]) -> String?
    /**
     * [EN] Remembers that `URL` came from `attributes`.
     * [CN] 记录 `URL` 来自 `attributes`。
     */
    @objc(bindAnimationURL:toAttributes:) func bindAnimationURL(_ URL: URL, toAttributes attributes: [AnyHashable: Any])
    /**
     * [EN] Replaces the animation of `control` with the one at `URL`.
     * [CN] 用 `URL` 处的动画替换 `control` 的动画。
     */
    @objc(replaceAnimationWithURL:size:contentMode:inControl:)
    optional func replaceAnimation(with URL: URL, size: CGSize, contentMode: UIView.ContentMode, in control: UIControl)
    /**
     * [EN] Applies the current colors to the animation of `control`.
     * [CN] 将当前颜色应用到 `control` 的动画。
     */
    @objc(refreshAnimationColorsInControl:) optional func refreshAnimationColors(in control: UIControl)
    /**
     * [EN] The file extensions this library plays.
     * [CN] 本动画库可播放的文件扩展名。
     */
    @objc(animationFileExtensions) optional func animationFileExtensions() -> [String]
}
