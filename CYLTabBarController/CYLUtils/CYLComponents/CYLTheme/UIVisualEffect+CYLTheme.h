//
//  UIVisualEffect+CYLTheme.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/05/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CYLThemeManager;

/*!
 * [EN] Returns the effect (e.g. a `UIBlurEffect`) for the current theme of `manager`. Called when the effect is created
 *      and every time the theme changes.
 * [CN] 返回 `manager` 当前主题下的效果（例如 `UIBlurEffect`）。创建效果时以及每次主题切换时调用。
 */
typedef UIVisualEffect *_Nullable (^CYLThemeEffectProvider)(__kindof CYLThemeManager *manager, __kindof NSObject<NSCopying> *_Nullable identifier, __kindof NSObject *_Nullable theme);

/*!
 * FIX: issue #216
 * [EN] Visual effects (blur, vibrancy) that follow the theme of a `CYLThemeManager`, without method swizzling. A theme
 *      effect is a copy of the provider's effect for the current theme that remembers its provider. When the theme
 *      changes it is replaced by the effect of the new theme in:
 *      - `UIVisualEffectView`'s `effect`;
 *      - the properties registered with `-[UIView cyl_registerThemeColorProperties:]`;
 *      - the `backgroundEffect` of the `UITabBar`, `UINavigationBar` and `UIToolbar` appearances.
 *      A vibrancy effect view inside a blur effect view: give both a theme effect.
 * [CN] 跟随 `CYLThemeManager` 主题的视觉效果（模糊、vibrancy），无需 hook 任何方法。主题效果是 provider 返回的当前主题效果的副本，
 *      并记住它的 provider。主题切换时，以下位置的主题效果会被替换为新主题的效果：
 *      - `UIVisualEffectView` 的 `effect`；
 *      - 通过 `-[UIView cyl_registerThemeColorProperties:]` 注册的属性；
 *      - `UITabBar`、`UINavigationBar`、`UIToolbar` appearance 的 `backgroundEffect`。
 *      模糊效果视图中的 vibrancy 效果视图：两者都使用主题效果。
 */
@interface UIVisualEffect (CYLTheme)

/*!
 * [EN] An effect of `CYLThemeManagerCenter.defaultThemeManager`'s theme. A provider that returns nil gives an effect
 *      that does nothing (a plain `UIVisualEffect`).
 * [CN] 跟随 `CYLThemeManagerCenter.defaultThemeManager` 主题的效果。provider 返回 nil 时为不产生任何效果的 `UIVisualEffect`。
 */
+ (UIVisualEffect *)cyl_effectWithThemeProvider:(CYLThemeEffectProvider)provider;

/*!
 * [EN] An effect of the theme of the manager named `managerName`.
 * [CN] 跟随名为 `managerName` 的管理器主题的效果。
 */
+ (UIVisualEffect *)cyl_effectWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeEffectProvider)provider;

/*!
 * [EN] YES for an effect created by the methods above.
 * [CN] 由上述方法创建的效果为 YES。
 */
@property (nonatomic, assign, readonly) BOOL cyl_isThemeEffect;

/*!
 * [EN] The provider's effect for the current theme (not a theme effect); the receiver itself for any other effect.
 * [CN] provider 在当前主题下返回的效果（不是主题效果）；其他效果返回自身。
 */
@property (nonatomic, strong, readonly) UIVisualEffect *cyl_rawEffect;

@end

NS_ASSUME_NONNULL_END
