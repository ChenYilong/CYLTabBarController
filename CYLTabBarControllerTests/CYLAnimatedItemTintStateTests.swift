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

    func testAGlassWithoutAColorHasTheDefaultFrostedTint() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIGlassEffect needs iOS 26")
        }
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        item.layoutIfNeeded()
        let glass = try XCTUnwrap(item.itemLiquidGlassView as? UIVisualEffectView)
        var alpha: CGFloat = -1
        (glass.effect as? UIGlassEffect)?.tintColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            .getRed(nil, green: nil, blue: nil, alpha: &alpha)
        XCTAssertEqual(alpha, 0.5, accuracy: 0.01, "no color set: the default frosted tint, so one style parameter is visible")
    }

    func testAClearColorMeansNoColorAndGetsTheDefaultFrostedTint() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIGlassEffect needs iOS 26")
        }
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        item.itemBackgroundColor = .clear
        item.itemBorderWidth = 1
        item.itemCornerRadius = 12
        item.layoutIfNeeded()
        let glass = try XCTUnwrap(item.itemLiquidGlassView as? UIVisualEffectView)
        var alpha: CGFloat = -1
        (glass.effect as? UIGlassEffect)?.tintColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            .getRed(nil, green: nil, blue: nil, alpha: &alpha)
        XCTAssertEqual(alpha, 0.5, accuracy: 0.01, "UIColor.clear is no color: the default frosted tint, like nil")
        XCTAssertEqual(item.layer.borderWidth, 1, "the border and the corner radius stay as set")
        XCTAssertEqual(item.layer.cornerRadius, 12)
        // A color with a real alpha still tints at 75% of it.
        item.itemBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.4)
        item.layoutIfNeeded()
        (glass.effect as? UIGlassEffect)?.tintColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            .getRed(nil, green: nil, blue: nil, alpha: &alpha)
        XCTAssertEqual(alpha, 0.3, accuracy: 0.01)
    }

    func testGlassTintAlphaOneKeepsTheColorAsItIs() throws {
        guard #available(iOS 26.0, *) else {
            throw XCTSkip("UIGlassEffect needs iOS 26")
        }
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        item.itemBackgroundColor = UIColor.systemTeal
        item.layoutIfNeeded()
        let glass = try XCTUnwrap(item.itemLiquidGlassView as? UIVisualEffectView)
        func tintAlpha() -> CGFloat {
            var alpha: CGFloat = -1
            (glass.effect as? UIGlassEffect)?.tintColor?.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
                .getRed(nil, green: nil, blue: nil, alpha: &alpha)
            return alpha
        }
        XCTAssertEqual(tintAlpha(), 0.75, accuracy: 0.01, "the default share")
        item.itemGlassTintAlpha = 1
        item.layoutIfNeeded()
        XCTAssertEqual(tintAlpha(), 1, accuracy: 0.01, "1: the color as it is, still glass")
        item.itemGlassTintAlpha = nil
        item.layoutIfNeeded()
        XCTAssertEqual(tintAlpha(), 0.75, accuracy: 0.01)
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

    // MARK: - itemContentHorizontalInset 内容左右内缩

    func testUnsetContentInsetIsZeroOnFlatAndTheConstantOnActiveGlass() {
        let flat = makeItem()
        XCTAssertNil(flat.itemContentHorizontalInset)
        XCTAssertEqual(flat.resolvedItemContentHorizontalInset, 0)
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let glass = makeItem()
        glass.itemBackgroundStyle = .liquidGlass
        XCTAssertEqual(CYLAnimatedItemLiquidGlassContentInset, 14)
        XCTAssertEqual(glass.resolvedItemContentHorizontalInset, CYLAnimatedItemLiquidGlassContentInset)
        XCTAssertNil(glass.itemContentHorizontalInsetNumber, "unset stays unset for the bridges")
    }

    func testUnsetContentInsetIsZeroWhenGlassIsRequestedButNotDrawn() {
        CYLAnimatedItemView.liquidGlassActiveOverride = false
        let item = makeItem()
        item.itemBackgroundStyle = .liquidGlass
        XCTAssertEqual(item.resolvedItemBackgroundStyle, .flat)
        XCTAssertEqual(item.resolvedItemContentHorizontalInset, 0)
    }

    func testAnExplicitContentInsetWins() {
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let glass = makeItem()
        glass.itemBackgroundStyle = .liquidGlass
        glass.itemContentHorizontalInset = 0
        XCTAssertEqual(glass.resolvedItemContentHorizontalInset, 0, "0 on glass is explicit")
        XCTAssertEqual(glass.itemContentHorizontalInsetNumber, 0)
        let flat = makeItem()
        flat.itemContentHorizontalInset = 20
        XCTAssertEqual(flat.resolvedItemContentHorizontalInset, 20)
        flat.itemContentHorizontalInsetNumber = nil
        XCTAssertEqual(flat.resolvedItemContentHorizontalInset, 0)
    }

    func testWrapContentWidthGrowsByTwiceTheInsetOnGlass() {
        let flat = makeItem()
        let flatWidth = flat.intrinsicContentSize.width
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let glass = makeItem()
        glass.itemBackgroundStyle = .liquidGlass
        XCTAssertEqual(glass.intrinsicContentSize.width, flatWidth + 2 * CYLAnimatedItemLiquidGlassContentInset, accuracy: 1)
        glass.itemContentHorizontalInset = 20
        XCTAssertEqual(glass.intrinsicContentSize.width, flatWidth + 40, accuracy: 1, "the setter changes the size")
    }

    func testStackViewMarginsAddTheInsetLeftAndRightOnly() {
        func margins(_ stack: CYLAnimatedItemStackView) -> (leading: CGFloat, top: CGFloat) {
            func constant(_ attribute: NSLayoutConstraint.Attribute) -> CGFloat {
                stack.constraints.first { ($0.firstItem as? UIView) === stack.stackView && $0.firstAttribute == attribute }?.constant ?? -1
            }
            return (constant(.leading), constant(.top))
        }
        let flat = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        flat.itemBackgroundStyle = .flat
        let flatMargins = margins(flat)
        XCTAssertEqual(flatMargins.leading, flat.contentMargin)
        XCTAssertEqual(flatMargins.top, flat.contentMargin)
        CYLAnimatedItemView.liquidGlassActiveOverride = true
        let glass = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 200))
        glass.itemBackgroundStyle = .liquidGlass
        XCTAssertEqual(margins(glass).leading, flatMargins.leading + CYLAnimatedItemLiquidGlassContentInset, "the margins follow the style")
        XCTAssertEqual(margins(glass).top, flatMargins.top, "top and bottom unchanged")
        glass.itemContentHorizontalInset = 0
        XCTAssertEqual(margins(glass).leading, flatMargins.leading)
        XCTAssertEqual(glass.contentMargin, 16, "the default of contentMargin is unchanged")
    }
}
