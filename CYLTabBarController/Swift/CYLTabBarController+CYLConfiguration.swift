//
//  CYLTabBarController+CYLConfiguration.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
#if canImport(CYLAnimatedItem)
import CYLAnimatedItem
#endif

// [EN] Configuration dictionaries (`CYLTabBarController (CYLConfiguration)`), translated from Objective-C (docs/Swift-Migration.md,
//      step 44): value conversion, skins, localization, routes, files and URLs. Every selector of the header is kept.
//      `CYLTabBarConfigurationTheme` and the initializers stay in CYLTabBarController+CYLConfiguration.m: a Swift initializer
//      cannot build the subclass a class method is called on, and the theme's protocol names the Objective-C class.
// [CN] 配置字典（`CYLTabBarController (CYLConfiguration)`），已从 Objective-C 翻译（docs/Swift-Migration.md，第 44 步）：值转换、皮肤、
//      本地化、路由、文件与 URL。头文件中的选择器全部保留。`CYLTabBarConfigurationTheme` 与初始化方法留在
//      CYLTabBarController+CYLConfiguration.m：Swift 初始化方法无法创建类方法所在的子类，且主题协议引用了 Objective-C 类。

/**
 * [EN] The class factory of `CYLTabBarConfigurationTheme`, implemented in CYLTabBarController+CYLConfiguration.m.
 * [CN] `CYLTabBarConfigurationTheme` 的类工厂方法，实现见 CYLTabBarController+CYLConfiguration.m。
 */
@objc protocol CYLTabBarConfigurationThemeFactory {
    @objc(cyl_themeWithIdentifier:values:references:)
    func cylTheme(identifier: String, values: [String: Any], references: NSDictionary) -> NSObject
}

/**
 * [EN] The keys and the value conversion of configuration dictionaries.
 * [CN] 配置字典的键与值转换。
 */
enum CYLConfigurationValues {

    // MARK: Keys

    /** [EN] Private: marks a left-out tab; the same key as in CYLTabBarController.m. [CN] 私有：标记被排除的 Tab；与 CYLTabBarController.m 中的键相同。 */
    static let excludedKey = "_CYLTabBarItemExcluded"
    /** [EN] Private: the reason of a left-out tab (English). [CN] 私有：被排除的 Tab 的原因（英文）。 */
    static let exclusionReasonKey = "_CYLTabBarItemExclusionReason"
    /** [EN] Private: the PlusButton slot's entry (#774). [CN] 私有：PlusButton slot 的一项（#774）。 */
    static let plusSlotPlaceholderKey = "CYLTabBarItemPlusSlotPlaceholder"
    /** [EN] Private: the skins of a normalized configuration. [CN] 私有：规范化配置中的皮肤。 */
    static let themesKey = "_CYLTabBarControllerConfigurationThemes"
    static let themesListKey = "themes"
    static let themesBaseKey = "base"
    static let themesDarkKey = "dark"
    static let themesInitialKey = "initial"
    static let themesManagerKey = "manager"
    /** [EN] Private: the folder of the configuration file, set by the file loader. [CN] 私有：配置文件所在目录，由文件加载方法设置。 */
    static let fileDirectoryKey = "_CYLTabBarControllerConfigurationFileDirectory"

    // [EN] The keys of the Lottie, PAG, Rive and GIF subspecs by name (#605, B29): a configuration may name them in any build.
    // [CN] Lottie、PAG、Rive 与 GIF 子库的键按名称引用（#605、B29）：配置在任何构建中都可以写这些键。
    static let pagURL = "CYLTabBarPAGURL"
    static let pagFilePath = "CYLTabBarPAGFilePath"
    static let pagSize = "CYLTabBarPAGSize"
    static let pagDarkURL = "CYLTabBarPAGDarkURL"
    static let pagDarkFilePath = "CYLTabBarPAGDarkFilePath"
    static let riveURL = "CYLTabBarRiveURL"
    static let riveFilePath = "CYLTabBarRiveFilePath"
    static let riveSize = "CYLTabBarRiveSize"
    static let riveDarkURL = "CYLTabBarRiveDarkURL"
    static let riveDarkFilePath = "CYLTabBarRiveDarkFilePath"
    static let riveDarkColors = "CYLTabBarRiveDarkColors"
    static let gifURL = "CYLTabBarGIFURL"
    static let gifFilePath = "CYLTabBarGIFFilePath"
    static let gifSize = "CYLTabBarGIFSize"
    static let gifDarkURL = "CYLTabBarGIFDarkURL"
    static let gifDarkFilePath = "CYLTabBarGIFDarkFilePath"
    // FIX: issue #415 — SVGA. [CN] SVGA。
    static let svgaURL = "CYLTabBarSVGAURL"
    static let svgaFilePath = "CYLTabBarSVGAFilePath"
    static let svgaSize = "CYLTabBarSVGASize"
    static let svgaDarkURL = "CYLTabBarSVGADarkURL"
    static let svgaDarkFilePath = "CYLTabBarSVGADarkFilePath"
    static let lottieURL = "CYLTabBarLottieURL"
    static let lottieFilePath = "CYLTabBarLottieFilePath"
    static let lottieSize = "CYLTabBarLottieSize"
    static let lottieDarkURL = "CYLTabBarLottieDarkURL"
    static let lottieDarkFilePath = "CYLTabBarLottieDarkFilePath"
    static let lottieDarkColors = "CYLTabBarLottieDarkColors"
    static let lottieLoopsWhenUnselected = "CYLTabBarLottieLoopsWhenUnselected"

    /**
     * [EN] Insets, offsets and sizes must be finite and at most 1000 in magnitude (B7, B8).
     * [CN] 内边距、偏移与尺寸必须是有限值且绝对值不超过 1000（B7、B8）。
     */
    static let maximumMagnitude = 1000.0

    // MARK: Logging

    static func logInvalid(_ key: String, _ value: Any?) {
        #if DEBUG
        NSLog("🔴 CYLTabBarController configuration: the value of %@ (%@) is not valid and is ignored.", key, String(describing: value ?? "nil"))
        #endif
    }

    static func debugLog(_ message: @autoclosure () -> String) {
        #if DEBUG
        NSLog("%@", message())
        #endif
    }

    // MARK: Basic values

