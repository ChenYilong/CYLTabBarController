//
//  CYLTabBarManifest.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CryptoKit

/**
 * [EN] Where the manifest a loader applied came from.
 * [CN] 加载器所应用的清单的来源。
 */
@objc public enum CYLTabBarManifestSource: Int {
    /**
     * [EN] No manifest.
     * [CN] 没有清单。
     */
    case none = 0
    /**
     * [EN] Downloaded now.
     * [CN] 本次下载。
     */
    case remote = 1
    /**
     * [EN] A manifest downloaded earlier.
     * [CN] 之前下载的清单。
     */
    case cache = 2
    /**
     * [EN] The manifest shipped with the app.
     * [CN] 随 App 发布的清单。
     */
    case embedded = 3
}

/**
 * [EN] Short names for the configuration keys the manifest writes (the constants of `CYLConstants+Keys.swift`). Was a seam
 *      with copied strings until the constants moved to Swift (docs/Swift-Migration.md).
 * [CN] 清单写入的配置键的简称（即 `CYLConstants+Keys.swift` 中的常量）。在常量迁移到 Swift 之前是复制字符串的接缝
 *      （docs/Swift-Migration.md）。
 */
enum CYLConfigurationKeys {
    static let styleType = CYLTabBarControllerStyleType
    static let itemsAttributes = CYLTabBarControllerTabBarItemsAttributes
    static let themes = CYLTabBarControllerThemes
    static let themeIdentifier = CYLTabBarControllerThemeIdentifier
    static let darkThemeIdentifier = CYLTabBarControllerDarkThemeIdentifier
    static let themeManagerName = CYLTabBarControllerThemeManagerName
    static let plusButton = CYLTabBarControllerPlusButton
    static let context = CYLTabBarControllerContext
    static let localization = CYLTabBarControllerLocalization
    static let itemIdentifier = CYLTabBarItemIdentifier
    static let itemTitle = CYLTabBarItemTitle
    static let itemImage = CYLTabBarItemImage
    static let itemSelectedImage = CYLTabBarItemSelectedImage
    static let itemPageIdentifier = CYLTabBarItemPageIdentifier
    static let itemMinimumAppVersion = CYLTabBarItemMinimumAppVersion
    static let itemTitleColor = CYLTabBarItemTitleColor
    static let itemSelectedTitleColor = CYLTabBarItemSelectedTitleColor
    static let backgroundColor = CYLTabBarBackgroundColor
    static let plusButtonBackgroundImage = CYLPlusButtonBackgroundImage
    static let plusButtonIndexInTabBar = CYLPlusButtonIndexInTabBar
    static let plusButtonSize = CYLPlusButtonSize
    static let localizationTableName = CYLTabBarLocalizationTableName
    static let localizationPath = CYLTabBarLocalizationPath
}

/**
 * [EN] Reading a manifest's values, versions, dates and conditions (Firebase Remote Config's expression subset).
 * [CN] 读取清单的值、版本、日期与条件（Firebase Remote Config 表达式的子集）。
 */
enum CYLManifestValues {

    static let assetNamePrefix = "cyl.asset."

    static func error(_ code: CYLTabBarConfigurationErrorCode, _ description: String) -> NSError {
        NSError(domain: CYLTabBarConfigurationErrorDomain, code: code.rawValue, userInfo: [NSLocalizedDescriptionKey: description])
    }

    static func dictionary(_ container: Any?, _ key: String) -> [String: Any]? {
        (container as? [String: Any])?[key] as? [String: Any]
    }

    static func array(_ container: Any?, _ key: String) -> [Any]? {
        (container as? [String: Any])?[key] as? [Any]
    }

