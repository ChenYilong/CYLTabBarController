//
//  UIControl+CYLTabBarItemAnimation.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/**
 * [EN] The tab item animation core: the animation library service, the host the tab bar offers it, the attribute helpers
 *      and the `UIControl` / `UIView` / `CYLTabBar` entry points. Translated from Objective-C (docs/Swift-Migration.md,
 *      branch swift-core); `CYLTabBarItemAnimationURLFromAttributes()` stays Objective-C until `CYLConstants` moves, as it
 *      registers dark styles through functions declared only in private headers. The C functions keep their names (`@_cdecl`): Objective-C and Swift callers keep using the
 *      declarations of `CYLTabBarController.h` and `CYLTabBarItemAnimationService.h`.
 * [CN] TabBarItem 动画核心：动画库服务、TabBar 提供给它的宿主、属性辅助函数，以及 `UIControl` / `UIView` / `CYLTabBar` 的入口。
 *      已从 Objective-C 翻译（docs/Swift-Migration.md，swift-core 分支）。C 函数保留原名（`@_cdecl`）：Objective-C 与 Swift 调用方继续使用
 *      `CYLTabBarController.h` 与 `CYLTabBarItemAnimationService.h` 中的声明。
 */
enum CYLTabBarItemAnimationCore {

    private static let lock = NSLock()
    private static var currentService: CYLTabBarItemAnimationService?

    static var service: CYLTabBarItemAnimationService? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return currentService
        }
        set {
            lock.lock()
            currentService = newValue
            lock.unlock()
        }
    }

    static let host = CYLTabBarItemAnimationCoreHost()

    /**
     * [EN] `attributes` with a file of `fileType` added to each item: its path under `filePathKey`, and the path of the
     *      `cyl_darkImageNameSuffix` variant under `darkFilePathKey` when it exists.
     * [CN] 为每个 item 添加 `fileType` 类型文件后的 `attributes`：路径写入 `filePathKey`，存在 `cyl_darkImageNameSuffix` 变体时其路径写入
     *      `darkFilePathKey`。
     */
    static func attributes(_ attributes: [[AnyHashable: Any]], addingFiles fileNames: [Any], bundle: Bundle?,
                           fileType: String, filePathKey: String, darkFilePathKey: String) -> [[AnyHashable: Any]] {
        if fileNames.isEmpty {
            return attributes
        }
        let bundle = bundle ?? Bundle.main
        let darkSuffix = UIImage.cyl_darkImageNameSuffix ?? ""
        return attributes.enumerated().map { index, item in
            guard index < fileNames.count, let name = fileNames[index] as? String, !name.isEmpty,
                  let path = bundle.path(forResource: name, ofType: fileType) else {
                return item
            }
            var animated = item
            animated[filePathKey] = path
            if !darkSuffix.isEmpty, let darkPath = bundle.path(forResource: name + darkSuffix, ofType: fileType) {
                animated[darkFilePathKey] = darkPath
            }
            return animated
        }
    }

    /**
     * [EN] The value of a generic animation key in `attributes`, else of the library's own key for it.
     * [CN] `attributes` 中通用动画键的值；没有时取动画库对应自身键的值。
     */
    static func attributesAnimationValue(_ attributes: [AnyHashable: Any]?, _ genericKey: String) -> Any? {
        guard let attributes, !genericKey.isEmpty else {
            return nil
        }
        if let value = attributes[genericKey] {
            return value
        }
        return service?.attributeKey(forGenericKey: genericKey, inAttributes: attributes).flatMap { attributes[$0] }
    }
}

/**
 * [EN] The host the tab bar offers an animation library (internal; public only for the generated header).
 * [CN] TabBar 提供给动画库的宿主（内部使用；为了生成的头文件而声明为 public）。
 */
@objc(CYLTabBarItemAnimationCoreHost)
public final class CYLTabBarItemAnimationCoreHost: NSObject, CYLTabBarItemAnimationHost {

    public func isPlusControl(_ control: UIControl) -> Bool {
        control.cyl_isPlusControl()
    }

    public func isAnimationView(_ animationView: UIView?, readyIn control: UIControl) -> Bool {
        if let tabBarController = control.cyl_tabBarController, tabBarController.tabBarItemAnimationURLs.count > 0 {
            return tabBarController.isTabBarItemAnimationViewAdded
        }
        return (animationView?.frame.size.width ?? 0) > 10
    }

