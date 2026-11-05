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
 * [EN] Returns the image for the current theme of `manager`; nil shows nothing (a transparent 1 × 1 pt image). Called
 *      when the image is created and on every theme change: keep it fast (load from the asset catalog or a cache).
 * [CN] 返回 `manager` 当前主题下的图片；返回 nil 时不显示任何内容（透明的 1 × 1 pt 图片）。创建图片时以及每次切换主题时调用：请勿在其中
 *      做耗时操作（从资源目录或缓存读取）。
 */
typedef UIImage *_Nullable (^CYLThemeImageProvider)(__kindof CYLThemeManager *manager, __kindof NSObject<NSCopying> *_Nullable identifier, __kindof NSObject *_Nullable theme);

/*!
 * FIX: issue #216
 * [EN] Images that follow the theme of a `CYLThemeManager`, like theme colors (`UIColor+CYLTheme.h`).
 *      - The image returned is a normal `UIImage`: the provider's image for the current theme, as its own object (the
 *        provider's image itself, e.g. a shared `+imageNamed:` one, is never marked), which remembers the provider.
 *        Light and dark variants of an asset image keep following Dark Mode.
 *      - When the theme changes, every view in a window, and the views of the app's view controllers that are not in a
 *        window (other tabs, pages under the top of a navigation stack), get the image of the new theme, with no UIKit
 *        method hooked:
 *        - `UIImageView`: `image`, `highlightedImage` (also the image views inside buttons and cells);
 *        - `UIButton`: the image and the background image of each state set with one, and `configuration.image` /
 *          `configuration.background.image` (iOS 15+);
 *        - any property registered with `-[UIView cyl_registerThemeColorProperties:]` that holds a theme image.
 *      - Keep the provider, not an image, when you assign it later: an image made before a theme change shows the old
 *        theme until the next change. `cyl_imageForCurrentTheme` gives the image of the current theme.
 *      - Tab bar items keep a copy of their images: theme the tab bar with `CYLTabBarTheme` (`CYLTabBarController.h`).
 * [CN] 跟随 `CYLThemeManager` 主题的图片，用法与主题颜色（`UIColor+CYLTheme.h`）相同。
 *      - 返回的是普通的 `UIImage`：provider 在当前主题下返回的图片，作为独立对象（不会标记 provider 返回的图片本身，例如共享的
 *        `+imageNamed:` 图片），并记住该 provider。资源目录图片的浅色与深色版本仍跟随深色模式。
 *      - 主题切换时，window 中的所有视图，以及 App 中不在 window 上的控制器视图（其他 Tab、导航栈中非顶部的页面）都会得到新主题的图片，
 *        不 hook 任何 UIKit 方法：
 *        - `UIImageView`：`image`、`highlightedImage`（也包括按钮与 cell 中的图片视图）；
 *        - `UIButton`：设置过图片的各状态的图片与背景图片，以及 `configuration.image` / `configuration.background.image`（iOS 15+）；
 *        - 通过 `-[UIView cyl_registerThemeColorProperties:]` 注册、值为主题图片的属性。
 *      - 之后才赋值时，请保存 provider 而不是图片：主题切换前创建的图片在下一次切换前显示旧主题。`cyl_imageForCurrentTheme` 返回当前主题的图片。
 *      - TabBarItem 保存的是图片副本：TabBar 请使用 `CYLTabBarTheme`（`CYLTabBarController.h`）换肤。
 */
@interface UIImage (CYLTheme)

/*!
 * [EN] An image of `CYLThemeManagerCenter.defaultThemeManager`'s theme.
 * [CN] 跟随 `CYLThemeManagerCenter.defaultThemeManager` 主题的图片。
 */
+ (UIImage *)cyl_imageWithThemeProvider:(CYLThemeImageProvider)provider;

/*!
 * [EN] An image of the theme of the manager named `managerName`.
 * [CN] 跟随名为 `managerName` 的管理器主题的图片。
 */
+ (UIImage *)cyl_imageWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeImageProvider)provider;

/*!
 * [EN] YES for an image created by the methods above (and the images refreshed from it).
 * [CN] 由上述方法创建的图片（及由其刷新得到的图片）为 YES。
 */
@property (nonatomic, assign, readonly) BOOL cyl_isThemeImage;

/*!
 * [EN] For a theme image, the image of the current theme, itself a theme image; the receiver for any other image.
 * [CN] 主题图片在当前主题下的图片（同样是主题图片）；其他图片返回自身。
 */
- (UIImage *)cyl_imageForCurrentTheme;

@end

NS_ASSUME_NONNULL_END
