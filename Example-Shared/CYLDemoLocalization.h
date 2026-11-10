//
//  CYLDemoLocalization.h
//  CYLTabBarController examples
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 2026/11/11.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CYLTabBarController/CYLTabBarController.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] The examples' own texts (AGENTS.md, "Localization (i18n / l10n) file structure"): they live in the example-level
 *      `Example-Shared/CYLDemo.bundle` (table `CYLDemo`, 33 languages), not in the library's core bundle. The language is
 *      the library's (`CYLLocalizationLanguage()`, so `CYLSetLocalizationLanguage()` switches both); a key the demo
 *      table does not have falls back to `CYLLocalizedString()`. Pass the original Chinese text as the key, as with
 *      `CYLLocalizedString()`.
 * [CN] 示例自己的文字（AGENTS.md「Localization (i18n / l10n) file structure」）：放在示例级的 `Example-Shared/CYLDemo.bundle`
 *      （表 `CYLDemo`，33 种语言）中，而不是本库的核心 bundle。语言与本库一致（`CYLLocalizationLanguage()`，因此
 *      `CYLSetLocalizationLanguage()` 会同时切换两者）；示例表中没有的键回退到 `CYLLocalizedString()`。与 `CYLLocalizedString()`
 *      一样，以中文原文作为键。
 */
FOUNDATION_EXTERN NSString *CYLDemoLocalizedString(NSString *key) CYL_RETURNS_LOCALIZED_STRING NS_FORMAT_ARGUMENT(1);

NS_ASSUME_NONNULL_END