    public func defaultAnimationSize() -> CGSize {
        CGSize(width: CYLTabBarItemImagePlaceholderWidth, height: CYLTabBarItemImagePlaceholderHeight)
    }

    public func showAnimationView(_ animationView: UIView, in control: UIControl) {
        control.cyl_replaceTabImageView(withNewView: animationView, show: true)
    }

    public func replaceTrackedSubview(_ view: UIView, with newView: UIView, inSuperview superview: UIView) {
        // [EN] Seam: `-[UIView cyl_replaceTrackedSubview:withView:]` is declared only in a private header.
        // [CN] 接缝：`-[UIView cyl_replaceTrackedSubview:withView:]` 只在私有头文件中声明。
        let selector = NSSelectorFromString("cyl_replaceTrackedSubview:withView:")
        if superview.responds(to: selector) {
            superview.perform(selector, with: view, with: newView)
        }
    }

    public func animationViewDidAdd(in control: UIControl) {
        NotificationCenter.default.post(name: .CYLTabBarItemAnimationViewDidAdd, object: control)
    }

    public func animationWillPlay(in control: UIControl) {
        NotificationCenter.default.post(name: .CYLTabBarItemAnimationPlaying, object: control)
    }
}

// MARK: - The C entry points (declared in CYLTabBarItemAnimationService.h, UIControl+CYLTabBarItemAnimation.h, CYLTabBarController.h)

@_cdecl("CYLTabBarItemAnimationSetService")
public func cylTabBarItemAnimationSetServiceEntryPoint(_ service: CYLTabBarItemAnimationService?) {
    CYLTabBarItemAnimationCore.service = service
}

@_cdecl("CYLTabBarItemAnimationGetService")
public func cylTabBarItemAnimationGetServiceEntryPoint() -> CYLTabBarItemAnimationService? {
    CYLTabBarItemAnimationCore.service
}

@_cdecl("CYLTabBarItemAnimationDefaultHost")
public func cylTabBarItemAnimationDefaultHostEntryPoint() -> CYLTabBarItemAnimationHost {
    CYLTabBarItemAnimationCore.host
}

@_cdecl("CYLTabBarItemAttributesAnimationValue")
public func cylTabBarItemAttributesAnimationValueEntryPoint(_ attributes: NSDictionary?, _ genericKey: NSString) -> Any? {
    CYLTabBarItemAnimationCore.attributesAnimationValue(attributes as? [AnyHashable: Any], genericKey as String)
}

@_cdecl("CYLTabBarItemsAttributesAddingLottieFiles")
public func cylTabBarItemsAttributesAddingLottieFilesEntryPoint(_ attributes: NSArray, _ lottieFileNames: NSArray,
                                                                _ bundle: Bundle?) -> NSArray {
    let items = attributes.compactMap { $0 as? [AnyHashable: Any] }
    return CYLTabBarItemAnimationCore.attributes(items, addingFiles: lottieFileNames as? [Any] ?? [], bundle: bundle,
                                                 fileType: "json", filePathKey: "CYLTabBarLottieFilePath" /* CYLTabBarLottieFilePath, deprecated without Lottie */,
                                                 darkFilePathKey: "CYLTabBarLottieDarkFilePath" /* CYLTabBarLottieDarkFilePath, deprecated without Lottie */) as NSArray
}

@_cdecl("CYLTabBarAnimationURLWithOptions")
public func cylTabBarAnimationURLWithOptionsEntryPoint(_ fileURL: NSURL?, _ options: NSDictionary?) -> NSURL? {
    guard let fileURL = fileURL as URL?, var components = URLComponents(url: fileURL, resolvingAgainstBaseURL: true) else {
        return nil
    }
    var allowed = CharacterSet.urlQueryAllowed
    allowed.remove(charactersIn: "&=+#?")
    var values: [String: String] = [:]
    for case let (name as String, value as String) in options ?? [:] where !name.isEmpty && !value.isEmpty {
        values[name] = value
    }
    let items: [String] = values.keys.sorted().compactMap { name in
        guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: allowed), !encodedName.isEmpty,
              let encodedValue = values[name]?.addingPercentEncoding(withAllowedCharacters: allowed), !encodedValue.isEmpty else {
            return nil
        }
        return "\(encodedName)=\(encodedValue)"
    }
    components.percentEncodedFragment = items.isEmpty ? nil : items.joined(separator: "&")
    return components.url as NSURL?
}

