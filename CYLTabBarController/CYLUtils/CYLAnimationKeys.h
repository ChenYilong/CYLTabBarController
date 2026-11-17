//
//  CYLAnimationKeys.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYLUtilsMacros.h"

/*
 * [EN] The animation keys shared by the tab bar (Core) and the animation engine and its animators (CYLAnimationEngine,
 *      CYLAnimatedItem), moved here from CYLTabBarController.h with the same names, so that no animation subspec needs
 *      Core. CYLTabBarController.h still declares them (it imports CYLUtils.h, which imports this header).
 * [CN] TabBar（Core）与动画引擎及其 animator（CYLAnimationEngine、CYLAnimatedItem）共用的动画 key，从 CYLTabBarController.h 原样移到这里
 *      （名称不变），使任何动画子库都不再需要 Core。CYLTabBarController.h 仍然声明它们（它导入 CYLUtils.h，后者导入本头文件）。
 */

/*
 * [EN] `noexcept` in C++, as in UIView+CYLBadgeExtention.h: the declaration of CYLTabBarController-Swift.h (a function
 *      implemented in Swift with @_cdecl) carries it.
 * [CN] C++ 中的 `noexcept`，与 UIView+CYLBadgeExtention.h 相同：CYLTabBarController-Swift.h 中（用 @_cdecl 在 Swift 实现的函数）的声明带有它。
 */
