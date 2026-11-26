//
//  CYLAnimationURLOptions.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

// [EN] `CYLTabBarAnimationURLWithOptions()` (declared in cylAnimationKeys.h), moved from Core's
//      UIControl+CYLTabBarItemAnimation.swift unchanged, so the animation subspecs (Rive) do not need Core.
// [CN] `CYLTabBarAnimationURLWithOptions()`（声明于 cylAnimationKeys.h），从 Core 的 UIControl+CYLTabBarItemAnimation.swift 原样移来，
//      使动画子库（Rive）不再需要 Core。
@_cdecl("CYLTabBarAnimationURLWithOptions")
public func cylTabBarAnimationURLWithOptionsEntryPoint(_ fileURL: NSURL?, _ options: NSDictionary?) -> NSURL? {
    guard let fileURL = fileURL as URL?, var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: true) else {
        return nil
    }
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "&=+#?")
    var values: [String: String] = [:]
    for case let (name as String, value as String) in options ?? [:] where !name.isEmpty && !value.isEmpty {
        values[name] = value
    }
    let items: [String] = values.keys.sorted().compactMap { name in
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: allowed), !encodedName.isEmpty,
              let encodedValue = values[name]?.addingPercentEncoding(withAllowedCharacters: allowed), !encodedValue.isEmpty else {
            return nil
        }
        return "\(encodedName)=\(encodedValue)"
    }
    components.percentEncodedFragment = items.isEmpty ? nil : items.joined(separator: "&")
    return components.url as NSURL?
}

// MARK: - Reading options 读取选项

/**
 [EN] The options of a `#` / `?` options text, with the rules every platform shares (the vectors are in
      `CrossPlatform/animated-item-fixtures/source-options.json`, read by each platform's parser test): pairs are split at
      `&`, and at a `#` or `?` that does not follow `=`; names and values are percent-decoded, an undecodable text is kept as
      it is; a pair without a name (no `=`, or `=` first) is dropped.
 [CN] `#` / `?` 选项文本中的选项，规则各平台一致（测试向量在 `CrossPlatform/animated-item-fixtures/source-options.json`，由各平台的解析测试读取）：
      键值对在 `&` 处拆分，也在不紧跟 `=` 的 `#` 或 `?` 处拆分；名称与值做百分号解码，无法解码的文本保持原样；没有名称的键值对
      （没有 `=` 或 `=` 在最前）被丢弃。
 */
private func cylAnimationOptions(inText text: String) -> [String: String] {
    var pairs: [String] = []
    for piece in text.split(separator: "&", omittingEmptySubsequences: false) {
        let characters = Array(piece)
        var start = 0
        var index = 1
        while index < characters.count {
            if (characters[index] == "#" || characters[index] == "?") && characters[index - 1] != "=" {
                pairs.append(String(characters[start..<index]))
                start = index + 1
            }
            index += 1
        }
        pairs.append(start <= characters.count ? String(characters[min(start, characters.count)...]) : "")
    }
    var options: [String: String] = [:]
    for pair in pairs {
        guard let separator = pair.firstIndex(of: "="), separator != pair.startIndex else { continue }
        let name = String(pair[..<separator])
        let value = String(pair[pair.index(after: separator)...])
        options[name.removingPercentEncoding ?? name] = value.removingPercentEncoding ?? value
    }
    return options
}

/**
 [EN] A animation source written as one text, as the configuration files of the other platforms write it (HarmonyOS's
      `CYLAnimatedItemSource`): `file#name=value&…` or `file?name=value#…`, an optional `asset:` prefix, or Lottie JSON
      itself (a text starting with `{` or `[`). iOS tabs and items take a file `URL` whose fragment carries the options
      (`CYLTabBarAnimationURLWithOptions()`); this reads the text form with the shared rules.
 [CN] 写成一段文本的动画来源，与其他平台的配置文件写法一致（鸿蒙的 `CYLAnimatedItemSource`）：`file#名称=值&…` 或 `file?名称=值#…`，可带
      `asset:` 前缀，或直接是 Lottie JSON（以 `{` 或 `[` 开头的文本）。iOS 的 Tab 与条目使用 fragment 中带选项的文件 `URL`
      （`CYLTabBarAnimationURLWithOptions()`）；这里按共同的规则读取文本形式。
 */
public struct CYLAnimationSource: Equatable {
    /** [EN] The file path or URL text without its options; empty for inline JSON. [CN] 不含选项的文件路径或 URL 文本；内联 JSON 时为空。 */
    public let file: String
    /** [EN] The options (see the rules above). [CN] 选项（见上面的规则）。 */
    public let options: [String: String]
    /** [EN] The Lottie JSON text when the source is inline, else nil. [CN] 来源为内联时的 Lottie JSON 文本，否则为 nil。 */
    public let inlineJSON: String?
    /** [EN] "Lottie", "PAG", "Rive", "SVGA", "GIF" (from the file extension; inline JSON is Lottie), or nil. [CN] 类型（由文件扩展名判断；内联 JSON 为 Lottie），无法判断时为 nil。 */
    public let type: String?

    public init(parsing text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let assetPrefix = "asset:"
        if !trimmed.hasPrefix(assetPrefix), trimmed.hasPrefix("{") || trimmed.hasPrefix("[") {
            file = ""
            options = [:]
            inlineJSON = trimmed
            type = "Lottie"
            return
        }
        let raw = trimmed.hasPrefix(assetPrefix) ? String(trimmed.dropFirst(assetPrefix.count)) : trimmed
        if let at = raw.firstIndex(where: { $0 == "#" || $0 == "?" }) {
            file = String(raw[..<at])
            options = cylAnimationOptions(inText: String(raw[raw.index(after: at)...]))
        } else {
            file = raw
            options = [:]
        }
        inlineJSON = nil
        type = cylAnimationTypeOfFileEntryPoint(nil, NSURL(fileURLWithPath: file)) as String?
    }
}

/**
 [EN] The options in `url`'s fragment ("name=value&…", percent-encoded), as `CYLTabBarAnimationURLWithOptions()` writes them and
      with the shared rules of `CYLAnimationSource`; an option without a value is left out, as it is never written. A FILE URL's query
      is read too (the `file?name=value` form; a fragment option of the same name wins; write "#" as "%23" there). A remote URL's
      query belongs to its server and is not read.
 [CN] `url` 的 fragment 中的选项（「名称=值&…」，百分号编码），与 `CYLTabBarAnimationURLWithOptions()` 的写法对应，并采用
      `CYLAnimationSource` 的共同规则；没有值的选项被省略（从不会写入这样的选项）。文件 URL 的 query 也会读取（`file?名称=值` 写法；同名选项以
      fragment 为准；query 中的 "#" 需写作 "%23"）。远程 URL 的 query 属于其服务器，不读取。
 */
@_cdecl("CYLTabBarAnimationOptionsFromURL")
public func cylTabBarAnimationOptionsFromURLEntryPoint(_ url: NSURL?) -> NSDictionary {
    guard let url = url as URL?, let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
        return [:]
    }
    let query = url.isFileURL ? components.percentEncodedQuery : nil
    var options = cylAnimationOptions(inText: query ?? "")
    options.merge(cylAnimationOptions(inText: components.percentEncodedFragment ?? "")) { _, fragment in fragment }
    return options.filter { !$0.value.isEmpty } as NSDictionary
}