    /**
     * [EN] A non-empty trimmed string (a number gives its string), or nil.
     * [CN] 去除空白后的非空字符串（数字取其字符串），否则为 nil。
     */
    static func string(_ container: Any?, _ key: String) -> String? {
        let value = (container as? [String: Any])?[key]
        if let number = value as? NSNumber {
            return number.stringValue
        }
        guard let text = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return nil
        }
        return text
    }

    static func compareVersions(_ first: String, _ second: String) -> ComparisonResult {
        let a = first.components(separatedBy: ".")
        let b = second.components(separatedBy: ".")
        for index in 0..<max(a.count, b.count) {
            let x = index < a.count ? (a[index] as NSString).integerValue : 0
            let y = index < b.count ? (b[index] as NSString).integerValue : 0
            if x != y {
                return x < y ? .orderedAscending : .orderedDescending
            }
        }
        return .orderedSame
    }

    static var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    static func platforms(_ value: Any?) -> [String] {
        let items: [Any] = (value as? [Any]) ?? (value as? String)?.components(separatedBy: ",") ?? []
        return items.compactMap { item in
            guard let name = (item as? String)?.trimmingCharacters(in: .whitespaces).lowercased(), !name.isEmpty else {
                return nil
            }
            return name
        }
    }

    static func platformsAllowIOS(_ value: Any?) -> Bool {
        let list = platforms(value)
        return list.isEmpty || list.contains("all") || list.contains("ios")
    }

    static func date(_ text: String?) -> Date? {
        guard let text, !text.isEmpty else {
            return nil
        }
        return ISO8601DateFormatter().date(from: text)
    }

    static func merge(_ base: Any?, _ override: Any?) -> Any? {
        guard let baseDictionary = base as? [String: Any], let overrideDictionary = override as? [String: Any] else {
            return override
        }
        var merged = baseDictionary
        for (key, value) in overrideDictionary {
            merged[key] = merge(baseDictionary[key], value)
        }
        return merged
    }

    // MARK: - Conditions

    private static var percentile: Int {
        let key = "CYLTabBarManifestPercentile"
        let defaults = UserDefaults.standard
        if defaults.object(forKey: key) == nil {
            defaults.set(Int(arc4random_uniform(100)), forKey: key)
        }
        return defaults.integer(forKey: key)
    }

    private static func quoted(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespaces) as NSString
        if trimmed.length >= 2 && (trimmed.hasPrefix("'") || trimmed.hasPrefix("\"")) {
            return trimmed.substring(with: NSRange(location: 1, length: trimmed.length - 2))
        }
        return trimmed as String
    }

    private static func compare(_ order: ComparisonResult, _ operation: String) -> Bool {
        switch operation {
        case "==": return order == .orderedSame
        case "!=": return order != .orderedSame
        case ">=": return order != .orderedAscending
        case "<=": return order != .orderedDescending
        case ">": return order == .orderedDescending
        case "<": return order == .orderedAscending
        default: return false
        }
    }

    private static func match(_ pattern: String, _ text: String) -> [String]? {
        guard let expression = try? NSRegularExpression(pattern: pattern),
              let result = expression.firstMatch(in: text, range: NSRange(location: 0, length: (text as NSString).length)) else {
            return nil
        }
        return (0..<result.numberOfRanges).map { (text as NSString).substring(with: result.range(at: $0)) }
    }

    private static func elementHolds(_ element: String) -> Bool {
        let text = element.trimmingCharacters(in: .whitespaces)
        if let parts = match("^(device\\.os|app\\.version|percent)\\s*(==|!=|>=|<=|>|<)\\s*(.+)$", text) {
            let subject = parts[1]
            let operation = parts[2]
            let value = quoted(parts[3])
            if subject == "device.os" {
                let os = value.lowercased()
                let isIOS = os == "ios" || os == "apple"
                return operation == "==" ? isIOS : (operation == "!=" ? !isIOS : false)
            }
            if subject == "app.version" {
                return compare(compareVersions(appVersion, value), operation)
            }
            let current = percentile
            let limit = (value as NSString).integerValue
            return compare(current < limit ? .orderedAscending : (current > limit ? .orderedDescending : .orderedSame), operation)
        }
        if let parts = match("^percent\\s+between\\s+(\\d+)\\s+and\\s+(\\d+)$", text) {
            let current = percentile
            return current >= (parts[1] as NSString).integerValue && current <= (parts[2] as NSString).integerValue
        }
        if let parts = match("^device\\.language\\s+in\\s+\\[(.*)\\]$", text) {
            let current = CYLLocalizationLanguage().lowercased()
            for item in parts[1].components(separatedBy: ",") {
                let wanted = quoted(item).lowercased()
                if !wanted.isEmpty && (current == wanted || current.hasPrefix(wanted + "-")) {
                    return true
                }
            }
            return false
        }
        #if DEBUG
        NSLog("🟡 CYLTabBarManifest: unknown condition \"%@\" is false.", text)
        #endif
        return false
    }

    static func expressionHolds(_ expression: String?) -> Bool {
        guard let expression, !expression.isEmpty else {
            return false
        }
        return expression.components(separatedBy: "&&").allSatisfy(elementHolds)
    }

    /**
     * [EN] `sha256-` and the URL-safe Base64 (no padding) of the SHA-256 of `data`.
     * [CN] `sha256-` 加上 `data` 的 SHA-256 的 URL 安全 Base64（无填充）。
     */
    static func hash(of data: Data) -> String {
        let base64 = Data(SHA256.hash(data: data)).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-").replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return "sha256-" + base64
    }
}

/**
 * [EN] A tab bar manifest (schema version 1): tabs, themes, assets with hashes, runtime limits and conditional overrides,
 *      turned into a configuration of `CYLTabBarController` (docs/Configuration-Manifest.md). Translated from Objective-C
 *      (docs/Swift-Migration.md); Objective-C callers get this class from `CYLSwiftInterface.h`. Compatibility note:
 *      `-tabBarControllerWithError:` now returns a `UITabBarController` (always a `CYLTabBarController`), as the Swift layer
 *      cannot name the Objective-C class.
 * [CN] TabBar 清单（结构版本 1）：Tab、主题、带哈希的资源、运行条件与条件覆盖，转换为 `CYLTabBarController` 的配置
 *      （docs/Configuration-Manifest.md）。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 调用方通过 `CYLSwiftInterface.h`
 *      使用本类。兼容性说明：`-tabBarControllerWithError:` 现在返回 `UITabBarController`（实际总是 `CYLTabBarController`），因为 Swift 层
 *      无法引用该 Objective-C 类。
 */
