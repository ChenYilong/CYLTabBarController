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
                                                   viewProviderClassName:@"CYLRiveTabBarItemAnimationView"];
    });
    return animator;
}

#if __has_include(<RiveRuntime/RiveRuntime.h>)
/// [EN] Registers Rive's animator when linked with RiveRuntime. [CN] 链接了 RiveRuntime 时注册 Rive 的 animator。
+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:self.animator];
}
#endif

@end
