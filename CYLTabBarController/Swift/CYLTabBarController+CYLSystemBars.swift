//
//  CYLTabBarController+CYLSystemBars.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/// [EN] Storage implemented in CYLTabBarController.m. [CN] 实现于 CYLTabBarController.m 的存储。
@objc protocol CYLSystemBarsStorage {
    @objc(cyl_setAllowsVerticalBarStorage:) func cylSetAllowsVerticalBarStorage(_ allowsVerticalBar: Bool)
}

/// [EN] The folders of Apple's frameworks, as path components. [CN] 系统框架所在的文件夹，以路径组件表示。
private let systemFrameworkFolders = [["System", "Library"], ["usr", "lib"], ["Developer", "Library"]]

/**
 [EN] Whether an image path lies in a folder of Apple's frameworks (compared by path components, so no path literal is spelled out).
 [CN] 镜像路径是否位于系统框架所在的文件夹（按路径组件比较，因此不写出路径字面量）。
 */
func cylIsSystemFrameworkPath(_ path: String) -> Bool {
    let components = (path as NSString).pathComponents
    return systemFrameworkFolders.contains { folder in
        components.indices.contains { start in
            start + folder.count < components.count && Array(components[start..<(start + folder.count)]) == folder
        }
    }
}

/**
 FIX: issue #672
 [EN] Whether `selector` on `cls` comes from app code rather than a system framework such as UIKitCore.
 [CN] `cls` 的 `selector` 是否来自 App 代码，而不是 UIKitCore 等系统框架。
 */
private func cylIsImplementedOutsideSystemFrameworks(_ cls: AnyClass, _ selector: Selector) -> Bool {
    let implementation: IMP? = class_getMethodImplementation(cls, selector)
    guard let implementation else { return false }
    var info = Dl_info()
    guard dladdr(unsafeBitCast(implementation, to: UnsafeRawPointer.self), &info) != 0, let fileName = info.dli_fname else { return false }
    let path = String(cString: fileName)
    return !cylIsSystemFrameworkPath(path)
}

/**
 [EN] Block 6 of the second batch handed over by Mac-CYLTabBarController文件夹 (docs/Swift-Migration.md, step 129): the status bar
      and the vertical bar (iOS 27.1+, iPhone Duo). The UIKit overrides stay one-line forwarders in CYLTabBarController.m (a Swift
      extension of an Objective-C class cannot override them). The iOS 27.1 API is called by selector, so this builds with an
      older SDK (CI on Xcode 26); the overrides that name its types stay behind the SDK check in the `.m`.
 [CN] 另一会话移交的第二批第 6 块（第 129 步）：状态栏与竖向栏（iOS 27.1+，iPhone Duo）。UIKit 重写在 CYLTabBarController.m 中保留为一行的转发
      （Objective-C 类的 Swift 扩展无法重写它们）。iOS 27.1 的 API 通过 selector 调用，因此较旧的 SDK（CI 上的 Xcode 26）也能构建；使用其类型的
      重写在 `.m` 中留在 SDK 判断之后。
 */
extension CYLTabBarController {

    /**
     FIX: status bar style at launch
     [EN] The tab on screen: the selected view controller; before the first selection `selectedViewController` is nil and
          `selectedIndex` is -1 (classic and Liquid Glass) while the first tab is shown, so the tab at `selectedIndex` if that
          index is valid, else the first tab. Never the last tab.
     [CN] 屏幕上显示的 Tab：选中的控制器；首次选中之前 `selectedViewController` 为 nil、`selectedIndex` 为 -1（经典样式与液态玻璃），
          而此时显示的是第一个 Tab，因此取 `selectedIndex` 对应的 Tab（下标有效时），否则取第一个 Tab。绝不取最后一个 Tab。
     */
    @objc(cyl_displayedViewController)
    func cylDisplayedViewController() -> UIViewController? {
        if let selectedViewController {
            return selectedViewController
        }
        let tabs = viewControllers ?? []
        return tabs.indices.contains(selectedIndex) ? tabs[selectedIndex] : tabs.first
    }

    /**
     FIX: status bar style at launch
     [EN] The child that decides the status bar (and its hidden state, update animation, home indicator): the tab on screen
          (`cylDisplayedViewController()`), so at launch the first tab decides, not the last one.
     [CN] 决定状态栏（及其隐藏、更新动画、Home 指示条）的子控制器：屏幕上显示的 Tab（`cylDisplayedViewController()`），因此启动时由第一个 Tab
          决定，而不是最后一个。
     */
    @objc(cyl_childViewControllerForStatusBarStyle)
    func cylChildViewControllerForStatusBarStyle() -> UIViewController? {
        cylDisplayedViewController()
    }

    /**
     FIX: issue #653
     [EN] The body of `-setAllowsVerticalBar:`: a convenience switch for UIKit's `preferredVerticalBarBehavior` (NO keeps the tab
          bar horizontal; YES restores the system default), applied at once on iOS 27.1 and later.
     [CN] `-setAllowsVerticalBar:` 的实现：UIKit `preferredVerticalBarBehavior` 的便捷开关（NO 保持 TabBar 横向；YES 恢复系统默认），在 iOS 27.1
          及以上立即生效。
     */
    @objc(cyl_applyAllowsVerticalBar:)
    func cylApplyAllowsVerticalBar(_ allowsVerticalBar: Bool) {
        guard self.allowsVerticalBar != allowsVerticalBar else { return }
        unsafeBitCast(self as AnyObject, to: CYLSystemBarsStorage.self).cylSetAllowsVerticalBarStorage(allowsVerticalBar)
        let update = NSSelectorFromString("setNeedsUpdateOfVerticalBarConfiguration")
        if responds(to: update) {
            perform(update)
        }
    }

    /**
     FIX: issue #672
     [EN] Whether a view controller on the `childViewControllerForPreferredVerticalBarBehavior` chain that starts at the selected
          view controller implements `preferredVerticalBarBehavior` in app code. UIKit's own implementations do not count, so
          screens without an override still follow `allowsVerticalBar`.
     [CN] 从选中的控制器开始的 `childViewControllerForPreferredVerticalBarBehavior` 链上，是否有控制器在 App 代码里实现了
          `preferredVerticalBarBehavior`。UIKit 自带的实现不算，所以没有重写的页面仍按 `allowsVerticalBar` 处理。
     */
    @objc(cyl_selectedChildOverridesVerticalBarBehavior)
    func cylSelectedChildOverridesVerticalBarBehavior() -> Bool {
        let behavior = NSSelectorFromString("preferredVerticalBarBehavior")
        let childGetter = NSSelectorFromString("childViewControllerForPreferredVerticalBarBehavior")
        var viewController = cylDisplayedViewController()
        var depth = 0
        while let current = viewController, depth < 16 {
            depth += 1
            if cylIsImplementedOutsideSystemFrameworks(type(of: current), behavior) {
                return true
            }
            guard current.responds(to: childGetter),
                  let child = current.perform(childGetter)?.takeUnretainedValue() as? UIViewController, child !== current else { break }
            viewController = child
        }
        return false
    }
}
