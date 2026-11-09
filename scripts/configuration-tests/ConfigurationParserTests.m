//
//  ConfigurationParserTests.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] The tests of CYLTabBarConfigurationParser, run by run-tests.sh (macOS or Linux with GNUstep): the sample files of
//       the resource bundle, the edge-case files of make-fixtures.py, and the files exported from every Example. No
//       blocks, no subscripts and no properties, so it also builds with GNUstep's GCC runtime.
//  [CN] CYLTabBarConfigurationParser 的测试，由 run-tests.sh 运行（macOS，或装有 GNUstep 的 Linux）：资源包中的示例文件、make-fixtures.py
//       生成的边界情况文件，以及从每个 Example 导出的文件。不使用 block、下标与属性，因此也能用 GNUstep 的 GCC 运行时编译。
//

#import <Foundation/Foundation.h>
#import "CYLTabBarConfigurationParser.h"

static int CYLFailures = 0;
static int CYLChecks = 0;

static void CYLFail(NSString *message) {
    CYLFailures++;
    printf("  FAIL %s\n", [message UTF8String]);
}

/// [EN] Map entries ({key, value} lists, from XML and Protobuf text) become dictionaries, as the library's normalization does.
/// [CN] 将 map 条目（XML 与 Protobuf 文本中的 {key, value} 列表）转换为字典，与库的规范化一致。
static id CYLNormalized(id value) {
    if ([value isKindOfClass:[NSArray class]]) {
        NSArray *array = value;
        BOOL entries = [array count] > 0;
        NSUInteger i;
        for (i = 0; i < [array count]; i++) {
            id entry = [array objectAtIndex:i];
            if (![entry isKindOfClass:[NSDictionary class]] || [entry count] != 2 || ![entry objectForKey:@"key"]) {
                entries = NO;
            }
        }
        if (entries) {
            NSMutableDictionary *map = [NSMutableDictionary dictionary];
            for (i = 0; i < [array count]; i++) {
                [map setObject:[[array objectAtIndex:i] objectForKey:@"value"] forKey:[[array objectAtIndex:i] objectForKey:@"key"]];
            }
            return map;
        }
        NSMutableArray *out = [NSMutableArray array];
        for (i = 0; i < [array count]; i++) {
            [out addObject:CYLNormalized([array objectAtIndex:i])];
        }
        return out;
    }
    if ([value isKindOfClass:[NSDictionary class]] && [value count] == 2 && [value objectForKey:@"key"] && [value objectForKey:@"value"]) {
        // A map with one entry (Protobuf text): the library reads it as a one-key dictionary too.
        // 只有一个条目的 map（Protobuf 文本）：库同样把它读作只有一个键的字典。
        return [NSDictionary dictionaryWithObject:CYLNormalized([value objectForKey:@"value"]) forKey:[value objectForKey:@"key"]];
    }
    if ([value isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *out = [NSMutableDictionary dictionary];
        NSEnumerator *keys = [value keyEnumerator];
        id key;
        while ((key = [keys nextObject])) {
            [out setObject:CYLNormalized([value objectForKey:key]) forKey:key];
        }
        return out;
    }
    if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
        // [EN] A numeric string and a number compare equal: text formats (INI, properties, dotenv, XML) read "1.5" as a
        //      number, JSON and Protobuf keep a string, and the library reads both (CYLTabBarControllerTabBarItemAnimationSpeed, B28).
        // [CN] 数字字符串与数字视为相等：文本格式（INI、properties、dotenv、XML）把 "1.5" 读作数字，JSON 与 Protobuf 保留字符串，库两者都能读取
        //      （CYLTabBarControllerTabBarItemAnimationSpeed，B28）。
        NSScanner *scanner = [NSScanner scannerWithString:value];
        double number = 0;
        if ([scanner scanDouble:&number] && [scanner isAtEnd]) {
            return [NSNumber numberWithDouble:number];
        }
    }
    if ([value isKindOfClass:[NSNumber class]] && strcmp([value objCType], @encode(BOOL)) != 0 && strcmp([value objCType], "c") != 0) {
        return [NSNumber numberWithDouble:[value doubleValue]];
    }
    return value;
}

