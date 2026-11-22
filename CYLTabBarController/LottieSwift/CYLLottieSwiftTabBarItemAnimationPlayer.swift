//
//  CYLLottieSwiftTabBarItemAnimationPlayer.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] FIX: issue #604 — the lottie-ios 4.x player of the `CYLAnimatedItem/LottieSwift` subspec (SwiftPM: the CYLTabBarControllerLottieSwift target), translated from Objective-C (CYLLottieTabBarItemAnimator.m; docs/Swift-Migration.md,
//      engine step 5). CYLLottieTabBarItemAnimator stays Objective-C as the composition root: its `+load` registers the
//      animator (Swift has no `+load`), and it forwards to the type below. Public only so that the generated header
//      exports it to that Objective-C file.
// [CN] FIX: issue #604 — `CYLAnimatedItem/LottieSwift` 子库的 lottie-ios 4.x 播放器（SwiftPM：CYLTabBarControllerLottieSwift target），由 Objective-C 翻译而来（CYLLottieTabBarItemAnimator.m；docs/Swift-Migration.md 引擎第 5 步）。
//      CYLLottieTabBarItemAnimator 作为组合根保留为 Objective-C：其 `+load` 注册 animator（Swift 没有 `+load`），并转发给下面的类型。
//      声明为 public 只是为了让生成的头文件把它导出给那个 Objective-C 文件。

import UIKit
#if SWIFT_PACKAGE
import CYLAnimatedItem
#endif

/**
 * [EN] Plays a `CYLCompatibleLOTAnimationView` (lottie-ios 4.x).
 * [CN] 播放 `CYLCompatibleLOTAnimationView`（lottie-ios 4.x）。
 */
@objc(CYLLottieSwiftTabBarItemAnimationPlayer)
public final class CYLLottieSwiftTabBarItemAnimationPlayer: CYLTabBarItemAnimationBasePlayer, CYLTabBarItemAnimationPlayer {

    /**
     * [EN] Whether `view` is a lottie-ios 4.x view of this bridge.
     * [CN] `view` 是否为本桥接的 lottie-ios 4.x 视图。
     */
    @objc(isLottieView:)
    public static func isLottieView(_ view: UIView) -> Bool {
        view is CYLCompatibleLOTAnimationView
    }

    /**
     * [EN] A `CYLCompatibleLOTAnimationView` for `url`: a local file, or http / https, downloaded first (lottie-ios 4.x
     *      reads local files only through this bridge).
     * [CN] 为 `url` 创建 `CYLCompatibleLOTAnimationView`：本地文件，或先下载的 http / https（经由此桥接，lottie-ios 4.x 只读本地文件）。
     */
    @objc(viewWithURL:)
    public static func view(url: URL) -> UIView? {
        guard isRemote(url) else {
            return CYLCompatibleLOTAnimationView(compatibleAnimation: CYLCompatibleLOTAnimation(filepath: url.path))
        }
        let view = CYLCompatibleLOTAnimationView(frame: .zero)
        download(url, into: view) { target, data in
            target.cylLoadAnimationData(data)
        }
        return view
    }

    /**
     * [EN] A remote Lottie file, as the GIF and PAG animators do: `view` is marked as loading, so the item keeps its static
     *      image (or the placeholder); the file is downloaded through the shared URL session (its HTTP cache applies) and
     *      handed to `load` on the main queue; then `CYLTabBarItemAnimationReportLoaded` or, when the download fails, the
     *      status is 400 or above, or `load` returns false, `CYLTabBarItemAnimationReportFailure`.
     * [CN] 远程 Lottie 文件，与 GIF、PAG animator 相同：`view` 标记为加载中，item 保留静态图片（或占位图）；通过共享 URL session 下载
     *      （遵循其 HTTP 缓存），在主队列交给 `load`；随后调用 `CYLTabBarItemAnimationReportLoaded`，下载失败、状态码不小于 400 或 `load`
     *      返回 false 时调用 `CYLTabBarItemAnimationReportFailure`。
     */
    private static func download<View: UIView>(_ url: URL, into view: View, load: @escaping (View, Data) -> Bool) {
        CYLTabBarItemAnimationMarkLoading(view)
        let task = URLSession.shared.dataTask(with: url) { [weak view] data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 200
            let usable = (data?.isEmpty == false && status < 400) ? data : nil
            DispatchQueue.main.async {
                guard let view else {
                    return
                }
                if let usable, load(view, usable) {
                    CYLTabBarItemAnimationReportLoaded(view)
                } else {
                    CYLTabBarItemAnimationReportFailure(view, error as NSError?)
                }
            }
        }
        task.resume()
    }

    /**
     * [EN] Whether `url` is a remote file (http, https...), which this player downloads itself.
     * [CN] `url` 是否为远程文件（http、https 等），由本播放器自行下载。
     */
    private static func isRemote(_ url: URL) -> Bool {
        !url.isFileURL && !(url.scheme ?? "").isEmpty
    }

