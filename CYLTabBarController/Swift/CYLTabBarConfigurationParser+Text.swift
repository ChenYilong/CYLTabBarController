//
//  CYLTabBarConfigurationParser+Text.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

/**
 * [EN] The shared helpers of the configuration parsers: errors, nesting checks, text decoding, scalars, quoted strings,
 *      dotted paths and JSON5. Translated from Objective-C (docs/Swift-Migration.md) with the same rules: text is read as
 *      UTF-16 units through `NSString`, as the Objective-C version did, and the trees are Foundation mutable containers
 *      (shared by reference while they are built).
 * [CN] 配置解析器共用的辅助方法：错误、嵌套检查、文本解码、标量、引号字符串、点分路径与 JSON5。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md），规则不变：与 Objective-C 版本一样通过 `NSString` 按 UTF-16 单元读取文本，树结构使用 Foundation 可变容器
 *      （构建期间按引用共享）。
 */
enum CYLConfigurationText {

    /**
     * [EN] `CYLTabBarConfigurationMaximumDepth` as an `Int`, for the depth checks.
     * [CN] 以 `Int` 表示的 `CYLTabBarConfigurationMaximumDepth`，用于嵌套检查。
     */
    static let maximumDepth = Int(CYLTabBarConfigurationMaximumDepth)

    // MARK: - Errors

    static func error(_ code: CYLTabBarConfigurationErrorCode, _ description: String) -> NSError {
        NSError(domain: CYLTabBarConfigurationErrorDomain, code: code.rawValue,
                userInfo: [NSLocalizedDescriptionKey: description])
    }

    static func syntaxError(_ formatName: String, line: Int, _ reason: String) -> NSError {
        let description = line > 0
            ? "\(formatName) configuration, line \(line): \(reason)"
            : "\(formatName) configuration: \(reason)"
        return error(.invalidSyntax, description)
    }

    static func tooDeepError(_ formatName: String) -> NSError {
        error(.tooDeep, "\(formatName) configuration: nested deeper than \(CYLConfigurationText.maximumDepth) levels.")
    }

    // MARK: - Nesting checks

    /**
     * [EN] The deepest nesting of { [ ( outside quoted strings: checked before Apple's recursive parsers (JSON, property
     *      lists) run, so a hostile file cannot overflow the stack.
     * [CN] 引号字符串之外 { [ ( 的最大嵌套层数：在 Apple 的递归解析器（JSON、属性列表）运行前检查，避免恶意文件导致栈溢出。
     */
    static func bracketDepth(_ text: NSString) -> Int {
        var depth = 0
        var deepest = 0
        var quote: unichar = 0
        var i = 0
        while i < text.length {
            let c = text.character(at: i)
            if quote != 0 {
                if c == ascii("\\") {
                    i += 1
                } else if c == quote {
                    quote = 0
                }
            } else if c == ascii("\"") || c == ascii("'") {
                quote = c
            } else if c == ascii("{") || c == ascii("[") || c == ascii("(") {
                depth += 1
                deepest = max(deepest, depth)
            } else if (c == ascii("}") || c == ascii("]") || c == ascii(")")) && depth > 0 {
                depth -= 1
            }
            i += 1
        }
        return deepest
    }

    /**
     * [EN] The deepest nesting of <dict> / <array> in an XML property list.
     * [CN] XML 属性列表中 <dict> / <array> 的最大嵌套层数。
     */
    static func xmlPropertyListDepth(_ text: NSString) -> Int {
        var depth = 0
        var deepest = 0
        let length = text.length
        var search = NSRange(location: 0, length: length)
        while search.length > 0 {
            let open = text.range(of: "<", options: [], range: search)
            if open.location == NSNotFound {
                break
            }
            let close = text.range(of: ">", options: [], range: NSRange(location: open.location, length: length - open.location))
            if close.location == NSNotFound {
                break
            }
            let tag = text.substring(with: NSRange(location: open.location + 1, length: close.location - open.location - 1))
            if !tag.hasSuffix("/") && (tag.hasPrefix("dict") || tag.hasPrefix("array")) {
                depth += 1
                deepest = max(deepest, depth)
            } else if (tag.hasPrefix("/dict") || tag.hasPrefix("/array")) && depth > 0 {
                depth -= 1
            }
            let end = NSMaxRange(close)
            search = NSRange(location: end, length: length - end)
        }
        return deepest
    }

