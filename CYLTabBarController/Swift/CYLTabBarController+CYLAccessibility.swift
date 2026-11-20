//
//  CYLTabBarController+CYLAccessibility.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The values the library wrote, so a later change updates them while values the app set are kept.
 * [CN] 本库写入的值，使之后的变化可以更新它们，同时保留 App 自己设置的值。
 */
private enum CYLTabAccessibilityKeys {
    static let identifierSetByCYL = CYLUtilsKeys.key("cyl_accessibilityIdentifierSetByCYL")
    static let labelSetByCYL = CYLUtilsKeys.key("cyl_accessibilityLabelSetByCYL")
}

typealias CYLAccessibilityElement = NSObject & UIAccessibilityIdentification

/**
 * [EN] The accessibility of the tabs (identifiers, labels, hints). Translated from Objective-C
 *      (docs/Swift-Migration.md, step 55); `-cyl_syncTabBarItemAccessibility` stays declared in the private header, as
 *      CYLTabBarController.m and CYLTabBar call it.
 * [CN] Tab 的无障碍信息（identifier、label、hint）。已从 Objective-C 翻译（docs/Swift-Migration.md，第 55 步）；
 *      `-cyl_syncTabBarItemAccessibility` 仍声明在私有头文件中，CYLTabBarController.m 与 CYLTabBar 会调用它。
 */
extension CYLTabBarController {

