//
//  _CYLFlatDesignTabBarControllerTransition.swift
//  CYLFlatDesignTabBar
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] A minimal transition context for the FlatDesign tab bar controller: no interaction, frames are the container's
 *      bounds, `completionBlock` runs on completion. Internal helper of FlatDesign (not used by the library today, kept
 *      because its header shipped as public). Translated from Objective-C (docs/Swift-Migration.md).
 * [CN] FlatDesign TabBarController 的最简转场上下文：不支持交互，frame 都是容器的 bounds，完成时调用 `completionBlock`。FlatDesign 的
 *      内部辅助类（库目前未使用，因其头文件曾作为公开头文件发布而保留）。已从 Objective-C 翻译（docs/Swift-Migration.md）。
 */
@objc(_CYLFlatDesignUITabBarControllerTransitionContext)
public class _CYLFlatDesignUITabBarControllerTransitionContext: NSObject, UIViewControllerContextTransitioning {

    /**
     * [EN] Called by `completeTransition(_:)`.
     * [CN] 由 `completeTransition(_:)` 调用。
     */
    @objc public var completionBlock: ((Bool) -> Void)?

    /**
     * [EN] Whether the transition is animated.
     * [CN] 转场是否带动画。
     */
    public var isAnimated: Bool {
        @objc(isAnimated) get { storedAnimated }
        @objc(setAnimated:) set { storedAnimated = newValue }
    }

    private var storedAnimated = false

    /**
     * [EN] Whether the transition is interactive.
     * [CN] 转场是否可交互。
     */
    public var isInteractive: Bool {
        @objc(isInteractive) get { storedInteractive }
        @objc(setInteractive:) set { storedInteractive = newValue }
    }

    private var storedInteractive = false

    private weak var sourceViewController: UIViewController?
    private weak var destinationViewController: UIViewController?
    private weak var weakContainerView: UIView?

    /**
     * [EN] A context from one view controller to another inside `containerView`.
     * [CN] 在 `containerView` 中从一个控制器到另一个控制器的转场上下文。
     */
    @objc(initWithSourceViewController:destinationViewController:containerView:)
    public init(sourceViewController: UIViewController?, destinationViewController: UIViewController?,
                containerView: UIView) {
        self.sourceViewController = sourceViewController
        self.destinationViewController = destinationViewController
        weakContainerView = containerView
        super.init()
    }

    public var containerView: UIView {
        weakContainerView ?? UIView()
    }

    public var transitionWasCancelled: Bool {
        false
    }

    public var presentationStyle: UIModalPresentationStyle {
        .custom
    }

    public var targetTransform: CGAffineTransform {
        .identity
    }

    public func updateInteractiveTransition(_: CGFloat) {
        // [EN] Not interactive: nothing to update. [CN] 不支持交互：无需更新。
    }

    public func finishInteractiveTransition() {
        // [EN] Not interactive: nothing to finish. [CN] 不支持交互：无需完成。
    }

    public func cancelInteractiveTransition() {
        // [EN] Not interactive: nothing to cancel. [CN] 不支持交互：无需取消。
    }

    public func pauseInteractiveTransition() {
        // [EN] Not interactive: nothing to pause. [CN] 不支持交互：无需暂停。
    }

    public func completeTransition(_ didComplete: Bool) {
        completionBlock?(didComplete)
    }

    public func viewController(forKey key: UITransitionContextViewControllerKey) -> UIViewController? {
        switch key {
        case .from: return sourceViewController
        case .to: return destinationViewController
        default: return nil
        }
    }

    public func view(forKey key: UITransitionContextViewKey) -> UIView? {
        switch key {
        case .from: return sourceViewController?.view
        case .to: return destinationViewController?.view
        default: return nil
        }
    }

    public func initialFrame(for _: UIViewController) -> CGRect {
        containerView.bounds
    }

    public func finalFrame(for _: UIViewController) -> CGRect {
        containerView.bounds
    }
}

/**
 * [EN] Adds the destination view at once, without animation. Internal helper of FlatDesign (kept because its header
 *      shipped as public). Translated from Objective-C (docs/Swift-Migration.md).
 * [CN] 立即添加目标视图，不带动画。FlatDesign 的内部辅助类（因其头文件曾作为公开头文件发布而保留）。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md）。
 */
@objc(_CYLFlatDesignUITabBarControllerTransitionAnimator)
public class _CYLFlatDesignUITabBarControllerTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let destination = transitionContext.viewController(forKey: .to) {
            transitionContext.containerView.addSubview(destination.view)
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    }

    public func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        0
    }
}