@objc(CYLTabBarManifest)
public class CYLTabBarManifest: NSObject {

    private typealias Values = CYLManifestValues
    private typealias Keys = CYLConfigurationKeys

    /**
     * [EN] The schema version this library reads.
     * [CN] 本库读取的结构版本。
     */
    @objc public class var supportedSchemaVersion: Int {
        1
    }

    /**
     * [EN] The manifest with the overrides of the conditions that hold merged in.
     * [CN] 合并了成立条件的覆盖值之后的清单。
     */
    @objc public let dictionary: [String: Any]

    /**
     * [EN] The folder relative asset and localization routes are resolved from.
     * [CN] 解析相对资源路由与本地化路由的目录。
     */
    @objc public let baseDirectory: String?

    private init(merged: [String: Any], baseDirectory: String?) {
        dictionary = merged
        self.baseDirectory = baseDirectory
        super.init()
    }

    /**
     * [EN] A manifest from its dictionary; throws `.unsupportedManifest` without a "tabBar" dictionary or for another
     *      schema version.
     * [CN] 由字典创建清单；没有 "tabBar" 字典或结构版本不同时抛出 `.unsupportedManifest`。
     */
    public convenience init(dictionary: [String: Any], baseDirectory: String?) throws {
        try self.init(merged: CYLTabBarManifest.merged(dictionary), baseDirectory: baseDirectory)
    }

    /**
     * [EN] The manifest file a resource route points to.
     * [CN] 资源路由指向的清单文件。
     */
    public convenience init(route: String) throws {
        guard let path = CYLResourceRoute.path(forRoute: route, baseDirectory: nil), !path.isEmpty,
              FileManager.default.fileExists(atPath: path) else {
            throw Values.error(.fileNotFound, "No manifest matches the route \"\(route)\".")
        }
        let dictionary = try CYLTabBarConfigurationParser.dictionary(withContentsOfFile: path)
        try self.init(dictionary: dictionary, baseDirectory: (path as NSString).deletingLastPathComponent)
    }

    /**
     * [EN] The Objective-C entry of `init(dictionary:baseDirectory:)`.
     * [CN] `init(dictionary:baseDirectory:)` 的 Objective-C 入口。
     */
    @objc(manifestWithDictionary:baseDirectory:error:)
    public class func manifest(withDictionary dictionary: [String: Any], baseDirectory: String?) throws -> CYLTabBarManifest {
        try CYLTabBarManifest(dictionary: dictionary, baseDirectory: baseDirectory)
    }

    /**
     * [EN] The Objective-C entry of `init(route:)`.
     * [CN] `init(route:)` 的 Objective-C 入口。
     */
    @objc(manifestWithRoute:error:)
    public class func manifest(withRoute route: String) throws -> CYLTabBarManifest {
        try CYLTabBarManifest(route: route)
    }

    /**
     * [EN] The `sha256-…` hash of asset data, as in the manifest's "hash"; internal (the tests call it by its selector).
     * [CN] 资源数据的 `sha256-…` 哈希，与清单 "hash" 字段相同；内部使用（测试通过 selector 调用）。
     */
    @objc(hashOfData:)
    class func hash(ofData data: Data) -> String {
        Values.hash(of: data)
    }

    private static func merged(_ dictionary: [String: Any]) throws -> [String: Any] {
        guard dictionary["tabBar"] is [String: Any] else {
            throw Values.error(.unsupportedManifest, "Not a tab bar manifest: it has no \"tabBar\" dictionary.")
        }
        let schema = dictionary["schemaVersion"]
        let schemaNumber = (schema as? NSNumber)?.intValue ?? (schema as? NSString)?.integerValue
        guard schemaNumber == supportedSchemaVersion else {
            throw Values.error(.unsupportedManifest, "schemaVersion \(schema.map { "\($0)" } ?? "(missing)") is not supported "
                                                     + "(this library reads \(supportedSchemaVersion)).")
        }
        var merged = dictionary
        let overrides = Values.array(dictionary, "overrides") ?? []
        for condition in Values.array(dictionary, "conditions") ?? [] {
            guard let name = Values.string(condition, "name"), Values.expressionHolds(Values.string(condition, "expression")) else {
                continue
            }
            for case var values as [String: Any] in overrides where Values.string(values, "condition") == name {
                values.removeValue(forKey: "condition")
                merged = Values.merge(merged, values) as? [String: Any] ?? merged
            }
        }
        return merged
    }

    /**
     * [EN] The manifest's "id".
     * [CN] 清单的 "id"。
     */
    @objc public var identifier: String? {
        Values.string(dictionary, "id")
    }

    /**
     * [EN] The manifest's "version".
     * [CN] 清单的 "version"。
     */
    @objc public var version: String? {
        Values.string(dictionary, "version")
    }

