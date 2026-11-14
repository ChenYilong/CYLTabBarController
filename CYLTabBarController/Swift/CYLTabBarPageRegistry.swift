//
//  CYLTabBarPageRegistry.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import MachO
import UIKit

/**
 * [EN] The block types `CYLTabBarPageProvider`, `CYLTabBarPageFactory`, `CYLTabBarPageCompletion` and
 *      `CYLTabBarAsyncPageFactory` and the string type `CYLTabBarPageSource` stay declared in CYLTabBarPageRegistry.h
 *      (CYLTabBarController.h uses them). The public signatures below spell the types out: a typedef of a module header in
 *      a public Swift signature makes the generated header import the umbrella header.
 * [CN] block 类型 `CYLTabBarPageProvider`、`CYLTabBarPageFactory`、`CYLTabBarPageCompletion`、`CYLTabBarAsyncPageFactory` 与字符串类型
 *      `CYLTabBarPageSource` 仍声明在 CYLTabBarPageRegistry.h 中（CYLTabBarController.h 使用它们）。下面的公开签名写出完整类型：公开的
 *      Swift 签名中使用模块头文件的 typedef 会让生成的头文件导入总头文件。
 */
enum CYLTabBarPageTypes {
    typealias Provider = (String, [String: Any]) -> UIViewController?
    typealias Factory = (CYLTabBarPageRequest) -> UIViewController?
    typealias Completion = (UIViewController?) -> Void
    typealias AsyncFactory = (CYLTabBarPageRequest, @escaping (UIViewController?) -> Void) -> UIViewController?
}

/**
 * [EN] The registry passed with `CYLTabBarControllerPageRegistry`. [CN] 通过 `CYLTabBarControllerPageRegistry` 传入的注册表。
 */
public let CYLTabBarPageSourceInstanceRegistry = "instance"
/**
 * [EN] The block passed with `CYLTabBarControllerPageResolver`. [CN] 通过 `CYLTabBarControllerPageResolver` 传入的 block。
 */
public let CYLTabBarPageSourceResolver = "resolver"
/**
 * [EN] `CYLTabBarPageRegistry.shared`. [CN] `CYLTabBarPageRegistry.shared`。
 */
public let CYLTabBarPageSourceSharedRegistry = "shared"
/**
 * [EN] The classes that adopt `CYLTabBarPage`. [CN] 遵守 `CYLTabBarPage` 的类。
 */
public let CYLTabBarPageSourceAutomaticRegistration = "automatic"

/**
 * [EN] Why a tab got no page. [CN] Tab 没有页面的原因。
 */
@objc(CYLTabBarPageSkipReason)
public enum CYLTabBarPageSkipReason: Int {
    /**
     * [EN] The tab's attributes are not a dictionary (edge case B4). [CN] Tab 的属性不是字典（边界情况 B4）。
     */
    case invalidTab = 1
    /**
     * [EN] Neither `CYLTabBarItemPageIdentifier` nor `CYLTabBarItemIdentifier`. [CN] 既没有 `CYLTabBarItemPageIdentifier` 也没有 `CYLTabBarItemIdentifier`。
     */
    case missingIdentifier = 2
    /**
     * [EN] No source has a page for the ID. [CN] 没有任何来源提供该 ID 的页面。
     */
    case unregistered = 3
    /**
     * [EN] Left out on purpose (platform, app version). [CN] 有意排除（平台、App 版本）。
     */
    case excluded = 4
    /**
     * [EN] A source was found, but gave no usable page (nil, raised, not a page, already used). [CN] 找到了来源，但没有得到可用的页面（nil、抛出异常、不是页面、已被使用）。
     */
    case providerFailed = 5
}

/**
 * [EN] Something that gives the page provider of a page ID, e.g. a `CYLTabBarPageRegistry`.
 * [CN] 能给出某个页面 ID 的页面提供者的对象，例如 `CYLTabBarPageRegistry`。
 */
