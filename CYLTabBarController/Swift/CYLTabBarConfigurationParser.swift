//
//  CYLTabBarConfigurationParser.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

/**
 * [EN] The error domain of configuration files (`CYLTabBarConfigurationErrorCode`).
 * [CN] 配置文件的错误域（`CYLTabBarConfigurationErrorCode`）。
 */
public let CYLTabBarConfigurationErrorDomain = "CYLTabBarConfigurationErrorDomain"

/**
 * [EN] The largest configuration accepted, in bytes (5 MB).
 * [CN] 可接受的最大配置字节数（5 MB）。
 */
public let CYLTabBarConfigurationMaximumLength: UInt = 5 * 1024 * 1024

/**
 * [EN] The deepest nesting accepted in a configuration.
 * [CN] 配置可接受的最大嵌套层数。
 */
public let CYLTabBarConfigurationMaximumDepth: UInt = 64

/**
 * [EN] The format of a configuration file. Objective-C sees the same constant names (`CYLTabBarConfigurationFormatJSON` …).
 * [CN] 配置文件的格式。Objective-C 看到相同的常量名（`CYLTabBarConfigurationFormatJSON` …）。
 */
@objc public enum CYLTabBarConfigurationFormat: Int {
    /**
     * [EN] Detected from the content.
     * [CN] 根据内容识别。
     */
    case unknown = 0
    /**
     * [EN] JSON.
     * [CN] JSON。
     */
    case JSON
    /**
     * [EN] JSON5 and JSONC.
     * [CN] JSON5 与 JSONC。
     */
    case JSON5
    /**
     * [EN] Property lists (XML, binary, OpenStep) and .strings files.
     * [CN] 属性列表（XML、二进制、OpenStep）与 .strings 文件。
     */
    case propertyList
    /**
     * [EN] YAML.
     * [CN] YAML。
     */
    case YAML
    /**
     * [EN] TOML.
     * [CN] TOML。
     */
    case TOML
    /**
     * [EN] INI (.ini, .cfg, .conf).
     * [CN] INI（.ini、.cfg、.conf）。
     */
    case INI
    /**
     * [EN] .properties and .env.
     * [CN] .properties 与 .env。
     */
    case properties
    /**
     * [EN] XML that is not a property list.
     * [CN] 非属性列表的 XML。
     */
    case XML
    /**
     * [EN] Protocol Buffers text format.
     * [CN] Protocol Buffers 文本格式。
     */
    case protobufText
    /**
     * [EN] Binary Protocol Buffers (cyl_tabbar_configuration.proto).
     * [CN] 二进制 Protocol Buffers（cyl_tabbar_configuration.proto）。
     */
    case protobuf
}

/**
 * [EN] The error codes of `CYLTabBarConfigurationErrorDomain`. Objective-C keeps the old constant names
 *      (`CYLTabBarConfigurationErrorFileNotFound` …) through macros in `CYLTabBarConfigurationParser.h`.
 * [CN] `CYLTabBarConfigurationErrorDomain` 的错误码。Objective-C 通过 `CYLTabBarConfigurationParser.h` 中的宏保留原来的常量名
 *      （`CYLTabBarConfigurationErrorFileNotFound` …）。
 */
@objc public enum CYLTabBarConfigurationErrorCode: Int {
    /**
     * [EN] No file at the path.
     * [CN] 路径上没有文件。
     */
    case fileNotFound = 1
    /**
     * [EN] The format is not supported or could not be detected.
     * [CN] 格式不受支持或无法识别。
     */
    case unsupportedFormat = 2
    /**
     * [EN] The content does not follow its format.
     * [CN] 内容不符合其格式。
     */
    case invalidSyntax = 3
    /**
     * [EN] The top level is not a dictionary.
     * [CN] 顶层不是字典。
     */
    case notADictionary = 4
    /**
     * [EN] A network error while downloading.
     * [CN] 下载时出现网络错误。
     */
    case network = 5
    /**
     * [EN] The configuration is empty.
     * [CN] 配置为空。
     */
    case empty = 6
    /**
     * [EN] Larger than `CYLTabBarConfigurationMaximumLength`.
     * [CN] 大于 `CYLTabBarConfigurationMaximumLength`。
     */
    case tooLarge = 7
    /**
     * [EN] Nested deeper than `CYLTabBarConfigurationMaximumDepth`.
     * [CN] 嵌套深于 `CYLTabBarConfigurationMaximumDepth`。
     */
    case tooDeep = 8
    /**
     * [EN] No tab in the configuration.
     * [CN] 配置中没有 Tab。
     */
    case noTabs = 9
    /**
     * [EN] Must be called on the main thread.
     * [CN] 必须在主线程调用。
     */
    case mainThreadRequired = 10
    /**
     * [EN] No page could be created for the tabs.
     * [CN] 无法为 Tab 创建页面。
     */
    case noPages = 11
    /**
     * [EN] The manifest's schema version is not supported.
     * [CN] 清单的结构版本不受支持。
     */
    case unsupportedManifest = 12
    /**
     * [EN] The manifest does not apply now (dates, platforms, app version, rollout).
     * [CN] 清单当前不适用（日期、平台、App 版本、灰度比例）。
     */
    case notEligible = 13
    /**
     * [EN] An asset of the manifest is missing or does not match its checksum.
     * [CN] 清单中的资源缺失或校验和不符。
     */
    case assetInvalid = 14
}

