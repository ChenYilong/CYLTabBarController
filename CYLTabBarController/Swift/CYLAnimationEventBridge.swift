//
//  CYLAnimationEventBridge.swift
//  CYLTabBarController
//
//  [EN] Turns the animation pod's notifications into library events. [CN] 把动画 pod 的通知转为库事件。
//

import UIKit
import CYLAnimatedItem
import CYLDeallocBlockExecutor

/**
 [EN] The animation pod (CYLAnimatedItem) posts `cyl.animation.didStart` / `didStop` as notifications because it does not
      depend on CYLDeallocBlockExecutor. This bridge, installed once, posts them as custom lifecycle events on the sending
      view, so `view.cylAddLifecycleEvent(named:)` blocks and `CYLLifecycleCenter` observers hear them (and the log lists them).
 [CN] 动画 pod（CYLAnimatedItem）不依赖 CYLDeallocBlockExecutor，因此以通知形式发出 `cyl.animation.didStart` / `didStop`。
      本桥接只安装一次，把它们作为自定义生命周期事件发到发送通知的视图上，
      于是 `view.cylAddLifecycleEvent(named:)` 的 block 与 `CYLLifecycleCenter` 观察者都能收到（日志也会列出）。
 */
public enum CYLAnimationEventBridge {
    private static var installed = false

    public static func install() {
        guard !installed else { return }
        installed = true
        for name in ["cyl.animation.didStart", "cyl.animation.didStop", "cyl.animation.didPause", "cyl.animation.didResume"] {
            NotificationCenter.default.addObserver(forName: Notification.Name(name), object: nil, queue: nil) { note in
                guard let view = note.object as? NSObject else { return }
                var info: [String: Any] = [:]
                if let url = note.userInfo?["url"] { info["url"] = url }
                view.cylPostLifecycleEvent(name, userInfo: info)
            }
        }
    }

    // MARK: - Pause while the user scrolls

    private static let playing = NSHashTable<CYLAnimatedItemView>.weakObjects()
    private static var trackingInstalled = false
    private static var removeScrollObservers: (() -> Void)?

    /**
     [EN] Pauses every playing animated item while the user scrolls any scroll view, and resumes them when scrolling stopped
          (`CYLLifecycleCenter.whileUserScrolls`). Pass false to stop. Each pause and resume posts `cyl.animation.didPause` /
          `didResume`. Add your own blocks for finer control.
     [CN] 用户滚动任意 scroll view 时暂停所有正在播放的动画控件，滚动结束后恢复（`CYLLifecycleCenter.whileUserScrolls`）。
          传 false 停止。每次暂停与恢复都会发出 `cyl.animation.didPause` / `didResume`。需要更细的控制请添加自己的 block。
     */
    public static func pausesAnimationsWhileUserScrolls(_ enabled: Bool) {
        install()
        if !trackingInstalled {
            trackingInstalled = true
            let center = NotificationCenter.default
            center.addObserver(forName: Notification.Name("cyl.animation.didStart"), object: nil, queue: nil) { note in
                if let view = note.object as? CYLAnimatedItemView { playing.add(view) }
            }
            center.addObserver(forName: Notification.Name("cyl.animation.didStop"), object: nil, queue: nil) { note in
                if let view = note.object as? CYLAnimatedItemView { playing.remove(view) }
            }
        }
        removeScrollObservers?()
        removeScrollObservers = nil
        guard enabled else { return }
        removeScrollObservers = CYLLifecycleCenter.whileUserScrolls(key: "cyl.animation.scroll", pause: {
            playing.allObjects.forEach { $0.pauseAnimation() }
        }, resume: {
            playing.allObjects.forEach { $0.resumeAnimation() }
        })
    }
}
