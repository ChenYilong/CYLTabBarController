//
//  CYLBadgeAttributeKey.swift
//  CYLBadge
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] Not compiled yet: written statically on Linux (docs/Animated-Item-Badge.md, steps 13 and API design C).
//  [CN] 尚未编译：在 Linux 上静态编写（docs/Animated-Item-Badge.md，第 13 步与 API 设计 C）。
//

import UIKit

/**
 [EN] Keys of a badge style dictionary: the same strings as `CYLTabBarHostView.badgeAttributes` (React Native, Flutter),
      plus more. Values are objects or strings (`#RRGGBB` colors, `{x, y}` offsets). One parser,
      `UIView.cylApplyBadgeAttributes(_:)`, serves animated items, `CYLTabBarHostView` and configuration files.
 [CN] 角标样式字典的键：与 `CYLTabBarHostView.badgeAttributes`（React Native、Flutter）相同的字符串，并有更多。值为对象或字符串
      （`#RRGGBB` 颜色、`{x, y}` 偏移）。一个解析器 `UIView.cylApplyBadgeAttributes(_:)` 同时服务动效 item、`CYLTabBarHostView` 与配置文件。
 */
@objc public final class CYLBadgeAttributeKey: NSObject {
    /** [EN] The badge text. [CN] 角标文字。 */
    @objc public static let value = "value"
    /** [EN] Background color. [CN] 背景色。 */
    @objc public static let color = "color"
    /** [EN] One of the 10 `CYLBadgeAnimationType` names, a number, or a `CAAnimation`. [CN] 10 个 `CYLBadgeAnimationType` 名称之一、数字，或 `CAAnimation`。 */
    @objc public static let animation = "animation"
    /** [EN] Radius. [CN] 半径。 */
    @objc public static let radius = "radius"
    /** [EN] Offset from the icon's top-trailing corner. [CN] 相对图标右上角的偏移。 */
    @objc public static let centerOffset = "centerOffset"
    /** [EN] Text color. [CN] 文字颜色。 */
    @objc public static let textColor = "textColor"
    /** [EN] Font (a `UIFont`, or a point size). [CN] 字体（`UIFont` 或字号）。 */
    @objc public static let font = "font"
    /** [EN] Border color. [CN] 边框颜色。 */
    @objc public static let borderColor = "borderColor"
    /** [EN] Border width. [CN] 边框宽度。 */
    @objc public static let borderWidth = "borderWidth"
    /** [EN] The number above which "99+" style text shows. [CN] 超过该数字时显示 "99+" 形式的文字。 */
    @objc public static let maximumNumber = "maximumNumber"
    /** [EN] Whether Reduce Motion stops the animation. [CN] 减弱动态效果时是否停止动画。 */
    @objc public static let respectsReduceMotion = "respectsReduceMotion"
}

extension CYLBadgeAnimationType {
    /**
     [EN] A `CYLBadgeAnimationType` from an attribute value: a number, or one of the names `none`, `scale`, `shake`, `bounce`,
          `breathe`, `leftRightOnce`, `rightLeftOnce`, `fadeInOnce`, `rollingOnce`, `scaleOnce` (any letter case). Nil for
          anything else (a `CAAnimation` is handled by the caller).
     [CN] 由属性值得到 `CYLBadgeAnimationType`：数字，或名称 `none`、`scale`、`shake`、`bounce`、`breathe`、`leftRightOnce`、
          `rightLeftOnce`、`fadeInOnce`、`rollingOnce`、`scaleOnce`（不区分大小写）。其他值为 nil（`CAAnimation` 由调用方处理）。
     */
    public init?(attributeValue value: Any?) {
        if let number = value as? NSNumber, number.uintValue <= CYLBadgeAnimationType.scaleOnce.rawValue {
            self.init(rawValue: number.uintValue)
            return
        }
        let names = ["none", "scale", "shake", "bounce", "breathe", "leftrightonce", "rightleftonce", "fadeinonce", "rollingonce", "scaleonce"]
        if let name = (value as? String)?.lowercased(), let index = names.firstIndex(of: name) {
            self.init(rawValue: UInt(index))
            return
        }
        return nil
    }
}

