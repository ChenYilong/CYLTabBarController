//
//  CYLTabBarControllerTypes.swift
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

import UIKit

// [EN] Phase 3 of the class switch (docs/Swift-Migration.md): the enums of CYLConstants.h and the protocol of CYLPlusButton.h in Swift,
//      with the Objective-C names and the Swift names apps see. They could not move before: CYLTabBarController.h used them while
//      it declared the class. [CN] 类切换第 3 阶段：CYLConstants.h 的枚举与 CYLPlusButton.h 的协议改为 Swift，Objective-C 名称与 App 看到的
//      Swift 名称不变。之前无法迁移：CYLTabBarController.h 声明类时使用了它们。

/**
 [EN] The tab bar style: the default (Liquid Glass on iOS 26+, else the classic tab bar), the system tab bar, FlatDesign or
      Liquid Glass. Set it before `super.viewDidLoad()`.
 [CN] TabBar 样式：默认（iOS 26+ 为液态玻璃，否则为经典 TabBar）、系统 TabBar、扁平样式或液态玻璃。请在 `super.viewDidLoad()` 之前设置。
 */
@objc(CYLTabBarStyleType)
public enum CYLTabBarStyleType: Int, @unchecked Sendable {
    case `default` = 0
    case system = 1
    case flatDesign = 2
    case liquidGlass = 3
}

/**
 [EN] How the tab bar reacts to scrolling (issue #13); matches `UITabBarMinimizeBehavior`.
 [CN] TabBar 随滚动的变化方式（issue #13）；对应 `UITabBarMinimizeBehavior`。
 */
@objc(CYLTabBarMinimizeBehavior)
public enum CYLTabBarMinimizeBehavior: Int, @unchecked Sendable {
    /**
     [EN] Liquid Glass: the system default. FlatDesign and classic: same as Never.
     [CN] 液态玻璃：系统默认行为。扁平样式与经典样式：等同于 Never。
     */
    case automatic = 0
    /**
     [EN] The tab bar never minimizes or hides on scroll. [CN] 滚动时 TabBar 不缩小、不隐藏。
     */
    case never = 1
    /**
     [EN] Minimizes (FlatDesign and classic: hides) when scrolling down, expands when scrolling back up.
     [CN] 向下滚动时缩小（扁平样式与经典样式：隐藏），向上滚动时恢复。
     */
    case onScrollDown = 2
    /**
     [EN] Minimizes (FlatDesign and classic: hides) when scrolling up, expands when scrolling back down; for content aligned to
          the bottom, such as a chat.
     [CN] 向上滚动时缩小（扁平样式与经典样式：隐藏），向下滚动时恢复；适合底部对齐的内容，如聊天页面。
     */
    case onScrollUp = 3
}

/**
 [EN] What a plus button subclass provides; only `+plusButton` is required. Not NSObject-based, as in Objective-C.
 [CN] PlusButton 子类提供的内容；只有 `+plusButton` 是必需的。与 Objective-C 一样不继承 NSObject 协议。
 */
@objc(CYLPlusButtonSubclassing)
public protocol CYLPlusButtonSubclassing {


    /**
     * [EN] Required. Creates and returns the custom plus button instance.
     * [CN] 必须实现。创建并返回自定义的 PlusButton 实例。
     */
    @objc(plusButton) static func plusButton() -> Any


    /**
     * 用来自定义加号按钮的位置，如果不实现默认居中。
     * @attention 以下两种情况下，必须实现该协议方法，否则 CYLTabBarController 会抛出 exception 来进行提示：
                 1. 添加了 PlusButton 且 TabBarItem 的个数是奇数。
                 2. 实现了 `+plusChildViewController`。
     * @return 用来自定义加号按钮在 TabBar 中的位置。
     *
     * [EN] Returns the index of the plus button in the tab bar; centered by default. Required when the item count is odd or `+plusChildViewController` is implemented.
     * [CN] 返回 PlusButton 在 TabBar 中的索引，默认居中。当 TabBarItem 个数为奇数或实现了 +plusChildViewController 时必须实现。
     */
    @objc(indexOfPlusButtonInTabBar) optional static func indexOfPlusButtonInTabBar() -> UInt

