//
//  CYLThemeRuntime.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The theme module's shared state and helpers (was `CYLThemePrivate.h/.m`, translated from Objective-C,
 *      docs/Swift-Migration.md): refreshing a theme value, the views to refresh, the generation of a theme change, bar
 *      appearances and trait-dependent layer colors. Internal to the library.
 * [CN] 主题模块的共享状态与辅助方法（原 `CYLThemePrivate.h/.m`，已从 Objective-C 翻译，docs/Swift-Migration.md）：刷新主题值、
 *      需要刷新的视图、主题切换的代数、Bar 外观以及随特征变化的图层颜色。库内部使用。
 */
enum CYLThemeRuntime {

    private static let trackedViewTable = NSHashTable<UIView>.weakObjects()
    private static var lastChangeGeneration: UInt = 0

    /**
     * [EN] The generation of the theme change in progress, 0 outside a change.
     * [CN] 正在进行的主题切换的代数，不在切换中时为 0。
     */
    private(set) static var currentChangeGeneration: UInt = 0

    static func beginChange() {
        lastChangeGeneration += 1
        currentChangeGeneration = lastChangeGeneration
    }

    static func endChange() {
        currentChangeGeneration = 0
    }

    static func track(_ view: UIView) {
        trackedViewTable.add(view)
    }

    static var trackedViews: [UIView] {
        trackedViewTable.allObjects
    }

    /**
     * [EN] A new copy of a theme color, image or effect of `manager` (any manager when nil), resolved again; nil for any
     *      other value.
     * [CN] `manager`（为 nil 时为任意管理器）的主题颜色、图片或效果重新解析后的新副本；其他值返回 nil。
     */
    static func refreshedValue(_ value: Any?, manager: CYLThemeManager?) -> Any? {
        func matches(_ managerName: (NSCopying & NSObjectProtocol)?) -> Bool {
            guard let managerName else {
                return false
            }
            return manager.map { managerName.isEqual($0.name) } ?? true
        }
        if let color = value as? UIColor {
            return matches(CYLThemeColor.managerName(of: color)) ? CYLThemeColor.refreshed(color) : nil
        }
        if let image = value as? UIImage {
            return matches(CYLThemeImage.managerName(of: image)) ? CYLThemeImage.refreshed(image) : nil
        }
        if let effect = value as? UIVisualEffect {
            return matches(CYLThemeEffect.managerName(of: effect)) ? CYLThemeEffect.refreshed(effect) : nil
        }
        return nil
    }

    // MARK: - Bars

    static func refreshBarAppearances(of view: UIView) {
        if let tabBar = view as? UITabBar {
            tabBar.standardAppearance = refreshed(tabBar.standardAppearance)
            if #available(iOS 15.0, *), let scrollEdge = tabBar.scrollEdgeAppearance {
                tabBar.scrollEdgeAppearance = refreshed(scrollEdge)
            }
        } else if let navigationBar = view as? UINavigationBar {
            navigationBar.standardAppearance = refreshed(navigationBar.standardAppearance)
            if let scrollEdge = navigationBar.scrollEdgeAppearance {
                navigationBar.scrollEdgeAppearance = refreshed(scrollEdge)
            }
            if let compact = navigationBar.compactAppearance {
                navigationBar.compactAppearance = refreshed(compact)
            }
        } else if let toolbar = view as? UIToolbar {
            toolbar.standardAppearance = refreshed(toolbar.standardAppearance)
            if let compact = toolbar.compactAppearance {
                toolbar.compactAppearance = refreshed(compact)
            }
        }
    }

    private static func refreshed<Appearance: UIBarAppearance>(_ appearance: Appearance) -> Appearance {
        let copy = appearance.copy()
        if let effect = refreshedValue(copy.backgroundEffect, manager: nil) as? UIBlurEffect {
            copy.backgroundEffect = effect
        }
        if let image = refreshedValue(copy.backgroundImage, manager: nil) as? UIImage {
            copy.backgroundImage = image
        }
        if let image = refreshedValue(copy.shadowImage, manager: nil) as? UIImage {
            copy.shadowImage = image
        }
        return copy
    }

    // MARK: - Windows and trait-dependent values

    static var applicationWindows: [UIWindow] {
        let application = UIApplication.shared
        let windows = application.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap { $0.windows }
        if !windows.isEmpty {
            return windows
        }
        return application.value(forKey: "windows") as? [UIWindow] ?? []
    }

    /**
     * [EN] Resolves the layer theme colors again in every visible window and in detached view controller views (light or
     *      dark appearance changed without a theme change).
     * [CN] 在所有可见窗口以及脱离窗口的控制器视图中重新解析图层主题颜色（浅色/深色外观变化但主题未变时）。
     */
    static func refreshTraitDependentValues() {
        for window in applicationWindows where !window.isHidden {
            refreshLayerColors(ofViewTree: window)
            if let root = window.rootViewController {
                refreshLayerColors(ofDetachedViewsOf: root)
            }
        }
    }

    private static func refreshLayerColors(ofViewTree view: UIView) {
        view.layer.cyl_updateThemeColors()
        for subview in view.subviews {
            refreshLayerColors(ofViewTree: subview)
        }
    }

    private static func refreshLayerColors(ofDetachedViewsOf viewController: UIViewController) {
        if viewController.isViewLoaded, viewController.view.window == nil, viewController.view.superview == nil {
            refreshLayerColors(ofViewTree: viewController.view)
        }
        for child in viewController.children {
            refreshLayerColors(ofDetachedViewsOf: child)
        }
        if let presented = viewController.presentedViewController, presented.presentingViewController === viewController {
            refreshLayerColors(ofDetachedViewsOf: presented)
        }
    }
}
