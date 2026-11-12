//
//  CYLThemeManager.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Posted (object: the manager) when a manager's current theme changes.
 * [CN] 管理器的当前主题变化时发出（object 为该管理器）。
 */
extension NSNotification.Name {
    public static let CYLThemeDidChange = NSNotification.Name("CYLThemeDidChangeNotification")
}

/**
 * [EN] A set of themes (identifier → theme object) and the current one; changing it refreshes every visible view.
 *      Get one from `CYLThemeManagerCenter`. Translated from Objective-C (docs/Swift-Migration.md); Objective-C callers
 *      get this class from `CYLSwiftInterface.h`; the Swift names are the ones Clang imported.
 * [CN] 一组主题（标识 → 主题对象）及当前主题；切换时刷新所有可见视图。通过 `CYLThemeManagerCenter` 获取。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md）；Objective-C 调用方通过 `CYLSwiftInterface.h` 使用本类；Swift 名称与 Clang 原先导入的名称相同。
 */
@objc(CYLThemeManager)
public class CYLThemeManager: NSObject {

    /**
     * [EN] The manager's name in `CYLThemeManagerCenter`.
     * [CN] 管理器在 `CYLThemeManagerCenter` 中的名称。
     */
    @objc public let name: NSCopying & NSObjectProtocol

    private var identifierList: [NSCopying & NSObjectProtocol] = []
    private var themeList: [NSObject] = []
    private var storedIdentifier: (NSCopying & NSObjectProtocol)?
    private var storedTheme: NSObject?

    /**
     * [EN] Unavailable: use `CYLThemeManagerCenter.themeManager(withName:)`.
     * [CN] 不可用：请使用 `CYLThemeManagerCenter.themeManager(withName:)`。
     */
    @available(*, unavailable)
    override public init() {
        fatalError("Use CYLThemeManagerCenter.themeManager(withName:)")
    }

