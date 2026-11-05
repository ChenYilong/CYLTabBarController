//
//  UIImage+CYLTheme.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/05/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIImage+CYLTheme.h"
#import "CYLThemeManagerCenter.h"
#import "CYLThemePrivate.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] What a theme image is made of, kept on the image: enough to make the image of another theme.
 * [CN] 主题图片的组成，保存在图片上：足以生成其他主题下的图片。
 */
@interface CYLThemeImageInfo : NSObject
@property (nonatomic, copy) NSObject<NSCopying> *managerName;
@property (nonatomic, copy) CYLThemeImageProvider provider;
@end

@implementation CYLThemeImageInfo
@end

static char CYLThemeImageInfoKey;

static CYLThemeImageInfo *_Nullable CYLThemeImageInfoOfImage(UIImage *image) {
    return objc_getAssociatedObject(image, &CYLThemeImageInfoKey);
}

/*!
 * [EN] A new image object that draws like one image (no Dark Mode variants): the same bitmap (`CGImage`, or drawn when
 *      there is none), scale, orientation, rendering mode, cap insets and alignment insets; an animated image keeps its
 *      frames. Never an object UIKit may share: `-imageWithRenderingMode:` and similar methods cache their results, so
 *      they can return the very image they were sent to.
 * [CN] 与某一张图片绘制效果相同的新图片对象（不含深色模式版本）：相同的位图（`CGImage`，没有时重新绘制）、scale、方向、渲染模式、
 *      拉伸区域与对齐边距；动图保留其帧。不会是 UIKit 可能共享的对象：`-imageWithRenderingMode:` 等方法会缓存结果，可能返回原图片本身。
 */
static UIImage *CYLThemeImageBitmapCopy(UIImage *image) {
    // [EN] An SF Symbol stays a symbol (its weight and scale keep following the configuration), when UIKit gives a new
    //      object; otherwise it is copied as a bitmap below.
    // [CN] SF Symbol 保持为符号（粗细与缩放继续跟随配置），前提是 UIKit 返回新对象；否则在下面按位图复制。
    if (@available(iOS 13.0, *)) {
        if (image.isSymbolImage) {
            UIImageSymbolConfiguration *configuration = image.symbolConfiguration ?: [UIImageSymbolConfiguration unspecifiedConfiguration];
            UIImage *symbol = [image imageByApplyingSymbolConfiguration:configuration];
            if (symbol && symbol != image && symbol.isSymbolImage) {
                UIImage *symbolCopy = [symbol imageWithRenderingMode:image.renderingMode];
                if (symbolCopy != image) {
                    return symbolCopy;
                }
            }
        }
    }
    UIImage *copy = nil;
    if (image.images.count > 1) {
        copy = [UIImage animatedImageWithImages:image.images duration:image.duration];
    } else if (image.CGImage) {
        copy = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:image.imageOrientation];
    } else {
        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
        format.scale = image.scale;
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:image.size format:format];
        copy = [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [image drawAtPoint:CGPointZero];
        }];
    }
    copy = [copy imageWithRenderingMode:image.renderingMode];
    if (!UIEdgeInsetsEqualToEdgeInsets(image.capInsets, UIEdgeInsetsZero)) {
        copy = [copy resizableImageWithCapInsets:image.capInsets resizingMode:image.resizingMode];
    }
    if (!UIEdgeInsetsEqualToEdgeInsets(image.alignmentRectInsets, UIEdgeInsetsZero)) {
        copy = [copy imageWithAlignmentRectInsets:image.alignmentRectInsets];
    }
    return copy;
}

/*!
 * [EN] New image objects that draw like `image`, as `CYLThemeImageBitmapCopy()`; the first is the one to show. An image
 *      with light and dark variants (an asset catalog image, iOS 13+) gets a new `UIImageAsset` with a copy of each, so
 *      it still follows Dark Mode; every copy is returned, to be marked.
 * [CN] 绘制效果与 `image` 相同的新图片对象，同 `CYLThemeImageBitmapCopy()`；第一个为要显示的图片。带有浅色与深色版本的图片（资源目录图片，
 *      iOS 13+）会得到一个新的 `UIImageAsset`，其中是每个版本的副本，因此仍跟随深色模式；返回所有副本，以便全部标记。
 */
