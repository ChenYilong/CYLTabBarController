//
//  UIImage+CYLUtils.h
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Implemented in Swift (`Swift/UIImage+CYLUtils.swift`, each function exported under its C name with `@_cdecl`);
 *      declared here for Objective-C callers only, and hidden from Swift (`__swift__`), which uses the Swift functions
 *      (docs/Swift-Migration.md).
 * [CN] 在 Swift 中实现（`Swift/UIImage+CYLUtils.swift`，每个函数用 `@_cdecl` 以 C 名称导出）；这里只为 Objective-C 调用方声明，
 *      并对 Swift 隐藏（`__swift__`），Swift 直接使用 Swift 函数（docs/Swift-Migration.md）。
 */
#ifndef __swift__

#pragma mark - Loading images from anywhere (issue #535)

/*!
 * FIX: issue #535
 * [EN] Inline functions (no macros, so nothing is substituted at every use) to load tab icons from wherever the app
 *      keeps them, as suggested in the issue: the asset catalog or the app's folders (`CYLImageNamed`, cached by the
 *      system), or a `.bundle` (`CYLBundleImage...`, read with `imageWithContentsOfFile:` and not cached, which is better
 *      for large or rarely used images). Pass the results as `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage`.
 *          UIImage *home = CYLBundleImage(nil, @"TabBarIcons", @"home", @"home_normal");   // TabBarIcons.bundle/home/home_normal.png
 *      `folderReferenceName`: the blue (folder reference) folder that holds the bundle, nil for a yellow group.
 *      `bundleName`: the bundle's name without ".bundle". `subfolderPath`: a path inside the bundle, nil for none.
 *      `fileName`: ".png" is added when it has no extension; "@2x"/"@3x" files are found as `imageNamed:` finds them.
 * [CN] 按 issue 的建议，用内联函数（不用宏，不会在每次使用处展开替换）从 App 存放图标的任意位置加载 Tab 图标：Asset Catalog 或 App 目录
 *      （`CYLImageNamed`，由系统缓存），或某个 `.bundle`（`CYLBundleImage...`，使用 `imageWithContentsOfFile:` 读取、不缓存，更适合
 *      较大或不常用的图片）。结果可作为 `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage` 传入。
 *      `folderReferenceName`：存放该 bundle 的蓝色文件夹（folder reference）名，黄色 group 传 nil。`bundleName`：bundle 名，不含
 *      ".bundle"。`subfolderPath`：bundle 内的路径，没有时传 nil。`fileName`：没有扩展名时自动补 ".png"；"@2x"/"@3x" 文件的查找方式与
 *      `imageNamed:` 相同。
 */

/*!
 * [EN] `+[UIImage imageNamed:]`: cached by the system. [CN] `+[UIImage imageNamed:]`：由系统缓存。
 */
FOUNDATION_EXTERN UIImage *_Nullable CYLImageNamed(NSString *_Nullable imageName);

/*!
 * [EN] The path of an image file in `bundle` (e.g. a framework's resource bundle such as `CYLResourceBundle()`, which
 *      with `use_frameworks!` is inside the framework, not in the main bundle), or nil. ".png" is added to a file name
 *      without an extension.
 * [CN] `bundle` 中图片文件的路径，没有时为 nil。`bundle` 可以是 framework 的资源包，例如 `CYLResourceBundle()`（使用 `use_frameworks!`
 *      时它位于 framework 内，而不在主 bundle 中）。没有扩展名的文件名会自动补 ".png"。
 */
FOUNDATION_EXTERN NSString *_Nullable CYLImagePathInBundle(NSBundle *_Nullable bundle, NSString *_Nullable subfolderPath, NSString *_Nullable fileName);

/*!
 * [EN] An image from `bundle`, not cached (`imageWithContentsOfFile:`). [CN] `bundle` 中的图片，不缓存（`imageWithContentsOfFile:`）。
 */
FOUNDATION_EXTERN UIImage *_Nullable CYLImageInBundle(NSBundle *_Nullable bundle, NSString *_Nullable subfolderPath, NSString *_Nullable fileName);

/*!
 * [EN] The path of an image in a bundle of the main bundle, or nil. [CN] 主 bundle 中某个 bundle 内图片的路径，没有时为 nil。
 */
FOUNDATION_EXTERN NSString *_Nullable CYLBundleImagePath(NSString *_Nullable folderReferenceName, NSString *_Nullable bundleName, NSString *_Nullable subfolderPath, NSString *_Nullable fileName);

/*!
 * [EN] An image from a bundle, not cached (`imageWithContentsOfFile:`). [CN] bundle 中的图片，不缓存（`imageWithContentsOfFile:`）。
 */
FOUNDATION_EXTERN UIImage *_Nullable CYLBundleImage(NSString *_Nullable folderReferenceName, NSString *_Nullable bundleName, NSString *_Nullable subfolderPath, NSString *_Nullable fileName);

/*!
 * [EN] The data of an image file in a bundle. [CN] bundle 中图片文件的数据。
 */
FOUNDATION_EXTERN NSData *_Nullable CYLBundleImageData(NSString *_Nullable folderReferenceName, NSString *_Nullable bundleName, NSString *_Nullable subfolderPath, NSString *_Nullable fileName);

/*!
 * [EN] An image decoded from a bundle file's data, with the scale its name gives ("@2x", "@3x"; 1 otherwise).
 * [CN] 由 bundle 中文件数据解码的图片，scale 取自文件名（"@2x"、"@3x"，否则为 1）。
 */
FOUNDATION_EXTERN UIImage *_Nullable CYLBundleImageFromData(NSString *_Nullable folderReferenceName, NSString *_Nullable bundleName, NSString *_Nullable subfolderPath, NSString *_Nullable fileName);

#endif

NS_ASSUME_NONNULL_END
