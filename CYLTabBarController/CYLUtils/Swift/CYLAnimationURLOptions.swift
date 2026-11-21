//
//  CYLAnimationURLOptions.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import Foundation

// [EN] `CYLTabBarAnimationURLWithOptions()` (declared in CYLAnimationKeys.h), moved from Core's
//      UIControl+CYLTabBarItemAnimation.swift unchanged, so the animation subspecs (Rive) do not need Core.
// [CN] `CYLTabBarAnimationURLWithOptions()`（声明于 CYLAnimationKeys.h），从 Core 的 UIControl+CYLTabBarItemAnimation.swift 原样移来，
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
