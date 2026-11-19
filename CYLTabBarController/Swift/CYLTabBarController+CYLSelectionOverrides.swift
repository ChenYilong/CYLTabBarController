//
//  CYLTabBarController+CYLSelectionOverrides.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The FlatDesign side of the selection, implemented in the FlatDesign subspec (CYLTabBarController+CYLFlatDesign.swift).
 *      Optional: without that subspec nothing answers.
 * [CN] 选中的扁平样式部分，由扁平样式子库实现。可选：没有该子库时无人响应。
 */
@objc protocol CYLFlatDesignSelection {
    /// [EN] After `-setSelectedViewController:`: the stored index (any style, as the FlatDesign build always did) and the FlatDesign item.
    /// [CN] `-setSelectedViewController:` 之后：存储的下标（所有样式，与扁平样式构建一直以来的行为相同）以及扁平样式的 item。
    @objc(cyl_flatDesignDidSetSelectedViewController:) optional func cylFlatDesignDidSetSelectedViewController(_ viewController: UIViewController)
    /// [EN] `-setSelectedIndex:` in the FlatDesign style. [CN] 扁平样式下的 `-setSelectedIndex:`。
    @objc(cyl_flatDesignSetSelectedIndex:) optional func cylFlatDesignSetSelectedIndex(_ selectedIndex: UInt)
}

/**
 * [EN] The selection overrides (`-setSelectedViewController:` for a tap, `-setSelectedIndex:` in code), translated from
 *      Objective-C (docs/Swift-Migration.md, step 77). The UIKit overrides stay in CYLTabBarController.m as one-line forwarders
 *      until the class is Swift, and so do the two setters of the re-synthesized storage (`_selectedViewController`,
 *      `_selectedIndex`), which Swift cannot write.
 * [CN] 选中相关的重写（点击时的 `-setSelectedViewController:`、代码中的 `-setSelectedIndex:`），已从 Objective-C 翻译（第 77 步）。UIKit 重写以及
 *      重新合成的存储（`_selectedViewController`、`_selectedIndex`）的两个 setter 在类迁移到 Swift 之前保留在 CYLTabBarController.m 中（Swift 无法写入它们）。
 */
extension CYLTabBarController {

    private var cylFlatDesignSelection: CYLFlatDesignSelection {
        unsafeBitCast(self, to: CYLFlatDesignSelection.self)
    }

