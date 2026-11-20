//
//  CYLTabBarControllerTypedefs.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// CYL-SWIFT-MIGRATION: objc-required — [EN] the block typedefs and option sets above, and the C symbols below (the C data globals defined in
// CYLTabBarControllerGlobals.m, and the prototypes of the `@_cdecl` functions): Swift cannot export a data symbol or an `NS_OPTIONS`, and
// Objective-C callers that do not import the Swift module need the prototypes. [CN] 上述 block typedef 与选项集，以及下方的 C 符号（定义于
// CYLTabBarControllerGlobals.m 的 C 全局变量，以及 `@_cdecl` 函数的原型）：Swift 无法导出数据符号或 `NS_OPTIONS`，不导入 Swift 模块的
// Objective-C 调用方需要这些原型。

#import <UIKit/UIKit.h>
#if __has_include("CYLUtils/CYLUtilsMacros.h")
#import "CYLUtils/CYLUtilsMacros.h"
#else
#import "CYLUtilsMacros.h"
#endif

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

#pragma mark - C symbols (moved from CYLTabBarController.h)

/*!
 * [EN] Returns `attributes` with a Lottie animation added to each item: `CYLTabBarLottieFilePath` for "<name>.json" in
 *      `bundle` (nil: the main bundle), and `CYLTabBarLottieDarkFilePath` for "<name>_dark.json" when that file exists
 *      (the suffix is `UIImage.cyl_darkImageNameSuffix`, as for images). Names are matched by position; an item without a
 *      name, or whose file is missing, is left as it is.
 *
 *          // green_lottie_tab_home.json, green_lottie_tab_home_dark.json, ...
 *          CYLTabBarItemsAttributesAddingLottieFiles(attributes, @[@"green_lottie_tab_home", @"green_lottie_tab_discover"], nil);
 *
 *      A Lottie file holds fixed colors and lottie-ios has no themes, so a dark version is a copy of the animation with
 *      dark colors. With Lottie 4.x, one file can also follow Dark Mode by itself: see `CYLTabBarLottieDarkColors`.
 * [CN] 返回为每个 item 添加了 Lottie 动画的 `attributes`：`CYLTabBarLottieFilePath` 为 `bundle`（nil 表示 main bundle）中的
 *      「<名称>.json」；存在「<名称>_dark.json」时再加上 `CYLTabBarLottieDarkFilePath`（后缀与图片相同，为
 *      `UIImage.cyl_darkImageNameSuffix`）。名称按位置对应；没有名称或文件不存在的 item 保持不变。示例见上。
 *      Lottie 文件中的颜色是固定的，lottie-ios 也不支持主题，因此深色版本即改为深色配色的动画副本。使用 Lottie 4.x 时，也可以只用一份文件
 *      适配深色模式，见 `CYLTabBarLottieDarkColors`。
 */
FOUNDATION_EXTERN NSArray *CYLTabBarItemsAttributesAddingLottieFiles(NSArray *attributes,
                                                                     NSArray *lottieFileNames,
                                                                                    NSBundle * _Nullable bundle) CYL_NOEXCEPT CYL_LOTTIE_REQUIRED;

/*!
 * FIX: issue #477 — only some tabs animated, with any animation library.
 * [EN] Returns one tab's `attributes` with an animation added (`CYLTabBarAnimationFilePath`, and
 *      `CYLTabBarAnimationDarkFilePath` when "<name>_dark.<ext>" exists), so that only that tab is animated and the others
 *      keep their images. `fileName` is "<name>.<ext>" for that file, or "<name>" for the first file found with the
 *      extensions of the libraries in the build, in their lookup order (PAG ".pag", Lottie ".json" / ".lottie", or any
 *      library added later). `bundle` nil means the main bundle. A missing file, or no animation library, leaves
 *      `attributes` as they are. Animated and static tabs, and tabs of different libraries, can be mixed in one tab bar,
 *      in every style.
 *
 *          NSArray *attributes = @[
 *              homeAttributes,                                                                     // images only
 *              CYLTabBarItemAttributesAddingAnimationFile(messageAttributes, @"tab_message.json", nil), // Lottie
 *              CYLTabBarItemAttributesAddingAnimationFile(mineAttributes, @"tab_mine.pag", nil),        // PAG
 *          ];
 * [CN] 返回添加了动画的单个 Tab 的 `attributes`（`CYLTabBarAnimationFilePath`；存在「名称_dark.扩展名」时再加上
 *      `CYLTabBarAnimationDarkFilePath`），使只有该 Tab 有动画，其他 Tab 保持图片。`fileName` 为「名称.扩展名」时使用该文件；为「名称」时，
 *      按查找顺序使用构建中各动画库的扩展名（PAG ".pag"、Lottie ".json" / ".lottie"，或以后新增的动画库），取第一个存在的文件。`bundle` 为 nil
 *      表示 main bundle。文件不存在或没有动画库时 `attributes` 保持不变。同一个 TabBar 中可以混用有动画与无动画的 Tab，以及不同动画库的 Tab，
 *      所有样式均支持。示例见上。
 */
