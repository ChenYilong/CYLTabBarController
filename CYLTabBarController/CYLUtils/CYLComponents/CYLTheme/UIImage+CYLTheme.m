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
static UIImage *CYLThemeImageBitmapCopy(UIImage *image, CGFloat scale) {
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
        copy = [UIImage imageWithCGImage:image.CGImage scale:scale orientation:image.imageOrientation];
    } else {
        UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
        format.scale = scale;
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
        // [EN] UIKit gives every image light and dark objects, the same bitmap for an image without a dark variant: only
        //      different bitmaps make a new asset. The copies keep the scale of `image`.
        // [CN] UIKit 会为任何图片提供浅色与深色对象，没有深色版本的图片两者位图相同：只有位图不同时才新建资源。副本保留 `image` 的 scale。
        if (light && dark && light != dark && light.CGImage != dark.CGImage) {
            UIImage *lightCopy = CYLThemeImageBitmapCopy(light, image.scale);
            UIImage *darkCopy = CYLThemeImageBitmapCopy(dark, image.scale);
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
    return @[ CYLThemeImageBitmapCopy(image, image.scale) ];
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

#pragma mark - Refreshing

UIImage *CYLThemeImageRefreshedImage(UIImage *image) {
    CYLThemeImageInfo *info = CYLThemeImageInfoOfImage(image);
    return info ? CYLThemeImageMake(info.managerName, info.provider) : image;
}

NSObject<NSCopying> *_Nullable CYLThemeImageManagerName(UIImage *image) {
    return CYLThemeImageInfoOfImage(image).managerName;
}

@implementation UIImage (CYLTheme)

+ (UIImage *)cyl_imageWithThemeProvider:(CYLThemeImageProvider)provider {
    return CYLThemeImageMake(CYLThemeManagerNameDefault, provider);
}

+ (UIImage *)cyl_imageWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeImageProvider)provider {
    return CYLThemeImageMake(managerName, provider);
}

- (BOOL)cyl_isThemeImage {
    return CYLThemeImageInfoOfImage(self) != nil;
}

- (UIImage *)cyl_imageForCurrentTheme {
    return CYLThemeImageRefreshedImage(self);
}

@end

NS_ASSUME_NONNULL_END