    private static func readBigEndian(_ bytes: [UInt8], _ start: Int, _ size: Int) -> UInt64 {
        var value: UInt64 = 0
        for i in 0..<size {
            value = (value << 8) | UInt64(bytes[start + i])
        }
        return value
    }

    /**
     * [EN] Checks the structure of a binary property list without recursion: every offset and reference in bounds, no
     *      container nested deeper than the limit, and a bounded number of visits (which also stops reference cycles).
     *      Returns false with `tooDeep` set when it is nested too deeply.
     * [CN] 以非递归方式检查二进制属性列表的结构：所有偏移与引用都在范围内、容器嵌套不超过上限、访问次数有限（也可阻止循环引用）。
     *      嵌套过深时返回 false 并设置 `tooDeep`。
     */
    static func binaryPropertyListIsSafe(_ data: Data, tooDeep: inout Bool) -> Bool {
        let bytes = [UInt8](data)
        let length = UInt64(bytes.count)
        tooDeep = false
        if length < 8 + 32 {
            return false
        }
        let trailer = Int(length) - 32
        let offsetSize = UInt64(bytes[trailer + 6])
        let referenceSize = UInt64(bytes[trailer + 7])
        let objectCount = readBigEndian(bytes, trailer + 8, 8)
        let topObject = readBigEndian(bytes, trailer + 16, 8)
        let tableOffset = readBigEndian(bytes, trailer + 24, 8)
        if offsetSize < 1 || offsetSize > 8 || referenceSize < 1 || referenceSize > 8 || objectCount == 0
            || topObject >= objectCount || tableOffset >= length || objectCount > (length - tableOffset) / offsetSize {
            return false
        }
        var stack: [UInt64] = [topObject]
        var depths: [Int] = [1]
        var visits = 0
        while let object = stack.popLast(), let depth = depths.popLast() {
            visits += 1
            if visits > 100_000 || object >= objectCount {
                return false
            }
            let offset = readBigEndian(bytes, Int(tableOffset + object * offsetSize), Int(offsetSize))
            if offset >= tableOffset {
                return false
            }
            let marker = bytes[Int(offset)]
            let type = marker >> 4
            if type != 0xA && type != 0xC && type != 0xD {
                continue
            }
            if depth > CYLConfigurationText.maximumDepth {
                tooDeep = true
                return false
            }
            var count = UInt64(marker & 0x0F)
            var position = offset + 1
            if count == 0x0F {
                // [EN] The count follows as an int object: 0x1N, 2^N bytes. [CN] 数量以整数对象形式紧随其后：0x1N，2^N 字节。
                if position >= tableOffset || (bytes[Int(position)] >> 4) != 0x1 || (bytes[Int(position)] & 0x0F) > 3 {
                    return false
                }
                let size = UInt64(1) << UInt64(bytes[Int(position)] & 0x0F)
                if position + 1 + size > tableOffset {
                    return false
                }
                count = readBigEndian(bytes, Int(position + 1), Int(size))
                position += 1 + size
            }
            let references = type == 0xD ? count * 2 : count
            // [EN] References must fit, and the pending work stays bounded. [CN] 引用必须在范围内，且待处理的工作量有上限。
            if count > objectCount || references > (tableOffset - position) / referenceSize
                || UInt64(stack.count) + references > 200_000 {
                return false
            }
            for i in 0..<references {
                stack.append(readBigEndian(bytes, Int(position + i * referenceSize), Int(referenceSize)))
                depths.append(depth + 1)
            }
        }
        return true
    }

    // MARK: - Characters and lines

    static func ascii(_ character: Unicode.Scalar) -> unichar {
        unichar(character.value)
    }

