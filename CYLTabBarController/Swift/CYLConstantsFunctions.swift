//
//  CYLConstantsFunctions.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import ObjectiveC

// [EN] The inline helper functions of CYLConstants.h, translated from Objective-C (docs/Swift-Migration.md, step 133). Same C names
//      (`@_cdecl`): Objective-C reaches them through the generated Swift interface, which CYLConstants.h imports at its end; the
//      macros of the header that call them (`CYLScale`…) are unchanged. The Swift names are lowerCamelCase (`cylScreenWidth()`); the
//      old C-style Swift names are deprecated forwards in Deprecated/ (docs/Swift-Coding-Style.md).
// [CN] CYLConstants.h 的内联辅助函数，已从 Objective-C 翻译（第 133 步）。C 名称不变（`@_cdecl`）：Objective-C 通过 CYLConstants.h 末尾导入的
//      生成 Swift 接口调用它们；头文件中调用它们的宏（`CYLScale`…）不变。Swift 名称为 lowerCamelCase（`cylScreenWidth()`）；旧的 C 风格 Swift 名称是 Deprecated/ 中已废弃的转发（docs/Swift-Coding-Style.md）。

/**
 [EN] The foreground active window scene, or nil.
 [CN] 处于前台活跃状态的 window scene；没有时为 nil。
 */
@_cdecl("CYLGetWindowScene")
public func cylGetWindowScene() -> UIWindowScene? {
    UIApplication.shared.connectedScenes.lazy
        .compactMap { $0 as? UIWindowScene }
        .first { $0.activationState == .foregroundActive }
}

/**
 [EN] The application delegate's window, else the first window of the foreground scene; nil before the app has a window.
 [CN] AppDelegate 的 window，否则为前台 scene 的第一个 window；App 还没有 window 时为 nil。
 */
@_cdecl("CYLGetRootWindow")
public func cylGetRootWindow() -> UIWindow? {
    if let delegate = UIApplication.shared.delegate, delegate.responds(to: #selector(getter: UIApplicationDelegate.window)),
       let window = delegate.window ?? nil {
        return window
    }
    return cylGetWindowScene()?.windows.first
}

/**
 [EN] The top presented view controller of the root window (its root view controller when nothing is presented).
 [CN] 根 window 最上层 present 出的控制器（没有 present 时为其根控制器）。
 */
@_cdecl("CYLGetRootViewController")
public func cylGetRootViewController() -> UIViewController? {
    var top = cylGetRootWindow()?.rootViewController
    while let presented = top?.presentedViewController {
        top = presented
    }
    return top
}

/**
 [EN] `baseTabBarHeight` plus the root window's bottom safe area.
 [CN] `baseTabBarHeight` 加上根 window 的底部安全区域。
 */
@_cdecl("CYLGetTabBarFullH")
public func cylGetTabBarFullH(_ baseTabBarHeight: CGFloat) -> CGFloat {
    baseTabBarHeight + max(cylGetRootWindow()?.safeAreaInsets.bottom ?? 0, 0)
}

/**
 [EN] The screen size (not the tab bar size): the foreground scene's screen, else the main screen.
 [CN] 屏幕尺寸（不是 TabBar 尺寸）：前台 scene 的屏幕，否则为主屏幕。
 */
@_cdecl("CYLScreenSize")
public func cylScreenSize() -> CGSize {
    if let size = cylGetWindowScene()?.screen.bounds.size, size.width != 0, size.height != 0 {
        return size
    }
    return cylMainScreenBounds().size
}

/// [EN] `UIScreen.main`, deprecated in iOS 16, through Objective-C's runtime so no warning is raised. [CN] 通过运行时读取已废弃的 `UIScreen.main`，避免警告。
private func cylMainScreenBounds() -> CGRect {
    let selector = NSSelectorFromString("mainScreen")
    guard let screen = (UIScreen.self as AnyObject).perform(selector)?.takeUnretainedValue() as? UIScreen else { return .zero }
    return screen.bounds
}

/**
 [EN] The screen width. [CN] 屏幕宽度。
 */
@_cdecl("CYLScreenWidth")
public func cylScreenWidth() -> CGFloat {
    cylScreenSize().width
}

/**
 [EN] The screen height. [CN] 屏幕高度。
 */
@_cdecl("CYLScreenHeight")
public func cylScreenHeight() -> CGFloat {
    cylScreenSize().height
}

/**
 [EN] `value` scaled by the design width (`CYLScale`). [CN] 按设计宽度缩放的 `value`（`CYLScale`）。
 */
@_cdecl("CYLScaleValue")
public func cylScaleValue(_ value: CGFloat) -> CGFloat {
    value * cylConstantsUIBasisWidthScale()
}

/**
 [EN] `value` scaled by the design height (`CYLHScale`). [CN] 按设计高度缩放的 `value`（`CYLHScale`）。
 */
@_cdecl("CYLHScaleValue")
public func cylHScaleValue(_ value: CGFloat) -> CGFloat {
    value * cylConstantsUIBasisHeightScale()
}

/**
 [EN] The system font of the scaled size. [CN] 缩放后大小的系统字体。
 */
@_cdecl("CYLScaleFont")
public func cylScaleFont(_ fontSize: CGFloat) -> UIFont {
    UIFont.systemFont(ofSize: cylScaleValue(fontSize))
}

/**
 [EN] The bold system font of the scaled size. [CN] 缩放后大小的粗体系统字体。
 */
@_cdecl("CYLScaleBoldFont")
public func cylScaleBoldFont(_ fontSize: CGFloat) -> UIFont {
    UIFont.boldSystemFont(ofSize: cylScaleValue(fontSize))
}

/**
 [EN] Whether two strings are equal (two nil values also count as equal).
 [CN] 判断两个字符串是否相等（两个都为 nil 也算相等）。
 */
@_cdecl("CYLStringEqual")
public func cylStringEqual(_ a: NSString?, _ b: NSString?) -> Bool {
    guard let a, let b else { return a === b }
    return a === b || a.isEqual(to: b as String)
}

/**
 [EN] Half of `value1 - value2`. [CN] `value1 - value2` 的一半。
 */
@_cdecl("CYLHalfOfDiff")
public func cylHalfOfDiff(_ value1: CGFloat, _ value2: CGFloat) -> CGFloat {
    (value1 - value2) * 0.5
}

// MARK: - Ivar type encodings

/// [EN] The `@encode` of `BOOL`: `signed char` on x86_64 (the Intel simulator), `bool` on arm64. [CN] `BOOL` 的 `@encode`：x86_64 为 `c`，arm64 为 `B`。
#if arch(x86_64) || arch(i386)
private let cylBOOLTypeEncoding = "c"
#else
private let cylBOOLTypeEncoding = "B"
#endif

/// [EN] Whether `typeEncoding` starts with `encode`, as the former `strncmp(@encode(T), …)`. [CN] `typeEncoding` 是否以 `encode` 开头，与原来的 `strncmp` 相同。
private func cylTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?, matches encode: String) -> Bool {
    guard let typeEncoding else { return false }
    return strncmp(encode, typeEncoding, encode.utf8.count) == 0
}

