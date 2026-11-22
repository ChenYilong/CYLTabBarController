//
//  CYLSVGATabBarItemAnimationView.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] FIX: issue #415 — the SVGA view of the `CYLAnimatedItem/SVGA` subspec, translated from Objective-C (it was a private
//      class of CYLSVGATabBarItemAnimator.m; docs/Swift-Migration.md, engine step 6). Same Objective-C name and selectors, so
//      CYLSVGATabBarItemAnimator, the composition root that registers it in `+load`, names it as before. It conforms to
//      `CYLTabBarItemAnimationPlayableView` and `CYLTabBarItemAnimationViewProviding` through a category in that file:
//      `SVGAPlayer` already has `-stopAnimation`, the Swift name of the protocol's `-cyl_stopAnimationView`, so Swift
//      cannot declare the conformance (its methods keep the selectors, under other Swift names). It stays an `SVGAPlayer`
//      (not a view holding one) because the engine keeps the tint overlay below a view's subviews. Public only so
//      that the generated header exports it to that Objective-C file; apps use the animator, not this class. Compiled only
//      with SVGAPlayerLite (the SVGA subspec's maintained fork) or the original SVGAPlayer pod.
// [CN] FIX: issue #415 — `CYLAnimatedItem/SVGA` 子库的 SVGA 视图，由 Objective-C 翻译而来（原为 CYLSVGATabBarItemAnimator.m 的私有类；
//      docs/Swift-Migration.md 引擎第 6 步）。Objective-C 名称与 selector 不变，因此在 `+load` 中注册它的组合根 CYLSVGATabBarItemAnimator 照旧使用它。
//      它通过该文件中的分类遵守 `CYLTabBarItemAnimationPlayableView` 与 `CYLTabBarItemAnimationViewProviding`：`SVGAPlayer` 已有 `-stopAnimation`，
//      即协议中 `-cyl_stopAnimationView` 的 Swift 名称，因此 Swift 无法声明该遵守关系（方法保留 selector，使用其他 Swift 名称）。它仍是 `SVGAPlayer`
//      （而不是持有一个 SVGAPlayer 的视图），因为引擎把着色叠加图层放在视图的子视图之下。
//      声明为 public 只是为了让生成的头文件把它导出给那个 Objective-C 文件；App 使用 animator，而不是这个类。只在引入 SVGAPlayerLite
//      （SVGA 子库维护的分支）或原版 SVGAPlayer pod 时编译。

#if canImport(SVGAPlayerLite) || canImport(SVGAPlayer)
import UIKit
#if canImport(SVGAPlayerLite)
import SVGAPlayerLite
#else
import SVGAPlayer
#endif

/**
 * [EN] An SVGA file in a tab: an `SVGAPlayer` that plays once and keeps its last frame (`fillMode` "Forward"), or shows its
 *      first frame. The parsed video is cached by the parser's memory cache, keyed by the file URL.
 * [CN] Tab 中的 SVGA 文件：一个播放一次并停在最后一帧（`fillMode` 为 "Forward"）或显示第一帧的 `SVGAPlayer`。解析后的视频由解析器的内存缓存
 *      按文件 URL 缓存。
 */
@objc(CYLSVGATabBarItemAnimationView)
public final class CYLSVGATabBarItemAnimationView: SVGAPlayer, SVGAPlayerDelegate {

    /**
     * [EN] What the view shows once its file is parsed (parsing is asynchronous): a request made before is kept and applied then.
     * [CN] 文件解析完成后视图显示的内容（解析是异步的）：之前的请求会被保留并在那时应用。
     */
    private enum RequestedState {
        case firstFrame
        case playing
        case lastFrame
    }

    private var requestedState = RequestedState.firstFrame
    private var currentFrame = 0
    private var loopsForever = false
    private var speed: CGFloat = 1
    /// [EN] Steps the frames itself when the rate is not 1: SVGAPlayer's display link has a fixed, private frame interval.
    /// [CN] 速率不为 1 时自行逐帧推进：SVGAPlayer 的 display link 帧间隔固定且为私有。
    private var speedLink: CADisplayLink?
    private var speedStartTime: CFTimeInterval = 0
    private var speedStartFrame = 0
    private var endHandler: (() -> Void)?
    /// [EN] Whether SVGAPlayer's own display link runs a pass (`step(toFrame:andPlay: true)`): SVGAPlayer does not expose it.
    /// [CN] SVGAPlayer 自己的 display link 是否正在播放一遍（`step(toFrame:andPlay: true)`）：SVGAPlayer 没有公开这一状态。
    private var playerRunning = false

