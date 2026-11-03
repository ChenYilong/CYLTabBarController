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

UIInterfaceOrientationMask CYLInfoPlistSupportedInterfaceOrientations(void) {
    NSDictionary *info = NSBundle.mainBundle.infoDictionary;
    NSArray<NSString *> *orientations = nil;
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        orientations = info[@"UISupportedInterfaceOrientations~ipad"];
    }
    if (orientations.count == 0) {
        orientations = info[@"UISupportedInterfaceOrientations"];
    }
    NSDictionary<NSString *, NSNumber *> *masks = @{
        @"UIInterfaceOrientationPortrait": @(UIInterfaceOrientationMaskPortrait),
        @"UIInterfaceOrientationPortraitUpsideDown": @(UIInterfaceOrientationMaskPortraitUpsideDown),
        @"UIInterfaceOrientationLandscapeLeft": @(UIInterfaceOrientationMaskLandscapeLeft),
        @"UIInterfaceOrientationLandscapeRight": @(UIInterfaceOrientationMaskLandscapeRight),
    };
    UIInterfaceOrientationMask mask = 0;
    for (NSString *orientation in orientations) {
        mask |= masks[orientation].unsignedIntegerValue;
    }
    return mask ?: UIInterfaceOrientationMaskAllButUpsideDown;
}

@implementation AppDelegate

//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//#pragma clang diagnostic push
//#pragma clang diagnostic ignored "-Wdeprecated-declarations"
//    [UIApplication sharedApplication].statusBarHidden = NO;
//#pragma clang diagnostic pop
//    // 设置主窗口,并设置根控制器
//    self.window = [[UIWindow alloc] init];
//    self.window.frame = [UIScreen mainScreen].bounds;
//    [self.window makeKeyAndVisible];
//    CYLMainRootViewController *rootViewController = [[CYLMainRootViewController alloc] init];
//    [self.window setRootViewController:rootViewController];
//    [self setUpNavigationBarAppearance];
////    CYLGetRootWindow().overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
////    [UIWindow appearance].overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
//    return YES;
//}

//- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
////    return YES;
//}

- (UISceneConfiguration *)application:(UIApplication *)application
configurationForConnectingSceneSession:(UISceneSession *)sceneSession
                               options:(UISceneConnectionOptions *)options {
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration"
                                          sessionRole:sceneSession.role];
}


CYL_METHOD_SIGNATURES_PUSH
- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window {
    //设置强制旋转屏幕
    if (self.cyl_isForceLandscape) {
        //只支持横屏
        return UIInterfaceOrientationMaskLandscape;
    }
    // Otherwise the orientations set in Xcode (Info.plist). 其他情况以 Xcode 中的设置（Info.plist）为准。
    return CYLInfoPlistSupportedInterfaceOrientations();
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
