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
    

    override func viewDidLoad() {

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

    override func tabBarController(_ tabBarController: CYLTabBarController, shouldShowPlatterLiquidLensViewFor control: UIControl) -> Bool {
//        return super.tabBarController(tabBarController, shouldShowPlatterLiquidLensViewFor: control)
        return true
    }
}

