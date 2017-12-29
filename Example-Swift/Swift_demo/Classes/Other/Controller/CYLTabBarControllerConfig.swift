//
//  CYLTabBarControllerConfig.swift
//  Swift_demo
//
//  Created by Willei Wang on 2017/12/26.
//  Copyright © 2017年 WenLei Wang. All rights reserved.
//

import UIKit

fileprivate let CYLTabBarControllerHeight = 40


class CYLBaseNavigationController: UINavigationController {
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if (self.viewControllers.count > 0) {
            viewController.hidesBottomBarWhenPushed = true
        }
        super.pushViewController(viewController, animated: animated)
    }
}

class CYLTabBarControllerConfig: NSObject {

//    lazy var tabBarController: CYLTabBarController = {
//        /**
//         * 以下两行代码目的在于手动设置让TabBarItem只显示图标，不显示文字，并让图标垂直居中。
//         * 等效于在 `-tabBarItemsAttributesForController` 方法中不传 `CYLTabBarItemTitle` 字段。
//         * 更推荐后一种做法。
//         */
//        let imageInsets = UIEdgeInsets.zero
//        let titlePositionAdjustment = UIOffset.zero
//
//
//    }
    
    lazy var tabBarController: CYLTabBarController = {
        /**
         * 以下两行代码目的在于手动设置让TabBarItem只显示图标，不显示文字，并让图标垂直居中。
         * 等效于在 `-tabBarItemsAttributesForController` 方法中不传 `CYLTabBarItemTitle` 字段。
         * 更推荐后一种做法。
         */
        let imageInsets = UIEdgeInsets.zero
        let titlePositionAdjustment = UIOffset.zero
        
        var tabBarController = CYLTabBarController.init(viewControllers: self.viewControllers, tabBarItemsAttributes: self.tabBarItemsAttributesForController, imageInsets: imageInsets, titlePositionAdjustment: titlePositionAdjustment)
        
        self.customizeTabBarAppearance(tabBarController: tabBarController!)
        self.tabBarController = tabBarController!
        return tabBarController!
    }()
    
    
    let viewControllers:[UIViewController] = {
        
        let firstViewController = HomeViewController()
        let firstNavigationController = CYLBaseNavigationController.init(rootViewController: firstViewController)
        
        let secondViewController = DiscoverViewController()
        let secondNavigationController = CYLBaseNavigationController.init(rootViewController: secondViewController)
        
        let thirdViewController = MessageViewController()
        let thirdNavigationController = CYLBaseNavigationController.init(rootViewController: thirdViewController)
        
        let fourthViewController = MeViewController()
        let fourthNavigationController = CYLBaseNavigationController.init(rootViewController: fourthViewController)
        
        
        var array = [firstNavigationController,secondNavigationController,thirdNavigationController,fourthNavigationController]
        
        return array
    }()
    
    let tabBarItemsAttributesForController:[[String : Any]] = {
        let firstTabBarItemsAttributes = [
//            CYLTabBarItemTitle : "首页",
            CYLTabBarItemImage : "home_normal",  /* NSString and UIImage are supported*/
            CYLTabBarItemSelectedImage : "home_highlight", /* NSString and UIImage are supported*/
        ]
        
        let secondTabBarItemsAttributes = [
//            CYLTabBarItemTitle : "同城",
            CYLTabBarItemImage : "mycity_normal",  /* NSString and UIImage are supported*/
            CYLTabBarItemSelectedImage : "mycity_highlight", /* NSString and UIImage are supported*/
        ]
        
        let thirdTabBarItemsAttributes = [
//            CYLTabBarItemTitle : "消息",
            CYLTabBarItemImage : "message_normal",  /* NSString and UIImage are supported*/
            CYLTabBarItemSelectedImage : "message_highlight", /* NSString and UIImage are supported*/
        ]
        
        let fourthTabBarItemsAttributes = [
//            CYLTabBarItemTitle : "我的",
            CYLTabBarItemImage : "account_normal",  /* NSString and UIImage are supported*/
            CYLTabBarItemSelectedImage : "account_highlight", /* NSString and UIImage are supported*/
        ]
        
        
        let tabBarItemsAttributes = [firstTabBarItemsAttributes,secondTabBarItemsAttributes,thirdTabBarItemsAttributes,fourthTabBarItemsAttributes]
        
        return tabBarItemsAttributes
    }()
    

    
}


extension CYLTabBarControllerConfig:UITabBarControllerDelegate {
    func customizeTabBarAppearance(tabBarController: CYLTabBarController){
        // Customize UITabBar height
        // 自定义 TabBar 高度
        tabBarController.tabBarHeight = UIDevice.current.isX() ? 65 : 49;
        
        // set the text color for unselected state
        // 普通状态下的文字属性
        let normalAttrs = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 10), NSAttributedStringKey.foregroundColor: UIColor.gray]
        
        // set the text color for selected state
        // 选中状态下的文字属性
        let selectedAttrs = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: 10), NSAttributedStringKey.foregroundColor: UIColor.black]
        
        // set the text Attributes
        // 设置文字属性
        let tabBar = UITabBarItem.appearance()
        tabBar.setTitleTextAttributes(normalAttrs, for: .normal)
        tabBar.setTitleTextAttributes(selectedAttrs, for: .selected)
   

        UITabBar.appearance().backgroundColor = UIColor.white
        
    }
    
    
    
    
}


