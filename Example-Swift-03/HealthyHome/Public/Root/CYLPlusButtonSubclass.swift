//
//  CYLPlusButtonSubclass.swift
//  HealthyHome
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

import UIKit

class CYLPlusButtonSubclass: CYLPlusButton, CYLPlusButtonSubclassing {

    
    /// MARK: 添加按钮
    static func plusButton() -> Any {
        
        let button = CYLPlusButtonSubclass()
        
        button.setBackgroundImage(UIImage(named: "tabbar_database"), for: .normal)
        button.titleLabel?.textAlignment = .center
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        
        button.setTitle("菜单", for: .normal)
        button.setTitleColor(.white, for: .normal)
        
        button.setTitle("菜单", for: .selected)
        button.setTitleColor(.white, for: .selected)
        
        button.adjustsImageWhenHighlighted = false
        button.sizeToFit()
        
//        button.titleEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
        
        return button
    }

    /*!
    * 实现该方法后，能让 PlusButton 的点击效果与跟点击其他 TabBar 按钮效果一样，跳转到该方法指定的 UIViewController 。
    * @attention 必须同时实现 `+indexOfPlusButtonInTabBar` 来指定 PlusButton 的位置。
    * @return 指定 PlusButton 点击后跳转的 UIViewController。
    *
    */
    static func plusChildViewController() -> UIViewController {
        let wisdom = WisdomVC()
        let nav = RootNavigationController(rootViewController: wisdom)
        return nav
    }
    
    /// MARK: 插入位置
    static func indexOfPlusButtonInTabBar() -> UInt {
        return 2
    }
    
    
    /*!
    * 该方法是为了调整 PlusButton 中心点Y轴方向的位置，建议在按钮超出了 tabbar 的边界时实现该方法。
    * @attention 如果不实现该方法，内部会自动进行比对，预设一个较为合适的位置，如果实现了该方法，预设的逻辑将失效。
    * @return 返回值是自定义按钮中心点Y轴方向的坐标除以 tabbar 的高度，
              内部实现时，会使用该返回值来设置 PlusButton 的 centerY 坐标，公式如下：
                 `PlusButtonCenterY = multiplierOfTabBarHeight * tabBarHeight + constantOfPlusButtonCenterYOffset;`
              也就是说：如果 constantOfPlusButtonCenterYOffset 为0，同时 multiplierOfTabBarHeight 的值是0.5，表示 PlusButton 居中，小于0.5表示 PlusButton 偏上，大于0.5则表示偏下。
    *
    */
    static func multiplier(ofTabBarHeight tabBarHeight: CGFloat) -> CGFloat {
        return 0.3
    }
    
    /*!
    * 见 `+multiplierOfTabBarHeight:` 注释：
    * `PlusButtonCenterY = multiplierOfTabBarHeight * tabBarHeight + constantOfPlusButtonCenterYOffset;`
    * 也就是说： constantOfPlusButtonCenterYOffset 大于0会向下偏移，小于0会向上偏移。
    * @attention 实现了该方法，但没有实现 `+multiplierOfTabBarHeight:` 方法，在这种情况下，会在预设逻辑的基础上进行偏移。
    */
    static func constantOfPlusButtonCenterYOffset(forTabBarHeight tabBarHeight: CGFloat) -> CGFloat {
        let screenHeight = UIScreen.main.nativeBounds.size.height;
        if screenHeight == 2436 || screenHeight == 1792 || screenHeight == 2688 || screenHeight == 1624 {
            return -30
        }
        return -10
    }
    
    
}
