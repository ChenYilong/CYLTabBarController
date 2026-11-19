//
//  CYLTabBarController+CYLTabBarItemAnimationViews.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 [EN] Block 8 of the third batch handed over by Mac-CYLTabBarController文件夹 (docs/Swift-Migration.md, step 131): the animated tab
      icons (Lottie, PAG and the other engines of the `CYLTabBarItemAnimation` subspec) added to the tab buttons, from the
      "delegate" section of CYLTabBarController.m: `-isLottieEnabled`, the four `-addLottieImageWithControl:…` methods and
      `-cyl_stopObservingTabImageViewDefaultOffset`. Internal members with the Objective-C selectors; the life cycle and the
      `.m` call them by selector (declared in CYLTabBarController+CYLPrivate.h). `-tabBarController:shouldSelectViewController:`
      stays the step-61 forwarder in the `.m`.
 [CN] 另一会话移交的第三批第 8 块（第 131 步）：添加到 Tab 按钮上的动画图标（Lottie、PAG 及 `CYLTabBarItemAnimation` 子库的其他引擎），来自
      CYLTabBarController.m 的 "delegate" 部分。以 Objective-C selector 实现的内部成员；生命周期与 `.m` 按 selector 调用（声明于
      CYLTabBarController+CYLPrivate.h）。`-tabBarController:shouldSelectViewController:` 仍为 `.m` 中第 61 步的转发。
 */
extension CYLTabBarController {

    /// [EN] Whether the tabs have animation files. FIX: placeholder count mismatch — without the slot's entry (it is the first one
    ///      when the plus button is the first tab). [CN] Tab 是否有动画文件。FIX：不含 slot 的属性项。
    @objc(isLottieEnabled)
    func cylIsLottieEnabled() -> Bool {
        let urls = cylPrivate.cylTabBarItemAnimationURLs().compactMap { $0 as? URL }
        return CYLConstants.isTabBarItemAnimationEnabled(with: urls,
                                                         tabBarItemsAttributes: cylTabBarItemsAttributesByRemovingPlusSlot(tabBarItemsAttributes) ?? [])
    }

    @objc(addLottieImageWithControl:animation:)
    func cylAddLottieImage(withControl control: UIControl, animation: Bool) {
        guard tabBarStyleType != .flatDesign else { return }
        cylAddLottieImage(withControl: control, lottieURL: nil, lottieSizeValue: nil, animation: animation)
    }

    @objc(addLottieImageWithControl:lottieURL:lottieSizeValue:animation:)
    func cylAddLottieImage(withControl control: UIControl, lottieURL: URL?, lottieSizeValue: NSValue?, animation: Bool) {
        guard tabBarStyleType != .flatDesign else { return }
        cylAddLottieImage(withControl: control, lottieURL: lottieURL, lottieSizeValue: lottieSizeValue, animation: animation, defaultSelected: false)
    }

    /**
     FIX: issue #477
     [EN] YES when every tab (the plus button's placeholder aside) has an animation file, the only case where a tab's file can be
          taken by its position in `tabBarItemAnimationURLs`. With only some animated tabs, each one takes its own file.
     [CN] 每个 Tab（PlusButton 的占位除外）都有动画文件时返回 YES，只有这时才能按位置在 `tabBarItemAnimationURLs` 中取文件。只有部分 Tab 有动画时，
          每个 Tab 使用自己的文件。
     */
    private func cylEveryTabHasAnimationFile() -> Bool {
        let tabCount = (viewControllers ?? []).filter { !$0.cyl_isPlaceholder }.count
        return tabCount > 0 && cylPrivate.cylTabBarItemAnimationURLs().count >= tabCount && cylPrivate.cylTabBarItemAnimationSizes().count >= tabCount
    }

    private func cylAddAnimation(to control: UIControl, url: URL, size: CGSize) {
        control.cyl_addTabBarItemAnimation(with: url, size: size, contentMode: tabBarItemAnimationViewContentMode(), animationSpeed: tabBarItemAnimationSpeed)
        control.cyl_setTabBarItemAnimationLoops(tabBarItemAnimationLoops)
    }

    /**
     [EN] The classic tab bar: the file of the button's own tab item first (issue #423), by position only when every tab has one
          (issue #477) and bounds-checked (issue #618); Liquid Glass goes through the five-argument method. FIX: issue #604 — only
          with an animation library in the build.
     [CN] 经典 TabBar：优先使用按钮自己 TabBarItem 的文件（issue #423），只有每个 Tab 都有文件时才按位置取（issue #477）并检查越界（issue #618）；
          液态玻璃使用五个参数的方法。FIX：issue #604——只在构建中包含动画库时。
     */
    @objc(addLottieImageWithControl:animation:defaultSelected:)
    func cylAddLottieImage(withControl control: UIControl, animation: Bool, defaultSelected: Bool) {
        guard cylTabBarItemAnimationGetServiceEntryPoint() != nil, tabBarStyleType != .flatDesign else { return }
        if CYLConstants.isLiquidGlassActive() {
            cylAddLottieImage(withControl: control, lottieURL: nil, lottieSizeValue: nil, animation: animation, defaultSelected: defaultSelected)
            return
        }
        let tabBar = cyl_tabBar as? CYLTabBar
        guard let index = tabBar?.cylSubTabBarButtonsWithoutPlusButton().firstIndex(where: { $0 === control }), !control.cyl_isPlusButton() else { return }
        let tabBarItem = cylTabBarItem(forTabButton: control)
        var url = tabBarItem?.cyl_tabBarItemAnimationURL
        var sizeValue = tabBarItem?.cyl_tabBarItemAnimationSizeValue
        if url == nil {
            let urls = cylPrivate.cylTabBarItemAnimationURLs()
            let sizes = cylPrivate.cylTabBarItemAnimationSizes()
            guard cylEveryTabHasAnimationFile(), index < urls.count, index < sizes.count else { return }
            url = urls[index] as? URL
            sizeValue = sizes[index] as? NSValue
        }
        guard let url else { return }
        let size = sizeValue?.cgSizeValue ?? .zero
        cylAddAnimation(to: control, url: url, size: size)
        // [EN] A view added after layout (React Native) gets its tint at once. [CN] 布局之后添加的视图（React Native）立即获得着色。
        cylSetNeedsApplyTabBarItemAnimationTintColors()
        if animation {
            tabBar?.cylPlayTabBarItemAnimation(withSelectedControl: control, url: url, size: size, defaultSelected: defaultSelected,
                                               contentMode: tabBarItemAnimationViewContentMode())
        }
    }

