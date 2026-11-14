//
//  UIImage+CYLUtils.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] FIX: issue #535 — loading images from anywhere. Translated from Objective-C (docs/Swift-Migration.md): these were
 *      `CG_INLINE` functions in `UIImage+CYLUtils.h`; each is now exported under its C name (`@_cdecl`) for Objective-C
 *      callers, which keep the declarations in the header, and is a Swift function of the same name for Swift.
 * [CN] FIX: issue #535 —— 从任意位置加载图片。已从 Objective-C 翻译为 Swift（docs/Swift-Migration.md）：原为 `UIImage+CYLUtils.h` 中的
 *      `CG_INLINE` 函数；现在每个函数以 C 名称导出（`@_cdecl`）供 Objective-C 调用方使用（声明仍在头文件中），对 Swift 是同名 Swift 函数。
 */

/**
 * [EN] `+[UIImage imageNamed:]`, or nil for an empty name.
 * [CN] `+[UIImage imageNamed:]`，名称为空时返回 nil。
 */
public func CYLImageNamed(_ imageName: String?) -> UIImage? {
    guard let imageName, !imageName.isEmpty else {
        return nil
    }
    return UIImage(named: imageName)
}

/**
 * [EN] The path of an image file in `bundle` (in `subfolderPath` when given); `.png` is added to a name without an
 *      extension. Nil without a bundle path or a file name.
 * [CN] `bundle` 中（给出 `subfolderPath` 时在该子目录中）图片文件的路径；没有扩展名的文件名补上 `.png`。没有 bundle 路径或文件名时返回 nil。
 */
public func CYLImagePathInBundle(_ bundle: Bundle?,
                                 _ subfolderPath: String?, _ fileName: String) -> String? {
    guard let bundlePath = bundle?.bundlePath, !fileName.isEmpty else {
        return nil
    }
    var directory = bundlePath as NSString
    if let subfolderPath, !subfolderPath.isEmpty {
        directory = directory.appendingPathComponent(subfolderPath) as NSString
    }
    guard let name = imageFileName(fileName) else {
        return nil
    }
    return directory.appendingPathComponent(name)
}

/**
 * [EN] The image at `CYLImagePathInBundle()`, read from the file (not cached).
 * [CN] `CYLImagePathInBundle()` 处的图片，从文件读取（不缓存）。
 */
public func CYLImageInBundle(_ bundle: Bundle?,
                             _ subfolderPath: String?, _ fileName: String) -> UIImage? {
    CYLImagePathInBundle(bundle, subfolderPath, fileName).flatMap { UIImage(contentsOfFile: $0) }
}

/**
 * [EN] The path of an image in `<bundleName>.bundle` of the main bundle (inside the folder reference
 *      `folderReferenceName` when given, and in `subfolderPath` of the bundle when given).
 * [CN] 主 bundle 中 `<bundleName>.bundle` 里图片的路径（给出 `folderReferenceName` 时在该文件夹引用中，给出 `subfolderPath` 时在
 *      bundle 的该子目录中）。
 */
public func CYLBundleImagePath(_ folderReferenceName: String?,
                               _ bundleName: String, _ subfolderPath: String?,
                               _ fileName: String) -> String? {
    guard !bundleName.isEmpty, !fileName.isEmpty else {
        return nil
    }
    let bundlePath: String?
    if let folderReferenceName, !folderReferenceName.isEmpty {
        bundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle", inDirectory: folderReferenceName)
    } else {
        bundlePath = Bundle.main.path(forResource: bundleName, ofType: "bundle")
    }
    guard var path = bundlePath as NSString?, let name = imageFileName(fileName) else {
        return nil
    }
    if let subfolderPath, !subfolderPath.isEmpty {
        path = path.appendingPathComponent(subfolderPath) as NSString
    }
    return path.appendingPathComponent(name)
}

/**
 * [EN] The image at `CYLBundleImagePath()`, read from the file.
 * [CN] `CYLBundleImagePath()` 处的图片，从文件读取。
 */
public func CYLBundleImage(_ folderReferenceName: String?,
                           _ bundleName: String, _ subfolderPath: String?,
                           _ fileName: String) -> UIImage? {
    CYLBundleImagePath(folderReferenceName, bundleName, subfolderPath, fileName).flatMap { UIImage(contentsOfFile: $0) }
}

