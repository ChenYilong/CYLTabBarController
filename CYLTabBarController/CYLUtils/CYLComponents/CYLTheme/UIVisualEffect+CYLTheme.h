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
 * [EN] Returns the effect for the current theme of `manager` (e.g. `[UIBlurEffect effectWithStyle:...]`); nil for no
 *      effect. Called when the effect is created and on every theme change.
 * [CN] 返回 `manager` 当前主题下的效果（例如 `[UIBlurEffect effectWithStyle:...]`）；返回 nil 表示没有效果。创建效果时以及每次切换主题时调用。
 */
typedef UIVisualEffect *_Nullable (^CYLThemeVisualEffectProvider)(__kindof CYLThemeManager *manager, __kindof NSObject<NSCopying> *_Nullable identifier, __kindof NSObject *_Nullable theme);

/*!
 * FIX: issue #216
 * [EN] Visual effects (blur, vibrancy) that follow the theme of a `CYLThemeManager`, like theme colors and images.
 *      - The effect returned is a normal `UIVisualEffect`: the provider's effect for the current theme, as its own
 *        object, which remembers the provider. Assign it to `UIVisualEffectView.effect`.
 *      - When the theme changes, every `UIVisualEffectView` in a window, and in the views of the app's view controllers
 *        that are not in a window, gets the effect of the new theme (with no UIKit method hooked), as does any property
 *        registered with `-[UIView cyl_registerThemeColorProperties:]` that holds a theme effect.
 *      - A provider that returns nil makes the effect view show no effect.
 * [CN] 跟随 `CYLThemeManager` 主题的视觉效果（模糊、活力效果），用法与主题颜色、图片相同。
 *      - 返回的是普通的 `UIVisualEffect`：provider 在当前主题下返回的效果，作为独立对象，并记住该 provider。赋给 `UIVisualEffectView.effect`。
 *      - 主题切换时，window 中的所有 `UIVisualEffectView`，以及 App 中不在 window 上的控制器视图中的 `UIVisualEffectView`，都会得到新主题的
 *        效果（不 hook 任何 UIKit 方法）；通过 `-[UIView cyl_registerThemeColorProperties:]` 注册、值为主题效果的属性也是如此。
 *      - provider 返回 nil 时，效果视图不显示效果。
 */
@interface UIVisualEffect (CYLTheme)

/*!
 * [EN] An effect of `CYLThemeManagerCenter.defaultThemeManager`'s theme.
 * [CN] 跟随 `CYLThemeManagerCenter.defaultThemeManager` 主题的效果。
 */
+ (UIVisualEffect *)cyl_effectWithThemeProvider:(CYLThemeVisualEffectProvider)provider;

/*!
 * [EN] An effect of the theme of the manager named `managerName`.
 * [CN] 跟随名为 `managerName` 的管理器主题的效果。
 */
+ (UIVisualEffect *)cyl_effectWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeVisualEffectProvider)provider;

/*!
 * [EN] YES for an effect created by the methods above (and the effects refreshed from it).
 * [CN] 由上述方法创建的效果（及由其刷新得到的效果）为 YES。
 */
@property (nonatomic, assign, readonly) BOOL cyl_isThemeEffect;

/*!
 * [EN] For a theme effect, the effect of the current theme, itself a theme effect; the receiver for any other effect.
 * [CN] 主题效果在当前主题下的效果（同样是主题效果）；其他效果返回自身。
 */
- (UIVisualEffect *)cyl_effectForCurrentTheme;

@end

NS_ASSUME_NONNULL_END
