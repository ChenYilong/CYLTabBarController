//
//  CYLTabBarController+CYLLayout.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 FIX: issue #91
 [EN] iOS 26 and later put the tab bar in a container view only as tall as the bar, and UIKit does not ask
      `-[CYLTabBar hitTest:withEvent:]` about points above it: the raised part of the plus button, and a hit area enlarged with
      `touchableAreaOutsets` / `touchableAreaScale`, gave their touches to the page behind. This clear view, in front of the
      controller's view, asks the tab bar about points above the bar and keeps only the plus button (and its subviews); every
      other point returns nil, so the pages get their touches as before. Translated from Objective-C (step 132).
 [CN] FIX：issue #91——iOS 26 及以上把 TabBar 放在只有 TabBar 高度的容器视图中，UIKit 不会就 TabBar 上方的点询问 `-[CYLTabBar hitTest:withEvent:]`：
      PlusButton 凸出的部分、以及扩大的点击区域，触摸会交给后面的页面。这个透明视图位于控制器视图的最前面，就 TabBar 上方的点询问 TabBar，只保留
      PlusButton（及其子视图）；其他点返回 nil，页面照常接收触摸。已从 Objective-C 翻译（第 132 步）。
 */
@objc(CYLTabBarOverflowTouchView)
final class CYLTabBarOverflowTouchView: UIView {

    weak var tabBar: UITabBar?

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let tabBar = tabBar as? CYLTabBar, tabBar.window != nil, !tabBar.isHidden, tabBar.alpha >= 0.01,
              tabBar.isUserInteractionEnabled else { return nil }
        let tabBarPoint = convert(point, to: tabBar)
        // [EN] On the bar itself UIKit already routes the touch. [CN] TabBar 本身范围内的触摸 UIKit 已经能正确分发。
        guard !tabBar.point(inside: tabBarPoint, with: event), let plusButton = tabBar.plusButton else { return nil }
        let hit = tabBar.hitTest(tabBarPoint, with: event)
        return hit?.isDescendant(of: plusButton) == true ? hit : nil
    }
}

/// [EN] The overflow touch view of a controller. [CN] 控制器的溢出触摸视图。
private var cylOverflowTouchViewKey: UInt8 = 0

/// [EN] The layout steps implemented elsewhere (Swift or CYLTabBarController.m), called by selector. [CN] 在别处实现、按 selector 调用的布局步骤。
@objc protocol CYLLayoutHooks {
    @objc(cyl_installInteractionGestureRecognizersIfNeeded) func cylInstallInteractionGestureRecognizersIfNeeded()
    @objc(cyl_updateTabBarMinimizeTracking) func cylUpdateTabBarMinimizeTracking()
    @objc(cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded) func cylFixOpaqueTabBarSafeAreaInsetsIfNeeded()
    @objc(cyl_bindTabControlActions) func cylBindTabControlActions()
    @objc(initLottieTabBar:) func cylInitLottieTabBar(_ tabBar: CYLTabBar)
    @objc(cyl_layOutPlusButtonInLiquidGlassLayers) func cylLayOutPlusButtonInLiquidGlassLayers()
    @objc(cyl_runPendingReloadBadgesBlocksIfReady) func cylRunPendingReloadBadgesBlocksIfReady()
    @objc(shouldInvokeOnceViewDidLayoutSubViewsBlock) func cylShouldInvokeOnceViewDidLayoutSubViewsBlock() -> Bool
    @objc(isTabBarItemAnimationViewAdded) func cylIsTabBarItemAnimationViewAdded() -> Bool
    @objc(tabBarFrame) func cylTabBarFrame() -> CGRect
    /// [EN] Optional here: the property is imported as non-optional but is nil until the app sets it. [CN] 此处为可选：属性导入为非可选，但 App 设置前为 nil。
    @objc(viewDidLayoutSubviewsBlock) func cylViewDidLayoutSubviewsBlock() -> (@convention(block) (CYLTabBarController) -> Void)?
}

