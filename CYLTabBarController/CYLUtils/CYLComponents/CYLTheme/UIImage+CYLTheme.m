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
 * [CN] 主题图片的组成，保存在图片上：足以生成另一个主题的图片。
 */
@interface CYLThemeImageInfo : NSObject
@property (nonatomic, copy, nullable) NSString *name;
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
 * [EN] The provider's image for the current theme, with a nested theme image resolved; an empty image for nil.
 * [CN] provider 在当前主题下的图片，嵌套的主题图片也会被解析；nil 时为空图片。
 */
static UIImage *CYLThemeImageResolve(NSObject<NSCopying> *managerName, CYLThemeImageProvider provider) {
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:managerName];
    UIImage *image = provider(manager, manager.currentThemeIdentifier, manager.currentTheme);
    for (NSUInteger depth = 0; depth < 8 && image; depth++) {
        CYLThemeImageInfo *info = CYLThemeImageInfoOfImage(image);
        if (!info) {
            break;
        }
        CYLThemeManager *nestedManager = [CYLThemeManagerCenter themeManagerWithName:info.managerName];
        image = info.provider(nestedManager, nestedManager.currentThemeIdentifier, nestedManager.currentTheme);
    }
    if (image) {
        return image;
    }
    static UIImage *emptyImage;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        emptyImage = [[[UIGraphicsImageRenderer alloc] initWithSize:CGSizeMake(1, 1)] imageWithActions:^(UIGraphicsImageRendererContext *context) {}];
    });
    return emptyImage;
}

static UIImage *CYLThemeImageMake(NSString *_Nullable name, NSObject<NSCopying> *managerName, CYLThemeImageProvider provider) {
    UIImage *resolvedImage = CYLThemeImageResolve(managerName, provider);
    // [EN] A new image object with the same content: the provider's image is often shared (`+imageNamed:` caches it) and
    //      must not carry the info. `-imageWithAlignmentRectInsets:` always returns a new object and keeps the image
    //      asset (Dark Mode variant), the rendering mode and the symbol configuration.
    // [CN] 内容相同的新图片对象：provider 返回的图片通常是共享的（`+imageNamed:` 会缓存），不能在其上保存信息。
    //      `-imageWithAlignmentRectInsets:` 总是返回新对象，并保留 image asset（深色模式变体）、渲染模式与 SF Symbol 配置。
    UIImage *image = [resolvedImage imageWithAlignmentRectInsets:resolvedImage.alignmentRectInsets];
    CYLThemeImageInfo *info = [[CYLThemeImageInfo alloc] init];
    info.name = name;
    info.managerName = managerName;
    info.provider = provider;
    objc_setAssociatedObject(image, &CYLThemeImageInfoKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return image;
}

UIImage *CYLThemeImageRefreshedImage(UIImage *image) {
    CYLThemeImageInfo *info = CYLThemeImageInfoOfImage(image);
    if (!info) {
        return image;
    }
    return CYLThemeImageMake(info.name, info.managerName, info.provider);
}

NSObject<NSCopying> *_Nullable CYLThemeImageManagerName(UIImage *image) {
    return CYLThemeImageInfoOfImage(image).managerName;
}

@implementation UIImage (CYLTheme)

+ (UIImage *)cyl_imageWithThemeProvider:(CYLThemeImageProvider)provider {
    return [self cyl_imageWithName:nil themeManagerName:CYLThemeManagerNameDefault provider:provider];
}

+ (UIImage *)cyl_imageWithName:(nullable NSString *)name themeProvider:(CYLThemeImageProvider)provider {
    return [self cyl_imageWithName:name themeManagerName:CYLThemeManagerNameDefault provider:provider];
}

+ (UIImage *)cyl_imageWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeImageProvider)provider {
    return [self cyl_imageWithName:nil themeManagerName:managerName provider:provider];
}

+ (UIImage *)cyl_imageWithName:(nullable NSString *)name themeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeImageProvider)provider {
    return CYLThemeImageMake(name, managerName ?: CYLThemeManagerNameDefault, provider);
}

- (BOOL)cyl_isThemeImage {
    return CYLThemeImageInfoOfImage(self) != nil;
}

- (nullable NSString *)cyl_themeImageName {
    return CYLThemeImageInfoOfImage(self).name;
}

- (UIImage *)cyl_rawImage {
    CYLThemeImageInfo *info = CYLThemeImageInfoOfImage(self);
    if (!info) {
        return self;
    }
    return CYLThemeImageResolve(info.managerName, info.provider);
}

@end

NS_ASSUME_NONNULL_END
