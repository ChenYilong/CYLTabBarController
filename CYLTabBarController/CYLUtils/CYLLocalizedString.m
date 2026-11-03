//
//  CYLLocalizedString.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/02/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// FIX: issue #535 — moved from CYLLocalization.m into CYLUtils, shared by Core and CYLBadgeView.
// FIX: issue #535 — 从 CYLLocalization.m 移入 CYLUtils，供 Core 与 CYLBadgeView 共用。

#import "CYLLocalizedString.h"

NSString *const CYLLocalizationLanguageDidChangeNotification = @"CYLLocalizationLanguageDidChangeNotification";

static NSString *const CYLLocalizationTable = @"CYLTabBarController";
static NSString *const CYLLocalizationFallbackLanguage = @"en";

/// Any class of the library, to find the bundle it was built into.
@interface CYLLocalizationBundleToken : NSObject
@end
@implementation CYLLocalizationBundleToken
@end

NSBundle *CYLResourceBundle(void) {
    static NSBundle *resourceBundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // `CYLTabBarController.bundle` is shipped as is: inside the SPM module bundle, inside the framework (CocoaPods
        // with frameworks, Carthage), or inside the app (static CocoaPods).
        NSMutableArray<NSBundle *> *containers = [NSMutableArray array];
#if defined(SWIFTPM_MODULE_BUNDLE)
        [containers addObject:SWIFTPM_MODULE_BUNDLE];
#endif
        [containers addObject:[NSBundle bundleForClass:[CYLLocalizationBundleToken class]]];
        [containers addObject:[NSBundle mainBundle]];
        for (NSBundle *container in containers) {
            NSURL *url = [container URLForResource:CYLLocalizationTable withExtension:@"bundle"];
            resourceBundle = url ? [NSBundle bundleWithURL:url] : nil;
            if (resourceBundle) {
                break;
            }
        }
        resourceBundle = resourceBundle ?: containers.firstObject;
    });
    return resourceBundle;
}

static NSBundle *CYLLocalizationResourceBundle(void) {
    return CYLResourceBundle();
}

static NSString *CYLOverriddenLanguage;
static NSString *CYLResolvedLanguage;
static NSBundle *CYLResolvedLanguageBundle;

static NSObject *CYLLocalizationLock(void) {
    static NSObject *lock;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        lock = [[NSObject alloc] init];
    });
    return lock;
}

/// The closest language the table has to the first of `preferences`, else English.
static NSString *CYLLocalizationClosestLanguage(NSArray<NSString *> *preferences) {
    NSMutableArray<NSString *> *available = [CYLLocalizationResourceBundle().localizations mutableCopy];
    [available removeObject:@"Base"];
    NSString *language = [NSBundle preferredLocalizationsFromArray:available forPreferences:preferences].firstObject;
    return language.length > 0 ? language : CYLLocalizationFallbackLanguage;
}

/// The `*.lproj` bundle of a language the table has.
static NSBundle *CYLLocalizationBundleForLanguage(NSString *language) {
    NSString *path = [CYLLocalizationResourceBundle() pathForResource:language ofType:@"lproj"];
    return (path ? [NSBundle bundleWithPath:path] : nil) ?: CYLLocalizationResourceBundle();
}

/// The app's language, or the override; matched to the closest language the table has, else English.
static NSString *CYLLocalizationResolveLanguage(void) {
    NSString *wanted = CYLOverriddenLanguage;
    if (!wanted) {
        // The language the app's own texts are shown in, so every text on screen shares it.
        NSString *appLanguage = [NSBundle mainBundle].preferredLocalizations.firstObject;
        wanted = [appLanguage isEqualToString:@"Base"] ? nil : appLanguage;
    }
    return CYLLocalizationClosestLanguage(wanted ? @[wanted] : [NSLocale preferredLanguages]);
}

static NSBundle *CYLLocalizationLanguageBundle(NSString **languageOut) {
    @synchronized (CYLLocalizationLock()) {
        if (!CYLResolvedLanguageBundle) {
            CYLResolvedLanguage = CYLLocalizationResolveLanguage();
            CYLResolvedLanguageBundle = CYLLocalizationBundleForLanguage(CYLResolvedLanguage);
        }
        if (languageOut) {
            *languageOut = CYLResolvedLanguage;
        }
        return CYLResolvedLanguageBundle;
    }
}

NSString *CYLLocalizedString(NSString *key) {
    if (key.length == 0) {
        return key ?: @"";
    }
    NSBundle *languageBundle = CYLLocalizationLanguageBundle(NULL);
    return [languageBundle localizedStringForKey:key value:key table:CYLLocalizationTable] ?: key;
}

NSString *CYLLocalizedStringForLanguage(NSString *key, NSString *language) {
    if (key.length == 0) {
        return key ?: @"";
    }
    NSString *closest = CYLLocalizationClosestLanguage(language ? @[language] : [NSLocale preferredLanguages]);
    return [CYLLocalizationBundleForLanguage(closest) localizedStringForKey:key value:key table:CYLLocalizationTable] ?: key;
}

void CYLSetLocalizationLanguage(NSString *language) {
    @synchronized (CYLLocalizationLock()) {
        CYLOverriddenLanguage = [language copy];
        CYLResolvedLanguage = nil;
        CYLResolvedLanguageBundle = nil;
    }
    dispatch_block_t didChange = ^{
        // VoiceOver picks its voice from `accessibilityLanguage`; without it, an overridden language would be read with
        // the device language's voice.
        [UIApplication sharedApplication].accessibilityLanguage = language ? CYLLocalizationLanguage() : nil;
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLLocalizationLanguageDidChangeNotification object:nil];
    };
    if ([NSThread isMainThread]) {
        didChange();
    } else {
        dispatch_async(dispatch_get_main_queue(), didChange);
    }
}

NSString *CYLLocalizationLanguage(void) {
    NSString *language = nil;
    CYLLocalizationLanguageBundle(&language);
    return language ?: CYLLocalizationFallbackLanguage;
}