/**
 * [EN] Reads configuration files in every supported format into the same dictionary. Translated from Objective-C
 *      (docs/Swift-Migration.md); Objective-C callers get this class from `CYLSwiftInterface.h`; the Swift names are the
 *      ones Clang imported.
 * [CN] 将各种支持格式的配置文件读取为同样的字典。已从 Objective-C 翻译（docs/Swift-Migration.md）；Objective-C 调用方通过
 *      `CYLSwiftInterface.h` 使用本类；Swift 名称与 Clang 原先导入的名称相同。
 */
@objc(CYLTabBarConfigurationParser)
public class CYLTabBarConfigurationParser: NSObject {

    private typealias Text = CYLConfigurationText

    private static let formatsByPathExtension: [String: CYLTabBarConfigurationFormat] = [
        "json": .JSON, "json5": .JSON5, "jsonc": .JSON5, "plist": .propertyList, "strings": .propertyList,
        "yaml": .YAML, "yml": .YAML, "toml": .TOML, "ini": .INI, "cfg": .INI, "conf": .INI,
        "properties": .properties, "env": .properties, "xml": .XML,
        "textproto": .protobufText, "txtpb": .protobufText, "pbtxt": .protobufText, "prototxt": .protobufText,
        "binpb": .protobuf, "pb": .protobuf, "protobuf": .protobuf,
    ]

    /**
     * [EN] Every file extension the parser reads, sorted.
     * [CN] 解析器可读取的所有文件扩展名（已排序）。
     */
    @objc public class func supportedPathExtensions() -> [String] {
        formatsByPathExtension.keys.sorted()
    }

    /**
     * [EN] The format of a file extension, `.unknown` when it is not supported.
     * [CN] 文件扩展名对应的格式；不支持时为 `.unknown`。
     */
    @objc(formatForPathExtension:)
    public class func format(forPathExtension pathExtension: String?) -> CYLTabBarConfigurationFormat {
        pathExtension.flatMap { formatsByPathExtension[$0.lowercased()] } ?? .unknown
    }

    /**
     * [EN] The format of an HTTP Content-Type, `.unknown` when it does not tell (XML may also be a property list).
     * [CN] HTTP Content-Type 对应的格式；无法确定时为 `.unknown`（XML 也可能是属性列表）。
     */
    @objc(formatForMIMEType:)
    public class func format(forMIMEType MIMEType: String?) -> CYLTabBarConfigurationFormat {
        let type = Text.trimmed(MIMEType?.components(separatedBy: ";").first?.lowercased() ?? "")
        if type.isEmpty {
            return .unknown
        }
        if type.contains("protobuf") || type.contains("textproto") {
            // [EN] text/x-protobuf, text/x-textproto: text format; application/x-protobuf...: binary.
            // [CN] 文本类型为文本格式，其他为二进制。
            return type.hasPrefix("text/") ? .protobufText : .protobuf
        }
        if type.hasSuffix("json5") {
            return .JSON5
        }
        if type.hasSuffix("json") {
            return .JSON
        }
        if type.contains("yaml") {
            return .YAML
        }
        if type.contains("toml") {
            return .TOML
        }
        if type.contains("plist") {
            return .propertyList
        }
        if type.hasSuffix("/xml") || type.hasSuffix("+xml") {
            return .unknown
        }
        if type.contains("properties") {
            return .properties
        }
        if type.contains("ini") {
            return .INI
        }
        return .unknown
    }