    /**
     * [EN] A tab selected by a tap (and by `-setSelectedIndex:`). A tab under "More" is a child of the More navigation controller,
     *      not of this controller, and can still be selected. Liquid Glass reports the change here instead of in the tap.
     * [CN] 点击（以及 `-setSelectedIndex:`）选中的 Tab。收在「More」下的 Tab 是 More 导航控制器的子控制器，仍可以被选中。液态玻璃在这里而不是点击中上报变化。
     */
    @objc(cyl_setSelectedViewController:)
    func cylSetSelectedViewController(_ selectedViewController: UIViewController?) {
        cylSetNeedsUpdateTabBarItemIconViews()
        cylSetNeedsUpdateSelectedBackgroundColors()
        guard let selectedViewController,
              children.contains(where: { $0 === selectedViewController }) || (viewControllers ?? []).contains(where: { $0 === selectedViewController }) else {
            return
        }
        super.selectedViewController = selectedViewController
        cylPrivate.cylSetSelectedViewControllerStorage(selectedViewController)
        // FIX: issue #433 — the selected tab shows its selected title. [CN] 选中的 Tab 显示选中标题。
        cylSetNeedsUpdateTabBarItemSelectedTitles(self)
        if selectedViewController.cyl_isPlaceholder {
            return
        }
        guard tabBarStyleType != .flatDesign else {
            cylFlatDesignSelection.cylFlatDesignDidSetSelectedViewController?(selectedViewController)
            return
        }
        cylFlatDesignSelection.cylFlatDesignDidSetSelectedViewController?(selectedViewController)
        // FIX: issue #574
        // [EN] The classic tab bar sometimes became transparent on iOS 15 and later: show its effect and shadow views again.
        // [CN] iOS 15 及以上经典 TabBar 有时会变透明：重新显示其效果视图与阴影视图。
        if #available(iOS 15.0, *), !CYLConstants.isLiquidGlassActive(), UITabBar.appearance().backgroundImage == nil, let tabBar = cyl_tabBar as? UITabBar {
            tabBar.cyl_tabBackgroundView()?.cyl_tabEffectView()?.alpha = 1
            if let shadow = tabBar.cyl_tabShadowImageView(), let first = shadow.subviews.first {
                first.alpha = 1
            }
        }
        guard CYLConstants.isLiquidGlassActive() else {
            return
        }
        // [EN] Liquid Glass reports the change here, not in a tap action (a tap and code both come here).
        // [CN] 液态玻璃在这里而不是点击事件中上报变化（点击与代码都会到这里）。
        if let plusChild = cylPrivate.cylContextPlusChildViewController(), selectedViewController.isEqual(plusChild),
           let plusButton = cylPrivate.cylContextPlusButton() {
            plusButton.isSelected = true
            cylTabChanged(toSelectedIndex: (cyl_tabBar as? UITabBar)?.cyl_plusButtonIndex() ?? 0, viewController: selectedViewController,
                          control: plusButton)
        } else {
            cylTabChanged(toSelectedIndex: UInt(selectedIndex), viewController: selectedViewController, control: selectedViewController.cyl_tabButton)
        }
        cylSetNeedsLiquidGlassTabBarResample()
    }

    /**
     * FIX: issue #646 — mitigation, not verified on device.
     * [EN] Liquid Glass switches between light and dark from the content behind it, and sometimes kept the previous tab's
     *      background. On the next run loop (once the new tab's view is in place), re-register the new tab's bottom content scroll
     *      view (only when it has one) and lay the system tab bar out again, so UIKit looks at what is behind the glass again.
     * [CN] 液态玻璃根据其背后的内容在浅色 / 深色之间切换，有时保持上一个 Tab 的底色。在下一个 runloop（新 Tab 的 view 已就位）为新 Tab 重新注册底部
     *      content scroll view（仅当存在时），并重新布局系统 TabBar，促使 UIKit 重新评估玻璃背后的内容。
     */
    @objc(cyl_setNeedsLiquidGlassTabBarResample)
    func cylSetNeedsLiquidGlassTabBarResample() {
        guard CYLConstants.isLiquidGlassActive() else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self else {
                return
            }
            var page = self.selectedViewController
            if let navigationController = page as? UINavigationController {
                page = navigationController.topViewController ?? navigationController
            }
            if #available(iOS 15.0, *), let page, let scrollView = page.contentScrollView(for: .bottom) {
                page.setContentScrollView(scrollView, for: .bottom)
            }
            self.tabBar.setNeedsLayout()
            self.tabBar.layoutIfNeeded()
        }
    }

    /**
     * FIX: issue #594
     * [EN] The plus button, when `viewController` is the plus child view controller of a registered plus button (unless
     *      `+shouldSelectPlusChildViewController` opts out): selecting it in code then marks the plus button selected, as a tap
     *      does, instead of the system tab button under it.
     * [CN] `viewController` 是已注册 PlusButton 的子控制器时返回 PlusButton（`+shouldSelectPlusChildViewController` 返回 NO 时除外）：用代码选中它时与点击一样
     *      选中 PlusButton，而不是其下方的系统 Tab 按钮。
     */
    @objc(cyl_plusButtonControlIfSelectingPlusChildViewController:)
    func cylPlusButtonControlIfSelectingPlusChildViewController(_ viewController: UIViewController?) -> UIControl? {
        guard let viewController, let plusButton = cylPrivate.cylContextPlusButton(), hasPlusButton(), hasPlusChildViewController(),
              let plusChild = cylPrivate.cylContextPlusChildViewController(), viewController.cyl_isEqual(to: plusChild) else {
            return nil
        }
        let selector = NSSelectorFromString("shouldSelectPlusChildViewController")
        if let plusButtonClass = object_getClass(plusButton) as AnyObject?, plusButtonClass.responds(to: selector) {
            typealias CYLBoolGetter = @convention(c) (AnyObject, Selector) -> Bool
            let shouldSelect = unsafeBitCast(plusButtonClass.method(for: selector), to: CYLBoolGetter.self)(plusButtonClass, selector)
            if !shouldSelect {
                return nil
            }
        }
        return plusButton
    }

    /**
     * FIX: issue #441
     * [EN] A tab selected in code. The index of the placeholder that stands for a plus button without a child view controller
     *      selects nothing (use `cyl_selectedIndexIgnoringPlusButton` for an index without the plus button, issue #515).
     * [CN] 代码选中的 Tab。没有子控制器的 PlusButton 对应的占位控制器的下标不会选中任何内容（不计 PlusButton 的下标请使用
     *      `cyl_selectedIndexIgnoringPlusButton`，issue #515）。
     */
    @objc(cyl_setSelectedIndex:)
    func cylSetSelectedIndex(_ selectedIndex: UInt) {
        cylSetNeedsUpdateTabBarItemIconViews()
        cylSetNeedsUpdateSelectedBackgroundColors()
        let viewControllers = self.viewControllers ?? []
        if selectedIndex < UInt(viewControllers.count), viewControllers[Int(selectedIndex)].cyl_isPlaceholder {
            #if DEBUG
            NSLog("[CYLTabBarController] setSelectedIndex:%lu is the plus button's placeholder and is ignored; use cyl_selectedIndexIgnoringPlusButton for the index without the plus button (issue #441).",
                  selectedIndex)
            #endif
            return
        }
        guard tabBarStyleType != .flatDesign else {
            cylFlatDesignSelection.cylFlatDesignSetSelectedIndex?(selectedIndex)
            return
        }
        super.selectedIndex = Int(selectedIndex)
        var selected: UIViewController?
        if selectedIndex < UInt(viewControllers.count) {
            selected = viewControllers[Int(selectedIndex)]
            selectedViewController = selected
        }
        // [EN] Liquid Glass no longer uses tap actions: a tab selected in code is reported here.
        // [CN] 液态玻璃不再使用点击事件：代码切换的 Tab 在这里上报。
        if selectedViewController?.cyl_isPlaceholder == true {
            return
        }
        cylTabChanged(toSelectedIndex: selectedIndex, viewController: selected,
                      control: cylPlusButtonControlIfSelectingPlusChildViewController(selected))
    }

    /// [EN] The size of the tab bar on screen. [CN] 屏幕上 TabBar 的尺寸。
    @objc(visiableTabBarSize)
    func cylVisiableTabBarSize() -> CGSize {
        cyl_tabBarController?.tabBar.cyl_boundsSize() ?? .zero
    }
}
