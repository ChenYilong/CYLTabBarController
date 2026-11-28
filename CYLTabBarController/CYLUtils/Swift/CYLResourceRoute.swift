//
//  CYLResourceRoute.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

/**
 * [EN] Resolves a resource route (`bundle:`, `sandbox:`, `file:`, an absolute or relative path, with an optional query
 *      `?name=…&theme=…&version=…&format=…` that picks a file in a folder) to a path. Translated from Objective-C
 *      (docs/Swift-Migration.md); the rules are the same, written with `NSString`'s path methods so the results match
 *      the Objective-C version exactly. Objective-C callers get this class from `CYLSwiftInterface.h`.
 * [CN] 把资源路由（`bundle:`、`sandbox:`、`file:`、绝对或相对路径，可带 `?name=…&theme=…&version=…&format=…` 查询以在目录中选择文件）
 *      解析为路径。已从 Objective-C 翻译为 Swift（docs/Swift-Migration.md）；规则不变，使用 `NSString` 的路径方法，结果与
 *      Objective-C 版本完全一致。Objective-C 调用方通过 `CYLSwiftInterface.h` 使用本类。
 */
@objc(CYLResourceRoute)
public class CYLResourceRoute: NSObject {

    private static let formats = ["json", "json5", "jsonc", "yaml", "yml", "plist", "xml", "toml", "ini", "cfg", "conf",
                                  "properties", "env", "textproto", "txtpb", "pbtxt", "prototxt", "binpb", "pb", "protobuf",
                                  "strings"]

    private static let extensionGroups = [["yaml", "yml"], ["json5", "jsonc"], ["ini", "cfg", "conf"], ["properties", "env"],
                                          ["textproto", "txtpb", "pbtxt", "prototxt"], ["binpb", "pb", "protobuf"]]

    /**
     * [EN] The path of `route`, or nil for an empty route or a query without `name` / without a matching file.
     *      `baseDirectory` resolves relative paths (default: the main bundle's resources).
     * [CN] `route` 对应的路径；路由为空、查询没有 `name` 或没有匹配的文件时返回 nil。`baseDirectory` 用于解析相对路径
     *      （默认：主 bundle 的资源目录）。
     */
    @objc(pathForRoute:baseDirectory:)
    public class func path(forRoute route: Any?, baseDirectory: String?) -> String? {
        // [EN] As the Objective-C version: anything but a string (a number from a configuration file) gives nil.
        // [CN] 与 Objective-C 版本相同：不是字符串（例如配置文件中的数字）时返回 nil。
        guard let route = route as? String else {
            return nil
        }
        let trimmed = (route as NSString).trimmingCharacters(in: .whitespacesAndNewlines) as NSString
        guard trimmed.length > 0 else {
            return nil
        }
        let question = trimmed.range(of: "?")
        let location = question.location == NSNotFound ? trimmed as String : trimmed.substring(to: question.location)
        let path = path(forLocation: location, baseDirectory: baseDirectory)
        guard question.location != NSNotFound else {
            return path
        }
        var components = URLComponents()
        components.percentEncodedQuery = trimmed.substring(from: question.location + 1)
        var query: [String: String] = [:]
        for item in components.queryItems ?? [] {
            if let value = item.value, !value.isEmpty {
                query[item.name.lowercased()] = value
            }
        }
        guard let name = query["name"], !name.isEmpty else {
            return nil
        }
        return pathOfFile(inDirectory: path, name: name, theme: query["theme"], version: query["version"], format: query["format"])
    }