    init(name: NSCopying & NSObjectProtocol) {
        self.name = (name.copy() as? NSCopying & NSObjectProtocol) ?? name
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(cyl_applicationDidBecomeActive(_:)),
                                               name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override public var description: String {
        "\(super.description), name = \(name), currentThemeIdentifier = \(String(describing: storedIdentifier)), "
            + "themeIdentifiers = \(String(describing: themeIdentifiers))"
    }

    // MARK: - System appearance

    /**
     * [EN] Follows the system light / dark appearance through `identifierForTrait`.
     * [CN] 通过 `identifierForTrait` 跟随系统浅色/深色外观。
     */
    @objc public var respondsSystemStyleAutomatically = false {
        didSet {
            if respondsSystemStyleAutomatically {
                updateTheme(for: currentTraitCollection)
            }
        }
    }

    /**
     * [EN] The theme identifier for a trait collection (light / dark).
     * [CN] 特征集合（浅色/深色）对应的主题标识。
     */
    @objc public var identifierForTrait: ((UITraitCollection) -> (NSCopying & NSObjectProtocol)?)?

    /**
     * [EN] Switches to `identifierForTrait(traitCollection)` when following the system appearance (not in the background,
     *      not for an unspecified style).
     * [CN] 跟随系统外观时切换到 `identifierForTrait(traitCollection)`（不在后台、外观未指定时不切换）。
     */
    @objc(updateThemeForTraitCollection:)
    public func updateTheme(for traitCollection: UITraitCollection) {
        guard respondsSystemStyleAutomatically, let identifierForTrait,
              UIApplication.shared.applicationState != .background,
              traitCollection.userInterfaceStyle != .unspecified,
              let identifier = identifierForTrait(traitCollection),
              !(storedIdentifier.map { identifier.isEqual($0) } ?? false) else {
            return
        }
        currentThemeIdentifier = identifier
    }

    @objc private func cyl_applicationDidBecomeActive(_ notification: Notification) {
        if respondsSystemStyleAutomatically {
            updateTheme(for: currentTraitCollection)
        }
    }

    private var currentTraitCollection: UITraitCollection {
        CYLThemeRuntime.applicationWindows.first { !$0.isHidden && $0.rootViewController != nil }?.traitCollection
            ?? UITraitCollection.current
    }

    // MARK: - Persistence

    /**
     * [EN] Saves the current identifier (a string or number) in user defaults and restores it.
     * [CN] 将当前标识（字符串或数字）保存在 user defaults 中并恢复。
     */
    @objc public var persistsCurrentThemeIdentifier = false {
        didSet {
            guard persistsCurrentThemeIdentifier, storedIdentifier == nil, let saved = savedThemeIdentifier,
                  theme(forIdentifier: saved) != nil || themeGenerator != nil else {
                return
            }
            currentThemeIdentifier = saved
        }
    }

    private var persistenceKey: String {
        "CYLThemeManager.\(name).currentThemeIdentifier"
    }

    private var savedThemeIdentifier: (NSCopying & NSObjectProtocol)? {
        let identifier = UserDefaults.standard.object(forKey: persistenceKey)
        return (identifier as? NSString) ?? (identifier as? NSNumber)
    }

    private func saveCurrentThemeIdentifierIfNeeded() {
        guard persistsCurrentThemeIdentifier, let identifier = storedIdentifier,
              identifier is NSString || identifier is NSNumber else {
            return
        }
        UserDefaults.standard.set(identifier, forKey: persistenceKey)
    }

    // MARK: - Current theme

    /**
     * [EN] The animation length of a theme change (a fading snapshot); 0 for none.
     * [CN] 主题切换动画（渐隐快照）的时长；0 表示无动画。
     */
    @objc public var themeChangeAnimationDuration: TimeInterval = 0

    /**
     * [EN] Makes the theme of an identifier that is not registered yet.
     * [CN] 为尚未注册的标识生成主题。
     */
    @objc public var themeGenerator: ((NSCopying & NSObjectProtocol) -> NSObject?)?

    /**
     * [EN] Gives the identifier of a theme that is not registered yet.
     * [CN] 为尚未注册的主题给出标识。
     */
    @objc public var themeIdentifierGenerator: ((NSObject) -> (NSCopying & NSObjectProtocol)?)?

    /**
     * [EN] The current theme's identifier; setting a registered (or generated) one changes the theme. Main thread only.
     * [CN] 当前主题的标识；设置已注册（或可生成）的标识即切换主题。仅限主线程。
     */
    @objc public var currentThemeIdentifier: (NSCopying & NSObjectProtocol)? {
        get { storedIdentifier }
        set {
            assert(Thread.isMainThread, "CYLThemeManager: change the theme on the main thread.")
            guard let identifier = newValue else {
                return
            }
            if !identifierList.contains(where: { $0.isEqual(identifier) }), let theme = themeGenerator?(identifier) {
                addThemeIdentifier(identifier, theme: theme)
            }
            guard let theme = self.theme(forIdentifier: identifier) else {
                NSLog("🔴 CYLThemeManager: register the theme of identifier %@ before making it current.", String(describing: identifier))
                return
            }
            let themeChanged = storedIdentifier.map { !$0.isEqual(identifier) } ?? false
            storedIdentifier = (identifier.copy() as? NSCopying & NSObjectProtocol) ?? identifier
            storedTheme = theme
            saveCurrentThemeIdentifierIfNeeded()
            if themeChanged {
                notifyThemeChanged()
            }
        }
    }

    /**
     * [EN] The current theme; setting a registered (or identifiable) one changes the theme. Main thread only.
     * [CN] 当前主题；设置已注册（或可得到标识）的主题即切换主题。仅限主线程。
     */
    @objc public var currentTheme: NSObject? {
        get { storedTheme }
        set {
            assert(Thread.isMainThread, "CYLThemeManager: change the theme on the main thread.")
            guard let theme = newValue else {
                return
            }
            if !themeList.contains(where: { $0.isEqual(theme) }), let identifier = themeIdentifierGenerator?(theme) {
                addThemeIdentifier(identifier, theme: theme)
            }
            guard let identifier = self.identifier(forTheme: theme) else {
                NSLog("🔴 CYLThemeManager: register the theme %@ before making it current.", theme)
                return
            }
            let themeChanged = storedTheme.map { !$0.isEqual(theme) } ?? false
            storedTheme = theme
            storedIdentifier = identifier
            saveCurrentThemeIdentifierIfNeeded()
            if themeChanged {
                notifyThemeChanged()
            }
        }
    }

    // MARK: - Themes

    /**
     * [EN] The registered identifiers, nil when none.
     * [CN] 已注册的标识，没有时为 nil。
     */
    @objc public var themeIdentifiers: [NSCopying & NSObjectProtocol]? {
        identifierList.isEmpty ? nil : identifierList
    }

    /**
     * [EN] The registered themes, nil when none.
     * [CN] 已注册的主题，没有时为 nil。
     */
    @objc public var themes: [NSObject]? {
        themeList.isEmpty ? nil : themeList
    }

    /**
     * [EN] The theme of `identifier`.
     * [CN] `identifier` 对应的主题。
     */
    @objc(themeForIdentifier:)
    public func theme(forIdentifier identifier: NSCopying & NSObjectProtocol) -> NSObject? {
        identifierList.firstIndex { $0.isEqual(identifier) }.map { themeList[$0] }
    }

    /**
     * [EN] The identifier of `theme`.
     * [CN] `theme` 对应的标识。
     */
    @objc(identifierForTheme:)
    public func identifier(forTheme theme: NSObject) -> (NSCopying & NSObjectProtocol)? {
        themeList.firstIndex { $0.isEqual(theme) }.map { identifierList[$0] }
    }

    /**
     * [EN] Registers a theme; ignored when the identifier or the theme is registered already.
     * [CN] 注册主题；标识或主题已注册时忽略。
     */
    @objc(addThemeIdentifier:theme:)
    public func addThemeIdentifier(_ identifier: NSCopying & NSObjectProtocol, theme: NSObject) {
        if identifierList.contains(where: { $0.isEqual(identifier) }) || themeList.contains(where: { $0.isEqual(theme) }) {
            NSLog("🔴 CYLThemeManager: the theme identifier %@ or its theme is already registered.", String(describing: identifier))
            return
        }
        identifierList.append((identifier.copy() as? NSCopying & NSObjectProtocol) ?? identifier)
        themeList.append(theme)
        if persistsCurrentThemeIdentifier, storedIdentifier == nil, let saved = savedThemeIdentifier, identifier.isEqual(saved) {
            currentThemeIdentifier = identifier
        }
    }

    /**
     * [EN] Removes the theme of `identifier`.
     * [CN] 移除 `identifier` 对应的主题。
     */
    @objc(removeThemeIdentifier:)
    public func removeThemeIdentifier(_ identifier: NSCopying & NSObjectProtocol) {
        if let index = identifierList.firstIndex(where: { $0.isEqual(identifier) }) {
            identifierList.remove(at: index)
            themeList.remove(at: index)
        }
    }

    /**
     * [EN] Removes `theme`.
     * [CN] 移除 `theme`。
     */
    @objc(removeTheme:)
    public func removeTheme(_ theme: NSObject) {
        if let index = themeList.firstIndex(where: { $0.isEqual(theme) }) {
            identifierList.remove(at: index)
            themeList.remove(at: index)
        }
    }

    // MARK: - Notify

    private func notifyThemeChanged() {
        var snapshots: [UIView] = []
        if themeChangeAnimationDuration > 0 {
            for window in CYLThemeRuntime.applicationWindows where !window.isHidden && window.alpha > 0.01 {
                guard let snapshot = window.snapshotView(afterScreenUpdates: false) else {
                    continue
                }
                snapshot.frame = window.bounds
                snapshot.isUserInteractionEnabled = false
                window.addSubview(snapshot)
                snapshots.append(snapshot)
            }
        }
        NotificationCenter.default.post(name: .CYLThemeDidChange, object: self)
        let identifier = currentThemeIdentifier
        let theme = currentTheme
        CYLThemeRuntime.beginChange()
        for window in CYLThemeRuntime.applicationWindows where !window.isHidden && window.alpha > 0.01 {
            guard let root = window.rootViewController else {
                continue
            }
            root.cyl_themeDidChange(by: self, identifier: identifier, theme: theme)
            window.cyl_themeDidChange(by: self, identifier: identifier, theme: theme, enumeratesSubviews: true)
        }
        for view in CYLThemeRuntime.trackedViews {
            view.cyl_themeDidChange(by: self, identifier: identifier, theme: theme, enumeratesSubviews: true)
        }
        if !snapshots.isEmpty {
            UIView.animate(withDuration: themeChangeAnimationDuration, delay: 0, options: .beginFromCurrentState, animations: {
                snapshots.forEach { $0.alpha = 0 }
            }, completion: { _ in
                snapshots.forEach { $0.removeFromSuperview() }
            })
        }
        CYLThemeRuntime.endChange()
    }
}
