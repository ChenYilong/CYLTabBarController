//
//  CYLTabBarController+CYLPrivate.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Private header of Core, not part of the public API: the declarations that CYLTabBarController.m and the files
//      split out of it (CYLTabBarController+CYL….m) share.
// [CN] Core 的私有头文件，不属于公开 API：CYLTabBarController.m 与从中拆分出的文件（CYLTabBarController+CYL….m）共用的声明。

#import "CYLTabBarController.h"
#import "CYLPlusButton.h"

NS_ASSUME_NONNULL_BEGIN

/// [EN] Implemented in CYLTabBarController+CYLTabBarMinimize.m (issue #13). [CN] 实现见 CYLTabBarController+CYLTabBarMinimize.m（issue #13）。
@interface CYLTabBarController (CYLTabBarMinimizePrivate)
/// [EN] FlatDesign: observe the scroll view of the page on screen. [CN] 扁平样式：观察当前显示页面的滚动视图。
- (void)cyl_updateTabBarMinimizeTracking;
/// [EN] Liquid Glass: expand a tab bar the system minimized (issue #13 lifecycle restore).
/// [CN] 液态玻璃：恢复被系统缩小的 TabBar（issue #13 生命周期恢复）。
- (void)cyl_expandSystemMinimizedTabBar;
/// [EN] Liquid Glass: a new drag started, give the system its minimize behavior back.
/// [CN] 液态玻璃：新的拖动开始，把缩小行为交还给系统。
- (void)cyl_releaseSystemMinimizeHoldIfNeeded;
/// [EN] A view lifecycle event of this controller (appear, disappear, size change): ends any hide session.
/// [CN] 本控制器的视图生命周期事件（出现、消失、尺寸变化）：结束隐藏会话。
- (void)cyl_tabBarMinimizeLifecycleEvent;
/// [EN] Every `-setTabBarHidden:animated:` call: one not made by scroll hiding is the app taking the tab bar over.
/// [CN] 每次 `-setTabBarHidden:animated:` 调用：不是滚动隐藏发出的调用，即 App 接管 TabBar。
- (void)cyl_tabBarMinimizeDidReceiveTabBarHiddenRequest:(BOOL)hidden;
/// [EN] The scroll view that drives the tab bar for `viewController`, as UIKit picks it (also used by CYLReselect's
///      scroll to top). nil when there is none or the view is not loaded.
/// [CN] `viewController` 中控制 TabBar 的滚动视图，与 UIKit 的选择方式一致（CYLReselect 的滚动到顶部也使用）。没有或视图未加载时为 nil。
- (nullable UIScrollView *)cyl_tabBarMinimizeScrollViewForViewController:(nullable UIViewController *)viewController;
@end

/// [EN] Implemented in `CYLPlusButton.m`. [CN] 在 `CYLPlusButton.m` 中实现。
@interface CYLPlusButton (CYLLiquidGlassPrivate)
/// [EN] With a plus child: the stand-in shows the plus button's normal image. [CN] 有 PlusButton 子控制器时：替身显示 PlusButton 普通状态的图片。
- (void)cyl_updateSelectedContentViewImage;
/// [EN] In the layouts where the stand-in follows the plus button, puts it in place. [CN] 在替身跟随 PlusButton 的布局中放置替身。
- (void)cyl_moveSelectedContentViewWithPlusButton;
/// [EN] Puts the stand-in in place, in every layout. [CN] 在所有布局中放置替身。
- (void)cyl_placeSelectedContentView;
/// [EN] A button whose picture is its background image, its title on it. [CN] 以背景图为图片、标题画在图上的按钮。
- (BOOL)cyl_drawsTitleOverBackgroundImage;
/// [EN] Runs `handler` whenever a background image is set for the normal state; nil stops it. [CN] 每次为普通状态设置背景图片时执行 `handler`；传 nil 则停止。
- (void)cyl_setBackgroundImageDidChangeHandler:(nullable void (^)(void))handler;
/// [EN] Removes the image from the plus button and its stand-in, in every state. [CN] 移除 PlusButton 及其替身所有状态的图片。
- (void)cyl_removeImage;
/// [EN] While the Liquid Glass gesture presses or drags, the lens mask is off; it is checked again once the lens settles.
/// [CN] 液态玻璃手势按压或拖动期间关闭放大镜遮罩；放大镜停稳后再重新判断。
- (void)cyl_setLiquidGlassLensMaskSuspended:(BOOL)suspended;
@end

