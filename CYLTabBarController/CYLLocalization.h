//
//  CYLLocalization.h
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/02/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

// FIX: issue #535 — CYLLocalizedString(), CYLResourceBundle(), CYLSetLocalizationLanguage() and the rest of the string
// table live in CYLUtils, shared with CYLBadgeView. 字符串表相关函数位于 CYLUtils，与 CYLBadgeView 共用。
#if __has_include("CYLUtils/CYLLocalizedString.h")
#import "CYLUtils/CYLLocalizedString.h"
#else
#import "CYLLocalizedString.h"
#endif

NS_ASSUME_NONNULL_BEGIN

/// Marks a function that returns translated text, for the static analyzer's localizability checker.
#define CYL_RETURNS_LOCALIZED_STRING __attribute__((annotate("returns_localized_nsstring")))

/*!
<<<<<<< HEAD
 * [EN] Returns the translation of `key` from the library's string table (`CYLTabBarController.strings`, shipped in the
 *      Core subspec, so no extra import or resource is needed), or `key` itself when there is none. The key is the
 *      original text, so wrapping a literal is all a call site needs:
 *
 *          self.navigationItem.title = CYLLocalizedString(@"首页");       // Objective-C
 *          title = CYLLocalizedString("首页")                            // Swift
 *          [NSString stringWithFormat:CYLLocalizedString(@"首页(%@)"), @(row)]
 *
 *      It is a C function rather than a macro, so Swift calls it exactly the same way.
 *
 *      Every text in one language: the language is the one the app itself is displayed in
 *      (`[NSBundle mainBundle].preferredLocalizations`), matched to the closest available translation, and English when
 *      there is none. So the library never shows a language the app does not; an app that declares
 *      `CFBundleLocalizations` follows the device language. `CYLSetLocalizationLanguage()` overrides it.
 *      Thread-safe.
 * [CN] 返回 `key` 在本库字符串表（`CYLTabBarController.strings`，随 Core 子模块提供，无需额外导入资源）中的译文，没有译文时返回
 *      `key` 本身。key 即原文，调用处只需把字面量包起来（示例见上方英文部分）。
 *      使用 C 函数而不是宏，因此 Swift 中的写法完全相同。
 *
 *      所有文字使用同一种语言：语言取 App 自身当前显示的语言（`[NSBundle mainBundle].preferredLocalizations`），匹配到最接近的译文，
 *      没有时使用英文。因此本库不会显示 App 本身不支持的语言；声明了 `CFBundleLocalizations` 的 App 会跟随设备语言。
 *      可用 `CYLSetLocalizationLanguage()` 指定。线程安全。
 */
FOUNDATION_EXTERN NSString *CYLLocalizedString(NSString *key) CYL_RETURNS_LOCALIZED_STRING;

/*!
 * [EN] The library's resource bundle, `CYLTabBarController.bundle` (Core, no extra import). It holds the `*.lproj` string
 *      tables; images and other resources can be added to it too and loaded from it, e.g.
 *      `[UIImage imageNamed:@"icon" inBundle:CYLResourceBundle() compatibleWithTraitCollection:nil]`.
 * [CN] 本库的资源包 `CYLTabBarController.bundle`（属于 Core，无需额外导入）。其中存放各语言的 `*.lproj` 字符串表；图片等资源也可以
 *      放进同一个 bundle，并从中读取，例如上面的 `UIImage` 示例。
 */
FOUNDATION_EXTERN NSBundle *CYLResourceBundle(void);

/*!
 * [EN] Overrides the language of `CYLLocalizedString()`, e.g. @"ja" or @"zh-Hant", for an in-app language setting; nil
 *      follows the app again. Texts already shown keep their language until they are set again (e.g. the tab bar
 *      controller is created again).
 * [CN] 指定 `CYLLocalizedString()` 使用的语言，例如 @"ja"、@"zh-Hant"，用于 App 内切换语言；传 nil 恢复跟随 App。
 *      已显示的文字在重新设置之前（例如重新创建 TabBarController）保持原语言。
 *
 * [EN] VoiceOver: the app's `accessibilityLanguage` is set to the same language, so VoiceOver reads the texts with a
 *      matching voice even when it differs from the device language. Posts `CYLLocalizationLanguageDidChangeNotification`.
 * [CN] VoiceOver：同时把 App 的 `accessibilityLanguage` 设为该语言，即使与设备语言不同，VoiceOver 也会用对应语言的语音朗读。
 *      会发送 `CYLLocalizationLanguageDidChangeNotification`。
 */
FOUNDATION_EXTERN void CYLSetLocalizationLanguage(NSString * _Nullable language);

/*!
 * [EN] Posted on the main queue by `CYLSetLocalizationLanguage()`. `-[UIWindow cyl_setRootViewControllerProvider:]`
 *      observes it to rebuild the screen in the new language.
 * [CN] 由 `CYLSetLocalizationLanguage()` 在主队列发送。`-[UIWindow cyl_setRootViewControllerProvider:]` 监听它，用新语言重建界面。
 */
FOUNDATION_EXTERN NSString *const CYLLocalizationLanguageDidChangeNotification;