    static func isInlineSpace(_ c: unichar) -> Bool {
        c == ascii(" ") || c == ascii("\t")
    }

    static func isSpaceOrNewline(_ c: unichar) -> Bool {
        c == ascii(" ") || c == ascii("\t") || c == ascii("\n") || c == ascii("\r")
    }

    static func isDigit(_ c: unichar) -> Bool {
        c >= ascii("0") && c <= ascii("9")
    }

    static func isLetter(_ c: unichar) -> Bool {
        (c >= ascii("A") && c <= ascii("Z")) || (c >= ascii("a") && c <= ascii("z"))
    }

    static func string(_ c: unichar) -> String {
        String(utf16CodeUnits: [c], count: 1)
    }

    static func trimmed(_ string: String) -> String {
        string.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /**
     * [EN] UTF-16 and UTF-32 text with a BOM re-encoded as UTF-8, so every parser and the format detection read it;
     *      anything else is returned as it is (A16).
     * [CN] 带 BOM 的 UTF-16 与 UTF-32 文本重新编码为 UTF-8，使所有解析器与格式识别都能读取；其他数据原样返回（A16）。
     */
    static func utf8Data(from data: Data) -> Data {
        let bytes = [UInt8](data.prefix(4))
        var encoding: String.Encoding?
        var bom = 0
        if bytes.count >= 4 && bytes[0] == 0xFF && bytes[1] == 0xFE && bytes[2] == 0x00 && bytes[3] == 0x00 {
            encoding = .utf32LittleEndian
            bom = 4
        } else if bytes.count >= 4 && bytes[0] == 0x00 && bytes[1] == 0x00 && bytes[2] == 0xFE && bytes[3] == 0xFF {
            encoding = .utf32BigEndian
            bom = 4
        } else if bytes.count >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE {
            encoding = .utf16LittleEndian
            bom = 2
        } else if bytes.count >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF {
            encoding = .utf16BigEndian
            bom = 2
        }
        guard let encoding, let string = String(data: data.dropFirst(bom), encoding: encoding) else {
            return data
        }
        return string.data(using: .utf8) ?? data
    }

    static func string(from data: Data) -> NSString? {
        guard let string = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            return nil
        }
        if string.length > 0 && string.character(at: 0) == 0xFEFF {
            return string.substring(from: 1) as NSString
        }
        return string
    }

    /**
     * [EN] Splits text into lines (\n, \r\n or \r).
     * [CN] 将文本拆分为行（\n、\r\n 或 \r）。
     */
    static func lines(_ text: NSString) -> [NSString] {
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        return normalized.components(separatedBy: "\n").map { $0 as NSString }
    }

    // MARK: - Scalars

    /**
     * [EN] A decimal or hexadecimal integer, or a float, or nil. `allowsUnderscores`: TOML's `_` digit separators.
     * [CN] 十进制或十六进制整数、浮点数，否则返回 nil。`allowsUnderscores`：TOML 的 `_` 数字分隔符。
     */
    static func number(from string: String, allowsUnderscores: Bool) -> NSNumber? {
        let text = (allowsUnderscores ? string.replacingOccurrences(of: "_", with: "") : string) as NSString
        let length = text.length
        if length == 0 {
            return nil
        }
        var index = 0
        let first = text.character(at: 0)
        if first == ascii("+") || first == ascii("-") {
            index = 1
        }
        if index >= length {
            return nil
        }
        if length > index + 2 && text.character(at: index) == ascii("0")
            && (text.character(at: index + 1) == ascii("x") || text.character(at: index + 1) == ascii("X")) {
            // [EN] As NSScanner's scanHexLongLong: hex digits after "0x", nothing else. [CN] 与 NSScanner 的 scanHexLongLong 相同：
            //      "0x" 之后只能是十六进制数字。
            let digits = text.substring(from: index + 2)
            guard digits.allSatisfy(\.isHexDigit), let value = UInt64(digits, radix: 16) else {
                return nil
            }
            let signedValue = Int64(bitPattern: value)
            return NSNumber(value: first == ascii("-") ? -signedValue : signedValue)
        }
        var sawDigit = false
        var sawDot = false
        var sawExponent = false
        var i = index
        while i < length {
            let c = text.character(at: i)
            if isDigit(c) {
                sawDigit = true
            } else if c == ascii(".") && !sawDot && !sawExponent {
                sawDot = true
            } else if (c == ascii("e") || c == ascii("E")) && sawDigit && !sawExponent && i + 1 < length {
                sawExponent = true
                let next = text.character(at: i + 1)
                if next == ascii("+") || next == ascii("-") {
                    i += 1
                }
            } else {
                return nil
            }
            i += 1
        }
        if !sawDigit {
            return nil
        }
        if sawDot || sawExponent {
            return NSNumber(value: text.doubleValue)
        }
        return NSNumber(value: text.longLongValue)
    }

