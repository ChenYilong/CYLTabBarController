//
//  MainTabBarController.swift
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import ObjectiveC
import CYLTabBarController

/// [EN] The tab bar height the selection indicator image is drawn for. [CN] 绘制选中指示图所用的 TabBar 高度。
private let CYLTabBarControllerHeight: CGFloat = 40

/// [EN] iOS 26 or later (`CYL_IS_IOS_26`). [CN] iOS 26 及以后（`CYL_IS_IOS_26`）。
private var CYLDemoIsIOS26: Bool {
    ProcessInfo.processInfo.isOperatingSystemAtLeast(OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0))
}

/**
 [EN] The Objective-C example's main tab bar controller, ported to Swift (docs/Swift-Migration.md, step 110): `CYLTabBarController`
      becomes an `open` Swift class in phase ②, which Objective-C cannot subclass (docs/Subclassing-In-Swift.md). Objective-C
      files of the example use it through `CYLTabBarControllerDemo-Swift.h`, under the same name and selectors.
 [CN] Objective-C 示例的主 TabBarController，已改写为 Swift（docs/Swift-Migration.md，第 110 步）：第 ② 阶段 `CYLTabBarController` 将成为
      Objective-C 无法继承的 `open` Swift 类（docs/Subclassing-In-Swift.md）。示例的 Objective-C 文件通过 `CYLTabBarControllerDemo-Swift.h`
      以相同的类名与 selector 使用它。
 */
@objc(MainTabBarController)
class MainTabBarController: CYLTabBarController, CYLFlatDesignUITabBarControllerDelegate {

    /// [EN] The covers of the first tab, kept: the decoration runs again after a theme switch or a tab reload, and covering
    ///      with the same views moves them instead of adding more.
    /// [CN] 第一个 Tab 的封面，保留下来：换肤或重新加载 Tab 后装饰会再次执行，用同样的视图覆盖只会移动它们，不会再添加新的。
    private var contentCover: UIButton?
    private var selectedContentCover: UIButton?

    /**
     [EN] A tab bar controller of the demo's four tabs, for a context (each context has its own plus button).
     [CN] 由 Demo 四个 Tab 组成的 TabBarController，对应一个 context（每个 context 有自己的 PlusButton）。
     */
    @objc(initWithContext:)
    init(context: String) {
        // [EN] A title offset for the classic style; `CYLTabBarStyleTypeFlatDesign` / `…LiquidGlass` are the other styles.
        // [CN] 经典样式的标题偏移；其他样式为 `CYLTabBarStyleTypeFlatDesign` / `…LiquidGlass`。
        let titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -3.5)
        super.init(viewControllers: MainTabBarController.viewControllersForTabBar(),
                   tabBarItemsAttributes: MainTabBarController.tabBarItemsAttributesForTabBar(),
                   imageInsets: .zero,
                   titlePositionAdjustment: titlePositionAdjustment,
                   styleType: .default,
                   context: context)
        customizeTabBarAppearance(titlePositionAdjustment: titlePositionAdjustment)
        delegate = self
        navigationController?.navigationBar.isHidden = true
        setUpLoginRequiredTabs()
        setUpTabBarItemGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    /**
     [EN] The superclass's initializers end in `-initWithConfiguration:` (then `-initWithNibName:bundle:`), sent to `self`: a Swift subclass that has its own
          initializer inherits none, so this one forwards it (without it the app trapped at launch: "unimplemented initializer").
     [CN] 父类的初始化方法最终向 `self` 发送 `-initWithConfiguration:`：有自己初始化方法的 Swift 子类不会继承任何父类初始化方法，因此在这里转发
          （否则 App 启动即崩溃："unimplemented initializer"）。
     */
    override init(configuration: [String: Any]) {
        super.init(configuration: configuration)
    }

