//
//  CYLTabBarManifest.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarManifest.h"
#import "CYLTabBarController.h"
#import <CommonCrypto/CommonDigest.h>

/// [EN] The prefix of the theme names that hold one tab's image. [CN] 保存某个 Tab 图片的主题名称前缀。
static NSString *const CYLManifestAssetNamePrefix = @"cyl.asset.";

static NSError *CYLManifestError(CYLTabBarConfigurationErrorCode code, NSString *description) {
    return [NSError errorWithDomain:CYLTabBarConfigurationErrorDomain code:code userInfo:@{ NSLocalizedDescriptionKey : description }];
}

static id CYLManifestValue(id container, NSString *key, Class kind) {
    id value = [container isKindOfClass:[NSDictionary class]] ? container[key] : nil;
    return [value isKindOfClass:kind] ? value : nil;
}

static NSString *CYLManifestString(id container, NSString *key) {
    id value = [container isKindOfClass:[NSDictionary class]] ? container[key] : nil;
    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }
    NSString *text = [value isKindOfClass:[NSString class]] ? [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] : nil;
    return text.length > 0 ? text : nil;
}

/// [EN] "1.10.0" > "1.9": each number compared as a number, missing parts count as 0. [CN] 逐段按数值比较，缺少的段视为 0。
static NSComparisonResult CYLManifestCompareVersions(NSString *first, NSString *second) {
    NSArray<NSString *> *a = [first componentsSeparatedByString:@"."];
    NSArray<NSString *> *b = [second componentsSeparatedByString:@"."];
    for (NSUInteger index = 0; index < MAX(a.count, b.count); index++) {
        NSInteger x = index < a.count ? a[index].integerValue : 0;
        NSInteger y = index < b.count ? b[index].integerValue : 0;
        if (x != y) {
            return x < y ? NSOrderedAscending : NSOrderedDescending;
        }
    }
    return NSOrderedSame;
}

static NSString *CYLManifestAppVersion(void) {
    NSString *version = NSBundle.mainBundle.infoDictionary[@"CFBundleShortVersionString"];
    return [version isKindOfClass:[NSString class]] ? version : @"0";
}

/// [EN] A list of platforms ("all", "ios", "android"), from a list or a comma-separated string. [CN] 平台列表，来自数组或逗号分隔的字符串。
static NSArray<NSString *> *CYLManifestPlatforms(id value) {
    NSArray *items = [value isKindOfClass:[NSArray class]] ? value : ([value isKindOfClass:[NSString class]] ? [value componentsSeparatedByString:@","] : nil);
    NSMutableArray<NSString *> *platforms = [NSMutableArray array];
    for (id item in items) {
        NSString *name = [item isKindOfClass:[NSString class]] ? [[item stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet] lowercaseString] : nil;
        if (name.length > 0) {
            [platforms addObject:name];
        }
    }
    return platforms;
}

static BOOL CYLManifestPlatformsAllowIOS(id value) {
    NSArray<NSString *> *platforms = CYLManifestPlatforms(value);
    return platforms.count == 0 || [platforms containsObject:@"all"] || [platforms containsObject:@"ios"];
}

static NSDate *CYLManifestDate(NSString *text) {
    if (text.length == 0) {
        return nil;
    }
    NSISO8601DateFormatter *formatter = [[NSISO8601DateFormatter alloc] init];
    return [formatter dateFromString:text];
}

/// [EN] `override` merged into `base`: dictionaries key by key, anything else replaced. [CN] 把 `override` 合并进 `base`：字典逐键合并，其他值直接替换。
static id CYLManifestMerge(id base, id override) {
    if (![base isKindOfClass:[NSDictionary class]] || ![override isKindOfClass:[NSDictionary class]]) {
        return override;
    }
    NSMutableDictionary *merged = [base mutableCopy];
    for (id key in override) {
        merged[key] = CYLManifestMerge(base[key], override[key]);
    }
    return merged;
}

#pragma mark - Conditions (Firebase Remote Config's expression subset)

/// [EN] A number from 0 to 99 that stays the same for this install, for `percent`. [CN] 本次安装固定不变的 0–99 数字，用于 `percent`。
static NSInteger CYLManifestPercentile(void) {
    static NSString *const key = @"CYLTabBarManifestPercentile";
    NSUserDefaults *defaults = NSUserDefaults.standardUserDefaults;
    if (![defaults objectForKey:key]) {
        [defaults setInteger:(NSInteger)arc4random_uniform(100) forKey:key];
    }
    return [defaults integerForKey:key];
}

static NSString *CYLManifestQuoted(NSString *text) {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (trimmed.length >= 2 && ([trimmed hasPrefix:@"'"] || [trimmed hasPrefix:@"\""])) {
        return [trimmed substringWithRange:NSMakeRange(1, trimmed.length - 2)];
    }
    return trimmed;
}

