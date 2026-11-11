//
//  CALayer+CYLTheme.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/05/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #216
 * [EN] Layer colors that follow the theme, without method swizzling. A layer draws a `CGColor`, which is a fixed value:
 *      `layer.borderColor = themeColor.CGColor` keeps the value of the theme current at that moment. Set the
 *      `UIColor` here instead; the layer gets its `CGColor` now and again:
 *      - when the theme changes, for a layer of a view the theme reaches (see `UIView+CYLTheme.h`) and its sublayers;
 *      - on iOS 17+, when the Dark Mode of the view the layer belongs to changes (`-registerForTraitChanges:`), so a
 *        system color returned by a theme color provider follows Dark Mode too. Before iOS 17, a Dark Mode change
 *        reaches the layer only through a theme change (`CYLThemeManager.respondsSystemStyleAutomatically`).
 *      Works with any color (a theme color, a dynamic color, a plain color).
 * [CN] 跟随主题的 layer 颜色，无需 hook 任何方法。layer 绘制的是 `CGColor`，它是固定的值：`layer.borderColor = themeColor.CGColor`
 *      只保留当时主题的颜色值。请改为在这里设置 `UIColor`，layer 会立即得到对应的 `CGColor`，并在以下时机重新设置：
 *      - 主题切换时：主题能够传递到的视图（见 `UIView+CYLTheme.h`）的 layer 及其 sublayer；
 *      - iOS 17+ 上 layer 所属视图的深色模式变化时（`-registerForTraitChanges:`），因此主题颜色 provider 返回的系统颜色同样跟随深色模式。
 *        iOS 17 以前，深色模式变化只能通过主题切换传递到 layer（`CYLThemeManager.respondsSystemStyleAutomatically`）。
 *      适用于任何颜色（主题颜色、动态颜色、普通颜色）。
 */
@interface CALayer (CYLTheme)

/*!
 * [EN] Sets the `CGColor` property `key` of the layer (`backgroundColor`, `borderColor`, `shadowColor`, and for a
 *      `CAShapeLayer` `fillColor`, `strokeColor`, ...) from `color`, and keeps doing so when the theme changes. nil
 *      clears the property and stops following.
 * [CN] 用 `color` 设置 layer 的 `CGColor` 属性 `key`（`backgroundColor`、`borderColor`、`shadowColor`，以及 `CAShapeLayer` 的
 *      `fillColor`、`strokeColor` 等），并在主题切换时继续设置。传 nil 时清除该属性并停止跟随。
 */
- (void)cyl_setThemeColor:(nullable UIColor *)color forKey:(NSString *)key;

/*!
 * [EN] The color set with `-cyl_setThemeColor:forKey:` for `key`, else nil.
 * [CN] 通过 `-cyl_setThemeColor:forKey:` 为 `key` 设置的颜色，没有时为 nil。
 */
- (nullable UIColor *)cyl_themeColorForKey:(NSString *)key;

/*!
 * [EN] Sets the `CGColor`s of the colors set with `-cyl_setThemeColor:forKey:` again, for this layer and its sublayers
 *      that belong to no other view. Called for you on a theme change; call it when the colors must follow something
 *      else.
 * [CN] 重新设置通过 `-cyl_setThemeColor:forKey:` 设置的颜色对应的 `CGColor`，包括本 layer 及不属于其他视图的 sublayer。主题切换时会自动调用；
 *      颜色需要跟随其他变化时可手动调用。
 */
- (void)cyl_updateThemeColors;

/*!
 * [EN] `backgroundColor`, `borderColor` and `shadowColor` as theme colors (`-cyl_setThemeColor:forKey:`).
 * [CN] 以主题颜色设置 `backgroundColor`、`borderColor` 与 `shadowColor`（`-cyl_setThemeColor:forKey:`）。
 */
@property (nonatomic, strong, nullable, setter=cyl_setThemeBackgroundColor:) UIColor *cyl_themeBackgroundColor;
@property (nonatomic, strong, nullable, setter=cyl_setThemeBorderColor:) UIColor *cyl_themeBorderColor;
@property (nonatomic, strong, nullable, setter=cyl_setThemeShadowColor:) UIColor *cyl_themeShadowColor;

@end

NS_ASSUME_NONNULL_END
