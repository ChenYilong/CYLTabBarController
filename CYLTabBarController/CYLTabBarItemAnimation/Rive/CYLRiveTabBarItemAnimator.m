//
//  CYLRiveTabBarItemAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLRiveTabBarItemAnimator.h"

// [EN] Only with the Rive subspec; without it this file is empty and the class is never used.
// [CN] 仅在引入 Rive 子库时编译；未引入时本文件为空，也不会使用该类。
#if __has_include(<RiveRuntime/RiveRuntime.h>)
// [EN] The protocol and the registry of the `CYLTabBarItemAnimation` subspec (the source tree, or flattened by CocoaPods).
// [CN] `CYLTabBarItemAnimation` 子库的协议与注册表（源码目录，或 CocoaPods 展平后）。
#if __has_include("../CYLTabBarItemAnimatorRegistry.h")
#import "../CYLTabBarItemAnimatorRegistry.h"
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#endif
// [EN] Core's keys (`CYLTabBarRive…`, `CYLTabBarAnimation…`). [CN] Core 的 key。
#if __has_include("../../CYLTabBarController.h")
#import "../../CYLTabBarController.h"
#else
#import "CYLTabBarController.h"
#endif

/*!
 * [EN] The composition root: the one place that names the default view provider, the Swift bridge in RiveSwift/
 *      (Swift has no `+load`, so it cannot register itself). It is used only when it adopts
 *      `CYLRiveTabBarItemAnimationViewProviding`; everything else talks to the protocols.
 * [CN] 装配点：唯一指定默认视图 provider 的地方，即 RiveSwift/ 中的 Swift 桥接（Swift 没有 `+load`，无法自行注册）。仅在它遵守
 *      `CYLRiveTabBarItemAnimationViewProviding` 时使用；其他代码都只与协议交互。
 */
static NSString *const CYLRiveDefaultViewProviderClassName = @"CYLRiveTabBarItemAnimationView";

static Class<CYLRiveTabBarItemAnimationViewProviding> CYLRiveDefaultViewProvider(void) {
    static Class<CYLRiveTabBarItemAnimationViewProviding> provider;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class candidate = NSClassFromString(CYLRiveDefaultViewProviderClassName);
        if ([candidate conformsToProtocol:@protocol(CYLRiveTabBarItemAnimationViewProviding)]) {
            provider = candidate;
        }
    });
    return provider;
}

/// [EN] The injected provider; nil means the default. [CN] 注入的 provider；nil 表示使用默认值。
static Class<CYLRiveTabBarItemAnimationViewProviding> CYLRiveInjectedViewProvider;

/// [EN] Plays any view adopting `CYLRiveTabBarItemAnimationViewing`. [CN] 播放任意遵守 `CYLRiveTabBarItemAnimationViewing` 的视图。
@interface CYLRiveTabBarItemAnimationPlayer : CYLTabBarItemAnimationBasePlayer <CYLTabBarItemAnimationPlayer>
@end

@implementation CYLRiveTabBarItemAnimationPlayer {
    /// [EN] Whether the dark colors are applied now. [CN] 当前是否已应用深色颜色。
    BOOL _darkColorsApplied;
}

+ (BOOL)canPlayView:(UIView *)view {
    return [view conformsToProtocol:@protocol(CYLRiveTabBarItemAnimationViewing)];
}

- (id<CYLRiveTabBarItemAnimationViewing>)riveView {
    UIView *view = self.animationView;
    return [[self class] canPlayView:view] ? (id<CYLRiveTabBarItemAnimationViewing>)view : nil;
}

- (void)play {
    [self.riveView cyl_play];
}

- (void)showLastFrame {
    [self.riveView cyl_showLastFrame];
}

- (void)stop {
    [self.riveView cyl_stop];
}

/*!
 * [EN] Sets `darkColors` (view model color property path -> color) where `traitCollection` is dark, and restores the
 *      light colors otherwise, so one file follows Dark Mode. Does nothing when they are already in that state.
 * [CN] `traitCollection` 为深色时设置 `darkColors`（view model 颜色属性路径 -> 颜色），否则恢复浅色颜色，使一份文件即可适配深色模式。
 *      状态未变化时不做处理。
 */