    /**
     * [EN] Throws `.notEligible` when the runtime limits (platforms, app versions, start and end time) exclude `date`.
     * [CN] 运行条件（平台、App 版本、开始与结束时间）排除 `date` 时抛出 `.notEligible`。
     */
    @objc(isEligibleAtDate:error:)
    public func isEligible(at date: Date) throws {
        let runtime = Values.dictionary(dictionary, "runtime")
        let appVersion = Values.appVersion
        let minimum = Values.string(runtime, "minAppVersion")
        let maximum = Values.string(runtime, "maxAppVersion")
        let start = Values.date(Values.string(runtime, "startTime"))
        let end = Values.date(Values.string(runtime, "endTime"))
        var reason: String?
        if !Values.platformsAllowIOS(runtime?["platforms"]) {
            reason = "runtime.platforms \(Values.platforms(runtime?["platforms"])) does not include ios."
        } else if let minimum, Values.compareVersions(appVersion, minimum) == .orderedAscending {
            reason = "It needs app version \(minimum) or later (this app is \(appVersion))."
        } else if let maximum, Values.compareVersions(appVersion, maximum) == .orderedDescending {
            reason = "It is for app version \(maximum) or earlier (this app is \(appVersion))."
        } else if let start, date < start {
            reason = "It starts at \(Values.string(runtime, "startTime") ?? "")."
        } else if let end, date >= end {
            reason = "It ended at \(Values.string(runtime, "endTime") ?? "")."
        }
        if let reason {
            throw Values.error(.notEligible, reason)
        }
    }

    // MARK: - Assets

    private var assetsDirectory: String? {
        let route = Values.string(Values.dictionary(dictionary, "assets"), "baseRoute") ?? ""
        return CYLResourceRoute.path(forRoute: route.isEmpty ? "." : route, baseDirectory: baseDirectory)
    }

    var assetEntries: [[String: Any]] {
        let list = Values.array(Values.dictionary(dictionary, "assets"), "list") ?? []
        return list.compactMap { $0 as? [String: Any] }.filter {
            Values.string($0, "key") != nil && Values.string($0, "path") != nil && Values.platformsAllowIOS($0["platforms"])
        }
    }

    /**
     * [EN] The path of an asset entry, nil when it would leave the assets folder.
     * [CN] 资源条目的路径；会离开资源目录时为 nil。
     */
    func path(ofEntry entry: [String: Any]) -> String? {
        guard let directory = (assetsDirectory as NSString?)?.standardizingPath,
              let relative = Values.string(entry, "path") else {
            return nil
        }
        let path = ((directory as NSString).appendingPathComponent(relative) as NSString).standardizingPath
        return path.hasPrefix(directory + "/") ? path : nil
    }

    private var defaultTheme: String? {
        Values.string(Values.dictionary(dictionary, "themes"), "default")
    }

    /**
     * [EN] The path of the asset `key` for a theme and a state, falling back to the default theme, any theme and the
     *      normal state; only existing files.
     * [CN] 资源 `key` 在某主题与状态下的路径，依次回退到默认主题、任意主题与 normal 状态；只返回存在的文件。
     */
    @objc(pathOfAssetWithKey:theme:state:)
    public func pathOfAsset(withKey key: String, theme: String?, state: String?) -> String? {
        let wantedState = state?.isEmpty == false ? state ?? "normal" : "normal"
        let wantedTheme = theme?.isEmpty == false ? theme : defaultTheme
        var attempts: [(theme: String, state: String)] = []
        for candidate in [wantedTheme ?? "", defaultTheme ?? "", "*"] {
            attempts.append((candidate, wantedState))
            attempts.append((candidate, "normal"))
        }
        let entries = assetEntries
        for attempt in attempts {
            for entry in entries {
                let entryTheme = Values.string(entry, "theme") ?? ""
                let entryState = Values.string(entry, "state") ?? "normal"
                let themeMatches = attempt.theme == "*" || entryTheme == attempt.theme
                guard Values.string(entry, "key") == key, themeMatches, entryState == attempt.state else {
                    continue
                }
                if let path = path(ofEntry: entry), FileManager.default.fileExists(atPath: path) {
                    return path
                }
            }
        }
        return nil
    }

    /**
     * [EN] The path of an `asset:<key>?theme=…&state=…` reference.
     * [CN] `asset:<key>?theme=…&state=…` 引用对应的路径。
     */
    @objc(pathForAssetReference:)
    public func path(forAssetReference reference: String) -> String? {
        guard reference.hasPrefix("asset:") else {
            return nil
        }
        let rest = String(reference.dropFirst("asset:".count))
        let parts = rest.split(separator: "?", maxSplits: 1, omittingEmptySubsequences: false)
        let key = String(parts.first ?? "")
        var components = URLComponents()
        components.percentEncodedQuery = parts.count > 1 ? String(parts[1]) : nil
        let items = components.queryItems ?? []
        let theme = items.last { $0.name == "theme" }?.value
        let state = items.last { $0.name == "state" }?.value
        return key.isEmpty ? nil : pathOfAsset(withKey: key, theme: theme, state: state)
    }

