//
//  CYLGalleryProvider.swift
//  CYLTabBarController
//
//  Ported from Objective-C on 2026/11/11: the examples are Swift only.
//

import UIKit
import CYLTabBarController

/**
 * [EN] The scenes of the tab bar gallery (the "Liquid Glass robustness" section demonstrates the bounds checks, the marked
 *      inserted views, the plus button's stand-in that follows layout, and More editing; see docs/Liquid-Glass-Robustness.md):
 *      the system baselines, embedding, animations, an irregular center button, custom clicks, reminders, Lottie, and the
 *      newer tab APIs. The order is kept: scripts and docs open scenes by their `section.row` number. See
 *      docs/Tab-Bar-Gallery.md.
 * [CN] TabBar 图库中的场景（「Liquid Glass robustness」一组演示下标检查、被标记的插入视图、随布局安装的 PlusButton 替身与「More」编辑，见
 *      docs/Liquid-Glass-Robustness.md）：系统样式对照、嵌套、动画、不规则中间按钮、自定义点击、提醒、Lottie，以及新增的 Tab 接口。
 *      顺序保持不变：脚本与文档按 `分组.行` 编号打开场景。见 docs/Tab-Bar-Gallery.md。
 */
enum CYLGalleryProvider {

    static func sections() -> [CYLGallerySection] {
        [basicSection(), embedSection(), animationSection(), irregularSection(), customClickSection(), remindSection(),
         lottieSection(), newAPISection(), liquidGlassRobustnessSection(), moreThanFiveTabsSection()]
    }

    // MARK: - Basic

    private static func fullWidthTabBarController(count: Int) -> CYLTabBarController {
        CYLGallery.tabBarController(pages: CYLGallery.pages(count, embedsInNavigation: false),
                                    attributes: CYLGallery.attributes(count, showsTitles: true, pointSize: 20),
                                    styleType: CYLGallery.fullWidthStyle, context: CYLGallery.context)
    }

    private static func defaultTabBarController(count: Int) -> CYLTabBarController {
        CYLGallery.tabBarController(pages: CYLGallery.pages(count, embedsInNavigation: false),
                                    attributes: CYLGallery.attributes(count, showsTitles: true, pointSize: 20),
                                    styleType: .default, context: CYLGallery.context)
    }

    private static func bounceEveryOtherTab(of tabBarController: CYLTabBarController, count: Int) {
        for index in stride(from: 0, to: count, by: 2) {
            tabBarController.viewControllers?[index].cyl_tabButtonAnimation = CYLGalleryBounceAnimation()
        }
    }

    private static func basicSection() -> CYLGallerySection {
        let selectThirdTab: (UIViewController) -> Void = { presented in
            (presented as? UITabBarController)?.selectedIndex = 2
        }
        let scenes = [
            CYLGalleryScene(title: "UITabBarController style", subtitle: "The system tab bar, for comparison") {
                CYLGallery.systemTabBarController(5)
            },
            CYLGalleryScene(title: "CYLTabBarController like system style", subtitle: "Three tabs; full width on iOS 26 (FlatDesign)") {
                fullWidthTabBarController(count: 3)
            },
            CYLGalleryScene(title: "Mix styled and system items", subtitle: "Tabs 1, 3 and 5 bounce; tabs 2 and 4 are plain") {
                let tabBarController = defaultTabBarController(count: 5)
                bounceEveryOtherTab(of: tabBarController, count: 5)
                return tabBarController
            },
            CYLGalleryScene(title: "CYLTabBarController with Liquid Glass", subtitle: "\"Photo\" opens a dialog (cyl_customActionTabBarItemIdentifiers)") {
                let tabBarController = defaultTabBarController(count: 5)
                CYLGallery.useCustomActionForPhotoTab(of: tabBarController)
                return tabBarController
            },
            CYLGalleryScene(title: "UITabBarController with 'More'", subtitle: "Eight tabs; \"Photo\" opens a dialog (delegate)") {
                let tabBarController = CYLGallery.systemTabBarController(8)
                tabBarController.delegate = CYLGallerySystemPhotoActionDelegate.shared
                return tabBarController
            },
            CYLGalleryScene(title: "CYLTabBarController with 'More'", subtitle: "Eight tabs, full width") {
                fullWidthTabBarController(count: 8)
            },
            CYLGalleryScene(title: "Mix styled and system items with 'More'", subtitle: "Eight tabs; every other one bounces") {
                let tabBarController = fullWidthTabBarController(count: 8)
                bounceEveryOtherTab(of: tabBarController, count: 8)
                return tabBarController
            },
            CYLGalleryScene(title: "Liquid Glass with 'More'", subtitle: "Eight tabs with Liquid Glass") {
                defaultTabBarController(count: 8)
            },
            CYLGalleryScene(title: "UITabBarController with non-zero default index", subtitle: "selectedIndex = 2 after presenting",
                            builder: { CYLGallery.systemTabBarController(5) }, didPresent: selectThirdTab),
            CYLGalleryScene(title: "CYLTabBarController with non-zero default index", subtitle: "selectedIndex = 2 after presenting",
                            builder: { fullWidthTabBarController(count: 3) }, didPresent: selectThirdTab),
            CYLGalleryScene(title: "Classic design on every system", subtitle: "CYLTabBarStyleTypeFlatDesign, white bar; \"Photo\" opens a dialog") {
                let tabBarController = CYLGallery.tabBarController(pages: CYLGallery.pages(5, embedsInNavigation: false),
                                                                   attributes: CYLGallery.attributes(5, showsTitles: true, pointSize: 20),
                                                                   styleType: .flatDesign, context: CYLGallery.context)
                CYLGallery.setTabBarBackgroundColor(tabBarController, .white)
                CYLGallery.useCustomActionForPhotoTab(of: tabBarController)
                return tabBarController
            },
            CYLGalleryScene(title: "Liquid Glass with badges", subtitle: "New, 99+, a blue 1, a dot, none; the selected tab hides its badge") {
                let tabBarController = defaultTabBarController(count: 5)
                addSystemBadges(to: tabBarController)
                // [EN] The selected tab hides its badge; the others keep theirs. [CN] 选中的 Tab 隐藏角标，其他 Tab 保留。
                tabBarController.cyl_hidesBadgeOfSelectedTab = true
                return tabBarController
            },
            CYLGalleryScene(title: "UITabBarController tab style", subtitle: "UITab (iOS 18+), eight tabs, \"Favor\" selected") {
                systemTabStyleTabBarController()
            },
        ]
        return CYLGallerySection(title: "Basic", scenes: scenes)
    }

