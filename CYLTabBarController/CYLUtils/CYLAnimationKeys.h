//
//  CYLAnimationKeys.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#if __has_include(<CYLAnimatedItem/CYLAnimatedItemMacros.h>)
#import <CYLAnimatedItem/CYLAnimatedItemMacros.h>
#elif __has_include("../CYLAnimatedItem/CYLAnimatedItemMacros.h")
#import "../CYLAnimatedItem/CYLAnimatedItemMacros.h"
#else
#import "CYLAnimatedItemMacros.h"
#endif

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

/*!
 * [EN] The keys of each animation type (PAG, Rive, SVGA, GIF; Lottie's are above), declared here in the component's core so
 *      that they always exist: a project that passes one without that type's engine still compiles, gets a compile
 *      warning on the key (`CYL_PAG_REQUIRED` and its siblings, from `CYLAnimatedItemMacros.h`), a debug log at run
 *      time (`CYLAnimationWarnMissingEngine()`), and shows the static image, or the placeholder without one.
 * [CN] 各动画类型（PAG、Rive、SVGA、GIF；Lottie 见上）的 key，声明在组件核心中，因此总是存在：没有该类型的引擎却传入了它的 key 时，
 *      项目仍能编译，在该 key 上得到编译警告（`CYL_PAG_REQUIRED` 等，来自 `CYLAnimatedItemMacros.h`），运行时在 debug 下输出日志
 *      （`CYLAnimationWarnMissingEngine()`），并显示静态图片，没有时显示占位图。
 */