static NSArray<UIImage *> *CYLThemeImageDistinctCopies(UIImage *image) {
    if (@available(iOS 13.0, *)) {
        UIImageAsset *asset = image.imageAsset;
        UIImage *light = [asset imageWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
        UIImage *dark = [asset imageWithTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
        if (light && dark && light != dark) {
            UIImage *lightCopy = CYLThemeImageBitmapCopy(light);
            UIImage *darkCopy = CYLThemeImageBitmapCopy(dark);
            UIImageAsset *newAsset = [[UIImageAsset alloc] init];
            [newAsset registerImage:lightCopy withTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleLight]];
            [newAsset registerImage:darkCopy withTraitCollection:[UITraitCollection traitCollectionWithUserInterfaceStyle:UIUserInterfaceStyleDark]];
            UIImage *resolved = [newAsset imageWithTraitCollection:UITraitCollection.currentTraitCollection] ?: lightCopy;
            NSMutableArray<UIImage *> *copies = [NSMutableArray arrayWithObject:resolved];
            for (UIImage *copy in @[ lightCopy, darkCopy ]) {
                if (copy != resolved) {
                    [copies addObject:copy];
                }
            }
            return copies;
        }
    }
    return @[ CYLThemeImageBitmapCopy(image) ];
}

/// [EN] A transparent 1 × 1 pt image, a new object each time. [CN] 透明的 1 × 1 pt 图片，每次都是新对象。
static UIImage *CYLThemeImageTransparent(void) {
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)];
    return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {}];
}

static UIImage *CYLThemeImageMake(NSObject<NSCopying> *managerName, CYLThemeImageProvider provider) {
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:managerName];
    UIImage *providedImage = provider(manager, manager.currentThemeIdentifier, manager.currentTheme);
    // [EN] A theme image returned by the provider: its own image of this theme. [CN] provider 返回主题图片时：使用其当前主题的图片。
    for (NSUInteger depth = 0; depth < 8 && providedImage; depth++) {
        CYLThemeImageInfo *nestedInfo = CYLThemeImageInfoOfImage(providedImage);
        if (!nestedInfo) {
            break;
        }
        CYLThemeManager *nestedManager = [CYLThemeManagerCenter themeManagerWithName:nestedInfo.managerName];
        providedImage = nestedInfo.provider(nestedManager, nestedManager.currentThemeIdentifier, nestedManager.currentTheme);
    }
    // [EN] Never the provider's image itself, which UIKit may share (e.g. one of `+imageNamed:`): new objects, all marked.
    // [CN] 不使用 provider 返回的图片本身（UIKit 可能共享它，例如 `+imageNamed:` 的图片）：使用新对象，并全部标记。
    NSArray<UIImage *> *images = providedImage ? CYLThemeImageDistinctCopies(providedImage) : @[ CYLThemeImageTransparent() ];
    CYLThemeImageInfo *info = [[CYLThemeImageInfo alloc] init];
    info.managerName = managerName;
    info.provider = provider;
    for (UIImage *image in images) {
        objc_setAssociatedObject(image, &CYLThemeImageInfoKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return images.firstObject;
}

#pragma mark - Dynamic theme images

/*!
 * [EN] An image that is always the provider's image of the current theme (`+cyl_dynamicImageWithThemeProvider:`): every
 *      public property and drawing method answers with that image, so an image made before a theme change and assigned
 *      after it still shows the current theme. The theme walk assigns it again on a change (UIKit skips assigning the
 *      very same image), since a view keeps what it drew.
 * [CN] 始终为 provider 在当前主题下的图片（`+cyl_dynamicImageWithThemeProvider:`）：所有公开属性与绘制方法都以该图片作答，因此在主题切换
 *      前创建、切换后才赋值的图片仍显示当前主题。由于视图会保留已绘制的内容，主题切换时由遍历重新赋值（UIKit 会跳过赋值同一个图片）。
 */
@interface CYLThemeDynamicImage : UIImage
@property (nonatomic, copy) NSObject<NSCopying> *cyl_managerName;
@property (nonatomic, copy) CYLThemeImageProvider cyl_provider;
@end

@implementation CYLThemeDynamicImage

/// [EN] The image of the current theme (nested theme images resolved). [CN] 当前主题下的图片（嵌套的主题图片也会被解析）。
- (UIImage *)cyl_resolvedImage {
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:self.cyl_managerName];
    UIImage *image = self.cyl_provider(manager, manager.currentThemeIdentifier, manager.currentTheme);
    for (NSUInteger depth = 0; depth < 8 && image; depth++) {
        if ([image isKindOfClass:[CYLThemeDynamicImage class]]) {
            image = [(CYLThemeDynamicImage *)image cyl_resolvedImage];
            continue;
        }
        CYLThemeImageInfo *nestedInfo = CYLThemeImageInfoOfImage(image);
        if (!nestedInfo) {
            break;
        }
        CYLThemeManager *nestedManager = [CYLThemeManagerCenter themeManagerWithName:nestedInfo.managerName];
        image = nestedInfo.provider(nestedManager, nestedManager.currentThemeIdentifier, nestedManager.currentTheme);
    }
    static UIImage *transparent;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        transparent = CYLThemeImageTransparent();
    });
    return image ?: transparent;
}

