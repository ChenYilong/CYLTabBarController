/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIViewController (CYLNavigationControllerExtention)

@property (nonatomic, assign, getter=cyl_disablePopGestureRecognizer, setter=cyl_setDisablePopGestureRecognizer:) BOOL cyl_disablePopGestureRecognizer;
@property (nonatomic, assign, getter=cyl_hideNavigationBarSeparator, setter=cyl_setHideNavigationBarSeparator:) BOOL cyl_hideNavigationBarSeparator;
@property (nonatomic, assign, getter=cyl_navigationBarHidden, setter=cyl_setNavigationBarHidden:) BOOL cyl_navigationBarHidden;
@property (nonatomic, assign, getter=cyl_hidesBottomBarWhenPushed, setter=cyl_setHidesBottomBarWhenPushed:) BOOL cyl_hidesBottomBarWhenPushed;

/*!
 * FIX: issue #535
 * [EN] Also hides the navigation bars of the navigation controllers around this one, e.g. when the tab bar controller
 *      is pushed onto a navigation controller, so `cyl_navigationBarHidden` hides only the inner bar. They are shown
 *      again when no visible page asks for it any more (only the bars hidden this way). Default NO. Applied by the
 *      all-in-one `-cyl_viewWillAppearNavigationSetting:` / `-cyl_viewDidDisappearNavigationSetting:`, so by
 *      CYLBaseViewController and by `cyl_automaticNavigationSettingEnabled`.
 * [CN] 同时隐藏外层导航控制器的导航栏，例如 TabBarController 被 push 到某个导航控制器中时，`cyl_navigationBarHidden` 只隐藏内层导航栏。
 *      当没有可见页面再要求隐藏时恢复显示（只恢复以这种方式隐藏的导航栏）。默认 NO。由一站式方法
 *      `-cyl_viewWillAppearNavigationSetting:` / `-cyl_viewDidDisappearNavigationSetting:` 执行，因此 CYLBaseViewController 与
 *      `cyl_automaticNavigationSettingEnabled` 都会生效。
 */
@property (nonatomic, assign, getter=cyl_hidesAncestorNavigationBars, setter=cyl_setHidesAncestorNavigationBars:) BOOL cyl_hidesAncestorNavigationBars;

/*!
 * FIX: issue #535
 * [EN] The properties above (`cyl_navigationBarHidden`, `cyl_hideNavigationBarSeparator`, `cyl_disablePopGestureRecognizer`,
 *      `cyl_hidesAncestorNavigationBars`) only work in subclasses of CYLBaseViewController / CYLBaseTableViewController,
 *      or when you call the `-cyl_view...NavigationSetting:` methods yourself. Set this to YES once (e.g. at launch) and
 *      they work in any view controller, without inheriting: the library calls those methods after `-viewWillAppear:`,
 *      `-viewDidAppear:`, `-viewWillDisappear:` and `-viewDidDisappear:`, for the view controllers that set one of the
 *      properties to YES and are inside a navigation controller. The base classes keep working as before and are not called
 *      twice. Default NO.
 * [CN] 上面的属性（`cyl_navigationBarHidden`、`cyl_hideNavigationBarSeparator`、`cyl_disablePopGestureRecognizer`、
 *      `cyl_hidesAncestorNavigationBars`）只在 CYLBaseViewController / CYLBaseTableViewController 的子类中，或自己调用
 *      `-cyl_view...NavigationSetting:` 方法时生效。将本属性设为 YES 一次（如在启动时），任何控制器都可以使用，无需继承：本库在
 *      `-viewWillAppear:`、`-viewDidAppear:`、`-viewWillDisappear:`、`-viewDidDisappear:` 之后，为设置了其中任一属性为 YES 的控制器
 *      调用这些方法（位于导航控制器中即可）。基类保持原有方式，不会被重复调用。默认 NO。
 */
@property (class, nonatomic, assign, getter=cyl_automaticNavigationSettingEnabled, setter=cyl_setAutomaticNavigationSettingEnabled:) BOOL cyl_automaticNavigationSettingEnabled;

