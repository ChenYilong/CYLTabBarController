//
//  UIViewController+CYLMemoryWarning.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Seam (docs/Swift-Migration.md): the members of `CYLTabBarController` (still Objective-C) that the memory warning
 *      demo reads. `CYLTabBarController` adopts it in `CYLTabBarController.m`; not meant for apps. Removed when
 *      `CYLTabBarController` moves to Swift.
 * [CN] 接缝（docs/Swift-Migration.md）：内存警告示例读取的 `CYLTabBarController`（仍为 Objective-C）成员。`CYLTabBarController` 在
 *      `CYLTabBarController.m` 中遵守它；不供 App 使用。`CYLTabBarController` 迁移到 Swift 后删除。
 */
@objc(CYLTabBarControllerMemoryWarningSeam)
public protocol CYLTabBarControllerMemoryWarningSeam: NSObjectProtocol {
    /**
     * [EN] `-[CYLTabBarController unloadsUnselectedViewsOnMemoryWarning]`.
     * [CN] `-[CYLTabBarController unloadsUnselectedViewsOnMemoryWarning]`。
     */
    var unloadsUnselectedViewsOnMemoryWarning: Bool { get }
    /**
     * [EN] `-[CYLTabBarController shouldUnloadViewOfViewController:]`.
     * [CN] `-[CYLTabBarController shouldUnloadViewOfViewController:]`。
     */
    @objc(shouldUnloadViewOfViewController:)
    func shouldUnloadView(of viewController: UIViewController) -> Bool
}

/**
 * [EN] Simulates a memory warning for `tabBarController` (`+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`)
 *      and describes what happened to each tab. Translated from Objective-C (docs/Swift-Migration.md); takes a
 *      `UITabBarController`, which every `CYLTabBarController` is.
 * [CN] 对 `tabBarController` 模拟内存警告（`+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`），并描述每个 Tab 的结果。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md）；参数类型为 `UITabBarController`，每个 `CYLTabBarController` 都是。
 */
public func CYLSimulateMemoryWarningReport(_ tabBarController: UITabBarController?) -> String {
    let viewControllers = tabBarController?.viewControllers ?? []
    let wasLoaded = viewControllers.map { CYLMemoryWarning.root(of: $0).isViewLoaded }
    CYLMemoryWarning.simulate(for: tabBarController)
    let seam = tabBarController as? CYLTabBarControllerMemoryWarningSeam
    let unloads = seam?.unloadsUnselectedViewsOnMemoryWarning ?? false
    var lines: [String] = []
    if tabBarController == nil {
        lines.append(CYLLocalizedString("不在 CYLTabBarController 中，没有可卸载的 Tab。"))
    } else if !unloads {
        lines.append(CYLLocalizedString("unloadsUnselectedViewsOnMemoryWarning = NO，未卸载任何 Tab。"))
    }
    for (index, viewController) in viewControllers.enumerated() where !viewController.cyl_isPlaceholder {
        let root = CYLMemoryWarning.root(of: viewController)
        let title = viewController.tabBarItem.title ?? root.title ?? NSStringFromClass(type(of: root))
        let status: String
        if !wasLoaded[index] {
            status = CYLLocalizedString("未加载")
        } else if !root.isViewLoaded {
            status = CYLLocalizedString("已卸载")
        } else if viewController === tabBarController?.selectedViewController {
            status = CYLLocalizedString("保留：当前选中")
        } else if unloads, seam?.shouldUnloadView(of: viewController) == false {
            status = CYLLocalizedString("保留：shouldUnload 返回 NO")
        } else {
            status = CYLLocalizedString("保留")
        }
        lines.append("\(title): \(status)")
    }
    return lines.joined(separator: "\n")
}

@_cdecl("CYLSimulateMemoryWarningReport")
public func cylSimulateMemoryWarningReportEntryPoint(_ tabBarController: UITabBarController?) -> NSString {
    CYLSimulateMemoryWarningReport(tabBarController) as NSString
}

/**
 * [EN] The memory warning row of the demos. Translated from Objective-C (docs/Swift-Migration.md).
 * [CN] 示例中的内存警告行。已从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
extension UIViewController {

    private static let memoryWarningCellIdentifier = "CYLMemoryWarningCell"

    /**
     * [EN] A table row "Simulate memory warning"; selecting it should call `cyl_simulateMemoryWarningAndShowResult()`.
     * [CN] "模拟内存警告"表格行；选中时应调用 `cyl_simulateMemoryWarningAndShowResult()`。
     */
    @objc(cyl_memoryWarningCellForTableView:)
    public func cyl_memoryWarningCell(for tableView: UITableView) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UIViewController.memoryWarningCellIdentifier)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: UIViewController.memoryWarningCellIdentifier)
        cell.textLabel?.font = .boldSystemFont(ofSize: 15)
        cell.detailTextLabel?.textColor = .gray
        cell.imageView?.image = UIImage(systemName: "memorychip")
        cell.textLabel?.text = CYLLocalizedString("模拟内存警告")
        cell.detailTextLabel?.text = CYLLocalizedString("卸载未选中的 Tab，切换时重新加载")
        return cell
    }

    /**
     * [EN] Simulates a memory warning for this view controller's tab bar controller and shows the result in an alert.
     * [CN] 对本控制器所在的 TabBarController 模拟内存警告，并用弹窗显示结果。
     */
    @objc(cyl_simulateMemoryWarningAndShowResult)
    public func cyl_simulateMemoryWarningAndShowResult() {
        let tabBarController = CYLMemoryWarning.tabBarController(of: self)
        let alertController = UIAlertController(title: CYLLocalizedString("内存警告"),
                                                message: CYLSimulateMemoryWarningReport(tabBarController),
                                                preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: CYLLocalizedString("OK"), style: .default))
        present(alertController, animated: true)
    }
}

/**
 * [EN] Seam (docs/Swift-Migration.md): calls into `CYLTabBarController` (still Objective-C) by selector.
 * [CN] 接缝（docs/Swift-Migration.md）：通过 selector 调用 `CYLTabBarController`（仍为 Objective-C）。
 */
private enum CYLMemoryWarning {

    static func root(of viewController: UIViewController) -> UIViewController {
        (viewController as? UINavigationController)?.viewControllers.first ?? viewController
    }

    // [EN] `+[CYLTabBarController cyl_simulateMemoryWarningForTabBarController:]`. [CN] 同左。
    static func simulate(for tabBarController: UITabBarController?) {
        let selector = NSSelectorFromString("cyl_simulateMemoryWarningForTabBarController:")
        guard let controllerClass = NSClassFromString("CYLTabBarController") as AnyObject?,
              controllerClass.responds(to: selector) else {
            return
        }
        _ = controllerClass.perform(selector, with: tabBarController)
    }

    // [EN] `-cyl_owningTabBarController`, then `-cyl_tabBarController`. [CN] 先 `-cyl_owningTabBarController`，再 `-cyl_tabBarController`。
    static func tabBarController(of viewController: UIViewController) -> UITabBarController? {
        for name in ["cyl_owningTabBarController", "cyl_tabBarController"] {
            let selector = NSSelectorFromString(name)
            if viewController.responds(to: selector),
               let controller = viewController.perform(selector)?.takeUnretainedValue() as? UITabBarController {
                return controller
            }
        }
        return nil
    }
}
