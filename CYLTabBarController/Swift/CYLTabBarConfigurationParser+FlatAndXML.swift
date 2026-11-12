//
//  CYLTabBarConfigurationParser+FlatAndXML.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

/**
 * [EN] The INI, .properties / .env and XML (not property list) configuration readers. Translated from Objective-C
 *      (docs/Swift-Migration.md) with the same rules and messages. Each returns the parsed value or nil with `error` set.
 * [CN] INI、.properties / .env 与 XML（非属性列表）配置读取器。已从 Objective-C 翻译（docs/Swift-Migration.md），规则与错误信息
 *      不变。每个函数返回解析结果，失败时返回 nil 并设置 `error`。
 */
enum CYLFlatConfigurationReader {

    private typealias Text = CYLConfigurationText

    // MARK: - INI

    /**
     * [EN] INI: `[a.b]` sections (dotted paths, numbers for array elements), `key = value` or `key: value`, comments on
     *      their own line starting with `;` or `#`.
     * [CN] INI：`[a.b]` 节（点分路径，数字表示数组元素），`key = value` 或 `key: value`，以 `;` 或 `#` 开头的独立注释行。
     */
    static func dictionary(fromINI text: NSString, error: inout NSError?) -> Any? {
        let root = NSMutableDictionary()
        var section: [String] = []
        for (offset, raw) in Text.lines(text).enumerated() {
            let number = offset + 1
            let line = Text.trimmed(raw as String) as NSString
            if line.length == 0 || line.hasPrefix(";") || line.hasPrefix("#") {
                continue
            }
            if line.hasPrefix("[") {
                if !line.hasSuffix("]") {
                    error = Text.syntaxError("INI", line: number, "expected ']'")
                    return nil
                }
                guard let path = Text.splitDottedKey(line.substring(with: NSRange(location: 1, length: line.length - 2))
                                                        as NSString) else {
                    error = Text.syntaxError("INI", line: number, "invalid section name")
                    return nil
                }
                section = path
                continue
            }
            let equals = line.range(of: "=")
            let colon = line.range(of: ":")
            var separator = equals
            if separator.location == NSNotFound || (colon.location != NSNotFound && colon.location < equals.location) {
                separator = colon
            }
            if separator.location == NSNotFound {
                error = Text.syntaxError("INI", line: number, "expected \"key = value\"")
                return nil
            }
            guard let key = Text.splitDottedKey(line.substring(to: separator.location) as NSString) else {
                error = Text.syntaxError("INI", line: number, "invalid key")
                return nil
            }
            let value = Text.unquotedOrTypedValue(line.substring(from: NSMaxRange(separator)))
            if !Text.setValue(root, section + key, value) {
                error = Text.syntaxError("INI", line: number, "key conflicts with an existing value")
                return nil
            }
        }
        return Text.arraysFromNumericKeys(root)
    }

    // MARK: - .properties / .env

    private static func unescapedPropertiesString(_ text: NSString) -> String {
        if text.range(of: "\\").location == NSNotFound {
            return text as String
        }
        let output = NSMutableString()
        let length = text.length
        var i = 0
        while i < length {
            let c = text.character(at: i)
            if c != Text.ascii("\\") || i + 1 >= length {
                output.append(Text.string(c))
                i += 1
                continue
            }
            i += 1
            let e = text.character(at: i)
            if e == Text.ascii("n") {
                output.append("\n")
            } else if e == Text.ascii("t") {
                output.append("\t")
            } else if e == Text.ascii("r") {
                output.append("\r")
            } else if e == Text.ascii("u") && i + 4 < length
                        && Text.appendUnicodeEscape(output, text.substring(with: NSRange(location: i + 1, length: 4))) {
                i += 4
            } else {
                output.append(Text.string(e))
            }
            i += 1
        }
        return output as String
    }

