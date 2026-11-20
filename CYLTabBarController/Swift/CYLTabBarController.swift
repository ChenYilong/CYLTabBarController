//
//  CYLTabBarController.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

/// [EN] The block run at the end of `-viewDidLayoutSubviews`. [CN] 在 `-viewDidLayoutSubviews` 末尾执行的 block。
public typealias CYLViewDidLayoutSubViewsBlock = (CYLTabBarController) -> Void
/// [EN] The block called when a tab is long pressed. [CN] 长按 Tab 时调用的 block。
public typealias CYLTabBarControllerDidLongPressControlBlock = (CYLTabBarController, UIControl) -> Void
/// [EN] The completion of the configuration loaders. [CN] 配置加载方法的回调。
public typealias CYLTabBarControllerConfigurationCompletion = (CYLTabBarController?, Error?) -> Void
/// [EN] The provider of a view shown in place of a tab's icon. [CN] 显示在 Tab 图标位置的视图的提供 block。
public typealias CYLTabBarItemIconViewProvider = @convention(block) (Bool) -> UIView?
/// [EN] The handler of the tab bar item gestures. [CN] Tab 手势的处理 block。
public typealias CYLTabBarItemGestureHandler = (CYLTabBarController, CYLTabBarItemGesture, UIControl, UIViewController?) -> Void

/**
 * [EN] The delegate of `CYLTabBarController`: everything optional, on top of `UITabBarControllerDelegate`. Translated from the
 *      Objective-C protocol (docs/Swift-Migration.md, the class switch); the selectors are unchanged.
 * [CN] `CYLTabBarController` 的代理：所有方法可选，在 `UITabBarControllerDelegate` 之上。已从 Objective-C 协议翻译（docs/Swift-Migration.md，类迁移）；selector 不变。
 */
@objc(CYLTabBarControllerDelegate)
public protocol CYLTabBarControllerDelegate: UITabBarControllerDelegate {
    @objc(cyl_tabBarController:didLoadPage:forPlaceholder:atIndex:)
    optional func cyl_tabBarController(_ tabBarController: CYLTabBarController, didLoadPage page: UIViewController?,
                                       forPlaceholder placeholder: UIViewController, at index: UInt)
    @objc(tabBarController:requiresLoginToSelectViewController:)
    optional func tabBarController(_ tabBarController: CYLTabBarController, requiresLoginToSelect viewController: UIViewController) -> Bool
    @objc(tabBarController:presentLoginForViewController:completion:)
    optional func tabBarController(_ tabBarController: CYLTabBarController, presentLoginFor viewController: UIViewController,
                                   completion: @escaping CYLTabBarLoginCompletion)
    @objc(tabBarController:didSelectControl:)
    optional func tabBarController(_ tabBarController: CYLTabBarController, didSelect control: UIControl)
    @objc(tabBarController:didRecognizeTabBarItemGesture:control:viewController:)
    optional func tabBarController(_ tabBarController: CYLTabBarController, didRecognize gesture: CYLTabBarItemGesture, control: UIControl,
                                   viewController: UIViewController?)
    @objc(tabBarController:didLongPressControl:)
    optional func tabBarController(_ tabBarController: CYLTabBarController, didLongPress control: UIControl)
    @objc(tabBarController:shouldPerformCustomActionForViewController:)
    optional func tabBarController(_ tabBarController: CYLTabBarController, shouldPerformCustomActionFor viewController: UIViewController) -> Bool
    @objc(tabBarController:performCustomActionForViewController:)
    optional func tabBarController(_ tabBarController: CYLTabBarController, performCustomActionFor viewController: UIViewController)
    @objc(tabBarController:shouldShowPlatterLiquidLensViewForControl:)
    optional func tabBarController(_ tabBarController: CYLTabBarController, shouldShowPlatterLiquidLensViewFor control: UIControl) -> Bool
}

