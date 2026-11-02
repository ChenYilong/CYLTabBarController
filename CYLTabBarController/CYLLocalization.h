//
//  CYLLocalization.h
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/02/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
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
 *      there is none. So the library never shows a language the app does not, and the demos (which declare
 *      `CFBundleLocalizations`) follow the device language. `CYLSetLocalizationLanguage()` overrides it.
 *      Thread-safe.
 * [CN] 返回 `key` 在本库字符串表（`CYLTabBarController.strings`，随 Core 子模块提供，无需额外导入资源）中的译文，没有译文时返回
 *      `key` 本身。key 即原文，调用处只需把字面量包起来（示例见上方英文部分）。
 *      使用 C 函数而不是宏，因此 Swift 中的写法完全相同。
 *
 *      所有文字使用同一种语言：语言取 App 自身当前显示的语言（`[NSBundle mainBundle].preferredLocalizations`），匹配到最接近的译文，
 *      没有时使用英文。因此本库不会显示 App 本身不支持的语言；Demo 声明了 `CFBundleLocalizations`，会跟随设备语言。
 *      可用 `CYLSetLocalizationLanguage()` 指定。线程安全。
 */
FOUNDATION_EXTERN NSString *CYLLocalizedString(NSString *key);

/*!
 * [EN] Overrides the language of `CYLLocalizedString()`, e.g. @"ja" or @"zh-Hant", for an in-app language setting; nil
 *      follows the app again. Texts already shown keep their language until they are set again (e.g. the tab bar
 *      controller is created again).
 * [CN] 指定 `CYLLocalizedString()` 使用的语言，例如 @"ja"、@"zh-Hant"，用于 App 内切换语言；传 nil 恢复跟随 App。
 *      已显示的文字在重新设置之前（例如重新创建 TabBarController）保持原语言。
 */
FOUNDATION_EXTERN void CYLSetLocalizationLanguage(NSString * _Nullable language);

/*!
 * [EN] The language `CYLLocalizedString()` currently uses, e.g. @"zh-Hans".
 * [CN] `CYLLocalizedString()` 当前使用的语言，例如 @"zh-Hans"。
 */
FOUNDATION_EXTERN NSString *CYLLocalizationLanguage(void);

NS_ASSUME_NONNULL_END
