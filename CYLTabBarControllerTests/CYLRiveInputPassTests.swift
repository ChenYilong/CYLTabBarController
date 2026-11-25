//
//  CYLRiveInputPassTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import XCTest
@testable import CYLAnimatedItem

/**
 [EN] The end rule of a Rive state machine input pass (`CYLRiveInputPass`), the pure function behind the end callback of
      `CYLRiveLegacyTabBarItemAnimationView`; no RiveRuntime needed (docs/Animated-Item.md).
 [CN] Rive 状态机输入一遍播放的结束规则（`CYLRiveInputPass`），即 `CYLRiveLegacyTabBarItemAnimationView` 结束回调背后的纯函数；
      无需 RiveRuntime（docs/Animated-Item.md）。
 */
final class CYLRiveInputPassTests: XCTestCase {

    func testAPassWithADurationEndsAndTellsTheHandlerWhenNotLooping() {
        XCTAssertEqual(CYLRiveInputPass.ending(activeDuration: 1, isCancelled: false, loops: false), .ended(notifiesEnd: true))
    }

    func testALoopingPassEndsWithoutTellingTheHandler() {
        XCTAssertEqual(CYLRiveInputPass.ending(activeDuration: 1, isCancelled: false, loops: true), .ended(notifiesEnd: false))
    }

    func testAnInputHeldYesHasNoEnd() {
        XCTAssertFalse(CYLRiveInputPass.hasEnd(activeDuration: 0))
        XCTAssertEqual(CYLRiveInputPass.ending(activeDuration: 0, isCancelled: false, loops: false), .noEnd)
    }

    func testACancelledPassIsNotEndedByTheTimer() {
        XCTAssertEqual(CYLRiveInputPass.ending(activeDuration: 1, isCancelled: true, loops: false), .noEnd)
        XCTAssertEqual(CYLRiveInputPass.ending(activeDuration: 1, isCancelled: true, loops: true), .noEnd)
    }

    func testTheDurationFloorAndTheMaximum() {
        XCTAssertTrue(CYLRiveInputPass.hasEnd(activeDuration: 0.001))
        XCTAssertTrue(CYLRiveInputPass.hasEnd(activeDuration: 60))
        XCTAssertFalse(CYLRiveInputPass.hasEnd(activeDuration: -1))
    }

    func testTheOffWindowLastsAtLeastAFrameEvenWhenSettled() {
        XCTAssertFalse(CYLRiveInputPass.offWindowEnds(elapsed: 0.016, isSettled: true))
        XCTAssertTrue(CYLRiveInputPass.offWindowEnds(elapsed: 0.05, isSettled: true))
    }

    func testTheOffWindowWaitsForTheNoPassToSettle() {
        XCTAssertFalse(CYLRiveInputPass.offWindowEnds(elapsed: 0.5, isSettled: false))
        XCTAssertTrue(CYLRiveInputPass.offWindowEnds(elapsed: 0.5, isSettled: true))
    }

    func testTheOffWindowEndsAtTheMaximumForAMachineThatNeverSettles() {
        XCTAssertFalse(CYLRiveInputPass.offWindowEnds(elapsed: 1.4, isSettled: false))
        XCTAssertTrue(CYLRiveInputPass.offWindowEnds(elapsed: 1.5, isSettled: false))
    }

    /// [EN] The case table shared with Android (`CYLRiveInputPassTest`) and HarmonyOS (`CYLAnimatedItemRiveOptions.test.mjs`):
    ///      `activeDuration` in seconds -> the cap of the NO window in seconds.
    /// [CN] 与 Android（`CYLRiveInputPassTest`）、HarmonyOS（`CYLAnimatedItemRiveOptions.test.mjs`）共用的用例表：
    ///      `activeDuration`（秒）-> NO 窗口的上限（秒）。
    private let offWindowCapCases: [(activeDuration: TimeInterval, cap: TimeInterval)] = [
        (0, 1.5), (-1, 1.5), (0.001, 0.05), (0.05, 0.05), (0.3, 0.3), (1, 1), (1.5, 1.5), (2, 1.5), (60, 1.5),
    ]

    func testTheOffWindowCapFollowsTheActiveDurationBetweenAFrameAndTheMaximum() {
        for testCase in offWindowCapCases {
            XCTAssertEqual(CYLRiveInputPass.offWindowCap(activeDuration: testCase.activeDuration), testCase.cap, accuracy: 1e-9,
                           "activeDuration \(testCase.activeDuration)")
        }
    }

    /// [EN] Proof of the bug: with the old rule (no `activeDuration`) a machine that never settles keeps a 0.3 s input off for the
    ///      full 1.5 s; the same call with the input's duration ends the window at 0.3 s.
    /// [CN] 缺陷的证明：旧规则（不带 `activeDuration`）下，永不稳定的状态机让 0.3 秒的输入白等整整 1.5 秒；带上输入时长则在 0.3 秒结束。
    func testAMachineThatNeverSettlesDoesNotWaitTheFullCapForAShortInput() {
        XCTAssertFalse(CYLRiveInputPass.offWindowEnds(elapsed: 0.3, isSettled: false), "without the duration the window runs to 1.5 s")
        XCTAssertFalse(CYLRiveInputPass.offWindowEnds(elapsed: 1.4, isSettled: false))
        XCTAssertFalse(CYLRiveInputPass.offWindowEnds(elapsed: 0.29, isSettled: false, activeDuration: 0.3))
        XCTAssertTrue(CYLRiveInputPass.offWindowEnds(elapsed: 0.3, isSettled: false, activeDuration: 0.3))
    }

    func testAnInputHeldYesKeepsTheFullCap() {
        XCTAssertFalse(CYLRiveInputPass.offWindowEnds(elapsed: 1.4, isSettled: false, activeDuration: 0))
        XCTAssertTrue(CYLRiveInputPass.offWindowEnds(elapsed: 1.5, isSettled: false, activeDuration: 0))
    }

    func testALongDurationNeverRaisesTheCapAboveTheMaximum() {
        XCTAssertTrue(CYLRiveInputPass.offWindowEnds(elapsed: 1.5, isSettled: false, activeDuration: 60))
        XCTAssertFalse(CYLRiveInputPass.offWindowEnds(elapsed: 1.4, isSettled: false, activeDuration: 60))
    }

    func testASettledMachineStillEndsAtTheFrameFloorWhateverTheDuration() {
        XCTAssertTrue(CYLRiveInputPass.offWindowEnds(elapsed: 0.05, isSettled: true, activeDuration: 1))
        XCTAssertFalse(CYLRiveInputPass.offWindowEnds(elapsed: 0.03, isSettled: true, activeDuration: 0.001))
    }
}
