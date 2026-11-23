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

    // MARK: - The cross-platform player contract 跨平台播放器约定

    /// [EN] The GIF engine's answers: no speed, loops, progress or colors; playing and the end of a pass are reported.
    /// [CN] GIF 引擎的回答：没有速度、循环、进度与颜色；播放状态与一遍播放的结束会被报告。
    func testGIFPlayerAnswersTheCrossPlatformContract() throws {
        let url = try makeTwoFrameGIF()
        defer { try? FileManager.default.removeItem(at: url) }
        let view = try XCTUnwrap(CYLTabBarItemAnimationFactory.shared().animationView(url: url, size: CGSize(width: 24, height: 24), contentMode: .scaleAspectFit))
        let player = try XCTUnwrap(CYLTabBarItemAnimationFactory.shared().player(for: view))
        XCTAssertEqual(player.supportsSpeed, false)
        XCTAssertEqual(player.supportsLoops, false)
        XCTAssertEqual(player.supportsProgress, false)
        XCTAssertEqual(player.supportsColors, false)
        XCTAssertEqual(player.isPlaying, false)
        XCTAssertEqual(player.speed, 1, "an engine without speed reports 1")
        let base = try XCTUnwrap(player as? CYLTabBarItemAnimationBasePlayer)
        // [EN] Core Animation only runs the animation of a layer that is on screen. [CN] Core Animation 只运行在屏幕上的 layer 的动画。
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        window.addSubview(view)
        window.makeKeyAndVisible()
        defer { window.isHidden = true }
        let ended = expectation(description: "the pass ended")
        base.onEnded = { ended.fulfill() }
        player.play()
        XCTAssertEqual(player.isPlaying, true)
        wait(for: [ended], timeout: 3)
        XCTAssertEqual(player.isPlaying, false)
    }

    /// [EN] A stop is not the end of a pass. [CN] 停止不是一遍播放的结束。
    func testGIFStopDoesNotReportTheEnd() throws {
        let url = try makeTwoFrameGIF()
        defer { try? FileManager.default.removeItem(at: url) }
        let view = try XCTUnwrap(CYLTabBarItemAnimationFactory.shared().animationView(url: url, size: CGSize(width: 24, height: 24), contentMode: .scaleAspectFit))
        let player = try XCTUnwrap(CYLTabBarItemAnimationFactory.shared().player(for: view))
        let base = try XCTUnwrap(player as? CYLTabBarItemAnimationBasePlayer)
        let notEnded = expectation(description: "no end after a stop")
        notEnded.isInverted = true
        base.onEnded = { notEnded.fulfill() }
        player.play()
        player.stop()
        XCTAssertEqual(player.isPlaying, false)
        wait(for: [notEnded], timeout: 1)
    }
}

private func assertAccuratelyEqual(_ lhs: [Double], _ rhs: [Double], accuracy: Double, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(lhs.count, rhs.count, file: file, line: line)
    for (a, b) in zip(lhs, rhs) {
        XCTAssertEqual(a, b, accuracy: accuracy, file: file, line: line)
    }
}

// MARK: - The `#` option fixture 选项测试向量

/// [EN] A view that plays nothing, made by the recording provider. [CN] 什么也不播放的视图，由记录选项的 provider 创建。
private final class CYLRecordingOptionsView: UIView, CYLTabBarItemAnimationPlayableView {
    func playAnimation() {}
    func showAnimationLastFrame() {}
    func stopAnimation() {}
}

/// [EN] Records the file and the options the animator hands to its view provider. [CN] 记录 animator 交给视图 provider 的文件与选项。
@MainActor
private final class CYLRecordingOptionsProvider: NSObject, CYLTabBarItemAnimationViewProviding {
    static var received: (fileURL: URL, options: [String: String])?

    static func makeAnimationView(fileURL: URL, options: [String: String],
                                  contentMode _: UIView.ContentMode) -> (UIView & CYLTabBarItemAnimationPlayableView)? {
        received = (fileURL, options)
        return CYLRecordingOptionsView()
    }
}

/**
 [EN] `CrossPlatform/animated-item-fixtures/source-options.json` against the iOS parsers: the text form
      (`CYLAnimationSource`) and the URL form (`CYLTabBarAnimationURLWithOptions()` written, then read by the animator that
      hands the options to its view). Every platform's parser test reads the same file.
 [CN] `CrossPlatform/animated-item-fixtures/source-options.json` 对照 iOS 的解析器：文本形式（`CYLAnimationSource`）与 URL 形式
      （`CYLTabBarAnimationURLWithOptions()` 写入，再由把选项交给视图的 animator 读取）。每个平台的解析测试读取同一个文件。
 */
@MainActor
final class CYLAnimatedItemSourceOptionsTests: XCTestCase {

    private struct Case {
        let input: String
        let file: String?
        let inlineJSON: String?
        let type: String?
        let options: [String: String]
    }

