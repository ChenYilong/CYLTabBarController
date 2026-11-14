//
//  CYLTabBarHostView.swift
//  CYLTabBarController
//
//  v1.100.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 2026/11/08.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import ObjectiveC
import UIKit

/**
 * [EN] Helpers of `CYLTabBarHostView`: colors, badge animations, and what the host view shows as a badge. Translated from
 *      Objective-C (docs/Swift-Migration.md, step 36).
 * [CN] `CYLTabBarHostView` 的辅助函数：颜色、角标动画，以及宿主视图显示的角标。已从 Objective-C 翻译（docs/Swift-Migration.md，第 36 步）。
 */
enum CYLTabBarHostSupport {

    /**
     * [EN] The room left above the icons for a badge. [CN] 图标上方为角标留出的空间。
     */
    static let badgeRoom: CGFloat = 8

    /**
     * [EN] The pages of the configuration's tabs, in order, without the plus button's own page and placeholders.
     * [CN] 配置中各 Tab 的页面，按顺序，不含 PlusButton 自己的页面与占位页面。
     */
    static func pages(of tabBarController: UITabBarController?) -> [UIViewController] {
        // [EN] The plus button's own page is not one of the configuration's tabs. [CN] PlusButton 自己的页面不属于配置中的 Tab。
        let plusPage = (tabBarController as? CYLTabBarController).flatMap {
            CYLPlusButton.plusChildViewController(forTabBarContext: $0.context)
        }
        return (tabBarController?.viewControllers ?? []).filter { !$0.cyl_isPlaceholder && $0 !== plusPage }
    }

    /**
     * [EN] "#RRGGBB" / "#RRGGBBAA" or a UIColor; nil otherwise. [CN] "#RRGGBB" / "#RRGGBBAA" 或 UIColor；其他为 nil。
     */
    static func color(_ value: Any?) -> UIColor? {
        if let color = value as? UIColor {
            return color
        }
        guard let text = value as? String, text.hasPrefix("#") else { return nil }
        let hex = String(text.dropFirst())
        var number: UInt64 = 0
        guard hex.count == 6 || hex.count == 8, Scanner(string: hex).scanHexInt64(&number) else { return nil }
        let alpha = hex.count == 8 ? CGFloat(number & 0xFF) / 255 : 1
        let rgb = hex.count == 8 ? number >> 8 : number
        return UIColor(red: CGFloat((rgb >> 16) & 0xFF) / 255, green: CGFloat((rgb >> 8) & 0xFF) / 255, blue: CGFloat(rgb & 0xFF) / 255, alpha: alpha)
    }

    /**
     * [EN] A `CYLBadgeAnimationType` number or name; `fallback` otherwise. [CN] `CYLBadgeAnimationType` 数字或名称；其他为 `fallback`。
     */
    static func animation(_ value: Any?, fallback: CYLBadgeAnimationType) -> CYLBadgeAnimationType {
        if let number = value as? NSNumber, number.uintValue <= CYLBadgeAnimationType.scaleOnce.rawValue {
            return CYLBadgeAnimationType(rawValue: number.uintValue) ?? fallback
        }
        if let name = (value as? String)?.lowercased() {
            let names = ["none", "scale", "shake", "bounce", "breathe", "leftrightonce", "rightleftonce", "fadeinonce", "rollingonce", "scaleonce"]
            if let index = names.firstIndex(of: name) {
                return CYLBadgeAnimationType(rawValue: UInt(index)) ?? fallback
            }
        }
        return fallback
    }

    /**
     * [EN] Shows the badge `attributes` describe on `target` (a page or the plus button), its style first. A dot animates
     *      only with an animation of its own (`badgeAnimationType` is for text badges), as `cyl_showBadgeValue:@""`.
     * [CN] 在 `target`（页面或 PlusButton）上显示 `attributes` 描述的角标，先设置样式。红点仅在自身指定动画时播放（`badgeAnimationType` 用于
     *      文字角标），与 `cyl_showBadgeValue:@""` 相同。
     */
    static func showBadge(on target: CYLBadgeProtocol, _ attributes: [String: Any], animationType: CYLBadgeAnimationType) {
        let value = attributes[CYLTabBarHostBadgeValue]
        let text = (value as? String) ?? (value as? NSNumber)?.stringValue ?? ""
        if let color = color(attributes[CYLTabBarHostBadgeColor]) {
            target.cyl_badgeBackgroundColor = color
        }
        if let radius = attributes[CYLTabBarHostBadgeRadius] as? NSNumber {
            target.cyl_badgeRadius = CGFloat(radius.doubleValue)
        }
        let offset = attributes[CYLTabBarHostBadgeCenterOffset]
        if let pair = offset as? [Any], pair.count == 2 {
            target.cyl_badgeCenterOffset = CGPoint(x: (pair[0] as? NSNumber)?.doubleValue ?? 0, y: (pair[1] as? NSNumber)?.doubleValue ?? 0)
        } else if let point = offset as? NSValue, String(cString: point.objCType) == String(cString: NSValue(cgPoint: .zero).objCType) {
            target.cyl_badgeCenterOffset = point.cgPointValue
        }
        let animation = animation(attributes[CYLTabBarHostBadgeAnimation], fallback: animationType)
        if text.isEmpty {
            target.cyl_clearBadge()
        } else if text == "dot" {
            if attributes[CYLTabBarHostBadgeAnimation] == nil || animation == .none {
                target.cyl_showBadge()
            } else {
                target.cyl_showBadgeValue("", animationType: animation)
            }
        } else {
            target.cyl_showBadgeValue(text, animationType: animation)
        }
    }