static BOOL CYLManifestCompare(NSComparisonResult order, NSString *operator) {
    if ([operator isEqualToString:@"=="]) return order == NSOrderedSame;
    if ([operator isEqualToString:@"!="]) return order != NSOrderedSame;
    if ([operator isEqualToString:@">="]) return order != NSOrderedAscending;
    if ([operator isEqualToString:@"<="]) return order != NSOrderedDescending;
    if ([operator isEqualToString:@">"]) return order == NSOrderedDescending;
    if ([operator isEqualToString:@"<"]) return order == NSOrderedAscending;
    return NO;
}

/// [EN] One element: `device.os`, `app.version`, `device.language in [...]` or `percent`. Unknown: NO. [CN] 一个元素；未知时为 NO。
static BOOL CYLManifestElementHolds(NSString *element) {
    NSString *text = [element stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSRegularExpression *comparison = [NSRegularExpression regularExpressionWithPattern:@"^(device\\.os|app\\.version|percent)\\s*(==|!=|>=|<=|>|<)\\s*(.+)$" options:0 error:NULL];
    NSTextCheckingResult *match = [comparison firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
    if (match) {
        NSString *subject = [text substringWithRange:[match rangeAtIndex:1]];
        NSString *operator = [text substringWithRange:[match rangeAtIndex:2]];
        NSString *value = CYLManifestQuoted([text substringWithRange:[match rangeAtIndex:3]]);
        if ([subject isEqualToString:@"device.os"]) {
            NSString *os = value.lowercaseString;
            BOOL isIOS = [os isEqualToString:@"ios"] || [os isEqualToString:@"apple"];
            return [operator isEqualToString:@"=="] ? isIOS : ([operator isEqualToString:@"!="] ? !isIOS : NO);
        }
        if ([subject isEqualToString:@"app.version"]) {
            return CYLManifestCompare(CYLManifestCompareVersions(CYLManifestAppVersion(), value), operator);
        }
        NSInteger percentile = CYLManifestPercentile();
        NSInteger limit = value.integerValue;
        return CYLManifestCompare(percentile < limit ? NSOrderedAscending : (percentile > limit ? NSOrderedDescending : NSOrderedSame), operator);
    }
    NSRegularExpression *between = [NSRegularExpression regularExpressionWithPattern:@"^percent\\s+between\\s+(\\d+)\\s+and\\s+(\\d+)$" options:0 error:NULL];
    match = [between firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
    if (match) {
        NSInteger percentile = CYLManifestPercentile();
        return percentile >= [text substringWithRange:[match rangeAtIndex:1]].integerValue && percentile <= [text substringWithRange:[match rangeAtIndex:2]].integerValue;
    }
    NSRegularExpression *language = [NSRegularExpression regularExpressionWithPattern:@"^device\\.language\\s+in\\s+\\[(.*)\\]$" options:0 error:NULL];
    match = [language firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];
    if (match) {
        NSString *current = (CYLLocalizationLanguage() ?: NSLocale.preferredLanguages.firstObject ?: @"").lowercaseString;
        for (NSString *item in [[text substringWithRange:[match rangeAtIndex:1]] componentsSeparatedByString:@","]) {
            NSString *wanted = CYLManifestQuoted(item).lowercaseString;
            if (wanted.length > 0 && ([current isEqualToString:wanted] || [current hasPrefix:[wanted stringByAppendingString:@"-"]])) {
                return YES;
            }
        }
        return NO;
    }
#if defined(DEBUG) || defined(BETA)
    NSLog(@"🟡 CYLTabBarManifest: unknown condition \"%@\" is false.", text);
#endif
    return NO;
}

/// [EN] Every element joined with " && " holds. [CN] 用 " && " 连接的每个元素都成立。
static BOOL CYLManifestExpressionHolds(NSString *expression) {
    if (expression.length == 0) {
        return NO;
    }
    for (NSString *element in [expression componentsSeparatedByString:@"&&"]) {
        if (!CYLManifestElementHolds(element)) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - CYLTabBarManifest

@interface CYLTabBarManifest ()
@property (nonatomic, copy, readwrite) NSDictionary<NSString *, id> *dictionary;
@property (nonatomic, copy, readwrite, nullable) NSString *baseDirectory;
/// [EN] The asset entries for this platform. [CN] 适用于本平台的资源项。
- (NSArray<NSDictionary *> *)assetEntries;
/// [EN] An entry's path inside the assets folder, or nil. [CN] 资源项在资源目录内的路径，没有时为 nil。
- (nullable NSString *)pathOfEntry:(NSDictionary *)entry;
@end

@implementation CYLTabBarManifest

+ (NSInteger)supportedSchemaVersion {
    return 1;
}

+ (instancetype)manifestWithDictionary:(NSDictionary<NSString *, id> *)dictionary baseDirectory:(NSString *)baseDirectory error:(NSError **)error {
    if (![dictionary isKindOfClass:[NSDictionary class]] || ![dictionary[@"tabBar"] isKindOfClass:[NSDictionary class]]) {
        if (error) {
            *error = CYLManifestError(CYLTabBarConfigurationErrorUnsupportedManifest, @"Not a tab bar manifest: it has no \"tabBar\" dictionary.");
        }
        return nil;
    }
    id schema = dictionary[@"schemaVersion"];
    if (![schema respondsToSelector:@selector(integerValue)] || [schema integerValue] != self.supportedSchemaVersion) {
        if (error) {
            *error = CYLManifestError(CYLTabBarConfigurationErrorUnsupportedManifest,
                                      [NSString stringWithFormat:@"schemaVersion %@ is not supported (this library reads %ld).", schema ?: @"(missing)", (long)self.supportedSchemaVersion]);
        }
        return nil;
    }
    CYLTabBarManifest *manifest = [[self alloc] init];
    // [EN] Overrides of the conditions that hold, in order (Firebase: conditions in priority order).
    // [CN] 按顺序合并成立条件的覆盖项（Firebase：条件按优先级排列）。
    NSMutableDictionary *merged = [dictionary mutableCopy];
    NSArray *conditions = CYLManifestValue(dictionary, @"conditions", [NSArray class]);
    NSArray *overrides = CYLManifestValue(dictionary, @"overrides", [NSArray class]);
    for (NSDictionary *condition in conditions) {
        NSString *name = CYLManifestString(condition, @"name");
        if (!name || !CYLManifestExpressionHolds(CYLManifestString(condition, @"expression"))) {
            continue;
        }
        for (NSDictionary *override in overrides) {
            if ([CYLManifestString(override, @"condition") isEqualToString:name]) {
                NSMutableDictionary *values = [override mutableCopy];
                [values removeObjectForKey:@"condition"];
                merged = [CYLManifestMerge(merged, values) mutableCopy];
            }
        }
    }
    manifest.dictionary = merged;
    manifest.baseDirectory = baseDirectory;
    return manifest;
}

+ (instancetype)manifestWithRoute:(NSString *)route error:(NSError **)error {
    NSString *path = [route isKindOfClass:[NSString class]] ? [CYLResourceRoute pathForRoute:route baseDirectory:nil] : nil;
    if (path.length == 0 || ![NSFileManager.defaultManager fileExistsAtPath:path]) {
        if (error) {
            *error = CYLManifestError(CYLTabBarConfigurationErrorFileNotFound, [NSString stringWithFormat:@"No manifest matches the route \"%@\".", route ?: @""]);
        }
        return nil;
    }
    NSDictionary *dictionary = [CYLTabBarConfigurationParser dictionaryWithContentsOfFile:path error:error];
    return dictionary ? [self manifestWithDictionary:dictionary baseDirectory:path.stringByDeletingLastPathComponent error:error] : nil;
}

- (NSString *)identifier {
    return CYLManifestString(self.dictionary, @"id");
}

- (NSString *)version {
    return CYLManifestString(self.dictionary, @"version");
}

- (BOOL)isEligibleAtDate:(NSDate *)date error:(NSError **)error {
    NSDictionary *runtime = CYLManifestValue(self.dictionary, @"runtime", [NSDictionary class]);
    NSString *reason = nil;
    NSString *appVersion = CYLManifestAppVersion();
    NSString *minimum = CYLManifestString(runtime, @"minAppVersion");
    NSString *maximum = CYLManifestString(runtime, @"maxAppVersion");
    NSDate *start = CYLManifestDate(CYLManifestString(runtime, @"startTime"));
    NSDate *end = CYLManifestDate(CYLManifestString(runtime, @"endTime"));
    if (!CYLManifestPlatformsAllowIOS(runtime[@"platforms"])) {
        reason = [NSString stringWithFormat:@"runtime.platforms %@ does not include ios.", CYLManifestPlatforms(runtime[@"platforms"])];
    } else if (minimum && CYLManifestCompareVersions(appVersion, minimum) == NSOrderedAscending) {
        reason = [NSString stringWithFormat:@"It needs app version %@ or later (this app is %@).", minimum, appVersion];
    } else if (maximum && CYLManifestCompareVersions(appVersion, maximum) == NSOrderedDescending) {
        reason = [NSString stringWithFormat:@"It is for app version %@ or earlier (this app is %@).", maximum, appVersion];
    } else if (start && [date compare:start] == NSOrderedAscending) {
        reason = [NSString stringWithFormat:@"It starts at %@.", CYLManifestString(runtime, @"startTime")];
    } else if (end && [date compare:end] != NSOrderedAscending) {
        reason = [NSString stringWithFormat:@"It ended at %@.", CYLManifestString(runtime, @"endTime")];
    }
    if (reason && error) {
        *error = CYLManifestError(CYLTabBarConfigurationErrorNotEligible, reason);
    }
    return reason == nil;
}

#pragma mark - Assets

- (NSString *)assetsDirectory {
    NSDictionary *assets = CYLManifestValue(self.dictionary, @"assets", [NSDictionary class]);
    NSString *route = CYLManifestString(assets, @"baseRoute") ?: @"";
    return [CYLResourceRoute pathForRoute:(route.length > 0 ? route : @".") baseDirectory:self.baseDirectory];
}

- (NSArray<NSDictionary *> *)assetEntries {
    NSArray *list = CYLManifestValue(CYLManifestValue(self.dictionary, @"assets", [NSDictionary class]), @"list", [NSArray class]);
    NSMutableArray<NSDictionary *> *entries = [NSMutableArray array];
    for (NSDictionary *entry in list) {
        if (CYLManifestString(entry, @"key") && CYLManifestString(entry, @"path") && CYLManifestPlatformsAllowIOS(entry[@"platforms"])) {
            [entries addObject:entry];
        }
    }
    return entries;
}

/// [EN] A path inside the assets folder only: "../" cannot leave it. [CN] 只允许资源目录内的路径："../" 不能跳出该目录。
- (NSString *)pathOfEntry:(NSDictionary *)entry {
    NSString *directory = self.assetsDirectory.stringByStandardizingPath;
    NSString *path = [directory stringByAppendingPathComponent:CYLManifestString(entry, @"path")].stringByStandardizingPath;
    return [path hasPrefix:[directory stringByAppendingString:@"/"]] ? path : nil;
}

- (NSString *)defaultTheme {
    return CYLManifestString(CYLManifestValue(self.dictionary, @"themes", [NSDictionary class]), @"default");
}

- (NSString *)pathOfAssetWithKey:(NSString *)key theme:(NSString *)theme state:(NSString *)state {
    NSString *wantedState = state.length > 0 ? state : @"normal";
    NSString *wantedTheme = theme.length > 0 ? theme : self.defaultTheme;
    NSMutableArray<NSArray<NSString *> *> *attempts = [NSMutableArray array];
    // [EN] "*" last: any theme, for a manifest without themes. [CN] 最后是 "*"：任意主题，用于没有主题的清单。
    for (NSString *candidateTheme in @[ wantedTheme ?: @"", self.defaultTheme ?: @"", @"*" ]) {
        [attempts addObject:@[ candidateTheme, wantedState ]];
        [attempts addObject:@[ candidateTheme, @"normal" ]];
    }
    NSArray<NSDictionary *> *entries = self.assetEntries;
    for (NSArray<NSString *> *attempt in attempts) {
        for (NSDictionary *entry in entries) {
            NSString *entryTheme = CYLManifestString(entry, @"theme") ?: @"";
            NSString *entryState = CYLManifestString(entry, @"state") ?: @"normal";
            BOOL themeMatches = [attempt[0] isEqualToString:@"*"] || [entryTheme isEqualToString:attempt[0]];
            if ([CYLManifestString(entry, @"key") isEqualToString:key] && themeMatches && [entryState isEqualToString:attempt[1]]) {
                NSString *path = [self pathOfEntry:entry];
                if (path && [NSFileManager.defaultManager fileExistsAtPath:path]) {
                    return path;
                }
            }
        }
    }
    return nil;
}

- (NSString *)pathForAssetReference:(NSString *)reference {
    if (![reference isKindOfClass:[NSString class]] || ![reference hasPrefix:@"asset:"]) {
        return nil;
    }
    NSString *rest = [reference substringFromIndex:@"asset:".length];
    NSRange question = [rest rangeOfString:@"?"];
    NSString *key = question.location == NSNotFound ? rest : [rest substringToIndex:question.location];
    NSURLComponents *components = [[NSURLComponents alloc] init];
    components.percentEncodedQuery = question.location == NSNotFound ? nil : [rest substringFromIndex:question.location + 1];
    NSString *theme = nil;
    NSString *state = nil;
    for (NSURLQueryItem *item in components.queryItems) {
        if ([item.name isEqualToString:@"theme"]) theme = item.value;
        if ([item.name isEqualToString:@"state"]) state = item.value;
    }
    return key.length > 0 ? [self pathOfAssetWithKey:key theme:theme state:state] : nil;
}

- (BOOL)verifyAssetsWithError:(NSError **)error {
    for (NSDictionary *entry in self.assetEntries) {
        NSString *path = [self pathOfEntry:entry];
        NSData *data = path ? [NSData dataWithContentsOfFile:path] : nil;
        if (!data) {
            if (error) {
                *error = CYLManifestError(CYLTabBarConfigurationErrorAssetInvalid, [NSString stringWithFormat:@"Asset %@ is missing.", CYLManifestString(entry, @"path")]);
            }
            return NO;
        }
        NSString *hash = CYLManifestString(entry, @"hash");
        if (hash && ![hash isEqualToString:[CYLTabBarManifest hashOfData:data]]) {
            if (error) {
                *error = CYLManifestError(CYLTabBarConfigurationErrorAssetInvalid, [NSString stringWithFormat:@"Asset %@ does not match its hash.", CYLManifestString(entry, @"path")]);
            }
            return NO;
        }
    }
    return YES;
}

/// [EN] "sha256-" and the Base64URL digest, without padding (Expo's asset hash). [CN] "sha256-" 加无填充的 Base64URL 摘要（Expo 的资源哈希）。
+ (NSString *)hashOfData:(NSData *)data {
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSString *base64 = [[NSData dataWithBytes:digest length:sizeof(digest)] base64EncodedStringWithOptions:0];
    base64 = [[[base64 stringByReplacingOccurrencesOfString:@"+" withString:@"-"] stringByReplacingOccurrencesOfString:@"/" withString:@"_"]
              stringByReplacingOccurrencesOfString:@"=" withString:@""];
    return [@"sha256-" stringByAppendingString:base64];
}

#pragma mark - Configuration

/// [EN] An `@name` value of `theme`, else of the default theme. [CN] `theme` 中 `@名称` 的值，否则取默认主题中的值。
- (id)resolvedValue:(id)value theme:(NSString *)theme {
    if (![value isKindOfClass:[NSString class]] || ![value hasPrefix:@"@"]) {
        return value;
    }
    NSString *name = [value substringFromIndex:1];
    NSDictionary *list = CYLManifestValue(CYLManifestValue(self.dictionary, @"themes", [NSDictionary class]), @"list", [NSDictionary class]);
    return CYLManifestValue(list, theme, [NSDictionary class])[name] ?: CYLManifestValue(list, self.defaultTheme, [NSDictionary class])[name];
}

/// [EN] An image value: an asset reference, a resource route, or an `@name` of the themes. [CN] 图片值：资源引用、资源路由或主题中的 `@名称`。
- (NSString *)imagePathForValue:(id)value theme:(NSString *)theme {
    id resolved = [self resolvedValue:value theme:theme];
    if (![resolved isKindOfClass:[NSString class]] || [resolved length] == 0) {
        return nil;
    }
    if ([resolved hasPrefix:@"asset:"]) {
        NSString *reference = resolved;
        if (theme.length > 0 && [reference rangeOfString:@"theme="].location == NSNotFound) {
            reference = [reference stringByAppendingFormat:@"%@theme=%@", [reference containsString:@"?"] ? @"&" : @"?", theme];
        }
        return [self pathForAssetReference:reference];
    }
    NSString *path = [CYLResourceRoute pathForRoute:resolved baseDirectory:self.baseDirectory];
    return [NSFileManager.defaultManager fileExistsAtPath:path] ? path : nil;
}

- (BOOL)itemIsForThisApp:(NSDictionary *)item {
    if (!CYLManifestPlatformsAllowIOS(item[@"platforms"])) {
        return NO;
    }
    NSString *maximum = CYLManifestString(item, @"maxAppVersion");
    return !(maximum && CYLManifestCompareVersions(CYLManifestAppVersion(), maximum) == NSOrderedDescending);
}

- (NSDictionary<NSString *, id> *)configuration {
    NSDictionary *tabBar = CYLManifestValue(self.dictionary, @"tabBar", [NSDictionary class]);
    NSDictionary *themes = CYLManifestValue(self.dictionary, @"themes", [NSDictionary class]);
    NSDictionary *themeList = CYLManifestValue(themes, @"list", [NSDictionary class]);
    NSMutableDictionary<NSString *, id> *configuration = [NSMutableDictionary dictionary];
    NSString *styleType = CYLManifestString(tabBar, @"styleType");
    if (styleType) {
        configuration[CYLTabBarControllerStyleType] = styleType;
    }
    NSMutableArray<NSDictionary *> *items = [NSMutableArray array];
    NSMutableArray<NSDictionary *> *imageItems = [NSMutableArray array];
    for (NSDictionary *item in CYLManifestValue(tabBar, @"list", [NSArray class])) {
        NSString *key = CYLManifestString(item, @"key");
        if (![item isKindOfClass:[NSDictionary class]] || [item[@"visible"] isEqual:@NO] || ![self itemIsForThisApp:item]) {
            continue;
        }
        NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
        attributes[CYLTabBarItemIdentifier] = key;
        attributes[CYLTabBarItemTitle] = CYLManifestString(item, @"text");
        attributes[CYLTabBarItemPageIdentifier] = CYLManifestString(item, @"pagePath");
        attributes[CYLTabBarItemMinimumAppVersion] = CYLManifestString(item, @"minAppVersion");
        [items addObject:attributes];
        [imageItems addObject:item];
    }
    // [EN] One theme per entry of `themes.list`: its variables, the bar's colors, and every tab's image in that theme (a
    //      tab's image is then "@cyl.asset.<key>.<state>", so switching the theme switches the icons in place).
    // [CN] `themes.list` 中每项一个主题：其变量、TabBar 的颜色，以及该主题下每个 Tab 的图片（Tab 的图片写作 "@cyl.asset.<key>.<state>"，
    //      因此切换主题会原地切换图标）。
    NSString *defaultTheme = self.defaultTheme ?: themeList.allKeys.firstObject;
    if (themeList.count > 0) {
        NSMutableDictionary *compiled = [NSMutableDictionary dictionary];
        for (NSString *theme in themeList) {
            NSMutableDictionary *values = [CYLManifestValue(themeList, theme, [NSDictionary class]) mutableCopy] ?: [NSMutableDictionary dictionary];
            NSDictionary *barKeys = @{ @"color" : CYLTabBarItemTitleColor, @"selectedColor" : CYLTabBarItemSelectedTitleColor, @"backgroundColor" : CYLTabBarBackgroundColor };
            for (NSString *manifestKey in barKeys) {
                id color = [self resolvedValue:tabBar[manifestKey] theme:theme];
                if (color) {
                    values[barKeys[manifestKey]] = color;
                }
            }
            for (NSDictionary *item in imageItems) {
                NSString *key = CYLManifestString(item, @"key") ?: @"";
                NSString *normal = [self imagePathForValue:item[@"iconPath"] theme:theme];
                NSString *selected = [self imagePathForValue:item[@"selectedIconPath"] theme:theme] ?: normal;
                values[[NSString stringWithFormat:@"%@%@.normal", CYLManifestAssetNamePrefix, key]] = normal;
                values[[NSString stringWithFormat:@"%@%@.selected", CYLManifestAssetNamePrefix, key]] = selected;
            }
            compiled[theme] = values;
        }
        configuration[CYLTabBarControllerThemes] = compiled;
        configuration[CYLTabBarControllerThemeIdentifier] = defaultTheme;
        // [EN] The skins' own manager keeps the app's skins apart (default: the controller's, i.e. the default manager).
        // [CN] 皮肤使用独立的管理器，与 App 自己的皮肤分开（默认：TabBarController 的管理器，即默认管理器）。
        configuration[CYLTabBarControllerThemeManagerName] = CYLManifestString(themes, @"managerName");
        NSString *darkTheme = CYLManifestString(themes, @"darkMode");
        if (darkTheme && themeList[darkTheme]) {
            configuration[CYLTabBarControllerDarkThemeIdentifier] = darkTheme;
        }
        [items enumerateObjectsUsingBlock:^(NSDictionary *attributes, NSUInteger index, BOOL *stop) {
            NSMutableDictionary *withImages = [attributes mutableCopy];
            NSString *key = CYLManifestString(imageItems[index], @"key") ?: @"";
            withImages[CYLTabBarItemImage] = [NSString stringWithFormat:@"@%@%@.normal", CYLManifestAssetNamePrefix, key];
            withImages[CYLTabBarItemSelectedImage] = [NSString stringWithFormat:@"@%@%@.selected", CYLManifestAssetNamePrefix, key];
            items[index] = withImages;
        }];
    } else {
        [items enumerateObjectsUsingBlock:^(NSDictionary *attributes, NSUInteger index, BOOL *stop) {
            NSMutableDictionary *withImages = [attributes mutableCopy];
            withImages[CYLTabBarItemImage] = [self imagePathForValue:imageItems[index][@"iconPath"] theme:nil];
            withImages[CYLTabBarItemSelectedImage] = [self imagePathForValue:imageItems[index][@"selectedIconPath"] theme:nil];
            items[index] = withImages;
        }];
    }
    configuration[CYLTabBarControllerTabBarItemsAttributes] = items;
    NSDictionary *midButton = CYLManifestValue(tabBar, @"midButton", [NSDictionary class]);
    if (midButton && [self itemIsForThisApp:midButton]) {
        NSMutableDictionary *plus = [NSMutableDictionary dictionary];
        plus[CYLTabBarItemIdentifier] = CYLManifestString(midButton, @"key");
        plus[CYLTabBarItemTitle] = CYLManifestString(midButton, @"text");
        plus[CYLTabBarItemImage] = [self imagePathForValue:midButton[@"iconPath"] theme:defaultTheme];
        plus[CYLPlusButtonBackgroundImage] = [self imagePathForValue:midButton[@"backgroundImage"] theme:defaultTheme];
        id index = midButton[@"index"];
        if ([index respondsToSelector:@selector(integerValue)]) {
            plus[CYLPlusButtonIndexInTabBar] = @([index integerValue]);
        }
        id width = midButton[@"width"];
        id height = midButton[@"height"];
        if ([width respondsToSelector:@selector(doubleValue)] && [height respondsToSelector:@selector(doubleValue)]) {
            plus[CYLPlusButtonSize] = [NSString stringWithFormat:@"{%g, %g}", [width doubleValue], [height doubleValue]];
        }
        if (![CYLManifestString(midButton, @"action") isEqualToString:@"callback"]) {
            plus[CYLTabBarItemPageIdentifier] = CYLManifestString(midButton, @"pagePath");
        }
        configuration[CYLTabBarControllerPlusButton] = plus;
        // [EN] The plus button is registered per context: one of its own. [CN] PlusButton 按 context 注册：使用独立的 context。
        configuration[CYLTabBarControllerContext] = [@"CYLTabBarManifest:" stringByAppendingString:self.identifier ?: @"manifest"];
    }
    NSDictionary *localization = CYLManifestValue(self.dictionary, @"localization", [NSDictionary class]);
    if (localization) {
        NSMutableDictionary *value = [NSMutableDictionary dictionary];
        value[CYLTabBarLocalizationTableName] = CYLManifestString(localization, @"tableName");
        NSString *route = CYLManifestString(localization, @"route");
        if (route) {
            value[CYLTabBarLocalizationPath] = [CYLResourceRoute pathForRoute:route baseDirectory:self.baseDirectory];
        }
        configuration[CYLTabBarControllerLocalization] = value;
    }
    return configuration;
}

- (CYLTabBarController *)tabBarControllerWithError:(NSError **)error {
    if (![NSThread isMainThread]) {
        if (error) {
            *error = CYLManifestError(CYLTabBarConfigurationErrorMainThreadRequired, @"A tab bar controller can only be created on the main thread.");
        }
        return nil;
    }
    CYLTabBarController *tabBarController = [CYLTabBarController tabBarControllerWithConfiguration:self.configuration];
    if (tabBarController.viewControllers.count == 0) {
        if (error) {
            *error = CYLManifestError(CYLTabBarConfigurationErrorNoPages, @"No tab of the manifest found its page: register the pages first (docs/Tab-Page-Registry.md).");
        }
        return nil;
    }
    return tabBarController;
}

@end

#pragma mark - CYLTabBarManifestLoader

@implementation CYLTabBarManifestLoader

/// [EN] sandbox:Caches/CYLTabBarManifest. [CN] sandbox:Caches/CYLTabBarManifest。
+ (NSString *)cacheDirectory {
    return [CYLResourceRoute pathForRoute:@"sandbox:Caches/CYLTabBarManifest" baseDirectory:nil];
}

- (CYLTabBarManifest *)cachedManifest {
    NSString *root = [CYLTabBarManifestLoader cacheDirectory];
    NSArray<NSString *> *versions = [[NSFileManager.defaultManager contentsOfDirectoryAtPath:root error:NULL]
                                     sortedArrayUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        return CYLManifestCompareVersions(b, a);
    }];
    for (NSString *version in versions) {
        NSString *path = [[root stringByAppendingPathComponent:version] stringByAppendingPathComponent:@"manifest.json"];
        NSDictionary *dictionary = [CYLTabBarConfigurationParser dictionaryWithContentsOfFile:path error:NULL];
        CYLTabBarManifest *manifest = dictionary ? [CYLTabBarManifest manifestWithDictionary:dictionary baseDirectory:path.stringByDeletingLastPathComponent error:NULL] : nil;
        if (manifest && [manifest isEligibleAtDate:self.date ?: [NSDate date] error:NULL] && [manifest verifyAssetsWithError:NULL]) {
            return manifest;
        }
    }
    return nil;
}

- (void)loadManifestWithURL:(NSURL *)URL completion:(CYLTabBarManifestCompletion)completion {
    NSURLSessionDataTask *task = [NSURLSession.sharedSession dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *downloadError) {
        NSError *error = downloadError;
        NSDictionary *dictionary = data ? [CYLTabBarConfigurationParser dictionaryWithData:data format:CYLTabBarConfigurationFormatJSON error:&error] : nil;
        CYLTabBarManifest *remote = dictionary ? [CYLTabBarManifest manifestWithDictionary:dictionary baseDirectory:nil error:&error] : nil;
        if (remote && ![remote isEligibleAtDate:self.date ?: [NSDate date] error:&error]) {
            remote = nil;
        }
        CYLTabBarManifest *saved = remote ? [self saveManifest:remote data:data fromURL:URL error:&error] : nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self finishWithRemote:saved fallbackFrom:(saved ? nil : (remote ?: dictionary)) error:error completion:completion];
        });
    }];
    [task resume];
}