/**
 * [EN] The tab bar controller. The class is Swift since the class switch (docs/Swift-Migration.md, phase 2 and 3); every member
 *      keeps its Objective-C selector and its Swift name. Stored properties that the Swift extensions of the other files need
 *      are `@objc` here, because an extension cannot declare stored properties; the FlatDesign ones exist in every build
 *      (a few bytes) because this file cannot name the FlatDesign types.
 * [CN] TabBarController。自类迁移起，本类为 Swift（docs/Swift-Migration.md，第 2、3 阶段）；每个成员保留其 Objective-C selector 与 Swift 名称。
 *      其他文件的 Swift 扩展需要的存储属性在这里声明为 `@objc`（扩展不能声明存储属性）；扁平样式相关的存储在所有构建中都存在（几个字节），
 *      因为本文件无法引用扁平样式的类型。
 */
@objc(CYLTabBarController)
open class CYLTabBarController: UITabBarController, CYLTabBarControllerDelegate, CYLTabBarControllerMemoryWarningSeam {

    // MARK: - Public state

    /// [EN] The style of the tab bar. [CN] TabBar 的样式。
    @objc open var tabBarStyleType: CYLTabBarStyleType = .default {
        didSet { _ = oldValue }
    }

    /// [EN] The block run at the end of `-viewDidLayoutSubviews`. [CN] 在 `-viewDidLayoutSubviews` 末尾执行的 block。
    @objc open var viewDidLayoutSubviewsBlock: CYLViewDidLayoutSubViewsBlock?

    /// [EN] The tab bar item attributes the tab bar was created with. [CN] 创建 TabBar 时传入的 Tab item 属性。
    @objc open var tabBarItemsAttributes: [[AnyHashable: Any]] = []

    /// [EN] Image insets of every tab (read-only; change them with `-updateImageInsets:`). [CN] 所有 Tab 的图片内边距（只读；用 `-updateImageInsets:` 修改）。
    @objc open internal(set) var imageInsets: UIEdgeInsets = .zero

    /// [EN] The title offset of every tab. [CN] 所有 Tab 的标题偏移。
    @objc open var titlePositionAdjustment: UIOffset = .zero {
        didSet { cylApplyTitlePositionAdjustmentToItems(titlePositionAdjustment) }
    }

    /// [EN] The image offset of every tab (read-only). [CN] 所有 Tab 的图片偏移（只读）。
    @objc open internal(set) var imagePositionAdjustment: UIOffset = .zero

    /// [EN] See `adjustTabBarItemImageViewSizeDependOnSuperView`. [CN] 见 `adjustTabBarItemImageViewSizeDependOnSuperView`。
    @objc open var adjustTabBarItemImageViewSizeDependOnSuperView = true

    /// [EN] Whether the views of unselected tabs are released on a memory warning. [CN] 收到内存警告时是否释放未选中 Tab 的视图。
    @objc open var unloadsUnselectedViewsOnMemoryWarning = false

    /// [EN] Whether the tab bar item animations loop. [CN] Tab 动画是否循环。
    @objc open var tabBarItemAnimationLoops = false {
        didSet {
            cylApplyTabBarItemAnimationPlayback()
            cylApplyAnimatedImagesLoops(tabBarItemAnimationLoops)
        }
    }

    /// [EN] The deprecated speed storage. [CN] 已废弃的速度存储。
    private var storedLottieAnimationSpeed: CGFloat = 0

    /// [EN] The deprecated name of `tabBarItemAnimationSpeed`. [CN] `tabBarItemAnimationSpeed` 的已废弃名称。
    @available(*, deprecated, message: "Use tabBarItemAnimationSpeed")
    @objc open var lottieAnimationSpeed: CGFloat {
        get { storedLottieAnimationSpeed > 0 && storedLottieAnimationSpeed.isFinite ? storedLottieAnimationSpeed : 1.0 }
        set { storedLottieAnimationSpeed = newValue }
    }