    static func trimmed(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /** [EN] A number from an NSNumber or a string (`-doubleValue`). [CN] NSNumber 或字符串中的数字（`-doubleValue`）。 */
    static func double(of value: Any?) -> Double? {
        if let number = value as? NSNumber { return number.doubleValue }
        if let string = value as? NSString { return string.doubleValue }
        return nil
    }

    /** [EN] A whole string read as one double, as NSScanner did. [CN] 整个字符串作为一个 double 读取，与 NSScanner 相同。 */
    static func scanDouble(_ text: String) -> Double? {
        let scanner = Scanner(string: text)
        scanner.charactersToBeSkipped = nil
        guard let number = scanner.scanDouble(), scanner.isAtEnd else { return nil }
        return number
    }

    /**
     * [EN] `count` numbers: "{a, b}", "a, b" or "a b", an array, or a dictionary with one of the names in `keys[i]`
     *      (alternatives separated by "|"). nil when it does not fit.
     * [CN] 取出 `count` 个数字："{a, b}"、"a, b" 或 "a b"、数组，或字典（第 i 个键为 `keys[i]` 中的任一名称，用 "|" 分隔）。不符合时为 nil。
     */
    static func numbers(_ value: Any, count: Int, keys: [String]) -> [Double]? {
        var numbers: [Double] = []
        if let string = value as? String {
            let separators = CharacterSet(charactersIn: "{}[](), \t")
            for part in string.components(separatedBy: separators) where !part.isEmpty {
                guard let number = scanDouble(part) else { return nil }
                numbers.append(number)
            }
        } else if let array = value as? [Any] {
            for element in array {
                guard let number = double(of: element) else { return nil }
                numbers.append(number)
            }
        } else if let dictionary = value as? NSDictionary {
            for names in keys {
                let number = names.components(separatedBy: "|").lazy.compactMap { dictionary[$0] }.first
                numbers.append(double(of: number) ?? 0)
            }
        }
        return numbers.count == count ? numbers : nil
    }

    static func isValue(_ value: Any, ofType type: UnsafePointer<CChar>) -> Bool {
        guard let value = value as? NSValue else { return false }
        return strcmp(value.objCType, type) == 0
    }

    static func areReasonable(_ values: [Double], positive: Bool) -> Bool {
        values.allSatisfy { $0.isFinite && abs($0) <= maximumMagnitude && (!positive || $0 > 0) }
    }

    static func edgeInsetsValue(_ value: Any, key: String) -> NSValue? {
        var insets = UIEdgeInsets.zero
        if isValue(value, ofType: NSValue(uiEdgeInsets: .zero).objCType), let value = value as? NSValue {
            insets = value.uiEdgeInsetsValue
        } else {
            guard let n = numbers(value, count: 4, keys: ["top", "left", "bottom", "right"]) else {
                logInvalid(key, value)
                return nil
            }
            insets = UIEdgeInsets(top: n[0], left: n[1], bottom: n[2], right: n[3])
        }
        guard areReasonable([insets.top, insets.left, insets.bottom, insets.right], positive: false) else {
            logInvalid(key, value)
            return nil
        }
        return NSValue(uiEdgeInsets: insets)
    }

    static func offsetValue(_ value: Any, key: String) -> NSValue? {
        var offset = UIOffset.zero
        if isValue(value, ofType: NSValue(uiOffset: .zero).objCType), let value = value as? NSValue {
            offset = value.uiOffsetValue
        } else {
            guard let n = numbers(value, count: 2, keys: ["horizontal|x", "vertical|y"]) else {
                logInvalid(key, value)
                return nil
            }
            offset = UIOffset(horizontal: n[0], vertical: n[1])
        }
        guard areReasonable([offset.horizontal, offset.vertical], positive: false) else {
            logInvalid(key, value)
            return nil
        }
        return NSValue(uiOffset: offset)
    }

    static func sizeValue(_ value: Any, key: String) -> NSValue? {
        var size = CGSize.zero
        if isValue(value, ofType: NSValue(cgSize: .zero).objCType), let value = value as? NSValue {
            size = value.cgSizeValue
        } else {
            guard let n = numbers(value, count: 2, keys: ["width|w", "height|h"]) else {
                logInvalid(key, value)
                return nil
            }
            size = CGSize(width: n[0], height: n[1])
        }
        guard areReasonable([size.width, size.height], positive: true) else {
            logInvalid(key, value)
            return nil
        }
        return NSValue(cgSize: size)
    }

    /**
     * [EN] "default", "system", "flatDesign", "liquidGlass" (any case, with or without the `CYLTabBarStyleType` prefix) or a number.
     * [CN] "default"、"system"、"flatDesign"、"liquidGlass"（不区分大小写，可带 `CYLTabBarStyleType` 前缀）或数字。
     */
    static func styleTypeValue(_ value: Any) -> NSNumber? {
        let key = CYLTabBarControllerStyleType
        if let number = value as? NSNumber, !(value is String) {
            let style = number.intValue
            let flatDesign = CYLTabBarStyleType.flatDesign.rawValue
            guard Double(style) == number.doubleValue, style >= CYLTabBarStyleType.default.rawValue,
                  style <= CYLTabBarStyleType.liquidGlass.rawValue else {
                logInvalid(key, value)
                return nil
            }
            if style == flatDesign, NSClassFromString("CYLFlatDesignTabBar") == nil {
                // FlatDesign needs its subspec (B10). 扁平样式需要其子库（B10）。
                debugLog("🔴 CYLTabBarController configuration: flatDesign needs the CYLTabBarController/CYLFlatDesignTabBar subspec; the default style is used.")
                return nil
            }
            return NSNumber(value: style)
        }
        guard let string = value as? String else {
            logInvalid(key, value)
            return nil
        }
        var name = string.lowercased().replacingOccurrences(of: "cyltabbarstyletype", with: "")
        name = trimmed(name.replacingOccurrences(of: "_", with: "").replacingOccurrences(of: "-", with: ""))
        let styles: [String: CYLTabBarStyleType] = [
            "default": .default, "system": .system, "flatdesign": .flatDesign, "flat": .flatDesign,
            "liquidglass": .liquidGlass, "glass": .liquidGlass,
        ]
        var style = styles[name].map { NSNumber(value: $0.rawValue) }
        if style == nil {
            let scanner = Scanner(string: name)
            scanner.charactersToBeSkipped = nil
            if let number = scanner.scanInt(), scanner.isAtEnd {
                style = NSNumber(value: number)
            }
        }
        guard let style else {
            logInvalid(key, value)
            return nil
        }
        return styleTypeValue(style)
    }

    /** [EN] "system:<name>" is an SF Symbol; anything else is kept. [CN] "system:<名称>" 为 SF Symbol；其他值保持不变。 */
    static func imageValue(_ value: Any) -> Any {
        if let string = value as? String, string.hasPrefix("system:") {
            if let image = UIImage(systemName: String(string.dropFirst(7))) {
                return image
            }
            logInvalid(CYLTabBarItemImage, value)
        }
        return value
    }

    /** [EN] A path in the main bundle for a relative path or file name; the path itself otherwise. [CN] 相对路径或文件名对应 main bundle 中的路径；否则返回原路径。 */
    static func mainBundlePath(_ path: String) -> String {
        if path.isEmpty || (path as NSString).isAbsolutePath {
            return path
        }
        if let resources = Bundle.main.resourcePath {
            let bundled = (resources as NSString).appendingPathComponent(path)
            if FileManager.default.fileExists(atPath: bundled) {
                return bundled
            }
        }
        let extensionName = (path as NSString).pathExtension
        let name = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
        return Bundle.main.path(forResource: name, ofType: extensionName.isEmpty ? nil : extensionName) ?? path
    }

    static func isRemoteURL(_ url: URL?) -> Bool {
        guard let url, let scheme = url.scheme?.lowercased() else { return false }
        return (scheme == "https" || scheme == "http") && !(url.host ?? "").isEmpty
    }

    static func fileExists(_ path: String?) -> Bool {
        guard let path, !path.isEmpty else { return false }
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory) && !isDirectory.boolValue
    }

    private static func head(of path: String, length: Int) -> Data {
        guard let handle = FileHandle(forReadingAtPath: path) else { return Data() }
        defer { handle.closeFile() }
        return handle.readData(ofLength: length)
    }

    /**
     * [EN] A local animation file the library can read (B17): a .json file must be a JSON object with "layers", a .lottie
     *      file a zip archive, a .gif file must start with a GIF signature (#605, B30); other names are left to the library.
     * [CN] 本库可以读取的本地动画文件（B17）：.json 必须是含 "layers" 的 JSON 对象，.lottie 必须是 zip 压缩包，.gif 必须以 GIF 签名开头
     *      （#605、B30）；其他文件名交给动画库。
     */
    static func isReadableAnimationFile(_ path: String) -> Bool {
        let extensionName = (path as NSString).pathExtension.lowercased()
        switch extensionName {
        case "gif":
            let head = head(of: path, length: 6)
            return head == Data("GIF87a".utf8) || head == Data("GIF89a".utf8)
        case "lottie":
            return head(of: path, length: 4) == Data([0x50, 0x4B, 0x03, 0x04])
        case "json":
            guard let data = FileManager.default.contents(atPath: path),
                  let animation = try? JSONSerialization.jsonObject(with: data) as? NSDictionary else { return false }
            return animation["layers"] is NSArray
        default:
            return true
        }
    }

    /**
     * [EN] A URL from a URL, a URL string, a path or a file name in the main bundle: only http(s) URLs and local files that
     *      exist (B13, B21).
     * [CN] 将 URL、URL 字符串、路径或 main bundle 中的文件名转换为 URL：只接受 http(s) URL 与存在的本地文件（B13、B21）。
     */
    static func urlValue(_ value: Any) -> URL? {
        var url = value as? URL
        if let string = value as? String {
            let path = string.isEmpty ? nil : mainBundlePath(string)
            if let parsed = URL(string: string), (parsed.scheme ?? "").count > 1 {
                url = parsed
            } else {
                url = (path?.isEmpty ?? true) ? nil : URL(fileURLWithPath: path ?? "")
            }
        }
        if isRemoteURL(url) || (url?.isFileURL == true && fileExists(url?.path)) {
            return url
        }
        return nil
    }

    /**
     * [EN] An icon for `CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL` (B13, B14).
     * [CN] `CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL` 的图标（B13、B14）。
     */
    static func imageURLValue(_ value: Any) -> Any? {
        if value is UIImage {
            return value
        }
        if value is URL {
            return urlValue(value)
        }
        guard let string = value as? String, !string.isEmpty else { return nil }
        if let parsed = URL(string: string), (parsed.scheme ?? "").count > 1 {
            guard let url = urlValue(parsed) else { return nil }
            return url.isFileURL ? url.path : string
        }
        if (string as NSString).isAbsolutePath {
            return fileExists(string) ? string : nil
        }
        let bundled = mainBundlePath(string)
        return fileExists(bundled) ? bundled : string
    }