/**
 [EN] The FlatDesign part of `-viewDidLayoutSubviews`, implemented by CYLTabBarController+CYLFlatDesignLayout.swift in the FlatDesign
      subspec. Returns false when the FlatDesign tab bar is not in place (the layout stops there).
 [CN] `-viewDidLayoutSubviews` 的扁平样式部分，由扁平样式子库中的 CYLTabBarController+CYLFlatDesignLayout.swift 实现。扁平样式 TabBar 不存在时
      返回 false（布局到此为止）。
 */
@objc protocol CYLFlatDesignLayout {
    @objc(cyl_flatDesignViewDidLayoutSubviews) optional func cylFlatDesignViewDidLayoutSubviews() -> Bool
}

/**
 [EN] Block 9 of the third batch handed over by Mac-CYLTabBarController文件夹 (docs/Swift-Migration.md, step 132): the bodies of
      `-viewDidLayoutSubviews`, `-viewWillLayoutSubviews`, `-supportedInterfaceOrientations` and the observer teardown of
      `-dealloc`, the overflow touch view (issue #91) and the orientation's presented view controller. The UIKit overrides and
      `-dealloc` stay one-line forwarders in CYLTabBarController.m; `-shouldAutorotate` stays there whole (it reads the deprecated
      `shouldAutorotate`, a warning Swift cannot silence).
 [CN] 另一会话移交的第三批第 9 块（第 132 步）：`-viewDidLayoutSubviews`、`-viewWillLayoutSubviews`、`-supportedInterfaceOrientations` 与 `-dealloc`
      中移除观察的实现、溢出触摸视图（issue #91）以及决定方向的 present 控制器。UIKit 重写与 `-dealloc` 在 CYLTabBarController.m 中保留为一行的转发；
      `-shouldAutorotate` 完整保留在那里（它读取已废弃的 `shouldAutorotate`，Swift 无法消除该警告）。
 */
extension CYLTabBarController {

    var cylLayoutHooks: CYLLayoutHooks {
        unsafeBitCast(self as AnyObject, to: CYLLayoutHooks.self)
    }

    private var cylFlatDesignLayout: CYLFlatDesignLayout {
        unsafeBitCast(self as AnyObject, to: CYLFlatDesignLayout.self)
    }

    /// [EN] The body of `-viewDidLayoutSubviews`, after `super`. [CN] `-viewDidLayoutSubviews` 的实现，在 `super` 之后。
    @objc(cyl_viewDidLayoutSubviews)
    func cylViewDidLayoutSubviews() {
        let hooks = cylLayoutHooks
        // [EN] Lottie views are added during layout: start the looping ones. [CN] Lottie 视图在布局时添加：启动循环播放的视图。
        cylUpdateLoopingLottieViews()
        // [EN] Animation views added during layout get the tab's template tint. [CN] 布局时添加的动画视图获得 Tab 的模板着色。
        cylSetNeedsApplyTabBarItemAnimationTintColors()
        // FIX: issue #535 — long press and swipe to switch tabs, once the view exists (every style).
        hooks.cylInstallInteractionGestureRecognizersIfNeeded()
        // [EN] FlatDesign `cyl_tabBarMinimizeBehavior` (issue #13): follow the scroll view of the page on screen.
        hooks.cylUpdateTabBarMinimizeTracking()
        // [EN] Issue #601: tab buttons created again (e.g. after a rotation) get their icon views again.
        cylPrivate.cylSetNeedsUpdateTabBarItemIconViews()
        hooks.cylFixOpaqueTabBarSafeAreaInsetsIfNeeded()
        // FIX: issue #91 — points above the bar reach the plus button on iOS 26+ too.
        cylUpdateOverflowTouchView()
        if tabBarStyleType != .flatDesign {
            cylLayOutClassicTabBar()
        } else if cylFlatDesignLayout.cylFlatDesignViewDidLayoutSubviews?() == false {
            return
        }
        hooks.cylRunPendingReloadBadgesBlocksIfReady()
        let block = hooks.cylViewDidLayoutSubviewsBlock()
        guard hooks.cylShouldInvokeOnceViewDidLayoutSubViewsBlock() else {
            block?(self)
            return
        }
        // [EN] Once in the controller's life (`-cyl_rearmViewDidLayoutSubviewsBlockInvokeOnce` clears the mark).
        // [CN] 在控制器生命周期内只执行一次（`-cyl_rearmViewDidLayoutSubviewsBlockInvokeOnce` 会清除标记）。
        let key = CYLUtilsKeys.key("viewDidLayoutSubviews")
        guard objc_getAssociatedObject(self, key) == nil else { return }
        block?(self)
        objc_setAssociatedObject(self, key, "shouldInvokeOnceViewDidLayoutSubViewsBlock", .OBJC_ASSOCIATION_RETAIN)
    }

