//
//  CYLDemoLocalization.m
//  CYLTabBarController examples
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 2026/11/11.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLDemoLocalization.h"

static NSString *const CYLDemoLocalizationTable = @"CYLDemo";
static NSString *const CYLDemoLocalizationFallbackLanguage = @"en";

/// [EN] `CYLDemo.bundle` in the app, or nil. [CN] App 中的 `CYLDemo.bundle`，没有时为 nil。
static NSBundle *_Nullable CYLDemoLocalizationBundle(void) {
    static NSBundle *bundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *url = [[NSBundle mainBundle] URLForResource:@"CYLDemo" withExtension:@"bundle"];
        bundle = url ? [NSBundle bundleWithURL:url] : nil;
    });
    return bundle;
}

/// [EN] The `.lproj` of `language` in `CYLDemo.bundle`, else English. [CN] `CYLDemo.bundle` 中 `language` 的 `.lproj`，没有时为英语。
static NSBundle *_Nullable CYLDemoLocalizationLanguageBundle(NSString *language) {
    NSBundle *bundle = CYLDemoLocalizationBundle();
    NSString *path = [bundle pathForResource:language ofType:@"lproj"] ?: [bundle pathForResource:CYLDemoLocalizationFallbackLanguage ofType:@"lproj"];
    return path ? [NSBundle bundleWithPath:path] : nil;
}

NSString *CYLDemoLocalizedString(NSString *key) {
    if (key.length == 0) {
        return key ?: @"";
    }
    // [EN] A sentinel tells "not in the demo table" apart from a translation equal to the key.
    // [CN] 用哨兵值区分「示例表中没有」与「译文恰好等于键」。
    static NSString *const missing = @"<CYLDemoLocalizedString: missing>";
    NSString *value = [CYLDemoLocalizationLanguageBundle(CYLLocalizationLanguage()) localizedStringForKey:key value:missing table:CYLDemoLocalizationTable];
    if (value.length == 0 || [value isEqualToString:missing]) {
        return CYLLocalizedString(key);
    }
    return value;
}
