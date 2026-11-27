//
//  CYLConstantsFunctions+CYLDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if canImport(CYLBadge)
import CYLBadge
#endif
import ObjectiveC

// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

/**
 [EN] Deprecated: renamed to `cylGetWindowScene`.
 [CN] 已废弃：已改名为 `cylGetWindowScene`。
 */
@available(*, deprecated, renamed: "cylGetWindowScene()")
public func CYLGetWindowScene() -> UIWindowScene? { cylGetWindowScene() }

/**
 [EN] Deprecated: renamed to `cylGetRootWindow`.
 [CN] 已废弃：已改名为 `cylGetRootWindow`。
 */
@available(*, deprecated, renamed: "cylGetRootWindow()")
public func CYLGetRootWindow() -> UIWindow? { cylGetRootWindow() }

/**
 [EN] Deprecated: renamed to `cylGetRootViewController`.
 [CN] 已废弃：已改名为 `cylGetRootViewController`。
 */
@available(*, deprecated, renamed: "cylGetRootViewController()")
public func CYLGetRootViewController() -> UIViewController? { cylGetRootViewController() }

/**
 [EN] Deprecated: renamed to `cylGetTabBarFullH`.
 [CN] 已废弃：已改名为 `cylGetTabBarFullH`。
 */
@available(*, deprecated, renamed: "cylGetTabBarFullH(_:)")
public func CYLGetTabBarFullH(_ baseTabBarHeight: CGFloat) -> CGFloat { cylGetTabBarFullH(baseTabBarHeight) }

/**
 [EN] Deprecated: renamed to `cylScreenSize`.
 [CN] 已废弃：已改名为 `cylScreenSize`。
 */
@available(*, deprecated, renamed: "cylScreenSize()")
public func CYLScreenSize() -> CGSize { cylScreenSize() }

/**
 [EN] Deprecated: renamed to `cylScreenWidth`.
 [CN] 已废弃：已改名为 `cylScreenWidth`。
 */
@available(*, deprecated, renamed: "cylScreenWidth()")
public func CYLScreenWidth() -> CGFloat { cylScreenWidth() }

/**
 [EN] Deprecated: renamed to `cylScreenHeight`.
 [CN] 已废弃：已改名为 `cylScreenHeight`。
 */
@available(*, deprecated, renamed: "cylScreenHeight()")
public func CYLScreenHeight() -> CGFloat { cylScreenHeight() }

/**
 [EN] Deprecated: renamed to `cylScaleValue`.
 [CN] 已废弃：已改名为 `cylScaleValue`。
 */
@available(*, deprecated, renamed: "cylScaleValue(_:)")
public func CYLScaleValue(_ value: CGFloat) -> CGFloat { cylScaleValue(value) }

/**
 [EN] Deprecated: renamed to `cylHScaleValue`.
 [CN] 已废弃：已改名为 `cylHScaleValue`。
 */
@available(*, deprecated, renamed: "cylHScaleValue(_:)")
public func CYLHScaleValue(_ value: CGFloat) -> CGFloat { cylHScaleValue(value) }

/**
 [EN] Deprecated: renamed to `cylScaleFont`.
 [CN] 已废弃：已改名为 `cylScaleFont`。
 */
@available(*, deprecated, renamed: "cylScaleFont(_:)")
public func CYLScaleFont(_ fontSize: CGFloat) -> UIFont { cylScaleFont(fontSize) }

/**
 [EN] Deprecated: renamed to `cylScaleBoldFont`.
 [CN] 已废弃：已改名为 `cylScaleBoldFont`。
 */
@available(*, deprecated, renamed: "cylScaleBoldFont(_:)")
public func CYLScaleBoldFont(_ fontSize: CGFloat) -> UIFont { cylScaleBoldFont(fontSize) }

/**
 [EN] Deprecated: renamed to `cylStringEqual`.
 [CN] 已废弃：已改名为 `cylStringEqual`。
 */
@available(*, deprecated, renamed: "cylStringEqual(_:_:)")
public func CYLStringEqual(_ a: NSString?, _ b: NSString?) -> Bool { cylStringEqual(a, b) }

/**
 [EN] Deprecated: renamed to `cylHalfOfDiff`.
 [CN] 已废弃：已改名为 `cylHalfOfDiff`。
 */
@available(*, deprecated, renamed: "cylHalfOfDiff(_:_:)")
public func CYLHalfOfDiff(_ value1: CGFloat, _ value2: CGFloat) -> CGFloat { cylHalfOfDiff(value1, value2) }

/**
 [EN] Deprecated: renamed to `cylIsCharTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsCharTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsCharTypeEncoding(_:)")
public func cyl_isCharTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsCharTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsCharIvar`.
 [CN] 已废弃：已改名为 `cylIsCharIvar`。
 */
