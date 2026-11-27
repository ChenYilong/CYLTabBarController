//
//  CYLPAGTabBarItemAnimation.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] FIX: issue #604 — the PAG player and view loading of the `CYLAnimatedItem/PAG` and `PAGEnterprise` subspecs, translated
//      from Objective-C (CYLPAGTabBarItemAnimator.m; docs/Swift-Migration.md, engine step 4). CYLPAGTabBarItemAnimator stays
//      Objective-C as the composition root: its `+load` registers the animator (Swift has no `+load`), and it forwards to
//      the types below. Public only so that the generated header exports them to that Objective-C file.
// [CN] FIX: issue #604 — `CYLAnimatedItem/PAG` 与 `PAGEnterprise` 子库的 PAG 播放器与视图加载，由 Objective-C 翻译而来
//      （CYLPAGTabBarItemAnimator.m；docs/Swift-Migration.md 引擎第 4 步）。CYLPAGTabBarItemAnimator 作为组合根保留为 Objective-C：其 `+load`
//      注册 animator（Swift 没有 `+load`），并转发给下面的类型。声明为 public 只是为了让生成的头文件把它们导出给那个 Objective-C 文件。

#if canImport(libpag)
import UIKit
#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
import libpag

/**
 * [EN] Plays a `PAGView`, like a stopped Lottie view: plays once from the first frame, rests on the last one.
 * [CN] 播放一个 `PAGView`，与 Lottie 视图一致：从第一帧播放一次，停在最后一帧。
 */
@objc(CYLPAGTabBarItemAnimationPlayer)
public final class CYLPAGTabBarItemAnimationPlayer: CYLTabBarItemAnimationBasePlayer, CYLTabBarItemAnimationPlayer {

    private var pagView: PAGView? {
        animationView as? PAGView
    }

    /// [EN] Tells `onEnded` when PAG reports the end of the animation (after its repeat count; never with `loops` on).
    ///      Added to the view on the first `play()`, the only moment an end can follow. [CN] PAG 报告动画结束时（重复次数用完后；`loops`
    ///      开启时从不）通知 `onEnded`。在第一次 `play()` 时加到视图上，结束只可能出现在此之后。
    private var endObserver: CYLPAGPassObserver?

    public func play() {
        if endObserver == nil, let pagView {
            let observer = CYLPAGPassObserver { [weak self] in self?.notifyPlaybackEnded() }
            pagView.add(observer)
            endObserver = observer
        }
        pagView?.stop()
        pagView?.setProgress(0)
        pagView?.play()
    }

    public var isPlaying: Bool {
        pagView?.isPlaying() ?? false
    }

    public func showLastFrame() {
        pagView?.setProgress(1)
        pagView?.flush()
    }

    public func stop() {
        // [EN] As a stopped Lottie view: only when it has moved, back to the first frame. [CN] 与停止后的 Lottie 视图一致：仅在播放过时回到第一帧。
        guard let pagView, pagView.getProgress() > 0 else {
            return
        }
        pagView.stop()
        pagView.setProgress(0)
        pagView.flush()
    }

    public var progress: CGFloat {
        get { CGFloat(pagView?.getProgress() ?? 0) }
        set {
            pagView?.setProgress(Double(newValue))
            pagView?.flush()
        }
    }

    public var loops: Bool {
        get { pagView?.repeatCount() == 0 }
        set { pagView?.setRepeatCount(newValue ? 0 : 1) }
    }
}

/**
 * [EN] Receives the end of a PAG animation for `CYLPAGTabBarItemAnimationPlayer` (not public: the player's header stays free of libpag).
 * [CN] 为 `CYLPAGTabBarItemAnimationPlayer` 接收 PAG 动画的结束（非 public：播放器的头文件不引入 libpag）。
 */
private final class CYLPAGPassObserver: NSObject, PAGViewListener {
    private let didEnd: () -> Void

    init(didEnd: @escaping () -> Void) {
        self.didEnd = didEnd
    }

    func onAnimationEnd(_: PAGView!) {
        didEnd()
    }
}

/**
 * [EN] Makes the `PAGView` of a tab and its player, for CYLPAGTabBarItemAnimator.
 * [CN] 为 CYLPAGTabBarItemAnimator 创建 Tab 的 `PAGView` 及其播放器。
 */
@objc(CYLPAGTabBarItemAnimationViews)
public final class CYLPAGTabBarItemAnimationViews: NSObject {