/// [EN] Downloads every asset next to the manifest, checks it, and keeps the folder only when all are good (Expo).
/// [CN] 下载清单旁边的每个资源并校验，全部通过才保留该目录（与 Expo 相同）。
- (CYLTabBarManifest *)saveManifest:(CYLTabBarManifest *)manifest data:(NSData *)data fromURL:(NSURL *)URL error:(NSError **)error {
    NSString *version = manifest.version ?: @"0";
    if ([version containsString:@"/"] || [version containsString:@".."]) {
        if (error) *error = CYLManifestError(CYLTabBarConfigurationErrorUnsupportedManifest, @"The manifest version is not a valid folder name.");
        return nil;
    }
    NSFileManager *manager = NSFileManager.defaultManager;
    NSString *folder = [[CYLTabBarManifestLoader cacheDirectory] stringByAppendingPathComponent:version];
    NSString *staging = [folder stringByAppendingString:@".download"];
    [manager removeItemAtPath:staging error:NULL];
    [manager createDirectoryAtPath:staging withIntermediateDirectories:YES attributes:nil error:NULL];
    NSDictionary *assets = CYLManifestValue(manifest.dictionary, @"assets", [NSDictionary class]);
    NSString *baseURLText = CYLManifestString(assets, @"baseURL");
    NSURL *baseURL = baseURLText ? [NSURL URLWithString:baseURLText] : URL.URLByDeletingLastPathComponent;
    // [EN] Saved with baseRoute "." so the cached copy reads its assets from its own folder. [CN] 以 baseRoute "." 保存，缓存副本从自己的目录读取资源。
    NSMutableDictionary *cached = [manifest.dictionary mutableCopy];
    NSMutableDictionary *cachedAssets = [assets mutableCopy] ?: [NSMutableDictionary dictionary];
    cachedAssets[@"baseRoute"] = @".";
    cached[@"assets"] = cachedAssets;
    CYLTabBarManifest *staged = [CYLTabBarManifest manifestWithDictionary:cached baseDirectory:staging error:error];
    for (NSDictionary *entry in staged.assetEntries) {
        NSString *path = [staged pathOfEntry:entry];
        NSString *urlText = CYLManifestString(entry, @"url");
        NSURL *assetURL = urlText ? [NSURL URLWithString:urlText] : [NSURL URLWithString:CYLManifestString(entry, @"path") relativeToURL:baseURL];
        NSData *assetData = assetURL && path ? [NSData dataWithContentsOfURL:assetURL options:0 error:error] : nil;
        if (!assetData) {
            [manager removeItemAtPath:staging error:NULL];
            if (error && !*error) *error = CYLManifestError(CYLTabBarConfigurationErrorAssetInvalid, [NSString stringWithFormat:@"Asset %@ could not be downloaded.", CYLManifestString(entry, @"path")]);
            return nil;
        }
        [manager createDirectoryAtPath:path.stringByDeletingLastPathComponent withIntermediateDirectories:YES attributes:nil error:NULL];
        [assetData writeToFile:path atomically:YES];
    }
    if (![staged verifyAssetsWithError:error]) {
        [manager removeItemAtPath:staging error:NULL];
        return nil;
    }
    NSData *json = [NSJSONSerialization dataWithJSONObject:cached options:0 error:NULL];
    [json writeToFile:[staging stringByAppendingPathComponent:@"manifest.json"] atomically:YES];
    [manager removeItemAtPath:folder error:NULL];
    if (![manager moveItemAtPath:staging toPath:folder error:error]) {
        return nil;
    }
    return [CYLTabBarManifest manifestWithDictionary:cached baseDirectory:folder error:error];
}

