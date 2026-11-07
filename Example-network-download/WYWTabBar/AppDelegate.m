//
//  AppDelegate.m
//  WYWTabBar
//
//  Created by weiyanwu on 2026/4/17.
//

#import "AppDelegate.h"
#import "CYLTabBarController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // [EN] FIX: issue #601 — how long and how much the icons from the network stay cached (memory and sandbox), as
    //      SDWebImage's SDImageCacheConfig.
    // [CN] 网络图标在内存与沙盒中的缓存时长与大小，参考 SDWebImage 的 SDImageCacheConfig。
    CYLImageCache *imageCache = [CYLImageCache sharedImageCache];
    imageCache.maxDiskAge = 30 * 24 * 60 * 60;                 // 30 days
    imageCache.maxDiskSize = 20 * 1024 * 1024;                 // 20 MB
    imageCache.diskCacheExpireType = CYLImageCacheExpireTypeAccessDate;
    return YES;
}

@end
