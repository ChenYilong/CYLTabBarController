//
//  CYLSVGATabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// CYL-SWIFT-MIGRATION: objc-required — [EN] The composition root of the SVGA subspec: its `+load` registers the animator before any tab is built, and Swift has no `+load`; its category declares the Swift view's protocol conformance, which Swift cannot (`SVGAPlayer` already has `-stopAnimation`, the protocol's Swift name of `-cyl_stopAnimationView`). The view is Swift (CYLSVGATabBarItemAnimationView.swift). [CN] SVGA 子库的组合根：其 `+load` 在创建任何 Tab 之前注册 animator，而 Swift 没有 `+load`；其分类声明 Swift 视图的协议遵守关系，Swift 做不到（`SVGAPlayer` 已有 `-stopAnimation`，即协议中 `-cyl_stopAnimationView` 的 Swift 名称）。视图为 Swift（CYLSVGATabBarItemAnimationView.swift）。

#import "CYLSVGATabBarItemAnimator.h"
// [EN] The registry and the playable view protocol of the `CYLTabBarItemAnimation` subspec.
// [CN] `CYLTabBarItemAnimation` 子库的注册表与可播放视图协议。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#import "../CYLTabBarItemAnimationPlayableView.h"
#import "../CYLTabBarItemAnimationFactory.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#import "CYLTabBarItemAnimationPlayableView.h"
#import "CYLTabBarItemAnimationFactory.h"
#endif

// [EN] FIX: issue #415 — only with SVGAPlayer (`CYL_SVGA_AVAILABLE`, the SVGA subspec); without it this file is empty.
// [CN] 仅在引入 SVGAPlayer 时编译（`CYL_SVGA_AVAILABLE`，SVGA 子库）；未引入时本文件为空。
#if CYL_SVGA_AVAILABLE
// [EN] SVGAPlayerLite (the SVGA subspec's maintained fork) first; the original SVGAPlayer pod works too.
// [CN] 优先使用 SVGAPlayerLite（SVGA 子库依赖的维护分支）；原版 SVGAPlayer pod 同样可用。
#if __has_include(<SVGAPlayerLite/SVGA.h>)
#import <SVGAPlayerLite/SVGA.h>
#elif __has_include(<SVGAPlayer/SVGA.h>)
#import <SVGAPlayer/SVGA.h>
#else
#import "SVGA.h"
#endif



// [EN] The Swift view of this subspec, through the module's generated header (framework or static library).
// [CN] 本子库的 Swift 视图，通过模块生成的头文件引入（framework 或静态库）。
#if __has_include(<CYLAnimatedItem/CYLAnimatedItem-Swift.h>)
#import <CYLAnimatedItem/CYLAnimatedItem-Swift.h>
#else
#import "CYLAnimatedItem-Swift.h"
#endif

/*!
 * [EN] The protocols of the Swift view, declared here: its methods already have the protocols' selectors
 *      (`-cyl_playAnimationView`…), but Swift cannot declare the conformance because `SVGAPlayer` has a `-stopAnimation`
 *      of its own, the Swift name of `-cyl_stopAnimationView`.
 * [CN] Swift 视图的协议在这里声明：其方法已具有协议的 selector（`-cyl_playAnimationView`……），但 Swift 无法声明遵守关系，因为 `SVGAPlayer`
 *      自己有 `-stopAnimation`，即 `-cyl_stopAnimationView` 的 Swift 名称。
 */
@interface CYLSVGATabBarItemAnimationView (CYLTabBarItemAnimationPlayableView) <CYLTabBarItemAnimationPlayableView, CYLTabBarItemAnimationViewProviding>
@end

@implementation CYLSVGATabBarItemAnimationView (CYLTabBarItemAnimationPlayableView)
@end

@implementation CYLSVGATabBarItemAnimator

+ (CYLTabBarItemViewAnimator *)animator {
    static CYLTabBarItemViewAnimator *animator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        animator = [[CYLTabBarItemViewAnimator alloc] initWithIdentifier:@"SVGA"
                                                          fileExtensions:@[ @"svga" ]
                                                           attributeKeys:@{
            CYLTabBarAnimationURL : CYLTabBarSVGAURL,
            CYLTabBarAnimationFilePath : CYLTabBarSVGAFilePath,
            CYLTabBarAnimationSize : CYLTabBarSVGASize,
            CYLTabBarAnimationDarkURL : CYLTabBarSVGADarkURL,
            CYLTabBarAnimationDarkFilePath : CYLTabBarSVGADarkFilePath,
        }
                                                            viewProvider:[CYLSVGATabBarItemAnimationView class]];
    });
    return animator;
}

/// [EN] Registers SVGA's animator (this file only compiles with SVGAPlayer). [CN] 注册 SVGA 的 animator（本文件只在有 SVGAPlayer 时编译）。
+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:self.animator];
}

@end

#endif
