//
//  CYLRiveTabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLRiveTabBarItemAnimator.h"
// [EN] The registry of the `CYLTabBarItemAnimation` subspec. [CN] `CYLTabBarItemAnimation` 子库的注册表。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#endif
// [EN] Only with RiveRuntime (`CYL_RIVE_AVAILABLE`, the Rive subspec); without it this file is empty: no keys, no class.
//      A Swift package (Package.swift: no RiveRuntime, no RiveSwift/) compiles it that way.
// [CN] 仅在引入 RiveRuntime 时编译（`CYL_RIVE_AVAILABLE`，Rive 子库）；未引入时本文件为空：没有 key，也没有类。
//      Swift Package（Package.swift：没有 RiveRuntime 与 RiveSwift/）即按此编译。
#if CYL_RIVE_AVAILABLE
// [EN] The Swift views of this subspec (RiveSwift/), through the module's generated header (framework or static library).
// [CN] 本子库的 Swift 视图（RiveSwift/），通过模块生成的头文件引入（framework 或静态库）。
#if __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#define CYL_RIVE_SWIFT_VIEWS_AVAILABLE 1
#elif __has_include("CYLTabBarController-Swift.h")
#import "CYLTabBarController-Swift.h"
#define CYL_RIVE_SWIFT_VIEWS_AVAILABLE 1
#endif

NSString *const CYLTabBarRiveURL = @"CYLTabBarRiveURL";
NSString *const CYLTabBarRiveFilePath = @"CYLTabBarRiveFilePath";
NSString *const CYLTabBarRiveSize = @"CYLTabBarRiveSize";
NSString *const CYLTabBarRiveDarkURL = @"CYLTabBarRiveDarkURL";
NSString *const CYLTabBarRiveDarkFilePath = @"CYLTabBarRiveDarkFilePath";
NSString *const CYLTabBarRiveDarkColors = @"CYLTabBarRiveDarkColors";

CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveArtboard = @"artboard";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveStateMachine = @"stateMachine";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveActiveProperty = @"active";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveActiveDuration = @"duration";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveTriggerProperty = @"trigger";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveColor = @"color";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveInput = @"input";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveTriggerInput = @"triggerInput";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveAnimation = @"animation";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveLegacyRuntime = @"legacy";

@implementation CYLRiveTabBarItemAnimator

/*!
 * [EN] The composition root of the Rive subspec: the only place that names its view classes, checked by the compiler.
 * [CN] Rive 子库的组合根：唯一指定其视图类的地方，由编译器检查。
 */
static Class<CYLTabBarItemAnimationViewProviding> CYLRiveTabBarItemAnimationViewProvider(void) {
#if defined(CYL_RIVE_SWIFT_VIEWS_AVAILABLE)
    // [EN] The legacy renderer is deprecated together with the legacy Rive API it wraps; this is its one intended use.
    // [CN] 旧版渲染器与其封装的旧版 Rive API 一起标记为废弃；这里是它唯一的预期用法。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CYLRiveTabBarItemAnimationView.legacyViewProvider = [CYLRiveLegacyTabBarItemAnimationView class];
#pragma clang diagnostic pop
    return [CYLRiveTabBarItemAnimationView class];
#else
    // [EN] Without the Swift views (e.g. a build without RiveSwift/), Rive tabs show their images.
    // [CN] 没有 Swift 视图时（例如构建中不含 RiveSwift/），Rive Tab 显示图片。
    return nil;
#endif
}

+ (CYLTabBarItemViewAnimator *)animator {
    static CYLTabBarItemViewAnimator *animator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        animator = [[CYLTabBarItemViewAnimator alloc] initWithIdentifier:@"Rive"
                                                          fileExtensions:@[ @"riv" ]
                                                           attributeKeys:@{
            CYLTabBarAnimationURL : CYLTabBarRiveURL,
            CYLTabBarAnimationFilePath : CYLTabBarRiveFilePath,
            CYLTabBarAnimationSize : CYLTabBarRiveSize,
            CYLTabBarAnimationDarkURL : CYLTabBarRiveDarkURL,
            CYLTabBarAnimationDarkFilePath : CYLTabBarRiveDarkFilePath,
            CYLTabBarAnimationDarkColors : CYLTabBarRiveDarkColors,
        }
                                                            viewProvider:CYLRiveTabBarItemAnimationViewProvider()];
    });
    return animator;
}

/// [EN] Registers Rive's animator (this file only compiles with RiveRuntime). [CN] 注册 Rive 的 animator（本文件只在有 RiveRuntime 时编译）。
+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:self.animator];
}

@end

#endif
