//
//  CYLTabBarController+CYLConfiguration.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"
#import "CYLTabBarController+CYLPrivate.h"

/// [EN] Private: marks a left-out tab; the same key as in CYLTabBarController.m. [CN] 私有：标记被排除的 Tab；与 CYLTabBarController.m 中的键相同。
static NSString *const CYLTabBarItemExcludedKey = @"_CYLTabBarItemExcluded";
/// [EN] Private: the reason of a left-out tab (English); the same key as in CYLTabBarController.m. [CN] 私有：被排除的 Tab 的原因（英文）；与 CYLTabBarController.m 中的键相同。
static NSString *const CYLTabBarItemExclusionReasonKey = @"_CYLTabBarItemExclusionReason";

/*!
 * [EN] The keys of the PAG, Rive and GIF subspecs (`CYLTabBarPAG…`, `CYLTabBarRive…`, `CYLTabBarGIF…`, #605), by name: their constants exist only
 *      when that subspec is part of the build, while a configuration may name them whether or not the library is
 *      installed (a library that is not installed ignores its keys, B29). The values are converted like the Lottie keys.
 * [CN] PAG、Rive 与 GIF 子库的键（`CYLTabBarPAG…`、`CYLTabBarRive…`、`CYLTabBarGIF…`，#605），按名称引用：它们的常量只在该子库参与编译时存在，而配置无论动画库是否
 *      安装都可以写这些键（未安装的动画库会忽略自己的键，B29）。值的转换与 Lottie 键相同。
 */
static NSString *const CYLConfigurationPAGURLKey = @"CYLTabBarPAGURL";
static NSString *const CYLConfigurationPAGFilePathKey = @"CYLTabBarPAGFilePath";
static NSString *const CYLConfigurationPAGSizeKey = @"CYLTabBarPAGSize";
static NSString *const CYLConfigurationPAGDarkURLKey = @"CYLTabBarPAGDarkURL";
static NSString *const CYLConfigurationPAGDarkFilePathKey = @"CYLTabBarPAGDarkFilePath";
static NSString *const CYLConfigurationRiveURLKey = @"CYLTabBarRiveURL";
static NSString *const CYLConfigurationRiveFilePathKey = @"CYLTabBarRiveFilePath";
static NSString *const CYLConfigurationRiveSizeKey = @"CYLTabBarRiveSize";
static NSString *const CYLConfigurationRiveDarkURLKey = @"CYLTabBarRiveDarkURL";
static NSString *const CYLConfigurationRiveDarkFilePathKey = @"CYLTabBarRiveDarkFilePath";
static NSString *const CYLConfigurationRiveDarkColorsKey = @"CYLTabBarRiveDarkColors";
static NSString *const CYLConfigurationGIFURLKey = @"CYLTabBarGIFURL";
static NSString *const CYLConfigurationGIFFilePathKey = @"CYLTabBarGIFFilePath";
static NSString *const CYLConfigurationGIFSizeKey = @"CYLTabBarGIFSize";
static NSString *const CYLConfigurationGIFDarkURLKey = @"CYLTabBarGIFDarkURL";
static NSString *const CYLConfigurationGIFDarkFilePathKey = @"CYLTabBarGIFDarkFilePath";
/*!
 * [EN] The Lottie keys by name too: their constants are `CYL_LOTTIE_REQUIRED` (a deprecation warning in a build without
 *      Lottie, which CI treats as an error), while a configuration may name them in any build (B29). Same values as
 *      CYLTabBarController.m.
 * [CN] Lottie 的键同样按名称引用：它们的常量带 `CYL_LOTTIE_REQUIRED`（无 Lottie 的构建中是弃用警告，CI 视为错误），而配置在任何构建中都可以写
 *      这些键（B29）。值与 CYLTabBarController.m 相同。
 */
static NSString *const CYLConfigurationLottieURLKey = @"CYLTabBarLottieURL";
static NSString *const CYLConfigurationLottieFilePathKey = @"CYLTabBarLottieFilePath";
static NSString *const CYLConfigurationLottieSizeKey = @"CYLTabBarLottieSize";
static NSString *const CYLConfigurationLottieDarkURLKey = @"CYLTabBarLottieDarkURL";
static NSString *const CYLConfigurationLottieDarkFilePathKey = @"CYLTabBarLottieDarkFilePath";
static NSString *const CYLConfigurationLottieDarkColorsKey = @"CYLTabBarLottieDarkColors";
static NSString *const CYLConfigurationLottieLoopsWhenUnselectedKey = @"CYLTabBarLottieLoopsWhenUnselected";
/*!
 * [EN] Private: marks the entry the tab bar controller inserts for the PlusButton slot; the same key as in
 *      CYLTabBarController.m (#774).
 * [CN] 私有：标记 TabBarController 为 PlusButton 的 slot 插入的一项；与 CYLTabBarController.m 中的键相同（#774）。
 */
static NSString *const CYLTabBarItemPlusSlotPlaceholderKey = @"CYLTabBarItemPlusSlotPlaceholder";
#include <math.h>

#pragma mark - Value conversion

/*!
 * [EN] `count` numbers from a configuration value: "{a, b}", "a, b" or "a b", an array, or a dictionary with one of the
 *      names in `keys[i]` (alternatives separated by "|") for each number. nil when it does not fit.
 * [CN] 从配置值中取出 `count` 个数字：支持 "{a, b}"、"a, b" 或 "a b"、数组，或字典（第 i 个数字的键为 `keys[i]` 中的任一名称，
 *      用 "|" 分隔）。不符合时返回 nil。
 */
static NSArray<NSNumber *> *_Nullable CYLConfigurationNumbers(id value, NSUInteger count, NSArray<NSString *> *keys) {
    NSMutableArray<NSNumber *> *numbers = [NSMutableArray array];
    if ([value isKindOfClass:[NSString class]]) {
        NSCharacterSet *separators = [NSCharacterSet characterSetWithCharactersInString:@"{}[](), \t"];
        for (NSString *part in [(NSString *)value componentsSeparatedByCharactersInSet:separators]) {
            if (part.length == 0) {
                continue;
            }
            NSScanner *scanner = [NSScanner scannerWithString:part];
            double number = 0;
            if (![scanner scanDouble:&number] || !scanner.isAtEnd) {
                return nil;
            }
            [numbers addObject:@(number)];
        }
    } else if ([value isKindOfClass:[NSArray class]]) {
        for (id element in (NSArray *)value) {
            if (![element respondsToSelector:@selector(doubleValue)]) {
                return nil;
            }
            [numbers addObject:@([element doubleValue])];
        }
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        for (NSString *names in keys) {
            id number = nil;
            for (NSString *name in [names componentsSeparatedByString:@"|"]) {
                number = number ?: [(NSDictionary *)value objectForKey:name];
            }
            [numbers addObject:@([number respondsToSelector:@selector(doubleValue)] ? [number doubleValue] : 0)];
        }
    }
    return numbers.count == count ? numbers : nil;
}

static BOOL CYLIsValueOfType(id value, const char *type) {
    return [value isKindOfClass:[NSValue class]] && strcmp([(NSValue *)value objCType], type) == 0;
}

static void CYLLogInvalidConfigurationValue(NSString *key, id value) {
#if defined(DEBUG) || defined(BETA)
    NSLog(@"🔴 CYLTabBarController configuration: the value of %@ (%@) is not valid and is ignored.", key, value);
#endif
}

/*!
 * [EN] Insets, offsets and sizes must be finite and at most 1000 in magnitude (sizes also above 0): NaN or Infinity in a
 *      layout raises a CALayer exception, and a huge value pushes the icon off screen (B7, B8). Values passed in code
 *      as NSValue are checked too.
 * [CN] 内边距、偏移与尺寸必须是有限值且绝对值不超过 1000（尺寸还必须大于 0）：布局中的 NaN 或 Infinity 会触发 CALayer 异常，极大的值会让
 *      图标移出屏幕（B7、B8）。代码中以 NSValue 传入的值同样会检查。
 */
static const double CYLConfigurationMaximumMagnitude = 1000;

static BOOL CYLNumbersAreReasonable(const double *values, NSUInteger count, BOOL positive) {
    for (NSUInteger i = 0; i < count; i++) {
        if (!isfinite(values[i]) || fabs(values[i]) > CYLConfigurationMaximumMagnitude || (positive && values[i] <= 0)) {
            return NO;
        }
    }
    return YES;
}

static NSValue *_Nullable CYLEdgeInsetsValue(id value, NSString *key) {
    UIEdgeInsets insets = UIEdgeInsetsZero;
    if (CYLIsValueOfType(value, @encode(UIEdgeInsets))) {
        insets = [(NSValue *)value UIEdgeInsetsValue];
    } else {
        NSArray<NSNumber *> *n = CYLConfigurationNumbers(value, 4, @[ @"top", @"left", @"bottom", @"right" ]);
        if (!n) {
            CYLLogInvalidConfigurationValue(key, value);
            return nil;
        }
        insets = UIEdgeInsetsMake(n[0].doubleValue, n[1].doubleValue, n[2].doubleValue, n[3].doubleValue);
    }
    double values[4] = { insets.top, insets.left, insets.bottom, insets.right };
    if (!CYLNumbersAreReasonable(values, 4, NO)) {
        CYLLogInvalidConfigurationValue(key, value);
        return nil;
    }
    return [NSValue valueWithUIEdgeInsets:insets];
}

static NSValue *_Nullable CYLOffsetValue(id value, NSString *key) {
    UIOffset offset = UIOffsetZero;
    if (CYLIsValueOfType(value, @encode(UIOffset))) {
        offset = [(NSValue *)value UIOffsetValue];
    } else {
        NSArray<NSNumber *> *n = CYLConfigurationNumbers(value, 2, @[ @"horizontal|x", @"vertical|y" ]);
        if (!n) {
            CYLLogInvalidConfigurationValue(key, value);
            return nil;
        }
        offset = UIOffsetMake(n[0].doubleValue, n[1].doubleValue);
    }
    double values[2] = { offset.horizontal, offset.vertical };
    if (!CYLNumbersAreReasonable(values, 2, NO)) {
        CYLLogInvalidConfigurationValue(key, value);
        return nil;
    }
    return [NSValue valueWithUIOffset:offset];
}

static NSValue *_Nullable CYLSizeValue(id value, NSString *key) {
    CGSize size = CGSizeZero;
    if (CYLIsValueOfType(value, @encode(CGSize))) {
        size = [(NSValue *)value CGSizeValue];
    } else {
        NSArray<NSNumber *> *n = CYLConfigurationNumbers(value, 2, @[ @"width|w", @"height|h" ]);
        if (!n) {
            CYLLogInvalidConfigurationValue(key, value);
            return nil;
        }
        size = CGSizeMake(n[0].doubleValue, n[1].doubleValue);
    }
    double values[2] = { size.width, size.height };
    if (!CYLNumbersAreReasonable(values, 2, YES)) {
        CYLLogInvalidConfigurationValue(key, value);
        return nil;
    }
    return [NSValue valueWithCGSize:size];
}

/// [EN] "default", "system", "flatDesign", "liquidGlass" (any case, with or without the `CYLTabBarStyleType` prefix) or a number.
/// [CN] "default"、"system"、"flatDesign"、"liquidGlass"（不区分大小写，可带 `CYLTabBarStyleType` 前缀）或数字。
static NSNumber *_Nullable CYLStyleTypeValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        NSInteger style = [value integerValue];
        if ((double)style != [value doubleValue] || style < CYLTabBarStyleTypeDefault || style > CYLTabBarStyleTypeLiquidGlass) {
            CYLLogInvalidConfigurationValue(CYLTabBarControllerStyleType, value);
            return nil;
        }