    /**
     * 该方法是为了调整 PlusButton 中心点Y轴方向的位置，建议在按钮超出了 tabbar 的边界时实现该方法。
     * @attention 如果不实现该方法，内部会自动进行比对，预设一个较为合适的位置，如果实现了该方法，预设的逻辑将失效。
     * 但是 iOS26+ 系统， Liquid Glass 效果下， 自定义后，需要实现代理方法如下， 隐藏玻璃遮罩，
     见 issue#636 讨论：

     - (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control {
    if ([tabBarController.selectedViewController isEqual:CYLPlusChildViewController]) {
    [self.tabBar.cyl_platterLiquidLensViewContentView cyl_setHidden:YES];
    } else {
    [self.tabBar.cyl_platterLiquidLensViewContentView cyl_setHidden:NO];
    }
     * @return 返回值是自定义按钮中心点Y轴方向的坐标除以 tabbar 的高度，
           内部实现时，会使用该返回值来设置 PlusButton 的 centerY 坐标，公式如下：
              `PlusButtonCenterY = multiplierOfTabBarHeight * tabBarHeight + constantOfPlusButtonCenterYOffset;`
           也就是说：如果 constantOfPlusButtonCenterYOffset 为0，同时 multiplierOfTabBarHeight 的值是0.5，表示 PlusButton 居中，小于0.5表示 PlusButton 偏上，大于0.5则表示偏下。
     
     * [EN] Returns the plus button's centerY as a ratio of the tab bar height (0.5 = centered, <0.5 = higher, >0.5 = lower).
     *      If it is not implemented: on the system tab bar (iOS 25 and earlier, and UI compatibility mode on iOS 26) the
     *      plus button is centered on the tab items (0.5), the same as in the Flat style; with Liquid Glass, a plus button
     *      taller than the tab bar is raised so that its bottom meets the tab bar's.
     * [CN] 返回 PlusButton 中心点 Y 坐标相对 TabBar 高度的比例（0.5 居中，小于 0.5 偏上，大于 0.5 偏下）。
     */
    @objc(multiplierOfTabBarHeight:) optional static func multiplier(ofTabBarHeight tabBarHeight: CGFloat) -> CGFloat

    /**
     * 见 `+multiplierOfTabBarHeight:` 注释：
     * `PlusButtonCenterY = multiplierOfTabBarHeight * tabBarHeight + constantOfPlusButtonCenterYOffset;`
     * 也就是说： constantOfPlusButtonCenterYOffset 大于0会向下偏移，小于0会向上偏移。
     * @attention 实现了该方法，但没有实现 `+multiplierOfTabBarHeight:` 方法，在这种情况下，会在预设逻辑的基础上进行偏移。但是 iOS26+ 系统， Liquid Glass 效果下， 自定义后，需要实现代理方法如下， 隐藏玻璃遮罩，
     见 issue#636 讨论：
      - (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control {
     if ([tabBarController.selectedViewController isEqual:CYLPlusChildViewController]) {
     [self.tabBar.cyl_platterLiquidLensViewContentView cyl_setHidden:YES];
     } else {
     [self.tabBar.cyl_platterLiquidLensViewContentView cyl_setHidden:NO];
     }

     * [EN] Returns a constant offset added to the plus button's centerY (>0 moves down, <0 moves up).
     * [CN] 返回在 PlusButton 中心点 Y 坐标上追加的固定偏移量（大于 0 向下，小于 0 向上）。
     */
    @objc(constantOfPlusButtonCenterYOffsetForTabBarHeight:) optional static func constantOfPlusButtonCenterYOffset(forTabBarHeight tabBarHeight: CGFloat) -> CGFloat

    /**
     * 实现该方法后，能让 PlusButton 的点击效果与跟点击其他 TabBar 按钮效果一样，跳转到该方法指定的 UIViewController 。
     * @attention 必须同时实现 `+indexOfPlusButtonInTabBar` 来指定 PlusButton 的位置。
     * @return 指定 PlusButton 点击后跳转的 UIViewController。
     *
     * [EN] Returns the view controller shown when the plus button is tapped, making it behave like a normal tab.
     * [CN] 返回点击 PlusButton 后展示的控制器，使其表现得和普通 Tab 一样。
     */
    @objc(plusChildViewController) optional static func plusChildViewController() -> UIViewController

    /**
     * 
     Asks the delegate whether the specified view controller should be made active.
     Return YES if the view controller’s tab should be selected or NO if the current tab should remain active.
     Returns YES true if the view controller’s tab should be selected or
         NO  false if the current tab should remain active.
     * [EN] Returns whether the plus child view controller should be selected when the plus button is tapped.
     * [CN] 返回点击 PlusButton 时是否选中 PlusButton 对应的子控制器。
     */
    @objc(shouldSelectPlusChildViewController) optional static func shouldSelectPlusChildViewController() -> Bool

