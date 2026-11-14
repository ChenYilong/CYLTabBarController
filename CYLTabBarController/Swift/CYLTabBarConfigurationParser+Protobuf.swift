//
//  CYLTabBarConfigurationParser+Protobuf.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

/**
 * [EN] Protocol Buffers text format, without a schema: `name: value`, `name { ... }` (or `< ... >`), `name: [a, b]`;
 *      a name written several times makes an array; `#` comments; `,` or `;` between fields; strings with C escapes
 *      (octal and \x escapes are bytes, decoded as UTF-8, as protoc writes non-ASCII text); `true` / `false` as booleans,
 *      numbers as NSNumber, enum names as strings. Translated from Objective-C (docs/Swift-Migration.md); one fix: a
 *      character outside the Basic Multilingual Plane (an emoji) in a string is kept, where the Objective-C version
 *      dropped it.
 * [CN] 无结构定义的 Protocol Buffers 文本格式：`name: value`、`name { ... }`（或 `< ... >`）、`name: [a, b]`；同名字段多次出现组成数组；
 *      `#` 注释；字段之间可用 `,` 或 `;`；字符串支持 C 转义（八进制与 \x 转义按字节处理，再按 UTF-8 解码）；`true` / `false` 为布尔值，
 *      数字为 NSNumber，枚举名为字符串。已从 Objective-C 翻译（docs/Swift-Migration.md）；修复一处：字符串中基本多文种平面以外的字符
 *      （emoji）会被保留，Objective-C 版本会丢弃它。
 */
final class CYLTextProtoParser {

    private typealias Text = CYLConfigurationText

    private let text: NSString
    private var index = 0
    private var depth = 0
    private(set) var error: NSError?

    init(text: NSString) {
        self.text = text
    }

    /**
     * [EN] The top-level message, or nil with `error` set.
     * [CN] 顶层消息；失败时返回 nil 并设置 `error`。
     */
    func parse() -> NSMutableDictionary? {
        parseFields(until: 0)
    }

    // MARK: - Reading

    private var currentLine: Int {
        var line = 1
        var i = 0
        while i < index && i < text.length {
            if text.character(at: i) == Text.ascii("\n") {
                line += 1
            }
            i += 1
        }
        return line
    }

    private func fail(_ reason: String) {
        if error == nil {
            error = Text.syntaxError("Protobuf text", line: currentLine, reason)
        }
    }

    private var atEnd: Bool {
        index >= text.length
    }

    private var peek: unichar {
        atEnd ? 0 : text.character(at: index)
    }

    private func skipSpaceAndComments() {
        while !atEnd {
            let c = peek
            if Text.isSpaceOrNewline(c) {
                index += 1
            } else if c == Text.ascii("#") {
                while !atEnd && peek != Text.ascii("\n") {
                    index += 1
                }
            } else {
                break
            }
        }
    }

    private static func isNameCharacter(_ c: unichar) -> Bool {
        Text.isLetter(c) || Text.isDigit(c) || c == Text.ascii("_") || c == Text.ascii(".") || c == Text.ascii("/")
    }

    private func parseName() -> String? {
        if peek == Text.ascii("[") {
            // [EN] An extension or Any type URL: [package.name]. [CN] 扩展或 Any 类型 URL：[package.name]。
            let end = text.range(of: "]", options: [], range: NSRange(location: index, length: text.length - index))
            if end.location == NSNotFound {
                fail("expected ']'")
                return nil
            }
            let name = text.substring(with: NSRange(location: index + 1, length: end.location - index - 1))
            index = NSMaxRange(end)
            return Text.trimmed(name)
        }
        let start = index
        while !atEnd && CYLTextProtoParser.isNameCharacter(peek) {
            index += 1
        }
        if index == start {
            fail("expected a field name")
            return nil
        }
        return text.substring(with: NSRange(location: start, length: index - start))
    }

    private static func isHexDigit(_ c: unichar) -> Bool {
        Text.isDigit(c) || (c >= Text.ascii("a") && c <= Text.ascii("f")) || (c >= Text.ascii("A") && c <= Text.ascii("F"))
    }

    private func appendUTF8(_ string: String, to bytes: inout Data) {
        bytes.append(contentsOf: Array(string.utf8))
    }