@objc(CYLTabBarPageProviding)
public protocol CYLTabBarPageProviding: NSObjectProtocol {
    @objc(pageProviderForPageIdentifier:)
    func pageProvider(forPageIdentifier pageIdentifier: String) -> ((String, [String: Any]) -> UIViewController?)?
}

/**
 * [EN] A page class that registers itself: the library finds the classes that adopt it, without registration code
 *      (docs/Tab-Page-Registry.md).
 * [CN] 自行注册的页面类：本库自动找到遵守它的类，无需注册代码（docs/Tab-Page-Registry.md）。
 */
@objc(CYLTabBarPage)
public protocol CYLTabBarPage: NSObjectProtocol {
    /**
     * [EN] The page ID of this class. [CN] 该类的页面 ID。
     */
    @objc(cylTabBarPageIdentifier)
    static func cylTabBarPageIdentifier() -> String

    /**
     * [EN] The page for a tab; without it, the class is created with `init()`. [CN] 某个 Tab 的页面；未实现时用 `init()` 创建。
     */
    @objc(cylTabBarPageWithAttributes:)
    optional static func cylTabBarPage(attributes tabAttributes: [String: Any]) -> UIViewController?
}

enum CYLTabBarPageValues {
    static let loadKey = CYLUtilsKeys.key("cyl_pageLoad")
    static let identifierSelector = NSSelectorFromString("cylTabBarPageIdentifier")
    static let pageSelector = NSSelectorFromString("cylTabBarPageWithAttributes:")

    /**
     * [EN] A non-empty ID with surrounding spaces removed, or nil. [CN] 去掉首尾空白后的非空 ID，否则为 nil。
     */
    static func identifier(_ value: Any?) -> String? {
        guard let trimmed = (value as? String)?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        return trimmed
    }

    static func log(_ message: String) {
#if DEBUG
        NSLog("%@", message as NSString)
#endif
    }
}

/**
 * [EN] What a page factory gets: the page ID and the public attributes of its tab (keys starting with "_" are the
 *      library's private markers and are left out).
 * [CN] 页面工厂收到的内容：页面 ID 及其 Tab 的公开属性（以 "_" 开头的键是库的私有标记，不包含在内）。
 */
@objc(CYLTabBarPageRequest)
public final class CYLTabBarPageRequest: NSObject {
    @objc public let pageIdentifier: String
    /**
     * [EN] `CYLTabBarItemIdentifier` of the tab. [CN] Tab 的 `CYLTabBarItemIdentifier`。
     */
    @objc public let tabIdentifier: String?
    /**
     * [EN] `CYLTabBarItemTitle` of the tab. [CN] Tab 的 `CYLTabBarItemTitle`。
     */
    @objc public let title: String?
    /**
     * [EN] `CYLTabBarItemPageParameters` of the tab, empty when it has none. [CN] Tab 的 `CYLTabBarItemPageParameters`，没有时为空。
     */
    @objc public let parameters: [String: Any]
    @objc public let attributes: [String: Any]

    @objc(requestWithPageIdentifier:attributes:)
    public class func request(withPageIdentifier pageIdentifier: String, attributes: [String: Any]?) -> CYLTabBarPageRequest {
        CYLTabBarPageRequest(pageIdentifier: pageIdentifier, attributes: attributes)
    }

    public init(pageIdentifier: String, attributes: [String: Any]?) {
        self.pageIdentifier = pageIdentifier
        let publicAttributes = (attributes ?? [:]).filter { !$0.key.hasPrefix("_") }
        self.attributes = publicAttributes
        tabIdentifier = publicAttributes[CYLTabBarItemIdentifier] as? String
        title = publicAttributes[CYLTabBarItemTitle] as? String
        parameters = publicAttributes[CYLTabBarItemPageParameters] as? [String: Any] ?? [:]
    }

    override public var description: String {
        "<\(NSStringFromClass(type(of: self))) \(Unmanaged.passUnretained(self).toOpaque()) page ID \"\(pageIdentifier)\" "
            + "tab ID \(tabIdentifier ?? "nil") title \(title ?? "nil") parameters \(parameters as NSDictionary)>"
    }
}

