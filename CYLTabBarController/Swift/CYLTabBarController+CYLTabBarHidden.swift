//
//  CYLTabBarController+CYLTabBarHidden.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

#if canImport(CYLUtilsKit)
import CYLUtilsKit
#endif
#if canImport(CYLBadge)
import CYLBadge
#endif
/**
 * [EN] The FlatDesign side of hiding the tab bar and of the delegate, implemented in the FlatDesign subspec
 *      (CYLTabBarController+CYLFlatDesign.swift). Optional: without that subspec nothing answers.
 * [CN] 隐藏 TabBar 与 delegate 的扁平样式部分，由扁平样式子库实现。可选：没有该子库时无人响应。
 */
@objc protocol CYLFlatDesignTabBarHiding {
    /// [EN] The recorded request (the class-extension property, FlatDesign only). [CN] 记录的请求（类扩展属性，仅扁平样式）。
    @objc(cyl_tabBarHidden) optional func cylFlatDesignTabBarHiddenRequest() -> Bool
    @objc(cyl_flatDesignSetTabBarHidden:animated:) optional func cylFlatDesignSetTabBarHidden(_ hidden: Bool, animated: Bool)
    @objc(cyl_flatDesignDelegateDidChange:) optional func cylFlatDesignDelegateDidChange(_ delegate: AnyObject?)
}

/**
 * [EN] Hiding the tab bar in every style and the delegate, translated from Objective-C (docs/Swift-Migration.md, step 75). The
 *      UIKit overrides (`-isTabBarHidden`, `-setTabBarHidden:animated:`, `-setDelegate:`) stay in CYLTabBarController.m as one-line
 *      forwarders until the class is Swift.
 * [CN] 所有样式下隐藏 TabBar 以及 delegate，已从 Objective-C 翻译（docs/Swift-Migration.md，第 75 步）。UIKit 重写在类迁移到 Swift 之前保留在
 *      CYLTabBarController.m 中，只有一行转发。
 */
extension CYLTabBarController {

    /**
     * [EN] Classic tab bar before iOS 18 (not FlatDesign, not Liquid Glass): duration of the animated `-setTabBarHidden:animated:`,
     *      the same as FlatDesign, so both styles hide and show alike.
     * [CN] iOS 18 以前的经典 TabBar（非扁平样式、非液态玻璃）：带动画的 `-setTabBarHidden:animated:` 的时长，与扁平样式相同。
     */
    static let cylTabBarHideShowDuration: TimeInterval = 0.2

    private var cylFlatDesignHiding: CYLFlatDesignTabBarHiding {
        unsafeBitCast(self, to: CYLFlatDesignTabBarHiding.self)
    }

