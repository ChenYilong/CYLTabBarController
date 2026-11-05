//
//  CYLThemePrivate.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

/*!
 * [EN] Private to the theme sources (not a public header): how the manager, the colors and the views talk to each other.
 * [CN] 仅供主题相关源文件使用（非公开头文件）：管理器、颜色与视图之间的内部接口。
 */

#import <UIKit/UIKit.h>
#import "CYLThemeManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CYLThemeManager (CYLThemePrivate)

/// [EN] Used by `CYLThemeManagerCenter` only. [CN] 仅供 `CYLThemeManagerCenter` 使用。
- (instancetype)initWithName:(__kindof NSObject<NSCopying> *)name;

@end

/*!
 * [EN] A new color object made from the same provider as `color` (a theme color), so that UIKit, which skips setting the
 *      very same object again (e.g. `tintColor`), redraws; `color` itself for any other color.
 * [CN] 用与 `color`（主题颜色）相同的 provider 新建的颜色对象，使 UIKit 重绘（UIKit 遇到同一个对象时会跳过赋值，例如 `tintColor`）；
 *      其他颜色返回 `color` 本身。
 */
FOUNDATION_EXTERN UIColor *CYLThemeColorRefreshedColor(UIColor *color);

/*!
 * [EN] The name of the manager a theme color follows; nil for any other color.
 * [CN] 主题颜色所跟随的管理器名字；其他颜色为 nil。
 */
FOUNDATION_EXTERN NSObject<NSCopying> *_Nullable CYLThemeColorManagerName(UIColor *color);

/*!
 * [EN] The image of the current theme for a theme image (a new object, itself a theme image); `image` for any other.
 * [CN] 主题图片在当前主题下的图片（新对象，同样是主题图片）；其他图片返回 `image`。
 */
FOUNDATION_EXTERN UIImage *CYLThemeImageRefreshedImage(UIImage *image);

/// [EN] The name of the manager a theme image follows; nil for any other image. [CN] 主题图片所跟随的管理器名字；其他图片为 nil。
FOUNDATION_EXTERN NSObject<NSCopying> *_Nullable CYLThemeImageManagerName(UIImage *image);

/*!
 * [EN] The effect of the current theme for a theme effect (a new object, itself a theme effect); `effect` for any other.
 * [CN] 主题效果在当前主题下的效果（新对象，同样是主题效果）；其他效果返回 `effect`。
 */
FOUNDATION_EXTERN UIVisualEffect *CYLThemeVisualEffectRefreshedEffect(UIVisualEffect *effect);

/// [EN] The name of the manager a theme effect follows; nil for any other. [CN] 主题效果所跟随的管理器名字；其他效果为 nil。
FOUNDATION_EXTERN NSObject<NSCopying> *_Nullable CYLThemeVisualEffectManagerName(UIVisualEffect *effect);

/*!
 * [EN] Assigns the bar appearances (`standardAppearance`, `scrollEdgeAppearance`, `compactAppearance`...) of a
 *      `UITabBar`, `UINavigationBar` or `UIToolbar` again, so that the theme colors in them are drawn with the new theme:
 *      a bar does not update by itself for colors nested in an appearance object.
 * [CN] 重新设置 `UITabBar`、`UINavigationBar`、`UIToolbar` 的 appearance（`standardAppearance`、`scrollEdgeAppearance`、
 *      `compactAppearance` 等），使其中的主题颜色以新主题重新绘制：appearance 对象内的颜色变化不会让 Bar 自动更新。
 */
FOUNDATION_EXTERN void CYLThemeRefreshBarAppearances(UIView *view);

@interface UIView (CYLThemePrivate)

/*!
 * [EN] Getter → setter of the properties registered with `-cyl_registerThemeColorProperties:`.
 * [CN] 通过 `-cyl_registerThemeColorProperties:` 注册的属性：getter → setter。
 */
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSString *> *cyl_themeColorProperties;

/*!
 * [EN] `-cyl_themeDidChangeByManager:identifier:theme:` on the receiver, then on its subviews when `enumeratesSubviews`.
 * [CN] 对自身调用 `-cyl_themeDidChangeByManager:identifier:theme:`，`enumeratesSubviews` 为 YES 时再对其子视图调用。
 */
- (void)cyl_themeDidChangeByManager:(nullable CYLThemeManager *)manager
                         identifier:(nullable __kindof NSObject<NSCopying> *)identifier
                              theme:(nullable __kindof NSObject *)theme
                 enumeratesSubviews:(BOOL)enumeratesSubviews;

@end

NS_ASSUME_NONNULL_END
