//
//  CYLTabBarItemAnimationTint.h
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationColorCount.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationColorCount.h>
#else
#import "CYLTabBarItemAnimationColorCount.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@protocol CYLTabBarItemAnimationPlayer;

/*!
 * [EN] The tint of a tab's animation view: the `tint` / `darkTint` options of the tab's animation URL (Rive's interface). Returns whether the
 *      view takes a tint now. The tab bar's animation flow calls it; the template tint itself belongs to the CYLAnimatedItem component.
 * [CN] Tab 动画视图的着色：Tab 动画 URL 的 `tint` / `darkTint` 选项（Rive 的接口）。返回视图现在是否接受着色。TabBar 的动画流程调用它；
 *      模板着色本身属于 CYLAnimatedItem 组件。
 */
FOUNDATION_EXTERN BOOL CYLTabBarItemAnimationPrepareTint(UIView *view, NSURL *sourceURL, id<CYLTabBarItemAnimationPlayer> _Nullable player);

/*!
 * [EN] The same with the tab bar's default rendering mode (`-[CYLTabBarController tabBarItemAnimationRenderingMode]`), used only where the URL has
 *      neither a `tint` nor a `renderingMode` option; automatic means no default (the tab flow keeps the file's own colors).
 * [CN] 同上，并带 TabBar 的默认渲染模式（`-[CYLTabBarController tabBarItemAnimationRenderingMode]`），只在 URL 既没有 `tint` 也没有 `renderingMode`
 *      选项时使用；automatic 表示没有默认值（Tab 流程保持文件自己的颜色）。
 */
FOUNDATION_EXTERN BOOL CYLTabBarItemAnimationPrepareTabTint(UIView *view, NSURL *sourceURL, id<CYLTabBarItemAnimationPlayer> _Nullable player,
                                                            NSInteger defaultRenderingMode);

/*!
 * [EN] Removes the tint of an animation view and forgets its tint options, so it can be prepared again (the bar's default changed).
 * [CN] 移除动画视图的着色并忘记其着色选项，以便重新准备（TabBar 默认值变化时）。
 */
FOUNDATION_EXTERN void CYLTabBarItemAnimationResetTint(UIView *view);

/*!
 * [EN] The tint of the animation view of a `CYLAnimatedItemView`: `tint` ("title" or "#RRGGBB(AA)") and `darkTint`, overriding the source URL's
 *      options of the same names (Rive's interface); prepared again each time, so setting or clearing it after the file loaded works. With
 *      neither the view is tinted by the tint properties (the rendering mode decides). Returns whether the view takes a tint now.
 * [CN] `CYLAnimatedItemView` 的动画视图的着色：`tint`（"title" 或 "#RRGGBB(AA)"）与 `darkTint`，覆盖来源 URL 中同名的选项（Rive 的接口）；每次都
 *      重新准备，因此文件加载之后再设置或清除也有效。两者都没有时不处理视图：文件保持自己的颜色。返回视图现在是否接受着色。
 */
FOUNDATION_EXTERN BOOL CYLTabBarItemAnimationPrepareItemTint(UIView *view, NSURL *sourceURL, id<CYLTabBarItemAnimationPlayer> _Nullable player,
                                                              NSString * _Nullable tint, NSString * _Nullable darkTint);

/*!
 * [EN] The animation rendering mode, applied only while the tint is unset (an explicit `tint` always wins): automatic (default) tints with the
 *      effective icon color only when the file is detected as ONE color (`CYLTabBarItemAnimationColorKindOfURL`), alwaysTemplate always, alwaysOriginal
 *      never. The URL option is `renderingMode=automatic|alwaysTemplate|alwaysOriginal`.
 * [CN] 动画渲染模式，只在未设置着色时生效（显式 `tint` 总是优先）：automatic（默认）只在文件被检测为单色时用有效图标颜色着色，alwaysTemplate 总是着色，
 *      alwaysOriginal 从不着色。URL 选项为 `renderingMode=automatic|alwaysTemplate|alwaysOriginal`。
 */
typedef NS_ENUM(NSInteger, CYLTabBarItemAnimationRenderingMode) {
    CYLTabBarItemAnimationRenderingModeAutomatic = 0,
    CYLTabBarItemAnimationRenderingModeAlwaysTemplate = 1,
    CYLTabBarItemAnimationRenderingModeAlwaysOriginal = 2,
};

/// [EN] "automatic" / "alwaysTemplate" / "alwaysOriginal" (case-insensitive), else `fallback`. [CN] "automatic" / "alwaysTemplate" / "alwaysOriginal"（不区分大小写），否则为 `fallback`。
FOUNDATION_EXTERN CYLTabBarItemAnimationRenderingMode CYLTabBarItemAnimationRenderingModeFromString(NSString * _Nullable text, CYLTabBarItemAnimationRenderingMode fallback);