    /**
     * [EN] The human-readable name of a format ("Unknown" for `.unknown`).
     * [CN] 格式的可读名称（`.unknown` 为 "Unknown"）。
     */
    @objc(nameOfFormat:)
    public class func name(of format: CYLTabBarConfigurationFormat) -> String {
        switch format {
        case .JSON: return "JSON"
        case .JSON5: return "JSON5"
        case .propertyList: return "Property List"
        case .YAML: return "YAML"
        case .TOML: return "TOML"
        case .INI: return "INI"
        case .properties: return "Properties"
        case .XML: return "XML"
        case .protobufText: return "Protobuf text"
        case .protobuf: return "Protobuf"
        case .unknown: return "Unknown"
        }
    }

    /**
     * [EN] The format detected from the content, `.unknown` when no format reads it as a non-empty dictionary.
     * [CN] 根据内容识别的格式；没有格式能将其读取为非空字典时为 `.unknown`。
     */
    @objc(formatBySniffingData:)
    public class func format(bySniffing rawData: Data) -> CYLTabBarConfigurationFormat {
        let data = Text.utf8Data(from: rawData)
        if data.starts(with: Array("bplist".utf8)) {
            return .propertyList
        }
        if CYLProtobufConfigurationReader.looksBinary(data) {
            // [EN] Binary data: only a protobuf message can be. [CN] 二进制数据：只可能是 protobuf 消息。
            var ignored: NSError?
            let dictionary = CYLProtobufConfigurationReader.dictionary(from: data, error: &ignored)
            return (dictionary?.count ?? 0) > 0 ? .protobuf : .unknown
        }
        let trimmed = Text.trimmed((Text.string(from: data) as String?) ?? "")
        guard let first = trimmed.utf16.first else {
            return .unknown
        }
        if first == Text.ascii("<") {
            let isPlist = trimmed.contains("<plist") || trimmed.contains("DOCTYPE plist")
            return isPlist ? .propertyList : .XML
        }
        var candidates: [CYLTabBarConfigurationFormat] = []
        if first == Text.ascii("{") {
            candidates += [.JSON, .JSON5]
        } else {
            if first == Text.ascii("/") || first == Text.ascii("[") {
                // [EN] JSON5 only starts with '{', a comment, or '[' for a (rejected) array.
                // [CN] JSON5 只能以 '{'、注释或 '['（数组，不接受）开头。
                candidates.append(.JSON5)
            }
            candidates += [.TOML, .YAML, .protobufText]
            // [EN] Without [sections], .properties first: it also reads .env. [CN] 没有 [节] 时先尝试 .properties：它也能读取 .env。
            let hasSections = trimmed.hasPrefix("[") || trimmed.contains("\n[")
            candidates += hasSections ? [.INI, .properties] : [.properties, .INI]
        }
        // [EN] OpenStep property lists and .strings files. [CN] OpenStep 属性列表与 .strings 文件。
        candidates.append(.propertyList)
        for candidate in candidates {
            if candidate == .YAML && !trimmed.contains(":") {
                continue
            }
            var error: NSError?
            let dictionary = parse(data, candidate, &error)
            if (dictionary?.count ?? 0) > 0 || error?.code == CYLTabBarConfigurationErrorCode.tooDeep.rawValue {
                // [EN] Too deep: this is the format, and the caller gets the TooDeep error. [CN] 嵌套过深：就是该格式。
                return candidate
            }
        }
        return .unknown
    }

