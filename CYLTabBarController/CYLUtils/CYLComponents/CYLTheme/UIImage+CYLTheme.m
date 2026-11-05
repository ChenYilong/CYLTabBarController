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
 * [EN] A new image object that draws like `image` (asset, Dark Mode variants, symbol configuration, cap insets and
 *      animation kept): changing the rendering mode twice always makes a new object. nil when UIKit returned `image`.
 * [CN] 绘制效果与 `image` 相同的新图片对象（保留资源目录、深色模式版本、符号配置、拉伸区域与动画）：修改两次渲染模式总会得到新对象。
 *      UIKit 返回 `image` 本身时为 nil。
 */
static UIImage *_Nullable CYLThemeImageDistinctCopy(UIImage *image) {
    UIImageRenderingMode mode = image.renderingMode;
    UIImageRenderingMode otherMode = (mode == UIImageRenderingModeAlwaysOriginal) ? UIImageRenderingModeAlwaysTemplate : UIImageRenderingModeAlwaysOriginal;
    UIImage *copy = [[image imageWithRenderingMode:otherMode] imageWithRenderingMode:mode];
    return (copy && copy != image) ? copy : nil;
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
    UIImage *image = providedImage ? CYLThemeImageDistinctCopy(providedImage) : CYLThemeImageTransparent();
    if (!image) {
        // [EN] Never mark an image UIKit may share (e.g. one of `+imageNamed:`): return it as a plain image.
        // [CN] 不能标记 UIKit 可能共享的图片（例如 `+imageNamed:` 返回的图片）：作为普通图片返回。
        NSLog(@"🔴 UIImage (CYLTheme): could not copy the image of the provider; it will not follow the theme.");
        return providedImage ?: CYLThemeImageTransparent();
    }
    CYLThemeImageInfo *info = [[CYLThemeImageInfo alloc] init];
    info.managerName = managerName;
    info.provider = provider;
    objc_setAssociatedObject(image, &CYLThemeImageInfoKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return image;
}

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