    /**
     * [EN] Liquid Glass and the classic style: the system tab bar's state (before iOS 18, the request while the classic animation
     *      runs). FlatDesign: the recorded request.
     * [CN] 液态玻璃与经典样式：系统 TabBar 的状态（iOS 18 以前，经典动画进行中时返回请求）。扁平样式：记录的请求。
     */
    @objc(cyl_isTabBarHidden)
    func cylIsTabBarHidden() -> Bool {
        guard tabBarStyleType != .flatDesign else {
            return cylFlatDesignHiding.cylFlatDesignTabBarHiddenRequest?() ?? false
        }
        if #available(iOS 18.0, *) {
            return super.isTabBarHidden
        }
        // [EN] While the hide / show animation runs, the request, not the bar's `hidden` (which changes when it ends).
        // [CN] 动画进行中返回请求的状态，而不是 TabBar 的 `hidden`（动画结束时才改变）。
        if cylPrivate.cylClassicTabBarIsAnimating() {
            return cylPrivate.cylClassicTabBarHiddenRequest()
        }
        return tabBar.isHidden
    }

    /**
     * [EN] Shows or hides the tab bar in every style. Scroll hiding (issue #13): a request by the app takes the tab bar over.
     *      Liquid Glass and the classic style: UIKit's animation on iOS 18 and later, the library's before.
     * [CN] 在所有样式下显示或隐藏 TabBar。滚动隐藏（issue #13）：App 自己的请求接管 TabBar。液态玻璃与经典样式：iOS 18 及以上由 UIKit 执行动画，之前由本库执行。
     */
    @objc(cyl_setTabBarHidden:animated:)
    func cylSetTabBarHidden(_ hidden: Bool, animated: Bool) {
        cylTabBarMinimizeDidReceiveTabBarHiddenRequest(hidden)
        if tabBarStyleType == .flatDesign {
            cylFlatDesignHiding.cylFlatDesignSetTabBarHidden?(hidden, animated: animated)
            return
        }
        if #available(iOS 18.0, *) {
            super.setTabBarHidden(hidden, animated: animated)
        } else {
            cylSetClassicTabBarHidden(hidden, animated: animated)
        }
    }

    /**
     * [EN] How far the classic tab bar moves down to leave the screen: its height plus the part of the plus button (or any
     *      subview) that sticks up above it.
     * [CN] 经典 TabBar 移出屏幕需要下移的距离：TabBar 的高度，再加上 PlusButton（或任何子视图）高出 TabBar 的部分。
     */
    private static func cylClassicTabBarHideDistance(_ tabBar: UITabBar) -> CGFloat {
        let overflowAbove = tabBar.subviews.filter { !$0.isHidden }.map { -$0.frame.minY }.max() ?? 0
        return tabBar.bounds.height + max(overflowAbove, 0)
    }

    /**
     * [EN] Classic tab bar before iOS 18: hides or shows the system tab bar, with its plus button, animated as FlatDesign does
     *      (the bar moves down out of the screen and back, `hidden` set when the animation ends). The newest request wins. Never
     *      FlatDesign, never Liquid Glass.
     * [CN] iOS 18 以前的经典 TabBar：隐藏或显示系统 TabBar 及其中的 PlusButton，动画与扁平样式一致（向下移出屏幕再移回，动画结束时设置 `hidden`）。
     *      以最新请求为准。不处理扁平样式与液态玻璃。
     */
    @objc(cyl_setClassicTabBarHidden:animated:)
    func cylSetClassicTabBarHidden(_ hidden: Bool, animated: Bool) {
        let tabBar: UITabBar = self.tabBar
        guard tabBarStyleType != .flatDesign, !CYLConstants.isLiquidGlassActive() else {
            return
        }
        let state = cylPrivate
        // [EN] The same request is already animating. [CN] 同一请求的动画正在进行。
        if state.cylClassicTabBarIsAnimating() && state.cylClassicTabBarHiddenRequest() == hidden {
            return
        }
        let generation = state.cylClassicTabBarAnimationGeneration() + 1
        state.cylSetClassicTabBarAnimationGeneration(generation)
        if !animated || tabBar.window == nil || tabBar.bounds.isEmpty {
            state.cylSetClassicTabBarIsAnimating(false)
            tabBar.transform = .identity
            tabBar.isHidden = hidden
            return
        }
        // [EN] Already there, nothing animating. [CN] 已是目标状态且没有动画。
        if !state.cylClassicTabBarIsAnimating() && tabBar.isHidden == hidden {
            return
        }
        state.cylSetClassicTabBarIsAnimating(true)
        state.cylSetClassicTabBarHiddenRequest(hidden)
        let distance = Self.cylClassicTabBarHideDistance(tabBar)
        if !hidden && tabBar.isHidden {
            // [EN] Showing: start below the screen. [CN] 显示：从屏幕下方开始。
            tabBar.transform = CGAffineTransform(translationX: 0, y: distance)
            tabBar.isHidden = false
        }
        let endTransform = hidden ? CGAffineTransform(translationX: 0, y: distance) : .identity
        UIView.animate(withDuration: Self.cylTabBarHideShowDuration, delay: 0, options: .beginFromCurrentState, animations: {
            tabBar.transform = endTransform
        }, completion: { _ in
            // [EN] A newer request owns the tab bar now. [CN] 已有更新的请求接管 TabBar。
            guard generation == self.cylPrivate.cylClassicTabBarAnimationGeneration() else {
                return
            }
            self.cylPrivate.cylSetClassicTabBarIsAnimating(false)
            // [EN] Reset the transform, so later layouts by UIKit never meet a moved tab bar. [CN] 还原 transform，使 UIKit 之后的布局不会遇到移动过的 TabBar。
            tabBar.transform = .identity
            tabBar.isHidden = hidden
        })
    }

    /**
     * [EN] Sets UIKit's delegate; FlatDesign remembers which show / hide callbacks it answers.
     * [CN] 设置 UIKit 的 delegate；扁平样式记录它响应哪些显示 / 隐藏回调。
     */
    @objc(cyl_setDelegate:)
    func cylSetDelegate(_ delegate: AnyObject?) {
        super.delegate = delegate.map { unsafeBitCast($0, to: UITabBarControllerDelegate.self) }
        if tabBarStyleType == .flatDesign {
            cylFlatDesignHiding.cylFlatDesignDelegateDidChange?(delegate)
        }
    }
}
