//
//  CYLConstants.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// MARK: - The placeholder size of a tab image Tab 图片的占位尺寸

/**
 [EN] The width of a tab's image when it has none (an animation without a size or an image). Swift since docs/Swift-Migration.md
      step 114; Objective-C reads it through the macro of CYLConstants.h and sets it with `CYLConstants.tabBarItemImagePlaceholderSize`.
 [CN] Tab 没有图片时（没有尺寸与图片的动画）图片的宽度。自第 114 步起为 Swift；Objective-C 通过 CYLConstants.h 的宏读取，通过
      `CYLConstants.tabBarItemImagePlaceholderSize` 设置。
 */
public var CYLTabBarItemImagePlaceholderWidth: CGFloat = 22

/**
 [EN] The height of a tab's image when it has none. [CN] Tab 没有图片时图片的高度。
 */
public var CYLTabBarItemImagePlaceholderHeight: CGFloat = 22

/**
 [EN] Objective-C's `CYLTabBarItemImagePlaceholderWidth` (a macro of CYLConstants.h). [CN] Objective-C 的 `CYLTabBarItemImagePlaceholderWidth`（宏）。
 */
@_cdecl("CYLTabBarItemImagePlaceholderCurrentWidth")
public func CYLTabBarItemImagePlaceholderCurrentWidth() -> CGFloat {
    CYLTabBarItemImagePlaceholderWidth
}

/**
 [EN] Objective-C's `CYLTabBarItemImagePlaceholderHeight` (a macro of CYLConstants.h). [CN] Objective-C 的 `CYLTabBarItemImagePlaceholderHeight`（宏）。
 */
@_cdecl("CYLTabBarItemImagePlaceholderCurrentHeight")
public func CYLTabBarItemImagePlaceholderCurrentHeight() -> CGFloat {
    CYLTabBarItemImagePlaceholderHeight
}

/**
 [EN] `CYLConstants.uiBasisWidthScale()` for the `CYLScale` macro of CYLConstants.h. [CN] 供 CYLConstants.h 的 `CYLScale` 宏使用。
 */
@_cdecl("CYLConstantsUIBasisWidthScale")
public func CYLConstantsUIBasisWidthScale() -> CGFloat {
    CYLConstants.uiBasisWidthScale()
}

/**
 [EN] `CYLConstants.uiBasisHeightScale()` for the `CYLHScale` macro of CYLConstants.h. [CN] 供 CYLConstants.h 的 `CYLHScale` 宏使用。
 */
@_cdecl("CYLConstantsUIBasisHeightScale")
public func CYLConstantsUIBasisHeightScale() -> CGFloat {
    CYLConstants.uiBasisHeightScale()
}

// MARK: - CYLConstants

/**
 [EN] Layout scales, the Liquid Glass check and helpers for tab animations. Swift since docs/Swift-Migration.md step 114 (was
      CYLConstants.m); every class method keeps its selector and its Swift name. Nothing subclasses it.
 [CN] 布局比例、液态玻璃判断与 Tab 动画的辅助方法。自第 114 步起为 Swift（原为 CYLConstants.m）；每个类方法保留其 selector 与 Swift 名称。
      没有子类。
 */
@objc(CYLConstants)
open class CYLConstants: NSObject {

    /// [EN] The screen against the 375 x 667 design size, read once (the Objective-C class did it in `+initialize`).
    /// [CN] 屏幕相对 375 x 667 设计尺寸的比例，只读取一次（原 Objective-C 类在 `+initialize` 中读取）。
    private static let cylBasisScales: (width: CGFloat, height: CGFloat) = {
        let bounds = CYLGetRootWindow()?.windowScene?.screen.bounds ?? .zero
        return (bounds.width / 375, bounds.height / 667)
    }()

    /**
     [EN] The screen width divided by 375 (the iPhone 8 design width). [CN] 屏幕宽度与 375（iPhone 8 设计稿宽度）的比例。
     */
    @objc(UIBasisWidthScale)
    open class func uiBasisWidthScale() -> CGFloat { cylBasisScales.width }

    /**
     [EN] The screen height divided by 667. [CN] 屏幕高度与 667 的比例。
     */
    @objc(UIBasisHeightScale)
    open class func uiBasisHeightScale() -> CGFloat { cylBasisScales.height }

