//
//  CYLTabBarController+CYLTabBarAccessors.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/// [EN] The system tab bar height, the default of `tabBarHeight`. [CN] 系统 TabBar 的高度，`tabBarHeight` 的默认值。
private let CYLDefaultTabBarHeight: CGFloat = 49

/**
 [EN] The FlatDesign parts of the accessors, implemented by CYLTabBarController+CYLFlatDesignTabBarAccessors.swift in the
      FlatDesign subspec.
 [CN] 访问器的扁平样式部分，由扁平样式子库中的 CYLTabBarController+CYLFlatDesignTabBarAccessors.swift 实现。
 */
@objc protocol CYLFlatDesignTabBarAccessors {
    @objc(cyl_flatDesignInstallTabBarIfNeeded) optional func cylFlatDesignInstallTabBarIfNeeded()
    @objc(cyl_flatDesignApplyTabBarHeight:) optional func cylFlatDesignApplyTabBarHeight(_ tabBarHeight: CGFloat)
}

/// [EN] Storage and helpers implemented in CYLTabBarController.m. [CN] 实现于 CYLTabBarController.m 的存储与辅助方法。
@objc protocol CYLTabBarAccessorsStorage {
    @objc(cyl_tabBarHeightStorage) func cylTabBarHeightStorage() -> CGFloat
    @objc(cyl_setTabBarHeightStorage:) func cylSetTabBarHeightStorage(_ tabBarHeight: CGFloat)
    @objc(isObservingTabImageViewDefaultOffset) func cylIsObservingTabImageViewDefaultOffset() -> Bool
    @objc(setObservingTabImageViewDefaultOffset:) func cylSetObservingTabImageViewDefaultOffset(_ observing: Bool)
    @objc(setCylRefreshedSystemTabBarWindow:) func cylSetRefreshedSystemTabBarWindow(_ window: UIWindow?)
    @objc(setTabBarHidden:) func cylSetTabBarHidden(_ hidden: Bool)
    @objc(setCyl_tabBarHidden:) func cylSetTabBarHiddenRequest(_ hidden: Bool)
    @objc(tabBarIsAnimating) func cylTabBarIsAnimating() -> Bool
}

/**
 [EN] Block 5 of the second batch handed over by Mac-CYLTabBarController文件夹 (docs/Swift-Migration.md, step 128): the bodies of
      the `cyl_tabBar` getter (the tab bar is created lazily: CYLTabBar, or the FlatDesign one), `-setContext:` and the
      `tabBarHeight` accessors. The accessors stay one-line forwarders in CYLTabBarController.m (a Swift extension cannot
      replace the accessors of an Objective-C property); the ivars go through `CYLTabBarController (CYLTabSetupStorage)`.
 [CN] 另一会话移交的第二批第 5 块（第 128 步）：`cyl_tabBar` getter（TabBar 延迟创建：CYLTabBar 或扁平样式 TabBar）、`-setContext:` 与
      `tabBarHeight` 访问器的实现。访问器在 CYLTabBarController.m 中保留为一行的转发（Swift 扩展无法替换 Objective-C 属性的访问器）；
      实例变量通过 `CYLTabBarController (CYLTabSetupStorage)` 访问。
 */
extension CYLTabBarController {

    var cylTabBarAccessorsStorage: CYLTabBarAccessorsStorage {
        unsafeBitCast(self as AnyObject, to: CYLTabBarAccessorsStorage.self)
    }

    private var cylFlatDesignTabBarAccessors: CYLFlatDesignTabBarAccessors {
        unsafeBitCast(self as AnyObject, to: CYLFlatDesignTabBarAccessors.self)
    }

    /// [EN] Whether `view` is the FlatDesign tab bar (by class name: the class is in the FlatDesign subspec).
    /// [CN] `view` 是否为扁平样式 TabBar（按类名判断：该类位于扁平样式子库）。
    func cylIsFlatDesignTabBar(_ view: UIView?) -> Bool {
        guard let view, let flatDesignClass = NSClassFromString("CYLFlatDesignTabBar") else { return false }
        return view.isKind(of: flatDesignClass)
    }