    /// [EN] The deprecated name of `tabBarItemAnimationViewContentMode()`. [CN] `tabBarItemAnimationViewContentMode()` 的已废弃名称。
    @available(*, deprecated, message: "Use -tabBarItemAnimationViewContentMode")
    @objc open dynamic func lottieAnimationViewContentMode() -> UIView.ContentMode {
        .scaleAspectFit
    }

    /// [EN] How the animation views of the tabs are scaled (through the deprecated name, so an old override keeps working). [CN] Tab 动画视图的缩放方式（经由已废弃的名称，旧的重写仍然有效）。
    @objc open dynamic func tabBarItemAnimationViewContentMode() -> UIView.ContentMode {
        lottieAnimationViewContentMode()
    }

    /// [EN] The speed of the tab animations. [CN] Tab 动画的速度。
    @objc open var tabBarItemAnimationSpeed: CGFloat {
        get { lottieAnimationSpeed }
        set {
            lottieAnimationSpeed = newValue
            cylApplyTabBarItemAnimationPlayback()
        }
    }

    // MARK: - State for the Swift extensions

    @objc var pagesFromPageIdentifiers = false
    @objc var pageRegistry: CYLTabBarPageProviding?
    @objc var pageResolver: CYLTabBarPageProvider?
    @objc var pageLookupOrder: [String]?
    @objc var pagesByPageIdentifier: NSMutableDictionary?
    @objc var skippedTabs: [CYLTabBarSkippedTab] = []
    private var storedObservingTabImageViewDefaultOffset = false
    /// [EN] Explicit accessors: Swift would name the setter after `isObserving…`, the Objective-C callers use `-setObservingTabImageViewDefaultOffset:`. [CN] 显式访问器：Swift 会按 `isObserving…` 命名 setter，而 Objective-C 调用方使用 `-setObservingTabImageViewDefaultOffset:`。
    @objc(isObservingTabImageViewDefaultOffset) var isObservingTabImageViewDefaultOffset: Bool {
        @objc(isObservingTabImageViewDefaultOffset) get { storedObservingTabImageViewDefaultOffset }
        @objc(setObservingTabImageViewDefaultOffset:) set { storedObservingTabImageViewDefaultOffset = newValue }
    }
    /// [EN] Backing flag of `automaticallyAdjustsImageOnlyTabs`, negated so that the default (false) means true (issues #257, #522). [CN] `automaticallyAdjustsImageOnlyTabs` 的存储标记，取反存储。
    @objc var cyl_imageOnlyTabsAdjustmentDisabled = false
    private var invokeOnceViewDidLayoutSubViewsBlockStorage = false
    /// [EN] Getter `shouldInvokeOnce…`, setter `setInvokeOnce…:` (the selectors the Objective-C property had). [CN] getter 为 `shouldInvokeOnce…`、setter 为 `setInvokeOnce…:`（与原 Objective-C 属性的 selector 相同）。
    @objc(shouldInvokeOnceViewDidLayoutSubViewsBlock) var invokeOnceViewDidLayoutSubViewsBlock: Bool {
        @objc(shouldInvokeOnceViewDidLayoutSubViewsBlock) get { invokeOnceViewDidLayoutSubViewsBlockStorage }
        @objc(setInvokeOnceViewDidLayoutSubViewsBlock:) set { invokeOnceViewDidLayoutSubViewsBlockStorage = newValue }
    }
    @objc(cyl_controlReportedInCurrentRunLoop) weak var cyl_controlReportedInCurrentRunLoop: UIControl?
    private var storedTabBarItemAnimationViewAdded = false
    @objc(isTabBarItemAnimationViewAdded) var isTabBarItemAnimationViewAdded: Bool {
        @objc(isTabBarItemAnimationViewAdded) get { storedTabBarItemAnimationViewAdded }
        @objc(setTabBarItemAnimationViewAdded:) set { storedTabBarItemAnimationViewAdded = newValue }
    }
    @objc var tabItemPlaceholderImage: UIImage?
    @objc var storedContext: String?
    @objc var cylClassicTabBarIsAnimating = false
    @objc var cylClassicTabBarHiddenRequest = false
    @objc var cylClassicTabBarAnimationGeneration: UInt = 0