/**
 * [EN] A tab that got no page, with the reason (`-[CYLTabBarController cyl_skippedTabs]`).
 * [CN] 没有页面的 Tab 及其原因（`-[CYLTabBarController cyl_skippedTabs]`）。
 */
@objc(CYLTabBarSkippedTab)
public final class CYLTabBarSkippedTab: NSObject {
    @objc public let reason: CYLTabBarPageSkipReason
    @objc public let pageIdentifier: String?
    @objc public let title: String?
    @objc public let attributes: [String: Any]
    /**
     * [EN] Why, in English, when there is more to say (e.g. what the provider returned). [CN] 更详细的英文原因（例如提供者返回了什么）。
     */
    @objc public let detail: String?

    @objc(skippedTabWithReason:pageIdentifier:attributes:detail:)
    public class func skippedTab(with reason: CYLTabBarPageSkipReason, pageIdentifier: String?, attributes: [String: Any]?,
                                 detail: String?) -> CYLTabBarSkippedTab {
        CYLTabBarSkippedTab(reason: reason, pageIdentifier: pageIdentifier, attributes: attributes, detail: detail)
    }

    public init(reason: CYLTabBarPageSkipReason, pageIdentifier: String?, attributes: [String: Any]?, detail: String?) {
        self.reason = reason
        self.pageIdentifier = pageIdentifier
        self.attributes = attributes ?? [:]
        title = attributes?[CYLTabBarItemTitle] as? String
        self.detail = detail
    }

    override public var description: String {
        let names = ["none", "invalid tab", "missing identifier", "unregistered", "excluded", "provider failed"]
        let name = names.indices.contains(reason.rawValue) ? names[reason.rawValue] : names[0]
        return "<\(NSStringFromClass(type(of: self))) \(Unmanaged.passUnretained(self).toOpaque()) \"\(title ?? "")\" "
            + "(page ID \(pageIdentifier ?? "missing")): \(name)\(detail.map { " — " + $0 } ?? "")>"
    }
}

/**
 * [EN] The built-in placeholder of an asynchronous page: a spinner. [CN] 异步页面的内置占位：一个加载指示器。
 */
@objc(CYLTabBarPagePlaceholder)
open class CYLTabBarPagePlaceholder: UIViewController {
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.color = .gray
        indicator.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(indicator)
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])
        indicator.startAnimating()
    }
}

/**
 * [EN] The pending load behind a placeholder; one per asynchronous factory call. [CN] 占位背后的待完成加载；每次调用异步工厂一个。
 */
final class CYLTabBarPageLoad: NSObject {
    weak var placeholder: UIViewController?
    var page: UIViewController?
    var finished = false
    var failed = false
    var handler: ((UIViewController) -> Void)?

    /**
     * [EN] Takes the delivered page, once, on the main thread; later calls are ignored. [CN] 在主线程接收交付的页面，只接收一次；之后的调用忽略。
     */
    func finish(with page: UIViewController?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { self.finish(with: page) }
            return
        }
        if finished {
            CYLTabBarPageValues.log("🟡 CYLTabBarPageRegistry: the completion of an asynchronous page factory was called again; ignored.")
            return
        }
        finished = true
        failed = page == nil
        self.page = page
        if let placeholder {
            handler?(placeholder)
        }
    }
}

/**
 * [EN] `UIViewController (CYLTabBarPageLoading)`: the state of a placeholder returned for an asynchronous page.
 * [CN] `UIViewController (CYLTabBarPageLoading)`：为异步页面返回的占位的状态。
 */
extension UIViewController {

    private var cyl_pageLoad: CYLTabBarPageLoad? {
        objc_getAssociatedObject(self, CYLTabBarPageValues.loadKey) as? CYLTabBarPageLoad
    }

