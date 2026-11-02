//
//  SceneDelegate.m
//  CYLTabBarController
//
//  Created by chenyilong on 2026/4/16.
//  Copyright © 2026 微博@iOS程序犭袁. All rights reserved.
//

#import "SceneDelegate.h"
#import "CYLMainRootViewController.h"
#import <CYLTabBarController/CYLLocalization.h>

NS_ASSUME_NONNULL_BEGIN

@implementation SceneDelegate

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session
      options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) { return; }
    
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.frame = windowScene.coordinateSpace.bounds;
    self.window.backgroundColor = [UIColor whiteColor];
    [self setUpBadgeAppearance];
    
    // Rebuilt after a language change (the language row in every list), so every text shows in the new language.
    [self.window cyl_setRootViewControllerProvider:^UIViewController *{
        return [[CYLMainRootViewController alloc] init];
    }];
    [self.window makeKeyAndVisible];
    //要根据你的window与tabbar的关系，来设置， 如果你 设置了 self.window.rootViewController = rootViewController; 那么你应该用下面的方式来设置暗黑模式, 否则 window的overrideUserInterfaceStyle 不认, 只跟随系统
//    self.window.rootViewController.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;

//    [UIWindow appearance].overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    [self setUpNavigationBarAppearance];
}
 
/*!
 * #425: the badge style shared by the whole demo, set once before any badge is shown. Badges then set only what
 * differs (e.g. a random color, or the "NEW" tab's offset). Red background and white text are already the defaults.
 * #425：整个 Demo 共用的角标样式，在显示任何角标之前统一设置一次。之后每个角标只需设置不同之处
 * （如随机颜色、"NEW" Tab 的偏移）。红色背景和白色文字本来就是默认值，无需设置。
 */
- (void)setUpBadgeAppearance {
    [CYLBadgeAppearance globalAppearance].centerOffset = CGPointMake(-5, 3);
}

CYL_METHOD_SIGNATURES_PUSH
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    //设置强制旋转屏幕
    if (self.cyl_isForceLandscape) {
        //只支持横屏
        return UIInterfaceOrientationMaskLandscape;
    } else {
        //只支持竖屏
        return UIInterfaceOrientationMaskPortrait;
    }
}
CYL_METHOD_SIGNATURES_POP
/**
 *  设置navigationBar样式
 */
- (void)setUpNavigationBarAppearance {
//    UINavigationBar *navigationBarAppearance = [UINavigationBar appearance];
//    UIColor *backgroundColor = [UIColor cyl_systemBackgroundColor];
//    NSDictionary *textAttributes = nil;
//    UIColor *labelColor =   [UIColor cyl_labelColor];
//
//    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
//        textAttributes = @{
//                           NSFontAttributeName : [UIFont boldSystemFontOfSize:18],
//                           NSForegroundColorAttributeName : labelColor,
//                           };
//    } else {
//#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
//        textAttributes = @{
//                           UITextAttributeFont : [UIFont boldSystemFontOfSize:18],
//                           UITextAttributeTextColor : labelColor,
//                           UITextAttributeTextShadowColor : [UIColor clearColor],
//                           UITextAttributeTextShadowOffset : [NSValue valueWithUIOffset:UIOffsetZero],
//                           };
//#endif
//    }
//    [navigationBarAppearance setBarTintColor:backgroundColor];
//    [navigationBarAppearance setTitleTextAttributes:textAttributes];
}

@end

NS_ASSUME_NONNULL_END
