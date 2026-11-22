//
//  CYLLottieTabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// CYL-SWIFT-MIGRATION: objc-required — [EN] The composition root of the Lottie subspecs: its `+load` registers the animator before any tab is built, and Swift has no `+load`. The players are Swift (Lottie/ObjectiveC/CYLLottieObjectiveCTabBarItemAnimationPlayer.swift, LottieSwift/CYLLottieSwiftTabBarItemAnimationPlayer.swift). [CN] Lottie 子库的组合根：其 `+load` 在创建任何 Tab 之前注册 animator，而 Swift 没有 `+load`。播放器为 Swift。

#import "CYLLottieTabBarItemAnimator.h"
// The protocol and the registry of the `CYLTabBarItemAnimation` subspec (the source tree, or flattened by CocoaPods).
// `CYLTabBarItemAnimation` 子库的协议与注册表（源码目录，或 CocoaPods 展平后）。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#endif
// [EN] The keys (`CYLTabBarLottie…`, `CYLTabBarAnimation…`), from CYLUtils: no Core. [CN] key（`CYLTabBarLottie…`、`CYLTabBarAnimation…`），来自 CYLUtils：不依赖 Core。
#if __has_include("../../CYLUtils/CYLAnimationKeys.h")
#import "../../CYLUtils/CYLAnimationKeys.h"
#else
#import "CYLAnimationKeys.h"
#endif
// Shared through CYLUtils (the source tree, or flattened by CocoaPods). 通过 CYLUtils 共用（源码目录，或 CocoaPods 展平后）。
#if __has_include(<CYLAnimatedItem/CYLAnimatedItemMacros.h>)
#import <CYLAnimatedItem/CYLAnimatedItemMacros.h>
#elif __has_include("../../CYLAnimatedItem/CYLAnimatedItemMacros.h")
#import "../../CYLAnimatedItem/CYLAnimatedItemMacros.h"
#else
#import "CYLAnimatedItemMacros.h"
#endif

// FIX: issue #604 — only with a Lottie library; without one this file is empty and the class is never used.
// 仅在引入 Lottie 库时编译；未引入时本文件为空，也不会使用该类。
#if CYL_LOTTIE_AVAILABLE

// [EN] FIX: issue #605 — first: the generated header below also declares the Swift views of the Rive subspec when both are in the
//      build (e.g. Rive with FlatDesign, which brings Lottie), and those views adopt this header's protocols.
// [CN] FIX: issue #605 — 需先引入：两者同时在构建中时（例如 Rive 与会引入 Lottie 的扁平样式），下面生成的头文件也声明了 Rive 子库的 Swift 视图，这些视图遵守本头文件的协议。
#if __has_include("../CYLTabBarItemAnimationPlayableView.h")
#import "../CYLTabBarItemAnimationPlayableView.h"
#import "../CYLTabBarItemAnimationFactory.h"
#else
#import "CYLTabBarItemAnimationPlayableView.h"
#import "CYLTabBarItemAnimationFactory.h"
#endif
#if __has_include(<CYLAnimatedItem/CYLAnimatedItem-Swift.h>)
#import <CYLAnimatedItem/CYLAnimatedItem-Swift.h>
#elif __has_include("CYLAnimatedItem-Swift.h")
#import "CYLAnimatedItem-Swift.h"
#elif __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#endif

#if defined(SWIFT_PACKAGE)
// [EN] Swift Package Manager: the Swift modules this file uses through their Objective-C interface. [CN] Swift Package Manager：本文件通过其 Objective-C 接口使用的 Swift 模块。
#pragma clang module import CYLAnimatedItemSwift
#pragma clang module import CYLTabBarControllerLottieSwift
#endif

#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#endif

#if __has_include(<Lottie/Lottie-Swift.h>)
#import <Lottie/Lottie-Swift.h>
#endif

// [EN] The players are Swift (docs/Swift-Migration.md, engine step 5): CYLLottieObjectiveCTabBarItemAnimationPlayer
//      (Lottie/ObjectiveC/, lottie-ios 2.x) and CYLLottieSwiftTabBarItemAnimationPlayer (LottieSwift/, lottie-ios 4.x), each
//      compiled with its Lottie library and exported by the generated header imported above. This class stays Objective-C as
//      the composition root: its +load registers the animator, which Swift cannot do.
// [CN] 播放器为 Swift（docs/Swift-Migration.md 引擎第 5 步）：CYLLottieObjectiveCTabBarItemAnimationPlayer（Lottie/ObjectiveC/，lottie-ios 2.x）
//      与 CYLLottieSwiftTabBarItemAnimationPlayer（LottieSwift/，lottie-ios 4.x），各自随其 Lottie 库编译，由上面引入的生成头文件导出。本类作为组合根
//      保留为 Objective-C：其 +load 注册 animator，这是 Swift 做不到的。