/// [EN] Whether the ivar's type encoding starts with `encode`. [CN] ivar 的类型编码是否以 `encode` 开头。
private func cylIvar(_ ivar: Ivar, matches encode: String) -> Bool {
    cylTypeEncoding(ivar_getTypeEncoding(ivar), matches: encode)
}

// [EN] One pair per type, as `_CYLTypeEncodingDetectorGenerator` expanded: `cyl_is<Type>TypeEncoding(const char *)` and
//      `cyl_is<Type>Ivar(Ivar)`. The encodings are the 64-bit ones (`long` is `q`). [CN] 每种类型一对，与原宏展开相同；编码为 64 位（`long` 为 `q`）。

/** [EN] `char`. [CN] `char`。 */
@_cdecl("cyl_isCharTypeEncoding") public func cylIsCharTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "c") }
/** [EN] `char` ivar. [CN] `char` ivar。 */
@_cdecl("cyl_isCharIvar") public func cylIsCharIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "c") }
/** [EN] `int`. [CN] `int`。 */
@_cdecl("cyl_isIntTypeEncoding") public func cylIsIntTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "i") }
/** [EN] `int` ivar. [CN] `int` ivar。 */
@_cdecl("cyl_isIntIvar") public func cylIsIntIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "i") }
/** [EN] `short`. [CN] `short`。 */
@_cdecl("cyl_isShortTypeEncoding") public func cylIsShortTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "s") }
/** [EN] `short` ivar. [CN] `short` ivar。 */
@_cdecl("cyl_isShortIvar") public func cylIsShortIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "s") }
/** [EN] `long`. [CN] `long`。 */
@_cdecl("cyl_isLongTypeEncoding") public func cylIsLongTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "q") }
/** [EN] `long` ivar. [CN] `long` ivar。 */
@_cdecl("cyl_isLongIvar") public func cylIsLongIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "q") }
/** [EN] `long long`. [CN] `long long`。 */
@_cdecl("cyl_isLongLongTypeEncoding") public func cylIsLongLongTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "q") }
/** [EN] `long long` ivar. [CN] `long long` ivar。 */
@_cdecl("cyl_isLongLongIvar") public func cylIsLongLongIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "q") }
/** [EN] `NSInteger`. [CN] `NSInteger`。 */
@_cdecl("cyl_isNSIntegerTypeEncoding") public func cylIsNSIntegerTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "q") }
/** [EN] `NSInteger` ivar. [CN] `NSInteger` ivar。 */
@_cdecl("cyl_isNSIntegerIvar") public func cylIsNSIntegerIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "q") }
/** [EN] `unsigned char`. [CN] `unsigned char`。 */
@_cdecl("cyl_isUnsignedCharTypeEncoding") public func cylIsUnsignedCharTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "C") }
/** [EN] `unsigned char` ivar. [CN] `unsigned char` ivar。 */
@_cdecl("cyl_isUnsignedCharIvar") public func cylIsUnsignedCharIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "C") }
/** [EN] `unsigned int`. [CN] `unsigned int`。 */
@_cdecl("cyl_isUnsignedIntTypeEncoding") public func cylIsUnsignedIntTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "I") }
/** [EN] `unsigned int` ivar. [CN] `unsigned int` ivar。 */
@_cdecl("cyl_isUnsignedIntIvar") public func cylIsUnsignedIntIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "I") }
/** [EN] `unsigned short`. [CN] `unsigned short`。 */
@_cdecl("cyl_isUnsignedShortTypeEncoding") public func cylIsUnsignedShortTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "S") }
/** [EN] `unsigned short` ivar. [CN] `unsigned short` ivar。 */
@_cdecl("cyl_isUnsignedShortIvar") public func cylIsUnsignedShortIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "S") }
/** [EN] `unsigned long`. [CN] `unsigned long`。 */
@_cdecl("cyl_isUnsignedLongTypeEncoding") public func cylIsUnsignedLongTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "Q") }
/** [EN] `unsigned long` ivar. [CN] `unsigned long` ivar。 */
@_cdecl("cyl_isUnsignedLongIvar") public func cylIsUnsignedLongIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "Q") }
/** [EN] `unsigned long long`. [CN] `unsigned long long`。 */
@_cdecl("cyl_isUnsignedLongLongTypeEncoding") public func cylIsUnsignedLongLongTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "Q") }
/** [EN] `unsigned long long` ivar. [CN] `unsigned long long` ivar。 */
@_cdecl("cyl_isUnsignedLongLongIvar") public func cylIsUnsignedLongLongIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "Q") }
/** [EN] `NSUInteger`. [CN] `NSUInteger`。 */
@_cdecl("cyl_isNSUIntegerTypeEncoding") public func cylIsNSUIntegerTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "Q") }
/** [EN] `NSUInteger` ivar. [CN] `NSUInteger` ivar。 */
@_cdecl("cyl_isNSUIntegerIvar") public func cylIsNSUIntegerIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "Q") }
/** [EN] `float`. [CN] `float`。 */
@_cdecl("cyl_isFloatTypeEncoding") public func cylIsFloatTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "f") }
/** [EN] `float` ivar. [CN] `float` ivar。 */
@_cdecl("cyl_isFloatIvar") public func cylIsFloatIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "f") }
/** [EN] `double`. [CN] `double`。 */
@_cdecl("cyl_isDoubleTypeEncoding") public func cylIsDoubleTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "d") }
/** [EN] `double` ivar. [CN] `double` ivar。 */
@_cdecl("cyl_isDoubleIvar") public func cylIsDoubleIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "d") }
/** [EN] `CGFloat` (64-bit: `double`). [CN] `CGFloat`（64 位：`double`）。 */
@_cdecl("cyl_isCGFloatTypeEncoding") public func cylIsCGFloatTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "d") }
/** [EN] `CGFloat` ivar. [CN] `CGFloat` ivar。 */
@_cdecl("cyl_isCGFloatIvar") public func cylIsCGFloatIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "d") }
/** [EN] `BOOL`. [CN] `BOOL`。 */
@_cdecl("cyl_isBOOLTypeEncoding") public func cylIsBOOLTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: cylBOOLTypeEncoding) }
/** [EN] `BOOL` ivar. [CN] `BOOL` ivar。 */
@_cdecl("cyl_isBOOLIvar") public func cylIsBOOLIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: cylBOOLTypeEncoding) }
/** [EN] `void`. [CN] `void`。 */
@_cdecl("cyl_isVoidTypeEncoding") public func cylIsVoidTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "v") }
/** [EN] `void` ivar. [CN] `void` ivar。 */
@_cdecl("cyl_isVoidIvar") public func cylIsVoidIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "v") }
/** [EN] `char *`. [CN] `char *`。 */
@_cdecl("cyl_isCharacterTypeEncoding") public func cylIsCharacterTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "*") }
/** [EN] `char *` ivar. [CN] `char *` ivar。 */
@_cdecl("cyl_isCharacterIvar") public func cylIsCharacterIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "*") }
/** [EN] `id`. [CN] `id`。 */
@_cdecl("cyl_isObjectTypeEncoding") public func cylIsObjectTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "@") }
/** [EN] `id` ivar. [CN] `id` ivar。 */
@_cdecl("cyl_isObjectIvar") public func cylIsObjectIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "@") }
/** [EN] `Class`. [CN] `Class`。 */
@_cdecl("cyl_isClassTypeEncoding") public func cylIsClassTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: "#") }
/** [EN] `Class` ivar. [CN] `Class` ivar。 */
@_cdecl("cyl_isClassIvar") public func cylIsClassIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: "#") }
/** [EN] `SEL`. [CN] `SEL`。 */
@_cdecl("cyl_isSelectorTypeEncoding") public func cylIsSelectorTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylTypeEncoding(typeEncoding, matches: ":") }
/** [EN] `SEL` ivar. [CN] `SEL` ivar。 */
@_cdecl("cyl_isSelectorIvar") public func cylIsSelectorIvar(_ ivar: OpaquePointer) -> Bool { cylIvar(ivar, matches: ":") }