    /**
     * [EN] Whether the dark colors are applied now (#442).
     * [CN] 当前是否已应用深色颜色（#442）。
     */
    private var darkColorsApplied = false

    /**
     * [EN] FIX: issue #216 — the keypaths `applyColors` set last.
     * [CN] `applyColors` 上次设置的 keypath。
     */
    private var appliedColorKeypaths = Set<String>()

    private var lottieView: CYLCompatibleLOTAnimationView? {
        animationView as? CYLCompatibleLOTAnimationView
    }

    // [CN] 不能放到 dispatch_get_main_queue 中，否则暂停与播放可能错乱。
    // [EN] Not on the main queue: pause and play may get out of order otherwise.

    public func play() {
        lottieView?.animationProgress = 0
        // [EN] `finished` is true only when the pass ran to its end: a stop or a restart calls it with false. A pass that
        //      ends while `loops` is on does not call `onEnded` (`notifyPlaybackEnded`).
        // [CN] 只有一遍播放到结尾时 `finished` 才为 true：停止或重新播放时为 false。`loops` 开启时结束的一遍不调用 `onEnded`（`notifyPlaybackEnded`）。
        lottieView?.play { [weak self] finished in
            if finished {
                self?.notifyPlaybackEnded()
            }
        }
    }

    public var isPlaying: Bool {
        lottieView?.isAnimationPlaying ?? false
    }

    public func showLastFrame() {
        // [CN] 希望Lottie icon 启动后 index== 0 不执行动画 #389
        // [EN] Avoid triggering Lottie animation when index == 0 on app startup. #389
        lottieView?.animationProgress = 1
        lottieView?.forceDrawingUpdate()
    }

    public func stop() {
        guard let lottieView, lottieView.animationProgress > 0 else {
            return
        }
        lottieView.stop()
    }

    public var progress: CGFloat {
        get { lottieView?.animationProgress ?? 0 }
        set {
            lottieView?.animationProgress = newValue
            lottieView?.forceDrawingUpdate()
        }
    }

    public var animationSpeed: CGFloat {
        get { lottieView?.animationSpeed ?? 1 }
        set { lottieView?.animationSpeed = newValue }
    }

    public var loops: Bool {
        get { lottieView?.loopAnimationCount == -1 }
        // [EN] -1 loops; 1 plays once. Lottie 4.x applies a new loop mode to the animation in flight.
        // [CN] -1 表示循环；1 表示播放一次。Lottie 4.x 会把新的循环模式应用到正在播放的动画。
        set { lottieView?.loopAnimationCount = newValue ? -1 : 1 }
    }

    /**
     * [EN] FIX: issue #442 — sets `darkColors` with Lottie's value providers where `traitCollection` is dark, and removes
     *      them otherwise, so one file follows Dark Mode. Does nothing when they are already in that state.
     * [CN] FIX: issue #442 — `traitCollection` 为深色时，用 Lottie 的 value provider 设置 `darkColors`，否则移除，使一份文件即可适配深色模式。
     *      状态未变化时不做处理。
     */
    public func applyDarkColors(_ darkColors: [String: UIColor], traitCollection: UITraitCollection) {
        guard let lottieView, !darkColors.isEmpty else {
            return
        }
        let dark = traitCollection.userInterfaceStyle == .dark
        if darkColorsApplied == dark {
            return
        }
        for (keypath, color) in darkColors {
            if dark {
                lottieView.setColorValue(color.resolvedColor(with: traitCollection), forKeypathString: keypath)
            } else {
                lottieView.removeValueProvider(forKeypathString: keypath)
            }
        }
        darkColorsApplied = dark
        lottieView.forceDrawingUpdate()
    }

    /**
     * [EN] FIX: issue #216 — sets `colors` (already resolved) with Lottie's value providers and removes the providers of the
     *      keypaths set by a previous call that are no longer in it; nil removes them all.
     * [CN] FIX: issue #216 — 用 Lottie 的 value provider 设置 `colors`（已解析），并移除上一次调用设置、这次不再包含的 keypath 的 provider；
     *      nil 移除全部。
     */
    public func applyColors(_ colors: [String: UIColor]?, traitCollection _: UITraitCollection) {
        guard let lottieView else {
            return
        }
        let colors = colors ?? [:]
        for keypath in appliedColorKeypaths where colors[keypath] == nil {
            lottieView.removeValueProvider(forKeypathString: keypath)
        }
        for (keypath, color) in colors {
            lottieView.setColorValue(color, forKeypathString: keypath)
        }
        appliedColorKeypaths = Set(colors.keys)
        // [EN] `applyColors` carries the dark colors itself. [CN] `applyColors` 自己带有深色颜色。
        darkColorsApplied = false
        lottieView.forceDrawingUpdate()
    }
}
