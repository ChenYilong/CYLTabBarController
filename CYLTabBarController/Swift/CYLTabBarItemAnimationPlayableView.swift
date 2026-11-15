//
//  CYLTabBarItemAnimationPlayableView.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] FIX: issue #415 — the playable view protocols of the `CYLTabBarItemAnimation` subspec, translated from Objective-C
//      (CYLTabBarItemAnimation/CYLTabBarItemAnimationPlayableView.h; docs/Swift-Migration.md). Their Objective-C names,
//      selectors and Swift names are unchanged. Declared in Swift so the Swift views that adopt them (Rive's) no longer make
//      the generated header import the umbrella header, which broke a CocoaPods build with the Rive subspec.
// [CN] `CYLTabBarItemAnimation` 子库的可播放视图协议，已从 Objective-C 翻译（CYLTabBarItemAnimation/CYLTabBarItemAnimationPlayableView.h；
//      docs/Swift-Migration.md）。Objective-C 名称、selector 与 Swift 名称都不变。在 Swift 中声明，遵守它们的 Swift 视图（Rive）就不会再让生成的
//      头文件导入总头文件；此前这会让引入 Rive 子库的 CocoaPods 构建失败。

/**
 * [EN] The short path for adding an animation library: a view that plays itself. A library whose view can play, stop and
 *      show its last frame adopts this protocol and `CYLTabBarItemAnimationViewProviding`, and registers a
 *      `CYLTabBarItemViewAnimator`; it needs no animator or player class of its own (Rive, GIF and SVGA do this). The methods
 *      keep a `cyl_` prefix in Objective-C and get camelCase names in Swift.
 * [CN] 新增动画库的简便方式：自己会播放的视图。如果动画库的视图能够播放、停止并显示最后一帧，只需遵守本协议与
 *      `CYLTabBarItemAnimationViewProviding`，并注册一个 `CYLTabBarItemViewAnimator`，不需要编写自己的 animator 或播放器类（Rive、GIF 与 SVGA
 *      即是如此）。方法在 Objective-C 中保留 `cyl_` 前缀，在 Swift 中使用驼峰命名。
 */
@MainActor
@objc(CYLTabBarItemAnimationPlayableView)
public protocol CYLTabBarItemAnimationPlayableView: NSObjectProtocol {

    /**
     * [EN] Plays once, from the start.
     * [CN] 从头播放一次。
     */
    @objc(cyl_playAnimationView)
    func playAnimation()

    /**
     * [EN] Shows the end state without playing (the tab selected at launch, #389).
     * [CN] 不播放，直接显示结束状态（启动时选中的 Tab，#389）。
     */
    @objc(cyl_showAnimationViewLastFrame)
    func showAnimationLastFrame()

    /**
     * [EN] Stops, back to the start.
     * [CN] 停止并回到起始状态。
     */
    @objc(cyl_stopAnimationView)
    func stopAnimation()

    /**
     * [EN] Colors for Dark Mode (`CYLTabBarAnimationDarkColors`, already resolved for the trait collection): a library path ->
     *      color; nil restores the light colors. Called only when the state changes.
     * [CN] 深色模式的颜色（`CYLTabBarAnimationDarkColors`，已按 trait collection 解析）：动画库中的路径 -> 颜色；nil 恢复浅色颜色。仅在状态变化时调用。
     */
    @objc(cyl_applyAnimationViewColors:)
    optional func applyAnimationColors(_ colors: [String: UIColor]?)
}

/**
 * [EN] The abstract factory of playable views, used by `CYLTabBarItemViewAnimator`.
 * [CN] 可播放视图的抽象工厂，由 `CYLTabBarItemViewAnimator` 使用。
 */
@MainActor
@objc(CYLTabBarItemAnimationViewProviding)
public protocol CYLTabBarItemAnimationViewProviding: NSObjectProtocol {

    /**
     * [EN] A view for the animation file `fileURL`, with the `options` of the tab's URL (`CYLTabBarAnimationURLWithOptions()`),
     *      scaled like `contentMode`; nil when it cannot be made. The animator sets its frame.
     * [CN] 为动画文件 `fileURL` 创建的视图，带有 Tab URL 中的 `options`（`CYLTabBarAnimationURLWithOptions()`），按 `contentMode` 缩放；无法创建时
     *      返回 nil。由 animator 设置其 frame。
     */
    @objc(cyl_animationViewWithFileURL:options:contentMode:)
    static func makeAnimationView(fileURL: URL, options: [String: String],
                                  contentMode: UIView.ContentMode) -> (UIView & CYLTabBarItemAnimationPlayableView)?
}
