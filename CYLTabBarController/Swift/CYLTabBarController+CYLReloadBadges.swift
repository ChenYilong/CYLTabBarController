//
//  CYLTabBarController+CYLReloadBadges.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/// [EN] The blocks of `-reloadBadgesWithBlock:` / `-performWhenTabBarItemsReady:` that wait for the tab buttons (#404).
/// [CN] `-reloadBadgesWithBlock:` / `-performWhenTabBarItemsReady:` 中等待 Tab 按钮创建的 block（#404）。
private let cylPendingReloadBadgesBlocksKey = CYLUtilsKeys.key("cyl_pendingReloadBadgesBlocks")

/**
 * FIX: issue #404, issue #605, issue #610
 * [EN] Waiting for the tab buttons before running badge blocks (#404), and the target-actions of the classic tab buttons:
 *      added in the layout pass that places them, including buttons UIKit replaced after a change of a tab item's image or
 *      title (#610, #605). Declared in `CYLTabBarController (CYLReloadBadges)` (public) and in CYLTabBarController+CYLPrivate.h
 *      (the rest, called by CYLTabBarController.m). Internal Swift members with the Objective-C selectors: the generated
 *      header must not declare a category of the class (it is read before it). Translated from Objective-C
 *      (docs/Swift-Migration.md, step 105).
 * [CN] 在 Tab 按钮创建后再执行角标 block（#404），以及经典 Tab 按钮的点击事件：在放置按钮的布局中添加，包括修改 tabBarItem 的图片或标题后 UIKit
 *      替换的按钮（#610、#605）。声明于 `CYLTabBarController (CYLReloadBadges)`（公开）与 CYLTabBarController+CYLPrivate.h（其余，由
 *      CYLTabBarController.m 调用）。以 Objective-C selector 实现的内部 Swift 成员：生成的头文件不能声明该类的类别（它在类之前被读取）。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，第 105 步）。
 */
extension CYLTabBarController {

