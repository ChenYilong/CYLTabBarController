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
// [EN] Core's keys and options (`CYLTabBarRive…`, `CYLTabBarAnimation…`).
// [CN] Core 的 key 与选项。
#if __has_include("../../CYLTabBarController.h")
#import "../../CYLTabBarController.h"
#else
#import "CYLTabBarController.h"
#endif

/// [EN] The runtime name of the Swift bridge (`RiveSwift/CYLRiveTabBarItemAnimationView.swift`).
/// [CN] Swift 桥接类的运行时名称（`RiveSwift/CYLRiveTabBarItemAnimationView.swift`）。
static NSString *const CYLRiveTabBarItemAnimationViewClassName = @"CYLRiveTabBarItemAnimationView";

/*!
 * [EN] What this file calls on the Swift bridge. It is resolved at runtime (`NSClassFromString`, `respondsToSelector:`), so
 *      this file needs no generated Swift header and builds the same with CocoaPods, SPM and Carthage.
 * [CN] 本文件调用 Swift 桥接的方法。运行时解析（`NSClassFromString`、`respondsToSelector:`），因此本文件不需要生成的 Swift 头文件，
 *      在 CocoaPods、SPM、Carthage 下编译方式相同。
 */
@protocol CYLRiveTabBarItemAnimationViewControlling <NSObject>
- (instancetype)initWithFileURL:(NSURL *)fileURL
                   artboardName:(nullable NSString *)artboardName
               stateMachineName:(nullable NSString *)stateMachineName
             activePropertyPath:(NSString *)activePropertyPath
                 activeDuration:(NSTimeInterval)activeDuration
            triggerPropertyPath:(nullable NSString *)triggerPropertyPath
                     lightColor:(nullable UIColor *)lightColor
                    contentMode:(UIViewContentMode)contentMode;
- (void)cyl_play;
- (void)cyl_showLastFrame;
- (void)cyl_stop;
/// [EN] Color property path -> color; nil restores the colors the view had before. [CN] 颜色属性路径 -> 颜色；nil 恢复原来的颜色。
- (void)cyl_applyColors:(nullable NSDictionary<NSString *, UIColor *> *)colors;
@end

/// [EN] The default path of the view model boolean that plays an icon (rive_animated_icon's icons use it).
/// [CN] 播放图标的 view model 布尔属性的默认路径（rive_animated_icon 的图标使用它）。
static NSString *const CYLRiveDefaultActivePropertyPath = @"active";
/// [EN] Seconds the boolean stays YES (as rive_animated_icon does on a tap). [CN] 布尔属性保持 YES 的秒数（与 rive_animated_icon 点击时相同）。
static const NSTimeInterval CYLRiveDefaultActiveDuration = 1;

/// [EN] The options in `URL`'s fragment ("name=value&…", percent-encoded). [CN] `URL` 的 fragment 中的选项（「名称=值&…」，百分号编码）。
static NSDictionary<NSString *, NSString *> *CYLRiveOptionsFromURL(NSURL *URL) {
    NSString *fragment = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES].percentEncodedFragment;
    if (fragment.length == 0) {
        return @{};
    }
    NSMutableDictionary<NSString *, NSString *> *options = [NSMutableDictionary dictionary];
    for (NSString *item in [fragment componentsSeparatedByString:@"&"]) {
        NSRange separator = [item rangeOfString:@"="];
        if (separator.location == NSNotFound || separator.location == 0) {
            continue;
        }
        NSString *name = [[item substringToIndex:separator.location] stringByRemovingPercentEncoding];
        NSString *value = [[item substringFromIndex:NSMaxRange(separator)] stringByRemovingPercentEncoding];
        if (name.length > 0 && value.length > 0) {
            options[name] = value;
        }
    }
    return [options copy];
}

/// [EN] `URL` without its fragment: the .riv file itself. [CN] 去掉 fragment 的 `URL`，即 .riv 文件本身。
static NSURL *CYLRiveFileURLFromURL(NSURL *URL) {
    NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    components.fragment = nil;
    return components.URL ?: URL;
}

/// [EN] "#RRGGBB" or "#RRGGBBAA" (the "#" is optional), else nil. [CN] "#RRGGBB" 或 "#RRGGBBAA"（"#" 可省略），否则返回 nil。
static UIColor *CYLRiveColorFromHexString(NSString *string) {
    NSString *hex = [string hasPrefix:@"#"] ? [string substringFromIndex:1] : string;
    if (hex.length != 6 && hex.length != 8) {
        return nil;
    }
    NSCharacterSet *notHex = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdefABCDEF"] invertedSet];
    if ([hex rangeOfCharacterFromSet:notHex].location != NSNotFound) {
        return nil;
    }
    unsigned long long value = strtoull(hex.UTF8String, NULL, 16);
    if (hex.length == 6) {
        value = (value << 8) | 0xFF;
    }
    return [UIColor colorWithRed:((value >> 24) & 0xFF) / 255.0
                           green:((value >> 16) & 0xFF) / 255.0
                            blue:((value >> 8) & 0xFF) / 255.0
                           alpha:(value & 0xFF) / 255.0];
}

