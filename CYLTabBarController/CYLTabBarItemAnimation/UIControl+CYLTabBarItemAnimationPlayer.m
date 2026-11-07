//
//  UIControl+CYLTabBarItemAnimationPlayer.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIControl+CYLTabBarItemAnimationPlayer.h"
#import "CYLTabBarItemAnimationFactory.h"
// Core, which this subspec depends on (the source tree, or flattened by CocoaPods). 本子库依赖的 Core（源码目录，或 CocoaPods 展平后）。
#if __has_include("../UIControl+CYLTabBarItemAnimation.h")
#import "../UIControl+CYLTabBarItemAnimation.h"
#else
#import "UIControl+CYLTabBarItemAnimation.h"
#endif

@implementation UIControl (CYLTabBarItemAnimationPlayer)

- (id<CYLTabBarItemAnimationPlayer>)cyl_tabBarItemAnimationPlayer {
    return [CYLTabBarItemAnimationFactory playerForView:self.cyl_tabBarItemAnimationView];
}

@end