    /** 可以不设置， 默认为 CYLTabBarController，如果设置了，请 与 CYLTabBarController 里 context 并保持一致。如果两个都不是实现，默认为一致均为 CYLTabBarController
     * [EN] Returns the context this plus button belongs to; must match `CYLTabBarController.context`. Defaults to "CYLTabBarController".
     * [CN] 返回 PlusButton 所属的 context，需与 CYLTabBarController 的 context 保持一致，默认为 "CYLTabBarController"。
     */
    @objc(tabBarContext) optional static func tabBarContext() -> String

    /**
     * [EN] Return YES to make the plus button's title match the tab items' titles, in every tab bar style (the system tab
     *      bar, Liquid Glass and the Flat style): the same center line, the same font and font size, the unselected tabs'
     *      title color, and the selected tab's title color while the plus button is selected. Nothing needs customizing in
     *      the plus button; it works with or without `UIButtonConfiguration`, and replaces the title font and colors it set.
     *      - The reference is the first tab item whose title label is visible and has text: a first item without a title,
     *        or with a hidden one, is skipped. With no such item, or a plus button without a visible title, nothing
     *        changes.
     *      - The plus button and the tab items are in different view hierarchies, so the item title's center is converted
     *        into the plus button's coordinate space. Only the plus button title's centerY moves.
     *      - Not implemented: the core's default, YES for a plus button with a title that is not part of its background image
     *        (nothing to implement). NO: the title stays where the plus button lays it out, as before.
     *      - A plus button drawn with a background image only, its title on that picture: better not implemented. The title
     *        would leave the middle of the picture for the tab titles' line and take their font and colors. Such a button is
     *        placed by `+multiplierOfTabBarHeight:` and `+constantOfPlusButtonCenterYOffsetForTabBarHeight:` in every style
     *        (see docs/PlusButton-Background-Image-Liquid-Glass.md).
     * [CN] 返回 YES 时，PlusButton 的标题与 TabBarItem 的标题保持一致，适用于所有 TabBar 样式（系统 TabBar、液态玻璃、扁平样式）：同一中心线、
     *      相同的字体与字号、未选中 Tab 标题的颜色，以及 PlusButton 选中时使用选中 Tab 标题的颜色。PlusButton 无需任何自定义；
     *      支持使用与未使用 `UIButtonConfiguration` 的按钮，并会替换其原有的标题字体和颜色。
     *      - 以第一个标题可见且有文字的 TabBarItem 为参照：没有标题或标题隐藏的 item 会被跳过。没有这样的 item，或 PlusButton 没有可见
     *        标题时，不做任何调整。
     *      - PlusButton 与 TabBarItem 不在同一视图层级，因此会把 item 标题的中心点转换到 PlusButton 的坐标系。只调整 PlusButton 标题的 centerY。
     *      - 未实现：核心的默认值，有标题且标题不是背景图的一部分时为 YES（无需实现）；返回 NO：标题保持 PlusButton 自身布局的位置，与旧版本一致。
     *      - 只用背景图片绘制、标题画在图上的 PlusButton：建议不实现。否则标题会离开图片中心、移到 Tab 标题所在的线上，并使用其字体和颜色。
     *        这种按钮在所有样式下都按 `+multiplierOfTabBarHeight:` 与 `+constantOfPlusButtonCenterYOffsetForTabBarHeight:` 放置
     *        （见 docs/PlusButton-Background-Image-Liquid-Glass.md）。
     * [EN] With this, the stand-in in the Liquid Glass selected layer lines up with the plus button by icon only; other subviews are
     *      not considered: https://github.com/ChenYilong/CYLTabBarController/blob/master/docs/PlusButton.md
     * [CN] 实现后，液态玻璃选中图层中的替身与 PlusButton 只对齐图标，不考虑其他子视图，见上面的链接。
     */
    @objc(alignsTitleWithTabBarItemTitles) optional static func alignsTitleWithTabBarItemTitles() -> Bool

    /**
     * FIX: issue #408
     * [EN] The plus button's identifier, like `CYLTabBarItemIdentifier` for the other tabs, e.g. @"plus". Every tab bar
     *      controller's copy of the plus button gets it, so it also works with several tab bar controllers. Read it as
     *      `control.cyl_tabBarItemIdentifier` in `-tabBarController:didSelectControl:`. Optional: without it, the identifier
     *      is the class name, e.g. @"CYLPlusButtonSubclass".
     * [CN] PlusButton 的标识，作用与其他 Tab 的 `CYLTabBarItemIdentifier` 相同，例如 @"plus"。每个 TabBarController 中的 PlusButton
     *      副本都会带上它，多 TabBar 场景同样适用。在 `-tabBarController:didSelectControl:` 中通过 `control.cyl_tabBarItemIdentifier` 读取。
     *      可选：未实现时标识为类名，例如 @"CYLPlusButtonSubclass"。
     */
    @objc(tabBarItemIdentifier) optional static func tabBarItemIdentifier() -> String