    /**
     [EN] The `cyl_tabBar` getter. The classic style and Liquid Glass: CYLTabBar, set up on first use (`-setUpDefaultStyleTabBar`)
          and observed for `tabImageViewDefaultOffset`; FlatDesign: the FlatDesign tab bar, in the FlatDesign subspec. A tab bar
          of the other style is dropped first.
     [CN] `cyl_tabBar` 的 getter。经典样式与液态玻璃：首次使用时设置 CYLTabBar（`-setUpDefaultStyleTabBar`）并观察 `tabImageViewDefaultOffset`；
          扁平样式：扁平样式 TabBar，由扁平样式子库处理。先丢弃另一种样式的 TabBar。
     */
    @objc(cyl_lazyTabBar)
    func cylLazyTabBar() -> UIView? {
        let storage = cylTabSetupStorage
        guard tabBarStyleType != .flatDesign else {
            cylFlatDesignTabBarAccessors.cylFlatDesignInstallTabBarIfNeeded?()
            return cylPrivate.cylStoredTabBar()
        }
        if cylIsFlatDesignTabBar(cylPrivate.cylStoredTabBar()) {
            storage.cylSetStoredTabBar(nil)
        }
        if cylPrivate.cylStoredTabBar() == nil {
            cylSetUpDefaultStyleTabBar()
            let accessors = cylTabBarAccessorsStorage
            if !accessors.cylIsObservingTabImageViewDefaultOffset() {
                // [EN] Formerly inside `@try` ("may crash when deallocating"); adding an observer for a key the class has does not
                //      raise. [CN] 以前位于 `@try` 中；为类中存在的键添加观察不会抛异常。
                cylPrivate.cylStoredTabBar()?.addObserver(self, forKeyPath: "tabImageViewDefaultOffset", options: .new,
                                                          context: CYLTabBarController.cylTabImageViewDefaultOffsetKVOContext())
                accessors.cylSetObservingTabImageViewDefaultOffset(true)
            }
            NotificationCenter.default.post(name: NSNotification.Name.CYLTabBarStyleTypeDidChange, object: self)
        }
        return cylPrivate.cylStoredTabBar()
    }

    /**
     [EN] The body of `-setContext:`: stores the context and passes it to the tab bar (FlatDesign: only to the FlatDesign tab bar).
          FIX: issue #556 — `-cyl_setValue:forKey:` checks the key and logs a failure (a subclass that does not call
          `super.viewDidLoad()` last), which replaces the former `@try`.
     [CN] `-setContext:` 的实现：保存 context 并传给 TabBar（扁平样式：只传给扁平样式 TabBar）。FIX：issue #556——`-cyl_setValue:forKey:`
          会检查键并在失败时输出日志（子类没有在最后调用 `super.viewDidLoad()`），代替原来的 `@try`。
     */
    @objc(cyl_applyContext:)
    func cylApplyContext(_ context: String?) {
        if tabBarStyleType == .flatDesign && !cylIsFlatDesignTabBar(cylPrivate.cylStoredTabBar()) {
            return
        }
        cyl_context = context
        cyl_tabBar?.cyl_setValue(cyl_context, forKey: "context")
    }

    /// [EN] The `tabBarHeight` getter: the system height until one is set. [CN] `tabBarHeight` 的 getter：未设置时为系统高度。
    @objc(cyl_resolvedTabBarHeight)
    func cylResolvedTabBarHeight() -> CGFloat {
        let accessors = cylTabBarAccessorsStorage
        let isFlatDesignWithoutItsTabBar = tabBarStyleType == .flatDesign && !cylIsFlatDesignTabBar(cylPrivate.cylStoredTabBar())
        if !isFlatDesignWithoutItsTabBar && accessors.cylTabBarHeightStorage() == 0 {
            // [EN] Not the global `CYLTabBarHeight`: another controller with a custom height wrote it. [CN] 不使用全局变量：其他控制器会改写它。
            accessors.cylSetTabBarHeightStorage(CYLDefaultTabBarHeight)
        }
        return accessors.cylTabBarHeightStorage()
    }

    /// [EN] The `tabBarHeight` setter; FlatDesign in the FlatDesign subspec. [CN] `tabBarHeight` 的 setter；扁平样式由扁平样式子库处理。
    @objc(cyl_applyTabBarHeight:)
    func cylApplyTabBarHeight(_ tabBarHeight: CGFloat) {
        guard tabBarStyleType != .flatDesign else {
            cylFlatDesignTabBarAccessors.cylFlatDesignApplyTabBarHeight?(tabBarHeight)
            return
        }
        cylTabBarAccessorsStorage.cylSetTabBarHeightStorage(tabBarHeight)
        CYLTabBarHeight = tabBarHeight
    }
}
