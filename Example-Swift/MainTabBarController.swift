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
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        lottieAnimationSpeed = 1.5 // Issue #428: Lottie tab icons at 1.5x (no effect without Lottie) Lottie 图标 1.5 倍速
        // * @attention 请在父类的 ViewDidLoad 调用之前设置CYLTabBarStyleType。也就是在 `-[super viewDidLoad];` 之前调用。因为 需要在 tabBar 的KVC操作之前确定自定义样式，否则， 就会执行默认逻辑， 可能会导致你的自定义样式失效。

        self.tabBarStyleType = .liquidGlass

        UIApplication.shared.applicationSupportsShakeToEdit = true
        self.becomeFirstResponder()
        
        
        super.viewDidLoad()
        observeLottieAnimationViewDidAdd()
    }

    // Issue #428: called once for each Lottie view, after `lottieAnimationSpeed` was applied; one tab can get its own
    // speed here. 每个 Lottie 视图添加后回调一次，可在这里为某一个 Tab 单独设置速度。
    private func observeLottieAnimationViewDidAdd() {
        let name = NSNotification.Name(CYLTabBarItemLottieAnimationViewDidAddNotification)
        _ = NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { [weak self] note in
            guard let tabButton = note.object as? UIControl, tabButton.cyl_tabBarController === self else { return }
            if tabButton.cyl_tabBarChildViewControllerIndex == 0 {
                tabButton.cyl_setLottieAnimationSpeed(2.0)
            }
        }
    }
    
    
    
}

// MARK: - Delegate
extension MainTabBarController {
    
    override func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        self.updateSelectionStatusIfNeeded(for: tabBarController, shouldSelect: viewController)
        return true
    }
 
    static func makeViewControllers() -> [UIViewController] {
        let home = UINavigationController(rootViewController: CYLBadgeHelperTableViewController())
        let connection = UINavigationController(rootViewController: ConnectionViewController())
        let message = UINavigationController(rootViewController: MessageViewController())
        let personal = UINavigationController(rootViewController: PersonalViewController())

        return [home, connection, message, personal]
    }

    static func makeTabBarItemsAttributes() -> [[AnyHashable: Any]] {

        let tabBarItemOne = [
            CYLTabBarItemTitle: "首页",
            CYLTabBarItemImage: "home_normal",
            CYLTabBarItemSelectedImage: "home_highlight"
        ]

        let tabBarItemTwo = [
            CYLTabBarItemTitle: "鱼塘",
            CYLTabBarItemImage: "fishpond_normal",
            CYLTabBarItemSelectedImage: "fishpond_highlight"
        ]

        let tabBarItemThree = [
            CYLTabBarItemTitle: "消息",
            CYLTabBarItemImage: "message_normal",
            CYLTabBarItemSelectedImage: "message_highlight"
        ]

        let tabBarItemFour = [
            CYLTabBarItemTitle: "我的",
            CYLTabBarItemImage: "account_normal",
            CYLTabBarItemSelectedImage: "account_highlight"
        ]

        return [tabBarItemOne, tabBarItemTwo, tabBarItemThree, tabBarItemFour]
    }
}