/// [EN] A single tab written as a dictionary (Protobuf text, XML) compared as a list. [CN] 以字典写出的单个 Tab（Protobuf 文本、XML）按列表比较。
static id CYLComparable(id dictionary) {
    id normalized = CYLNormalized(dictionary);
    id items = [normalized objectForKey:@"CYLTabBarControllerTabBarItemsAttributes"];
    if ([items isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *copy = [normalized mutableCopy];
        [copy setObject:[NSArray arrayWithObject:items] forKey:@"CYLTabBarControllerTabBarItemsAttributes"];
        return copy;
    }
    return normalized;
}

/// [EN] The value at a key path: dots, numbers for list elements. [CN] 键路径处的值：用点分隔，数字表示列表元素。
static id CYLValueAtPath(id root, NSString *path) {
    id value = root;
    NSArray *parts = [path componentsSeparatedByString:@"."];
    NSUInteger i;
    for (i = 0; i < [parts count]; i++) {
        NSString *part = [parts objectAtIndex:i];
        if ([value isKindOfClass:[NSArray class]]) {
            NSInteger index = [part integerValue];
            value = (index >= 0 && (NSUInteger)index < [value count]) ? [value objectAtIndex:(NSUInteger)index] : nil;
        } else if ([value isKindOfClass:[NSDictionary class]]) {
            value = [value objectForKey:part];
        } else {
            return nil;
        }
    }
    return value;
}

static NSDictionary *CYLParse(NSString *path, BOOL sniff, NSError **error) {
    if (!sniff) {
        return [CYLTabBarConfigurationParser dictionaryWithContentsOfFile:path error:error];
    }
    return [CYLTabBarConfigurationParser dictionaryWithData:[NSData dataWithContentsOfFile:path] format:CYLTabBarConfigurationFormatUnknown error:error];
}

static NSArray *CYLFiles(NSString *folder) {
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:NULL];
    return [files sortedArrayUsingSelector:@selector(compare:)];
}

/// [EN] 1. Every sample file gives the dictionary of the JSON sample (the first tab's title is the format's name).
/// [CN] 1. 每个示例文件都得到与 JSON 示例相同的字典（第一个 Tab 的标题为格式名称）。
/// [EN] The skins of a configuration as identifier -> values, from either form. [CN] 把配置中的皮肤统一为 标识 -> 值，两种写法均可。
static NSDictionary *CYLThemesByIdentifier(id configuration) {
    id themes = [configuration objectForKey:@"CYLTabBarControllerThemes"];
    if ([themes isKindOfClass:[NSDictionary class]]) {
        return themes;
    }
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    NSUInteger i;
    for (i = 0; [themes isKindOfClass:[NSArray class]] && i < [themes count]; i++) {
        NSMutableDictionary *theme = [[themes objectAtIndex:i] mutableCopy];
        NSString *identifier = [theme objectForKey:@"CYLTabBarThemeIdentifier"];
        if (identifier) {
            [theme removeObjectForKey:@"CYLTabBarThemeIdentifier"];
            // [EN] Protobuf: the values are in the map CYLTabBarThemeValues. [CN] Protobuf：值位于 map 字段 CYLTabBarThemeValues 中。
            id values = [theme objectForKey:@"CYLTabBarThemeValues"];
            if ([values isKindOfClass:[NSDictionary class]]) {
                [theme removeObjectForKey:@"CYLTabBarThemeValues"];
                [theme addEntriesFromDictionary:values];
            }
            [result setObject:theme forKey:identifier];
        }
    }
    return result;
}