    /// [EN] Reached the same way, from `-initWithConfiguration:`. [CN] 同样经 `-initWithConfiguration:` 调用。
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    /// [EN] #152: gestures on the tab buttons and the plus button, with the block API.
    /// [CN] #152：Tab 按钮与 PlusButton 上的手势，使用 block 方式。
    private func setUpTabBarItemGestures() {
        cyl_tabBarItemGestureHandler = { [weak self] _, gesture, control, viewController in
            guard let viewController else { return }
            self?.cyl_demo_handleTabBarItemGesture(gesture, control: control, viewController: viewController)
        }
        // [EN] `-CYLDemoDoubleTapInterval 0.8`: a longer double tap interval for automated taps on the simulator.
        // [CN] `-CYLDemoDoubleTapInterval 0.8`：加长双击间隔，供模拟器上的自动点击使用。
        let doubleTapInterval = UserDefaults.standard.double(forKey: "CYLDemoDoubleTapInterval")
        if doubleTapInterval > 0 {
            cyl_tabBarItemDoubleTapInterval = doubleTapInterval
        }
    }

    /// [EN] #19: "Messages" and "Me" need login (block API). [CN] #19：「消息」「我的」需要登录（block 方式）。
    private func setUpLoginRequiredTabs() {
        // [EN] "Me" has no identifier, so it uses its class name (#408). [CN] 「我的」没有设置标识，使用类名（#408）。
        cyl_loginRequiredTabBarItemIdentifiers = ["message", NSStringFromClass(CYLMineViewController.self)]
        cyl_loginHandler = { tabBarController, viewController, completion in
            tabBarController.cyl_demo_presentLogin(for: viewController, completion: completion)
        }
    }

    override func viewDidLoad() {
        // [EN] Set the style before `super.viewDidLoad()`. [CN] 在 `super.viewDidLoad()` 之前设置样式。
        UIApplication.shared.applicationSupportsShakeToEdit = true
        becomeFirstResponder()
        customizeInterface()
        // [EN] Issue #426: unload the unselected tabs' views on a memory warning. [CN] Issue #426：内存警告时卸载未选中 Tab 的视图。
        unloadsUnselectedViewsOnMemoryWarning = true
        // [EN] Issue #428: 1.5 times as fast, set so the playback controls can change it live.
        // [CN] Issue #428：1.5 倍速，用赋值使播放控件可以实时修改。
        tabBarItemAnimationSpeed = 1.5
        super.viewDidLoad()
        observeLottieAnimationViewDidAdd()
        // FIX: issue #22
        // [EN] `tabBar.items` is still empty here. [CN] 此时 `tabBar.items` 仍为空。
        perform(whenTabBarItemsReady: { tabBarController in
            for item in tabBarController.tabBar.items ?? [] {
                item.accessibilityHint = item.title
            }
        })
    }

    /// [EN] Issue #428: called once per Lottie view. [CN] Issue #428：每个 Lottie 视图添加后回调一次。
    private func observeLottieAnimationViewDidAdd() {
        NotificationCenter.default.addObserver(forName: .CYLTabBarItemAnimationViewDidAdd, object: nil, queue: .main) { [weak self] note in
            guard let tabButton = note.object as? UIControl, tabButton.cyl_tabBarController === self else { return }
            NSLog("🟢 Lottie view added: tab %@, animationSpeed %@", "\(tabButton.cyl_tabBarChildViewControllerIndex)",
                  String(describing: (tabButton.cyl_tabBarItemAnimationView() as AnyObject?)?.value(forKey: "animationSpeed")))
        }
    }

    private static func viewControllersForTabBar() -> [UIViewController] {
        let pages: [UIViewController] = [CYLHomeViewController(), CYLSameCityViewController(), CYLMessageViewController(), CYLMineViewController()]
        let viewControllers = pages.map { page -> UIViewController in
            let navigationController = CYLBaseNavigationController(rootViewController: page)
            page.cyl_hideNavigationBarSeparator = true
            // [EN] The navigation bar title is the tab title, also after it changes in place.
            // [CN] 导航栏标题即 Tab 标题，原地修改后也会同步。
            page.cyl_navigationTitleFollowsTabBarItemTitle = true
            return navigationController
        }
        return viewControllers
    }

