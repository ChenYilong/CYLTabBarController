//
//  UIImage+CYLDeprecatedNames.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import ImageIO
import CryptoKit

// [EN] Deprecated Swift names, kept for source compatibility: each forwards to its lowerCamelCase replacement (the
//      Objective-C selectors never changed). Removed at the next major version; SonarCloud skips this folder
//      (.sonarcloud.properties, docs/Swift-Coding-Style.md).
// [CN] 已废弃的 Swift 名称，为保持源码兼容而保留：每个名称都转发到其 lowerCamelCase 的新名称（Objective-C 的 selector
//      从未改变）。下一个主版本移除；SonarCloud 不分析此文件夹（.sonarcloud.properties、docs/Swift-Coding-Style.md）。

extension UIImage {
    /**
     [EN] Deprecated: renamed to `cylLoad`.
     [CN] 已废弃：已改名为 `cylLoad`。
     */
    @available(*, deprecated, renamed: "cylLoad(with:completion:)")
    @nonobjc
    public class func cyl_load(with url: URL?, completion: @escaping (UIImage?) -> Void) { Self.cylLoad(with: url, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylLoad`.
     [CN] 已废弃：已改名为 `cylLoad`。
     */
    @available(*, deprecated, renamed: "cylLoad(with:options:completion:)")
    @nonobjc
    public class func cyl_load(with url: URL?, options: CYLImageLoadOptions, completion: @escaping (UIImage?) -> Void) { Self.cylLoad(with: url, options: options, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylLoad`.
     [CN] 已废弃：已改名为 `cylLoad`。
     */
    @available(*, deprecated, renamed: "cylLoad(with:rawOptions:completion:)")
    @nonobjc
    public class func cyl_load(with url: URL?, rawOptions: UInt, completion: @escaping (UIImage?) -> Void) { Self.cylLoad(with: url, rawOptions: rawOptions, completion: completion) }

    /**
     [EN] Deprecated: renamed to `cylGIFFrameDelay`.
     [CN] 已废弃：已改名为 `cylGIFFrameDelay`。
     */
    @available(*, deprecated, renamed: "cylGIFFrameDelay(withProperties:)")
    @nonobjc
    public class func cyl_GIFFrameDelay(withProperties properties: [AnyHashable: Any]) -> TimeInterval { Self.cylGIFFrameDelay(withProperties: properties) }

    /**
     [EN] Deprecated: renamed to `cylAnimatedImage`.
     [CN] 已废弃：已改名为 `cylAnimatedImage`。
     */
    @available(*, deprecated, renamed: "cylAnimatedImage(withGIFData:)")
    @nonobjc
    public class func cyl_animatedImage(withGIFData data: Data) -> UIImage? { Self.cylAnimatedImage(withGIFData: data) }

    /**
     [EN] Deprecated: renamed to `cylImage`.
     [CN] 已废弃：已改名为 `cylImage`。
     */
    @available(*, deprecated, renamed: "cylImage(with:size:)")
    @nonobjc
    public class func cyl_image(with color: UIColor?, size: CGSize) -> UIImage? { Self.cylImage(with: color, size: size) }

    /**
     [EN] Deprecated: renamed to `cylImage`.
     [CN] 已废弃：已改名为 `cylImage`。
     */
    @available(*, deprecated, renamed: "cylImage(with:size:cornerRadius:)")
    @nonobjc
    public class func cyl_image(with color: UIColor?, size: CGSize, cornerRadius: CGFloat) -> UIImage? { Self.cylImage(with: color, size: size, cornerRadius: cornerRadius) }

    /**
     [EN] Deprecated: renamed to `cylImage`.
     [CN] 已废弃：已改名为 `cylImage`。
     */
    @available(*, deprecated, renamed: "cylImage(withLight:dark:)")
    @nonobjc
    public class func cyl_image(withLight lightImage: UIImage?, dark darkImage: UIImage?) -> UIImage? { Self.cylImage(withLight: lightImage, dark: darkImage) }

    /**
     [EN] Deprecated: renamed to `cylImage`.
     [CN] 已废弃：已改名为 `cylImage`。
     */
    @available(*, deprecated, renamed: "cylImage(withImageInfo:darkImageInfo:)")
    @nonobjc
    public class func cyl_image(withImageInfo imageInfo: Any?, darkImageInfo: Any?) -> UIImage? { Self.cylImage(withImageInfo: imageInfo, darkImageInfo: darkImageInfo) }

    /**
     [EN] Deprecated: renamed to `cylLightOrDarkModeImage`.
     [CN] 已废弃：已改名为 `cylLightOrDarkModeImage`。
     */
    @available(*, deprecated, renamed: "cylLightOrDarkModeImage(withLightImage:darkImage:)")
    @nonobjc
    public class func cyl_lightOrDarkModeImage(withLightImage lightImage: UIImage?, darkImage: UIImage?) -> UIImage? { Self.cylLightOrDarkModeImage(withLightImage: lightImage, darkImage: darkImage) }

    /**
     [EN] Deprecated: renamed to `cylLightOrDarkModeImage`.
     [CN] 已废弃：已改名为 `cylLightOrDarkModeImage`。
     */
    @available(*, deprecated, renamed: "cylLightOrDarkModeImage(withOwner:lightImage:darkImage:)")
    @nonobjc
    public class func cyl_lightOrDarkModeImage(withOwner owner: UITraitEnvironment?, lightImage: UIImage?, darkImage: UIImage?) -> UIImage? { Self.cylLightOrDarkModeImage(withOwner: owner, lightImage: lightImage, darkImage: darkImage) }

    /**
     [EN] Deprecated: renamed to `cylLightOrDarkModeImage`.
     [CN] 已废弃：已改名为 `cylLightOrDarkModeImage`。
     */
    @available(*, deprecated, renamed: "cylLightOrDarkModeImage(withOwner:lightImageName:darkImageName:)")
    @nonobjc
    public class func cyl_lightOrDarkModeImage(withOwner owner: UITraitEnvironment?, lightImageName: String, darkImageName: String?) -> UIImage? { Self.cylLightOrDarkModeImage(withOwner: owner, lightImageName: lightImageName, darkImageName: darkImageName) }

    /**
     [EN] Deprecated: renamed to `cylAssetImageName`.
     [CN] 已废弃：已改名为 `cylAssetImageName`。
     */
    @available(*, deprecated, renamed: "cylAssetImageName(_:userInterfaceStyle:)")
    @nonobjc
    public class func cyl_assetImageName(_ assetImageName: String, userInterfaceStyle: Int) -> UIImage? { Self.cylAssetImageName(assetImageName, userInterfaceStyle: userInterfaceStyle) }

    /**
     [EN] Deprecated: renamed to `cylImageNamed`.
     [CN] 已废弃：已改名为 `cylImageNamed`。
     */
    @available(*, deprecated, renamed: "cylImageNamed(_:)")
    @nonobjc
    public class func cyl_imageNamed(_ imageInfo: Any?) -> UIImage! { Self.cylImageNamed(imageInfo) }

    /**
     [EN] Deprecated: renamed to `cylGetImage`.
     [CN] 已废弃：已改名为 `cylGetImage`。
     */
    @available(*, deprecated, renamed: "cylGetImage(fromImageInfo:)")
    @nonobjc
    public class func cyl_getImage(fromImageInfo imageInfo: Any) -> UIImage? { Self.cylGetImage(fromImageInfo: imageInfo) }

    /**
     [EN] Deprecated: renamed to `cylTabItemPlaceholder`.
     [CN] 已废弃：已改名为 `cylTabItemPlaceholder`。
     */
    @available(*, deprecated, renamed: "cylTabItemPlaceholder()")
    @nonobjc
    public class func cyl_tabItemPlaceholder() -> UIImage { Self.cylTabItemPlaceholder() }
}