    /**
     * [EN] Throws `.assetInvalid` when an asset is missing or does not match its hash.
     * [CN] 资源缺失或与哈希不符时抛出 `.assetInvalid`。
     */
    @objc(verifyAssetsWithError:)
    public func verifyAssets() throws {
        for entry in assetEntries {
            let name = Values.string(entry, "path") ?? ""
            guard let path = path(ofEntry: entry), let data = FileManager.default.contents(atPath: path) else {
                throw Values.error(.assetInvalid, "Asset \(name) is missing.")
            }
            if let hash = Values.string(entry, "hash"), hash != Values.hash(of: data) {
                throw Values.error(.assetInvalid, "Asset \(name) does not match its hash.")
            }
        }
    }

    // MARK: - Configuration

    private func resolvedValue(_ value: Any?, theme: String?) -> Any? {
        guard let text = value as? String, text.hasPrefix("@") else {
            return value
        }
        let name = String(text.dropFirst())
        let list = Values.dictionary(Values.dictionary(dictionary, "themes"), "list")
        let themed = theme.flatMap { Values.dictionary(list, $0)?[name] }
        return themed ?? defaultTheme.flatMap { Values.dictionary(list, $0)?[name] }
    }

    private func imagePath(for value: Any?, theme: String?) -> String? {
        guard let resolved = resolvedValue(value, theme: theme) as? String, !resolved.isEmpty else {
            return nil
        }
        if resolved.hasPrefix("asset:") {
            var reference = resolved
            if let theme, !theme.isEmpty, !reference.contains("theme=") {
                reference += (reference.contains("?") ? "&" : "?") + "theme=\(theme)"
            }
            return path(forAssetReference: reference)
        }
        guard let path = CYLResourceRoute.path(forRoute: resolved, baseDirectory: baseDirectory),
              FileManager.default.fileExists(atPath: path) else {
            return nil
        }
        return path
    }

    private func itemIsForThisApp(_ item: [String: Any]) -> Bool {
        guard Values.platformsAllowIOS(item["platforms"]) else {
            return false
        }
        let maximum = Values.string(item, "maxAppVersion")
        return !(maximum.map { Values.compareVersions(Values.appVersion, $0) == .orderedDescending } ?? false)
    }

    /**
     * [EN] The `CYLTabBarController` configuration of this manifest (keys of `CYLTabBarController.h`).
     * [CN] 本清单对应的 `CYLTabBarController` 配置（`CYLTabBarController.h` 中的键）。
     */
    @objc public func configuration() -> [String: Any] {
        let tabBar = Values.dictionary(dictionary, "tabBar")
        let themes = Values.dictionary(dictionary, "themes")
        let themeList = Values.dictionary(themes, "list") ?? [:]
        var configuration: [String: Any] = [:]
        configuration[Keys.styleType] = Values.string(tabBar, "styleType")
        var items: [[String: Any]] = []
        var imageItems: [[String: Any]] = []
        for case let item as [String: Any] in Values.array(tabBar, "list") ?? [] {
            if (item["visible"] as? NSNumber) == NSNumber(value: false) || !itemIsForThisApp(item) {
                continue
            }
            var attributes: [String: Any] = [:]
            attributes[Keys.itemIdentifier] = Values.string(item, "key")
            attributes[Keys.itemTitle] = Values.string(item, "text")
            attributes[Keys.itemPageIdentifier] = Values.string(item, "pagePath")
            attributes[Keys.itemMinimumAppVersion] = Values.string(item, "minAppVersion")
            items.append(attributes)
            imageItems.append(item)
        }
        let defaultTheme = self.defaultTheme ?? themeList.keys.first
        if !themeList.isEmpty {
            var compiled: [String: Any] = [:]
            let barKeys = ["color": Keys.itemTitleColor, "selectedColor": Keys.itemSelectedTitleColor,
                           "backgroundColor": Keys.backgroundColor]
            for theme in themeList.keys {
                var values = Values.dictionary(themeList, theme) ?? [:]
                for (manifestKey, configurationKey) in barKeys {
                    if let color = resolvedValue(tabBar?[manifestKey], theme: theme) {
                        values[configurationKey] = color
                    }
                }
                for item in imageItems {
                    let key = Values.string(item, "key") ?? ""
                    let normal = imagePath(for: item["iconPath"], theme: theme)
                    let selected = imagePath(for: item["selectedIconPath"], theme: theme) ?? normal
                    values["\(Values.assetNamePrefix)\(key).normal"] = normal
                    values["\(Values.assetNamePrefix)\(key).selected"] = selected
                }
                compiled[theme] = values
            }
            configuration[Keys.themes] = compiled
            configuration[Keys.themeIdentifier] = defaultTheme
            configuration[Keys.themeManagerName] = Values.string(themes, "managerName")
            if let darkTheme = Values.string(themes, "darkMode"), themeList[darkTheme] != nil {
                configuration[Keys.darkThemeIdentifier] = darkTheme
            }
            for index in items.indices {
                let key = Values.string(imageItems[index], "key") ?? ""
                items[index][Keys.itemImage] = "@\(Values.assetNamePrefix)\(key).normal"
                items[index][Keys.itemSelectedImage] = "@\(Values.assetNamePrefix)\(key).selected"
            }
        } else {
            for index in items.indices {
                items[index][Keys.itemImage] = imagePath(for: imageItems[index]["iconPath"], theme: nil)
                items[index][Keys.itemSelectedImage] = imagePath(for: imageItems[index]["selectedIconPath"], theme: nil)
            }
        }
        configuration[Keys.itemsAttributes] = items
        if let midButton = Values.dictionary(tabBar, "midButton"), itemIsForThisApp(midButton) {
            configuration[Keys.plusButton] = plusButtonAttributes(midButton, defaultTheme: defaultTheme)
            configuration[Keys.context] = "CYLTabBarManifest:" + (identifier ?? "manifest")
        }
        if let localization = Values.dictionary(dictionary, "localization") {
            var value: [String: Any] = [:]
            value[Keys.localizationTableName] = Values.string(localization, "tableName")
            if let route = Values.string(localization, "route") {
                value[Keys.localizationPath] = CYLResourceRoute.path(forRoute: route, baseDirectory: baseDirectory)
            }
            configuration[Keys.localization] = value
        }
        return configuration
    }

