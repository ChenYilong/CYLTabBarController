//
//  CYLPlusButtonSubclass.swift
//  HealthyHome
//
//  Created by apple on 2020/2/14.
//  Copyright © 2020 apple. All rights reserved.
//

#if CYL_DEMO_SWIFTUI
import SwiftUI
#endif
import UIKit

class CYLPlusButtonSubclass: CYLPlusButton, CYLPlusButtonSubclassing {
    
    
    /// [CN] MARK: 添加按钮
    /// [EN] MARK: Add the button
    static func plusButton() -> Any {
        
        let button = CYLPlusButtonSubclass()
        
        button.setBackgroundImage(UIImage(named: "tabbar_database"), for: .normal)
        button.titleLabel?.textAlignment = .center
        
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        
        button.setTitle(CYLLocalizedString("菜单"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        
        button.setTitle(CYLLocalizedString("菜单"), for: .selected)
        button.setTitleColor(.white, for: .selected)
        
        // An explicit highlighted image is drawn as is, so the button does not darken on touch
        // (replaces `adjustsImageWhenHighlighted = false`, deprecated in iOS 15).
        button.setBackgroundImage(button.backgroundImage(for: .normal), for: .highlighted)
        button.sizeToFit()
        button.cyl_keepShowingPlusButtonLabel = true
        //        button.titleEdgeInsets = UIEdgeInsets(top: 3, left: 0, bottom: 0, right: 0)
        
        return button
    }
    
    /*!
     * [CN] 实现该方法后，能让 PlusButton 的点击效果与跟点击其他 TabBar 按钮效果一样，跳转到该方法指定的 UIViewController 。
     * @attention 必须同时实现 `+indexOfPlusButtonInTabBar` 来指定 PlusButton 的位置。
     * @return 指定 PlusButton 点击后跳转的 UIViewController。
     * [EN] Implementing this method makes tapping the PlusButton behave like tapping other TabBar buttons, switching to
     *      the UIViewController specified by this method.
     *      @attention You must also implement `+indexOfPlusButtonInTabBar` to specify the PlusButton's position.
     *      @return The UIViewController to switch to when the PlusButton is tapped.
     *
     */
    // #408: the plus button's identifier, read as `control.cyl_tabBarItemIdentifier`. PlusButton 的标识。
    static func tabBarItemIdentifier() -> String {
        return "plus"
    }

    static func plusChildViewController() -> UIViewController {
        #if CYL_DEMO_SWIFTUI
        // [EN] SwiftUI demo: the plus button's page is a SwiftUI view in a UIHostingController.
        // [CN] SwiftUI 演示：PlusButton 对应的页面是放在 UIHostingController 中的 SwiftUI 视图。
        let publish = UIHostingController(rootView: PublishView())
        publish.title = CYLLocalizedString("发布")
        return RootNavigationController(rootViewController: publish)
        #else
        let wisdom = WisdomVC()
        //        wisdom.title = "菜单"
        let nav = RootNavigationController(rootViewController: wisdom)
        return nav
        #endif
    }
    
    // [CN] Example-PAG（`CYL_DEMO_PAG`）不实现 `alignsTitleWithTabBarItemTitles`：其按钮只有背景图片，标题画在图上，保持在图片中心
    //      （见 docs/PlusButton-Background-Image-Liquid-Glass.md）。
    // [EN] Example-PAG (`CYL_DEMO_PAG`) has no `alignsTitleWithTabBarItemTitles`: its button has a background image only, with
    //      its title drawn on it, so the title stays in the middle of the picture (see docs/PlusButton-Background-Image-Liquid-Glass.md).
    #if !CYL_DEMO_PAG
    /// MARK: 插入位置
    // The plus button's title stays on the same center line as the tab item titles, in every tab bar style.
    static func alignsTitleWithTabBarItemTitles() -> Bool {
        return true
    }
    #endif

    static func indexOfPlusButtonInTabBar() -> UInt {
        return 2
    }
    
    
    /*!
     * [CN] 该方法是为了调整 PlusButton 中心点Y轴方向的位置，建议在按钮超出了 tabbar 的边界时实现该方法。
     * @attention 如果不实现该方法，内部会自动进行比对，预设一个较为合适的位置，如果实现了该方法，预设的逻辑将失效。
     * @return 返回值是自定义按钮中心点Y轴方向的坐标除以 tabbar 的高度，
     内部实现时，会使用该返回值来设置 PlusButton 的 centerY 坐标，公式如下：
     [EN] This method adjusts the Y-axis position of the PlusButton's center; it is recommended when the button extends
          beyond the tabbar's bounds.
          @attention If not implemented, a suitable position is preset internally by comparison; if implemented,
          the preset logic no longer applies.
          @return The Y coordinate of the custom button's center divided by the tabbar's height.
          Internally, this return value is used to set the PlusButton's centerY with the following formula:
     `PlusButtonCenterY = multiplierOfTabBarHeight * tabBarHeight + constantOfPlusButtonCenterYOffset;`
     [CN] 也就是说：如果 constantOfPlusButtonCenterYOffset 为0，同时 multiplierOfTabBarHeight 的值是0.5，表示 PlusButton 居中，小于0.5表示 PlusButton 偏上，大于0.5则表示偏下。
     [EN] In other words: if constantOfPlusButtonCenterYOffset is 0 and multiplierOfTabBarHeight is 0.5, the PlusButton is
          centered; below 0.5 it sits higher, and above 0.5 it sits lower.
     *
     */
    static func multiplier(ofTabBarHeight _: CGFloat) -> CGFloat {
        return 0.3
    }
    
    static func constantOfPlusButtonCenterYOffsetForTabBarHeight(tabBarHeight _: CGFloat) -> CGFloat {
        return -10
    }
    
    
    /*!
     * [CN] 见 `+multiplierOfTabBarHeight:` 注释：
     * [EN] See the `+multiplierOfTabBarHeight:` comment:
     * `PlusButtonCenterY = multiplierOfTabBarHeight * tabBarHeight + constantOfPlusButtonCenterYOffset;`
     * [CN] 也就是说： constantOfPlusButtonCenterYOffset 大于0会向下偏移，小于0会向上偏移。
     * @attention 实现了该方法，但没有实现 `+multiplierOfTabBarHeight:` 方法，在这种情况下，会在预设逻辑的基础上进行偏移。
     * [EN] In other words: a constantOfPlusButtonCenterYOffset greater than 0 shifts down, less than 0 shifts up.
     *      @attention If this method is implemented but `+multiplierOfTabBarHeight:` is not, the offset is applied on top
     *      of the preset logic.
     */
    static func constantOfPlusButtonCenterYOffset(forTabBarHeight _: CGFloat) -> CGFloat {
        let screenHeight = currentWindowScene()?.screen.nativeBounds.size.height ?? 0
        if screenHeight == 2436 || screenHeight == 1792 || screenHeight == 2688 || screenHeight == 1624 {
            return -30
        }
        return -10
    }
    
    
}