    /** [EN] "#RGB", "#RRGGBB" or "#RRGGBBAA" (the "#" is optional). [CN] "#RGB"、"#RRGGBB" 或 "#RRGGBBAA"（"#" 可省略）。 */
    static func color(fromHex string: String) -> UIColor? {
        var hex = trimmed(string).replacingOccurrences(of: "#", with: "")
        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }
        if hex.count == 6 {
            hex += "FF"
        }
        let scanner = Scanner(string: hex)
        scanner.charactersToBeSkipped = nil
        guard hex.count == 8, let rgba = scanner.scanUInt64(representation: .hexadecimal), scanner.isAtEnd else { return nil }
        return UIColor(red: CGFloat((rgba >> 24) & 0xFF) / 255, green: CGFloat((rgba >> 16) & 0xFF) / 255,
                       blue: CGFloat((rgba >> 8) & 0xFF) / 255, alpha: CGFloat(rgba & 0xFF) / 255)
    }

    /** [EN] A UIColor, or a hex string; nil otherwise (B19). [CN] UIColor 或十六进制字符串；否则为 nil（B19）。 */
    static func colorValue(_ value: Any?) -> UIColor? {
        if let color = value as? UIColor { return color }
        if let string = value as? String { return color(fromHex: string) }
        return nil
    }

    /** [EN] A Protobuf text map's `{ key value }` entries become one dictionary. [CN] Protobuf 文本 map 的 `{ key value }` 条目转换为一个字典。 */
    static func dictionaryFromMapEntries(_ value: Any) -> Any {
        var entries = value as? [Any]
        if let dictionary = value as? NSDictionary {
            let isEntry = dictionary.count == 2 && dictionary["key"] != nil && dictionary["value"] != nil
            entries = isEntry ? [dictionary] : nil
        }
        guard let entries else { return value }
        let map = NSMutableDictionary()
        for entry in entries {
            guard let entry = entry as? NSDictionary, let key = entry["key"] as? NSCopying, let entryValue = entry["value"] else {
                return value
            }
            map[key] = entryValue
        }
        return map
    }

    static func darkColorsValue(_ value: Any, key: String) -> Any {
        let value = dictionaryFromMapEntries(value)
        guard let dictionary = value as? NSDictionary else { return value }
        let colors = NSMutableDictionary()
        for (keypath, entry) in dictionary {
            if let color = colorValue(entry), let keypath = keypath as? NSCopying {
                colors[keypath] = color
            } else {
                logInvalid(key, entry)
            }
        }
        return colors
    }

    /**
     * [EN] `CYLTabBarAnimationOptions`: option name -> string; numbers become strings, other values are dropped (B28).
     * [CN] `CYLTabBarAnimationOptions`：选项名 -> 字符串；数字转为字符串，其他值丢弃（B28）。
     */
    static func animationOptionsValue(_ value: Any) -> [String: String]? {
        guard let dictionary = dictionaryFromMapEntries(value) as? NSDictionary else {
            logInvalid(CYLTabBarAnimationOptions, value)
            return nil
        }
        var options: [String: String] = [:]
        for (name, option) in dictionary {
            let text = (option as? String) ?? ((option as? NSNumber).map { $0.stringValue })
            if let name = name as? String, !name.isEmpty, let text, !text.isEmpty {
                options[name] = text
            } else {
                logInvalid(CYLTabBarAnimationOptions, option)
            }
        }
        return options
    }

    /**
     * [EN] Writes `options` into the tab's animation URLs with `CYLTabBarAnimationURLWithOptions()`; a file path without a
     *      URL gets a file URL under the matching URL key.
     * [CN] 用 `CYLTabBarAnimationURLWithOptions()` 把 `options` 写入 Tab 的动画 URL；只有文件路径时，在对应的 URL 键下写入其 file URL。
     */
    static func applyAnimationOptions(_ item: inout [String: Any], _ options: [String: String]?) {
        guard let options, !options.isEmpty else { return }
        let pairs = [
            (CYLTabBarAnimationURL, CYLTabBarAnimationFilePath), (CYLTabBarAnimationDarkURL, CYLTabBarAnimationDarkFilePath),
            (lottieURL, lottieFilePath), (lottieDarkURL, lottieDarkFilePath), (pagURL, pagFilePath), (pagDarkURL, pagDarkFilePath),
            (riveURL, riveFilePath), (riveDarkURL, riveDarkFilePath), (gifURL, gifFilePath), (gifDarkURL, gifDarkFilePath),
            (svgaURL, svgaFilePath), (svgaDarkURL, svgaDarkFilePath),
        ]
        for (urlKey, pathKey) in pairs {
            var url = item[urlKey] as? URL
            if url == nil, let path = item[pathKey] as? String, !path.isEmpty {
                url = URL(fileURLWithPath: path)
            }
            if let withOptions = cylTabBarAnimationURLWithOptionsEntryPoint(url as NSURL?, options as NSDictionary) {
                item[urlKey] = withOptions as URL
            }
        }
    }

    /** [EN] A finite number above 0 (B28). [CN] 大于 0 的有限数字（B28）。 */
    static func animationSpeedValue(_ value: Any) -> NSNumber? {
        var number = value as? NSNumber
        if let string = value as? String {
            let text = trimmed(string)
            number = text.isEmpty ? nil : scanDouble(text).map { NSNumber(value: $0) }
        }
        guard let number, number.doubleValue.isFinite, number.doubleValue > 0 else { return nil }
        return number
    }

    /** [EN] An image for the plus button: a UIImage, an image name or an absolute path. [CN] PlusButton 的图片：UIImage、图片名或绝对路径。 */
    private static func plusButtonImage(_ value: Any?) -> UIImage? {
        guard let value else { return nil }
        let image = imageValue(value)
        if let image = image as? UIImage { return image }
        guard let name = image as? String else { return nil }
        if let named = UIImage(named: name) { return named }
        return (name as NSString).isAbsolutePath ? UIImage(contentsOfFile: name) : nil
    }

    /**
     * [EN] `CYLTabBarControllerPlusButton`: the title, images and numbers as the plus button needs them; nil when it is not
     *      a dictionary.
     * [CN] `CYLTabBarControllerPlusButton`：按 PlusButton 需要转换标题、图片与数字；不是字典时为 nil。
     */
    static func plusButtonAttributesValue(_ value: Any) -> [String: Any]? {
        guard let value = value as? NSDictionary else {
            logInvalid(CYLTabBarControllerPlusButton, value)
            return nil
        }
        var attributes: [String: Any] = [:]
        for key in [CYLTabBarItemTitle, CYLTabBarItemSelectedTitle] {
            if let title = value[key], title is String || title is NSNumber {
                attributes[key] = (title as AnyObject).description
            }
        }
        // [EN] The image, and the selected one (`CYLPlusButtonSubclass`'s highlighted image). [CN] 图片与选中图片（`CYLPlusButtonSubclass` 的高亮图片）。
        for key in [CYLTabBarItemImage, CYLTabBarItemSelectedImage] {
            attributes[key] = plusButtonImage(value[key])
        }
        attributes[CYLTabBarItemSelectedTitleColor] = colorValue(value[CYLTabBarItemSelectedTitleColor])
        attributes[CYLTabBarItemTitleColor] = colorValue(value[CYLTabBarItemTitleColor])
        attributes[CYLTabBarItemTitleFont] = fontValue(value[CYLTabBarItemTitleFont])
        attributes[CYLPlusButtonBackgroundImage] = plusButtonImage(value[CYLPlusButtonBackgroundImage])
        // [EN] Numbers: a position and a vertical center. [CN] 数字：位置与垂直中心。
        for key in [CYLPlusButtonIndexInTabBar, CYLPlusButtonCenterYMultiplier, CYLPlusButtonCenterYOffset] {
            guard let raw = value[key] else { continue }
            let number = (raw as? NSString).map { NSNumber(value: $0.doubleValue) } ?? (raw as? NSNumber)
            if let number, number.doubleValue.isFinite, !(key == CYLPlusButtonIndexInTabBar && number.doubleValue < 0) {
                attributes[key] = number
            } else {
                logInvalid(key, raw)
            }
        }
        for key in [CYLPlusButtonSize, CYLPlusButtonImageSize] {
            attributes[key] = value[key].flatMap { sizeValue($0, key: key) }
        }
        for key in [CYLPlusButtonAlignsTitle, CYLPlusButtonKeepsTitleVisible, CYLPlusButtonShowsSelection] {
            attributes[key] = value[key].flatMap { boolValue($0) }
        }
        for key in [CYLTabBarItemIdentifier, CYLTabBarItemPageIdentifier] {
            if let string = value[key] as? String, !string.isEmpty {
                attributes[key] = string
            }
        }
        return attributes
    }

    /** [EN] "light", "dark", "system" → UIUserInterfaceStyle. [CN] "light"、"dark"、"system" → UIUserInterfaceStyle。 */
    static func userInterfaceStyleValue(_ value: Any) -> NSNumber? {
        let names: [String: Int] = ["system": 0, "unspecified": 0, "light": 1, "dark": 2]
        if let string = value as? String {
            return names[string.lowercased()].map { NSNumber(value: $0) }
        }
        if let number = value as? NSNumber, (0...2).contains(number.intValue) {
            return number
        }
        return nil
    }

    /** [EN] A tap animation name → CYLTabButtonTapAnimationType. [CN] 点击动画名称 → CYLTabButtonTapAnimationType。 */
    static func tapAnimationValue(_ value: Any) -> NSNumber? {
        let names = ["none", "scale", "zoomin", "bounce", "bouncewithfireworks", "rotation", "flip", "fume"]
        if let string = value as? String {
            return names.firstIndex(of: string.lowercased()).map { NSNumber(value: $0) }
        }
        if let number = value as? NSNumber, number.intValue >= 0, number.intValue < names.count {
            return number
        }
        return nil
    }

    /** [EN] Every key the library reads. [CN] 本库读取的所有键。 */
    static let knownConfigurationKeys: [String] = [
        CYLTabBarControllerViewControllers, CYLTabBarControllerTabBarItemsAttributes, CYLTabBarControllerImageInsets,
        CYLTabBarControllerTitlePositionAdjustment, CYLTabBarControllerStyleType, CYLTabBarControllerContext,
        CYLTabBarControllerPageRegistry, CYLTabBarControllerPageResolver, CYLTabBarControllerPageLookupOrder,
        CYLTabBarControllerAutomaticPageRegistration, CYLTabBarControllerTabBarItemAnimationSpeed,
        CYLTabBarControllerThemes, CYLTabBarControllerThemeIdentifier, CYLTabBarControllerDarkThemeIdentifier,
        CYLTabBarControllerThemeManagerName, CYLTabBarControllerPlusButton, CYLTabBarControllerPlusButtonAction,
        CYLTabBarControllerUserInterfaceStyle, CYLTabBarControllerTabButtonTapAnimation, CYLTabBarControllerSwipeToSwitchTab,
        CYLTabBarControllerLoginRequiredTabBarItemIdentifiers, CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning,
        CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers, CYLTabBarControllerLocalization,
        CYLTabBarControllerConfigurationRoute, CYLTabBarControllerManifestRoute, CYLTabBarControllerIconRenderingMode,
        CYLTabBarControllerIconColor, CYLTabBarControllerSelectedIconColor,
    ]

    static let knownItemKeys: [String] = [
        CYLTabBarItemTitle, CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLTabBarItemDarkImage,
        CYLTabBarItemSelectedDarkImage, CYLTabBarItemImageURL, CYLTabBarItemSelectedImageURL, CYLTabBarItemImageURLSize,
        CYLTabBarItemImageInsets, CYLTabBarItemTitlePositionAdjustment, CYLTabBarItemImagePositionAdjustment,
        lottieFilePath, lottieURL, lottieSize, CYLTabBarItemIdentifier, lottieDarkURL, lottieDarkFilePath, lottieDarkColors,
        CYLTabBarItemPageIdentifier, CYLTabBarItemPageParameters, CYLTabBarItemPlatforms, CYLTabBarItemMinimumAppVersion,
        CYLTabBarItemSelectedTitle, CYLTabBarItemTitleColor, CYLTabBarItemSelectedTitleColor, CYLTabBarItemIconColor,
        CYLTabBarItemSelectedIconColor, CYLTabBarItemIconRenderingMode, CYLTabBarItemSelectedBackgroundColor,
        CYLTabBarItemBackgroundColor, CYLTabBarItemTitleFont, CYLTabBarItemSelectedTitleFont,
        CYLTabBarItemAccessibilityIdentifier, CYLTabBarItemAccessibilityLabel, CYLTabBarItemAccessibilityHint,
        // [EN] Tab animations (#604, #752, #605). [CN] Tab 动画（#604、#752、#605）。
        CYLTabBarAnimationURL, CYLTabBarAnimationFilePath, CYLTabBarAnimationSize, CYLTabBarAnimationDarkURL,
        CYLTabBarAnimationDarkFilePath, CYLTabBarAnimationDarkColors, CYLTabBarAnimationColors, CYLTabBarAnimationOptions,
        lottieLoopsWhenUnselected, pagURL, pagFilePath, pagSize, pagDarkURL, pagDarkFilePath, riveURL, riveFilePath, riveSize,
        riveDarkURL, riveDarkFilePath, riveDarkColors, gifURL, gifFilePath, gifSize, gifDarkURL, gifDarkFilePath,
        svgaURL, svgaFilePath, svgaSize, svgaDarkURL, svgaDarkFilePath,
    ]

    /** [EN] Case-insensitive edit distance (at most 64 characters); DEBUG hints only. [CN] 不区分大小写的编辑距离（最多 64 个字符），仅用于 DEBUG 提示。 */
    static func editDistance(_ a: String, _ b: String) -> Int {
        let a = Array(a.lowercased().utf16.prefix(64))
        let b = Array(b.lowercased().utf16.prefix(64))
        var row = Array(0...b.count)
        for i in stride(from: 1, through: a.count, by: 1) {
            var diagonal = row[0]
            row[0] = i
            for j in stride(from: 1, through: b.count, by: 1) {
                let above = row[j]
                row[j] = min(row[j] + 1, row[j - 1] + 1, diagonal + (a[i - 1] == b[j - 1] ? 0 : 1))
                diagonal = above
            }
        }
        return row[b.count]
    }

    /**
     * [EN] DEBUG: names the closest known key of a "CYL..." key the library does not read (B11). The key itself is kept.
     * [CN] DEBUG：对本库不读取的 "CYL..." 键，提示最接近的已知键（B11）。该键本身会保留。
     */
    static func warnUnknownKeys(_ keys: some Sequence<String>, known: [String]) {
        #if DEBUG
        for key in keys where key.hasPrefix("CYL") && !known.contains(key) {
            let closest = known.min { editDistance(key, $0) < editDistance(key, $1) }
            let best = closest.map { editDistance(key, $0) } ?? Int.max
            NSLog("🟡 CYLTabBarController configuration: unknown key %@%@.", key, best <= 3 ? "; did you mean \(closest ?? "")?" : "")
        }
        #endif
    }

    /**
     * [EN] `CYLTabBarItemIdentifier` must be unique: later duplicates become "identifier_2", "identifier_3"... (B12).
     * [CN] `CYLTabBarItemIdentifier` 必须唯一：后出现的重复标识改为「标识_2」「标识_3」……（B12）。
     */
    static func makeIdentifiersUnique(_ items: inout [[String: Any]]) {
        var used = Set<String>()
        for index in items.indices {
            guard let identifier = items[index][CYLTabBarItemIdentifier] as? String else { continue }
            var unique = identifier
            var suffix = 2
            while used.contains(unique) {
                unique = "\(identifier)_\(suffix)"
                suffix += 1
            }
            if unique != identifier {
                debugLog("🟡 CYLTabBarController configuration: duplicate identifier \(identifier) renamed \(unique).")
                items[index][CYLTabBarItemIdentifier] = unique
                // [EN] The page ID falls back to the tab ID: keep the original one (B12). [CN] 页面 ID 默认取 Tab 标识：保留原来的标识（B12）。
                if ((items[index][CYLTabBarItemPageIdentifier] as? String) ?? "").isEmpty {
                    items[index][CYLTabBarItemPageIdentifier] = identifier
                }
            }
            used.insert(unique)
        }
    }

    static func fontWeight(named name: String) -> UIFont.Weight? {
        let weights: [String: UIFont.Weight] = [
            "ultralight": .ultraLight, "thin": .thin, "light": .light, "regular": .regular, "medium": .medium,
            "semibold": .semibold, "bold": .bold, "heavy": .heavy, "black": .black,
        ]
        return weights[name.lowercased()]
    }

    /**
     * [EN] A font (B20): a UIFont; a number; "bold:15"; "Menlo-Regular:12"; or {name, size, weight}. The size must be finite
     *      and between 1 and 200; an unknown font name gives nil.
     * [CN] 字体（B20）：UIFont；数字；"bold:15"；"Menlo-Regular:12"；或 {name, size, weight}。字号必须是 1 到 200 之间的有限值；字体名称不存在时为 nil。
     */
    static func fontValue(_ value: Any?) -> UIFont? {
        if let font = value as? UIFont { return font }
        var name: String?
        var weightName: String?
        var size = 0.0
        if let string = value as? String {
            let text = trimmed(string)
            let colon = text.range(of: ":", options: .backwards)
            guard let parsed = scanDouble(colon.map { String(text[$0.upperBound...]) } ?? text) else { return nil }
            size = parsed
            name = colon.map { String(text[..<$0.lowerBound]) }
        } else if let number = value as? NSNumber {
            size = number.doubleValue
        } else if let dictionary = value as? NSDictionary {
            size = double(of: dictionary["size"]) ?? 0
            name = dictionary["name"] as? String
            weightName = dictionary["weight"] as? String
        } else {
            return nil
        }
        guard size.isFinite, size >= 1, size <= 200 else { return nil }
        let weight = fontWeight(named: weightName ?? name ?? "regular")
        if let name, !name.isEmpty, weight == nil {
            return UIFont(name: name, size: size)
        }
        return UIFont.systemFont(ofSize: size, weight: weight ?? .regular)
    }

    /** [EN] A string, or a number as a string; nil for anything else (B5). [CN] 字符串，或转换为字符串的数字；其他类型为 nil（B5）。 */
    static func stringValue(_ value: Any?) -> String? {
        if let string = value as? String { return string }
        if let number = value as? NSNumber { return number.stringValue }
        return nil
    }

    /** [EN] `CYLTabBarItemPlatforms` as lowercase names (B23). [CN] 将 `CYLTabBarItemPlatforms` 转为小写名称列表（B23）。 */
    static func platformsValue(_ value: Any) -> [String]? {
        guard let names = (value as? String).map({ $0.components(separatedBy: ",") as [Any] }) ?? (value as? [Any]) else {
            logInvalid(CYLTabBarItemPlatforms, value)
            return nil
        }
        var platforms: [String] = []
        for name in names {
            guard let platform = (name as? String).map({ trimmed($0).lowercased() }), !platform.isEmpty else {
                logInvalid(CYLTabBarItemPlatforms, value)
                return nil
            }
            platforms.append(platform)
        }
        return platforms.isEmpty ? nil : platforms
    }

    /** [EN] The numbers of a version string, or nil (B24). [CN] 版本字符串中的数字；无效时为 nil（B24）。 */
    static func versionNumbers(_ version: String) -> [Int64]? {
        let text = trimmed(version)
        guard !text.isEmpty else { return nil }
        var numbers: [Int64] = []
        for part in text.components(separatedBy: ".") {
            let scanner = Scanner(string: part)
            guard let number = scanner.scanInt64(), scanner.isAtEnd, number >= 0 else { return nil }
            numbers.append(number)
        }
        return numbers
    }

    /** [EN] Whether `version` is lower than `minimum` (missing parts count as 0). [CN] `version` 是否低于 `minimum`（缺少的部分视为 0）。 */
    static func version(_ version: [Int64], isLowerThan minimum: [Int64]) -> Bool {
        for index in 0..<max(version.count, minimum.count) {
            let a = index < version.count ? version[index] : 0
            let b = index < minimum.count ? minimum[index] : 0
            if a != b {
                return a < b
            }
        }
        return false
    }

    /** [EN] A BOOL: NSNumber, or "true" / "false", "yes" / "no", "1" / "0". [CN] BOOL：NSNumber，或 "true" / "false"、"yes" / "no"、"1" / "0"。 */
    static func boolValue(_ value: Any) -> NSNumber? {
        if let number = value as? NSNumber {
            return NSNumber(value: number.boolValue)
        }
        if let string = value as? String {
            let text = trimmed(string).lowercased()
            if ["true", "yes", "1"].contains(text) { return NSNumber(value: true) }
            if ["false", "no", "0"].contains(text) { return NSNumber(value: false) }
        }
        return nil
    }

    /** [EN] The page lookup order (C18); nil when nothing is left. [CN] 页面查找顺序（C18）；没有剩余项时为 nil。 */
    static func pageLookupOrderValue(_ value: Any) -> [String]? {
        let entries: [Any] = (value as? String).map { $0.components(separatedBy: ",") } ?? (value as? [Any]) ?? []
        var order: [String] = []
        for entry in entries {
            let name = (entry as? String).map { trimmed($0).lowercased() } ?? ""
            if !name.isEmpty, CYLTabBarPageRegistry.defaultPageLookupOrder.contains(name), !order.contains(name) {
                order.append(name)
            } else if !name.isEmpty || !(entry is String) {
                logInvalid(CYLTabBarControllerPageLookupOrder, entry)
            }
        }
        if order.isEmpty {
            logInvalid(CYLTabBarControllerPageLookupOrder, value)
            return nil
        }
        return order
    }

    /**
     * [EN] Why a tab is left out on this device, or nil: not for iOS, or a newer app needed (B24).
     * [CN] 该 Tab 在本设备上被排除的原因，没有则为 nil：不适用于 iOS，或需要更新的 App 版本（B24）。
     */
    static func exclusionReason(_ item: [String: Any]) -> String? {
        if let platforms = item[CYLTabBarItemPlatforms] as? [String], !platforms.contains("ios") {
            return "its platforms are \(platforms.joined(separator: ", "))"
        }
        if let minimum = item[CYLTabBarItemMinimumAppVersion] as? String {
            let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
            guard let minimumNumbers = versionNumbers(minimum) else {
                logInvalid(CYLTabBarItemMinimumAppVersion, minimum)
                return nil
            }
            if let appVersion, let appNumbers = versionNumbers(appVersion), version(appNumbers, isLowerThan: minimumNumbers) {
                return "it needs version \(minimum) (this app is \(appVersion))"
            }
        }
        return nil
    }

    // MARK: Tabs

    /**
     * [EN] The attributes of one tab, each known key checked for its type (B5, B6); wrong values are removed, unknown keys kept.
     * [CN] 一个 Tab 的属性，每个已知键都检查类型（B5、B6）；错误的值会被移除，未知键保留。
     */
    static func normalizedItemAttributes(_ attributes: NSDictionary) -> [String: Any] {
        var item: [String: Any] = [:]
        for (key, value) in attributes {
            if let key = key as? String, !(value is NSNull) {
                item[key] = value
            }
        }
        for key in [CYLTabBarItemTitle, CYLTabBarItemSelectedTitle, CYLTabBarItemIdentifier, CYLTabBarItemPageIdentifier,
                    CYLTabBarItemMinimumAppVersion, CYLTabBarItemAccessibilityIdentifier, CYLTabBarItemAccessibilityLabel,
                    CYLTabBarItemAccessibilityHint] {
            if let value = item[key], stringValue(value) == nil {
                logInvalid(key, value)
            }
            item[key] = stringValue(item[key])
        }
        for key in [CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLTabBarItemDarkImage, CYLTabBarItemSelectedDarkImage] {
            var value = item[key]
            if let unwrapped = value, !(unwrapped is String), !(unwrapped is UIImage) {
                logInvalid(key, unwrapped)
                value = nil
            }
            item[key] = value.map { imageValue($0) }
        }
        if let value = item[CYLTabBarItemImageInsets] {
            item[CYLTabBarItemImageInsets] = edgeInsetsValue(value, key: CYLTabBarItemImageInsets)
        }
        for key in [CYLTabBarItemTitlePositionAdjustment, CYLTabBarItemImagePositionAdjustment] {
            if let value = item[key] {
                item[key] = offsetValue(value, key: key)
            }
        }
        for key in [CYLTabBarItemImageURLSize, lottieSize, CYLTabBarAnimationSize, pagSize, riveSize, gifSize, svgaSize] {
            if let value = item[key] {
                item[key] = sizeValue(value, key: key)
            }
        }
        // [EN] Animation URLs: a local file must exist and be readable (B17). [CN] 动画 URL：本地文件必须存在且可读（B17）。
        for key in [CYLTabBarItemImageURL, CYLTabBarItemSelectedImageURL, lottieURL, lottieDarkURL, CYLTabBarAnimationURL,
                    CYLTabBarAnimationDarkURL, pagURL, pagDarkURL, riveURL, riveDarkURL, gifURL, gifDarkURL, svgaURL, svgaDarkURL] {
            guard let value = item[key] else { continue }
            let isImage = key == CYLTabBarItemImageURL || key == CYLTabBarItemSelectedImageURL
            var checked: Any? = isImage ? imageURLValue(value) : urlValue(value)
            if !isImage, let url = checked as? URL, url.isFileURL, !isReadableAnimationFile(url.path) {
                checked = nil
            }
            if checked == nil {
                logInvalid(key, value)
            }
            item[key] = checked
        }
        for key in [lottieFilePath, lottieDarkFilePath, CYLTabBarAnimationFilePath, CYLTabBarAnimationDarkFilePath, pagFilePath,
                    pagDarkFilePath, riveFilePath, riveDarkFilePath, gifFilePath, gifDarkFilePath, svgaFilePath, svgaDarkFilePath] {
            guard let value = item[key] else { continue }
            var path = (value as? String).map { mainBundlePath($0) }
            if !fileExists(path) || !isReadableAnimationFile(path ?? "") {
                logInvalid(key, value)
                path = nil
            }
            item[key] = path
        }
        for key in [CYLTabBarItemTitleColor, CYLTabBarItemSelectedTitleColor, CYLTabBarItemIconColor, CYLTabBarItemSelectedIconColor,
                    CYLTabBarItemSelectedBackgroundColor, CYLTabBarItemBackgroundColor] {
            guard let value = item[key] else { continue }
            item[key] = colorValue(value)
            if item[key] == nil {
                logInvalid(key, attributes[key])
            }
        }
        if let value = item[CYLTabBarItemIconRenderingMode] {
            // FIX: issue #787 — "template", "original" or "automatic". [CN] "template"、"original" 或 "automatic"。
            var mode = (value as? String)?.lowercased()
            if !["template", "original", "automatic"].contains(mode ?? "") {
                logInvalid(CYLTabBarItemIconRenderingMode, attributes[CYLTabBarItemIconRenderingMode])
                mode = nil
            }
            item[CYLTabBarItemIconRenderingMode] = mode
        }
        for key in [CYLTabBarItemTitleFont, CYLTabBarItemSelectedTitleFont] {
            guard let value = item[key] else { continue }
            item[key] = fontValue(value)
            if item[key] == nil {
                logInvalid(key, attributes[key])
            }
        }
        if let value = item[CYLTabBarItemPageParameters] {
            // [EN] Protobuf maps arrive as key / value entries; parameters must be a dictionary (B25).
            // [CN] Protobuf 的 map 以 key / value 条目出现；参数必须是字典（B25）。
            let parameters = dictionaryFromMapEntries(value)
            if parameters is NSDictionary {
                item[CYLTabBarItemPageParameters] = parameters
            } else {
                logInvalid(CYLTabBarItemPageParameters, parameters)
                item[CYLTabBarItemPageParameters] = nil
            }
        }
        if let value = item[CYLTabBarItemPlatforms] {
            item[CYLTabBarItemPlatforms] = platformsValue(value)
        }
        warnUnknownKeys(item.keys, known: knownItemKeys)
        for key in [lottieDarkColors, CYLTabBarAnimationDarkColors, CYLTabBarAnimationColors, riveDarkColors] {
            guard let value = item[key] else { continue }
            let colors = darkColorsValue(value, key: key)
            if colors is NSDictionary {
                item[key] = colors
            } else {
                logInvalid(key, colors)
                item[key] = nil
            }
        }
        if let value = item[lottieLoopsWhenUnselected] {
            let loops = boolValue(value)
            if loops == nil {
                logInvalid(lottieLoopsWhenUnselected, value)
            }
            item[lottieLoopsWhenUnselected] = loops
        }
        if let value = item[CYLTabBarAnimationOptions] {
            let options = animationOptionsValue(value)
            item[CYLTabBarAnimationOptions] = options
            applyAnimationOptions(&item, options)
        }
        return item
    }

    /** [EN] View controllers from code: only UIViewController instances, each once (C6, C7). [CN] 代码传入的子控制器：只保留 UIViewController 实例，且每个只保留一次（C6、C7）。 */
    static func validViewControllers(_ value: Any) -> [UIViewController]? {
        guard let array = value as? [Any] else {
            logInvalid(CYLTabBarControllerViewControllers, value)
            return nil
        }
        var viewControllers: [UIViewController] = []
        for element in array {
            guard let viewController = element as? UIViewController, !viewControllers.contains(where: { $0 === viewController }) else {
                logInvalid(CYLTabBarControllerViewControllers, element)
                continue
            }
            viewControllers.append(viewController)
        }
        return viewControllers
    }

    static func error(_ code: CYLTabBarConfigurationErrorCode, _ description: String, underlying: Error? = nil) -> NSError {
        var userInfo: [String: Any] = [NSLocalizedDescriptionKey: description]
        userInfo[NSUnderlyingErrorKey] = underlying
        return NSError(domain: CYLTabBarConfigurationErrorDomain, code: code.rawValue, userInfo: userInfo)
    }

    /** [EN] A configuration read from a file or a URL must describe at least one tab (B1, B2, D7). [CN] 从文件或 URL 读取的配置必须至少描述一个 Tab（B1、B2、D7）。 */
    static func tabsError(_ configuration: [String: Any]) -> NSError? {
        let items = configuration[CYLTabBarControllerTabBarItemsAttributes]
        if items is NSDictionary || (items as? [Any])?.contains(where: { $0 is NSDictionary }) == true {
            return nil
        }
        return error(.noTabs, "The configuration has no tab: CYLTabBarControllerTabBarItemsAttributes is missing or empty (was an HTML page downloaded instead?).")
    }

    /** [EN] A tab bar controller from a file or a URL must show at least one tab (C11). [CN] 由文件或 URL 创建的 TabBarController 必须至少显示一个 Tab（C11）。 */
    static func pagesError(_ tabBarController: UITabBarController?) -> NSError? {
        if let count = tabBarController?.viewControllers?.count, count > 0 {
            return nil
        }
        return error(.noPages, "No tab found its page: register the page IDs (CYLTabBarItemPageIdentifier) with CYLTabBarPageRegistry, or adopt CYLTabBarPage.")
    }
}