- (void)applyDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors traitCollection:(UITraitCollection *)traitCollection {
    id<CYLRiveTabBarItemAnimationViewing> riveView = self.riveView;
    if (!riveView || darkColors.count == 0) {
        return;
    }
    BOOL dark = NO;
    if (@available(iOS 13.0, *)) {
        dark = (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    }
    if (_darkColorsApplied == dark) {
        return;
    }
    if (dark) {
        NSMutableDictionary<NSString *, UIColor *> *colors = [NSMutableDictionary dictionaryWithCapacity:darkColors.count];
        [darkColors enumerateKeysAndObjectsUsingBlock:^(NSString *path, UIColor *color, BOOL *stop) {
            (void)stop;
            if (![path isKindOfClass:[NSString class]] || ![color isKindOfClass:[UIColor class]]) {
                return;
            }
            UIColor *resolvedColor = color;
            if (@available(iOS 13.0, *)) {
                resolvedColor = [color resolvedColorWithTraitCollection:traitCollection];
            }
            colors[path] = resolvedColor;
        }];
        [riveView cyl_applyColors:colors];
    } else {
        [riveView cyl_applyColors:nil];
    }
    _darkColorsApplied = dark;
}

@end

@implementation CYLRiveTabBarItemAnimator

/// [EN] Registers itself when it is linked (only with Rive). [CN] 被链接时自行注册（仅在引入 Rive 时）。
+ (void)load {
    [CYLTabBarItemAnimatorRegistry registerAnimator:[[self alloc] init]];
}

+ (Class<CYLRiveTabBarItemAnimationViewProviding>)viewProvider {
    return CYLRiveInjectedViewProvider ?: CYLRiveDefaultViewProvider();
}

+ (void)setViewProvider:(Class<CYLRiveTabBarItemAnimationViewProviding>)viewProvider {
    CYLRiveInjectedViewProvider = [viewProvider conformsToProtocol:@protocol(CYLRiveTabBarItemAnimationViewProviding)] ? viewProvider : nil;
}

- (NSString *)identifier {
    return @"Rive";
}

- (NSArray<NSString *> *)fileExtensions {
    return @[ @"riv" ];
}

/// [EN] The Rive keys, which stand for the generic `CYLTabBarAnimation…` keys. [CN] Rive 的 key，对应通用的 `CYLTabBarAnimation…` key。
- (NSDictionary<NSString *, NSString *> *)attributeKeys {
    return @{
        CYLTabBarAnimationURL : CYLTabBarRiveURL,
        CYLTabBarAnimationFilePath : CYLTabBarRiveFilePath,
        CYLTabBarAnimationSize : CYLTabBarRiveSize,
        CYLTabBarAnimationDarkURL : CYLTabBarRiveDarkURL,
        CYLTabBarAnimationDarkFilePath : CYLTabBarRiveDarkFilePath,
        CYLTabBarAnimationDarkColors : CYLTabBarRiveDarkColors,
    };
}

- (BOOL)canAnimateFileAtURL:(NSURL *)URL {
    // [EN] `pathExtension` leaves out the fragment (the options). [CN] `pathExtension` 不包含 fragment（选项）。
    return [URL.pathExtension.lowercaseString isEqualToString:@"riv"];
}

- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    CYLRiveTabBarItemAnimationConfiguration *configuration =
        [CYLRiveTabBarItemAnimationConfiguration configurationWithAnimationURL:URL contentMode:contentMode];
    Class<CYLRiveTabBarItemAnimationViewProviding> provider = [[self class] viewProvider];
    if (!configuration || !provider) {
        return nil;
    }
    UIView<CYLRiveTabBarItemAnimationViewing> *view = [provider cyl_animationViewWithConfiguration:configuration];
    view.frame = CGRectMake(0, 0, size.width, size.height);
    return view;
}

- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
    return [CYLRiveTabBarItemAnimationPlayer canPlayView:view] ? [[CYLRiveTabBarItemAnimationPlayer alloc] initWithAnimationView:view] : nil;
}

@end

#endif
