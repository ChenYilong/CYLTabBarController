//
//  RootNavigationController.swift
//  CYLTabBarController
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

class RootNavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        //背景颜色
        self.navigationBar.barTintColor = .hexColor("3A57ED")
        //标题设置
        let dict: NSDictionary = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 15)]
        self.navigationBar.titleTextAttributes = dict as? [NSAttributedString.Key: AnyObject]
        
    }
    
    
    
    func isNavBarHidden(isHidden: Bool) {
         self.isNavigationBarHidden = isHidden
     }
     
     //MARK:重写跳转
     override func pushViewController(_ viewController: UIViewController, animated: Bool) {
         if self.viewControllers.count > 0 {
             //跳转后隐藏
             viewController.hidesBottomBarWhenPushed = true
         }
         
         super.pushViewController(viewController, animated: true)
     }
    
    

}
