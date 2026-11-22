//
//  UINavigationController+CYLFlatDesignTabBarPrivate.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] The push / pop hooks that let the FlatDesign tab bar follow navigation transitions, translated from Objective-C
//      (docs/Swift-Migration.md, step 48). The selectors of UINavigationController+CYLFlatDesignTabBarPrivate.h are kept.
//      `+cyl_navigationBarActionHook` is called by CYLFlatDesignTabBar only, so Liquid Glass and the classic style are untouched.
// [CN] 让扁平样式 TabBar 跟随导航转场的 push / pop hook，已从 Objective-C 翻译（docs/Swift-Migration.md，第 48 步）。
//      UINavigationController+CYLFlatDesignTabBarPrivate.h 中的 selector 保持不变。`+cyl_navigationBarActionHook` 只由 CYLFlatDesignTabBar
//      调用，因此液态玻璃与经典样式不受影响。

/**
 * [EN] The callbacks of `UINavigationControllerExtensionDelegate` (UINavigationController+CYLFlatDesignTabBarPrivate.h), called by
 *      selector: the tab bar controller implements them without declaring the protocol.
 * [CN] `UINavigationControllerExtensionDelegate`（UINavigationController+CYLFlatDesignTabBarPrivate.h）的回调，按 selector 调用：
 *      TabBarController 实现了这些方法，但没有声明遵守该协议。
 */
@objc protocol CYLFlatDesignNavigationExtensionDelegate {
    @objc(cylflatdesign_navigationController:navigationBarDidChangeHeight:)
    optional func navigationController(_ navigationController: UINavigationController, navigationBarDidChangeHeight height: CGFloat)

    @objc(cylflatdesign_navigationController:didBeginTransitionFrom:to:operation:)
    optional func navigationController(_ navigationController: UINavigationController, didBeginTransitionFrom fromVC: UIViewController?,
                                       to toVC: UIViewController?, operation: UINavigationController.Operation)

    @objc(cylflatdesign_navigationController:didUpdateInteractiveFrom:to:percentComplete:)
    optional func navigationController(_ navigationController: UINavigationController, didUpdateInteractiveFrom fromVC: UIViewController?,
                                       to toVC: UIViewController?, percentComplete: CGFloat)

    @objc(cylflatdesign_navigationController:didUpdateInteractiveFrom:to:popGestureRecognizer:)
    optional func navigationController(_ navigationController: UINavigationController, didUpdateInteractiveFrom fromVC: UIViewController?,
                                       to toVC: UIViewController?, popGestureRecognizer: UIGestureRecognizer)

    @objc(cylflatdesign_navigationController:willEndTransitionFrom:to:operation:cancelled:)
    optional func navigationController(_ navigationController: UINavigationController, willEndTransitionFrom fromVC: UIViewController?,
                                       to toVC: UIViewController?, operation: UINavigationController.Operation, cancelled: Bool)

    @objc(cylflatdesign_navigationController:didEndTransitionFrom:to:operation:cancelled:)
    optional func navigationController(_ navigationController: UINavigationController, didEndTransitionFrom fromVC: UIViewController?,
                                       to toVC: UIViewController?, operation: UINavigationController.Operation, cancelled: Bool)
}

/**
 * [EN] What a navigation controller inside a FlatDesign tab bar controller remembers.
 * [CN] 扁平样式 TabBarController 中的导航控制器记录的信息。
 */
private final class CYLFlatDesignNavigationState: NSObject {
    weak var extensionDelegate: AnyObject?
    var nestedInFlatDesignTabBarController = false
    var popGestureRecognizerRegistered = false
    var customPopGestureRecognizer: UIGestureRecognizer?
}

extension UINavigationController {

