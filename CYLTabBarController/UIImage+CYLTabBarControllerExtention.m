//
//  UIImage+CYLTabBarControllerExtention.m
//  CYLTabBarController
//
//  Created by chenyilong on 18/4/2019.
//  Copyright © 2019 微博@iOS程序犭袁. All rights reserved.
//

#import "UIImage+CYLTabBarControllerExtention.h"

@implementation UIImage (CYLTabBarControllerExtention)

+ (UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size {
    if (!color || size.width <= 0 || size.height <= 0) return nil;
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
        //TODO: 如果Xcode10加入的asset，没有加入图片，那么image是nil，还是默认是light的值？我期望是获取的light的值，要不然xcode11编译后很多图片都不会显示啊！！！！！
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
        //TODO: self 有自定义traitCollection，那么 [UITraitCollection currentTraitCollection]获取到的是当前系统的，还是当前self的？我期望是self的，不然的话，那就太坑了。每次都要判断self和系统两个做取舍，那太坑了！！！！！
        UITraitCollection *traitCollection = owner.traitCollection ?: [UITraitCollection currentTraitCollection];
        UIUserInterfaceStyle userInterfaceStyle = traitCollection.userInterfaceStyle;
        isDarkImage = (userInterfaceStyle == UIUserInterfaceStyleDark);
#else
#endif
    }
#endif
    UIImage *image = (isDarkImage ? darkImage : lightImage);
    return image;
}

@end