FOUNDATION_EXTERN NSDictionary *CYLTabBarItemAttributesAddingAnimationFile(NSDictionary *attributes,
                                                                          NSString *fileName,
                                                                          NSBundle * _Nullable bundle) CYL_NOEXCEPT;

/*!
 * [EN] The same for every tab, by position: an empty name or `NSNull` leaves that tab static (#477).
 *
 *          CYLTabBarItemsAttributesAddingAnimationFiles(attributes, @[@"tab_home.json", @"", @"tab_mine.pag"], nil);
 * [CN] 按位置为每个 Tab 执行上面的操作：名称为空字符串或 `NSNull` 的 Tab 保持静态（#477）。示例见上。
 */
FOUNDATION_EXTERN NSArray *CYLTabBarItemsAttributesAddingAnimationFiles(NSArray *attributes,
                                                                        NSArray *fileNames,
                                                                                    NSBundle * _Nullable bundle) CYL_NOEXCEPT;

/*!
 * [EN] These globals hold what was written LAST, by whichever tab bar controller or plus button wrote last. The library
 *      no longer lays out with them: with several tab bar controllers they overwrote each other (a tab bar with 5 items
 *      was laid out with the 3 of the one pushed after it, issues #414, #489). Each tab bar keeps its own values:
 *      `-[UIView cyl_tabbarItemsCount]`, `-[UIView cyl_tabBarItemWidth]`, `-[UIView cyl_plusButtonIndex]`,
 *      `-[UIView cyl_plusButtonWidth]` (see UIView+CYLTabBarControllerExtention.h) and `-[CYLTabBarController tabBarHeight]`.
 *      With one tab bar controller they are what they always were.
 * [CN] 这些全局变量保存的是 **最后一次** 写入的值，由最后写入的 TabBarController 或 PlusButton 决定。库不再使用它们来布局：
 *      存在多个 TabBarController 时它们会互相覆盖（5 个 item 的 TabBar 按后面 push 进来的 3 个 item 来布局，issue #414、#489）。
 *      每个 TabBar 保存自己的值：`-[UIView cyl_tabbarItemsCount]`、`-[UIView cyl_tabBarItemWidth]`、`-[UIView cyl_plusButtonIndex]`、
 *      `-[UIView cyl_plusButtonWidth]`（见 UIView+CYLTabBarControllerExtention.h）和 `-[CYLTabBarController tabBarHeight]`。
 *      只有一个 TabBarController 时，它们与以前完全一致。
 */
FOUNDATION_EXTERN NSUInteger CYLTabbarItemsCount;

FOUNDATION_EXTERN NSUInteger CYLPlusButtonIndex;

FOUNDATION_EXTERN CGFloat CYLPlusButtonCurrentWidth(void);

FOUNDATION_EXTERN CGFloat CYLTabBarItemWidth;

FOUNDATION_EXTERN CGFloat CYLTabBarHeight;

FOUNDATION_EXTERN NSString *const CYLTabBarItemLottieAnimationPlayingNotification DEPRECATED_MSG_ATTRIBUTE("Use CYLTabBarItemAnimationPlayingNotification");

/*!
 * [EN] Posted after a Lottie animation view is added to a tab button (issue #428). The notification's `object` is the tab
 *      button; get the view with `-[UIControl cyl_lottieAnimationView]`. Posted on the main queue, after
 *      `-[CYLTabBarController lottieAnimationSpeed]` has been applied, so a value set in the handler is kept.
 *      In the Liquid Glass style a tab has two buttons (normal and selected), so it is posted once for each.
 * [CN] Lottie 动画视图添加到 Tab 按钮后发送（issue #428）。通知的 `object` 为 Tab 按钮，可用
 *      `-[UIControl cyl_lottieAnimationView]` 取得动画视图。在主队列发送，此时已设置 `-[CYLTabBarController lottieAnimationSpeed]`，
 *      在回调中设置的值不会被覆盖。液态玻璃样式中每个 Tab 有普通与选中两个按钮，因此各发送一次。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarItemLottieAnimationViewDidAddNotification DEPRECATED_MSG_ATTRIBUTE("Use CYLTabBarItemAnimationViewDidAddNotification");

@class CYLThemeManager;

 //TODO:  
/*!
 * [CN] * 液态玻璃开关变化
 * [EN] Liquid Glass toggle changed
 */
FOUNDATION_EXTERN NSString *const CYLTabBarStyleTypeDidChangeNotification;

NS_ASSUME_NONNULL_END