    /**
     * [EN] An image loaded from a value (a file, an asset, a URL) is drawn as is, as an image name or a path in a configuration
     *      (#535): left automatic, the tab bar drew a full color icon as a gray template silhouette.
     * [CN] 由值（文件、asset、URL）加载的图片按原图绘制，与配置中的图片名或路径相同（#535）：保持 automatic 时，TabBar 会把全彩图标画成灰色模板剪影。
     */
    static func original(_ image: UIImage) -> UIImage {
        image.renderingMode == .automatic ? image.withRenderingMode(.alwaysOriginal) : image
    }

    /**
     * [EN] Rects contain `point`. [CN] 矩形中是否有包含 `point` 的。
     */
    static func rects(_ rects: [NSValue], contain point: CGPoint) -> Bool {
        rects.contains { $0.cgRectValue.contains(point) }
    }

    /**
     * [EN] The selectors of `UITabBarControllerDelegate` and `CYLTabBarControllerDelegate`: those the host does not handle
     *      itself go to the controller, so it keeps its own behavior.
     * [CN] `UITabBarControllerDelegate` 与 `CYLTabBarControllerDelegate` 的 selector：宿主未处理的交给 controller，使其保留自身行为。
     */
    static func isDelegateSelector(_ selector: Selector) -> Bool {
        let protocols = ["UITabBarControllerDelegate", "CYLTabBarControllerDelegate"].compactMap { NSProtocolFromString($0) }
        return protocols.contains { protocolObject in
            [false, true].contains { isRequired in protocol_getMethodDescription(protocolObject, selector, isRequired, true).name != nil }
        }
    }

    /**
     * [EN] Adds the FlatDesign delegate protocol to the class when that subspec is built, as the Objective-C class adopted it
     *      under `CYL_FLATDESIGN_AVAILABLE`; Core Swift cannot name it. Once.
     * [CN] 构建了扁平样式子库时，把其 delegate 协议加入该类（Objective-C 类在 `CYL_FLATDESIGN_AVAILABLE` 下遵循它）；Core 的 Swift 代码无法
     *      直接引用它。只执行一次。
     */
    static let adoptFlatDesignDelegate: Void = {
        if let flatProtocol = NSProtocolFromString("CYLFlatDesignUITabBarControllerDelegate") {
            class_addProtocol(CYLTabBarHostView.self, flatProtocol)
        }
    }()
}

/**
 * [EN] A tab bar for hosts that draw their own pages (React Native, Flutter): a view that holds a CYLTabBarController built
 *      from a configuration dictionary, with the pages left to the host (docs/Cross-Platform-Components.md). The delegate
 *      methods the host view does not handle go to the controller.
 * [CN] 供自行绘制页面的宿主（React Native、Flutter）使用的 TabBar：一个持有由配置字典创建的 CYLTabBarController 的视图，页面交给宿主
 *      （docs/Cross-Platform-Components.md）。宿主视图未处理的 delegate 方法交给 controller。
 */
@objc(CYLTabBarHostView)
open class CYLTabBarHostView: UIView {

