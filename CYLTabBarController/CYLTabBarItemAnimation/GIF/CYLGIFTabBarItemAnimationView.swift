//
//  CYLGIFTabBarItemAnimationView.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] FIX: issue #605 — the GIF view of the `CYLAnimatedItem/GIF` subspec, translated from Objective-C (it was a private
//      class of CYLGIFTabBarItemAnimator.m; docs/Swift-Migration.md, the engine rows). Same Objective-C name, so
//      CYLGIFTabBarItemAnimator, the composition root that registers it in `+load`, names it as before. Public only so
//      that the generated header exports it to that Objective-C file; apps use the animator, not this class.
// [CN] FIX: issue #605 — `CYLAnimatedItem/GIF` 子库的 GIF 视图，由 Objective-C 翻译而来（原为 CYLGIFTabBarItemAnimator.m 的私有类；
//      docs/Swift-Migration.md 引擎相关条目）。Objective-C 名称不变，因此在 `+load` 中注册它的组合根 CYLGIFTabBarItemAnimator 照旧使用它。
//      声明为 public 只是为了让生成的头文件把它导出给那个 Objective-C 文件；App 使用 animator，而不是这个类。

#if CYL_ANIMATION_ENGINE_AVAILABLE
import UIKit
import ImageIO
#if SWIFT_PACKAGE
import CYLAnimatedItem
import CYLAnimatedItemSwift
#endif

/**
 * [EN] A GIF that plays by itself. The frames play through a keyframe animation of the layer's contents, so each keeps its own
 *      delay; `UIImageView.animationImages` gives every frame the same one. The image view already holds the end state while
 *      the animation runs, so nothing changes when the animation ends or the system removes it (e.g. in the background).
 * [CN] 自己会播放的 GIF。各帧通过 layer contents 的关键帧动画播放，因此保留各自的时长；`UIImageView.animationImages` 会让每一帧时长相同。
 *      动画运行期间图片视图已经持有结束状态，因此动画结束或被系统移除时（例如进入后台）画面不会变化。
 */
@objc(CYLGIFTabBarItemAnimationView)
public final class CYLGIFTabBarItemAnimationView: UIImageView, CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding {

    private static let playAnimationKey = "CYLGIFTabBarItemPlayAnimation"

    private var frames: [UIImage] = []
    private var frameDelays: [TimeInterval] = []

    /**
     * [EN] The delay of one GIF frame (0.1 s for a delay under 11 ms, as browsers do): the same rule as Core's
     *      `+[UIImage cyl_GIFFrameDelayWithProperties:]`, here so that this subspec does not need Core.
     * [CN] 一帧 GIF 的延迟（小于 11 毫秒时为 0.1 秒，与浏览器一致）：与 Core 的 `+[UIImage cyl_GIFFrameDelayWithProperties:]` 规则相同，
     *      放在这里使本子库不依赖 Core。
     */
    public static func frameDelay(properties: [CFString: Any]?) -> TimeInterval {
        let gif = properties?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
        var delay = (gif?[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber)?.doubleValue ?? 0
        if delay <= 0 {
            delay = (gif?[kCGImagePropertyGIFDelayTime] as? NSNumber)?.doubleValue ?? 0
        }
        return delay < 0.011 ? 0.1 : delay
    }

    /**
     * [EN] Decodes every frame of `source` into the view. false when it has no frame (not a GIF, or a broken one).
     * [CN] 把 `source` 的每一帧解码到视图中。没有任何帧时（不是 GIF 或已损坏）返回 false。
     */
    private func loadFrames(from source: CGImageSource) -> Bool {
        var frames: [UIImage] = []
        var frameDelays: [TimeInterval] = []
        for index in 0..<CGImageSourceGetCount(source) {
            guard let imageRef = CGImageSourceCreateImageAtIndex(source, index, nil) else {
                continue
            }
            frames.append(UIImage(cgImage: imageRef))
            let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any]
            frameDelays.append(Self.frameDelay(properties: properties))
        }
        guard !frames.isEmpty else {
            return false
        }
        self.frames = frames
        self.frameDelays = frameDelays
        image = frames.first
        return true
    }

    public static func makeAnimationView(fileURL: URL, options _: [String: String],
                                         contentMode: UIView.ContentMode) -> (UIView & CYLTabBarItemAnimationPlayableView)? {
        if !fileURL.isFileURL, let scheme = fileURL.scheme, !scheme.isEmpty {
            return downloadingView(url: fileURL, contentMode: contentMode)
        }
        guard let source = CGImageSourceCreateWithURL(fileURL as CFURL, nil) else {
            return nil
        }
        let view = CYLGIFTabBarItemAnimationView(image: nil)
        guard view.loadFrames(from: source) else {
            return nil
        }
        view.contentMode = contentMode
        return view
    }

    /**
     * [EN] A remote GIF (http, https): an empty view, marked as loading so that the item keeps its static image (or the
     *      placeholder), filled once the file is downloaded (`CYLTabBarItemAnimationReportLoaded`), or reported as failed
     *      when the download or the decoding fails (`CYLTabBarItemAnimationReportFailure`), which shows the static image again.
     *      The download goes through the shared URL session, so its HTTP cache applies.
     * [CN] 远程 GIF（http、https）：先返回空视图并标记为加载中，使条目继续显示静态图片（或占位图）；下载完成后填充帧
     *      （`CYLTabBarItemAnimationReportLoaded`）；下载或解码失败时报告失败（`CYLTabBarItemAnimationReportFailure`），重新显示静态图片。
     *      下载使用共享的 URL session，因此遵循其 HTTP 缓存。
     */
    private static func downloadingView(url: URL, contentMode: UIView.ContentMode) -> CYLGIFTabBarItemAnimationView {
        let view = CYLGIFTabBarItemAnimationView(image: nil)
        view.contentMode = contentMode
        CYLTabBarItemAnimationMarkLoading(view)
        let task = URLSession.shared.dataTask(with: url) { [weak view] data, response, error in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 200
            let source = (data.map { !$0.isEmpty } ?? false) && status < 400 ? data.flatMap { CGImageSourceCreateWithData($0 as CFData, nil) } : nil
            DispatchQueue.main.async {
                guard let view else {
                    return
                }
                if let source, view.loadFrames(from: source) {
                    CYLTabBarItemAnimationReportLoaded(view)
                } else {
                    CYLTabBarItemAnimationReportFailure(view, error as NSError?)
                }
            }
        }
        task.resume()
        return view
    }

    public func playAnimation() {
        layer.removeAnimation(forKey: Self.playAnimationKey)
        image = frames.last
        guard frames.count >= 2 else {
            return
        }
        let duration = frameDelays.reduce(0, +)
        var keyTimes: [NSNumber] = []
        var elapsed: TimeInterval = 0
        for delay in frameDelays {
            keyTimes.append(NSNumber(value: elapsed / duration))
            elapsed += delay
        }
        // [EN] Discrete: one key time more than values, the last one 1. [CN] 离散模式：key time 比 values 多一个，最后一个为 1。
        keyTimes.append(1)
        let animation = CAKeyframeAnimation(keyPath: "contents")
        animation.calculationMode = .discrete
        animation.values = frames.compactMap { $0.cgImage }
        animation.keyTimes = keyTimes
        animation.duration = duration
        layer.add(animation, forKey: Self.playAnimationKey)
    }

    public func showAnimationLastFrame() {
        layer.removeAnimation(forKey: Self.playAnimationKey)
        image = frames.last
    }

    public func stopAnimation() {
        layer.removeAnimation(forKey: Self.playAnimationKey)
        image = frames.first
    }
}
#endif
