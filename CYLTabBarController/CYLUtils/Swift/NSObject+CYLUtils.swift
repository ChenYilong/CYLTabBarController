//
//  NSObject+CYLUtils.swift
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import ObjectiveC

/**
 * [EN] Translated from Objective-C (docs/Swift-Migration.md); Objective-C callers keep the declarations in
 *      `NSObject+CYLUtils.h`. The Objective-C version caught KVC exceptions with `@try`, which Swift cannot do: the
 *      Swift version checks first that the key resolves, in the order KVC searches (accessor methods, then instance
 *      variables), and only then asks KVC, so it does not raise for an unknown key.
 * [CN] 已从 Objective-C 翻译为 Swift（docs/Swift-Migration.md）；Objective-C 调用方继续使用 `NSObject+CYLUtils.h` 中的声明。
 *      Objective-C 版本用 `@try` 捕获 KVC 异常，Swift 无法这样做：Swift 版本先按 KVC 的查找顺序（存取方法，然后实例变量）确认 key
 *      能找到，再交给 KVC，因此未知的 key 不会抛出异常。
 */
extension NSObject {

    /**
     * [EN] `valueForKey:` that returns nil instead of raising for a key the receiver does not have.
     * [CN] 对接收者没有的 key 返回 nil 而不是抛出异常的 `valueForKey:`。
     */
    @objc(cyl_valueForKey:)
    public func cyl_value(forKey key: String) -> Any? {
        guard CYLKeyValueCoding.resolves(key, of: self, setting: false, value: nil) else {
            CYLKeyValueCoding.log("KVC failed", key: key, of: self)
            return nil
        }
        return value(forKey: key)
    }

    /**
     * [EN] `setValue:forKey:` that does nothing instead of raising for a key the receiver does not have (or nil for
     *      a scalar).
     * [CN] 对接收者没有的 key（或给标量传 nil）不做任何事而不是抛出异常的 `setValue:forKey:`。
     */
    @objc(cyl_setValue:forKey:)
    public func cyl_setValue(_ value: Any?, forKey key: String) {
        guard CYLKeyValueCoding.resolves(key, of: self, setting: true, value: value) else {
            CYLKeyValueCoding.log("KVC set failed", key: key, of: self)
            return
        }
        setValue(value, forKey: key)
    }

