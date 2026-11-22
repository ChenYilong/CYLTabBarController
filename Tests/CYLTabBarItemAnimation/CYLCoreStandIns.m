//
//  CYLCoreStandIns.m
//  CYLTabBarItemAnimation tests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Objective-C stand-ins for the three Core helpers these tests drive the subspec with. Core is Swift now
//      (`CYLTabBarItemAttributesAnimationValue()` and `CYLTabBarAnimationURLWithOptions()` in
//      Swift/UIControl+CYLTabBarItemAnimation.swift, `CYLTabBarItemAnimationStyleRegistry` in
//      Swift/CYLTabBarItemAnimationStyleRegistry.swift; docs/Swift-Migration.md) and needs UIKit, which this macOS harness only
//      stubs, so run.sh can no longer extract them. Each stand-in mirrors the Swift code line by line; keep them in step.
//      The subspec sources under test (registry, engine, view animator, player) are still the real ones.
// [CN] 本测试驱动子库所用的三个 Core 辅助函数的 Objective-C 替身。Core 已是 Swift（`CYLTabBarItemAttributesAnimationValue()` 与
//      `CYLTabBarAnimationURLWithOptions()` 位于 Swift/UIControl+CYLTabBarItemAnimation.swift，`CYLTabBarItemAnimationStyleRegistry` 位于
//      Swift/CYLTabBarItemAnimationStyleRegistry.swift；docs/Swift-Migration.md），且依赖 UIKit，而本 macOS 测试只有 UIKit 的桩，因此 run.sh
//      无法再提取它们。每个替身逐行对应 Swift 代码，修改时请保持一致。被测试的子库源码（注册表、引擎、视图 animator、播放器）仍是真实代码。

#import <UIKit/UIKit.h>
#import "CYLTabBarItemAnimationService.h"

typedef NSString *CYLTabBarAnimationOption;

/// [EN] The service slot, defined in main.m. [CN] 服务槽位，定义在 main.m 中。
id<CYLTabBarItemAnimationService> CYLTabBarItemAnimationGetService(void);

/// [EN] `CYLTabBarItemAnimationCore.attributesAnimationValue`: the generic key first, then the key of the library the tab's keys choose.
/// [CN] `CYLTabBarItemAnimationCore.attributesAnimationValue`：先读通用 key，再读 Tab 的 key 所选动画库的 key。
id CYLTabBarItemAttributesAnimationValue(NSDictionary *attributes, NSString *genericKey) {
    if (attributes == nil || genericKey.length == 0) {
        return nil;
    }
    id value = attributes[genericKey];
    if (value) {
        return value;
    }
    NSString *key = [CYLTabBarItemAnimationGetService() attributeKeyForGenericKey:genericKey inAttributes:attributes];
    return key ? attributes[key] : nil;
}