    private func plusButtonAttributes(_ midButton: [String: Any], defaultTheme: String?) -> [String: Any] {
        var plus: [String: Any] = [:]
        plus[Keys.itemIdentifier] = Values.string(midButton, "key")
        plus[Keys.itemTitle] = Values.string(midButton, "text")
        plus[Keys.itemImage] = imagePath(for: midButton["iconPath"], theme: defaultTheme)
        plus[Keys.plusButtonBackgroundImage] = imagePath(for: midButton["backgroundImage"], theme: defaultTheme)
        if let index = CYLTabBarManifest.number(midButton["index"]) {
            plus[Keys.plusButtonIndexInTabBar] = NSNumber(value: index.intValue)
        }
        if let width = CYLTabBarManifest.number(midButton["width"]), let height = CYLTabBarManifest.number(midButton["height"]) {
            plus[Keys.plusButtonSize] = String(format: "{%g, %g}", width.doubleValue, height.doubleValue)
        }
        if Values.string(midButton, "action") != "callback" {
            plus[Keys.itemPageIdentifier] = Values.string(midButton, "pagePath")
        }
        return plus
    }

    /**
     * [EN] A number, or a string read as one (as `-integerValue` / `-doubleValue` did).
     * [CN] 数字，或可读作数字的字符串（与 `-integerValue` / `-doubleValue` 相同）。
     */
    private static func number(_ value: Any?) -> NSNumber? {
        if let number = value as? NSNumber {
            return number
        }
        if let text = value as? NSString {
            return NSNumber(value: text.doubleValue)
        }
        return nil
    }

    /**
     * [EN] A `CYLTabBarController` (returned as `UITabBarController`) made from `configuration()`; main thread only; throws
     *      `.noPages` when no tab found its page.
     * [CN] 由 `configuration()` 创建的 `CYLTabBarController`（以 `UITabBarController` 返回）；仅限主线程；没有 Tab 找到页面时抛出
     *      `.noPages`。
     */
    @objc(tabBarControllerWithError:)
    public func tabBarController() throws -> UITabBarController {
        guard Thread.isMainThread else {
            throw Values.error(.mainThreadRequired, "A tab bar controller can only be created on the main thread.")
        }
        // [EN] Seam (docs/Swift-Migration.md): `+[CYLTabBarController tabBarControllerWithConfiguration:]` by selector.
        // [CN] 接缝（docs/Swift-Migration.md）：通过 selector 调用 `+[CYLTabBarController tabBarControllerWithConfiguration:]`。
        let selector = NSSelectorFromString("tabBarControllerWithConfiguration:")
        let controllerClass = NSClassFromString("CYLTabBarController") as AnyObject?
        let made = controllerClass?.responds(to: selector) == true
            ? controllerClass?.perform(selector, with: configuration())?.takeUnretainedValue() as? UITabBarController
            : nil
        guard let tabBarController = made, tabBarController.viewControllers?.isEmpty == false else {
            throw Values.error(.noPages, "No tab of the manifest found its page: register the pages first "
                                         + "(docs/Tab-Page-Registry.md).")
        }
        return tabBarController
    }
}

/**
 * [EN] Called by `CYLTabBarManifestLoader` before and after it applies a manifest, and when the download fails.
 * [CN] `CYLTabBarManifestLoader` 在应用清单前后以及下载失败时调用。
 */