// MARK: - Skins (named values, after QMUI's skins)

/**
 * [EN] The skins of a configuration: identifiers, the base skin, the dark one, the first one and the manager name.
 * [CN] 配置中的皮肤：标识、基础皮肤、深色皮肤、首个皮肤与管理器名称。
 */
enum CYLConfigurationSkins {
    private typealias Values = CYLConfigurationValues

    /** [EN] The named values of one skin, without null values. [CN] 一个皮肤的命名值，去掉 null 值。 */
    static func themeValues(_ value: Any?) -> [String: Any]? {
        guard let map = Values.dictionaryFromMapEntries(value ?? NSDictionary()) as? NSDictionary else { return nil }
        var values: [String: Any] = [:]
        for (key, entry) in map {
            if let key = key as? String, !(entry is NSNull) {
                values[key] = entry
            }
        }
        return values
    }

    /** [EN] `CYLTabBarControllerThemes`: identifier -> named values; nil without a valid skin. [CN] `CYLTabBarControllerThemes`：标识 -> 命名值；没有有效皮肤时为 nil。 */
    static func themes(_ value: Any) -> [String: [String: Any]]? {
        var list = value as? [Any]
        var themes: [String: [String: Any]] = [:]
        if let dictionary = value as? NSDictionary {
            if dictionary[CYLTabBarThemeIdentifier] != nil {
                list = [dictionary]
            } else {
                for (key, entry) in dictionary {
                    if let identifier = Values.stringValue(key), !identifier.isEmpty, let values = themeValues(entry) {
                        themes[identifier] = values
                    } else {
                        Values.logInvalid(CYLTabBarControllerThemes, key)
                    }
                }
            }
        }
        for entry in list ?? [] {
            let dictionary = entry as? NSDictionary
            if let identifier = Values.stringValue(dictionary?[CYLTabBarThemeIdentifier]), !identifier.isEmpty,
               let values = themeValues(dictionary?[CYLTabBarThemeValues]) {
                themes[identifier] = values
            } else {
                Values.logInvalid(CYLTabBarControllerThemes, entry)
            }
        }
        if themes.isEmpty {
            Values.logInvalid(CYLTabBarControllerThemes, value)
            return nil
        }
        return themes
    }