    /**
     * [EN] An unquoted scalar of a text format: true / false as booleans, null / ~ as NSNull (YAML), numbers as NSNumber,
     *      anything else as the string itself.
     * [CN] 文本格式中未加引号的标量：true / false 为布尔值，null / ~ 为 NSNull（YAML），数字为 NSNumber，其余保持字符串。
     */
    static func typedScalar(_ raw: String, allowsNull: Bool) -> Any {
        let text = trimmed(raw)
        let lowercase = text.lowercased()
        if lowercase == "true" {
            return NSNumber(value: true)
        }
        if lowercase == "false" {
            return NSNumber(value: false)
        }
        if allowsNull && (lowercase == "null" || text == "~" || text.isEmpty) {
            return NSNull()
        }
        return number(from: text, allowsUnderscores: false) ?? text
    }

    /**
     * [EN] Appends the character of a `\uXXXX` / `\UXXXXXXXX` escape.
     * [CN] 追加 `\uXXXX` / `\UXXXXXXXX` 转义对应的字符。
     */
    static func appendUnicodeEscape(_ output: NSMutableString, _ hex: String) -> Bool {
        guard hex.allSatisfy(\.isHexDigit), var value = UInt32(hex, radix: 16) else {
            return false
        }
        if value > 0xFFFF {
            value -= 0x10000
            let pair: [unichar] = [unichar(0xD800 + (value >> 10)), unichar(0xDC00 + (value & 0x3FF))]
            output.append(String(utf16CodeUnits: pair, count: 2))
        } else {
            output.append(string(unichar(value)))
        }
        return true
    }

    // MARK: - Quoted strings

    /**
     * [EN] Reads a double-quoted string starting at `index` (on the quote), with JSON / TOML / YAML escapes; `index` ends
     *      after the closing quote. nil when it is not closed.
     * [CN] 从 `index`（引号处）开始读取双引号字符串，支持 JSON / TOML / YAML 转义；结束时 `index` 位于右引号之后。未闭合时返回 nil。
     */
    static func readDoubleQuoted(_ text: NSString, _ index: inout Int) -> String? {
        let output = NSMutableString()
        var i = index + 1
        let length = text.length
        while i < length {
            let c = text.character(at: i)
            if c == ascii("\"") {
                index = i + 1
                return output as String
            }
            if c == ascii("\\") && i + 1 < length {
                let e = text.character(at: i + 1)
                i += 2
                switch e {
                case ascii("n"): output.append("\n")
                case ascii("t"): output.append("\t")
                case ascii("r"): output.append("\r")
                case ascii("b"): output.append("\u{08}")
                case ascii("f"): output.append("\u{0C}")
                case ascii("0"): output.append("\0")
                case ascii("u"), ascii("U"):
                    let count = e == ascii("u") ? 4 : 8
                    if i + count > length
                        || !appendUnicodeEscape(output, text.substring(with: NSRange(location: i, length: count))) {
                        return nil
                    }
                    i += count
                default:
                    output.append(string(e))
                }
                continue
            }
            output.append(string(c))
            i += 1
        }
        return nil
    }

