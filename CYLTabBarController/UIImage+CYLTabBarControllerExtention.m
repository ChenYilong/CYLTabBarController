//
//  UIImage+CYLTabBarControllerExtention.m
//  CYLTabBarController
//
//  Created by chenyilong on 18/4/2026.
//  Copyright © 2026 微博@iOS程序犭袁. All rights reserved.
//

#import "UIImage+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"
#import <ImageIO/ImageIO.h>
#import <CommonCrypto/CommonDigest.h>

/// Memory cache of `+cyl_loadImageWithURL:completion:`. 网络图片的内存缓存。
static NSCache<NSString *, UIImage *> *CYLRemoteImageMemoryCache(void) {
    static NSCache *cache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSCache alloc] init];
        cache.countLimit = 100;
    });
    return cache;
}

/// Disk cache directory of `+cyl_loadImageWithURL:completion:`. 网络图片的磁盘缓存目录。
static NSURL *CYLRemoteImageCacheDirectory(void) {
    NSURL *caches = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask].firstObject;
    return [caches URLByAppendingPathComponent:@"CYLTabBarController/RemoteImages" isDirectory:YES];
}

/// The cache key of a URL: its SHA-256. URL 的缓存 key：其 SHA-256。
static NSString *CYLRemoteImageCacheKey(NSURL *URL) {
    NSData *data = [URL.absoluteString dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);
    NSMutableString *key = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int index = 0; index < CC_SHA256_DIGEST_LENGTH; index++) {
        [key appendFormat:@"%02x", digest[index]];
    }
    return key;
}

/// An image from downloaded data: animated for a GIF, at the screen scale otherwise. 由数据生成图片：GIF 为动图，其他按屏幕倍数。
static UIImage *CYLRemoteImageWithData(NSData *data) {
    const char *bytes = data.bytes;
    if (data.length > 4 && memcmp(bytes, "GIF8", 4) == 0) {
        return [UIImage cyl_animatedImageWithGIFData:data];
    }
    return [UIImage imageWithData:data scale:[UIScreen mainScreen].scale];
}

@implementation UIImage (CYLTabBarControllerExtention)

+ (void)cyl_loadImageWithURL:(NSURL *)URL completion:(void (^)(UIImage *))completion {
    void (^finish)(UIImage *) = ^(UIImage *image) {
        dispatch_async(dispatch_get_main_queue(), ^{
            !completion ?: completion(image);
        });
    };
    if (!URL) {
        finish(nil);
        return;
    }
    NSString *key = CYLRemoteImageCacheKey(URL);
    UIImage *cachedImage = [CYLRemoteImageMemoryCache() objectForKey:key];
    if (cachedImage) {
        finish(cachedImage);
        return;
    }
    NSURL *fileURL = [CYLRemoteImageCacheDirectory() URLByAppendingPathComponent:key];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_UTILITY, 0), ^{
        NSDate *modificationDate = nil;
        [fileURL getResourceValue:&modificationDate forKey:NSURLContentModificationDateKey error:NULL];
        BOOL isFresh = modificationDate && -[modificationDate timeIntervalSinceNow] < 7 * 24 * 60 * 60;
        NSData *cachedData = isFresh ? [NSData dataWithContentsOfURL:fileURL] : nil;
        UIImage *diskImage = cachedData ? CYLRemoteImageWithData(cachedData) : nil;
        if (diskImage) {
            [CYLRemoteImageMemoryCache() setObject:diskImage forKey:key];
            finish(diskImage);
            return;
        }
        [[[NSURLSession sharedSession] dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 200;
            UIImage *image = (!error && data && statusCode / 100 == 2) ? CYLRemoteImageWithData(data) : nil;
            if (image) {
                [CYLRemoteImageMemoryCache() setObject:image forKey:key];
                [[NSFileManager defaultManager] createDirectoryAtURL:CYLRemoteImageCacheDirectory()
                                         withIntermediateDirectories:YES attributes:nil error:NULL];
                [data writeToURL:fileURL atomically:YES];
            }
            finish(image);
        }] resume];
    });
}

+ (UIImage *)cyl_animatedImageWithGIFData:(NSData *)data {
    if (data.length == 0) {
        return nil;
    }
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    if (!source) {
        return nil;
    }
    size_t count = CGImageSourceGetCount(source);
    CGFloat scale = [UIScreen mainScreen].scale;
    NSMutableArray<UIImage *> *frames = [NSMutableArray arrayWithCapacity:count];
    NSTimeInterval duration = 0;
    for (size_t index = 0; index < count; index++) {
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(source, index, NULL);
        if (!imageRef) {
            continue;
        }
        [frames addObject:[UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp]];
        CGImageRelease(imageRef);
        // The frame's delay, unclamped first; browsers treat very short delays as 0.1 s.
        // 帧时长，优先使用未修正值；与浏览器一致，过短的时长按 0.1 秒处理。
        NSDictionary *properties = (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, index, NULL);
        NSDictionary *gifProperties = properties[(__bridge NSString *)kCGImagePropertyGIFDictionary];
        NSNumber *delay = gifProperties[(__bridge NSString *)kCGImagePropertyGIFUnclampedDelayTime];
        if (delay.doubleValue <= 0) {
            delay = gifProperties[(__bridge NSString *)kCGImagePropertyGIFDelayTime];
        }
        duration += (delay.doubleValue < 0.011) ? 0.1 : delay.doubleValue;
    }
    CFRelease(source);
    if (frames.count <= 1) {
        return frames.firstObject;
    }
    return [UIImage animatedImageWithImages:frames duration:duration];
}

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
/*!
 * FIX: issue #535, #601
 * [EN] An image by name, or by the absolute path of a file anywhere (e.g. an icon downloaded to the Documents directory):
 *      a path is loaded with `+imageWithContentsOfFile:`, which does not keep it in the system image cache.
 * [CN] 按名称加载图片，或按任意位置文件的绝对路径加载（例如下载到 Documents 目录的图标）：路径使用 `+imageWithContentsOfFile:` 加载，
 *      不会进入系统图片缓存。
 */
static UIImage *CYLImageNamedOrAtPath(NSString *name) {
    if (name.isAbsolutePath) {
        return [UIImage imageWithContentsOfFile:name];
    }
    return [UIImage imageNamed:name];
}

+ (nullable UIImage *)cyl_imageNamedFollowingDarkMode:(NSString *)name renderingMode:(UIImageRenderingMode)renderingMode {
    UIImage *image = CYLImageNamedOrAtPath(name);
    if (!image || CYLImageHasDarkAppearance(image)) {
        return [image imageWithRenderingMode:renderingMode];
    }
    NSString *darkName = CYLDarkImageNameForName(name);
    UIImage *darkImage = darkName ? CYLImageNamedOrAtPath(darkName) : nil;
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
