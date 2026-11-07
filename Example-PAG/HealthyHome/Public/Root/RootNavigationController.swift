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

        // [EN] A blue bar with a white title and white buttons. An appearance, because `barTintColor` does not draw on a Liquid
        //      Glass navigation bar: the white title and buttons were on a light background there, and could not be read.
        // [CN] 蓝色导航栏，白色标题与按钮。使用 appearance，因为 `barTintColor` 在液态玻璃导航栏上不绘制：白色的标题和按钮落在浅色背景上，无法看清。
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .hexColor("3A57ED")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 17)]
        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = .white

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