    /**
     * [EN] The configuration in `data` (`.unknown`: detected from the content). When the declared format fails with a syntax
     *      error, a clearly different detected format is tried (A7), never .properties, INI or Protobuf text (A17).
     * [CN] `data` 中的配置（`.unknown`：根据内容识别）。声明的格式出现语法错误时，会尝试明显不同的识别格式（A7），但不会尝试
     *      .properties、INI 或 Protobuf 文本（A17）。
     */
    @objc(dictionaryWithData:format:error:)
    public class func dictionary(with data: Data?, format: CYLTabBarConfigurationFormat) throws -> [String: Any] {
        let utf8 = Text.utf8Data(from: data ?? Data())
        var firstError: NSError?
        if let dictionary = parse(utf8, format, &firstError) {
            // [EN] A Remote Config template or defaults file reads as the configuration it holds (docs/Configuration-File.md).
            // [CN] Remote Config 模板或默认值文件读取为其中的配置（docs/Configuration-File.md）。
            return try CYLRemoteConfigReader.configuration(fromFileDictionary: dictionary)
        }
        let retries = firstError?.code == CYLTabBarConfigurationErrorCode.invalidSyntax.rawValue
            || firstError?.code == CYLTabBarConfigurationErrorCode.notADictionary.rawValue
        if format != .unknown && retries {
            let detected = self.format(bySniffing: utf8)
            let distinctive = detected != .properties && detected != .INI && detected != .protobufText
            if detected != .unknown && detected != format && distinctive {
                var ignored: NSError?
                if let dictionary = parse(utf8, detected, &ignored) {
                    #if DEBUG
                    NSLog("🟡 CYLTabBarConfigurationParser: the content is %@, not %@; read as %@.",
                          name(of: detected), name(of: format), name(of: detected))
                    #endif
                    return try CYLRemoteConfigReader.configuration(fromFileDictionary: dictionary)
                }
            }
        }
        throw firstError ?? Text.syntaxError(name(of: format), line: 0, "invalid content")
    }

    /**
     * [EN] The configuration in the file at `path`, its format from the extension (or the content). A file larger than
     *      `CYLTabBarConfigurationMaximumLength` is not read at all.
     * [CN] `path` 处文件中的配置，格式取自扩展名（或内容）。大于 `CYLTabBarConfigurationMaximumLength` 的文件完全不会读取。
     */
    @objc(dictionaryWithContentsOfFile:error:)
    public class func dictionary(withContentsOfFile path: String?) throws -> [String: Any] {
        let path = path ?? ""
        var isDirectory: ObjCBool = false
        let exists = !path.isEmpty && FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            && !isDirectory.boolValue
        let attributes = exists ? try? FileManager.default.attributesOfItem(atPath: path) : nil
        let size = (attributes?[.size] as? NSNumber)?.uint64Value ?? 0
        if size > UInt64(CYLTabBarConfigurationMaximumLength) {
            throw Text.error(.tooLarge, "\"\((path as NSString).lastPathComponent)\" is \(size) bytes, more than the "
                                        + "\(CYLTabBarConfigurationMaximumLength) allowed.")
        }
        guard exists, let data = FileManager.default.contents(atPath: path) else {
            throw Text.error(.fileNotFound, "No configuration file at \"\(path)\".")
        }
        return try dictionary(with: data, format: format(forPathExtension: (path as NSString).pathExtension))
    }

    // MARK: - Parsing one format

    private class func parse(_ data: Data, _ declaredFormat: CYLTabBarConfigurationFormat,
                             _ error: inout NSError?) -> [String: Any]? {
        if data.count > Int(CYLTabBarConfigurationMaximumLength) {
            error = Text.error(.tooLarge, "The configuration is \(data.count) bytes, more than the "
                                          + "\(CYLTabBarConfigurationMaximumLength) allowed.")
            return nil
        }
        let text = Text.string(from: data)
        if data.isEmpty || (text.map { Text.trimmed($0 as String).isEmpty } ?? false) {
            error = Text.error(.empty, "The configuration is empty.")
            return nil
        }
        var format = declaredFormat
        if format == .unknown {
            format = self.format(bySniffing: data)
            if format == .unknown {
                error = Text.error(.unsupportedFormat, "The configuration format could not be detected. Supported file "
                                                       + "extensions: \(supportedPathExtensions().joined(separator: ", ")).")
                return nil
            }
        }
        let formatName = name(of: format)
        var parseError: NSError?
        var tooDeep = false
        let result = value(of: data, text: text, format: format, formatName: formatName, &parseError, tooDeep: &tooDeep)
        if tooDeep {
            error = Text.tooDeepError(formatName)
            return nil
        }
        guard let result else {
            error = parseError ?? Text.syntaxError(formatName, line: 0, "invalid content")
            return nil
        }
        guard let dictionary = result as? [String: Any] else {
            error = Text.error(.notADictionary, "\(formatName) configuration: the top level must be a dictionary "
                                                + "(key-value pairs).")
            return nil
        }
        if dictionary.isEmpty {
            error = Text.error(.empty, "\(formatName) configuration: no key (only whitespace or comments).")
            return nil
        }
        return dictionary
    }