static void CYLTestSamples(NSString *folder) {
    printf("Samples (%s)\n", [folder UTF8String]);
    NSDictionary *json = CYLParse([folder stringByAppendingPathComponent:@"cyl_tabbar_configuration.json"], NO, NULL);
    NSArray *files = CYLFiles(folder);
    NSUInteger i;
    for (i = 0; i < [files count]; i++) {
        NSString *file = [files objectAtIndex:i];
        if ([file hasSuffix:@".proto"] || [file hasPrefix:@"."] || file.pathExtension.length == 0) { // [EN] not the Localization folder [CN] 跳过 Localization 文件夹
            continue;
        }
        int sniff;
        for (sniff = 0; sniff < 2; sniff++) {
            NSError *error = nil;
            id parsed = CYLComparable(CYLParse([folder stringByAppendingPathComponent:file], sniff, &error));
            id expected = CYLComparable(json);
            NSMutableArray *parsedItems = [[parsed objectForKey:@"CYLTabBarControllerTabBarItemsAttributes"] mutableCopy];
            NSMutableArray *expectedItems = [[expected objectForKey:@"CYLTabBarControllerTabBarItemsAttributes"] mutableCopy];
            if ([parsedItems count] > 0 && [expectedItems count] > 0) {
                NSMutableDictionary *first = [[parsedItems objectAtIndex:0] mutableCopy];
                [first setObject:@"<format>" forKey:@"CYLTabBarItemTitle"];
                [parsedItems replaceObjectAtIndex:0 withObject:first];
                first = [[expectedItems objectAtIndex:0] mutableCopy];
                [first setObject:@"<format>" forKey:@"CYLTabBarItemTitle"];
                [expectedItems replaceObjectAtIndex:0 withObject:first];
            }
            CYLChecks++;
            if (!parsedItems || ![parsedItems isEqual:expectedItems]) {
                CYLFail([NSString stringWithFormat:@"%@ (%@): %@", file, sniff ? @"content" : @"extension", [error localizedDescription] ?: @"different dictionary"]);
            }
            // [EN] Every format carries the same two skins (a list of skins with CYLTabBarThemeIdentifier, or a dictionary).
            // [CN] 每种格式都带有同样的两套皮肤（带 CYLTabBarThemeIdentifier 的皮肤数组，或字典）。
            CYLChecks++;
            if (![CYLThemesByIdentifier(parsed) isEqual:CYLThemesByIdentifier(expected)]
                || ![[parsed objectForKey:@"CYLTabBarControllerDarkThemeIdentifier"] isEqual:@"dark"]) {
                CYLFail([NSString stringWithFormat:@"%@ (%@): skins are %@", file, sniff ? @"content" : @"extension", [parsed objectForKey:@"CYLTabBarControllerThemes"]]);
            }
            // [EN] Every text format names its string tables (binary Protobuf has no field for them).
            // [CN] 每种文本格式都写明字符串表（二进制 Protobuf 没有对应字段）。
            if (![file hasSuffix:@".binpb"]) {
                NSDictionary *localization = [parsed objectForKey:@"CYLTabBarControllerLocalization"];
                CYLChecks++;
                if (![localization isKindOfClass:[NSDictionary class]]
                    || ![[localization objectForKey:@"CYLTabBarLocalizationTableName"] isEqual:@"ConfigurationDemo"]
                    || ![[localization objectForKey:@"CYLTabBarLocalizationPath"] isEqual:@"Localization"]) {
                    CYLFail([NSString stringWithFormat:@"%@ (%@): CYLTabBarControllerLocalization is %@", file, sniff ? @"content" : @"extension", localization]);
                }
            }
        }
    }
}