    /**
     * [EN] The configuration; images are loaded off the main queue, and the controller is built once there is a window and
     *      a width. A newer configuration drops the result of an older, slower one. nil removes the controller.
     * [CN] 配置；图片在主队列之外加载，有 window 和宽度后创建 controller。较新的配置会丢弃较旧、较慢配置的结果。设为 nil 则移除 controller。
     */
    @objc open var configuration: [String: Any]? {
        didSet {
            generation += 1
            pendingConfiguration = nil
            guard let source = configuration else {
                removeTabBarController()
                return
            }
            let generation = generation
            let resolver = imageResolver
            // [EN] Image loads can be slow (a dev server, a big file): never on the main queue. [CN] 图片加载可能较慢（开发服务器、大文件）：不在主队列进行。
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let resolved = CYLTabBarHostView.configuration(withImagesOf: source, resolver: resolver)
                DispatchQueue.main.async {
                    guard let self, generation == self.generation else { return }
                    self.pendingConfiguration = resolved
                    self.buildTabBarControllerIfReady()
                }
            }
        }
    }

    /**
     * [EN] Sets the configuration from a JSON string; NO when it is not a JSON object. [CN] 用 JSON 字符串设置配置；不是 JSON 对象时返回 NO。
     */
    @discardableResult
    @objc open func setConfigurationJSON(_ JSON: String?) -> Bool {
        guard let data = JSON?.data(using: .utf8), !data.isEmpty,
              let parsed = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
            return false
        }
        configuration = parsed
        return true
    }

    /**
     * [EN] Loads an image the host knows (an asset, a dev server) from the value in the configuration; called off the main queue.
     * [CN] 由宿主按配置中的值加载其自己的图片（asset、开发服务器）；在主队列之外调用。
     */
    @objc open var imageResolver: ((Any) -> UIImage?)?

    @objc open var selectedIndex: Int {
        get { currentSelectedIndex }
        set {
            currentSelectedIndex = newValue
            applySelectedIndex()
        }
    }

    /**
     * [EN] The badge text of each tab. [CN] 每个 Tab 的角标文字。
     */
    @objc open var badgeValues: [String] = [] {
        didSet { applyBadgeValues() }
    }

    @objc open var plusButtonBadgeValue: String? {
        didSet { applyBadgeValues() }
    }

    /**
     * [EN] A `CYLBadgeAnimationType` raw value. [CN] `CYLBadgeAnimationType` 的原始值。
     */
    @objc open var badgeAnimationType = 0

    @objc open var badgeAttributes: [Any]? {
        didSet { applyBadgeValues() }
    }

    @objc open var plusButtonBadgeAttributes: [String: Any]? {
        didSet { applyBadgeValues() }
    }

    /**
     * [EN] An image per tab covering its button (a value, as in the configuration). [CN] 每个 Tab 覆盖其按钮的图片（与配置中相同的值）。
     */
    @objc open var tabCoverImages: [Any]? {
        didSet {
            let values = tabCoverImages ?? []
            let resolver = imageResolver
            coverGeneration += 1
            let generation = coverGeneration
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let images: [Any] = values.map { value in
                    var image = CYLTabBarHostView.image(forValue: value, resolver: resolver)
                    if let name = image as? String {
                        image = UIImage(named: name) as Any
                    }
                    return image is UIImage ? image : NSNull()
                }
                DispatchQueue.main.async {
                    guard let self, generation == self.coverGeneration else { return }
                    self.loadedTabCoverImages = images
                    self.applyTabCoverImages()
                }
            }
        }
    }

    /**
     * [EN] YES: the height includes what rises above the bar (the plus button, the badges); a touch in the transparent strip
     *      away from them goes to the views below.
     * [CN] YES：高度包含高出 TabBar 的部分（PlusButton、角标）；落在远离它们的透明区域的触摸交给下方的视图。
     */
    @objc open var heightIncludesOverflow = false

    @objc open private(set) var preferredHeight: CGFloat = 0

    @objc open var didSelectTab: ((Int, String) -> Void)?
    @objc open var didLongPressTab: ((Int, String, String) -> Void)?

    /**
     * [EN] The app's login state; until it sets one, the cached state of the library is used and reported. [CN] App 的登录状态；
     *      设置之前使用并上报库中缓存的状态。
     */
    @objc open var loggedIn: Bool {
        get { currentLoggedIn }
        set {
            currentLoggedIn = newValue
            loggedInSet = true
            guard let controller = tabBarController, controller.cyl_loggedIn != newValue else { return }
            let pages = CYLTabBarHostSupport.pages(of: controller)
            let before = controller.selectedViewController
            controller.cyl_loggedIn = newValue
            if newValue {
                // [EN] A selection the app set while logged out (it may come before the login state) is applied now.
                // [CN] App 在未登录时设置的选中（可能先于登录状态到达）现在生效。
                applySelectedIndex()
                return
            }
            // [EN] Logging out moved the selection away from a tab that needs login: tell the app.
            // [CN] 退出登录使选中离开了需要登录的 Tab：通知 App。
            let after = controller.selectedViewController
            if after !== before, let after, let index = pages.firstIndex(of: after) {
                currentSelectedIndex = index
                didSelectTab?(index, after.cyl_tabBarItemIdentifier ?? "")
            }
        }
    }

    @objc open var didRequestLogin: ((Int, String, String) -> Void)?
    @objc open var loginStateDidChange: ((Bool) -> Void)?

    @objc open func resetLoggedIn() {
        loggedInSet = false
        currentLoggedIn = false
    }

    @objc open var animationSpeed: CGFloat = 0 {
        didSet {
            if animationSpeed > 0 && animationSpeed.isFinite {
                tabBarController?.tabBarItemAnimationSpeed = animationSpeed
            }
        }
    }

    @objc open var animationLoops = false {
        didSet { tabBarController?.tabBarItemAnimationLoops = animationLoops }
    }

    /**
     * [EN] Plays every tab icon animation from progress 0. [CN] 从进度 0 开始播放每个 Tab 图标的动画。
     */
    @objc open func playAllAnimations() {
        tabBarController?.cyl_playAllTabBarItemAnimations()
    }

    /**
     * [EN] The library's language (`CYLSetLocalizationLanguage`); the controller is built again. [CN] 库的语言
     *      （`CYLSetLocalizationLanguage`）；重新创建 controller。
     */
    @objc open var language: String? {
        didSet {
            guard language != oldValue else { return }
            CYLSetLocalizationLanguage(language)
            // [EN] Built again: the library's texts and the layout direction are set when the tab bar is created.
            // [CN] 重新创建：库的文字与布局方向在创建 TabBar 时设置。
            if tabBarController != nil, let configuration {
                self.configuration = configuration
            }
        }
    }

    @objc open var tabBarHidden = false {
        didSet {
            guard tabBarHidden != oldValue else { return }
            tabBarController?.setTabBarHidden(tabBarHidden, animated: true)
            updateTouchableRects()
        }
    }

    /**
     * [EN] Simulates a memory warning on the controller and returns one line per tab, in the library's language (issue #426).
     * [CN] 对 TabBarController 模拟内存警告，并返回每个 Tab 的结果（每个 Tab 一行），使用库的语言（issue #426）。
     */
    @discardableResult
    @objc open func simulateMemoryWarning() -> String {
        CYLSimulateMemoryWarningReport(tabBarController)
    }

    @objc open var titlePositionAdjustment: NSValue? {
        didSet {
            guard titlePositionAdjustment != oldValue else { return }
            if let titlePositionAdjustment {
                tabBarController?.titlePositionAdjustment = titlePositionAdjustment.uiOffsetValue
            }
        }
    }

    @objc open var didTapPlusButton: (() -> Void)?
    @objc open var preferredHeightDidChange: ((CGFloat) -> Void)?

    /**
     * [EN] The tab bar, and the plus button with its badge, in this view's coordinates. [CN] TabBar，以及 PlusButton 与其角标，本视图坐标。
     */
    @objc open private(set) var touchableRects: [NSValue] = []
    @objc open var touchableRectsDidChange: (([NSValue]) -> Void)?

    @objc open private(set) var tabBarController: CYLTabBarController?

    // MARK: State

    /// [EN] Bumped by every new configuration, so a slow image load of an older one is dropped. [CN] 每份新配置加一，较早配置的慢速图片加载结果会被丢弃。
    private var generation = 0
    /// [EN] The configuration with its images loaded, waiting for a window and a width. [CN] 已加载图片、等待 window 与宽度的配置。
    private var pendingConfiguration: [String: Any]?
    /// [EN] `tabCoverImages` loaded (UIImage or NSNull), and the tab buttons now covered. [CN] 已加载的 `tabCoverImages`（UIImage 或 NSNull），以及当前被覆盖的 Tab 按钮。
    private var loadedTabCoverImages: [Any]?
    private var coveredTabButtons: [(button: UIControl, cover: UIView, selectedCover: UIView)] = []
    private var coverGeneration = 0
    /// [EN] The app set `loggedIn`. [CN] App 设置过 `loggedIn`。
    private var loggedInSet = false
    private var currentLoggedIn = false
    private var currentSelectedIndex = -1

    override public init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        _ = CYLTabBarHostSupport.adoptFlatDesignDelegate
    }

    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        _ = CYLTabBarHostSupport.adoptFlatDesignDelegate
    }

    deinit {
        removeTabBarController()
    }

    // MARK: Images

    /**
     * [EN] The image a value stands for: the host's resolver first, then a URL (a scheme of two letters or more, so "C:" style
     *      paths are not taken for one); the value itself when neither gives an image.
     * [CN] 值所代表的图片：先用宿主的 resolver，再尝试 URL（scheme 至少两个字母）；两者都得不到图片时返回值本身。
     */
    @objc(imageForValue:resolver:)
    class func image(forValue value: Any, resolver: ((Any) -> UIImage?)?) -> Any {
        if let image = resolver?(value) {
            return CYLTabBarHostSupport.original(image)
        }
        guard let text = value as? String, let url = URL(string: text), (url.scheme?.count ?? 0) >= 2 else {
            return value
        }
        let image = (try? Data(contentsOf: url)).flatMap { UIImage(data: $0, scale: UIScreen.main.scale) }
        return image.map(CYLTabBarHostSupport.original) ?? value
    }

    class func attributes(_ attributes: [String: Any], withImagesResolvedBy resolver: ((Any) -> UIImage?)?) -> [String: Any] {
        var result = attributes
        for key in [CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLTabBarItemDarkImage, CYLTabBarItemSelectedDarkImage,
                    CYLPlusButtonBackgroundImage] {
            if let value = result[key] {
                result[key] = image(forValue: value, resolver: resolver)
            }
        }
        return result
    }

    class func configuration(withImagesOf configuration: [String: Any], resolver: ((Any) -> UIImage?)?) -> [String: Any] {
        var result = configuration
        if let items = configuration[CYLTabBarControllerTabBarItemsAttributes] as? [Any] {
            result[CYLTabBarControllerTabBarItemsAttributes] = items.enumerated().map { index, item -> Any in
                guard let dictionary = item as? [String: Any] else { return item }
                var attributes = self.attributes(dictionary, withImagesResolvedBy: resolver)
                // [EN] Pages are looked up by page ID: a tab with neither a page ID nor an identifier would get no page, and no tab.
                //      The host's pages are empty anyway, so it gets one of its own; the identifier reported stays empty.
                // [CN] 页面按页面 ID 查找：既没有页面 ID 也没有 identifier 的 Tab 得不到页面，也就不会显示。宿主的页面本来就是空的，因此为它
                //      指定一个页面 ID；回调中的 identifier 仍为空。
                if ((attributes[CYLTabBarItemPageIdentifier] as? String) ?? "").isEmpty && ((attributes[CYLTabBarItemIdentifier] as? String) ?? "").isEmpty {
                    attributes[CYLTabBarItemPageIdentifier] = "CYLTabBarHostView-tab-\(index)"
                }
                return attributes
            }
        }
        if let plusButton = configuration[CYLTabBarControllerPlusButton] as? [String: Any] {
            result[CYLTabBarControllerPlusButton] = attributes(plusButton, withImagesResolvedBy: resolver)
        }
        return result
    }

    // MARK: The tab bar controller

    override open func didMoveToWindow() {
        super.didMoveToWindow()
        // [EN] Back in a window (a recycled or moved view): rejoin the view controller hierarchy. [CN] 重新进入 window（被复用或移动的视图）：重新加入视图控制器层级。
        if window != nil, let tabBarController, tabBarController.parent == nil {
            let parent = hostViewController
            parent?.addChild(tabBarController)
            tabBarController.didMove(toParent: parent)
        }
        buildTabBarControllerIfReady()
    }

    override open func layoutSubviews() {
        super.layoutSubviews()
        buildTabBarControllerIfReady()
        // [EN] The tab bar is laid out by the controller's view, after this view: lay it out now, or a resize (Flutter sets the
        //      preferred height) leaves `touchableRects` and the height measured on the old frame.
        // [CN] TabBar 由 controller 的视图在本视图之后布局：在这里先完成布局，否则尺寸变化（Flutter 设置所需高度）后，`touchableRects` 与高度
        //      仍按旧 frame 计算。
        tabBarController?.view.layoutIfNeeded()
        updatePreferredHeight()
    }

    private func buildTabBarControllerIfReady() {
        guard var configuration = pendingConfiguration, window != nil, bounds.width > 0 else { return }
        pendingConfiguration = nil
        removeTabBarController()
        // [EN] Every tab bar keeps its own plus button: a context of its own unless the configuration gives one.
        // [CN] 每个 TabBar 保留自己的 PlusButton：配置没有给出 context 时使用自己的 context。
        if !(configuration[CYLTabBarControllerContext] is String) {
            configuration[CYLTabBarControllerContext] = "CYLTabBarHostView-\(Unmanaged.passUnretained(self).toOpaque())"
        }
        // [EN] The pages belong to the host: each tab gets an empty, transparent one. [CN] 页面由宿主绘制：每个 Tab 得到一个透明的空页面。
        // [EN] `@convention(block)`: a plain Swift closure in a `[String: Any]` is not an Objective-C block for the controller.
        // [CN] `@convention(block)`：`[String: Any]` 中的普通 Swift 闭包对 controller 而言不是 Objective-C block。
        let resolver: @convention(block) (String, [String: Any]) -> UIViewController? = { _, _ in
            let page = UIViewController()
            page.view.backgroundColor = .clear
            return page
        }
        configuration[CYLTabBarControllerPageResolver] = resolver
        configuration[CYLTabBarControllerPageLookupOrder] = [CYLTabBarPageSourceResolver]
        if configuration[CYLTabBarControllerPlusButton] is [String: Any] {
            let action: @convention(block) (CYLPlusButton) -> Void = { [weak self] _ in self?.didTapPlusButton?() }
            configuration[CYLTabBarControllerPlusButtonAction] = action
        }
        let tabBarController = CYLTabBarController(configuration: configuration)
        guard let pageCount = tabBarController.viewControllers?.count, pageCount > 0 else { return }
        // [EN] The host is the delegate (it conforms to the delegate protocols in an extension): set by key, as the property's
        //      type names FlatDesign's protocol too, which Core cannot name.
        // [CN] 宿主担任 delegate（在 extension 中遵循 delegate 协议）：通过 key 设置，因为该属性的类型还包含 Core 无法引用的扁平样式协议。
        tabBarController.setValue(self, forKey: "delegate")
        tabBarController.view.backgroundColor = .clear
        tabBarController.view.frame = bounds
        tabBarController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        applyLayoutDirection(to: tabBarController)
        if tabBarHidden {
            tabBarController.setTabBarHidden(true, animated: false)
        }
        if let titlePositionAdjustment {
            tabBarController.titlePositionAdjustment = titlePositionAdjustment.uiOffsetValue
        }
        let parent = hostViewController
        parent?.addChild(tabBarController)
        addSubview(tabBarController.view)
        tabBarController.didMove(toParent: parent)
        tabBarController.cyl_didLongPressControlBlock = { [weak self] _, control in
            self?.didLongPress(control)
        }
        // [EN] The app's state once it set one; until then the cached one. [CN] App 设置过时使用其状态；之前使用缓存的状态。
        if loggedInSet {
            tabBarController.cyl_loggedIn = currentLoggedIn
        } else {
            currentLoggedIn = tabBarController.cyl_loggedIn
        }
        loginStateDidChange?(currentLoggedIn)
        if animationSpeed > 0 {
            tabBarController.tabBarItemAnimationSpeed = animationSpeed
        }
        tabBarController.tabBarItemAnimationLoops = animationLoops
        // [EN] The app shows the login screen: the tab is not selected now (see `didRequestLogin`).
        // [CN] 由 App 展示登录界面：此时不选中该 Tab（见 `didRequestLogin`）。
        tabBarController.cyl_loginHandler = { [weak self] controller, viewController, completion in
            completion(false)
            guard let host = self, let didRequestLogin = host.didRequestLogin else { return }
            let index = CYLTabBarHostSupport.pages(of: controller).firstIndex(of: viewController) ?? -1
            didRequestLogin(index, viewController.cyl_tabBarItemIdentifier ?? "", viewController.tabBarItem.title ?? "")
        }
        self.tabBarController = tabBarController
        applySelectedIndex()
        applyBadgeValues()
        applyTabCoverImages()
        setNeedsLayout()
    }

    private func removeTabBarController() {
        guard let tabBarController else { return }
        tabBarController.willMove(toParent: nil)
        tabBarController.view.removeFromSuperview()
        tabBarController.removeFromParent()
        self.tabBarController = nil
        updateTouchableRects()
    }

    private var hostViewController: UIViewController? {
        var responder = next
        while let current = responder {
            if let viewController = current as? UIViewController {
                return viewController
            }
            responder = current.next
        }
        return window?.rootViewController
    }

    /**
     * [EN] Right to left for a right-to-left language (e.g. Arabic), as the Objective-C example's `[UIView appearance]`.
     * [CN] 从右到左的语言（如阿拉伯语）使用从右到左布局，与 Objective-C 示例的 `[UIView appearance]` 相同。
     */
    private func applyLayoutDirection(to tabBarController: CYLTabBarController) {
        let rightToLeft = NSLocale.characterDirection(forLanguage: CYLLocalizationLanguage()) == .rightToLeft
        let attribute: UISemanticContentAttribute = rightToLeft ? .forceRightToLeft : .unspecified
        tabBarController.view.semanticContentAttribute = attribute
        tabBarController.tabBar.semanticContentAttribute = attribute
    }

    // MARK: Touches

    /**
     * [EN] The plus button and the badges rise above the bar and the view: a touch there belongs to the tab bar, which
     *      hit-tests its plus button outside its bounds. With `heightIncludesOverflow`, a touch in the transparent strip above
     *      the bar, away from the plus button and its badge, goes to the views below.
     * [CN] PlusButton 与角标会高出 TabBar 与视图：落在那里的触摸属于 TabBar，TabBar 会在其边界之外检测 PlusButton。`heightIncludesOverflow` 时，
     *      落在 TabBar 上方透明区域、且不在 PlusButton 与其角标上的触摸交给下方的视图。
     */
    override open func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let tabBar = tabBarController?.tabBar
        let takesTouches = tabBar != nil && !isHidden && alpha > 0.01 && isUserInteractionEnabled
        // [EN] Above the bar, inside this view or not: the controller's view would hand the touch to a page, so the tab bar is
        //      asked directly. [CN] TabBar 上方（无论是否在本视图内）：controller 的视图会把触摸交给页面，因此直接询问 TabBar。
        if takesTouches, let tabBar, !tabBar.convert(tabBar.bounds, to: self).contains(point),
           let hit = tabBar.hitTest(convert(point, to: tabBar), with: event) {
            return hit
        }
        if takesTouches && heightIncludesOverflow && !CYLTabBarHostSupport.rects(touchableRects, contain: point) {
            return nil
        }
        return super.hitTest(point, with: event)
    }

    private var currentTouchableRects: [NSValue] {
        guard let tabBarController, !tabBarHidden else { return [] }
        let tabBar = tabBarController.tabBar
        var rects = [NSValue(cgRect: tabBar.convert(tabBar.bounds, to: self))]
        if let plusButton = CYLPlusButton(forTabBarContext: tabBarController.context), plusButton.isDescendant(of: tabBar), !plusButton.isHidden {
            var frame = plusButton.bounds
            for subview in plusButton.subviews where !subview.isHidden && subview.alpha > 0.01 {
                frame = frame.union(subview.frame)
            }
            rects.append(NSValue(cgRect: plusButton.convert(frame, to: self)))
        }
        return rects
    }

    private func updateTouchableRects() {
        let rects = currentTouchableRects
        guard rects != touchableRects else { return }
        touchableRects = rects
        touchableRectsDidChange?(rects)
    }

    // MARK: Selection, badges and covers

    private func applySelectedIndex() {
        let pages = CYLTabBarHostSupport.pages(of: tabBarController)
        guard let tabBarController, currentSelectedIndex >= 0, currentSelectedIndex < pages.count else { return }
        let page = pages[currentSelectedIndex]
        // [EN] Never a tab that needs login while logged out, whatever the order the app sets the values in.
        // [CN] 未登录时不选中需要登录的 Tab，无论 App 以何种顺序设置这些值。
        if !tabBarController.cyl_loggedIn && tabBarController.cyl_isLoginRequired(for: page) {
            return
        }
        if tabBarController.selectedViewController !== page {
            tabBarController.selectedViewController = page
        }
    }

    /**
     * [EN] Badges sit on the tab buttons, which exist once the tab bar is laid out. The values are read when the block runs, as the
     *      Android host: a block that waited for a layout shows the current badges, never older ones.
     * [CN] 角标位于 Tab 按钮上，TabBar 布局后按钮才存在。与 Android 宿主相同，在 block 执行时读取值：等待布局的 block 显示当前的角标，而不是旧的。
     */
    private func applyBadgeValues() {
        tabBarController?.perform(whenTabBarItemsReady: { [weak self] tabBarController in
            guard let host = self else { return }
            let animationType = CYLBadgeAnimationType(rawValue: UInt(max(host.badgeAnimationType, 0))) ?? .none
            let plusAttributes = host.plusButtonBadgeAttributes.flatMap { $0.isEmpty ? nil : $0 }
                ?? [CYLTabBarHostBadgeValue: host.plusButtonBadgeValue ?? ""]
            for (index, page) in CYLTabBarHostSupport.pages(of: tabBarController).enumerated() {
                var attributes = (host.badgeAttributes.flatMap { index < $0.count ? $0[index] : nil }) as? [String: Any]
                if attributes?.isEmpty ?? true {
                    attributes = [CYLTabBarHostBadgeValue: index < host.badgeValues.count ? host.badgeValues[index] : ""]
                }
                CYLTabBarHostSupport.showBadge(on: page, attributes ?? [:], animationType: animationType)
            }
            if let plusButton = CYLPlusButton(forTabBarContext: tabBarController.context) {
                CYLTabBarHostSupport.showBadge(on: plusButton, plusAttributes, animationType: animationType)
            }
        })
    }

    /**
     * [EN] Covers the tab buttons with the loaded images, removing the covers of an earlier list first.
     * [CN] 用已加载的图片覆盖 Tab 按钮，先移除之前列表的覆盖。
     */
    private func applyTabCoverImages() {
        guard let controller = tabBarController, loadedTabCoverImages != nil else { return }
        // [EN] Read when the block runs, as the badges. [CN] 与角标相同，在 block 执行时读取。
        controller.perform(whenTabBarItemsReady: { [weak self] tabBarController in
            guard let host = self else { return }
            let images = host.loadedTabCoverImages ?? []
            for covered in host.coveredTabButtons {
                covered.cover.removeFromSuperview()
                covered.selectedCover.removeFromSuperview()
                covered.button.cyl_coverVisiableTabImageViewOrTabButton(true, contentNewView: covered.cover, seclectContentNewView: covered.selectedCover,
                                                                         offset: .zero, show: false, delayIfNeededForSeconds: 0, completion: nil)
            }
            host.coveredTabButtons = []
            for (index, page) in CYLTabBarHostSupport.pages(of: tabBarController).enumerated() {
                guard index < images.count, let image = images[index] as? UIImage, let button = page.cyl_tabButton else { continue }
                // [EN] A button holding the image, as the Objective-C example's `-selectedCover`: an image view here was taken for
                //      the tab's own icon by the views shown in place of it (a skin's network icons), and hidden on every
                //      selection change. [CN] 与 Objective-C 示例的 `-selectedCover` 相同，用按钮承载图片：使用 image view 时，替换图标的
                //      视图（皮肤的网络图标）会把它当成 Tab 自身的图标，在每次切换选中时将其隐藏。
                func cover() -> UIView {
                    let cover = UIButton(type: .custom)
                    cover.setImage(image, for: .normal)
                    cover.frame = CGRect(origin: .zero, size: image.size)
                    cover.contentMode = .center
                    cover.imageView?.contentMode = .scaleAspectFit
                    cover.isUserInteractionEnabled = false
                    // [EN] Decoration over the tab: VoiceOver reads the tab. [CN] Tab 上的装饰：VoiceOver 朗读 Tab 本身。
                    cover.accessibilityElementsHidden = true
                    return cover
                }
                let contentCover = cover()
                let selectedCover = cover()
                button.cyl_coverVisiableTabImageViewOrTabButton(true, contentNewView: contentCover, seclectContentNewView: selectedCover,
                                                                 offset: .zero, show: true, delayIfNeededForSeconds: 0.1, completion: nil)
                host.coveredTabButtons.append((button, contentCover, selectedCover))
            }
        })
    }

    private func didLongPress(_ control: UIControl) {
        guard let didLongPressTab else { return }
        let identifier = control.cyl_tabBarItemIdentifier ?? ""
        var index = -1
        if !control.cyl_isPlusControl(), !identifier.isEmpty {
            index = CYLTabBarHostSupport.pages(of: tabBarController).firstIndex { $0.cyl_tabBarItemIdentifier == identifier } ?? -1
        }
        didLongPressTab(index, identifier, control.cyl_tabBarItemDisplayName)
    }

    // MARK: Height

    private func updatePreferredHeight() {
        guard let tabBarController, tabBarController.tabBar.frame.height > 0 else { return }
        let tabBar = tabBarController.tabBar
        updateTouchableRects()
        var height = tabBar.frame.height
        if heightIncludesOverflow {
            var overflow = CYLTabBarHostSupport.badgeRoom
            if let plusButton = CYLPlusButton(forTabBarContext: tabBarController.context), plusButton.isDescendant(of: tabBar) {
                overflow = max(overflow, -plusButton.convert(plusButton.bounds, to: tabBar).minY)
            }
            height += overflow
        }
        height = ceil(height)
        guard abs(height - preferredHeight) >= 0.5 else { return }
        preferredHeight = height
        preferredHeightDidChange?(height)
    }

    // MARK: Delegate forwarding

    /**
     * [EN] The host is the tab bar controller's delegate, in place of the controller itself (which is its own delegate otherwise,
     *      as the Objective-C example's subclass is, calling `super`). The delegate methods the host does not handle go to the
     *      controller, so it keeps its own behavior: the tap recognizer, login and custom tab actions, placeholders, and the
     *      Liquid Glass lens decisions for the plus button's page.
     * [CN] 宿主代替 TabBarController 担任其 delegate；否则 controller 自己就是 delegate（Objective-C 示例的子类即如此，并调用 `super`）。宿主
     *      未处理的 delegate 方法交给 controller，使其保留自身行为：点击识别、登录与自定义 Tab 操作、占位控制器，以及 PlusButton 页面的液态玻璃
     *      放大镜判断。
     */
    override open func responds(to selector: Selector!) -> Bool {
        if super.responds(to: selector) {
            return true
        }
        return CYLTabBarHostSupport.isDelegateSelector(selector) && (tabBarController?.responds(to: selector) ?? false)
    }

    override open func forwardingTarget(for selector: Selector!) -> Any? {
        if CYLTabBarHostSupport.isDelegateSelector(selector), let tabBarController, tabBarController.responds(to: selector) {
            return tabBarController
        }
        return super.forwardingTarget(for: selector)
    }
}

