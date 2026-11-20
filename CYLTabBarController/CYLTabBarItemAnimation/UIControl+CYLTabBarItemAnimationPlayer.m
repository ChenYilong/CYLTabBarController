//
//  UIControl+CYLTabBarItemAnimationPlayer.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIControl+CYLTabBarItemAnimationPlayer.h"

#if CYL_ANIMATION_ENGINE_AVAILABLE
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationFactory.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationFactory.h>
#else
#import "CYLTabBarItemAnimationFactory.h"
#endif
// Core, which this subspec depends on (the source tree, or flattened by CocoaPods). 本子库依赖的 Core（源码目录，或 CocoaPods 展平后）。
#if __has_include("../UIControl+CYLTabBarItemAnimation.h")
#import "../UIControl+CYLTabBarItemAnimation.h"
#else
#import "UIControl+CYLTabBarItemAnimation.h"
#endif

#if defined(SWIFT_PACKAGE)
// [EN] Swift Package Manager: the Swift modules this file uses through their Objective-C interface. [CN] Swift Package Manager：本文件通过其 Objective-C 接口使用的 Swift 模块。
#pragma clang module import CYLTabBarController
#endif

@implementation UIControl (CYLTabBarItemAnimationPlayer)

- (id<CYLTabBarItemAnimationPlayer>)cyl_tabBarItemAnimationPlayer {
    return [CYLTabBarItemAnimationFactory playerForView:[self cyl_tabBarItemAnimationView]];
}

@end

#endif
