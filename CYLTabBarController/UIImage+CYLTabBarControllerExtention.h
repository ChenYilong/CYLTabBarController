//
//  UIImage+CYLTabBarControllerExtention.h
//  CYLTabBarController
//
//  Created by chenyilong on 18/4/2026.
//  Copyright © 2026 微博@iOS程序犭袁. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLSwiftInterface.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] `CYLImageCache`, `CYLImageCacheExpireType` and `UIImage (CYLTabBarControllerExtention)` are implemented in Swift
 *      (`Swift/UIImage+CYLTabBarControllerExtention.swift`); Objective-C callers get their declarations, with their
 *      documentation, from the generated Swift interface (`CYLSwiftInterface.h`) (docs/Swift-Migration.md).
 *      `CYLImageLoadOptions` stays here for Objective-C (an option set cannot be exported from Swift): Swift has its own
 *      `CYLImageLoadOptions` with the same values, and `+cyl_loadImageWithURL:options:completion:` takes the raw value.
 * [CN] `CYLImageCache`、`CYLImageCacheExpireType` 与 `UIImage (CYLTabBarControllerExtention)` 在 Swift 中实现
 *      （`Swift/UIImage+CYLTabBarControllerExtention.swift`）；Objective-C 调用方从 Swift 生成接口（`CYLSwiftInterface.h`）获得声明及其
 *      文档（docs/Swift-Migration.md）。`CYLImageLoadOptions` 为 Objective-C 保留在这里（选项集合无法从 Swift 导出）：Swift 有取值相同的
 *      `CYLImageLoadOptions`，`+cyl_loadImageWithURL:options:completion:` 接收其原始值。
 */
#ifndef __swift__
/*!
 * [EN] Options for `+cyl_loadImageWithURL:options:completion:`.
 * [CN] `+cyl_loadImageWithURL:options:completion:` 的选项。
 */
typedef NS_OPTIONS(NSUInteger, CYLImageLoadOptions) {
    /*!
     * [EN] Memory, then disk, then the network; the image is stored as `CYLImageCache` allows. [CN] 内存、磁盘、网络依次查找；按 `CYLImageCache` 设置缓存。
     */
    CYLImageLoadOptionsDefault = 0,
    /*!
     * [EN] Downloads again, ignoring the cached image, and stores the new one: for a URL whose image changes. [CN] 忽略缓存重新下载并缓存新图片：用于图片会变化的 URL。
     */
    CYLImageLoadOptionsRefreshCached = 1 << 0,
    /*!
     * [EN] Only from the caches, never downloads: nil when not cached. [CN] 只从缓存读取，不下载：未缓存时为 nil。
     */
    CYLImageLoadOptionsFromCacheOnly = 1 << 1,
    /*!
     * [EN] Keeps the image in memory only, not on disk. [CN] 只缓存在内存，不写入磁盘。
     */
    CYLImageLoadOptionsMemoryCacheOnly = 1 << 2,
    /*!
     * [EN] Does not keep the image in memory (the disk cache still applies). [CN] 不缓存在内存（磁盘缓存仍然有效）。
     */
    CYLImageLoadOptionsAvoidMemoryCache = 1 << 3,
};
#endif

NS_ASSUME_NONNULL_END
