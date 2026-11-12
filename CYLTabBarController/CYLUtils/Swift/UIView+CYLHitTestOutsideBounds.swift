//
//  UIView+CYLHitTestOutsideBounds.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import ObjectiveC

/**
 * [EN] Translated from Objective-C (docs/Swift-Migration.md); Objective-C callers keep the declaration in
 *      `UIView+CYLHitTestOutsideBounds.h`. A subview with `cyl_respondsOutsideSuperviewBounds` set receives touches
 *      outside its superview's bounds. The first time one is set, `-hitTest:withEvent:` of `UIView` is exchanged once
 *      for `-cyl_outsideBoundsHitTest:withEvent:`, which asks the system first and only then those subviews.
 * [CN] 已从 Objective-C 翻译为 Swift（docs/Swift-Migration.md）；Objective-C 调用方继续使用 `UIView+CYLHitTestOutsideBounds.h`
 *      中的声明。设置了 `cyl_respondsOutsideSuperviewBounds` 的子视图可以接收父视图范围之外的触摸。第一次设置时，把 `UIView` 的
 *      `-hitTest:withEvent:` 与 `-cyl_outsideBoundsHitTest:withEvent:` 交换一次：先询问系统，再询问这些子视图。
 */
extension UIView {

    /**
     * [EN] Whether the view receives touches outside its superview's bounds.
     * [CN] 视图是否接收父视图范围之外的触摸。
     */
    @objc public var cyl_respondsOutsideSuperviewBounds: Bool {
        @objc(cyl_respondsOutsideSuperviewBounds)
        get {
            (objc_getAssociatedObject(self, CYLUtilsKeys.respondsOutsideSuperviewBounds) as? NSNumber)?.boolValue ?? false
        }
        @objc(cyl_setRespondsOutsideSuperviewBounds:)
        set {
            objc_setAssociatedObject(self, CYLUtilsKeys.respondsOutsideSuperviewBounds, NSNumber(value: newValue),
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            if newValue {
                CYLHitTestOutsideBounds.installIfNeeded()
            }
        }
    }

    /**
     * [EN] Exchanged with `-hitTest:withEvent:`: calling it here runs the system's implementation.
     * [CN] 与 `-hitTest:withEvent:` 交换：在这里调用它即执行系统的实现。
     */
    @objc(cyl_outsideBoundsHitTest:withEvent:)
    dynamic func cyl_outsideBoundsHitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = cyl_outsideBoundsHitTest(point, with: event)
        if view != nil || !CYLHitTestOutsideBounds.isInstalled {
            return view
        }
        if isHidden || alpha < 0.01 || !isUserInteractionEnabled {
            return nil
        }
        for subview in subviews.reversed() where subview.cyl_respondsOutsideSuperviewBounds {
            if let hitView = subview.hitTest(subview.convert(point, from: self), with: event) {
                return hitView
            }
        }
        return nil
    }
}

private enum CYLHitTestOutsideBounds {
    static var isInstalled = false

    /**
     * [EN] Exchanges the implementations once (`static let` runs its initializer once, thread-safely).
     * [CN] 只交换一次实现（`static let` 的初始化只执行一次，线程安全）。
     */
    static func installIfNeeded() {
        _ = installation
    }

    private static let installation: Void = {
        let viewClass: AnyClass = UIView.self
        guard let original = class_getInstanceMethod(viewClass, #selector(UIView.hitTest(_:with:))),
              let swizzled = class_getInstanceMethod(viewClass, #selector(UIView.cyl_outsideBoundsHitTest(_:with:))) else {
            return
        }
        method_exchangeImplementations(original, swizzled)
        isInstalled = true
    }()
}
