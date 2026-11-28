//
//  CYLAnimationKeyLookupStandIns.m
//  CYLTabBarItemAnimation tests
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>

// [EN] Objective-C stand-ins for the animation type lookup, which is Swift now (`CYLUtils/Swift/CYLAnimationKeyLookup.swift`, `@_cdecl`,
//      docs/Swift-Migration.md, step 122). This macOS harness builds no Swift, so run.sh links these instead; each one mirrors the Swift code.
//      Keep them in step with its table.
// [CN] 动画类型查找的 Objective-C 替身；该查找已是 Swift（`CYLUtils/Swift/CYLAnimationKeyLookup.swift`，`@_cdecl`，第 122 步）。本 macOS
//      测试不构建 Swift，因此 run.sh 链接这些替身；每个都对应 Swift 代码。请与其表格保持一致。

static NSArray<NSDictionary<NSString *, id> *> *CYLStandInTypeTable(void) {
    static NSArray *table;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSString *> *genericKeys = @[ @"CYLTabBarAnimationURL", @"CYLTabBarAnimationFilePath", @"CYLTabBarAnimationSize",
                                              @"CYLTabBarAnimationDarkURL", @"CYLTabBarAnimationDarkFilePath", @"CYLTabBarAnimationDarkColors" ];
        NSArray<NSString *> *suffixes = @[ @"URL", @"FilePath", @"Size", @"DarkURL", @"DarkFilePath", @"DarkColors" ];
        NSArray<NSArray *> *types = @[ @[ @"Lottie", @[ @"json", @"lottie" ], @"LottieSwift", @YES ], @[ @"PAG", @[ @"pag" ], @"PAG", @NO ],
                                       @[ @"Rive", @[ @"riv" ], @"Rive", @YES ], @[ @"SVGA", @[ @"svga" ], @"SVGA", @NO ],
                                       @[ @"GIF", @[ @"gif" ], @"GIF", @NO ] ];
        NSMutableArray *entries = [NSMutableArray array];
        for (NSArray *type in types) {
            NSMutableDictionary *keys = [NSMutableDictionary dictionary];
            for (NSUInteger index = 0; index < genericKeys.count; index++) {
                if ([type[3] boolValue] || ![suffixes[index] isEqualToString:@"DarkColors"]) {
                    keys[genericKeys[index]] = [NSString stringWithFormat:@"CYLTabBar%@%@", type[0], suffixes[index]];
                }
            }
            [entries addObject:@{ @"type" : type[0], @"extensions" : type[1], @"pod" : type[2], @"keys" : keys }];
        }
        table = [entries copy];
    });
    return table;
}

NSString *_Nullable CYLAnimationTypeOfFile(NSDictionary *_Nullable attributes, NSURL *_Nullable fileURL) {
    if ([attributes isKindOfClass:[NSDictionary class]]) {
        for (NSDictionary *entry in CYLStandInTypeTable()) {
            for (NSString *key in [entry[@"keys"] allValues]) {
                if (attributes[key]) {
                    return entry[@"type"];
                }
            }
        }
    }
    NSString *extension = fileURL.path.pathExtension.lowercaseString;
    if (extension.length == 0) {
        return nil;
    }
    for (NSDictionary *entry in CYLStandInTypeTable()) {
        if ([entry[@"extensions"] containsObject:extension]) {
            return entry[@"type"];
        }
    }
    return nil;
}

NSArray<NSString *> *CYLAnimationKnownTypes(void) {
    return [CYLStandInTypeTable() valueForKey:@"type"];
}

NSString *_Nullable CYLAnimationSubspecOfType(NSString *_Nullable type) {
    for (NSDictionary *entry in CYLStandInTypeTable()) {
        if (type.length > 0 && [entry[@"type"] isEqualToString:type]) {
            return entry[@"pod"];
        }
    }
    return nil;
}
