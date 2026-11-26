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
@testable import CYLAnimatedItem
@testable import CYLTabBarController

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

/// [EN] A remote URL built from parts, so no test hard-codes a URI. [CN] 由各部分拼出的远程 URL，测试里不写死 URI。
private func cylTestRemoteURL(host: String, path: String) -> URL? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = host
    components.path = "/" + path
    return components.url
}

/// [EN] A file URL in the temporary directory, built from the file name. [CN] 临时目录里的文件 URL，由文件名拼出。
private func cylTestFileURL(_ name: String) -> URL {
    URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
}

// MARK: - The `#` option fixture 选项测试向量

/// [EN] A view that plays nothing, made by the recording provider. [CN] 什么也不播放的视图，由记录选项的 provider 创建。
private final class CYLRecordingOptionsView: UIView, CYLTabBarItemAnimationPlayableView {
    func playAnimation() {
        // Intentionally empty: this view plays nothing, the test only reads the options it was made with.
    }

    func showAnimationLastFrame() {
        // Intentionally empty: this view plays nothing.
    }

    func stopAnimation() {
        // Intentionally empty: this view plays nothing.
    }
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
    func showAnimationLastFrame() {
        // Intentionally empty: the test decides when a play ends, no last frame is drawn.
    }

    func stopAnimation() { isPlayingNow = false }

    func setAnimationLoops(_: Bool) {
        // Intentionally empty: looping is not part of what this view records.
    }

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
    private let fileURL = cylTestRemoteURL(host: "example.com", path: "ending.ending")!

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

    func testTheStillImageReplacesAnEndedAnimationOnlyWhenAsked() throws {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        item.animationSource = makeFactory()
        item.image = UIImage(systemName: "star")
        item.animationURL = fileURL
        let view = try XCTUnwrap(item.animationView as? CYLEndingPlayableView)
        XCTAssertFalse(item.showsImageWhenAnimationEnds, "off by default, like HarmonyOS and Android")
        item.playAnimation()
        view.finishPass()
        XCTAssertFalse(item.isShowingImageAfterAnimationEnd, "off: the last frame stays")
        XCTAssertFalse(view.isHidden)
        item.showsImageWhenAnimationEnds = true
        item.playAnimation()
        var shownOnEnd: Bool?
        item.onAnimationEnd = { shownOnEnd = item.isShowingImageAfterAnimationEnd }
        view.finishPass()
        XCTAssertTrue(item.isShowingImageAfterAnimationEnd, "the end swaps the animation for the still image")
        XCTAssertEqual(shownOnEnd, true, "onAnimationEnd comes after the image is shown")
        XCTAssertTrue(view.isHidden)
        XCTAssertFalse(item.imageView.isHidden)
        XCTAssertNotNil(item.imageView.image)
        item.restartAnimation()
        XCTAssertFalse(item.isShowingImageAfterAnimationEnd, "the next play shows the animation again")
        XCTAssertFalse(view.isHidden)
        item.animationLoops = true
        item.playAnimation()
        view.finishPass()
        XCTAssertFalse(item.isShowingImageAfterAnimationEnd, "a looping animation has no end")
        item.animationLoops = false
        item.playAnimation()
        view.finishPass()
        item.showsImageWhenAnimationEnds = false
        XCTAssertFalse(item.isShowingImageAfterAnimationEnd, "turning it off shows the animation again")
        XCTAssertFalse(view.isHidden)
    }
}

/**
 [EN] The tab bar's `onResourceMissing` (docs/Animated-Item.md): a UIKit tab button is not a `CYLAnimatedItemView`, so the tab
      animation engine reports a missing file of a tab to `CYLAnimationEngines.resourceMissingListener`, as Android's `CYLTabBar`
      does: once per resource per tab button, on the main queue, with one of the four reasons.
 [CN] Tab 栏的 `onResourceMissing`（docs/Animated-Item.md）：UIKit 的 Tab 按钮不是 `CYLAnimatedItemView`，因此 Tab 动画引擎把 Tab 缺失的文件报告给
      `CYLAnimationEngines.resourceMissingListener`，与 Android 的 `CYLTabBar` 相同：每个 Tab 按钮每个资源一次，在主队列，原因为四种之一。
 */
@MainActor
final class CYLTabBarResourceMissingTests: XCTestCase {

    private var heard: [String] = []

    override func setUp() {
        super.setUp()
        heard = []
        CYLAnimationEngines.resourceMissingListener = { [weak self] resource, reason in
            XCTAssertTrue(Thread.isMainThread)
            self?.heard.append("\((resource as NSString).lastPathComponent)|\(reason)")
        }
    }

    override func tearDown() {
        CYLAnimationEngines.resourceMissingListener = nil
        super.tearDown()
    }

