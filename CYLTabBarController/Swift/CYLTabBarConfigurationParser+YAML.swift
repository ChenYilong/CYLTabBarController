//
//  CYLTabBarConfigurationParser+YAML.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

/**
 * [EN] One meaningful YAML line: its indentation, its text without comment, and its line number (1-based).
 * [CN] 一行有效的 YAML：缩进、去掉注释后的文字以及行号（从 1 开始）。
 */
private final class CYLYAMLLine {
    var indent: Int
    var text: String
    let number: Int

    init(indent: Int, text: String, number: Int) {
        self.indent = indent
        self.text = text
        self.number = number
    }
}

/**
 * [EN] The YAML subset of configuration files: block mappings and sequences, flow collections, quoted and block scalars,
 *      comments; nesting limited to `CYLTabBarConfigurationMaximumDepth`. Translated from Objective-C
 *      (docs/Swift-Migration.md) with the same rules and messages.
 * [CN] 配置文件使用的 YAML 子集：块映射与序列、流式集合、引号与块标量、注释；嵌套不超过 `CYLTabBarConfigurationMaximumDepth`。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md），规则与错误信息不变。
 */
final class CYLYAMLParser {

    private typealias Text = CYLConfigurationText

    private let rawLines: [NSString]
    private var lines: [CYLYAMLLine] = []
    private var position = 0
    private var depth = 0
    private(set) var error: NSError?

    init(text: NSString) {
        rawLines = Text.lines(text)
        for (offset, raw) in rawLines.enumerated() {
            let withoutComment = CYLYAMLParser.stripComment(raw)
            let trimmed = Text.trimmed(withoutComment as String)
            if trimmed.isEmpty || trimmed.hasPrefix("%") || trimmed == "---" || trimmed == "..." {
                continue
            }
            var indent = 0
            while indent < withoutComment.length && Text.isInlineSpace(withoutComment.character(at: indent)) {
                indent += 1
            }
            lines.append(CYLYAMLLine(indent: indent, text: Text.trimmed(withoutComment.substring(from: indent)),
                                     number: offset + 1))
        }
    }

    /**
     * [EN] The parsed document (an empty dictionary for an empty one), or nil with `error` set.
     * [CN] 解析结果（空文档为空字典）；失败时返回 nil 并设置 `error`。
     */
    func parse() -> Any? {
        if lines.isEmpty {
            return NSMutableDictionary()
        }
        let value = parseBlock(atIndent: 0)
        if let left = currentLine, error == nil {
            fail(atLine: left.number, "unexpected indentation")
        }
        return error == nil ? value : nil
    }

    // MARK: - Lines

    private static func stripComment(_ text: NSString) -> NSString {
        var inSingle = false
        var inDouble = false
        var i = 0
        while i < text.length {
            let c = text.character(at: i)
            if c == Text.ascii("\\") && inDouble {
                i += 2
                continue
            }
            if c == Text.ascii("\"") && !inSingle {
                inDouble.toggle()
            } else if c == Text.ascii("'") && !inDouble {
                inSingle.toggle()
            } else if c == Text.ascii("#") && !inSingle && !inDouble && (i == 0 || Text.isInlineSpace(text.character(at: i - 1))) {
                return text.substring(to: i) as NSString
            }
            i += 1
        }
        return text
    }

    private var currentLine: CYLYAMLLine? {
        position < lines.count ? lines[position] : nil
    }

    private func fail(atLine line: Int, _ reason: String) {
        if error == nil {
            error = Text.syntaxError("YAML", line: line, reason)
        }
    }

    private static func isSequenceEntry(_ text: String) -> Bool {
        text == "-" || text.hasPrefix("- ")
    }

    /**
     * [EN] The location of the `:` that ends a mapping key, outside quotes and brackets, or NSNotFound.
     * [CN] 结束映射键的 `:` 的位置（在引号与括号之外），没有时为 NSNotFound。
     */
    private static func keyColonLocation(_ string: String) -> Int {
        let text = string as NSString
        var inSingle = false
        var inDouble = false
        var depth = 0
        var i = 0
        while i < text.length {
            let c = text.character(at: i)
            if c == Text.ascii("\\") && inDouble {
                i += 2
                continue
            }
            if c == Text.ascii("\"") && !inSingle {
                inDouble.toggle()
            } else if c == Text.ascii("'") && !inDouble {
                inSingle.toggle()
            } else if !inSingle && !inDouble {
                if c == Text.ascii("[") || c == Text.ascii("{") {
                    depth += 1
                } else if c == Text.ascii("]") || c == Text.ascii("}") {
                    depth -= 1
                } else if c == Text.ascii(":") && depth == 0
                            && (i + 1 == text.length || Text.isInlineSpace(text.character(at: i + 1))) {
                    return i
                }
            }
            i += 1
        }
        return NSNotFound
    }

    // MARK: - Blocks

    private func enterLevel() -> Bool {
        depth += 1
        if depth > CYLConfigurationText.maximumDepth {
            error = error ?? Text.tooDeepError("YAML")
            return false
        }
        return true
    }