#if !CYL_FLATDESIGN_AVAILABLE
        if (style == CYLTabBarStyleTypeFlatDesign) {
            // FlatDesign needs its subspec (B10). 扁平样式需要其子库（B10）。
#if defined(DEBUG) || defined(BETA)
            NSLog(@"🔴 CYLTabBarController configuration: flatDesign needs the CYLTabBarController/CYLFlatDesignTabBar subspec; the default style is used.");
#endif
            return nil;
        }
#endif
        return @(style);
    }
    if (![value isKindOfClass:[NSString class]]) {
        CYLLogInvalidConfigurationValue(CYLTabBarControllerStyleType, value);
        return nil;
    }
    NSString *name = [[(NSString *)value lowercaseString] stringByReplacingOccurrencesOfString:@"cyltabbarstyletype" withString:@""];
    name = [[name stringByReplacingOccurrencesOfString:@"_" withString:@""] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSDictionary<NSString *, NSNumber *> *styles = @{
        @"default" : @(CYLTabBarStyleTypeDefault),
        @"system" : @(CYLTabBarStyleTypeSystem),
        @"flatdesign" : @(CYLTabBarStyleTypeFlatDesign),
        @"flat" : @(CYLTabBarStyleTypeFlatDesign),
        @"liquidglass" : @(CYLTabBarStyleTypeLiquidGlass),
        @"glass" : @(CYLTabBarStyleTypeLiquidGlass),
    };
    NSNumber *style = styles[name];
    if (!style) {
        NSScanner *scanner = [NSScanner scannerWithString:name];
        NSInteger number = 0;
        if ([scanner scanInteger:&number] && scanner.isAtEnd) {
            style = @(number);
        }
    }
    if (!style) {
        CYLLogInvalidConfigurationValue(CYLTabBarControllerStyleType, value);
        return nil;
    }
    return CYLStyleTypeValue(style);
}

/// [EN] "system:<name>" is an SF Symbol (iOS 13+); anything else is kept (an image name, a UIImage...).
/// [CN] "system:<名称>" 为 SF Symbol（iOS 13+）；其他值保持不变（图片名称、UIImage 等）。
static id CYLImageValue(id value) {
    if ([value isKindOfClass:[NSString class]] && [(NSString *)value hasPrefix:@"system:"]) {
        if (@available(iOS 13.0, *)) {
            UIImage *image = [UIImage systemImageNamed:[(NSString *)value substringFromIndex:7]];
            if (image) {
                return image;
            }
        }
        CYLLogInvalidConfigurationValue(CYLTabBarItemImage, value);
    }
    return value;
}

/// [EN] A path in the main bundle for a relative path or file name; the path itself otherwise.
/// [CN] 相对路径或文件名对应 main bundle 中的路径；其他情况返回原路径。
static NSString *CYLMainBundlePath(NSString *path) {
    if (path.length == 0 || [path isAbsolutePath]) {
        return path;
    }
    NSString *bundled = [[NSBundle mainBundle].resourcePath stringByAppendingPathComponent:path];
    if ([[NSFileManager defaultManager] fileExistsAtPath:bundled]) {
        return bundled;
    }
    NSString *extension = path.pathExtension;
    NSString *found = [[NSBundle mainBundle] pathForResource:path.lastPathComponent.stringByDeletingPathExtension
                                                      ofType:extension.length > 0 ? extension : nil];
    return found ?: path;
}

static BOOL CYLIsRemoteURL(NSURL *URL) {
    NSString *scheme = URL.scheme.lowercaseString;
    return ([scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"]) && URL.host.length > 0;
}

static BOOL CYLFileExists(NSString *path) {
    BOOL isDirectory = NO;
    return path.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory] && !isDirectory;
}

/*!
 * [EN] A local Lottie file that Lottie can read (B17): a .json file must be a JSON object with "layers", a .lottie file a
 *      zip archive; other names are left to Lottie. A broken animation never reaches Lottie, whose parsers may assert.
 * [CN] Lottie 可以读取的本地 Lottie 文件（B17）：.json 文件必须是含有 "layers" 的 JSON 对象，.lottie 文件必须是 zip 压缩包；其他文件名交给 Lottie。
 *      损坏的动画不会传给 Lottie（其解析器可能触发断言）。
 */
static BOOL CYLIsReadableLottieFile(NSString *path) {
    NSString *extension = path.pathExtension.lowercaseString;
    // [EN] FIX: issue #605 — a ".gif" must start with a GIF signature (B30). [CN] ".gif" 文件必须以 GIF 签名开头（B30）。
    if ([extension isEqualToString:@"gif"]) {
        NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
        NSData *head = [handle readDataOfLength:6];
        [handle closeFile];
        return head.length == 6 && (memcmp(head.bytes, "GIF87a", 6) == 0 || memcmp(head.bytes, "GIF89a", 6) == 0);
    }
    if ([extension isEqualToString:@"lottie"]) {
        NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
        NSData *head = [handle readDataOfLength:4];
        [handle closeFile];
        return head.length == 4 && memcmp(head.bytes, "PK\x03\x04", 4) == 0;
    }
    if (![extension isEqualToString:@"json"]) {
        return YES;
    }
    NSData *data = [NSData dataWithContentsOfFile:path];
    id animation = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL] : nil;
    return [animation isKindOfClass:[NSDictionary class]] && [animation[@"layers"] isKindOfClass:[NSArray class]];
}

/*!
 * [EN] An NSURL from a URL, a URL string, a path or a file name in the main bundle: only http(s) URLs and local files
 *      that exist; anything else is nil (B13).
 * [CN] 将 URL、URL 字符串、路径或 main bundle 中的文件名转换为 NSURL：只接受 http(s) URL 与存在的本地文件，其他情况返回 nil（B13）。
 */
static NSURL *_Nullable CYLURLValue(id value) {
    NSURL *URL = [value isKindOfClass:[NSURL class]] ? value : nil;
    if ([value isKindOfClass:[NSString class]]) {
        // [EN] FIX: B21: an empty string is no URL; +fileURLWithPath: requires a non-empty path.
        // [CN] 修复 B21：空字符串不是 URL；+fileURLWithPath: 要求非空路径。
        NSString *path = [(NSString *)value length] > 0 ? CYLMainBundlePath(value) : nil;
        NSURL *parsed = [NSURL URLWithString:value];
        if (parsed.scheme.length > 1) {
            URL = parsed;
        } else {
            URL = path.length > 0 ? [NSURL fileURLWithPath:path] : nil;
        }
    }
    if (CYLIsRemoteURL(URL) || (URL.isFileURL && CYLFileExists(URL.path))) {
        return URL;
    }
    return nil;
}

/*!
 * [EN] An icon for `CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL`, which take the sources of
 *      `-setTabBarItemIcon:selectedIcon:size:atIndex:` (B13): a UIImage (kept); an NSURL or URL string, kept when it is
 *      http(s) or a local file that exists; an absolute path, kept when the file exists; any other string is a file
 *      name in the main bundle (its path) or an image name (kept: a missing image only leaves the tab's own icon, B14).
 *      Other URL schemes and other types are nil.
 * [CN] `CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL` 的图标，接受 `-setTabBarItemIcon:selectedIcon:size:atIndex:` 的来源（B13）：
 *      UIImage（保留）；NSURL 或 URL 字符串，为 http(s) 或存在的本地文件时保留；绝对路径，文件存在时保留；其他字符串为 main bundle 中的
 *      文件名（转换为路径）或图片名（保留：图片不存在只会让 Tab 保持自身图标，B14）。其他 URL scheme 与其他类型返回 nil。
 */
static id _Nullable CYLImageURLValue(id value) {
    if ([value isKindOfClass:[UIImage class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSURL class]]) {
        return CYLURLValue(value);
    }
    if (![value isKindOfClass:[NSString class]] || [(NSString *)value length] == 0) {
        return nil;
    }
    NSString *string = value;
    NSURL *parsed = [NSURL URLWithString:string];
    if (parsed.scheme.length > 1) {
        NSURL *URL = CYLURLValue(parsed);
        return URL ? (URL.isFileURL ? URL.path : string) : nil;
    }
    if ([string isAbsolutePath]) {
        return CYLFileExists(string) ? string : nil;
    }
    NSString *bundled = CYLMainBundlePath(string);
    return CYLFileExists(bundled) ? bundled : string;
}

/// [EN] "#RGB", "#RRGGBB" or "#RRGGBBAA" (the "#" is optional). [CN] "#RGB"、"#RRGGBB" 或 "#RRGGBBAA"（"#" 可省略）。
static UIColor *_Nullable CYLColorFromHexString(NSString *string) {
    NSString *hex = [[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]
                     stringByReplacingOccurrencesOfString:@"#" withString:@""];
    if (hex.length == 3) {
        hex = [NSString stringWithFormat:@"%C%C%C%C%C%C", [hex characterAtIndex:0], [hex characterAtIndex:0], [hex characterAtIndex:1],
               [hex characterAtIndex:1], [hex characterAtIndex:2], [hex characterAtIndex:2]];
    }
    if (hex.length == 6) {
        hex = [hex stringByAppendingString:@"FF"];
    }
    unsigned int rgba = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hex];
    if (hex.length != 8 || ![scanner scanHexInt:&rgba] || !scanner.isAtEnd) {
        return nil;
    }
    return [UIColor colorWithRed:((rgba >> 24) & 0xFF) / 255.0
                           green:((rgba >> 16) & 0xFF) / 255.0
                            blue:((rgba >> 8) & 0xFF) / 255.0
                           alpha:(rgba & 0xFF) / 255.0];
}

/// [EN] A Protobuf text map: `{ key: "a" value: "b" }` entries (one entry, or a list of them) become one dictionary.
/// [CN] Protobuf 文本格式的 map：`{ key: "a" value: "b" }` 条目（一个或一组）转换为一个字典。
static id CYLDictionaryFromMapEntries(id value) {
    NSArray *entries = [value isKindOfClass:[NSArray class]] ? value : nil;
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = value;
        BOOL isEntry = dictionary.count == 2 && dictionary[@"key"] && dictionary[@"value"];
        entries = isEntry ? @[ dictionary ] : nil;
    }
    if (!entries) {
        return value;
    }
    NSMutableDictionary *map = [NSMutableDictionary dictionary];
    for (id entry in entries) {
        if (![entry isKindOfClass:[NSDictionary class]] || !entry[@"key"] || !entry[@"value"]) {
            return value;
        }
        map[entry[@"key"]] = entry[@"value"];
    }
    return map;
}

static id CYLDarkColorsValue(id value, NSString *key) {
    value = CYLDictionaryFromMapEntries(value);
    if (![value isKindOfClass:[NSDictionary class]]) {
        return value;
    }
    NSMutableDictionary *colors = [NSMutableDictionary dictionary];
    NSDictionary *dictionary = value;
    for (id keypath in dictionary) {
        id color = dictionary[keypath];
        if ([color isKindOfClass:[NSString class]]) {
            color = CYLColorFromHexString(color);
        }
        if ([color isKindOfClass:[UIColor class]]) {
            colors[keypath] = color;
        } else {
            CYLLogInvalidConfigurationValue(key, dictionary[keypath]);
        }
    }
    return colors;
}

/*!
 * [EN] `CYLTabBarAnimationOptions` from a configuration value: a dictionary (or Protobuf map entries) of option name ->
 *      string; numbers become strings, other values are dropped with a warning. nil when it is not a dictionary (B28).
 * [CN] 配置值中的 `CYLTabBarAnimationOptions`：选项名 -> 字符串的字典（或 Protobuf 的 map 条目）；数字转为字符串，其他值丢弃并警告。
 *      不是字典时为 nil（B28）。
 */
