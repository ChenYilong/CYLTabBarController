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
    self.window.backgroundColor = UIColor.systemBackgroundColor; // [EN] Dark Mode. [CN] 适配深色模式。
    [self setUpBadgeAppearance];
    
    // Rebuilt after a language change (the language row in every list), so every text shows in the new language.
    [self.window cyl_setRootViewControllerProvider:^UIViewController *{
        return [[CYLMainRootViewController alloc] init];
    }];
    [self.window makeKeyAndVisible];
    // [CN] 要根据你的window与tabbar的关系，来设置， 如果你 设置了 self.window.rootViewController = rootViewController; 那么你应该用下面的方式来设置暗黑模式, 否则 window的overrideUserInterfaceStyle 不认, 只跟随系统
    // [EN] Set this according to the relationship between your window and tabbar. If you set
    //      self.window.rootViewController = rootViewController; then you should set Dark Mode as below; otherwise the
    //      window's overrideUserInterfaceStyle is ignored and it only follows the system.
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

/**
 * [CN] 设置navigationBar样式
 * [EN] Set the navigationBar style
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