    /**
     * [EN] A tab with its "@name" values taken from `values`; "@@text" is the literal "@text"; a missing name drops the key.
     * [CN] 用 `values` 替换 Tab 中的 "@name" 值；"@@text" 表示普通文本 "@text"；缺少的名称会移除该键。
     */
    static func item(_ item: NSDictionary, resolving values: [String: Any], references: inout [String: String]) -> NSDictionary {
        let resolved = NSMutableDictionary(dictionary: item)
        for (key, value) in item {
            guard let key = key as? String, let string = value as? String, string.hasPrefix("@") else { continue }
            if string.hasPrefix("@@") {
                resolved[key] = String(string.dropFirst())
                continue
            }
            let name = String(string.dropFirst()).trimmingCharacters(in: .whitespaces)
            guard !name.isEmpty else { continue }
            references[key] = name
            if let themed = values[name] {
                resolved[key] = themed
            } else {
                Values.debugLog("🟡 CYLTabBarController configuration: no skin gives the value \"\(name)\" of \(key); the key is left out.")
                resolved.removeObject(forKey: key)
            }
        }
        return resolved
    }

    static func info(of configuration: [String: Any]) -> [String: Any]? {
        guard let themes = configuration[CYLTabBarControllerThemes].flatMap({ self.themes($0) }) else { return nil }
        let identifiers = themes.keys.sorted { ($0 as NSString).compare($1) == .orderedAscending }
        var base = Values.stringValue(configuration[CYLTabBarControllerThemeIdentifier])
        if let name = base, themes[name] == nil {
            Values.logInvalid(CYLTabBarControllerThemeIdentifier, name)
            base = nil
        }
        let baseIdentifier = base ?? identifiers.first ?? ""
        var dark = Values.stringValue(configuration[CYLTabBarControllerDarkThemeIdentifier])
        if let name = dark, themes[name] == nil {
            Values.logInvalid(CYLTabBarControllerDarkThemeIdentifier, name)
            dark = nil
        }
        var managerName: String?
        if let raw = configuration[CYLTabBarControllerThemeManagerName] {
            managerName = Values.stringValue(raw)
            if (managerName ?? "").isEmpty {
                Values.logInvalid(CYLTabBarControllerThemeManagerName, raw)
                managerName = nil
            }
        }
        let manager = managerName.map { CYLThemeManagerCenter.themeManager(withName: $0 as NSString) } ?? CYLThemeManagerCenter.defaultThemeManager
        var initial = baseIdentifier
        if let current = manager.currentThemeIdentifier as? String, themes[current] != nil {
            initial = current
        } else if let dark, UITraitCollection.current.userInterfaceStyle == .dark {
            initial = dark
        }
        var merged: [String: [String: Any]] = [:]
        for identifier in identifiers {
            merged[identifier] = (themes[baseIdentifier] ?? [:]).merging(themes[identifier] ?? [:]) { $1 }
        }
        var info: [String: Any] = [Values.themesListKey: merged, Values.themesInitialKey: initial]
        info[Values.themesBaseKey] = base ?? identifiers.first
        info[Values.themesDarkKey] = dark
        info[Values.themesManagerKey] = managerName
        return info
    }

