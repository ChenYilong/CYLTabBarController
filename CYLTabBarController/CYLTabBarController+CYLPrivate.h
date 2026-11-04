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
+ (CYLTabBarController *)cyl_tabBarControllerForContext:(NSString *)context matching:(CYLTabBarControllerMatcher)matcher;
@end
