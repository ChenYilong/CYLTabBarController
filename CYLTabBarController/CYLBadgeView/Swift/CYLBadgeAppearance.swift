//
//  CYLBadgeAppearance.swift
//  CYLBadgeView
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The default look of badges (global, or per badge host). Invalid numbers fall back to safe values. Translated
 *      from Objective-C (docs/Swift-Migration.md); Objective-C callers get this class from `CYLSwiftInterface.h`; the
 *      Swift names are the ones Clang imported (`CYLBadgeAppearance.global`).
 * [CN] 角标的默认外观（全局，或每个角标宿主）。无效数值会回退为安全值。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C
 *      调用方通过 `CYLSwiftInterface.h` 使用本类；Swift 名称与 Clang 原先导入的名称相同（`CYLBadgeAppearance.global`）。
 */
@objc(CYLBadgeAppearance)
public class CYLBadgeAppearance: NSObject {

    private static let defaultRadius: CGFloat = 4
    private static let defaultMargin: CGFloat = 8
    private static let defaultMaximumBadgeNumber = 99

    /**
     * [EN] The appearance every badge uses unless its host has its own.
     * [CN] 所有角标使用的外观，除非宿主有自己的外观。
     */
    @objc(globalAppearance) public static let global = CYLBadgeAppearance()

    private var storedBackgroundColor: UIColor?
    private var storedTextColor: UIColor?
    private var storedFont: UIFont?

    override public init() {
        super.init()
        reset()
    }

    /**
     * [EN] The badge's background color; red when not set (nil resets it).
     * [CN] 角标背景色；未设置时为红色（设为 nil 即重置）。
     */
    @objc public var backgroundColor: UIColor! {
        get { storedBackgroundColor ?? .red }
        set { storedBackgroundColor = newValue }
    }

    /**
     * [EN] The badge's text color; white when not set (nil resets it).
     * [CN] 角标文字颜色；未设置时为白色（设为 nil 即重置）。
     */
    @objc public var textColor: UIColor! {
        get { storedTextColor ?? .white }
        set { storedTextColor = newValue }
    }

    /**
     * [EN] The badge's font; bold 9 pt when not set (nil resets it).
     * [CN] 角标字体；未设置时为 9pt 粗体（设为 nil 即重置）。
     */
    @objc public var font: UIFont! {
        get { storedFont ?? .boldSystemFont(ofSize: 9) }
        set { storedFont = newValue }
    }

    /**
     * [EN] The offset of the badge's center; non-finite components become 0.
     * [CN] 角标中心点的偏移；非有限的分量变为 0。
     */
    @objc public var centerOffset: CGPoint = .zero {
        didSet {
            let x = centerOffset.x.isFinite ? centerOffset.x : 0
            let y = centerOffset.y.isFinite ? centerOffset.y : 0
            if x != centerOffset.x || y != centerOffset.y {
                centerOffset = CGPoint(x: x, y: y)
            }
        }
    }

    /**
     * [EN] The radius of the dot badge; 4 for a value that is not positive and finite.
     * [CN] 圆点角标的半径；非正数或非有限值时为 4。
     */
    @objc public var radius: CGFloat = CYLBadgeAppearance.defaultRadius {
        didSet {
            if !(radius > 0 && radius.isFinite) {
                radius = CYLBadgeAppearance.defaultRadius
            }
        }
    }

    /**
     * [EN] The horizontal padding of a text badge; never negative.
     * [CN] 文字角标的水平内边距；不会为负数。
     */
    @objc public var margin: CGFloat = CYLBadgeAppearance.defaultMargin {
        didSet { margin = CYLBadgeAppearance.nonNegative(margin) }
    }

    /**
     * [EN] The largest number shown before "99+"; at least 1.
     * [CN] 显示 "99+" 之前的最大数字；至少为 1。
     */
    @objc public var maximumBadgeNumber: Int = CYLBadgeAppearance.defaultMaximumBadgeNumber {
        didSet {
            if maximumBadgeNumber < 1 {
                maximumBadgeNumber = 1
            }
        }
    }

    /**
     * [EN] The corner radius of a text badge (0: half its height); never negative.
     * [CN] 文字角标的圆角（0：高度的一半）；不会为负数。
     */
    @objc public var cornerRadius: CGFloat = 0 {
        didSet { cornerRadius = CYLBadgeAppearance.nonNegative(cornerRadius) }
    }

    /**
     * [EN] The border color; none by default.
     * [CN] 边框颜色；默认无。
     */
    @objc public var borderColor: UIColor?

    /**
     * [EN] The border width; never negative.
     * [CN] 边框宽度；不会为负数。
     */
    @objc public var borderWidth: CGFloat = 0 {
        didSet { borderWidth = CYLBadgeAppearance.nonNegative(borderWidth) }
    }

    /**
     * [EN] Restores every value to its default.
     * [CN] 将所有值恢复为默认值。
     */
    @objc public func reset() {
        storedBackgroundColor = nil
        storedTextColor = nil
        storedFont = nil
        centerOffset = .zero
        radius = CYLBadgeAppearance.defaultRadius
        margin = CYLBadgeAppearance.defaultMargin
        maximumBadgeNumber = CYLBadgeAppearance.defaultMaximumBadgeNumber
        cornerRadius = 0
        borderColor = nil
        borderWidth = 0
    }

    private static func nonNegative(_ value: CGFloat) -> CGFloat {
        value.isFinite ? max(0, value) : 0
    }
}
