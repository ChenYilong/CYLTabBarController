//
//  UIViewController+CYLTabBarControllerExtention.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 16/2/26.
// [CN] Copyright © 2026年 https://github.com/ChenYilong .All rights reserved.
// [EN] Copyright © 2026 https://github.com/ChenYilong .All rights reserved.
//

// [CN] FIX: issue #535 — see CYLTabBarController.h. 见 CYLTabBarController.h。
// [EN] FIX: issue #535 — see CYLTabBarController.h.
#if __has_include("CYLBadgeView/CYLBadgeProtocol.h")
// [CN] FIX: issue #535 — shared with CYLBadgeView through CYLUtils. 通过 CYLUtils 与 CYLBadgeView 共用。
// [EN] FIX: issue #535 — shared with CYLBadgeView through CYLUtils.
#if __has_include("CYLUtils/UIViewController+CYLUtils.h")
#import "CYLUtils/UIViewController+CYLUtils.h"
#else
#import "UIViewController+CYLUtils.h"
#endif
#import "CYLBadgeView/CYLBadgeProtocol.h"
#else
#import "CYLBadgeProtocol.h"
#endif
#import "CYLConstants.h"
#if CYL_FLATDESIGN_AVAILABLE
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The page a `-cyl_popSelectTabBarChildViewController…` call selected; nil when the index, class type or identifier is
 *      not a tab (it always was, the nonnull declaration was wrong).
 * [CN] `-cyl_popSelectTabBarChildViewController…` 选中的页面；index、classType 或标识不是 Tab 时为 nil（一直如此，原先的非空声明有误）。
 */
typedef void (^CYLPopSelectTabBarChildViewControllerCompletion)(__kindof UIViewController * _Nullable selectedTabBarChildViewController);

typedef void (^CYLPushOrPopCompletionHandler)(BOOL shouldPop,
                                              __kindof UIViewController * _Nullable viewControllerPopTo,
                                              BOOL shouldPopSelectTabBarChildViewController,
                                              NSUInteger index
                                              );

typedef void (^CYLPushOrPopCallback)(NSArray<__kindof UIViewController *> *viewControllers, CYLPushOrPopCompletionHandler completionHandler);

/*!
 * [EN] `UIViewController (CYLTabBarControllerExtention)` and `UIViewController (CYLTabBarControllerExtentionDeprecated)` are
 *      implemented in Swift (`Swift/UIViewController+CYLTabBarControllerExtention.swift`, every selector kept) and declared by
 *      the generated Swift interface (`CYLSwiftInterface.h`), imported at the end of this header. The `CYLBadgeProtocol`
 *      conformance stays declared here: a public Swift conformance to a protocol of this module would make the generated
 *      header import the umbrella header. The FlatDesign `cyl_tabBarItem` is in the FlatDesign subspec
 *      (`UIViewController+CYLFlatDesignTabBarItem.swift`); `cylflatdesign_tabBarController` is declared on `NSObject` in
 *      CYLTabBarController.h (docs/Swift-Migration.md, step 27).
 * [CN] `UIViewController (CYLTabBarControllerExtention)` 与 `UIViewController (CYLTabBarControllerExtentionDeprecated)` 在 Swift 中实现
 *      （`Swift/UIViewController+CYLTabBarControllerExtention.swift`，所有 selector 不变），由本头文件末尾导入的 Swift 生成接口
 *      （`CYLSwiftInterface.h`）声明。`CYLBadgeProtocol` 遵循仍在此声明：Swift 公开遵循本模块的协议会让生成的头文件导入总头文件。扁平样式的
 *      `cyl_tabBarItem` 位于扁平样式子库（`UIViewController+CYLFlatDesignTabBarItem.swift`）；`cylflatdesign_tabBarController` 在
 *      CYLTabBarController.h 中声明于 `NSObject`（docs/Swift-Migration.md，第 27 步）。
 */
@interface UIViewController (CYLTabBarControllerExtention)<CYLBadgeProtocol>
@end

NS_ASSUME_NONNULL_END

#import "CYLSwiftInterface.h"
