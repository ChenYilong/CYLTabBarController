//
//  MainTabBarController.swift
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

import CYLTabBarController
import UIKit
class MainTabBarController: CYLTabBarController {
    
    // MARK: - Your main designated initializer
    override init(
        viewControllers: [UIViewController],
        tabBarItemsAttributes: [[AnyHashable: Any]],
        imageInsets: UIEdgeInsets,
        titlePositionAdjustment: UIOffset,
        
        context: String?
    ) {
        super.init(
            viewControllers: viewControllers,
            tabBarItemsAttributes: tabBarItemsAttributes,
            imageInsets: imageInsets,
            titlePositionAdjustment: titlePositionAdjustment,
            context: context
        )
    }
    override init(
        viewControllers: [UIViewController],
        tabBarItemsAttributes: [[AnyHashable: Any]],
        imageInsets: UIEdgeInsets,
        titlePositionAdjustment: UIOffset,
        styleType: CYLTabBarStyleType,
        context: String?
    ) {
        super.init(
            viewControllers: viewControllers,
            tabBarItemsAttributes: tabBarItemsAttributes,
            imageInsets: imageInsets,
            titlePositionAdjustment: titlePositionAdjustment,
            styleType: styleType,
            context: context
        )
    }
  
//    override init() {
//            super.init()
//    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
            super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

//    required init(coder aDecoder: NSCoder) {
//            super.init(coder: aDecoder)
//    }

    
    convenience init(context: String = "") {
        let imageInsets = UIEdgeInsets.zero
        let titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -3.5)
        
        self.init(viewControllers: Self.makeViewControllers(), tabBarItemsAttributes: Self.makeTabBarItemsAttributes(), imageInsets: imageInsets, titlePositionAdjustment: titlePositionAdjustment, context: context)
    }
    // MARK: - REQUIRED by UIKit (🔥 Fix here)
//    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
//        
//        let imageInsets = UIEdgeInsets.zero
//        let titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -3.5)
//        
//        super.init(
//            viewControllers: Self.makeViewControllers(),
//            tabBarItemsAttributes: Self.makeTabBarItemsAttributes(),
//            imageInsets: imageInsets,
//            titlePositionAdjustment: titlePositionAdjustment,
//            context: ""
//        )
//        
////        self.tabBarStyleType = .liquidGlass
//    }
    
    // MARK: - REQUIRED
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        lottieAnimationSpeed = 1.5 // Issue #428: Lottie tab icons at 1.5x (no effect without Lottie) Lottie 图标 1.5 倍速
        // [CN] * @attention 请在父类的 ViewDidLoad 调用之前设置CYLTabBarStyleType。也就是在 `-[super viewDidLoad];` 之前调用。因为 需要在 tabBar 的KVC操作之前确定自定义样式，否则， 就会执行默认逻辑， 可能会导致你的自定义样式失效。
        // [EN] * @attention Set CYLTabBarStyleType before the superclass's ViewDidLoad is called, i.e. before
        //      `-[super viewDidLoad];`. The custom style must be determined before the tabBar's KVC operations; otherwise
        //      the default logic runs, which may cause your custom style to have no effect.

        self.tabBarStyleType = .liquidGlass

        UIApplication.shared.applicationSupportsShakeToEdit = true
        self.becomeFirstResponder()
        
        
        super.viewDidLoad()
        // `tabBarController(_:didSelect:)` (the plus button's badge, below) is a CYLTabBarControllerDelegate method:
        // without a delegate it is never called and the badge never changes.
        // `tabBarController(_:didSelect:)`（下方 PlusButton 的角标）是 CYLTabBarControllerDelegate 的方法：不设置 delegate 就不会回调，角标也不会变化。
        delegate = self
        observeLottieAnimationViewDidAdd()
    }

    // Issue #428: called once for each Lottie view, after `lottieAnimationSpeed` was applied; one tab can get its own
    // speed here. 每个 Lottie 视图添加后回调一次，可在这里为某一个 Tab 单独设置速度。
    private func observeLottieAnimationViewDidAdd() {
        let name = NSNotification.Name.CYLTabBarItemLottieAnimationViewDidAdd
        _ = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
            guard let tabButton = note.object as? UIControl, tabButton.cyl_tabBarController === self else { return }
            if tabButton.cyl_tabBarChildViewControllerIndex == 0 {
                tabButton.cyl_setLottieAnimationSpeed(2.0)
            }
        }
    }
    
    
    

    // #535: the plus button's badge, shared by every Swift demo (Example-Shared/CYLPlusButtonBadgeDemo.swift).
    // #535：PlusButton 的角标，所有 Swift Demo 共用（Example-Shared/CYLPlusButtonBadgeDemo.swift）。
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        demoShowPlusButtonBadgeAfterLayout()
    }

    override func tabBarController(_ _: CYLTabBarController, didSelect control: UIControl) {
        demoPlusButtonDidTap(control)
    }
}

// MARK: - Delegate
extension MainTabBarController {
    
    override func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        self.updateSelectionStatusIfNeeded(for: tabBarController, shouldSelect: viewController)
        return true
    }
 
    static func makeViewControllers() -> [UIViewController] {
        let home = UINavigationController(rootViewController: HomeViewController())
        let connection = UINavigationController(rootViewController: ConnectionViewController())
        let message = UINavigationController(rootViewController: MessageViewController())
        let personal = UINavigationController(rootViewController: PersonalViewController())

        return [home, connection, message, personal]
    }

    static func makeTabBarItemsAttributes() -> [[AnyHashable: Any]] {
        // Dark Mode (#620): "home_normal" also loads home_normal_dark (naming convention), the message tab names its dark
        // image, account_normal has its own Dark appearance. 深色模式：见 README「适配深色模式」。
        let attributes = CYLLocalizedTabBarItemsAttributes(["首页", "鱼塘", "消息", "我的"],
                                                           ["home_normal", "fishpond_normal", "message_normal", "account_normal"],
                                                           ["home_highlight", "fishpond_highlight", "message_highlight", "account_highlight"],
                                                           [2: "message_normal_night"])
        let lottieAttributes = CYLTabBarItemsAttributesAddingLottieFiles(attributes, ["green_lottie_tab_home", "green_lottie_tab_discover", "green_lottie_tab_news", "green_lottie_tab_mine"], nil)
        // #442 (Lottie 4.x): one file per tab follows Dark Mode, its colors set with Lottie's value providers.
        // 每个 Tab 一份 Lottie 文件适配深色模式，颜色通过 Lottie 的 value provider 设置。
        return zip(lottieAttributes, lottieDarkColors()).map { item, darkColors in
            var item = item
            item[CYLTabBarLottieDarkColors] = darkColors
            return item
        }
    }

    /// Dark Mode colors of the green Lottie icons (keypath -> color): the gray outline of the unselected icon turns
    /// light gray, the pale fill of the selected one dark green; the green outline is kept.
    /// 绿色 Lottie 图标的深色颜色（keypath -> 颜色）：未选中的灰色描边改为浅灰，选中的浅色填充改为深绿，绿色描边不变。
    static func lottieDarkColors() -> [[String: UIColor]] {
        return ["Icon_Shop", "Icon_Discovery", "Icon_Knowledge", "Icon_Mine"].map { layer in
            ["\(layer)_Normal.**.Color": UIColor(white: 0.78, alpha: 1),
             "\(layer)_Active_Main.**.Color": UIColor(red: 0.15, green: 0.39, blue: 0.16, alpha: 1)]
        }
    }
}