/// [EN] A dynamic image whose image is `transform` applied to this one's. [CN] 图片为对本图片应用 `transform` 结果的动态图片。
- (UIImage *)cyl_dynamicImageWithTransform:(UIImage *(^)(UIImage *image))transform {
    CYLThemeImageProvider provider = self.cyl_provider;
    NSObject<NSCopying> *managerName = self.cyl_managerName;
    CYLThemeDynamicImage *base = self;
    return [UIImage cyl_dynamicImageWithThemeManagerName:managerName provider:^UIImage *(CYLThemeManager *manager, id identifier, id theme) {
        return transform([base cyl_resolvedImage]) ?: provider(manager, identifier, theme);
    }];
}

- (CGSize)size { return [self cyl_resolvedImage].size; }
- (CGFloat)scale { return [self cyl_resolvedImage].scale; }
- (nullable CGImageRef)CGImage { return [self cyl_resolvedImage].CGImage; }
- (nullable CIImage *)CIImage { return [self cyl_resolvedImage].CIImage; }
- (UIImageOrientation)imageOrientation { return [self cyl_resolvedImage].imageOrientation; }
- (nullable NSArray<UIImage *> *)images { return [self cyl_resolvedImage].images; }
- (NSTimeInterval)duration { return [self cyl_resolvedImage].duration; }
- (UIEdgeInsets)capInsets { return [self cyl_resolvedImage].capInsets; }
- (UIImageResizingMode)resizingMode { return [self cyl_resolvedImage].resizingMode; }
- (UIEdgeInsets)alignmentRectInsets { return [self cyl_resolvedImage].alignmentRectInsets; }
- (UIImageRenderingMode)renderingMode { return [self cyl_resolvedImage].renderingMode; }
- (BOOL)flipsForRightToLeftLayoutDirection { return [self cyl_resolvedImage].flipsForRightToLeftLayoutDirection; }
- (UITraitCollection *)traitCollection { return [self cyl_resolvedImage].traitCollection; }
- (nullable UIImageAsset *)imageAsset { return [self cyl_resolvedImage].imageAsset; }
- (BOOL)isSymbolImage API_AVAILABLE(ios(13.0)) { return [self cyl_resolvedImage].isSymbolImage; }
- (nullable UIImageSymbolConfiguration *)symbolConfiguration API_AVAILABLE(ios(13.0)) { return [self cyl_resolvedImage].symbolConfiguration; }
- (CGFloat)baselineOffsetFromBottom API_AVAILABLE(ios(13.0)) { return [self cyl_resolvedImage].baselineOffsetFromBottom; }
- (BOOL)hasBaseline API_AVAILABLE(ios(13.0)) { return [self cyl_resolvedImage].hasBaseline; }

- (void)drawAtPoint:(CGPoint)point { [[self cyl_resolvedImage] drawAtPoint:point]; }
- (void)drawAtPoint:(CGPoint)point blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha {
    [[self cyl_resolvedImage] drawAtPoint:point blendMode:blendMode alpha:alpha];
}
- (void)drawInRect:(CGRect)rect { [[self cyl_resolvedImage] drawInRect:rect]; }
- (void)drawInRect:(CGRect)rect blendMode:(CGBlendMode)blendMode alpha:(CGFloat)alpha {
    [[self cyl_resolvedImage] drawInRect:rect blendMode:blendMode alpha:alpha];
}
- (void)drawAsPatternInRect:(CGRect)rect { [[self cyl_resolvedImage] drawAsPatternInRect:rect]; }