    /**
     [EN] Whether Liquid Glass (iOS 26+, no UI compatibility mode) is in use. [CN] 是否正在使用液态玻璃（iOS 26+，非 UI 兼容模式）。
     */
    @objc open class func isLiquidGlassActive() -> Bool { isUsedLiquidGlass() }

    /**
     [EN] Same as `isLiquidGlassActive()`. [CN] 与 `isLiquidGlassActive()` 相同。
     */
    @objc open class func isUsedLiquidGlass() -> Bool { CYLUtils.isLiquidGlassActive() }

    /**
     [EN] The placeholder size of a tab image (`CYLTabBarItemImagePlaceholderWidth` / `…Height`), settable from Objective-C, where
          the two globals are read-only macros since step 114.
     [CN] Tab 图片的占位尺寸（`CYLTabBarItemImagePlaceholderWidth` / `…Height`），可在 Objective-C 中设置（自第 114 步起两个全局变量在
          Objective-C 中是只读的宏）。
     */
    @objc open class var tabBarItemImagePlaceholderSize: CGSize {
        get { CGSize(width: CYLTabBarItemImagePlaceholderWidth, height: CYLTabBarItemImagePlaceholderHeight) }
        set {
            CYLTabBarItemImagePlaceholderWidth = newValue.width
            CYLTabBarItemImagePlaceholderHeight = newValue.height
        }
    }

    /**
     [EN] Deprecated. Use `cyl_tabBarItemAnimationSizeValue(_:fromNormalImage:)`. [CN] 已废弃，请改用 `cyl_tabBarItemAnimationSizeValue(_:fromNormalImage:)`。
     */
    @available(*, deprecated, message: "Use +cyl_tabBarItemAnimationSizeValue:fromNormalImage:")
    @objc(cyl_getTureLottieSizeValue:fromNormalImage:)
    open class func cyl_getTureLottieSizeValue(_ lottieSizeValue: NSValue!, fromNormalImage normalImage: UIImage!) -> NSValue! {
        cyl_tabBarItemAnimationSizeValue(lottieSizeValue, fromNormalImage: normalImage)
    }

    /**
     [EN] The size of a tab animation: the given size, else the normal image's, else the placeholder size.
     [CN] Tab 动画的尺寸：给定的尺寸，否则为普通图片的尺寸，否则为占位尺寸。
     */
    @objc(cyl_tabBarItemAnimationSizeValue:fromNormalImage:)
    open class func cyl_tabBarItemAnimationSizeValue(_ sizeValue: NSValue!, fromNormalImage normalImage: UIImage!) -> NSValue! {
        if let sizeValue, sizeValue.cgSizeValue != .zero {
            return sizeValue
        }
        if let normalImage, normalImage.size != .zero {
            return NSValue(cgSize: normalImage.size)
        }
        return NSValue(cgSize: tabBarItemImagePlaceholderSize)
    }

    /**
     [EN] A file URL for a path that exists, else nil. [CN] 存在的路径对应的文件 URL，否则为 nil。
     */
    @objc(cyl_getURLFromString:)
    open class func cyl_getURL(from string: String!) -> URL! {
        guard let string, FileManager.default.fileExists(atPath: string) else { return nil }
        return URL(fileURLWithPath: string)
    }

    /**
     [EN] Deprecated. Use the `CYLTabBarAnimationDarkURL` / `CYLTabBarAnimationDarkFilePath` tab item keys. [CN] 已废弃，请使用 Tab item 键。
     */
    @available(*, deprecated, message: "Use the CYLTabBarAnimationDarkURL / CYLTabBarAnimationDarkFilePath tab item keys")
    @objc(cyl_registerDarkLottieURL:forLottieURL:)
    open class func cyl_registerDarkLottieURL(_ darkLottieURL: URL!, forLottieURL lottieURL: URL!) {
        CYLTabBarItemAnimationStyleRegistry.shared.registerDarkURL(darkLottieURL, for: lottieURL)
    }

    /**
     [EN] Deprecated. Use the `CYLTabBarAnimationDarkURL` tab item key. [CN] 已废弃，请使用 `CYLTabBarAnimationDarkURL` 键。
     */
    @available(*, deprecated, message: "Use the CYLTabBarAnimationDarkURL tab item key")
    @objc(cyl_lottieURL:forTraitCollection:)
    open class func cyl_lottieURL(_ lottieURL: URL!, for traitCollection: UITraitCollection!) -> URL! {
        CYLTabBarItemAnimationStyleRegistry.shared.url(lottieURL, for: traitCollection)
    }