    private var cylflatdesignState: CYLFlatDesignNavigationState {
        let key = CYLUtilsKeys.key("cylflatdesign_navigationState")
        if let state = objc_getAssociatedObject(self, key) as? CYLFlatDesignNavigationState {
            return state
        }
        let state = CYLFlatDesignNavigationState()
        objc_setAssociatedObject(self, key, state, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return state
    }

    /** [EN] The tab bar controller, typed for its callbacks. [CN] TabBarController，按回调类型使用。 */
    private var cylflatdesignExtensionDelegate: CYLFlatDesignNavigationExtensionDelegate? {
        cylflatdesignState.extensionDelegate.map { unsafeBitCast($0, to: CYLFlatDesignNavigationExtensionDelegate.self) }
    }

    /**
     [EN] The pop gesture recognizer used instead of the system one (public Swift since step 117; it was declared in
          UINavigationController+CYLFlatDesignTabBarPrivate.h).
     [CN] 代替系统返回手势的识别器（自第 117 步起为公开的 Swift 属性；原声明在 UINavigationController+CYLFlatDesignTabBarPrivate.h）。
     */
    @objc public var cylflatdesign_customPopGestureRecognizer: UIGestureRecognizer? {
        @objc(cylflatdesign_customPopGestureRecognizer) get { cylflatdesignState.customPopGestureRecognizer }
        @objc(cylflatdesign_setCustomPopGestureRecognizer:) set { cylflatdesignState.customPopGestureRecognizer = newValue }
    }

    // MARK: Hook

    /**
     * [EN] Swizzles the pop, push, `setViewControllers`, `didMoveToParentViewController:` and `viewDidLayoutSubviews` methods
     *      once. Called by CYLFlatDesignTabBar, so only the FlatDesign style installs it.
     * [CN] （只执行一次）交换 pop、push、`setViewControllers`、`didMoveToParentViewController:` 与 `viewDidLayoutSubviews` 方法。
     *      由 CYLFlatDesignTabBar 调用，因此只有扁平样式会安装。
     */
    @objc(cyl_navigationBarActionHook)
    public class func cyl_navigationBarActionHook() {
        _ = cylflatdesignHookInstalled
    }

    private static let cylflatdesignHookInstalled: Void = {
        let pairs: [(Selector, Selector)] = [
            (#selector(popViewController(animated:)), #selector(cylFlatDesignPopViewController(animated:))),
            (#selector(popToViewController(_:animated:)), #selector(cylFlatDesignPopToViewController(_:animated:))),
            (#selector(popToRootViewController(animated:)), #selector(cylFlatDesignPopToRootViewController(animated:))),
            (#selector(pushViewController(_:animated:)), #selector(cylFlatDesignPushViewController(_:animated:))),
            (#selector(setViewControllers(_:animated:)), #selector(cylFlatDesignSetViewControllers(_:animated:))),
            (#selector(didMove(toParent:)), #selector(cylFlatDesignDidMove(toParent:))),
            (#selector(viewDidLayoutSubviews), #selector(cylFlatDesignViewDidLayoutSubviews)),
        ]
        for (original, swizzled) in pairs {
            cylflatdesignSwizzle(UINavigationController.self, original, swizzled)
        }
    }()

    private static func cylflatdesignSwizzle(_ cls: AnyClass, _ original: Selector, _ swizzled: Selector) {
        guard let originalMethod = class_getInstanceMethod(cls, original),
              let swizzledMethod = class_getInstanceMethod(cls, swizzled) else { return }
        if class_addMethod(cls, original, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod)) {
            class_replaceMethod(cls, swizzled, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod))
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod)
        }
    }

    // MARK: Pop and push (after the swap, `cylflatdesign_…` runs the original)

    @objc(cylflatdesign_popViewControllerWithAnimated:) dynamic func cylFlatDesignPopViewController(animated: Bool) -> UIViewController? {
        let previous = cylFlatDesignPopViewController(animated: animated)
        if cylflatdesignState.nestedInFlatDesignTabBarController {
            cylflatdesignPop(from: previous, to: topViewController, animated: animated)
        }
        return previous
    }

    @objc(cylflatdesign_popToViewController:animated:) dynamic func cylFlatDesignPopToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let previous = topViewController
        let popped = cylFlatDesignPopToViewController(viewController, animated: animated)
        if cylflatdesignState.nestedInFlatDesignTabBarController {
            cylflatdesignPop(from: previous, to: viewController, animated: animated)
        }
        return popped
    }

    @objc(cylflatdesign_popToRootViewControllerWithAnimated:) dynamic func cylFlatDesignPopToRootViewController(animated: Bool) -> [UIViewController]? {
        let previous = topViewController
        let popped = cylFlatDesignPopToRootViewController(animated: animated)
        if cylflatdesignState.nestedInFlatDesignTabBarController, let popped, !popped.isEmpty {
            cylflatdesignPop(from: previous, to: topViewController, animated: animated)
        }
        return popped
    }

    @objc(cylflatdesign_pushViewController:animated:) dynamic func cylFlatDesignPushViewController(_ viewController: UIViewController, animated: Bool) {
        guard cylflatdesignState.nestedInFlatDesignTabBarController else {
            cylFlatDesignPushViewController(viewController, animated: animated)
            return
        }
        let previous = topViewController
        cylFlatDesignPushViewController(viewController, animated: animated)
        cylflatdesignPush(from: previous, to: viewController, animated: animated)
    }

    @objc(cylflatdesign_setViewControllers:animated:) dynamic func cylFlatDesignSetViewControllers(_ viewControllers: [UIViewController], animated: Bool) {
        guard cylflatdesignState.nestedInFlatDesignTabBarController else {
            cylFlatDesignSetViewControllers(viewControllers, animated: animated)
            return
        }
        let previous = topViewController
        let target = viewControllers.last
        // [EN] A new top view controller counts as a push, as before (not always exact). [CN] 新的顶层控制器视为 push，与以前相同（不一定准确）。
        let isPush = target.map { !self.viewControllers.contains($0) } ?? true
        cylFlatDesignSetViewControllers(viewControllers, animated: animated)
        if isPush {
            cylflatdesignPush(from: previous, to: target, animated: animated)
        } else {
            cylflatdesignPop(from: previous, to: target, animated: animated)
        }
    }

    @objc(cylflatdesign_didMoveToParent:) dynamic func cylFlatDesignDidMove(toParent parent: UIViewController?) {
        cylFlatDesignDidMove(toParent: parent)
        let state = cylflatdesignState
        if parent == nil, state.nestedInFlatDesignTabBarController {
            state.extensionDelegate = nil
            state.nestedInFlatDesignTabBarController = false
            cylflatdesignUnregisterPopGestureRecognizer()
        } else if let parent, parent.cyl_isFlatDesignStyleTabBar() {
            state.extensionDelegate = parent
            state.nestedInFlatDesignTabBarController = true
            cylflatdesignRegisterPopGestureRecognizer()
            cylflatdesignUpdateNavigationBarHeight()
        }
    }

    @objc(cylflatdesign_viewDidLayoutSubviews) dynamic func cylFlatDesignViewDidLayoutSubviews() {
        cylFlatDesignViewDidLayoutSubviews()
        if cylflatdesignState.nestedInFlatDesignTabBarController {
            cylflatdesignUpdateNavigationBarHeight()
        }
    }

    // MARK: Gestures

    private var cylflatdesignResponsePopGestureRecognizer: UIGestureRecognizer? {
        if let custom = cylflatdesignState.customPopGestureRecognizer {
            return custom
        }
        if #available(iOS 26.0, *) {
            return interactiveContentPopGestureRecognizer
        }
        return interactivePopGestureRecognizer
    }

    private func cylflatdesignRegisterPopGestureRecognizer() {
        guard !cylflatdesignState.popGestureRecognizerRegistered, let recognizer = cylflatdesignResponsePopGestureRecognizer else { return }
        recognizer.addTarget(self, action: #selector(cylflatdesignPopGestureRecognizerHandler(_:)))
        cylflatdesignState.popGestureRecognizerRegistered = true
    }

    private func cylflatdesignUnregisterPopGestureRecognizer() {
        guard cylflatdesignState.popGestureRecognizerRegistered, let recognizer = cylflatdesignResponsePopGestureRecognizer else { return }
        recognizer.removeTarget(self, action: #selector(cylflatdesignPopGestureRecognizerHandler(_:)))
        cylflatdesignState.popGestureRecognizerRegistered = false
    }

    @objc(_cylflatdesign_popGestureRecognizerHandler:)
    private func cylflatdesignPopGestureRecognizerHandler(_ recognizer: UIPanGestureRecognizer) {
        let delegate = cylflatdesignExtensionDelegate
        let fromVC = transitionCoordinator?.viewController(forKey: .from)
        delegate?.navigationController?(self, didUpdateInteractiveFrom: fromVC, to: topViewController, popGestureRecognizer: recognizer)
        guard recognizer.state != .ended else { return }
        let translation = recognizer.translation(in: view).x
        guard translation != 0 else { return }
        let completed = max(0, min(1, translation / view.bounds.width))
        delegate?.navigationController?(self, didUpdateInteractiveFrom: fromVC, to: topViewController, percentComplete: completed)
    }

    // MARK: Transitions

    private func cylflatdesignEndTransition(from fromVC: UIViewController?, to toVC: UIViewController?,
                                            operation: UINavigationController.Operation, animated: Bool, spring: Bool) {
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: { [weak self] context in
                guard let self else { return }
                self.cylflatdesignExtensionDelegate?.navigationController?(self, willEndTransitionFrom: fromVC, to: toVC,
                                                                          operation: operation, cancelled: context.isCancelled)
            }, completion: { [weak self] context in
                guard let self else { return }
                self.cylflatdesignExtensionDelegate?.navigationController?(self, didEndTransitionFrom: fromVC, to: toVC,
                                                                          operation: operation, cancelled: context.isCancelled)
            })
            return
        }
        let willEnd: () -> Void = {
            self.cylflatdesignExtensionDelegate?.navigationController?(self, willEndTransitionFrom: fromVC, to: toVC,
                                                                      operation: operation, cancelled: false)
        }
        let didEnd: () -> Void = {
            self.cylflatdesignExtensionDelegate?.navigationController?(self, didEndTransitionFrom: fromVC, to: toVC,
                                                                      operation: operation, cancelled: false)
        }
        guard animated else {
            willEnd()
            didEnd()
            return
        }
        // [EN] The keyboard's curve (7 << 16), as the system transition. [CN] 键盘曲线（7 << 16），与系统转场一致。
        let options = UIView.AnimationOptions(rawValue: 7 << 16)
        if spring {
            UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: options,
                           animations: willEnd) { _ in didEnd() }
        } else {
            UIView.animate(withDuration: 0.35, delay: 0, options: options, animations: willEnd) { _ in didEnd() }
        }
    }

    private func cylflatdesignPush(from fromVC: UIViewController?, to toVC: UIViewController?, animated: Bool) {
        cylflatdesignExtensionDelegate?.navigationController?(self, didBeginTransitionFrom: fromVC, to: toVC, operation: .push)
        cylflatdesignEndTransition(from: fromVC, to: toVC, operation: .push, animated: animated, spring: false)
    }

    private func cylflatdesignPop(from fromVC: UIViewController?, to target: UIViewController?, animated: Bool) {
        var toVC = target
        if let fromVC, fromVC === toVC {
            #if DEBUG
            NSLog("%@", CYLLocalizedString("UINavigationController+CYLFlatDesignTabBarPrivate：是否连续 pop 操作？这可能会出问题!"))
            #endif
            // [EN] Consecutive pops: the destination is the one below. [CN] 连续 pop：目标为下面一个控制器。
            if let index = viewControllers.firstIndex(of: fromVC), index > 0 {
                toVC = viewControllers[index - 1]
            }
        }
        cylflatdesignExtensionDelegate?.navigationController?(self, didBeginTransitionFrom: fromVC, to: toVC, operation: .pop)
        cylflatdesignEndTransition(from: fromVC, to: toVC, operation: .pop, animated: animated, spring: true)
    }

    private func cylflatdesignUpdateNavigationBarHeight() {
        let contentView = navigationBar.subviews.first { NSStringFromClass(type(of: $0)).contains("ContentView") }
        let height = (contentView?.frame.maxY ?? 0) + view.safeAreaInsets.top
        cylflatdesignExtensionDelegate?.navigationController?(self, navigationBarDidChangeHeight: height)
    }
}

/**
 [EN] The callbacks of a navigation controller's transitions to the FlatDesign tab bar controller. Swift since step 117 (it was
      declared in UINavigationController+CYLFlatDesignTabBarPrivate.h); kept under its name for source compatibility, the
      library itself uses `CYLFlatDesignNavigationExtensionDelegate`.
 [CN] 导航控制器转场回调给扁平样式 TabBarController 的协议。自第 117 步起为 Swift（原声明在 UINavigationController+CYLFlatDesignTabBarPrivate.h 中）；
      为保持源码兼容保留此名称，库内部使用 `CYLFlatDesignNavigationExtensionDelegate`。
 */
@objc public protocol UINavigationControllerExtensionDelegate: NSObjectProtocol {
    @objc(cylflatdesign_navigationController:navigationBarDidChangeHeight:)
    func cylflatdesign_navigationController(_ navigationController: UINavigationController, navigationBarDidChangeHeight height: CGFloat)

    @objc(cylflatdesign_navigationController:didBeginTransitionFrom:to:operation:)
    func cylflatdesign_navigationController(_ navigationController: UINavigationController, didBeginTransitionFrom fromVC: UIViewController?,
                                            to toVC: UIViewController?, operation: UINavigationController.Operation)

    @objc(cylflatdesign_navigationController:didUpdateInteractiveFrom:to:percentComplete:)
    func cylflatdesign_navigationController(_ navigationController: UINavigationController, didUpdateInteractiveFrom fromVC: UIViewController?,
                                            to toVC: UIViewController?, percentComplete: CGFloat)

    @objc(cylflatdesign_navigationController:didUpdateInteractiveFrom:to:popGestureRecognizer:)
    func cylflatdesign_navigationController(_ navigationController: UINavigationController, didUpdateInteractiveFrom fromVC: UIViewController?,
                                            to toVC: UIViewController?, popGestureRecognizer: UIGestureRecognizer)

    @objc(cylflatdesign_navigationController:willEndTransitionFrom:to:operation:cancelled:)
    func cylflatdesign_navigationController(_ navigationController: UINavigationController, willEndTransitionFrom fromVC: UIViewController?,
                                            to toVC: UIViewController?, operation: UINavigationController.Operation, cancelled: Bool)

    @objc(cylflatdesign_navigationController:didEndTransitionFrom:to:operation:cancelled:)
    func cylflatdesign_navigationController(_ navigationController: UINavigationController, didEndTransitionFrom fromVC: UIViewController?,
                                            to toVC: UIViewController?, operation: UINavigationController.Operation, cancelled: Bool)
}