// [EN] Derived images stay dynamic. [CN] 派生图片仍为动态图片。
- (UIImage *)imageWithRenderingMode:(UIImageRenderingMode)renderingMode {
    return [self cyl_dynamicImageWithTransform:^UIImage *(UIImage *image) { return [image imageWithRenderingMode:renderingMode]; }];
}
- (UIImage *)imageWithAlignmentRectInsets:(UIEdgeInsets)alignmentInsets {
    return [self cyl_dynamicImageWithTransform:^UIImage *(UIImage *image) { return [image imageWithAlignmentRectInsets:alignmentInsets]; }];
}
- (UIImage *)resizableImageWithCapInsets:(UIEdgeInsets)capInsets {
    return [self cyl_dynamicImageWithTransform:^UIImage *(UIImage *image) { return [image resizableImageWithCapInsets:capInsets]; }];
}
- (UIImage *)resizableImageWithCapInsets:(UIEdgeInsets)capInsets resizingMode:(UIImageResizingMode)resizingMode {
    return [self cyl_dynamicImageWithTransform:^UIImage *(UIImage *image) { return [image resizableImageWithCapInsets:capInsets resizingMode:resizingMode]; }];
}
- (UIImage *)imageWithTintColor:(UIColor *)color API_AVAILABLE(ios(13.0)) {
    return [self cyl_dynamicImageWithTransform:^UIImage *(UIImage *image) { return [image imageWithTintColor:color]; }];
}
- (UIImage *)imageWithTintColor:(UIColor *)color renderingMode:(UIImageRenderingMode)renderingMode API_AVAILABLE(ios(13.0)) {
    return [self cyl_dynamicImageWithTransform:^UIImage *(UIImage *image) { return [image imageWithTintColor:color renderingMode:renderingMode]; }];
}

// [EN] Anything else (private UIKit methods included) goes to the image of the current theme.
// [CN] 其他消息（包括 UIKit 的私有方法）转发给当前主题的图片。
- (id)forwardingTargetForSelector:(SEL)aSelector {
    return [self cyl_resolvedImage];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@: %p, manager = %@, current = %@>", NSStringFromClass(self.class), self, self.cyl_managerName, [self cyl_resolvedImage]];
}

@end

BOOL CYLThemeImageIsDynamic(UIImage *_Nullable image) {
    return [image isKindOfClass:[CYLThemeDynamicImage class]];
}

#pragma mark - Refreshing

UIImage *CYLThemeImageRefreshedImage(UIImage *image) {
    // [EN] A dynamic image is the current theme's already: the same object, to be assigned again.
    // [CN] 动态图片已经是当前主题的图片：返回同一对象，由调用方重新赋值。
    if (CYLThemeImageIsDynamic(image)) {
        return image;
    }
    CYLThemeImageInfo *info = CYLThemeImageInfoOfImage(image);
    return info ? CYLThemeImageMake(info.managerName, info.provider) : image;
}

NSObject<NSCopying> *_Nullable CYLThemeImageManagerName(UIImage *image) {
    if (CYLThemeImageIsDynamic(image)) {
        return ((CYLThemeDynamicImage *)image).cyl_managerName;
    }
    return CYLThemeImageInfoOfImage(image).managerName;
}

@implementation UIImage (CYLTheme)

+ (UIImage *)cyl_imageWithThemeProvider:(CYLThemeImageProvider)provider {
    return CYLThemeImageMake(CYLThemeManagerNameDefault, provider);
}

+ (UIImage *)cyl_imageWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeImageProvider)provider {
    return CYLThemeImageMake(managerName, provider);
}

+ (UIImage *)cyl_dynamicImageWithThemeProvider:(CYLThemeImageProvider)provider {
    return [self cyl_dynamicImageWithThemeManagerName:CYLThemeManagerNameDefault provider:provider];
}

+ (UIImage *)cyl_dynamicImageWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeImageProvider)provider {
    CYLThemeDynamicImage *image = [[CYLThemeDynamicImage alloc] init];
    image.cyl_managerName = managerName;
    image.cyl_provider = provider;
    return image;
}

- (BOOL)cyl_isThemeImage {
    return CYLThemeImageIsDynamic(self) || CYLThemeImageInfoOfImage(self) != nil;
}

- (BOOL)cyl_isDynamicThemeImage {
    return CYLThemeImageIsDynamic(self);
}

- (UIImage *)cyl_imageForCurrentTheme {
    // [EN] For a dynamic image, a plain (marked) copy of the current theme's image. [CN] 动态图片：返回当前主题图片的普通（已标记）副本。
    if (CYLThemeImageIsDynamic(self)) {
        CYLThemeDynamicImage *dynamicImage = (CYLThemeDynamicImage *)self;
        return CYLThemeImageMake(dynamicImage.cyl_managerName, dynamicImage.cyl_provider);
    }
    return CYLThemeImageRefreshedImage(self);
}

@end

NS_ASSUME_NONNULL_END
