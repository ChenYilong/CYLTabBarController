//
//  CYLTabBarItemAnimationPlayableView.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
// [EN] FIX: issue #415 — the playable view protocols of the `CYLTabBarItemAnimation` subspec, translated from Objective-C
//      (CYLTabBarItemAnimation/CYLTabBarItemAnimationPlayableView.h; docs/Swift-Migration.md). It lives with the engine (subspec
//      CYLAnimationEngine), not in Core, so the engine builds without Core. Their Objective-C names,
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

    /**
     * [EN] Whether the view plays again after each pass until this is set to NO (`loops` of the player, which forwards it
     *      only when the view implements this). For views with no progress to restart, such as Rive state machines
     *      (docs/Animated-Item.md, the Rive loop).
     * [CN] 视图是否在每次播放后再次播放，直到设为 NO（播放器的 `loops`，仅在视图实现本方法时转发）。用于没有进度可重新开始的视图，例如 Rive 状态机
     *      （docs/Animated-Item.md，Rive 循环）。
     */
    @objc(cyl_setAnimationViewLoops:)
    optional func setAnimationLoops(_ loops: Bool)

    /**
     * [EN] The playback position, 0 (first frame) to 1 (last frame). With `setAnimationProgress(_:)` it makes the player
     *      offer `progress`, so the host can seek (a placeholder scrubbed by a pull) and restart a pass. Implement both or
     *      neither.
     * [CN] 播放位置，0（第一帧）到 1（最后一帧）。与 `setAnimationProgress(_:)` 一起让播放器提供 `progress`，宿主据此定位（随下拉定位的占位图）并
     *      重新开始一遍。两者同时实现或都不实现。
     */
    @objc(cyl_animationViewProgress)
    optional func animationProgress() -> CGFloat

    /**
     * [EN] Shows the frame at `progress` (0 to 1) without playing. [CN] 显示 `progress`（0 到 1）处的帧，不播放。
     */
    @objc(cyl_setAnimationViewProgress:)
    optional func setAnimationProgress(_ progress: CGFloat)

    /**
     * [EN] The playback rate (1 = the file's own frame rate), applied live; the player offers `animationSpeed` only when
     *      the view implements this. [CN] 播放速率（1 为文件自身帧率），实时生效；只有视图实现时播放器才提供 `animationSpeed`。
     */
    @objc(cyl_setAnimationViewSpeed:)
    optional func setAnimationSpeed(_ speed: CGFloat)

    /**
     * [EN] The tab's current title color, for a view whose `tint` option is "title" (`CYLTabBarAnimationOptionTint`): the
     *      icon is drawn in it like a template image. Called when the tab is selected or deselected and when the colors change.
     * [CN] Tab 当前的标题颜色，用于 `tint` 选项为 "title" 的视图（`CYLTabBarAnimationOptionTint`）：图标像模板图片一样用该颜色绘制。在 Tab
     *      选中或取消选中、颜色变化时调用。
     */
    @objc(cyl_applyAnimationViewTintColor:)
    optional func applyAnimationTintColor(_ color: UIColor?)

    /**
     * [EN] The same with the tab's state; preferred over `-cyl_applyAnimationViewTintColor:` when implemented. A fixed `tint`
     *      ("#RRGGBB", with `darkTint`) is drawn on the unselected tab only; the selected tab takes `color`, the title's
     *      selected color, as with "title" (2026-11-19).
     * [CN] 同上，并带 Tab 的状态；实现后优先于 `-cyl_applyAnimationViewTintColor:` 调用。固定 `tint`（"#RRGGBB"，及 `darkTint`）只用于未选中的
     *      Tab；选中的 Tab 使用 `color`（标题的选中颜色），与 "title" 相同（2026-11-19）。
     */
    @objc(cyl_applyAnimationViewTintColor:selected:)
    optional func applyAnimationTintColor(_ color: UIColor?, selected: Bool)

    /**
     * [EN] Whether a pass is playing now; the player's `isPlaying`. A view that cannot tell leaves it out (the player answers NO).
     * [CN] 当前是否正在播放一遍；对应播放器的 `isPlaying`。无法判断的视图不实现（播放器回答 NO）。
     */
    @objc(cyl_animationViewIsPlaying)
    optional func isAnimationPlaying() -> Bool

    /**
     * [EN] The callback of the end of a play-once pass (not of a stop, not while looping); the player's `onEnded` comes
     *      through it. A view that cannot tell leaves it out and never calls it.
     * [CN] 只播放一次的一遍播放结束时的回调（停止时不调用，循环时不调用）；播放器的 `onEnded` 经由它触发。无法判断的视图不实现，也从不调用。
     */
    @objc(cyl_setAnimationViewEndHandler:)
    optional func setAnimationEndHandler(_ handler: (() -> Void)?)
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