    private class func value(of data: Data, text: NSString?, format: CYLTabBarConfigurationFormat, formatName: String,
                             _ parseError: inout NSError?, tooDeep: inout Bool) -> Any? {
        switch format {
        case .propertyList:
            return propertyList(of: data, text: text, formatName: formatName, &parseError, tooDeep: &tooDeep)
        case .XML:
            return CYLFlatConfigurationReader.dictionary(fromXML: data, error: &parseError)
        case .protobuf:
            return CYLProtobufConfigurationReader.dictionary(from: data, error: &parseError)
        default:
            break
        }
        guard let text else {
            parseError = Text.syntaxError(formatName, line: 0, "the file is not UTF-8 text")
            return nil
        }
        switch format {
        case .JSON, .JSON5:
            let json = format == .JSON5 ? Text.jsonFromJSON5(text) : text as String
            if Text.bracketDepth((json ?? "") as NSString) > Text.maximumDepth {
                tooDeep = true
                return nil
            }
            guard let jsonData = json?.data(using: .utf8) else {
                parseError = Text.syntaxError(formatName, line: 0, "invalid JSON")
                return nil
            }
            do {
                return try JSONSerialization.jsonObject(with: jsonData)
            } catch {
                parseError = Text.syntaxError(formatName, line: 0, error.localizedDescription)
                return nil
            }
        case .YAML:
            let parser = CYLYAMLParser(text: text)
            let result = parser.parse()
            parseError = parser.error
            return result
        case .TOML:
            let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
            let parser = CYLTOMLParser(text: normalized as NSString)
            let result = parser.parse()
            parseError = parser.error
            return result
        case .INI:
            return CYLFlatConfigurationReader.dictionary(fromINI: text, error: &parseError)
        case .properties:
            return CYLFlatConfigurationReader.dictionary(fromProperties: text, error: &parseError)
        case .protobufText:
            let parser = CYLTextProtoParser(text: text)
            let result = parser.parse()
            parseError = parser.error
            return result
        default:
            return nil
        }
    }

    /**
     * [EN] A property list (XML, binary, OpenStep) or a .strings file. Apple's parser is recursive, so the nesting is
     *      checked first (A10).
     * [CN] 属性列表（XML、二进制、OpenStep）或 .strings 文件。Apple 的解析器是递归的，因此先检查嵌套层数（A10）。
     */
    private class func propertyList(of data: Data, text: NSString?, formatName: String, _ parseError: inout NSError?,
                                    tooDeep: inout Bool) -> Any? {
        let isBinary = data.starts(with: Array("bplist".utf8))
        if isBinary {
            if !Text.binaryPropertyListIsSafe(data, tooDeep: &tooDeep) {
                if !tooDeep {
                    parseError = Text.syntaxError(formatName, line: 0, "invalid binary property list structure")
                }
                return nil
            }
        } else {
            let plistText = text ?? ""
            let isXML = plistText.range(of: "<plist").location != NSNotFound || Text.trimmed(plistText as String).hasPrefix("<")
            let depth = isXML ? Text.xmlPropertyListDepth(plistText) : Text.bracketDepth(plistText)
            tooDeep = depth > Text.maximumDepth
            if tooDeep {
                return nil
            }
        }
        do {
            return try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            if !isBinary, let text,
               let wrapped = "{\n\(text)\n}".data(using: .utf8),
               let strings = try? PropertyListSerialization.propertyList(from: wrapped, options: [], format: nil) {
                // [EN] A .strings file: `"key" = value;` pairs without the outer braces. [CN] .strings 文件：没有外层大括号。
                return strings
            }
            parseError = Text.syntaxError(formatName, line: 0, error.localizedDescription)
            return nil
        }
    }
}

// MARK: - Firebase Remote Config

