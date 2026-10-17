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
 * [EN] Returns a solid-color image of `size`; nil if `color` is nil or `size` is empty.
 * [CN] 生成指定尺寸的纯色图片；color 为 nil 或 size 为空时返回 nil。
 */
+ (UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size;

/*!
 * [EN] Returns a solid-color image of `size` with rounded corners.
 * [CN] 生成指定尺寸、带圆角的纯色图片。
 */
+ (UIImage *)cyl_imageWithColor:(UIColor *)color size:(CGSize)size cornerRadius:(CGFloat)cornerRadius;

/*!
 * [EN] Returns the image described by `imageInfo` (name or UIImage), or a placeholder image when it is nil.
 * [CN] 根据 imageInfo（图片名或 UIImage）返回图片；imageInfo 为 nil 时返回占位图。
 */
+ (UIImage *)cyl_imageNamed:(id)imageInfo;

/*!
 * [EN] Returns a UIImage from `imageInfo`: an NSString is loaded by name (always-original rendering), a UIImage is returned as is.
 * [CN] 根据 imageInfo 返回图片：NSString 按名称加载（始终原图渲染），UIImage 直接返回。
 */
+ (UIImage *)cyl_getImageFromImageInfo:(id)imageInfo;

/**
 *  tabItemPlaceholderImage
 *
 *  @return UIImage
 * [EN] Returns a 1×1 white placeholder image for tab items without an image.
 * [CN] 返回 1×1 的白色占位图，用于没有图片的 TabBarItem。
 */
+ (UIImage *)cyl_tabItemPlaceholderImage;

@end

NS_ASSUME_NONNULL_END