    /**
     [EN] Deprecated. Use the `CYLTabBarAnimationDarkColors` tab item key. [CN] 已废弃，请使用 `CYLTabBarAnimationDarkColors` 键。
     */
    @available(*, deprecated, message: "Use the CYLTabBarAnimationDarkColors tab item key")
    @objc(cyl_registerLottieDarkColors:forLottieURL:)
    open class func cyl_registerLottieDarkColors(_ darkColors: [String: UIColor]!, forLottieURL lottieURL: URL!) {
        CYLTabBarItemAnimationStyleRegistry.shared.registerDarkColors(darkColors as NSDictionary?, for: lottieURL)
    }

    /**
     [EN] Deprecated. Use the `CYLTabBarAnimationDarkColors` tab item key. [CN] 已废弃，请使用 `CYLTabBarAnimationDarkColors` 键。
     */
    @available(*, deprecated, message: "Use the CYLTabBarAnimationDarkColors tab item key")
    @objc(cyl_lottieDarkColorsForLottieURL:)
    open class func cyl_lottieDarkColors(forLottieURL lottieURL: URL!) -> [String: UIColor]! {
        CYLTabBarItemAnimationStyleRegistry.shared.darkColors(for: lottieURL)
    }

    /**
     [EN] Deprecated. Use the `CYLTabBarAnimationDark…` tab item keys. [CN] 已废弃，请使用 `CYLTabBarAnimationDark…` 键。
     */
    @available(*, deprecated, message: "Use the CYLTabBarAnimationDark… tab item keys")
    @objc open class func cyl_hasDarkLottieURLs() -> Bool {
        CYLTabBarItemAnimationStyleRegistry.shared.hasStyleVariants()
    }

    /**
     [EN] Deprecated. Use the `CYLTabBarAnimationDark…` tab item keys. [CN] 已废弃，请使用 `CYLTabBarAnimationDark…` 键。
     */
    @available(*, deprecated, message: "Use the CYLTabBarAnimationDark… tab item keys")
    @objc(cyl_hasDarkLottieForLottieURL:)
    open class func cyl_hasDarkLottie(forLottieURL lottieURL: URL!) -> Bool {
        CYLTabBarItemAnimationStyleRegistry.shared.hasStyleVariant(for: lottieURL)
    }

    /**
     [EN] Deprecated. Use `isTabBarItemAnimationEnabled(with:tabBarItemsAttributes:)`. [CN] 已废弃，请改用 `isTabBarItemAnimationEnabled(with:tabBarItemsAttributes:)`。
     */
    @available(*, deprecated, message: "Use +isTabBarItemAnimationEnabledWithURLs:tabBarItemsAttributes:")
    @objc(isLottieEnabledFromlottieURLs:tabBarItemsAttributes:)
    open class func isLottieEnabledFromlottieURLs(_ lottieURLs: NSMutableArray!, tabBarItemsAttributes: [[AnyHashable: Any]]!) -> Bool {
        isTabBarItemAnimationEnabled(with: lottieURLs?.compactMap { $0 as? URL }, tabBarItemsAttributes: tabBarItemsAttributes)
    }

    /**
     [EN] Whether tab animations are on: an animation library is in the build, and URLs were given or a tab's attributes name an
          animation file.
     [CN] Tab 动画是否开启：构建中包含动画库，并且给出了 URL，或某个 Tab 的属性指定了动画文件。
     */
    @objc(isTabBarItemAnimationEnabledWithURLs:tabBarItemsAttributes:)
    open class func isTabBarItemAnimationEnabled(with URLs: [URL]!, tabBarItemsAttributes: [[AnyHashable: Any]]!) -> Bool {
        guard CYLTabBarItemAnimationCore.service != nil else { return false }
        if !(URLs ?? []).isEmpty {
            return true
        }
        let attributesList: [[AnyHashable: Any]] = tabBarItemsAttributes ?? []
        return attributesList.contains { attributes in
            CYLTabBarItemAnimationCore.attributesAnimationValue(attributes, CYLTabBarAnimationURL) != nil
                || CYLTabBarItemAnimationCore.attributesAnimationValue(attributes, CYLTabBarAnimationFilePath) != nil
        }
    }
}
