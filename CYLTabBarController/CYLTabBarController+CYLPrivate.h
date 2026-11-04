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