    /**
     * [EN] YES while this placeholder waits for its page. [CN] 该占位仍在等待其页面时为 YES。
     */
    @objc public var cyl_isPendingPage: Bool {
        cyl_pageLoad.map { !$0.finished } ?? false
    }

    /**
     * [EN] The delivered page, once the load finished with one. [CN] 加载完成并交付了页面时，为该页面。
     */
    @objc public var cyl_loadedPage: UIViewController? {
        cyl_pageLoad.flatMap { $0.finished ? $0.page : nil }
    }

    /**
     * [EN] YES when the load finished without a page. [CN] 加载完成但没有页面时为 YES。
     */
    @objc public var cyl_pageLoadFailed: Bool {
        cyl_pageLoad.map { $0.finished && $0.failed } ?? false
    }

    /**
     * [EN] Called on the main thread when the load of this placeholder finishes. [CN] 该占位的加载完成时在主线程调用。
     */
    @objc public var cyl_pageLoadHandler: ((UIViewController) -> Void)? {
        get { cyl_pageLoad?.handler }
        set { cyl_pageLoad?.handler = newValue }
    }
}

/**
 * [EN] Page IDs and the providers that create their pages (docs/Tab-Page-Registry.md). Thread-safe. Translated from
 *      Objective-C (docs/Swift-Migration.md, step 35); selectors and Swift names kept.
 * [CN] 页面 ID 及创建其页面的提供者（docs/Tab-Page-Registry.md）。线程安全。已从 Objective-C 翻译（docs/Swift-Migration.md，第 35 步）；
 *      selector 与 Swift 名称不变。
 */
@objc(CYLTabBarPageRegistry)
open class CYLTabBarPageRegistry: NSObject, CYLTabBarPageProviding {

    private var providers: [String: CYLTabBarPageTypes.Provider] = [:]
    private let lock = NSLock()

    /**
     * [EN] The app-wide registry. [CN] App 全局的注册表。
     */
    @objc(sharedRegistry) public static let shared = CYLTabBarPageRegistry()

    // MARK: Registering

    @objc(registerPageProvider:forPageIdentifier:)
    public func register(_ provider: @escaping (String, [String: Any]) -> UIViewController?, forPageIdentifier pageIdentifier: String) {
        guard let identifier = CYLTabBarPageValues.identifier(pageIdentifier) else { return }
        lock.lock()
        providers[identifier] = provider
        lock.unlock()
    }

    @objc(registerPageProvider:forPageIdentifiers:)
    public func register(_ provider: @escaping (String, [String: Any]) -> UIViewController?, forPageIdentifiers pageIdentifiers: [String]) {
        pageIdentifiers.forEach { register(provider, forPageIdentifier: $0) }
    }

    @objc(registerAsyncPageFactory:forPageIdentifier:)
    public func register(asyncFactory factory: @escaping (CYLTabBarPageRequest, @escaping (UIViewController?) -> Void) -> UIViewController?, forPageIdentifier pageIdentifier: String) {
        register(Self.provider(ofAsyncFactory: factory), forPageIdentifier: pageIdentifier)
    }

    @objc(registerAsyncPageFactory:forPageIdentifiers:)
    public func register(asyncFactory factory: @escaping (CYLTabBarPageRequest, @escaping (UIViewController?) -> Void) -> UIViewController?, forPageIdentifiers pageIdentifiers: [String]) {
        register(Self.provider(ofAsyncFactory: factory), forPageIdentifiers: pageIdentifiers)
    }

    @objc(registerPageFactory:forPageIdentifier:)
    public func register(factory: @escaping (CYLTabBarPageRequest) -> UIViewController?, forPageIdentifier pageIdentifier: String) {
        register(Self.provider(ofFactory: factory), forPageIdentifier: pageIdentifier)
    }

    @objc(registerPageFactory:forPageIdentifiers:)
    public func register(factory: @escaping (CYLTabBarPageRequest) -> UIViewController?, forPageIdentifiers pageIdentifiers: [String]) {
        register(Self.provider(ofFactory: factory), forPageIdentifiers: pageIdentifiers)
    }

