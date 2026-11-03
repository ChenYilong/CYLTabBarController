//
//  UIImage+CYLTabBarControllerExtention.h
//  CYLTabBarController
//
//  Created by chenyilong on 18/4/2026.
//  Copyright © 2026 微博@iOS程序犭袁. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (CYLTabBarControllerExtention)

/*!
 * [EN] Returns a solid-color image of `size`; nil if `color` is nil or `size` is empty. A dynamic color (e.g.
 *      `systemBackgroundColor`, `+[UIColor cyl_colorWithLightColor:darkColor:]`) gives an image that follows Dark Mode,
 *      e.g. for a tab bar's `shadowImage` or `backgroundImage`.
 * [CN] 生成指定尺寸的纯色图片；color 为 nil 或 size 为空时返回 nil。动态颜色（如 `systemBackgroundColor`、
 *      `+[UIColor cyl_colorWithLightColor:darkColor:]`）生成的图片会跟随深色模式，可用于 TabBar 的 `shadowImage`、`backgroundImage` 等。
 */
+ (nullable UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size;

/*!
 * [EN] Returns a solid-color image of `size` with rounded corners. A dynamic color gives an image that follows Dark Mode.
 * [CN] 生成指定尺寸、带圆角的纯色图片。动态颜色生成的图片会跟随深色模式。
 */
+ (nullable UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius;

/*!
 * FIX: issue #620
 * [EN] One image that shows `darkImage` where the view's interface style is dark and `lightImage` otherwise, like an
 *      asset catalog image with a Dark appearance. UIKit resolves it against each view's traits (image views, tab bar
 *      items, buttons), so it follows the system setting and any `overrideUserInterfaceStyle` on a window, view
 *      controller or view, and switches when the style changes. Rendering modes are kept. Returns the other image
 *      when one is nil, and `lightImage` on iOS 12.
 *
 *          CYLTabBarItemImage : [UIImage cyl_imageWithLightImage:[UIImage imageNamed:@"home"]
 *                                                       darkImage:[UIImage imageNamed:@"home_dark"]],
 *
 *      Images from an asset catalog with a Dark appearance already behave like this; pass their names as they are.
 * [CN] 一张图片：视图为深色界面风格时显示 `darkImage`，否则显示 `lightImage`，相当于 Asset Catalog 中带 Dark 外观的图片。
 *      UIKit 会按每个视图的 trait 解析它（图片视图、TabBarItem、按钮），因此会跟随系统设置以及 window、视图控制器、视图上的
 *      `overrideUserInterfaceStyle`，并在风格切换时自动切换。保留渲染模式。其中一张为 nil 时返回另一张；iOS 12 返回 `lightImage`。
 *      Asset Catalog 中已设置 Dark 外观的图片本身就是这样，直接传图片名即可。
 */
+ (nullable UIImage *)cyl_imageWithLightImage:(nullable UIImage *)lightImage darkImage:(nullable UIImage *)darkImage NS_SWIFT_NAME(cyl_image(withLight:dark:));

/*!
 * [EN] The tab image for `imageInfo` (a name or a UIImage, see `+cyl_getImageFromImageInfo:`) combined with
 *      `darkImageInfo` (also a name or a UIImage) as its dark image, like `+cyl_imageWithLightImage:darkImage:`; just the
 *      `imageInfo` image when `darkImageInfo` is nil. This is what `CYLTabBarItemDarkImage` and
 *      `CYLTabBarItemSelectedDarkImage` in `tabBarItemsAttributes` do.
 * [CN] 由 `imageInfo`（图片名或 UIImage，见 `+cyl_getImageFromImageInfo:`）与作为深色图片的 `darkImageInfo`（同样为图片名或 UIImage）
 *      合成的 Tab 图片，同 `+cyl_imageWithLightImage:darkImage:`；`darkImageInfo` 为 nil 时只返回 `imageInfo` 对应的图片。
 *      `tabBarItemsAttributes` 中的 `CYLTabBarItemDarkImage`、`CYLTabBarItemSelectedDarkImage` 即使用此方法。
 */
+ (nullable UIImage *)cyl_imageWithImageInfo:(nullable id)imageInfo darkImageInfo:(nullable id)darkImageInfo;

/*!
 * [EN] Same as `+cyl_imageWithLightImage:darkImage:`.
 * [CN] 同 `+cyl_imageWithLightImage:darkImage:`。
 */
+ (nullable UIImage *)cyl_lightOrDarkModeImageWithLightImage:(nullable UIImage *)lightImage
                                                   darkImage:(nullable UIImage *)darkImage;

/*!
 * [EN] Same as `+cyl_imageWithLightImage:darkImage:`; the returned object starts as the variant for `owner`'s current
 *      style (it still follows the style of whichever view shows it).
 * [CN] 同 `+cyl_imageWithLightImage:darkImage:`；返回对象的初始外观为 `owner` 当前风格对应的那张（之后仍随显示它的视图切换）。
 */
+ (nullable UIImage *)cyl_lightOrDarkModeImageWithOwner:(nullable id<UITraitEnvironment>)owner
                                             lightImage:(nullable UIImage *)lightImage
                                              darkImage:(nullable UIImage *)darkImage;

/*!
 * [EN] Loads two images by name and combines them like `+cyl_lightOrDarkModeImageWithOwner:lightImage:darkImage:`.
 *      With a nil `darkImageName`, the dark image comes from the asset's own Dark appearance, else from the naming
 *      convention (`lightImageName` + `cyl_darkImageNameSuffix`).
 * [CN] 按名称加载两张图片，并像 `+cyl_lightOrDarkModeImageWithOwner:lightImage:darkImage:` 一样合成。
 *      `darkImageName` 为 nil 时，深色图片取 asset 自身的 Dark 外观，否则按命名规范（`lightImageName` + `cyl_darkImageNameSuffix`）查找。
 */
+ (nullable UIImage *)cyl_lightOrDarkModeImageWithOwner:(nullable id<UITraitEnvironment>)owner
                                         lightImageName:(NSString *)lightImageName
                                          darkImageName:(nullable NSString *)darkImageName;

/*!
 * [EN] The variant of the asset image `assetImageName` for one interface style (e.g. to draw it elsewhere); the image
 *      as it is for `UIUserInterfaceStyleUnspecified`, on iOS 12, or when it has no asset.
 * [CN] 名为 `assetImageName` 的 asset 图片在指定界面风格下的版本（如需另行绘制时使用）；风格为 Unspecified、iOS 12
 *      或图片没有 asset 时返回原图。
 */
+ (nullable UIImage *)cyl_assetImageName:(NSString *)assetImageName userInterfaceStyle:(NSInteger)userInterfaceStyle;

/*!
 * FIX: issue #620
 * [EN] Naming convention for dark tab images given by name. A name in `tabBarItemsAttributes` (`CYLTabBarItemImage`,
 *      `CYLTabBarItemSelectedImage`) also loads its dark image, in this order:
 *      1. the image's own Dark appearance in the asset catalog, if it has one (recommended);
 *      2. otherwise an image named with this suffix: "home_normal" → "home_normal_dark", "home.png" → "home_dark.png".
 *      The two are combined into one image that follows Dark Mode. Without either, the image is used as before.
 *      `@"_dark"` by default; set another suffix (e.g. `@"-dark"`) to match your names, or nil to turn it off.
 *      Set it before creating the tab bar controller.
 * [CN] 按名称指定的 Tab 图片的深色命名规范。`tabBarItemsAttributes` 中的图片名（`CYLTabBarItemImage`、
 *      `CYLTabBarItemSelectedImage`）会同时加载其深色图片，顺序为：
 *      1. Asset Catalog 中该图片自身的 Dark 外观（推荐）；
 *      2. 否则按此后缀查找：「home_normal」→「home_normal_dark」，「home.png」→「home_dark.png」。
 *      两者合成为一张跟随深色模式的图片；都没有时与以前一样。默认 `@"_dark"`；可改为与你的命名一致的后缀（如 `@"-dark"`），
 *      设为 nil 关闭。请在创建 TabBarController 之前设置。
 */
@property (class, nonatomic, copy, nullable, getter=cyl_darkImageNameSuffix, setter=cyl_setDarkImageNameSuffix:) NSString *cyl_darkImageNameSuffix;

/*!
 * [EN] Returns the image described by `imageInfo` (name or UIImage), or a placeholder image when it is nil.
 * [CN] 根据 imageInfo（图片名或 UIImage）返回图片；imageInfo 为 nil 时返回占位图。
 */
+ (UIImage *)cyl_imageNamed:(nullable id)imageInfo;

/*!
 * [EN] Returns a UIImage from `imageInfo`: an NSString is loaded by name (always-original rendering) together with its
 *      dark image, if any (see `cyl_darkImageNameSuffix`); a UIImage is returned as is (combine two with
 *      `+cyl_imageWithLightImage:darkImage:`).
 * [CN] 根据 imageInfo 返回图片：NSString 按名称加载（始终原图渲染），并带上其深色图片（如果有，见 `cyl_darkImageNameSuffix`）；
 *      UIImage 直接返回（两张图可用 `+cyl_imageWithLightImage:darkImage:` 合成）。
 */
+ (nullable UIImage *)cyl_getImageFromImageInfo:(id)imageInfo;

/**
 *  tabItemPlaceholderImage
 *
 *  @return UIImage
 * [EN] Returns a 1×1 transparent placeholder image for tab items without an image.
 * [CN] 返回 1×1 的透明占位图，用于没有图片的 TabBarItem。
 */
+ (UIImage *)cyl_tabItemPlaceholderImage;

/*!
 * FIX: issue #605, #215
 * [EN] An animated image from GIF data, playing for the total duration of its frames (shared evenly between them), e.g. for the icon view of
 *      `-[CYLTabBarController setTabBarItemIconViewProvider:atIndex:]`: `[[UIImageView alloc] initWithImage:image]`
 *      plays it. The first frame when the data has one frame; nil when it is not an image.
 * [CN] 由 GIF 数据生成动图，播放时长为各帧时长之和（平均分配给每帧），例如用于 `-[CYLTabBarController setTabBarItemIconViewProvider:atIndex:]` 的图标视图：
 *      `[[UIImageView alloc] initWithImage:image]` 即可播放。只有一帧时返回该帧；不是图片时返回 nil。
 */
+ (nullable UIImage *)cyl_animatedImageWithGIFData:(NSData *)data;

/*!
 * FIX: issue #601, #337, #215
 * [EN] Loads an image from `URL`: from memory, else from the disk cache (7 days), else downloads it. A GIF becomes an
 *      animated image (`+cyl_animatedImageWithGIFData:`). `completion` runs on the main queue, with nil on failure. Used by
 *      `-[CYLTabBarController setTabBarItemIconWithURL:selectedURL:size:atIndex:]`.
 * [CN] 从 `URL` 加载图片：先查内存，再查磁盘缓存（7 天），否则下载。GIF 会生成动图（`+cyl_animatedImageWithGIFData:`）。`completion`
 *      在主队列回调，失败时为 nil。供 `-[CYLTabBarController setTabBarItemIconWithURL:selectedURL:size:atIndex:]` 使用。
 */
+ (void)cyl_loadImageWithURL:(NSURL *)URL completion:(void (^)(UIImage * _Nullable image))completion;

@end

NS_ASSUME_NONNULL_END
