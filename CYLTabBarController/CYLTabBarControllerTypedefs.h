//
//  CYLTabBarControllerTypedefs.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The Objective-C typedefs, enums and option sets that the Swift API of `CYLTabBarController` uses. They live in this header
 *      because the generated `CYLTabBarController-Swift.h` is imported before the big headers, and it needs them first (the class
 *      switch, docs/Swift-Migration.md). Swift cannot export `NS_OPTIONS` or block typedefs, so they stay Objective-C.
 * [CN] `CYLTabBarController` 的 Swift API 所用的 Objective-C typedef、枚举与选项集。它们放在这个头文件中，因为生成的
 *      `CYLTabBarController-Swift.h` 先于大头文件被导入，需要先看到它们（类迁移，docs/Swift-Migration.md）。Swift 无法导出 `NS_OPTIONS`
 *      与 block typedef，因此它们保留为 Objective-C。
 */
@class CYLTabBarController;

/*!
 * FIX: issue #19
 * [EN] Called once a login started by `-cyl_loginHandler` / `-tabBarController:presentLoginForViewController:completion:`
 *      ends: YES when the user logged in (the tab they tapped is then selected), NO when they cancelled.
 * [CN] 由 `-cyl_loginHandler` / `-tabBarController:presentLoginForViewController:completion:` 发起的登录结束时调用：用户登录成功
 *      为 YES（随后选中用户点击的 Tab），取消为 NO。
 */
typedef void (^CYLTabBarLoginCompletion)(BOOL loggedIn);

/*!
 * FIX: issue #152
 * [EN] Gestures on a tab button or the plus button, reported by `cyl_tabBarItemGestureHandler` and
 *      `-tabBarController:didRecognizeTabBarItemGesture:control:viewController:`, in every style (classic, Liquid Glass,
 *      FlatDesign). See `CYLTabBarController (CYLTabBarItemGesture)` and docs/TabBarItem-Gestures.md.
 *      - Reselect: a tap on the tab that is already selected (e.g. scroll to the top).
 *      - DoubleTap: two taps on the same tab within `cyl_tabBarItemDoubleTapInterval` (e.g. refresh, as Weibo does). The
 *        second tap is also a Reselect, reported first.
 *      - LongPress: a long press began on the tab (e.g. a menu). The tab is still selected when the finger lifts.
 * [CN] Tab 按钮或 PlusButton 上的手势，通过 `cyl_tabBarItemGestureHandler` 和
 *      `-tabBarController:didRecognizeTabBarItemGesture:control:viewController:` 回调，适用于所有样式（经典、液态玻璃、扁平）。
 *      见 `CYLTabBarController (CYLTabBarItemGesture)` 与 docs/TabBarItem-Gestures.md。
 *      - Reselect：点击已选中的 Tab（例如滚动到顶部）。
 *      - DoubleTap：在 `cyl_tabBarItemDoubleTapInterval` 内连续两次点击同一个 Tab（例如像微博一样双击刷新）。第二次点击同时也是
 *        Reselect，Reselect 先回调。
 *      - LongPress：在 Tab 上开始长按（例如弹出菜单）。手指抬起时该 Tab 仍会被选中。
 */
typedef NS_ENUM(NSInteger, CYLTabBarItemGesture) {
    CYLTabBarItemGestureReselect = 0,
    CYLTabBarItemGestureDoubleTap,
    CYLTabBarItemGestureLongPress,
};

/*!
 * [EN] Completion of `+loadConfigurationWithURL:completion:`, on the main queue. [CN] `+loadConfigurationWithURL:completion:` 的回调，在主队列执行。
 */
typedef void (^CYLTabBarConfigurationCompletion)(NSDictionary<NSString *, id> *_Nullable configuration, NSError *_Nullable error);

typedef void (^CYLTabBarControllerConfigurationCompletion)(CYLTabBarController *_Nullable tabBarController, NSError *_Nullable error);

/*!
 * [EN] What the library does when the user taps the tab that is already selected (a "reselect"). See
 *      `-[CYLTabBarController cyl_reselectBehavior]` and docs/Tab-Reselect.md.
 *      - PopToRoot: a navigation controller with pushed pages pops back to its root page.
 *      - ScrollToTop: the page's scroll view scrolls back to the top.
 *      - PopToRootThenScrollToTop: both, as the system apps do: the first tap pops, the next one (already at the root)
 *        scrolls to the top.
 * [CN] 用户点击已选中的 Tab（"重复点击"）时本库执行的操作。见 `-[CYLTabBarController cyl_reselectBehavior]` 与 docs/Tab-Reselect.md。
 *      - PopToRoot：push 了页面的导航控制器返回根页面。
 *      - ScrollToTop：页面的滚动视图滚动到顶部。
 *      - PopToRootThenScrollToTop：二者兼有，与系统 App 一致：第一次点击返回根页面，再点击一次（已在根页面）滚动到顶部。
 */
