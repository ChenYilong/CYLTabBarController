//
//  CYLAnimationEventBridge.swift
//  CYLTabBarController
//
//  [EN] Turns the animation pod's notifications into library events. [CN] 把动画 pod 的通知转为库事件。
//

import UIKit
#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if canImport(CYLBadge)
import CYLBadge
#endif
import os
import CYLAnimatedItem
#if SWIFT_PACKAGE
import CYLAnimatedItemViews
#endif
internal import CYLDeallocBlockExecutor

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
        track()
    }

    /**
     [EN] Pauses (`true`) or resumes (`false`) every playing animated item, for hosts that decide themselves (React Native, Flutter).
     [CN] 暂停（`true`）或恢复（`false`）所有正在播放的动画控件，供自行决定的宿主使用（React Native、Flutter）。
     */
    public static func setAnimationsPaused(_ paused: Bool) {
        track()
        paused ? pauseAllPlaying() : resumeAllPlaying()
    }

    // MARK: - Observing the pause path

    /**
     [EN] How many times every playing item was paused and resumed since launch (by `setAnimationsPaused(_:)` or by the scroll
          pause). For debugging and demos: the example shows them next to the "Pause while scrolling" switch, and the tests read
          them to see the scroll path without the library's log.
     [CN] 自启动以来所有播放中控件被暂停与恢复的次数（来自 `setAnimationsPaused(_:)` 或滚动暂停）。用于调试与示例：示例在「滚动时暂停」
          开关旁显示它们，测试也用它们在不依赖库日志的情况下观察滚动路径。
     */
    public private(set) static var pauseCount = 0
    public private(set) static var resumeCount = 0

    /**
     [EN] Posted on the main queue after `pauseCount` or `resumeCount` changed. [CN] `pauseCount` 或 `resumeCount` 变化后在主队列发出。
     */
    public static let countsDidChangeNotification = Notification.Name("CYLAnimationEventBridgeCountsDidChange")

    private static func pauseAllPlaying() {
        pauseCount += 1
        playing.allObjects.forEach { $0.pauseAnimation() }
        NotificationCenter.default.post(name: countsDidChangeNotification, object: nil)
    }

    private static func resumeAllPlaying() {
        resumeCount += 1
        playing.allObjects.forEach { $0.resumeAnimation() }
        NotificationCenter.default.post(name: countsDidChangeNotification, object: nil)
    }

    // MARK: - Pause while the user scrolls

    private static let playing = NSHashTable<CYLAnimatedItemView>.weakObjects()
    private static var trackingInstalled = false
    /// [EN] Starts remembering which views play, once. [CN] 开始记录哪些视图在播放（只执行一次）。
    private static func track() {
        install()
        guard !trackingInstalled else { return }
        trackingInstalled = true
        let center = NotificationCenter.default
        center.addObserver(forName: Notification.Name("cyl.animation.didStart"), object: nil, queue: nil) { note in
            if let view = note.object as? CYLAnimatedItemView { playing.add(view) }
        }
        center.addObserver(forName: Notification.Name("cyl.animation.didStop"), object: nil, queue: nil) { note in
            if let view = note.object as? CYLAnimatedItemView { playing.remove(view) }
        }
    }

    /**
     [EN] Writes every lifecycle moment the library sees (window, screen, scroll, animation, badge) to the unified log, subsystem
          `CYLTabBarController`, category `lifecycle` (`xcrun simctl spawn <udid> log stream --predicate 'subsystem == "CYLTabBarController"'`).
          For debugging only; off by default.
     [CN] 把库看到的每个生命周期时机（窗口、屏幕、滚动、动画、角标）写入统一日志，subsystem 为 `CYLTabBarController`，category 为 `lifecycle`。
          仅用于调试；默认关闭。
     */
    public static func logsLifecycleMoments(_ enabled: Bool) {
        CYLLifecycleLog.isEnabled = enabled
        let logger = Logger(subsystem: "CYLTabBarController", category: "lifecycle")
        CYLLifecycleLog.sink = { message in logger.notice("\(message, privacy: .public)") }
    }

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
        track()
        removeScrollObservers?()
        removeScrollObservers = nil
        guard enabled else { return }
        removeScrollObservers = CYLLifecycleCenter.whileUserScrolls(key: "cyl.animation.scroll", pause: {
            pauseAllPlaying()
        }, resume: {
            resumeAllPlaying()
        })
    }
}

/**
 [EN] The entry point the animation pod finds by name (`CYLAnimatedItemView` cannot import this module): installs the bridge.
 [CN] 动画 pod 按名称查找的入口（`CYLAnimatedItemView` 不能导入本模块）：安装桥接。
 */
@objc(CYLAnimationEventBridgeInstaller)
final class CYLAnimationEventBridgeInstaller: NSObject {
    @objc static func install() {
        CYLAnimationEventBridge.install()
    }
}
