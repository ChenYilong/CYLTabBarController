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

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
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

/**
 * [EN] The animation engines as a whole. `resourceMissingListener` is called on the main queue when an animation file
 *      cannot be shown, with the file name or path as configured and a short reason: "not found", "unreadable",
 *      "decode failed" or "engine library missing". Once per resource per view; it is the signal of
 *      `CYLAnimatedItemView.onResourceMissing` for a host with no view reference (CYLPlaceholder's status bar). Nothing else
 *      changes: the item shows its static image or the placeholder. Android: `CYLAnimationEngines.resourceMissingListener`.
 * [CN] 动画引擎的整体入口。动画文件无法显示时在主队列调用 `resourceMissingListener`，参数为按配置给出的文件名或路径与简短原因：
 *      "not found"、"unreadable"、"decode failed"、"engine library missing"。每个视图每个资源一次；与
 *      `CYLAnimatedItemView.onResourceMissing` 是同一信号，供没有视图引用的宿主使用（CYLPlaceholder 状态栏）。其他行为不变：条目显示
 *      静态图片或占位图。
 */
@objc(CYLAnimationEngines)
public final class CYLAnimationEngines: NSObject {
    /** [EN] See the type's comment. [CN] 见类型说明。 */
    @objc public static var resourceMissingListener: ((String, String) -> Void)?

    /** [EN] The four reasons, the same strings on every platform. [CN] 四种原因，各平台字符串相同。 */
    static let reasonNotFound = "not found"
    static let reasonUnreadable = "unreadable"
    static let reasonDecodeFailed = "decode failed"
    static let reasonEngineLibraryMissing = "engine library missing"

    /** [EN] The reason a failure reports: from the error when there is one. [CN] 失败的原因：有错误时由错误决定。 */
    static func reason(for error: Error?, remote: Bool) -> String {
        guard let error = error as NSError? else { return remote ? reasonNotFound : reasonDecodeFailed }
        switch (error.domain, error.code) {
        case (NSCocoaErrorDomain, NSFileNoSuchFileError), (NSCocoaErrorDomain, NSFileReadNoSuchFileError),
             (NSURLErrorDomain, NSURLErrorFileDoesNotExist), (NSURLErrorDomain, NSURLErrorBadURL), (NSURLErrorDomain, NSURLErrorUnsupportedURL),
             (NSURLErrorDomain, NSURLErrorCannotFindHost), (NSURLErrorDomain, NSURLErrorResourceUnavailable):
            return reasonNotFound
        case (NSCocoaErrorDomain, NSFileReadNoPermissionError), (NSCocoaErrorDomain, NSFileReadUnknownError),
             (NSURLErrorDomain, NSURLErrorNoPermissionsToReadFile), (NSURLErrorDomain, NSURLErrorFileIsDirectory):
            return reasonUnreadable
        default:
            return remote && error.domain == NSURLErrorDomain ? reasonNotFound : reasonDecodeFailed
        }
    }
}
