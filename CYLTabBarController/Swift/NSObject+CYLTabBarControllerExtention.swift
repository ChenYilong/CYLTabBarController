//
//  NSObject+CYLTabBarControllerExtention.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] Context, forced orientation, the topmost view controller, dismissing everything, gesture recognizer kinds and the
 *      plus page check. Translated from Objective-C (docs/Swift-Migration.md, branch swift-core); the two KVO-safe
 *      `-cyl_removeObserver:…` methods stay Objective-C (Swift cannot catch Objective-C exceptions). Objective-C callers get
 *      the declarations from `CYLSwiftInterface.h`; the Swift names are the ones Clang imported.
 * [CN] 上下文、强制方向、最顶层控制器、关闭所有弹出页面、手势识别器类型与 PlusButton 页面检查。已从 Objective-C 翻译
 *      （docs/Swift-Migration.md，swift-core 分支）；两个 KVO 安全的 `-cyl_removeObserver:…` 方法保留为 Objective-C（Swift 无法捕获
 *      Objective-C 异常）。Objective-C 调用方从 `CYLSwiftInterface.h` 获得声明；Swift 名称与 Clang 原先导入的名称相同。
 */
extension NSObject {

    private static let contextKey = CYLUtilsKeys.key("cyl_context")
    private static let forceLandscapeKey = CYLUtilsKeys.key("cyl_isForceLandscape")