    /**
     * [EN] Registers a class that adopts `CYLTabBarPage` under its page ID. [CN] 以其页面 ID 注册遵守 `CYLTabBarPage` 的类。
     */
    @objc(registerPageClass:)
    public func register(pageClass: AnyClass) {
        guard let identifier = Self.pageIdentifier(of: pageClass) else {
            CYLTabBarPageValues.log("🔴 CYLTabBarPageRegistry: \(NSStringFromClass(pageClass)) does not adopt CYLTabBarPage with a page ID; not registered.")
            return
        }
        register(Self.provider(ofClass: pageClass), forPageIdentifier: identifier)
    }

    @objc(unregisterPageIdentifier:)
    public func unregister(pageIdentifier: String) {
        guard let identifier = CYLTabBarPageValues.identifier(pageIdentifier) else { return }
        lock.lock()
        providers[identifier] = nil
        lock.unlock()
    }

    @objc public func removeAllPageProviders() {
        lock.lock()
        providers.removeAll()
        lock.unlock()
    }

    @objc(pageProviderForPageIdentifier:)
    public func pageProvider(forPageIdentifier pageIdentifier: String) -> ((String, [String: Any]) -> UIViewController?)? {
        guard let identifier = CYLTabBarPageValues.identifier(pageIdentifier) else { return nil }
        lock.lock()
        defer { lock.unlock() }
        return providers[identifier]
    }

    @objc public var registeredPageIdentifiers: [String] {
        lock.lock()
        defer { lock.unlock() }
        return providers.keys.sorted()
    }

    // MARK: Providers

    /**
     * [EN] A provider that calls a factory with a typed request. [CN] 用类型化请求调用工厂的提供者。
     */
    private static func provider(ofFactory factory: @escaping CYLTabBarPageTypes.Factory) -> CYLTabBarPageTypes.Provider {
        { pageIdentifier, tabAttributes in factory(CYLTabBarPageRequest(pageIdentifier: pageIdentifier, attributes: tabAttributes)) }
    }