static NSDictionary<NSString *, NSString *> *_Nullable CYLAnimationOptionsValue(id value) {
    value = CYLDictionaryFromMapEntries(value);
    if (![value isKindOfClass:[NSDictionary class]]) {
        CYLLogInvalidConfigurationValue(CYLTabBarAnimationOptions, value);
        return nil;
    }
    NSMutableDictionary<NSString *, NSString *> *options = [NSMutableDictionary dictionary];
    [(NSDictionary *)value enumerateKeysAndObjectsUsingBlock:^(id name, id option, BOOL *stop) {
        NSString *text = [option isKindOfClass:[NSString class]] ? option : ([option isKindOfClass:[NSNumber class]] ? [option stringValue] : nil);
        if ([name isKindOfClass:[NSString class]] && [(NSString *)name length] > 0 && text.length > 0) {
            options[name] = text;
        } else {
            CYLLogInvalidConfigurationValue(CYLTabBarAnimationOptions, option);
        }
    }];
    return [options copy];
}

/*!
 * [EN] Writes `options` into the tab's animation URLs with `CYLTabBarAnimationURLWithOptions()`: every URL key that has
 *      a value, and, for a file path without a URL, a file URL of that path under the matching URL key (the URL wins
 *      over the path in the library, so the path may stay).
 * [CN] 用 `CYLTabBarAnimationURLWithOptions()` 把 `options` 写入 Tab 的动画 URL：每个有值的 URL 键；只有文件路径而没有 URL 时，在对应的
 *      URL 键下写入该路径的 file URL（库中 URL 优先于路径，路径可以保留）。
 */
static void CYLApplyAnimationOptions(NSMutableDictionary *item, NSDictionary<NSString *, NSString *> *options) {
    if (options.count == 0) {
        return;
    }
    NSArray<NSArray<NSString *> *> *pairs = @[
        @[ CYLTabBarAnimationURL, CYLTabBarAnimationFilePath ], @[ CYLTabBarAnimationDarkURL, CYLTabBarAnimationDarkFilePath ],
        @[ CYLConfigurationLottieURLKey, CYLConfigurationLottieFilePathKey ], @[ CYLConfigurationLottieDarkURLKey, CYLConfigurationLottieDarkFilePathKey ],
        @[ CYLConfigurationPAGURLKey, CYLConfigurationPAGFilePathKey ], @[ CYLConfigurationPAGDarkURLKey, CYLConfigurationPAGDarkFilePathKey ],
        @[ CYLConfigurationRiveURLKey, CYLConfigurationRiveFilePathKey ], @[ CYLConfigurationRiveDarkURLKey, CYLConfigurationRiveDarkFilePathKey ],
        @[ CYLConfigurationGIFURLKey, CYLConfigurationGIFFilePathKey ], @[ CYLConfigurationGIFDarkURLKey, CYLConfigurationGIFDarkFilePathKey ],
    ];
    for (NSArray<NSString *> *pair in pairs) {
        NSURL *URL = [item[pair[0]] isKindOfClass:[NSURL class]] ? item[pair[0]] : nil;
        NSString *path = [item[pair[1]] isKindOfClass:[NSString class]] ? item[pair[1]] : nil;
        if (!URL && path.length > 0) {
            URL = [NSURL fileURLWithPath:path];
        }
        NSURL *withOptions = CYLTabBarAnimationURLWithOptions(URL, options);
        if (withOptions) {
            item[pair[0]] = withOptions;
        }
    }
}

/*!
 * [EN] `CYLTabBarControllerTabBarItemAnimationSpeed` from a configuration value: a finite number above 0 (an NSNumber,
 *      or a numeric string from a file); nil otherwise (B28).
 * [CN] 配置值中的 `CYLTabBarControllerTabBarItemAnimationSpeed`：大于 0 的有限数字（NSNumber，或文件中的数字字符串）；否则为 nil（B28）。
 */
static NSNumber *_Nullable CYLAnimationSpeedValue(id value) {
    NSNumber *number = nil;
    if ([value isKindOfClass:[NSNumber class]]) {
        number = value;
    } else if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSScanner *scanner = [NSScanner scannerWithString:text];
        double parsed = 0;
        if (text.length > 0 && [scanner scanDouble:&parsed] && scanner.isAtEnd) {
            number = @(parsed);
        }
    }
    double speed = number.doubleValue;
    return (number && isfinite(speed) && speed > 0) ? number : nil;
}

/// [EN] Every key the library reads. [CN] 本库读取的所有键。
static NSArray<NSString *> *CYLKnownConfigurationKeys(void) {
    return @[ CYLTabBarControllerViewControllers, CYLTabBarControllerTabBarItemsAttributes, CYLTabBarControllerImageInsets,
              CYLTabBarControllerTitlePositionAdjustment, CYLTabBarControllerStyleType, CYLTabBarControllerContext,
              CYLTabBarControllerPageRegistry, CYLTabBarControllerPageResolver, CYLTabBarControllerPageLookupOrder,
              CYLTabBarControllerAutomaticPageRegistration, CYLTabBarControllerTabBarItemAnimationSpeed,
              CYLTabBarControllerThemes, CYLTabBarControllerThemeIdentifier, CYLTabBarControllerDarkThemeIdentifier,
              CYLTabBarControllerThemeManagerName ];
}

static NSArray<NSString *> *CYLKnownItemKeys(void) {
    return @[ CYLTabBarItemTitle, CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLTabBarItemDarkImage,
              CYLTabBarItemSelectedDarkImage, CYLTabBarItemImageURL, CYLTabBarItemSelectedImageURL, CYLTabBarItemImageURLSize,
              CYLTabBarItemImageInsets, CYLTabBarItemTitlePositionAdjustment, CYLTabBarItemImagePositionAdjustment,
              CYLConfigurationLottieFilePathKey, CYLConfigurationLottieURLKey, CYLConfigurationLottieSizeKey, CYLTabBarItemIdentifier, CYLConfigurationLottieDarkURLKey,
              CYLConfigurationLottieDarkFilePathKey, CYLConfigurationLottieDarkColorsKey, CYLTabBarItemPageIdentifier,
              CYLTabBarItemPageParameters, CYLTabBarItemPlatforms, CYLTabBarItemMinimumAppVersion, CYLTabBarItemSelectedTitle, CYLTabBarItemTitleColor, CYLTabBarItemSelectedTitleColor,
              CYLTabBarItemIconColor, CYLTabBarItemSelectedIconColor, CYLTabBarItemSelectedBackgroundColor, CYLTabBarItemBackgroundColor,
              CYLTabBarItemTitleFont, CYLTabBarItemSelectedTitleFont, CYLTabBarItemAccessibilityIdentifier, CYLTabBarItemAccessibilityLabel,
              CYLTabBarItemAccessibilityHint,
              // [EN] Tab animations (#604, #752, #605): the generic keys, the options, Lottie's loop flag, PAG, Rive and GIF.
              // [CN] Tab 动画（#604、#752、#605）：通用键、选项、Lottie 的循环开关、PAG、Rive 与 GIF。
              CYLTabBarAnimationURL, CYLTabBarAnimationFilePath, CYLTabBarAnimationSize, CYLTabBarAnimationDarkURL,
              CYLTabBarAnimationDarkFilePath, CYLTabBarAnimationDarkColors, CYLTabBarAnimationColors, CYLTabBarAnimationOptions,
              CYLConfigurationLottieLoopsWhenUnselectedKey,
              CYLConfigurationPAGURLKey, CYLConfigurationPAGFilePathKey, CYLConfigurationPAGSizeKey, CYLConfigurationPAGDarkURLKey,
              CYLConfigurationPAGDarkFilePathKey, CYLConfigurationRiveURLKey, CYLConfigurationRiveFilePathKey, CYLConfigurationRiveSizeKey,
              CYLConfigurationRiveDarkURLKey, CYLConfigurationRiveDarkFilePathKey, CYLConfigurationRiveDarkColorsKey,
              CYLConfigurationGIFURLKey, CYLConfigurationGIFFilePathKey, CYLConfigurationGIFSizeKey, CYLConfigurationGIFDarkURLKey,
              CYLConfigurationGIFDarkFilePathKey ];
}

#if defined(DEBUG) || defined(BETA)
/// [EN] Edit distance, case-insensitive (keys are at most ~50 characters); DEBUG hints only. [CN] 不区分大小写的编辑距离（键最多约 50 个字符），仅用于 DEBUG 提示。
static NSUInteger CYLEditDistance(NSString *a, NSString *b) {
    a = a.lowercaseString;
    b = b.lowercaseString;
    NSUInteger m = MIN(a.length, (NSUInteger)64), n = MIN(b.length, (NSUInteger)64);
    NSUInteger row[65];
    for (NSUInteger j = 0; j <= n; j++) {
        row[j] = j;
    }
    for (NSUInteger i = 1; i <= m; i++) {
        NSUInteger diagonal = row[0];
        row[0] = i;
        for (NSUInteger j = 1; j <= n; j++) {
            NSUInteger above = row[j];
            NSUInteger cost = ([a characterAtIndex:i - 1] == [b characterAtIndex:j - 1]) ? 0 : 1;
            row[j] = MIN(MIN(row[j] + 1, row[j - 1] + 1), diagonal + cost);
            diagonal = above;
        }
    }
    return row[n];
}
#endif

/*!
 * [EN] DEBUG: names the closest known key of a "CYL..." key the library does not read, e.g. a typo such as
 *      `CYLTabBarItemTitel` (B11). The key itself is kept: the app may read keys of its own.
 * [CN] DEBUG：对本库不读取的 "CYL..." 键，提示最接近的已知键，例如 `CYLTabBarItemTitel` 这样的拼写错误（B11）。该键本身会保留：App 可能
 *      读取自己的键。
 */
static void CYLWarnUnknownKeys(NSDictionary *dictionary, NSArray<NSString *> *knownKeys) {
#if defined(DEBUG) || defined(BETA)
    for (id key in dictionary) {
        if (![key isKindOfClass:[NSString class]] || ![(NSString *)key hasPrefix:@"CYL"] || [knownKeys containsObject:key]) {
            continue;
        }
        NSString *closest = nil;
        NSUInteger best = NSUIntegerMax;
        for (NSString *known in knownKeys) {
            NSUInteger distance = CYLEditDistance(key, known);
            if (distance < best) {
                best = distance;
                closest = known;
            }
        }
        NSLog(@"🟡 CYLTabBarController configuration: unknown key %@%@.", key,
              best <= 3 ? [NSString stringWithFormat:@"; did you mean %@?", closest] : @"");
    }
#endif
}

/*!
 * [EN] `CYLTabBarItemIdentifier` must be unique: lookups by identifier would find only the first tab. Later duplicates
 *      become "identifier_2", "identifier_3"... (B12).
 * [CN] `CYLTabBarItemIdentifier` 必须唯一：按标识查找只能找到第一个 Tab。后出现的重复标识改为「标识_2」「标识_3」……（B12）。
 */
static void CYLMakeIdentifiersUnique(NSMutableArray<NSDictionary *> *items) {
    NSMutableSet<NSString *> *used = [NSMutableSet set];
    for (NSUInteger i = 0; i < items.count; i++) {
        NSString *identifier = items[i][CYLTabBarItemIdentifier];
        if (!identifier) {
            continue;
        }
        NSString *unique = identifier;
        for (NSUInteger suffix = 2; [used containsObject:unique]; suffix++) {
            unique = [NSString stringWithFormat:@"%@_%lu", identifier, (unsigned long)suffix];
        }
        if (![unique isEqualToString:identifier]) {
#if defined(DEBUG) || defined(BETA)
            NSLog(@"🟡 CYLTabBarController configuration: duplicate identifier %@ renamed %@.", identifier, unique);
#endif
            NSMutableDictionary *item = [items[i] mutableCopy];
            item[CYLTabBarItemIdentifier] = unique;
            // The page ID falls back to the tab ID: keep the original one, so the page is still found (B12).
            // 页面 ID 默认取 Tab 标识：保留原来的标识，以便仍能找到页面（B12）。
            if ([item[CYLTabBarItemPageIdentifier] length] == 0) {
                item[CYLTabBarItemPageIdentifier] = identifier;
            }
            items[i] = item;
        }
        [used addObject:unique];
    }
}

