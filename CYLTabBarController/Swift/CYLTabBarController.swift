//
//  CYLTabBarController.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

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
    @objc open func lottieAnimationViewContentMode() -> UIView.ContentMode {
        .scaleAspectFit
    }

    /// [EN] How the animation views of the tabs are scaled (through the deprecated name, so an old override keeps working). [CN] Tab 动画视图的缩放方式（经由已废弃的名称，旧的重写仍然有效）。
    @objc open func tabBarItemAnimationViewContentMode() -> UIView.ContentMode {
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
    @objc(isObservingTabImageViewDefaultOffset) var isObservingTabImageViewDefaultOffset = false
    /// [EN] Backing flag of `automaticallyAdjustsImageOnlyTabs`, negated so that the default (false) means true (issues #257, #522). [CN] `automaticallyAdjustsImageOnlyTabs` 的存储标记，取反存储。
    @objc var cyl_imageOnlyTabsAdjustmentDisabled = false
    @objc(shouldInvokeOnceViewDidLayoutSubViewsBlock) var invokeOnceViewDidLayoutSubViewsBlock = false
    @objc(cyl_controlReportedInCurrentRunLoop) weak var cyl_controlReportedInCurrentRunLoop: UIControl?
    @objc(isTabBarItemAnimationViewAdded) var tabBarItemAnimationViewAdded = false
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
        cylDidInitialize()
    }

    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        cylDidInitialize()
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
    public convenience init(viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]], imageInsets: UIEdgeInsets,
                            titlePositionAdjustment: UIOffset) {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: imageInsets,
                  titlePositionAdjustment: titlePositionAdjustment, styleType: .default, context: nil)
    }

    @objc(initWithViewControllers:tabBarItemsAttributes:imageInsets:titlePositionAdjustment:context:)
    public convenience init(viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]], imageInsets: UIEdgeInsets,
                            titlePositionAdjustment: UIOffset, context: String?) {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: imageInsets,
                  titlePositionAdjustment: titlePositionAdjustment, styleType: .default, context: context)
    }

    @objc(initWithViewControllers:tabBarItemsAttributes:styleType:context:)
    public convenience init(viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]], styleType: CYLTabBarStyleType,
                            context: String?) {
        self.init(viewControllers: viewControllers, tabBarItemsAttributes: tabBarItemsAttributes, imageInsets: .zero,
                  titlePositionAdjustment: .zero, styleType: styleType, context: context)
    }

    @objc(initWithViewControllers:tabBarItemsAttributes:imageInsets:titlePositionAdjustment:styleType:context:)
    public convenience init(viewControllers: [UIViewController], tabBarItemsAttributes: [[AnyHashable: Any]], imageInsets: UIEdgeInsets,
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
    open func cylDidInitialize() {
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

    open override var tabBar: UITabBar {
        super.tabBar
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
}
