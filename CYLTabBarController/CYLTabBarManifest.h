//
//  CYLTabBarManifest.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYLSwiftInterface.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] `CYLTabBarManifest`, `CYLTabBarManifestLoader`, `CYLTabBarManifestLoaderDelegate` and `CYLTabBarManifestSource` are
 *      implemented in Swift (`Swift/CYLTabBarManifest.swift`); Objective-C callers get their declarations, with their
 *      documentation, from the generated Swift interface (`CYLSwiftInterface.h`) (docs/Swift-Migration.md). Compatibility
 *      note: `-tabBarControllerWithError:` returns a `UITabBarController` (always a `CYLTabBarController`); cast it.
 * [CN] `CYLTabBarManifest`、`CYLTabBarManifestLoader`、`CYLTabBarManifestLoaderDelegate` 与 `CYLTabBarManifestSource` 在 Swift 中实现
 *      （`Swift/CYLTabBarManifest.swift`）；Objective-C 调用方从 Swift 生成接口（`CYLSwiftInterface.h`）获得声明及其文档
 *      （docs/Swift-Migration.md）。兼容性说明：`-tabBarControllerWithError:` 返回 `UITabBarController`（实际总是
 *      `CYLTabBarController`），请转换类型。
 */
@class CYLTabBarManifest;

NS_ASSUME_NONNULL_END