@available(*, deprecated, renamed: "cylIsCharIvar(_:)")
public func cyl_isCharIvar(_ ivar: OpaquePointer) -> Bool { cylIsCharIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsIntTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsIntTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsIntTypeEncoding(_:)")
public func cyl_isIntTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsIntTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsIntIvar`.
 [CN] 已废弃：已改名为 `cylIsIntIvar`。
 */
@available(*, deprecated, renamed: "cylIsIntIvar(_:)")
public func cyl_isIntIvar(_ ivar: OpaquePointer) -> Bool { cylIsIntIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsShortTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsShortTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsShortTypeEncoding(_:)")
public func cyl_isShortTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsShortTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsShortIvar`.
 [CN] 已废弃：已改名为 `cylIsShortIvar`。
 */
@available(*, deprecated, renamed: "cylIsShortIvar(_:)")
public func cyl_isShortIvar(_ ivar: OpaquePointer) -> Bool { cylIsShortIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsLongTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsLongTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsLongTypeEncoding(_:)")
public func cyl_isLongTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsLongTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsLongIvar`.
 [CN] 已废弃：已改名为 `cylIsLongIvar`。
 */
@available(*, deprecated, renamed: "cylIsLongIvar(_:)")
public func cyl_isLongIvar(_ ivar: OpaquePointer) -> Bool { cylIsLongIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsLongLongTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsLongLongTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsLongLongTypeEncoding(_:)")
public func cyl_isLongLongTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsLongLongTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsLongLongIvar`.
 [CN] 已废弃：已改名为 `cylIsLongLongIvar`。
 */
@available(*, deprecated, renamed: "cylIsLongLongIvar(_:)")
public func cyl_isLongLongIvar(_ ivar: OpaquePointer) -> Bool { cylIsLongLongIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsNSIntegerTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsNSIntegerTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsNSIntegerTypeEncoding(_:)")
public func cyl_isNSIntegerTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsNSIntegerTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsNSIntegerIvar`.
 [CN] 已废弃：已改名为 `cylIsNSIntegerIvar`。
 */
@available(*, deprecated, renamed: "cylIsNSIntegerIvar(_:)")
public func cyl_isNSIntegerIvar(_ ivar: OpaquePointer) -> Bool { cylIsNSIntegerIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsUnsignedCharTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsUnsignedCharTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsUnsignedCharTypeEncoding(_:)")
public func cyl_isUnsignedCharTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsUnsignedCharTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsUnsignedCharIvar`.
 [CN] 已废弃：已改名为 `cylIsUnsignedCharIvar`。
 */
@available(*, deprecated, renamed: "cylIsUnsignedCharIvar(_:)")
public func cyl_isUnsignedCharIvar(_ ivar: OpaquePointer) -> Bool { cylIsUnsignedCharIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsUnsignedIntTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsUnsignedIntTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsUnsignedIntTypeEncoding(_:)")
public func cyl_isUnsignedIntTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsUnsignedIntTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsUnsignedIntIvar`.
 [CN] 已废弃：已改名为 `cylIsUnsignedIntIvar`。
 */
@available(*, deprecated, renamed: "cylIsUnsignedIntIvar(_:)")
public func cyl_isUnsignedIntIvar(_ ivar: OpaquePointer) -> Bool { cylIsUnsignedIntIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsUnsignedShortTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsUnsignedShortTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsUnsignedShortTypeEncoding(_:)")
public func cyl_isUnsignedShortTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsUnsignedShortTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsUnsignedShortIvar`.
 [CN] 已废弃：已改名为 `cylIsUnsignedShortIvar`。
 */
@available(*, deprecated, renamed: "cylIsUnsignedShortIvar(_:)")
public func cyl_isUnsignedShortIvar(_ ivar: OpaquePointer) -> Bool { cylIsUnsignedShortIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsUnsignedLongTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsUnsignedLongTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsUnsignedLongTypeEncoding(_:)")
public func cyl_isUnsignedLongTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsUnsignedLongTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsUnsignedLongIvar`.
 [CN] 已废弃：已改名为 `cylIsUnsignedLongIvar`。
 */
@available(*, deprecated, renamed: "cylIsUnsignedLongIvar(_:)")
public func cyl_isUnsignedLongIvar(_ ivar: OpaquePointer) -> Bool { cylIsUnsignedLongIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsUnsignedLongLongTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsUnsignedLongLongTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsUnsignedLongLongTypeEncoding(_:)")
public func cyl_isUnsignedLongLongTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsUnsignedLongLongTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsUnsignedLongLongIvar`.
 [CN] 已废弃：已改名为 `cylIsUnsignedLongLongIvar`。
 */
@available(*, deprecated, renamed: "cylIsUnsignedLongLongIvar(_:)")
public func cyl_isUnsignedLongLongIvar(_ ivar: OpaquePointer) -> Bool { cylIsUnsignedLongLongIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsNSUIntegerTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsNSUIntegerTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsNSUIntegerTypeEncoding(_:)")
public func cyl_isNSUIntegerTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsNSUIntegerTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsNSUIntegerIvar`.
 [CN] 已废弃：已改名为 `cylIsNSUIntegerIvar`。
 */
@available(*, deprecated, renamed: "cylIsNSUIntegerIvar(_:)")
public func cyl_isNSUIntegerIvar(_ ivar: OpaquePointer) -> Bool { cylIsNSUIntegerIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsFloatTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsFloatTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsFloatTypeEncoding(_:)")
public func cyl_isFloatTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsFloatTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsFloatIvar`.
 [CN] 已废弃：已改名为 `cylIsFloatIvar`。
 */
@available(*, deprecated, renamed: "cylIsFloatIvar(_:)")
public func cyl_isFloatIvar(_ ivar: OpaquePointer) -> Bool { cylIsFloatIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsDoubleTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsDoubleTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsDoubleTypeEncoding(_:)")
public func cyl_isDoubleTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsDoubleTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsDoubleIvar`.
 [CN] 已废弃：已改名为 `cylIsDoubleIvar`。
 */
@available(*, deprecated, renamed: "cylIsDoubleIvar(_:)")
public func cyl_isDoubleIvar(_ ivar: OpaquePointer) -> Bool { cylIsDoubleIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsCGFloatTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsCGFloatTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsCGFloatTypeEncoding(_:)")
public func cyl_isCGFloatTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsCGFloatTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsCGFloatIvar`.
 [CN] 已废弃：已改名为 `cylIsCGFloatIvar`。
 */
@available(*, deprecated, renamed: "cylIsCGFloatIvar(_:)")
public func cyl_isCGFloatIvar(_ ivar: OpaquePointer) -> Bool { cylIsCGFloatIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsBOOLTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsBOOLTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsBOOLTypeEncoding(_:)")
public func cyl_isBOOLTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsBOOLTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsBOOLIvar`.
 [CN] 已废弃：已改名为 `cylIsBOOLIvar`。
 */
@available(*, deprecated, renamed: "cylIsBOOLIvar(_:)")
public func cyl_isBOOLIvar(_ ivar: OpaquePointer) -> Bool { cylIsBOOLIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsVoidTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsVoidTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsVoidTypeEncoding(_:)")
public func cyl_isVoidTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsVoidTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsVoidIvar`.
 [CN] 已废弃：已改名为 `cylIsVoidIvar`。
 */
@available(*, deprecated, renamed: "cylIsVoidIvar(_:)")
public func cyl_isVoidIvar(_ ivar: OpaquePointer) -> Bool { cylIsVoidIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsCharacterTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsCharacterTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsCharacterTypeEncoding(_:)")
public func cyl_isCharacterTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsCharacterTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsCharacterIvar`.
 [CN] 已废弃：已改名为 `cylIsCharacterIvar`。
 */
@available(*, deprecated, renamed: "cylIsCharacterIvar(_:)")
public func cyl_isCharacterIvar(_ ivar: OpaquePointer) -> Bool { cylIsCharacterIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsObjectTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsObjectTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsObjectTypeEncoding(_:)")
public func cyl_isObjectTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsObjectTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsObjectIvar`.
 [CN] 已废弃：已改名为 `cylIsObjectIvar`。
 */
@available(*, deprecated, renamed: "cylIsObjectIvar(_:)")
public func cyl_isObjectIvar(_ ivar: OpaquePointer) -> Bool { cylIsObjectIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsClassTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsClassTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsClassTypeEncoding(_:)")
public func cyl_isClassTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsClassTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsClassIvar`.
 [CN] 已废弃：已改名为 `cylIsClassIvar`。
 */
@available(*, deprecated, renamed: "cylIsClassIvar(_:)")
public func cyl_isClassIvar(_ ivar: OpaquePointer) -> Bool { cylIsClassIvar(ivar) }

/**
 [EN] Deprecated: renamed to `cylIsSelectorTypeEncoding`.
 [CN] 已废弃：已改名为 `cylIsSelectorTypeEncoding`。
 */
@available(*, deprecated, renamed: "cylIsSelectorTypeEncoding(_:)")
public func cyl_isSelectorTypeEncoding(_ typeEncoding: UnsafePointer<CChar>?) -> Bool { cylIsSelectorTypeEncoding(typeEncoding) }

/**
 [EN] Deprecated: renamed to `cylIsSelectorIvar`.
 [CN] 已废弃：已改名为 `cylIsSelectorIvar`。
 */
@available(*, deprecated, renamed: "cylIsSelectorIvar(_:)")
public func cyl_isSelectorIvar(_ ivar: OpaquePointer) -> Bool { cylIsSelectorIvar(ivar) }