// MARK: - The delegate methods the host handles itself
// [EN] Not a declared conformance: a public Swift conformance to a protocol of this module would make the generated header import
//      the umbrella header (a cycle). The controller calls these by selector, and `responds(to:)` answers for them.
// [CN] 不声明遵循协议：Swift 公开遵循本模块的协议会让生成的头文件导入总头文件（形成循环）。controller 通过 selector 调用它们，`responds(to:)` 会
//      对它们作出回答。

extension CYLTabBarHostView {

    @objc(tabBarController:shouldSelectViewController:)
    func cyl_tabBarController(_ tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        guard let controller = self.tabBarController else { return true }
        // [EN] The plus button's own page is selected by the plus button (its page key), which the controller's check, made for
        //      tabs, refuses as the plus slot. [CN] PlusButton 自己的页面由 PlusButton 选中（其页面键）；controller 为 Tab 设计的检查会把它当作
        //      PlusButton 的位置而拒绝。
        if viewController === CYLPlusButton.plusChildViewController(forTabBarContext: controller.context) {
            controller.updateSelectionStatusIfNeeded(for: tabBarController, shouldSelect: viewController)
            return true
        }
        return controller.tabBarController(tabBarController, shouldSelect: viewController)
    }

    /**
     * [EN] Every tap on a tab, also on the selected one, as `-tabBarController:didSelectControl:` in the Objective-C example.
     * [CN] 每次点击 Tab（包括已选中的 Tab），与 Objective-C 示例中的 `-tabBarController:didSelectControl:` 相同。
     */
    @objc(tabBarController:didSelectControl:)
    func cyl_tabBarController(_ tabBarController: UITabBarController, didSelectControl control: UIControl) {
        guard let controller = self.tabBarController, control.cyl_isTabButton(), !control.cyl_isPlusControl() else { return }
        if let selected = controller.selectedViewController, let index = CYLTabBarHostSupport.pages(of: controller).firstIndex(of: selected) {
            didSelectTab?(index, selected.cyl_tabBarItemIdentifier ?? "")
        }
    }

    /**
     * [EN] The tabs are reported by `-tabBarController:didSelectControl:`; here only the plus button's own page: index -1 and
     *      the plus button's identifier.
     * [CN] Tab 由 `-tabBarController:didSelectControl:` 上报；这里只处理 PlusButton 自己的页面：下标 -1 与 PlusButton 的标识。
     */
    @objc(tabBarController:didSelectViewController:)
    func cyl_tabBarController(_ tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        guard let controller = self.tabBarController,
              viewController === CYLPlusButton.plusChildViewController(forTabBarContext: controller.context) else {
            return
        }
        didSelectTab?(-1, CYLPlusButton(forTabBarContext: controller.context)?.cyl_tabBarItemIdentifier ?? "")
    }
}