    /**
     * [EN] Writes `identifier` on `element` unless the app set a different one itself.
     * [CN] 写入 `identifier`，除非 App 自己设置了其他值。
     */
    private static func cylApplyDefaultAccessibilityIdentifier(_ element: CYLAccessibilityElement, _ identifier: String?) {
        guard let identifier, !identifier.isEmpty else {
            return
        }
        let current = element.accessibilityIdentifier ?? ""
        let setByCYL = objc_getAssociatedObject(element, CYLTabAccessibilityKeys.identifierSetByCYL) as? String ?? ""
        let ownedByApp = !current.isEmpty && current != setByCYL
        if ownedByApp || current == identifier {
            return
        }
        element.accessibilityIdentifier = identifier
        objc_setAssociatedObject(element, CYLTabAccessibilityKeys.identifierSetByCYL, identifier, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    /**
     * [EN] Writes the explicit identifier, label and hint of `attributes` on `element` (only values that changed).
     * [CN] 将 `attributes` 中显式指定的 identifier、label、hint 写入 `element`（只写入有变化的值）。
     */
    private static func cylApplyExplicitAccessibility(_ element: CYLAccessibilityElement, _ attributes: [String: Any]) {
        if let identifier = attributes[CYLTabBarItemAccessibilityIdentifier] as? String, element.accessibilityIdentifier != identifier {
            element.accessibilityIdentifier = identifier
            objc_setAssociatedObject(element, CYLTabAccessibilityKeys.identifierSetByCYL, identifier, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
        if let label = attributes[CYLTabBarItemAccessibilityLabel] as? String, element.accessibilityLabel != label {
            element.accessibilityLabel = label
        }
        if let hint = attributes[CYLTabBarItemAccessibilityHint] as? String, element.accessibilityHint != hint {
            element.accessibilityHint = hint
        }
    }

    /**
     * [EN] Liquid Glass draws each tab twice, in the normal layer and in the selected layer (the lens), and VoiceOver reads
     *      the selected layer's button. That button reads the item's own `accessibilityLabel` when it has one, else the
     *      title it got when it was created: after an in-place title change (`-updateTabBarItemAtIndex:attributes:`, a skin),
     *      VoiceOver read the old title. So the item's title is written as its label, unless the app set a different label.
     * [CN] 液态玻璃中每个 Tab 绘制两次：普通图层与选中图层（放大镜），VoiceOver 读取选中图层中的按钮。该按钮有 item 自己的
     *      `accessibilityLabel` 时读取它，否则读取创建时得到的标题：原地修改标题后（`-updateTabBarItemAtIndex:attributes:`、换肤），
     *      VoiceOver 读出旧标题。因此把 item 的标题写为其 label，除非 App 自己设置了其他 label。
     */
    private static func cylApplyDefaultAccessibilityLabel(_ item: UITabBarItem, _ title: String?) {
        guard let title, !title.isEmpty else {
            return
        }
        let current = item.accessibilityLabel ?? ""
        let setByCYL = objc_getAssociatedObject(item, CYLTabAccessibilityKeys.labelSetByCYL) as? String
        // [EN] Without a label of its own, the item reports its title. [CN] 没有自己的 label 时，item 返回其标题。
        let ownedByApp = !current.isEmpty && current != (setByCYL ?? "") && current != title
        if ownedByApp || setByCYL == title {
            return
        }
        item.accessibilityLabel = title
        objc_setAssociatedObject(item, CYLTabAccessibilityKeys.labelSetByCYL, title, .OBJC_ASSOCIATION_COPY_NONATOMIC)
    }

    /**
     * [EN] The FlatDesign button of the tab at `index`. The FlatDesign tab bar is an optional subspec, so its items are read
     *      at run time.
     * [CN] 第 `index` 个 Tab 的扁平样式按钮。扁平样式 TabBar 是可选子库，因此在运行时读取其 items。
     */
    private func cylFlatDesignTabButton(at index: Int) -> UIControl? {
        guard responds(to: NSSelectorFromString("items")), let items = value(forKey: "items") as? [NSObject], index < items.count,
              items[index].responds(to: NSSelectorFromString("tabBarButton")) else {
            return nil
        }
        return items[index].value(forKey: "tabBarButton") as? UIControl
    }

    /**
     * [EN] Gives every tab (and the plus button) an `accessibilityIdentifier` and the explicit accessibility values of its
     *      attributes. Runs on layout (`-cyl_syncTabBarAppearances`); only changed values are written.
     * [CN] 为每个 Tab（以及 PlusButton）设置 `accessibilityIdentifier` 及其 attributes 中显式指定的无障碍信息。在布局时执行
     *      （`-cyl_syncTabBarAppearances`）；只写入有变化的值。
     */
    @objc(cyl_syncTabBarItemAccessibility)
    func cylSyncTabBarItemAccessibility() {
        let viewControllers = self.viewControllers ?? []
        let isFlatDesign = tabBarStyleType == .flatDesign
        // [EN] Not FlatDesign: on iOS 26 `+isLiquidGlassActive` is YES with the FlatDesign tab bar too.
        // [CN] 不是扁平样式：iOS 26 上使用扁平样式 TabBar 时 `+isLiquidGlassActive` 也为 YES。
        let isLiquidGlassTabBar = !isFlatDesign && CYLConstants.isLiquidGlassActive()
        let plusChildViewController = cylPrivate.cylContextPlusChildViewController()
        for (index, viewController) in viewControllers.enumerated() {
            // [EN] The plus child view controller's tab sits under the plus button, which gets the identifier instead.
            // [CN] PlusButton 子控制器的 Tab 位于 PlusButton 下方，由 PlusButton 使用该标识。
            if viewController.cyl_isPlaceholder || viewController === plusChildViewController {
                continue
            }
            let element: CYLAccessibilityElement? = isFlatDesign ? cylFlatDesignTabButton(at: index) : viewController.tabBarItem
            guard let element else {
                continue
            }
            Self.cylApplyDefaultAccessibilityIdentifier(element, viewController.cyl_tabBarItemIdentifier)
            if let attributes = tabBarItemAttributes(at: UInt(index)) {
                Self.cylApplyExplicitAccessibility(element, attributes)
            }
            if isLiquidGlassTabBar {
                Self.cylApplyDefaultAccessibilityLabel(viewController.tabBarItem, viewController.tabBarItem.title)
            }
        }
        guard let plusButton = cylPrivate.cylContextPlusButton(), hasPlusButton() else {
            return
        }
        Self.cylApplyDefaultAccessibilityIdentifier(plusButton, plusButton.cyl_tabBarItemIdentifier)
        // [EN] Liquid Glass: the plus child view controller's tab sits under the plus button and reads as the plus button.
        //      Its label was set once, at setup, and kept the old title after the plus button's title changed.
        // [CN] 液态玻璃：PlusButton 子控制器的 Tab 位于 PlusButton 下方，读作 PlusButton。其 label 以前只在设置时写入一次，
        //      PlusButton 标题变化后仍为旧标题。
        if isLiquidGlassTabBar, let plusChildViewController, let plusLabel = plusButton.accessibilityLabel, !plusLabel.isEmpty,
           plusChildViewController.tabBarItem.accessibilityLabel != plusLabel {
            plusChildViewController.tabBarItem.accessibilityLabel = plusLabel
        }
    }
}