/// [EN] Plays a `CYLRiveTabBarItemAnimationView`. [CN] 播放 `CYLRiveTabBarItemAnimationView`。
@interface CYLRiveTabBarItemAnimationPlayer : CYLTabBarItemAnimationBasePlayer <CYLTabBarItemAnimationPlayer>
@end

@implementation CYLRiveTabBarItemAnimationPlayer {
    /// [EN] Whether the dark colors are applied now. [CN] 当前是否已应用深色颜色。
    BOOL _darkColorsApplied;
}

+ (BOOL)isRiveView:(UIView *)view {
    Class viewClass = NSClassFromString(CYLRiveTabBarItemAnimationViewClassName);
    return viewClass && [view isKindOfClass:viewClass];
}

- (id<CYLRiveTabBarItemAnimationViewControlling>)riveView {
    return (id<CYLRiveTabBarItemAnimationViewControlling>)self.animationView;
}

- (void)play {
    id<CYLRiveTabBarItemAnimationViewControlling> riveView = self.riveView;
    if ([riveView respondsToSelector:@selector(cyl_play)]) {
        [riveView cyl_play];
    }
}

- (void)showLastFrame {
    id<CYLRiveTabBarItemAnimationViewControlling> riveView = self.riveView;
    if ([riveView respondsToSelector:@selector(cyl_showLastFrame)]) {
        [riveView cyl_showLastFrame];
    }
}

- (void)stop {
    id<CYLRiveTabBarItemAnimationViewControlling> riveView = self.riveView;
    if ([riveView respondsToSelector:@selector(cyl_stop)]) {
        [riveView cyl_stop];
    }
}

/*!
 * [EN] Sets `darkColors` (view model color property path -> color) where `traitCollection` is dark, and restores the
 *      light colors otherwise, so one file follows Dark Mode. Does nothing when they are already in that state.
 * [CN] `traitCollection` 为深色时设置 `darkColors`（view model 颜色属性路径 -> 颜色），否则恢复浅色颜色，使一份文件即可适配深色模式。
 *      状态未变化时不做处理。
 */
- (void)applyDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors traitCollection:(UITraitCollection *)traitCollection {
    id<CYLRiveTabBarItemAnimationViewControlling> riveView = self.riveView;
    if (!riveView || darkColors.count == 0 || ![riveView respondsToSelector:@selector(cyl_applyColors:)]) {
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
    // [EN] `pathExtension` leaves out the fragment (the artboard and state machine options).
    // [CN] `pathExtension` 不包含 fragment（画板与状态机选项）。
    return [URL.pathExtension.lowercaseString isEqualToString:@"riv"];
}

- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    Class viewClass = NSClassFromString(CYLRiveTabBarItemAnimationViewClassName);
    SEL initializer = @selector(initWithFileURL:artboardName:stateMachineName:activePropertyPath:activeDuration:triggerPropertyPath:lightColor:contentMode:);
    if (!URL || ![viewClass isSubclassOfClass:[UIView class]] || ![viewClass instancesRespondToSelector:initializer]) {
        return nil;
    }
    NSDictionary<NSString *, NSString *> *options = CYLRiveOptionsFromURL(URL);
    NSString *activePropertyPath = options[CYLTabBarRiveOptionActiveProperty] ?: CYLRiveDefaultActivePropertyPath;
    NSString *durationString = options[CYLTabBarRiveOptionActiveDuration];
    NSTimeInterval activeDuration = durationString.length > 0 ? durationString.doubleValue : CYLRiveDefaultActiveDuration;
    // [EN] Zero, negative or not a number: the default. [CN] 为 0、负数或不是数字时使用默认值。
    if (!(activeDuration > 0)) {
        activeDuration = CYLRiveDefaultActiveDuration;
    }
    NSString *colorString = options[CYLTabBarRiveOptionColor];
    UIColor *lightColor = colorString.length > 0 ? CYLRiveColorFromHexString(colorString) : nil;
    id<CYLRiveTabBarItemAnimationViewControlling> riveView = [(id<CYLRiveTabBarItemAnimationViewControlling>)[viewClass alloc]
                                                               initWithFileURL:CYLRiveFileURLFromURL(URL)
                                                                  artboardName:options[CYLTabBarRiveOptionArtboard]
                                                              stateMachineName:options[CYLTabBarRiveOptionStateMachine]
                                                            activePropertyPath:activePropertyPath
                                                                activeDuration:activeDuration
                                                           triggerPropertyPath:options[CYLTabBarRiveOptionTriggerProperty]
                                                                    lightColor:lightColor
                                                                   contentMode:contentMode];
    UIView *view = [riveView isKindOfClass:[UIView class]] ? (UIView *)riveView : nil;
    view.frame = CGRectMake(0, 0, size.width, size.height);
    return view;
}

- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
    return [CYLRiveTabBarItemAnimationPlayer isRiveView:view] ? [[CYLRiveTabBarItemAnimationPlayer alloc] initWithAnimationView:view] : nil;
}

@end

#endif
