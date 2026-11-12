//
//  UIColor+CYLTabBarControllerExtention.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Semantic and system colors, a light / dark color pair and a random color. Translated from Objective-C
 *      (docs/Swift-Migration.md): every color is the UIKit one (the library needs iOS 13, so the old fallbacks for
 *      earlier systems are gone). Objective-C callers get the declarations from `CYLSwiftInterface.h`; the Swift names are
 *      the ones Clang imported (`UIColor.cyl_systemRed`, `cyl_color(withLight:dark:)`).
 * [CN] 语义色与系统色、浅色/深色颜色对以及随机颜色。已从 Objective-C 翻译（docs/Swift-Migration.md）：每个颜色都是 UIKit 的颜色（本库要求
 *      iOS 13，因此去掉了旧系统的回退值）。Objective-C 调用方从 `CYLSwiftInterface.h` 获得声明；Swift 名称与 Clang 原先导入的名称相同
 *      （`UIColor.cyl_systemRed`、`cyl_color(withLight:dark:)`）。
 */
extension UIColor {

    /**
     * [EN] `UIColor.systemRed`.
     * [CN] `UIColor.systemRed`。
     */
    @objc(cyl_systemRedColor) public class var cyl_systemRed: UIColor {
        .systemRed
    }

    /**
     * [EN] `UIColor.systemGreen`.
     * [CN] `UIColor.systemGreen`。
     */
    @objc(cyl_systemGreenColor) public class var cyl_systemGreen: UIColor {
        .systemGreen
    }

    /**
     * [EN] `UIColor.systemBlue`.
     * [CN] `UIColor.systemBlue`。
     */
    @objc(cyl_systemBlueColor) public class var cyl_systemBlue: UIColor {
        .systemBlue
    }

    /**
     * [EN] `UIColor.systemOrange`.
     * [CN] `UIColor.systemOrange`。
     */
    @objc(cyl_systemOrangeColor) public class var cyl_systemOrange: UIColor {
        .systemOrange
    }

    /**
     * [EN] `UIColor.systemYellow`.
     * [CN] `UIColor.systemYellow`。
     */
    @objc(cyl_systemYellowColor) public class var cyl_systemYellow: UIColor {
        .systemYellow
    }

    /**
     * [EN] `UIColor.systemPink`.
     * [CN] `UIColor.systemPink`。
     */
    @objc(cyl_systemPinkColor) public class var cyl_systemPink: UIColor {
        .systemPink
    }

    /**
     * [EN] `UIColor.systemPurple`.
     * [CN] `UIColor.systemPurple`。
     */
    @objc(cyl_systemPurpleColor) public class var cyl_systemPurple: UIColor {
        .systemPurple
    }

    /**
     * [EN] `UIColor.systemTeal`.
     * [CN] `UIColor.systemTeal`。
     */
    @objc(cyl_systemTealColor) public class var cyl_systemTeal: UIColor {
        .systemTeal
    }

    /**
     * [EN] `UIColor.systemIndigo`.
     * [CN] `UIColor.systemIndigo`。
     */
    @objc(cyl_systemIndigoColor) public class var cyl_systemIndigo: UIColor {
        .systemIndigo
    }

    /**
     * [EN] `UIColor.systemGray`.
     * [CN] `UIColor.systemGray`。
     */
    @objc(cyl_systemGrayColor) public class var cyl_systemGray: UIColor {
        .systemGray
    }

    /**
     * [EN] `UIColor.systemGray2`.
     * [CN] `UIColor.systemGray2`。
     */
    @objc(cyl_systemGray2Color) public class var cyl_systemGray2: UIColor {
        .systemGray2
    }

    /**
     * [EN] `UIColor.systemGray3`.
     * [CN] `UIColor.systemGray3`。
     */
    @objc(cyl_systemGray3Color) public class var cyl_systemGray3: UIColor {
        .systemGray3
    }

    /**
     * [EN] `UIColor.systemGray4`.
     * [CN] `UIColor.systemGray4`。
     */
    @objc(cyl_systemGray4Color) public class var cyl_systemGray4: UIColor {
        .systemGray4
    }

    /**
     * [EN] `UIColor.systemGray5`.
     * [CN] `UIColor.systemGray5`。
     */
    @objc(cyl_systemGray5Color) public class var cyl_systemGray5: UIColor {
        .systemGray5
    }

    /**
     * [EN] `UIColor.systemGray6`.
     * [CN] `UIColor.systemGray6`。
     */
    @objc(cyl_systemGray6Color) public class var cyl_systemGray6: UIColor {
        .systemGray6
    }

    /**
     * [EN] `UIColor.label`.
     * [CN] `UIColor.label`。
     */
    @objc(cyl_labelColor) public class var cyl_label: UIColor {
        .label
    }

    /**
     * [EN] `UIColor.secondaryLabel`.
     * [CN] `UIColor.secondaryLabel`。
     */
    @objc(cyl_secondaryLabelColor) public class var cyl_secondaryLabel: UIColor {
        .secondaryLabel
    }

    /**
     * [EN] `UIColor.tertiaryLabel`.
     * [CN] `UIColor.tertiaryLabel`。
     */
    @objc(cyl_tertiaryLabelColor) public class var cyl_tertiaryLabel: UIColor {
        .tertiaryLabel
    }

    /**
     * [EN] `UIColor.quaternaryLabel`.
     * [CN] `UIColor.quaternaryLabel`。
     */
    @objc(cyl_quaternaryLabelColor) public class var cyl_quaternaryLabel: UIColor {
        .quaternaryLabel
    }