    /**
     * [EN] The best file in `directory` named `name`, optionally `-theme` and `@version`: an exact theme (none when
     *      `theme` is nil), the version asked for (or the highest), then the format earliest in the list.
     * [CN] `directory` 中名为 `name`（可带 `-theme` 与 `@version`）的最佳文件：主题完全一致（`theme` 为 nil 时不带主题），版本为指定版本
     *      （或最高版本），再按格式列表中靠前的格式。
     */
    @objc(pathOfFileInDirectory:name:theme:version:format:)
    public class func pathOfFile(inDirectory directory: String, name: String, theme: String?, version: String?,
                                 format: String?) -> String? {
        let extensions = format.map { $0.isEmpty ? formats : extensionGroup(for: $0) } ?? formats
        var best: String?
        var bestVersion: String?
        var bestFormat = Int.max
        let files = (try? FileManager.default.contentsOfDirectory(atPath: directory)) ?? []
        for file in files where !file.hasPrefix(".") {
            let fileString = file as NSString
            let fileExtension = fileString.pathExtension.lowercased()
            guard extensions.contains(fileExtension) else {
                continue
            }
            let stem = fileString.deletingPathExtension as NSString
            guard stem.hasPrefix(name) else {
                continue
            }
            var rest = stem.substring(from: (name as NSString).length) as NSString
            var fileVersion: String?
            let at = rest.range(of: "@", options: .backwards)
            if at.location != NSNotFound {
                fileVersion = rest.substring(from: at.location + 1)
                rest = rest.substring(to: at.location) as NSString
            }
            var fileTheme: String?
            if rest.length > 0 {
                guard rest.hasPrefix("-") else {
                    continue
                }
                fileTheme = rest.substring(from: 1)
            }
            if let theme, !theme.isEmpty {
                guard fileTheme == theme else {
                    continue
                }
            } else if let fileTheme, !fileTheme.isEmpty {
                continue
            }
            if let version, !version.isEmpty {
                guard let fileVersion, compare(fileVersion, version) == .orderedSame else {
                    continue
                }
            }
            let formatRank = formats.firstIndex(of: fileExtension) ?? Int.max
            var better = best == nil
            if !better {
                let order: ComparisonResult
                if let bestVersion, let fileVersion {
                    order = compare(fileVersion, bestVersion)
                } else if fileVersion != nil {
                    order = .orderedDescending
                } else if bestVersion != nil {
                    order = .orderedAscending
                } else {
                    order = .orderedSame
                }
                better = order == .orderedDescending || (order == .orderedSame && formatRank < bestFormat)
            }
            if better {
                best = file
                bestVersion = fileVersion
                bestFormat = formatRank
            }
        }
        return best.map { (directory as NSString).appendingPathComponent($0) }
    }

    // MARK: - Private

    private static func extensionGroup(for format: String) -> [String] {
        let lowercase = format.lowercased()
        return extensionGroups.first { $0.contains(lowercase) } ?? [lowercase]
    }

    private static func compare(_ first: String, _ second: String) -> ComparisonResult {
        (first as NSString).compare(second, options: .numeric)
    }

    private static func path(forLocation location: String, baseDirectory: String?) -> String {
        let resources = (Bundle.main.resourcePath ?? "") as NSString
        if location.hasPrefix("bundle:") {
            return resources.appendingPathComponent(dropLeadingSlashes(String(location.dropFirst("bundle:".count))))
        }
        if location.hasPrefix("sandbox:") {
            return sandboxPath(String(location.dropFirst("sandbox:".count)))
        }
        if location.hasPrefix("file:") {
            return URL(string: location)?.path ?? String(location.dropFirst("file:".count))
        }
        let expanded = (location as NSString).expandingTildeInPath as NSString
        if expanded.isAbsolutePath {
            return expanded as String
        }
        let base = (baseDirectory.flatMap { $0.isEmpty ? nil : $0 } ?? resources as String) as NSString
        return base.appendingPathComponent(expanded as String)
    }

    private static func sandboxPath(_ path: String) -> String {
        let rest = dropLeadingSlashes(path)
        let parts = rest.components(separatedBy: "/")
        let first = parts.first ?? ""
        let remainder = parts.dropFirst().joined(separator: "/")
        let root: String?
        switch first {
        case "Documents":
            root = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first
        case "Caches":
            root = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
        case "tmp":
            root = NSTemporaryDirectory()
        default:
            root = nil
        }
        if let root {
            return (root as NSString).appendingPathComponent(remainder)
        }
        return (NSHomeDirectory() as NSString).appendingPathComponent(rest)
    }

    private static func dropLeadingSlashes(_ path: String) -> String {
        String(path.drop { $0 == "/" })
    }
}
