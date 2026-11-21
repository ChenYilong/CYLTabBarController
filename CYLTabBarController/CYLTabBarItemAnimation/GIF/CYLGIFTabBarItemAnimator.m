//
//  CYLGIFTabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// CYL-SWIFT-MIGRATION: objc-required — [EN] The composition root of the GIF subspec: its `+load` registers the animator before any tab is built, and Swift has no `+load`. The view is Swift (CYLGIFTabBarItemAnimationView.swift). [CN] GIF 子库的组合根：其 `+load` 在创建任何 Tab 之前注册 animator，而 Swift 没有 `+load`。视图为 Swift（CYLGIFTabBarItemAnimationView.swift）。

#import "CYLGIFTabBarItemAnimator.h"
// [EN] The registry and the view protocols of the `CYLTabBarItemAnimation` subspec. [CN] `CYLTabBarItemAnimation` 子库的注册表与视图协议。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#import "../CYLTabBarItemAnimationPlayableView.h"
#import "../CYLTabBarItemAnimationFactory.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#import "CYLTabBarItemAnimationPlayableView.h"
#import "CYLTabBarItemAnimationFactory.h"
#endif
// [EN] `CYLTabBarAnimationURL` and the other generic keys, from CYLUtils: no Core, so the subspec works without the tab bar.
// [CN] `CYLTabBarAnimationURL` 等通用 key，来自 CYLUtils：不依赖 Core，因此本子库无需 TabBar 也能使用。
#if __has_include("../../CYLUtils/CYLAnimationKeys.h")
#import "../../CYLUtils/CYLAnimationKeys.h"
#else
#import "CYLAnimationKeys.h"
#endif

#if CYL_GIF_AVAILABLE
// [EN] The Swift view of this subspec, through the module's generated header (framework or static library). Swift Package
//      Manager compiles the view into the CYLAnimatedItemViews target, whose generated header this C target does not get, so
//      there the class is found by its Objective-C name.
// [CN] 本子库的 Swift 视图，通过模块生成的头文件引入（framework 或静态库）。Swift Package Manager 把视图编译进 CYLAnimatedItemViews target，
//      本 C target 拿不到其生成的头文件，因此在那里按 Objective-C 类名查找。
#if __has_include(<CYLAnimatedItem/CYLAnimatedItem-Swift.h>)
#import <CYLAnimatedItem/CYLAnimatedItem-Swift.h>
#define CYL_GIF_SWIFT_VIEW_AVAILABLE 1
#elif __has_include("CYLAnimatedItem-Swift.h")
#import "CYLAnimatedItem-Swift.h"
#define CYL_GIF_SWIFT_VIEW_AVAILABLE 1
#endif

/*!
 * [EN] The view class of the GIF animator: the only place that names it.
 * [CN] GIF animator 的视图类：唯一指定它的地方。
 */
static Class<CYLTabBarItemAnimationViewProviding> CYLGIFTabBarItemAnimationViewProvider(void) {
#if defined(CYL_GIF_SWIFT_VIEW_AVAILABLE)
    return [CYLGIFTabBarItemAnimationView class];
#else
    return NSClassFromString(@"CYLGIFTabBarItemAnimationView");
#endif
}

@implementation CYLGIFTabBarItemAnimator

+ (CYLTabBarItemViewAnimator *)animator {
    static CYLTabBarItemViewAnimator *animator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        animator = [[CYLTabBarItemViewAnimator alloc] initWithIdentifier:@"GIF"
                                                          fileExtensions:@[ @"gif" ]
                                                           attributeKeys:@{
            CYLTabBarAnimationURL : CYLTabBarGIFURL,
            CYLTabBarAnimationFilePath : CYLTabBarGIFFilePath,
            CYLTabBarAnimationSize : CYLTabBarGIFSize,
            CYLTabBarAnimationDarkURL : CYLTabBarGIFDarkURL,
            CYLTabBarAnimationDarkFilePath : CYLTabBarGIFDarkFilePath,
        }
                                                            viewProvider:CYLGIFTabBarItemAnimationViewProvider()];
    });
    return animator;
}

/// [EN] Registers the GIF animator, the composition root of this subspec. [CN] 注册 GIF 的 animator，这是本子库的组合根。
+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:self.animator];
}

@end

#endif