#pragma mark - The animator (the factory of the Swift players)

@implementation CYLLottieTabBarItemAnimator

/// [EN] Registers itself when it is linked (only with Lottie). [CN] 被链接时自行注册（仅在引入 Lottie 时）。
+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:[[self alloc] init]];
}

- (NSString *)identifier {
    return @"Lottie";
}

/// [EN] Looked up last: Lottie takes every file no other animator takes, as before. [CN] 最后查找：其他 animator 都不处理的文件交给 Lottie，与原来一致。
- (CYLTabBarItemAnimatorPriority)priority {
    return CYLTabBarItemAnimatorPriorityFallback;
}

- (NSArray<NSString *> *)fileExtensions {
    return @[ @"json", @"lottie" ];
}

/// [EN] The Lottie keys, which stand for the generic `CYLTabBarAnimation…` keys. [CN] Lottie 的 key，对应通用的 `CYLTabBarAnimation…` key。
- (NSDictionary<NSString *, NSString *> *)attributeKeys {
    return @{
        CYLTabBarAnimationURL : CYLTabBarLottieURL,
        CYLTabBarAnimationFilePath : CYLTabBarLottieFilePath,
        CYLTabBarAnimationSize : CYLTabBarLottieSize,
        CYLTabBarAnimationDarkURL : CYLTabBarLottieDarkURL,
        CYLTabBarAnimationDarkFilePath : CYLTabBarLottieDarkFilePath,
        CYLTabBarAnimationDarkColors : CYLTabBarLottieDarkColors,
    };
}

/// [EN] Lottie 4 (LottieSwift) also plays `.lottie` archives; Lottie 2 does not. [CN] Lottie 4（LottieSwift）也能播放 `.lottie` 压缩包；Lottie 2 不能。
static BOOL CYLLottieAnimatorAcceptsDotLottie(void) {
#if __has_include(<Lottie/Lottie-Swift.h>)
    return YES;
#else
    return NO;
#endif
}

- (BOOL)canAnimateFileAtURL:(NSURL *)URL {
    // [EN] Every file another animator does not take (they are looked up first), but only a Lottie animation: a picture or
    //      a broken file is left to the static image (CYLTabBarItemAnimationURLMayBeLottie).
    // [CN] 其他 animator 不处理的文件（它们先被查找），但只接收 Lottie 动画：图片或损坏的文件交给静态图片（CYLTabBarItemAnimationURLMayBeLottie）。
    return CYLTabBarItemAnimationURLMayBeLottie(URL, CYLLottieAnimatorAcceptsDotLottie());
}

- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    // [EN] Also checked here: a tab's Lottie keys bind a URL to this animator without asking -canAnimateFileAtURL:. A file
    //      that does not load makes no view, so the caller keeps the static image instead of an empty Lottie view over it.
    // [CN] 这里也要检查：Tab 的 Lottie key 会把 URL 绑定到本 animator，而不调用 -canAnimateFileAtURL:。无法加载的文件不创建视图，调用方因此保留静态
    //      图片，而不是在其上方放一个空的 Lottie 视图。
    if (!CYLTabBarItemAnimationURLMayBeLottie(URL, CYLLottieAnimatorAcceptsDotLottie())) {
        return nil;
    }
    // The first Lottie library linked makes the view (each behind its own guard). 由先引入的 Lottie 库创建视图（各自使用独立的 guard）。
    UIView *lottieView = nil;
#if __has_include(<Lottie/Lottie.h>)
    lottieView = [CYLLottieObjectiveCTabBarItemAnimationPlayer viewWithURL:URL];
#endif
#if __has_include(<Lottie/Lottie-Swift.h>)
    lottieView = lottieView ?: [CYLLottieSwiftTabBarItemAnimationPlayer viewWithURL:URL];
#endif
    return lottieView;
}

- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
#if __has_include(<Lottie/Lottie.h>)
    if ([CYLLottieObjectiveCTabBarItemAnimationPlayer isLottieView:view]) {
        return [[CYLLottieObjectiveCTabBarItemAnimationPlayer alloc] initWithAnimationView:view];
    }
#endif
#if __has_include(<Lottie/Lottie-Swift.h>)
    if ([CYLLottieSwiftTabBarItemAnimationPlayer isLottieView:view]) {
        return [[CYLLottieSwiftTabBarItemAnimationPlayer alloc] initWithAnimationView:view];
    }
#endif
    return nil;
}

@end

#endif