    // FlatDesign state (always present; see the class comment)
    @objc var items: NSMutableArray = NSMutableArray()
    @objc var cyl_tabBarHidden = false
    @objc var cylDelegateHasWillShowTabBar = false
    @objc var cylDelegateHasDidShowTabBar = false
    @objc var cylDelegateHasWillHideTabBar = false
    @objc var cylDelegateHasDidHideTabBar = false
    @objc var tabBarIsAnimating = false
    @objc var lastShowHideTabBar = false
    @objc var lastShowHideTabBarAnimated = false
    @objc var needsReloadItems = false
    @objc var cylDidRefreshSystemTabBarVisibility = false
    @objc var cylRefreshingSystemTabBarVisibility = false
    @objc var cylWaitingForVisibilityTransition = false
    @objc weak var cylRefreshedSystemTabBarWindow: UIWindow?
    @objc var parallaxOverlayView: UIView?

    // MARK: - Storage behind UIKit properties

    private var storedViewControllers: [UIViewController]?
    private var storedTabBarView: UIView?
    private var storedSelectedViewController: UIViewController?
    private var storedSelectedIndex = 0
    private var storedTabBarHeight: CGFloat = 0
    private var storedAllowsVerticalBar = false
    private var storedNoNeedUIDesignCompatibility = false

    @objc(cyl_setViewControllersStorage:) func cylSetViewControllersStorage(_ viewControllers: [UIViewController]?) { storedViewControllers = viewControllers }
    @objc(cyl_setStoredTabBar:) func cylSetStoredTabBar(_ tabBar: UIView?) { storedTabBarView = tabBar }
    @objc(cyl_storedTabBar) func cylStoredTabBar() -> UIView? { storedTabBarView }
    @objc(cyl_setSelectedViewControllerStorage:) func cylSetSelectedViewControllerStorage(_ viewController: UIViewController?) { storedSelectedViewController = viewController }
    @objc(cyl_setSelectedIndexStorage:) func cylSetSelectedIndexStorage(_ selectedIndex: UInt) { storedSelectedIndex = Int(selectedIndex) }
    @objc(cyl_tabBarHeightStorage) func cylTabBarHeightStorage() -> CGFloat { storedTabBarHeight }
    @objc(cyl_setTabBarHeightStorage:) func cylSetTabBarHeightStorage(_ tabBarHeight: CGFloat) { storedTabBarHeight = tabBarHeight }
    @objc(cyl_setAllowsVerticalBarStorage:) func cylSetAllowsVerticalBarStorage(_ allowsVerticalBar: Bool) { storedAllowsVerticalBar = allowsVerticalBar }
    @objc(cyl_replaceTabBarItemsAttributesStorage:) func cylReplaceTabBarItemsAttributesStorage(_ attributes: [[AnyHashable: Any]]) { tabBarItemsAttributes = attributes }

    // MARK: - Initializers

    /**
     * [EN] The designated initializer: normalizes the configuration, sets up the tab bar, the plus button and the pages, and
     *      applies the options. `required`, so the configuration factories can build the class they are called on.
     * [CN] 指定初始化方法：规范化配置，设置 TabBar、PlusButton 与页面，并应用各选项。`required`，使配置工厂方法能构建被调用的那个类。
     */
    @objc(initWithConfiguration:)
    public required init(configuration: [String: Any]) {
        super.init(nibName: nil, bundle: nil)
        cylSetUp(withConfiguration: configuration)
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        cyl_didInitialize()
    }