    /**
     [EN] The classic style and Liquid Glass. FIX: issue #585, #543 (follow-up to #93, #392) — the forced `-layoutSubviews` was an
          iOS 10 workaround; on the classic system tab bar of iOS 11+ it re-laid the bar out in the middle of push / pop (#585) and
          rotation (#543), so only Liquid Glass keeps it (the deployment target is above iOS 10). Then the tab actions, the
          accessibility of the slot (issue: VoiceOver read an empty tab), the animated icons and the plus button in the Liquid
          Glass layers.
     [CN] 经典样式与液态玻璃。FIX：issue #585、#543（#93、#392 的后续）——强制 `-layoutSubviews` 是 iOS 10 的变通；iOS 11+ 的经典系统 TabBar 上它会在
          push / pop（#585）与旋转（#543）过程中重新布局，因此只有液态玻璃保留（部署版本高于 iOS 10）。之后是 Tab 事件、slot 的无障碍（VoiceOver 曾读成
          空 Tab）、动画图标，以及液态玻璃图层中的 PlusButton。
     */
    private func cylLayOutClassicTabBar() {
        let hooks = cylLayoutHooks
        if CYLConstants.isLiquidGlassActive() {
            cyl_tabBar?.layoutSubviews()
        }
        if let tabBar = cyl_tabBar as? CYLTabBar {
            hooks.cylBindTabControlActions()
            // [EN] The tab under the plus button has no title, and the plus button's own page may have none: they read as the
            //      plus button. [CN] PlusButton 下方的 Tab 没有标题，PlusButton 自己的页面也可能没有：读作 PlusButton。
            let plusChild = CYLPlusButton.plusChildViewController(forOwner: self)
            for viewController in viewControllers ?? [] {
                if viewController.cyl_isPlaceholder {
                    // [EN] Classic: the button is the element. Liquid Glass: the element comes from the item. [CN] 经典：按钮即元素；液态玻璃：元素来自 item。
                    viewController.cyl_tabButton?.accessibilityElementsHidden = true
                    viewController.cyl_tabButton?.isAccessibilityElement = false
                } else if viewController !== plusChild || !(viewController.tabBarItem.title ?? "").isEmpty {
                    continue
                }
                viewController.tabBarItem.accessibilityLabel = cylPrivate.cylContextPlusButton()?.accessibilityLabel
            }
            // FIX: issue #477 — only some tabs may have an animation: each tab takes its own file, the others keep their images.
            if !hooks.cylIsTabBarItemAnimationViewAdded() {
                if cylIsLottieEnabled() {
                    hooks.cylInitLottieTabBar(tabBar)
                } else {
                    cylPrivate.cylSetTabBarItemAnimationViewAdded(true)
                }
            }
        }
        // [EN] The plus button in the Liquid Glass layers; also run from `-[CYLTabBar layoutSubviews]`. [CN] 也由 `-[CYLTabBar layoutSubviews]` 调用。
        hooks.cylLayOutPlusButtonInLiquidGlassLayers()
    }