    /**
     [EN] The demo's four tabs: titles, identifiers (#408), images with Dark Mode versions (#620) and Lottie animations with
          dark versions (#442).
     [CN] Demo 的四个 Tab：标题、标识（#408）、带深色版本的图片（#620）与带深色版本的 Lottie 动画（#442）。
     */
    @objc class func tabBarItemsAttributesForTabBar() -> [[String: Any]] {
        let path = { (name: String) -> String in Bundle.main.path(forResource: name, ofType: "json") ?? "" }
        // [EN] The Lottie files come from NorthSea, respect! [CN] Lottie 动画的 json 文件来自 NorthSea，致敬！
        let first: [String: Any] = [
            CYLTabBarItemTitle: cylDemoLocalizedString("首页"),
            // [EN] #433: the selected Home tab reads "Refresh"; a re-tap replays its animation.
            // [CN] #433：选中的「首页」显示「刷新」；再次点击重播动画。
            CYLTabBarItemSelectedTitle: cylDemoLocalizedString("刷新"),
            CYLTabBarItemIdentifier: "home",
            // [EN] A name also loads "<name>_dark" when it exists. [CN] 图片名会同时加载存在的「<name>_dark」。
            CYLTabBarItemImage: "home_normal",
            CYLTabBarItemSelectedImage: "home_highlight",
            CYLTabBarLottieFilePath: path("green_lottie_tab_home"),
            CYLTabBarLottieDarkFilePath: path("green_lottie_tab_home_dark"),
        ]
        let second: [String: Any] = [
            CYLTabBarItemTitle: cylDemoLocalizedString("同城"),
            CYLTabBarItemIdentifier: "city",
            CYLTabBarItemImage: "fishpond_normal",
            CYLTabBarItemSelectedImage: "fishpond_highlight",
            CYLTabBarLottieFilePath: path("green_lottie_tab_discover"),
            CYLTabBarLottieDarkFilePath: path("green_lottie_tab_discover_dark"),
            // [EN] #216: the unselected icon's color follows the skin: gray, or red with the Grapefruit skin.
            // [CN] #216：未选中图标的颜色跟随皮肤：灰色，西柚皮肤时为红色。
            CYLTabBarAnimationColors: ["Icon_Discovery_Normal.**.Color": UIColor.cyl_color { _, identifier, _ in
                (identifier as? NSObject)?.isEqual("Grapefruit") == true ? .systemRed : UIColor(white: 0.498, alpha: 1)
            }],
        ]
        let third: [String: Any] = [
            CYLTabBarItemTitle: cylDemoLocalizedString("消息"),
            CYLTabBarItemIdentifier: "message",
            // [EN] A dark image under any name. [CN] 任意名称的深色图片。
            CYLTabBarItemImage: "message_normal",
            CYLTabBarItemDarkImage: "message_normal_night",
            CYLTabBarItemSelectedImage: "message_highlight",
            CYLTabBarLottieFilePath: path("green_lottie_tab_news"),
            CYLTabBarLottieDarkFilePath: path("green_lottie_tab_news_dark"),
        ]
        let fourth: [String: Any] = [
            CYLTabBarItemTitle: cylDemoLocalizedString("我的"),
            // [EN] No identifier: the default is the class name, "CYLMineViewController" (#408); account_normal has its own Dark
            //      appearance in Images.xcassets.
            // [CN] 未设置标识：默认值为类名 "CYLMineViewController"（#408）；account_normal 在 Images.xcassets 中自带 Dark 外观。
            CYLTabBarItemImage: "account_normal",
            CYLTabBarItemSelectedImage: "account_highlight",
            CYLTabBarLottieFilePath: path("green_lottie_tab_mine"),
            CYLTabBarLottieDarkFilePath: path("green_lottie_tab_mine_dark"),
        ]
        return [first, second, third, fourth]
    }

