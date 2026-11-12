//
//  UIImage+CYLTheme.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Gives the image of a theme image for a manager, its current theme identifier and its current theme. Translated from
 *      Objective-C with the rest of the theme module (docs/Swift-Migration.md).
 * [CN] 根据管理器、其当前主题标识与当前主题给出主题图片的图片。与主题模块其他部分一起从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
public typealias CYLThemeImageProvider = (CYLThemeManager, (NSCopying & NSObjectProtocol)?, NSObject?) -> UIImage?

private final class CYLThemeImageInfo: NSObject {
    let name: String?
    let managerName: NSCopying & NSObjectProtocol
    let provider: CYLThemeImageProvider

    init(name: String?, managerName: NSCopying & NSObjectProtocol, provider: @escaping CYLThemeImageProvider) {
        self.name = name
        self.managerName = managerName
        self.provider = provider
    }
}

/**
 * [EN] Making, resolving and refreshing theme images (internal).
 * [CN] 生成、解析与刷新主题图片（内部使用）。
 */
enum CYLThemeImage {

    private static var infoKey: UInt8 = 0

    fileprivate static func info(of image: UIImage) -> CYLThemeImageInfo? {
        objc_getAssociatedObject(image, &infoKey) as? CYLThemeImageInfo
    }

    /**
     * [EN] The provider's image for the current theme of its manager; a theme image it returns is resolved too (8 levels).
     * [CN] provider 针对其管理器当前主题给出的图片；它返回的主题图片也会继续解析（最多 8 层）。
     */
    fileprivate static func resolve(_ managerName: NSCopying & NSObjectProtocol, _ provider: CYLThemeImageProvider) -> UIImage {
        let manager = CYLThemeManagerCenter.themeManager(withName: managerName)
        var image: UIImage? = provider(manager, manager.currentThemeIdentifier, manager.currentTheme)
        var depth = 0
        while depth < 8, let current = image, let nested = info(of: current) {
            let nestedManager = CYLThemeManagerCenter.themeManager(withName: nested.managerName)
            image = nested.provider(nestedManager, nestedManager.currentThemeIdentifier, nestedManager.currentTheme)
            depth += 1
        }
        return image ?? emptyImage
    }

    fileprivate static func make(_ name: String?, _ managerName: NSCopying & NSObjectProtocol,
                                 _ provider: @escaping CYLThemeImageProvider) -> UIImage {
        let resolved = resolve(managerName, provider)
        let image = resolved.withAlignmentRectInsets(resolved.alignmentRectInsets)
        let info = CYLThemeImageInfo(name: name, managerName: managerName, provider: provider)
        objc_setAssociatedObject(image, &infoKey, info, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return image
    }

    static func refreshed(_ image: UIImage) -> UIImage {
        guard let info = info(of: image) else {
            return image
        }
        return make(info.name, info.managerName, info.provider)
    }

    static func managerName(of image: UIImage) -> (NSCopying & NSObjectProtocol)? {
        info(of: image)?.managerName
    }

    // [EN] A 1×1 empty image for a provider that gives none. [CN] 当 provider 没有给出图片时使用的 1×1 空图片。
    private static let emptyImage = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1)).image { _ in
        // [EN] Nothing to draw: the image stays empty. [CN] 无需绘制：图片保持为空。
    }

    fileprivate static var defaultManagerName: NSCopying & NSObjectProtocol {
        CYLThemeManagerNameDefault as NSString
    }
}

/**
 * [EN] An image that follows a theme: its provider gives it again on every theme change. Translated from Objective-C
 *      (docs/Swift-Migration.md); Objective-C callers keep the declarations in `UIImage+CYLTheme.h`; the Swift names are
 *      the ones Clang imported.
 * [CN] 图片跟随主题：每次切换主题时由 provider 重新给出。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 调用方继续使用
 *      `UIImage+CYLTheme.h` 中的声明；Swift 名称与 Clang 原先导入的名称相同。
 */
extension UIImage {

    /**
     * [EN] A theme image of the default manager.
     * [CN] 默认管理器的主题图片。
     */
    @objc(cyl_imageWithThemeProvider:)
    public class func cyl_image(themeProvider provider: @escaping CYLThemeImageProvider) -> UIImage { // NOSONAR: kept API name
        CYLThemeImage.make(nil, CYLThemeImage.defaultManagerName, provider)
    }

    /**
     * [EN] A named theme image of the default manager.
     * [CN] 默认管理器的具名主题图片。
     */
    @objc(cyl_imageWithName:themeProvider:)
    public class func cyl_image(withName name: String?, // NOSONAR: kept API name
                                themeProvider provider: @escaping CYLThemeImageProvider) -> UIImage {
        CYLThemeImage.make(name, CYLThemeImage.defaultManagerName, provider)
    }

    /**
     * [EN] A theme image of the manager named `managerName`.
     * [CN] 名为 `managerName` 的管理器的主题图片。
     */
    @objc(cyl_imageWithThemeManagerName:provider:)
    public class func cyl_image(withThemeManagerName managerName: (NSCopying & NSObjectProtocol)?, // NOSONAR: kept API name
                                provider: @escaping CYLThemeImageProvider) -> UIImage {
        CYLThemeImage.make(nil, managerName ?? CYLThemeImage.defaultManagerName, provider)
    }

    /**
     * [EN] A named theme image of the manager named `managerName` (the default manager when nil).
     * [CN] 名为 `managerName` 的管理器（为 nil 时为默认管理器）的具名主题图片。
     */
    @objc(cyl_imageWithName:themeManagerName:provider:)
    public class func cyl_image(withName name: String?, // NOSONAR: kept API name
                                themeManagerName managerName: (NSCopying & NSObjectProtocol)?,
                                provider: @escaping CYLThemeImageProvider) -> UIImage {
        CYLThemeImage.make(name, managerName ?? CYLThemeImage.defaultManagerName, provider)
    }

    /**
     * [EN] The name given when the theme image was made.
     * [CN] 生成主题图片时给出的名称。
     */
    @objc public var cyl_themeImageName: String? {
        CYLThemeImage.info(of: self)?.name
    }

    /**
     * [EN] Whether this is a theme image.
     * [CN] 是否为主题图片。
     */
    @objc public var cyl_isThemeImage: Bool {
        CYLThemeImage.info(of: self) != nil
    }

    /**
     * [EN] The plain image the provider gives for the current theme (self when this is not a theme image).
     * [CN] provider 针对当前主题给出的普通图片（不是主题图片时返回自身）。
     */
    @objc(cyl_rawImage) public var cyl_raw: UIImage {
        guard let info = CYLThemeImage.info(of: self) else {
            return self
        }
        return CYLThemeImage.resolve(info.managerName, info.provider)
    }
}
