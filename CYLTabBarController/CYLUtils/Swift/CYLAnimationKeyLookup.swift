//
//  CYLAnimationKeyLookup.swift
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

// [EN] The lookup of the animation keys (CYLAnimationKeys.h), Swift since docs/Swift-Migration.md step 122 (phase ③, group J of
//      docs/Swift-Migration-Phase3.md). Part of the CYLAnimatedItem component (its pod, its Xcode target, the SwiftPM target
//      `CYLAnimatedItemSwift`), never of CYLTabBarController's CYLUtils, so each C symbol is defined once. The keys are written
//      as strings here (each key equals its name): referring to the constants would raise their per-engine warnings
//      (`CYL_PAG_REQUIRED` …) in Swift, where they cannot be silenced. The constants, `CYLAnimationTypeIsAvailable()` and
//      `CYLAnimationWarnMissingEngine()` stay in CYLAnimationKeys.m: they need the `__has_include` engine switches.
// [CN] 动画 key（CYLAnimationKeys.h）的查找，自第 122 步（第 ③ 阶段 J 组）起为 Swift。属于 CYLAnimatedItem 组件（其 pod、Xcode target、
//      SwiftPM target `CYLAnimatedItemSwift`），不属于 CYLTabBarController 的 CYLUtils，因此每个 C 符号只定义一次。这里以字符串写出 key（每个 key 等于其
//      名称）：引用常量会在 Swift 中触发各引擎的警告（`CYL_PAG_REQUIRED` 等），且无法屏蔽。常量、`CYLAnimationTypeIsAvailable()` 与
//      `CYLAnimationWarnMissingEngine()` 留在 CYLAnimationKeys.m：它们需要 `__has_include` 引擎开关。

/// [EN] One animation type: its name, file extensions, subspec and the type-specific key of each generic key.
/// [CN] 一种动画类型：名称、文件扩展名、子库以及每个通用 key 对应的类型专用 key。
private struct CYLAnimationTypeEntry {
    let type: String
    let extensions: [String]
    let pod: String
    let keys: [String: String]
}

/// [EN] The generic keys (`CYLTabBarAnimationURL` …), in the order of the table. [CN] 通用 key（`CYLTabBarAnimationURL` 等）。
private let CYLAnimationGenericKeys = ["CYLTabBarAnimationURL", "CYLTabBarAnimationFilePath", "CYLTabBarAnimationSize",
                                       "CYLTabBarAnimationDarkURL", "CYLTabBarAnimationDarkFilePath", "CYLTabBarAnimationDarkColors"]

/// [EN] The type-specific keys of `prefix` ("Lottie" → `CYLTabBarLottieURL` …); `darkColors` says whether it has one.
/// [CN] `prefix` 的类型专用 key（"Lottie" → `CYLTabBarLottieURL` 等）；`darkColors` 表示是否有深色配色 key。
private func CYLAnimationKeys(_ prefix: String, darkColors: Bool) -> [String: String] {
    let suffixes = ["URL", "FilePath", "Size", "DarkURL", "DarkFilePath", "DarkColors"]
    var keys: [String: String] = [:]
    for (generic, suffix) in zip(CYLAnimationGenericKeys, suffixes) where darkColors || suffix != "DarkColors" {
        keys[generic] = "CYLTabBar\(prefix)\(suffix)"
    }
    return keys
}

private let CYLAnimationTypeTable: [CYLAnimationTypeEntry] = [
    CYLAnimationTypeEntry(type: "Lottie", extensions: ["json", "lottie"], pod: "LottieSwift", keys: CYLAnimationKeys("Lottie", darkColors: true)),
    CYLAnimationTypeEntry(type: "PAG", extensions: ["pag"], pod: "PAG", keys: CYLAnimationKeys("PAG", darkColors: false)),
    CYLAnimationTypeEntry(type: "Rive", extensions: ["riv"], pod: "Rive", keys: CYLAnimationKeys("Rive", darkColors: true)),
    CYLAnimationTypeEntry(type: "SVGA", extensions: ["svga"], pod: "SVGA", keys: CYLAnimationKeys("SVGA", darkColors: false)),
    CYLAnimationTypeEntry(type: "GIF", extensions: ["gif"], pod: "GIF", keys: CYLAnimationKeys("GIF", darkColors: false)),
]

/**
 [EN] The value of a generic key in `attributes`: the generic key first, then the type-specific keys of every type.
 [CN] `attributes` 中通用 key 的值：先取通用 key，再依次取每种类型的专用 key。
 */
@_cdecl("CYLAnimationAttributesValue")
public func CYLAnimationAttributesValueEntryPoint(_ attributes: NSDictionary?, _ genericKey: NSString) -> Any? {
    guard let attributes, genericKey.length > 0 else { return nil }
    if let value = attributes[genericKey] {
        return value
    }
    for entry in CYLAnimationTypeTable {
        if let key = entry.keys[genericKey as String], let value = attributes[key] {
            return value
        }
    }
    return nil
}

/**
 [EN] The animation type of a tab: the type whose keys `attributes` use, else the type of the file's extension.
 [CN] Tab 的动画类型：`attributes` 使用了哪种类型的 key 即为该类型，否则按文件扩展名判断。
 */
@_cdecl("CYLAnimationTypeOfFile")
public func CYLAnimationTypeOfFileEntryPoint(_ attributes: NSDictionary?, _ fileURL: NSURL?) -> NSString? {
    if let attributes {
        for entry in CYLAnimationTypeTable where entry.keys.values.contains(where: { attributes[$0] != nil }) {
            return entry.type as NSString
        }
    }
    let fileExtension = (fileURL?.path as NSString?)?.pathExtension.lowercased() ?? ""
    guard !fileExtension.isEmpty else { return nil }
    return CYLAnimationTypeTable.first { $0.extensions.contains(fileExtension) }?.type as NSString?
}

/**
 [EN] The names of the known animation types. [CN] 已知动画类型的名称。
 */
@_cdecl("CYLAnimationKnownTypes")
public func CYLAnimationKnownTypesEntryPoint() -> NSArray {
    CYLAnimationTypeTable.map { $0.type } as NSArray
}

/**
 [EN] The subspec that brings a type's engine ("Lottie" → "LottieSwift"). [CN] 提供某类型引擎的子库（"Lottie" → "LottieSwift"）。
 */
@_cdecl("CYLAnimationSubspecOfType")
public func CYLAnimationSubspecOfTypeEntryPoint(_ type: NSString?) -> NSString? {
    guard let type, type.length > 0 else { return nil }
    return CYLAnimationTypeTable.first { $0.type == type as String }?.pod as NSString?
}

/**
 [EN] The file extensions of a type. [CN] 某类型的文件扩展名。
 */
@_cdecl("CYLAnimationFileExtensionsOfType")
public func CYLAnimationFileExtensionsOfTypeEntryPoint(_ type: NSString?) -> NSArray {
    guard let type, type.length > 0 else { return [] as NSArray }
    return (CYLAnimationTypeTable.first { $0.type == type as String }?.extensions ?? []) as NSArray
}
