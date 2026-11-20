//
//  CYLAnimatedItemCountdownTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import XCTest
import CYLAnimatedItem

/**
 * [EN] A clock the tests move by hand: no timer is waited for. [CN] 由测试手动拨动的时钟：不需要等待定时器。
 */
private final class CYLCountdownTestClock {
    var date: Date

    init(_ seconds: TimeInterval) {
        date = Date(timeIntervalSince1970: seconds)
    }

    func set(_ seconds: TimeInterval) {
        date = Date(timeIntervalSince1970: seconds)
    }
}

/**
 * [EN] Records the delegate's countdown callbacks. [CN] 记录代理的倒计时回调。
 */
private final class CYLCountdownTestDelegate: NSObject, CYLAnimatedItemViewDelegate {
    var events: [String] = []

    func animatedItemViewDidStartCountdown(_ itemView: CYLAnimatedItemView) {
        events.append("start")
    }

    func animatedItemView(_ itemView: CYLAnimatedItemView, didTickCountdown remainingSeconds: Int) {
        events.append("tick \(remainingSeconds)")
    }

    func animatedItemViewDidFinishCountdown(_ itemView: CYLAnimatedItemView) {
        events.append("finish")
    }
}

/**
 * [EN] The countdown style of `CYLAnimatedItemView` (the "Get code" button of SMSCodeButton), on a clock the tests move.
 * [CN] `CYLAnimatedItemView` 的倒计时样式（SMSCodeButton 的「获取验证码」按钮），使用由测试拨动的时钟。
 */