    /**
     * [EN] Returns the plus button's touchable area, in its superview's coordinates, used for hit testing when it extends
     *      beyond the tab bar. By default: the frame scaled by `touchableAreaScale`, then grown by `touchableAreaOutsets`
     *      (issue #91). Override it for any other shape; the tab bars convert it to their own coordinates.
     * [CN] 返回 PlusButton 的可点击区域（父视图坐标系），用于按钮超出 TabBar 时的点击判断。默认：frame 先按 `touchableAreaScale`
     *      放大，再按 `touchableAreaOutsets` 向外扩展（issue #91）。需要其他形状时可重写；TabBar 会将其转换到自身坐标系。
     */
    @objc(touchableRect) optional func touchableRect() -> CGRect

    /**
     * iOS26+ selectedContentView 只有在选中状态下会显示。
     * [EN] iOS 26+. Returns the button shown as the plus button's selected-state content. With a plus child view controller on
     *      Liquid Glass (not FlatDesign) its image is replaced by the plus button's normal image, in every state: https://github.com/ChenYilong/CYLTabBarController/blob/master/docs/PlusButton.md
     * [CN] 有 PlusButton 子控制器且为液态玻璃（非扁平样式）时，其所有状态的图片都被替换为 PlusButton 普通状态的图片，见上面的链接。
     * [CN] iOS 26+。返回作为 PlusButton 选中态内容展示的按钮。
     */
    @objc(selectedContentView) optional static func selectedContentView() -> UIButton

    /**
     * iOS26+
     * [EN] iOS 26+. Returns the image used as the plus button's normal-state content.
     * [CN] iOS 26+。返回 PlusButton 常态内容所使用的图片。
     */
    @objc(contentImage) optional static func contentImage() -> UIImage

    /**
     * iOS26+  如果plusButton只有图片没有label，更简单的方式是实现下面这个代理。
     * [EN] iOS 26+. Returns the image used as the plus button's selected-state content. Ignored with a plus child view controller
     *      on Liquid Glass (not FlatDesign): the stand-in shows the plus button's normal image: https://github.com/ChenYilong/CYLTabBarController/blob/master/docs/PlusButton.md
     * [CN] iOS 26+。返回 PlusButton 选中态内容所使用的图片。有 PlusButton 子控制器且为液态玻璃（非扁平样式）时被忽略：替身显示 PlusButton
     *      普通状态的图片。见上面的链接。
     */
    @objc(selectedContentImage) optional static func selectedContentImage() -> UIImage

    /**
     * iOS26+
     */
    @objc optional weak var selectedContentView: UIButton? { get set }

    /**
     * Snapshot of plusButton, iOS26+
     * [EN] Ignored with a plus child view controller on Liquid Glass (not FlatDesign), see `+selectedContentImage`: https://github.com/ChenYilong/CYLTabBarController/blob/master/docs/PlusButton.md
     * [CN] 有 PlusButton 子控制器且为液态玻璃（非扁平样式）时被忽略，见 `+selectedContentImage` 与上面的链接。
     */
    @objc optional var selectedContentImage: UIImage { get set }

    /**
     * Snapshot of plusButton, iOS26+
     */
    @objc optional var contentImage: UIImage { get set }

    /**
     * [EN] Returns YES if the plus button is vertically centered (no centerY offset and a 0.5 height multiplier).
     * [CN] 判断 PlusButton 是否垂直居中（无中心点偏移且高度比例为 0.5）。
     */
    @objc(isLayoutCentered) optional func isLayoutCentered() -> Bool

    /**
     * [EN] Returns YES if `tabBarContext` matches this plus button's context.
     * [CN] 判断 tabBarContext 是否与 PlusButton 的 context 一致。
     */
    @objc(matchedTabBarContext:) optional static func matchedTabBarContext(_ tabBarContext: String) -> Bool

    /**
     * [EN] Deprecated. Use `+multiplierOfTabBarHeight:` instead. A requirement of the protocol since step 109 (it was a category
     *      method of the Objective-C class, implemented only by subclasses).
     * [CN] 已废弃，请改用 +multiplierOfTabBarHeight:。自第 109 步起为协议的方法（原为 Objective-C 类的分类方法，只由子类实现）。
     */
    @available(*, deprecated, message: "Deprecated in 1.6.0. Use `+multiplierOfTabBarHeight:` instead.")
    @objc(multiplerInCenterY) optional static func multiplerInCenterY() -> CGFloat

}