    /**
     [EN] The demo's tab bar appearance: red titles, green selected titles and icons, a green shadow line (also used by
          CYLFlatDesignMainTabBarController).
     [CN] Demo 的 TabBar 外观：红色标题，绿色的选中标题与图标，绿色阴影线（CYLFlatDesignMainTabBarController 也使用）。
     */
    @objc(demoStandardAppearanceWithTitlePositionAdjustment:)
    class func demoStandardAppearance(titlePositionAdjustment: UIOffset) -> UITabBarAppearance {
        let normalAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.red, .font: UIFont.systemFont(ofSize: 10)]
        let selectedAttributes: [NSAttributedString.Key: Any] = [.foregroundColor: UIColor.cyl_systemGreen, .font: UIFont.systemFont(ofSize: 10)]
        let itemAppearance = UITabBarItemAppearance()
        // FIX: issue #456
        itemAppearance.normal.titlePositionAdjustment = titlePositionAdjustment
        itemAppearance.normal.titleTextAttributes = normalAttributes
        itemAppearance.selected.titleTextAttributes = selectedAttributes
        // [EN] The icon colors follow the titles. [CN] 图标颜色与标题一致。
        itemAppearance.selected.iconColor = .cyl_systemGreen
        let appearance = UITabBarAppearance()
        appearance.stackedLayoutAppearance = itemAppearance
        appearance.inlineLayoutAppearance = itemAppearance
        appearance.compactInlineLayoutAppearance = itemAppearance
        // [EN] FIX: #581 — no background color on iOS 26 (it would hide the unselected titles under the glass).
        // [CN] FIX: #581 —— iOS 26 上不设置背景色（会在玻璃下遮住未选中的标题）。
        appearance.shadowColor = .cyl_systemGreen
        return appearance
    }

    private func customizeTabBarAppearance(titlePositionAdjustment: UIOffset) {
        CYLGetRootWindow()?.backgroundColor = UIColor.cyl_systemBackground
        // [EN] The same appearance also styles the FlatDesign tab bar. [CN] 同一个 appearance 同样作用于扁平样式 TabBar。
        let appearance = MainTabBarController.demoStandardAppearance(titlePositionAdjustment: titlePositionAdjustment)
        tabBar.unselectedItemTintColor = .red
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
        if !CYLDemoIsIOS26 {
            // [EN] Not on iOS 26: the glass decides the unselected title color. [CN] iOS 26 上不设置：未选中标题颜色由玻璃决定。
            UITabBar.appearance().isTranslucent = false
        }
    }

    /// [EN] The red selection indicator of the classic style. [CN] 经典样式的红色选中指示图。
    private func customizeTabBarSelectionIndicatorImage() {
        guard !CYLDemoIsIOS26 else { return }
        // [EN] This tab bar's own item width. [CN] 本 TabBar 自己的 item 宽度。
        let size = CGSize(width: cyl_tabBar?.cyl_tabBarItemWidth ?? 0, height: CYLTabBarControllerHeight)
        let image = UIImage.cyl_image(with: .red, size: size)?.resizableImage(withCapInsets: UIEdgeInsets(top: 1, left: 0, bottom: 0, right: 0))
        tabBar.selectionIndicatorImage = image
    }

    // MARK: - The first tab's cover 第一个 Tab 的封面

    /// [EN] A cover over the selected first tab; decorative, VoiceOver reads the tab. [CN] 选中的第一个 Tab 上的封面；装饰性，VoiceOver 朗读 Tab。
    private func makeSelectedCover() -> UIButton {
        let cover = UIButton(type: .custom)
        cover.accessibilityElementsHidden = true
        let image = UIImage(named: "home_select_cover")
        cover.setImage(image, for: .normal)
        cover.frame.size = image?.size ?? .zero
        cover.contentMode = .center
        cover.imageView?.contentMode = .scaleAspectFit
        cover.translatesAutoresizingMaskIntoConstraints = false
        return cover
    }

    /**
     [EN] Shows or hides the cover of the first tab (the demo adds it, 1.5 s after launch; AGENTS.md).
     [CN] 显示或隐藏第一个 Tab 的封面（由示例在启动 1.5 秒后添加；AGENTS.md）。
     */
    @objc(setSelectedCoverShow:)
    func setSelectedCoverShow(_ show: Bool) {
        guard let firstTabButton = viewControllers?.first?.cyl_tabButton else { return }
        if contentCover == nil {
            contentCover = makeSelectedCover()
            selectedContentCover = makeSelectedCover()
        }
        guard let contentCover, let selectedContentCover else { return }
        // [EN] A Lottie icon needs the delay, or the replacement happens before the animation view is ready.
        // [CN] Lottie 图标需要延迟，否则会在动画视图就绪前替换。
        firstTabButton.cyl_coverVisiableTabImageViewOrTabButton(true, contentNewView: contentCover, seclectContentNewView: selectedContentCover,
                                                                offset: .zero, show: show, delayIfNeededForSeconds: 0.1) { [weak self] isReplaced, _, newView in
            guard let self, isReplaced, show else { return }
            self.viewControllers?.first?.cyl_clearBadge()
            // [EN] Liquid Glass has its own scale animation. [CN] 液态玻璃自带缩放动画。
            if !CYLConstants.isLiquidGlassActive() {
                self.addOnceScaleAnimation(on: newView)
            }
        }
    }

    private func addOnceScaleAnimation(on view: UIView) {
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.5, 1.0]
        animation.duration = 0.1
        animation.calculationMode = .cubic
        view.layer.add(animation, forKey: nil)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        // [EN] #620: compare this controller's own traits. [CN] #620：比较本控制器自身的 trait。
        guard traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else { return }
        UIViewController.cyl_topmostViewController()?.navigationController?.navigationBar.barTintColor = UIColor.cyl_systemBackground
    }

    private func customizeInterface() {
        setViewDidLayoutSubViewsBlockInvokeOnce(true) { [weak self] tabBarController in
            self?.cyl_demo_decorate(tabBarController)
            self?.cyl_demo_selectTabFromLaunchArgument(of: tabBarController)
        }
    }

    /**
     [EN] Launch arguments (screenshots, UI tests): `-CYLDemoSelectedTab <identifier>` logs in and selects that tab 2 s after
          launch; `-CYLDemoOrientation landscape` rotates the main tab bar; `-CYLDemoPlaceholderPreview <kind>` shows a placeholder.
     [CN] 启动参数（截图、UI 测试）：`-CYLDemoSelectedTab <identifier>` 启动 2 秒后登录并选中该 Tab；`-CYLDemoOrientation landscape` 旋转主
          TabBar；`-CYLDemoPlaceholderPreview <kind>` 展示占位图。
     */
    private func cyl_demo_selectTabFromLaunchArgument(of tabBarController: CYLTabBarController) {
        let defaults = UserDefaults.standard
        if defaults.string(forKey: "CYLDemoOrientation") == "landscape", (defaults.string(forKey: "CYLDemoGalleryScene") ?? "").isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak tabBarController] in
                guard #available(iOS 16.0, *), let scene = tabBarController?.view.window?.windowScene else { return }
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight)) { error in
                    NSLog("CYLDemoOrientation: %@", error.localizedDescription)
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak tabBarController] in
            if let tabBarController {
                _ = CYLDemoPlaceholder.presentPlaceholderPreviewIfRequested(from: tabBarController)
            }
        }
        guard let identifier = defaults.string(forKey: "CYLDemoSelectedTab"), !identifier.isEmpty else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak tabBarController] in
            tabBarController?.cyl_loggedIn = true
            tabBarController?.cyl_selectTabBarItem(withIdentifier: identifier)
        }
    }

    /**
     [EN] The badges, the cover of the first tab and the selection indicator, once the tab buttons exist; again after they
          are set up again (issue #481).
     [CN] Tab 按钮创建后添加角标、第一个 Tab 的封面与选中指示图；Tab 按钮重新创建后再次调用（issue #481）。
     */
    private func cyl_demo_decorate(_ tabBarController: CYLTabBarController) {
        customizeTabBarSelectionIndicatorImage()
        // [EN] The delay only makes the badge animations easy to see. [CN] 延迟只是为了方便看清角标动画。
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let viewControllers = tabBarController.viewControllers, viewControllers.count >= 4 else { return }
            // [EN] #425: the shared badge style is set once in SceneDelegate; each tab sets only what differs.
            // [CN] #425：共用的角标样式在 SceneDelegate 中统一设置；每个 Tab 只设置不同的部分。
            let first = viewControllers[0]
            first.cyl_badgeBackgroundColor = .cyl_randomColor
            first.cyl_badgeRadius = 11 / 2
            first.cyl_showBadgeValue("", animationType: .breathe)
            self?.setSelectedCoverShow(true)
            // [EN] Issue #481: directly on the tab item. [CN] Issue #481：直接设置在 TabBarItem 上。
            viewControllers[1].tabBarItem.cyl_badgeBackgroundColor = .systemPurple
            viewControllers[1].tabBarItem.cyl_showBadgeValue("8", animationType: .scale)
            viewControllers[2].cyl_showBadgeValue("", animationType: .shake)
            viewControllers[3].cyl_showBadgeValue("100", animationType: .bounce)
            if viewControllers.count > 4 {
                // [EN] Differs from the global offset. [CN] 与全局偏移不同。
                viewControllers[4].cyl_badgeCenterOffset = CGPoint(x: -1, y: 3)
                viewControllers[4].cyl_showBadgeValue("NEW", animationType: .breathe)
            }
            // [EN] #535: the plus button gets a badge too; each tap adds 1. [CN] #535：PlusButton 也显示角标；每次点击加 1。
            tabBarController.cyl_demo_showPlusButtonBadge()
        }
    }

    // MARK: - CYLTabBarControllerDelegate

    override func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        let shouldSelect = super.tabBarController(tabBarController, shouldSelect: viewController)
        #if DEBUG
        NSLog(cylDemoLocalizedString("🔴类名与方法名：%@（在第%@行）, 描述：index%@ title%@"), "\(#function)", "\(#line)",
              "\(viewControllers?.firstIndex(of: viewController) ?? NSNotFound)", viewController.title ?? "")
        #endif
        // [EN] #152: re-tap, double tap and long press go to `cyl_tabBarItemGestureHandler`. [CN] #152：再次点击、双击与长按交给手势回调。
        return shouldSelect
    }

    override func tabBarController(_ tabBarController: CYLTabBarController, shouldShowPlatterLiquidLensViewFor control: UIControl) -> Bool {
        _ = super.tabBarController(tabBarController, shouldShowPlatterLiquidLensViewFor: control)
        return true
    }

    /**
     [EN] #408: tabs by identifier, not by index; every tab bar controller answers for its own tabs and plus button.
     [CN] #408：按标识而不是下标区分 Tab；每个 TabBarController 只处理自己的 Tab 和 PlusButton。
     */
    private func cyl_logTabBarItemIdentifiers(of tabBarController: CYLTabBarController, selectedControl control: UIControl) {
        let identifier = control.cyl_tabBarItemIdentifier
        NSLog("🟢 #408 [%@] tapped \"%@\" (selected \"%@\")", tabBarController.context ?? "", identifier ?? "",
              tabBarController.cyl_selectedTabBarItemIdentifier ?? "")
        for eachIdentifier in tabBarController.cyl_tabBarItemIdentifiers {
            let eachControl = tabBarController.cyl_control(withTabBarItemIdentifier: eachIdentifier)
            NSLog("   \"%@\": index %@, %@", eachIdentifier, "\(tabBarController.cyl_index(ofTabBarItemIdentifier: eachIdentifier))",
                  eachControl?.cyl_isPlusButton() == true ? "plus button" : "tab button")
        }
        switch identifier {
        case "plus", "camera": NSLog("   plus button of context %@", tabBarController.context ?? "")
        case "message": NSLog("   message tab, wherever it is now")
        case "CYLMineViewController": NSLog("   mine tab, by its default identifier (class name)")
        default: break
        }
    }

    override func tabBarController(_ tabBarController: UITabBarController, didSelect control: UIControl) {
        guard let tabBarController = tabBarController as? CYLTabBarController else { return }
        cyl_logTabBarItemIdentifiers(of: tabBarController, selectedControl: control)
        var animationView: UIView?
        // [EN] #535: the plus button's badge changes on every tap; checked first (before iOS 26 `cyl_isTabButton` is also true
        //      for the plus button). [CN] #535：每次点击 PlusButton 角标都会变化；需先判断（iOS 26 以前 `cyl_isTabButton` 对 PlusButton 也为真）。
        let isPlusControl = tabBarController.hasPlusButton() && control.cyl_isPlusControl()
        if isPlusControl {
            tabBarController.cyl_demo_plusButtonDidTap()
            animationView = CYLPlusButton(forOwner: tabBarController)?.imageView
        } else if control.cyl_isTabButton() {
            // [EN] Toggle the red dot. [CN] 切换红点。
            let isFlatDesign = tabBarController.tabBarStyleType == .flatDesign
            if control.cyl_isShowBadge() {
                if isFlatDesign {
                    control.cyl_clearBadge()
                } else {
                    tabBarController.selectedViewController?.cyl_clearBadge()
                }
            } else if isFlatDesign {
                control.cyl_showBadgeValue("", animationType: .scaleOnce)
            } else {
                tabBarController.selectedViewController?.cyl_showBadge()
            }
            animationView = control.cyl_tabImageView()
        }
        addScaleAnimation(on: animationView, repeatCount: 1)
    }

    /// [EN] A scale animation; none on iOS 26, where the glass already animates. [CN] 缩放动画；iOS 26 上不使用（玻璃已有动画）。
    private func addScaleAnimation(on view: UIView?, repeatCount: Float) {
        guard let view, !CYLDemoIsIOS26 else { return }
        let animation = CAKeyframeAnimation(keyPath: "transform.scale")
        animation.values = [1.0, 1.3, 0.9, 1.15, 0.95, 1.02, 1.0]
        animation.duration = 1
        animation.repeatCount = repeatCount
        animation.calculationMode = .cubic
        view.layer.add(animation, forKey: nil)
    }

    // MARK: - Overrides of CYLTabBarController

    /// [EN] Issue #426: keeps the home tab loaded (its viewDidLoad adds a scroll edge interaction). [CN] Issue #426：保留首页 Tab 不卸载。
    override func shouldUnloadView(of viewController: UIViewController) -> Bool {
        let root = (viewController as? UINavigationController)?.viewControllers.first ?? viewController
        return !(root is CYLHomeViewController)
    }

    override func tabBarItemAnimationViewContentMode() -> UIView.ContentMode {
        .scaleAspectFit
    }
}

