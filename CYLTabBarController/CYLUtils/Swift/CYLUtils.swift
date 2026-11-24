//
//  CYLUtils.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
// [EN] CocoaPods: the animated item component is its own pod and module, CYLAnimatedItem; re-exported so that
//      `import CYLTabBarController` keeps giving its keys and classes to Swift callers.
// [CN] CocoaPods：动效组件是独立的 pod 与模块 CYLAnimatedItem；在此重新导出，使 `import CYLTabBarController` 仍向 Swift 调用方提供其 key 与类。
#if canImport(CYLAnimatedItem)
@_exported import CYLAnimatedItem
#endif
// [EN] The Liquid Glass rule lives in CYLAnimatedItemView (`isLiquidGlassActive()`); `isLiquidGlassActive()` below forwards to it.
// [CN] 液态玻璃的判断规则在 CYLAnimatedItemView 中（`isLiquidGlassActive()`）；下面的 `isLiquidGlassActive()` 转发到它。
#if canImport(CYLAnimatedItemViews)
import CYLAnimatedItemViews
#endif

/**
 * [EN] Shared helpers of the CYLUtils subspec. Translated from Objective-C (docs/Swift-Migration.md); Objective-C
 *      callers keep the declaration in `CYLUtils.h`.
 * [CN] CYLUtils 子库的共用辅助方法。已从 Objective-C 翻译为 Swift（docs/Swift-Migration.md）；Objective-C 调用方继续使用
 *      `CYLUtils.h` 中的声明。
 */
@objc(CYLUtils)
public class CYLUtils: NSObject {

    /**
     * [EN] Whether Liquid Glass is in use: iOS 27 and later always; iOS 26 unless the app sets
     *      `UIDesignRequiresCompatibility` in its Info.plist. Read once.
     * [CN] 是否使用液态玻璃：iOS 27 及以上总是；iOS 26 上 App 未在 Info.plist 中设置 `UIDesignRequiresCompatibility` 时。只读取一次。
     */
    @objc public class func isLiquidGlassActive() -> Bool {
        CYLAnimatedItemView.isLiquidGlassActive()
    }
}