    private func spin(_ seconds: TimeInterval = 0.1) {
        RunLoop.main.run(until: Date(timeIntervalSinceNow: seconds))
    }

    private func temporaryFile(_ name: String, contents: Data) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + "-" + name)
        try contents.write(to: url)
        return url
    }

    /// [EN] The engine reaches the reporter by its Objective-C selectors (it finds the class at run time). [CN] 引擎通过 Objective-C selector 访问报告方法（运行时查找类）。
    func testTheEngineFindsTheReporterByItsSelectors() {
        let engines: AnyClass = CYLAnimationEngines.self
        XCTAssertNotNil(NSClassFromString("CYLAnimationEngines"))
        XCTAssertTrue(engines.responds(to: NSSelectorFromString("cyl_reportTabAnimationFailureOfURL:error:owner:")))
        XCTAssertTrue(engines.responds(to: NSSelectorFromString("cyl_reportTabAnimationNotMadeForURL:owner:")))
    }

    func testALateFailureReportsTheFileOncePerTabButtonWithTheReasonOfTheError() {
        let button = UIControl()
        let url = cylTestFileURL("cyl-tab-home.json")
        let notFound = NSError(domain: NSCocoaErrorDomain, code: NSFileReadNoSuchFileError)
        CYLAnimationEngines.reportTabAnimationFailure(url: url, error: notFound, owner: button)
        CYLAnimationEngines.reportTabAnimationFailure(url: url, error: notFound, owner: button)
        spin()
        XCTAssertEqual(heard, ["cyl-tab-home.json|not found"], "once per resource per tab button")

        // [EN] The same file for another tab button is another report; another file for the same button too. [CN] 同一文件在另一个 Tab 按钮上是另一次报告；同一按钮的另一个文件也是。
        CYLAnimationEngines.reportTabAnimationFailure(url: url, error: nil, owner: UIControl())
        CYLAnimationEngines.reportTabAnimationFailure(url: cylTestFileURL("cyl-tab-mine.json"),
                                                      error: NSError(domain: "CYLTest", code: 1), owner: button)
        spin()
        XCTAssertEqual(heard, ["cyl-tab-home.json|not found", "cyl-tab-home.json|decode failed", "cyl-tab-mine.json|decode failed"])
    }

    func testTheResourceIsTheFileAsConfiguredWithoutTheOptionsOfTheSource() {
        CYLAnimationEngines.reportTabAnimationFailure(url: URL(string: cylTestFileURL("cyl-tab-rive.riv").absoluteString + "#artboard=Main")!, error: nil, owner: UIControl())
        spin()
        XCTAssertEqual(heard, ["cyl-tab-rive.riv|decode failed"])
    }

    func testAMissingLocalFileIsNotFoundAndAnEmptyOneIsUnreadable() throws {
        let missing = URL(fileURLWithPath: NSTemporaryDirectory() + "cyl-tab-missing.json")
        XCTAssertEqual(CYLAnimationEngines.tabAnimationNotMadeReason(missing), "not found")
        let empty = try temporaryFile("cyl-tab-empty.json", contents: Data())
        XCTAssertEqual(CYLAnimationEngines.tabAnimationNotMadeReason(empty), "unreadable")
        let unknown = try temporaryFile("cyl-tab-unknown.xyz", contents: Data("{}".utf8))
        XCTAssertEqual(CYLAnimationEngines.tabAnimationNotMadeReason(unknown), "decode failed", "a file no engine claims")
    }

    /// [EN] Through the real tab flow: a tab button whose animation file is not there reports it once, however often the tab bar
    ///      asks again (trait and style refreshes). [CN] 经过真实的 Tab 流程：动画文件不存在的 Tab 按钮只报告一次，无论 TabBar 再询问多少次（深浅色与风格刷新）。
    func testTheTabFlowReportsAMissingFileOncePerTabButton() throws {
        let service = try XCTUnwrap(cylTabBarItemAnimationGetServiceEntryPoint(), "needs the animation engine in the build")
        let button = UIControl()
        let missing = URL(fileURLWithPath: NSTemporaryDirectory() + "cyl-tab-flow-missing.json")
        for _ in 0..<3 {
            service.addAnimation(with: missing, size: CGSize(width: 24, height: 24), contentMode: .scaleAspectFit, animationSpeed: 0, to: button)
        }
        spin()
        XCTAssertEqual(heard, ["cyl-tab-flow-missing.json|not found"])
        service.addAnimation(with: nil, size: CGSize(width: 24, height: 24), contentMode: .scaleAspectFit, animationSpeed: 0, to: button)
        service.addAnimation(with: cylTestRemoteURL(host: "example.com", path: "remote.json"), size: CGSize(width: 24, height: 24), contentMode: .scaleAspectFit, animationSpeed: 0, to: button)
        spin()
        XCTAssertEqual(heard.count, 1, "no URL and a remote URL report nothing on the tab path")
    }
}