    /**
     * [EN] `UIColor.link`.
     * [CN] `UIColor.link`。
     */
    @objc(cyl_linkColor) public class var cyl_link: UIColor {
        .link
    }

    /**
     * [EN] `UIColor.placeholderText`.
     * [CN] `UIColor.placeholderText`。
     */
    @objc(cyl_placeholderTextColor) public class var cyl_placeholderText: UIColor {
        .placeholderText
    }

    /**
     * [EN] `UIColor.separator`.
     * [CN] `UIColor.separator`。
     */
    @objc(cyl_separatorColor) public class var cyl_separator: UIColor {
        .separator
    }

    /**
     * [EN] `UIColor.opaqueSeparator`.
     * [CN] `UIColor.opaqueSeparator`。
     */
    @objc(cyl_opaqueSeparatorColor) public class var cyl_opaqueSeparator: UIColor {
        .opaqueSeparator
    }

    /**
     * [EN] `UIColor.systemBackground`.
     * [CN] `UIColor.systemBackground`。
     */
    @objc(cyl_systemBackgroundColor) public class var cyl_systemBackground: UIColor {
        .systemBackground
    }

    /**
     * [EN] `UIColor.secondarySystemBackground`.
     * [CN] `UIColor.secondarySystemBackground`。
     */
    @objc(cyl_secondarySystemBackgroundColor) public class var cyl_secondarySystemBackground: UIColor {
        .secondarySystemBackground
    }

    /**
     * [EN] `UIColor.tertiarySystemBackground`.
     * [CN] `UIColor.tertiarySystemBackground`。
     */
    @objc(cyl_tertiarySystemBackgroundColor) public class var cyl_tertiarySystemBackground: UIColor {
        .tertiarySystemBackground
    }

    /**
     * [EN] `UIColor.systemGroupedBackground`.
     * [CN] `UIColor.systemGroupedBackground`。
     */
    @objc(cyl_systemGroupedBackgroundColor) public class var cyl_systemGroupedBackground: UIColor {
        .systemGroupedBackground
    }

    /**
     * [EN] `UIColor.secondarySystemGroupedBackground`.
     * [CN] `UIColor.secondarySystemGroupedBackground`。
     */
    @objc(cyl_secondarySystemGroupedBackgroundColor) public class var cyl_secondarySystemGroupedBackground: UIColor {
        .secondarySystemGroupedBackground
    }

    /**
     * [EN] `UIColor.tertiarySystemGroupedBackground`.
     * [CN] `UIColor.tertiarySystemGroupedBackground`。
     */
    @objc(cyl_tertiarySystemGroupedBackgroundColor) public class var cyl_tertiarySystemGroupedBackground: UIColor {
        .tertiarySystemGroupedBackground
    }

    /**
     * [EN] `UIColor.systemFill`.
     * [CN] `UIColor.systemFill`。
     */
    @objc(cyl_systemFillColor) public class var cyl_systemFill: UIColor {
        .systemFill
    }

    /**
     * [EN] `UIColor.secondarySystemFill`.
     * [CN] `UIColor.secondarySystemFill`。
     */
    @objc(cyl_secondarySystemFillColor) public class var cyl_secondarySystemFill: UIColor {
        .secondarySystemFill
    }

    /**
     * [EN] `UIColor.tertiarySystemFill`.
     * [CN] `UIColor.tertiarySystemFill`。
     */
    @objc(cyl_tertiarySystemFillColor) public class var cyl_tertiarySystemFill: UIColor {
        .tertiarySystemFill
    }

    /**
     * [EN] `UIColor.quaternarySystemFill`.
     * [CN] `UIColor.quaternarySystemFill`。
     */
    @objc(cyl_quaternarySystemFillColor) public class var cyl_quaternarySystemFill: UIColor {
        .quaternarySystemFill
    }

    /**
     * [EN] `UIColor.lightText`.
     * [CN] `UIColor.lightText`。
     */
    @objc(cyl_lightTextColor) public class var cyl_lightText: UIColor {
        .lightText
    }

    /**
     * [EN] `UIColor.darkText`.
     * [CN] `UIColor.darkText`。
     */
    @objc(cyl_darkTextColor) public class var cyl_darkText: UIColor {
        .darkText
    }

    /**
     * [EN] A color that is `lightColor` in light mode and `darkColor` in dark mode; `lightColor` alone when `darkColor` is nil.
     * [CN] 浅色模式下为 `lightColor`、深色模式下为 `darkColor` 的颜色；`darkColor` 为 nil 时直接返回 `lightColor`。
     */
    @objc(cyl_colorWithLightColor:darkColor:)
    public class func cyl_color(withLight lightColor: UIColor, dark darkColor: UIColor?) -> UIColor {
        guard let darkColor else {
            return lightColor
        }
        return UIColor { $0.userInterfaceStyle == .dark ? darkColor : lightColor }
    }

    /**
     * [EN] A random, fairly saturated and bright color.
     * [CN] 随机颜色，饱和度与亮度较高。
     */
    @objc(cyl_randomColor) public class var cyl_randomColor: UIColor {
        let hue = CGFloat(arc4random_uniform(256)) / 256
        let saturation = CGFloat(arc4random_uniform(128)) / 256 + 0.5
        let brightness = CGFloat(arc4random_uniform(128)) / 256 + 0.5
        return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1)
    }

    /**
     * [EN] Always nil: Apple removed this color in iOS 13 beta 2.
     * [CN] 总是返回 nil：Apple 在 iOS 13 beta 2 中移除了该颜色。
     */
    @available(*, deprecated, message: "Deprecated in 1.27.5.")
    @objc(cyl_systemBrownColor) public class var cyl_systemBrown: UIColor? {
        nil
    }
}
