//
//  UIImage+CYLTheme.h
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/05/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class CYLThemeManager;

/*!
 * [EN] Returns the image for the current theme of `manager`. Called when the image is created and every time the theme
 *      changes: return images that are already loaded (e.g. `+[UIImage imageNamed:]`), not ones drawn each time.
 * [CN] 返回 `manager` 当前主题下的图片。创建图片时以及每次主题切换时调用：请返回已加载的图片（例如 `+[UIImage imageNamed:]`），
 *      不要每次重新绘制。
 */
typedef UIImage *_Nullable (^CYLThemeImageProvider)(__kindof CYLThemeManager *manager, __kindof NSObject<NSCopying> *_Nullable identifier, __kindof NSObject *_Nullable theme);

/*!
 * FIX: issue #216
 * [EN] Images that follow the theme of a `CYLThemeManager`, for any image view or button of the app, without method
 *      swizzling. A theme image is a real `UIImage` (the provider's image for the current theme, so its asset catalog
 *      Dark Mode variant, rendering mode and symbol configuration are kept) that remembers its provider. When the theme
 *      changes it is replaced by the image of the new theme in:
 *      - `UIImageView`'s `image` and `highlightedImage`;
 *      - `UIButton`'s image and background image of each state (normal, highlighted, selected, disabled);
 *      - the properties registered with `-[UIView cyl_registerThemeColorProperties:]` (e.g. `@[ @"image" ]` on a view
 *        of your own);
 *      - the background and shadow images of the `UITabBar`, `UINavigationBar` and `UIToolbar` appearances.
 *      Elsewhere (a `UIButtonConfiguration`, a tab bar item, an attributed string attachment) set the image again in
 *      `cyl_themeDidChangeBlock`; for a tab bar of `CYLTabBarController`, use the `CYLTabBarTheme` protocol.
 * [CN] 跟随 `CYLThemeManager` 主题的图片，可用于 App 中任何图片视图与按钮，无需 hook 任何方法。主题图片是一个真正的 `UIImage`
 *      （provider 返回的当前主题图片，因此保留 Asset Catalog 中的深色模式变体、渲染模式与 SF Symbol 配置），并记住它的 provider。
 *      主题切换时，以下位置的主题图片会被替换为新主题的图片：
 *      - `UIImageView` 的 `image` 与 `highlightedImage`；
 *      - `UIButton` 各状态（normal、highlighted、selected、disabled）的 image 与 background image；
 *      - 通过 `-[UIView cyl_registerThemeColorProperties:]` 注册的属性（例如自定义视图的 `@[ @"image" ]`）；
 *      - `UITabBar`、`UINavigationBar`、`UIToolbar` appearance 中的背景图片与阴影图片。
 *      其他位置（`UIButtonConfiguration`、TabBarItem、富文本附件）请在 `cyl_themeDidChangeBlock` 中重新设置；`CYLTabBarController`
 *      的 TabBar 请使用 `CYLTabBarTheme` 协议。
 */
@interface UIImage (CYLTheme)

/*!
 * [EN] An image of `CYLThemeManagerCenter.defaultThemeManager`'s theme. A provider that returns nil gives an empty
 *      1 × 1 image.
 * [CN] 跟随 `CYLThemeManagerCenter.defaultThemeManager` 主题的图片。provider 返回 nil 时为 1 × 1 的空图片。
 */
+ (UIImage *)cyl_imageWithThemeProvider:(CYLThemeImageProvider)provider;

/*!
 * [EN] An image of the default manager's theme, with a name (for debugging, see `cyl_themeImageName`).
 * [CN] 跟随默认管理器主题、带名字的图片（便于调试，见 `cyl_themeImageName`）。
 */
+ (UIImage *)cyl_imageWithName:(nullable NSString *)name themeProvider:(CYLThemeImageProvider)provider;

/*!
 * [EN] An image of the theme of the manager named `managerName`.
 * [CN] 跟随名为 `managerName` 的管理器主题的图片。
 */
+ (UIImage *)cyl_imageWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeImageProvider)provider;

/*!
 * [EN] An image of the theme of the manager named `managerName`, with a name.
 * [CN] 跟随名为 `managerName` 的管理器主题、带名字的图片。
 */
+ (UIImage *)cyl_imageWithName:(nullable NSString *)name themeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeImageProvider)provider;

/*!
 * [EN] YES for an image created by the methods above.
 * [CN] 由上述方法创建的图片为 YES。
 */
@property (nonatomic, assign, readonly) BOOL cyl_isThemeImage;

/*!
 * [EN] The name given to a theme image, else nil.
 * [CN] 主题图片的名字，没有时为 nil。
 */
@property (nonatomic, copy, readonly, nullable) NSString *cyl_themeImageName;

/*!
 * [EN] The provider's image for the current theme (not a theme image); the receiver itself for any other image.
 * [CN] provider 在当前主题下返回的图片（不是主题图片）；其他图片返回自身。
 */
@property (nonatomic, strong, readonly) UIImage *cyl_rawImage;

@end

NS_ASSUME_NONNULL_END