    /**
     * [EN] .properties and .env: `a.b.0.c = value` (also `:` or a space as separator), `#` or `!` comment lines, a trailing
     *      `\` continues the line; .env style `export KEY="value"` and `__` as a path separator are accepted too.
     * [CN] .properties 与 .env：`a.b.0.c = value`（也可用 `:` 或空格分隔），`#` 或 `!` 注释行，行尾 `\` 续行；
     *      也接受 .env 风格的 `export KEY="value"`，以及用 `__` 作为路径分隔符。
     */
    static func dictionary(fromProperties text: NSString, error: inout NSError?) -> Any? {
        let root = NSMutableDictionary()
        let lines = Text.lines(text)
        var index = 0
        while index < lines.count {
            let number = index + 1
            var line = lines[index].trimmingCharacters(in: .whitespaces) as NSString
            defer { index += 1 }
            if line.length == 0 || line.hasPrefix("#") || line.hasPrefix("!") {
                continue
            }
            while line.hasSuffix("\\") && !line.hasSuffix("\\\\") && index + 1 < lines.count {
                index += 1
                line = (line.substring(to: line.length - 1) + Text.trimmed(lines[index] as String)) as NSString
            }
            if line.hasPrefix("export ") {
                line = Text.trimmed(line.substring(from: 7)) as NSString
            }
            var separator = NSNotFound
            var i = 0
            while i < line.length {
                let c = line.character(at: i)
                if c == Text.ascii("\\") {
                    i += 2
                    continue
                }
                if c == Text.ascii("=") || c == Text.ascii(":") || Text.isInlineSpace(c) {
                    separator = i
                    break
                }
                i += 1
            }
            if separator == NSNotFound {
                error = Text.syntaxError("Properties", line: number, "expected \"key = value\"")
                return nil
            }
            let key = unescapedPropertiesString(line.substring(to: separator) as NSString)
            var rest = line.substring(from: separator).trimmingCharacters(in: .whitespaces)
            if rest.hasPrefix("=") || rest.hasPrefix(":") {
                rest = String(rest.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
            let value: Any
            if (rest as NSString).length >= 2 && (rest.hasPrefix("\"") || rest.hasPrefix("'")) {
                value = Text.unquotedOrTypedValue(rest)
            } else {
                value = Text.typedScalar(unescapedPropertiesString(rest as NSString), allowsNull: false)
            }
            let dotted = key.replacingOccurrences(of: "__", with: ".")
            // [EN] A quoted part may contain dots, e.g. a Lottie keypath: a."Icon.**.Color". [CN] 带引号的部分可以包含点。
            let path = dotted.contains("\"") ? Text.splitDottedKey(dotted as NSString) ?? [] : dotted.components(separatedBy: ".")
            if path.isEmpty || path.count > CYLConfigurationText.maximumDepth || path.contains(where: { $0.isEmpty }) {
                error = Text.syntaxError("Properties", line: number, "invalid key")
                return nil
            }
            if !Text.setValue(root, path, value) {
                error = Text.syntaxError("Properties", line: number, "key conflicts with an existing value")
                return nil
            }
        }
        return Text.arraysFromNumericKeys(root)
    }

    // MARK: - XML (not a property list)

    /**
     * [EN] An XML configuration: the root element (e.g. <CYLTabBarController>) holds the configuration. External entities
     *      are never fetched or expanded (XXE, A14).
     * [CN] XML 配置：根元素（如 <CYLTabBarController>）包含配置。绝不获取或展开外部实体（XXE，A14）。
     */
    static func dictionary(fromXML data: Data, error: inout NSError?) -> NSDictionary? {
        let parser = XMLParser(data: data)
        let builder = CYLXMLTreeBuilder()
        parser.delegate = builder
        parser.shouldResolveExternalEntities = false
        let parsed = parser.parse()
        if builder.tooDeep {
            error = Text.tooDeepError("XML")
            return nil
        }
        guard parsed, let root = builder.root else {
            let reason = parser.parserError?.localizedDescription ?? "invalid XML"
            error = Text.syntaxError("XML", line: parser.lineNumber, reason)
            return nil
        }
        if let dictionary = value(from: root) as? NSDictionary {
            return dictionary
        }
        error = Text.error(.notADictionary, "XML configuration: the root element must contain elements")
        return nil
    }

    /**
     * [EN] An element as a value: with children, a dictionary (children by name, a repeated name makes an array) or, when
     *      every child is `<item>` (or `type="array"`), an array; with only attributes, a dictionary of the attributes; else
     *      its text as a scalar (`type="string"` keeps it a string).
     * [CN] 元素对应的值：有子元素时为字典（按名称，名称重复时为数组），全部子元素为 `<item>`（或 `type="array"`）时为数组；只有属性时为
     *      属性字典；否则为其文本标量（`type="string"` 时保持字符串）。
     */
    private static func value(from node: CYLXMLNode) -> Any {
        let type = node.attributes["type"]
        var attributes = node.attributes
        attributes.removeValue(forKey: "type")
        let allItems = !node.children.isEmpty && node.children.allSatisfy { $0.name == "item" }
        if type == "array" || allItems {
            return NSMutableArray(array: node.children.map { value(from: $0) })
        }
        if !node.children.isEmpty || !attributes.isEmpty || type == "dict" {
            let dictionary = NSMutableDictionary()
            for (key, attribute) in attributes {
                dictionary[key] = Text.typedScalar(attribute, allowsNull: false)
            }
            // [EN] Children grouped by name, in order: a repeated name makes an array. [CN] 按名称分组（保持顺序）：名称重复时组成数组。
            var names: [String] = []
            var values: [String: [Any]] = [:]
            for child in node.children {
                if values[child.name] == nil {
                    values[child.name] = []
                    names.append(child.name)
                }
                values[child.name]?.append(value(from: child))
            }
            for name in names {
                let group = values[name] ?? []
                dictionary[name] = group.count == 1 ? group[0] : NSMutableArray(array: group)
            }
            return dictionary
        }
        if type == "string" {
            return node.text.length > 0 ? (node.text.copy() as? String ?? "") : ""
        }
        return Text.typedScalar(Text.trimmed(node.text as String), allowsNull: false)
    }
}

/**
 * [EN] One XML element while the tree is built.
 * [CN] 构建树时的一个 XML 元素。
 */
private final class CYLXMLNode {
    let name: String
    let attributes: [String: String]
    var children: [CYLXMLNode] = []
    let text = NSMutableString()

    init(name: String, attributes: [String: String]) {
        self.name = name
        self.attributes = attributes
    }
}

/**
 * [EN] Builds the element tree, refusing to nest deeper than `CYLTabBarConfigurationMaximumDepth`.
 * [CN] 构建元素树，嵌套不超过 `CYLTabBarConfigurationMaximumDepth`。
 */
private final class CYLXMLTreeBuilder: NSObject, XMLParserDelegate {
    var root: CYLXMLNode?
    var tooDeep = false
    private var stack: [CYLXMLNode] = []

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI _: String?,
                qualifiedName _: String?, attributes attributeDict: [String: String] = [:]) {
        if tooDeep || stack.count >= CYLConfigurationText.maximumDepth {
            // [EN] Some parsers keep calling back after -abortParsing: ignore everything from here.
            // [CN] 部分解析器在 -abortParsing 之后仍会回调：此后的回调全部忽略。
            tooDeep = true
            parser.abortParsing()
            return
        }
        let node = CYLXMLNode(name: elementName, attributes: attributeDict)
        stack.last?.children.append(node)
        if root == nil {
            root = node
        }
        stack.append(node)
    }

    func parser(_: XMLParser, foundCharacters string: String) {
        if !tooDeep {
            stack.last?.text.append(string)
        }
    }

    func parser(_: XMLParser, foundCDATA CDATABlock: Data) {
        if let string = String(data: CDATABlock, encoding: .utf8) {
            stack.last?.text.append(string)
        }
    }

    func parser(_: XMLParser, didEndElement _: String, namespaceURI _: String?, qualifiedName _: String?) {
        if !tooDeep {
            stack.removeLast()
        }
    }
}