/// [EN] Implemented in CYLTabBarController.m (CYLTheme, issue #216). [CN] 实现见 CYLTabBarController.m 中的 CYLTheme（issue #216）。
@interface CYLTabBarController (CYLThemePrivate)
/// [EN] Registers the skins of a normalized configuration (`CYLTabBarControllerThemes`) and applies the first one. [CN] 注册规范化配置中的皮肤（`CYLTabBarControllerThemes`）并应用首个皮肤。
- (void)cyl_applyConfigurationThemes:(NSDictionary<NSString *, id> *)normalizedConfiguration;
/// [EN] Once, when first shown: the theme chosen at launch. [CN] 首次显示时执行一次：应用启动时选择的主题。
- (void)cyl_applyLaunchTabBarThemeIfNeeded;
/// [EN] Implemented in the main implementation (tabBar.standardAppearance). [CN] 实现于主 implementation（tabBar.standardAppearance）。
- (void)cyl_syncTabBarAppearances;
/// [EN] The icon view providers by view controller (theme icons use them). [CN] 按子控制器保存的图标视图 provider（主题图标会使用）。
- (NSMapTable<UIViewController *, CYLTabBarItemIconViewProvider> *)cyl_tabBarItemIconViewProviders;
/// [EN] Removes `keys` from the attributes of the tab at `index` (a key a theme added that the app did not have).
/// [CN] 从第 `index` 个 Tab 的 attributes 中移除 `keys`（主题添加、App 原本没有的 key）。
- (void)cyl_themeRemoveTabBarItemAttributeKeys:(NSArray<NSString *> *)keys atIndex:(NSUInteger)index;
/// [EN] The one-time layout block runs once more. [CN] 只执行一次的布局 block 再执行一次。
- (void)cyl_rearmViewDidLayoutSubviewsBlockInvokeOnce;
/// [EN] Loads a tab icon (a UIImage, a name, a path or a URL), asynchronously for a URL. [CN] 加载 Tab 图标（UIImage、图片名、路径或 URL），URL 为异步。
+ (void)cyl_loadTabBarItemIcon:(nullable id)icon completion:(void (^)(UIImage *_Nullable image))completion;
@end

/// [EN] Implemented in CYLTabBarController.m (tab bar customization toolkit). [CN] 实现见 CYLTabBarController.m（TabBar 自定义工具集）。
@interface CYLTabBarController (CYLTabBarToolkitPrivate)
/// [EN] CYLTabBarItemStyle: writes the stored item styles into the tab bar. [CN] CYLTabBarItemStyle：把保存的 item 样式写入 TabBar。
- (void)cyl_applyTabBarItemStyles;
/// [EN] CYLOpaqueTabBarSafeArea: keeps the page's bottom clear of an opaque tab bar. [CN] CYLOpaqueTabBarSafeArea：避免不透明 TabBar 遮挡页面底部。
- (void)cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded;
@end

// [EN] Implemented in CYLTabBarController+CYLInteraction.m: the pressed (highlight / dehighlight) animation of a button.
// [CN] 在 CYLTabBarController+CYLInteraction.m 中实现：按钮的按下（highlight / dehighlight）动画。
@interface CYLTabBarController (CYLTabButtonHighlight)
- (void)cyl_tabButtonTouchDown:(UIControl *)control;
- (void)cyl_tabButtonTouchUp:(UIControl *)control;
@end

/// [EN] Implemented in CYLTabBarController.m (CYLReselect). [CN] 实现见 CYLTabBarController.m 中的 CYLReselect。
@interface CYLTabBarController (CYLReselectPrivate)
/// [EN] The view controller of a tab button (classic or Liquid Glass), nil for the plus button. [CN] Tab 按钮对应的控制器，PlusButton 返回 nil。
- (nullable UIViewController *)cyl_viewControllerForTabControl:(UIControl *)control;
/// [EN] Runs `cyl_reselectBehavior` for a reselected tab. [CN] 为重复点击的 Tab 执行 `cyl_reselectBehavior`。
- (void)cyl_performReselectBehaviorForViewController:(UIViewController *)viewController;
@end

/// [EN] Per-tab colors, implemented in the main implementation. [CN] 单个 Tab 的颜色，在主实现中实现。
@interface CYLTabBarController (CYLTabBarItemColorsPrivate)
- (void)cyl_updateSelectedBackgroundColorsOfTabButtons;
- (void)cyl_setNeedsUpdateSelectedBackgroundColors;
- (void)cyl_updateLoopingLottieViews;
- (void)cyl_updateBadgesOfSelectedTab;
- (void)cyl_syncTabBarItemAccessibility;
#if CYL_FLATDESIGN_AVAILABLE
- (void)cyl_syncFlatDesignTabBarItemColors;
#endif
@end

/// [EN] Implemented in CYLTabBarController.m: the plus button of this controller's context, and its child view controller.
///      Used by CYLTabBarController+CYLTabBarControllerLookup.m (identifiers #408, the selected index without the plus
///      button #515).
/// [CN] 实现见 CYLTabBarController.m：本控制器 context 的 PlusButton 及其子控制器。供
///      CYLTabBarController+CYLTabBarControllerLookup.m 使用（标识 #408、不含 PlusButton 的选中下标 #515）。
@interface CYLTabBarController (CYLContextPlusButtonPrivate)
- (nullable CYLPlusButton<CYLPlusButtonSubclassing> *)cyl_contextPlusButton;
- (nullable UIViewController *)cyl_contextPlusChildViewController;
/// [EN] The plus button's slot (its placeholder or plus child view controller), see "Plus slot" in CYLTabBarController.m.
/// [CN] PlusButton 的 slot（占位控制器或 PlusButton 子控制器），见 CYLTabBarController.m 中的 "Plus slot"。
- (BOOL)cyl_isPlusSlotViewController:(UIViewController *)viewController;
/// [EN] The tab buttons of `viewController` (two with Liquid Glass: the normal and the selected layer). [CN] `viewController` 的 Tab 按钮（液态玻璃为两个：普通层与选中层）。
- (NSArray<UIControl *> *)cyl_tabButtonsOfViewController:(UIViewController *)viewController;
@end

