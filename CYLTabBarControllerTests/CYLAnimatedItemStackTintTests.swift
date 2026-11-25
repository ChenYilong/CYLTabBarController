//
//  CYLAnimatedItemStackTintTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import XCTest
import CYLAnimatedItem

/**
 * [EN] An animation view that records the tint it gets. [CN] 记录所收到着色的动画视图。
 */
private final class StackRecordingView: UIView {
    var calls: [UIColor?] = []

    @objc(cyl_applyAnimationViewTintColor:selected:)
    func applyTint(_ color: UIColor?, selected _: Bool) {
        calls.append(color)
    }
}

private final class StackRecordingFactory: NSObject, CYLTabBarItemAnimationViewMaking {
    let view = StackRecordingView()

    func animationView(url _: URL, size _: CGSize, contentMode _: UIView.ContentMode) -> UIView? { view }
    func player(for _: UIView?) -> CYLTabBarItemAnimationPlayer? { nil }
    func isAnimationView(_ view: UIView?) -> Bool { view === self.view }
}

/// A tag-like subclass that sets its own icon color by `applyIconTintColor`, as ClassifyMenu's CYLTagButton does.
private final class OrangeTagItem: CYLAnimatedItemView {
    override func itemStateDidChange() {
        super.itemStateDidChange()
        applyIconTintColor(.orange)
    }
}

/**
 * [EN] The divider item and the stack-level tint, divider color and layout (the stack-tint spec, iOS).
 * [CN] 分隔条条目，以及堆叠视图级的着色、分隔线颜色与布局（stack-tint 规格，iOS）。
 */
final class CYLAnimatedItemStackTintTests: XCTestCase {