/**
 * [EN] The data of the file at `CYLBundleImagePath()`.
 * [CN] `CYLBundleImagePath()` 处文件的数据。
 */
public func CYLBundleImageData(_ folderReferenceName: String?,
                               _ bundleName: String, _ subfolderPath: String?,
                               _ fileName: String) -> Data? {
    CYLBundleImagePath(folderReferenceName, bundleName, subfolderPath, fileName).flatMap { FileManager.default.contents(atPath: $0) }
}

/**
 * [EN] The image made from `CYLBundleImageData()`, with the scale its name ends with (`@2x`, `@3x`, else 1).
 * [CN] 由 `CYLBundleImageData()` 生成的图片，倍率取自文件名结尾（`@2x`、`@3x`，否则为 1）。
 */
public func CYLBundleImageFromData(_ folderReferenceName: String?,
                                   _ bundleName: String, _ subfolderPath: String?,
                                   _ fileName: String) -> UIImage? {
    guard let data = CYLBundleImageData(folderReferenceName, bundleName, subfolderPath, fileName) else {
        return nil
    }
    let baseName = (fileName as NSString).deletingPathExtension
    var scale: CGFloat = 1
    if baseName.hasSuffix("@3x") {
        scale = 3
    } else if baseName.hasSuffix("@2x") {
        scale = 2
    }
    return UIImage(data: data, scale: scale)
}

// [EN] The file name with `.png` added when it has no extension. [CN] 没有扩展名时补上 `.png` 的文件名。
private func imageFileName(_ fileName: String) -> String? {
    let name = fileName as NSString
    return name.pathExtension.isEmpty ? name.appendingPathExtension("png") : fileName
}

// MARK: - The C entry points for Objective-C callers

@_cdecl("CYLImageNamed")
public func cylImageNamedEntryPoint(_ imageName: NSString?) -> UIImage? {
    CYLImageNamed(imageName as String?)
}

@_cdecl("CYLImagePathInBundle")
public func cylImagePathInBundleEntryPoint(_ bundle: Bundle?, _ subfolderPath: NSString?, _ fileName: NSString?) -> NSString? {
    CYLImagePathInBundle(bundle, subfolderPath as String?, (fileName ?? "") as String) as NSString?
}

@_cdecl("CYLImageInBundle")
public func cylImageInBundleEntryPoint(_ bundle: Bundle?, _ subfolderPath: NSString?, _ fileName: NSString?) -> UIImage? {
    CYLImageInBundle(bundle, subfolderPath as String?, (fileName ?? "") as String)
}

@_cdecl("CYLBundleImagePath")
public func cylBundleImagePathEntryPoint(_ folderReferenceName: NSString?, _ bundleName: NSString?, _ subfolderPath: NSString?,
                                 _ fileName: NSString?) -> NSString? {
    CYLBundleImagePath(folderReferenceName as String?, (bundleName ?? "") as String, subfolderPath as String?,
                       (fileName ?? "") as String) as NSString?
}

@_cdecl("CYLBundleImage")
public func cylBundleImageEntryPoint(_ folderReferenceName: NSString?, _ bundleName: NSString?, _ subfolderPath: NSString?,
                             _ fileName: NSString?) -> UIImage? {
    CYLBundleImage(folderReferenceName as String?, (bundleName ?? "") as String, subfolderPath as String?,
                   (fileName ?? "") as String)
}

@_cdecl("CYLBundleImageData")
public func cylBundleImageDataEntryPoint(_ folderReferenceName: NSString?, _ bundleName: NSString?, _ subfolderPath: NSString?,
                                 _ fileName: NSString?) -> NSData? {
    CYLBundleImageData(folderReferenceName as String?, (bundleName ?? "") as String, subfolderPath as String?,
                       (fileName ?? "") as String) as NSData?
}

@_cdecl("CYLBundleImageFromData")
public func cylBundleImageFromDataEntryPoint(_ folderReferenceName: NSString?, _ bundleName: NSString?, _ subfolderPath: NSString?,
                                     _ fileName: NSString?) -> UIImage? {
    CYLBundleImageFromData(folderReferenceName as String?, (bundleName ?? "") as String, subfolderPath as String?,
                           (fileName ?? "") as String)
}
