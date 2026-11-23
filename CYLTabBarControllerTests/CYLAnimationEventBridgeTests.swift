//
//  CYLAnimationEventBridgeTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import XCTest
import UIKit
import CYLTabBarController
import CYLAnimatedItem

/**
 [EN] The animation moments (`cyl.animation.didStart` / `didPause` / `didResume` / `didStop`) of an animated GIF icon, and `CYLAnimationEventBridge.setAnimationsPaused(_:)` (docs/Lifecycle-Library.md, steps 11 and 21).
 [CN] 动图（GIF）图标的动画时机（`cyl.animation.didStart` / `didPause` / `didResume` / `didStop`）
      以及 `CYLAnimationEventBridge.setAnimationsPaused(_:)`（docs/Lifecycle-Library.md，第 11 与 21 步）。
 */
@MainActor
final class CYLAnimationEventBridgeTests: XCTestCase {

    private let names = ["didStart", "didPause", "didResume", "didStop"].map { "cyl.animation.\($0)" }

    private func makeAnimatedImage() -> UIImage {
        let frames = [UIColor.red, UIColor.blue].map { color in
            UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
            }
        }
        return UIImage.animatedImage(with: frames, duration: 1) ?? UIImage()
    }

    /// [EN] Names of the notifications posted by `view`, in order. [CN] `view` 发出的通知名称（按顺序）。
    private func record(_ view: CYLAnimatedItemView) -> () -> [String] {
        var seen: [String] = []
        let tokens = names.map { name in
            NotificationCenter.default.addObserver(forName: Notification.Name(name), object: view, queue: nil) { _ in seen.append(name) }
        }
        addTeardownBlock { tokens.forEach { NotificationCenter.default.removeObserver($0) } }
        return { seen }
    }

    func testAnimatedImagePostsStartPauseResumeStop() {
        let view = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        let seen = record(view)
        XCTAssertTrue(view.playAnimatedImage(makeAnimatedImage()))
        XCTAssertTrue(view.imageView.isAnimating)
        view.pauseAnimation()
        XCTAssertFalse(view.imageView.isAnimating, "paused: the frames stop")
        view.pauseAnimation()
        view.resumeAnimation()
        XCTAssertTrue(view.imageView.isAnimating, "resumed: the frames run again")
        view.resumeAnimation()
        view.stopAnimatedImage()
        XCTAssertEqual(seen(), ["cyl.animation.didStart", "cyl.animation.didPause", "cyl.animation.didResume", "cyl.animation.didStop"],
                       "a second pause or resume without a state change posts nothing")
    }

    func testSetAnimationsPausedPausesAndResumesEveryPlayingItem() {
        // [EN] A tab bar controller installs the bridge when it is set up; items that start before that are not tracked.
        // [CN] TabBarController 在初始化时安装桥接；在此之前开始播放的控件不会被记录。
        CYLAnimationEventBridge.install()
        let playing = CYLAnimatedItemView(frame: .zero)
        let idle = CYLAnimatedItemView(frame: .zero)
        playing.playAnimatedImage(makeAnimatedImage())
        CYLAnimationEventBridge.setAnimationsPaused(true)
        XCTAssertFalse(playing.imageView.isAnimating)
        XCTAssertFalse(idle.imageView.isAnimating)
        CYLAnimationEventBridge.setAnimationsPaused(false)
        XCTAssertTrue(playing.imageView.isAnimating)
        XCTAssertFalse(idle.imageView.isAnimating, "an item that never played stays still")
        playing.stopAnimatedImage()
        CYLAnimationEventBridge.setAnimationsPaused(true)
        CYLAnimationEventBridge.setAnimationsPaused(false)
        XCTAssertFalse(playing.imageView.isAnimating, "a stopped item is not resumed")
    }
}