    /**
     * [EN] Turns the merged values into `CYLTabBarConfigurationTheme`s, with the "@name" keys of every kept tab, by its
     *      identifier or its position among the kept tabs.
     * [CN] 把合并后的值转换为 `CYLTabBarConfigurationTheme`，带上每个保留 Tab 的 "@name" 键（按其标识，没有标识时按位置）。
     */
    static func finish(_ info: inout [String: Any], items: [[String: Any]], itemReferences: [[String: String]]) {
        let references = NSMutableDictionary()
        var position = 0
        for (item, itemReference) in zip(items, itemReferences) {
            if (item[Values.excludedKey] as? NSNumber)?.boolValue == true {
                continue
            }
            if !itemReference.isEmpty {
                let identifier = Values.stringValue(item[CYLTabBarItemIdentifier]) ?? ""
                references[identifier.isEmpty ? NSNumber(value: position) : identifier as NSString] = itemReference
            }
            position += 1
        }
        let merged = info[Values.themesListKey] as? [String: [String: Any]] ?? [:]
        let factory = unsafeBitCast(CYLTabBarConfigurationTheme.self as AnyObject, to: CYLTabBarConfigurationThemeFactory.self)
        info[Values.themesListKey] = merged.keys.sorted { ($0 as NSString).compare($1) == .orderedAscending }.map {
            factory.cylTheme(identifier: $0, values: merged[$0] ?? [:], references: references)
        }
    }
}

// MARK: - Localization and routes

enum CYLConfigurationLocalization {
    private typealias Values = CYLConfigurationValues

    /** [EN] The text keys whose values are localization keys. [CN] 值为本地化键的文本键。 */
    static let textKeys = [CYLTabBarItemTitle, CYLTabBarItemSelectedTitle, CYLTabBarItemAccessibilityLabel, CYLTabBarItemAccessibilityHint]

    /** [EN] The folder of the `.lproj` folders and the table name; nil when off or invalid. [CN] `.lproj` 文件夹所在目录与表名；关闭或无效时为 nil。 */
    static func directory(_ value: Any, fileDirectory: String?) -> (directory: String, table: String)? {
        let resources = Bundle.main.resourcePath ?? ""
        if let number = value as? NSNumber {
            return number.boolValue ? (resources, "Localizable") : nil
        }
        if let string = value as? String {
            let text = string.trimmingCharacters(in: .whitespaces)
            switch text.lowercased() {
            case "true", "yes": return (resources, "Localizable")
            case "", "false", "no": return nil
            default: return (resources, text)
            }
        }
        guard let info = value as? NSDictionary else {
            Values.logInvalid(CYLTabBarControllerLocalization, value)
            return nil
        }
        var table = "Localizable"
        if let name = Values.stringValue(info[CYLTabBarLocalizationTableName]), !name.isEmpty {
            table = name.hasSuffix(".strings") ? (name as NSString).deletingPathExtension : name
        }
        if let path = Values.stringValue(info[CYLTabBarLocalizationPath]), !path.isEmpty {
            // [EN] A location route (CYLResourceRoute, docs/Resource-Routes.md). [CN] 位置路由（CYLResourceRoute，docs/Resource-Routes.md）。
            return CYLResourceRoute.path(forRoute: path, baseDirectory: fileDirectory ?? resources).map { ($0, table) }
        }
        if let bundleName = Values.stringValue(info[CYLTabBarLocalizationBundleName]), !bundleName.isEmpty, bundleName != "main" {
            let name = bundleName.hasSuffix(".bundle") ? bundleName : bundleName + ".bundle"
            guard let bundlePath = Bundle.main.path(forResource: name, ofType: nil) else {
                Values.logInvalid(CYLTabBarLocalizationBundleName, bundleName)
                return nil
            }
            return (bundlePath, table)
        }
        return (resources, table)
    }

    /** [EN] `<directory>/{language}.lproj/{table}.strings`, falling back to the script, the language, "Base" and "en". [CN] 读取 `<目录>/{语言}.lproj/{表名}.strings`，依次回退到文字、语言代码、"Base" 与 "en"。 */
    static func strings(directory: String, table: String, language: String) -> NSDictionary? {
        let parts = language.components(separatedBy: "-")
        var candidates = [language]
        if parts.count > 2 {
            candidates.append("\(parts[0])-\(parts[1])")
        }
        if parts.count > 1 {
            candidates.append(parts[0])
        }
        candidates += ["Base", "en"]
        for candidate in candidates {
            let file = ((directory as NSString).appendingPathComponent(candidate + ".lproj") as NSString).appendingPathComponent(table + ".strings")
            if let strings = NSDictionary(contentsOfFile: file) {
                return strings
            }
        }
        return nil
    }

    /** [EN] `object` with every text value translated, at any depth. [CN] 翻译 `object` 中任意层级的所有文本值。 */
    static func localized(_ object: Any, strings: NSDictionary) -> Any {
        if let array = object as? [Any] {
            return array.map { localized($0, strings: strings) }
        }
        guard let dictionary = object as? NSDictionary else { return object }
        let result = NSMutableDictionary(dictionary: dictionary)
        for (key, value) in dictionary {
            guard let copyingKey = key as? NSCopying else { continue }
            if let textKey = key as? String, textKeys.contains(textKey), let text = value as? String {
                if let translation = strings[text] as? String {
                    result[copyingKey] = translation
                }
            } else if value is NSArray || value is NSDictionary {
                result[copyingKey] = localized(value, strings: strings)
            }
        }
        return result
    }

    /** [EN] Translates the texts when `CYLTabBarControllerLocalization` is set; removes the private file folder. [CN] 设置了 `CYLTabBarControllerLocalization` 时翻译文本；移除私有的文件目录键。 */
    static func apply(_ configuration: inout [String: Any]) {
        let fileDirectory = Values.stringValue(configuration.removeValue(forKey: Values.fileDirectoryKey))
        guard let value = configuration[CYLTabBarControllerLocalization],
              let (directory, table) = directory(value, fileDirectory: fileDirectory) else { return }
        let language = CYLLocalizationLanguage()
        guard let strings = strings(directory: directory, table: table, language: language) else {
            Values.debugLog("🟡 CYLTabBarController configuration: no \(table).strings for \(language) in \(directory); the texts stay as they are.")
            return
        }
        configuration = localized(configuration, strings: strings) as? [String: Any] ?? configuration
    }