    /**
     * [EN] A `PAGView` for `url` (a file, or http / https), `size` large, scaled like `contentMode`; nil for a local file
     *      that libpag cannot load. Loaded as the official samples (libpag/pag-ios) do: `setComposition` with
     *      `PAGFile.load`, which every libpag version has (3.x and later).
     * [CN] 为 `url`（文件或 http / https）创建尺寸为 `size`、按 `contentMode` 缩放的 `PAGView`；libpag 无法加载的本地文件返回 nil。
     *      与官方示例（libpag/pag-ios）一致：用 `PAGFile.load` 加 `setComposition` 加载，各版本均支持。
     */
    @objc(animationViewWithURL:size:contentMode:)
    public static func animationView(url: URL, size: CGSize, contentMode: UIView.ContentMode) -> UIView? {
        let remote = !url.isFileURL && !(url.scheme ?? "").isEmpty
        let pagFile = !remote && !url.path.isEmpty ? PAGFile.load(url.path) : nil
        if pagFile == nil && !remote {
            return nil
        }
        let pagView = PAGView(frame: CGRect(origin: .zero, size: size))
        // [EN] Rendered on the main thread, everywhere: a tab bar has several small PAGViews. With one render thread each,
        //      those threads stalled inside the simulator's software OpenGL while holding their player's lock, and the first
        //      call that needed it (`stop`, `isHidden`) blocked the main thread: blank icons, no playback. One path on every
        //      target also means that what the simulator shows is what a device runs.
        // [CN] 在所有环境都在主线程渲染：一个 TabBar 有多个小 PAGView。每个各有一个渲染线程时，这些线程在模拟器的软件 OpenGL 中持锁卡住，
        //      之后第一个需要该锁的调用（`stop`、`isHidden`）会阻塞主线程：图标空白，不播放。所有环境走同一条路径，模拟器上看到的就是真机运行的。
        pagView.setSync(true)
        if let pagFile {
            pagView.setComposition(pagFile)
        } else {
            loadRemote(url, into: pagView)
        }
        // [EN] Like a Lottie view: plays once, shows its first frame until then. [CN] 与 Lottie 视图一致：播放一次，播放前显示第一帧。
        pagView.setRepeatCount(1)
        switch contentMode {
        case .scaleToFill:
            pagView.setScaleMode(PAGScaleModeStretch)
        case .scaleAspectFill:
            pagView.setScaleMode(PAGScaleModeZoom)
        default:
            pagView.setScaleMode(PAGScaleModeLetterBox)
        }
        pagView.setProgress(0)
        pagView.flush()
        return pagView
    }

    /**
     * [EN] A remote file (http, https): downloaded through the shared URL session into the caches folder, then loaded on the
     *      main thread; meanwhile the item keeps its static image (or the placeholder), and a failed download or file goes
     *      back to it (`CYLTabBarItemAnimationReportFailure`).
     * [CN] 远程文件（http、https）：通过共享 URL session 下载到缓存目录，再在主线程加载；期间条目保持静态图片（或占位图），下载或文件失败时
     *      回到静态图片（`CYLTabBarItemAnimationReportFailure`）。
     */
    private static func loadRemote(_ url: URL, into pagView: PAGView) {
        CYLTabBarItemAnimationMarkLoading(pagView)
        let task = URLSession.shared.downloadTask(with: url) { [weak pagView] location, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 200
            var path: String?
            if let location, status < 400,
               let caches = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first {
                let candidate = (caches as NSString).appendingPathComponent("cyl-pag-\(UInt(bitPattern: (url.absoluteString as NSString).hash)).pag")
                try? FileManager.default.removeItem(atPath: candidate)
                if (try? FileManager.default.moveItem(at: location, to: URL(fileURLWithPath: candidate))) != nil {
                    path = candidate
                }
            }
            DispatchQueue.main.async {
                guard let pagView else {
                    return
                }
                guard let path, let file = PAGFile.load(path) else {
                    CYLTabBarItemAnimationReportFailure(pagView, error as NSError?)
                    return
                }
                pagView.setComposition(file)
                pagView.setProgress(0)
                pagView.flush()
                CYLTabBarItemAnimationReportLoaded(pagView)
            }
        }
        task.resume()
    }

    /**
     * [EN] The player of a `PAGView`; nil for any other view.
     * [CN] `PAGView` 的播放器；其他视图返回 nil。
     */
    @objc(playerForAnimationView:)
    public static func player(for view: UIView) -> CYLTabBarItemAnimationPlayer? {
        view is PAGView ? CYLPAGTabBarItemAnimationPlayer(animationView: view) : nil
    }
}
#endif