    private var cylPendingReloadBadgesBlocks: NSMutableArray {
        if let blocks = objc_getAssociatedObject(self, cylPendingReloadBadgesBlocksKey) as? NSMutableArray {
            return blocks
        }
        let blocks = NSMutableArray()
        objc_setAssociatedObject(self, cylPendingReloadBadgesBlocksKey, blocks, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return blocks
    }

    @objc(reloadBadgesWithBlock:)
    func cylReloadBadges(with block: CYLViewDidLayoutSubViewsBlock?) {
        if let block { perform(whenTabBarItemsReady: block) }
    }

    @objc(performWhenTabBarItemsReady:)
    open func perform(whenTabBarItemsReady block: @escaping CYLViewDidLayoutSubViewsBlock) {
        cylPendingReloadBadgesBlocks.add(block)
        cylRunPendingReloadBadgesBlocksIfReady()
        if cylPendingReloadBadgesBlocks.count > 0, isViewLoaded, view.window != nil {
            view.setNeedsLayout()
        }
    }

    /// [EN] The tab buttons exist once the first real tab's badge host is a laid-out view: until then it is nil, or a
    ///      `UITabBarItem` (Liquid Glass) or a not yet sized control, and a badge shown on it would be dropped.
    /// [CN] 第一个真实 Tab 的角标宿主成为已布局的视图时，Tab 按钮即已创建：在此之前它为 nil、`UITabBarItem`（液态玻璃）或尚未确定尺寸的控件，
    ///      此时显示的角标会被丢弃。
    private func cylTabButtonsAreReadyForBadges() -> Bool {
        guard isViewLoaded else { return false }
        if tabBarStyleType != .flatDesign && (tabBar.items?.isEmpty ?? true) { return false }
        for viewController in viewControllers ?? [] where !viewController.cyl_isPlaceholder {
            var host: Any? = viewController.cyl_getActualBadgeSuperView()
            if let item = host as? UITabBarItem {
                host = item.cyl_getActualBadgeSuperView()
            }
            if let view = host as? UIView, view.bounds.width > 10 {
                return true
            }
        }
        return false
    }

    @objc(cyl_runPendingReloadBadgesBlocksIfReady)
    func cylRunPendingReloadBadgesBlocksIfReady() {
        let pending = cylPendingReloadBadgesBlocks
        guard pending.count > 0 else { return }
        if !cylTabButtonsAreReadyForBadges() {
            guard isViewLoaded, view.window != nil else { return }
            cyl_tabBar?.layoutIfNeeded()
            guard cylTabButtonsAreReadyForBadges() else { return }
        }
        let blocks = pending.copy() as? [Any] ?? []
        pending.removeAllObjects()
        for case let block as CYLViewDidLayoutSubViewsBlock in blocks {
            block(self)
        }
    }

    /// [EN] Adds a target-action once: the first event of `events` decides whether it is already there (#610).
    /// [CN] 只添加一次点击事件：以 `events` 中的第一个事件判断是否已添加（#610）。
    private func cylAddTabControlActionOnce(_ control: UIControl, _ action: Selector, _ events: UIControl.Event) {
        let firstEvent = UIControl.Event(rawValue: events.rawValue & (~events.rawValue &+ 1))
        let existing = control.actions(forTarget: self, forControlEvent: firstEvent) ?? []
        if !existing.contains(NSStringFromSelector(action)) {
            control.addTarget(self, action: action, for: events)
        }
    }

    /// [EN] #605: a tab button UIKit made after a title change becomes its view controller's tab button, and a tab with an
    ///      animation gets its animation view again (the selected tab shows its last frame, as at launch).
    /// [CN] #605：标题改变后 UIKit 新建的 Tab 按钮成为其控制器的 Tab 按钮，有动画的 Tab 重新获得动画视图（选中的 Tab 与启动时一样显示最后一帧）。
    @objc(cyl_adoptTabButton:forTabBarItem:)
    func cylAdoptTabButton(_ tabButton: UIControl?, forTabBarItem item: UITabBarItem?) {
        guard let tabButton = tabButton, let item = item else { return }
        for viewController in viewControllers ?? [] where viewController.tabBarItem === item && viewController.cyl_tabButton !== tabButton {
            viewController.cyl_tabButton = tabButton
        }
        guard isTabBarItemAnimationViewAdded, let animationURL = item.cyl_tabBarItemAnimationURL,
              tabButton.cylTabBarItemAnimationView() == nil else { return }
        let isSelected = item === selectedViewController?.tabBarItem
        cylAddLottieImage(withControl: tabButton, lottieURL: animationURL,
                                     lottieSizeValue: item.cyl_tabBarItemAnimationSizeValue,
                                     animation: isSelected, defaultSelected: isSelected)
    }

    /// [EN] #605: the button to go on with after a tap; on the classic tab bar UIKit may have replaced the tapped button
    ///      (the page changed its tab's title while loading); laying the tab bar out adopts the new one.
    /// [CN] #605：点击后继续使用的按钮；在经典 TabBar 上，UIKit 可能已替换被点击的按钮（页面在加载时修改了 Tab 标题）；布局 TabBar 时接管新按钮。
    @objc(cyl_tabButtonReplacingTappedControl:)
    func cylTabButtonReplacingTappedControl(_ control: UIControl?) -> UIControl? {
        guard let control = control, control.superview == nil, control.cylIsTabButton(), !CYLConstants.isLiquidGlassActive() else {
            return control
        }
        cyl_tabBar?.layoutIfNeeded()
        return selectedViewController?.tabBarItem.cyl_tabButton ?? control
    }

    /// [EN] The target-actions of the classic tab buttons (not Liquid Glass, not FlatDesign), and each button's tab index;
    ///      only system tab buttons are counted (a plus button without a child view controller takes a slot, no index).
    /// [CN] 经典 Tab 按钮（非液态玻璃、非扁平样式）的点击事件与每个按钮的 Tab 下标；只计系统 Tab 按钮（没有子控制器的 PlusButton 占位但没有下标）。
    @objc(cyl_bindTabControlActions)
    func cylBindTabControlActions() {
        guard let tabBar = cyl_tabBar as? CYLTabBar, !CYLConstants.isLiquidGlassActive() else { return }
        let action = #selector(CYLTabBarController.tabChanged(to:))
        var tabIndex = 0
        for control in tabBar.cylVisibleControls() ?? [] {
            let isTabButton = control.cylIsTabButton()
            let controlTabIndex = isTabButton ? tabIndex : NSNotFound
            if isTabButton {
                tabIndex += 1
                control.cyl_tabBarChildViewControllerIndex = controlTabIndex
            }
            if control.cylIsChildViewControllerPlusButton() {
                control.removeTarget(self, action: action, for: .touchUpInside)
                continue
            }
            control.cylTabLabel()?.textAlignment = .center
            cylAddTabControlActionOnce(control, action, .touchUpInside)
            if isTabButton {
                cylAdoptTabButton(control, forTabBarItem: cylTabBarItem(forTabButton: control))
                cylAddTabControlActionOnce(control, NSSelectorFromString("cyl_tabButtonTouchDown:"), .touchDown)
                cylAddTabControlActionOnce(control, NSSelectorFromString("cyl_tabButtonTouchUp:"), [.touchUpInside, .touchUpOutside, .touchCancel])
            }
            if isTabButton && selectedIndex != NSNotFound {
                control.isSelected = controlTabIndex == selectedIndex
            }
        }
        cylUpdateSelectedBackgroundColorsOfTabButtons()
    }
}
