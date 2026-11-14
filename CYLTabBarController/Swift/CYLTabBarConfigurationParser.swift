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
            return dictionary
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
                    return dictionary
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
