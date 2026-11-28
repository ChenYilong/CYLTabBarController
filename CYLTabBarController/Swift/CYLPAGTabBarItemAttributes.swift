//
//  CYLPAGTabBarItemAttributes.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] FIX: issue #604 — the tab bar's PAG helper `CYLTabBarItemsAttributesAddingPAGFiles()` (declared in
//      CYLPAGTabBarItemAnimator.h), translated from Objective-C (TabBar/CYLPAGTabBarItemAttributes.m; docs/Swift-Migration.md,
//      engine step 2). It builds on Core's `CYLTabBarItemsAttributesAddingAnimationFiles()`, so it is part of Core, and is
//      compiled only with a PAG subspec (`PAG` or `PAGEnterprise`), which sets the Swift condition `CYL_PAG_AVAILABLE` on
//      the pod: Swift cannot read the C macro of the same name.
// [CN] FIX: issue #604 — TabBar 的 PAG 工具函数 `CYLTabBarItemsAttributesAddingPAGFiles()`（声明于 CYLPAGTabBarItemAnimator.h），由
//      Objective-C 翻译而来（TabBar/CYLPAGTabBarItemAttributes.m；docs/Swift-Migration.md 引擎第 2 步）。它基于 Core 的
//      `CYLTabBarItemsAttributesAddingAnimationFiles()`，因此属于 Core，只有引入 PAG 子库（`PAG` 或 `PAGEnterprise`）时才编译：子库在 pod 上
//      设置 Swift 条件 `CYL_PAG_AVAILABLE`，因为 Swift 读不到同名 C 宏。

#if CYL_PAG_AVAILABLE
import Foundation

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if canImport(CYLBadge)
import CYLBadge
#endif
/**
 * [EN] The generic helper with "<name>.pag": the same files, under the generic keys the PAG keys stand for. A name that is
 *      not a non-empty string becomes "", which leaves its item as it is.
 * [CN] 使用「名称.pag」调用通用工具函数：文件相同，使用 PAG key 所对应的通用 key。不是非空字符串的名称变为 ""，其 item 保持不变。
 */
@_cdecl("CYLTabBarItemsAttributesAddingPAGFiles")
public func cylTabBarItemsAttributesAddingPAGFilesEntryPoint(_ attributes: NSArray, _ pagFileNames: NSArray,
                                                             _ bundle: Bundle?) -> NSArray {
    let fileNames = pagFileNames.map { name -> String in
        guard let name = name as? String, !name.isEmpty else {
            return ""
        }
        return (name as NSString).appendingPathExtension("pag") ?? ""
    }
    return cylTabBarItemsAttributesAddingAnimationFilesEntryPoint(attributes, fileNames as NSArray, bundle)
}
#endif
