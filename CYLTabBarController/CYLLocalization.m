//
//  CYLLocalization.m
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/02/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLLocalization.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>

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

NSArray<NSDictionary *> *CYLLocalizedTabBarItemsAttributes(NSArray<NSString *> *titles,
                                                           NSArray *images,
                                                           NSArray *selectedImages,
                                                           NSDictionary<NSNumber *, id> *darkImages) {
    NSMutableArray<NSDictionary *> *attributes = [NSMutableArray arrayWithCapacity:titles.count];
    [titles enumerateObjectsUsingBlock:^(NSString *title, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary *item = [NSMutableDictionary dictionaryWithObject:CYLLocalizedString(title) forKey:CYLTabBarItemTitle];
        item[CYLTabBarItemImage] = idx < images.count ? images[idx] : nil;
        item[CYLTabBarItemSelectedImage] = idx < selectedImages.count ? selectedImages[idx] : nil;
        item[CYLTabBarItemDarkImage] = darkImages[@(idx)];
        [attributes addObject:[item copy]];
    }];
    return [attributes copy];
}

NSString *CYLLocalizationLanguage(void) {
    NSString *language = nil;
    CYLLocalizationLanguageBundle(&language);
    return language ?: CYLLocalizationFallbackLanguage;
}

@implementation UIView (CYLLocalization)

- (void)cyl_localizeTexts {
    if ([self isKindOfClass:[UIButton class]]) {
        // The button's own title label is handled through its titles, not as a label.
        UIButton *button = (UIButton *)self;
        for (NSNumber *state in @[@(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateSelected), @(UIControlStateDisabled)]) {
            NSString *title = [button titleForState:state.unsignedIntegerValue];
            if (title.length > 0) {
                [button setTitle:CYLLocalizedString(title) forState:state.unsignedIntegerValue];
            }
        }
        return;
    }
    if ([self isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)self;
        if (label.text.length > 0) {
            label.text = CYLLocalizedString(label.text);
        }
    } else if ([self isKindOfClass:[UITextField class]]) {
        UITextField *textField = (UITextField *)self;
        if (textField.placeholder.length > 0) {
            textField.placeholder = CYLLocalizedString(textField.placeholder);
        }
    }
    for (UIView *subview in self.subviews) {
        [subview cyl_localizeTexts];
    }
}

@end

/// The language's name in that language with an uppercase first letter, e.g. "Español"; VoiceOver reads this instead of
/// a flag.
static NSString *CYLLocalizationNativeName(NSString *language) {
    NSLocale *locale = [NSLocale localeWithLocaleIdentifier:language];
    NSString *name = [locale localizedStringForLanguageCode:language];
    if (name.length == 0) {
        return language;
    }
    return [[[name substringToIndex:1] uppercaseStringWithLocale:locale] stringByAppendingString:[name substringFromIndex:1]];
}

/// Flag and the language's own name, e.g. "🇪🇸 Español".
static NSString *CYLLocalizationFlaggedName(NSString *language) {
    NSDictionary<NSString *, NSString *> *flags = @{@"en": @"🇺🇸", @"zh-Hans": @"🇨🇳", @"hi": @"🇮🇳", @"es": @"🇪🇸", @"ar": @"🇸🇦"};
    return [NSString stringWithFormat:@"%@ %@", flags[language] ?: @"🌐", CYLLocalizationNativeName(language)];
}

static NSString *const CYLLanguageCellIdentifier = @"CYLLanguageCell";

@implementation UIViewController (CYLLocalization)

+ (NSArray<NSString *> *)cyl_pickerLanguages {
    return @[@"en", @"zh-Hans", @"hi", @"es", @"ar"];
}