    private static func addSystemBadges(to tabBarController: UITabBarController) {
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

    private static func systemTabStyleTabBarController() -> UITabBarController {
        guard #available(iOS 18.0, *) else {
            return CYLGallery.systemTabBarController(8)
        }
        let tabBarController = UITabBarController()
        let tabs = CYLGallery.tabSpecs.map { spec in
            UITab(title: spec.title, image: CYLGallery.symbol(spec.symbol, filled: false, pointSize: 20), identifier: spec.identifier) { _ in
                CYLGalleryPageViewController()
            }
        }
        tabBarController.tabs = tabs
        tabBarController.selectedTab = tabs[3]
        tabBarController.delegate = CYLGallerySystemPhotoActionDelegate.shared
        return tabBarController
    }

    // MARK: - Embed

    private static func embedSection() -> CYLGallerySection {
        let scenes = [
            CYLGalleryScene(title: "UINavigationController embeds CYLTabBarController", subtitle: "One navigation bar above the tab bar controller") {
                CYLGallery.embed(fullWidthTabBarController(count: 3))
            },
            CYLGalleryScene(title: "CYLTabBarController embeds UINavigationController", subtitle: "A navigation controller in every tab") {
                CYLGallery.tabBarController(pages: CYLGallery.pages(5, embedsInNavigation: true),
                                            attributes: CYLGallery.attributes(5, showsTitles: true, pointSize: 20),
                                            styleType: .default, context: CYLGallery.context)
            },
        ]
        return CYLGallerySection(title: "Embed", scenes: scenes)
    }

    // MARK: - Animation

    private static func redTabBarController() -> CYLTabBarController {
        let attributes = CYLGallery.attributes(5, showsTitles: true, pointSize: 20) { _ in CYLGallery.redTabAttributes() }
        return CYLGallery.tabBarController(pages: CYLGallery.pages(5, embedsInNavigation: false), attributes: attributes,
                                           styleType: .default, context: CYLGallery.context)
    }