    /** [EN] `CYLTabBarControllerManifestRoute` and `CYLTabBarControllerConfigurationRoute`: the routed keys, then this configuration's keys over them. [CN] 先取路由指向的键，再用本配置中的键覆盖。 */
    static func applyRoutes(_ configuration: inout [String: Any]) {
        if let manifestRoute = configuration.removeValue(forKey: CYLTabBarControllerManifestRoute) {
            // [EN] A manifest the app may use, as a configuration, under the other keys. [CN] 本 App 可以使用的清单，转换为配置，再由其他键覆盖。
            if let route = manifestRoute as? String, let manifest = try? CYLTabBarManifest.manifest(withRoute: route),
               (try? manifest.isEligible(at: Date())) != nil {
                configuration = manifest.configuration().merging(configuration) { $1 }
            } else {
                Values.logInvalid(CYLTabBarControllerManifestRoute, manifestRoute)
            }
        }
        guard let route = configuration.removeValue(forKey: CYLTabBarControllerConfigurationRoute) else { return }
        guard let routeString = route as? String, let file = try? CYLTabBarController.cylConfiguration(route: routeString) else {
            Values.logInvalid(CYLTabBarControllerConfigurationRoute, route)
            return
        }
        configuration = file.merging(configuration) { $1 }
    }
}

// MARK: - CYLTabBarController (CYLConfiguration)

extension CYLTabBarController {
    private typealias Values = CYLConfigurationValues

    /** [EN] The timeout of `+loadConfigurationWithURL:completion:` (D5). [CN] `+loadConfigurationWithURL:completion:` 的超时（D5）。 */
    private static let cylConfigurationRequestTimeout: TimeInterval = 15

    private static func cylIsBlock(_ value: Any) -> Bool {
        guard let blockClass = NSClassFromString("NSBlock") else { return false }
        return (value as AnyObject).isKind(of: blockClass)
    }

    @objc(cyl_normalizedConfiguration:)
    class func cylNormalizedConfiguration(_ configuration: Any?) -> [String: Any] {
        var normalized: [String: Any] = [:]
        if let dictionary = configuration as? NSDictionary {
            for case let (key as String, value) in dictionary where !(value is NSNull) {
                normalized[key] = value
            }
        } else {
            // E.g. an untyped JSON result that is a list (B18). 例如类型不明、实际为数组的 JSON 结果（B18）。
            Values.logInvalid("configuration", configuration)
        }
        // [EN] The routed file first, then its localized texts. [CN] 先读取路由指向的文件，再本地化文本。
        CYLConfigurationLocalization.applyRoutes(&normalized)
        CYLConfigurationLocalization.apply(&normalized)
        if let value = normalized[CYLTabBarControllerViewControllers] {
            normalized[CYLTabBarControllerViewControllers] = Values.validViewControllers(value)
        }
        if let registry = normalized[CYLTabBarControllerPageRegistry], !(registry is CYLTabBarPageProviding) {
            // [EN] Any `CYLTabBarPageProviding`; a string from a file cannot provide pages (C14). [CN] 任何 `CYLTabBarPageProviding`；文件中的字符串不能提供页面（C14）。
            Values.logInvalid(CYLTabBarControllerPageRegistry, registry)
            normalized[CYLTabBarControllerPageRegistry] = nil
        }
        for key in [CYLTabBarControllerPageResolver, CYLTabBarControllerPlusButtonAction] {
            if let value = normalized[key], !cylIsBlock(value) {
                // [EN] Only a block can be called (C15). [CN] 只有 block 可以调用（C15）。
                Values.logInvalid(key, value)
                normalized[key] = nil
            }
        }
        if let value = normalized[CYLTabBarControllerPageLookupOrder] {
            normalized[CYLTabBarControllerPageLookupOrder] = Values.pageLookupOrderValue(value)
        }
        let checked: [(String, (Any) -> NSNumber?)] = [
            (CYLTabBarControllerTabBarItemAnimationSpeed, Values.animationSpeedValue),
            (CYLTabBarControllerUserInterfaceStyle, Values.userInterfaceStyleValue),
            (CYLTabBarControllerTabButtonTapAnimation, Values.tapAnimationValue),
            (CYLTabBarControllerSwipeToSwitchTab, Values.boolValue),
            (CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning, Values.boolValue),
            (CYLTabBarControllerAutomaticPageRegistration, Values.boolValue),
        ]
        for (key, convert) in checked {
            guard let value = normalized[key] else { continue }
            let converted = convert(value)
            if converted == nil {
                Values.logInvalid(key, value)
            }
            normalized[key] = converted
        }
        if let value = normalized[CYLTabBarControllerPlusButton] {
            normalized[CYLTabBarControllerPlusButton] = Values.plusButtonAttributesValue(value)
        }
        // [EN] Lists of tab identifiers: an array of strings, or a comma-separated string. [CN] Tab 标识列表：字符串数组或逗号分隔的字符串。
        for key in [CYLTabBarControllerLoginRequiredTabBarItemIdentifiers, CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers] {
            guard let list = normalized[key] else { continue }
            let entries = (list as? String).map { $0.components(separatedBy: ",") as [Any] } ?? (list as? [Any])
            if entries == nil {
                Values.logInvalid(key, list)
            }
            normalized[key] = (entries ?? []).compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        }
        cylNormalizeTabs(&normalized)
        Values.warnUnknownKeys(normalized.keys, known: Values.knownConfigurationKeys)
        #if DEBUG
        if ((normalized[CYLTabBarControllerTabBarItemsAttributes] as? [Any])?.isEmpty ?? true),
           ((normalized[CYLTabBarControllerViewControllers] as? [Any])?.isEmpty ?? true) {
            NSLog("🔴 CYLTabBarController configuration: no tab; the tab bar controller will be empty.")
        }
        #endif
        if let value = normalized[CYLTabBarControllerImageInsets] {
            normalized[CYLTabBarControllerImageInsets] = Values.edgeInsetsValue(value, key: CYLTabBarControllerImageInsets)
        }
        if let value = normalized[CYLTabBarControllerTitlePositionAdjustment] {
            normalized[CYLTabBarControllerTitlePositionAdjustment] = Values.offsetValue(value, key: CYLTabBarControllerTitlePositionAdjustment)
        }
        if let value = normalized[CYLTabBarControllerStyleType] {
            normalized[CYLTabBarControllerStyleType] = Values.styleTypeValue(value)
        }
        if let context = normalized[CYLTabBarControllerContext] {
            if let number = context as? NSNumber, !(context is String) {
                normalized[CYLTabBarControllerContext] = number.stringValue
            } else if !(context is String) {
                Values.logInvalid(CYLTabBarControllerContext, context)
                normalized[CYLTabBarControllerContext] = nil
            }
        }
        return normalized
    }

    /**
     * [EN] The tabs: skins' "@name" values, the bar's icon defaults (#787), left-out tabs (B22), placeholders (B4) and
     *      unique identifiers (B12).
     * [CN] Tab：皮肤的 "@name" 值、TabBar 的图标默认值（#787）、被排除的 Tab（B22）、占位（B4）与唯一标识（B12）。
     */
    private class func cylNormalizeTabs(_ normalized: inout [String: Any]) {
        var themesInfo = normalized[CYLTabBarControllerThemes] != nil ? CYLConfigurationSkins.info(of: normalized) : nil
        let initialValues = themesInfo.flatMap { info in
            (info[Values.themesListKey] as? [String: [String: Any]])?[info[Values.themesInitialKey] as? String ?? ""]
        }
        var itemReferences: [[String: String]] = []
        var items = normalized[CYLTabBarControllerTabBarItemsAttributes]
        if items is NSDictionary {
            // [EN] One tab: Protobuf text and XML give a dictionary. [CN] 只有一个 Tab：Protobuf 文本与 XML 解析为字典。
            items = [items as Any]
        }
        var barIconDefaults: [String: Any] = [:]
        barIconDefaults[CYLTabBarItemIconRenderingMode] = normalized[CYLTabBarControllerIconRenderingMode]
        barIconDefaults[CYLTabBarItemIconColor] = normalized[CYLTabBarControllerIconColor]
        barIconDefaults[CYLTabBarItemSelectedIconColor] = normalized[CYLTabBarControllerSelectedIconColor]
        if let items {
            var normalizedItems: [[String: Any]] = []
            if let list = items as? [Any] {
                for element in list {
                    guard let item = element as? NSDictionary else {
                        // [EN] A placeholder keeps the indexes of view controllers passed in code (B4). [CN] 用占位保持与代码传入的子控制器的下标对应（B4）。
                        Values.logInvalid(CYLTabBarControllerTabBarItemsAttributes, element)
                        normalizedItems.append([:])
                        itemReferences.append([:])
                        continue
                    }
                    if (item[Values.plusSlotPlaceholderKey] as? NSNumber)?.boolValue == true {
                        // [EN] The slot's entry from an existing tab bar controller: inserted again, once (B26). [CN] 已有 TabBarController 的 slot 项：重新插入且只插入一次（B26）。
                        continue
                    }
                    var references: [String: String] = [:]
                    var source = initialValues.map { CYLConfigurationSkins.item(item, resolving: $0, references: &references) } ?? item
                    itemReferences.append(references)
                    if !barIconDefaults.isEmpty {
                        // FIX: issue #787 — the tab bar's icon defaults, for a tab without its own. [CN] TabBar 的图标默认值，用于没有单独设置的 Tab。
                        let withDefaults = NSMutableDictionary(dictionary: barIconDefaults)
                        withDefaults.addEntries(from: source as? [AnyHashable: Any] ?? [:])
                        source = withDefaults
                    }
                    var normalizedItem = Values.normalizedItemAttributes(source)
                    if let reason = Values.exclusionReason(normalizedItem) {
                        // [EN] A marked placeholder: the tab is left out (B22), kept for `cyl_skippedTabs`. [CN] 带标记的占位：该 Tab 被移除（B22），保留给 `cyl_skippedTabs`。
                        Values.debugLog("🟡 CYLTabBarController configuration: the tab \(normalizedItem[CYLTabBarItemTitle] as? String ?? "") is left out on this device: \(reason).")
                        var excluded: [String: Any] = [Values.excludedKey: true, Values.exclusionReasonKey: reason]
                        for key in [CYLTabBarItemTitle, CYLTabBarItemIdentifier, CYLTabBarItemPageIdentifier] {
                            excluded[key] = normalizedItem[key]
                        }
                        normalizedItem = excluded
                    }
                    normalizedItems.append(normalizedItem)
                }
            } else {
                Values.logInvalid(CYLTabBarControllerTabBarItemsAttributes, items)
            }
            Values.makeIdentifiersUnique(&normalizedItems)
            normalized[CYLTabBarControllerTabBarItemsAttributes] = normalizedItems
        }
        if var info = themesInfo {
            CYLConfigurationSkins.finish(&info, items: normalized[CYLTabBarControllerTabBarItemsAttributes] as? [[String: Any]] ?? [],
                                         itemReferences: itemReferences)
            themesInfo = info
            normalized[Values.themesKey] = info
        }
    }