/*!
 * [EN] The rendering mode the tab flow gave `view` (`CYLTabBarItemAnimationPrepareTint`): the URL's `renderingMode` option, else alwaysOriginal when the
 *      tab URL has no tint option (tab bars keep the file's own colors). Automatic for a view the tab flow did not prepare.
 * [CN] Tab 流程为 `view` 给出的渲染模式（`CYLTabBarItemAnimationPrepareTint`）：URL 的 `renderingMode` 选项，Tab URL 没有着色选项时为 alwaysOriginal
 *      （TabBar 保持文件自己的颜色）。Tab 流程没有准备过的视图为 automatic。
 */
FOUNDATION_EXTERN CYLTabBarItemAnimationRenderingMode CYLTabBarItemAnimationTabFlowRenderingMode(UIView * _Nullable view);

/*!
 * [EN] THE truth table of the tint (identical on iOS, Android, HarmonyOS and the mini program), as a pure function: the color the animation
 *      view is drawn in, nil = no tint (the file's own colors). `tint`: nil / invalid = unset (nil); "title" = `effectiveIconColor` (the EFFECTIVE
 *      icon color of the current state: explicit, else subclass, else built-in); "#RRGGBB" / "#RRGGBBAA" = the fixed color (`darkTint` instead in
 *      dark mode when valid), except that a SELECTED item takes `explicitSelectedIconColor` (EXPLICIT item / stack value only, never a built-in or
 *      subclass color) when there is one.
 * [CN] 着色的真值表（iOS、Android、HarmonyOS 与小程序一致），纯函数：动画视图使用的颜色，nil 表示不着色（文件自己的颜色）。`tint` 为 nil / 无效即未设置
 *      （nil）；"title" 为 `effectiveIconColor`（当前状态的有效图标颜色：显式值，否则子类，否则内置）；"#RRGGBB" / "#RRGGBBAA" 为固定颜色（深色模式下
 *      `darkTint` 有效则用它），但选中的条目在有 `explicitSelectedIconColor`（仅条目 / 堆叠视图的显式值，绝不是内置或子类颜色）时使用它。
 */
FOUNDATION_EXTERN UIColor * _Nullable CYLTabBarItemAnimationResolveTint(NSString * _Nullable tint, NSString * _Nullable darkTint, BOOL selected, BOOL isDark,
                                                                         UIColor * _Nullable effectiveIconColor, UIColor * _Nullable explicitSelectedIconColor);

/*!
 * [EN] `CYLTabBarItemAnimationResolveTint`, then the rendering mode when the tint is unset: alwaysTemplate gives `effectiveIconColor`, alwaysOriginal nil,
 *      automatic `effectiveIconColor` only for `colorKind` OneColor (Undetectable and MultiColor keep the file's colors).
 * [CN] `CYLTabBarItemAnimationResolveTint`，着色未设置时再按渲染模式：alwaysTemplate 为 `effectiveIconColor`，alwaysOriginal 为 nil，automatic 只在
 *      `colorKind` 为单色时为 `effectiveIconColor`（无法判断与多色保持文件颜色）。
 */
FOUNDATION_EXTERN UIColor * _Nullable CYLTabBarItemAnimationResolveTintWithRenderingMode(NSString * _Nullable tint, NSString * _Nullable darkTint,
                                                                                         CYLTabBarItemAnimationRenderingMode mode, CYLTabBarItemAnimationColorKind colorKind,
                                                                                         BOOL selected, BOOL isDark,
                                                                                         UIColor * _Nullable effectiveIconColor, UIColor * _Nullable explicitSelectedIconColor);

/*!
 * [EN] `CYLTabBarItemAnimationResolveTintWithRenderingMode` with the options of the source URL (`tint`, `darkTint`, `renderingMode`), overridden by `tint` /
 *      `darkTint` of the item (a non-empty override wins, valid or not) and by `modeOverride` (when not automatic). The color kind is read from the
 *      source URL only when it is needed.
 * [CN] 带来源 URL 选项（`tint`、`darkTint`、`renderingMode`）的 `CYLTabBarItemAnimationResolveTintWithRenderingMode`，条目自己的 `tint` / `darkTint`
 *      （非空即覆盖，无论是否有效）与 `modeOverride`（非 automatic 时）覆盖。只在需要时才读取来源 URL 的颜色类型。
 */
FOUNDATION_EXTERN UIColor * _Nullable CYLTabBarItemAnimationItemTintColor(NSURL * _Nullable sourceURL, NSString * _Nullable tintOverride, NSString * _Nullable darkTintOverride,
                                                                           CYLTabBarItemAnimationRenderingMode modeOverride,
                                                                           BOOL selected, BOOL isDark, UIColor * _Nullable effectiveIconColor, UIColor * _Nullable explicitSelectedIconColor);

NS_ASSUME_NONNULL_END
