//
//  CYLRiveTabBarItemAnimationConfiguration.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLRiveTabBarItemAnimationConfiguration.h"
// [EN] Core's option names (`CYLTabBarRiveOption…`). [CN] Core 的选项名称。
#if __has_include("../../CYLTabBarController.h")
#import "../../CYLTabBarController.h"
#else
#import "CYLTabBarController.h"
#endif

/// [EN] The defaults of rive_animated_icon's icons. [CN] rive_animated_icon 图标的默认值。
static NSString *const CYLRiveDefaultActivePropertyPath = @"active";
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

@implementation CYLRiveTabBarItemAnimationConfiguration

+ (instancetype)configurationWithAnimationURL:(NSURL *)animationURL contentMode:(UIViewContentMode)contentMode {
    if (![animationURL isKindOfClass:[NSURL class]]) {
        return nil;
    }
    NSDictionary<NSString *, NSString *> *options = CYLRiveOptionsFromURL(animationURL);
    NSString *colorString = options[CYLTabBarRiveOptionColor];
    return [[self alloc] initWithFileURL:CYLRiveFileURLFromURL(animationURL)
                            artboardName:options[CYLTabBarRiveOptionArtboard]
                        stateMachineName:options[CYLTabBarRiveOptionStateMachine]
                      activePropertyPath:options[CYLTabBarRiveOptionActiveProperty]
                          activeDuration:options[CYLTabBarRiveOptionActiveDuration].doubleValue
                     triggerPropertyPath:options[CYLTabBarRiveOptionTriggerProperty]
                              lightColor:colorString.length > 0 ? CYLRiveColorFromHexString(colorString) : nil
                             contentMode:contentMode];
}

- (instancetype)initWithFileURL:(NSURL *)fileURL
                   artboardName:(NSString *)artboardName
               stateMachineName:(NSString *)stateMachineName
             activePropertyPath:(NSString *)activePropertyPath
                 activeDuration:(NSTimeInterval)activeDuration
            triggerPropertyPath:(NSString *)triggerPropertyPath
                     lightColor:(UIColor *)lightColor
                    contentMode:(UIViewContentMode)contentMode {
    if (self = [super init]) {
        _fileURL = [fileURL copy];
        _artboardName = artboardName.length > 0 ? [artboardName copy] : nil;
        _stateMachineName = stateMachineName.length > 0 ? [stateMachineName copy] : nil;
        _activePropertyPath = activePropertyPath.length > 0 ? [activePropertyPath copy] : CYLRiveDefaultActivePropertyPath;
        // [EN] Zero, negative or not a number: the default. [CN] 为 0、负数或不是数字时使用默认值。
        _activeDuration = (activeDuration > 0) ? activeDuration : CYLRiveDefaultActiveDuration;
        _triggerPropertyPath = triggerPropertyPath.length > 0 ? [triggerPropertyPath copy] : nil;
        _lightColor = lightColor;
        _contentMode = contentMode;
    }
    return self;
}

/// [EN] Immutable, so a copy is itself. [CN] 不可变对象，拷贝即自身。
- (id)copyWithZone:(NSZone *)zone {
    (void)zone;
    return self;
}

@end