// MARK: - Demo helpers on every tab bar controller (also used by CYLFlatDesignMainTabBarController)

private var CYLDemoPlusButtonBadgeCountKey: UInt8 = 0

extension CYLTabBarController {

    private var cyl_demo_plusButtonBadgeCount: Int {
        get { (objc_getAssociatedObject(self, &CYLDemoPlusButtonBadgeCountKey) as? Int) ?? 0 }
        set { objc_setAssociatedObject(self, &CYLDemoPlusButtonBadgeCountKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    /**
     [EN] #535: the plus button's badge, the same API and look as the tabs'; with a plus child view controller its system tab
          button (the layer under the plus button) shows the same value.
     [CN] #535：PlusButton 的角标，与 Tab 角标相同的 API 和样式；有 PlusButton 子控制器时，其系统 Tab 按钮（PlusButton 下方的图层）显示相同的值。
     */
    @objc func cyl_demo_showPlusButtonBadge() {
        guard hasPlusButton(), let plusButton = CYLPlusButton(forOwner: self) else { return }
        let count = max(cyl_demo_plusButtonBadgeCount, 1)
        cyl_demo_plusButtonBadgeCount = count
        let badgeValue = "\(count)"
        plusButton.cyl_showBadgeValue(badgeValue, animationType: .bounce)
        if hasPlusChildViewController() {
            CYLPlusButton.plusChildViewController(forOwner: self)?.cyl_showBadgeValue(badgeValue, animationType: .bounce)
        }
        #if DEBUG
        NSLog("🟣 #535 plus button badge %@ (Liquid Glass: %@, from CYLUtils)", "\(count)", CYLUtils.isLiquidGlassActive() ? "YES" : "NO")
        #endif
    }

    /// [EN] #535: each tap adds 1. [CN] #535：每次点击加 1。
    @objc func cyl_demo_plusButtonDidTap() {
        cyl_demo_plusButtonBadgeCount += 1
        cyl_demo_showPlusButtonBadge()
    }

    /// [EN] #19: the login alert of the demo. [CN] #19：Demo 的登录弹框。
    @objc(cyl_demo_presentLoginForViewController:completion:)
    func cyl_demo_presentLogin(for viewController: UIViewController, completion: @escaping CYLTabBarLoginCompletion) {
        let title = viewController.tabBarItem.title ?? viewController.cyl_getViewControllerInsteadOfNavigation().title ?? ""
        let alert = UIAlertController(title: cylDemoLocalizedString("需要登录"),
                                      message: String(format: cylDemoLocalizedString("「%@」需要登录后才能查看"), title), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cylDemoLocalizedString("取消"), style: .cancel) { _ in completion(false) })
        // [EN] A real app logs in here first. [CN] 实际 App 在这里先完成登录。
        alert.addAction(UIAlertAction(title: cylDemoLocalizedString("登录"), style: .default) { _ in completion(true) })
        var presenter: UIViewController = self
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        presenter.present(alert, animated: true)
    }

    /// [EN] #152: re-tap refreshes the list (or scrolls to the top), long press shows a menu. [CN] #152：再次点击刷新列表（或滚动到顶部），长按显示菜单。
    @objc(cyl_demo_handleTabBarItemGesture:control:viewController:)
    func cyl_demo_handleTabBarItemGesture(_ gesture: CYLTabBarItemGesture, control: UIControl, viewController: UIViewController) {
        let content = viewController.cyl_getViewControllerInsteadOfNavigation()
        NSLog("🟣 #152 gesture %@ on \"%@\"", "\(gesture.rawValue)", control.cyl_tabBarItemIdentifier ?? "")
        switch gesture {
        case .reselect:
            if !CYLDemoPlaceholder.refreshList(of: content) {
                cyl_demo_scrollToTop(content)
            }
        case .doubleTap:
            // [EN] The second tap was already reported as a Reselect. [CN] 第二次点击已作为 Reselect 回调。
            break
        case .longPress:
            cyl_demo_showActions(for: control)
        @unknown default:
            break
        }
    }

    /// [EN] Scrolls the page's first scroll view to its top. [CN] 将页面中的第一个滚动视图滚动到顶部。
    private func cyl_demo_scrollToTop(_ viewController: UIViewController) {
        var views: [UIView] = viewController.isViewLoaded ? [viewController.view] : []
        while !views.isEmpty {
            let each = views.removeFirst()
            if let scrollView = each as? UIScrollView {
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: -scrollView.adjustedContentInset.top), animated: true)
                return
            }
            views.append(contentsOf: each.subviews)
        }
    }

    /// [EN] The long press menu: the tab's identifier and a way to select it. [CN] 长按菜单：显示 Tab 标识，并可选中它。
    private func cyl_demo_showActions(for control: UIControl) {
        let identifier = control.cyl_tabBarItemIdentifier ?? ""
        let sheet = UIAlertController(title: identifier, message: cylDemoLocalizedString("长按（#152）"), preferredStyle: .actionSheet)
        if !identifier.isEmpty, !control.cyl_isPlusButton() {
            sheet.addAction(UIAlertAction(title: cylDemoLocalizedString("选中"), style: .default) { [weak self] _ in
                self?.cyl_selectTabBarItem(withIdentifier: identifier)
            })
        }
        sheet.addAction(UIAlertAction(title: cylDemoLocalizedString("取消"), style: .cancel))
        sheet.popoverPresentationController?.sourceView = control
        sheet.popoverPresentationController?.sourceRect = control.bounds
        if presentedViewController == nil {
            present(sheet, animated: true)
        }
    }
}