    /** [EN] The path of a configuration file: a path, a file URL string, or a file name in the main bundle. [CN] 配置文件的路径：路径、文件 URL 字符串或 main bundle 中的文件名。 */
    private class func cylPathOfConfigurationFile(_ filePath: String) -> String {
        if filePath.hasPrefix("file:"), let path = URL(string: filePath)?.path, !path.isEmpty {
            return path
        }
        return Values.mainBundlePath((filePath as NSString).expandingTildeInPath)
    }

    @objc(configurationWithContentsOfFile:error:)
    class func cylConfiguration(contentsOfFile filePath: Any?) throws -> [String: Any] {
        let path = (filePath as? String).map { cylPathOfConfigurationFile($0) } ?? ""
        var configuration = try CYLTabBarConfigurationParser.dictionary(withContentsOfFile: path)
        if let error = Values.tabsError(configuration) {
            throw error
        }
        if configuration[CYLTabBarControllerLocalization] != nil {
            // [EN] A relative `CYLTabBarLocalizationPath` is resolved against this file's folder. [CN] 相对的 `CYLTabBarLocalizationPath` 相对于本文件所在目录。
            configuration[Values.fileDirectoryKey] = (path as NSString).deletingLastPathComponent
        }
        return configuration
    }

    /** [EN] The path of a route, or a file-not-found error. [CN] 路由对应的路径；没有时抛出“文件不存在”错误。 */
    @objc(cyl_pathOfConfigurationRoute:error:)
    class func cylPathOfConfigurationRoute(_ route: Any?) throws -> String {
        let routeString = route as? String
        guard let path = routeString.flatMap({ CYLResourceRoute.path(forRoute: $0, baseDirectory: nil) }), !path.isEmpty,
              FileManager.default.fileExists(atPath: path) else {
            throw Values.error(.fileNotFound, "No configuration file matches the route \"\(routeString ?? "")\".")
        }
        return path
    }

    @objc(configurationWithRoute:error:)
    class func cylConfiguration(route: Any?) throws -> [String: Any] {
        try cylConfiguration(contentsOfFile: cylPathOfConfigurationRoute(route))
    }

    /** [EN] The no-pages error for `-initWithConfigurationFile:error:` and the loaders (C11). [CN] 供 `-initWithConfigurationFile:error:` 与加载方法使用的“没有页面”错误（C11）。 */
    @objc(cyl_configurationPagesErrorForTabBarController:)
    class func cylConfigurationPagesError(for tabBarController: UITabBarController?) -> NSError? {
        Values.pagesError(tabBarController)
    }

    /** [EN] The main-thread error of `-initWithConfigurationFile:error:` (E1). [CN] `-initWithConfigurationFile:error:` 的主线程错误（E1）。 */
    @objc(cyl_configurationMainThreadError)
    class func cylConfigurationMainThreadError() -> NSError {
        Values.error(.mainThreadRequired, "A tab bar controller can only be created on the main thread; read the dictionary in the background with +configurationWithContentsOfFile:error:.")
    }

    // MARK: Values for CYLTabBarConfigurationTheme

    @objc(cyl_configurationColorValue:)
    class func cylConfigurationColorValue(_ value: Any?) -> UIColor? {
        Values.colorValue(value)
    }

    @objc(cyl_configurationFontValue:)
    class func cylConfigurationFontValue(_ value: Any?) -> UIFont? {
        value.flatMap { Values.fontValue($0) }
    }

    @objc(cyl_configurationImageValue:)
    class func cylConfigurationImageValue(_ value: Any?) -> Any? {
        value.map { Values.imageValue($0) }
    }

    @objc(cyl_configurationStringValue:)
    class func cylConfigurationStringValue(_ value: Any?) -> String? {
        Values.stringValue(value)
    }

    @objc(cyl_normalizedItemAttributes:)
    class func cylNormalizedItemAttributes(_ attributes: NSDictionary) -> [String: Any] {
        Values.normalizedItemAttributes(attributes)
    }

    @objc(cyl_logInvalidConfigurationValue:forKey:)
    class func cylLogInvalidConfigurationValue(_ value: Any?, forKey key: String) {
        Values.logInvalid(key, value)
    }

    // MARK: Skins

    @objc(cyl_applyConfigurationThemes:)
    func cylApplyConfigurationThemes(_ normalizedConfiguration: [String: Any]) {
        guard let info = normalizedConfiguration[Values.themesKey] as? [String: Any] else { return }
        if let managerName = info[Values.themesManagerKey] as? String {
            cylSetThemeManager(CYLThemeManagerCenter.themeManager(withName: managerName as NSString))
        }
        let manager = cylThemeManager()
        let themes = info[Values.themesListKey] as? [CYLTabBarConfigurationTheme] ?? []
        for theme in themes {
            manager.addThemeIdentifier(theme.identifier as NSString, theme: theme)
        }
        let base = info[Values.themesBaseKey] as? String
        let dark = info[Values.themesDarkKey] as? String
        var current = manager.currentThemeIdentifier
        // [EN] A skin of an earlier configuration that this one does not have is not a choice to keep (React Native, Flutter).
        // [CN] 之前配置中的皮肤、而本配置中没有，不属于需要保留的选择（React Native、Flutter）。
        let listed = themes.contains { current?.isEqual($0.identifier) == true }
        let staleConfigurationSkin = !listed && manager.currentTheme is CYLTabBarConfigurationTheme
        // [EN] A skin the app or the user chose before stays; otherwise the first one. [CN] App 或用户之前选择的皮肤保持不变；否则使用首个皮肤。
        if current == nil || staleConfigurationSkin {
            manager.currentThemeIdentifier = (info[Values.themesInitialKey] as? String).map { $0 as NSString }
            current = staleConfigurationSkin ? nil : current
        }
        // [EN] Dark Mode follows the system, unless the manager follows it its own way or another skin was chosen.
        // [CN] 深色模式跟随系统，除非管理器有自己的跟随方式，或已选择了其他皮肤。
        let keepsChoice = current.map { !$0.isEqual(base) && !$0.isEqual(dark) } ?? false
        if let dark, manager.identifierForTrait == nil, !keepsChoice {
            let baseIdentifier = (base ?? "") as NSString
            manager.identifierForTrait = { trait in trait.userInterfaceStyle == .dark ? dark as NSString : baseIdentifier }
            manager.respondsSystemStyleAutomatically = true
        }
    }

    // MARK: URLs

    /** [EN] Loads a local (file URL) or missing configuration URL and calls `completion` on the main queue. [CN] 加载本地（file URL）或缺失的配置 URL，并在主队列回调 `completion`。 */
    private class func cylLoadLocalConfiguration(_ url: URL?, completion: @escaping ([String: Any]?, Error?) -> Void) {
        var configuration: [String: Any]?
        var loadError: Error?
        if let url {
            do {
                // [EN] A file URL's path can be empty (C10). [CN] file URL 的 path 可能为空（C10）。
                configuration = try cylConfiguration(contentsOfFile: url.path)
            } catch {
                loadError = error
            }
        } else {
            loadError = Values.error(.fileNotFound, "No configuration URL.")
        }
        let result = configuration
        let failure = loadError
        DispatchQueue.main.async {
            completion(result, failure)
        }
    }

    @objc(loadConfigurationWithURL:completion:)
    @discardableResult
    class func cylLoadConfiguration(url: URL?, completion: (([String: Any]?, Error?) -> Void)?) -> URLSessionDataTask? {
        guard let completion else { return nil }
        guard let url, !url.isFileURL else {
            cylLoadLocalConfiguration(url, completion: completion)
            return nil
        }
        let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: cylConfigurationRequestTimeout)
        return cylLoadConfiguration(request: request, completion: completion)
    }

    @objc(loadConfigurationWithURLRequest:completion:)
    @discardableResult
    class func cylLoadConfiguration(request: URLRequest?, completion: (([String: Any]?, Error?) -> Void)?) -> URLSessionDataTask? {
        guard let completion else { return nil }
        guard let request, let url = request.url, !url.isFileURL else {
            cylLoadLocalConfiguration(request?.url, completion: completion)
            return nil
        }
        let task = URLSession.shared.dataTask(with: request) { data, response, networkError in
            var configuration: [String: Any]?
            var loadError: Error?
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 200
            if let data, networkError == nil, statusCode < 400 {
                var format = CYLTabBarConfigurationParser.format(forPathExtension: url.pathExtension)
                if format == .unknown {
                    format = CYLTabBarConfigurationParser.format(forMIMEType: response?.mimeType)
                }
                do {
                    let parsed = try CYLTabBarConfigurationParser.dictionary(with: data, format: format)
                    if let tabsError = Values.tabsError(parsed) {
                        loadError = tabsError
                    } else {
                        configuration = parsed
                    }
                } catch {
                    loadError = error
                }
            } else {
                loadError = Values.error(.network, "The configuration could not be downloaded from \(url.absoluteString) (HTTP \(statusCode)).",
                                         underlying: networkError)
            }
            let result = configuration
            let failure = loadError
            DispatchQueue.main.async {
                completion(result, failure)
            }
        }
        task.resume()
        return task
    }
}