    /**
     * [EN] Reads a single-quoted string starting at `index`. `doubledQuoteEscapes`: YAML's '' for one quote; otherwise no
     *      escapes at all (TOML literal strings).
     * [CN] 从 `index` 开始读取单引号字符串。`doubledQuoteEscapes`：YAML 中 '' 表示一个引号；否则不处理任何转义（TOML 字面量字符串）。
     */
    static func readSingleQuoted(_ text: NSString, _ index: inout Int, doubledQuoteEscapes: Bool) -> String? {
        let output = NSMutableString()
        var i = index + 1
        let length = text.length
        while i < length {
            let c = text.character(at: i)
            if c == ascii("'") {
                if doubledQuoteEscapes && i + 1 < length && text.character(at: i + 1) == ascii("'") {
                    output.append("'")
                    i += 2
                    continue
                }
                index = i + 1
                return output as String
            }
            output.append(string(c))
            i += 1
        }
        return nil
    }

    static func unquotedOrTypedValue(_ raw: String) -> Any {
        let text = trimmed(raw) as NSString
        if text.length >= 2 {
            let first = text.character(at: 0)
            let last = text.character(at: text.length - 1)
            if first == ascii("\"") && last == ascii("\"") {
                var index = 0
                if let string = readDoubleQuoted(text, &index), index == text.length {
                    return string
                }
            }
            if first == ascii("'") && last == ascii("'") {
                return text.substring(with: NSRange(location: 1, length: text.length - 2))
            }
        }
        return typedScalar(text as String, allowsNull: false)
    }

    // MARK: - Dotted paths (INI, .properties, TOML)

    static func childDictionary(_ dictionary: NSMutableDictionary, _ key: String) -> NSMutableDictionary? {
        guard let child = dictionary[key] else {
            let created = NSMutableDictionary()
            dictionary[key] = created
            return created
        }
        if let array = child as? NSMutableArray {
            // [EN] TOML: `[a.b]` after `[[a]]` is a table of the last element. [CN] TOML：`[[a]]` 之后的 `[a.b]` 属于最后一个元素。
            return array.lastObject as? NSMutableDictionary
        }
        return child as? NSMutableDictionary
    }

    /**
     * [EN] Sets `value` at `path` under `root`, creating the dictionaries in between. false when a non-table is in the way.
     * [CN] 在 `root` 下的 `path` 处设置 `value`，并创建中间的字典。路径上有非表值时返回 false。
     */
    static func setValue(_ root: NSMutableDictionary, _ path: [String], _ value: Any) -> Bool {
        guard let last = path.last else {
            return false
        }
        var dictionary = root
        for key in path.dropLast() {
            guard let child = childDictionary(dictionary, key) else {
                return false
            }
            dictionary = child
        }
        dictionary[last] = value
        return true
    }

    static func splitDottedKey(_ key: NSString) -> [String]? {
        var parts: [String] = []
        var i = 0
        let length = key.length
        while i <= length {
            while i < length && isInlineSpace(key.character(at: i)) {
                i += 1
            }
            if i >= length {
                return nil
            }
            let c = key.character(at: i)
            let part: String?
            if c == ascii("\"") {
                part = readDoubleQuoted(key, &i)
            } else if c == ascii("'") {
                part = readSingleQuoted(key, &i, doubledQuoteEscapes: false)
            } else {
                let start = i
                while i < length && key.character(at: i) != ascii(".") {
                    i += 1
                }
                part = trimmed(key.substring(with: NSRange(location: start, length: i - start)))
            }
            guard let part, !part.isEmpty else {
                return nil
            }
            parts.append(part)
            if parts.count > CYLConfigurationText.maximumDepth {
                return nil
            }
            while i < length && isInlineSpace(key.character(at: i)) {
                i += 1
            }
            if i >= length {
                break
            }
            if key.character(at: i) != ascii(".") {
                return nil
            }
            i += 1
        }
        return parts
    }

