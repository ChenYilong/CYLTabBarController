//
//  CYLAnimationEngineSwiftTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import XCTest
import ImageIO
import CYLTabBarController
import CYLAnimatedItem

/**
 [EN] The animation engine's move to Swift (docs/Swift-Migration.md, 2026-11-21): every ported type keeps its Objective-C
      name, selectors and protocol list, so Objective-C callers and runtime lookups keep working.
 [CN] 动画引擎迁移到 Swift（docs/Swift-Migration.md，2026-11-21）：每个迁移的类型保留其 Objective-C 名称、选择器与协议列表，
      Objective-C 调用方与运行时查找继续可用。
 */
final class CYLAnimationEngineSwiftTests: XCTestCase {

    func testTabButtonPlayerKeepsItsObjectiveCSelector() {
        let control = UIControl()
        XCTAssertTrue(control.responds(to: NSSelectorFromString("cyl_tabBarItemAnimationPlayer")))
        XCTAssertNil(control.cyl_tabBarItemAnimationPlayer, "no animation view, no player")
    }

    /// [EN] A two-frame GIF (0.2 s and 0.3 s) on disk. [CN] 磁盘上的两帧 GIF（0.2 秒与 0.3 秒）。
    private func makeTwoFrameGIF() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".gif")
        let destination = try XCTUnwrap(CGImageDestinationCreateWithURL(url as CFURL, "com.compuserve.gif" as CFString, 2, nil))
        for (color, delay) in [(UIColor.red, 0.2), (UIColor.blue, 0.3)] {
            let image = UIGraphicsImageRenderer(size: CGSize(width: 4, height: 4)).image { context in
                color.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
            }
            let properties = [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: delay]] as CFDictionary
            CGImageDestinationAddImage(destination, try XCTUnwrap(image.cgImage), properties)
        }
        XCTAssertTrue(CGImageDestinationFinalize(destination))
        return url
    }

    /// [EN] The GIF view, Swift since the engine migration: same Objective-C name and protocols, registered by the GIF animator.
    /// [CN] GIF 视图，引擎迁移后为 Swift：Objective-C 名称与协议不变，由 GIF animator 注册。
    func testGIFViewKeepsItsNameProtocolsAndAnimator() throws {
        let viewClass: AnyClass = try XCTUnwrap(NSClassFromString("CYLGIFTabBarItemAnimationView"))
        XCTAssertTrue(viewClass.isSubclass(of: UIImageView.self))
        XCTAssertTrue(class_conformsToProtocol(viewClass, NSProtocolFromString("CYLTabBarItemAnimationPlayableView")))
        XCTAssertTrue(class_conformsToProtocol(viewClass, NSProtocolFromString("CYLTabBarItemAnimationViewProviding")))
        let animatorClass: AnyClass = try XCTUnwrap(NSClassFromString("CYLGIFTabBarItemAnimator"))
        let animator = try XCTUnwrap((animatorClass as AnyObject).value(forKey: "animator") as? NSObject)
        XCTAssertTrue(animator.value(forKey: "viewProvider") as AnyObject === viewClass, "the animator makes the Swift view")
    }

    /// [EN] Decodes every frame with its own delay; play shows the last frame under one discrete animation, stop the first.
    /// [CN] 解码每一帧及其时长；播放时显示最后一帧并加上一个离散动画，停止时显示第一帧。
    @MainActor
    func testGIFViewPlaysEachFrameWithItsDelay() throws {
        let url = try makeTwoFrameGIF()
        defer { try? FileManager.default.removeItem(at: url) }
        let view = try XCTUnwrap(CYLGIFTabBarItemAnimationView.makeAnimationView(fileURL: url, options: [:], contentMode: .scaleAspectFit)
                                 as? CYLGIFTabBarItemAnimationView)
        XCTAssertEqual(view.contentMode, .scaleAspectFit)
        let first = view.image
        XCTAssertNotNil(first)
        view.playAnimation()
        let animation = try XCTUnwrap(view.layer.animation(forKey: "CYLGIFTabBarItemPlayAnimation") as? CAKeyframeAnimation)
        XCTAssertEqual(animation.calculationMode, .discrete)
        XCTAssertEqual(animation.duration, 0.5, accuracy: 0.001)
        XCTAssertEqual(animation.values?.count, 2)
        assertAccuratelyEqual(animation.keyTimes?.map(\.doubleValue) ?? [], [0, 0.4, 1], accuracy: 0.001)
        XCTAssertFalse(view.image === first, "the last frame is the end state")
        view.stopAnimation()
        XCTAssertNil(view.layer.animation(forKey: "CYLGIFTabBarItemPlayAnimation"))
        XCTAssertTrue(view.image === first)
        let notGIF = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".gif")
        try Data("no gif".utf8).write(to: notGIF)
        defer { try? FileManager.default.removeItem(at: notGIF) }
        XCTAssertNil(CYLGIFTabBarItemAnimationView.makeAnimationView(fileURL: notGIF, options: [:], contentMode: .center))
    }

    /// [EN] The resource bundle lookup, Swift since engine step 3: the C symbol and the Swift entry point return the same cached bundle.
    /// [CN] 资源包查找，引擎第 3 步起为 Swift：C 符号与 Swift 入口返回同一个缓存的资源包。
    func testResourceBundleKeepsItsCSymbol() {
        XCTAssertTrue(CYLAnimatedItemResourceBundle() === cylAnimatedItemResourceBundleEntryPoint())
        if let bundle = CYLAnimatedItemResourceBundle() {
            XCTAssertEqual(bundle.bundleURL.lastPathComponent, "CYLAnimatedItem.bundle")
        }
    }

    func testGIFFrameDelayClampsLikeBrowsers() {
        XCTAssertEqual(CYLGIFTabBarItemAnimationView.frameDelay(properties: nil), 0.1)
        let gif = { (key: CFString, value: Double) in [kCGImagePropertyGIFDictionary: [key: value] as [CFString: Any]] as [CFString: Any] }
        XCTAssertEqual(CYLGIFTabBarItemAnimationView.frameDelay(properties: gif(kCGImagePropertyGIFDelayTime, 0.01)), 0.1)
        XCTAssertEqual(CYLGIFTabBarItemAnimationView.frameDelay(properties: gif(kCGImagePropertyGIFUnclampedDelayTime, 0.25)), 0.25)
    }
}

private func assertAccuratelyEqual(_ lhs: [Double], _ rhs: [Double], accuracy: Double, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(lhs.count, rhs.count, file: file, line: line)
    for (a, b) in zip(lhs, rhs) {
        XCTAssertEqual(a, b, accuracy: accuracy, file: file, line: line)
    }
}
