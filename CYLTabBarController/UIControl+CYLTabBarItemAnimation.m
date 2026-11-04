//
//  UIControl+CYLTabBarItemAnimation.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] FIX: issue #604 — Core's side of the tab icon animation: it only forwards to the injected
//      `CYLTabBarItemAnimationService`, so Core knows no animation library (dependency inversion), and a new library needs
//      no change here.
// [CN] Core 一侧的 Tab 图标动画：只转发给注入的 `CYLTabBarItemAnimationService`，因此 Core 不认识任何动画库（依赖反转），
//      新增动画库时这里无需修改。

#import "UIControl+CYLTabBarItemAnimation.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"

#pragma mark - Service

static id<CYLTabBarItemAnimationService> CYLTabBarItemAnimationCurrentService = nil;

void CYLTabBarItemAnimationSetService(id<CYLTabBarItemAnimationService> service) {
    @synchronized ([UIControl class]) {
        CYLTabBarItemAnimationCurrentService = service;
    }
}

id<CYLTabBarItemAnimationService> CYLTabBarItemAnimationGetService(void) {
    @synchronized ([UIControl class]) {
        return CYLTabBarItemAnimationCurrentService;
    }
}

id CYLTabBarItemAttributesAnimationValue(NSDictionary *attributes, NSString *genericKey) {
    if (![attributes isKindOfClass:[NSDictionary class]] || genericKey.length == 0) {
        return nil;
    }
    id value = attributes[genericKey];
    if (value) {
        return value;
    }
    // [EN] The keys of the libraries in the build, e.g. `CYLTabBarLottieURL`, `CYLTabBarPAGURL`.
    // [CN] 构建中各动画库的 key，例如 `CYLTabBarLottieURL`、`CYLTabBarPAGURL`。
    for (NSString *key in [CYLTabBarItemAnimationGetService() attributeKeysForGenericKey:genericKey]) {
        value = attributes[key];
        if (value) {
            return value;
        }
    }
    return nil;
}

#pragma mark - Categories

@implementation UIControl (CYLTabBarItemAnimation)

- (UIView *)cyl_tabBarItemAnimationView {
    return [CYLTabBarItemAnimationGetService() animationViewInControl:self];
}

- (BOOL)cyl_isTabBarItemAnimationReady {
    return [CYLTabBarItemAnimationGetService() isAnimationReadyInControl:self];
}

- (void)cyl_addTabBarItemAnimationWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    [CYLTabBarItemAnimationGetService() addAnimationWithURL:URL size:size contentMode:contentMode animationSpeed:0 toControl:self];
}

- (void)cyl_addTabBarItemAnimationWithURL:(NSURL *)URL
                                     size:(CGSize)size
                              contentMode:(UIViewContentMode)contentMode
                           animationSpeed:(CGFloat)animationSpeed {
    [CYLTabBarItemAnimationGetService() addAnimationWithURL:URL size:size contentMode:contentMode animationSpeed:animationSpeed toControl:self];
}

- (void)cyl_setTabBarItemAnimationSpeed:(CGFloat)animationSpeed {
    [CYLTabBarItemAnimationGetService() setAnimationSpeed:animationSpeed inControl:self];
}

- (void)cyl_reloadTabBarItemAnimationViewForCurrentStyle {
    [CYLTabBarItemAnimationGetService() reloadAnimationForCurrentStyleInControl:self];
}

- (void)cyl_playTabBarItemAnimationWithURL:(NSURL *)URL
                                      size:(CGSize)size
                           defaultSelected:(BOOL)defaultSelected
                               contentMode:(UIViewContentMode)contentMode {
    [CYLTabBarItemAnimationGetService() playAnimationWithURL:URL size:size defaultSelected:defaultSelected contentMode:contentMode inControl:self];
}

- (void)cyl_stopTabBarItemAnimation {
    [CYLTabBarItemAnimationGetService() stopAnimationInControl:self];
}

@end

@implementation UIView (CYLTabBarItemAnimation)

- (BOOL)cyl_isTabBarItemAnimationView {
    return [CYLTabBarItemAnimationGetService() isAnimationView:self];
}

@end

@implementation CYLTabBar (CYLTabBarItemAnimation)

- (void)cyl_playTabBarItemAnimationWithSelectedControl:(UIControl *)selectedControl
                                                   URL:(NSURL *)URL
                                                  size:(CGSize)size
                                       defaultSelected:(BOOL)defaultSelected
                                           contentMode:(UIViewContentMode)contentMode {
    if (!URL) {
        return;
    }
    // [CN] 统一使用CYLTabBarItemLottieAnimationPlayingNotification进行动画重置， 故删除手动重置。
    // [EN] Animation reset is handled uniformly via CYLTabBarItemLottieAnimationPlayingNotification, so the manual reset
    //      was removed.
    [selectedControl cyl_playTabBarItemAnimationWithURL:URL size:size defaultSelected:defaultSelected contentMode:contentMode];
}

- (void)cyl_stopAllTabBarItemAnimations {
    [self.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cyl_stopTabBarItemAnimation];
    }];
    [self.cyl_platterSelectedContentViews enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj cyl_stopTabBarItemAnimation];
    }];
}

@end
