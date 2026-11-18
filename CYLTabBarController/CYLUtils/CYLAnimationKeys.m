//
//  CYLAnimationKeys.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

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

/*
 * [EN] Each type with its own keys, by generic key. [CN] 每种类型及其自己的 key，按通用 key 排列。
 */
static NSArray<NSDictionary<NSString *, id> *> *CYLAnimationTypeTable(void) {
    static NSArray *table;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = @[
            @{ @"type" : @"Lottie", @"extensions" : @[ @"json", @"lottie" ], @"pod" : @"LottieSwift",
               @"keys" : @{ CYLTabBarAnimationURL : CYLTabBarLottieURL, CYLTabBarAnimationFilePath : CYLTabBarLottieFilePath,
                            CYLTabBarAnimationSize : CYLTabBarLottieSize, CYLTabBarAnimationDarkURL : CYLTabBarLottieDarkURL,
                            CYLTabBarAnimationDarkFilePath : CYLTabBarLottieDarkFilePath, CYLTabBarAnimationDarkColors : CYLTabBarLottieDarkColors } },
            @{ @"type" : @"PAG", @"extensions" : @[ @"pag" ], @"pod" : @"PAG",
               @"keys" : @{ CYLTabBarAnimationURL : CYLTabBarPAGURL, CYLTabBarAnimationFilePath : CYLTabBarPAGFilePath,
                            CYLTabBarAnimationSize : CYLTabBarPAGSize, CYLTabBarAnimationDarkURL : CYLTabBarPAGDarkURL,
                            CYLTabBarAnimationDarkFilePath : CYLTabBarPAGDarkFilePath } },
            @{ @"type" : @"Rive", @"extensions" : @[ @"riv" ], @"pod" : @"Rive",
               @"keys" : @{ CYLTabBarAnimationURL : CYLTabBarRiveURL, CYLTabBarAnimationFilePath : CYLTabBarRiveFilePath,
                            CYLTabBarAnimationSize : CYLTabBarRiveSize, CYLTabBarAnimationDarkURL : CYLTabBarRiveDarkURL,
                            CYLTabBarAnimationDarkFilePath : CYLTabBarRiveDarkFilePath, CYLTabBarAnimationDarkColors : CYLTabBarRiveDarkColors } },
            @{ @"type" : @"SVGA", @"extensions" : @[ @"svga" ], @"pod" : @"SVGA",
               @"keys" : @{ CYLTabBarAnimationURL : CYLTabBarSVGAURL, CYLTabBarAnimationFilePath : CYLTabBarSVGAFilePath,
                            CYLTabBarAnimationSize : CYLTabBarSVGASize, CYLTabBarAnimationDarkURL : CYLTabBarSVGADarkURL,
                            CYLTabBarAnimationDarkFilePath : CYLTabBarSVGADarkFilePath } },
            @{ @"type" : @"GIF", @"extensions" : @[ @"gif" ], @"pod" : @"GIF",
               @"keys" : @{ CYLTabBarAnimationURL : CYLTabBarGIFURL, CYLTabBarAnimationFilePath : CYLTabBarGIFFilePath,
                            CYLTabBarAnimationSize : CYLTabBarGIFSize, CYLTabBarAnimationDarkURL : CYLTabBarGIFDarkURL,
                            CYLTabBarAnimationDarkFilePath : CYLTabBarGIFDarkFilePath } },
        ];
    });
    return table;
}
#pragma clang diagnostic pop

id CYLAnimationAttributesValue(NSDictionary *attributes, NSString *genericKey) {
    if (![attributes isKindOfClass:[NSDictionary class]] || genericKey.length == 0) {
        return nil;
    }
    id value = attributes[genericKey];
    if (value) {
        return value;
    }
    for (NSDictionary *entry in CYLAnimationTypeTable()) {
        NSString *key = entry[@"keys"][genericKey];
        if (key && attributes[key]) {
            return attributes[key];
        }
    }
    return nil;
}

NSString *CYLAnimationTypeOfFile(NSDictionary *attributes, NSURL *fileURL) {
    NSString *extension = fileURL.path.pathExtension.lowercaseString;
    for (NSDictionary *entry in CYLAnimationTypeTable()) {
        if ([attributes isKindOfClass:[NSDictionary class]]) {
            for (NSString *key in [entry[@"keys"] allValues]) {
                if (attributes[key]) {
                    return entry[@"type"];
                }
            }
        }
    }
    for (NSDictionary *entry in CYLAnimationTypeTable()) {
        if (extension.length > 0 && [entry[@"extensions"] containsObject:extension]) {
            return entry[@"type"];
        }
    }
    return nil;
}

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

NSArray<NSString *> *CYLAnimationKnownTypes(void) {
    return [CYLAnimationTypeTable() valueForKey:@"type"];
}

/// [EN] The table entry of `type`, or nil. [CN] `type` 在表中的条目；没有时为 nil。
static NSDictionary<NSString *, id> *CYLAnimationTypeEntry(NSString *type) {
    if (type.length == 0) {
        return nil;
    }
    for (NSDictionary<NSString *, id> *entry in CYLAnimationTypeTable()) {
        if ([entry[@"type"] isEqualToString:type]) {
            return entry;
        }
    }
    return nil;
}

NSString *CYLAnimationSubspecOfType(NSString *type) {
    return CYLAnimationTypeEntry(type)[@"pod"];
}

NSArray<NSString *> *CYLAnimationFileExtensionsOfType(NSString *type) {
    return CYLAnimationTypeEntry(type)[@"extensions"] ?: @[];
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