    private func parseQuotedString() -> String? {
        let quote = peek
        index += 1
        var bytes = Data()
        while !atEnd {
            let c = peek
            if c == quote {
                index += 1
                let string = String(data: bytes, encoding: .utf8)
                if string == nil {
                    fail("a string is not valid UTF-8")
                }
                return string
            }
            if c == Text.ascii("\n") {
                break
            }
            if c != Text.ascii("\\") {
                // [EN] A surrogate pair is one character. [CN] 代理对是一个字符。
                if UTF16.isLeadSurrogate(c) && index + 1 < text.length && UTF16.isTrailSurrogate(text.character(at: index + 1)) {
                    appendUTF8(String(utf16CodeUnits: [c, text.character(at: index + 1)], count: 2), to: &bytes)
                    index += 2
                } else {
                    if !UTF16.isLeadSurrogate(c) && !UTF16.isTrailSurrogate(c) {
                        appendUTF8(Text.string(c), to: &bytes)
                    }
                    index += 1
                }
                continue
            }
            index += 1
            let e = peek
            index += 1
            if e >= Text.ascii("0") && e <= Text.ascii("7") {
                var value = UInt32(e - Text.ascii("0"))
                var n = 0
                while n < 2 && !atEnd && peek >= Text.ascii("0") && peek <= Text.ascii("7") {
                    value = value * 8 + UInt32(peek - Text.ascii("0"))
                    index += 1
                    n += 1
                }
                bytes.append(UInt8(truncatingIfNeeded: value))
            } else if e == Text.ascii("x") || e == Text.ascii("X") {
                var value: UInt32 = 0
                var digits = 0
                while digits < 2 && !atEnd && CYLTextProtoParser.isHexDigit(peek) {
                    let h = peek
                    value = value * 16 + UInt32(h <= Text.ascii("9") ? h - Text.ascii("0") : (h | 0x20) - Text.ascii("a") + 10)
                    index += 1
                    digits += 1
                }
                bytes.append(UInt8(truncatingIfNeeded: value))
            } else if e == Text.ascii("u") || e == Text.ascii("U") {
                let count = e == Text.ascii("u") ? 4 : 8
                let character = NSMutableString()
                if index + count > text.length
                    || !Text.appendUnicodeEscape(character, text.substring(with: NSRange(location: index, length: count))) {
                    fail("invalid unicode escape")
                    return nil
                }
                index += count
                appendUTF8(character as String, to: &bytes)
            } else {
                let simple: [unichar: UInt8] = [Text.ascii("n"): 0x0A, Text.ascii("t"): 0x09, Text.ascii("r"): 0x0D,
                                                Text.ascii("a"): 0x07, Text.ascii("b"): 0x08, Text.ascii("f"): 0x0C,
                                                Text.ascii("v"): 0x0B]
                if let byte = simple[e] {
                    bytes.append(byte)
                } else if !UTF16.isLeadSurrogate(e) && !UTF16.isTrailSurrogate(e) {
                    appendUTF8(Text.string(e), to: &bytes)
                }
            }
        }
        fail("unterminated string")
        return nil
    }

    // MARK: - Values

    private func parseScalar() -> Any? {
        let c = peek
        if c == Text.ascii("\"") || c == Text.ascii("'") {
            // [EN] Adjacent strings are concatenated. [CN] 相邻的字符串会被连接。
            var string = ""
            while error == nil && (peek == Text.ascii("\"") || peek == Text.ascii("'")) {
                guard let part = parseQuotedString() else {
                    return nil
                }
                string += part
                skipSpaceAndComments()
            }
            return string
        }
        let start = index
        while !atEnd {
            let d = peek
            if Text.isSpaceOrNewline(d) || d == Text.ascii(",") || d == Text.ascii(";") || d == Text.ascii("}")
                || d == Text.ascii(">") || d == Text.ascii("]") || d == Text.ascii("#") {
                break
            }
            index += 1
        }
        let token = text.substring(with: NSRange(location: start, length: index - start))
        if token.isEmpty {
            fail("expected a value")
            return nil
        }
        if token == "true" || token == "True" || token == "t" {
            return NSNumber(value: true)
        }
        if token == "false" || token == "False" || token == "f" {
            return NSNumber(value: false)
        }
        var numeric = token
        if (numeric as NSString).length > 1 && (numeric.hasSuffix("f") || numeric.hasSuffix("F"))
            && !numeric.hasPrefix("0x") && !numeric.hasPrefix("0X") {
            numeric = String(numeric.dropLast())
        }
        return Text.number(from: numeric, allowsUnderscores: false) ?? token
    }

