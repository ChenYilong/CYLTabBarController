//
//  CYLTabBarController+CYLMemoryWarning.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/// [EN] The associated object key of `cyl_keepsLoadedTabBarItemIdentifiers` (selector-based, as in CYLTabBarController.m before).
/// [CN] `cyl_keepsLoadedTabBarItemIdentifiers` 的关联对象 key（基于 selector，与原 CYLTabBarController.m 相同）。
private let CYLKeepsLoadedTabBarItemIdentifiersKey = CYLUtilsKeys.key("cyl_keepsLoadedTabBarItemIdentifiers")

/**
 * FIX: issue #426
 * [EN] Unloading the views of the tabs that are not selected on a memory warning (`unloadsUnselectedViewsOnMemoryWarning`),
 *      declared in `CYLTabBarController (CYLMemoryWarning)`. A navigation controller's stack is unloaded with it or not at
 *      all; a tab is skipped while its view is on screen or it presents a view controller. Translated from Objective-C
 *      (docs/Swift-Migration.md, step 103).
 * [CN] 收到内存警告时卸载未选中 Tab 的视图（`unloadsUnselectedViewsOnMemoryWarning`），声明于 `CYLTabBarController (CYLMemoryWarning)`。
 *      导航控制器的栈与它一起卸载或都不卸载；Tab 的视图在屏幕上或正在 present 其他控制器时跳过。已从 Objective-C 翻译（docs/Swift-Migration.md，第 103 步）。
 */
extension CYLTabBarController {

    // [EN] Internal: the generated header must not declare these (it is read before the class); Objective-C callers and
    //      subclasses use the declarations of `CYLTabBarController (CYLMemoryWarning)` in CYLTabBarController.h, and calls go
    //      through Objective-C dispatch, so overrides in subclasses still apply. `-didReceiveMemoryWarning` stays in the
    //      Objective-C class: an override in an extension of a public class would have to be public.
    // [CN] 内部访问级别：生成的头文件不能声明它们（它在类之前被读取）；Objective-C 调用方与子类使用 CYLTabBarController.h 中
    //      `CYLTabBarController (CYLMemoryWarning)` 的声明，调用经由 Objective-C 派发，子类的重写仍然生效。`-didReceiveMemoryWarning` 留在
    //      Objective-C 类中：在公开类的扩展中重写必须是 public。

    @objc(shouldUnloadViewOfViewController:)
    open dynamic func shouldUnloadView(of viewController: UIViewController) -> Bool {
        guard let identifier = viewController.cyl_tabBarItemIdentifier else { return true }
        return !cylKeepsLoadedTabBarItemIdentifiers().contains(identifier)
    }

    @objc(cyl_keepsLoadedTabBarItemIdentifiers)
    open var cyl_keepsLoadedTabBarItemIdentifiers: [String] {
        @objc(cyl_keepsLoadedTabBarItemIdentifiers) get { cylKeepsLoadedTabBarItemIdentifiers() }
        @objc(setCyl_keepsLoadedTabBarItemIdentifiers:) set { cylSetKeepsLoadedTabBarItemIdentifiers(newValue) }
    }

    func cylKeepsLoadedTabBarItemIdentifiers() -> [String] {
        objc_getAssociatedObject(self, CYLKeepsLoadedTabBarItemIdentifiersKey) as? [String] ?? []
    }

    func cylSetKeepsLoadedTabBarItemIdentifiers(_ identifiers: [String]) {
        objc_setAssociatedObject(self, CYLKeepsLoadedTabBarItemIdentifiersKey, identifiers, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    @objc(unloadViewsOfUnselectedViewControllers)
    open func unloadViewsOfUnselectedViewControllers() {
        let selected = selectedViewController
        for viewController in viewControllers ?? [] where viewController !== selected && !viewController.cyl_isPlaceholder {
            // [EN] A navigation controller's stack is unloaded with it, or not at all. [CN] 导航控制器的栈与它一起卸载，或都不卸载。
            var toUnload = (viewController as? UINavigationController)?.viewControllers ?? []
            toUnload.append(viewController)
            let busy = toUnload.contains { $0.isViewLoaded && ($0.view.window != nil || $0.presentedViewController != nil) }
            guard !busy, shouldUnloadView(of: viewController) else { continue }
            for each in toUnload where each.isViewLoaded {
                // [EN] Setting `view` to nil does not take it out of its superview (e.g. the navigation controller's).
                // [CN] 把 `view` 设为 nil 不会把它从父视图（例如导航控制器的视图）中移除。
                each.view.removeFromSuperview()
                each.view = nil
            }
        }
    }
}
