//
//  CYLResourceRoute.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLResourceRoute.h"

/// [EN] The extensions the configuration parser reads, in the order a route without `format` prefers them; kept in step
///      with `+[CYLTabBarConfigurationParser formatsByPathExtension]` (CYLUtils sits below Core, so it cannot ask it).
/// [CN] 配置解析器支持的扩展名，按不写 `format` 时的优先顺序排列；与 `+[CYLTabBarConfigurationParser formatsByPathExtension]` 保持一致
///      （CYLUtils 位于 Core 之下，无法直接调用它）。
static NSArray<NSString *> *CYLResourceRouteFormats(void) {
    return @[ @"json", @"json5", @"jsonc", @"yaml", @"yml", @"plist", @"xml", @"toml", @"ini", @"cfg", @"conf", @"properties",
              @"env", @"textproto", @"txtpb", @"pbtxt", @"prototxt", @"binpb", @"pb", @"protobuf", @"strings" ];
}

/// [EN] Extensions that are one format. [CN] 属于同一格式的扩展名。
static NSArray<NSString *> *CYLResourceRouteExtensions(NSString *format) {
    NSString *lowercase = format.lowercaseString;
    for (NSArray<NSString *> *group in @[ @[ @"yaml", @"yml" ], @[ @"json5", @"jsonc" ], @[ @"ini", @"cfg", @"conf" ],
                                          @[ @"properties", @"env" ], @[ @"textproto", @"txtpb", @"pbtxt", @"prototxt" ],
                                          @[ @"binpb", @"pb", @"protobuf" ] ]) {
        if ([group containsObject:lowercase]) {
            return group;
        }
    }
    return @[ lowercase ];
}

/// [EN] "1.10" > "1.9": compares numeric parts as numbers. [CN] "1.10" > "1.9"：数字部分按数值比较。
static NSComparisonResult CYLResourceRouteCompareVersions(NSString *first, NSString *second) {
    return [first compare:second options:NSNumericSearch];
}

@implementation CYLResourceRoute

+ (NSString *)sandboxPath:(NSString *)rest {
    while ([rest hasPrefix:@"/"]) {
        rest = [rest substringFromIndex:1];
    }
    NSArray<NSString *> *parts = [rest componentsSeparatedByString:@"/"];
    NSString *first = parts.firstObject ?: @"";
    NSString *remainder = parts.count > 1 ? [[parts subarrayWithRange:NSMakeRange(1, parts.count - 1)] componentsJoinedByString:@"/"] : @"";
    NSString *root = nil;
    if ([first isEqualToString:@"Documents"]) {
        root = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    } else if ([first isEqualToString:@"Caches"]) {
        root = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    } else if ([first isEqualToString:@"tmp"]) {
        root = NSTemporaryDirectory();
    }
    return root ? [root stringByAppendingPathComponent:remainder] : [NSHomeDirectory() stringByAppendingPathComponent:rest];
}

/// [EN] The local path of a route without its query. [CN] 不含查询参数的路由对应的本地路径。
+ (NSString *)pathForLocation:(NSString *)location baseDirectory:(NSString *)baseDirectory {
    NSString *resources = NSBundle.mainBundle.resourcePath ?: @"";
    if ([location hasPrefix:@"bundle:"]) {
        NSString *rest = [location substringFromIndex:@"bundle:".length];
        while ([rest hasPrefix:@"/"]) {
            rest = [rest substringFromIndex:1];
        }
        return [resources stringByAppendingPathComponent:rest];
    }
    if ([location hasPrefix:@"sandbox:"]) {
        return [self sandboxPath:[location substringFromIndex:@"sandbox:".length]];
    }
    if ([location hasPrefix:@"file:"]) {
        return [NSURL URLWithString:location].path ?: [location substringFromIndex:@"file:".length];
    }
    NSString *expanded = [location stringByExpandingTildeInPath];
    if (expanded.isAbsolutePath) {
        return expanded;
    }
    return [(baseDirectory.length > 0 ? baseDirectory : resources) stringByAppendingPathComponent:expanded];
}