#ifndef CYL_NOEXCEPT
#if defined(__cplusplus)
#define CYL_NOEXCEPT noexcept
#else
#define CYL_NOEXCEPT
#endif
#endif

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const CYLTabBarLottieFilePath CYL_LOTTIE_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarLottieURL CYL_LOTTIE_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarLottieSize CYL_LOTTIE_REQUIRED;
/*!
 * FIX: issue #442
 * [EN] Optional Dark Mode versions of `CYLTabBarLottieURL` / `CYLTabBarLottieFilePath` (an NSURL / a file path). A
 *      Lottie animation draws its own colors, so a tab with `CYLTabBarLottieURL` used to stay light in Dark Mode, whatever
 *      its images. With one of these, the tab shows the dark animation where the interface style is dark (system setting
 *      or `overrideUserInterfaceStyle`), and switches by itself, keeping the selected tab's state.
 *
 *          CYLTabBarLottieURL : [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tab_home" ofType:@"json"]],
 *          CYLTabBarLottieDarkURL : [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tab_home_dark" ofType:@"json"]],
 *
 * [CN] 可选的深色模式 Lottie 动画，对应 `CYLTabBarLottieURL` / `CYLTabBarLottieFilePath`（NSURL / 文件路径）。Lottie 动画自带颜色，
 *      所以设置了 `CYLTabBarLottieURL` 的 Tab 以前在深色模式下保持浅色样式，与图片无关。设置后，界面风格为深色时（系统设置或
 *      `overrideUserInterfaceStyle`）Tab 显示深色动画，并自动切换，选中状态保持不变。示例见上。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarLottieDarkURL CYL_LOTTIE_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarLottieDarkFilePath CYL_LOTTIE_REQUIRED;
/*!
 * FIX: issue #442 — Lottie 4.x (`CYLTabBarController/LottieSwift`, `CYLFlatDesignTabBar`, SPM)
 * [EN] One Lottie file for both styles: an NSDictionary of keypath -> UIColor, the colors used where the interface style
 *      is dark. They are set with Lottie's official value providers (`setValueProvider(_:keypath:)` with a
 *      `ColorValueProvider`), which both rendering engines support, and removed in light mode, so the animation shows its
 *      own colors again. Switching keeps the view and its progress. Keypaths use Lottie's syntax: layer, group and item
 *      names joined by ".", with "*" for one name and "**" for any number (see `logHierarchyKeypaths()`):
 *
 *          CYLTabBarLottieDarkColors : @{
 *              @"Icon_Shop_Normal.**.Color" : [UIColor colorWithWhite:0.78 alpha:1],     // gray strokes, lighter
 *              @"Icon_Shop_Active_Main.**.Color" : [UIColor colorWithRed:0.15 green:0.39 blue:0.16 alpha:1],
 *          },
 *
 *      Lottie 2.x (`CYLTabBarController/LottieObjectiveC`) ignores it; use `CYLTabBarLottieDarkFilePath` there. A dark
 *      file and dark colors can be combined: the colors then apply to the dark file.
 * [CN] 一份 Lottie 文件适配深浅两种风格：keypath -> UIColor 的 NSDictionary，即界面风格为深色时使用的颜色。通过 Lottie 官方的
 *      value provider（`setValueProvider(_:keypath:)` + `ColorValueProvider`）设置，两种渲染引擎都支持；浅色模式下移除，动画恢复自身颜色。
 *      切换时保留原视图及播放进度。keypath 使用 Lottie 的语法：图层、组、元素名称用 "." 连接，"*" 匹配一个名称，"**" 匹配任意多个
 *      （见 `logHierarchyKeypaths()`），示例见上。
 *      Lottie 2.x（`CYLTabBarController/LottieObjectiveC`）不支持，请使用 `CYLTabBarLottieDarkFilePath`。深色文件与深色颜色可同时设置，
 *      此时颜色作用于深色文件。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarLottieDarkColors CYL_LOTTIE_REQUIRED;

/*!
 * [EN] Optional, per tab (an NSNumber BOOL, default NO): the tab's Lottie animation (`CYLTabBarLottieURL` /
 *      `CYLTabBarLottieFilePath`) loops while the tab is NOT selected, inviting a tap, and pauses while it is selected,
 *      instead of playing once on selection. Lottie 2.x and 4.x; every style. See docs/Custom-Tab-Bar-Features.md.
 * [CN] 可选，单个 Tab 设置（NSNumber BOOL，默认 NO）：该 Tab 的 Lottie 动画（`CYLTabBarLottieURL` / `CYLTabBarLottieFilePath`）在
 *      **未选中**时循环播放以吸引点击，选中时暂停，而不是在选中时播放一次。支持 Lottie 2.x 与 4.x，适用于所有样式。见
 *      docs/Custom-Tab-Bar-Features.md。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarLottieLoopsWhenUnselected CYL_LOTTIE_REQUIRED;

/*!
 * FIX: issue #604 — generic animation keys, for every animation library.
 * [EN] Keys for a tab's animation that do not name a library: the file decides which library plays it (".json" Lottie,
 *      ".pag" PAG, or the file type of any library added later, see `CYLTabBarItemAnimatorRegistry`). They work like the
 *      Lottie keys, and each library's own keys (`CYLTabBarLottie…`, `CYLTabBarPAG…`) keep working too.
 *      - `CYLTabBarAnimationURL` (NSURL) / `CYLTabBarAnimationFilePath` (NSString): the file; the URL wins.
 *      - `CYLTabBarAnimationSize`: the view size, an NSValue of CGSize (default: the icon placeholder size).
 *      - `CYLTabBarAnimationDarkURL` / `CYLTabBarAnimationDarkFilePath`: the Dark Mode version (#442).
 *      - `CYLTabBarAnimationDarkColors`: keypath -> UIColor for Dark Mode, for libraries that support it (Lottie 4.x).
 * [CN] 不指定动画库的 Tab 动画 key：由文件决定使用哪个动画库播放（".json" 为 Lottie，".pag" 为 PAG，或以后新增的动画库对应的文件类型，
 *      见 `CYLTabBarItemAnimatorRegistry`）。用法与 Lottie key 相同，各动画库自己的 key（`CYLTabBarLottie…`、`CYLTabBarPAG…`）也仍然有效。
 *      - `CYLTabBarAnimationURL`（NSURL）/ `CYLTabBarAnimationFilePath`（NSString）：动画文件，URL 优先。
 *      - `CYLTabBarAnimationSize`：视图尺寸，CGSize 的 NSValue（默认使用图标占位尺寸）。
 *      - `CYLTabBarAnimationDarkURL` / `CYLTabBarAnimationDarkFilePath`：深色模式版本（#442）。
 *      - `CYLTabBarAnimationDarkColors`：深色模式下 keypath -> UIColor，用于支持该功能的动画库（Lottie 4.x）。
 */
