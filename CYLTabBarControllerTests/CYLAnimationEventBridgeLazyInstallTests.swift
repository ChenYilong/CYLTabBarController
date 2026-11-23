//
//  CYLAnimationEventBridgeLazyInstallTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import XCTest
import UIKit
import CYLTabBarController
import CYLAnimatedItem

/**
 [EN] The bridge is installed lazily: not at launch, but by the first `CYLAnimatedItemView` of the process (the pod finds
      `CYLAnimationEventBridgeInstaller` by name). `install()` adds notification observers (it swizzles nothing) and the
      library has no public "is installed" flag, so the test observes the effect: a pause through
      `setAnimationsPaused(_:)` reaches an item that started playing before that call only if the bridge was already
      listening when the item started, which nobody but the item's own creation could have arranged. The bridge is
      process-wide, so this is only meaningful in a fresh process: run it alone,
      `xcodebuild test -only-testing:CYLTabBarControllerTests/CYLAnimationEventBridgeLazyInstallTests`. In a full run an
      earlier test may have touched the bridge, and the test skips instead of failing.
 [CN] 桥接是惰性安装的：不在启动时，而是由进程中第一个 `CYLAnimatedItemView` 安装（动画 pod 按名称查找
      `CYLAnimationEventBridgeInstaller`）。`install()` 只添加通知观察者（不做 swizzle），库也没有公开的“是否已安装”标志，
      所以本测试观察效果：只有当桥接在控件开始播放时已经在监听，`setAnimationsPaused(_:)` 才能暂停在该调用之前开始播放的控件，
      而这只能由控件自身的创建来保证。桥接是进程级的，所以只有在全新进程中才有意义：单独运行它，
      `xcodebuild test -only-testing:CYLTabBarControllerTests/CYLAnimationEventBridgeLazyInstallTests`。
      完整运行时，之前的测试可能已动过桥接，此时本测试跳过而不是失败。
 */
@MainActor
final class CYLAnimationEventBridgeLazyInstallTests: XCTestCase {

    private func makeAnimatedImage() -> UIImage {
        let frames = [UIColor.red, UIColor.blue].map { color in
            UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
            }
        }
        return UIImage.animatedImage(with: frames, duration: 1) ?? UIImage()
    }

    func testTheFirstAnimatedItemInstallsTheBridgeBeforeItPlays() throws {
        try XCTSkipIf(CYLAnimationEventBridge.pauseCount != 0 || CYLAnimationEventBridge.resumeCount != 0,
                      "not a fresh process: an earlier test used the bridge")

        // [EN] Nobody called install(): the item's creation did. [CN] 没有人调用 install()：是控件的创建做的。
        let item = CYLAnimatedItemView(frame: .zero)
        XCTAssertTrue(item.playAnimatedImage(makeAnimatedImage()))
        XCTAssertTrue(item.imageView.isAnimating)
        CYLAnimationEventBridge.setAnimationsPaused(true)
        XCTAssertFalse(item.imageView.isAnimating, "tracked from its start, so the pause reached it")
        CYLAnimationEventBridge.setAnimationsPaused(false)
        XCTAssertTrue(item.imageView.isAnimating)
        item.stopAnimatedImage()
    }
}