/*!
 * FIX: issue #604 — PAG animations (Tencent libpag), the same way as Lottie.
 * [EN] Keys for a tab's PAG animation, used exactly like their Lottie twins and through the same pipeline: the view is
 *      added in place of the tab's icon, plays when the tab is selected, stops when another one is, follows
 *      `lottieAnimationViewContentMode`, is returned by `-[UIControl cyl_lottieAnimationView]` and posts
 *      `CYLTabBarItemAnimationViewDidAddNotification`. Needs the `CYLTabBarController/PAG` subspec (the `libpag`
 *      pod) to play; the keys always exist (without it they get a compile warning and the tab shows its image). Use either the
 *      Lottie keys or the PAG keys for a tab;
 *      PAG has no playback speed, so `lottieAnimationSpeed` does not apply to it.
 *      - `CYLTabBarPAGURL`: an NSURL of a .pag file; `CYLTabBarPAGFilePath`: its path (NSString). The URL wins.
 *      - `CYLTabBarPAGSize`: the view size, an NSValue of CGSize (default: the icon placeholder size).
 *      - `CYLTabBarPAGDarkURL` / `CYLTabBarPAGDarkFilePath`: the Dark Mode version, like `CYLTabBarLottieDarkURL`.
 * [CN] Tab 的 PAG 动画 key，用法与对应的 Lottie key 完全相同，并走同一套流程：替换 Tab 图标显示，选中时播放，选中其他 Tab 时停止，
 *      遵循 `lottieAnimationViewContentMode`，由 `-[UIControl cyl_lottieAnimationView]` 返回，并发送
 *      `CYLTabBarItemAnimationViewDidAddNotification`。播放需要引入 `CYLTabBarController/PAG` 子库（依赖 `libpag` pod）；这些 key 总是存在
 *      （未引入时会有编译警告，Tab 显示图片）。同一个 Tab 请使用 Lottie key 或 PAG key 之一；PAG 没有播放速度，`lottieAnimationSpeed` 对其无效。
 *      - `CYLTabBarPAGURL`：.pag 文件的 NSURL；`CYLTabBarPAGFilePath`：其路径（NSString）。URL 优先。
 *      - `CYLTabBarPAGSize`：视图尺寸，CGSize 的 NSValue（默认使用图标占位尺寸）。
 *      - `CYLTabBarPAGDarkURL` / `CYLTabBarPAGDarkFilePath`：深色模式版本，与 `CYLTabBarLottieDarkURL` 相同。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarPAGURL CYL_PAG_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarPAGFilePath CYL_PAG_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarPAGSize CYL_PAG_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarPAGDarkURL CYL_PAG_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarPAGDarkFilePath CYL_PAG_REQUIRED;
/*!
 * [EN] Keys for a tab's Rive animation, aliases of the generic `CYLTabBarAnimation…` keys (either works), like the Lottie
 *      and PAG keys. A Rive state machine has no playback speed, so `lottieAnimationSpeed` does not apply.
 *      - `CYLTabBarRiveURL`: an NSURL of a .riv file, usually with options (`CYLTabBarAnimationURLWithOptions()`);
 *        `CYLTabBarRiveFilePath`: its path (NSString, the default artboard). The URL wins.
 *      - `CYLTabBarRiveSize`: the view size, an NSValue of CGSize.
 *      - `CYLTabBarRiveDarkURL` / `CYLTabBarRiveDarkFilePath`: the Dark Mode version.
 *      - `CYLTabBarRiveDarkColors`: view model color property path -> UIColor for Dark Mode, e.g. @{ @"color" : UIColor.whiteColor }.
 * [CN] Tab 的 Rive 动画 key，是通用 key `CYLTabBarAnimation…` 的别名（两者都可以用），与 Lottie、PAG 的 key 相同。Rive 状态机没有播放速度，
 *      `lottieAnimationSpeed` 对其无效。
 *      - `CYLTabBarRiveURL`：.riv 文件的 NSURL，通常带有选项（`CYLTabBarAnimationURLWithOptions()`）；`CYLTabBarRiveFilePath`：其路径（NSString，
 *        使用默认画板）。URL 优先。
 *      - `CYLTabBarRiveSize`：视图尺寸，CGSize 的 NSValue。
 *      - `CYLTabBarRiveDarkURL` / `CYLTabBarRiveDarkFilePath`：深色模式版本。
 *      - `CYLTabBarRiveDarkColors`：深色模式下 view model 颜色属性路径 -> UIColor，例如 @{ @"color" : UIColor.whiteColor }。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarRiveURL CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarRiveFilePath CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarRiveSize CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarRiveDarkURL CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarRiveDarkFilePath CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarRiveDarkColors CYL_RIVE_REQUIRED;
/*!
 * [EN] Rive's options for `CYLTabBarAnimationURLWithOptions()` (Swift: `.riveArtboard`, …). Every value is a string.
 *      - `CYLTabBarAnimationOptionRiveArtboard`: the artboard (default: the file's default); one .riv file can hold many icons.
 *      - `CYLTabBarAnimationOptionRiveStateMachine`: the state machine (default: the artboard's default).
 *      - `CYLTabBarAnimationOptionRiveActiveProperty`: the view model boolean set to YES when the tab is selected, then back
 *        to NO after `CYLTabBarAnimationOptionRiveActiveDuration` seconds (defaults @"active" and @"1").
 *      - `CYLTabBarAnimationOptionRiveTriggerProperty`: a view model trigger fired instead.
 *      - `CYLTabBarAnimationOptionRiveColor`: "#RRGGBB" or "#RRGGBBAA", set on the view model color @"color" (light mode).
 *      For files made before data binding, which have no view model (Rive's legacy runtime, see docs/Rive-Animation.md):
 *      - `CYLTabBarAnimationOptionRiveInput`: a state machine boolean input, set to YES when the tab plays and back to NO
 *        after `CYLTabBarAnimationOptionRiveActiveDuration` seconds, or when it stops.
 *      - `CYLTabBarAnimationOptionRiveTriggerInput`: a state machine trigger input fired when the tab plays.
 *      - `CYLTabBarAnimationOptionRiveAnimation`: a linear animation played when the tab plays (no state machine).
 *      - `CYLTabBarAnimationOptionRiveLegacyRuntime`: @"1" plays the file through the legacy runtime with none of the above,
 *        e.g. a file without a state machine, whose default animation then loops.
 *      `CYLTabBarAnimationOptionRiveActiveDuration` @"0" keeps the boolean (view model or input) YES until the animation stops.
 * [CN] Rive 用于 `CYLTabBarAnimationURLWithOptions()` 的选项（Swift：`.riveArtboard` 等），所有值都是字符串。
 *      - `CYLTabBarAnimationOptionRiveArtboard`：画板（默认为文件的默认画板）；一个 .riv 文件可以包含多个图标。
 *      - `CYLTabBarAnimationOptionRiveStateMachine`：状态机（默认为画板的默认状态机）。
 *      - `CYLTabBarAnimationOptionRiveActiveProperty`：选中 Tab 时设为 YES 的 view model 布尔属性，`CYLTabBarAnimationOptionRiveActiveDuration` 秒后
 *        恢复为 NO（默认 @"active" 与 @"1"）。
 *      - `CYLTabBarAnimationOptionRiveTriggerProperty`：改为触发的 view model trigger。
 *      - `CYLTabBarAnimationOptionRiveColor`："#RRGGBB" 或 "#RRGGBBAA"，设置到 view model 颜色 @"color"（浅色模式）。
 *      数据绑定出现之前制作、没有 view model 的文件（Rive 旧版运行时，见 docs/Rive-Animation.md）：
 *      - `CYLTabBarAnimationOptionRiveInput`：状态机布尔输入，播放时设为 YES，`CYLTabBarAnimationOptionRiveActiveDuration` 秒后或停止时恢复为 NO。
 *      - `CYLTabBarAnimationOptionRiveTriggerInput`：播放时触发的状态机 trigger 输入。
 *      - `CYLTabBarAnimationOptionRiveAnimation`：播放时播放的线性动画（不使用状态机）。
 *      - `CYLTabBarAnimationOptionRiveLegacyRuntime`：@"1" 表示不使用以上选项、直接通过旧版运行时播放文件，例如没有状态机的文件，其默认动画会循环播放。
 *      `CYLTabBarAnimationOptionRiveActiveDuration` 为 @"0" 时，布尔属性（view model 或输入）保持 YES，直到动画停止。
 */
