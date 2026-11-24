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
    func applyTint(_: UIColor?) {
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

/**
 * [EN] The item background of CYLAnimatedItemView (flat or Liquid Glass, corner radius, border): the rules of `itemCornerRadius`, the capsule
 *      constant, the border, the resolved style. [CN] CYLAnimatedItemView 的条目背景（扁平或液态玻璃、圆角、边框）：`itemCornerRadius` 的规则、胶囊常量、边框、
 *      实际样式。
 */
final class CYLAnimatedItemBackgroundTests: XCTestCase {

    private func makeItem(height: CGFloat = 56) -> CYLAnimatedItemView {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 200, height: height))
        item.title = "Home"
        return item
    }

    override func tearDown() {
        CYLAnimatedItemView.liquidGlassActiveOverride = nil
        super.tearDown()
    }

    func testFlatUnsetRadiusIsSquare() {
        let item = makeItem()
        item.itemBackgroundColor = .systemBlue
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.cornerRadius, 0)
        XCTAssertNil(item.itemLiquidGlassView)
    }

    func testLiquidGlassUnsetRadiusIsACapsule() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        item.layoutIfNeeded()
        XCTAssertEqual(item.resolvedItemBackgroundStyle, .liquidGlass)
        XCTAssertEqual(item.layer.cornerRadius, 28, accuracy: 0.01)
        XCTAssertNotNil(item.itemLiquidGlassView)
    }

    func testASetRadiusIsPointsAndZeroIsSquare() {
        let item = makeItem()
        item.itemBackgroundColor = .systemBlue
        item.itemCornerRadius = 12
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.cornerRadius, 12)
        item.itemCornerRadius = 0
        XCTAssertEqual(item.layer.cornerRadius, 0)
        item.itemCornerRadius = 1000.5
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.cornerRadius, 28, accuracy: 0.01, "limited to half the height")
    }

    func testTheCapsuleConstantIsHalfTheHeightAndFollowsTheSize() {
        let item = makeItem()
        item.itemBackgroundColor = .systemBlue
        item.itemCornerRadius = CYLAnimatedItemCornerRadiusCapsule
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.cornerRadius, 28, accuracy: 0.01)
        item.frame.size.height = 40
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.cornerRadius, 20, accuracy: 0.01, "follows a resize")
    }

    func testTheBorderIsDrawn() {
        let item = makeItem()
        item.itemBorderWidth = 2
        item.itemBorderColor = .red
        item.layoutIfNeeded()
        XCTAssertEqual(item.layer.borderWidth, 2)
        XCTAssertNotNil(item.layer.borderColor)
    }

    func testTheResolvedStyleIsFlatWhereTheSystemDrawsNoGlass() {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        XCTAssertEqual(item.resolvedItemBackgroundStyle, .flat)
        XCTAssertNil(item.itemLiquidGlassView)
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        XCTAssertEqual(item.resolvedItemBackgroundStyle, .liquidGlass)
    }

    func testSettingTheSameValueAgainDoesNotRequestALayout() {
        let item = makeItem()
        item.itemCornerRadius = 8
        item.layoutIfNeeded()
        item.itemCornerRadius = 8
        XCTAssertFalse(item.layer.needsLayout(), "an unchanged value does nothing (no layout loop when set inside layoutSubviews)")
    }

    func testTheStackViewHasTheSameRules() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 200, height: 80))
        stack.itemBackgroundColor = .systemBlue
        stack.layoutIfNeeded()
        XCTAssertEqual(stack.layer.cornerRadius, 0, "flat, unset: square")
        stack.itemBackgroundStyle = .liquidGlass
        stack.layoutIfNeeded()
        XCTAssertEqual(stack.layer.cornerRadius, 40, accuracy: 0.01, "glass, unset: a capsule")
        stack.itemCornerRadius = 12
        XCTAssertEqual(stack.layer.cornerRadius, 12)
        stack.itemCornerRadius = CYLAnimatedItemCornerRadiusCapsule
        XCTAssertEqual(stack.layer.cornerRadius, 40, accuracy: 0.01)
        XCTAssertNotNil(stack.itemLiquidGlassView)
    }
}
