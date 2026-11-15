//
//  CYLFlatDesignTabBarHideTabBar.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Two FlatDesign views with UIKit-only interfaces, translated from Objective-C (docs/Swift-Migration.md, step 47):
//      `CYLFlatDesignTabBarHideTabBar` (the system tab bar that always stays hidden) and `_CYLFlatDesignTabBarParallaxOverlayView`
//      (the view that carries the FlatDesign tab bar during push / pop). Objective-C callers get them from the generated
//      Swift interface, through their headers.
// [CN] 两个接口只使用 UIKit 的扁平样式视图，已从 Objective-C 翻译（docs/Swift-Migration.md，第 47 步）：`CYLFlatDesignTabBarHideTabBar`
//      （始终隐藏的系统 TabBar）与 `_CYLFlatDesignTabBarParallaxOverlayView`（push / pop 时承载扁平样式 TabBar 的视图）。Objective-C 调用方
//      通过各自头文件从 Swift 生成接口获得声明。

/**
 * [EN] The system tab bar of a FlatDesign tab bar controller: always hidden, with its Liquid Glass platter hidden and its
 *      continuous and long-press gestures off, so it never takes space or touches from the FlatDesign tab bar.
 * [CN] 扁平样式 TabBarController 的系统 TabBar：始终隐藏，隐藏其液态玻璃 platter 并关闭连续手势与长按手势，因此从不占用空间，也不抢扁平样式
 *      TabBar 的触摸。
 */
@objc(CYLFlatDesignTabBarHideTabBar)
open class CYLFlatDesignTabBarHideTabBar: UITabBar {

    private weak var platterView: UIView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        // FIX: issue #662
        // [EN] `isHidden`'s setter below forces the bar to stay hidden, but only when someone calls it. On iOS 18+ the bar is
        //      hidden with `-[UITabBarController setTabBarHidden:animated:]`, which does not call it, and on iOS 27+ UIKit then
        //      reserved its 49 pt in the children's safe area too. Hide it from the start.
        // [CN] 下面的 `isHidden` setter 强制 TabBar 保持隐藏，但只有被调用时才生效。iOS 18+ 使用 `-[UITabBarController setTabBarHidden:animated:]`
        //      隐藏系统 TabBar，不会调用它；iOS 27+ UIKit 于是还会在子控制器的安全区中预留其 49 pt。因此从一开始就隐藏。
        super.isHidden = true
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        super.isHidden = true
    }

    open override var isHidden: Bool {
        get { super.isHidden }
        set { super.isHidden = true }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        cylPlatterView()?.cyl_setHidden(true)
        platterView?.cyl_setHidden(true)
    }

    open override func addSubview(_ view: UIView) {
        if view is UITabBar {
            // [EN] A tab bar added to itself (`[self.tabBar addSubview:myTabBar]`) is ignored; set it with KVC instead.
            // [CN] 忽略把 TabBar 添加到自身（`[self.tabBar addSubview:myTabBar]`）的情况；请改用 KVC 设置。
            return
        }
        if view.cyl_isPlatterView() {
            view.isHidden = true
            cylSetPlatterView(view)
            platterView = view
            return
        }
        super.addSubview(view)
    }

    open override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.cyl_isContinuousGestureRecognizer() || gestureRecognizer.cyl_isLongGestureRecognizer() {
            gestureRecognizer.isEnabled = false
        }
        super.addGestureRecognizer(gestureRecognizer)
    }
}

/**
 * [EN] During UINavigationController push / pop transitions, the FlatDesign tab bar is added to this view for a moment, so
 *      the effect matches the system transition.
 * [CN] UINavigationController push / pop 转场时，临时将扁平样式 TabBar 添加到本视图上，使效果与系统转场一致。
 */
@objc(_CYLFlatDesignTabBarParallaxOverlayView)
open class _CYLFlatDesignTabBarParallaxOverlayView: UIView { // swiftlint:disable:this type_name

    /** [EN] The scroll view this overlay follows while attached. [CN] 附着期间本视图跟随的滚动视图。 */
    private var observations: [NSKeyValueObservation] = []
    private weak var observedScrollView: UIScrollView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    // MARK: Pin to the visible area of a scrolling page (#662)

    // FIX: issue #662
    // [EN] The overlay is added to the page's view during push / pop. When that view is a UIScrollView, its subviews move with
    //      the content, and the page can still settle its adjustedContentInset after the overlay was placed (e.g. iPhone Duo,
    //      iOS 27.1 SDK: 24 → 82 pt), which carried the tab bar off the bottom edge. Keep the overlay on the visible bounds.
    // [CN] push / pop 时本视图被添加到页面视图上。页面视图是 UIScrollView 时，子视图会随内容移动，而页面在本视图放好后仍可能调整
    //      adjustedContentInset（例如 iPhone Duo、iOS 27.1 SDK：24 → 82 pt），把 TabBar 带出底部边缘。因此让本视图保持在可见区域上。

    open override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        stopObservingScrollView()
    }

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let scrollView = superview as? UIScrollView else { return }
        observedScrollView = scrollView
        observations = [
            scrollView.observe(\.contentOffset, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.pinToScrollViewBounds() }
            },
            scrollView.observe(\.bounds, options: [.new]) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.pinToScrollViewBounds() }
            },
        ]
        pinToScrollViewBounds()
    }

    private func stopObservingScrollView() {
        observations.forEach { $0.invalidate() }
        observations = []
        observedScrollView = nil
    }

    private func pinToScrollViewBounds() {
        guard let scrollView = observedScrollView, frame != scrollView.bounds else { return }
        UIView.performWithoutAnimation {
            frame = scrollView.bounds
        }
    }

    open override var safeAreaInsets: UIEdgeInsets {
        var next = self.next
        while let responder = next, !(responder is UIViewController) {
            next = responder.next
        }
        if let tabBarController = (next as? UIViewController)?.cylflatdesign_tabBarController {
            return tabBarController.view.safeAreaInsets
        }
        return super.safeAreaInsets
    }
}
