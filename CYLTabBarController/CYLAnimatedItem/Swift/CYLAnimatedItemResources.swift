//
//  CYLAnimatedItemResources.swift
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] `CYLAnimatedItemResourceBundle()` (declared in CYLAnimatedItemMacros.h), translated from Objective-C
//      (CYLAnimatedItemResources.m; docs/Swift-Migration.md, engine step 3). Same C symbol, so Objective-C callers keep it.
// [CN] `CYLAnimatedItemResourceBundle()`（声明于 CYLAnimatedItemMacros.h），由 Objective-C 翻译而来（CYLAnimatedItemResources.m；
//      docs/Swift-Migration.md 引擎第 3 步）。C 符号不变，Objective-C 调用方照常使用。

import UIKit

/**
 * [EN] Looks for `CYLAnimatedItem.bundle` where each package manager puts it: next to the component's code (CocoaPods, a
 *      framework), in the app, and inside Swift Package Manager's resource bundle of the CYLAnimatedItemSwift target (before
 *      2026-11-17 the bundle was in CYLTabBarControllerSwift's). Looked up once.
 * [CN] 在各包管理器放置的位置查找 `CYLAnimatedItem.bundle`：组件代码旁（CocoaPods、framework）、App 内，以及 Swift Package Manager 中
 *      CYLAnimatedItemSwift target 的资源包内（2026-11-17 之前在 CYLTabBarControllerSwift 的资源包中）。只查找一次。
 */
private let cylAnimatedItemResourceBundle: Bundle? = {
    var containers = [Bundle(for: CYLAnimatedItemView.self), Bundle.main]
    for packageName in ["CYLTabBarController_CYLAnimatedItemSwift", "CYLTabBarController_CYLTabBarControllerSwift"] {
        if let path = Bundle.main.path(forResource: packageName, ofType: "bundle"), let package = Bundle(path: path) {
            containers.append(package)
        }
    }
    return containers.lazy.compactMap { $0.path(forResource: "CYLAnimatedItem", ofType: "bundle") }.first.flatMap(Bundle.init(path:))
}()

/**
 * [EN] The component's resource bundle (placeholder image, LICENSE), or nil when the app does not ship it.
 * [CN] 组件的资源包（占位图、LICENSE）；App 未包含时为 nil。
 */
@_cdecl("CYLAnimatedItemResourceBundle")
public func cylAnimatedItemResourceBundleEntryPoint() -> Bundle? {
    cylAnimatedItemResourceBundle
}