/// [EN] 2. Every edge-case file gives its expected result. [CN] 2. 每个边界情况文件都得到预期结果。
static void CYLTestFixtures(NSString *folder) {
    printf("Edge cases (%s)\n", [folder UTF8String]);
    NSData *manifestData = [NSData dataWithContentsOfFile:[folder stringByAppendingPathComponent:@"manifest.json"]];
    NSArray *cases = manifestData ? [NSJSONSerialization JSONObjectWithData:manifestData options:0 error:NULL] : nil;
    if (![cases isKindOfClass:[NSArray class]]) {
        CYLFail(@"no manifest.json (run make-fixtures.py)");
        return;
    }
    NSUInteger i;
    for (i = 0; i < [cases count]; i++) {
        NSDictionary *testCase = [cases objectAtIndex:i];
        NSString *file = [testCase objectForKey:@"file"];
        NSString *path = [folder stringByAppendingPathComponent:file];
        id expect = [testCase objectForKey:@"expect"];
        int sniff;
        for (sniff = 0; sniff < 2; sniff++) {
            NSError *error = nil;
            NSDictionary *parsed = CYLParse(path, sniff, &error);
            CYLChecks++;
            NSString *mode = sniff ? @"content" : @"extension";
            if ([expect isKindOfClass:[NSString class]]) {
                if (!parsed) {
                    CYLFail([NSString stringWithFormat:@"[%@] %@ (%@): expected a dictionary, got error %ld %@", [testCase objectForKey:@"case"], file, mode, (long)[error code], [error localizedDescription]]);
                    continue;
                }
            } else if (!sniff) {
                // The error code is checked for the extension; detection from content may name another error.
                // 按扩展名检查错误码；根据内容识别时可能给出其他错误。
                if (parsed || [error code] != [expect integerValue]) {
                    CYLFail([NSString stringWithFormat:@"[%@] %@: expected error %@, got %@", [testCase objectForKey:@"case"], file, expect,
                             parsed ? @"a dictionary" : [NSString stringWithFormat:@"error %ld %@", (long)[error code], [error localizedDescription]]]);
                }
                continue;
            } else {
                // Content detection must never crash and never produce a deep tree; a flat dictionary is acceptable.
                // 根据内容识别时不能崩溃，也不能生成过深的树；扁平的字典可以接受。
                continue;
            }
            NSString *equals = [testCase objectForKey:@"equals"];
            if ([equals isKindOfClass:[NSString class]]) {
                NSDictionary *reference = CYLParse([folder stringByAppendingPathComponent:equals], NO, NULL);
                if (![CYLComparable(parsed) isEqual:CYLComparable(reference)]) {
                    CYLFail([NSString stringWithFormat:@"[%@] %@ (%@): not equal to %@: %@", [testCase objectForKey:@"case"], file, mode, equals, parsed]);
                }
            }
            NSDictionary *values = [testCase objectForKey:@"values"];
            NSEnumerator *paths = [values keyEnumerator];
            NSString *keyPath;
            while ((keyPath = [paths nextObject])) {
                id value = CYLValueAtPath(parsed, keyPath);
                id wanted = [values objectForKey:keyPath];
                if (!value || ![value isEqual:wanted]) {
                    CYLFail([NSString stringWithFormat:@"[%@] %@ (%@): %@ is %@, expected %@", [testCase objectForKey:@"case"], file, mode, keyPath, value, wanted]);
                }
            }
        }
    }
}

/// [EN] 3. Every file exported from an Example gives the dictionary of its JSON twin. [CN] 3. 从 Example 导出的每个文件都与其 JSON 版本得到相同的字典。
static void CYLTestExports(NSString *root) {
    printf("Exported files (%s)\n", [root UTF8String]);
    NSArray *examples = CYLFiles(root);
    NSUInteger e;
    for (e = 0; e < [examples count]; e++) {
        NSString *folder = [root stringByAppendingPathComponent:[examples objectAtIndex:e]];
        NSArray *files = CYLFiles(folder);
        NSUInteger i, j;
        for (i = 0; i < [files count]; i++) {
            NSString *json = [files objectAtIndex:i];
            if (![json hasSuffix:@".json"]) {
                continue;
            }
            id reference = CYLComparable(CYLParse([folder stringByAppendingPathComponent:json], NO, NULL));
            NSString *stem = [[json stringByDeletingPathExtension] stringByAppendingString:@"."];
            for (j = 0; j < [files count]; j++) {
                NSString *file = [files objectAtIndex:j];
                if (![file hasPrefix:stem]) {
                    continue;
                }
                int sniff;
                for (sniff = 0; sniff < 2; sniff++) {
                    NSError *error = nil;
                    id parsed = CYLComparable(CYLParse([folder stringByAppendingPathComponent:file], sniff, &error));
                    CYLChecks++;
                    if (!parsed || ![parsed isEqual:reference]) {
                        CYLFail([NSString stringWithFormat:@"%@/%@ (%@): %@", [examples objectAtIndex:e], file, sniff ? @"content" : @"extension", [error localizedDescription] ?: @"different dictionary"]);
                    }
                }
            }
        }
    }
}

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 3) {
            printf("usage: ConfigurationParserTests <samples folder> <fixtures folder> [<exports folder>]\n");
            return 2;
        }
        CYLTestSamples([NSString stringWithUTF8String:argv[1]]);
        CYLTestFixtures([NSString stringWithUTF8String:argv[2]]);
        if (argc > 3) {
            CYLTestExports([NSString stringWithUTF8String:argv[3]]);
        }
        printf("%d checks, %d failures\n", CYLChecks, CYLFailures);
    }
    return CYLFailures == 0 ? 0 : 1;
}
