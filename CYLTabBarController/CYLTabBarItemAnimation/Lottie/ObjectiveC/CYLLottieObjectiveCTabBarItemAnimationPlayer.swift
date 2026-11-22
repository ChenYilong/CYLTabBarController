//
//  CYLLottieObjectiveCTabBarItemAnimationPlayer.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] FIX: issue #604 — the lottie-ios 2.x player of the `CYLAnimatedItem/LottieObjectiveC` subspec, translated from Objective-C (CYLLottieTabBarItemAnimator.m; docs/Swift-Migration.md,
//      engine step 5). CYLLottieTabBarItemAnimator stays Objective-C as the composition root: its `+load` registers the
//      animator (Swift has no `+load`), and it forwards to the type below. Public only so that the generated header
//      exports it to that Objective-C file.
// [CN] FIX: issue #604 — `CYLAnimatedItem/LottieObjectiveC` 子库的 lottie-ios 2.x 播放器，由 Objective-C 翻译而来（CYLLottieTabBarItemAnimator.m；docs/Swift-Migration.md 引擎第 5 步）。
//      CYLLottieTabBarItemAnimator 作为组合根保留为 Objective-C：其 `+load` 注册 animator（Swift 没有 `+load`），并转发给下面的类型。
//      声明为 public 只是为了让生成的头文件把它导出给那个 Objective-C 文件。

#if canImport(Lottie)
import Lottie
import UIKit

/**
 * [EN] Plays a `LOTAnimationView` (lottie-ios 2.x).
 * [CN] 播放 `LOTAnimationView`（lottie-ios 2.x）。
 */
@objc(CYLLottieObjectiveCTabBarItemAnimationPlayer)
public final class CYLLottieObjectiveCTabBarItemAnimationPlayer: CYLTabBarItemAnimationBasePlayer, CYLTabBarItemAnimationPlayer {

    /**
     * [EN] Whether `view` is a lottie-ios 2.x view.
     * [CN] `view` 是否为 lottie-ios 2.x 视图。
     */
    @objc(isLottieView:)
    public static func isLottieView(_ view: UIView) -> Bool {
        view is LOTAnimationView
    }

    /**
     * [EN] A `LOTAnimationView` for `url` (a file, or http / https, downloaded here: lottie-ios 2.x's
     *      `-initWithContentsOfURL:` reports neither success nor failure).
     * [CN] 为 `url`（文件，或在这里下载的 http / https：lottie-ios 2.x 的 `-initWithContentsOfURL:` 既不报告成功也不报告失败）创建
     *      `LOTAnimationView`。
     */
    @objc(viewWithURL:)
    public static func view(url: URL) -> UIView? {
        guard isRemote(url) else {
            return LOTAnimationView(contentsOf: url)
        }
        let view = LOTAnimationView(frame: .zero)
        download(url, into: view) { target, data in
            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [AnyHashable: Any] else {
                return false
            }
            target.sceneModel = LOTComposition(json: json, withAssetBundle: nil)
            return true
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

    private var lottieView: LOTAnimationView? {
        animationView as? LOTAnimationView
    }

    public func play() {
        let lottieView = lottieView
        DispatchQueue.main.async {
            lottieView?.animationProgress = 0
            lottieView?.play()
        }
    }

    public func showLastFrame() {
        let lottieView = lottieView
        DispatchQueue.main.async {
            // [CN] 希望Lottie icon 启动后 index== 0 不执行动画 #389
            // [EN] Avoid triggering Lottie animation when index == 0 on app startup. #389
            lottieView?.animationProgress = 1
            lottieView?.forceDrawingUpdate()
        }
    }

    public func stop() {
        // [CN] 通过 (animationProgress > 0) 判断，降低扁平风格 CYLFlatDesignTabBar 第一次初始化时展示失败的几率。
        // [EN] The (animationProgress > 0) check lowers the chance that the flat design CYLFlatDesignTabBar fails to show on its
        //      first initialization.
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
        get { lottieView?.loopAnimation ?? false }
        set {
            guard let lottieView, lottieView.loopAnimation != newValue else {
                return
            }
            lottieView.loopAnimation = newValue
            // [EN] Lottie 2.x reads it when a play starts: a playing view continues from where it is under the new mode.
            // [CN] Lottie 2.x 在开始播放时读取该值：正在播放的视图从当前位置按新模式继续播放。
            if lottieView.isAnimationPlaying {
                lottieView.play()
            }
        }
    }
}
#endif