    /// FIX: issue #91 — the overflow touch view while the tab bar lives in a wrapper view of its own (iOS 26 and later).
    /// [CN] TabBar 位于自己的容器视图中时（iOS 26 及以上）安装溢出触摸视图，否则移除。
    private func cylUpdateOverflowTouchView() {
        let tabBar = self.tabBar
        let touchView = objc_getAssociatedObject(self, &cylOverflowTouchViewKey) as? CYLTabBarOverflowTouchView
        guard isViewLoaded, let superview = tabBar.superview, superview !== view else {
            touchView?.removeFromSuperview()
            objc_setAssociatedObject(self, &cylOverflowTouchViewKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        let overflowView = touchView ?? {
            let created = CYLTabBarOverflowTouchView(frame: view.bounds)
            created.backgroundColor = .clear
            created.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            // [EN] Not a control: VoiceOver reads the plus button. [CN] 不是控件：VoiceOver 读 PlusButton。
            created.accessibilityElementsHidden = true
            objc_setAssociatedObject(self, &cylOverflowTouchViewKey, created, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return created
        }()
        overflowView.tabBar = tabBar
        if overflowView.superview !== view {
            view.addSubview(overflowView)
        } else if view.subviews.last !== overflowView {
            view.bringSubviewToFront(overflowView)
        }
        overflowView.frame = view.bounds
    }

    /**
     [EN] The body of `-viewWillLayoutSubviews`: the appearances are observed and synced; the classic tab bar takes the custom
          height. FIX: issue #591 — `bounds`, not `frame` (a transition that scales the view shrank `frame` and moved the bar up).
          Liquid Glass has a fixed height; FlatDesign lays its own bar out.
     [CN] `-viewWillLayoutSubviews` 的实现：观察并同步外观；经典 TabBar 使用自定义高度。FIX：issue #591——使用 `bounds` 而不是 `frame`（缩放视图的转场
          会使 `frame` 变小并上移 TabBar）。液态玻璃高度固定；扁平样式自行布局其 TabBar。
     */
    @objc(cyl_viewWillLayoutSubviews)
    func cylViewWillLayoutSubviews() {
        cylStartObservingStandardAppearance()
        cylSyncTabBarAppearances()
        guard tabBarStyleType != .flatDesign, !CYLConstants.isLiquidGlassActive(), tabBarHeight != 0, let bar = cyl_tabBar else { return }
        let height = cylLayoutHooks.cylTabBarFrame().height
        var frame = bar.frame
        frame.size.height = height
        frame.origin.y = view.bounds.height - height
        bar.frame = frame
    }

    /**
     [EN] The view controller that decides the orientation now: one presented by this controller (not while it is being dismissed,
          and never a `UIAlertController`, which asks its presenting view controller back and would loop), else nil (the
          selected tab decides). The system's full screen video player is presented too, so a video can turn to landscape.
     [CN] 当前决定方向的控制器：本控制器 present 出的控制器（正在 dismiss 时除外，且绝不是会反过来询问 presenting 控制器而造成循环的
          `UIAlertController`），否则为 nil（由选中的 Tab 决定）。系统的全屏视频播放器同样是 present 出来的，因此视频也能横屏。
     */
    @objc(cyl_presentedViewControllerForOrientation)
    func cylPresentedViewControllerForOrientation() -> UIViewController? {
        guard let presented = presentedViewController, !presented.isBeingDismissed, presented.presentingViewController === self,
              !(presented is UIAlertController) else { return nil }
        return presented
    }

    /// [EN] The presented view controller, else the selected tab (the top of its navigation stack; FlatDesign: the tab itself).
    /// [CN] present 出的控制器，否则为选中的 Tab（其导航栈的栈顶；扁平样式：Tab 本身）。
    @objc(cyl_supportedInterfaceOrientations)
    func cylSupportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if let presented = cylPresentedViewControllerForOrientation() {
            return presented.supportedInterfaceOrientations
        }
        if tabBarStyleType != .flatDesign, let navigationController = selectedViewController as? UINavigationController {
            return navigationController.topViewController?.supportedInterfaceOrientations ?? []
        }
        return selectedViewController?.supportedInterfaceOrientations ?? []
    }

    /// [EN] The observers removed in `-dealloc`, whatever the style is now (it can change after an observation started).
    /// [CN] `-dealloc` 中移除的观察，与当前样式无关（开始观察后样式可能已改变）。
    @objc(cyl_stopObservingForDealloc)
    func cylStopObservingForDealloc() {
        cylStopObservingStandardAppearance()
        if tabBarStyleType != .flatDesign {
            cylStopObservingTabImageViewDefaultOffset()
        } else if cylIsFlatDesignTabBar(cylPrivate.cylStoredTabBar()) {
            cyl_removeObserver(self, forKeyPath: "cyl_tabBar", context: CYLTabBarController.cylFlatDesignTabBarKVOContext())
        }
    }
}