    /**
     * [EN] `CYLTabBarItemAnimationViewProviding`: a view for an SVGA file (local, or http / https parsed by SVGAParser).
     * [CN] `CYLTabBarItemAnimationViewProviding`：为 SVGA 文件（本地，或由 SVGAParser 解析的 http / https）创建视图。
     */
    @objc(cyl_animationViewWithFileURL:options:contentMode:)
    public static func makeAnimationView(fileURL: URL, options _: [String: String], contentMode: UIView.ContentMode) -> UIView? {
        let view = CYLSVGATabBarItemAnimationView(frame: .zero)
        view.loops = 1
        view.delegate = view
        view.clearsAfterStop = false
        view.fillMode = "Forward"
        view.contentMode = contentMode
        view.isUserInteractionEnabled = false
        view.isAccessibilityElement = false
        let completion: (SVGAVideoEntity) -> Void = { [weak view] videoItem in
            guard let view else {
                return
            }
            view.show(videoItem)
            CYLTabBarItemAnimationReportLoaded(view)
        }
        let failure: (Error?) -> Void = { [weak view] error in
            #if DEBUG
            NSLog("🔴 CYLTabBarController SVGA: %@ could not be parsed: %@", fileURL.absoluteString, error?.localizedDescription ?? "")
            #endif
            // [EN] A corrupted file or a failed download: the host shows its image or placeholder. [CN] 文件损坏或下载失败：宿主显示其图片或占位图。
            guard let view else {
                return
            }
            CYLTabBarItemAnimationReportFailure(view, error as NSError?)
        }
        let parser = SVGAParser()
        parser.enabledMemoryCache = true
        if fileURL.isFileURL {
            guard let data = try? Data(contentsOf: fileURL), !data.isEmpty else {
                return nil
            }
            parser.parse(with: data, cacheKey: fileURL.absoluteString, completionBlock: completion, failureBlock: failure)
        } else {
            // [EN] A download: the host shows its static image, or its placeholder, until the file is parsed.
            // [CN] 下载中：在文件解析完成之前，宿主显示其静态图片或占位图。
            CYLTabBarItemAnimationMarkLoading(view)
            parser.parse(with: fileURL, completionBlock: { videoItem in
                if let videoItem {
                    completion(videoItem)
                } else {
                    failure(nil)
                }
            }, failureBlock: failure)
        }
        return view
    }

    private func show(_ videoItem: SVGAVideoEntity) {
        self.videoItem = videoItem
        switch requestedState {
        case .playing:
            playAnimationView()
        case .lastFrame:
            showAnimationViewLastFrame()
        case .firstFrame:
            stopAnimationView()
        }
    }

    @objc(cyl_playAnimationView)
    public func playAnimationView() {
        requestedState = .playing
        guard let videoItem else {
            return
        }
        stopSpeedLink()
        currentFrame = 0
        if speed != 1 && videoItem.fps > 0 {
            playerRunning = false
            step(toFrame: 0, andPlay: false)
            startSpeedLink(from: 0)
        } else {
            playerRunning = true
            step(toFrame: 0, andPlay: true)
        }
        keepTintOverlayAboveDrawing()
    }

    @objc(cyl_showAnimationViewLastFrame)
    public func showAnimationViewLastFrame() {
        requestedState = .lastFrame
        stopSpeedLink()
        guard let frames = videoItem?.frames, frames > 0 else {
            return
        }
        currentFrame = Int(frames) - 1
        playerRunning = false
        step(toFrame: currentFrame, andPlay: false)
        keepTintOverlayAboveDrawing()
    }

    @objc(cyl_stopAnimationView)
    public func stopAnimationView() {
        requestedState = .firstFrame
        stopSpeedLink()
        guard videoItem != nil else {
            return
        }
        currentFrame = 0
        playerRunning = false
        step(toFrame: 0, andPlay: false)
        keepTintOverlayAboveDrawing()
    }

    // MARK: - Loop, seek and speed

    @objc(cyl_setAnimationViewLoops:)
    public func setAnimationViewLoops(_ loops: Bool) {
        loopsForever = loops
        // [EN] SVGAPlayer: 0 repeats until stopped. [CN] SVGAPlayer：0 表示一直重复直到停止。
        self.loops = loops ? 0 : 1
    }

    /**
     * [EN] Whether a pass is running: the display link of a rate other than 1, or SVGAPlayer's own animation.
     * [CN] 是否正在播放一遍：速率不为 1 时的 display link，或 SVGAPlayer 自己的动画。
     */
    @objc(cyl_animationViewIsPlaying)
    public func isAnimationPlaying() -> Bool {
        speedLink != nil || playerRunning
    }

    /**
     * [EN] Called when a one-pass animation reaches its last frame (either path); not on a stop, not while looping.
     * [CN] 只播放一遍的动画到达最后一帧时调用（两种路径都会）；停止时不调用，循环时不调用。
     */
    @objc(cyl_setAnimationViewEndHandler:)
    public func setAnimationEndHandler(_ handler: (() -> Void)?) {
        endHandler = handler
    }