#ifndef __swift__
#define CYLTabBarAnimationURL @"CYLTabBarAnimationURL"
#endif
#ifndef __swift__
#define CYLTabBarAnimationFilePath @"CYLTabBarAnimationFilePath"
#endif
#ifndef __swift__
#define CYLTabBarAnimationSize @"CYLTabBarAnimationSize"
#endif
#ifndef __swift__
#define CYLTabBarAnimationDarkURL @"CYLTabBarAnimationDarkURL"
#endif
#ifndef __swift__
#define CYLTabBarAnimationDarkFilePath @"CYLTabBarAnimationDarkFilePath"
#endif
#ifndef __swift__
#define CYLTabBarAnimationDarkColors @"CYLTabBarAnimationDarkColors"
#endif
/*!
 * FIX: issue #216
 * [EN] `CYLTabBarAnimationColors`: keypath -> UIColor applied in every appearance, for libraries that support color
 *      overrides (Lottie 4.x, Rive). A theme color (`+[UIColor cyl_colorWithThemeProvider:]`) is resolved again on every
 *      theme change, so the animation follows the skin; `CYLTabBarAnimationDarkColors` is added on top of it in Dark Mode.
 * [CN] `CYLTabBarAnimationColors`：在所有外观下应用的 keypath -> UIColor，用于支持颜色覆盖的动画库（Lottie 4.x、Rive）。
 *      主题颜色（`+[UIColor cyl_colorWithThemeProvider:]`）会在每次主题切换时重新解析，使动画跟随皮肤；深色模式下再叠加
 *      `CYLTabBarAnimationDarkColors`。
 */
#ifndef __swift__
#define CYLTabBarAnimationColors @"CYLTabBarAnimationColors"
#endif

/*!
 * [EN] Options of a tab animation, for `CYLTabBarAnimationURLWithOptions()`. Each library declares the options it reads
 *      in its own subspec (e.g. `CYLTabBarAnimationOptionRiveArtboard` in the `Rive` subspec); Core only carries them.
 * [CN] Tab 动画的选项，用于 `CYLTabBarAnimationURLWithOptions()`。每个动画库在自己的子库中声明它读取的选项（例如 `Rive` 子库中的
 *      `CYLTabBarAnimationOptionRiveArtboard`）；Core 只负责传递。
 */
typedef NSString *CYLTabBarAnimationOption NS_TYPED_EXTENSIBLE_ENUM;

/*!
 * [EN] The URL of a tab animation with options: `fileURL` with `options` in its fragment, for `CYLTabBarAnimationURL` (or a
 *      library's own URL key) and `CYLTabBarAnimationDarkURL`. The file's library reads the options, e.g. which artboard
 *      of a Rive file a tab plays, so several tabs can use one file. Each URL stays a different tab animation (it is
 *      also the key of its Dark Mode version). Returns nil when `fileURL` is nil.
 *
 *          NSURL *iconSet = [[NSBundle mainBundle] URLForResource:@"icon-set" withExtension:@"riv"];
 *          home[CYLTabBarAnimationURL] = CYLTabBarAnimationURLWithOptions(iconSet, @{
 *              CYLTabBarAnimationOptionRiveArtboard : @"HOME",
 *          });
 *          // Swift: CYLTabBarAnimationURLWithOptions(iconSet, [.riveArtboard: "HOME"])
 * [CN] 带选项的 Tab 动画 URL：`fileURL` 加上写在 fragment 中的 `options`，用于 `CYLTabBarAnimationURL`（或动画库自己的 URL key）与
 *      `CYLTabBarAnimationDarkURL`。由文件对应的动画库读取选项，例如 Tab 播放 Rive 文件中的哪个画板，因此多个 Tab 可以使用同一个文件。每个 URL
 *      仍是不同的 Tab 动画（也是其深色模式版本的 key）。`fileURL` 为 nil 时返回 nil。示例见上。
 */
FOUNDATION_EXTERN NSURL * _Nullable CYLTabBarAnimationURLWithOptions(NSURL * _Nullable fileURL,
                                                                     NSDictionary * _Nullable options) CYL_NOEXCEPT;

NS_ASSUME_NONNULL_END