    /**
     * [EN] Whether the receiver is a placeholder (for a view controller: also its root view controller's flag).
     * [CN] 是否为占位对象（视图控制器还会读取其根控制器的标记）。
     */
    @objc public var cyl_isPlaceholder: Bool {
        @objc(cyl_isPlaceholder)
        get {
            let own = (objc_getAssociatedObject(self, CYLUtilsKeys.isPlaceholder) as? NSNumber)?.boolValue ?? false
            guard let viewController = self as? UIViewController else {
                return own
            }
            let root = viewController.cyl_getViewControllerInsteadOfNavigation()
            let rootFlag = (objc_getAssociatedObject(root, CYLUtilsKeys.isPlaceholder) as? NSNumber)?.boolValue ?? false
            return own || rootFlag
        }
        @objc(cyl_setIsPlaceholder:)
        set {
            let flag = NSNumber(value: newValue)
            objc_setAssociatedObject(self, CYLUtilsKeys.isPlaceholder, flag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            guard let viewController = self as? UIViewController else {
                return
            }
            // [EN] As the Objective-C version: the root of the root view controller. [CN] 与 Objective-C 版本相同：根控制器的根控制器。
            let root = viewController.cyl_getViewControllerInsteadOfNavigation().cyl_getViewControllerInsteadOfNavigation()
            objc_setAssociatedObject(root, CYLUtilsKeys.isPlaceholder, flag, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /**
     * [EN] Stores `object` weakly under `key`; nil removes it.
     * [CN] 以弱引用方式在 `key` 下保存 `object`；传 nil 则移除。
     */
    @objc(cyl_setWeakAssociatedObject:forKey:)
    public func cyl_setWeakAssociatedObject(_ object: Any?, forKey key: UnsafeRawPointer) {
        guard let object = object as AnyObject? else {
            objc_setAssociatedObject(self, key, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        objc_setAssociatedObject(self, key, CYLWeakBox(object), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    /**
     * [EN] The object stored with `-cyl_setWeakAssociatedObject:forKey:`, or nil once it is gone.
     * [CN] 用 `-cyl_setWeakAssociatedObject:forKey:` 保存的对象，释放后为 nil。
     */
    @objc(cyl_weakAssociatedObjectForKey:)
    public func cyl_weakAssociatedObject(forKey key: UnsafeRawPointer) -> Any? {
        (objc_getAssociatedObject(self, key) as? CYLWeakBox)?.object
    }
}

/**
 * [EN] Association keys shared with Objective-C: the selector, as the Objective-C version used.
 * [CN] 与 Objective-C 共用的关联对象 key：与 Objective-C 版本一样使用 selector。
 */
enum CYLUtilsKeys {
    static let isPlaceholder = CYLUtilsKeys.key("cyl_isPlaceholder")
    static let respondsOutsideSuperviewBounds = CYLUtilsKeys.key("cyl_respondsOutsideSuperviewBounds")

    static func key(_ selectorName: String) -> UnsafeRawPointer {
        unsafeBitCast(sel_registerName(selectorName), to: UnsafeRawPointer.self)
    }
}

/**
 * [EN] A weak reference that can be stored as an associated object.
 * [CN] 可作为关联对象保存的弱引用。
 */
private final class CYLWeakBox: NSObject {
    weak var object: AnyObject?

    init(_ object: AnyObject) {
        self.object = object
    }
}

/**
 * [EN] Whether KVC finds a key, without raising (Apple's "Accessor Search Patterns").
 * [CN] 不抛出异常地判断 KVC 能否找到 key（Apple 文档 "Accessor Search Patterns"）。
 */
enum CYLKeyValueCoding {

    static func resolves(_ key: String, of object: NSObject, setting: Bool, value: Any?) -> Bool {
        guard let first = key.first else {
            return false
        }
        let objectClass: AnyClass = type(of: object)
        // [EN] A class that handles KVC itself (collections, overrides) is asked directly.
        // [CN] 自己处理 KVC 的类（集合类、重写了 KVC 的类）直接交给它。
        let handler = setting ? #selector(NSObject.setValue(_:forUndefinedKey:)) : #selector(NSObject.value(forUndefinedKey:))
        let entry = setting ? #selector(NSObject.setValue(_:forKey:)) : #selector(NSObject.value(forKey:))
        if overrides(handler, in: objectClass) || overrides(entry, in: objectClass) {
            return true
        }
        let capitalized = String(first).uppercased() + key.dropFirst()
        if setting {
            for name in ["set\(capitalized):", "_set\(capitalized):"] {
                if let method = class_getInstanceMethod(objectClass, sel_registerName(name)) {
                    return value != nil || argumentIsObject(method)
                }
            }
        } else {
            for name in ["get\(capitalized)", key, "is\(capitalized)", "_\(key)"] where object.responds(to: sel_registerName(name)) {
                return true
            }
        }
        guard objectClass.accessInstanceVariablesDirectly else {
            return false
        }
        for name in ["_\(key)", "_is\(capitalized)", key, "is\(capitalized)"] {
            if let ivar = class_getInstanceVariable(objectClass, name) {
                return !setting || value != nil || encodingIsObject(ivar_getTypeEncoding(ivar))
            }
        }
        return false
    }

    static func log(_ message: String, key: String, of object: NSObject) {
        #if DEBUG
        if key != "imageView" {
            NSLog("🔴 %@: %@ of %@", message, key, NSStringFromClass(type(of: object)))
        }
        #endif
    }

    private static func overrides(_ selector: Selector, in objectClass: AnyClass) -> Bool {
        guard let method = class_getInstanceMethod(objectClass, selector),
              let base = class_getInstanceMethod(NSObject.self, selector) else {
            return false
        }
        return method_getImplementation(method) != method_getImplementation(base)
    }

    private static func argumentIsObject(_ method: Method) -> Bool {
        guard let type = method_copyArgumentType(method, 2) else {
            return true
        }
        defer { free(type) }
        return encodingIsObject(UnsafePointer(type))
    }

    private static func encodingIsObject(_ encoding: UnsafePointer<CChar>?) -> Bool {
        guard let encoding else {
            return true
        }
        let first = encoding.pointee
        return first == CChar(UInt8(ascii: "@")) || first == CChar(UInt8(ascii: "#"))
    }
}