/// [EN] A UIColor, or "#RGB" / "#RRGGBB" / "#RRGGBBAA"; nil otherwise (B19). [CN] UIColor，或 "#RGB" / "#RRGGBB" / "#RRGGBBAA"；否则返回 nil（B19）。
static UIColor *_Nullable CYLColorValue(id value) {
    if ([value isKindOfClass:[UIColor class]]) {
        return value;
    }
    return [value isKindOfClass:[NSString class]] ? CYLColorFromHexString(value) : nil;
}

static UIFontWeight CYLFontWeightNamed(NSString *name, BOOL *found) {
    NSDictionary<NSString *, NSNumber *> *weights = @{
        @"ultralight" : @(UIFontWeightUltraLight), @"thin" : @(UIFontWeightThin), @"light" : @(UIFontWeightLight),
        @"regular" : @(UIFontWeightRegular), @"medium" : @(UIFontWeightMedium), @"semibold" : @(UIFontWeightSemibold),
        @"bold" : @(UIFontWeightBold), @"heavy" : @(UIFontWeightHeavy), @"black" : @(UIFontWeightBlack),
    };
    NSNumber *weight = weights[name.lowercaseString];
    *found = (weight != nil);
    return weight ? (UIFontWeight)weight.doubleValue : UIFontWeightRegular;
}

/*!
 * [EN] A font for `CYLTabBarItemTitleFont` / `CYLTabBarItemSelectedTitleFont` (B20): a UIFont; a number (a system font
 *      of that size); "bold:15" (a system font with a weight: ultralight, thin, light, regular, medium, semibold, bold,
 *      heavy, black); "Menlo-Regular:12" (a font by name); or {name, size, weight}. The size must be finite and between
 *      1 and 200; an unknown font name gives nil.
 * [CN] `CYLTabBarItemTitleFont` / `CYLTabBarItemSelectedTitleFont` 的字体（B20）：UIFont；数字（该字号的系统字体）；"bold:15"（指定字重的
 *      系统字体：ultralight、thin、light、regular、medium、semibold、bold、heavy、black）；"Menlo-Regular:12"（按名称的字体）；或
 *      {name, size, weight}。字号必须是 1 到 200 之间的有限值；字体名称不存在时返回 nil。
 */
