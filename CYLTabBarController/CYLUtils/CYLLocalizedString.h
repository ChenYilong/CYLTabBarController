//
//  CYLLocalizedString.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/02/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * FIX: issue #535
 * [EN] The library's string table and resource bundle, part of CYLUtils so Core and CYLBadgeView share them.
 *      `CYLLocalization.h` (Core) imports this header, so existing imports keep working.
 * [CN] 本库的字符串表与资源包，属于 CYLUtils，由 Core 与 CYLBadgeView 共用。Core 的 `CYLLocalization.h` 会导入本头文件，
 *      原有的导入方式不受影响。
 */

#import <UIKit/UIKit.h>

/*!
 * Marks a function that returns translated text, for the static analyzer's localizability checker.
 */
#ifndef CYL_RETURNS_LOCALIZED_STRING
#define CYL_RETURNS_LOCALIZED_STRING __attribute__((annotate("returns_localized_nsstring")))
#endif

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] Implemented in Swift (`Swift/CYLLocalizedString.swift`, each function exported under its C name with
 *      `@_cdecl`); declared here for Objective-C callers only, and hidden from Swift (`__swift__`), which uses the
 *      Swift functions and constant (docs/Swift-Migration.md).
 * [CN] 在 Swift 中实现（`Swift/CYLLocalizedString.swift`，每个函数用 `@_cdecl` 以 C 名称导出）；这里只为 Objective-C 调用方声明，
 *      并对 Swift 隐藏（`__swift__`），Swift 直接使用 Swift 函数与常量（docs/Swift-Migration.md）。
 */
#ifndef __swift__


/*!
 * [EN] Returns the translation of `key` from the library's string table (`CYLTabBarController.strings`, shipped in the
 *      CYLUtils subspec, so no extra import or resource is needed), or `key` itself when there is none. The key is the
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
 * [CN] 返回 `key` 在本库字符串表（`CYLTabBarController.strings`，随 CYLUtils 子模块提供，无需额外导入资源）中的译文，没有译文时返回
 *      `key` 本身。key 即原文，调用处只需把字面量包起来（示例见上方英文部分）。
 *      使用 C 函数而不是宏，因此 Swift 中的写法完全相同。
 *
 *      所有文字使用同一种语言：语言取 App 自身当前显示的语言（`[NSBundle mainBundle].preferredLocalizations`），匹配到最接近的译文，
 *      没有时使用英文。因此本库不会显示 App 本身不支持的语言；声明了 `CFBundleLocalizations` 的 App 会跟随设备语言。
 *      可用 `CYLSetLocalizationLanguage()` 指定。线程安全。
 */
/* [EN] Declared by the generated Swift header too (C++ sees that one: `noexcept`). [CN] 生成的 Swift 头文件也声明了它（C++ 使用那一份：`noexcept`）。 */
#if !defined(__cplusplus) || !__has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
FOUNDATION_EXTERN NSString *CYLLocalizedString(NSString * _Nullable key) CYL_RETURNS_LOCALIZED_STRING NS_FORMAT_ARGUMENT(1);
#endif

/*!
 * [EN] The library's resource bundle, `CYLTabBarController.bundle` (CYLUtils, no extra import). It holds the `*.lproj` string
 *      tables; images and other resources can be added to it too and loaded from it, e.g.
 *      `[UIImage imageNamed:@"icon" inBundle:CYLResourceBundle() compatibleWithTraitCollection:nil]`.
 * [CN] 本库的资源包 `CYLTabBarController.bundle`（属于 CYLUtils，无需额外导入）。其中存放各语言的 `*.lproj` 字符串表；图片等资源也可以
 *      放进同一个 bundle，并从中读取，例如上面的 `UIImage` 示例。
 */
/* [EN] Declared by the generated Swift header too (C++ sees that one: `noexcept`). [CN] 生成的 Swift 头文件也声明了它（C++ 使用那一份：`noexcept`）。 */
#if !defined(__cplusplus) || !__has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
FOUNDATION_EXTERN NSBundle *CYLResourceBundle(void);
#endif

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
/* [EN] Declared by the generated Swift header too (C++ sees that one: `noexcept`). [CN] 生成的 Swift 头文件也声明了它（C++ 使用那一份：`noexcept`）。 */
#if !defined(__cplusplus) || !__has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
FOUNDATION_EXTERN void CYLSetLocalizationLanguage(NSString * _Nullable language);
#endif

/*!
 * [EN] Posted on the main queue by `CYLSetLocalizationLanguage()`. `-[UIWindow cyl_setRootViewControllerProvider:]`
 *      observes it to rebuild the screen in the new language.
 * [CN] 由 `CYLSetLocalizationLanguage()` 在主队列发送。`-[UIWindow cyl_setRootViewControllerProvider:]` 监听它，用新语言重建界面。
 */
#define CYLLocalizationLanguageDidChangeNotification @"CYLLocalizationLanguageDidChangeNotification"

/*!
 * [EN] Like `CYLLocalizedString()`, but in `language` (matched to the closest translation); nil means the device language
 *      (`[NSLocale preferredLanguages]`), whatever language the app uses. Use it for a hint the user must be able to read
 *      after switching to a language they do not know, e.g. the subtitle of a language setting.
 * [CN] 同 `CYLLocalizedString()`，但使用 `language`（匹配最接近的译文）；传 nil 表示设备语言（`[NSLocale preferredLanguages]`），
 *      与 App 当前语言无关。用于切换到看不懂的语言后用户仍需读懂的提示，例如语言设置的副标题。
 */
/* [EN] Declared by the generated Swift header too (C++ sees that one: `noexcept`). [CN] 生成的 Swift 头文件也声明了它（C++ 使用那一份：`noexcept`）。 */
#if !defined(__cplusplus) || !__has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
FOUNDATION_EXTERN NSString *CYLLocalizedStringForLanguage(NSString * _Nullable key, NSString * _Nullable language) CYL_RETURNS_LOCALIZED_STRING NS_FORMAT_ARGUMENT(1);
#endif

/*!
 * [EN] The language `CYLLocalizedString()` currently uses, e.g. @"zh-Hans".
 * [CN] `CYLLocalizedString()` 当前使用的语言，例如 @"zh-Hans"。
 */
/* [EN] Declared by the generated Swift header too (C++ sees that one: `noexcept`). [CN] 生成的 Swift 头文件也声明了它（C++ 使用那一份：`noexcept`）。 */
#if !defined(__cplusplus) || !__has_include(<CYLTabBarController/CYLTabBarController-Swift.h>)
FOUNDATION_EXTERN NSString *CYLLocalizationLanguage(void);
#endif

#endif

NS_ASSUME_NONNULL_END