    private func loadCases(file: StaticString = #filePath, line: UInt = #line) throws -> [Case] {
        // [EN] Relative to this file: CYLTabBarControllerTests/ -> the repository root. [CN] 相对本文件：CYLTabBarControllerTests/ 的上一级为仓库根目录。
        let root = URL(fileURLWithPath: "\(file)").deletingLastPathComponent().deletingLastPathComponent()
        let fixture = root.appendingPathComponent("CrossPlatform/animated-item-fixtures/source-options.json")
        let data = try Data(contentsOf: fixture)
        let object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any], file: file, line: line)
        let cases = try XCTUnwrap(object["cases"] as? [[String: Any]], file: file, line: line)
        XCTAssertFalse(cases.isEmpty, "the fixture has no case", file: file, line: line)
        return cases.map {
            Case(input: $0["input"] as? String ?? "", file: $0["file"] as? String, inlineJSON: $0["inlineJSON"] as? String,
                 type: $0["type"] as? String, options: $0["options"] as? [String: String] ?? [:])
        }
    }

    func testTextFormFollowsTheFixture() throws {
        for item in try loadCases() {
            let source = CYLAnimationSource(parsing: item.input)
            XCTAssertEqual(source.options, item.options, item.input)
            XCTAssertEqual(source.inlineJSON, item.inlineJSON, item.input)
            if let file = item.file {
                XCTAssertEqual(source.file, file, item.input)
            }
            if let type = item.type {
                XCTAssertEqual(source.type, type, item.input)
            }
        }
    }

    func testURLFormRoundTripsEveryOption() throws {
        for item in try loadCases() where item.inlineJSON == nil {
            let file = try XCTUnwrap(item.file)
            let fileURL = URL(fileURLWithPath: "/tmp/\(file)")
            let url = try XCTUnwrap(CYLTabBarAnimationURLWithOptions(fileURL, item.options), item.input)
            let animator = CYLTabBarItemViewAnimator(identifier: "Recording", fileExtensions: [fileURL.pathExtension],
                                                     attributeKeys: nil, viewProvider: CYLRecordingOptionsProvider.self)
            CYLRecordingOptionsProvider.received = nil
            XCTAssertNotNil(animator.animationView(with: url, size: CGSize(width: 24, height: 24), contentMode: .scaleAspectFit), item.input)
            let received = try XCTUnwrap(CYLRecordingOptionsProvider.received, item.input)
            XCTAssertEqual(received.options, item.options, item.input)
            XCTAssertEqual(received.fileURL.path, fileURL.path, item.input)
            XCTAssertEqual(CYLTabBarAnimationOptionsFromURL(url) as? [String: String], item.options, item.input)
        }
    }

    /// [EN] The rules the fixture lists: an undecodable text is kept, a pair without a name is dropped, `#` and `?` split a pair
    ///      only when they do not follow `=`. [CN] 向量文件列出的规则：无法解码的文本保持原样，没有名称的键值对被丢弃，`#` 与 `?` 只在不紧跟 `=` 时拆分。
    func testRulesOfTheFixture() {
        XCTAssertEqual(CYLAnimationSource(parsing: "a.riv#x=100%&y=%E0%A4%A").options, ["x": "100%", "y": "%E0%A4%A"])
        XCTAssertEqual(CYLAnimationSource(parsing: "a.riv#=1&novalue&k=v").options, ["k": "v"])
        XCTAssertEqual(CYLAnimationSource(parsing: "a.riv?a=1#b=2&c=#FF0000").options, ["a": "1", "b": "2", "c": "#FF0000"])
        XCTAssertEqual(CYLAnimationSource(parsing: "asset:a.riv#k=v").file, "a.riv")
        XCTAssertEqual(CYLAnimationSource(parsing: "[1]").type, "Lottie")
    }
}

/// [EN] A playable view that ends its pass when the test says so: stands for the view of an engine whose own library tells the
///      end (SVGA, Rive), reached through the same optional members of `CYLTabBarItemAnimationPlayableView`.
/// [CN] 由测试决定何时结束一遍播放的可播放视图：代表由其动画库报告结束的引擎视图（SVGA、Rive），经由
///      `CYLTabBarItemAnimationPlayableView` 的同一组可选成员。
private final class CYLEndingPlayableView: UIView, CYLTabBarItemAnimationPlayableView {
    private(set) var isPlayingNow = false
    private var endHandler: (() -> Void)?

    func playAnimation() { isPlayingNow = true }
    func showAnimationLastFrame() {}
    func stopAnimation() { isPlayingNow = false }
    func setAnimationLoops(_: Bool) {}
    func isAnimationPlaying() -> Bool { isPlayingNow }
    func setAnimationEndHandler(_ handler: (() -> Void)?) { endHandler = handler }

    /// [EN] The library reports that a pass ran to its end, always: the guards against reporting while looping belong to the
    ///      player and the item, and are what the tests check. [CN] 动画库一律报告一遍播放到了结尾：循环时不报告的保护属于播放器与条目，
    ///      正是测试要检查的。
    func finishPass() {
        isPlayingNow = false
        endHandler?()
    }
}

