//
//  RootNavigationController.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

class RootNavigationController: CYLBaseNavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // [CN] 背景颜色
        // [EN] Background color
        self.navigationBar.barTintColor = .hexColor("3A57ED")
        // [CN] 标题设置
        // [EN] Title settings
        let dict: NSDictionary = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)]
        self.navigationBar.titleTextAttributes = dict as? [NSAttributedString.Key: AnyObject]

    }
    
    
    
    func isNavBarHidden(isHidden: Bool) {
         self.isNavigationBarHidden = isHidden
     }
     
     // [CN] MARK:重写跳转
     // [EN] MARK: Override push
     override func pushViewController(_ viewController: UIViewController, animated: Bool) {
         if self.viewControllers.count > 0 {
             // [CN] 跳转后隐藏
             // [EN] Hide after pushing
             viewController.hidesBottomBarWhenPushed = true
         }
         
         super.pushViewController(viewController, animated: animated)
     }
    
    

}
