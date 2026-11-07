//
//  UIColor+CYLTheme.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CYLThemeManager;

/*!
 * [EN] Returns the color for the current theme of `manager`. Called every time the color is drawn: keep it fast.
 * [CN] 返回 `manager` 当前主题下的颜色。每次绘制该颜色时都会调用：请勿在其中做耗时操作。
 */
typedef UIColor *_Nonnull (^CYLThemeColorProvider)(__kindof CYLThemeManager *manager, __kindof NSObject<NSCopying> *_Nullable identifier, __kindof NSObject *_Nullable theme);

/*!
 * FIX: issue #216
 * [EN] Colors that follow the theme of a `CYLThemeManager`. On iOS 13+ the color is a dynamic color (like
 *      `+[UIColor colorWithDynamicProvider:]`) that asks the provider each time it is drawn; colors of the system (e.g.
 *      `labelColor`) returned by the provider still follow Dark Mode. When the theme changes, the view properties
 *      registered with `-[UIView cyl_registerThemeColorProperties:]` get a fresh copy of the color, so every view
 *      redraws. Before iOS 13 the color is the value of the theme current when it was created; a registered property
 *      gets the value of the new theme when the theme changes.
 *      A `CGColor` (layers) is a fixed value: set the layer's colors with `-[CALayer cyl_setThemeColor:forKey:]`
 *      (`CALayer+CYLTheme.h`) to follow the theme.
 * [CN] 跟随 `CYLThemeManager` 主题的颜色。iOS 13+ 上是动态颜色（类似 `+[UIColor colorWithDynamicProvider:]`），每次绘制时都向
 *      provider 取值；provider 返回的系统颜色（例如 `labelColor`）仍然跟随深色模式。主题切换时，用
 *      `-[UIView cyl_registerThemeColorProperties:]` 注册的视图属性会得到该颜色的新副本，从而使视图重绘。iOS 13 以前，颜色为创建时
 *      所在主题的值；主题切换时，已注册的属性会得到新主题的值。
 *      `CGColor`（layer）是固定值：请用 `-[CALayer cyl_setThemeColor:forKey:]`（`CALayer+CYLTheme.h`）设置 layer 颜色以跟随主题。
 */
@interface UIColor (CYLTheme)

/*!
 * [EN] A color of `CYLThemeManagerCenter.defaultThemeManager`'s theme.
 * [CN] 跟随 `CYLThemeManagerCenter.defaultThemeManager` 主题的颜色。
 */
+ (UIColor *)cyl_colorWithThemeProvider:(CYLThemeColorProvider)provider;

/*!
 * [EN] A color of the default manager's theme, with a name (for debugging, see `cyl_themeColorName`).
 * [CN] 跟随默认管理器主题、带名字的颜色（便于调试，见 `cyl_themeColorName`）。
 */
+ (UIColor *)cyl_colorWithName:(nullable NSString *)name themeProvider:(CYLThemeColorProvider)provider;

/*!
 * [EN] A color of the theme of the manager named `managerName`.
 * [CN] 跟随名为 `managerName` 的管理器主题的颜色。
 */
+ (UIColor *)cyl_colorWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeColorProvider)provider;

/*!
 * [EN] A color of the theme of the manager named `managerName`, with a name.
 * [CN] 跟随名为 `managerName` 的管理器主题、带名字的颜色。
 */
+ (UIColor *)cyl_colorWithName:(nullable NSString *)name themeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeColorProvider)provider;

/*!
 * [EN] YES for a color created by the methods above.
 * [CN] 由上述方法创建的颜色为 YES。
 */
@property (nonatomic, assign, readonly) BOOL cyl_isThemeColor;

/*!
 * [EN] The name given to a theme color, else nil.
 * [CN] 主题颜色的名字，没有时为 nil。
 */
@property (nonatomic, copy, readonly, nullable) NSString *cyl_themeColorName;

/*!
 * [EN] The value of a theme color in the current theme (another theme color returned by the provider is resolved too);
 *      the receiver itself for any other color.
 * [CN] 主题颜色在当前主题下的值（provider 返回的另一个主题颜色也会被解析）；其他颜色返回自身。
 */
@property (nonatomic, strong, readonly) UIColor *cyl_rawColor;

@end

NS_ASSUME_NONNULL_END
