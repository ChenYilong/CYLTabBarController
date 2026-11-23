//
//  CYLAnimationEventBridge.swift
//  CYLTabBarController
//
//  [EN] Turns the animation pod's notifications into library events. [CN] 把动画 pod 的通知转为库事件。
//

import UIKit
import CYLDeallocBlockExecutor

/**
 [EN] The animation pod (CYLAnimatedItem) posts `cyl.animation.didStart` / `didStop` as notifications because it does not
      depend on CYLDeallocBlockExecutor. This bridge, installed once, posts them as custom lifecycle events on the sending
      view, so `view.cylAddLifecycleEvent(named:)` blocks and `CYLLifecycleCenter` observers hear them (and the log lists them).
 [CN] 动画 pod（CYLAnimatedItem）不依赖 CYLDeallocBlockExecutor，因此以通知形式发出 `cyl.animation.didStart` / `didStop`。
      本桥接只安装一次，把它们作为自定义生命周期事件发到发送通知的视图上，
      于是 `view.cylAddLifecycleEvent(named:)` 的 block 与 `CYLLifecycleCenter` 观察者都能收到（日志也会列出）。
 */
enum CYLAnimationEventBridge {
    private static var installed = false

    static func install() {
        guard !installed else { return }
        installed = true
        for name in ["cyl.animation.didStart", "cyl.animation.didStop"] {
            NotificationCenter.default.addObserver(forName: Notification.Name(name), object: nil, queue: nil) { note in
                guard let view = note.object as? NSObject else { return }
                var info: [String: Any] = [:]
                if let url = note.userInfo?["url"] { info["url"] = url }
                view.cylPostLifecycleEvent(name, userInfo: info)
            }
        }
    }
}
