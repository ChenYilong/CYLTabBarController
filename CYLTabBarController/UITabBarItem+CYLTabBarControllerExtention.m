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

- (NSURL *)cyl_lottieURL {
    NSURL *lottieURL = objc_getAssociatedObject(self, @selector(cyl_lottieURL));
    return lottieURL;
}

- (void)cyl_setLottieURL:(NSURL *)lottieURL {
    NSURL *lottieURL_ = lottieURL;
    objc_setAssociatedObject(self, @selector(cyl_lottieURL), lottieURL_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSValue *)cyl_lottieSizeValue {
    NSValue *lottieSizeValue = objc_getAssociatedObject(self, @selector(cyl_lottieSizeValue));
    return lottieSizeValue;
}

- (void)cyl_setLottieSizeValue:(NSValue *)lottieSizeValue {
    NSValue *lottieSizeValue_ = lottieSizeValue;
    objc_setAssociatedObject(self, @selector(cyl_lottieSizeValue), lottieSizeValue_, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

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