typedef NS_OPTIONS(NSUInteger, CYLTabBarReselectBehavior) {
    CYLTabBarReselectBehaviorNone        = 0,
    CYLTabBarReselectBehaviorPopToRoot   = 1 << 0,
    CYLTabBarReselectBehaviorScrollToTop = 1 << 1,
    CYLTabBarReselectBehaviorPopToRootThenScrollToTop = CYLTabBarReselectBehaviorPopToRoot | CYLTabBarReselectBehaviorScrollToTop,
};

typedef void(^CYLViewDidLayoutSubViewsBlock)(CYLTabBarController *tabBarController);

typedef void (^CYLTabBarItemGestureHandler)(CYLTabBarController *tabBarController,
                                            CYLTabBarItemGesture gesture,
                                            UIControl *control,
                                            UIViewController *_Nullable viewController);

/*!
 * [EN] Creates the page (view controller) of a tab. `pageIdentifier` is the tab's page ID (see
 *      `CYLTabBarItemPageIdentifier`), `tabAttributes` the tab's normalized attributes (title, icons,
 *      `CYLTabBarItemPageParameters`, ...). Return nil to skip the tab. The page may be a navigation controller that wraps
 *      the content. Called on the main thread, once per tab and tab bar controller.
 * [CN] 创建 Tab 的页面（视图控制器）。`pageIdentifier` 为该 Tab 的页面 ID（见 `CYLTabBarItemPageIdentifier`），`tabAttributes` 为该 Tab
 *      规范化后的属性（标题、图标、`CYLTabBarItemPageParameters` 等）。返回 nil 则跳过该 Tab。页面可以是包裹内容的导航控制器。
 *      在主线程调用，每个 TabBarController 的每个 Tab 调用一次。
 */
typedef UIViewController *_Nullable (^CYLTabBarPageProvider)(NSString *pageIdentifier, NSDictionary<NSString *, id> *tabAttributes);

/*!
 * FIX: issue #535
 * [EN] Built-in tap animations, see `cyl_tabButtonTapAnimationType`.
 * [CN] 内置的点击动画，见 `cyl_tabButtonTapAnimationType`。
 */
typedef NS_ENUM(NSInteger, CYLTabButtonTapAnimationType) {
    /*!
     * [EN] No animation (default). [CN] 无动画（默认）。
     */
    CYLTabButtonTapAnimationTypeNone = 0,
    /*!
     * [EN] 1.0 → 1.5 → 0.8 → 1.0, `CYLTabButtonScaleAnimation`. [CN] 放大再缩小。
     */
    CYLTabButtonTapAnimationTypeScale,
    /*!
     * [EN] Grows from small, `CYLTabButtonZoomInAnimation`. [CN] 从小放大。
     */
    CYLTabButtonTapAnimationTypeZoomIn,
    /*!
     * [EN] Elastic bounce, `CYLTabButtonBounceAnimation`. [CN] 弹性动画。
     */
    CYLTabButtonTapAnimationTypeBounce,
    /*!
     * [EN] Bounce with fireworks. [CN] 弹性动画加烟花。
     */
    CYLTabButtonTapAnimationTypeBounceWithFireworks,
    /*!
     * [EN] One full turn, `CYLTabButtonRotationAnimation`. [CN] 旋转一圈。
     */
    CYLTabButtonTapAnimationTypeRotation,
    /*!
     * [EN] Flip from left, `CYLTabButtonFlipAnimation`. [CN] 从左翻转。
     */
    CYLTabButtonTapAnimationTypeFlip,
    /*!
     * [EN] Icon down, title floats away, `CYLTabButtonFumeAnimation`. [CN] 图标下移、标题飘散。
     */
    CYLTabButtonTapAnimationTypeFume,
};

typedef void (^CYLTabBarControllerDidLongPressControlBlock)(CYLTabBarController *tabBarController, UIControl *control);

/*!
 * [EN] Returns the view that shows a tab's icon: `selected` NO for the unselected look, YES for the selected one (`-setTabBarItemIconViewProvider:atIndex:`).
 * [CN] 返回显示 Tab 图标的视图：`selected` 为 NO 表示未选中外观，为 YES 表示选中外观（`-setTabBarItemIconViewProvider:atIndex:`）。
 */
typedef UIView * _Nullable (^CYLTabBarItemIconViewProvider)(BOOL selected);

NS_ASSUME_NONNULL_END