FOUNDATION_EXTERN CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveArtboard CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveStateMachine CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveActiveProperty CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveActiveDuration CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveTriggerProperty CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveColor CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveInput CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveTriggerInput CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveAnimation CYL_RIVE_REQUIRED;
FOUNDATION_EXTERN CYLTabBarAnimationOption const CYLTabBarAnimationOptionRiveLegacyRuntime CYL_RIVE_REQUIRED;
/*!
 * [EN] An SVGA file's URL (NSURL), the counterpart of `CYLTabBarLottieURL`; read from `CYLTabBarAnimationURL` too.
 * [CN] SVGA 文件的 URL（NSURL），对应 `CYLTabBarLottieURL`；也可以使用 `CYLTabBarAnimationURL`。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarSVGAURL CYL_SVGA_REQUIRED;
/*!
 * [EN] An SVGA file's path (NSString), used when there is no URL.
 * [CN] SVGA 文件的路径（NSString），没有 URL 时使用。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarSVGAFilePath CYL_SVGA_REQUIRED;
/*!
 * [EN] The size of the animation view (NSValue of CGSize); default: the size of the tab's image.
 * [CN] 动画视图的尺寸（CGSize 的 NSValue）；默认为 Tab 图片的尺寸。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarSVGASize CYL_SVGA_REQUIRED;
/*!
 * [EN] The SVGA file played in Dark Mode (NSURL).
 * [CN] 深色模式下播放的 SVGA 文件（NSURL）。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarSVGADarkURL CYL_SVGA_REQUIRED;
/*!
 * [EN] The path of the SVGA file played in Dark Mode (NSString).
 * [CN] 深色模式下播放的 SVGA 文件路径（NSString）。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarSVGADarkFilePath CYL_SVGA_REQUIRED;
/*!
 * [EN] Keys for a tab's GIF animation, aliases of the generic `CYLTabBarAnimation…` keys (either works), like the Lottie, PAG
 *      and Rive keys. A GIF has no color layers, so there is no dark colors key: give a Dark Mode file instead.
 *      - `CYLTabBarGIFURL`: an NSURL of a local .gif file; `CYLTabBarGIFFilePath`: its full path (NSString). The URL wins.
 *      - `CYLTabBarGIFSize`: the view size, an NSValue of CGSize.
 *      - `CYLTabBarGIFDarkURL` / `CYLTabBarGIFDarkFilePath`: the Dark Mode version.
 * [CN] Tab 的 GIF 动画 key，是通用 key `CYLTabBarAnimation…` 的别名（两者都可以用），与 Lottie、PAG、Rive 的 key 相同。GIF 没有颜色图层，因此没有深色颜色
 *      key：请提供深色模式的文件。
 *      - `CYLTabBarGIFURL`：本地 .gif 文件的 NSURL；`CYLTabBarGIFFilePath`：其完整路径（NSString）。URL 优先。
 *      - `CYLTabBarGIFSize`：视图尺寸，CGSize 的 NSValue。
 *      - `CYLTabBarGIFDarkURL` / `CYLTabBarGIFDarkFilePath`：深色模式版本。
 */
