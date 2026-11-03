//
//  AppDelegate.h
//  CYLTabBarControllerDemo
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

/*!
 * [EN] The orientations set in Xcode (Deployment Info), i.e. `UISupportedInterfaceOrientations` in Info.plist (its
 *      `~ipad` variant on iPad).
 * [CN] Xcode 中设置的方向（Deployment Info），即 Info.plist 的 `UISupportedInterfaceOrientations`（iPad 上为 `~ipad`）。
 */
FOUNDATION_EXTERN UIInterfaceOrientationMask CYLInfoPlistSupportedInterfaceOrientations(void);

@end

