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
private final class CYLScriptedPanRecognizer: UIPanGestureRecognizer {
    var scripted: UIGestureRecognizer.State = .possible
    override var state: UIGestureRecognizer.State {
        get { scripted }
        set {}
    }
}

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

    /// [EN] An item made on its own (no tab bar controller) is found by the bridge by name, and plays and pauses without
    ///      anyone calling `install()` first. (The bridge is process-wide, so earlier tests may have installed it already: the
    ///      lookup by name is what this pins down.)
    /// [CN] 单独创建的控件（没有 TabBarController）能被桥接按名称找到，并且不必先调用 `install()` 就能播放与暂停。
    ///      （桥接是进程级的，之前的测试可能已安装：这里固定的是按名称查找。）
    func testAnItemOutsideATabBarControllerFindsTheBridgeByName() throws {
        let installer = try XCTUnwrap(NSClassFromString("CYLAnimationEventBridgeInstaller") as? NSObject.Type)
        XCTAssertTrue(installer.responds(to: NSSelectorFromString("install")))
        let item = CYLAnimatedItemView(frame: .zero)
        let seen = record(item)
        item.playAnimatedImage(makeAnimatedImage())
        XCTAssertEqual(seen(), ["cyl.animation.didStart"])
        CYLAnimationEventBridge.setAnimationsPaused(true)
        XCTAssertFalse(item.imageView.isAnimating)
        CYLAnimationEventBridge.setAnimationsPaused(false)
        item.stopAnimatedImage()
    }

    /// [EN] The scroll path: a view controller on screen reports its scroll view to the library once a global observer waits;
    ///      a drag that begins pauses every playing item, the end of scrolling resumes them. The drag is driven through the pan
    ///      gesture recognizer's target, as the library listens to it (the test target does not link the library).
    /// [CN] 滚动路径：全局观察者存在后，屏幕上的视图控制器把它的滚动视图报告给库；开始拖动时暂停所有播放中的控件，滚动结束时恢复。
    ///      拖动通过 pan 手势识别器的 target 驱动，与库监听它的方式一致（测试目标未链接该库）。
    func testScrollingPausesPlayingItemsAndResumesThem() throws {
        let item = CYLAnimatedItemView(frame: .zero)
        item.animationLoops = true // [EN] a finite pass would end during the run loop waits below. [CN] 有限次播放会在下面等待 run loop 时结束。
        item.playAnimatedImage(makeAnimatedImage())
        CYLAnimationEventBridge.pausesAnimationsWhileUserScrolls(true)
        addTeardownBlock { CYLAnimationEventBridge.pausesAnimationsWhileUserScrolls(false); item.stopAnimatedImage() }

        let scrollView = UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        scrollView.contentSize = CGSize(width: 320, height: 2000)
        let controller = UIViewController()
        controller.view.addSubview(scrollView)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
        window.rootViewController = controller
        window.makeKeyAndVisible()
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))

        let pauses = CYLAnimationEventBridge.pauseCount
        let resumes = CYLAnimationEventBridge.resumeCount
        let targets = try XCTUnwrap(scrollView.panGestureRecognizer.value(forKey: "targets") as? [NSObject])
        // [EN] The library's observer reads only `recognizer.state`; a real recognizer's state cannot be set from outside UIKit,
        //      so the observer gets a recognizer that reports the state we want.
        // [CN] 库的观察者只读取 `recognizer.state`；真实识别器的状态无法在 UIKit 之外设置，所以交给观察者一个报告我们想要的状态的识别器。
        let fake = CYLScriptedPanRecognizer()
        func drive(_ state: UIGestureRecognizer.State) {
            fake.scripted = state
            for case let target as NSObject in targets.compactMap({ $0.value(forKey: "target") as AnyObject? }) where target.responds(to: NSSelectorFromString("pan:")) {
                target.perform(NSSelectorFromString("pan:"), with: fake)
            }
        }
        drive(.began)
        XCTAssertEqual(CYLAnimationEventBridge.pauseCount, pauses + 1, "a drag that begins pauses the playing items")
        XCTAssertFalse(item.imageView.isAnimating)
        drive(.ended)
        RunLoop.main.run(until: Date().addingTimeInterval(0.3))
        XCTAssertEqual(CYLAnimationEventBridge.resumeCount, resumes + 1, "the end of scrolling resumes them")
        XCTAssertTrue(item.imageView.isAnimating)
        window.isHidden = true
    }

    /// [EN] Cost of the library's UIView window hooks (docs/Lifecycle-Library.md, step 21): the clock time of making and showing
    ///      200 windows, each with a scroll view, before the bridge is installed (`testWindowHookCost1Baseline`), after `install()`
    ///      (`…2AfterInstall`), and after `pausesAnimationsWhileUserScrolls(true)` (`…3AfterScrollObserver`: the first global
    ///      observer, which installs the hooks). XCTest allows one measurement per method and runs methods in name order; the
    ///      hooks cannot be removed again, so run only these three for clean numbers (`-only-testing`, in a fresh process). There is no baseline and no assertion on purpose: the numbers are read from the log, so a slow CI
    ///      machine cannot make it flaky.
    /// [CN] 库的 UIView 窗口钩子的开销（docs/Lifecycle-Library.md，第 21 步）：创建并显示 200 个窗口（各含一个 scroll view）的时钟时间，
    ///      分三个阶段：安装桥接之前（基线）、`install()` 之后、`pausesAnimationsWhileUserScrolls(true)`（第一个全局观察者，
    ///      它才安装钩子）之后。钩子无法再移除，所以三个阶段必须在同一进程中按此顺序运行：单独运行此测试才能得到干净的数字
    ///      （`-only-testing`，新进程）。XCTest 每个方法只允许一次测量，并按名称顺序运行；三个方法分别是基线、`install()` 之后、第一个全局观察者之后。故意没有基线断言：数字从日志中读取，因此慢速 CI 机器不会让它不稳定。
    func testWindowHookCost1Baseline() { measureWindows() }
    func testWindowHookCost2AfterInstall() { CYLAnimationEventBridge.install(); measureWindows() }
    func testWindowHookCost3AfterScrollObserver() {
        CYLAnimationEventBridge.pausesAnimationsWhileUserScrolls(true)
        addTeardownBlock { CYLAnimationEventBridge.pausesAnimationsWhileUserScrolls(false) }
        measureWindows()
    }

    private func measureWindows() {
        let options = XCTMeasureOptions()
        options.iterationCount = 10
        func windows() {
            for _ in 0..<200 {
                let controller = UIViewController()
                controller.view.addSubview(UIScrollView(frame: CGRect(x: 0, y: 0, width: 320, height: 480)))
                let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 480))
                window.rootViewController = controller
                window.makeKeyAndVisible()
                window.isHidden = true
            }
        }
        measure(metrics: [XCTClockMetric()], options: options, block: windows)
    }
}