/**
 * [EN] Firebase Remote Config, without Firebase (docs/Configuration-File.md, "Firebase Remote Config"). Remote Config hands
 *      an app a flat map of parameters whose values are strings (String, Number, Boolean or JSON). This reader turns such
 *      values, a Remote Config template JSON (as the console or the REST API exports it) and an Android defaults file
 *      (`remote_config_defaults.xml`) into the same dictionary the other formats give, so `-initWithConfiguration:` and
 *      every key keep working. The mapping:
 *      - Flat: each top-level key of the configuration is one parameter; a nested value (the tab items, the plus button,
 *        the themes...) is a JSON parameter holding exactly the JSON the `.json` file has under that key.
 *      - Whole file: one parameter, `CYLTabBarConfiguration`, holding a whole configuration file (any format); the flat
 *        parameters, when there are some too, replace its keys.
 *      Only parameters whose key starts with "CYL" are read, so a template can hold the app's other parameters. Conditions
 *      are evaluated by Firebase, not here: a template is read by its default values.
 * [CN] Firebase Remote Config，但不依赖 Firebase（docs/Configuration-File.md，“Firebase Remote Config”）。Remote Config 交给 App 的是
 *      一组扁平参数，值都是字符串（String、Number、Boolean 或 JSON）。本读取器把这些值、Remote Config 模板 JSON（控制台或 REST API 导出的格式）
 *      以及 Android 默认值文件（`remote_config_defaults.xml`）转换为与其他格式相同的字典，使 `-initWithConfiguration:` 与所有 key 照常工作。
 *      映射方式：
 *      - 扁平映射：配置的每个顶层 key 是一个参数；嵌套的值（Tab 列表、PlusButton、主题等）是一个 JSON 参数，内容与 `.json` 文件中该 key 下的
 *        JSON 完全相同。
 *      - 整个文件：一个参数 `CYLTabBarConfiguration`，内容为完整的配置文件（任意格式）；同时有扁平参数时，扁平参数替换其中的 key。
 *      只读取 key 以 "CYL" 开头的参数，因此模板中可以有 App 的其他参数。条件由 Firebase 计算，不在这里计算：模板按其默认值读取。
 */
enum CYLRemoteConfigReader {

    private typealias Text = CYLConfigurationText

    /**
     * [EN] The parameter that holds a whole configuration file. [CN] 存放完整配置文件的参数。
     */
    static let wholeConfigurationKey = "CYLTabBarConfiguration"

    /**
     * [EN] The prefix of the parameters this library reads. [CN] 本库读取的参数的前缀。
     */
    static let parameterPrefix = "CYL"

    /**
     * [EN] The name used in error messages. [CN] 错误信息中使用的名称。
     */
    static let formatName = "Remote Config"

    // MARK: - Values

    /**
     * [EN] The configuration in Remote Config values (`key` → string, as `RemoteConfig.configValue(forKey:).stringValue`
     *      gives; numbers and booleans are accepted too). A JSON value that does not parse, or a whole configuration that
     *      does not read, throws the parser's error, so the caller keeps its defaults. Empty values (a parameter that
     *      Firebase does not have) are left out.
     * [CN] Remote Config 值中的配置（`key` → 字符串，即 `RemoteConfig.configValue(forKey:).stringValue` 的结果；也接受数字与布尔值）。
     *      无法解析的 JSON 值，或无法读取的完整配置，会抛出解析器的错误，调用方因此保留默认值。空值（Firebase 中没有的参数）会被忽略。
     */
    static func configuration(fromValues values: [String: Any]) throws -> [String: Any] {
        var length = 0
        for value in values.values {
            length += (value as? String)?.utf8.count ?? 0
        }
        if length > Int(CYLTabBarConfigurationMaximumLength) {
            throw Text.error(.tooLarge, "The Remote Config values are \(length) bytes, more than the "
                                        + "\(CYLTabBarConfigurationMaximumLength) allowed.")
        }
        var configuration: [String: Any] = [:]
        if let whole = values[wholeConfigurationKey] {
            if let text = whole as? String, !Text.trimmed(text).isEmpty {
                do {
                    configuration = try CYLTabBarConfigurationParser.dictionary(with: Data(text.utf8), format: .unknown)
                } catch {
                    let reason = (error as NSError).localizedDescription
                    throw Text.syntaxError(formatName, line: 0, "the parameter \"\(wholeConfigurationKey)\" is not a "
                                                                 + "configuration: \(reason)")
                }
            } else if let dictionary = whole as? [String: Any] {
                configuration = dictionary
            }
        }
        for key in values.keys.sorted() where key != wholeConfigurationKey && key.hasPrefix(parameterPrefix) {
            guard let raw = values[key], let value = try decodedValue(raw, key: key) else {
                continue
            }
            configuration[key] = value
        }
        if configuration.isEmpty {
            throw Text.error(.empty, "Remote Config: no \(parameterPrefix)… parameter (or \"\(wholeConfigurationKey)\") "
                                     + "with a value.")
        }
        return configuration
    }