- (void)finishWithRemote:(CYLTabBarManifest *)remote fallbackFrom:(id)failed error:(NSError *)error completion:(CYLTabBarManifestCompletion)completion {
    if (remote && [self shouldApply:remote source:CYLTabBarManifestSourceRemote]) {
        if ([self.delegate respondsToSelector:@selector(manifestLoader:didApplyManifest:source:)]) {
            [self.delegate manifestLoader:self didApplyManifest:remote source:CYLTabBarManifestSourceRemote];
        }
        completion(remote, CYLTabBarManifestSourceRemote, nil);
        return;
    }
    // [EN] The policy of the failed manifest when it could be read, else "previous". [CN] 能读取失败的清单时使用其策略，否则使用 "previous"。
    NSDictionary *failedDictionary = [failed isKindOfClass:[CYLTabBarManifest class]] ? [failed dictionary] : ([failed isKindOfClass:[NSDictionary class]] ? failed : nil);
    NSDictionary *fallback = CYLManifestValue(failedDictionary, @"fallback", [NSDictionary class]);
    NSString *policy = CYLManifestString(fallback, @"onError") ?: @"previous";
    NSString *embeddedRoute = self.embeddedManifestRoute ?: CYLManifestString(fallback, @"embeddedRoute");
    CYLTabBarManifest *manifest = nil;
    CYLTabBarManifestSource source = CYLTabBarManifestSourceNone;
    if ([policy isEqualToString:@"previous"]) {
        manifest = [self cachedManifest];
        source = manifest ? CYLTabBarManifestSourceCache : CYLTabBarManifestSourceNone;
    }
    if (!manifest && ![policy isEqualToString:@"none"] && embeddedRoute) {
        manifest = [CYLTabBarManifest manifestWithRoute:embeddedRoute error:NULL];
        source = manifest ? CYLTabBarManifestSourceEmbedded : CYLTabBarManifestSourceNone;
    }
    if (manifest && ![self shouldApply:manifest source:source]) {
        manifest = nil;
        source = CYLTabBarManifestSourceNone;
    }
    NSError *reason = error ?: CYLManifestError(CYLTabBarConfigurationErrorUnsupportedManifest, @"The manifest was refused.");
    if ([self.delegate respondsToSelector:@selector(manifestLoader:didFailWithError:fallbackSource:)]) {
        [self.delegate manifestLoader:self didFailWithError:reason fallbackSource:source];
    }
    if (manifest && [self.delegate respondsToSelector:@selector(manifestLoader:didApplyManifest:source:)]) {
        [self.delegate manifestLoader:self didApplyManifest:manifest source:source];
    }
    completion(manifest, source, reason);
}

- (BOOL)shouldApply:(CYLTabBarManifest *)manifest source:(CYLTabBarManifestSource)source {
    if ([self.delegate respondsToSelector:@selector(manifestLoader:shouldApplyManifest:source:)]) {
        return [self.delegate manifestLoader:self shouldApplyManifest:manifest source:source];
    }
    return YES;
}

@end
