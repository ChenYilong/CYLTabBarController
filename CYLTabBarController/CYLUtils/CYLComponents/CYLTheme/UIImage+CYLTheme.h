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
 *        Light and dark variants of an asset image keep following Dark Mode; an SF Symbol becomes a bitmap of its
 *        current configuration (its rendering mode is kept, so a template symbol still takes the tint color).
 *      - When the theme changes, every view in a window, and the views of the app's view controllers that are not in a
 *        window (other tabs, pages under the top of a navigation stack), get the image of the new theme, with no UIKit
 *        method hooked:
 *        - `UIImageView`: `image`, `highlightedImage` (also the image views inside buttons and cells);
 *        - `UIButton`: the image and the background image of each state set with one, and `configuration.image` /
 *          `configuration.background.image` (iOS 15+);
 *        - any property registered with `-[UIView cyl_registerThemeColorProperties:]` that holds a theme image.
 *      - Keep the provider, not an image, when you assign it later: an image made before a theme change shows the old
 *        theme until the next change. `cyl_imageForCurrentTheme` gives the image of the current theme, and
 *        `+cyl_dynamicImageWithThemeProvider:` an image that is always the current theme's.
 *      - Tab bar items keep a copy of their images: theme the tab bar with `CYLTabBarTheme` (`CYLTabBarController.h`).
 * [CN] 跟随 `CYLThemeManager` 主题的图片，用法与主题颜色（`UIColor+CYLTheme.h`）相同。
 *      - 返回的是普通的 `UIImage`：provider 在当前主题下返回的图片，作为独立对象（不会标记 provider 返回的图片本身，例如共享的
 *        `+imageNamed:` 图片），并记住该 provider。资源目录图片的浅色与深色版本仍跟随深色模式；SF Symbol 会变为当前配置下的位图（保留渲染模式，因此模板符号仍使用
 *        tintColor）。
 *      - 主题切换时，window 中的所有视图，以及 App 中不在 window 上的控制器视图（其他 Tab、导航栈中非顶部的页面）都会得到新主题的图片，
 *        不 hook 任何 UIKit 方法：
 *        - `UIImageView`：`image`、`highlightedImage`（也包括按钮与 cell 中的图片视图）；
 *        - `UIButton`：设置过图片的各状态的图片与背景图片，以及 `configuration.image` / `configuration.background.image`（iOS 15+）；
 *        - 通过 `-[UIView cyl_registerThemeColorProperties:]` 注册、值为主题图片的属性。
 *      - 之后才赋值时，请保存 provider 而不是图片：主题切换前创建的图片在下一次切换前显示旧主题。`cyl_imageForCurrentTheme` 返回当前主题的图片，
 *        `+cyl_dynamicImageWithThemeProvider:` 返回始终为当前主题的图片。
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
 * [EN] An image of `CYLThemeManagerCenter.defaultThemeManager`'s theme that is always the provider's image of the current
 *      theme, also when it is assigned after a theme change: every public property (`size`, `CGImage`, `scale`,
 *      `renderingMode`...) and drawing method answers with that image, and derived images (`-imageWithRenderingMode:`,
 *      `-resizableImageWithCapInsets:`, `-imageWithTintColor:`...) stay dynamic. The theme walk assigns it again to the
 *      views that hold it, as for the other theme images.
 *      Opt in: it is a `UIImage` subclass that holds no bitmap of its own. Prefer `+cyl_imageWithThemeProvider:` for
 *      code that inspects images deeply (e.g. caches keyed by the image, Core Image filters on the object itself).
 * [CN] 跟随 `CYLThemeManagerCenter.defaultThemeManager` 主题、且始终为 provider 在当前主题下图片的图片，主题切换后才赋值也是如此：所有公开
 *      属性（`size`、`CGImage`、`scale`、`renderingMode` 等）与绘制方法都以该图片作答，派生图片（`-imageWithRenderingMode:`、
 *      `-resizableImageWithCapInsets:`、`-imageWithTintColor:` 等）仍为动态图片。与其他主题图片一样，主题切换时由遍历重新赋给持有它的视图。
 *      需主动选用：它是不含自身位图的 `UIImage` 子类。对图片做深入处理的代码（例如以图片为 key 的缓存、直接对该对象使用 Core Image）请使用
 *      `+cyl_imageWithThemeProvider:`。
 */
+ (UIImage *)cyl_dynamicImageWithThemeProvider:(CYLThemeImageProvider)provider;

/*!
 * [EN] A dynamic image (see above) of the theme of the manager named `managerName`.
 * [CN] 跟随名为 `managerName` 的管理器主题的动态图片（见上）。
 */
+ (UIImage *)cyl_dynamicImageWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeImageProvider)provider;

/*!
 * [EN] YES for an image of `+cyl_dynamicImageWithThemeProvider:` (and its manager variant and derived images).
 * [CN] `+cyl_dynamicImageWithThemeProvider:`（及其管理器版本与派生图片）创建的图片为 YES。
 */
@property (nonatomic, assign, readonly) BOOL cyl_isDynamicThemeImage;

/*!
 * [EN] YES for an image created by the methods above (and the images refreshed from it).
 * [CN] 由上述方法创建的图片（及由其刷新得到的图片）为 YES。
 */
@property (nonatomic, assign, readonly) BOOL cyl_isThemeImage;

/*!
 * [EN] For a theme image, the image of the current theme, itself a theme image (a plain copy for a dynamic image); the
 *      receiver for any other image.
 * [CN] 主题图片在当前主题下的图片（同样是主题图片；动态图片返回普通副本）；其他图片返回自身。
 */
- (UIImage *)cyl_imageForCurrentTheme;

@end

NS_ASSUME_NONNULL_END
