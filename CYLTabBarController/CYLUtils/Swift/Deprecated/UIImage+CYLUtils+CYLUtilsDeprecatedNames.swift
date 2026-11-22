//
//  UIImage+CYLUtils+CYLUtilsDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

/**
 [EN] Deprecated: renamed to `cylImageNamed`.
 [CN] 已废弃：已改名为 `cylImageNamed`。
 */
@available(*, deprecated, renamed: "cylImageNamed(_:)")
public func CYLImageNamed(_ imageName: String?) -> UIImage? { cylImageNamed(imageName) }

/**
 [EN] Deprecated: renamed to `cylImagePathInBundle`.
 [CN] 已废弃：已改名为 `cylImagePathInBundle`。
 */
@available(*, deprecated, renamed: "cylImagePathInBundle(_:_:_:)")
public func CYLImagePathInBundle(_ bundle: Bundle?, _ subfolderPath: String?, _ fileName: String) -> String? { cylImagePathInBundle(bundle, subfolderPath, fileName) }

/**
 [EN] Deprecated: renamed to `cylImageInBundle`.
 [CN] 已废弃：已改名为 `cylImageInBundle`。
 */
@available(*, deprecated, renamed: "cylImageInBundle(_:_:_:)")
public func CYLImageInBundle(_ bundle: Bundle?, _ subfolderPath: String?, _ fileName: String) -> UIImage? { cylImageInBundle(bundle, subfolderPath, fileName) }

/**
 [EN] Deprecated: renamed to `cylBundleImagePath`.
 [CN] 已废弃：已改名为 `cylBundleImagePath`。
 */
@available(*, deprecated, renamed: "cylBundleImagePath(_:_:_:_:)")
public func CYLBundleImagePath(_ folderReferenceName: String?, _ bundleName: String, _ subfolderPath: String?, _ fileName: String) -> String? { cylBundleImagePath(folderReferenceName, bundleName, subfolderPath, fileName) }

/**
 [EN] Deprecated: renamed to `cylBundleImage`.
 [CN] 已废弃：已改名为 `cylBundleImage`。
 */
@available(*, deprecated, renamed: "cylBundleImage(_:_:_:_:)")
public func CYLBundleImage(_ folderReferenceName: String?, _ bundleName: String, _ subfolderPath: String?, _ fileName: String) -> UIImage? { cylBundleImage(folderReferenceName, bundleName, subfolderPath, fileName) }

/**
 [EN] Deprecated: renamed to `cylBundleImageData`.
 [CN] 已废弃：已改名为 `cylBundleImageData`。
 */
@available(*, deprecated, renamed: "cylBundleImageData(_:_:_:_:)")
public func CYLBundleImageData(_ folderReferenceName: String?, _ bundleName: String, _ subfolderPath: String?, _ fileName: String) -> Data? { cylBundleImageData(folderReferenceName, bundleName, subfolderPath, fileName) }

/**
 [EN] Deprecated: renamed to `cylBundleImageFromData`.
 [CN] 已废弃：已改名为 `cylBundleImageFromData`。
 */
@available(*, deprecated, renamed: "cylBundleImageFromData(_:_:_:_:)")
public func CYLBundleImageFromData(_ folderReferenceName: String?, _ bundleName: String, _ subfolderPath: String?, _ fileName: String) -> UIImage? { cylBundleImageFromData(folderReferenceName, bundleName, subfolderPath, fileName) }