/// [EN] Which tab bar controllers a lookup accepts; nil accepts any CYLTabBarController.
/// [CN] 查找时接受哪些 TabBarController；nil 表示接受任意 CYLTabBarController。
typedef BOOL (^CYLTabBarControllerMatcher)(CYLTabBarController *tabBarController);

/// [EN] Implemented in CYLTabBarController+CYLTabBarControllerLookup.m: the registry of live tab bar controllers.
/// [CN] 实现见 CYLTabBarController+CYLTabBarControllerLookup.m：存活的 TabBarController 的注册表。
@interface CYLTabBarController (CYLActiveTabBarControllerPrivate)
+ (void)cyl_registerTabBarController:(CYLTabBarController *)tabBarController;
+ (void)cyl_markTabBarControllerActive:(CYLTabBarController *)tabBarController;
+ (nullable CYLTabBarController *)cyl_tabBarControllerForContext:(nullable NSString *)context matching:(nullable CYLTabBarControllerMatcher)matcher;
@end

/// [EN] FIX: issue #152 — implemented in CYLTabBarController+CYLTabBarItemGesture.m. [CN] 实现见 CYLTabBarController+CYLTabBarItemGesture.m。
@interface CYLTabBarController (CYLTabBarItemGesturePrivate)
- (void)cyl_recognizeTabBarItemGestureForReportedControl:(UIControl *)control;
- (void)cyl_installTabBarItemLongPressIfNeeded;
- (BOOL)cyl_isTabBarItemGestureControl:(UIControl *)control viewController:(UIViewController *__autoreleasing _Nullable *_Nullable)viewController;
- (void)cyl_reportTabBarItemGesture:(CYLTabBarItemGesture)gesture control:(UIControl *)control viewController:(nullable UIViewController *)viewController;
- (void)cyl_recognizeTapOnControl:(UIControl *)control viewController:(nullable UIViewController *)viewController isReselect:(BOOL)isReselect;
- (void)cyl_recognizeTabBarItemTapWillSelectViewController:(UIViewController *)viewController;
- (void)cyl_recognizeTabBarItemTapOnControl:(UIControl *)control viewController:(nullable UIViewController *)viewController isReselect:(BOOL)isReselect;
@end

/// [EN] FIX: issue #535 — implemented in CYLTabBarController+CYLInteraction.m. [CN] 实现位于 CYLTabBarController+CYLInteraction.m。
@interface CYLTabBarController (CYLInteractionInstall)
- (void)cyl_installInteractionGestureRecognizersIfNeeded;
- (BOOL)cyl_liquidGlassTakesTabTaps;
@end

/*!
 * [EN] The two jobs of the deprecated `cyl_userInteractionDisabled` / `cyl_shouldNotSelect`, kept apart (implemented in
 *      UIControl+CYLTabBarControllerExtention.m):
 *      - `CYLControlIsSelectionLocked` / `CYLControlSetSelectionLocked`: the library's lock on the selected tab button
 *        (same stored value as the deprecated properties, so an app that still sets them keeps its behavior);
 *      - `CYLControlReportsTaps`: whether a tap on `control` is reported through `tabBarController:didSelectControl:`.
 *        For a plus button that is `reportsTapsToDelegate`; for any other control, "not locked".
 * [CN] 已废弃的 `cyl_userInteractionDisabled` / `cyl_shouldNotSelect` 承担的两件事，在这里分开（实现位于 UIControl+CYLTabBarControllerExtention.m）：
 *      - `CYLControlIsSelectionLocked` / `CYLControlSetSelectionLocked`：库对已选中 Tab 按钮的锁定（与废弃属性存储同一个值，仍在设置它们的
 *        App 行为不变）；
 *      - `CYLControlReportsTaps`：点击 `control` 是否通过 `tabBarController:didSelectControl:` 上报。PlusButton 为 `reportsTapsToDelegate`；
 *        其他控件为“未锁定”。
 */
FOUNDATION_EXTERN BOOL CYLControlIsSelectionLocked(UIControl *_Nullable control);
FOUNDATION_EXTERN void CYLControlSetSelectionLocked(UIControl *_Nullable control, BOOL locked);
FOUNDATION_EXTERN BOOL CYLControlReportsTaps(UIControl *_Nullable control);

NS_ASSUME_NONNULL_END