FOUNDATION_EXTERN NSString *const CYLTabBarGIFURL CYL_GIF_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarGIFFilePath CYL_GIF_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarGIFSize CYL_GIF_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarGIFDarkURL CYL_GIF_REQUIRED;
FOUNDATION_EXTERN NSString *const CYLTabBarGIFDarkFilePath CYL_GIF_REQUIRED;

/*!
 * [EN] The value of `genericKey` (`CYLTabBarAnimationURL`, `…FilePath`, `…Size`, `…DarkURL`, `…DarkFilePath`, `…DarkColors`)
 *      in `attributes`, under the generic key or under any type's own key (Lottie, PAG, Rive, SVGA, GIF), whether or not
 *      that type's engine is in the build. Used to find a tab's file even when nothing can play it.
 * [CN] `attributes` 中 `genericKey`（`CYLTabBarAnimationURL`、`…FilePath`、`…Size`、`…DarkURL`、`…DarkFilePath`、`…DarkColors`）的值，
 *      取通用 key 或任一类型自己的 key（Lottie、PAG、Rive、SVGA、GIF），与该类型的引擎是否参与构建无关。用于在无法播放时也能找到 Tab 的文件。
 */
FOUNDATION_EXTERN id _Nullable CYLAnimationAttributesValue(NSDictionary * _Nullable attributes, NSString *genericKey);

/*!
 * [EN] The animation type of a file: "Lottie", "PAG", "Rive", "SVGA" or "GIF", from the type keys in `attributes`, else from
 *      the file's extension; nil when unknown.
 * [CN] 文件的动画类型："Lottie"、"PAG"、"Rive"、"SVGA" 或 "GIF"，先看 `attributes` 中的类型 key，否则看文件扩展名；未知时为 nil。
 */
FOUNDATION_EXTERN NSString * _Nullable CYLAnimationTypeOfFile(NSDictionary * _Nullable attributes, NSURL * _Nullable fileURL);

/*!
 * [EN] Whether the engine of `type` is in the build (`CYL_LOTTIE_AVAILABLE`, `CYL_PAG_AVAILABLE`, `CYL_RIVE_AVAILABLE`,
 *      `CYL_SVGA_AVAILABLE`, `CYL_GIF_AVAILABLE`, and the engine itself, `CYL_ANIMATION_ENGINE_AVAILABLE`).
 * [CN] `type` 的引擎是否参与构建（`CYL_LOTTIE_AVAILABLE` 等各类型开关，以及引擎本身 `CYL_ANIMATION_ENGINE_AVAILABLE`）。
 */
FOUNDATION_EXTERN BOOL CYLAnimationTypeIsAvailable(NSString * _Nullable type);

/*!
 * [EN] In debug builds (`DEBUG`), logs once per type that a file cannot play because its engine is not in the build, with
 *      the pod to add; the item shows its static image, or the placeholder without one. Does nothing in release builds,
 *      for an unknown type, or when the engine is there (a failure of the file itself is reported by the engine).
 * [CN] 在 debug 构建（`DEBUG`）中，每种类型输出一次日志：文件因其引擎未参与构建而无法播放，并给出需要加入的 pod；条目显示静态图片，没有时
 *      显示占位图。release 构建、未知类型或引擎存在时（文件本身的失败由引擎报告）不做任何事。
 */
FOUNDATION_EXTERN void CYLAnimationWarnMissingEngine(NSDictionary * _Nullable attributes, NSURL * _Nullable fileURL);

NS_ASSUME_NONNULL_END