@objc(CYLTabBarManifestLoaderDelegate)
public protocol CYLTabBarManifestLoaderDelegate: NSObjectProtocol {
    /**
     * [EN] Whether to apply `manifest` (default true).
     * [CN] 是否应用 `manifest`（默认 true）。
     */
    @objc(manifestLoader:shouldApplyManifest:source:)
    optional func manifestLoader(_ loader: CYLTabBarManifestLoader, shouldApply manifest: CYLTabBarManifest,
                                 source: CYLTabBarManifestSource) -> Bool
    /**
     * [EN] `manifest` was applied.
     * [CN] 已应用 `manifest`。
     */
    @objc(manifestLoader:didApplyManifest:source:)
    optional func manifestLoader(_ loader: CYLTabBarManifestLoader, didApply manifest: CYLTabBarManifest,
                                 source: CYLTabBarManifestSource)
    /**
     * [EN] The remote manifest failed or was refused; `fallbackSource` tells what was used instead.
     * [CN] 远程清单失败或被拒绝；`fallbackSource` 表示改用的来源。
     */
    @objc(manifestLoader:didFailWithError:fallbackSource:)
    optional func manifestLoader(_ loader: CYLTabBarManifestLoader, didFailWithError error: Error,
                                 fallbackSource: CYLTabBarManifestSource)
}

/**
 * [EN] The completion of `CYLTabBarManifestLoader.loadManifest(with:completion:)`, on the main queue.
 * [CN] `CYLTabBarManifestLoader.loadManifest(with:completion:)` 的完成回调，在主队列执行。
 */
public typealias CYLTabBarManifestCompletion = (CYLTabBarManifest?, CYLTabBarManifestSource, Error?) -> Void

