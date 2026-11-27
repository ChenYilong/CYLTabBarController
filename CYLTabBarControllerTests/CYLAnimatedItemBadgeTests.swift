//
//  CYLAnimatedItemBadgeTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] Not compiled yet: written statically on Linux (docs/Animated-Item-Badge.md, step 16).
//  [CN] 尚未编译：在 Linux 上静态编写（docs/Animated-Item-Badge.md，第 16 步）。
//

import UIKit
import XCTest
import CYLAnimatedItem
import CYLTabBarController

/**
 * [EN] The item badge API of `CYLAnimatedItemView`: the anchor sits on the icon, the badge never moves or shrinks the icon,
 *      clearing restores everything, the accessibility value carries the description, and the old spelling reaches the same view.
 * [CN] `CYLAnimatedItemView` 的角标 API：锚点位于图标上，角标不会移动或缩小图标，清除后一切复原，无障碍值带有描述，旧写法落在同一个视图。
 */
final class CYLAnimatedItemBadgeTests: XCTestCase {
    private func makeItem(axis: CYLAnimatedItemAxis = .horizontal) -> CYLAnimatedItemView {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 120, height: 44))
        item.axis = axis
        item.title = "Title"
        item.image = UIGraphicsImageRenderer(size: CGSize(width: 20, height: 20)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 20, height: 20))
        }
        item.layoutIfNeeded()
        return item
    }

    func testAnchorSitsOnTheIconAboveItAndIsNotInteractive() {
        let item = makeItem()
        item.badgeValue = "3"
        item.layoutIfNeeded()
        let anchor = item.badgeAnchorView
        XCTAssertEqual(anchor.frame, item.imageView.frame)
        XCTAssertTrue(anchor.superview === item)
        XCTAssertEqual(item.subviews.last, anchor)
        XCTAssertFalse(anchor.isUserInteractionEnabled)
        XCTAssertTrue(anchor.accessibilityElementsHidden)
    }

    func testBadgeDoesNotMoveOrShrinkTheIconAndClearingRestoresIt() {
        let item = makeItem()
        let before = item.imageView.frame
        item.badgeValue = "3"
        item.layoutIfNeeded()
        XCTAssertEqual(item.imageView.frame, before)
        XCTAssertTrue(item.isShowingBadge)
        item.badgeValue = nil
        item.layoutIfNeeded()
        XCTAssertEqual(item.imageView.frame, before)
        XCTAssertFalse(item.isShowingBadge)
    }

    func testOldSpellingAndBadgeValueAreTheSameBadge() {
        let item = makeItem()
        item.cyl_showBadgeValue("5", animationType: .none)
        XCTAssertTrue(item.isShowingBadge)
        XCTAssertTrue(item.cylAnimatedItemBadgeHost() === item.badgeAnchorView)
    }

    func testAccessibilityValueAddsTheBadgeDescriptionAndRestoresTheOwnValue() {
        let item = makeItem()
        item.accessibilityValue = "Selected"
        item.badgeValue = "3"
        XCTAssertTrue(item.accessibilityValue?.hasPrefix("Selected, ") == true)
        item.badgeValue = nil
        XCTAssertEqual(item.accessibilityValue, "Selected")
    }

    func testReservesBadgeSpaceGrowsMeasuringOnlyWhenOn() {
        let item = makeItem()
        item.badgeValue = "3"
        let plain = item.sizeThatFits(CGSize(width: 200, height: 44))
        item.reservesBadgeSpace = true
        let reserved = item.sizeThatFits(CGSize(width: 200, height: 44))
        XCTAssertGreaterThan(reserved.width, plain.width)
    }

    func testAttributeParserAcceptsStringsAndIgnoresUnknownTypes() {
        let view = UIView()
        view.cylApplyBadgeAttributes([
            CYLBadgeAttributeKey.color: "#FF3B30",
            CYLBadgeAttributeKey.centerOffset: "{4, -2}",
            CYLBadgeAttributeKey.radius: "5",
            CYLBadgeAttributeKey.maximumNumber: NSNull(),
        ])
        XCTAssertEqual(view.cyl_badgeCenterOffset, CGPoint(x: 4, y: -2))
        XCTAssertEqual(view.cyl_badgeRadius, 5)
        XCTAssertEqual(CYLBadgeAnimationType(attributeValue: "Scale"), .scale)
        XCTAssertNil(CYLBadgeAnimationType(attributeValue: "unknown"))
    }
}