extension UIView {

    /**
     [EN] Applies the style keys of `attributes` (`CYLBadgeAttributeKey`) to this view's badge settings. Colors are a `UIColor`
          or `"#RRGGBB"` / `"#RRGGBBAA"`; an offset is an `NSValue(cgPoint:)` or `"{x, y}"`; a number is an `NSNumber` or a
          numeric string. `NSNull` and unknown types are ignored, never a crash. The value and the animation are not applied
          here: the caller shows the badge.
     [CN] 把 `attributes` 中的样式键（`CYLBadgeAttributeKey`）应用到本视图的角标设置。颜色为 `UIColor` 或 `"#RRGGBB"` / `"#RRGGBBAA"`；偏移为
          `NSValue(cgPoint:)` 或 `"{x, y}"`；数字为 `NSNumber` 或数字字符串。`NSNull` 与未知类型被忽略，不会崩溃。值与动画不在这里应用：
          由调用方显示角标。
     */
    @objc(cyl_applyBadgeAttributes:)
    public func cylApplyBadgeAttributes(_ attributes: [String: Any]) {
        if let color = Self.cylBadgeColor(attributes[CYLBadgeAttributeKey.color]) { cyl_badgeBackgroundColor = color }
        if let color = Self.cylBadgeColor(attributes[CYLBadgeAttributeKey.textColor]) { cyl_badgeTextColor = color }
        if let font = attributes[CYLBadgeAttributeKey.font] as? UIFont {
            cyl_badgeFont = font
        } else if let size = Self.cylBadgeNumber(attributes[CYLBadgeAttributeKey.font]) {
            cyl_badgeFont = UIFont.systemFont(ofSize: CGFloat(size), weight: .bold)
        }
        if let radius = Self.cylBadgeNumber(attributes[CYLBadgeAttributeKey.radius]) { cyl_badgeRadius = CGFloat(radius) }
        if let offset = Self.cylBadgePoint(attributes[CYLBadgeAttributeKey.centerOffset]) { cyl_badgeCenterOffset = offset }
        if let maximum = Self.cylBadgeNumber(attributes[CYLBadgeAttributeKey.maximumNumber]) { cyl_badgeMaximumBadgeNumber = Int(maximum) }
        if let respects = attributes[CYLBadgeAttributeKey.respectsReduceMotion] as? Bool { cyl_badgeRespectsReduceMotion = respects }
        // [EN] The border belongs to the badge view, which exists only after the badge is shown: the caller applies again then.
        // [CN] 边框属于角标视图，它在显示角标之后才存在：调用方在那时再应用一次。
        if let badge = cyl_badge {
            if let color = Self.cylBadgeColor(attributes[CYLBadgeAttributeKey.borderColor]) { badge.layer.borderColor = color.cgColor }
            if let width = Self.cylBadgeNumber(attributes[CYLBadgeAttributeKey.borderWidth]) { badge.layer.borderWidth = CGFloat(width) }
        }
    }

    private static func cylBadgeColor(_ value: Any?) -> UIColor? {
        if let color = value as? UIColor { return color }
        guard var text = (value as? String)?.trimmingCharacters(in: .whitespaces), text.hasPrefix("#") else { return nil }
        text.removeFirst()
        guard text.count == 6 || text.count == 8, let rgba = UInt64(text, radix: 16) else { return nil }
        let hasAlpha = text.count == 8
        let r = CGFloat((rgba >> (hasAlpha ? 24 : 16)) & 0xFF) / 255
        let g = CGFloat((rgba >> (hasAlpha ? 16 : 8)) & 0xFF) / 255
        let b = CGFloat((rgba >> (hasAlpha ? 8 : 0)) & 0xFF) / 255
        let a = hasAlpha ? CGFloat(rgba & 0xFF) / 255 : 1
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }

    private static func cylBadgeNumber(_ value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let text = value as? String { return Double(text) }
        return nil
    }

    private static func cylBadgePoint(_ value: Any?) -> CGPoint? {
        if let point = value as? NSValue { return point.cgPointValue }
        if let text = value as? String, text.hasPrefix("{") { return NSCoder.cgPoint(for: text) }
        return nil
    }
}
