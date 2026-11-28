//
//  CYLUtils.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
// [EN] D7 and D8 (docs/Animated-Item-Badge.md): CYLUtils is the bottom pod; it re-exports the lifecycle library (its only direct user) and
//      imports nothing of this repository. Core re-exports CYLAnimatedItem (`CYLTabBarControllerObjCImport.swift`).
// [CN] D7 与 D8（docs/Animated-Item-Badge.md）：CYLUtils 是最底层的 pod；它重新导出生命周期库（其唯一直接使用者），不导入本仓库的任何东西。
//      Core 重新导出 CYLAnimatedItem（`CYLTabBarControllerObjCImport.swift`）。
#if canImport(CYLDeallocBlockExecutor)
@_exported import CYLDeallocBlockExecutor
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
        liquidGlassActiveOverride ?? systemDrawsLiquidGlass
    }

    /**
     * [EN] For tests: replaces the system check of `isLiquidGlassActive()` (nil, the default, asks the system). The one copy of the rule
     *      (D2): `CYLAnimatedItemView.isLiquidGlassActive()` and `liquidGlassActiveOverride` forward here.
     * [CN] 供测试使用：替代 `isLiquidGlassActive()` 对系统的检查（默认 nil，询问系统）。规则的唯一一份（D2）：
     *      `CYLAnimatedItemView.isLiquidGlassActive()` 与 `liquidGlassActiveOverride` 转发到这里。
     */
    public nonisolated(unsafe) static var liquidGlassActiveOverride: Bool?

    private static let systemDrawsLiquidGlass: Bool = {
        if #available(iOS 27.0, *) {
            return true
        }
        if #available(iOS 26.0, *) {
            let requiresCompatibility = Bundle.main.object(forInfoDictionaryKey: "UIDesignRequiresCompatibility") as? Bool
            return !(requiresCompatibility ?? false)
        }
        return false
    }()
}

extension CYLUtils {

    /**
     * [EN] Posts a lifecycle event on `view` through CYLDeallocBlockExecutor. CYLUtils is the only layer that links the lifecycle
     *      library (D8); CYLBadge calls this instead of importing the library, which its Xcode framework target could not resolve.
     * [CN] 通过 CYLDeallocBlockExecutor 在 `view` 上发出生命周期事件。CYLUtils 是唯一链接生命周期库的层（D8）；CYLBadge 调用本方法，
     *      而不再自己导入该库（其 Xcode framework target 无法解析它）。
     */
    @nonobjc
    public class func postLifecycleEvent(_ name: String, userInfo: [String: Any]?, on view: UIView) {
        #if canImport(CYLDeallocBlockExecutor)
        view.cylPostLifecycleEvent(name, userInfo: userInfo)
        #endif
    }
}
