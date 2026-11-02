//
//  UIImage+CYLTabBarControllerExtention.m
//  CYLTabBarController
//
//  Created by chenyilong on 18/4/2026.
//  Copyright © 2026 微博@iOS程序犭袁. All rights reserved.
//

#import "UIImage+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"
@implementation UIImage (CYLTabBarControllerExtention)

+ (nullable UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size {
    if (!color || size.width <= 0 || size.height <= 0) { return nil; }
    return [self cyl_imageWithColor:color size:size cornerRadius:0 renderingMode:UIImageRenderingModeAlwaysOriginal];
}

#pragma mark - Dark Mode (#552, #620)

/// A copy of `image` that belongs to no image asset, so it can be registered in a new one. Images that are not
/// bitmap based (e.g. symbols) are returned as they are.
static UIImage *CYLImageForRegistering(UIImage *image) {
    CGImageRef cgImage = image.CGImage;
    if (!cgImage) {
        return image;
    }
    UIImage *copy = [UIImage imageWithCGImage:cgImage scale:image.scale orientation:image.imageOrientation];
    return [copy imageWithRenderingMode:image.renderingMode];
}

/// The variant of `image` for `style` when it comes from an asset with appearances (e.g. an asset catalog image, or one
/// made by `+cyl_imageWithLightImage:darkImage:`), keeping its rendering mode; `image` itself otherwise. Without it, an
/// asset image passed while the app is dark would put its dark bitmap in the light slot.
static UIImage *CYLImageVariantForStyle(UIImage *image, UIUserInterfaceStyle style) API_AVAILABLE(ios(13.0)) {
    if (!image.imageAsset) {
        return image;
    }
    UITraitCollection *traits = [UITraitCollection traitCollectionWithTraitsFromCollections:@[
        [UITraitCollection traitCollectionWithDisplayScale:image.scale],
        [UITraitCollection traitCollectionWithUserInterfaceStyle:style],
    ]];
    UIImage *variant = [image.imageAsset imageWithTraitCollection:traits];
    return variant ? [variant imageWithRenderingMode:image.renderingMode] : image;
}

+ (nullable UIImage *)cyl_imageWithLightImage:(nullable UIImage *)lightImage darkImage:(nullable UIImage *)darkImage {
    if (!lightImage || !darkImage) {
        return lightImage ?: darkImage;
    }
    if (@available(iOS 13.0, *)) {
        lightImage = CYLImageVariantForStyle(lightImage, UIUserInterfaceStyleLight);
        darkImage = CYLImageVariantForStyle(darkImage, UIUserInterfaceStyleDark);
        // Registered like an asset catalog image with "Any" and "Dark" appearances: the light image for any style
        // (light and unspecified), the dark one for dark. UIKit resolves such an image against each view's traits.
        UITraitCollection *anyTraits = [UITraitCollection traitCollectionWithDisplayScale:lightImage.scale];
        UITraitCollection *darkTraits = [UITraitCollection traitCollectionWithTraitsFromCollections:@[
            [UITraitCollection traitCollectionWithDisplayScale:darkImage.scale],
            [UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark],
        ]];
        UIImageAsset *imageAsset = [[UIImageAsset alloc] init];
        [imageAsset registerImage:CYLImageForRegistering(lightImage) withTraitCollection:anyTraits];
        [imageAsset registerImage:CYLImageForRegistering(darkImage) withTraitCollection:darkTraits];
        return [imageAsset imageWithTraitCollection:[UITraitCollection currentTraitCollection]];
    }
    return lightImage;
}

#pragma mark - Dark images by name

static NSString *CYLDarkImageNameSuffix = @"_dark";

+ (nullable NSString *)cyl_darkImageNameSuffix {
    return CYLDarkImageNameSuffix;
}

+ (void)cyl_setDarkImageNameSuffix:(nullable NSString *)darkImageNameSuffix {
    CYLDarkImageNameSuffix = darkImageNameSuffix.length > 0 ? [darkImageNameSuffix copy] : nil;
}

/// `name` with the dark suffix before its extension, if any: "home" → "home_dark", "home.png" → "home_dark.png".
/// nil when the convention is off or `name` already ends with the suffix.
static NSString *CYLDarkImageNameForName(NSString *name) {
    NSString *suffix = CYLDarkImageNameSuffix;
    NSString *baseName = name.stringByDeletingPathExtension;
    if (suffix.length == 0 || baseName.length == 0 || [baseName hasSuffix:suffix]) {
        return nil;
    }
    NSString *darkName = [baseName stringByAppendingString:suffix];
    return name.pathExtension.length > 0 ? [darkName stringByAppendingPathExtension:name.pathExtension] : darkName;
}

/// YES if `image` comes from an asset with its own Dark appearance, e.g. an asset catalog image set to "Any, Dark".
static BOOL CYLImageHasDarkAppearance(UIImage *image) {
    if (@available(iOS 13.0, *)) {
        UIImageAsset *imageAsset = image.imageAsset;
        if (!imageAsset) {
            return NO;
        }
        UIImage *lightImage = [imageAsset imageWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        UIImage *darkImage = [imageAsset imageWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
        return lightImage && darkImage && lightImage != darkImage && lightImage.CGImage != darkImage.CGImage;
    }
    return NO;
}

/*!
 * [EN] The image named `name`, with its dark image when it has one: the asset's own Dark appearance (which wins, so one
 *      image never gets two dark sources), else the image named `name` + `cyl_darkImageNameSuffix`.
 * [CN] 名为 `name` 的图片，并带上它的深色图片（如果有）：优先使用 asset 自身的 Dark 外观（同一张图不会有两个深色来源），
 *      否则使用名为 `name` + `cyl_darkImageNameSuffix` 的图片。
 */
+ (nullable UIImage *)cyl_imageNamedFollowingDarkMode:(NSString *)name renderingMode:(UIImageRenderingMode)renderingMode {
    UIImage *image = [UIImage imageNamed:name];
    if (!image || CYLImageHasDarkAppearance(image)) {
        return [image imageWithRenderingMode:renderingMode];
    }
    NSString *darkName = CYLDarkImageNameForName(name);
    UIImage *darkImage = darkName ? [UIImage imageNamed:darkName] : nil;
    image = [image imageWithRenderingMode:renderingMode];
    if (!darkImage) {
        return image;
    }
    return [self cyl_imageWithLightImage:image darkImage:[darkImage imageWithRenderingMode:renderingMode]];
}

+ (UIImage *)cyl_assetImageName:(NSString *)assetImageName
             userInterfaceStyle:(NSInteger)userInterfaceStyle  {
    // This used to load an image named "image" whatever the name passed.
    UIImage *image = [UIImage imageNamed:assetImageName];
    if (@available(iOS 13.0, *)) {
        if (image.imageAsset && userInterfaceStyle != UIUserInterfaceStyleUnspecified) {
            UITraitCollection *trait = [UITraitCollection traitCollectionWithUserInterfaceStyle:userInterfaceStyle];
            image = [image.imageAsset imageWithTraitCollection:trait] ?: image;
        }
    }
    return image;
}

+ (UIImage *)cyl_lightOrDarkModeImageWithLightImage:(UIImage *)lightImage
                                          darkImage:(UIImage *)darkImage  {
    return [self cyl_imageWithLightImage:lightImage darkImage:darkImage];
}

+ (UIImage *)cyl_lightOrDarkModeImageWithOwner:(id<UITraitEnvironment>)owner
                                lightImageName:(NSString *)lightImageName
                                 darkImageName:(NSString *)darkImageName {
    if (darkImageName.length == 0) {
        // No dark name: follow the asset's own Dark appearance or the naming convention.
        UIImage *image = lightImageName.length > 0 ? [self cyl_imageNamedFollowingDarkMode:lightImageName renderingMode:UIImageRenderingModeAutomatic] : nil;
        return [UIImage cyl_lightOrDarkModeImageWithOwner:owner lightImage:image darkImage:nil];
    }
    UIImage *lightImage = lightImageName.length > 0 ? [UIImage imageNamed:lightImageName] : nil;
    UIImage *darkImage = [UIImage imageNamed:darkImageName];
    return [UIImage cyl_lightOrDarkModeImageWithOwner:owner lightImage:lightImage darkImage:darkImage];
}

/*!
 * FIX: issue #620
 * [EN] This used to pick one of the two images once, by the window scene's style when `owner` was nil. A scene ignores
 *      `overrideUserInterfaceStyle` on its windows, so a window forced to light or dark still got the image of the
 *      system style, and the image never changed afterwards. It now returns an image that holds both and follows the
 *      style of whichever view shows it; `owner` only picks which one the returned object starts as.
 * [CN] 原先只选择一次，`owner` 为 nil 时依据 window scene 的风格。scene 不认其 window 上的 `overrideUserInterfaceStyle`，
 *      因此强制为浅色或深色的 window 仍得到系统风格的图片，之后也不再切换。现在返回同时包含两张图的图片，随显示它的视图的风格切换；
 *      `owner` 只决定返回对象的初始外观。
 */
+ (UIImage *)cyl_lightOrDarkModeImageWithOwner:(id<UITraitEnvironment>)owner
                                    lightImage:(UIImage *)lightImage
                                     darkImage:(UIImage *)darkImage {
    UIImage *image = [self cyl_imageWithLightImage:lightImage darkImage:darkImage];
    if (@available(iOS 13.0, *)) {
        if (owner && image.imageAsset) {
            image = [image.imageAsset imageWithTraitCollection:owner.traitCollection] ?: image;
        }
    }
    return image;
}

+ (nullable UIImage *)cyl_getImageFromImageInfo:(id)imageInfo {
    UIImage *image = nil;
    if ([imageInfo isKindOfClass:[NSString class]]) {
        // A name also brings its dark image: the asset's own Dark appearance, else "<name>_dark" (see
        // `cyl_darkImageNameSuffix`). Both keep the always-original rendering a name has always had.
        image = [self cyl_imageNamedFollowingDarkMode:imageInfo renderingMode:UIImageRenderingModeAlwaysOriginal];
    } else if ([imageInfo isKindOfClass:[UIImage class]]) {
        image = (UIImage *)imageInfo;
    }
    return image;
}

+ (nullable UIImage *)cyl_imageWithImageInfo:(nullable id)imageInfo darkImageInfo:(nullable id)darkImageInfo {
    UIImage *image = imageInfo ? [self cyl_getImageFromImageInfo:imageInfo] : nil;
    UIImage *darkImage = darkImageInfo ? [self cyl_getImageFromImageInfo:darkImageInfo] : nil;
    if (!darkImage) {
        return image;
    }
    // A dark image given explicitly replaces any the name brought (asset appearance or naming convention).
    return [self cyl_imageWithLightImage:image darkImage:darkImage];
}

+ (UIImage *)cyl_imageNamed:(nullable id)imageInfo {
    UIImage *image = nil;
    if (imageInfo) {
        image = [self cyl_getImageFromImageInfo:imageInfo];
    }
    else {
        image = [self cyl_tabItemPlaceholderImage];
    }
    return image;
}

+ (UIImage *)cyl_tabItemPlaceholderImage {
    // Transparent: it only keeps the item's layout. It used to be white, drawn as is (always original), so a tab
    // without an image showed a white dot, plain to see on a dark tab bar.
    // 透明：只用于保持布局。原先是白色且按原图绘制，没有图片的 Tab 会显示一个白点，在深色 TabBar 上尤其明显。
    CGSize placeholderSize = CGSizeMake(1, 1);
    UIImage *placeholderImage = [UIImage cyl_imageWithColor:[UIColor clearColor] size:placeholderSize];
    return placeholderImage;
}

+ (UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius {
    return [self cyl_imageWithColor:color size:size cornerRadius:cornerRadius renderingMode:UIImageRenderingModeAutomatic];
}

/*!
 * [EN] A dynamic color (e.g. `systemBackgroundColor`, `+cyl_colorWithLightColor:darkColor:`) is drawn twice, resolved
 *      for light and for dark, and returned as one image that follows Dark Mode. Drawing `color.CGColor` once froze it
 *      in the style current at that moment.
 * [CN] 动态颜色（如 `systemBackgroundColor`、`+cyl_colorWithLightColor:darkColor:`）分别按浅色和深色解析并绘制两次，
 *      合成一张跟随深色模式的图片。原先只用 `color.CGColor` 绘制一次，颜色被固定为当时的风格。
 */
+ (UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius renderingMode:(UIImageRenderingMode)renderingMode {
    color = color ? color : [UIColor clearColor];
    if (@available(iOS 13.0, *)) {
        UIColor *lightColor = [color resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        UIColor *darkColor = [color resolvedColorWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
        if (![lightColor isEqual:darkColor]) {
            UIImage *lightImage = [self cyl_staticImageWithColor:lightColor size:size cornerRadius:cornerRadius];
            UIImage *darkImage = [self cyl_staticImageWithColor:darkColor size:size cornerRadius:cornerRadius];
            return [self cyl_imageWithLightImage:[lightImage imageWithRenderingMode:renderingMode]
                                       darkImage:[darkImage imageWithRenderingMode:renderingMode]];
        }
    }
    return [[self cyl_staticImageWithColor:color size:size cornerRadius:cornerRadius] imageWithRenderingMode:renderingMode];
}

+ (UIImage *)cyl_staticImageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius {
    // Not `-getRed:green:blue:alpha:`: it fails for grayscale colors such as `+whiteColor` and left the alpha at 0.
    BOOL opaque = (cornerRadius == 0.0 && CGColorGetAlpha(color.CGColor) == 1.0);
    return [self cyl_imageWithSize:size opaque:opaque scale:0 actions:^(CGContextRef contextRef) {
        CGContextSetFillColorWithColor(contextRef, color.CGColor);
        if (cornerRadius > 0) {
            UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:cornerRadius];
            [path addClip];
            [path fill];
        } else {
            CGContextFillRect(contextRef, CGRectMake(0, 0, size.width, size.height));
        }
    }];
}

+ (UIImage *)cyl_imageWithSize:(CGSize)size opaque:(BOOL)opaque scale:(CGFloat)scale actions:(void (^)(CGContextRef contextRef))actionBlock {
    if (!actionBlock || size.width <= 0 || size.height <= 0) {
        return nil;
    }
    // `UIGraphicsImageRenderer`: `UIGraphicsBeginImageContextWithOptions` is deprecated (iOS 17), and its early return
    // on a nil context left the image context pushed.
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat preferredFormat];
    format.opaque = opaque;
    if (scale > 0) {
        format.scale = scale;   // 0 keeps the screen scale, as `UIGraphicsBeginImageContextWithOptions` did
    }
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:size format:format];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        actionBlock(rendererContext.CGContext);
    }];
}

@end