/// [EN] `cylTabBarAnimationURLWithOptionsEntryPoint`: the options, sorted and percent-encoded, as the URL's fragment.
/// [CN] `cylTabBarAnimationURLWithOptionsEntryPoint`：选项排序并百分号编码后作为 URL 的 fragment。
NSURL *CYLTabBarAnimationURLWithOptions(NSURL *fileURL, NSDictionary<CYLTabBarAnimationOption, NSString *> *options) {
    NSURLComponents *components = fileURL ? [NSURLComponents componentsWithURL:fileURL resolvingAgainstBaseURL:YES] : nil;
    if (!components) {
        return nil;
    }
    NSMutableCharacterSet *allowed = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [allowed removeCharactersInString:@"&=+#?"];
    NSMutableDictionary<NSString *, NSString *> *values = [NSMutableDictionary dictionary];
    [options enumerateKeysAndObjectsUsingBlock:^(id name, id value, BOOL *stop) {
        if ([name isKindOfClass:[NSString class]] && [value isKindOfClass:[NSString class]] && [name length] > 0 && [value length] > 0) {
            values[name] = value;
        }
    }];
    NSMutableArray<NSString *> *items = [NSMutableArray array];
    for (NSString *name in [values.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        NSString *encodedName = [name stringByAddingPercentEncodingWithAllowedCharacters:allowed];
        NSString *encodedValue = [values[name] stringByAddingPercentEncodingWithAllowedCharacters:allowed];
        if (encodedName.length > 0 && encodedValue.length > 0) {
            [items addObject:[NSString stringWithFormat:@"%@=%@", encodedName, encodedValue]];
        }
    }
    components.percentEncodedFragment = items.count > 0 ? [items componentsJoinedByString:@"&"] : nil;
    return components.URL;
}

/// [EN] `cylTabBarAnimationOptionsFromURLEntryPoint` (CYLUtils/Swift/CYLAnimationURLOptions.swift, with its private
///      `cylAnimationOptions(inText:)`): the fragment split at `&`, then at a `#` or `?` that does not follow `=`; a pair needs a
///      name; names and values percent-decoded when they can be (kept as they are otherwise); an empty value left out.
/// [CN] `cylTabBarAnimationOptionsFromURLEntryPoint`（CYLUtils/Swift/CYLAnimationURLOptions.swift 及其私有的
///      `cylAnimationOptions(inText:)`）：fragment 先按 `&` 分开，再按不跟在 `=` 后面的 `#` 或 `?` 分开；键值对必须有名称；名称与值能解码时
///      百分号解码（否则保持原样）；空值被省略。
NSDictionary *CYLTabBarAnimationOptionsFromURL(NSURL *URL) {
    NSString *fragment = URL ? [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES].percentEncodedFragment : nil;
    if (fragment == nil) {
        return @{};
    }
    NSMutableArray<NSString *> *pairs = [NSMutableArray array];
    for (NSString *piece in [fragment componentsSeparatedByString:@"&"]) {
        NSUInteger start = 0;
        for (NSUInteger index = 1; index < piece.length; index++) {
            unichar character = [piece characterAtIndex:index];
            if ((character == '#' || character == '?') && [piece characterAtIndex:index - 1] != '=') {
                [pairs addObject:[piece substringWithRange:NSMakeRange(start, index - start)]];
                start = index + 1;
            }
        }
        [pairs addObject:start <= piece.length ? [piece substringFromIndex:start] : @""];
    }
    NSMutableDictionary<NSString *, NSString *> *options = [NSMutableDictionary dictionary];
    for (NSString *pair in pairs) {
        NSRange separator = [pair rangeOfString:@"="];
        if (separator.location == NSNotFound || separator.location == 0) {
            continue;
        }
        NSString *name = [pair substringToIndex:separator.location];
        NSString *value = [pair substringFromIndex:NSMaxRange(separator)];
        NSString *decodedValue = value.stringByRemovingPercentEncoding ?: value;
        if (decodedValue.length > 0) {
            options[name.stringByRemovingPercentEncoding ?: name] = decodedValue;
        }
    }
    return [options copy];
}

/// [EN] `CYLTabBarItemAnimationStyleRegistry` (the dark versions and dark colors it keeps per URL).
/// [CN] `CYLTabBarItemAnimationStyleRegistry`（按 URL 保存的深色版本与深色颜色）。
@interface CYLTabBarItemAnimationStyleRegistry : NSObject <CYLTabBarItemAnimationStyleSource>
- (void)registerDarkURL:(NSURL *)darkURL forURL:(NSURL *)URL;
- (void)registerDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors forURL:(NSURL *)URL;
@end

@implementation CYLTabBarItemAnimationStyleRegistry {
    NSMutableDictionary<NSString *, NSURL *> *_darkURLs;
    NSMutableDictionary<NSString *, NSDictionary<NSString *, UIColor *> *> *_darkColors;
}

- (instancetype)init {
    if (self = [super init]) {
        _darkURLs = [NSMutableDictionary dictionary];
        _darkColors = [NSMutableDictionary dictionary];
    }
    return self;
}

static NSString *CYLStyleKey(NSURL *URL) {
    NSString *key = URL.absoluteString;
    return key.length > 0 ? key : nil;
}

- (void)registerDarkURL:(NSURL *)darkURL forURL:(NSURL *)URL {
    NSString *key = CYLStyleKey(URL);
    if (key) {
        _darkURLs[key] = darkURL;
    }
}

- (void)registerDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors forURL:(NSURL *)URL {
    NSString *key = CYLStyleKey(URL);
    if (!key) {
        return;
    }
    NSMutableDictionary<NSString *, UIColor *> *valid = [NSMutableDictionary dictionary];
    [darkColors enumerateKeysAndObjectsUsingBlock:^(id keypath, id color, BOOL *stop) {
        if ([keypath isKindOfClass:[NSString class]] && [keypath length] > 0 && [color isKindOfClass:[UIColor class]]) {
            valid[keypath] = color;
        }
    }];
    _darkColors[key] = valid.count > 0 ? [valid copy] : nil;
}

- (BOOL)hasStyleVariants {
    return _darkURLs.count > 0 || _darkColors.count > 0;
}

- (BOOL)hasStyleVariantForURL:(NSURL *)URL {
    NSString *key = CYLStyleKey(URL);
    return key && (_darkURLs[key] != nil || _darkColors[key].count > 0);
}

- (NSURL *)URL:(NSURL *)URL forTraitCollection:(UITraitCollection *)traitCollection {
    if (!URL) {
        return nil;
    }
    NSString *key = CYLStyleKey(URL);
    if (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark && key) {
        return _darkURLs[key] ?: URL;
    }
    return URL;
}

- (NSDictionary<NSString *, UIColor *> *)darkColorsForURL:(NSURL *)URL {
    NSString *key = CYLStyleKey(URL);
    return key ? _darkColors[key] : nil;
}

@end
