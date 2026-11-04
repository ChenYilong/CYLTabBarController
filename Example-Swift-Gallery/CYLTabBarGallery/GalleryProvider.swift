//
//  GalleryProvider.swift
//  CYLTabBarGallery
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit
import CYLTabBarController

// [EN] Builds every scene of the gallery with the library's public API. One function per scene, in the order of the list.
// [CN] 用本库公开 API 构建图库中的每个场景。每个场景一个函数，顺序与列表一致。
enum GalleryProvider {

    // MARK: - Basic

    static func systemStyle() -> UITabBarController {
        return Gallery.systemTabBarController(5)
    }

    /// [EN] Three tabs; full width on iOS 26 (FlatDesign). [CN] 三个 Tab；iOS 26 上为全宽（扁平样式）。
    static func customStyle() -> CYLTabBarController {
        return Gallery.tabBarController(pages: Gallery.pages(3), attributes: Gallery.attributes(3), styleType: Gallery.fullWidthStyle)
    }

    /// [EN] Tabs 1, 3 and 5 bounce; tabs 2 and 4 stay plain. [CN] 第 1、3、5 个 Tab 有弹性动画；第 2、4 个保持系统样式。
    static func mixtureStyle() -> CYLTabBarController {
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: Gallery.attributes(5))
        for index in stride(from: 0, to: 5, by: 2) {
            controller.viewControllers?[index].cyl_tabButtonAnimation = GalleryBounceAnimation()
        }
        return controller
    }

    /// [EN] Liquid Glass; "Photo" opens a dialog. [CN] 液态玻璃；"Photo" 打开对话框。
    static func customGlassStyle() -> CYLTabBarController {
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: Gallery.attributes(5))
        Gallery.hijackPhotoTab(of: controller)
        return controller
    }

    static func systemMoreStyle() -> UITabBarController {
        return Gallery.systemTabBarController(8)
    }

    static func customMoreStyle() -> CYLTabBarController {
        return Gallery.tabBarController(pages: Gallery.pages(8), attributes: Gallery.attributes(8), styleType: Gallery.fullWidthStyle)
    }

    static func mixtureMoreStyle() -> CYLTabBarController {
        let controller = customMoreStyle()
        for index in stride(from: 0, to: 8, by: 2) {
            controller.viewControllers?[index].cyl_tabButtonAnimation = GalleryBounceAnimation()
        }
        return controller
    }

    static func customGlassMoreStyle() -> CYLTabBarController {
        return Gallery.tabBarController(pages: Gallery.pages(8), attributes: Gallery.attributes(8))
    }

    /// [EN] The classic design on every system, white bar; "Photo" opens a dialog. [CN] 所有系统使用经典设计，白色 TabBar；"Photo" 打开对话框。
    static func mandatoryOldDesignStyle() -> CYLTabBarController {
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: Gallery.attributes(5), styleType: .flatDesign)
        Gallery.setBackgroundColor(of: controller, to: .white)
        Gallery.hijackPhotoTab(of: controller)
        return controller
    }

    /// [EN] New, 99+, a blue 1, a dot, none; the selected tab hides its badge. [CN] New、99+、蓝色 1、红点、无；选中的 Tab 隐藏角标。
    static func customGlassWithBadgeStyle() -> CYLTabBarController {
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: Gallery.attributes(5))
        addBadges(to: controller)
        controller.cyl_hidesBadgeOfSelectedTab = true
        return controller
    }

    static func addBadges(to tabBarController: UITabBarController) {
        guard let viewControllers = tabBarController.viewControllers, viewControllers.count >= 5 else {
            return
        }
        viewControllers[0].tabBarItem.badgeValue = "New"
        viewControllers[1].tabBarItem.badgeValue = "99+"
        viewControllers[2].tabBarItem.badgeValue = "1"
        viewControllers[2].tabBarItem.badgeColor = .blue
        viewControllers[3].tabBarItem.badgeValue = ""
        viewControllers[4].tabBarItem.badgeValue = nil
    }

    /// [EN] UITab (iOS 18+), eight tabs, "Favor" selected. [CN] UITab（iOS 18+），八个 Tab，选中 "Favor"。
    static func systemTabStyle() -> UITabBarController {
        guard #available(iOS 18.0, *) else {
            return Gallery.systemTabBarController(8)
        }
        let controller = UITabBarController()
        let tabs = Gallery.tabs.map { tab in
            UITab(title: tab.title, image: Gallery.symbol(tab.symbol, filled: false), identifier: tab.identifier) { _ in
                GalleryPageViewController()
            }
        }
        controller.tabs = tabs
        controller.selectedTab = tabs[3]
        return controller
    }

    // MARK: - Embed

    static func navigationWithTabbarStyle() -> UIViewController {
        return Gallery.embed(customStyle())
    }

    static func tabbarWithNavigationStyle() -> CYLTabBarController {
        return Gallery.tabBarController(pages: Gallery.pages(5, embedsInNavigation: true), attributes: Gallery.attributes(5))
    }

    // MARK: - Animation

    static func redAttributes(_ index: Int) -> [String: Any] {
        let gray = Gallery.gray(175)
        return [CYLTabBarItemTitleColor: gray, CYLTabBarItemSelectedTitleColor: Gallery.red,
                CYLTabBarItemIconColor: gray, CYLTabBarItemSelectedIconColor: Gallery.red]
    }

    static func customColorStyle() -> UIViewController {
        let attributes = Gallery.attributes(5, extra: redAttributes)
        return Gallery.embed(Gallery.tabBarController(pages: Gallery.pages(5), attributes: attributes))
    }

    static func customBouncesStyle() -> UIViewController {
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: Gallery.attributes(5, extra: redAttributes))
        controller.cyl_defaultTabButtonAnimation = GalleryBounceAnimation()
        return Gallery.embed(controller)
    }

    /// [EN] The dark image-only look: dark tabs, the selected one darker, the middle tab blue and larger.
    /// [CN] 深色纯图标外观：深色 Tab，选中的更深，中间 Tab 为蓝色且更大。
    static func backgroundTabBarController(styleType: CYLTabBarStyleType = Gallery.fullWidthStyle) -> CYLTabBarController {
        let attributes = Gallery.attributes(5, showsTitles: false, pointSize: 22) { index -> [String: Any] in
            if index == 2 {
                return [CYLTabBarItemImage: Gallery.symbol("camera", filled: false, pointSize: 28),
                        CYLTabBarItemSelectedImage: Gallery.symbol("camera", filled: true, pointSize: 28),
                        CYLTabBarItemIconColor: UIColor.white, CYLTabBarItemSelectedIconColor: UIColor.white,
                        CYLTabBarItemBackgroundColor: Gallery.rgb(17, 86, 136),
                        CYLTabBarItemSelectedBackgroundColor: Gallery.rgb(22, 24, 25)]
            }
            return [CYLTabBarItemIconColor: Gallery.gray(165), CYLTabBarItemSelectedIconColor: UIColor.white,
                    CYLTabBarItemBackgroundColor: Gallery.rgb(37, 39, 42),
                    CYLTabBarItemSelectedBackgroundColor: Gallery.rgb(22, 24, 25)]
        }
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: attributes, styleType: styleType)
        Gallery.setBackgroundColor(of: controller, to: Gallery.rgb(37, 39, 42))
        return controller
    }

    /// [EN] `implies`: the middle tab pulses every 3 s until it is selected. [CN] `implies`：中间 Tab 每 3 秒跳动一次，直到被选中。
    static func customBackgroundColorStyle(implies: Bool) -> UIViewController {
        let controller = backgroundTabBarController()
        if implies {
            let timer = Timer(timeInterval: 3, repeats: true) { [weak controller] timer in
                guard let controller = controller else {
                    timer.invalidate()
                    return
                }
                if controller.selectedIndex != 2 {
                    Gallery.playKeyframes(on: Gallery.iconView(of: controller, at: 2), keyPath: "transform.scale",
                                          values: [1.15, 0.8, 1.15], duration: 0.3)
                }
            }
            RunLoop.main.add(timer, forMode: .common)
        }
        return Gallery.embed(controller)
    }

    static func customHighlightableStyle() -> UIViewController {
        let controller = backgroundTabBarController()
        controller.cyl_defaultTabButtonAnimation = GalleryHighlightableAnimation()
        Gallery.forEachTabButton(of: controller) { button, _ in
            let scale = GalleryHighlightableAnimation.largeScale
            button.cyl_tabImageView()?.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
        return Gallery.embed(controller)
    }

    // MARK: - Irregular and customized clicks

    static func tealAttributes(_ index: Int) -> [String: Any] {
        return [CYLTabBarItemTitleColor: UIColor.white, CYLTabBarItemSelectedTitleColor: Gallery.teal,
                CYLTabBarItemIconColor: UIColor.white, CYLTabBarItemSelectedIconColor: Gallery.teal]
    }

    /// [EN] Home, Find, Favor and Me around a large round plus button. [CN] Home、Find、Favor、Me 位于大号圆形 PlusButton 两侧。
    static func irregularTabBarController() -> CYLTabBarController {
        GalleryIrregularPlusButton.register()
        let tabs = [Gallery.tabs[0], Gallery.tabs[1], Gallery.tabs[3], Gallery.tabs[4]]
        let attributes: [[String: Any]] = tabs.enumerated().map { index, tab in
            var item = tealAttributes(index)
            item[CYLTabBarItemTitle] = tab.title
            item[CYLTabBarItemImage] = Gallery.symbol(tab.symbol, filled: false)
            item[CYLTabBarItemSelectedImage] = Gallery.symbol(tab.symbol, filled: true)
            item[CYLTabBarItemIdentifier] = tab.identifier
            return item
        }
        let pages = Gallery.pages(4)
        let controller = Gallery.tabBarController(pages: pages, attributes: attributes, context: Gallery.irregularContext)
        pages.forEach { $0.cyl_tabButtonAnimation = GalleryBounceAnimation() }
        Gallery.setBackgroundColor(of: controller, to: Gallery.darkTeal)
        return controller
    }

    static func customIrregularityStyle() -> UIViewController {
        return Gallery.embed(irregularTabBarController())
    }

    /// [EN] A "New version" bubble above "Me"; "Photo" opens a dialog. [CN] "Me" 上方的 "New version" 气泡；"Photo" 打开对话框。
    static func customTipsStyle() -> UIViewController {
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: Gallery.attributes(5, extra: tealAttributes))
        controller.cyl_defaultTabButtonAnimation = GalleryBounceAnimation()
        Gallery.setBackgroundColor(of: controller, to: Gallery.darkTeal)
        Gallery.hijackPhotoTab(of: controller)
        // [EN] The bubble lives on the tab bar, not on the button, so it survives the page swaps of the "Photo" dialog.
        // [CN] 气泡加在 TabBar 上而不是按钮上，因此 "Photo" 对话框交换页面时不会丢失。
        Gallery.forEachTabButton(of: controller) { button, index in
            guard index == 4, let tabBar = button.superview else {
                return
            }
            let width: CGFloat = 120
            let buttonFrame = button.convert(button.bounds, to: tabBar)
            let bubble = Gallery.addBubble(to: tabBar, text: "New version", color: UIColor(white: 0, alpha: 0.75),
                                           frame: CGRect(x: buttonFrame.maxX - width, y: buttonFrame.minY - 40,
                                                         width: width, height: 36),
                                           font: .systemFont(ofSize: 14))
            bubble.autoresizingMask = [.flexibleLeftMargin]
        }
        return Gallery.embed(controller)
    }

    // MARK: - Remind

    static func systemRemindStyle() -> UITabBarController {
        let controller = Gallery.systemTabBarController(5)
        addBadges(to: controller)
        return controller
    }

    static func customRemindStyle() -> CYLTabBarController {
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: Gallery.attributes(5))
        addBadges(to: controller)
        return controller
    }

    /// [EN] The dark look, with a badge on "Find" two seconds after it appears. [CN] 深色外观，出现两秒后 "Find" 显示角标。
    static func remindStyle(animation: CYLTabButtonAnimation?, showBadge: @escaping (CYLTabBarController) -> Void) -> UIViewController {
        let controller = backgroundTabBarController()
        controller.cyl_defaultTabButtonAnimation = animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak controller] in
            if let controller = controller {
                showBadge(controller)
            }
        }
        return Gallery.embed(controller)
    }

    static func setFindBadge(_ controller: CYLTabBarController) {
        controller.viewControllers?[1].tabBarItem.badgeValue = "1"
    }

    /// [EN] The icon jumps when the badge appears (badge-changed hook). [CN] 角标出现时图标跳动（角标变化回调）。
    static func customAnimateRemindStyle() -> UIViewController {
        return remindStyle(animation: GalleryBadgeAnimation(style: .jumpingIcon), showBadge: setFindBadge)
    }

    /// [EN] The badge scales in when it appears (badge-changed hook). [CN] 角标出现时缩放弹出（角标变化回调）。
    static func customAnimateRemindStyle2() -> UIViewController {
        return remindStyle(animation: GalleryBadgeAnimation(style: .scalingBadge), showBadge: setFindBadge)
    }

    /// [EN] A gray bubble instead of the red badge. [CN] 用灰色气泡代替红色角标。
    static func customAnimateRemindStyle3() -> UIViewController {
        return remindStyle(animation: nil) { controller in
            guard let viewControllers = controller.viewControllers, viewControllers.count > 1,
                  let button = Gallery.tabButton(of: viewControllers[1]) else {
                return
            }
            let bubble = Gallery.addBubble(to: button, text: "1", color: .lightGray,
                                           frame: CGRect(x: button.bounds.midX + 2, y: -4, width: 30, height: 26),
                                           font: .systemFont(ofSize: 13))
            Gallery.playKeyframes(on: bubble, keyPath: "transform.scale", values: Gallery.bounceValues, duration: 0.6)
        }
    }

    // MARK: - Lottie

    /// [EN] The middle tab loops its Lottie animation until it is selected. [CN] 中间 Tab 循环播放 Lottie 动画，直到被选中。
    static func lottieStyle() -> CYLTabBarController {
        let normal = Gallery.rgb(61, 206, 193)
        let selected = Gallery.rgb(252, 13, 27)
        let lottieURL = Bundle.main.url(forResource: "tab_search_animate", withExtension: "json")
        let attributes = Gallery.attributes(5, showsTitles: false, pointSize: 22) { index -> [String: Any] in
            var item: [String: Any] = [CYLTabBarItemIconColor: normal, CYLTabBarItemSelectedIconColor: selected]
            if index == 2, let lottieURL = lottieURL {
                item[CYLTabBarLottieURL] = lottieURL
                item[CYLTabBarLottieSize] = NSValue(cgSize: CGSize(width: 33, height: 33))
                item[CYLTabBarLottieLoopsWhenUnselected] = true
            }
            return item
        }
        return Gallery.tabBarController(pages: Gallery.pages(5), attributes: attributes)
    }

    // MARK: - New APIs

    static func reselectStyle() -> CYLTabBarController {
        let pages: [UIViewController] = (0..<3).map { index in
            let list = GalleryListViewController(style: .plain)
            list.title = Gallery.tabs[index].title
            return GalleryNavigationController(rootViewController: list)
        }
        let controller = Gallery.tabBarController(pages: pages, attributes: Gallery.attributes(3))
        controller.cyl_reselectBehavior = .popToRootThenScrollToTop
        return controller
    }

    static func pressAndReselectStyle() -> CYLTabBarController {
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: Gallery.attributes(5))
        controller.cyl_defaultTabButtonAnimation = GalleryPressAndReselectAnimation()
        return controller
    }

    static func hijackStyle() -> CYLTabBarController {
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: Gallery.attributes(5))
        Gallery.hijackPhotoTab(of: controller)
        return controller
    }

    static func perTabStyle() -> CYLTabBarController {
        let colors: [UIColor] = [.systemRed, .systemOrange, .systemGreen, .systemBlue, .systemPurple]
        let attributes = Gallery.attributes(5) { index -> [String: Any] in
            let color = colors[index]
            return [CYLTabBarItemSelectedTitleColor: color, CYLTabBarItemSelectedIconColor: color,
                    CYLTabBarItemTitleFont: UIFont.systemFont(ofSize: 10),
                    CYLTabBarItemSelectedTitleFont: UIFont.systemFont(ofSize: 11, weight: .bold),
                    CYLTabBarItemSelectedBackgroundColor: color.withAlphaComponent(0.12)]
        }
        return Gallery.tabBarController(pages: Gallery.pages(5), attributes: attributes)
    }

    static func accessibilityStyle() -> UIViewController {
        let controller = Gallery.tabBarController(pages: Gallery.pages(5), attributes: Gallery.attributes(5))
        controller.performWhenTabBarItemsReady { tabBarController in
            let identifiers = (tabBarController.viewControllers ?? []).map {
                $0.tabBarItem.accessibilityIdentifier ?? $0.cyl_tabBarItemIdentifier ?? "-"
            }
            tabBarController.navigationItem.title = identifiers.joined(separator: ", ")
        }
        return Gallery.embed(controller)
    }

    static func centeredStyle() -> UIViewController {
        let controller = irregularTabBarController()
        controller.tabBar.itemPositioning = .centered
        controller.tabBar.itemWidth = 64
        controller.tabBar.itemSpacing = 12
        return Gallery.embed(controller)
    }

    static func edgeInsetsStyle() -> UIViewController {
        let controller = backgroundTabBarController(styleType: .default)
        controller.tabBar.cyl_itemEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        controller.tabBar.itemSpacing = 2
        Gallery.setBackgroundColor(of: controller, to: .black)
        return Gallery.embed(controller)
    }
}