/*!
 * [EN] Like `CYLLocalizedString()`, but in `language` (matched to the closest translation); nil means the device language
 *      (`[NSLocale preferredLanguages]`), whatever language the app uses. Use it for a hint the user must be able to read
 *      after switching to a language they do not know, e.g. the subtitle of a language setting.
 * [CN] 同 `CYLLocalizedString()`，但使用 `language`（匹配最接近的译文）；传 nil 表示设备语言（`[NSLocale preferredLanguages]`），
 *      与 App 当前语言无关。用于切换到看不懂的语言后用户仍需读懂的提示，例如语言设置的副标题。
 */
FOUNDATION_EXTERN NSString *CYLLocalizedStringForLanguage(NSString *key, NSString * _Nullable language) CYL_RETURNS_LOCALIZED_STRING;

/*!
=======
>>>>>>> master
 * [EN] Builds `tabBarItemsAttributes` from parallel arrays, with every title passed through `CYLLocalizedString()`.
 *      `images` / `selectedImages` hold image names or `UIImage`s; `darkImages` maps an item index to its Dark Mode image.
 *
 *          CYLLocalizedTabBarItemsAttributes(@[@"首页", @"消息"], @[@"home_normal", @"message_normal"],
 *                                            @[@"home_highlight", @"message_highlight"], @{@1: @"message_normal_night"});
 * [CN] 由并列的数组生成 `tabBarItemsAttributes`，每个标题都经过 `CYLLocalizedString()`。`images` / `selectedImages` 为图片名或
 *      `UIImage`；`darkImages` 为「下标 → 深色模式图片」。示例见上。
 */
FOUNDATION_EXTERN NSArray<NSDictionary *> *CYLLocalizedTabBarItemsAttributes(NSArray<NSString *> *titles,
                                                                            NSArray *images,
                                                                            NSArray *selectedImages,
                                                                            NSDictionary<NSNumber *, id> * _Nullable darkImages);

@interface UIView (CYLLocalization)

/*!
 * [EN] Translates, with `CYLLocalizedString()`, the texts set in a xib or storyboard: the text of every `UILabel`, the
 *      titles of every `UIButton` and the placeholder of every `UITextField` in this view and its subviews. Call it once,
 *      e.g. in `-viewDidLoad` with `self.view`, so a xib needs no per-language copy:
 *
 *          [self.view cyl_localizeTexts];    // Objective-C
 *          view.cyl_localizeTexts()          // Swift
 * [CN] 用 `CYLLocalizedString()` 翻译 xib 或 storyboard 中设置的文字：当前视图及其子视图中所有 `UILabel` 的 text、`UIButton` 的
 *      标题以及 `UITextField` 的 placeholder。在 `-viewDidLoad` 中对 `self.view` 调用一次即可，xib 无需为每种语言复制一份（示例见上）。
 */
- (void)cyl_localizeTexts;

@end

@interface UIViewController (CYLLocalization)

/*!
 * [EN] Languages offered by `-cyl_presentLanguagePicker`: English, Chinese, Hindi, Spanish and Arabic, the five most
 *      spoken languages, each shown with its flag and its own name.
 * [CN] `-cyl_presentLanguagePicker` 提供的语言：英语、中文、印地语、西班牙语和阿拉伯语这五种使用人数最多的语言，
 *      每种语言以国旗加其自身名称显示。
 */
+ (NSArray<NSString *> *)cyl_pickerLanguages;

/*!
 * [EN] A table view cell for a language setting. Title: 🌐, "Language" and the current language with its flag, in the app's
 *      language. Subtitle: "Tap to change the language" in the device language, so it stays readable whatever language
 *      was picked. Tapping it should call `-cyl_presentLanguagePicker`. VoiceOver reads the language names, not the flags.
 * [CN] 语言设置用的 cell。标题：🌐、“语言”及当前语言（带国旗），使用 App 语言。副标题：“点击切换语言”，使用设备语言，
 *      无论切换到哪种语言都能看懂。点击时调用 `-cyl_presentLanguagePicker`。VoiceOver 朗读语言名称而不是国旗。
 */
- (UITableViewCell *)cyl_languageCellForTableView:(UITableView *)tableView;

/*!
 * [EN] Presents an action sheet of `+cyl_pickerLanguages` and "Follow system"; a choice calls `CYLSetLocalizationLanguage()`.
 * [CN] 弹出 `+cyl_pickerLanguages` 与“跟随系统”的选项；选择后调用 `CYLSetLocalizationLanguage()`。
 */
- (void)cyl_presentLanguagePicker;

@end

@interface UIWindow (CYLLocalization)

/*!
 * [EN] Sets `rootViewController` to `provider()` now and again after every `CYLLocalizationLanguageDidChangeNotification`,
 *      so a language change shows at once: every text is created again in the new language. A right-to-left language
 *      (e.g. Arabic) also flips the layout. One call replaces `window.rootViewController = …`.
 * [CN] 立即把 `rootViewController` 设为 `provider()`，并在每次 `CYLLocalizationLanguageDidChangeNotification` 后重新设置，
 *      使切换语言立即生效：所有文字都用新语言重新创建。从右到左的语言（如阿拉伯语）同时翻转布局。
 *      用这一行代替 `window.rootViewController = …`。
 */
- (void)cyl_setRootViewControllerProvider:(UIViewController * (^)(void))provider;

@end

NS_ASSUME_NONNULL_END