- (UITableViewCell *)cyl_languageCellForTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CYLLanguageCellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CYLLanguageCellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.detailTextLabel.textColor = [UIColor grayColor];
    }
    NSString *language = CYLLocalizationLanguage();
    cell.textLabel.text = [NSString stringWithFormat:@"🌐 %@：%@", CYLLocalizedString(@"语言"), CYLLocalizationFlaggedName(language)];
    // Always in the device language: readable whatever language was picked.
    cell.detailTextLabel.text = CYLLocalizedStringForLanguage(@"点击切换语言", nil);
    cell.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", CYLLocalizedString(@"语言"), CYLLocalizationNativeName(language)];
    cell.accessibilityHint = cell.detailTextLabel.text;
    cell.accessibilityTraits = UIAccessibilityTraitButton;
    return cell;
}

- (void)cyl_presentLanguagePicker {
    UIAlertController *picker = [UIAlertController alertControllerWithTitle:CYLLocalizedString(@"语言")
                                                                    message:CYLLocalizedStringForLanguage(@"点击切换语言", nil)
                                                             preferredStyle:UIAlertControllerStyleActionSheet];
    for (NSString *language in [[self class] cyl_pickerLanguages]) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:CYLLocalizationFlaggedName(language)
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *selected) {
            CYLSetLocalizationLanguage(language);
        }];
        action.accessibilityLabel = CYLLocalizationNativeName(language);
        [picker addAction:action];
    }
    [picker addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"跟随系统") style:UIAlertActionStyleDefault handler:^(UIAlertAction *selected) {
        CYLSetLocalizationLanguage(nil);
    }]];
    [picker addAction:[UIAlertAction actionWithTitle:CYLLocalizedString(@"取消") style:UIAlertActionStyleCancel handler:nil]];
    picker.popoverPresentationController.sourceView = self.view;
    picker.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds), 1, 1);
    [self presentViewController:picker animated:YES completion:nil];
}

@end

/*!
 * FIX: issue #488
 * [EN] DEBUG only. A replaced root view controller (e.g. a CYLTabBarController) should be deallocated once UIKit's
 *      transitions have finished; when it is still alive 3 seconds later, something keeps a strong reference to it,
 *      so this logs it. Use the Xcode Memory Graph to find the owner.
 * [CN] 仅 DEBUG。被替换的根控制器（如 CYLTabBarController）应在 UIKit 转场结束后释放；3 秒后仍存活说明有对象强引用了它，
 *      这里会打印出来。可用 Xcode 的 Memory Graph 找到持有者。
 */
static void CYLWarnIfStillAliveAfterReplacement(UIViewController *viewController) {
#if DEBUG
    if (!viewController) {
        return;
    }
    __weak UIViewController *weakViewController = viewController;
    NSString *description = [NSString stringWithFormat:@"<%@: %p>", NSStringFromClass(viewController.class), viewController];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakViewController) {
            NSLog(@"⚠️ CYLTabBarController: %@ is still alive 3s after it was replaced as the root view controller; "
                  @"something keeps a strong reference to it (see the Xcode Memory Graph). #488", description);
        }
    });
#else
    (void)viewController;
#endif
}

@implementation UIWindow (CYLLocalization)

- (void)cyl_setRootViewControllerProvider:(UIViewController * (^)(void))provider {
    id previousObserver = objc_getAssociatedObject(self, @selector(cyl_setRootViewControllerProvider:));
    if (previousObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:previousObserver];
    }
    __weak UIWindow *weakWindow = self;
    void (^reload)(void) = ^{
        BOOL rightToLeft = [NSLocale characterDirectionForLanguage:CYLLocalizationLanguage()] == NSLocaleLanguageDirectionRightToLeft;
        [UIView appearance].semanticContentAttribute = rightToLeft ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeUnspecified;
        UIViewController *previousRootViewController = weakWindow.rootViewController;
        weakWindow.rootViewController = provider();
        CYLWarnIfStillAliveAfterReplacement(previousRootViewController);
    };
    reload();
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:CYLLocalizationLanguageDidChangeNotification
                                                                    object:nil
                                                                     queue:[NSOperationQueue mainQueue]
                                                                usingBlock:^(NSNotification *note) {
        reload();
    }];
    objc_setAssociatedObject(self, @selector(cyl_setRootViewControllerProvider:), observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