    /**
     * [EN] Flat formats (INI, .properties) write list elements as numeric path parts (`items.0.title`): every dictionary
     *      whose keys are all non-negative integers becomes an array, in the order of the numbers.
     * [CN] 扁平格式（INI、.properties）用数字路径表示列表元素（`items.0.title`）：键全为非负整数的字典会按数字顺序转换为数组。
     */
    static func arraysFromNumericKeys(_ value: Any) -> Any {
        if let dictionary = value as? NSDictionary {
            let converted = NSMutableDictionary()
            var allNumeric = dictionary.count > 0
            var numbers: [String: Int] = [:]
            for (key, element) in dictionary {
                converted[key] = arraysFromNumericKeys(element)
                let keyString = key as? String ?? ""
                // [EN] As NSScanner's scanInteger: leading spaces and a sign are allowed. [CN] 与 NSScanner 的 scanInteger 相同：
                //      允许前导空白与正负号。
                let digits = keyString.drop { $0.isWhitespace || $0.isNewline }
                if let number = Int(digits), number >= 0 {
                    numbers[keyString] = number
                } else {
                    allNumeric = false
                }
            }
            if !allNumeric {
                return converted
            }
            let sortedKeys = numbers.keys.sorted { numbers[$0] ?? 0 < numbers[$1] ?? 0 }
            return NSMutableArray(array: sortedKeys.compactMap { converted[$0] })
        }
        if let array = value as? NSArray {
            return NSMutableArray(array: array.map { arraysFromNumericKeys($0) })
        }
        return value
    }

    // MARK: - JSON5 / JSONC

    /**
     * [EN] JSON5 / JSONC to JSON: removes line comments (//) and block comments, and trailing commas; turns single-quoted
     *      strings into double-quoted ones, and quotes unquoted keys.
     * [CN] JSON5 / JSONC 转为 JSON：删除行注释（//）、块注释与尾随逗号；单引号字符串改为双引号，并为未加引号的键加上引号。
     */
    static func jsonFromJSON5(_ text: NSString) -> String? {
        let output = NSMutableString(capacity: text.length)
        let length = text.length
        var i = 0
        while i < length {
            let c = text.character(at: i)
            if c == ascii("\"") {
                let start = i
                guard readDoubleQuoted(text, &i) != nil else {
                    return nil
                }
                output.append(text.substring(with: NSRange(location: start, length: i - start)))
                continue
            }
            if c == ascii("'") {
                guard let string = readSingleQuoted(text, &i, doubledQuoteEscapes: false) else {
                    return nil
                }
                let escaped = string.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
                output.append("\"\(escaped)\"")
                continue
            }
            if c == ascii("/") && i + 1 < length && text.character(at: i + 1) == ascii("/") {
                while i < length && text.character(at: i) != ascii("\n") {
                    i += 1
                }
                continue
            }
            if c == ascii("/") && i + 1 < length && text.character(at: i + 1) == ascii("*") {
                let end = text.range(of: "*/", options: [], range: NSRange(location: i + 2, length: length - i - 2))
                if end.location == NSNotFound {
                    return nil
                }
                i = NSMaxRange(end)
                continue
            }
            if c == ascii("}") || c == ascii("]") {
                var back = output.length - 1
                while back >= 0 && isSpaceOrNewline(output.character(at: back)) {
                    back -= 1
                }
                if back >= 0 && output.character(at: back) == ascii(",") {
                    output.deleteCharacters(in: NSRange(location: back, length: 1))
                }
                output.append(string(c))
                i += 1
                continue
            }
            if isLetter(c) || c == ascii("_") || c == ascii("$") {
                let start = i
                while i < length {
                    let d = text.character(at: i)
                    if !(isLetter(d) || isDigit(d) || d == ascii("_") || d == ascii("$")) {
                        break
                    }
                    i += 1
                }
                let identifier = text.substring(with: NSRange(location: start, length: i - start))
                var next = i
                while next < length && isSpaceOrNewline(text.character(at: next)) {
                    next += 1
                }
                if next < length && text.character(at: next) == ascii(":") {
                    output.append("\"\(identifier)\"")
                } else {
                    output.append(identifier)
                }
                continue
            }
            output.append(string(c))
            i += 1
        }
        return output as String
    }
}
