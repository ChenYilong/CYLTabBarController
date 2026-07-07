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

+ (UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size {
    if (!color || size.width <= 0 || size.height <= 0) { return nil; }
    CGRect rect = CGRectMake(0.0f, 0.0f, size.width, size.height);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillRect(context, rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

+ (UIImage *)cyl_assetImageName:(NSString *)assetImageName
             userInterfaceStyle:(NSInteger)userInterfaceStyle  {
    UIImage *image = [UIImage imageNamed:@"image"];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        UITraitCollection *trait;
        //        UIUserInterfaceStyle currentUserInterfaceStyle = [UITraitCollection currentTraitCollection].userInterfaceStyle;
        //        if (currentUserInterfaceStyle == UIUserInterfaceStyleUnspecified) {
        //            currentUserInterfaceStyle == userInterfaceStyle;
        //        }
        trait = [UITraitCollection traitCollectionWithUserInterfaceStyle:userInterfaceStyle];
        image = [image.imageAsset imageWithTraitCollection:trait];
        //TODO:
        return image;
#else
#endif
    }
#endif
    return image;
}

+ (UIImage *)cyl_lightOrDarkModeImageWithLightImage:(UIImage *)lightImage
                                          darkImage:(UIImage *)darkImage  {
    return [self cyl_lightOrDarkModeImageWithOwner:nil lightImage:lightImage darkImage:darkImage];
}

+ (UIImage *)cyl_lightOrDarkModeImageWithOwner:(id<UITraitEnvironment>)owner
                                lightImageName:(NSString *)lightImageName
                                 darkImageName:(NSString *)darkImageName {
    UIImage *lightImage = [UIImage imageNamed:lightImageName];
    UIImage *darkImage= [UIImage imageNamed:darkImageName];
    UIImage *lightOrDarkImage = [UIImage cyl_lightOrDarkModeImageWithOwner:owner lightImage:lightImage darkImage:darkImage];
    return lightOrDarkImage;
}

+ (UIImage *)cyl_lightOrDarkModeImageWithOwner:(id<UITraitEnvironment>)owner
                                    lightImage:(UIImage *)lightImage
                                     darkImage:(UIImage *)darkImage {
    BOOL isDarkImage = NO;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    if (@available(iOS 13.0, *)) {
#if __has_include(<UIKit/UIScene.h>)
        UITraitCollection *traitCollection = owner.traitCollection ?: CYLGetWindowScene().traitCollection ?: [UITraitCollection currentTraitCollection];
        UIUserInterfaceStyle userInterfaceStyle = traitCollection.userInterfaceStyle;
        isDarkImage = (userInterfaceStyle == UIUserInterfaceStyleDark);
#else
#endif
    }
#endif
    UIImage *image = (isDarkImage ? darkImage : lightImage);
    return image;
}

+ (UIImage *)cyl_getImageFromImageInfo:(id)imageInfo {
    UIImage *image = nil;
    if ([imageInfo isKindOfClass:[NSString class]]) {
        image = [UIImage imageNamed:imageInfo];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    } else if ([imageInfo isKindOfClass:[UIImage class]]) {
        image = (UIImage *)imageInfo;
    }
    return image;
}

+ (UIImage *)cyl_imageNamed:(id)imageInfo {
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
    CGSize placeholderSize = CGSizeMake(1, 1);
    UIImage *placeholderImage = [UIImage cyl_imageWithColor:[UIColor whiteColor] size:placeholderSize];
    return placeholderImage;
}

+ (UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius {
    color = color ? color : [UIColor clearColor];
    CGFloat a = 0;
    [color getRed:0 green:0 blue:0 alpha:&a];
    BOOL opaque = (cornerRadius == 0.0 && a == 1.0);
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
    UIGraphicsBeginImageContextWithOptions(size, opaque, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return nil;
    actionBlock(context);
    UIImage *imageOut = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageOut;
}

@end
