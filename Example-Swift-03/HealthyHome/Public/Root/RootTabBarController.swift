//
//  RootTabBarController.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit
import CYLTabBarController

class RootTabBarController: CYLTabBarController {

    // #535: the plus button's badge, shared by every Swift demo (Example-Shared/CYLPlusButtonBadgeDemo.swift).
    // #535：PlusButton 的角标，所有 Swift Demo 共用（Example-Shared/CYLPlusButtonBadgeDemo.swift）。
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        demoShowPlusButtonBadgeAfterLayout()
    }

    override func tabBarController(_ _: CYLTabBarController, didSelect control: UIControl) {
        demoPlusButtonDidTap(control)
    }

    

    override func viewDidLoad() {
        lottieAnimationSpeed = 1.5 // Issue #428: Lottie tab icons at 1.5x (no effect without Lottie) Lottie 图标 1.5 倍速

        super.viewDidLoad()

        self.delegate = self

        customizeInterface()
        CYLPlusChildViewController.view.layoutIfNeeded()

    }
    
    /// MARK:TabBard底部标签设置
    func customizeInterface() {
        
        if #available(iOS 11.0, *) {
            tabBar.unselectedItemTintColor = .lightGray
            tabBar.tintColor = .hexColor("3A57ED")
        }else {
            let normalAttrs: NSDictionary = [NSAttributedString.Key.foregroundColor: UIColor.red]
            let selectAttrs: NSDictionary = [NSAttributedString.Key.foregroundColor: UIColor.blue]

            self.tabBarItem.setTitleTextAttributes(normalAttrs as? [NSAttributedString.Key: AnyObject], for: .normal)
            self.tabBarItem.setTitleTextAttributes(selectAttrs as? [NSAttributedString.Key: AnyObject], for: .selected)
        }
        
        //MARK:设置背景图片
        tabBar.backgroundImage = UIImage.imageWithColor(.white)
        //MARK:去除 TabBar 自带的顶部阴影
        self.tabBar.shadowImage = UIImage()
        
//        appearanceShawIamge()
    }
    
    @available(iOS 13, *)
    func appearanceShawIamge() {
        let appearance = tabBar.standardAppearance
        appearance.shadowImage = .imageWithColor(.clear)
        tabBar.standardAppearance = appearance
    }
}

extension RootTabBarController {

    func tabBarController(_ tabBarController: CYLTabBarController, shouldSelect viewController: UIViewController) -> Bool {

        super.tabBarController(tabBarController, shouldSelect: viewController)

        return true
    }

    override func tabBarController(_ _: CYLTabBarController, shouldShowPlatterLiquidLensViewFor _: UIControl) -> Bool {
//        return super.tabBarController(tabBarController, shouldShowPlatterLiquidLensViewFor: control)
        return true
    }
}

