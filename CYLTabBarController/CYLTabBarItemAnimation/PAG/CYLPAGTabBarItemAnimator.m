//
//  CYLPAGTabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// CYL-SWIFT-MIGRATION: objc-required — [EN] The composition root of the PAG subspecs: its `+load` registers the animator before any tab is built, and Swift has no `+load`. The player and the view loading are Swift (CYLPAGTabBarItemAnimation.swift). [CN] PAG 子库的组合根：其 `+load` 在创建任何 Tab 之前注册 animator，而 Swift 没有 `+load`。播放器与视图加载为 Swift（CYLPAGTabBarItemAnimation.swift）。

#import "CYLPAGTabBarItemAnimator.h"
// [EN] The generic keys, from CYLUtils: no Core. [CN] 通用 key，来自 CYLUtils：不依赖 Core。
#if __has_include("../../CYLUtils/CYLAnimationKeys.h")
#import "../../CYLUtils/CYLAnimationKeys.h"
#else
#import "CYLAnimationKeys.h"
#endif

// FIX: issue #604 — only with libpag (`CYL_PAG_AVAILABLE`, the PAG subspec); without it this file is empty: no keys,
// no class.
// [CN] 仅在引入 libpag 时编译（`CYL_PAG_AVAILABLE`，PAG 子库）；未引入时本文件为空：没有 key，也没有类。
#if CYL_PAG_AVAILABLE
#import <libpag/PAGView.h>

// [EN] The PAG keys are declared and defined in the component's core (CYLAnimationKeys), so they exist without libpag.
// [CN] PAG 的 key 在组件核心（CYLAnimationKeys）中声明与定义，没有 libpag 时也存在。

// The protocol and the registry of the `CYLTabBarItemAnimation` subspec (the source tree, or flattened by CocoaPods).
// `CYLTabBarItemAnimation` 子库的协议与注册表（源码目录，或 CocoaPods 展平后）。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#import "../CYLTabBarItemAnimationFactory.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#import "CYLTabBarItemAnimationFactory.h"
#endif

/// [EN] Plays a `PAGView`. [CN] 播放 `PAGView`。
// [EN] The Swift player and view loading of this subspec, through the module's generated header (framework or static library).
// [CN] 本子库的 Swift 播放器与视图加载，通过模块生成的头文件引入（framework 或静态库）。
#if __has_include(<CYLAnimatedItem/CYLAnimatedItem-Swift.h>)
#import <CYLAnimatedItem/CYLAnimatedItem-Swift.h>
#else
#import "CYLAnimatedItem-Swift.h"
#endif

@implementation CYLPAGTabBarItemAnimator

+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:[[self alloc] init]];
}

- (NSString *)identifier {
    return @"PAG";
}

- (NSArray<NSString *> *)fileExtensions {
    return @[ @"pag" ];
}

- (NSDictionary<NSString *, NSString *> *)attributeKeys {
    return @{
        CYLTabBarAnimationURL : CYLTabBarPAGURL,
        CYLTabBarAnimationFilePath : CYLTabBarPAGFilePath,
        CYLTabBarAnimationSize : CYLTabBarPAGSize,
        CYLTabBarAnimationDarkURL : CYLTabBarPAGDarkURL,
        CYLTabBarAnimationDarkFilePath : CYLTabBarPAGDarkFilePath,
    };
}

- (BOOL)canAnimateFileAtURL:(NSURL *)URL {
    return [URL.pathExtension.lowercaseString isEqualToString:@"pag"];
}

- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    return [CYLPAGTabBarItemAnimationViews animationViewWithURL:URL size:size contentMode:contentMode];
}

- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
    return [CYLPAGTabBarItemAnimationViews playerForAnimationView:view];
}

@end

#endif
