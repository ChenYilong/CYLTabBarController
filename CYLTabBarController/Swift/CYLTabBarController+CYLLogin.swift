//
//  CYLTabBarController+CYLLogin.swift
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
 * [EN] The login settings of a tab bar controller (issue #19), kept in one object that is attached to it: the login state
 *      provider, the identifiers and the block that tell which tabs need login, and the handler that shows the login screen.
 * [CN] TabBarController 的登录设置（issue #19），保存在附加到它的一个对象中：登录状态提供者、判断哪些 Tab 需要登录的标识与 block，以及展示
 *      登录界面的处理器。
 */
final class CYLLoginSettings: NSObject {
    var stateProvider: (@convention(block) () -> Bool)?
    var requiredIdentifiers: [String]?
    var requiredBlock: (@convention(block) (CYLTabBarController, UIViewController) -> Bool)?
    var handler: (@convention(block) (CYLTabBarController, UIViewController, @escaping CYLTabBarLoginCompletion) -> Void)?
    /// [EN] The page whose login started in the current run loop turn. [CN] 在当前 runloop 中已发起登录的页面。
    weak var interceptedViewController: UIViewController?
}

enum CYLLoginKeys {
    static let settings = CYLUtilsKeys.key("cyl_loginSettings")
    static let loggedInDefaultsKey = "CYLTabBarControllerLoggedIn"
}

/**
 * [EN] `CYLTabBarController (CYLLogin)`: tabs that require login (issue #19). Translated from Objective-C
 *      (docs/Swift-Migration.md, step 37). `CYLTabBarController` is still an Objective-C class, so its category stays
 *      declared in `CYLTabBarController.h` and these members are internal `@objc` methods with the declared selectors (a public
 *      Swift extension of it would be emitted before the class in the generated header).
 * [CN] `CYLTabBarController (CYLLogin)`：需要登录的 Tab（issue #19）。已从 Objective-C 翻译（docs/Swift-Migration.md，第 37 步）。
 *      `CYLTabBarController` 仍是 Objective-C 类，因此其分类仍声明在 `CYLTabBarController.h` 中，这些成员是使用已声明 selector 的 internal `@objc`
 *      方法（对它的 public Swift extension 会在生成的头文件中出现在该类之前）。
 */
extension CYLTabBarController {

    private var cyl_loginSettings: CYLLoginSettings {
        if let settings = objc_getAssociatedObject(self, CYLLoginKeys.settings) as? CYLLoginSettings {
            return settings
        }
        let settings = CYLLoginSettings()
        objc_setAssociatedObject(self, CYLLoginKeys.settings, settings, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return settings
    }

    @objc(cyl_loggedIn)
    open var cyl_loggedIn: Bool {
        @objc(cyl_loggedIn) get { cylLoggedIn() }
        @objc(cyl_setLoggedIn:) set { cylSetLoggedIn(newValue) }
    }

    /**
     * [EN] The cached login state, or the app's own when it set a state provider. [CN] 缓存的登录状态；设置了状态提供者时为 App 自己的状态。
     */
    func cylLoggedIn() -> Bool {
        if let provider = cyl_loginSettings.stateProvider {
            return provider()
        }
        return UserDefaults.standard.bool(forKey: CYLLoginKeys.loggedInDefaultsKey)
    }

    /**
     * [EN] Caches the login state, leaves a tab that needs login on logout, and posts the state change notification.
     * [CN] 缓存登录状态；退出登录时离开需要登录的 Tab；并发送状态变化通知。
     */
    func cylSetLoggedIn(_ loggedIn: Bool) {
        UserDefaults.standard.set(loggedIn, forKey: CYLLoginKeys.loggedInDefaultsKey)
        if !loggedIn {
            leaveTabRequiringLoginIfNeeded()
        }
        NotificationCenter.default.post(name: .cylTabBarLoginStateDidChange, object: self)
    }

    @objc(cyl_loginStateProvider)
    open var cyl_loginStateProvider: (() -> Bool)? {
        @objc(cyl_loginStateProvider) get { cyl_loginSettings.stateProvider }
        @objc(cyl_setLoginStateProvider:) set { cyl_loginSettings.stateProvider = newValue }
    }

    @objc(cyl_loginRequiredTabBarItemIdentifiers)
    open var cyl_loginRequiredTabBarItemIdentifiers: [String]? {
        @objc(cyl_loginRequiredTabBarItemIdentifiers) get { cylLoginRequiredTabBarItemIdentifiers() }
        @objc(cyl_setLoginRequiredTabBarItemIdentifiers:) set { cylSetLoginRequiredTabBarItemIdentifiers(newValue) }
    }

    func cylLoginRequiredTabBarItemIdentifiers() -> [String]? {
        cyl_loginSettings.requiredIdentifiers
    }

    func cylSetLoginRequiredTabBarItemIdentifiers(_ identifiers: [String]?) {
        cyl_loginSettings.requiredIdentifiers = identifiers
    }

    @objc(cyl_loginRequiredBlock)
    open var cyl_loginRequiredBlock: ((CYLTabBarController, UIViewController) -> Bool)? {
        @objc(cyl_loginRequiredBlock) get { cyl_loginSettings.requiredBlock }
        @objc(cyl_setLoginRequiredBlock:) set { cyl_loginSettings.requiredBlock = newValue }
    }

    @objc(cyl_loginHandler)
    open var cyl_loginHandler: ((CYLTabBarController, UIViewController, @escaping CYLTabBarLoginCompletion) -> Void)? {
        @objc(cyl_loginHandler) get { cyl_loginSettings.handler }
        @objc(cyl_setLoginHandler:) set { cyl_loginSettings.handler = newValue }
    }

    /**
     * [EN] Whether selecting `viewController` needs login: the required block, else the delegate, else the identifiers.
     * [CN] 选中 `viewController` 是否需要登录：依次取 required block、代理、标识列表。
     */
    @objc(cyl_isLoginRequiredForViewController:)
    open func cyl_isLoginRequired(for viewController: UIViewController) -> Bool {
        guard !viewController.cyl_isPlaceholder else { return false }
        if let block = cyl_loginSettings.requiredBlock {
            return block(self, viewController)
        }
        let delegate = cylDelegate
        if let required = delegate?.tabBarController?(self, requiresLoginToSelect: viewController) {
            return required
        }
        let identifier = viewController.cyl_tabBarItemIdentifier ?? ""
        return !identifier.isEmpty && (cyl_loginSettings.requiredIdentifiers?.contains(identifier) ?? false)
    }

    /**
     * [EN] When `viewController` needs login and the user is logged out, starts the login and returns YES (the tab is not
     *      selected). One tap reaches here up to twice (`-tabBarController:shouldSelectViewController:`, then the tab button's
     *      action): the login starts once per run loop turn.
     * [CN] `viewController` 需要登录且用户未登录时，发起登录并返回 YES（不选中该 Tab）。一次点击最多到达这里两次
     *      （`-tabBarController:shouldSelectViewController:`，然后是 Tab 按钮的 action）：每个 runloop 只发起一次登录。
     */
    @objc(cyl_interceptLoginIfNeededForViewController:)
    open func cyl_interceptLoginIfNeeded(for viewController: UIViewController) -> Bool {
        guard cyl_isLoginRequired(for: viewController), !cylLoggedIn() else { return false }
        let settings = cyl_loginSettings
        if settings.interceptedViewController === viewController {
            return true
        }
        settings.interceptedViewController = viewController
        DispatchQueue.main.async { [weak settings] in
            settings?.interceptedViewController = nil
        }
        startLogin(for: viewController)
        return true
    }

    private func startLogin(for viewController: UIViewController) {
        var completed = false
        let completion: CYLTabBarLoginCompletion = { [weak self, weak viewController] loggedIn in
            let finish = {
                // [EN] Only the first call counts. [CN] 只有第一次调用有效。
                if completed {
                    return
                }
                completed = true
                guard let self, loggedIn else { return }
                self.cylSetLoggedIn(true)
                if let viewController, let index = self.viewControllers?.firstIndex(of: viewController) {
                    self.selectedIndex = index
                }
            }
            if Thread.isMainThread {
                finish()
            } else {
                DispatchQueue.main.async(execute: finish)
            }
        }
        if let handler = cyl_loginSettings.handler {
            handler(self, viewController, completion)
            return
        }
        let delegate = cylDelegate
        if let present = delegate?.tabBarController?(self, presentLoginFor: viewController, completion: completion) {
            return present
        }
#if DEBUG
        NSLog(cylLocalizedString("🔴类名与方法名：%@（在第%@行）, 描述：%@"), "\(type(of: self)) \(#function)" as NSString, "\(#line)" as NSString,
              cylLocalizedString("需要登录的 Tab 被点击，但没有设置 cyl_loginHandler 或代理方法 -tabBarController:presentLoginForViewController:completion:。") as NSString)
#endif
    }

    /**
     * [EN] Logged out on a tab that needs login: select the first tab that does not. [CN] 在需要登录的 Tab 上退出登录：切换到第一个不需要登录的 Tab。
     */
    private func leaveTabRequiringLoginIfNeeded() {
        guard let selected = selectedViewController, cyl_isLoginRequired(for: selected) else { return }
        if let index = (viewControllers ?? []).firstIndex(where: { !$0.cyl_isPlaceholder && !cyl_isLoginRequired(for: $0) }) {
            selectedIndex = index
        }
    }
}
