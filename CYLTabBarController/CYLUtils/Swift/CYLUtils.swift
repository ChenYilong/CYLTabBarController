//
//  CYLUtils.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

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
        isLiquidGlassActiveOnce
    }

    private static let isLiquidGlassActiveOnce: Bool = {
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