    private func parseBlock(atIndent indent: Int) -> Any? {
        let value = enterLevel() ? parseBlockBody(atIndent: indent) : nil
        depth -= 1
        return value
    }

    private func parseBlockBody(atIndent indent: Int) -> Any? {
        guard let line = currentLine, line.indent >= indent else {
            return NSNull()
        }
        if CYLYAMLParser.isSequenceEntry(line.text) {
            return parseSequence(atIndent: line.indent)
        }
        if CYLYAMLParser.keyColonLocation(line.text) != NSNotFound {
            return parseMapping(atIndent: line.indent)
        }
        // [EN] A lone scalar (or a flow collection) as the whole block. [CN] 整个块只有一个标量（或流式集合）。
        position += 1
        return scalarOrFlow(line.text, line: line)
    }

    private func parseSequence(atIndent indent: Int) -> NSMutableArray {
        let sequence = NSMutableArray()
        while error == nil {
            guard let line = currentLine, line.indent == indent, CYLYAMLParser.isSequenceEntry(line.text) else {
                break
            }
            let lineText = line.text as NSString
            let rest = lineText.length > 1 ? Text.trimmed(lineText.substring(from: 2)) : ""
            if rest.isEmpty {
                position += 1
                let next = currentLine
                let value = next.map { $0.indent > indent ? parseBlock(atIndent: $0.indent) : NSNull() } ?? NSNull()
                sequence.add(value ?? NSNull())
                continue
            }
            if CYLYAMLParser.isSequenceEntry(rest) || CYLYAMLParser.keyColonLocation(rest) != NSNotFound {
                // [EN] `- key: value`: a mapping (or a nested sequence) whose first line starts after the dash.
                // [CN] `- key: value`：一个映射（或嵌套序列），其第一行从短横线之后开始。
                let restIndent = indent + (lineText.length - (rest as NSString).length)
                line.indent = restIndent
                line.text = rest
                sequence.add(parseBlock(atIndent: restIndent) ?? NSNull())
                continue
            }
            position += 1
            sequence.add(scalarOrFlow(rest, line: line) ?? NSNull())
        }
        return sequence
    }

    private func parseMapping(atIndent indent: Int) -> NSMutableDictionary {
        let mapping = NSMutableDictionary()
        while error == nil {
            guard let line = currentLine, line.indent == indent else {
                if let line = currentLine, line.indent > indent {
                    fail(atLine: line.number, "unexpected indentation")
                }
                break
            }
            if CYLYAMLParser.isSequenceEntry(line.text) {
                break
            }
            let colon = CYLYAMLParser.keyColonLocation(line.text)
            if colon == NSNotFound {
                fail(atLine: line.number, "expected \"key: value\"")
                break
            }
            let lineText = line.text as NSString
            let key = keyFromText(Text.trimmed(lineText.substring(to: colon)))
            let valueText = Text.trimmed(lineText.substring(from: colon + 1))
            position += 1
            let value: Any?
            if valueText.isEmpty {
                if let next = currentLine,
                   next.indent > indent || (next.indent == indent && CYLYAMLParser.isSequenceEntry(next.text)) {
                    value = parseBlock(atIndent: next.indent)
                } else {
                    value = NSNull()
                }
            } else if valueText.hasPrefix("|") || valueText.hasPrefix(">") {
                value = blockScalar(folded: valueText.hasPrefix(">"), parentIndent: indent)
            } else {
                value = scalarOrFlow(valueText, line: line)
            }
            if let value, !(value is NSNull) {
                mapping[key] = value
            }
        }
        return mapping
    }

    private func keyFromText(_ text: String) -> String {
        let key = scalarOrFlow(text, line: nil)
        return key as? String ?? "\(key.map { "\($0)" } ?? "(null)")"
    }

    private func blockScalar(folded: Bool, parentIndent: Int) -> String {
        // [EN] Use the raw lines, so that blank lines and '#' inside the text are kept. [CN] 使用原始行，保留文本中的空行与 '#'。
        guard let first = currentLine, first.indent > parentIndent else {
            return ""
        }
        let blockIndent = first.indent
        var rawIndex = first.number - 1
        var parts: [String] = []
        while rawIndex < rawLines.count {
            let raw = rawLines[rawIndex]
            let trimmed = Text.trimmed(raw as String)
            var rawIndent = 0
            while rawIndent < raw.length && Text.isInlineSpace(raw.character(at: rawIndent)) {
                rawIndent += 1
            }
            if !trimmed.isEmpty && rawIndent < blockIndent {
                break
            }
            parts.append(raw.length > blockIndent ? raw.substring(from: blockIndent) : "")
            rawIndex += 1
        }
        while let last = parts.last, last.isEmpty {
            parts.removeLast()
        }
        while let line = currentLine, line.number <= rawIndex {
            position += 1
        }
        return parts.joined(separator: folded ? " " : "\n")
    }

    // MARK: - Scalars and flow collections

