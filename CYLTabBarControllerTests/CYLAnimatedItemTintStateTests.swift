//
//  CYLAnimatedItemTintStateTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import XCTest
import CYLAnimatedItem

/**
 * [EN] An animation view that records the tint calls it gets. [CN] 记录所收到着色调用的动画视图。
 */
private final class CYLRecordingTintView: UIView {
    var stateCalls: [(UIColor?, Bool)] = []
    var plainCalls = 0

    @objc(cyl_applyAnimationViewTintColor:)
    func applyTint(_ color: UIColor?) {
        plainCalls += 1
    }

    @objc(cyl_applyAnimationViewTintColor:selected:)
    func applyTint(_ color: UIColor?, selected: Bool) {
        stateCalls.append((color, selected))
    }
}

/**
 * [EN] An item whose animation view is the recording view. [CN] 动画视图为记录视图的 item。
 */
private final class CYLRecordingItemView: CYLAnimatedItemView {
    let recordingView = CYLRecordingTintView()

    override var animationView: UIView? { recordingView }
}

/**
 * [EN] The tint hook with the item's state (2026-11-19: a fixed tint only on the unselected tab).
 * [CN] 带 item 状态的着色钩子（2026-11-19：固定着色只用于未选中的 Tab）。
 */
final class CYLAnimatedItemTintStateTests: XCTestCase {

    /// [EN] The state-aware hook wins over the plain one and gets the item's selected state.
    /// [CN] 带状态的钩子优先于普通钩子，并收到 item 的选中状态。
    func testIconTintPassesTheSelectedState() {
        let item = CYLRecordingItemView(frame: CGRect(x: 0, y: 0, width: 80, height: 49))
        item.isSelected = false
        item.applyIconTintColor(.red)
        item.isSelected = true
        item.applyIconTintColor(.blue)
        let calls = item.recordingView.stateCalls
        XCTAssertEqual(item.recordingView.plainCalls, 0, "the state-aware hook is preferred")
        XCTAssertTrue(calls.contains { $0.0 == .red && !$0.1 }, "unselected red reached the view")
        XCTAssertTrue(calls.contains { $0.0 == .blue && $0.1 }, "selected blue reached the view")
    }
}