/**
 [EN] The title color of a plus button built from a configuration (`UIButton.Configuration`) once its title follows the tab item
      titles (`+alignsTitleWithTabBarItemTitles`): the configuration's update handler used to put the default gray back after every
      configuration change, so in dark mode the title stayed gray while the other tab titles were white (docs/PlusButton.md). The
      default itself (`.gray` for a title the tab titles do not drive) is the owner's decision and stays.
 [CN] 由配置（`UIButton.Configuration`）创建的 PlusButton，在标题跟随 Tab 标题（`+alignsTitleWithTabBarItemTitles`）之后的标题颜色：
      配置的更新回调过去会在每次配置变化后把默认的灰色放回去，因此深色模式下其他 Tab 标题是白色，这个标题仍是灰色（docs/PlusButton.md）。
      默认值本身（Tab 标题不控制的标题使用 `.gray`）是维护者的决定，保持不变。
 */
@MainActor
final class CYLPlusButtonTitleColorTests: XCTestCase {

    private func makePlusButton() -> CYLPlusButton {
        let button = CYLPlusButton(frame: CGRect(x: 0, y: 0, width: 60, height: 60))
        button.cylConfigurationPlusButtonSetUp(attributes: ["CYLTabBarItemTitle": "Search"])
        return button
    }

    /// [EN] The color the title is drawn in after UIKit ran the configuration update (in a window, as the system does at layout).
    /// [CN] UIKit 执行配置更新（在窗口中，与系统在布局时的做法相同）之后标题绘制所用的颜色。
    private func shownTitleColor(_ button: CYLPlusButton) throws -> UIColor {
        let window = button.window ?? UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        if button.window == nil {
            window.addSubview(button)
            window.isHidden = false
        }
        button.setNeedsUpdateConfiguration()
        window.layoutIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        let transformer = try XCTUnwrap(button.configuration?.titleTextAttributesTransformer)
        return try XCTUnwrap(transformer(AttributeContainer()).foregroundColor)
    }

    func testTheDefaultTitleColorIsStillGrayWhenTheTabTitlesDoNotDriveIt() throws {
        let button = makePlusButton()
        XCTAssertNotNil(button.configuration, "a titled plus button of a configuration uses UIButton.Configuration")
        XCTAssertTrue(try shownTitleColor(button).isEqual(UIColor.gray))
    }

    func testTheColorsOfTheTabTitlesSurviveTheNextConfigurationUpdate() throws {
        let button = makePlusButton()
        // [EN] What `cylApplyTitleFont` stores for dark mode: white unselected (Liquid Glass label color), the selected color. [CN] `cylApplyTitleFont` 为深色模式保存的值：未选中为白色（液态玻璃的 label 颜色），以及选中颜色。
        button.cylPlusButtonStorage.titleStyle = ["font": UIFont.systemFont(ofSize: 10), "normal": UIColor.white, "selected": UIColor.systemOrange]
        XCTAssertTrue(try shownTitleColor(button).isEqual(UIColor.white), "the aligned unselected color, not the default gray")
        button.isSelected = true
        XCTAssertTrue(try shownTitleColor(button).isEqual(UIColor.systemOrange), "the aligned selected color")
    }
}

/**
 [EN] The core's default for `+alignsTitleWithTabBarItemTitles` (not implemented by the app's plus button): YES for a plus button with a
      title that is not part of its background image, NO without a title.
 [CN] `+alignsTitleWithTabBarItemTitles` 的核心默认值（App 的 PlusButton 未实现时）：有标题且标题不是背景图的一部分时为 YES，没有标题时为 NO。
 */
final class CYLPlusButtonDefaultAlignsTitleTests: XCTestCase {

    func testAPlusButtonWithATitleAlignsItByDefault() {
        let button = CYLTestPlusButton()
        button.setTitle("Plus", for: .normal)
        XCTAssertTrue(button.cylAlignsTitleWithTabBarItemTitles(), "no app code: the title lines up with the tab titles")
    }

    func testAPlusButtonWithoutATitleDoesNotAlign() {
        XCTAssertFalse(CYLTestPlusButton().cylAlignsTitleWithTabBarItemTitles())
    }

    func testATitleOnItsBackgroundImageIsLeftAlone() {
        let button = CYLTestPlusButton()
        button.setTitle("Plus", for: .normal)
        UIGraphicsBeginImageContext(CGSize(width: 10, height: 10))
        let picture = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        button.setBackgroundImage(picture, for: .normal)
        XCTAssertFalse(button.cylAlignsTitleWithTabBarItemTitles(), "the title is part of the picture")
    }
}
