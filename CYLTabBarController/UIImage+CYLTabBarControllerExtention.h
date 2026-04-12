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

+ (UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size;

+ (UIImage *)cyl_imageNamed:(id)imageInfo;

+ (UIImage *)cyl_getImageFromImageInfo:(id)imageInfo;

/**
 *  tabItemPlaceholderImage
 *
 *  @return UIImage
 */
+ (UIImage *)cyl_tabItemPlaceholderImage;

@end

NS_ASSUME_NONNULL_END
