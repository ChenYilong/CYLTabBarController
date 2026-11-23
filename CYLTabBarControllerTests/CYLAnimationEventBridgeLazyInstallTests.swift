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
      `CYLAnimationEventBridgeInstaller` by name). The flag is process-wide, so this test is only meaningful in a fresh
      process: run it alone, `xcodebuild test -only-testing:CYLTabBarControllerTests/CYLAnimationEventBridgeLazyInstallTests`.
      In a full run an earlier test may have installed the bridge, and the test skips instead of failing.
 [CN] 桥接是惰性安装的：不在启动时，而是由进程中第一个 `CYLAnimatedItemView` 安装（动画 pod 按名称查找
      `CYLAnimationEventBridgeInstaller`）。该标志是进程级的，所以只有在全新进程中才有意义：单独运行它，
      `xcodebuild test -only-testing:CYLTabBarControllerTests/CYLAnimationEventBridgeLazyInstallTests`。
      完整运行时，之前的测试可能已安装桥接，此时本测试跳过而不是失败。
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

    func testTheFirstAnimatedItemInstallsTheBridgeAndNothingBeforeIt() throws {
        try XCTSkipIf(CYLAnimationEventBridge.isInstalled, "not a fresh process: an earlier test installed the bridge")
        XCTAssertEqual(CYLAnimationEventBridge.pauseCount, 0)
        XCTAssertEqual(CYLAnimationEventBridge.resumeCount, 0)

        let item = CYLAnimatedItemView(frame: .zero)
        XCTAssertTrue(CYLAnimationEventBridge.isInstalled, "the first item installed the bridge, nobody called install()")

        // [EN] Installed in time: an item that starts afterwards is tracked, so a pause reaches it.
        // [CN] 安装得及时：之后开始播放的控件被记录，因此暂停能到达它。
        XCTAssertTrue(item.playAnimatedImage(makeAnimatedImage()))
        CYLAnimationEventBridge.setAnimationsPaused(true)
        XCTAssertFalse(item.imageView.isAnimating, "tracked from its start, so the pause reached it")
        CYLAnimationEventBridge.setAnimationsPaused(false)
        item.stopAnimatedImage()
    }
}
