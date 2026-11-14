//
//  CYLTabBarConfigurationParser+TOML.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

/**
 * [EN] The TOML subset of configuration files: tables, arrays of tables, dotted and quoted keys, strings (basic, literal,
 *      multi-line), numbers, booleans, arrays and inline tables; nesting limited to `CYLTabBarConfigurationMaximumDepth`.
 *      Translated from Objective-C (docs/Swift-Migration.md) with the same rules and messages.
 * [CN] 配置文件使用的 TOML 子集：表、表数组、点分与引号键、字符串（基本、字面量、多行）、数字、布尔值、数组与内联表；嵌套不超过
 *      `CYLTabBarConfigurationMaximumDepth`。已从 Objective-C 翻译（docs/Swift-Migration.md），规则与错误信息不变。
 */
final class CYLTOMLParser {

    private typealias Text = CYLConfigurationText

    private static let bareKeyCharacters = CharacterSet(
        charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_-").inverted

    private let text: NSString
    private var index = 0
    private var depth = 0
    private(set) var error: NSError?

    init(text: NSString) {
        self.text = text
    }

    /**
     * [EN] The parsed document, or nil with `error` set.
     * [CN] 解析结果；失败时返回 nil 并设置 `error`。
     */
    func parse() -> NSMutableDictionary? {
        let root = NSMutableDictionary()
        var table: NSMutableDictionary = root
        while error == nil {
            skipSpaceNewlinesAndComments()
            if atEnd {
                break
            }
            if hasPrefixAtIndex("[[") {
                index += 2
                guard let path = parseKey(until: "]"), hasPrefixAtIndex("]]"), let last = path.last else {
                    fail("expected ']]'")
                    break
                }
                index += 2
                expectEndOfLine()
                var parent: NSMutableDictionary? = root
                for key in path.dropLast() {
                    parent = parent.flatMap { Text.childDictionary($0, key) }
                }
                let existing = parent?[last]
                guard let parent, existing == nil || existing is NSMutableArray else {
                    fail("array of tables conflicts with an existing key")
                    break
                }
                let array = existing as? NSMutableArray ?? NSMutableArray()
                parent[last] = array
                table = NSMutableDictionary()
                array.add(table)
                continue
            }
            if peek == Text.ascii("[") {
                index += 1
                guard let path = parseKey(until: "]"), peek == Text.ascii("]") else {
                    fail("expected ']'")
                    break
                }
                index += 1
                expectEndOfLine()
                var current: NSMutableDictionary? = root
                for part in path {
                    current = current.flatMap { Text.childDictionary($0, part) }
                    if current == nil {
                        fail("table conflicts with an existing key")
                        break
                    }
                }
                if let current {
                    table = current
                }
                continue
            }
            guard let key = parseKey(until: "="), peek == Text.ascii("=") else {
                fail("expected \"key = value\"")
                break
            }
            index += 1
            guard let value = parseValue() else {
                break
            }
            if !Text.setValue(table, key, value) {
                fail("key conflicts with an existing value")
                break
            }
            expectEndOfLine()
        }
        return error == nil ? root : nil
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
            error = Text.syntaxError("TOML", line: currentLine, reason)
        }
    }

    private var atEnd: Bool {
        index >= text.length
    }

    private var peek: unichar {
        atEnd ? 0 : text.character(at: index)
    }

    private func hasPrefixAtIndex(_ prefix: String) -> Bool {
        let length = (prefix as NSString).length
        return index + length <= text.length && text.substring(with: NSRange(location: index, length: length)) == prefix
    }

    private func skipInlineSpace() {
        while !atEnd && Text.isInlineSpace(peek) {
            index += 1
        }
    }

    private func skipToEndOfLine() {
        while !atEnd && peek != Text.ascii("\n") {
            index += 1
        }
    }

    private func skipSpaceNewlinesAndComments() {
        while !atEnd {
            let c = peek
            if Text.isSpaceOrNewline(c) {
                index += 1
            } else if c == Text.ascii("#") {
                skipToEndOfLine()
            } else {
                break
            }
        }
    }

    private func expectEndOfLine() {
        skipInlineSpace()
        if peek == Text.ascii("#") {
            skipToEndOfLine()
        }
        if peek == Text.ascii("\r") {
            index += 1
        }
        if !atEnd && peek != Text.ascii("\n") {
            fail("expected the end of the line")
        }
    }