/*!
 * 使用方法：用在viewWillDisappear/dealloc
 * 作用：在左滑动的过渡的时间段内禁用interactivePopGestureRecognizer
 * [EN] Disables the interactive pop gesture during the swipe-back transition. Call in `viewWillDisappear` / `dealloc`.
 * [CN] 在左滑返回的过渡期间禁用 interactivePopGestureRecognizer，请在 viewWillDisappear / dealloc 中调用。
 */
- (void)cyl_disableInteractivePopGestureRecognizer;
/*!
 * use in viewDidDisappear
 * 作用：在左滑动的结束后启用interactivePopGestureRecognizer
 * [EN] Re-enables the interactive pop gesture after the swipe-back ends. Call in `viewDidDisappear`.
 * [CN] 左滑返回结束后重新启用 interactivePopGestureRecognizer，请在 viewDidDisappear 中调用。
 */
- (void)cyl_enableInteractivePopGestureRecognizer;
/*!
 * use in viewDidAppear
 * 当新的视图控制器加载完成后再启用
 * [EN] Enables or disables the pop gesture: disabled when `cyl_disablePopGestureRecognizer` is YES or this is the root controller. Call in `viewDidAppear`.
 * [CN] 重新设置返回手势：cyl_disablePopGestureRecognizer 为 YES 或当前为栈底控制器时禁用，否则启用。请在 viewDidAppear 中调用。
 */
- (void)cyl_resetInteractivePopGestureRecognizer;
/*!
 * use in viewWillAppear
 * [EN] Hides the navigation bar's bottom separator when `cyl_hideNavigationBarSeparator` is YES. Call in `viewWillAppear`.
 * [CN] 当 cyl_hideNavigationBarSeparator 为 YES 时隐藏导航栏底部分割线，请在 viewWillAppear 中调用。
 */
- (void)cyl_hideNavigationBarSeparatorIfNeeded;

/*!
 * [EN] Returns YES if the navigation bar should be shown again when this controller disappears (e.g. on pop). Call in `viewWillDisappear`.
 * [CN] 判断当前控制器消失时（如 Pop）是否应恢复显示导航栏，请在 viewWillDisappear 中使用。
 */
- (BOOL)cyl_shouldNavigationBarVisible;
//use in viewWillDisappear

/*!
 * [EN] Shows the navigation bar again if this controller hid it and it should become visible. Call in `viewWillDisappear`.
 * [CN] 若当前控制器隐藏了导航栏且需要恢复，则重新显示导航栏，请在 viewWillDisappear 中调用。
 */
- (void)cyl_setNavigationBarVisibleIfNeeded:(BOOL)animated;
//use in viewWillAppear

/*!
 * [EN] Hides the navigation bar when `cyl_navigationBarHidden` is YES. Call in `viewWillAppear`.
 * [CN] 当 cyl_navigationBarHidden 为 YES 时隐藏导航栏，请在 viewWillAppear 中调用。
 */
- (void)cyl_setNavigationBarHiddenIfNeeded:(BOOL)animated;

/*!
 * [EN] All-in-one setup for `viewWillAppear`: hides the separator and the navigation bar if needed.
 * [CN] viewWillAppear 中的一站式设置：按需隐藏导航栏分割线与导航栏。
 */
- (void)cyl_viewWillAppearNavigationSetting:(BOOL)animated;

/*!
 * [EN] All-in-one setup for `viewWillDisappear`: disables the pop gesture and restores the navigation bar if needed.
 * [CN] viewWillDisappear 中的一站式设置：禁用返回手势，并按需恢复导航栏。
 */
- (void)cyl_viewWillDisappearNavigationSetting:(BOOL)animated;

/*!
 * [EN] All-in-one setup for `viewDidDisappear`: re-enables the pop gesture.
 * [CN] viewDidDisappear 中的一站式设置：重新启用返回手势。
 */
- (void)cyl_viewDidDisappearNavigationSetting:(BOOL)animated;

/*!
 * [EN] All-in-one setup for `viewDidAppear`: resets the pop gesture state.
 * [CN] viewDidAppear 中的一站式设置：重置返回手势状态。
 */
- (void)cyl_viewDidAppearNavigationSetting:(BOOL)animated;

/*!
 * [EN] All-in-one setup for `dealloc`: disables the pop gesture.
 * [CN] dealloc 中的一站式设置：禁用返回手势。
 */
- (void)cyl_deallocNavigationSetting;

@end

NS_ASSUME_NONNULL_END