static UIFont *_Nullable CYLFontValue(id value) {
    if ([value isKindOfClass:[UIFont class]]) {
        return value;
    }
    NSString *name = nil;
    NSString *weightName = nil;
    double size = 0;
    if ([value isKindOfClass:[NSNumber class]]) {
        size = [value doubleValue];
    } else if ([value isKindOfClass:[NSString class]]) {
        NSString *string = [(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        NSRange colon = [string rangeOfString:@":" options:NSBackwardsSearch];
        NSString *sizeText = colon.location == NSNotFound ? string : [string substringFromIndex:NSMaxRange(colon)];
        NSScanner *scanner = [NSScanner scannerWithString:sizeText];
        if (![scanner scanDouble:&size] || !scanner.isAtEnd) {
            return nil;
        }
        if (colon.location != NSNotFound) {
            name = [string substringToIndex:colon.location];
        }
    } else if ([value isKindOfClass:[NSDictionary class]]) {
        id sizeValue = value[@"size"];
        size = [sizeValue respondsToSelector:@selector(doubleValue)] ? [sizeValue doubleValue] : 0;
        name = [value[@"name"] isKindOfClass:[NSString class]] ? value[@"name"] : nil;
        weightName = [value[@"weight"] isKindOfClass:[NSString class]] ? value[@"weight"] : nil;
    } else {
        return nil;
    }
    if (!isfinite(size) || size < 1 || size > 200) {
        return nil;
    }
    BOOL isWeight = NO;
    UIFontWeight weight = CYLFontWeightNamed(weightName ?: name ?: @"regular", &isWeight);
    if (name.length > 0 && !isWeight) {
        return [UIFont fontWithName:name size:size];
    }
    return [UIFont systemFontOfSize:size weight:weight];
}

/// [EN] A string, or a number as a string; nil for anything else (B5). [CN] 字符串，或转换为字符串的数字；其他类型返回 nil（B5）。
static NSString *_Nullable CYLStringValue(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    return nil;
}

/*!
 * [EN] `CYLTabBarItemPlatforms` as lowercase names: a list of strings, or one comma-separated string ("ios, android").
 *      Anything else is removed with a warning, so the tab shows on every platform (B23).
 * [CN] 将 `CYLTabBarItemPlatforms` 转为小写名称列表：字符串数组，或逗号分隔的字符串（"ios, android"）。其他值会被移除并输出警告，该 Tab
 *      在所有平台显示（B23）。
 */
static NSArray<NSString *> *_Nullable CYLPlatformsValue(id value) {
    NSArray *names = [value isKindOfClass:[NSString class]] ? [(NSString *)value componentsSeparatedByString:@","] : value;
    if (![names isKindOfClass:[NSArray class]]) {
        CYLLogInvalidConfigurationValue(CYLTabBarItemPlatforms, value);
        return nil;
    }
    NSMutableArray<NSString *> *platforms = [NSMutableArray array];
    for (id name in names) {
        NSString *platform = [name isKindOfClass:[NSString class]]
            ? [(NSString *)name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].lowercaseString : nil;
        if (platform.length == 0) {
            CYLLogInvalidConfigurationValue(CYLTabBarItemPlatforms, value);
            return nil;
        }
        [platforms addObject:platform];
    }
    return platforms.count > 0 ? platforms : nil;
}

/*!
 * [EN] The numbers of a version string ("2.10.1" -> 2, 10, 1), or nil when it has none or a part is not a number:
 *      "2.10" is newer than "2.9", which a string comparison gets wrong (B24).
 * [CN] 版本字符串中的数字（"2.10.1" -> 2、10、1）；没有数字或某部分不是数字时返回 nil："2.10" 比 "2.9" 新，字符串比较会算错（B24）。
 */
static NSArray<NSNumber *> *_Nullable CYLVersionNumbers(NSString *version) {
    NSString *trimmed = [version stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length == 0) {
        return nil;
    }
    NSMutableArray<NSNumber *> *numbers = [NSMutableArray array];
    for (NSString *part in [trimmed componentsSeparatedByString:@"."]) {
        NSScanner *scanner = [NSScanner scannerWithString:part];
        long long number = 0;
        if (![scanner scanLongLong:&number] || !scanner.isAtEnd || number < 0) {
            return nil;
        }
        [numbers addObject:@(number)];
    }
    return numbers;
}

/// [EN] Whether `version` is lower than `minimum` (missing parts count as 0). [CN] `version` 是否低于 `minimum`（缺少的部分视为 0）。
static BOOL CYLVersionIsLower(NSArray<NSNumber *> *version, NSArray<NSNumber *> *minimum) {
    for (NSUInteger i = 0; i < MAX(version.count, minimum.count); i++) {
        long long a = i < version.count ? version[i].longLongValue : 0;
        long long b = i < minimum.count ? minimum[i].longLongValue : 0;
        if (a != b) {
            return a < b;
        }
    }
    return NO;
}

/*!
 * [EN] Why a tab is left out on this device, or nil: not for iOS (`CYLTabBarItemPlatforms`), or a newer app needed
 *      (`CYLTabBarItemMinimumAppVersion`). An invalid minimum version is ignored with a warning (B24).
 * [CN] 该 Tab 在本设备上被排除的原因，没有则为 nil：不适用于 iOS（`CYLTabBarItemPlatforms`），或需要更新的 App 版本
 *      （`CYLTabBarItemMinimumAppVersion`）。无效的最低版本会被忽略并输出警告（B24）。
 */
/*!
 * [EN] A BOOL from a configuration value: NSNumber, or "true" / "false", "yes" / "no", "1" / "0" (any case). nil otherwise.
 * [CN] 配置值中的 BOOL：NSNumber，或 "true" / "false"、"yes" / "no"、"1" / "0"（不区分大小写）。否则为 nil。
 */
static NSNumber *_Nullable CYLBoolValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return @([value boolValue]);
    }
    if ([value isKindOfClass:[NSString class]]) {
        NSString *text = [[(NSString *)value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString];
        if ([@[ @"true", @"yes", @"1" ] containsObject:text]) {
            return @(YES);
        }
        if ([@[ @"false", @"no", @"0" ] containsObject:text]) {
            return @(NO);
        }
    }
    return nil;
}

/*!
 * [EN] The lookup order from a configuration value: an array of strings, or a comma-separated string, of "instance",
 *      "resolver", "shared", "automatic" (any case, each once). Unknown entries are dropped with a warning; nil when
 *      nothing is left (C18), so the default order is used.
 * [CN] 配置值中的查找顺序：由 "instance"、"resolver"、"shared"、"automatic"（不区分大小写，各一次）组成的数组或逗号分隔的字符串。
 *      未知项会被丢弃并输出警告；没有剩余项时为 nil（C18），即使用默认顺序。
 */
static NSArray<CYLTabBarPageSource> *_Nullable CYLPageLookupOrderValue(id value) {
    NSArray *entries = nil;
    if ([value isKindOfClass:[NSString class]]) {
        entries = [(NSString *)value componentsSeparatedByString:@","];
    } else if ([value isKindOfClass:[NSArray class]]) {
        entries = value;
    }
    NSMutableArray<CYLTabBarPageSource> *order = [NSMutableArray array];
    for (id entry in entries) {
        NSString *name = [entry isKindOfClass:[NSString class]]
            ? [[(NSString *)entry stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] lowercaseString] : @"";
        if (name.length > 0 && [CYLTabBarPageRegistry.defaultPageLookupOrder containsObject:name] && ![order containsObject:name]) {
            [order addObject:name];
        } else if (name.length > 0 || ![entry isKindOfClass:[NSString class]]) {
            CYLLogInvalidConfigurationValue(CYLTabBarControllerPageLookupOrder, entry);
        }
    }
    if (order.count == 0) {
        CYLLogInvalidConfigurationValue(CYLTabBarControllerPageLookupOrder, value);
        return nil;
    }
    return [order copy];
}

static NSString *_Nullable CYLExclusionReason(NSDictionary *item) {
    NSArray<NSString *> *platforms = item[CYLTabBarItemPlatforms];
    if (platforms && ![platforms containsObject:@"ios"]) {
        return [NSString stringWithFormat:@"its platforms are %@", [platforms componentsJoinedByString:@", "]];
    }
    NSString *minimum = item[CYLTabBarItemMinimumAppVersion];
    if (minimum) {
        NSArray<NSNumber *> *minimumNumbers = CYLVersionNumbers(minimum);
        NSString *appVersion = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
        NSArray<NSNumber *> *appNumbers = [appVersion isKindOfClass:[NSString class]] ? CYLVersionNumbers(appVersion) : nil;
        if (!minimumNumbers) {
            CYLLogInvalidConfigurationValue(CYLTabBarItemMinimumAppVersion, minimum);
        } else if (appNumbers && CYLVersionIsLower(appNumbers, minimumNumbers)) {
            return [NSString stringWithFormat:@"it needs version %@ (this app is %@)", minimum, appVersion];
        }
    }
    return nil;
}

/*!
 * [EN] The attributes of one tab, each known key checked for its type: a title that is a list or a dictionary, or a
 *      null, used to reach UIKit and crash with an unrecognized selector (B5, B6). Wrong values are removed, so the tab
 *      takes the default for that key. Keys the library does not know are kept for the app.
 * [CN] 一个 Tab 的属性，每个已知键都检查类型：以前标题为数组或字典、或值为 null 时，会传给 UIKit 并因 unrecognized selector 崩溃（B5、B6）。
 *      错误的值会被移除，该键使用默认值。本库不认识的键保留给 App 使用。
 */
static NSDictionary *CYLNormalizedItemAttributes(NSDictionary *attributes) {
    NSMutableDictionary *item = [NSMutableDictionary dictionary];
    for (id key in attributes) {
        id value = attributes[key];
        if (![key isKindOfClass:[NSString class]] || [value isKindOfClass:[NSNull class]]) {
            continue;
        }
        item[key] = value;
    }
    for (NSString *key in @[ CYLTabBarItemTitle, CYLTabBarItemSelectedTitle, CYLTabBarItemIdentifier, CYLTabBarItemPageIdentifier,
                              CYLTabBarItemMinimumAppVersion, CYLTabBarItemAccessibilityIdentifier, CYLTabBarItemAccessibilityLabel, CYLTabBarItemAccessibilityHint ]) {
        if (item[key] && !CYLStringValue(item[key])) {
            CYLLogInvalidConfigurationValue(key, item[key]);
        }
        item[key] = CYLStringValue(item[key]);
    }
    for (NSString *key in @[ CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLTabBarItemDarkImage, CYLTabBarItemSelectedDarkImage ]) {
        id value = item[key];
        if (value && ![value isKindOfClass:[NSString class]] && ![value isKindOfClass:[UIImage class]]) {
            CYLLogInvalidConfigurationValue(key, value);
            value = nil;
        }
        item[key] = value ? CYLImageValue(value) : nil;
    }
    if (item[CYLTabBarItemImageInsets]) {
        item[CYLTabBarItemImageInsets] = CYLEdgeInsetsValue(item[CYLTabBarItemImageInsets], CYLTabBarItemImageInsets);
    }
    for (NSString *key in @[ CYLTabBarItemTitlePositionAdjustment, CYLTabBarItemImagePositionAdjustment ]) {
        if (item[key]) {
            item[key] = CYLOffsetValue(item[key], key);
        }
    }
    for (NSString *key in @[ CYLTabBarItemImageURLSize, CYLConfigurationLottieSizeKey, CYLTabBarAnimationSize, CYLConfigurationPAGSizeKey,
                              CYLConfigurationRiveSizeKey, CYLConfigurationGIFSizeKey ]) {
        if (item[key]) {
            item[key] = CYLSizeValue(item[key], key);
        }
    }
    // [EN] Animation URLs: Lottie's, the generic ones (any library) and PAG's / Rive's; a local file must exist, and a
    //      Lottie file must be readable (B17). [CN] 动画 URL：Lottie、通用（任何动画库）与 PAG / Rive；本地文件必须存在，Lottie 文件必须可读（B17）。
    for (NSString *key in @[ CYLTabBarItemImageURL, CYLTabBarItemSelectedImageURL, CYLConfigurationLottieURLKey, CYLConfigurationLottieDarkURLKey,
                              CYLTabBarAnimationURL, CYLTabBarAnimationDarkURL, CYLConfigurationPAGURLKey, CYLConfigurationPAGDarkURLKey,
                              CYLConfigurationRiveURLKey, CYLConfigurationRiveDarkURLKey, CYLConfigurationGIFURLKey, CYLConfigurationGIFDarkURLKey ]) {
        id value = item[key];
        if (!value) {
            continue;
        }
        BOOL isImage = [key isEqualToString:CYLTabBarItemImageURL] || [key isEqualToString:CYLTabBarItemSelectedImageURL];
        id checked = isImage ? CYLImageURLValue(value) : CYLURLValue(value);
        if (!isImage && [(NSURL *)checked isFileURL] && !CYLIsReadableLottieFile([(NSURL *)checked path])) {
            checked = nil;
        }
        if (!checked) {
            CYLLogInvalidConfigurationValue(key, value);
        }
        item[key] = checked;
    }
    for (NSString *key in @[ CYLConfigurationLottieFilePathKey, CYLConfigurationLottieDarkFilePathKey, CYLTabBarAnimationFilePath, CYLTabBarAnimationDarkFilePath,
                              CYLConfigurationPAGFilePathKey, CYLConfigurationPAGDarkFilePathKey, CYLConfigurationRiveFilePathKey,
                              CYLConfigurationRiveDarkFilePathKey, CYLConfigurationGIFFilePathKey, CYLConfigurationGIFDarkFilePathKey ]) {
        id value = item[key];
        NSString *path = [value isKindOfClass:[NSString class]] ? CYLMainBundlePath(value) : nil;
        if (value && (!CYLFileExists(path) || !CYLIsReadableLottieFile(path))) {
            CYLLogInvalidConfigurationValue(key, value);
            path = nil;
        }
        item[key] = path;
    }
    for (NSString *key in @[ CYLTabBarItemTitleColor, CYLTabBarItemSelectedTitleColor, CYLTabBarItemIconColor, CYLTabBarItemSelectedIconColor,
                              CYLTabBarItemSelectedBackgroundColor, CYLTabBarItemBackgroundColor ]) {
        if (item[key] && !(item[key] = CYLColorValue(item[key]))) {
            CYLLogInvalidConfigurationValue(key, attributes[key]);
        }
    }
    for (NSString *key in @[ CYLTabBarItemTitleFont, CYLTabBarItemSelectedTitleFont ]) {
        if (item[key] && !(item[key] = CYLFontValue(item[key]))) {
            CYLLogInvalidConfigurationValue(key, attributes[key]);
        }
    }
    if (item[CYLTabBarItemPageParameters]) {
        // Protobuf maps arrive as key / value entries. Protobuf 的 map 以 key / value 条目的形式出现。
        item[CYLTabBarItemPageParameters] = CYLDictionaryFromMapEntries(item[CYLTabBarItemPageParameters]);
    }
    if (item[CYLTabBarItemPageParameters] && ![item[CYLTabBarItemPageParameters] isKindOfClass:[NSDictionary class]]) {
        // Page parameters must be a dictionary (B25). 页面参数必须是字典（B25）。
        CYLLogInvalidConfigurationValue(CYLTabBarItemPageParameters, item[CYLTabBarItemPageParameters]);
        item[CYLTabBarItemPageParameters] = nil;
    }
    if (item[CYLTabBarItemPlatforms]) {
        item[CYLTabBarItemPlatforms] = CYLPlatformsValue(item[CYLTabBarItemPlatforms]);
    }
    CYLWarnUnknownKeys(item, CYLKnownItemKeys());
    for (NSString *key in @[ CYLConfigurationLottieDarkColorsKey, CYLTabBarAnimationDarkColors, CYLTabBarAnimationColors, CYLConfigurationRiveDarkColorsKey ]) {
        if (item[key]) {
            id colors = CYLDarkColorsValue(item[key], key);
            if (![colors isKindOfClass:[NSDictionary class]]) {
                CYLLogInvalidConfigurationValue(key, colors);
                colors = nil;
            }
            item[key] = colors;
        }
    }
    if (item[CYLConfigurationLottieLoopsWhenUnselectedKey]) {
        NSNumber *loops = CYLBoolValue(item[CYLConfigurationLottieLoopsWhenUnselectedKey]);
        if (!loops) {
            CYLLogInvalidConfigurationValue(CYLConfigurationLottieLoopsWhenUnselectedKey, item[CYLConfigurationLottieLoopsWhenUnselectedKey]);
        }
        item[CYLConfigurationLottieLoopsWhenUnselectedKey] = loops;
    }
    if (item[CYLTabBarAnimationOptions]) {
        NSDictionary<NSString *, NSString *> *options = CYLAnimationOptionsValue(item[CYLTabBarAnimationOptions]);
        item[CYLTabBarAnimationOptions] = options;
        CYLApplyAnimationOptions(item, options);
    }
    return item;
}

/*!
 * [EN] View controllers from code: only UIViewController instances, each once. Anything else used to crash in
 *      -setViewControllers:, and UIKit raises when a view controller is added twice (C6, C7).
 * [CN] 代码传入的子控制器：只保留 UIViewController 实例，且每个只保留一次。以前其他对象会在 -setViewControllers: 中崩溃，同一个控制器添加两次
 *      UIKit 会抛出异常（C6、C7）。
 */
static NSArray<UIViewController *> *CYLValidViewControllers(id value) {
    if (![value isKindOfClass:[NSArray class]]) {
        CYLLogInvalidConfigurationValue(CYLTabBarControllerViewControllers, value);
        return nil;
    }
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    for (id viewController in (NSArray *)value) {
        if (![viewController isKindOfClass:[UIViewController class]] || [viewControllers indexOfObjectIdenticalTo:viewController] != NSNotFound) {
            CYLLogInvalidConfigurationValue(CYLTabBarControllerViewControllers, viewController);
            continue;
        }
        [viewControllers addObject:viewController];
    }
    return viewControllers;
}

/*!
 * [EN] A configuration read from a file or a URL must describe at least one tab (B1, B2, D7): a captive Wi-Fi portal
 *      or an error page answers with HTML, which parses as XML without any tab, and used to give an empty tab bar.
 * [CN] 从文件或 URL 读取的配置必须至少描述一个 Tab（B1、B2、D7）：公共 Wi-Fi 登录页或错误页返回的是 HTML，会被解析为没有 Tab 的 XML，
 *      以前会生成空的 TabBar。
 */
static NSError *_Nullable CYLConfigurationTabsError(NSDictionary<NSString *, id> *configuration) {
    id items = configuration[CYLTabBarControllerTabBarItemsAttributes];
    if ([items isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    if ([items isKindOfClass:[NSArray class]]) {
        for (id item in (NSArray *)items) {
            if ([item isKindOfClass:[NSDictionary class]]) {
                return nil;
            }
        }
    }
    return [NSError errorWithDomain:CYLTabBarConfigurationErrorDomain code:CYLTabBarConfigurationErrorNoTabs userInfo:@{
        NSLocalizedDescriptionKey : @"The configuration has no tab: CYLTabBarControllerTabBarItemsAttributes is missing or empty (was an HTML page downloaded instead?).",
    }];
}

/*!
 * [EN] A tab bar controller created from a file or a URL must show at least one tab: when no tab found its page (no
 *      page ID registered, C11), it is an error instead of an empty tab bar.
 * [CN] 由文件或 URL 创建的 TabBarController 必须至少显示一个 Tab：没有任何 Tab 找到页面时（页面 ID 均未注册，C11）返回错误，而不是空的 TabBar。
 */
static NSError *_Nullable CYLConfigurationPagesError(CYLTabBarController *_Nullable tabBarController) {
    if (tabBarController.viewControllers.count > 0) {
        return nil;
    }
    return [NSError errorWithDomain:CYLTabBarConfigurationErrorDomain code:CYLTabBarConfigurationErrorNoPages userInfo:@{
        NSLocalizedDescriptionKey : @"No tab found its page: register the page IDs (CYLTabBarItemPageIdentifier) with CYLTabBarPageRegistry, or adopt CYLTabBarPage.",
    }];
}


#pragma mark - Skins (named values, after QMUI's skins)

/// [EN] Private: the skins of a normalized configuration, for `-cyl_applyConfigurationThemes:`. [CN] 私有：规范化配置中的皮肤，供 `-cyl_applyConfigurationThemes:` 使用。
static NSString *const CYLConfigurationThemesKey = @"_CYLTabBarControllerConfigurationThemes";
static NSString *const CYLConfigurationThemesListKey = @"themes";
static NSString *const CYLConfigurationThemesBaseKey = @"base";
static NSString *const CYLConfigurationThemesDarkKey = @"dark";
static NSString *const CYLConfigurationThemesInitialKey = @"initial";
static NSString *const CYLConfigurationThemesManagerKey = @"manager";

/// [EN] The named values of one skin: a dictionary (a Protobuf map too), without null values. [CN] 一个皮肤的命名值：字典（也可以是 Protobuf map），去掉 null 值。
static NSDictionary<NSString *, id> *_Nullable CYLThemeValuesValue(id value) {
    id map = CYLDictionaryFromMapEntries(value ?: @{});
    if (![map isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    NSMutableDictionary<NSString *, id> *values = [NSMutableDictionary dictionary];
    for (id key in (NSDictionary *)map) {
        id entry = ((NSDictionary *)map)[key];
        if ([key isKindOfClass:[NSString class]] && ![entry isKindOfClass:[NSNull class]]) {
            values[key] = entry;
        }
    }
    return values;
}

/*!
 * [EN] `CYLTabBarControllerThemes`: identifier -> named values, from the dictionary form or the list form (one skin of
 *      the list form also arrives as a dictionary from XML or Protobuf text). nil when there is no valid skin.
 * [CN] `CYLTabBarControllerThemes`：标识 -> 命名值，来自字典形式或列表形式（XML 或 Protobuf 文本中只有一个皮肤时，列表形式也会是字典）。
 *      没有有效皮肤时为 nil。
 */
static NSDictionary<NSString *, NSDictionary<NSString *, id> *> *_Nullable CYLThemesValue(id value) {
    NSArray *list = [value isKindOfClass:[NSArray class]] ? value : nil;
    NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *themes = [NSMutableDictionary dictionary];
    if ([value isKindOfClass:[NSDictionary class]]) {
        if (((NSDictionary *)value)[CYLTabBarThemeIdentifier]) {
            list = @[ value ];
        } else {
            for (id key in (NSDictionary *)value) {
                NSString *identifier = CYLStringValue(key);
                NSDictionary *values = CYLThemeValuesValue(((NSDictionary *)value)[key]);
                if (identifier.length > 0 && values) {
                    themes[identifier] = values;
                } else {
                    CYLLogInvalidConfigurationValue(CYLTabBarControllerThemes, key);
                }
            }
        }
    }
    for (id entry in list) {
        NSDictionary *dictionary = [entry isKindOfClass:[NSDictionary class]] ? entry : nil;
        NSString *identifier = CYLStringValue(dictionary[CYLTabBarThemeIdentifier]);
        NSDictionary *values = CYLThemeValuesValue(dictionary[CYLTabBarThemeValues]);
        if (identifier.length > 0 && values) {
            themes[identifier] = values;
        } else {
            CYLLogInvalidConfigurationValue(CYLTabBarControllerThemes, entry);
        }
    }
    if (themes.count == 0) {
        CYLLogInvalidConfigurationValue(CYLTabBarControllerThemes, value);
        return nil;
    }
    return themes;
}

/*!
 * [EN] A tab with its "@name" values taken from `values` (QMUI's `?attr/name`); the keys that refer to a name are added
 *      to `references`. "@@text" is the literal "@text"; a name missing from `values` drops the key (with a warning).
 * [CN] 用 `values` 替换 Tab 中的 "@name" 值（对应 QMUI 的 `?attr/name`）；引用名称的键记录到 `references`。"@@text" 表示普通文本 "@text"；
 *      `values` 中没有的名称会移除该键（并输出警告）。
 */
static NSDictionary *CYLItemResolvingThemeReferences(NSDictionary *item, NSDictionary<NSString *, id> *values, NSMutableDictionary<NSString *, NSString *> *references) {
    NSMutableDictionary *resolved = [item mutableCopy];
    for (id key in item) {
        id value = item[key];
        if (![key isKindOfClass:[NSString class]] || ![value isKindOfClass:[NSString class]] || ![(NSString *)value hasPrefix:@"@"]) {
            continue;
        }
        NSString *string = value;
        if ([string hasPrefix:@"@@"]) {
            resolved[key] = [string substringFromIndex:1];
            continue;
        }
        NSString *name = [[string substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (name.length == 0) {
            continue;
        }
        references[key] = name;
        id themed = values[name];
        if (themed) {
            resolved[key] = themed;
        } else {
#if defined(DEBUG) || defined(BETA)
            NSLog(@"🟡 CYLTabBarController configuration: no skin gives the value \"%@\" of %@; the key is left out.", name, key);
#endif
            [resolved removeObjectForKey:key];
        }
    }
    return resolved;
}

/// [EN] Whether the screen is in Dark Mode now (iOS 13+). [CN] 屏幕当前是否为深色模式（iOS 13+）。
static BOOL CYLScreenIsDark(void) {
    if (@available(iOS 13.0, *)) {
        return UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark;
    }
    return NO;
}

@interface CYLTabBarConfigurationTheme ()
- (instancetype)initWithIdentifier:(NSString *)identifier values:(NSDictionary<NSString *, id> *)values
                        references:(NSDictionary<id, NSDictionary<NSString *, NSString *> *> *)references NS_DESIGNATED_INITIALIZER;
@end

@implementation CYLTabBarConfigurationTheme {
    /// [EN] Per tab (its identifier, or its position without one): item key -> value name. [CN] 每个 Tab（其标识，没有时为位置）：item 键 -> 值名称。
    NSDictionary<id, NSDictionary<NSString *, NSString *> *> *_references;
}

- (instancetype)initWithIdentifier:(NSString *)identifier values:(NSDictionary<NSString *, id> *)values
                        references:(NSDictionary<id, NSDictionary<NSString *, NSString *> *> *)references {
    if (self = [super init]) {
        _identifier = [identifier copy];
        _values = [values copy];
        _references = [references copy];
    }
    return self;
}

- (nullable id)valueForName:(NSString *)name {
    return [name isKindOfClass:[NSString class]] ? self.values[name] : nil;
}

- (nullable UIColor *)colorForName:(NSString *)name {
    return CYLColorValue([self valueForName:name]);
}

- (nullable UIFont *)fontForName:(NSString *)name {
    id value = [self valueForName:name];
    return value ? CYLFontValue(value) : nil;
}

- (nullable UIImage *)imageForName:(NSString *)name {
    id value = [self valueForName:name];
    if ([value isKindOfClass:[UIImage class]]) {
        return value;
    }
    if (![value isKindOfClass:[NSString class]]) {
        return nil;
    }
    id image = CYLImageValue(value);
    return [image isKindOfClass:[UIImage class]] ? image : [UIImage imageNamed:value];
}

+ (UIColor *)cyl_colorNamed:(NSString *)name inManager:(CYLThemeManager *)manager theme:(id)theme {
    UIColor *color = [theme isKindOfClass:[CYLTabBarConfigurationTheme class]] ? [(CYLTabBarConfigurationTheme *)theme colorForName:name] : nil;
    if (color) {
        return color;
    }
    // [EN] Another kind of theme is current: the first skin of the file that has the color. [CN] 当前是其他类型的主题：使用文件中第一个提供该颜色的皮肤。
    for (id candidate in manager.themes) {
        color = [candidate isKindOfClass:[CYLTabBarConfigurationTheme class]] ? [(CYLTabBarConfigurationTheme *)candidate colorForName:name] : nil;
        if (color) {
            return color;
        }
    }
    return UIColor.clearColor;
}

+ (UIColor *)colorNamed:(NSString *)name {
    NSString *colorName = [name copy];
    return [UIColor cyl_colorWithName:colorName themeProvider:^UIColor *(CYLThemeManager *manager, id identifier, id theme) {
        return [CYLTabBarConfigurationTheme cyl_colorNamed:colorName inManager:manager theme:theme];
    }];
}

+ (UIColor *)colorNamed:(NSString *)name themeManagerName:(__kindof NSObject<NSCopying> *)managerName {
    NSString *colorName = [name copy];
    return [UIColor cyl_colorWithName:colorName themeManagerName:managerName provider:^UIColor *(CYLThemeManager *manager, id identifier, id theme) {
        return [CYLTabBarConfigurationTheme cyl_colorNamed:colorName inManager:manager theme:theme];
    }];
}

#pragma mark CYLTabBarTheme

- (nullable NSArray<NSDictionary<NSString *, id> *> *)cyl_tabBarItemsAttributesForTabBarController:(CYLTabBarController *)tabBarController {
    NSMutableArray<NSDictionary<NSString *, id> *> *items = [NSMutableArray array];
    BOOL themed = NO;
    NSUInteger position = 0;
    for (NSDictionary *item in tabBarController.tabBarItemsAttributes) {
        if (![item isKindOfClass:[NSDictionary class]] || [item[CYLTabBarItemPlusSlotPlaceholderKey] boolValue]) {
            continue;
        }
        NSString *identifier = CYLStringValue(item[CYLTabBarItemIdentifier]);
        NSDictionary<NSString *, NSString *> *references = identifier.length > 0 ? _references[identifier] : _references[@(position)];
        position++;
        NSMutableDictionary *raw = [NSMutableDictionary dictionary];
        for (NSString *key in references) {
            id value = self.values[references[key]];
            if (value) {
                raw[key] = value;
            }
        }
        themed = themed || raw.count > 0;
        // [EN] An empty entry keeps that tab as it is. [CN] 空条目让该 Tab 保持不变。
        [items addObject:raw.count > 0 ? CYLNormalizedItemAttributes(raw) : @{}];
    }
    return themed ? items : nil;
}

- (nullable UITabBarAppearance *)cyl_tabBarAppearanceForTabBarController:(CYLTabBarController *)tabBarController API_AVAILABLE(ios(13.0)) {
    UIColor *background = [self colorForName:CYLTabBarBackgroundColor];
    UIColor *shadow = [self colorForName:CYLTabBarShadowColor];
    UIColor *titleColor = [self colorForName:CYLTabBarItemTitleColor];
    UIColor *selectedTitleColor = [self colorForName:CYLTabBarItemSelectedTitleColor];
    UIColor *iconColor = [self colorForName:CYLTabBarItemIconColor];
    UIColor *selectedIconColor = [self colorForName:CYLTabBarItemSelectedIconColor];
    UIFont *titleFont = [self fontForName:CYLTabBarItemTitleFont];
    UIFont *selectedTitleFont = [self fontForName:CYLTabBarItemSelectedTitleFont] ?: titleFont;
    if (!background && !shadow && !titleColor && !selectedTitleColor && !iconColor && !selectedIconColor && !titleFont && !selectedTitleFont) {
        // [EN] No bar-wide values: the app's own appearance stays. [CN] 没有整个 TabBar 的值：保留 App 自己的外观。
        return nil;
    }
    UITabBarAppearance *appearance = [[UITabBarAppearance alloc] init];
    [appearance configureWithDefaultBackground];
    if (background) {
        appearance.backgroundColor = background;
    }
    if (shadow) {
        appearance.shadowColor = shadow;
    }
    [appearance cyl_applyItemAppearanceWithBlock:^(UITabBarItemAppearance *itemAppearance) {
        NSMutableDictionary *normal = [itemAppearance.normal.titleTextAttributes mutableCopy] ?: [NSMutableDictionary dictionary];
        if (titleColor) {
            normal[NSForegroundColorAttributeName] = titleColor;
        }
        if (titleFont) {
            normal[NSFontAttributeName] = titleFont;
        }
        itemAppearance.normal.titleTextAttributes = normal;
        NSMutableDictionary *selected = [itemAppearance.selected.titleTextAttributes mutableCopy] ?: [NSMutableDictionary dictionary];
        if (selectedTitleColor) {
            selected[NSForegroundColorAttributeName] = selectedTitleColor;
        }
        if (selectedTitleFont) {
            selected[NSFontAttributeName] = selectedTitleFont;
        }
        itemAppearance.selected.titleTextAttributes = selected;
        if (iconColor) {
            itemAppearance.normal.iconColor = iconColor;
        }
        if (selectedIconColor) {
            itemAppearance.selected.iconColor = selectedIconColor;
        }
    }];
    return appearance;
}

- (void)cyl_customizeTabBarController:(CYLTabBarController *)tabBarController {
    if (@available(iOS 13.0, *)) {
        return;
    }
    // [EN] Before iOS 13, the classic tab bar colors. [CN] iOS 13 以前使用经典的 TabBar 颜色。
    UITabBar *tabBar = tabBarController.tabBar;
    UIColor *background = [self colorForName:CYLTabBarBackgroundColor];
    if (background) {
        tabBar.barTintColor = background;
    }
    UIColor *selectedIconColor = [self colorForName:CYLTabBarItemSelectedIconColor];
    if (selectedIconColor) {
        tabBar.tintColor = selectedIconColor;
    }
    UIColor *iconColor = [self colorForName:CYLTabBarItemIconColor];
    if (iconColor) {
        tabBar.unselectedItemTintColor = iconColor;
    }
}

@end

/*!
 * [EN] The skins of a configuration: the identifiers, the base skin (every skin falls back to its values), the dark one,
 *      the one used first (a skin of the manager chosen before is kept), and the manager name. nil without skins.
 * [CN] 配置中的皮肤：标识、基础皮肤（每个皮肤都回退到它的值）、深色皮肤、首先使用的皮肤（保留之前在管理器中选择的皮肤）与管理器名称。没有皮肤时为 nil。
 */
static NSMutableDictionary<NSString *, id> *_Nullable CYLThemesInfoOfConfiguration(NSDictionary<NSString *, id> *configuration) {
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *themes = CYLThemesValue(configuration[CYLTabBarControllerThemes]);
    if (!themes) {
        return nil;
    }
    NSArray<NSString *> *identifiers = [themes.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSString *base = CYLStringValue(configuration[CYLTabBarControllerThemeIdentifier]);
    if (base && !themes[base]) {
        CYLLogInvalidConfigurationValue(CYLTabBarControllerThemeIdentifier, base);
        base = nil;
    }
    base = base ?: identifiers.firstObject;
    NSString *dark = CYLStringValue(configuration[CYLTabBarControllerDarkThemeIdentifier]);
    if (dark && !themes[dark]) {
        CYLLogInvalidConfigurationValue(CYLTabBarControllerDarkThemeIdentifier, dark);
        dark = nil;
    }
    id managerName = configuration[CYLTabBarControllerThemeManagerName];
    if ([managerName isKindOfClass:[NSNumber class]]) {
        managerName = [managerName stringValue];
    }
    if (managerName && (![managerName isKindOfClass:[NSString class]] || [(NSString *)managerName length] == 0)) {
        CYLLogInvalidConfigurationValue(CYLTabBarControllerThemeManagerName, managerName);
        managerName = nil;
    }
    CYLThemeManager *manager = managerName ? [CYLThemeManagerCenter themeManagerWithName:managerName] : CYLThemeManagerCenter.defaultThemeManager;
    id current = manager.currentThemeIdentifier;
    NSString *initial = base;
    if ([current isKindOfClass:[NSString class]] && themes[current]) {
        initial = current;
    } else if (dark && CYLScreenIsDark()) {
        initial = dark;
    }
    NSMutableDictionary<NSString *, NSDictionary<NSString *, id> *> *merged = [NSMutableDictionary dictionary];
    for (NSString *identifier in identifiers) {
        NSMutableDictionary<NSString *, id> *values = [themes[base] mutableCopy];
        [values addEntriesFromDictionary:themes[identifier]];
        merged[identifier] = values;
    }
    NSMutableDictionary<NSString *, id> *info = [NSMutableDictionary dictionary];
    info[CYLConfigurationThemesListKey] = merged;
    info[CYLConfigurationThemesBaseKey] = base;
    info[CYLConfigurationThemesDarkKey] = dark;
    info[CYLConfigurationThemesInitialKey] = initial;
    info[CYLConfigurationThemesManagerKey] = managerName;
    return info;
}

/*!
 * [EN] Turns the merged values into `CYLTabBarConfigurationTheme`s, with the "@name" keys of every kept tab: by its
 *      identifier (made unique by then), or by its position among the kept tabs when it has none.
 * [CN] 把合并后的值转换为 `CYLTabBarConfigurationTheme`，带上每个保留 Tab 的 "@name" 键：按其标识（此时已唯一），没有标识时按其在保留 Tab
 *      中的位置。
 */
static void CYLFinishThemesInfo(NSMutableDictionary<NSString *, id> *info, NSArray<NSDictionary *> *items, NSArray<NSDictionary<NSString *, NSString *> *> *itemReferences) {
    NSMutableDictionary<id, NSDictionary<NSString *, NSString *> *> *references = [NSMutableDictionary dictionary];
    NSUInteger position = 0;
    for (NSUInteger index = 0; index < items.count && index < itemReferences.count; index++) {
        NSDictionary *item = items[index];
        if ([item[CYLTabBarItemExcludedKey] boolValue]) {
            continue;
        }
        NSString *identifier = CYLStringValue(item[CYLTabBarItemIdentifier]);
        if (itemReferences[index].count > 0) {
            references[identifier.length > 0 ? identifier : @(position)] = itemReferences[index];
        }
        position++;
    }
    NSDictionary<NSString *, NSDictionary<NSString *, id> *> *merged = info[CYLConfigurationThemesListKey];
    NSMutableArray<CYLTabBarConfigurationTheme *> *themes = [NSMutableArray array];
    for (NSString *identifier in [merged.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
        [themes addObject:[[CYLTabBarConfigurationTheme alloc] initWithIdentifier:identifier values:merged[identifier] references:references]];
    }
    info[CYLConfigurationThemesListKey] = themes;
}

@implementation CYLTabBarController (CYLConfiguration)

+ (NSDictionary<NSString *, id> *)cyl_normalizedConfiguration:(NSDictionary<NSString *, id> *)configuration {
    if (![configuration isKindOfClass:[NSDictionary class]]) {
        // E.g. an untyped JSON result that is a list (B18). 例如类型不明、实际为数组的 JSON 结果（B18）。
        CYLLogInvalidConfigurationValue(@"configuration", configuration);
        configuration = @{};
    }
    NSMutableDictionary<NSString *, id> *normalized = [configuration mutableCopy];
    for (NSString *key in configuration) {
        if ([configuration[key] isKindOfClass:[NSNull class]]) {
            [normalized removeObjectForKey:key];
        }
    }
    if (normalized[CYLTabBarControllerViewControllers]) {
        normalized[CYLTabBarControllerViewControllers] = CYLValidViewControllers(normalized[CYLTabBarControllerViewControllers]);
    }
    if (normalized[CYLTabBarControllerPageRegistry] && ![normalized[CYLTabBarControllerPageRegistry] conformsToProtocol:@protocol(CYLTabBarPageProviding)]) {
        // Any `CYLTabBarPageProviding` (a registry, a router, a mock); a string from a file cannot provide pages (C14).
        // 任何 `CYLTabBarPageProviding`（注册表、路由器、Mock）；文件中的字符串不能提供页面（C14）。
        CYLLogInvalidConfigurationValue(CYLTabBarControllerPageRegistry, normalized[CYLTabBarControllerPageRegistry]);
        [normalized removeObjectForKey:CYLTabBarControllerPageRegistry];
    }
    Class blockClass = NSClassFromString(@"NSBlock");
    if (normalized[CYLTabBarControllerPageResolver] && !(blockClass && [normalized[CYLTabBarControllerPageResolver] isKindOfClass:blockClass])) {
        // Only a block can be called; a string from a file cannot (C15). 只有 block 可以调用；文件中的字符串不行（C15）。
        CYLLogInvalidConfigurationValue(CYLTabBarControllerPageResolver, normalized[CYLTabBarControllerPageResolver]);
        [normalized removeObjectForKey:CYLTabBarControllerPageResolver];
    }
    if (normalized[CYLTabBarControllerPageLookupOrder]) {
        normalized[CYLTabBarControllerPageLookupOrder] = CYLPageLookupOrderValue(normalized[CYLTabBarControllerPageLookupOrder]);
    }
    if (normalized[CYLTabBarControllerTabBarItemAnimationSpeed]) {
        NSNumber *speed = CYLAnimationSpeedValue(normalized[CYLTabBarControllerTabBarItemAnimationSpeed]);
        if (!speed) {
            CYLLogInvalidConfigurationValue(CYLTabBarControllerTabBarItemAnimationSpeed, normalized[CYLTabBarControllerTabBarItemAnimationSpeed]);
        }
        normalized[CYLTabBarControllerTabBarItemAnimationSpeed] = speed;
    }
    if (normalized[CYLTabBarControllerAutomaticPageRegistration]) {
        NSNumber *automatic = CYLBoolValue(normalized[CYLTabBarControllerAutomaticPageRegistration]);
        if (!automatic) {
            CYLLogInvalidConfigurationValue(CYLTabBarControllerAutomaticPageRegistration, normalized[CYLTabBarControllerAutomaticPageRegistration]);
        }
        normalized[CYLTabBarControllerAutomaticPageRegistration] = automatic;
    }
    // [EN] Skins: the "@name" values of the tabs take the first skin's values (see `CYLTabBarControllerThemes`).
    // [CN] 皮肤：Tab 中的 "@name" 值取首个皮肤的值（见 `CYLTabBarControllerThemes`）。
    NSMutableDictionary<NSString *, id> *themesInfo = normalized[CYLTabBarControllerThemes] ? CYLThemesInfoOfConfiguration(normalized) : nil;
    NSDictionary<NSString *, id> *initialValues = themesInfo ? themesInfo[CYLConfigurationThemesListKey][themesInfo[CYLConfigurationThemesInitialKey]] : nil;
    NSMutableArray<NSDictionary<NSString *, NSString *> *> *itemReferences = [NSMutableArray array];
    id items = normalized[CYLTabBarControllerTabBarItemsAttributes];
    if ([items isKindOfClass:[NSDictionary class]]) {
        // One tab: formats without list syntax (Protobuf text, XML) give a dictionary. 只有一个 Tab：没有列表语法的格式（Protobuf 文本、XML）解析为字典。
        items = @[ items ];
    }
    if (items) {
        NSMutableArray<NSDictionary *> *normalizedItems = [NSMutableArray array];
        if ([items isKindOfClass:[NSArray class]]) {
            for (id item in (NSArray *)items) {
                if ([item isKindOfClass:[NSDictionary class]] && [((NSDictionary *)item)[CYLTabBarItemPlusSlotPlaceholderKey] boolValue]) {
                    // The slot's entry from an existing tab bar controller (its `tabBarItemsAttributes` re-used): not an app tab;
                    // the slot is inserted again, once (B26).
                    // 已有 TabBarController 的 slot 项（复用其 `tabBarItemsAttributes`）：不是 App 的 Tab；slot 会重新插入且只插入一次（B26）。
                    continue;
                }
                if ([item isKindOfClass:[NSDictionary class]]) {
                    NSMutableDictionary<NSString *, NSString *> *references = [NSMutableDictionary dictionary];
                    NSDictionary *source = initialValues ? CYLItemResolvingThemeReferences(item, initialValues, references) : item;
                    [itemReferences addObject:references];
                    NSDictionary *normalizedItem = CYLNormalizedItemAttributes(source);
                    NSString *reason = CYLExclusionReason(normalizedItem);
                    if (reason) {
                        // A marked placeholder: the tab (and a view controller from code) is left out (B22).
                        // 带标记的占位：该 Tab（以及代码传入的对应子控制器）会被移除（B22）。
#if defined(DEBUG) || defined(BETA)
                        NSLog(@"🟡 CYLTabBarController configuration: the tab %@ is left out on this device: %@.", normalizedItem[CYLTabBarItemTitle] ?: @"", reason);
#endif
                        NSMutableDictionary *excluded = [NSMutableDictionary dictionaryWithObject:@(YES) forKey:CYLTabBarItemExcludedKey];
                        excluded[CYLTabBarItemExclusionReasonKey] = reason;
                        // [EN] Kept for `cyl_skippedTabs`; the entry is still left out. [CN] 保留给 `cyl_skippedTabs`；该项仍被排除。
                        for (NSString *key in @[ CYLTabBarItemTitle, CYLTabBarItemIdentifier, CYLTabBarItemPageIdentifier ]) {
                            excluded[key] = normalizedItem[key];
                        }
                        normalizedItem = excluded;
                    }
                    [normalizedItems addObject:normalizedItem];
                } else {
                    // A placeholder keeps the indexes of view controllers passed in code (B4).
                    // 用占位保持与代码传入的子控制器的下标对应（B4）。
                    CYLLogInvalidConfigurationValue(CYLTabBarControllerTabBarItemsAttributes, item);
                    [normalizedItems addObject:@{}];
                    [itemReferences addObject:@{}];
                }
            }
        } else {
            CYLLogInvalidConfigurationValue(CYLTabBarControllerTabBarItemsAttributes, items);
        }
        CYLMakeIdentifiersUnique(normalizedItems);
        normalized[CYLTabBarControllerTabBarItemsAttributes] = normalizedItems;
    }
    if (themesInfo) {
        CYLFinishThemesInfo(themesInfo, normalized[CYLTabBarControllerTabBarItemsAttributes] ?: @[], itemReferences);
        normalized[CYLConfigurationThemesKey] = themesInfo;
    }
    CYLWarnUnknownKeys(normalized, CYLKnownConfigurationKeys());
#if defined(DEBUG) || defined(BETA)
    if ([normalized[CYLTabBarControllerTabBarItemsAttributes] count] == 0 && [normalized[CYLTabBarControllerViewControllers] count] == 0) {
        NSLog(@"🔴 CYLTabBarController configuration: no tab; the tab bar controller will be empty.");
    }
#endif
    if (normalized[CYLTabBarControllerImageInsets]) {
        normalized[CYLTabBarControllerImageInsets] = CYLEdgeInsetsValue(normalized[CYLTabBarControllerImageInsets], CYLTabBarControllerImageInsets);
    }
    if (normalized[CYLTabBarControllerTitlePositionAdjustment]) {
        normalized[CYLTabBarControllerTitlePositionAdjustment] = CYLOffsetValue(normalized[CYLTabBarControllerTitlePositionAdjustment], CYLTabBarControllerTitlePositionAdjustment);
    }
    if (normalized[CYLTabBarControllerStyleType]) {
        normalized[CYLTabBarControllerStyleType] = CYLStyleTypeValue(normalized[CYLTabBarControllerStyleType]);
    }
    id context = normalized[CYLTabBarControllerContext];
    if ([context isKindOfClass:[NSNumber class]]) {
        normalized[CYLTabBarControllerContext] = [context stringValue];
    } else if (context && ![context isKindOfClass:[NSString class]]) {
        CYLLogInvalidConfigurationValue(CYLTabBarControllerContext, context);
        [normalized removeObjectForKey:CYLTabBarControllerContext];
    }
    return normalized;
}

/// [EN] The path of a configuration file: a path, a file URL string, or a file name in the main bundle.
/// [CN] 配置文件的路径：路径、文件 URL 字符串或 main bundle 中的文件名。
+ (NSString *)cyl_pathOfConfigurationFile:(NSString *)filePath {
    if ([filePath hasPrefix:@"file:"]) {
        NSString *path = [NSURL URLWithString:filePath].path;
        if (path.length > 0) {
            return path;
        }
    }
    return CYLMainBundlePath([filePath stringByExpandingTildeInPath]);
}

+ (NSDictionary<NSString *, id> *)configurationWithContentsOfFile:(NSString *)filePath error:(NSError **)error {
    NSString *path = [filePath isKindOfClass:[NSString class]] ? [self cyl_pathOfConfigurationFile:filePath] : @"";
    NSDictionary<NSString *, id> *configuration = [CYLTabBarConfigurationParser dictionaryWithContentsOfFile:path error:error];
    NSError *tabsError = configuration ? CYLConfigurationTabsError(configuration) : nil;
    if (tabsError) {
        if (error) {
            *error = tabsError;
        }
        return nil;
    }
    return configuration;
}

- (instancetype)initWithConfigurationFile:(NSString *)filePath error:(NSError **)error {
    if (![NSThread isMainThread]) {
        // UIKit objects only on the main thread (E1). UIKit 对象只能在主线程创建（E1）。
        if (error) {
            *error = [NSError errorWithDomain:CYLTabBarConfigurationErrorDomain code:CYLTabBarConfigurationErrorMainThreadRequired userInfo:@{
                NSLocalizedDescriptionKey : @"A tab bar controller can only be created on the main thread; read the dictionary in the background with +configurationWithContentsOfFile:error:.",
            }];
        }
        return nil;
    }
    NSDictionary<NSString *, id> *configuration = [[self class] configurationWithContentsOfFile:filePath error:error];
    if (!configuration) {
        return nil;
    }
    self = [self initWithConfiguration:configuration];
    NSError *pagesError = CYLConfigurationPagesError(self);
    if (pagesError) {
        if (error) {
            *error = pagesError;
        }
        return nil;
    }
    return self;
}

+ (instancetype)tabBarControllerWithConfigurationFile:(NSString *)filePath error:(NSError **)error {
    return [[self alloc] initWithConfigurationFile:filePath error:error];
}

- (void)cyl_applyConfigurationThemes:(NSDictionary<NSString *, id> *)normalizedConfiguration {
    NSDictionary<NSString *, id> *info = normalizedConfiguration[CYLConfigurationThemesKey];
    if (![info isKindOfClass:[NSDictionary class]]) {
        return;
    }
    id managerName = info[CYLConfigurationThemesManagerKey];
    if (managerName) {
        self.cyl_themeManager = [CYLThemeManagerCenter themeManagerWithName:managerName];
    }
    CYLThemeManager *manager = self.cyl_themeManager;
    for (CYLTabBarConfigurationTheme *theme in info[CYLConfigurationThemesListKey]) {
        [manager addThemeIdentifier:theme.identifier theme:theme];
    }
    NSString *base = info[CYLConfigurationThemesBaseKey];
    NSString *dark = info[CYLConfigurationThemesDarkKey];
    id current = manager.currentThemeIdentifier;
    // [EN] A skin the app or the user chose before stays; otherwise the first one. [CN] App 或用户之前选择的皮肤保持不变；否则使用首个皮肤。
    if (!current) {
        manager.currentThemeIdentifier = info[CYLConfigurationThemesInitialKey];
    }
    if (@available(iOS 13.0, *)) {
        // [EN] Dark Mode follows the system, unless the manager follows it its own way or another skin was chosen.
        // [CN] 深色模式跟随系统，除非管理器有自己的跟随方式，或已选择了其他皮肤。
        BOOL keepsChoice = current && ![current isEqual:base] && ![current isEqual:dark];
        if (dark && !manager.identifierForTrait && !keepsChoice) {
            manager.identifierForTrait = ^NSObject<NSCopying> *(UITraitCollection *trait) {
                return trait.userInterfaceStyle == UIUserInterfaceStyleDark ? dark : base;
            };
            manager.respondsSystemStyleAutomatically = YES;
        }
    }
}

/// [EN] The timeout of `+loadConfigurationWithURL:completion:` (D5); the system default is 60 seconds. [CN] `+loadConfigurationWithURL:completion:` 的超时（D5）；系统默认 60 秒。
static const NSTimeInterval CYLConfigurationRequestTimeout = 15;

/// [EN] Loads a local (file URL) or missing configuration URL and calls `completion` on the main queue. Shared by both loaders,
///      so a nil URL is never passed to a nonnull parameter (FIX: static analyzer, nullability.NullPassedToNonnull).
/// [CN] 加载本地（file URL）或缺失的配置 URL，并在主队列回调 `completion`。两个加载方法共用，避免把 nil 传给 nonnull 参数
///      （修复静态分析警告 nullability.NullPassedToNonnull）。
static void CYLLoadLocalConfiguration(NSURL *_Nullable URL, CYLTabBarConfigurationCompletion completion) {
    NSError *error = nil;
    NSDictionary *configuration = nil;
    if (URL) {
        // [EN] A file URL's path can be nil (C10). [CN] file URL 的 path 可能为 nil（C10）。
        configuration = [CYLTabBarController configurationWithContentsOfFile:URL.path ?: @"" error:&error];
    } else {
        error = [NSError errorWithDomain:CYLTabBarConfigurationErrorDomain code:CYLTabBarConfigurationErrorFileNotFound
                                userInfo:@{ NSLocalizedDescriptionKey : @"No configuration URL." }];
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        completion(configuration, error);
    });
}

+ (NSURLSessionDataTask *)loadConfigurationWithURL:(NSURL *)URL completion:(CYLTabBarConfigurationCompletion)completion {
    if (!completion) {
        return nil;
    }
    if (!URL || URL.isFileURL) {
        CYLLoadLocalConfiguration(URL, completion);
        return nil;
    }
    NSURLRequest *request = [NSURLRequest requestWithURL:URL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:CYLConfigurationRequestTimeout];
    return [self loadConfigurationWithURLRequest:request completion:completion];
}

+ (NSURLSessionDataTask *)loadConfigurationWithURLRequest:(NSURLRequest *)request completion:(CYLTabBarConfigurationCompletion)completion {
    if (!completion) {
        return nil;
    }
    NSURL *URL = request.URL;
    if (![request isKindOfClass:[NSURLRequest class]] || !URL || URL.isFileURL) {
        CYLLoadLocalConfiguration(URL, completion);
        return nil;
    }
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
        NSDictionary *configuration = nil;
        NSError *error = nil;
        NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? [(NSHTTPURLResponse *)response statusCode] : 200;
        if (!data || networkError || statusCode >= 400) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSString stringWithFormat:@"The configuration could not be downloaded from %@ (HTTP %ld).", URL.absoluteString, (long)statusCode]
                                                                               forKey:NSLocalizedDescriptionKey];
            userInfo[NSUnderlyingErrorKey] = networkError;
            error = [NSError errorWithDomain:CYLTabBarConfigurationErrorDomain code:CYLTabBarConfigurationErrorNetwork userInfo:userInfo];
        } else {
            CYLTabBarConfigurationFormat format = [CYLTabBarConfigurationParser formatForPathExtension:URL.pathExtension];
            if (format == CYLTabBarConfigurationFormatUnknown) {
                format = [CYLTabBarConfigurationParser formatForMIMEType:response.MIMEType];
            }
            configuration = [CYLTabBarConfigurationParser dictionaryWithData:data format:format error:&error];
            NSError *tabsError = configuration ? CYLConfigurationTabsError(configuration) : nil;
            if (tabsError) {
                configuration = nil;
                error = tabsError;
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(configuration, error);
        });
    }];
    [task resume];
    return task;
}

+ (NSURLSessionDataTask *)loadTabBarControllerWithConfigurationURLRequest:(NSURLRequest *)request
                                                               completion:(CYLTabBarControllerConfigurationCompletion)completion {
    if (!completion) {
        return nil;
    }
    Class tabBarControllerClass = self;
    return [self loadConfigurationWithURLRequest:request completion:^(NSDictionary<NSString *, id> *configuration, NSError *error) {
        CYLTabBarController *tabBarController = configuration ? [[tabBarControllerClass alloc] initWithConfiguration:configuration] : nil;
        NSError *pagesError = configuration ? CYLConfigurationPagesError(tabBarController) : nil;
        completion(pagesError ? nil : tabBarController, pagesError ?: error);
    }];
}

+ (NSURLSessionDataTask *)loadTabBarControllerWithConfigurationURL:(NSURL *)URL
                                                        completion:(CYLTabBarControllerConfigurationCompletion)completion {
    if (!completion) {
        return nil;
    }
    Class tabBarControllerClass = self;
    return [self loadConfigurationWithURL:URL completion:^(NSDictionary<NSString *, id> *configuration, NSError *error) {
        CYLTabBarController *tabBarController = configuration ? [[tabBarControllerClass alloc] initWithConfiguration:configuration] : nil;
        NSError *pagesError = configuration ? CYLConfigurationPagesError(tabBarController) : nil;
        completion(pagesError ? nil : tabBarController, pagesError ?: error);
    }];
}

@end