@_cdecl("CYLTabBarItemAttributesAddingAnimationFile")
public func cylTabBarItemAttributesAddingAnimationFileEntryPoint(_ attributes: NSDictionary, _ fileName: NSString,
                                                                 _ bundle: Bundle?) -> NSDictionary {
    let name = fileName as String
    guard let item = attributes as? [AnyHashable: Any], !name.isEmpty else {
        return attributes
    }
    let bundle = bundle ?? Bundle.main
    let extensions = CYLTabBarItemAnimationCore.service?.animationFileExtensions?() ?? []
    let fileExtension = (name as NSString).pathExtension.lowercased()
    var resourceName = name
    var fileType: String?
    if !fileExtension.isEmpty && extensions.contains(fileExtension) {
        resourceName = (name as NSString).deletingPathExtension
        fileType = fileExtension
    } else {
        fileType = extensions.first { bundle.path(forResource: name, ofType: $0) != nil }
    }
    guard let fileType else {
        return attributes
    }
    let result = CYLTabBarItemAnimationCore.attributes([item], addingFiles: [resourceName], bundle: bundle, fileType: fileType,
                                                       filePathKey: CYLTabBarAnimationFilePath,
                                                       darkFilePathKey: CYLTabBarAnimationDarkFilePath)
    return (result.first ?? item) as NSDictionary
}

@_cdecl("CYLTabBarItemsAttributesAddingAnimationFiles")
public func cylTabBarItemsAttributesAddingAnimationFilesEntryPoint(_ attributes: NSArray, _ fileNames: NSArray,
                                                                   _ bundle: Bundle?) -> NSArray {
    attributes.enumerated().map { index, element -> Any in
        guard let item = element as? NSDictionary, index < fileNames.count, let fileName = fileNames[index] as? NSString else {
            return element
        }
        return cylTabBarItemAttributesAddingAnimationFileEntryPoint(item, fileName, bundle)
    } as NSArray
}

// MARK: - Categories

/**
 * [EN] Tab item animations in a tab button, through the animation library service.
 * [CN] 通过动画库服务在 Tab 按钮中使用 TabBarItem 动画。
 */
extension UIControl {

    /**
     * [EN] The animation view in this control.
     * [CN] 本控件中的动画视图。
     */
    @objc(cyl_tabBarItemAnimationView)
    public func cyl_tabBarItemAnimationView() -> UIView? {
        CYLTabBarItemAnimationCore.service?.animationView(in: self)
    }

    /**
     * [EN] Whether the animation of this control is loaded.
     * [CN] 本控件的动画是否已加载。
     */
    @objc(cyl_isTabBarItemAnimationReady)
    public func cyl_isTabBarItemAnimationReady() -> Bool {
        if let service = CYLTabBarItemAnimationCore.service {
            return service.isAnimationReady(in: self)
        }
        guard let tabBarController = cyl_tabBarController else {
            return false
        }
        return tabBarController.tabBarItemAnimationURLs.count > 0 && tabBarController.isTabBarItemAnimationViewAdded
    }

    /**
     * [EN] Adds the animation at `URL` to this control.
     * [CN] 向本控件添加 `URL` 处的动画。
     */
    @objc(cyl_addTabBarItemAnimationWithURL:size:contentMode:)
    public func cyl_addTabBarItemAnimation(with URL: URL?, size: CGSize, contentMode: UIView.ContentMode) {
        CYLTabBarItemAnimationCore.service?.addAnimation(with: URL, size: size, contentMode: contentMode, animationSpeed: 0, to: self)
    }

    /**
     * [EN] Adds the animation at `URL` to this control with a speed.
     * [CN] 以指定速度向本控件添加 `URL` 处的动画。
     */
    @objc(cyl_addTabBarItemAnimationWithURL:size:contentMode:animationSpeed:)
    public func cyl_addTabBarItemAnimation(with URL: URL?, size: CGSize, contentMode: UIView.ContentMode,
                                           animationSpeed: CGFloat) {
        CYLTabBarItemAnimationCore.service?.addAnimation(with: URL, size: size, contentMode: contentMode,
                                                         animationSpeed: animationSpeed, to: self)
    }

