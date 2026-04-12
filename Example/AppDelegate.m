//
//  AppDelegate.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "AppDelegate.h"
#import "CYLPlusButtonSubclass.h"
#import "CYLMainRootViewController.h"

@interface AppDelegate ()
@property (nonatomic, strong) NSMutableData *data;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [UIApplication sharedApplication].statusBarHidden = NO;
#pragma clang diagnostic pop
    // 设置主窗口,并设置根控制器
    self.window = [[UIWindow alloc] init];
    self.window.frame = [UIScreen mainScreen].bounds;
    [self.window makeKeyAndVisible];
    CYLMainRootViewController *rootViewController = [[CYLMainRootViewController alloc] init];
    [self.window setRootViewController:rootViewController];
    [self setUpNavigationBarAppearance];
//    CYLGetRootWindow().overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
//    [UIWindow appearance].overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
    return YES;
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
    UINavigationBar *navigationBarAppearance = [UINavigationBar appearance];
    UIColor *backgroundColor = [UIColor cyl_systemBackgroundColor];
    NSDictionary *textAttributes = nil;
    UIColor *labelColor =   [UIColor cyl_labelColor];

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        textAttributes = @{
                           NSFontAttributeName : [UIFont boldSystemFontOfSize:18],
                           NSForegroundColorAttributeName : labelColor,
                           };
    } else {
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_7_0
        textAttributes = @{
                           UITextAttributeFont : [UIFont boldSystemFontOfSize:18],
                           UITextAttributeTextColor : labelColor,
                           UITextAttributeTextShadowColor : [UIColor clearColor],
                           UITextAttributeTextShadowOffset : [NSValue valueWithUIOffset:UIOffsetZero],
                           };
#endif
    }
    [navigationBarAppearance setBarTintColor:backgroundColor];
    [navigationBarAppearance setTitleTextAttributes:textAttributes];
}

@end
