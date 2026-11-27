//
//  CYLTabBarController+CYLKeyValueObserving.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if canImport(CYLBadge)
import CYLBadge
#endif
/// [EN] The KVO contexts of the controller: stable addresses for the life of the app. [CN] 控制器的 KVO context：在 App 生命周期内地址不变。
private enum CYLKVOContexts {
    static let tabImageViewDefaultOffset = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    static let flatDesignTabBar = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
    static let standardAppearance = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 1)
}

/// [EN] The tab bar whose appearances are observed. [CN] 正在观察其外观的 TabBar。
private var cylObservedStandardAppearanceTabBarKey: UInt8 = 0

/**
 [EN] The FlatDesign tab bar replaced (`cyl_tabBar` observed), implemented by CYLTabBarController+CYLFlatDesignKeyValueObserving.swift
      in the FlatDesign subspec.
 [CN] 扁平样式 TabBar 被替换（观察 `cyl_tabBar`），由扁平样式子库中的 CYLTabBarController+CYLFlatDesignKeyValueObserving.swift 实现。
 */
@objc protocol CYLFlatDesignKeyValueObserving {
    @objc(cyl_flatDesignTabBarDidChange:) optional func cylFlatDesignTabBarDidChange(_ change: [NSKeyValueChangeKey: Any])
}

/**
 [EN] Block 4 of the sections handed over by Mac-CYLTabBarController文件夹 (docs/Swift-Migration.md, step 127): key-value observing.
      `-observeValueForKeyPath:ofObject:change:context:` stays a one-line override in CYLTabBarController.m that calls
      `-cyl_observeValueForKeyPath:ofObject:change:context:` here (dispatched by context, not by the current style: an
      observation outlives a change of `tabBarStyleType`, and an observation of ours passed on to `super` raises an
      exception). The contexts are Swift; CYLTabBarController.m reads them through macros of the same names. Also the
      observers of `standardAppearance` / `scrollEdgeAppearance` (synced to the title offsets, issue #475, and the
      FlatDesign tab bar). Internal members with the Objective-C selectors, declared in CYLTabBarController+CYLPrivate.h.
 [CN] 另一会话移交的第 4 块（第 127 步）：KVO。`-observeValueForKeyPath:ofObject:change:context:` 在 CYLTabBarController.m 中保留为一行的
      重写，调用这里的方法（按 context 分发而不是按当前样式：观察会在 `tabBarStyleType` 改变后继续存在，把自己的观察交给 `super` 会抛异常）。
      context 在 Swift 中定义；CYLTabBarController.m 通过同名宏读取。另有 `standardAppearance` / `scrollEdgeAppearance` 的观察。以 Objective-C
      selector 实现的内部成员，声明于 CYLTabBarController+CYLPrivate.h。
 */
extension CYLTabBarController {

    /// [EN] `CYLTabImageViewDefaultOffsetContext` in CYLTabBarController.m. [CN] 即 .m 中的 `CYLTabImageViewDefaultOffsetContext`。
    @objc(cyl_tabImageViewDefaultOffsetKVOContext)
    static func cylTabImageViewDefaultOffsetKVOContext() -> UnsafeMutableRawPointer {
        CYLKVOContexts.tabImageViewDefaultOffset
    }

    /// [EN] `CYLFlatDesignTabBarContext` in CYLTabBarController.m. [CN] 即 .m 中的 `CYLFlatDesignTabBarContext`。
    @objc(cyl_flatDesignTabBarKVOContext)
    static func cylFlatDesignTabBarKVOContext() -> UnsafeMutableRawPointer {
        CYLKVOContexts.flatDesignTabBar
    }

    /// [EN] `CYLStandardAppearanceContext` in CYLTabBarController.m. [CN] 即 .m 中的 `CYLStandardAppearanceContext`。
    @objc(cyl_standardAppearanceKVOContext)
    static func cylStandardAppearanceKVOContext() -> UnsafeMutableRawPointer {
        CYLKVOContexts.standardAppearance
    }

    private var cylFlatDesignKeyValueObserving: CYLFlatDesignKeyValueObserving {
        unsafeBitCast(self as AnyObject, to: CYLFlatDesignKeyValueObserving.self)
    }

    /// [EN] The body of `-observeValueForKeyPath:ofObject:change:context:`. [CN] `-observeValueForKeyPath:ofObject:change:context:` 的实现。
    @objc(cyl_observeValueForKeyPath:ofObject:change:context:)
    func cylObserveValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        switch context {
        case CYLKVOContexts.tabImageViewDefaultOffset:
            if tabBarStyleType != .flatDesign {
                offsetTabBarTabImageView(toFit: CGFloat((change?[.newKey] as? NSNumber)?.doubleValue ?? 0))
            }
        case CYLKVOContexts.standardAppearance:
            cylSyncTabBarAppearances()
        case CYLKVOContexts.flatDesignTabBar:
            cylFlatDesignKeyValueObserving.cylFlatDesignTabBarDidChange?(change ?? [:])
        default:
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

    private static var cylObservedAppearanceKeyPaths: [String] {
        ["standardAppearance", "scrollEdgeAppearance"]
    }

    /// [EN] Observes the current tab bar's appearances (again when `-setUpTabBar:` swapped in CYLTabBar).
    /// [CN] 观察当前 TabBar 的外观（`-setUpTabBar:` 换成 CYLTabBar 后改为观察新的 TabBar）。
    @objc(cyl_startObservingStandardAppearance)
    func cylStartObservingStandardAppearance() {
        let tabBar = self.tabBar
        if (objc_getAssociatedObject(self, &cylObservedStandardAppearanceTabBarKey) as? UITabBar) === tabBar {
            return
        }
        cylStopObservingStandardAppearance()
        for keyPath in CYLTabBarController.cylObservedAppearanceKeyPaths {
            tabBar.addObserver(self, forKeyPath: keyPath, options: .new, context: CYLKVOContexts.standardAppearance)
        }
        objc_setAssociatedObject(self, &cylObservedStandardAppearanceTabBarKey, tabBar, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /// [EN] Stops observing, whatever the style is now. [CN] 停止观察，与当前样式无关。
    @objc(cyl_stopObservingStandardAppearance)
    func cylStopObservingStandardAppearance() {
        guard let tabBar = objc_getAssociatedObject(self, &cylObservedStandardAppearanceTabBarKey) as? UITabBar else { return }
        for keyPath in CYLTabBarController.cylObservedAppearanceKeyPaths {
            tabBar.cyl_removeObserver(self, forKeyPath: keyPath, context: CYLKVOContexts.standardAppearance)
        }
        objc_setAssociatedObject(self, &cylObservedStandardAppearanceTabBarKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
}
