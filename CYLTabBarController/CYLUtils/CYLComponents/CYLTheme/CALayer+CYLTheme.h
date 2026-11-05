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
 * [EN] Layer colors that follow the theme. A `CGColor` is a fixed value, so `layer.borderColor = themeColor.CGColor` keeps
 *      the theme it was set in. Set the `UIColor` here instead (a theme color, a system dynamic color, or any color): the
 *      layer gets its `CGColor` now and again on every theme change, with no UIKit method hooked, for the layers of every
 *      view in a window and of the views of the app's view controllers that are not in a window, sublayers included.
 *      The color is resolved with the trait collection of the layer's view (Dark Mode).
 * [CN] 跟随主题的 layer 颜色。`CGColor` 是固定值，因此 `layer.borderColor = themeColor.CGColor` 会停留在设置时的主题。请改为在这里设置
 *      `UIColor`（主题颜色、系统动态颜色或任意颜色）：layer 立即得到对应的 `CGColor`，并在每次主题切换时重新设置，不 hook 任何 UIKit
 *      方法；适用于 window 中所有视图的 layer，以及 App 中不在 window 上的控制器视图的 layer，包括子 layer。颜色按 layer 所在视图的
 *      trait collection 解析（深色模式）。
 */
@interface CALayer (CYLTheme)

/*!
 * [EN] Sets the `CGColor` property at `keyPath` (e.g. `@"borderColor"`, `@"shadowColor"`, `@"fillColor"` of a
 *      `CAShapeLayer`, `@"foregroundColor"` of a `CATextLayer`) from `color`, now and on every theme change. nil stops
 *      following and clears the property.
 * [CN] 用 `color` 设置 `keyPath` 处的 `CGColor` 属性（例如 `@"borderColor"`、`@"shadowColor"`、`CAShapeLayer` 的 `@"fillColor"`、
 *      `CATextLayer` 的 `@"foregroundColor"`），立即生效并在每次主题切换时重新设置。传 nil 停止跟随并清空该属性。
 */
- (void)cyl_setThemeColor:(nullable UIColor *)color forKeyPath:(NSString *)keyPath;

/*!
 * [EN] The color set with `-cyl_setThemeColor:forKeyPath:` for `keyPath`, else nil.
 * [CN] 通过 `-cyl_setThemeColor:forKeyPath:` 为 `keyPath` 设置的颜色，没有时为 nil。
 */
- (nullable UIColor *)cyl_themeColorForKeyPath:(NSString *)keyPath;

/// [EN] `backgroundColor` that follows the theme. [CN] 跟随主题的 `backgroundColor`。
@property (nonatomic, strong, nullable, setter=cyl_setThemeBackgroundColor:) UIColor *cyl_themeBackgroundColor;

/// [EN] `borderColor` that follows the theme. [CN] 跟随主题的 `borderColor`。
@property (nonatomic, strong, nullable, setter=cyl_setThemeBorderColor:) UIColor *cyl_themeBorderColor;

/// [EN] `shadowColor` that follows the theme. [CN] 跟随主题的 `shadowColor`。
@property (nonatomic, strong, nullable, setter=cyl_setThemeShadowColor:) UIColor *cyl_themeShadowColor;

/*!
 * [EN] Sets the theme colors of this layer again, and those of its sublayers that are not the layer of a view (each
 *      view's layer is handled with its view). Called for you when the theme changes; call it yourself for a layer
 *      that is in no view.
 * [CN] 重新设置该 layer 的主题颜色，以及不属于某个视图的子 layer 的主题颜色（视图的 layer 随视图处理）。主题切换时会自动调用；不在任何
 *      视图中的 layer 请自行调用。
 */
- (void)cyl_refreshThemeColors;

@end

NS_ASSUME_NONNULL_END
