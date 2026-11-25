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

NS_ASSUME_NONNULL_END