@MainActor
private final class CYLEndingViewProvider: NSObject, CYLTabBarItemAnimationViewProviding {
    static func makeAnimationView(fileURL _: URL, options _: [String: String],
                                  contentMode _: UIView.ContentMode) -> (UIView & CYLTabBarItemAnimationPlayableView)? {
        CYLEndingPlayableView()
    }
}

/**
 [EN] The end callbacks (`CYLTabBarItemAnimationPlayer.onEnded`, `CYLAnimatedItemView.onAnimationEnd`) of the engines whose view
      is a `CYLTabBarItemAnimationPlayableView` (Rive, SVGA, GIF), through the shared `CYLTabBarItemViewAnimator` with a fake view
      in place of the library's. What no test here can reach without the library: the moment the library reports the end (see
      docs/Animated-Item.md, "Engine API across platforms").
 [CN] 视图为 `CYLTabBarItemAnimationPlayableView` 的引擎（Rive、SVGA、GIF）的结束回调（`CYLTabBarItemAnimationPlayer.onEnded`、
      `CYLAnimatedItemView.onAnimationEnd`）：经由共用的 `CYLTabBarItemViewAnimator`，用假视图代替动画库的视图。没有动画库时这里的测试够不到的是：
      动画库报告结束的那一刻（见 docs/Animated-Item.md「Engine API across platforms」）。
 */
@MainActor
final class CYLAnimationEndCallbackTests: XCTestCase {

    private func makeFactory() -> CYLTabBarItemAnimationFactory {
        let registry = CYLTabBarItemAnimatorRegistry()
        registry.register(CYLTabBarItemViewAnimator(identifier: "Ending", fileExtensions: ["ending"], attributeKeys: nil,
                                                            viewProvider: CYLEndingViewProvider.self))
        return CYLTabBarItemAnimationFactory(registry: registry)
    }

    /// [EN] A remote URL, so the item has no file to look for (as the Objective-C test of the fake engine does). [CN] 远程 URL，因此条目没有要查找的文件
    ///      （与 Objective-C 假引擎测试相同）。
    private let fileURL = URL(string: "https://example.com/ending.ending")!

    func testThePlayerReportsTheEndOfAPlayOncePass() throws {
        let factory = makeFactory()
        let view = try XCTUnwrap(factory.animationView(url: fileURL, size: CGSize(width: 24, height: 24), contentMode: .scaleAspectFit) as? CYLEndingPlayableView)
        let player = try XCTUnwrap(factory.player(for: view))
        XCTAssertTrue(player.supportsLoops == true)
        var ends = 0
        let base = try XCTUnwrap(player as? CYLTabBarItemAnimationBasePlayer)
        base.onEnded = { ends += 1 }
        player.play()
        XCTAssertTrue(player.isPlaying == true)
        view.finishPass()
        XCTAssertEqual(ends, 1)
        XCTAssertTrue(player.isPlaying == false)
    }

    func testAStopAndALoopReportNoEnd() throws {
        let factory = makeFactory()
        let view = try XCTUnwrap(factory.animationView(url: fileURL, size: CGSize(width: 24, height: 24), contentMode: .scaleAspectFit) as? CYLEndingPlayableView)
        let player = try XCTUnwrap(factory.player(for: view))
        var ends = 0
        let base = try XCTUnwrap(player as? CYLTabBarItemAnimationBasePlayer)
        base.onEnded = { ends += 1 }
        player.play()
        player.stop()
        XCTAssertEqual(ends, 0, "a stop is not an end")
        XCTAssertFalse(view.isPlayingNow)
        // [EN] `loops` YES: the view loops and reports nothing. [CN] `loops` 为 YES：视图自己循环，不报告。
        let looping = try XCTUnwrap(player as? NSObject)
        looping.setValue(true, forKey: "loops")
        player.play()
        view.finishPass()
        XCTAssertEqual(ends, 0, "the player drops an end that arrives while it loops")
        looping.setValue(false, forKey: "loops")
        player.play()
        view.finishPass()
        XCTAssertEqual(ends, 1, "the same player reports it again once it plays once")
    }

    func testTheItemReportsOnAnimationEndOnlyForAPlayOncePass() throws {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        item.animationSource = makeFactory()
        var ends = 0
        item.onAnimationEnd = { ends += 1 }
        item.animationURL = fileURL
        let view = try XCTUnwrap(item.animationView as? CYLEndingPlayableView)
        item.playAnimation()
        view.finishPass()
        XCTAssertEqual(ends, 1, "a play-once pass that runs to its end")
        item.animationLoops = true
        item.playAnimation()
        view.finishPass()
        XCTAssertEqual(ends, 1, "a looping animation has no end to report")
        item.animationLoops = false
        item.playAnimation()
        item.stopAnimation()
        XCTAssertEqual(ends, 1, "a stop is not an end")
        item.drivesAnimationPlayback = false
        item.animationPlayer?.play()
        view.finishPass()
        XCTAssertEqual(ends, 2, "a host that drives playback still gets the end")
    }
}
