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
}
