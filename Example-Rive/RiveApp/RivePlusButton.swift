//
//  RivePlusButton.swift
//  RiveApp
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

/*!
 * [EN] The plus button of Example-Rive: an image with the title "Start", between Search and Bell, whose page is the
 *      course's onboarding (Rive button and background, then sign-in). It takes the Timer tab's place, as an iPhone
 *      tab bar shows at most 5 items. On Liquid Glass its title moves into the tab item under it and the image sits above
 *      the tab titles (`+alignsTitleWithTabBarItemTitles`, issue #636); Example-PAG shows the other layout, a title drawn
 *      on a background image. Registered in `SceneDelegate` before the tab bar controller is created.
 * [CN] Example-Rive 的 PlusButton：标题为 "Start" 的图片，位于 Search 与 Bell 之间，其页面是课程的引导页（Rive 按钮与背景，然后进入登录页）。
 *      iPhone 的 TabBar 最多显示 5 项，因此它占用 Timer Tab 的位置。液态玻璃下，标题移到
 *      其下方的 TabBarItem 中，图片位于 Tab 标题上方（`+alignsTitleWithTabBarItemTitles`，issue #636）；Example-PAG 演示另一种布局：标题画在
 *      背景图上。在 `SceneDelegate` 中、创建 TabBarController 之前注册。
 */
final class RivePlusButton: CYLPlusButton, CYLPlusButtonSubclassing {

    /// [EN] The course's purple. [CN] 课程的紫色。
    static let courseColor = UIColor(red: 0x78 / 255.0, green: 0x50 / 255.0, blue: 0xF0 / 255.0, alpha: 1)

    static func plusButton() -> Any {
        RivePlusButton.cyl_plusButton(with: circleImage(diameter: 44), title: "Start",
                                      selectedTitle: nil, selectedTitleColor: nil)
    }

    static func indexOfPlusButtonInTabBar() -> UInt {
        2
    }

    // #408: the plus button's identifier. PlusButton 的标识。
    static func tabBarItemIdentifier() -> String {
        "plus"
    }

    static func alignsTitleWithTabBarItemTitles() -> Bool {
        true
    }

    /// [EN] The Timer tab's page (TabViewControllers.swift), titled after the plus button.
    /// [CN] Timer Tab 的页面（TabViewControllers.swift），标题与 PlusButton 一致。
    static func plusChildViewController() -> UIViewController {
        let navigationController = Tab.timer.viewController
        navigationController.children.first?.title = "Start"
        return navigationController
    }

    /// [EN] A purple circle with a white plus. No rendering mode needed: CYLPlusButton draws every image as is.
    /// [CN] 紫色圆形加白色加号。无需设置渲染模式：CYLPlusButton 会把所有图片按原图绘制。
    private static func circleImage(diameter: CGFloat) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        let symbolConfiguration = UIImage.SymbolConfiguration(pointSize: diameter * 0.45, weight: .bold)
        let plus = UIImage(systemName: "plus", withConfiguration: symbolConfiguration)?
            .withTintColor(.white, renderingMode: .alwaysOriginal)
        return UIGraphicsImageRenderer(size: size).image { _ in
            courseColor.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()
            if let plus = plus {
                plus.draw(at: CGPoint(x: (size.width - plus.size.width) / 2, y: (size.height - plus.size.height) / 2))
            }
        }
    }
}
