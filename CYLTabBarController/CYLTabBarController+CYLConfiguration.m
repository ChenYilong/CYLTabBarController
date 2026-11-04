//
//  CYLTabBarController+CYLConfiguration.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"
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

/// [EN] An NSURL from a URL string, a path or a file name in the main bundle. [CN] 将 URL 字符串、路径或 main bundle 中的文件名转换为 NSURL。
static id CYLURLValue(id value) {
    if (![value isKindOfClass:[NSString class]]) {
        return value;
    }
    NSString *string = value;
    NSURL *URL = [NSURL URLWithString:string];
    if (URL.scheme.length > 1) {
        return URL;
    }
    return [NSURL fileURLWithPath:CYLMainBundlePath(string)];
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

static id CYLDarkColorsValue(id value) {
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
            CYLLogInvalidConfigurationValue(CYLTabBarLottieDarkColors, dictionary[keypath]);
        }
    }
    return colors;
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
    for (NSString *key in @[ CYLTabBarItemTitle, CYLTabBarItemIdentifier, CYLTabBarItemViewControllerClass, CYLTabBarItemNavigationControllerClass ]) {
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
    for (NSString *key in @[ CYLTabBarItemImageURLSize, CYLTabBarLottieSize ]) {
        if (item[key]) {
            item[key] = CYLSizeValue(item[key], key);
        }
    }
    for (NSString *key in @[ CYLTabBarItemImageURL, CYLTabBarItemSelectedImageURL, CYLTabBarLottieURL, CYLTabBarLottieDarkURL ]) {
        id value = item[key];
        if (value && ![value isKindOfClass:[NSString class]] && ![value isKindOfClass:[NSURL class]]) {
            CYLLogInvalidConfigurationValue(key, value);
            item[key] = nil;
        }
    }
    for (NSString *key in @[ CYLTabBarLottieURL, CYLTabBarLottieDarkURL ]) {
        if (item[key]) {
            item[key] = CYLURLValue(item[key]);
        }
    }
    for (NSString *key in @[ CYLTabBarLottieFilePath, CYLTabBarLottieDarkFilePath ]) {
        id value = item[key];
        if (value && ![value isKindOfClass:[NSString class]]) {
            CYLLogInvalidConfigurationValue(key, value);
            value = nil;
        }
        item[key] = value ? CYLMainBundlePath(value) : nil;
    }
    if (item[CYLTabBarLottieDarkColors]) {
        id colors = CYLDarkColorsValue(item[CYLTabBarLottieDarkColors]);
        if (![colors isKindOfClass:[NSDictionary class]]) {
            CYLLogInvalidConfigurationValue(CYLTabBarLottieDarkColors, colors);
            colors = nil;
        }
        item[CYLTabBarLottieDarkColors] = colors;
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

@implementation CYLTabBarController (CYLConfiguration)

+ (NSDictionary<NSString *, id> *)cyl_normalizedConfiguration:(NSDictionary<NSString *, id> *)configuration {
    NSMutableDictionary<NSString *, id> *normalized = [configuration mutableCopy] ?: [NSMutableDictionary dictionary];
    for (NSString *key in configuration) {
        if ([configuration[key] isKindOfClass:[NSNull class]]) {
            [normalized removeObjectForKey:key];
        }
    }
    if (normalized[CYLTabBarControllerViewControllers]) {
        normalized[CYLTabBarControllerViewControllers] = CYLValidViewControllers(normalized[CYLTabBarControllerViewControllers]);
    }
    id items = normalized[CYLTabBarControllerTabBarItemsAttributes];
    if ([items isKindOfClass:[NSDictionary class]]) {
        // One tab: formats without list syntax (Protobuf text, XML) give a dictionary. 只有一个 Tab：没有列表语法的格式（Protobuf 文本、XML）解析为字典。
        items = @[ items ];
    }
    if (items) {
        NSMutableArray<NSDictionary *> *normalizedItems = [NSMutableArray array];
        if ([items isKindOfClass:[NSArray class]]) {
            for (id item in (NSArray *)items) {
                if ([item isKindOfClass:[NSDictionary class]]) {
                    [normalizedItems addObject:CYLNormalizedItemAttributes(item)];
                } else {
                    CYLLogInvalidConfigurationValue(CYLTabBarControllerTabBarItemsAttributes, item);
                }
            }
        } else {
            CYLLogInvalidConfigurationValue(CYLTabBarControllerTabBarItemsAttributes, items);
        }
        normalized[CYLTabBarControllerTabBarItemsAttributes] = normalizedItems;
    }
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
    NSDictionary<NSString *, id> *configuration = [[self class] configurationWithContentsOfFile:filePath error:error];
    if (!configuration) {
        return nil;
    }
    return [self initWithConfiguration:configuration];
}

+ (instancetype)tabBarControllerWithConfigurationFile:(NSString *)filePath error:(NSError **)error {
    return [[self alloc] initWithConfigurationFile:filePath error:error];
}

+ (NSURLSessionDataTask *)loadConfigurationWithURL:(NSURL *)URL completion:(CYLTabBarConfigurationCompletion)completion {
    if (!completion) {
        return nil;
    }
    if (!URL || URL.isFileURL) {
        NSError *error = nil;
        NSDictionary *configuration = URL ? [self configurationWithContentsOfFile:URL.path error:&error] : nil;
        if (!URL) {
            error = [NSError errorWithDomain:CYLTabBarConfigurationErrorDomain code:CYLTabBarConfigurationErrorFileNotFound
                                    userInfo:@{ NSLocalizedDescriptionKey : @"No configuration URL." }];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(configuration, error);
        });
        return nil;
    }
    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *networkError) {
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

+ (NSURLSessionDataTask *)loadTabBarControllerWithConfigurationURL:(NSURL *)URL
                                                        completion:(CYLTabBarControllerConfigurationCompletion)completion {
    if (!completion) {
        return nil;
    }
    Class tabBarControllerClass = self;
    return [self loadConfigurationWithURL:URL completion:^(NSDictionary<NSString *, id> *configuration, NSError *error) {
        CYLTabBarController *tabBarController = configuration ? [[tabBarControllerClass alloc] initWithConfiguration:configuration] : nil;
        completion(tabBarController, error);
    }];
}

@end
