//
//  CYLLocalization.m
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/02/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLLocalization.h"

static NSString *const CYLLocalizationTable = @"CYLTabBarController";
static NSString *const CYLLocalizationFallbackLanguage = @"en";

/// Any class of the library, to find the bundle it was built into.
@interface CYLLocalizationBundleToken : NSObject
@end
@implementation CYLLocalizationBundleToken
@end

/// The bundle that holds the `*.lproj` folders: the SPM resource bundle, the CocoaPods resource bundle
/// (`resource_bundles`, inside the framework or the app), or the Carthage framework itself.
static NSBundle *CYLLocalizationResourceBundle(void) {
    static NSBundle *resourceBundle;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if defined(SWIFTPM_MODULE_BUNDLE)
        resourceBundle = SWIFTPM_MODULE_BUNDLE;
#else
        NSBundle *codeBundle = [NSBundle bundleForClass:[CYLLocalizationBundleToken class]];
        NSURL *resourceBundleURL = [codeBundle URLForResource:CYLLocalizationTable withExtension:@"bundle"];
        resourceBundle = (resourceBundleURL ? [NSBundle bundleWithURL:resourceBundleURL] : nil) ?: codeBundle;
#endif
    });
    return resourceBundle;
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

/// The app's language, or the override; matched to the closest language the table has, else English.
static NSString *CYLLocalizationResolveLanguage(void) {
    NSBundle *resourceBundle = CYLLocalizationResourceBundle();
    NSMutableArray<NSString *> *available = [resourceBundle.localizations mutableCopy];
    [available removeObject:@"Base"];
    NSString *wanted = CYLOverriddenLanguage;
    if (!wanted) {
        // The language the app's own texts are shown in, so every text on screen shares it.
        NSString *appLanguage = [NSBundle mainBundle].preferredLocalizations.firstObject;
        wanted = [appLanguage isEqualToString:@"Base"] ? nil : appLanguage;
    }
    NSArray<NSString *> *preferences = wanted ? @[wanted] : [NSLocale preferredLanguages];
    NSString *language = [NSBundle preferredLocalizationsFromArray:available forPreferences:preferences].firstObject;
    return language.length > 0 ? language : CYLLocalizationFallbackLanguage;
}

static NSBundle *CYLLocalizationLanguageBundle(NSString **languageOut) {
    @synchronized (CYLLocalizationLock()) {
        if (!CYLResolvedLanguageBundle) {
            CYLResolvedLanguage = CYLLocalizationResolveLanguage();
            NSString *path = [CYLLocalizationResourceBundle() pathForResource:CYLResolvedLanguage ofType:@"lproj"];
            CYLResolvedLanguageBundle = (path ? [NSBundle bundleWithPath:path] : nil) ?: CYLLocalizationResourceBundle();
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

void CYLSetLocalizationLanguage(NSString *language) {
    @synchronized (CYLLocalizationLock()) {
        CYLOverriddenLanguage = [language copy];
        CYLResolvedLanguage = nil;
        CYLResolvedLanguageBundle = nil;
    }
}

NSString *CYLLocalizationLanguage(void) {
    NSString *language = nil;
    CYLLocalizationLanguageBundle(&language);
    return language ?: CYLLocalizationFallbackLanguage;
}