    /**
     * [EN] One parameter's value: a JSON object or array decoded (an error when it does not parse), other strings typed as
     *      the .properties reader types them ("true" → YES, "12" → 12...), nil for an empty string.
     * [CN] 单个参数的值：JSON 对象或数组会被解码（无法解析时报错），其他字符串按 .properties 读取器的规则转换类型（"true" → YES、"12" → 12……），
     *      空字符串返回 nil。
     */
    private static func decodedValue(_ raw: Any, key: String) throws -> Any? {
        guard let string = raw as? String else {
            // [EN] Already typed (a plist or an XML defaults file). [CN] 已有类型（plist 或 XML 默认值文件）。
            return raw is NSNull ? nil : raw
        }
        let trimmed = Text.trimmed(string)
        if trimmed.isEmpty {
            return nil
        }
        guard trimmed.hasPrefix("{") || trimmed.hasPrefix("[") else {
            return Text.typedScalar(trimmed, allowsNull: false)
        }
        if Text.bracketDepth(trimmed as NSString) > Text.maximumDepth {
            throw Text.tooDeepError(formatName)
        }
        do {
            return try JSONSerialization.jsonObject(with: Data(trimmed.utf8), options: [.fragmentsAllowed])
        } catch {
            if isGeometryString(trimmed) {
                // [EN] "{0, -2}", "{0, 0, 0, 0}": an offset, an inset or a size, as in every other format. [CN] 偏移、内边距或尺寸，与其他格式相同。
                return trimmed
            }
            throw Text.syntaxError(formatName, line: 0, "the parameter \"\(key)\" is not valid JSON: "
                                                         + error.localizedDescription)
        }
    }