/**
 * [EN] Downloads a manifest and its assets into a versioned cache, and falls back to the previous one or the embedded one.
 *      Translated from Objective-C (docs/Swift-Migration.md).
 * [CN] 下载清单及其资源到按版本存放的缓存，失败时回退到上一个或内置清单。已从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
@objc(CYLTabBarManifestLoader)
public class CYLTabBarManifestLoader: NSObject {

    private typealias Values = CYLManifestValues

    /**
     * [EN] Asked before a manifest is applied, told after, and told about failures.
     * [CN] 应用清单前询问、应用后通知，并通知失败。
     */
    @objc public weak var delegate: CYLTabBarManifestLoaderDelegate?

    /**
     * [EN] The route of the manifest shipped with the app (else the manifest's own fallback.embeddedRoute).
     * [CN] 随 App 发布的清单的路由（否则使用清单自身的 fallback.embeddedRoute）。
     */
    @objc public var embeddedManifestRoute: String?

    /**
     * [EN] The date for the eligibility checks (now when nil).
     * [CN] 用于适用性检查的日期（为 nil 时为当前时间）。
     */
    @objc public var date: Date?

    private static var cacheDirectory: String {
        CYLResourceRoute.path(forRoute: "sandbox:Caches/CYLTabBarManifest", baseDirectory: nil) ?? NSTemporaryDirectory()
    }

    /**
     * [EN] The newest cached manifest that is eligible now and whose assets are intact.
     * [CN] 当前适用且资源完整的最新缓存清单。
     */
    @objc public func cachedManifest() -> CYLTabBarManifest? {
        let root = CYLTabBarManifestLoader.cacheDirectory
        let versions = ((try? FileManager.default.contentsOfDirectory(atPath: root)) ?? [])
            .sorted { Values.compareVersions($1, $0) == .orderedAscending }
        for version in versions {
            let path = ((root as NSString).appendingPathComponent(version) as NSString).appendingPathComponent("manifest.json")
            guard let dictionary = try? CYLTabBarConfigurationParser.dictionary(withContentsOfFile: path),
                  let manifest = try? CYLTabBarManifest(dictionary: dictionary,
                                                        baseDirectory: (path as NSString).deletingLastPathComponent),
                  (try? manifest.isEligible(at: date ?? Date())) != nil, (try? manifest.verifyAssets()) != nil else {
                continue
            }
            return manifest
        }
        return nil
    }

    /**
     * [EN] Downloads the manifest at `URL` and its assets, then calls `completion` on the main queue with the manifest
     *      applied (remote, cache or embedded) and the error that caused a fallback.
     * [CN] 下载 `URL` 处的清单及其资源，然后在主队列调用 `completion`，传入所应用的清单（远程、缓存或内置）以及导致回退的错误。
     */
    @objc(loadManifestWithURL:completion:)
    public func loadManifest(with URL: URL, completion: @escaping CYLTabBarManifestCompletion) {
        URLSession.shared.dataTask(with: URL) { data, _, downloadError in
            var error = downloadError
            var dictionary: [String: Any]?
            if let data {
                do {
                    dictionary = try CYLTabBarConfigurationParser.dictionary(with: data, format: .JSON)
                } catch let parseError {
                    error = parseError
                }
            }
            var remote: CYLTabBarManifest?
            if let dictionary {
                do {
                    remote = try CYLTabBarManifest(dictionary: dictionary, baseDirectory: nil)
                    try remote?.isEligible(at: self.date ?? Date())
                } catch let manifestError {
                    if remote == nil {
                        error = manifestError
                    } else {
                        error = manifestError
                        remote = nil
                    }
                }
            }
            var saved: CYLTabBarManifest?
            if let remote, let data {
                do {
                    saved = try self.save(remote, data: data, from: URL)
                } catch let saveError {
                    error = saveError
                }
            }
            let failed: Any? = saved == nil ? (remote ?? dictionary) : nil
            DispatchQueue.main.async {
                self.finish(remote: saved, fallbackFrom: failed, error: error, completion: completion)
            }
        }.resume()
    }

    private func save(_ manifest: CYLTabBarManifest, data _: Data, from URL: URL) throws -> CYLTabBarManifest {
        let version = manifest.version ?? "0"
        if version.contains("/") || version.contains("..") {
            throw Values.error(.unsupportedManifest, "The manifest version is not a valid folder name.")
        }
        let manager = FileManager.default
        let folder = (CYLTabBarManifestLoader.cacheDirectory as NSString).appendingPathComponent(version)
        let staging = folder + ".download"
        try? manager.removeItem(atPath: staging)
        try? manager.createDirectory(atPath: staging, withIntermediateDirectories: true)
        let assets = Values.dictionary(manifest.dictionary, "assets")
        let baseURL = Values.string(assets, "baseURL").flatMap { Foundation.URL(string: $0) } ?? URL.deletingLastPathComponent()
        var cached = manifest.dictionary
        var cachedAssets = assets ?? [:]
        cachedAssets["baseRoute"] = "."
        cached["assets"] = cachedAssets
        let staged = try CYLTabBarManifest(dictionary: cached, baseDirectory: staging)
        for entry in staged.assetEntries {
            let name = Values.string(entry, "path") ?? ""
            let path = staged.path(ofEntry: entry)
            let assetURL = Values.string(entry, "url").flatMap { Foundation.URL(string: $0) }
                ?? Foundation.URL(string: name, relativeTo: baseURL)
            var assetData: Data?
            var downloadError: Error?
            if let assetURL, path != nil {
                do {
                    assetData = try Data(contentsOf: assetURL)
                } catch {
                    downloadError = error
                }
            }
            guard let path, let assetData else {
                try? manager.removeItem(atPath: staging)
                // [EN] As before: the download's own error, else "could not be downloaded". [CN] 与原来相同：优先使用下载本身的错误。
                throw downloadError ?? Values.error(.assetInvalid, "Asset \(name) could not be downloaded.")
            }
            try? manager.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
            try? assetData.write(to: Foundation.URL(fileURLWithPath: path), options: .atomic)
        }
        do {
            try staged.verifyAssets()
        } catch {
            try? manager.removeItem(atPath: staging)
            throw error
        }
        if let json = try? JSONSerialization.data(withJSONObject: cached) {
            try? json.write(to: Foundation.URL(fileURLWithPath: (staging as NSString).appendingPathComponent("manifest.json")),
                            options: .atomic)
        }
        try? manager.removeItem(atPath: folder)
        try manager.moveItem(atPath: staging, toPath: folder)
        return try CYLTabBarManifest(dictionary: cached, baseDirectory: folder)
    }

    private func finish(remote: CYLTabBarManifest?, fallbackFrom failed: Any?, error: Error?,
                        completion: CYLTabBarManifestCompletion) {
        if let remote, shouldApply(remote, source: .remote) {
            delegate?.manifestLoader?(self, didApply: remote, source: .remote)
            completion(remote, .remote, nil)
            return
        }
        let failedDictionary = (failed as? CYLTabBarManifest)?.dictionary ?? failed as? [String: Any]
        let fallback = Values.dictionary(failedDictionary, "fallback")
        let policy = Values.string(fallback, "onError") ?? "previous"
        let embeddedRoute = embeddedManifestRoute ?? Values.string(fallback, "embeddedRoute")
        var manifest: CYLTabBarManifest?
        var source = CYLTabBarManifestSource.none
        if policy == "previous" {
            manifest = cachedManifest()
            source = manifest == nil ? .none : .cache
        }
        if manifest == nil, policy != "none", let embeddedRoute {
            manifest = try? CYLTabBarManifest(route: embeddedRoute)
            source = manifest == nil ? .none : .embedded
        }
        if let candidate = manifest, !shouldApply(candidate, source: source) {
            manifest = nil
            source = .none
        }
        let reason = error ?? Values.error(.unsupportedManifest, "The manifest was refused.")
        delegate?.manifestLoader?(self, didFailWithError: reason, fallbackSource: source)
        if let manifest {
            delegate?.manifestLoader?(self, didApply: manifest, source: source)
        }
        completion(manifest, source, reason)
    }

    private func shouldApply(_ manifest: CYLTabBarManifest, source: CYLTabBarManifestSource) -> Bool {
        delegate?.manifestLoader?(self, shouldApply: manifest, source: source) ?? true
    }
}
