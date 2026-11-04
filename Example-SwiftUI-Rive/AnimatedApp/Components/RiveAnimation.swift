//
//  RiveAnimation.swift
//  AnimatedApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import SwiftUI
import CYLTabBarController

/*!
 * [EN] One Rive animation of this demo, played through CYLTabBarController's animation API: the same path as the tab bar
 *      icons (`CYLTabBarAnimationURLWithOptions()`, `CYLTabBarItemAnimationFactory`, the player). So the app uses no Rive
 *      API itself, and the course's files, which have no view model, play through the Rive subspec's state machine input
 *      support (`.riveInput`, `.riveTriggerInput`, `.riveAnimation`).
 * [CN] 本 Demo 中的一个 Rive 动画，通过 CYLTabBarController 的动画 API 播放：与 TabBar 图标走同一条路径（`CYLTabBarAnimationURLWithOptions()`、
 *      `CYLTabBarItemAnimationFactory`、播放器）。因此 App 本身不调用任何 Rive API；课程中没有 view model 的文件通过 Rive 子库对状态机输入的支持
 *      （`.riveInput`、`.riveTriggerInput`、`.riveAnimation`）播放。
 */
final class RiveAnimation {
    /// [EN] The file and its options, as a tab's `CYLTabBarRiveURL` would be. [CN] 文件及其选项，与 Tab 的 `CYLTabBarRiveURL` 相同。
    let url: URL?
    fileprivate weak var animationView: UIView?

    init(_ fileName: String, _ options: [CYLTabBarAnimationOption: String] = [:]) {
        url = CYLTabBarAnimationURLWithOptions(Bundle.main.url(forResource: fileName, withExtension: "riv"), options)
    }

    /// [EN] Plays once (sets the input, fires the trigger, or plays the animation). [CN] 播放一次（设置输入、触发 trigger 或播放动画）。
    func play() {
        CYLTabBarItemAnimationFactory.player(for: animationView)?.play()
    }

    /// [EN] Back to the resting state (the input goes back to NO). [CN] 回到静止状态（输入恢复为 NO）。
    func stop() {
        CYLTabBarItemAnimationFactory.player(for: animationView)?.stop()
    }

    /// [EN] The animation as a SwiftUI view; gestures added to it (e.g. `.onTapGesture`) get the touches.
    /// [CN] SwiftUI 形式的动画视图；添加到它上面的手势（例如 `.onTapGesture`）会接收触摸。
    func view() -> some View {
        RiveAnimationView(animation: self)
            .allowsHitTesting(false)
            .contentShape(Rectangle())
    }
}

/// [EN] Hosts the animation view made by `CYLTabBarItemAnimationFactory`. [CN] 承载由 `CYLTabBarItemAnimationFactory` 创建的动画视图。
private struct RiveAnimationView: UIViewRepresentable {
    let animation: RiveAnimation

    func makeUIView(context _: Context) -> UIView {
        let container = UIView()
        container.isUserInteractionEnabled = false
        guard let url = animation.url,
              let animationView = CYLTabBarItemAnimationFactory.animationView(url: url, size: .zero, contentMode: .scaleAspectFit) else {
            return container
        }
        animationView.frame = container.bounds
        animationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.addSubview(animationView)
        animation.animationView = animationView
        return container
    }

    func updateUIView(_: UIView, context _: Context) {}
}