    private func parseValue() -> Any? {
        depth += 1
        defer { depth -= 1 }
        if depth > CYLConfigurationText.maximumDepth {
            error = error ?? Text.tooDeepError("Protobuf text")
            return nil
        }
        return parseValueBody()
    }

    private func parseValueBody() -> Any? {
        skipSpaceAndComments()
        let c = peek
        if c == Text.ascii("{") || c == Text.ascii("<") {
            index += 1
            guard let message = parseFields(until: c == Text.ascii("{") ? Text.ascii("}") : Text.ascii(">")) else {
                return nil
            }
            index += 1
            return message
        }
        if c == Text.ascii("[") {
            index += 1
            let array = NSMutableArray()
            while error == nil {
                skipSpaceAndComments()
                if peek == Text.ascii("]") {
                    index += 1
                    return array
                }
                guard let value = parseValue() else {
                    return nil
                }
                array.add(value)
                skipSpaceAndComments()
                if peek == Text.ascii(",") {
                    index += 1
                } else if peek != Text.ascii("]") {
                    fail("expected ',' or ']'")
                    return nil
                }
            }
            return nil
        }
        return parseScalar()
    }

    private func parseFields(until terminator: unichar) -> NSMutableDictionary? {
        let message = NSMutableDictionary()
        var repeated = Set<String>()
        while error == nil {
            skipSpaceAndComments()
            if atEnd {
                if terminator != 0 {
                    fail("unterminated message")
                    return nil
                }
                break
            }
            if terminator != 0 && peek == terminator {
                break
            }
            guard let name = parseName() else {
                return nil
            }
            skipSpaceAndComments()
            if peek == Text.ascii(":") {
                index += 1
                skipSpaceAndComments()
            } else if peek != Text.ascii("{") && peek != Text.ascii("<") {
                fail("expected ':' or '{' after \"\(name)\"")
                return nil
            }
            guard let value = parseValue() else {
                return nil
            }
            if let existing = message[name] {
                if repeated.contains(name), let array = existing as? NSMutableArray {
                    array.add(value)
                } else {
                    message[name] = NSMutableArray(array: [existing, value])
                    repeated.insert(name)
                }
            } else {
                message[name] = value
            }
            skipSpaceAndComments()
            if peek == Text.ascii(",") || peek == Text.ascii(";") {
                index += 1
            }
        }
        return error == nil ? message : nil
    }
}