    /**
     * [EN] A provider that calls an asynchronous factory and returns its placeholder (else a `CYLTabBarPagePlaceholder`) with
     *      the pending load attached; the completion finishes the load, once, on the main thread. A placeholder that is a
     *      tab bar controller or already has a parent is replaced by the built-in one.
     * [CN] 调用异步工厂并返回其占位（否则为 `CYLTabBarPagePlaceholder`）的提供者，占位上附有待完成的加载；completion 在主线程完成该加载，
     *      且只完成一次。占位是 TabBarController 或已有父控制器时，改用内置占位。
     */
    private static func provider(ofAsyncFactory factory: @escaping CYLTabBarPageTypes.AsyncFactory) -> CYLTabBarPageTypes.Provider {
        { pageIdentifier, tabAttributes in
            let load = CYLTabBarPageLoad()
            var placeholder = factory(CYLTabBarPageRequest(pageIdentifier: pageIdentifier, attributes: tabAttributes)) { load.finish(with: $0) }
            if let given = placeholder, given is UITabBarController || given.parent != nil || given.presentingViewController != nil {
                CYLTabBarPageValues.log("🟡 CYLTabBarPageRegistry: the placeholder of \"\(pageIdentifier)\" cannot be a tab (\(given)); CYLTabBarPagePlaceholder is used.")
                placeholder = nil
            }
            let shown = placeholder ?? CYLTabBarPagePlaceholder()
            load.placeholder = shown
            objc_setAssociatedObject(shown, CYLTabBarPageValues.loadKey, load, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return shown
        }
    }

    /**
     * [EN] The page of a `CYLTabBarPage` class: `+cylTabBarPageWithAttributes:`, else `-init`.
     * [CN] `CYLTabBarPage` 类的页面：`+cylTabBarPageWithAttributes:`，否则 `-init`。
     */
    private static func provider(ofClass pageClass: AnyClass) -> CYLTabBarPageTypes.Provider {
        { _, tabAttributes in
            if let pageType = pageClass as? CYLTabBarPage.Type,
               (pageClass as AnyObject).responds(to: CYLTabBarPageValues.pageSelector) {
                return pageType.cylTabBarPage?(attributes: tabAttributes) ?? nil
            }
            return (pageClass as? UIViewController.Type)?.init()
        }
    }

    /**
     * [EN] The page ID a `CYLTabBarPage` class declares, or nil (also when it raises).
     * [CN] `CYLTabBarPage` 类声明的页面 ID；没有（或抛出异常）则为 nil。
     */
    private static func pageIdentifier(of pageClass: AnyClass) -> String? {
        guard class_conformsToProtocol(pageClass, CYLTabBarPage.self),
              class_getClassMethod(pageClass, CYLTabBarPageValues.identifierSelector) != nil,
              let pageType = pageClass as? CYLTabBarPage.Type else {
            return nil
        }
        var identifier: String?
        _ = CYLCatchException { identifier = CYLTabBarPageValues.identifier(pageType.cylTabBarPageIdentifier()) }
        return identifier
    }

    // MARK: Automatic registration

    private static let scanLock = NSLock()
    private static var scannedPageClasses: [String: AnyClass]?

    /**
     * [EN] Scans the classes of the app's own images (not the system's) for `CYLTabBarPage`. `class_conformsToProtocol` and
     *      `class_getClassMethod` read the class without sending it a message, so no `+initialize` runs during the scan. Two
     *      classes with one page ID: the first in class name order is used.
     * [CN] 在 App 自身镜像（不含系统镜像）的类中查找 `CYLTabBarPage`。`class_conformsToProtocol` 与 `class_getClassMethod` 只读取类信息，
     *      不向类发送消息，扫描时不会触发 `+initialize`。两个类声明同一个页面 ID 时，按类名顺序使用第一个。
     */
    private static func scanPageClasses() -> [String: AnyClass] {
        var pageClasses: [AnyClass] = []
        let identifierSelector = CYLTabBarPageValues.identifierSelector
        for index in 0..<_dyld_image_count() {
            guard let imagePath = _dyld_get_image_name(index) else { continue }
            let path = String(cString: imagePath)
            if path.contains("/System/Library/") || path.contains("/usr/lib/") || path.contains("/Developer/Library/") {
                continue
            }
            var classCount: UInt32 = 0
            guard let classNames = objc_copyClassNamesForImage(imagePath, &classCount) else { continue }
            for classIndex in 0..<Int(classCount) {
                if let aClass: AnyClass = objc_getClass(classNames[classIndex]) as? AnyClass,
                   class_conformsToProtocol(aClass, CYLTabBarPage.self), class_getClassMethod(aClass, identifierSelector) != nil {
                    pageClasses.append(aClass)
                }
            }
            free(UnsafeMutableRawPointer(mutating: classNames))
        }
        pageClasses.sort { NSStringFromClass($0) < NSStringFromClass($1) }
        var classesByIdentifier: [String: AnyClass] = [:]
        for pageClass in pageClasses {
            guard let identifier = pageIdentifier(of: pageClass) else { continue }
            if let used = classesByIdentifier[identifier] {
                CYLTabBarPageValues.log("🔴 CYLTabBarPageRegistry: \(NSStringFromClass(used)) and \(NSStringFromClass(pageClass)) both claim the page ID "
                                        + "\"\(identifier)\"; \(NSStringFromClass(used)) is used.")
                continue
            }
            classesByIdentifier[identifier] = pageClass
        }
        return classesByIdentifier
    }

    /**
     * [EN] The classes that adopt `CYLTabBarPage`, by page ID; scanned on first use. [CN] 遵守 `CYLTabBarPage` 的类，按页面 ID 索引；首次使用时扫描。
     */
    @objc public class var automaticallyRegisteredPageClasses: [String: AnyClass] {
        scanLock.lock()
        defer { scanLock.unlock() }
        if let scanned = scannedPageClasses {
            return scanned
        }
        let scanned = scanPageClasses()
        scannedPageClasses = scanned
        return scanned
    }

    /**
     * [EN] Forgets the scan, e.g. after loading a bundle with page classes. [CN] 丢弃扫描结果，例如加载了含页面类的 bundle 之后。
     */
    @objc public class func rescanPageClasses() {
        scanLock.lock()
        scannedPageClasses = nil
        scanLock.unlock()
    }

    /**
     * [EN] Runs the scan on a background queue, e.g. at launch. [CN] 在后台队列执行扫描，例如在启动时。
     */
    @objc public class func prepareAutomaticRegistrationInBackground() {
        DispatchQueue.global(qos: .utility).async { _ = automaticallyRegisteredPageClasses }
    }

    /**
     * [EN] Instance registry, resolver, shared registry, automatic registration. [CN] 实例注册表、解析回调、全局注册表、自动注册。
     */
    @objc public class var defaultPageLookupOrder: [String] {
        [CYLTabBarPageSourceInstanceRegistry, CYLTabBarPageSourceResolver, CYLTabBarPageSourceSharedRegistry,
         CYLTabBarPageSourceAutomaticRegistration]
    }

    // MARK: Lookup

    /**
     * [EN] The page ID of a tab: `CYLTabBarItemPageIdentifier`, else `CYLTabBarItemIdentifier`.
     * [CN] Tab 的页面 ID：`CYLTabBarItemPageIdentifier`，否则为 `CYLTabBarItemIdentifier`。
     */
    @objc(pageIdentifierOfTab:)
    public class func pageIdentifier(ofTab tabAttributes: [String: Any]) -> String? {
        [CYLTabBarItemPageIdentifier, CYLTabBarItemIdentifier].lazy.compactMap { CYLTabBarPageValues.identifier(tabAttributes[$0]) }.first
    }

    /**
     * [EN] Calls a page provider. A provider is app code: an Objective-C exception it raises is caught (C12), and a result
     *      that is not a view controller, is a tab bar controller, already belongs to another container or is already used
     *      by another tab is refused (C13), so UIKit never moves or nests it. The second value says why, in English.
     * [CN] 调用页面提供者。提供者是 App 代码：它抛出的 Objective-C 异常会被捕获（C12）；结果不是视图控制器、是 TabBarController、已属于其他
     *      容器或已被其他 Tab 使用时会被拒绝（C13），因此 UIKit 不会移动或嵌套它。第二个值为英文原因。
     */
    private static func call(_ provider: CYLTabBarPageTypes.Provider, _ pageIdentifier: String, _ attributes: [String: Any],
                             usedPages: [UIViewController], source: String) -> (UIViewController?, String?) {
        var result: AnyObject?
        if let exception = CYLCatchException({ result = provider(pageIdentifier, attributes) }) {
            return (nil, "\(source) raised \(exception.name.rawValue) (\(exception.reason ?? ""))")
        }
        guard let result else {
            return (nil, "\(source) returned nil")
        }
        let reason: String?
        // [EN] Checked at run time: Objective-C code can return any object. [CN] 运行时检查：Objective-C 代码可能返回任意对象。
        if !result.isKind(of: UIViewController.self) {
            reason = "is not a view controller"
        } else if result is UITabBarController {
            reason = "is a tab bar controller (tab bars cannot be nested)"
        } else if let page = result as? UIViewController, page.parent != nil || page.presentingViewController != nil {
            reason = "already belongs to another container (return a new page each time)"
        } else if usedPages.contains(where: { $0 === result }) {
            reason = "is already the page of another tab"
        } else {
            reason = nil
        }
        if let reason {
            return (nil, "the page from \(source) \(reason): \(result)")
        }
        return (result as? UIViewController, nil)
    }

    /**
     * [EN] The pages of `tabs`, each from the first source of `lookupOrder` (nil: the default order) that has a usable page.
     *      A tab with a page is added to `keptTabs`; a tab without one is skipped and added to `skipped` with the reason.
     * [CN] `tabs` 的页面，每个取自 `lookupOrder`（nil：默认顺序）中第一个有可用页面的来源。有页面的 Tab 加入 `keptTabs`；没有页面的 Tab 被
     *      跳过，并连同原因加入 `skipped`。
     */
    @objc(pagesOfTabs:registry:resolver:lookupOrder:keptTabs:skipped:)
    public class func pages(ofTabs tabs: [Any], registry: CYLTabBarPageProviding?, resolver: ((String, [String: Any]) -> UIViewController?)?,
                            lookupOrder: [String]?, keptTabs: NSMutableArray?, skipped: NSMutableArray?) -> [UIViewController] {
        let order = lookupOrder.flatMap { $0.isEmpty ? nil : $0 } ?? defaultPageLookupOrder
        var pages: [UIViewController] = []
        func skip(_ reason: CYLTabBarPageSkipReason, _ pageIdentifier: String?, _ attributes: [String: Any]?, _ detail: String?) {
            let skippedTab = CYLTabBarSkippedTab(reason: reason, pageIdentifier: pageIdentifier, attributes: attributes, detail: detail)
            skipped?.add(skippedTab)
            CYLTabBarPageValues.log("🔴 CYLTabBarController: the tab is skipped: \(skippedTab). Register the ID with CYLTabBarPageRegistry or adopt CYLTabBarPage.")
        }
        for tab in tabs {
            guard let tabDictionary = tab as? NSDictionary, let attributes = tabDictionary as? [String: Any] else {
                skip(.invalidTab, nil, nil, "not a dictionary: \(tab)")
                continue
            }
            guard let pageIdentifier = pageIdentifier(ofTab: attributes) else {
                skip(.missingIdentifier, nil, attributes, nil)
                continue
            }
            var page: UIViewController?
            var problems: [String] = []
            var found = false
            for source in order {
                var provider: CYLTabBarPageTypes.Provider?
                var sourceName = source
                switch source {
                case CYLTabBarPageSourceInstanceRegistry:
                    provider = registry?.pageProvider(forPageIdentifier: pageIdentifier)
                    sourceName = "CYLTabBarControllerPageRegistry"
                case CYLTabBarPageSourceResolver:
                    provider = resolver
                    sourceName = "CYLTabBarControllerPageResolver"
                case CYLTabBarPageSourceSharedRegistry:
                    provider = shared.pageProvider(forPageIdentifier: pageIdentifier)
                    sourceName = "sharedRegistry"
                case CYLTabBarPageSourceAutomaticRegistration:
                    if let pageClass = automaticallyRegisteredPageClasses[pageIdentifier] {
                        provider = Self.provider(ofClass: pageClass)
                        sourceName = NSStringFromClass(pageClass)
                    }
                default:
                    break
                }
                guard let provider else { continue }
                found = true
                let (made, problem) = call(provider, pageIdentifier, attributes, usedPages: pages, source: sourceName)
                if let made {
                    page = made
                    break
                }
                if let problem {
                    problems.append(problem)
                }
            }
            guard let page else {
                skip(found ? .providerFailed : .unregistered, pageIdentifier, attributes, problems.isEmpty ? nil : problems.joined(separator: "; "))
                continue
            }
            let content = (page as? UINavigationController)?.viewControllers.first ?? page
            if let title = attributes[CYLTabBarItemTitle] as? String, content.navigationItem.title == nil {
                content.navigationItem.title = title
            }
            pages.append(page)
            // [EN] The same dictionary object, not a Swift copy: the caller matches the kept tabs with its own by identity.
            // [CN] 放入同一个字典对象，而不是 Swift 副本：调用方按对象标识把保留的 Tab 与自己的 Tab 对应起来。
            keptTabs?.add(tabDictionary)
        }
        return pages
    }
}