    /**
     * [EN] The context the object belongs to (default "CYLTabBarController"; an empty value resets it).
     * [CN] 对象所属的上下文（默认 "CYLTabBarController"；设为空值即重置）。
     */
    @objc public var cyl_context: String? {
        @objc(cyl_context) get {
            objc_getAssociatedObject(self, NSObject.contextKey) as? String ?? NSStringFromClass(CYLTabBarController.self)
        }
        @objc(cyl_setContext:) set {
            let context = newValue?.isEmpty == false ? newValue : NSStringFromClass(CYLTabBarController.self)
            objc_setAssociatedObject(self, NSObject.contextKey, context, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] Whether the app delegate forces landscape (read by its supported orientations).
     * [CN] App 代理是否强制横屏（由其支持的方向读取）。
     */
    @objc public var cyl_isForceLandscape: Bool {
        @objc(cyl_isForceLandscape) get {
            (objc_getAssociatedObject(self, NSObject.forceLandscapeKey) as? NSNumber)?.boolValue ?? false
        }
        @objc(cyl_setIsForceLandscape:) set {
            objc_setAssociatedObject(self, NSObject.forceLandscapeKey, NSNumber(value: newValue), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] The app delegate.
     * [CN] App 代理。
     */
    @objc(cyl_sharedAppDelegate)
    public func cyl_sharedAppDelegate() -> (UIResponder & UIApplicationDelegate)! {
        UIApplication.shared.delegate as? UIResponder & UIApplicationDelegate
    }

    /**
     * [EN] Rotates the interface to `orientation` (iOS 16+: a geometry update of the window scene, limited to what the
     *      topmost view controller supports).
     * [CN] 将界面旋转到 `orientation`（iOS 16+：对窗口场景请求几何更新，限于最顶层控制器支持的方向）。
     */
    @objc(cyl_forceUpdateInterfaceOrientation:)
    public func cyl_forceUpdateInterfaceOrientation(_ orientation: UIInterfaceOrientation) {
        let appDelegate = cyl_sharedAppDelegate()
        appDelegate?.cyl_isForceLandscape = orientation == .landscapeLeft || orientation == .landscapeRight
        _ = appDelegate?.application?(UIApplication.shared, supportedInterfaceOrientationsFor: CYLGetRootWindow())
        if #available(iOS 16.0, *) {
            guard let windowScene = CYLGetWindowScene() else {
                return
            }
            var topViewController = windowScene.keyWindow?.rootViewController
            while let presented = topViewController?.presentedViewController {
                topViewController = presented
            }
            guard let topViewController else {
                return
            }
            var targetMask = NSObject.mask(from: orientation)
            let supportedMask = topViewController.supportedInterfaceOrientations
            if supportedMask.intersection(targetMask).isEmpty {
                targetMask = supportedMask
            }
            topViewController.setNeedsUpdateOfSupportedInterfaceOrientations()
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: targetMask)) { _ in
                // [EN] Nothing to do when the system refuses. [CN] 系统拒绝时无需处理。
            }
        } else {
            // [EN] As before: portrait first, then the wanted orientation (KVC instead of NSInvocation, which Swift lacks).
            // [CN] 与原来相同：先竖屏，再目标方向（用 KVC 代替 Swift 中没有的 NSInvocation）。
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
            UIViewController.attemptRotationToDeviceOrientation()
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }

    private static func mask(from orientation: UIInterfaceOrientation) -> UIInterfaceOrientationMask {
        switch orientation {
        case .portrait: return .portrait
        case .portraitUpsideDown: return .portraitUpsideDown
        case .landscapeLeft: return .landscapeLeft
        case .landscapeRight: return .landscapeRight
        default: return .portrait
        }
    }

    // MARK: - Topmost view controller

    private static func topmost(from viewController: UIViewController?, forNavigation: Bool) -> UIViewController? {
        var top = viewController
        while let current = top {
            if let presented = current.presentedViewController,
               !(forNavigation && (presented is UIAlertController || presented.isBeingDismissed)) {
                top = presented
                continue
            }
            let child: UIViewController?
            if let navigationController = current as? UINavigationController {
                child = navigationController.topViewController
            } else if let tabBarController = current as? UITabBarController {
                child = tabBarController.selectedViewController
            } else {
                break
            }
            if child == nil && forNavigation {
                break
            }
            top = child
        }
        return top
    }

    /**
     * [EN] The topmost view controller of the root window (presented, navigation top, selected tab).
     * [CN] 根窗口中最顶层的控制器（被 present 的、导航栈顶、选中的 Tab）。
     */
    @objc(cyl_topmostViewController)
    public class func cyl_topmostViewController() -> UIViewController? {
        topmost(from: CYLGetRootWindow()?.rootViewController, forNavigation: false)
    }

    /**
     * [EN] The navigation controller of the topmost view controller (alerts and dismissing pages skipped).
     * [CN] 最顶层控制器所在的导航控制器（跳过 alert 与正在关闭的页面）。
     */
    @objc(cyl_currentNavigationController)
    public class func cyl_currentNavigationController() -> UINavigationController? {
        let top = topmost(from: CYLGetRootWindow()?.rootViewController, forNavigation: true)
        return top as? UINavigationController ?? top?.navigationController
    }

    /**
     * [EN] Dismisses every presented view controller (popping presented navigation controllers to their root) without
     *      animation, then calls `completion`.
     * [CN] 无动画关闭所有被 present 的控制器（被 present 的导航控制器先回到根页面），然后调用 `completion`。
     */
    @objc(cyl_dismissAll:)
    public class func cyl_dismissAll(_ completion: (() -> Void)?) {
        guard var top = CYLGetRootViewController() else {
            completion?()
            return
        }
        var list: [UIViewController] = []
        while true {
            if let presented = top.presentedViewController {
                top = presented
                list.append(presented)
            } else if let navigationController = top as? UINavigationController, let next = navigationController.topViewController {
                top = next
            } else if let tabBarController = top as? UITabBarController, let next = tabBarController.selectedViewController {
                top = next
            } else {
                break
            }
        }
        if list.isEmpty {
            completion?()
            return
        }
        for (index, viewController) in list.enumerated().reversed() {
            (viewController as? UINavigationController)?.popToRootViewController(animated: false)
            viewController.dismiss(animated: false, completion: index == 0 ? completion : nil)
        }
    }

    // MARK: - Debugging

    /**
     * [EN] The instance variables of the object with their offsets (from `-_ivarDescription`), for debugging.
     * [CN] 对象的实例变量及其偏移（来自 `-_ivarDescription`），用于调试。
     */
    @objc(cyl_ivarList)
    public func cyl_ivarList() -> String {
        let selector = NSSelectorFromString("_ivarDescription")
        guard responds(to: selector), let description = perform(selector)?.takeUnretainedValue() as? String else {
            return ""
        }
        guard let expression = try? NSRegularExpression(pattern: "^(\\s+)(\\S+)", options: .caseInsensitive) else {
            return description
        }
        var lines = description.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            let text = line as NSString
            if NSObject.trimmed(line).count <= 2 || line.hasPrefix("\t\t") {
                continue
            }
            guard let match = expression.firstMatch(in: line, options: .reportCompletion,
                                                    range: NSRange(location: 0, length: text.length)),
                  match.numberOfRanges >= 3 else {
                continue
            }
            let indent = match.range(at: 1)
            let name = text.substring(with: match.range(at: 2))
            let offset = class_getInstanceVariable(type(of: self), name).map { ivar_getOffset($0) } ?? 0
            let insertion = "[\(offset)|0x\(String(offset, radix: 16).uppercased())]"
            lines[index] = text.replacingCharacters(in: NSRange(location: NSMaxRange(indent), length: 0), with: insertion)
        }
        return lines.joined(separator: "\n")
    }

    /**
     * [EN] The methods of the object (from `-_methodDescription`), for debugging in LLDB.
     * [CN] 对象的方法（来自 `-_methodDescription`），用于在 LLDB 中调试。
     */
    @objc(cyl_methodList)
    func cyl_methodList() -> String? {
        perform(NSSelectorFromString("_methodDescription"))?.takeUnretainedValue() as? String
    }

    /**
     * [EN] The methods of the object's own class (from `-_shortMethodDescription`), for debugging in LLDB.
     * [CN] 对象自身类的方法（来自 `-_shortMethodDescription`），用于在 LLDB 中调试。
     */
    @objc(cyl_shortMethodList)
    func cyl_shortMethodList() -> String? {
        perform(NSSelectorFromString("_shortMethodDescription"))?.takeUnretainedValue() as? String
    }

    /**
     * [EN] The view tree (from `-recursiveDescription`), for debugging in LLDB.
     * [CN] 视图树（来自 `-recursiveDescription`），用于在 LLDB 中调试。
     */
    @objc(cyl_viewInfo)
    func cyl_viewInfo() -> String? {
        guard self is UIView else {
            return "Sorry, only support UIView"
        }
        return perform(NSSelectorFromString("recursiveDescription"))?.takeUnretainedValue() as? String
    }

    private static func trimmed(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: "\0")))
    }

    // MARK: - Kinds

    /**
     * [EN] Whether the object is one of UIKit's private continuous gesture recognizers (`_UIContinuous…tionGestureRecognizer`).
     * [CN] 对象是否为 UIKit 私有的连续手势识别器（`_UIContinuous…tionGestureRecognizer`）。
     */
    @objc(cyl_isContinuousGestureRecognizer)
    public func cyl_isContinuousGestureRecognizer() -> Bool {
        let name = NSStringFromClass(type(of: self))
        return name.hasPrefix("_UIContinuous") && name.hasSuffix("tionGestureRecognizer")
    }

    /**
     * [EN] Whether the object is a long press gesture recognizer.
     * [CN] 对象是否为长按手势识别器。
     */
    @objc(cyl_isLongGestureRecognizer)
    public func cyl_isLongGestureRecognizer() -> Bool {
        let name = NSStringFromClass(type(of: self))
        return name.hasPrefix("UILongPr") && name.hasSuffix("essGestureRecognizer")
    }

    /**
     * [EN] Whether the plus child view controller of the receiver's context is among `viewControllers`.
     * [CN] 接收者上下文的 PlusChildViewController 是否在 `viewControllers` 中。
     */
    @objc(cyl_isPlusViewControllerAdded:)
    public func cyl_isPlusViewControllerAdded(_ viewControllers: [Any]?) -> Bool {
        guard let plusViewController = CYLPlusButton.plusChildViewController(forOwner: self) else {
            return false
        }
        return (viewControllers ?? []).contains { element in
            guard let viewController = element as? UIViewController else {
                return false
            }
            return viewController === plusViewController || viewController.cyl_isEqual(to: plusViewController)
        }
    }
}