    private func scalarOrFlow(_ string: String, line: CYLYAMLLine?) -> Any? {
        let text = string as NSString
        if text.length == 0 {
            return NSNull()
        }
        let lineNumber = line?.number ?? 0
        let first = text.character(at: 0)
        if first == Text.ascii("[") || first == Text.ascii("{") {
            let flow = NSMutableString(string: string)
            // [EN] A flow collection may span several lines. [CN] 流式集合可以跨多行。
            while !CYLYAMLParser.flowIsBalanced(flow), let next = currentLine {
                flow.append(" \(next.text)")
                position += 1
            }
            var index = 0
            let value = parseFlowValue(flow, &index, line: lineNumber)
            while index < flow.length && Text.isSpaceOrNewline(flow.character(at: index)) {
                index += 1
            }
            if index != flow.length && error == nil {
                fail(atLine: lineNumber, "unexpected text after a flow collection")
            }
            return value
        }
        if first == Text.ascii("\"") {
            var index = 0
            let result = Text.readDoubleQuoted(text, &index)
            if result == nil {
                fail(atLine: lineNumber, "unterminated double-quoted string")
            }
            return result
        }
        if first == Text.ascii("'") {
            var index = 0
            let result = Text.readSingleQuoted(text, &index, doubledQuoteEscapes: true)
            if result == nil {
                fail(atLine: lineNumber, "unterminated single-quoted string")
            }
            return result
        }
        return Text.typedScalar(string, allowsNull: true)
    }

    private static func flowIsBalanced(_ text: NSString) -> Bool {
        var depth = 0
        var inSingle = false
        var inDouble = false
        var i = 0
        while i < text.length {
            let c = text.character(at: i)
            if c == Text.ascii("\\") && inDouble {
                i += 2
                continue
            }
            if c == Text.ascii("\"") && !inSingle {
                inDouble.toggle()
            } else if c == Text.ascii("'") && !inDouble {
                inSingle.toggle()
            } else if !inSingle && !inDouble {
                if c == Text.ascii("[") || c == Text.ascii("{") {
                    depth += 1
                } else if c == Text.ascii("]") || c == Text.ascii("}") {
                    depth -= 1
                }
            }
            i += 1
        }
        return depth <= 0
    }

    private func parseFlowValue(_ text: NSString, _ index: inout Int, line: Int) -> Any? {
        let value = enterLevel() ? parseFlowValueBody(text, &index, line: line) : nil
        depth -= 1
        return value
    }

    private func skipSpace(_ text: NSString, _ index: inout Int) {
        while index < text.length && Text.isSpaceOrNewline(text.character(at: index)) {
            index += 1
        }
    }

    private func parseFlowValueBody(_ text: NSString, _ index: inout Int, line: Int) -> Any? {
        let length = text.length
        skipSpace(text, &index)
        if index >= length {
            fail(atLine: line, "unexpected end of a flow collection")
            return nil
        }
        let c = text.character(at: index)
        if c == Text.ascii("[") || c == Text.ascii("{") {
            return parseFlowCollection(text, &index, line: line, isSequence: c == Text.ascii("["))
        }
        if c == Text.ascii("\"") {
            let result = Text.readDoubleQuoted(text, &index)
            if result == nil {
                fail(atLine: line, "unterminated double-quoted string")
            }
            return result
        }
        if c == Text.ascii("'") {
            let result = Text.readSingleQuoted(text, &index, doubledQuoteEscapes: true)
            if result == nil {
                fail(atLine: line, "unterminated single-quoted string")
            }
            return result
        }
        let start = index
        while index < length {
            let d = text.character(at: index)
            if d == Text.ascii(",") || d == Text.ascii("]") || d == Text.ascii("}") {
                break
            }
            if d == Text.ascii(":") && (index + 1 >= length || Text.isSpaceOrNewline(text.character(at: index + 1))) {
                break
            }
            index += 1
        }
        return Text.typedScalar(text.substring(with: NSRange(location: start, length: index - start)), allowsNull: true)
    }

    private func parseFlowCollection(_ text: NSString, _ index: inout Int, line: Int, isSequence: Bool) -> Any? {
        let length = text.length
        let close = isSequence ? Text.ascii("]") : Text.ascii("}")
        index += 1
        let array = NSMutableArray()
        let dictionary = NSMutableDictionary()
        while error == nil {
            skipSpace(text, &index)
            if index >= length {
                fail(atLine: line, "unterminated flow collection")
                return nil
            }
            if text.character(at: index) == close {
                index += 1
                break
            }
            let value = parseFlowValue(text, &index, line: line)
            if error != nil {
                return nil
            }
            skipSpace(text, &index)
            if isSequence {
                array.add(value ?? NSNull())
            } else {
                if index >= length || text.character(at: index) != Text.ascii(":") {
                    fail(atLine: line, "expected ':' in a flow mapping")
                    return nil
                }
                index += 1
                let mapped = parseFlowValue(text, &index, line: line)
                if error != nil {
                    return nil
                }
                let key = value as? String ?? "\(value.map { "\($0)" } ?? "(null)")"
                if let mapped, !(mapped is NSNull) {
                    dictionary[key] = mapped
                }
                skipSpace(text, &index)
            }
            if index < length && text.character(at: index) == Text.ascii(",") {
                index += 1
            }
        }
        return isSequence ? array : dictionary
    }
}
