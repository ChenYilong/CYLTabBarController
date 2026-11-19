//
//  CYLAnimationKeys.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// CYL-SWIFT-MIGRATION: objc-required — [EN] What is left needs Objective-C: the key constants carry per-engine compile warnings
//      (`CYL_PAG_REQUIRED` …, an AGENTS.md rule; Swift cannot attach a warning that depends on which engine pod is in the build),
//      and `CYLAnimationTypeIsAvailable()` / `CYLAnimationWarnMissingEngine()` read the `__has_include` engine switches of
//      CYLAnimatedItemMacros.h. The lookup is Swift (CYLUtils/Swift/CYLAnimationKeyLookup.swift, step 122).
// [CN] 剩余部分需要 Objective-C：key 常量带有各引擎的编译警告（AGENTS.md 规则；Swift 无法附加取决于引擎子库是否存在的警告），
//      `CYLAnimationTypeIsAvailable()` / `CYLAnimationWarnMissingEngine()` 读取 CYLAnimatedItemMacros.h 的 `__has_include` 引擎开关。查找逻辑为 Swift。
#import "CYLAnimationKeys.h"

// [EN] Moved from CYLTabBarController.m (same names and values). [CN] 从 CYLTabBarController.m 移来（名称与值不变）。
NSString *const CYLTabBarLottieFilePath = @"CYLTabBarLottieFilePath";
NSString *const CYLTabBarLottieURL = @"CYLTabBarLottieURL";
NSString *const CYLTabBarLottieSize = @"CYLTabBarLottieSize";
NSString *const CYLTabBarLottieLoopsWhenUnselected = @"CYLTabBarLottieLoopsWhenUnselected";
NSString *const CYLTabBarLottieDarkURL = @"CYLTabBarLottieDarkURL";
NSString *const CYLTabBarLottieDarkFilePath = @"CYLTabBarLottieDarkFilePath";
NSString *const CYLTabBarLottieDarkColors = @"CYLTabBarLottieDarkColors";

// [EN] The keys of each animation type, defined here so that they exist without the type's engine (same names and values).
// [CN] 各动画类型的 key，在此定义，没有该类型的引擎时也存在（名称与值不变）。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
NSString *const CYLTabBarPAGURL = @"CYLTabBarPAGURL";
NSString *const CYLTabBarPAGFilePath = @"CYLTabBarPAGFilePath";
NSString *const CYLTabBarPAGSize = @"CYLTabBarPAGSize";
NSString *const CYLTabBarPAGDarkURL = @"CYLTabBarPAGDarkURL";
NSString *const CYLTabBarPAGDarkFilePath = @"CYLTabBarPAGDarkFilePath";
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
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveNumberInput = @"numberInput";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveNumberValues = @"values";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionTint = @"tint";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionDarkTint = @"darkTint";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveViewModelInstance = @"viewModelInstance";
CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveDarkViewModelInstance = @"darkViewModelInstance";
NSString *const CYLTabBarSVGAURL = @"CYLTabBarSVGAURL";
NSString *const CYLTabBarSVGAFilePath = @"CYLTabBarSVGAFilePath";
NSString *const CYLTabBarSVGASize = @"CYLTabBarSVGASize";
NSString *const CYLTabBarSVGADarkURL = @"CYLTabBarSVGADarkURL";
NSString *const CYLTabBarSVGADarkFilePath = @"CYLTabBarSVGADarkFilePath";
NSString *const CYLTabBarGIFURL = @"CYLTabBarGIFURL";
NSString *const CYLTabBarGIFFilePath = @"CYLTabBarGIFFilePath";
NSString *const CYLTabBarGIFSize = @"CYLTabBarGIFSize";
NSString *const CYLTabBarGIFDarkURL = @"CYLTabBarGIFDarkURL";
NSString *const CYLTabBarGIFDarkFilePath = @"CYLTabBarGIFDarkFilePath";

// [EN] The type table and the lookup functions are Swift since step 122 (CYLUtils/Swift/CYLAnimationKeyLookup.swift).
// [CN] 类型表与查找函数自第 122 步起为 Swift（CYLUtils/Swift/CYLAnimationKeyLookup.swift）。
#pragma clang diagnostic pop

BOOL CYLAnimationTypeIsAvailable(NSString *type) {
    // [EN] Evaluated where this pod is compiled, i.e. with the subspecs the project installed.
    // [CN] 在编译本 pod 的地方求值，即使用项目安装的子库。
#if CYL_ANIMATION_ENGINE_AVAILABLE
    NSDictionary<NSString *, NSNumber *> *available = @{
        @"Lottie" : @(CYL_LOTTIE_AVAILABLE), @"PAG" : @(CYL_PAG_AVAILABLE), @"Rive" : @(CYL_RIVE_AVAILABLE),
        @"SVGA" : @(CYL_SVGA_AVAILABLE), @"GIF" : @(CYL_GIF_AVAILABLE),
    };
    return type.length > 0 && [available[type] boolValue];
#else
    return NO;
#endif
}

void CYLAnimationWarnMissingEngine(NSDictionary *attributes, NSURL *fileURL) {
#if defined(DEBUG)
    NSString *type = CYLAnimationTypeOfFile(attributes, fileURL);
    if (!type || CYLAnimationTypeIsAvailable(type)) {
        return;
    }
    static NSMutableSet<NSString *> *warned;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        warned = [NSMutableSet set];
    });
    @synchronized (warned) {
        if ([warned containsObject:type]) {
            return;
        }
        [warned addObject:type];
    }
    NSString *pod = CYLAnimationSubspecOfType(type) ?: @"";
    NSLog(@"⚠️ [CYLAnimatedItem] %@ animation (%@) cannot play: the %@ engine is not in this build. Showing the static image, or the placeholder without one. Add pod 'CYLAnimatedItem/%@' (with CYLTabBarController: pod 'CYLTabBarController/%@'). This message is shown in debug builds only.",
          type, fileURL.lastPathComponent ?: @"?", type, pod, pod);
#endif
}