    /// [EN] Convenience, so a subclass that overrides `init(configuration:)` inherits every initializer. [CN] 便利初始化方法：重写了 `init(configuration:)` 的子类因此继承所有初始化方法。
    public override convenience init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        self.init(configuration: [:])
    }

    /// [EN] A tab bar controller without tabs. [CN] 没有 Tab 的 TabBarController。
    @objc public convenience init() {
        self.init(configuration: [:])
    }

    @objc(initWithViewControllers:tabBarItemsAttributes:)
    public required convenience init(viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]]) {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: .zero,
                  titlePositionAdjustment: .zero, styleType: .default, context: nil)
    }

    @objc(initWithViewControllers:tabBaritemsAttributes:)
    public convenience init(viewControllers: [UIViewController], tabBaritemsAttributes tabBarItemsAttributes: [[AnyHashable: Any]]) {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes)
    }

    @objc(initWithViewControllers:tabBarItemsAttributes:imageInsets:titlePositionAdjustment:)
    public required convenience init(viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]], imageInsets: UIEdgeInsets,
                            titlePositionAdjustment: UIOffset) {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: imageInsets,
                  titlePositionAdjustment: titlePositionAdjustment, styleType: .default, context: nil)
    }

    @objc(initWithViewControllers:tabBarItemsAttributes:imageInsets:titlePositionAdjustment:context:)
    public required convenience init(viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]], imageInsets: UIEdgeInsets,
                            titlePositionAdjustment: UIOffset, context: String?) {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: imageInsets,
                  titlePositionAdjustment: titlePositionAdjustment, styleType: .default, context: context)
    }

    @objc(initWithViewControllers:tabBarItemsAttributes:styleType:context:)
    public required convenience init(viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]], styleType: CYLTabBarStyleType,
                            context: String?) {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: .zero,
                  titlePositionAdjustment: .zero, styleType: styleType, context: context)
    }

    @objc(initWithViewControllers:tabBarItemsAttributes:imageInsets:titlePositionAdjustment:styleType:context:)
    public required convenience init(viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]], imageInsets: UIEdgeInsets,
                            titlePositionAdjustment: UIOffset, styleType: CYLTabBarStyleType, context: String?) {
        var configuration: [String: Any] = [:]
        configuration[CYLTabBarControllerViewControllers] = viewControllers
        configuration[CYLTabBarControllerTabBarItemsAttributes] = tabBarItemsAttributes
        configuration[CYLTabBarControllerImageInsets] = NSValue(uiEdgeInsets: imageInsets)
        configuration[CYLTabBarControllerTitlePositionAdjustment] = NSValue(uiOffset: titlePositionAdjustment)
        configuration[CYLTabBarControllerStyleType] = styleType.rawValue
        configuration[CYLTabBarControllerContext] = context
        configuration["_CYLTabBarControllerKeepsEmptyViewControllers"] = true
        self.init(configuration: configuration)
    }

    // MARK: - Class factories

    @objc(tabBarControllerWithConfiguration:)
    public class func tabBarController(withConfiguration configuration: [String: Any]) -> Self {
        self.init(configuration: configuration)
    }

    @objc(tabBarControllerWithViewControllers:tabBarItemsAttributes:)
    public class func tabBarController(withViewControllers viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]]) -> Self {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes)
    }

    @objc(tabBarControllerWithViewControllers:tabBarItemsAttributes:imageInsets:titlePositionAdjustment:)
    public class func tabBarController(withViewControllers viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]],
                                       imageInsets: UIEdgeInsets, titlePositionAdjustment: UIOffset) -> Self {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: imageInsets,
                  titlePositionAdjustment: titlePositionAdjustment)
    }

    @objc(tabBarControllerWithViewControllers:tabBarItemsAttributes:imageInsets:titlePositionAdjustment:context:)
    public class func tabBarController(withViewControllers viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]],
                                       imageInsets: UIEdgeInsets, titlePositionAdjustment: UIOffset, context: String?) -> Self {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: imageInsets,
                  titlePositionAdjustment: titlePositionAdjustment, context: context)
    }

    @objc(tabBarControllerWithViewControllers:tabBarItemsAttributes:styleType:context:)
    public class func tabBarController(withViewControllers viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]],
                                       styleType: CYLTabBarStyleType, context: String?) -> Self {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, styleType: styleType, context: context)
    }

    @objc(tabBarControllerWithViewControllers:tabBarItemsAttributes:imageInsets:titlePositionAdjustment:styleType:context:)
    public class func tabBarController(withViewControllers viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]],
                                       imageInsets: UIEdgeInsets, titlePositionAdjustment: UIOffset, styleType: CYLTabBarStyleType,
                                       context: String?) -> Self {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: imageInsets,
                  titlePositionAdjustment: titlePositionAdjustment, styleType: styleType, context: context)
    }

    deinit {
        cylStopObservingForDealloc()
    }

    /// [EN] After a coder or nib initialization. [CN] 通过 coder 或 nib 初始化之后。
    @objc(cyl_didInitialize)
    open func cyl_didInitialize() {
    }

    // MARK: - UIKit overrides

    open override var viewControllers: [UIViewController]? {
        get { storedViewControllers }
        set { cylSetViewControllers(newValue) }
    }

    open override var selectedViewController: UIViewController? {
        get { storedSelectedViewController }
        set { cylSetSelectedViewController(newValue) }
    }

    open override var selectedIndex: Int {
        get { tabBarStyleType == .flatDesign ? storedSelectedIndex : super.selectedIndex }
        set { cylSetSelectedIndex(UInt(newValue)) }
    }

    open override var delegate: UITabBarControllerDelegate? {
        get { super.delegate }
        set { cylSetDelegate(newValue) }
    }

    /// [EN] The tab bar, typed `CYLTabBar` as the Objective-C header declared it (an unchecked cast, as before: the tab bar is replaced by
    ///      `CYLTabBar` through KVC when the controller is set up). [CN] TabBar，类型为 `CYLTabBar`，与 Objective-C 头文件的声明一致（与以前一样不检查类型：
    ///      设置控制器时已通过 KVC 把 TabBar 换成 `CYLTabBar`）。
    ///      FIX: launch crash in `init(configurationFile:)` — before that swap the tab bar is still a plain `UITabBar`, and
    ///      `unsafeDowncast` traps on it in a Debug build; `unsafeBitCast` never checks, as the Objective-C cast did.
    ///      启动崩溃：换成 `CYLTabBar` 之前 TabBar 还是普通 `UITabBar`，`unsafeDowncast` 在 Debug 构建中会崩溃；`unsafeBitCast` 不检查，与 Objective-C 的强制转换一致。
    open override var tabBar: CYLTabBar {
        unsafeBitCast(super.tabBar as AnyObject, to: CYLTabBar.self)
    }

    open override var isTabBarHidden: Bool {
        get { cylIsTabBarHidden() }
        set { cylSetTabBarHidden(newValue, animated: false) }
    }

    open override func setTabBarHidden(_ hidden: Bool, animated: Bool) {
        cylSetTabBarHidden(hidden, animated: animated)
    }

    open override func addChild(_ childController: UIViewController) {
        super.addChild(childController)
        cylOverrideAddChildViewController(childController)
    }

    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        cylViewWillAppear(animated)
    }

    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        cylViewDidAppear(animated)
    }

    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cylViewWillDisappear(animated)
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        cylViewDidDisappear(animated)
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        cylViewDidLayoutSubviews()
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        cylViewWillLayoutSubviews()
    }

    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        if unloadsUnselectedViewsOnMemoryWarning {
            unloadViewsOfUnselectedViewControllers()
        }
    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?,
                                    context: UnsafeMutableRawPointer?) {
        cylObserveValue(forKeyPath: keyPath, of: object, change: change, context: context)
    }

    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        cylTraitCollectionDidChange(from: previousTraitCollection)
    }

    // MARK: - Properties with logic

    /// [EN] The context (several tab bar controllers, plus buttons). [CN] context（多个 TabBarController 与 PlusButton）。
    @objc open var context: String? { cyl_context }

    /// [EN] The `tabBarHeight`: the system height until one is set. [CN] `tabBarHeight`：未设置时为系统高度。
    @objc open var tabBarHeight: CGFloat {
        get { cylResolvedTabBarHeight() }
        set { cylApplyTabBarHeight(newValue) }
    }

    /// [EN] The tab bar of the style, created on first use. [CN] 当前样式的 TabBar，首次使用时创建。
    @objc(cyl_tabBar) open var cyl_tabBar: UIView? {
        get { cylLazyTabBar() }
        set { cylSetStoredTabBar(newValue) }
    }

    @objc(cyl_setTabBar:) open func cyl_setTabBar(_ tabBar: UIView?) { cylSetStoredTabBar(tabBar) }

    /**
     * [EN] YES when the app does not use the compatibility design: only Liquid Glass can be in compatibility, and only below iOS 26
     *      the answer is always YES.
     * [CN] App 不使用兼容设计时为 YES：只有液态玻璃才可能处于兼容模式，iOS 26 以下始终为 YES。
     */
    @objc open var noNeedUIDesignCompatibility: Bool {
        get {
            guard #available(iOS 26.0, *), CYLConstants.isLiquidGlassActive() else {
                return true
            }
            return storedNoNeedUIDesignCompatibility
        }
        set { storedNoNeedUIDesignCompatibility = newValue }
    }

    @objc open var allowsVerticalBar: Bool {
        get { storedAllowsVerticalBar }
        set { cylApplyAllowsVerticalBar(newValue) }
    }

    @objc open internal(set) var tabBarItemAnimationURLs: NSMutableArray = NSMutableArray()
    @objc open internal(set) var tabBarItemAnimationSizes: NSMutableArray = NSMutableArray()

    /// [EN] Sets the image insets of every tab. [CN] 设置所有 Tab 的图片内边距。
    @objc open func updateImageInsets(_ imageInsets: UIEdgeInsets) {
        self.imageInsets = imageInsets
        cylApplyImageInsetsToItems(imageInsets)
    }

    /// [EN] The frame of the tab bar in the view (height plus the bottom safe area). [CN] TabBar 在 view 中的 frame（高度加底部安全区）。
    @objc(tabBarFrame) var tabBarFrame: CGRect {
        let height = tabBarHeight + view.safeAreaInsets.bottom
        return CGRect(x: 0, y: view.bounds.height - height, width: view.bounds.width, height: height)
    }

    /// [EN] The speed and loop mode to the views already added (none before the tab bar is laid out). [CN] 把速度与循环模式应用到已添加的视图（TabBar 布局前没有视图）。
    @objc(cyl_applyTabBarItemAnimationPlayback) func cylApplyTabBarItemAnimationPlayback() {
        guard cylTabBarItemAnimationGetServiceEntryPoint() != nil, isViewLoaded, let tabBar = cyl_tabBar as? CYLTabBar else {
            return
        }
        tabBar.cylSetAllTabBarItemAnimations(speed: tabBarItemAnimationSpeed, loops: tabBarItemAnimationLoops)
    }

    /// [EN] Plays every tab's animation from the start. [CN] 让每个 Tab 的动画从头播放。
    @objc open func cyl_playAllTabBarItemAnimations() {
        for control in cylAllTabButtonsForAnimatedImages() {
            cylPlayAnimatedImages(ofTabButton: control)
        }
        guard cylTabBarItemAnimationGetServiceEntryPoint() != nil, let tabBar = cyl_tabBar as? CYLTabBar else {
            return
        }
        cylApplyTabBarItemAnimationPlayback()
        tabBar.cylRestartAllTabBarItemAnimations()
    }

    // MARK: - Helpers

    @objc open func hideTabBarShadowImageView() {
        guard tabBarStyleType != .flatDesign else {
            return
        }
        cyl_tabBar?.layoutIfNeeded()
        (cyl_tabBar as? UITabBar)?.cyl_tabShadowImageView()?.cyl_setHidden(true)
    }

    @available(*, deprecated)
    @objc open func hideTabBadgeBackgroundSeparator() {
        hideTabBarShadowImageView()
    }

    @objc open func hasPlusButton() -> Bool { cylContextPlusButton() != nil }

    @objc(cyl_contextPlusButton) func cylContextPlusButton() -> CYLPlusButton? { CYLPlusButton.cylPlusButton(forOwner: self) as? CYLPlusButton }

    @objc(cyl_contextPlusChildViewController) func cylContextPlusChildViewController() -> UIViewController? {
        CYLPlusButton.plusChildViewController(forOwner: self)
    }

    @objc open func allItemsInTabBarCount() -> UInt {
        var count = (cyl_tabBar as? UITabBar)?.cyl_tabbarItemsCount ?? 0
        if hasPlusButton() { count += 1 }
        return UInt(count)
    }

    @objc open func appDelegate() -> UIApplicationDelegate? { UIApplication.shared.delegate }

    // MARK: - Status bar, orientation, layout (UIKit overrides)

    open override var childForStatusBarStyle: UIViewController? { cylChildViewControllerForStatusBarStyle() }
    open override var childForStatusBarHidden: UIViewController? { childForStatusBarStyle }
    open override var childForScreenEdgesDeferringSystemGestures: UIViewController? { selectedViewController }
    open override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        childForStatusBarStyle?.preferredStatusBarUpdateAnimation ?? super.preferredStatusBarUpdateAnimation
    }
    open override var childForHomeIndicatorAutoHidden: UIViewController? { childForStatusBarStyle }

    @available(iOS, deprecated: 16.0)
    open override var shouldAutorotate: Bool {
        if let presented = cylPresentedViewControllerForOrientation() {
            return presented.shouldAutorotate
        }
        var controller = selectedViewController
        if let navigationController = controller as? UINavigationController {
            controller = navigationController.topViewController
        }
        return controller?.shouldAutorotate ?? true
    }

    open override var supportedInterfaceOrientations: UIInterfaceOrientationMask { cylSupportedInterfaceOrientations() }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        cylTabBarMinimizeLifecycleEvent()
        unsafeBitCast(self, to: CYLFlatDesignLayoutHooks.self).cylFlatDesignViewWillTransition?(to: size, with: coordinator)
        super.viewWillTransition(to: size, with: coordinator)
    }

    /// [EN] The theme callback of every view controller: the work is `-cyl_tabBarThemeDidChangeByManager:theme:`. [CN] 每个控制器的主题回调：实际工作在 `-cyl_tabBarThemeDidChangeByManager:theme:`。
    open override func cyl_themeDidChange(by manager: CYLThemeManager, identifier: (any NSCopying & NSObjectProtocol)?, theme: NSObject?) {
        super.cyl_themeDidChange(by: manager, identifier: identifier, theme: theme)
        cylTabBarThemeDidChange(by: manager, theme: theme)
    }

    @available(iOS 26.0, *)
    open override var tabBarMinimizeBehavior: UITabBarController.MinimizeBehavior {
        get { cylSystemTabBarMinimizeBehaviorForApp() }
        set { cylSetSystemTabBarMinimizeBehaviorFromApp(newValue) }
    }

    // MARK: - UITabBarControllerDelegate

    open dynamic func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        cyl_tabBarController(tabBarController, shouldSelect: viewController)
    }
}

/**
 * [EN] The FlatDesign side of `-viewWillTransitionToSize:withTransitionCoordinator:`, implemented in the FlatDesign subspec. Optional.
 * [CN] `-viewWillTransitionToSize:withTransitionCoordinator:` 的扁平样式部分，由扁平样式子库实现。可选。
 */
@objc protocol CYLFlatDesignLayoutHooks {
    @objc(cyl_flatDesignViewWillTransitionToSize:withTransitionCoordinator:)
    optional func cylFlatDesignViewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
}

