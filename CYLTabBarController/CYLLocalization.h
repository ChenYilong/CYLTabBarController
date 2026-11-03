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

/*!
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