    private static func animationSection() -> CYLGallerySection {
        let scenes = [
            CYLGalleryScene(title: "Customize the selected color", subtitle: "CYLTabBarItemTitleColor / IconColor per tab") {
                CYLGallery.embed(redTabBarController())
            },
            CYLGalleryScene(title: "Spring animation", subtitle: "A CYLTabButtonAnimation that bounces on select and reselect") {
                let tabBarController = redTabBarController()
                tabBarController.cyl_defaultTabButtonAnimation = CYLGalleryBounceAnimation()
                return CYLGallery.embed(tabBarController)
            },
            CYLGalleryScene(title: "Background color change", subtitle: "CYLTabBarItemBackgroundColor / SelectedBackgroundColor") {
                CYLGallery.embed(CYLGallery.backgroundTabBarController())
            },
            CYLGalleryScene(title: "With a pressed effect", subtitle: "Larger icons that shrink while pressed (highlight hooks)") {
                let tabBarController = CYLGallery.backgroundTabBarController()
                tabBarController.cyl_defaultTabButtonAnimation = CYLGalleryHighlightAnimation()
                CYLGallery.forEachTabButton(of: tabBarController) { button, _ in
                    button.cyl_tabImageView()?.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
                }
                return CYLGallery.embed(tabBarController)
            },
            CYLGalleryScene(title: "Suggest a click", subtitle: "The middle tab pulses every 3 s until it is selected") {
                let tabBarController = CYLGallery.backgroundTabBarController()
                CYLGallery.repeatEvery(3, while: tabBarController) { controller in
                    guard controller.selectedIndex != 2 else {
                        return
                    }
                    CYLGallery.playKeyframes(on: CYLGallery.iconView(of: controller, at: 2), keyPath: "transform.scale",
                                             values: [1.15, 0.8, 1.15], duration: 0.3)
                }
                return CYLGallery.embed(tabBarController)
            },
        ]
        return CYLGallerySection(title: "Animation", scenes: scenes)
    }

    // MARK: - Irregular

    /**
     * [EN] Four teal tabs (Home, Find, Favor, Me) around the large round center button.
     * [CN] 大号圆形中间按钮两侧的四个青色 Tab（Home、Find、Favor、Me）。
     */
    private static func irregularScene() -> UIViewController {
        CYLGalleryIrregularPlusButton.register()
        var items = CYLGallery.attributes(4, showsTitles: true, pointSize: 20) { _ in CYLGallery.tealTabAttributes() }
        for index in 2..<4 {
            let spec = CYLGallery.tabSpecs[index + 1]
            items[index][CYLTabBarItemTitle] = spec.title
            items[index][CYLTabBarItemImage] = CYLGallery.symbol(spec.symbol, filled: false, pointSize: 20)
            items[index][CYLTabBarItemSelectedImage] = CYLGallery.symbol(spec.symbol, filled: true, pointSize: 20)
            items[index][CYLTabBarItemIdentifier] = spec.identifier
        }
        let pages = CYLGallery.pages(4, embedsInNavigation: false)
        let tabBarController = CYLGallery.tabBarController(pages: pages, attributes: items, styleType: .default,
                                                           context: CYLGallery.irregularContext)
        for page in pages {
            page.cyl_tabButtonAnimation = CYLGalleryBounceAnimation()
        }
        CYLGallery.setTabBarBackgroundColor(tabBarController, CYLGallery.rgb(10, 66, 91))
        return CYLGallery.embed(tabBarController)
    }

    private static func irregularSection() -> CYLGallerySection {
        CYLGallerySection(title: "Irregular", scenes: [
            CYLGalleryScene(title: "A larger button in the middle", subtitle: "A raised round CYLPlusButton that responds inside its circle") {
                irregularScene()
            },
        ])
    }

    // MARK: - Customize click

    private static func customClickSection() -> CYLGallerySection {
        let scenes = [
            CYLGalleryScene(title: "Custom action for the button click", subtitle: "The center button shows an action sheet instead of a page") {
                irregularScene()
            },
            CYLGalleryScene(title: "Add a special reminder bubble", subtitle: "A bubble above \"Me\"; \"Photo\" opens a dialog") {
                let attributes = CYLGallery.attributes(5, showsTitles: true, pointSize: 20) { _ in CYLGallery.tealTabAttributes() }
                let tabBarController = CYLGallery.tabBarController(pages: CYLGallery.pages(5, embedsInNavigation: false),
                                                                   attributes: attributes, styleType: .default, context: CYLGallery.context)
                tabBarController.cyl_defaultTabButtonAnimation = CYLGalleryBounceAnimation()
                CYLGallery.setTabBarBackgroundColor(tabBarController, CYLGallery.rgb(10, 66, 91))
                CYLGallery.useCustomActionForPhotoTab(of: tabBarController)
                CYLGallery.forEachTabButton(of: tabBarController) { button, index in
                    guard index == 4, let tabBar = button.superview else {
                        return
                    }
                    // [EN] The bubble lives on the tab bar, not on the button, so it survives the page swaps of the "Photo" dialog.
                    // [CN] 气泡加在 TabBar 上而不是按钮上，因此 "Photo" 对话框交换页面时不会丢失。
                    let width: CGFloat = 120
                    let buttonFrame = button.convert(button.bounds, to: tabBar)
                    let bubble = CYLGallery.addBubble(to: tabBar, text: cylDemoLocalizedString("新版本"), color: UIColor(white: 0, alpha: 0.75),
                                                      frame: CGRect(x: buttonFrame.maxX - width, y: buttonFrame.minY - 40, width: width, height: 36),
                                                      font: .systemFont(ofSize: 14))
                    bubble.autoresizingMask = .flexibleLeftMargin
                }
                return CYLGallery.embed(tabBarController)
            },
        ]
        return CYLGallerySection(title: "Customize click", scenes: scenes)
    }