    /**
     * [EN] Changes the speed of this control's animation.
     * [CN] 修改本控件动画的速度。
     */
    @objc(cyl_setTabBarItemAnimationSpeed:)
    public func cyl_setTabBarItemAnimationSpeed(_ animationSpeed: CGFloat) {
        CYLTabBarItemAnimationCore.service?.setAnimationSpeed(animationSpeed, in: self)
    }

    /**
     * [EN] Makes this control's animation repeat (`loops`) or play once, applied to the animation already playing.
     * [CN] 让本控件的动画循环播放（`loops`）或只播放一次，对正在播放的动画立即生效。
     */
    @objc(cyl_setTabBarItemAnimationLoops:)
    public func cyl_setTabBarItemAnimationLoops(_ loops: Bool) {
        CYLTabBarItemAnimationCore.service?.setAnimationLoops?(loops, in: self)
    }

    /**
     * [EN] Plays this control's animation once more from progress 0, without resetting the other tabs.
     * [CN] 从进度 0 重新播放本控件的动画，不重置其他 Tab。
     */
    @objc(cyl_restartTabBarItemAnimation)
    public func cyl_restartTabBarItemAnimation() {
        CYLTabBarItemAnimationCore.service?.restartAnimation?(in: self)
    }

    /**
     * [EN] Reloads this control's animation for the current light / dark style.
     * [CN] 按当前浅色/深色风格重新加载本控件的动画。
     */
    @objc(cyl_reloadTabBarItemAnimationViewForCurrentStyle)
    public func cyl_reloadTabBarItemAnimationViewForCurrentStyle() {
        CYLTabBarItemAnimationCore.service?.reloadAnimationForCurrentStyle(in: self)
    }

    /**
     * [EN] Replaces this control's animation with the one at `URL`.
     * [CN] 用 `URL` 处的动画替换本控件的动画。
     */
    @objc(cyl_replaceTabBarItemAnimationWithURL:size:contentMode:)
    public func cyl_replaceTabBarItemAnimation(with URL: URL, size: CGSize, contentMode: UIView.ContentMode) {
        guard let service = CYLTabBarItemAnimationCore.service else {
            return
        }
        if service.responds(to: #selector(CYLTabBarItemAnimationService.replaceAnimation(with:size:contentMode:in:))) {
            service.replaceAnimation?(with: URL, size: size, contentMode: contentMode, in: self)
        } else {
            service.addAnimation(with: URL, size: size, contentMode: contentMode, animationSpeed: 0, to: self)
        }
    }

    /**
     * [EN] Applies the current colors to this control's animation.
     * [CN] 将当前颜色应用到本控件的动画。
     */
    @objc(cyl_refreshTabBarItemAnimationColors)
    public func cyl_refreshTabBarItemAnimationColors() {
        CYLTabBarItemAnimationCore.service?.refreshAnimationColors?(in: self)
    }

    /**
     * [EN] Plays the animation at `URL` in this control.
     * [CN] 在本控件中播放 `URL` 处的动画。
     */
    @objc(cyl_playTabBarItemAnimationWithURL:size:defaultSelected:contentMode:)
    public func cyl_playTabBarItemAnimation(with URL: URL, size: CGSize, defaultSelected: Bool,
                                            contentMode: UIView.ContentMode) {
        CYLTabBarItemAnimationCore.service?.playAnimation(with: URL, size: size, defaultSelected: defaultSelected,
                                                          contentMode: contentMode, in: self)
    }

    /**
     * [EN] Stops this control's animation.
     * [CN] 停止本控件的动画。
     */
    @objc(cyl_stopTabBarItemAnimation)
    public func cyl_stopTabBarItemAnimation() {
        CYLTabBarItemAnimationCore.service?.stopAnimation(in: self)
    }
}

extension UIView {

    /**
     * [EN] Whether this view is an animation view of the animation library (internal).
     * [CN] 本视图是否为动画库的动画视图（内部使用）。
     */
    @objc(cyl_isTabBarItemAnimationView)
    public func cyl_isTabBarItemAnimationView() -> Bool {
        CYLTabBarItemAnimationCore.service?.isAnimationView(self) ?? false
    }
}