    /**
     * [EN] YES for the geometry strings of configuration files ("{0, -2}", "{1.5, 0, 0, 0}"): they start with "{" but are not
     *      JSON, and stay strings for the value conversion.
     * [CN] 配置文件中的几何字符串（"{0, -2}"、"{1.5, 0, 0, 0}"）返回 YES：它们以 "{" 开头但不是 JSON，保留为字符串，由值转换处理。
     */
    private static func isGeometryString(_ text: String) -> Bool {
        text.range(of: #"^\{\s*-?[0-9.]+(\s*,\s*-?[0-9.]+)*\s*\}$"#, options: .regularExpression) != nil
    }

    // MARK: - Files

    /**
     * [EN] `dictionary` read back as a configuration when it is a Remote Config file: a template JSON
     *      (`{"parameters": {key: {"defaultValue": {"value": …}}}}`, with `parameterGroups` too) or an Android defaults file
     *      (`<defaultsMap><entry><key/><value/></entry></defaultsMap>`, read by the XML reader as `entry`). Any other
     *      dictionary is returned as it is.
     * [CN] `dictionary` 是 Remote Config 文件时，将其读取为配置：模板 JSON（`{"parameters": {key: {"defaultValue": {"value": …}}}}`，也包括
     *      `parameterGroups`）或 Android 默认值文件（`<defaultsMap><entry><key/><value/></entry></defaultsMap>`，XML 读取器将其读取为
     *      `entry`）。其他字典原样返回。
     */
    static func configuration(fromFileDictionary dictionary: [String: Any]) throws -> [String: Any] {
        if let values = templateValues(dictionary) {
            return try configuration(fromValues: values)
        }
        if let values = defaultsMapValues(dictionary) {
            return try configuration(fromValues: values)
        }
        if holdsJSONParameters(dictionary) {
            // [EN] An iOS defaults property list (`setDefaults(fromPlist:)`): nested values as JSON strings.
            // [CN] iOS 默认值属性列表（`setDefaults(fromPlist:)`）：嵌套的值为 JSON 字符串。
            return try configuration(fromValues: dictionary)
        }
        return dictionary
    }

    /**
     * [EN] YES when a "CYL…" key holds a JSON object or array as a string, as Remote Config stores nested values (an iOS
     *      defaults property list). A configuration file never stores a nested value as a string; geometry strings
     *      ("{0, -2}") do not count.
     * [CN] 某个 "CYL…" key 以字符串形式保存 JSON 对象或数组时返回 YES，这正是 Remote Config 保存嵌套值的方式（iOS 默认值属性列表）。配置文件从不以
     *      字符串保存嵌套的值；几何字符串（"{0, -2}"）不算在内。
     */
    private static func holdsJSONParameters(_ dictionary: [String: Any]) -> Bool {
        dictionary.contains { key, value in
            guard key.hasPrefix(parameterPrefix), let text = (value as? String).map(Text.trimmed),
                  text.hasPrefix("{") || text.hasPrefix("["), !isGeometryString(text) else {
                return false
            }
            return (try? JSONSerialization.jsonObject(with: Data(text.utf8))) != nil
        }
    }

    /**
     * [EN] The default values of a template's parameters, nil when `dictionary` is not a template. A parameter that uses
     *      the in-app default (`useInAppDefault`) is left out.
     * [CN] 模板参数的默认值；`dictionary` 不是模板时返回 nil。使用 App 内默认值（`useInAppDefault`）的参数会被忽略。
     */
    private static func templateValues(_ dictionary: [String: Any]) -> [String: Any]? {
        var parameterSets: [[String: Any]] = []
        if let parameters = dictionary["parameters"] as? [String: Any] {
            parameterSets.append(parameters)
        }
        if let groups = dictionary["parameterGroups"] as? [String: Any] {
            for group in groups.values {
                if let parameters = (group as? [String: Any])?["parameters"] as? [String: Any] {
                    parameterSets.append(parameters)
                }
            }
        }
        let isTemplate = parameterSets.contains { parameters in
            parameters.values.contains { ($0 as? [String: Any]).map(isTemplateParameter) ?? false }
        }
        guard isTemplate, !dictionary.keys.contains(where: { $0.hasPrefix(parameterPrefix) }) else {
            return nil
        }
        var values: [String: Any] = [:]
        for parameters in parameterSets {
            for (key, parameter) in parameters {
                guard let defaultValue = (parameter as? [String: Any])?["defaultValue"] as? [String: Any],
                      (defaultValue["useInAppDefault"] as? Bool) != true,
                      let value = defaultValue["value"] else {
                    continue
                }
                values[key] = value
            }
        }
        return values
    }

    private static func isTemplateParameter(_ parameter: [String: Any]) -> Bool {
        parameter["defaultValue"] is [String: Any] || parameter["conditionalValues"] is [String: Any]
            || parameter["valueType"] is String
    }

    /**
     * [EN] The entries of an Android defaults file, nil when `dictionary` is not one. The XML reader gives `entry` as one
     *      dictionary (a single entry), a list of `{key, value}` dictionaries, or a dictionary already keyed by the keys.
     * [CN] Android 默认值文件的条目；`dictionary` 不是这种文件时返回 nil。XML 读取器给出的 `entry` 可能是一个字典（只有一个条目）、
     *      `{key, value}` 字典的列表，或已按 key 组织的字典。
     */
    private static func defaultsMapValues(_ dictionary: [String: Any]) -> [String: Any]? {
        guard dictionary.count == 1, let entry = dictionary["entry"] else {
            return nil
        }
        let entries: [Any]
        if let list = entry as? [Any] {
            entries = list
        } else if let single = entry as? [String: Any], single["key"] != nil {
            entries = [single]
        } else if let keyed = entry as? [String: Any] {
            return keyed
        } else {
            return nil
        }
        var values: [String: Any] = [:]
        for item in entries {
            guard let pair = item as? [String: Any], let key = pair["key"] else {
                return nil
            }
            values["\(key)"] = pair["value"] ?? ""
        }
        return values
    }
}

extension CYLTabBarConfigurationParser {

    /**
     * [EN] The configuration in Firebase Remote Config values, without Firebase: pass every value as a string (e.g. for each
     *      key of `remoteConfig.allKeys(from: .remote)`, `remoteConfig[key].stringValue`). Only "CYL…" parameters are read;
     *      a nested value is a JSON parameter, and `CYLTabBarConfiguration` may hold a whole configuration file. Throws when
     *      a value is invalid, so the app keeps its defaults (docs/Configuration-File.md, "Firebase Remote Config").
     * [CN] Firebase Remote Config 值中的配置，不依赖 Firebase：以字符串传入每个值（例如对 `remoteConfig.allKeys(from: .remote)` 的每个 key，
     *      传入 `remoteConfig[key].stringValue`）。只读取 "CYL…" 参数；嵌套的值是 JSON 参数，`CYLTabBarConfiguration` 可以存放完整的配置文件。
     *      值无效时抛出错误，App 因此保留默认值（docs/Configuration-File.md，“Firebase Remote Config”）。
     */
    @objc(dictionaryWithRemoteConfigValues:error:)
    public class func dictionary(withRemoteConfigValues values: [String: Any]) throws -> [String: Any] {
        try CYLRemoteConfigReader.configuration(fromValues: values)
    }
}