    private func parseKey(until terminators: String) -> [String]? {
        let start = index
        var inSingle = false
        var inDouble = false
        while !atEnd {
            let c = peek
            if c == Text.ascii("\"") && !inSingle {
                inDouble.toggle()
            } else if c == Text.ascii("'") && !inDouble {
                inSingle.toggle()
            } else if !inSingle && !inDouble && terminators.contains(Text.string(c)) {
                break
            } else if c == Text.ascii("\n") {
                break
            }
            index += 1
        }
        let raw = text.substring(with: NSRange(location: start, length: index - start))
        var parts = Text.splitDottedKey(raw as NSString)
        if let found = parts, !raw.contains("\""), !raw.contains("'") {
            // [EN] Bare keys only (A17): `[1, 2]` is not a table. [CN] 仅裸键（A17）：`[1, 2]` 不是表。
            if found.contains(where: { $0.rangeOfCharacter(from: CYLTOMLParser.bareKeyCharacters) != nil }) {
                parts = nil
            }
        }
        if parts == nil {
            fail("invalid key")
        }
        return parts
    }

    // MARK: - Values

    private func parseValue() -> Any? {
        depth += 1
        defer { depth -= 1 }
        if depth > CYLConfigurationText.maximumDepth {
            error = error ?? Text.tooDeepError("TOML")
            return nil
        }
        return parseValueBody()
    }

    private func parseValueBody() -> Any? {
        skipInlineSpace()
        let c = peek
        if hasPrefixAtIndex("\"\"\"") || hasPrefixAtIndex("'''") {
            return parseMultilineString(literal: c == Text.ascii("'"))
        }
        if c == Text.ascii("\"") {
            var position = index
            guard let string = Text.readDoubleQuoted(text, &position) else {
                fail("unterminated string")
                return nil
            }
            index = position
            return string
        }
        if c == Text.ascii("'") {
            var position = index
            guard let string = Text.readSingleQuoted(text, &position, doubledQuoteEscapes: false) else {
                fail("unterminated literal string")
                return nil
            }
            index = position
            return string
        }
        if c == Text.ascii("[") {
            return parseArray()
        }
        if c == Text.ascii("{") {
            return parseInlineTable()
        }
        let start = index
        while !atEnd {
            let d = peek
            if d == Text.ascii(",") || d == Text.ascii("]") || d == Text.ascii("}") || d == Text.ascii("#")
                || Text.isSpaceOrNewline(d) {
                break
            }
            index += 1
        }
        let token = text.substring(with: NSRange(location: start, length: index - start))
        if token == "true" {
            return NSNumber(value: true)
        }
        if token == "false" {
            return NSNumber(value: false)
        }
        let number = Text.number(from: token, allowsUnderscores: true)
        if number == nil {
            fail("invalid value \"\(token)\" (strings need quotes)")
        }
        return number
    }

    private func parseMultilineString(literal: Bool) -> Any? {
        let delimiter = literal ? "'''" : "\"\"\""
        index += 3
        // [EN] A newline right after the opening delimiter is trimmed. [CN] 紧随开始分隔符的换行会被去掉。
        if peek == Text.ascii("\n") {
            index += 1
        } else if hasPrefixAtIndex("\r\n") {
            index += 2
        }
        let end = text.range(of: delimiter, options: [], range: NSRange(location: index, length: text.length - index))
        if end.location == NSNotFound {
            fail("unterminated multi-line string")
            return nil
        }
        let body = text.substring(with: NSRange(location: index, length: end.location - index))
        index = NSMaxRange(end)
        if literal {
            return body
        }
        let quoted = "\"\(body.replacingOccurrences(of: "\"", with: "\\\""))\"" as NSString
        var position = 0
        return Text.readDoubleQuoted(quoted, &position) ?? body
    }

    private func parseArray() -> Any? {
        index += 1
        let array = NSMutableArray()
        while error == nil {
            skipSpaceNewlinesAndComments()
            if atEnd {
                fail("unterminated array")
                return nil
            }
            if peek == Text.ascii("]") {
                index += 1
                break
            }
            guard let value = parseValue() else {
                return nil
            }
            array.add(value)
            skipSpaceNewlinesAndComments()
            if peek == Text.ascii(",") {
                index += 1
            } else if peek != Text.ascii("]") {
                fail("expected ',' or ']' in an array")
                return nil
            }
        }
        return array
    }

    private func parseInlineTable() -> Any? {
        index += 1
        let table = NSMutableDictionary()
        while error == nil {
            skipInlineSpace()
            if peek == Text.ascii("}") {
                index += 1
                break
            }
            guard let key = parseKey(until: "="), peek == Text.ascii("=") else {
                fail("expected '=' in an inline table")
                return nil
            }
            index += 1
            guard let value = parseValue(), Text.setValue(table, key, value) else {
                fail("invalid value in an inline table")
                return nil
            }
            skipInlineSpace()
            if peek == Text.ascii(",") {
                index += 1
            } else if peek != Text.ascii("}") {
                fail("expected ',' or '}' in an inline table")
                return nil
            }
        }
        return table
    }
}
