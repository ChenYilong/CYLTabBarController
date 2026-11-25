//
//  CYLTabBarItemAnimationTint.h
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

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
 * [EN] The tint of the animation view of a `CYLAnimatedItemView`: `tint` ("title" or "#RRGGBB(AA)") and `darkTint`, overriding the source URL's
 *      options of the same names (Rive's interface); prepared again each time, so setting or clearing it after the file loaded works. With
 *      neither the view is left alone: the file keeps its own colors. Returns whether the view takes a tint now.
 * [CN] `CYLAnimatedItemView` 的动画视图的着色：`tint`（"title" 或 "#RRGGBB(AA)"）与 `darkTint`，覆盖来源 URL 中同名的选项（Rive 的接口）；每次都
 *      重新准备，因此文件加载之后再设置或清除也有效。两者都没有时不处理视图：文件保持自己的颜色。返回视图现在是否接受着色。
 */
FOUNDATION_EXTERN BOOL CYLTabBarItemAnimationPrepareItemTint(UIView *view, NSURL *sourceURL, id<CYLTabBarItemAnimationPlayer> _Nullable player,
                                                              NSString * _Nullable tint, NSString * _Nullable darkTint);

/*!
 * [EN] THE truth table of the tint (identical on iOS, Android, HarmonyOS and the mini program), as a pure function: the color the animation
 *      view is drawn in, nil = no tint (the file's own colors). `tint`: nil / invalid = unset (nil); "title" = `normalIconColor` when
 *      unselected, `selectedIconColor` else `normalIconColor` when selected, nil when neither exists; "#RRGGBB" / "#RRGGBBAA" = the fixed
 *      color (`darkTint` instead in dark mode when valid) when unselected, the selected state's icon color (else the normal one) when
 *      selected, else the fixed color.
 * [CN] 着色的真值表（iOS、Android、HarmonyOS 与小程序一致），纯函数：动画视图使用的颜色，nil 表示不着色（文件自己的颜色）。`tint` 为 nil / 无效即未设置
 *      （nil）；"title"：未选中时为 `normalIconColor`，选中时为 `selectedIconColor`，否则 `normalIconColor`，两者都没有时为 nil；"#RRGGBB" / "#RRGGBBAA"：
 *      未选中时为固定颜色（深色模式下 `darkTint` 有效则用它），选中时为选中状态的图标颜色（否则普通状态的），都没有时为固定颜色。
 */
FOUNDATION_EXTERN UIColor * _Nullable CYLTabBarItemAnimationResolveTint(NSString * _Nullable tint, NSString * _Nullable darkTint, BOOL selected, BOOL isDark,
                                                                         UIColor * _Nullable normalIconColor, UIColor * _Nullable selectedIconColor);

/*!
 * [EN] `CYLTabBarItemAnimationResolveTint` with the options of the source URL, overridden by `tint` / `darkTint` of the item (a non-empty
 *      override wins, valid or not).
 * [CN] 带来源 URL 选项的 `CYLTabBarItemAnimationResolveTint`，条目自己的 `tint` / `darkTint` 覆盖（非空即覆盖，无论是否有效）。
 */
FOUNDATION_EXTERN UIColor * _Nullable CYLTabBarItemAnimationItemTintColor(NSURL * _Nullable sourceURL, NSString * _Nullable tintOverride, NSString * _Nullable darkTintOverride,
                                                                           BOOL selected, BOOL isDark, UIColor * _Nullable normalIconColor, UIColor * _Nullable selectedIconColor);

NS_ASSUME_NONNULL_END
