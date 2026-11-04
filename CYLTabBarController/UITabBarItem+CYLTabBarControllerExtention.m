//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"
#import "NSObject+CYLTabBarControllerExtention.h"
#import "UIView+CYLTabBarControllerExtention.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>

@implementation UITabBarItem (CYLTabBarControllerExtention)

static const void *CYLTabBarItemAnimationURLKey = &CYLTabBarItemAnimationURLKey;
static const void *CYLTabBarItemAnimationSizeValueKey = &CYLTabBarItemAnimationSizeValueKey;

- (NSURL *)cyl_tabBarItemAnimationURL {
    return objc_getAssociatedObject(self, CYLTabBarItemAnimationURLKey);
}

- (void)cyl_setTabBarItemAnimationURL:(NSURL *)URL {
    objc_setAssociatedObject(self, CYLTabBarItemAnimationURLKey, URL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSValue *)cyl_tabBarItemAnimationSizeValue {
    return objc_getAssociatedObject(self, CYLTabBarItemAnimationSizeValueKey);
}

- (void)cyl_setTabBarItemAnimationSizeValue:(NSValue *)sizeValue {
    objc_setAssociatedObject(self, CYLTabBarItemAnimationSizeValueKey, sizeValue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Deprecated Lottie names (compatibility) 已废弃的 Lottie 名称（兼容）

// [EN] Deprecated Lottie names kept for compatibility: implemented here, forwarding to the neutral API.
// [CN] 为兼容保留的已废弃 Lottie 名称：在此实现，并转发给通用 API。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (NSURL *)cyl_lottieURL {
    return self.cyl_tabBarItemAnimationURL;
}

- (void)cyl_setLottieURL:(NSURL *)lottieURL {
    self.cyl_tabBarItemAnimationURL = lottieURL;
}

- (NSValue *)cyl_lottieSizeValue {
    return self.cyl_tabBarItemAnimationSizeValue;
}

- (void)cyl_setLottieSizeValue:(NSValue *)lottieSizeValue {
    self.cyl_tabBarItemAnimationSizeValue = lottieSizeValue;
}

#pragma clang diagnostic pop

- (UIOffset)cyl_imagePositionAdjustment {
    NSValue *imagePositionAdjustmentObject = objc_getAssociatedObject(self, @selector(cyl_imagePositionAdjustment));
    return [imagePositionAdjustmentObject UIOffsetValue];
}

- (void)cyl_setImagePositionAdjustment:(UIOffset)imagePositionAdjustment {
    NSValue *imagePositionAdjustmentObject = @(imagePositionAdjustment);
    objc_setAssociatedObject(self, @selector(cyl_imagePositionAdjustment), imagePositionAdjustmentObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImageView *)cyl_imageView {
    return self.cyl_view.cyl_tabImageView;
}

- (UIImageView *)cyl_imageViewInTabBarButton {
    return [self.cyl_view cyl_tabImageView];
}

// [CN] 如果使用了液态玻璃，则返回 UITabBarPlatterView 中的 SelectedContentView 中的 subviews 中的 view
// [EN] If Liquid Glass is used, return the view among the subviews of SelectedContentView in UITabBarPlatterView
- (nullable UIControl *)cyl_selectedTabButton {
    if ([CYLConstants isLiquidGlassActive]) {
        if (![self isKindOfClass:UITabBarItem.class]) {
            return nil;
        }
        UIView *view = self.cyl_view;
        if (!view) {
            return nil;
        }
        NSInteger index = [view.superview.subviews indexOfObject:view];
        if (index == NSNotFound) {
            return nil;
        }
        UIView *platterView = self.cyl_tabBarController.tabBar.cyl_platterView;/*view.superview.superview;*/
        if (![platterView cyl_isPlatterView]) {
            return nil;
        }
        
        UIView *selectedContentView = platterView.subviews.firstObject;
        if (![selectedContentView cyl_isPlatterSelectedContentView]) {
            return nil;
        }
        if (index < selectedContentView.subviews.count) {
            UIControl *selectedView = [selectedContentView.subviews objectAtIndex:index];
            return selectedView;
        }
    }
    return nil;
}

- (UIControl *)cyl_visiableTabButton {
    if ([CYLConstants isLiquidGlassActive]) {
        return self.cyl_selectedTabButton;
    }
    return self.cyl_tabButton;
}

@end