    // MARK: - Remind

    /**
     * [EN] The background look, with a badge shown by `showBadge` two seconds after it appears.
     * [CN] 背景色外观，出现两秒后由 `showBadge` 显示角标。
     */
    private static func remindScene(animation: CYLTabButtonAnimation? = nil,
                                    showBadge: @escaping (CYLTabBarController) -> Void) -> UIViewController {
        let tabBarController = CYLGallery.backgroundTabBarController()
        if let animation {
            tabBarController.cyl_defaultTabButtonAnimation = animation
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak tabBarController] in
            if let tabBarController {
                showBadge(tabBarController)
            }
        }
        return CYLGallery.embed(tabBarController)
    }

    private static func remindSection() -> CYLGallerySection {
        let showFindBadge: (CYLTabBarController) -> Void = { $0.viewControllers?[1].tabBarItem.badgeValue = "1" }
        let scenes = [
            CYLGalleryScene(title: "System remind style", subtitle: "UITabBarItem badges on the system tab bar") {
                let tabBarController = CYLGallery.systemTabBarController(5)
                addSystemBadges(to: tabBarController)
                return tabBarController
            },
            CYLGalleryScene(title: "Imitate system remind style", subtitle: "The same badges on CYLTabBarController") {
                let tabBarController = defaultTabBarController(count: 5)
                addSystemBadges(to: tabBarController)
                return tabBarController
            },
            CYLGalleryScene(title: "Remind with animation", subtitle: "The icon jumps when the badge appears (CYLTabButtonBlockAnimation.badgeChangedAnimation)") {
                remindScene(animation: CYLGallery.badgeJumpAnimation(), showBadge: showFindBadge)
            },
            CYLGalleryScene(title: "Remind with animation (2)", subtitle: "The badge scales in when it appears (CYLTabButtonBlockAnimation.badgeChangedAnimation)") {
                remindScene(animation: CYLGallery.badgeScaleAnimation(), showBadge: showFindBadge)
            },
            CYLGalleryScene(title: "Customize remind style", subtitle: "A gray bubble instead of the red badge") {
                remindScene { tabBarController in
                    guard let viewController = tabBarController.viewControllers?[1],
                          let button = viewController.tabBarItem.cyl_tabButton ?? viewController.cyl_tabButton else {
                        return
                    }
                    let bubble = CYLGallery.addBubble(to: button, text: "1", color: .lightGray,
                                                      frame: CGRect(x: button.bounds.midX + 2, y: -4, width: 30, height: 26),
                                                      font: .systemFont(ofSize: 13))
                    CYLGallery.playKeyframes(on: bubble, keyPath: "transform.scale", values: [1.0, 1.4, 0.9, 1.15, 0.95, 1.02, 1.0], duration: 0.6)
                }
            },
        ]
        return CYLGallerySection(title: "Remind", scenes: scenes)
    }

    // MARK: - Lottie

    private static func lottieSection() -> CYLGallerySection {
        CYLGallerySection(title: "Lottie", scenes: [
            CYLGalleryScene(title: "Lottie", subtitle: "The middle tab loops its Lottie animation until it is selected (CYLTabBarLottieLoopsWhenUnselected)") {
                let normal = CYLGallery.rgb(61, 206, 193)
                let selected = CYLGallery.rgb(252, 13, 27)
                let lottieURL = Bundle.main.url(forResource: "tab_search_animate", withExtension: "json")
                let attributes = CYLGallery.attributes(5, showsTitles: false, pointSize: 22) { index in
                    var item: [String: Any] = [CYLTabBarItemIconColor: normal, CYLTabBarItemSelectedIconColor: selected]
                    if index == 2, let lottieURL {
                        item[CYLTabBarLottieURL] = lottieURL
                        item[CYLTabBarLottieSize] = NSValue(cgSize: CGSize(width: 33, height: 33))
                        // [EN] Loops while unselected, pauses while selected. [CN] 未选中时循环播放，选中时暂停。
                        item[CYLTabBarLottieLoopsWhenUnselected] = true
                    }
                    return item
                }
                return CYLGallery.tabBarController(pages: CYLGallery.pages(5, embedsInNavigation: false), attributes: attributes,
                                                   styleType: .default, context: CYLGallery.context)
            },
        ])
    }

    // MARK: - New APIs

    private static func newAPISection() -> CYLGallerySection {
        let scenes = [
            CYLGalleryScene(title: "Reselect: pop to root, then scroll to top", subtitle: "cyl_reselectBehavior = PopToRootThenScrollToTop") {
                let pages: [UIViewController] = (0..<3).map { index in
                    let list = CYLGalleryListViewController()
                    list.title = CYLGallery.tabSpecs[index].title
                    return CYLGalleryNavigationController(rootViewController: list)
                }
                let tabBarController = CYLGallery.tabBarController(pages: pages, attributes: CYLGallery.attributes(3, showsTitles: true, pointSize: 20),
                                                                   styleType: .default, context: CYLGallery.context)
                tabBarController.cyl_reselectBehavior = .popToRootThenScrollToTop
                return tabBarController
            },
            CYLGalleryScene(title: "Press and reselect animations", subtitle: "CYLTabButtonPressAnimation + a reselect turn") {
                let tabBarController = defaultTabBarController(count: 5)
                tabBarController.cyl_defaultTabButtonAnimation = CYLGalleryPressAndReselectAnimation()
                return tabBarController
            },
            CYLGalleryScene(title: "Custom action on a regular tab", subtitle: "cyl_customActionTabBarItemIdentifiers + cyl_customTabActionHandler") {
                let tabBarController = defaultTabBarController(count: 5)
                CYLGallery.useCustomActionForPhotoTab(of: tabBarController)
                return tabBarController
            },
            CYLGalleryScene(title: "Per-tab colors, fonts and backgrounds", subtitle: "Every tab has its own title color, font and background") {
                let colors: [UIColor] = [.systemRed, .systemOrange, .systemGreen, .systemBlue, .systemPurple]
                let attributes = CYLGallery.attributes(5, showsTitles: true, pointSize: 20) { index in
                    let color = colors[index]
                    return [CYLTabBarItemSelectedTitleColor: color, CYLTabBarItemSelectedIconColor: color,
                            CYLTabBarItemTitleFont: UIFont.systemFont(ofSize: 10),
                            CYLTabBarItemSelectedTitleFont: UIFont.systemFont(ofSize: 11, weight: .bold),
                            CYLTabBarItemSelectedBackgroundColor: color.withAlphaComponent(0.12)]
                }
                return CYLGallery.tabBarController(pages: CYLGallery.pages(5, embedsInNavigation: false), attributes: attributes,
                                                   styleType: .default, context: CYLGallery.context)
            },
            // [EN] Issue #787: Home and Video are templates (Home with its own gray / red icon colors, Video with the bar's
            //      tint), Fishpond keeps its colors although it has an icon color ("original"), Account is "automatic".
            // [CN] Issue #787：Home 与 Video 为模板（Home 使用自己的灰 / 红图标颜色，Video 使用 TabBar 着色），Fishpond 虽有图标颜色仍保持原色
            //      （"original"），Account 为 "automatic"（按原图绘制）。
            CYLGalleryScene(title: "Icon rendering mode (#787)", subtitle: "template: one image, two colors · original: own colors · automatic") {
                CYLGallery.tabBarController(pages: CYLGallery.pages(4, embedsInNavigation: false), attributes: CYLGallery.iconRenderingAttributes(),
                                            styleType: .default, context: CYLGallery.context)
            },
            CYLGalleryScene(title: "Icon rendering mode on Liquid Glass (#787)", subtitle: "template icons take the bar's tint without an icon color") {
                CYLGallery.tabBarController(pages: CYLGallery.pages(4, embedsInNavigation: false), attributes: CYLGallery.iconRenderingAttributes(),
                                            styleType: .liquidGlass, context: CYLGallery.context)
            },
            CYLGalleryScene(title: "Accessibility identifiers", subtitle: "Each tab is app.tabBars.buttons[\"home\"] etc. in UI tests") {
                let tabBarController = defaultTabBarController(count: 5)
                CYLGallery.whenTabBarItemsReady(tabBarController) { controller in
                    controller.navigationItem.title = tabIdentifiers(of: controller)
                }
                return CYLGallery.embed(tabBarController)
            },
            CYLGalleryScene(title: "Centered tabs around a plus button", subtitle: "itemPositioning = Centered, itemWidth 64, itemSpacing 12") {
                let navigationController = irregularScene()
                if let tabBarController = (navigationController as? UINavigationController)?.viewControllers.first as? UITabBarController {
                    tabBarController.tabBar.itemPositioning = .centered
                    tabBarController.tabBar.itemWidth = 64
                    tabBarController.tabBar.itemSpacing = 12
                }
                return navigationController
            },
            CYLGalleryScene(title: "Edge insets and gaps between tabs",
                            subtitle: "cyl_itemEdgeInsets 16 pt + itemSpacing 2 pt; classic tab bar (iOS 25 and earlier, or iOS 26 compatibility mode)") {
                let attributes = CYLGallery.attributes(5, showsTitles: false, pointSize: 22) { index in
                    CYLGallery.darkTabAttributes(special: index == 2)
                }
                let tabBarController = CYLGallery.tabBarController(pages: CYLGallery.pages(5, embedsInNavigation: false), attributes: attributes,
                                                                   styleType: .default, context: CYLGallery.context)
                tabBarController.tabBar.cyl_itemEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
                tabBarController.tabBar.itemSpacing = 2
                CYLGallery.setTabBarBackgroundColor(tabBarController, .black)
                return CYLGallery.embed(tabBarController)
            },
        ]
        return CYLGallerySection(title: "New APIs", scenes: scenes)
    }

    // MARK: - Liquid Glass robustness

    /**
     * [EN] Four tabs around the plus button that has its own page; `titles` replaces the first titles.
     * [CN] 拥有自己页面的 PlusButton 两侧的四个 Tab；`titles` 替换前几个标题。
     */
    private static func plusPageTabBarController(titles: [String] = []) -> CYLTabBarController {
        CYLGalleryPagePlusButton.register()
        var attributes = CYLGallery.attributes(5, showsTitles: true, pointSize: 20)
        attributes.remove(at: 2)
        for (index, title) in titles.enumerated() {
            attributes[index][CYLTabBarItemTitle] = title
        }
        var pages = CYLGallery.pages(5, embedsInNavigation: false)
        pages.remove(at: 2)
        return CYLGallery.tabBarController(pages: pages, attributes: attributes, styleType: .default, context: CYLGallery.plusPageContext)
    }

    /**
     * [EN] Shows how many marked views the tab bar holds, in the navigation bar. [CN] 在导航栏中显示 TabBar 中被标记视图的数量。
     */
    /**
     * [EN] The accessibility identifier of every tab, joined. [CN] 每个 Tab 的无障碍标识，用逗号连接。
     */
    private static func tabIdentifiers(of controller: CYLTabBarController) -> String {
        (controller.viewControllers ?? []).map(tabIdentifier(of:)).joined(separator: ", ")
    }

    private static func tabIdentifier(of viewController: UIViewController) -> String {
        viewController.tabBarItem.accessibilityIdentifier ?? viewController.cyl_tabBarItemIdentifier ?? "-"
    }

    /**
     * [EN] The class name of `object`, or "nil". [CN] `object` 的类名，没有时为 "nil"。
     */
    private static func className(of object: AnyObject?) -> String {
        guard let object else {
            return "nil"
        }
        return NSStringFromClass(type(of: object))
    }

    /**
     * [EN] `value` as text, or "nil". [CN] `value` 的文字描述，没有时为 "nil"。
     */
    private static func describe(_ value: Any?) -> String {
        guard let value else {
            return "nil"
        }
        return "\(value)"
    }

    /**
     * [EN] A star replaces Home's icon, then the marked views are counted on the next run loop turn.
     * [CN] 用星星替换 Home 的图标，然后在下一个 runloop 统计被标记的视图。
     */
    private static func markHomeIconWithStar(in controller: CYLTabBarController) {
        controller.viewControllers?.first?.cyl_tabButton?.cyl_replaceTabImageView(withNewView: CYLGallery.starView(), show: true)
        DispatchQueue.main.async { [weak controller] in
            if let controller {
                showMarkedViewCount(of: controller)
            }
        }
    }

    /**
     * [EN] Hides every marked view when any is shown, else shows them all, in one pass.
     * [CN] 只要有被标记的视图在显示就全部隐藏，否则全部显示，一次完成。
     */
    private static func toggleMarkedViews(in controller: CYLTabBarController) {
        let views = CYLGallery.markedViews(in: controller.tabBar)
        let hides = views.contains(where: isShown(_:))
        for view in views {
            view.isHidden = hides
        }
        showMarkedViewCount(of: controller)
    }

    private static func isShown(_ view: UIView) -> Bool {
        !view.isHidden
    }

    private static func showMarkedViewCount(of tabBarController: CYLTabBarController) {
        let views = CYLGallery.markedViews(in: tabBarController.tabBar)
        let hiddenCount = views.filter(\.isHidden).count
        tabBarController.navigationItem.title = "\(views.count) marked, \(hiddenCount) hidden"
    }

    private static func liquidGlassRobustnessSection() -> CYLGallerySection {
        let scenes = [
            CYLGalleryScene(title: "Selected control with bounds checks", subtitle: "cyl_selectedControl falls back in order; \"Read\" shows its index and class") {
                let tabBarController = defaultTabBarController(count: 5)
                let read: () -> Void = { [weak tabBarController] in
                    guard let controller = tabBarController else {
                        return
                    }
                    let tabBar = controller.tabBar
                    controller.navigationItem.title = "index \(tabBar.cyl_selectedIndex()), \(className(of: tabBar.cyl_selectedControl))"
                }
                tabBarController.navigationItem.rightBarButtonItem = CYLGallery.barButtonItem("Read", read)
                CYLGallery.whenTabBarItemsReady(tabBarController) { _ in read() }
                return CYLGallery.embed(tabBarController)
            },
            CYLGalleryScene(title: "Out-of-range reads return nil", subtitle: "Index 99 on the platter / tab button readers: nil, no exception") {
                let tabBarController = defaultTabBarController(count: 5)
                tabBarController.navigationItem.rightBarButtonItem = CYLGallery.barButtonItem("Read 99") { [weak tabBarController] in
                    guard let controller = tabBarController else {
                        return
                    }
                    let tabBar = controller.tabBar
                    let lines = [
                        "cyl_platterContentViewWithIndex: \(describe(tabBar.cyl_platterContentView(with: 99)))",
                        "cyl_platterSelectedContentViewWithIndex: \(describe(tabBar.cyl_platterSelectedContentView(with: 99)))",
                        "cyl_tabBarButtonWithTabIndex: \(describe(tabBar.cyl_tabBarButton(withTabIndex: 99)))",
                    ]
                    let alert = UIAlertController(title: "Index 99", message: lines.joined(separator: "\n"), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: cylDemoLocalizedString("好"), style: .cancel))
                    controller.present(alert, animated: true)
                }
                return CYLGallery.embed(tabBarController)
            },
            CYLGalleryScene(title: "Marked views in tab buttons", subtitle: "A star replaces Home's icon; \"Hide\" / \"Show\" toggles every marked view in one pass") {
                let tabBarController = defaultTabBarController(count: 5)
                CYLGallery.whenTabBarItemsReady(tabBarController) { controller in
                    markHomeIconWithStar(in: controller)
                }
                tabBarController.navigationItem.rightBarButtonItem = CYLGallery.barButtonItem("Hide / Show") { [weak tabBarController] in
                    guard let controller = tabBarController else {
                        return
                    }
                    toggleMarkedViews(in: controller)
                }
                return CYLGallery.embed(tabBarController)
            },
            CYLGalleryScene(title: "Plus stand-in after an item image changes",
                            subtitle: "Select the plus tab, then \"Change image\": UIKit rebuilds the buttons and the stand-in moves to the new one (Liquid Glass)",
                            builder: {
                                let tabBarController = plusPageTabBarController()
                                var usesAlternateImage = false
                                tabBarController.navigationItem.rightBarButtonItem = CYLGallery.barButtonItem("Change image") { [weak tabBarController] in
                                    usesAlternateImage.toggle()
                                    let name = usesAlternateImage ? "sun.max" : "house"
                                    let item = tabBarController?.viewControllers?.first?.tabBarItem
                                    item?.image = CYLGallery.symbol(name, filled: false, pointSize: 20)
                                    item?.selectedImage = CYLGallery.symbol(name, filled: true, pointSize: 20)
                                }
                                return CYLGallery.embed(tabBarController)
                            },
                            didPresent: { presented in
                                ((presented as? UINavigationController)?.viewControllers.first as? UITabBarController)?.selectedIndex = 2
                            }),
            CYLGalleryScene(title: "Plus stand-in on first display and rotation",
                            subtitle: "The plus tab is selected at once; rotate the device: the stand-in follows layout, no fixed delay (Liquid Glass)") {
                let tabBarController = plusPageTabBarController()
                tabBarController.selectedIndex = 2
                return CYLGallery.embed(tabBarController)
            },
            CYLGalleryScene(title: "More editing with 8 tabs",
                            subtitle: "Pushed. More → Edit → drag → Done: the star (a marked view) hides while editing and comes back after",
                            pushes: true) {
                let tabBarController = defaultTabBarController(count: 8)
                tabBarController.title = cylDemoLocalizedString("编辑更多")
                CYLGallery.whenTabBarItemsReady(tabBarController) { controller in
                    controller.viewControllers?.first?.cyl_tabButton?.cyl_replaceTabImageView(withNewView: CYLGallery.starView(), show: true)
                }
                return tabBarController
            },
            // [EN] Long titles on both tabs left of the plus button: before the title width limit, Liquid Glass made those
            //      tab buttons wider, so the plus button's slot moved right of the middle.
            // [CN] PlusButton 左侧两个 Tab 都使用长标题：限制标题宽度之前，液态玻璃会把这两个 Tab 按钮变宽，PlusButton 的 slot 偏到中间右侧。
            CYLGalleryScene(title: "Long titles left of the plus button",
                            subtitle: "Both tabs left of the plus button have long titles: they are cut to the width of one tab, so the plus button stays in the middle") {
                CYLGallery.embed(plusPageTabBarController(titles: ["Scene one: review filter", "Scene two: search and sort"]))
            },
        ]
        return CYLGallerySection(title: "Liquid Glass robustness", scenes: scenes)
    }

    // MARK: - More than five tabs (issue #472)

    /**
     * [EN] Issue #472: more than five tabs without the system "More". UIKit adds "More" as soon as a tab bar controller has
     *      more than five view controllers; so the controller gets five, and the fifth tab is an overflow slot. Tapping it
     *      (or tapping it again while it is selected) shows your own menu of the other pages; the chosen page is put in the
     *      slot with `replaceViewController(at:with:attributes:)`, with its own title and icon, and selected.
     * [CN] Issue #472：超过 5 个 Tab 而不出现系统的 "More"。视图控制器超过 5 个时 UIKit 就会添加 "More"；因此只给控制器 5 个，第 5 个 Tab
     *      作为溢出位。点击它（或在它选中时再次点击）弹出你自己的其他页面菜单；选中的页面通过 `replaceViewController(at:with:attributes:)`
     *      放进该位置（使用它自己的标题与图标）并选中。
     */
    private static func overflowMenuScene() -> UIViewController {
        var attributes = CYLGallery.attributes(4, showsTitles: true, pointSize: 20)
        attributes.append([CYLTabBarItemTitle: "More",
                           CYLTabBarItemImage: CYLGallery.symbol("ellipsis.circle", filled: false, pointSize: 20),
                           CYLTabBarItemSelectedImage: CYLGallery.symbol("ellipsis.circle", filled: true, pointSize: 20),
                           CYLTabBarItemIdentifier: "overflow"])
        var pages = CYLGallery.pages(4, embedsInNavigation: false)
        let placeholder = CYLGalleryPageViewController()
        pages.append(placeholder)
        // [EN] The pages that do not fit: Me, Message, Shop, Cardboard. [CN] 放不下的页面：Me、Message、Shop、Cardboard。
        let overflowSpecs = CYLGallery.tabSpecs[4...]
        let overflowPages = overflowSpecs.map { _ in CYLGalleryPageViewController() }
        let overflowAttributes: [[String: Any]] = overflowSpecs.map { spec in
            [CYLTabBarItemTitle: spec.title,
             CYLTabBarItemImage: CYLGallery.symbol(spec.symbol, filled: false, pointSize: 20),
             CYLTabBarItemSelectedImage: CYLGallery.symbol(spec.symbol, filled: true, pointSize: 20),
             CYLTabBarItemIdentifier: "overflow"]
        }
        let tabBarController = CYLGallery.tabBarController(pages: pages, attributes: attributes, styleType: .default, context: CYLGallery.context)
        tabBarController.cyl_customActionTabBarItemIdentifiers = ["overflow"]
        tabBarController.cyl_shouldPerformCustomTabActionHandler = { controller, viewController in
            guard controller.viewControllers?.firstIndex(of: viewController) == 4 else {
                return false
            }
            // [EN] The menu: from the placeholder, or when the slot is tapped again. [CN] 弹出菜单：溢出位还是占位页面，或再次点击该位置时。
            return viewController === placeholder || controller.selectedIndex == 4
        }
        tabBarController.cyl_customTabActionHandler = { controller, _ in
            let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            for (page, pageAttributes) in zip(overflowPages, overflowAttributes) {
                menu.addAction(UIAlertAction(title: pageAttributes[CYLTabBarItemTitle] as? String, style: .default) { _ in
                    if controller.viewControllers?[4] !== page {
                        controller.replaceViewController(at: 4, with: page, attributes: pageAttributes)
                    }
                    controller.selectedIndex = 4
                })
            }
            menu.addAction(UIAlertAction(title: cylDemoLocalizedString("取消"), style: .cancel))
            let source: UIView = controller.viewControllers?.last?.cyl_tabButton ?? controller.tabBar
            menu.popoverPresentationController?.sourceView = source
            menu.popoverPresentationController?.sourceRect = source.bounds
            controller.present(menu, animated: true)
        }
        return tabBarController
    }

    private static func moreThanFiveTabsSection() -> CYLGallerySection {
        CYLGallerySection(title: "More than five tabs", scenes: [
            CYLGalleryScene(title: "8 tabs without the system \"More\"",
                            subtitle: "Issue #472: the fifth tab opens your own menu of the other pages; the chosen page takes that slot with its own title and icon") {
                overflowMenuScene()
            },
            CYLGalleryScene(title: "For comparison: 8 tabs with the system \"More\"",
                            subtitle: "UIKit shows four tabs and \"More\" once there are more than five view controllers") {
                fullWidthTabBarController(count: 8)
            },
        ])
    }
}
