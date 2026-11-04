//
//  CYLTabBarController+CYLConfiguration.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"

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

static NSValue *_Nullable CYLEdgeInsetsValue(id value, NSString *key) {
    if (CYLIsValueOfType(value, @encode(UIEdgeInsets))) {
        return value;
    }
    NSArray<NSNumber *> *n = CYLConfigurationNumbers(value, 4, @[ @"top", @"left", @"bottom", @"right" ]);
    if (!n) {
        CYLLogInvalidConfigurationValue(key, value);
        return nil;
    }
    return [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(n[0].doubleValue, n[1].doubleValue, n[2].doubleValue, n[3].doubleValue)];
}

static NSValue *_Nullable CYLOffsetValue(id value, NSString *key) {
    if (CYLIsValueOfType(value, @encode(UIOffset))) {
        return value;
    }
    NSArray<NSNumber *> *n = CYLConfigurationNumbers(value, 2, @[ @"horizontal|x", @"vertical|y" ]);
    if (!n) {
        CYLLogInvalidConfigurationValue(key, value);
        return nil;
    }
    return [NSValue valueWithUIOffset:UIOffsetMake(n[0].doubleValue, n[1].doubleValue)];
}

static NSValue *_Nullable CYLSizeValue(id value, NSString *key) {
    if (CYLIsValueOfType(value, @encode(CGSize))) {
        return value;
    }
    NSArray<NSNumber *> *n = CYLConfigurationNumbers(value, 2, @[ @"width|w", @"height|h" ]);
    if (!n) {
        CYLLogInvalidConfigurationValue(key, value);
        return nil;
    }
    return [NSValue valueWithCGSize:CGSizeMake(n[0].doubleValue, n[1].doubleValue)];
}

/// [EN] "default", "system", "flatDesign", "liquidGlass" (any case, with or without the `CYLTabBarStyleType` prefix) or a number.
/// [CN] "default"、"system"、"flatDesign"、"liquidGlass"（不区分大小写，可带 `CYLTabBarStyleType` 前缀）或数字。
static NSNumber *_Nullable CYLStyleTypeValue(id value) {
    if ([value isKindOfClass:[NSNumber class]]) {
        return value;
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
    }
    return style;
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

static id CYLDarkColorsValue(id value) {
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

static NSDictionary *CYLNormalizedItemAttributes(NSDictionary *attributes) {
    NSMutableDictionary *item = [attributes mutableCopy];
    for (NSString *key in @[ CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLTabBarItemDarkImage, CYLTabBarItemSelectedDarkImage ]) {
        if (item[key]) {
            item[key] = CYLImageValue(item[key]);
        }
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
    for (NSString *key in @[ CYLTabBarLottieURL, CYLTabBarLottieDarkURL ]) {
        if (item[key]) {
            item[key] = CYLURLValue(item[key]);
        }
    }
    for (NSString *key in @[ CYLTabBarLottieFilePath, CYLTabBarLottieDarkFilePath ]) {
        if ([item[key] isKindOfClass:[NSString class]]) {
            item[key] = CYLMainBundlePath(item[key]);
        }
    }
    if (item[CYLTabBarLottieDarkColors]) {
        item[CYLTabBarLottieDarkColors] = CYLDarkColorsValue(item[CYLTabBarLottieDarkColors]);
    }
    for (NSString *key in @[ CYLTabBarItemTitle, CYLTabBarItemIdentifier ]) {
        if ([item[key] isKindOfClass:[NSNumber class]]) {
            item[key] = [item[key] stringValue];
        }
    }
    return item;
}

@implementation CYLTabBarController (CYLConfiguration)

+ (NSDictionary<NSString *, id> *)cyl_normalizedConfiguration:(NSDictionary<NSString *, id> *)configuration {
    NSMutableDictionary<NSString *, id> *normalized = [configuration mutableCopy] ?: [NSMutableDictionary dictionary];
    for (NSString *key in configuration) {
        if ([configuration[key] isKindOfClass:[NSNull class]]) {
            [normalized removeObjectForKey:key];
        }
    }
    id viewControllers = normalized[CYLTabBarControllerViewControllers];
    if (viewControllers && ![viewControllers isKindOfClass:[NSArray class]]) {
        CYLLogInvalidConfigurationValue(CYLTabBarControllerViewControllers, viewControllers);
        [normalized removeObjectForKey:CYLTabBarControllerViewControllers];
    }
    id items = normalized[CYLTabBarControllerTabBarItemsAttributes];
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
    return [CYLTabBarConfigurationParser dictionaryWithContentsOfFile:[self cyl_pathOfConfigurationFile:filePath ?: @""] error:error];
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