final class CYLAnimatedItemCountdownTests: XCTestCase {
    private func icon() -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
    }

    private func makeItem(clock: CYLCountdownTestClock, delegate: CYLCountdownTestDelegate) -> CYLAnimatedItemView {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        item.countdownDateProvider = { clock.date }
        item.countdownIdleTitle = "Get code"
        item.countdownRunningTitleFormat = "%ld s left"
        item.countdownFinishedTitle = "Resend"
        item.delegate = delegate
        item.style = .countdown
        return item
    }

    /**
     * [EN] FIX: issue #1 of SMSCodeButton: the seconds spent in the background count. The control reads the end date again
     *      when the app returns, so 4 seconds in the background leave 6, not 10.
     * [CN] 修复 SMSCodeButton 的 issue #1：后台度过的秒数计入。App 返回时控件重新读取结束时间，后台 4 秒后剩 6 秒，而不是 10 秒。
     */
    func testCountdownCountsTheSecondsSpentInTheBackground() {
        let clock = CYLCountdownTestClock(1000)
        let delegate = CYLCountdownTestDelegate()
        let item = makeItem(clock: clock, delegate: delegate)
        XCTAssertEqual(item.title, "Get code")
        XCTAssertEqual(item.countdownState, .idle)

        item.startCountdown(withDuration: 10)
        XCTAssertEqual(item.countdownState, .running)
        XCTAssertEqual(item.title, "10 s left")
        XCTAssertFalse(item.isEnabled, "a tap cannot start a second countdown")
        XCTAssertEqual(item.countdownRemainingSeconds, 10)

        clock.set(1004)
        NotificationCenter.default.post(name: UIApplication.willEnterForegroundNotification, object: nil)
        XCTAssertEqual(item.title, "6 s left")
        XCTAssertEqual(item.countdownRemainingSeconds, 6)

        clock.set(1020)
        NotificationCenter.default.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        XCTAssertEqual(item.countdownState, .finished, "it ended while the app was away")
        XCTAssertEqual(item.title, "Resend")
        XCTAssertTrue(item.isEnabled)
        XCTAssertNil(item.countdownEndDate)
        XCTAssertEqual(delegate.events, ["start", "tick 10", "tick 6", "finish"])
    }

    /**
     * [EN] The title changes only when the whole seconds left change, and a late read cannot skip the end.
     * [CN] 只有剩余整秒数变化时标题才变化，读取延迟也不会错过结束。
     */
    func testCountdownTicksOncePerSecondAndFinishesExactly() {
        let clock = CYLCountdownTestClock(500)
        let delegate = CYLCountdownTestDelegate()
        let item = makeItem(clock: clock, delegate: delegate)
        item.startCountdown(withDuration: 3)
        clock.set(500.4)
        item.refreshCountdown()
        clock.set(500.9)
        item.refreshCountdown()
        XCTAssertEqual(item.title, "3 s left", "still within the first second")
        clock.set(501.1)
        item.refreshCountdown()
        XCTAssertEqual(item.title, "2 s left")
        clock.set(503)
        item.refreshCountdown()
        XCTAssertEqual(item.countdownState, .finished)
        XCTAssertEqual(delegate.events, ["start", "tick 3", "tick 2", "finish"])
        item.refreshCountdown()
        XCTAssertEqual(delegate.events.count, 4, "a finished countdown reports nothing more")
    }

    func testCountdownResetAndRestartAndTheTapThatStartsIt() {
        let clock = CYLCountdownTestClock(0)
        let delegate = CYLCountdownTestDelegate()
        let item = makeItem(clock: clock, delegate: delegate)
        item.countdownDuration = 30
        item.startsCountdownOnTap = true
        item.sendActions(for: .touchUpInside)
        XCTAssertEqual(item.countdownState, .running)
        XCTAssertEqual(item.title, "30 s left")

        item.resetCountdown()
        XCTAssertEqual(item.countdownState, .idle)
        XCTAssertEqual(item.title, "Get code")
        XCTAssertTrue(item.isEnabled)
        XCTAssertFalse(delegate.events.contains("finish"), "a reset is not a finish")

        // [EN] The server asks for 120 seconds, more than the default. [CN] 服务器要求 120 秒，比默认值长。
        item.startCountdown(withDuration: 120)
        XCTAssertEqual(item.title, "120 s left")
        clock.set(1)
        item.refreshCountdown()
        XCTAssertEqual(item.title, "119 s left")
    }

    /**
     * [EN] No flicker and no jump: the same label changes its text, the icon is the countdown icon only while running, and
     *      the width is that of the widest title.
     * [CN] 不闪烁、不抖动：同一个 label 改变文字，只有倒计时期间显示倒计时图标，宽度为最宽标题的宽度。
     */
    func testCountdownKeepsOneLabelTheWidthAndShowsTheCountdownIconWhileRunning() {
        let clock = CYLCountdownTestClock(0)
        let item = makeItem(clock: clock, delegate: CYLCountdownTestDelegate())
        let idle = icon()
        let clockIcon = icon()
        item.image = idle
        item.countdownImage = clockIcon
        item.countdownDuration = 60
        let label = item.titleLabel
        let big = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        let idleSize = item.sizeThatFits(big)
        XCTAssertTrue(item.imageView.image === idle)

        item.startCountdown()
        XCTAssertTrue(item.titleLabel === label, "the label is reused")
        XCTAssertTrue(item.imageView.image === clockIcon)
        XCTAssertEqual(item.sizeThatFits(big).width, idleSize.width, accuracy: 0.5)
        clock.set(51)
        item.refreshCountdown()
        XCTAssertEqual(item.title, "9 s left")
        XCTAssertEqual(item.sizeThatFits(big).width, idleSize.width, accuracy: 0.5, "two digits or one, the width stays")
        XCTAssertTrue(item.accessibilityTraits.contains(.notEnabled), "VoiceOver hears that it cannot be used now")
        XCTAssertEqual(item.accessibilityLabel, "9 s left")

        clock.set(60)
        item.refreshCountdown()
        XCTAssertTrue(item.imageView.image === idle)
        XCTAssertFalse(item.accessibilityTraits.contains(.notEnabled))
    }

    func testPlainStyleHasNoCountdownLook() {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 200, height: 44))
        item.title = "Home"
        XCTAssertEqual(item.style, .plain)
        XCTAssertEqual(item.layer.borderWidth, 0)
        item.refreshCountdown()
        XCTAssertEqual(item.title, "Home", "not touched without the style")
        item.style = .countdown
        XCTAssertGreaterThan(item.layer.borderWidth, 0)
        item.style = .plain
        XCTAssertEqual(item.layer.borderWidth, 0)
    }
}
