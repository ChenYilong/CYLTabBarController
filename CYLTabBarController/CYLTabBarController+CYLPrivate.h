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

/// [EN] Implemented in CYLTabBarController.m (CYLTheme, issue #216). [CN] 实现见 CYLTabBarController.m 中的 CYLTheme（issue #216）。
@interface CYLTabBarController (CYLThemePrivate)
/// [EN] Once, when first shown: the theme chosen at launch. [CN] 首次显示时执行一次：应用启动时选择的主题。
- (void)cyl_applyLaunchTabBarThemeIfNeeded;
/// [EN] Implemented in the main implementation (tabBar.standardAppearance). [CN] 实现于主 implementation（tabBar.standardAppearance）。
- (void)cyl_syncTabBarAppearances;
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

NS_ASSUME_NONNULL_END