+ (NSString *)pathForRoute:(NSString *)route baseDirectory:(NSString *)baseDirectory {
    NSString *trimmed = [route isKindOfClass:[NSString class]] ? [route stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : @"";
    if (trimmed.length == 0) {
        return nil;
    }
    NSRange question = [trimmed rangeOfString:@"?"];
    NSString *location = question.location == NSNotFound ? trimmed : [trimmed substringToIndex:question.location];
    NSString *path = [self pathForLocation:location baseDirectory:baseDirectory];
    if (question.location == NSNotFound) {
        return path;
    }
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.percentEncodedQuery = [trimmed substringFromIndex:question.location + 1];
    NSMutableDictionary<NSString *, NSString *> *query = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in components.queryItems) {
        if (item.value.length > 0) {
            query[item.name.lowercaseString] = item.value;
        }
    }
    NSString *name = query[@"name"];
    if (name.length == 0) {
        return nil;
    }
    return [self pathOfFileInDirectory:path name:name theme:query[@"theme"] version:query[@"version"] format:query[@"format"]];
}

+ (NSString *)pathOfFileInDirectory:(NSString *)directory name:(NSString *)name theme:(NSString *)theme version:(NSString *)version format:(NSString *)format {
    NSArray<NSString *> *formats = CYLResourceRouteFormats();
    NSArray<NSString *> *extensions = format.length > 0 ? CYLResourceRouteExtensions(format) : formats;
    NSString *best = nil;
    NSString *bestVersion = nil;
    NSUInteger bestFormat = NSNotFound;
    for (NSString *file in [NSFileManager.defaultManager contentsOfDirectoryAtPath:directory error:NULL]) {
        if ([file hasPrefix:@"."]) {
            continue;
        }
        NSString *extension = file.pathExtension.lowercaseString;
        if (![extensions containsObject:extension]) {
            continue;
        }
        // [EN] {name}[-{theme}][@{version}]: the name first, then the version after the last "@", the theme after "-".
        // [CN] {name}[-{theme}][@{version}]：先匹配名称，版本位于最后一个 "@" 之后，主题位于 "-" 之后。
        NSString *stem = file.stringByDeletingPathExtension;
        if (![stem hasPrefix:name]) {
            continue;
        }
        NSString *rest = [stem substringFromIndex:name.length];
        NSString *fileVersion = nil;
        NSRange at = [rest rangeOfString:@"@" options:NSBackwardsSearch];
        if (at.location != NSNotFound) {
            fileVersion = [rest substringFromIndex:at.location + 1];
            rest = [rest substringToIndex:at.location];
        }
        NSString *fileTheme = nil;
        if (rest.length > 0) {
            if (![rest hasPrefix:@"-"]) {
                continue;
            }
            fileTheme = [rest substringFromIndex:1];
        }
        // [EN] A theme asked for must match; without one, only files without a theme. [CN] 指定的主题必须一致；未指定时只匹配没有主题的文件。
        if (theme.length > 0 ? ![fileTheme isEqualToString:theme] : fileTheme.length > 0) {
            continue;
        }
        if (version.length > 0 && !(fileVersion && CYLResourceRouteCompareVersions(fileVersion, version) == NSOrderedSame)) {
            continue;
        }
        NSUInteger formatRank = [formats indexOfObject:extension];
        BOOL better = NO;
        if (!best) {
            better = YES;
        } else {
            // [EN] The highest version (no version is the lowest), then the preferred format. [CN] 先比较版本（没有版本为最低），再比较格式优先级。
            NSComparisonResult order = bestVersion && fileVersion ? CYLResourceRouteCompareVersions(fileVersion, bestVersion)
                                     : (fileVersion ? NSOrderedDescending : (bestVersion ? NSOrderedAscending : NSOrderedSame));
            better = order == NSOrderedDescending || (order == NSOrderedSame && formatRank < bestFormat);
        }
        if (better) {
            best = file;
            bestVersion = fileVersion;
            bestFormat = formatRank;
        }
    }
    return best ? [directory stringByAppendingPathComponent:best] : nil;
}

@end
