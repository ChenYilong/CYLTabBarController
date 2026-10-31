//
//  CYLPlusButton.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLConstants.h"

NS_ASSUME_NONNULL_BEGIN

@class CYLPlusButton;

@protocol CYLPlusButtonSubclassing

@required

/*!
 * [EN] Required. Creates and returns the custom plus button instance.
 * [CN] 必须实现。创建并返回自定义的 PlusButton 实例。
 */
+ (id)plusButton;

@optional

/*!
 * 用来自定义加号按钮的位置，如果不实现默认居中。
 * @attention 以下两种情况下，必须实现该协议方法，否则 CYLTabBarController 会抛出 exception 来进行提示：
                 1. 添加了 PlusButton 且 TabBarItem 的个数是奇数。
                 2. 实现了 `+plusChildViewController`。
 * @return 用来自定义加号按钮在 TabBar 中的位置。
 *
 * [EN] Returns the index of the plus button in the tab bar; centered by default. Required when the item count is odd or `+plusChildViewController` is implemented.
 * [CN] 返回 PlusButton 在 TabBar 中的索引，默认居中。当 TabBarItem 个数为奇数或实现了 +plusChildViewController 时必须实现。
 */
+ (NSUInteger)indexOfPlusButtonInTabBar;

/*!
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
 * [CN] 返回 PlusButton 中心点 Y 坐标相对 TabBar 高度的比例（0.5 居中，小于 0.5 偏上，大于 0.5 偏下）。
 */
