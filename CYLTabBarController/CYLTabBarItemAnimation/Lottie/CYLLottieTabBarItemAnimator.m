//
//  CYLLottieTabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLLottieTabBarItemAnimator.h"
// The protocol and the registry of the `CYLTabBarItemAnimation` subspec (the source tree, or flattened by CocoaPods).
// `CYLTabBarItemAnimation` 子库的协议与注册表（源码目录，或 CocoaPods 展平后）。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#endif
// Core's keys (`CYLTabBarLottie…`, `CYLTabBarAnimation…`). Core 的 key。
#if __has_include("../../CYLTabBarController.h")
#import "../../CYLTabBarController.h"
#else
#import "CYLTabBarController.h"
#endif
// Shared through CYLUtils (the source tree, or flattened by CocoaPods). 通过 CYLUtils 共用（源码目录，或 CocoaPods 展平后）。
#if __has_include("../../CYLUtils/CYLUtils.h")
#import "../../CYLUtils/CYLUtils.h"
#else
#import "CYLUtils.h"
#endif

// FIX: issue #604 — only with a Lottie library; without one this file is empty and the class is never used.
// 仅在引入 Lottie 库时编译；未引入时本文件为空，也不会使用该类。
#if CYL_LOTTIE_AVAILABLE

#if __has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
#import <CYLTabBarController/CYLTabBarController-Swift.h>
#endif

#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#endif

#if __has_include(<Lottie/Lottie-Swift.h>)
#import <Lottie/Lottie-Swift.h>
#endif

#pragma mark - Lottie 2.x (Objective-C)

#if __has_include(<Lottie/Lottie.h>)
/// [EN] Plays a `LOTAnimationView` (lottie-ios 2.x). [CN] 播放 `LOTAnimationView`（lottie-ios 2.x）。
@interface CYLLottieObjectiveCTabBarItemAnimationPlayer : CYLTabBarItemAnimationBasePlayer <CYLTabBarItemAnimationPlayer>
@end

@implementation CYLLottieObjectiveCTabBarItemAnimationPlayer

+ (BOOL)isLottieView:(UIView *)view {
    // [EN] Inside the `__has_include` guard Lottie is linked (this file already uses the class), so no string lookup.
    // [CN] 在 `__has_include` 守卫内 Lottie 已链接（本文件已直接使用该类），因此无需按字符串查找。
    return [view isKindOfClass:[LOTAnimationView class]];
}

+ (UIView *)viewWithURL:(NSURL *)URL {
    if (![LOTAnimationView instancesRespondToSelector:@selector(initWithContentsOfURL:)]) {
        return nil;
    }
    return [[LOTAnimationView alloc] initWithContentsOfURL:URL];
}

- (LOTAnimationView *)lottieView {
    return (LOTAnimationView *)self.animationView;
}

- (void)play {
    LOTAnimationView *lottieView = self.lottieView;
    dispatch_async(dispatch_get_main_queue(), ^{
        lottieView.animationProgress = 0;
        [lottieView play];
    });
}

- (void)showLastFrame {
    LOTAnimationView *lottieView = self.lottieView;
    dispatch_async(dispatch_get_main_queue(), ^{
        // [CN] 希望Lottie icon 启动后 index== 0 不执行动画 #389
        // [EN] Avoid triggering Lottie animation when index == 0 on app startup. #389
        lottieView.animationProgress = 1;
        [lottieView forceDrawingUpdate];
    });
}

- (void)stop {
    // [CN] 通过 (animationProgress > 0) 判断，降低扁平风格 CYLFlatDesignTabBar 第一次初始化时展示失败的几率。
    // [EN] The (animationProgress > 0) check lowers the chance that the flat design CYLFlatDesignTabBar fails to show on its
    //      first initialization.
    LOTAnimationView *lottieView = self.lottieView;
    if (lottieView.animationProgress > 0) {
        [lottieView stop];
    }
}

- (CGFloat)progress {
    return self.lottieView.animationProgress;
}

- (void)setProgress:(CGFloat)progress {
    LOTAnimationView *lottieView = self.lottieView;
    lottieView.animationProgress = progress;
    [lottieView forceDrawingUpdate];
}

