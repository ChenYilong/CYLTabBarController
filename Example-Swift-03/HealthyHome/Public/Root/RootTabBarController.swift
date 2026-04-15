//
//  RootTabBarController.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

class RootTabBarController: CYLTabBarController {
    

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        customizeInterface()
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
    
    override func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        
        updateSelectionStatusIfNeeded(for: tabBarController, shouldSelect: viewController)
        
        return true
    }
}