/**
 * [EN] Binary Protocol Buffers with the built-in schema of Configurations/cyl_tabbar_configuration.proto: message name ->
 *      field number -> (field name, kind). Kinds: "string", "map" (map<string, string>), "repeated:<Message>", or
 *      "message:<Message>" (a single nested message). Field numbers never change; unknown fields are skipped; every
 *      field must fit in its message, so random bytes are rejected. Translated from Objective-C (docs/Swift-Migration.md).
 * [CN] 使用 Configurations/cyl_tabbar_configuration.proto 内置结构定义的二进制 Protocol Buffers：消息名 -> 字段编号 ->（字段名，类型）。
 *      类型为 "string"、"map"（map<string, string>）、"repeated:<消息名>" 或 "message:<消息名>"（单个嵌套消息）。字段编号永不改变；
 *      未知字段会被跳过；每个字段都必须在其消息范围内，因此随机字节会被拒绝。已从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
enum CYLProtobufConfigurationReader {

    private static let schema: [String: [UInt64: (name: String, kind: String)]] = [
        "CYLTabBarConfiguration": [
            1: ("CYLTabBarControllerTabBarItemsAttributes", "repeated:CYLTabBarItem"),
            2: ("CYLTabBarControllerImageInsets", "string"),
            3: ("CYLTabBarControllerTitlePositionAdjustment", "string"),
            4: ("CYLTabBarControllerStyleType", "string"),
            5: ("CYLTabBarControllerContext", "string"),
            7: ("CYLTabBarControllerTabBarItemAnimationSpeed", "string"),
            8: ("CYLTabBarControllerThemes", "repeated:CYLTabBarTheme"),
            9: ("CYLTabBarControllerThemeIdentifier", "string"),
            10: ("CYLTabBarControllerDarkThemeIdentifier", "string"),
            11: ("CYLTabBarControllerThemeManagerName", "string"),
            12: ("CYLTabBarControllerPlusButton", "message:CYLTabBarItem"),
            13: ("CYLTabBarControllerIconRenderingMode", "string"),
            14: ("CYLTabBarControllerIconColor", "string"),
            15: ("CYLTabBarControllerSelectedIconColor", "string"),
        ],
        "CYLTabBarTheme": [
            1: ("CYLTabBarThemeIdentifier", "string"),
            2: ("CYLTabBarThemeValues", "map"),
        ],
        "CYLTabBarItem": [
            1: ("CYLTabBarItemTitle", "string"),
            2: ("CYLTabBarItemImage", "string"),
            3: ("CYLTabBarItemSelectedImage", "string"),
            4: ("CYLTabBarItemDarkImage", "string"),
            5: ("CYLTabBarItemSelectedDarkImage", "string"),
            6: ("CYLTabBarItemImageURL", "string"),
            7: ("CYLTabBarItemSelectedImageURL", "string"),
            8: ("CYLTabBarItemImageURLSize", "string"),
            9: ("CYLTabBarItemImageInsets", "string"),
            10: ("CYLTabBarItemTitlePositionAdjustment", "string"),
            11: ("CYLTabBarItemImagePositionAdjustment", "string"),
            12: ("CYLTabBarLottieFilePath", "string"),
            13: ("CYLTabBarLottieURL", "string"),
            14: ("CYLTabBarLottieSize", "string"),
            15: ("CYLTabBarItemIdentifier", "string"),
            16: ("CYLTabBarLottieDarkURL", "string"),
            17: ("CYLTabBarLottieDarkFilePath", "string"),
            18: ("CYLTabBarLottieDarkColors", "map"),
            21: ("CYLTabBarItemSelectedTitle", "string"),
            22: ("CYLTabBarItemTitleColor", "string"),
            23: ("CYLTabBarItemSelectedTitleColor", "string"),
            24: ("CYLTabBarItemIconColor", "string"),
            25: ("CYLTabBarItemSelectedIconColor", "string"),
            26: ("CYLTabBarItemSelectedBackgroundColor", "string"),
            27: ("CYLTabBarItemBackgroundColor", "string"),
            28: ("CYLTabBarItemTitleFont", "string"),
            29: ("CYLTabBarItemSelectedTitleFont", "string"),
            30: ("CYLTabBarItemAccessibilityIdentifier", "string"),
            31: ("CYLTabBarItemAccessibilityLabel", "string"),
            32: ("CYLTabBarItemAccessibilityHint", "string"),
            33: ("CYLTabBarItemPageIdentifier", "string"),
            34: ("CYLTabBarItemPageParameters", "map"),
            35: ("CYLTabBarItemPlatforms", "string"),
            36: ("CYLTabBarItemMinimumAppVersion", "string"),
            37: ("CYLTabBarAnimationURL", "string"),
            38: ("CYLTabBarAnimationFilePath", "string"),
            39: ("CYLTabBarAnimationSize", "string"),
            40: ("CYLTabBarAnimationDarkURL", "string"),
            41: ("CYLTabBarAnimationDarkFilePath", "string"),
            42: ("CYLTabBarAnimationDarkColors", "map"),
            43: ("CYLTabBarAnimationColors", "map"),
            44: ("CYLTabBarAnimationOptions", "map"),
            45: ("CYLTabBarLottieLoopsWhenUnselected", "string"),
            46: ("CYLTabBarPAGURL", "string"),
            47: ("CYLTabBarPAGFilePath", "string"),
            48: ("CYLTabBarPAGSize", "string"),
            49: ("CYLTabBarPAGDarkURL", "string"),
            50: ("CYLTabBarPAGDarkFilePath", "string"),
            51: ("CYLTabBarRiveURL", "string"),
            52: ("CYLTabBarRiveFilePath", "string"),
            53: ("CYLTabBarRiveSize", "string"),
            54: ("CYLTabBarRiveDarkURL", "string"),
            55: ("CYLTabBarRiveDarkFilePath", "string"),
            56: ("CYLTabBarRiveDarkColors", "map"),
            57: ("CYLTabBarGIFURL", "string"),
            58: ("CYLTabBarGIFFilePath", "string"),
            59: ("CYLTabBarGIFSize", "string"),
            60: ("CYLTabBarGIFDarkURL", "string"),
            61: ("CYLTabBarGIFDarkFilePath", "string"),
            62: ("CYLTabBarItemIconRenderingMode", "string"),
        ],
        "CYLMapEntry": [
            1: ("key", "string"),
            2: ("value", "string"),
        ],
    ]

    static func dictionary(from data: Data, error: inout NSError?) -> NSDictionary? {
        let bytes = [UInt8](data)
        let dictionary = decode(bytes, 0, bytes.count, "CYLTabBarConfiguration")
        if dictionary == nil {
            error = CYLConfigurationText.syntaxError(
                "Protobuf", line: 0,
                "the data is not a valid cyl.CYLTabBarConfiguration message (see cyl_tabbar_configuration.proto)")
        }
        return dictionary
    }

    /**
     * [EN] Whether data holds control characters other than tab and newlines.
     * [CN] 数据中是否含有制表符与换行以外的控制字符。
     */
    static func looksBinary(_ data: Data) -> Bool {
        data.contains { $0 < 0x20 && $0 != 0x09 && $0 != 0x0A && $0 != 0x0D }
    }

    /**
     * [EN] Reads a base-128 varint at `offset`. nil when it runs past `end` or is longer than 10 bytes.
     * [CN] 在 `offset` 处读取 base-128 varint；超出 `end` 或超过 10 字节时返回 nil。
     */
    private static func readVarint(_ bytes: [UInt8], _ end: Int, _ offset: inout Int) -> UInt64? {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        while shift < 70 {
            if offset >= end {
                return nil
            }
            let byte = bytes[offset]
            offset += 1
            if shift < 64 {
                result |= UInt64(byte & 0x7F) << shift
            }
            if byte & 0x80 == 0 {
                return result
            }
            shift += 7
        }
        return nil
    }

    private static func decode(_ bytes: [UInt8], _ start: Int, _ length: Int, _ messageName: String) -> NSMutableDictionary? {
        let fields = schema[messageName] ?? [:]
        let message = NSMutableDictionary()
        let end = start + length
        var offset = start
        while offset < end {
            guard let key = readVarint(bytes, end, &offset), key >> 3 != 0 else {
                return nil
            }
            let field = fields[key >> 3]
            let wireType = key & 0x7
            if wireType == 0 {
                guard readVarint(bytes, end, &offset) != nil else {
                    return nil
                }
                continue
            }
            if wireType == 1 || wireType == 5 {
                let size = wireType == 1 ? 8 : 4
                if offset + size > end {
                    return nil
                }
                offset += size
                continue
            }
            if wireType != 2 {
                return nil
            }
            guard let size = readVarint(bytes, end, &offset), size <= UInt64(end - offset) else {
                return nil
            }
            let payload = offset
            offset += Int(size)
            guard let field else {
                continue
            }
            if !store(field, bytes, payload, Int(size), in: message) {
                return nil
            }
        }
        return message
    }

    private static func store(_ field: (name: String, kind: String), _ bytes: [UInt8], _ payload: Int, _ size: Int,
                              in message: NSMutableDictionary) -> Bool {
        let name = field.name
        let kind = field.kind
        if kind == "string" {
            guard let string = String(bytes: bytes[payload..<payload + size], encoding: .utf8) else {
                return false
            }
            message[name] = string
        } else if kind == "map" {
            guard let entry = decode(bytes, payload, size, "CYLMapEntry") else {
                return false
            }
            let map = message[name] as? NSMutableDictionary ?? NSMutableDictionary()
            map[entry["key"] ?? ""] = entry["value"] ?? ""
            message[name] = map
        } else if kind.hasPrefix("repeated:") {
            guard let element = decode(bytes, payload, size, String(kind.dropFirst(9))) else {
                return false
            }
            let array = message[name] as? NSMutableArray ?? NSMutableArray()
            array.add(element)
            message[name] = array
        } else if kind.hasPrefix("message:") {
            guard let element = decode(bytes, payload, size, String(kind.dropFirst(8))) else {
                return false
            }
            let merged = message[name] as? NSMutableDictionary ?? NSMutableDictionary()
            merged.addEntries(from: element as? [AnyHashable: Any] ?? [:])
            message[name] = merged
        }
        return true
    }
}