- (CGFloat)animationSpeed {
    return self.lottieView.animationSpeed;
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed {
    self.lottieView.animationSpeed = animationSpeed;
}

@end
#endif

#pragma mark - Lottie 4.x (Swift)

#if __has_include(<Lottie/Lottie-Swift.h>)
/// [EN] Plays a `CYLCompatibleLOTAnimationView` (lottie-ios 4.x, through the Swift bridge). [CN] 播放 `CYLCompatibleLOTAnimationView`（lottie-ios 4.x，经 Swift 桥接）。
@interface CYLLottieSwiftTabBarItemAnimationPlayer : CYLTabBarItemAnimationBasePlayer <CYLTabBarItemAnimationPlayer>
@end

@implementation CYLLottieSwiftTabBarItemAnimationPlayer {
    /// [EN] Whether the dark colors are applied now (#442). [CN] 当前是否已应用深色颜色（#442）。
    BOOL _darkColorsApplied;
    /// FIX: issue #216 — the keypaths `-applyColors:` set last. [CN] `-applyColors:` 上次设置的 keypath。
    NSSet<NSString *> *_appliedColorKeypaths;
}

+ (BOOL)isLottieView:(UIView *)view {
    // Avoid sending messages to a forward-declared class; resolve at runtime instead.
    // 避免向前向声明的类发送消息，改为在运行时判断。
    return [NSStringFromClass([view class]) containsString:@"CYLCompatibleLOTAnimationView"];
}

+ (UIView *)viewWithURL:(NSURL *)URL {
    if (![CYLCompatibleLOTAnimationView instancesRespondToSelector:@selector(initWithCompatibleAnimation:)]) {
        return nil;
    }
    CYLCompatibleLOTAnimation *composition = [[CYLCompatibleLOTAnimation alloc] initWithFilepath:URL.path];
    return [[CYLCompatibleLOTAnimationView alloc] initWithCompatibleAnimation:composition];
}

- (CYLCompatibleLOTAnimationView *)lottieView {
    return (CYLCompatibleLOTAnimationView *)self.animationView;
}

// [CN] 不能放到 dispatch_get_main_queue 中，否则暂停与播放可能错乱。
// [EN] Not on dispatch_get_main_queue: pause and play may get out of order otherwise.

- (void)play {
    CYLCompatibleLOTAnimationView *lottieView = self.lottieView;
    lottieView.animationProgress = 0;
    [lottieView play];
}

- (void)showLastFrame {
    // [CN] 希望Lottie icon 启动后 index== 0 不执行动画 #389
    // [EN] Avoid triggering Lottie animation when index == 0 on app startup. #389
    CYLCompatibleLOTAnimationView *lottieView = self.lottieView;
    lottieView.animationProgress = 1;
    [lottieView forceDrawingUpdate];
}

- (void)stop {
    CYLCompatibleLOTAnimationView *lottieView = self.lottieView;
    if (lottieView.animationProgress > 0) {
        [lottieView stop];
    }
}

- (CGFloat)progress {
    CYLCompatibleLOTAnimationView *lottieView = self.lottieView;
    return [lottieView respondsToSelector:@selector(animationProgress)] ? lottieView.animationProgress : 0;
}

- (void)setProgress:(CGFloat)progress {
    CYLCompatibleLOTAnimationView *lottieView = self.lottieView;
    if ([lottieView respondsToSelector:@selector(setAnimationProgress:)]) {
        lottieView.animationProgress = progress;
    }
    if ([lottieView respondsToSelector:@selector(forceDrawingUpdate)]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS([lottieView performSelector:@selector(forceDrawingUpdate)]);
    }
}

- (CGFloat)animationSpeed {
    CYLCompatibleLOTAnimationView *lottieView = self.lottieView;
    return [lottieView respondsToSelector:@selector(animationSpeed)] ? lottieView.animationSpeed : 1;
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed {
    CYLCompatibleLOTAnimationView *lottieView = self.lottieView;
    if ([lottieView respondsToSelector:@selector(setAnimationSpeed:)]) {
        lottieView.animationSpeed = animationSpeed;
    }
}

/*!
 * FIX: issue #442 — Lottie 4.x only.
 * [EN] Sets `darkColors` with Lottie's value providers where `traitCollection` is dark, and removes them otherwise, so one
 *      file follows Dark Mode. Does nothing when they are already in that state.
 * [CN] `traitCollection` 为深色时，用 Lottie 的 value provider 设置 `darkColors`，否则移除，使一份文件即可适配深色模式。状态未变化时不做处理。
 */
- (void)applyDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors traitCollection:(UITraitCollection *)traitCollection {
    UIView *view = self.animationView;
    // Methods added to `CYLCompatibleLOTAnimationView` for #442: call them only when the view responds to them.
    // #442 为 `CYLCompatibleLOTAnimationView` 新增的方法：仅在视图能响应时调用。
    SEL setColorSelector = @selector(setColorValue:forKeypathString:);
    SEL removeColorSelector = @selector(removeValueProviderForKeypathString:);
    if (!view || darkColors.count == 0 || ![view respondsToSelector:setColorSelector] || ![view respondsToSelector:removeColorSelector]) {
        return;
    }
    BOOL dark = NO;
    if (@available(iOS 13.0, *)) {
        dark = (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    }
    if (_darkColorsApplied == dark) {
        return;
    }
    [darkColors enumerateKeysAndObjectsUsingBlock:^(NSString *keypath, UIColor *color, BOOL *stop) {
        (void)stop;
        if (![keypath isKindOfClass:[NSString class]] || ![color isKindOfClass:[UIColor class]]) {
            return;
        }
        if (dark) {
            UIColor *resolvedColor = color;
            if (@available(iOS 13.0, *)) {
                resolvedColor = [color resolvedColorWithTraitCollection:traitCollection];
            }
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS([view performSelector:setColorSelector withObject:resolvedColor withObject:keypath]);
        } else {
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS([view performSelector:removeColorSelector withObject:keypath]);
        }
    }];
    _darkColorsApplied = dark;
    if ([view respondsToSelector:@selector(forceDrawingUpdate)]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS([view performSelector:@selector(forceDrawingUpdate)]);
    }
}

/*!
 * FIX: issue #216 — Lottie 4.x only.
 * [EN] Sets `colors` (already resolved) with Lottie's value providers and removes the providers of the keypaths set by a
 *      previous call that are no longer in it; nil removes them all.
 * [CN] 用 Lottie 的 value provider 设置 `colors`（已解析），并移除上一次调用设置、这次不再包含的 keypath 的 provider；nil 移除全部。
 */
- (void)applyColors:(nullable NSDictionary<NSString *, UIColor *> *)colors traitCollection:(UITraitCollection *)traitCollection {
    UIView *view = self.animationView;
    SEL setColorSelector = @selector(setColorValue:forKeypathString:);
    SEL removeColorSelector = @selector(removeValueProviderForKeypathString:);
    if (!view || ![view respondsToSelector:setColorSelector] || ![view respondsToSelector:removeColorSelector]) {
        return;
    }
    for (NSString *keypath in _appliedColorKeypaths) {
        if (!colors[keypath]) {
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS([view performSelector:removeColorSelector withObject:keypath]);
        }
    }
    NSMutableSet<NSString *> *appliedKeypaths = [NSMutableSet set];
    [colors enumerateKeysAndObjectsUsingBlock:^(NSString *keypath, UIColor *color, BOOL *stop) {
        (void)stop;
        if (![keypath isKindOfClass:[NSString class]] || ![color isKindOfClass:[UIColor class]]) {
            return;
        }
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS([view performSelector:setColorSelector withObject:color withObject:keypath]);
        [appliedKeypaths addObject:keypath];
    }];
    _appliedColorKeypaths = appliedKeypaths;
    // [EN] `-applyColors:` carries the dark colors itself. [CN] `-applyColors:` 自己带有深色颜色。
    _darkColorsApplied = NO;
    if ([view respondsToSelector:@selector(forceDrawingUpdate)]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS([view performSelector:@selector(forceDrawingUpdate)]);
    }
}

@end
#endif

#pragma mark - The animator (the factory of the players above)

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

- (BOOL)canAnimateFileAtURL:(NSURL *)URL {
    // Every file another animator does not take (they are looked up first). 其他 animator 不处理的文件（它们先被查找）。
    return URL != nil;
}

- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
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