    private var windows: [UIWindow] = []
    private var file: URL!
    private let fixed = UIColor(red: 0, green: 1, blue: 0, alpha: 1)
    private let darkFixed = UIColor(red: 0, green: 0, blue: 1, alpha: 1)
    private let iconColor = UIColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1)

    override func setUpWithError() throws {
        file = FileManager.default.temporaryDirectory.appendingPathComponent("cyl-stack-tint-\(UUID().uuidString).json")
        try "{}".write(to: file, atomically: true, encoding: .utf8)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: file)
        windows.forEach { $0.isHidden = true }
        windows = []
        super.tearDown()
    }

    private func window(dark: Bool = false) -> UIWindow {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 320, height: 200))
        window.overrideUserInterfaceStyle = dark ? .dark : .light
        window.isHidden = false
        windows.append(window)
        return window
    }

    private func components(_ color: UIColor?) -> [CGFloat]? {
        guard let color else { return nil }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light)).getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b, a]
    }

    private func assertColor(_ actual: UIColor?, _ expected: UIColor?, _ message: String, line: UInt = #line) {
        guard let a = components(actual), let e = components(expected) else {
            XCTAssertEqual(actual == nil, expected == nil, message, line: line)
            return
        }
        for (x, y) in zip(a, e) { XCTAssertEqual(x, y, accuracy: 0.01, message, line: line) }
    }

    private func appearance(normal: UIColor? = nil, selected: UIColor? = nil) -> UITabBarItemAppearance {
        let appearance = UITabBarItemAppearance()
        appearance.normal.iconColor = normal
        appearance.selected.iconColor = selected
        return appearance
    }

    // MARK: - Dividers 分隔条

    private func row(_ titles: [String], dark: Bool = false, shows: Bool = true)
        -> (stack: CYLAnimatedItemStackView, items: [CYLAnimatedItemView]) {
        let stack = CYLAnimatedItemStackView(frame: .zero)
        stack.axis = .horizontal
        stack.contentMargin = 0
        stack.spacing = 6
        window(dark: dark).addSubview(stack)
        let items = titles.map { tag($0) }
        items.forEach { stack.append($0, action: nil, spacingBefore: 6) }
        stack.showsDividers = shows
        stack.frame = CGRect(origin: .zero, size: stack.intrinsicContentSize)
        stack.layoutIfNeeded()
        return (stack, items)
    }

    private func line(of divider: UIView) -> UIView? {
        guard let item = divider as? CYLAnimatedItemView else { return nil }
        return item.subviews.first { $0 !== item.imageView && $0 !== item.titleLabel && !$0.isHidden }
    }

    func testShowsDividersPutsOneBetweenEveryTwoVisibleItems() {
        let (stack, items) = row(["A", "B", "C"])
        XCTAssertEqual(stack.dividerViews.count, 2)
        XCTAssertEqual(stack.itemViews.count, 3, "dividers are not items")
        XCTAssertTrue(stack.itemViews == items)
        let order = stack.stackView.arrangedSubviews
        XCTAssertTrue(order[0] === items[0] && order[1] === stack.dividerViews[0] && order[2] === items[1]
                      && order[3] === stack.dividerViews[1] && order[4] === items[2], "item, divider, item, divider, item")
        stack.showsDividers = false
        XCTAssertEqual(stack.dividerViews.count, 0)
        XCTAssertEqual(stack.stackView.arrangedSubviews.count, 3)
    }

    func testDividerGeometryAndSpacing() {
        let (stack, items) = row(["A", "B"])
        let divider = stack.dividerViews[0]
        let scale = stack.traitCollection.displayScale > 0 ? stack.traitCollection.displayScale : 2
        XCTAssertEqual(CYLAnimatedItemDividerLength, 20)
        XCTAssertEqual(stack.dividerLength, 20)
        XCTAssertEqual(divider.frame.size, CGSize(width: 1, height: 20), "1 x dividerLength in a horizontal row")
        XCTAssertEqual(line(of: divider)?.frame.width ?? 0, 1 / scale, accuracy: 0.001, "one pixel")
        XCTAssertEqual(line(of: divider)?.frame.height ?? 0, 20, accuracy: 0.01)
        XCTAssertEqual(divider.frame.minX - items[0].frame.maxX, 6, accuracy: 0.5, "stack spacing before")
        XCTAssertEqual(items[1].frame.minX - divider.frame.maxX, 6, accuracy: 0.5, "and after")
        XCTAssertEqual(divider.frame.midY, stack.bounds.midY, accuracy: 0.5, "centered")
        XCTAssertFalse(divider.isUserInteractionEnabled)
        XCTAssertTrue(divider.accessibilityElementsHidden)
        XCTAssertFalse(divider.isAccessibilityElement)
        let widthA = items[0].frame.width, widthB = items[1].frame.width
        XCTAssertEqual(stack.intrinsicContentSize.width, widthA + widthB + 6 + 1 + 6, accuracy: 1)
        stack.dividerLength = 8
        stack.layoutIfNeeded()
        XCTAssertEqual(stack.dividerViews[0].frame.height, 8, accuracy: 0.5)
        stack.axis = .vertical
        stack.frame = CGRect(origin: .zero, size: stack.intrinsicContentSize)
        stack.layoutIfNeeded()
        XCTAssertEqual(stack.dividerViews[0].frame.size.width, 8, accuracy: 0.5, "swapped in a vertical stack")
        XCTAssertEqual(stack.dividerViews[0].frame.size.height, 1, accuracy: 0.5)
    }

    func testAppendDividerOnAnEmptyStackDoesNothingAndAttachesAfterTheLastItem() {
        let stack = CYLAnimatedItemStackView(frame: .zero)
        stack.axis = .horizontal
        stack.appendDivider(spacingBefore: 8, spacingAfter: 8)
        XCTAssertEqual(stack.dividerViews.count, 0)
        XCTAssertEqual(stack.stackView.arrangedSubviews.count, 0)
        let camera = tag("Camera"), search = tag("Search")
        stack.append(camera, action: nil, spacingBefore: 0)
        stack.appendDivider(spacingBefore: 8, spacingAfter: 8)
        XCTAssertTrue(stack.hasDivider(after: camera))
        XCTAssertEqual(stack.dividerViews.count, 0, "no later visible item yet")
        stack.append(search, action: nil, spacingBefore: 0)
        XCTAssertEqual(stack.dividerViews.count, 1)
        XCTAssertTrue(stack.stackView.arrangedSubviews[1] === stack.dividerViews[0])
    }

    func testGapMathWorkedExampleAndFallbacks() {
        struct Case {
            let name: String
            var spacing: CGFloat = 12
            var nextBefore: CGFloat = 5
            var ownBefore: CGFloat?, ownAfter: CGFloat?
            var stackBefore: CGFloat?, stackAfter: CGFloat?
            var before: CGFloat, after: CGFloat
        }
        let cases = [
            Case(name: "worked example: 12 spacing, divider(8,8) = 17", nextBefore: 12, ownBefore: 8, ownAfter: 8, before: 8, after: 8),
            Case(name: "all nil: spacing before, next spacingBefore after", before: 12, after: 5),
            Case(name: "stack defaults", stackBefore: 3, stackAfter: 4, before: 3, after: 4),
            Case(name: "own beats the stack defaults", ownBefore: 7, ownAfter: 9, stackBefore: 3, stackAfter: 4, before: 7, after: 9),
            Case(name: "own before only", ownBefore: 2, before: 2, after: 5),
            Case(name: "stack after only", stackAfter: 0, before: 12, after: 0),
        ]
        for c in cases {
            let stack = CYLAnimatedItemStackView(frame: .zero)
            stack.axis = .horizontal
            stack.contentMargin = 0
            stack.spacing = c.spacing
            stack.dividerSpacingBefore = c.stackBefore
            stack.dividerSpacingAfter = c.stackAfter
            window().addSubview(stack)
            let a = tag("A"), b = tag("B")
            stack.append(a, action: nil, spacingBefore: 0)
            stack.appendDivider(spacingBefore: c.ownBefore, spacingAfter: c.ownAfter)
            stack.append(b, action: nil, spacingBefore: c.nextBefore)
            let width = a.sizeThatFits(CGSize(width: 1000, height: 100)).width + b.sizeThatFits(CGSize(width: 1000, height: 100)).width
            let expected = c.before + 1 + c.after
            XCTAssertEqual(stack.intrinsicContentSize.width, width + expected, accuracy: 1, c.name)
            stack.frame = CGRect(origin: .zero, size: stack.intrinsicContentSize)
            stack.layoutIfNeeded()
            let divider = stack.dividerViews[0]
            XCTAssertEqual(divider.frame.minX - a.frame.maxX, c.before, accuracy: 0.5, "\(c.name): before")
            XCTAssertEqual(b.frame.minX - divider.frame.maxX, c.after, accuracy: 0.5, "\(c.name): after")
            XCTAssertEqual(b.frame.minX - a.frame.maxX, expected, accuracy: 0.5, "\(c.name): the whole gap")
        }
    }

    func testRemoveDividerTurnsOneGapOffEvenWithShowsDividers() {
        let (stack, items) = row(["A", "B", "C"], shows: true)
        XCTAssertEqual(stack.dividerViews.count, 2)
        stack.removeDivider(after: items[0])
        XCTAssertFalse(stack.hasDivider(after: items[0]))
        XCTAssertTrue(stack.hasDivider(after: items[1]))
        XCTAssertEqual(stack.dividerViews.count, 1)
        XCTAssertTrue(stack.stackView.arrangedSubviews[2] === stack.dividerViews[0], "only after B")
        stack.showsDividers = false
        XCTAssertEqual(stack.dividerViews.count, 0)
        stack.setDivider(after: items[0])
        XCTAssertEqual(stack.dividerViews.count, 1, "an explicit divider needs no showsDividers")
        stack.setDivider(after: items[2])
        XCTAssertEqual(stack.dividerViews.count, 1, "never after the last visible item")
    }

    func testDividerMovesWithItsOwnerAndGoesWithIt() {
        let (stack, items) = row(["A", "B", "C"], shows: false)
        stack.setDivider(after: items[0], spacingBefore: 9, spacingAfter: 9)
        stack.move(items[0], to: 2)
        XCTAssertTrue(stack.itemViews == [items[1], items[2], items[0]])
        XCTAssertEqual(stack.dividerViews.count, 0, "its owner is last now: no later visible item")
        stack.move(items[0], to: 1)
        let order = stack.stackView.arrangedSubviews
        XCTAssertTrue(order[1] === items[0] && order[2] === stack.dividerViews[0] && order[3] === items[2], "after its owner")
        stack.remove(items[0])
        XCTAssertEqual(stack.dividerViews.count, 0, "removed with the owner")
        XCTAssertEqual(stack.stackView.arrangedSubviews.count, 2)
    }

    func testHiddenOwnerOrHiddenNextItem() {
        let (stack, items) = row(["A", "B", "C"], shows: false)
        stack.setDivider(after: items[0], spacingBefore: 8, spacingAfter: 8)
        XCTAssertEqual(stack.dividerViews.count, 1)
        items[0].isHidden = true
        XCTAssertEqual(stack.dividerViews.count, 0, "hidden owner: no divider")
        items[0].isHidden = false
        items[1].isHidden = true
        XCTAssertEqual(stack.dividerViews.count, 1, "the next VISIBLE item (C) counts")
        items[2].isHidden = true
        XCTAssertEqual(stack.dividerViews.count, 0, "no later visible item")
    }

    func testDividersShowOnlyBetweenVisibleItemsAndHiddenLeaveNoSpacing() {
        let (stack, items) = row(["A", "B", "C"])
        let full = stack.intrinsicContentSize.width
        items[1].isHidden = true
        XCTAssertEqual(stack.dividerViews.count, 1, "one gap between A and C")
        stack.frame = CGRect(origin: .zero, size: stack.intrinsicContentSize)
        stack.layoutIfNeeded()
        XCTAssertEqual(items[2].frame.minX - items[0].frame.maxX, 6 + 1 + 6, accuracy: 1, "A, spacing, divider, spacing, C")
        items[2].isHidden = true
        XCTAssertEqual(stack.dividerViews.count, 0, "none after the last visible item")
        items[0].isHidden = true
        items[1].isHidden = false
        items[2].isHidden = false
        XCTAssertEqual(stack.dividerViews.count, 1, "none before the first visible item")
        items[0].isHidden = false
        items[1].isHidden = false
        XCTAssertEqual(stack.dividerViews.count, 2)
        XCTAssertEqual(stack.intrinsicContentSize.width, full, accuracy: 1)
    }

    func testDividersFollowAppendRemoveAndReorder() {
        let (stack, items) = row(["A", "B"])
        let c = tag("C")
        stack.append(c, action: nil, spacingBefore: 6)
        XCTAssertEqual(stack.dividerViews.count, 2, "appended")
        stack.move(c, to: 0)
        XCTAssertTrue(stack.itemViews == [c, items[0], items[1]])
        let order = stack.stackView.arrangedSubviews
        XCTAssertTrue(order[0] === c && order[1] === stack.dividerViews[0] && order[2] === items[0]
                      && order[3] === stack.dividerViews[1] && order[4] === items[1], "dividers stay between items after a move")
        stack.remove(items[0])
        XCTAssertEqual(stack.dividerViews.count, 1, "removed")
        XCTAssertEqual(stack.stackView.arrangedSubviews.count, 3)
        stack.remove(c)
        XCTAssertEqual(stack.dividerViews.count, 0, "a single item has no divider")
        XCTAssertEqual(stack.stackView.arrangedSubviews.count, 1)
        stack.replaceItemViews([items[1], items[0], c])
        XCTAssertEqual(stack.dividerViews.count, 2)
        XCTAssertTrue(stack.itemViews == [items[1], items[0], c])
    }

    func testDividerColorTable() {
        let dynamic = UIColor { $0.userInterfaceStyle == .dark ? UIColor.blue : UIColor.green }
        struct Case {
            let name: String
            var color: UIColor?
            var icon: UIColor?
            var dark: Bool
        }
        let cases: [Case] = [
            Case(name: "fixed color", color: .red, icon: iconColor, dark: false),
            Case(name: "dynamic, light", color: dynamic, dark: false),
            Case(name: "dynamic, dark", color: dynamic, dark: true),
            Case(name: "icon color at 0.6, light", icon: iconColor, dark: false),
            Case(name: "icon color at 0.6, dark", icon: iconColor, dark: true),
            Case(name: "secondaryLabel, light", dark: false),
            Case(name: "secondaryLabel, dark", dark: true),
        ]
        for c in cases {
            let (stack, _) = row(["A", "B"], dark: c.dark)
            stack.dividerColor = c.color
            if let icon = c.icon { stack.itemAppearance = appearance(normal: icon) }
            stack.layoutIfNeeded()
            let style = UITraitCollection(userInterfaceStyle: c.dark ? .dark : .light)
            let expected: UIColor
            if let color = c.color {
                expected = color.resolvedColor(with: style)
            } else if let icon = c.icon {
                expected = icon.withAlphaComponent(CYLAnimatedItemDividerAlpha)
            } else {
                expected = UIColor.secondaryLabel.resolvedColor(with: style)
            }
            assertColor(line(of: stack.dividerViews[0])?.backgroundColor, expected, c.name)
        }
    }

    func testDividerColorFollowsALiveAppearanceSwitchAndChanges() {
        let (stack, _) = row(["A", "B"])
        let dynamic = UIColor { $0.userInterfaceStyle == .dark ? UIColor.blue : UIColor.green }
        stack.dividerColor = dynamic
        let window = stack.window!
        assertColor(line(of: stack.dividerViews[0])?.backgroundColor, .green, "light")
        window.overrideUserInterfaceStyle = .dark
        window.layoutIfNeeded()
        assertColor(line(of: stack.dividerViews[0])?.backgroundColor, .blue, "dark after the switch")
        window.overrideUserInterfaceStyle = .light
        window.layoutIfNeeded()
        assertColor(line(of: stack.dividerViews[0])?.backgroundColor, .green, "light again")
        stack.dividerColor = nil
        stack.itemAppearance = appearance(normal: iconColor)
        assertColor(line(of: stack.dividerViews[0])?.backgroundColor, iconColor.withAlphaComponent(CYLAnimatedItemDividerAlpha), "icon color change re-resolves")
        stack.itemAppearance = nil
        assertColor(line(of: stack.dividerViews[0])?.backgroundColor, UIColor.secondaryLabel.resolvedColor(with: stack.traitCollection), "secondaryLabel again")
    }

    // MARK: - Stack: tint inheritance 堆叠视图着色继承

    private func makeTintItem(_ factory: StackRecordingFactory) -> CYLAnimatedItemView {
        let item = CYLAnimatedItemView(frame: .zero)
        item.iconSize = CGSize(width: 24, height: 24)
        item.animationSource = factory
        item.animationURL = file
        return item
    }

    private func lastTint(_ factory: StackRecordingFactory) -> UIColor?? { factory.view.calls.last }

    func testStackTintInheritance() {
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        window().addSubview(stack)
        stack.itemAppearance = appearance(normal: iconColor)
        let fInherit = StackRecordingFactory(), fOwn = StackRecordingFactory(), fLater = StackRecordingFactory()
        let inherit = makeTintItem(fInherit)
        let own = makeTintItem(fOwn)
        own.animationTint = "#FF0000"
        stack.append(inherit, action: nil, spacingBefore: 0)
        stack.append(own, action: nil, spacingBefore: 0)

        stack.animationTint = "title"
        assertColor(lastTint(fInherit) ?? nil, iconColor, "stack only: the stack's tint, the stack's icon color")
        assertColor(lastTint(fOwn) ?? nil, .red, "the item's own tint wins")

        let later = makeTintItem(fLater)
        stack.append(later, action: nil, spacingBefore: 0)
        assertColor(lastTint(fLater) ?? nil, iconColor, "appended later")

        stack.animationTint = "#00FF00"
        assertColor(lastTint(fInherit) ?? nil, fixed, "changed")
        assertColor(lastTint(fOwn) ?? nil, .red, "own still wins")

        stack.animationTint = nil
        XCTAssertNil(lastTint(fInherit) ?? nil, "cleared: the inherited tint is gone")
        XCTAssertNotNil(lastTint(fInherit), "and the view was told")
        XCTAssertNil(lastTint(fLater) ?? nil)
        assertColor(lastTint(fOwn) ?? nil, .red, "the item's own setting stays")

        stack.animationTint = "title"
        own.animationTint = nil
        assertColor(lastTint(fOwn) ?? nil, iconColor, "an item that clears its own value inherits again")
    }

    func testStackDarkTintFollowsAnAppearanceChange() {
        let window = window()
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        window.addSubview(stack)
        let factory = StackRecordingFactory()
        stack.append(makeTintItem(factory), action: nil, spacingBefore: 0)
        stack.animationTint = "#00FF00"
        stack.animationDarkTint = "#0000FF"
        assertColor(lastTint(factory) ?? nil, fixed, "light")
        window.overrideUserInterfaceStyle = .dark
        stack.layoutIfNeeded()
        assertColor(lastTint(factory) ?? nil, darkFixed, "dark after the switch")
        stack.animationDarkTint = nil
        assertColor(lastTint(factory) ?? nil, fixed, "dark tint cleared")
    }

    func testRemovedItemKeepsNothingInherited() {
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        let item = CYLAnimatedItemView(frame: .zero)
        stack.append(item, action: nil, spacingBefore: 0)
        stack.animationTint = "title"
        XCTAssertEqual(item.inheritedAnimationTint, "title")
        stack.remove(item)
        XCTAssertNil(item.inheritedAnimationTint)
    }

    // MARK: - Host subclasses 宿主子类

    /// v2 precedence: an explicit stack value wins over the subclass built-in (the subclass wins over the component built-ins only).
    func testAnExplicitStackAppearanceWinsOverASubclassIconColor() {
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        window().addSubview(stack)
        let factory = StackRecordingFactory()
        let item = OrangeTagItem(frame: .zero)
        item.iconSize = CGSize(width: 24, height: 24)
        item.animationSource = factory
        item.animationURL = file
        item.animationTint = "title"
        item.applyIconTintColor(.orange)
        assertColor(item.imageView.tintColor, .orange, "subclass color beats the built-in label color")
        stack.itemAppearance = appearance(normal: .red, selected: .blue)
        stack.dispatchesItemTaps = false
        stack.append(item, action: nil, spacingBefore: 0)
        XCTAssertTrue(item is OrangeTagItem && stack.itemViews.first === item, "a subclass is accepted")
        XCTAssertTrue(item.isItemAppearanceInherited)
        assertColor(item.imageView.tintColor, .red, "appended: the stack's explicit normal color wins")
        assertColor(lastTint(factory) ?? nil, .red, "the animation tint takes the effective color")
        stack.itemAppearance = appearance(normal: .green, selected: .green)
        assertColor(item.imageView.tintColor, .green, "stack appearance changed")
        item.isSelected = true
        assertColor(item.imageView.tintColor, .green, "selected: the stack's selected color")
        stack.itemAppearance = appearance(normal: .green, selected: nil)
        assertColor(item.imageView.tintColor, .orange, "stack has no selected color: the subclass color is next")
        stack.itemAppearance = nil
        assertColor(item.imageView.tintColor, .orange, "no explicit value at all: the subclass color")
        XCTAssertEqual(stack.itemViews.count, 1)
    }

    func testAnItemWithItsOwnAppearanceKeepsItEvenIfSetAfterAppending() {
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        stack.itemAppearance = appearance(normal: .gray)
        let item = CYLAnimatedItemView(frame: .zero)
        stack.append(item, action: nil, spacingBefore: 0)
        XCTAssertTrue(item.isItemAppearanceInherited)
        item.itemAppearance = appearance(normal: .red)
        XCTAssertFalse(item.isItemAppearanceInherited)
        stack.itemAppearance = appearance(normal: .blue)
        assertColor(item.itemAppearance?.normal.iconColor, .red, "own, set later, wins")
    }

    func testDispatchesItemTapsFalseDoesNotTakeOverTapsOrAccessibilityGrouping() {
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 100))
        stack.dispatchesItemTaps = false
        var ran = 0
        stack.setHandler({ _, _ in ran += 1 }, for: "go")
        let item = CYLAnimatedItemView(frame: .zero)
        item.isUserInteractionEnabled = false
        stack.append(item, action: "go", spacingBefore: 0)
        XCTAssertFalse(item.isUserInteractionEnabled, "left as the host set it")
        item.sendActions(for: .touchUpInside)
        XCTAssertEqual(ran, 0, "no action on an item tap")
        XCTAssertFalse(stack.shouldGroupAccessibilityChildren, "no reordering of accessibility")
        stack.dispatchesItemTaps = true
        XCTAssertTrue(stack.shouldGroupAccessibilityChildren)
    }

    // MARK: - Row layout 横排布局

    private func tag(_ title: String) -> CYLAnimatedItemView {
        let item = CYLAnimatedItemView(frame: .zero)
        item.title = title
        item.axis = .horizontal
        return item
    }

    func testHorizontalRowHugsItsContentAtEachItemsOwnSize() {
        let stack = CYLAnimatedItemStackView(frame: .zero)
        stack.axis = .horizontal
        stack.contentMargin = 0
        stack.spacing = 6
        let a = tag("A"), b = tag("A much longer title")
        stack.append(a, action: nil, spacingBefore: 0)
        stack.append(b, action: nil, spacingBefore: 10)
        let sizeA = a.sizeThatFits(CGSize(width: 1000, height: 1000))
        let sizeB = b.sizeThatFits(CGSize(width: 1000, height: 1000))
        let size = stack.intrinsicContentSize
        XCTAssertEqual(size.width, sizeA.width + sizeB.width + 10, accuracy: 1, "contentMargin 0: no leftover padding")
        XCTAssertEqual(size.height, max(sizeA.height, sizeB.height), accuracy: 1)
        XCTAssertNotEqual(sizeA.width, sizeB.width)
        stack.frame = CGRect(origin: .zero, size: size)
        stack.layoutIfNeeded()
        XCTAssertEqual(a.frame.width, sizeA.width, accuracy: 1, "no equal widths")
        XCTAssertEqual(b.frame.width, sizeB.width, accuracy: 1)
        XCTAssertEqual(a.frame.minX, 0, accuracy: 0.5, "no padding at the leading edge")
        XCTAssertEqual(b.frame.maxX, size.width, accuracy: 1, "none at the trailing edge")
        stack.frame = .zero
        stack.contentMargin = 16
        XCTAssertEqual(stack.intrinsicContentSize.width, size.width + 32, accuracy: 1, "the default margin is untouched")
    }

    func testHiddenItemLeavesNoSpacingAndShowingBringsItBack() {
        let stack = CYLAnimatedItemStackView(frame: .zero)
        stack.axis = .horizontal
        stack.contentMargin = 0
        let a = tag("A"), b = tag("B"), c = tag("C")
        stack.append(a, action: nil, spacingBefore: 0)
        stack.append(b, action: nil, spacingBefore: 12)
        stack.append(c, action: nil, spacingBefore: 12)
        let full = stack.intrinsicContentSize.width
        let widthB = b.sizeThatFits(CGSize(width: 1000, height: 1000)).width
        b.isHidden = true
        XCTAssertEqual(stack.intrinsicContentSize.width, full - widthB - 12, accuracy: 1)
        stack.frame = CGRect(origin: .zero, size: stack.intrinsicContentSize)
        stack.layoutIfNeeded()
        XCTAssertEqual(c.frame.minX - a.frame.maxX, 12, accuracy: 1, "one spacing between the visible neighbours")
        a.isHidden = true
        XCTAssertEqual(stack.intrinsicContentSize.width, c.sizeThatFits(CGSize(width: 1000, height: 1000)).width, accuracy: 1,
                       "the first visible item takes no spacing before it")
        a.isHidden = false
        b.isHidden = false
        XCTAssertEqual(stack.intrinsicContentSize.width, full, accuracy: 1)
        b.alpha = 0
        XCTAssertEqual(stack.intrinsicContentSize.width, full, accuracy: 1, "faded keeps its place")
    }

    func testAddRemoveAndReorderAtAnyTime() {
        let stack = CYLAnimatedItemStackView(frame: CGRect(x: 0, y: 0, width: 300, height: 60))
        stack.axis = .horizontal
        stack.contentMargin = 0
        let a = tag("A"), b = tag("B"), c = tag("C")
        stack.append(a, action: "a", spacingBefore: 0)
        stack.append(b, action: "b", spacingBefore: 8)
        stack.append(c, action: "c", spacingBefore: 8)
        stack.move(c, to: 0)
        XCTAssertTrue(stack.itemViews == [c, a, b])
        XCTAssertTrue(stack.stackView.arrangedSubviews == [c, a, b])
        XCTAssertEqual(stack.action(for: c), "c", "the action travels with the item")
        stack.move(c, to: 99)
        XCTAssertTrue(stack.itemViews == [a, b, c], "clamped")
        let d = tag("D")
        stack.replaceItemViews([d, c, a])
        XCTAssertTrue(stack.itemViews == [d, c, a])
        XCTAssertNil(b.superview, "missing items are removed")
        XCTAssertEqual(stack.action(for: c), "c")
        stack.remove(d)
        XCTAssertTrue(stack.itemViews == [c, a])
        stack.layoutIfNeeded()
        XCTAssertLessThan(c.frame.minX, a.frame.minX, "the layout follows")
    }

    func testIntrinsicSizeFollowsDynamicType() {
        let window = window()
        let stack = CYLAnimatedItemStackView(frame: .zero)
        stack.axis = .horizontal
        stack.contentMargin = 0
        let item = tag("Dynamic")
        stack.append(item, action: nil, spacingBefore: 0)
        window.addSubview(stack)
        let small = stack.intrinsicContentSize
        window.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
        stack.layoutIfNeeded()
        let large = stack.intrinsicContentSize
        XCTAssertGreaterThan(large.width, small.width, "the row grows with the font")
        XCTAssertGreaterThan(large.height, small.height)
    }
}