    @objc(cyl_animationViewProgress)
    public func animationViewProgress() -> CGFloat {
        let frames = Int(videoItem?.frames ?? 0)
        return frames > 1 ? CGFloat(currentFrame) / CGFloat(frames - 1) : 0
    }

    @objc(cyl_setAnimationViewProgress:)
    public func setAnimationViewProgress(_ progress: CGFloat) {
        let frames = Int(videoItem?.frames ?? 0)
        guard frames > 0 else {
            return
        }
        stopSpeedLink()
        currentFrame = Int((min(max(progress, 0), 1) * CGFloat(frames - 1)).rounded())
        playerRunning = false
        step(toFrame: currentFrame, andPlay: false)
        keepTintOverlayAboveDrawing()
    }

    @objc(cyl_setAnimationViewSpeed:)
    public func setAnimationViewSpeed(_ speed: CGFloat) {
        guard speed > 0, speed.isFinite, speed != self.speed else {
            return
        }
        self.speed = speed
        let playing = speedLink != nil || requestedState == .playing
        guard playing, let videoItem, videoItem.fps > 0 else {
            return
        }
        // [EN] Live: continue from the frame shown now at the new rate. [CN] 实时生效：从当前帧以新速率继续。
        let frame = currentFrame
        stopSpeedLink()
        if speed == 1 {
            playerRunning = true
            step(toFrame: frame, andPlay: true)
        } else {
            playerRunning = false
            pauseAnimation()
            startSpeedLink(from: frame)
        }
    }

    private func startSpeedLink(from frame: Int) {
        speedStartFrame = frame
        speedStartTime = CACurrentMediaTime()
        let link = CADisplayLink(target: self, selector: #selector(speedTick(_:)))
        link.add(to: .main, forMode: .common)
        speedLink = link
    }

    private func stopSpeedLink() {
        speedLink?.invalidate()
        speedLink = nil
    }

    @objc private func speedTick(_: CADisplayLink) {
        let frames = Int(videoItem?.frames ?? 0)
        let fps = Double(videoItem?.fps ?? 0)
        guard frames > 0, fps > 0 else {
            stopSpeedLink()
            return
        }
        let elapsed = CACurrentMediaTime() - speedStartTime
        var frame = speedStartFrame + Int(floor(elapsed * fps * Double(speed)))
        if frame >= frames {
            if !loopsForever {
                // [EN] One pass: rest on the last frame, as fillMode "Forward". [CN] 播放一遍：停在最后一帧，与 fillMode "Forward" 相同。
                stopSpeedLink()
                currentFrame = frames - 1
                playerRunning = false
                step(toFrame: frames - 1, andPlay: false)
                keepTintOverlayAboveDrawing()
                endHandler?()
                return
            }
            frame %= frames
        }
        if frame != currentFrame {
            currentFrame = frame
            step(toFrame: frame, andPlay: false)
            keepTintOverlayAboveDrawing()
        }
    }

    public override func removeFromSuperview() {
        stopSpeedLink()
        super.removeFromSuperview()
    }

    // MARK: - SVGAPlayerDelegate

    public func svgaPlayer(_: SVGAPlayer!, didAnimatedToFrame frame: Int) {
        currentFrame = frame
    }

    public func svgaPlayerDidFinishedAnimation(_: SVGAPlayer!) {
        if !loopsForever {
            playerRunning = false
            endHandler?()
        }
    }

    /**
     * [EN] SVGAPlayer adds its drawing layer on top of its own layer each time it draws, which hid the `tint` overlay the
     *      engine puts over the view (a layer composited "sourceAtop"): it goes back right above the drawing layer, sized to
     *      the view, and nothing else moves (a badge keeps its place).
     * [CN] SVGAPlayer 每次绘制都会把其绘制图层加到自身图层的最上方，遮住引擎放在视图上的 `tint` 叠加视图（以 "sourceAtop" 合成的图层）：把它放回
     *      绘制图层的正上方并与视图同尺寸，其他内容位置不变（角标保持原位）。
     */
    private func keepTintOverlayAboveDrawing() {
        guard responds(to: NSSelectorFromString("drawLayer")), let drawLayer = value(forKey: "drawLayer") as? CALayer,
              drawLayer.superlayer === layer else {
            return
        }
        if let overlay = layer.sublayers?.first(where: { $0.name == "CYLTabBarItemAnimationTintOverlay" }) {
            overlay.frame = bounds
            layer.insertSublayer(overlay, above: drawLayer)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        keepTintOverlayAboveDrawing()
    }
}
#endif