    /**
     [EN] Adds the tab's animation to its button and, on Liquid Glass, to the button of the selected layer. No file given: the file
          of the button's own tab item (issue #423), then by position when every tab has one (issue #477; the slot has none, the
          tabs after it are one entry earlier). A tab without an animation stops the animated ones (issue #477).
     [CN] 把 Tab 的动画添加到其按钮，液态玻璃下也添加到选中图层的按钮。未指定文件时：先用按钮自己 TabBarItem 的文件（issue #423），每个 Tab 都有文件时
          再按位置取（issue #477；slot 没有，之后的 Tab 前移一项）。没有动画的 Tab 会停止有动画的 Tab（issue #477）。
     */
    @objc(addLottieImageWithControl:lottieURL:lottieSizeValue:animation:defaultSelected:)
    func cylAddLottieImage(withControl control: UIControl, lottieURL: URL?, lottieSizeValue: NSValue?, animation: Bool, defaultSelected: Bool) {
        guard cylTabBarItemAnimationGetServiceEntryPoint() != nil, tabBarStyleType != .flatDesign, !control.cyl_isPlusControl() else { return }
        var url = lottieURL
        var sizeValue = lottieSizeValue
        if url == nil || sizeValue == nil {
            let tabBarItem = cylTabBarItem(forTabButton: control)
            url = url ?? tabBarItem?.cyl_tabBarItemAnimationURL
            sizeValue = sizeValue ?? tabBarItem?.cyl_tabBarItemAnimationSizeValue
        }
        let tabBar = cyl_tabBar as? CYLTabBar
        if url == nil || sizeValue == nil, let tabBar, cylEveryTabHasAnimationFile(),
           var index = tabBar.cylSubTabBarButtons().firstIndex(where: { $0 === control }) {
            let slotIndex = cylPlusSlotIndexInViewControllers()
            var isSlot = false
            if slotIndex != NSNotFound {
                if index == slotIndex { isSlot = true } else if index > slotIndex { index -= 1 }
            }
            if !isSlot {
                let urls = cylPrivate.cylTabBarItemAnimationURLs()
                let sizes = cylPrivate.cylTabBarItemAnimationSizes()
                url = url ?? (index < urls.count ? urls[index] as? URL : nil)
                sizeValue = sizeValue ?? (index < sizes.count ? sizes[index] as? NSValue : nil)
            }
        }
        guard let url else {
            if animation {
                tabBar?.cylStopAllTabBarItemAnimations()
            }
            return
        }
        let size = sizeValue?.cgSizeValue ?? .zero
        cylAddAnimation(to: control, url: url, size: size)
        cylSetNeedsApplyTabBarItemAnimationTintColors()
        guard let tabBar else { return }
        let selectedLayerControl = tabBar.cylSelectedContentControl(fromContentControl: control)
        if let selectedLayerControl {
            cylAddAnimation(to: selectedLayerControl, url: url, size: size)
        }
        guard animation else { return }
        let contentMode = tabBarItemAnimationViewContentMode()
        tabBar.cylPlayTabBarItemAnimation(withSelectedControl: control, url: url, size: size, defaultSelected: defaultSelected, contentMode: contentMode)
        if let selectedLayerControl {
            tabBar.cylPlayTabBarItemAnimation(withSelectedControl: selectedLayerControl, url: url, size: size, defaultSelected: defaultSelected,
                                              contentMode: contentMode)
        }
    }

    /// [EN] Stops observing `tabImageViewDefaultOffset` of the CYLTabBar it was added to (the stored one, never the lazy getter).
    /// [CN] 停止观察添加时所在 CYLTabBar 的 `tabImageViewDefaultOffset`（已保存的 TabBar，绝不使用延迟创建的 getter）。
    @objc(cyl_stopObservingTabImageViewDefaultOffset)
    func cylStopObservingTabImageViewDefaultOffset() {
        let accessors = cylTabBarAccessorsStorage
        guard accessors.cylIsObservingTabImageViewDefaultOffset() else { return }
        if let tabBar = cylPrivate.cylStoredTabBar() as? CYLTabBar {
            tabBar.cyl_removeObserver(self, forKeyPath: "tabImageViewDefaultOffset", context: CYLTabBarController.cylTabImageViewDefaultOffsetKVOContext())
        }
        accessors.cylSetObservingTabImageViewDefaultOffset(false)
    }
}