+ (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight;

/*!
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
+ (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight;

/*!
 * 实现该方法后，能让 PlusButton 的点击效果与跟点击其他 TabBar 按钮效果一样，跳转到该方法指定的 UIViewController 。
 * @attention 必须同时实现 `+indexOfPlusButtonInTabBar` 来指定 PlusButton 的位置。
 * @return 指定 PlusButton 点击后跳转的 UIViewController。
 *
 * [EN] Returns the view controller shown when the plus button is tapped, making it behave like a normal tab.
 * [CN] 返回点击 PlusButton 后展示的控制器，使其表现得和普通 Tab 一样。
 */
+ (UIViewController *)plusChildViewController;

/*!
 * 
 Asks the delegate whether the specified view controller should be made active.
 Return YES if the view controller’s tab should be selected or NO if the current tab should remain active.
 Returns YES true if the view controller’s tab should be selected or
         NO  false if the current tab should remain active.
 * [EN] Returns whether the plus child view controller should be selected when the plus button is tapped.
 * [CN] 返回点击 PlusButton 时是否选中 PlusButton 对应的子控制器。
 */
+ (BOOL)shouldSelectPlusChildViewController;

/** 可以不设置， 默认为 CYLTabBarController，如果设置了，请 与 CYLTabBarController 里 context 并保持一致。如果两个都不是实现，默认为一致均为 CYLTabBarController
 * [EN] Returns the context this plus button belongs to; must match `CYLTabBarController.context`. Defaults to "CYLTabBarController".
 * [CN] 返回 PlusButton 所属的 context，需与 CYLTabBarController 的 context 保持一致，默认为 "CYLTabBarController"。
 */
+ (NSString *)tabBarContext;

/*!
* 可点击的范围,
 //TODO:  更换使用 padding 会更直观。
 * [EN] Returns the plus button's touchable area, used for hit testing when it extends beyond the tab bar.
 * [CN] 返回 PlusButton 的可点击区域，用于按钮超出 TabBar 时的点击判断。
*/
- (CGRect)touchableRect;

/*!
 * iOS26+ selectedContentView 只有在选中状态下会显示。
 * [EN] iOS 26+. Returns the button shown as the plus button's selected-state content.
 * [CN] iOS 26+。返回作为 PlusButton 选中态内容展示的按钮。
 */
+ (UIButton *)selectedContentView;

/*!
 * iOS26+
 * [EN] iOS 26+. Returns the image used as the plus button's normal-state content.
 * [CN] iOS 26+。返回 PlusButton 常态内容所使用的图片。
 */
+ (UIImage *)contentImage;

/*!
 * iOS26+  如果plusButton只有图片没有label，更简单的方式是实现下面这个代理。
 * [EN] iOS 26+. Returns the image used as the plus button's selected-state content.
 * [CN] iOS 26+。返回 PlusButton 选中态内容所使用的图片。
 */
+ (UIImage *)selectedContentImage;

/*!
 * iOS26+
 */
@property (nonatomic, weak) __kindof UIButton *selectedContentView;

/*!
 * Snapshot of plusButton, iOS26+
 */
@property (nonatomic, strong) UIImage *selectedContentImage;

/*!
 * Snapshot of plusButton, iOS26+
 */
@property (nonatomic, strong) UIImage *contentImage;

/*!
 * [EN] Returns YES if the plus button is vertically centered (no centerY offset and a 0.5 height multiplier).
 * [CN] 判断 PlusButton 是否垂直居中（无中心点偏移且高度比例为 0.5）。
 */
- (BOOL)isLayoutCentered;

/*!
 * [EN] Returns YES if `tabBarContext` matches this plus button's context.
 * [CN] 判断 tabBarContext 是否与 PlusButton 的 context 一致。
 */
+ (BOOL)matchedTabBarContext:(NSString *)tabBarContext;

@end

@class CYLTabBar;

/*!
 * [EN] The plus button and the plus child view controller registered LAST (and not removed since).
 *      Kept for source compatibility with code that reads them. The library no longer reads them: with several plus
 *      buttons, each tab bar controller uses the one registered for its own context, see
 *      `+plusButtonForTabBarContext:` and `+plusChildViewControllerForTabBarContext:`. With one plus button, they are
 *      what they always were.
 * [CN] 最后一次注册（且之后未被移除）的 PlusButton 与 PlusButton 子控制器。保留它们是为了让读取它们的代码继续可用。
 *      库内部不再读取它们：存在多个 PlusButton 时，每个 TabBarController 使用与自己 context 对应的那一个，
 *      见 `+plusButtonForTabBarContext:` 和 `+plusChildViewControllerForTabBarContext:`。只有一个 PlusButton 时，它们与以前完全一致。
 */
FOUNDATION_EXTERN CYLPlusButton<CYLPlusButtonSubclassing> *CYLExternPlusButton;
FOUNDATION_EXTERN UIViewController *CYLPlusChildViewController;

@interface CYLPlusButton : UIButton 

/*!
 * plusButton state:
 * Register + Context match == Active
 * [EN] Registers the subclass as the plus button of its context (`+tabBarContext`, "CYLTabBarController" by default)
 *      and sets up its child view controller if provided. Several plus buttons can be registered at the same time, one
 *      per context; a tab bar controller uses the one whose context equals its own `context`. Registering a second
 *      plus button for a context that already has one replaces it. `CYLExternPlusButton` and
 *      `CYLPlusChildViewController` point at the one registered last.
 * [CN] 将当前子类注册为它所属 context（`+tabBarContext`，默认 "CYLTabBarController"）的 PlusButton，若提供了子控制器也一并设置。
 *      可以同时注册多个 PlusButton，每个 context 一个；TabBarController 使用 context 与自己的 `context` 相同的那一个。
 *      为已有 PlusButton 的 context 再注册一个会替换它。`CYLExternPlusButton` 与 `CYLPlusChildViewController` 指向最后注册的那一个。
 */
+ (void)registerPlusButton;

/*!
 * [EN] Removes the plus button registered for this class's context from its superview, together with its child view
 *      controller, and unregisters them. The plus buttons of other contexts are not touched. When called on
 *      `CYLPlusButton` itself, which has no context of its own, it removes the one `CYLExternPlusButton` points at, as before.
 * [CN] 将本类所属 context 注册的 PlusButton 及其子控制器从父视图移除并取消注册，其他 context 的 PlusButton 不受影响。
 *      直接对没有自己 context 的 `CYLPlusButton` 调用时，与以前一样移除 `CYLExternPlusButton` 指向的那一个。
 */
+ (void)removePlusButton;

/*!
 * [EN] Same as `+removePlusButton`, for the given context.
 * [CN] 与 `+removePlusButton` 相同，作用于指定的 context。
 */
+ (void)removePlusButtonForTabBarContext:(NSString *)tabBarContext;

#pragma mark - Plus buttons by context

/*!
 * [EN] The registry maps a context to its plus button, plus child view controller and plus button width. A plus button
 *      is bound to a CYLTabBarController, through the controller's `context`. The controller's `-hasPlusButton` and
 *      `-hasPlusChildViewController` read the registry, and its tab bar (system or flat design) asks the controller that
 *      owns it, so several tab bar controllers with different contexts each get their own plus button. Tab bar
 *      controllers that share a context share one plus button, and a view can only be in one tab bar, so give each its own context.
 * [CN] 注册表将 context 映射到对应的 PlusButton、PlusButton 子控制器和 PlusButton 宽度。PlusButton 绑定的是 CYLTabBarController，
 *      通过控制器的 `context`。控制器的 `-hasPlusButton`、`-hasPlusChildViewController` 读取注册表，它的 TabBar（系统样式或扁平样式）
 *      则向拥有它的控制器询问，因此 context 不同的多个 TabBarController 各自使用自己的 PlusButton。
 *      context 相同的 TabBarController 共用同一个 PlusButton，而一个 View 只能在一个 TabBar 中，所以请给每个设置不同的 context。
 *
 *      Example:
 *      @code
 *      [HomePlusButton registerPlusButton];     // +tabBarContext returns @"home"
 *      [MinePlusButton registerPlusButton];     // +tabBarContext returns @"mine"
 *      CYLTabBarController *home = [[CYLTabBarController alloc] initWithViewControllers:… tabBarItemsAttributes:… context:@"home"];
 *      CYLTabBarController *mine = [[CYLTabBarController alloc] initWithViewControllers:… tabBarItemsAttributes:… context:@"mine"];
 *      [CYLPlusButton plusButtonForTabBarContext:@"home"];   // the HomePlusButton instance
 *      @endcode
 */

/*!
 * [EN] Returns the plus button registered for `tabBarContext`, or nil.
 * [CN] 返回为 tabBarContext 注册的 PlusButton，没有则返回 nil。
 */
+ (nullable CYLPlusButton<CYLPlusButtonSubclassing> *)plusButtonForTabBarContext:(nullable NSString *)tabBarContext;

/*!
 * [EN] Returns the plus child view controller registered for `tabBarContext`, or nil.
 * [CN] 返回为 tabBarContext 注册的 PlusButton 子控制器，没有则返回 nil。
 */
+ (nullable UIViewController *)plusChildViewControllerForTabBarContext:(nullable NSString *)tabBarContext;

/*!
 * [EN] Returns the width of the plus button registered for `tabBarContext`, or 0.
 * [CN] 返回为 tabBarContext 注册的 PlusButton 的宽度，没有则返回 0。
 */
+ (CGFloat)plusButtonWidthForTabBarContext:(nullable NSString *)tabBarContext;

/*!
 * [EN] The context of the CYLTabBarController `owner` belongs to: the controller itself, its tab bar, a view inside the
 *      tab bar (a tab button, the plus button), or a view controller (a tab's view controller, the plus child view controller). If it cannot be told,
 *      the context of the plus button registered last, which is what the global `CYLExternPlusButton` points at.
 * [CN] `owner` 所属 CYLTabBarController 的 context：控制器本身、它的 TabBar、TabBar 内的 View（Tab 按钮、PlusButton）或 ViewController
 *      （Tab 的控制器、PlusButton 子控制器）。无法判断时，返回最后注册的 PlusButton 的 context，即全局 `CYLExternPlusButton` 所指的那个。
 */
+ (nullable NSString *)tabBarContextForOwner:(nullable id)owner;

/*!
 * [EN] `+plusButtonForTabBarContext:` / `+plusChildViewControllerForTabBarContext:` / `+plusButtonWidthForTabBarContext:`
 *      for the context of `owner` (see `+tabBarContextForOwner:`).
 * [CN] 针对 `owner` 所属 context（见 `+tabBarContextForOwner:`）的 `+plusButtonForTabBarContext:` 等方法。
 */
+ (nullable CYLPlusButton<CYLPlusButtonSubclassing> *)plusButtonForOwner:(nullable id)owner;
+ (nullable UIViewController *)plusChildViewControllerForOwner:(nullable id)owner;
+ (CGFloat)plusButtonWidthForOwner:(nullable id)owner;

/*!
 * [EN] Returns YES if `view` is the plus button of any context (the registered instance, or an instance of a registered class).
 * [CN] 判断 `view` 是否是任意 context 的 PlusButton（已注册的实例，或已注册类的实例）。
 */
+ (BOOL)isPlusButtonView:(nullable UIView *)view;

/*!
 * [EN] Action for plus button taps; selects the plus child view controller when appropriate.
 * [CN] PlusButton 的点击事件，在需要时选中 PlusButton 对应的子控制器。
 */
- (void)plusChildViewControllerButtonClicked:(UIButton<CYLPlusButtonSubclassing> *)sender;

/*!
 * plusButton state:
 * Register + Context match == Active
 * [EN] Returns `+tabBarContext` if implemented and non-empty, otherwise "CYLTabBarController".
 * [CN] 若实现了 +tabBarContext 且非空则返回其值，否则返回 "CYLTabBarController"。
 */
+ (NSString *)matchedTabBarContext;

/*!
 * [EN] Returns YES if a plus button is registered for `tabBarContext`.
 * [CN] 判断是否为 tabBarContext 注册了 PlusButton。
 */
+ (BOOL)hasPlusButtonForTabBarContext:(NSString *)tabBarContext;

/*!
 * [EN] Returns YES if a plus child view controller is registered for `tabBarContext`.
 * [CN] 判断是否为 tabBarContext 注册了 PlusButton 子控制器。
 */
+ (BOOL)hasPlusChildViewControllerForTabBarContext:(NSString *)tabBarContext;

/*!
 * [EN] Returns the centerY multiplier for `tabBarHeight`, from `+multiplierOfTabBarHeight:` or a computed default.
 * [CN] 返回 tabBarHeight 对应的中心点比例，取自 +multiplierOfTabBarHeight:，未实现时使用计算出的默认值。
 */
- (CGFloat)multiplierOfTabBarHeight:(CGFloat)tabBarHeight;

/*!
 * [EN] Returns the centerY offset from `+constantOfPlusButtonCenterYOffsetForTabBarHeight:`, or 0 if not implemented.
 * [CN] 返回 +constantOfPlusButtonCenterYOffsetForTabBarHeight: 提供的中心点偏移，未实现时返回 0。
 */
- (CGFloat)constantOfPlusButtonCenterYOffsetForTabBarHeight:(CGFloat)tabBarHeight;

/*!
 * [EN] Returns the plus button index for the given item count: `+indexOfPlusButtonInTabBar` if implemented, otherwise the middle (asserts in DEBUG when the count is odd).
 * [CN] 根据 TabBarItem 个数返回 PlusButton 索引：优先使用 +indexOfPlusButtonInTabBar，否则取中间位置（个数为奇数时 DEBUG 下会断言）。
 */
+ (NSUInteger)indexForTabbarItemsCount:(NSUInteger)tabbarItemsCount;

/*!
 * [EN] Liquid Glass only. Hides or shows the plus button's title label and inversely toggles the selected-content label.
 * [CN] 仅液态玻璃下生效。隐藏或显示 PlusButton 的标题 Label，并反向切换选中态内容的 Label。
 */
- (void)setTabLabelHidden:(BOOL)hidden;

@end

#pragma mark - Deprecated API

@interface CYLPlusButton (CYLPlusButtonDeprecated)

/*!
 * [EN] Deprecated. Use `+registerPlusButton` instead.
 * [CN] 已废弃，请改用 +registerPlusButton。
 */
+ (void)registerSubclass CYL_DEPRECATED("Deprecated in 1.6.0. Use `+[CYLPlusButton registerPlusButton]` instead.");

/*!
 * [EN] Deprecated. Use `+multiplierOfTabBarHeight:` instead.
 * [CN] 已废弃，请改用 +multiplierOfTabBarHeight:。
 */
+ (CGFloat)multiplerInCenterY CYL_DEPRECATED("Deprecated in 1.6.0. Use `+multiplierOfTabBarHeight:` instead.");

@end

NS_ASSUME_NONNULL_END
