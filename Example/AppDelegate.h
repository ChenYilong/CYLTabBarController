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
 * FIX: issue #680
 * [EN] YES on a foldable device such as the iPhone Duo (set by CYLMainRootViewController from UIHingeInteraction).
 *      The demo then follows the device into landscape, so the unfolded inner screen is filled instead of showing
 *      a portrait window. Other devices stay portrait-only, as before.
 * [CN] 可折叠设备（如 iPhone Duo）上为 YES（由 CYLMainRootViewController 通过 UIHingeInteraction 设置）。
 *      此时 Demo 跟随设备横屏，展开内屏横屏时铺满屏幕，而不是显示竖屏窗口。其他设备保持仅竖屏，与之前一致。
 */
@property (nonatomic, assign) BOOL supportsLandscapeOnFoldableDevice;

@end

