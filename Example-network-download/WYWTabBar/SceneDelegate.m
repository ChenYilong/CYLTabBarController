//
//  SceneDelegate.m
//  WYWTabBar
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "SceneDelegate.h"
#import "AppDelegate.h"

@implementation SceneDelegate

// [EN] Creates the window for the scene: apps built with the iOS 27 SDK must adopt the UIScene life cycle.
// [CN] 为 scene 创建 window：使用 iOS 27 SDK 构建的 App 必须采用 UIScene 生命周期。
- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.backgroundColor = [UIColor whiteColor];
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    appDelegate.window = self.window;
    [appDelegate showTabBarControllerWithStyle:CYLTabBarStyleTypeLiquidGlass];
    [self.window makeKeyAndVisible];
}

@end
