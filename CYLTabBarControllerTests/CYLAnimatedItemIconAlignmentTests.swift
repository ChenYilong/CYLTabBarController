//
//  CYLAnimatedItemIconAlignmentTests.swift
//  CYLTabBarControllerTests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import XCTest
import CYLAnimatedItem

/**
 * [EN] `CYLAnimatedItemView` aligns by the icon itself: an image whose `alignmentRectInsets` mark a badge part sticking out at
 *      one corner keeps the icon, not the icon plus its badge, on the item's center line; an image without insets keeps the
 *      old layout. docs/Animated-Item.md, "Badge-tag icon off centre".
 * [CN] `CYLAnimatedItemView` 以图标本身对齐：图片的 `alignmentRectInsets` 标出从一角伸出的角标部分时，位于中线上的是图标而不是图标加
 *      角标；没有内边距的图片保持原布局。见 docs/Animated-Item.md 的“Badge-tag icon off centre”。
 */
final class CYLAnimatedItemIconAlignmentTests: XCTestCase {
    /** [EN] A 20 x 20 icon plus a badge 8 pt to the right and 6 pt above, as one image. [CN] 20 x 20 的图标加向右 8 pt、向上 6 pt 的角标，合成一张图片。 */
    private func badgedImage() -> UIImage {
        let image = UIGraphicsImageRenderer(size: CGSize(width: 28, height: 26)).image { context in
            UIColor.black.setFill()
            context.fill(CGRect(x: 0, y: 6, width: 20, height: 20))
        }
        return image.withAlignmentRectInsets(UIEdgeInsets(top: 6, left: 0, bottom: 0, right: 8))
    }

    private func item(image: UIImage, axis: CYLAnimatedItemAxis, title: String?) -> CYLAnimatedItemView {
        let item = CYLAnimatedItemView(frame: CGRect(x: 0, y: 0, width: 120, height: 80))
        item.axis = axis
        item.title = title
        item.image = image
        item.setNeedsLayout()
        item.layoutIfNeeded()
        return item
    }

    /** [EN] The icon part of the image view's frame. [CN] 图片视图范围中的图标部分。 */
    private func glyphFrame(of item: CYLAnimatedItemView) -> CGRect {
        item.imageView.frame.inset(by: item.imageView.image?.alignmentRectInsets ?? .zero)
    }

    func testStackedIconIsCenteredByTheIconNotTheBadge() {
        let item = item(image: badgedImage(), axis: .vertical, title: "Title")
        XCTAssertEqual(glyphFrame(of: item).midX, item.bounds.midX, accuracy: 0.5)
        XCTAssertEqual(item.imageView.frame.size, CGSize(width: 28, height: 26))
    }

    func testIconOnlyIsCenteredByTheIconInBothDirections() {
        let item = item(image: badgedImage(), axis: .horizontal, title: nil)
        XCTAssertEqual(glyphFrame(of: item).midX, item.bounds.midX, accuracy: 0.5)
        XCTAssertEqual(glyphFrame(of: item).midY, item.bounds.midY, accuracy: 0.5)
    }

    func testMeasurementReservesTheBadgeOnBothSides() {
        let item = item(image: badgedImage(), axis: .horizontal, title: nil)
        // [EN] 20 pt icon + 8 pt on each side; 20 pt + 6 pt on each side. [CN] 20 pt 图标 + 两侧各 8 pt；20 pt + 两侧各 6 pt。
        XCTAssertEqual(item.sizeThatFits(.zero), CGSize(width: 36, height: 32))
    }

    func testImageWithoutInsetsKeepsTheOldLayout() {
        let plain = UIGraphicsImageRenderer(size: CGSize(width: 28, height: 26)).image { _ in }
        let item = item(image: plain, axis: .vertical, title: "Title")
        XCTAssertEqual(item.imageView.frame.midX, item.bounds.midX, accuracy: 0.5)
        XCTAssertEqual(item.imageView.frame.size, CGSize(width: 28, height: 26))
    }
}
