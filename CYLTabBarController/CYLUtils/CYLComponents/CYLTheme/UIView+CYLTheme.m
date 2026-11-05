//
//  UIView+CYLTheme.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIView+CYLTheme.h"
#import "UIColor+CYLTheme.h"
#import "UIImage+CYLTheme.h"
#import "UIVisualEffect+CYLTheme.h"
#import "CALayer+CYLTheme.h"
#import "CYLThemeManager.h"
#import "CYLThemePrivate.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/// [EN] YES when a theme value of the manager named `managerName` follows a change of `manager` (nil: any manager).
/// [CN] 名为 `managerName` 的管理器的主题值是否随 `manager` 的切换更新（`manager` 为 nil 表示任意管理器）。
static BOOL CYLThemeFollowsManager(NSObject<NSCopying> *_Nullable managerName, CYLThemeManager *_Nullable manager) {
    return managerName != nil && (!manager || [managerName isEqual:manager.name]);
}

/// [EN] `image` of the new theme when it is a theme image of `manager`, else nil. [CN] `image` 为 `manager` 的主题图片时返回新主题的图片，否则为 nil。
static UIImage *_Nullable CYLThemeRefreshedImageIfNeeded(UIImage *_Nullable image, CYLThemeManager *_Nullable manager) {
    return (image && CYLThemeFollowsManager(CYLThemeImageManagerName(image), manager)) ? CYLThemeImageRefreshedImage(image) : nil;
}

/*!
 * [EN] The theme images and effects UIKit views hold without registration: `UIImageView` (`image`, `highlightedImage`),
 *      `UIButton` (the images and background images of the states set with one, and its iOS 15 configuration), and
 *      `UIVisualEffectView` (`effect`).
 * [CN] UIKit 视图无需注册即会处理的主题图片与效果：`UIImageView`（`image`、`highlightedImage`）、`UIButton`（设置过图片的各状态的图片与
 *      背景图片，以及 iOS 15 的 configuration）、`UIVisualEffectView`（`effect`）。
 */
static void CYLThemeRefreshImagesAndEffects(UIView *view, CYLThemeManager *_Nullable manager) {
    if ([view isKindOfClass:[UIImageView class]]) {
        // [EN] A tab button's image view swaps its images itself; the tab bar is themed with `CYLTabBarTheme`.
        // [CN] Tab 按钮的图片视图自己切换图片；TabBar 使用 `CYLTabBarTheme` 换肤。
        if ([view isKindOfClass:NSClassFromString(@"UITabBarSwappableImageView")]) {
            return;
        }
        // [EN] A button's own image views are set by the button from its states, refreshed below.
        // [CN] 按钮自己的图片视图由按钮根据各状态设置，在下面刷新。
        if ([view.superview isKindOfClass:[UIButton class]]) {
            return;
        }
        UIImageView *imageView = (UIImageView *)view;
        UIImage *image = CYLThemeRefreshedImageIfNeeded(imageView.image, manager);
        if (image) {
            imageView.image = image;
        }
        UIImage *highlightedImage = CYLThemeRefreshedImageIfNeeded(imageView.highlightedImage, manager);
        if (highlightedImage) {
            imageView.highlightedImage = highlightedImage;
        }
        return;
    }
    if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        if (@available(iOS 15.0, *)) {
            UIButtonConfiguration *configuration = [button.configuration copy];
            if (configuration) {
                BOOL changed = NO;
                UIImage *image = CYLThemeRefreshedImageIfNeeded(configuration.image, manager);
                if (image) {
                    configuration.image = image;
                    changed = YES;
                }
                UIBackgroundConfiguration *background = configuration.background;
                UIImage *backgroundImage = CYLThemeRefreshedImageIfNeeded(background.image, manager);
                if (backgroundImage) {
                    background.image = backgroundImage;
                    configuration.background = background;
                    changed = YES;
                }
                if (changed) {
                    button.configuration = configuration;
                }
            }
        }
        // [EN] A state without an image of its own returns the normal one: only the states set with their own image.
        // [CN] 没有单独设置图片的状态会返回普通状态的图片：只处理单独设置过图片的状态。
        UIImage *normalImage = [button imageForState:UIControlStateNormal];
        UIImage *normalBackgroundImage = [button backgroundImageForState:UIControlStateNormal];
        for (NSNumber *stateValue in @[ @(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateSelected),
                                        @(UIControlStateDisabled), @(UIControlStateSelected | UIControlStateHighlighted) ]) {
            UIControlState state = stateValue.unsignedIntegerValue;
            UIImage *stateImage = [button imageForState:state];
            if (state == UIControlStateNormal || stateImage != normalImage) {
                UIImage *image = CYLThemeRefreshedImageIfNeeded(stateImage, manager);
                if (image) {
                    [button setImage:image forState:state];
                }
            }
            UIImage *stateBackgroundImage = [button backgroundImageForState:state];
            if (state == UIControlStateNormal || stateBackgroundImage != normalBackgroundImage) {
                UIImage *backgroundImage = CYLThemeRefreshedImageIfNeeded(stateBackgroundImage, manager);
                if (backgroundImage) {
                    [button setBackgroundImage:backgroundImage forState:state];
                }
            }
        }
        return;
    }
    if ([view isKindOfClass:[UIVisualEffectView class]]) {
        UIVisualEffectView *effectView = (UIVisualEffectView *)view;
        UIVisualEffect *effect = effectView.effect;
        if (effect && CYLThemeFollowsManager(CYLThemeVisualEffectManagerName(effect), manager)) {
            effectView.effect = CYLThemeVisualEffectRefreshedEffect(effect);
        }
    }
}

/// [EN] `backgroundColor` → `setBackgroundColor:`. [CN] `backgroundColor` → `setBackgroundColor:`。
static NSString *CYLThemeSetterNameForGetterName(NSString *getterName) {
    if (getterName.length == 0) {
        return getterName;
    }
    NSString *first = [[getterName substringToIndex:1] uppercaseString];
    return [NSString stringWithFormat:@"set%@%@:", first, [getterName substringFromIndex:1]];
}

@implementation UIView (CYLTheme)

- (void)cyl_registerThemeColorProperties:(NSArray<NSString *> *)getters {
    for (NSString *getterName in getters) {
        NSString *setterName = CYLThemeSetterNameForGetterName(getterName);
        if (![self respondsToSelector:NSSelectorFromString(getterName)] || ![self respondsToSelector:NSSelectorFromString(setterName)]) {
            NSLog(@"🔴 UIView (CYLTheme): %@ has no property %@ with the setter %@, it is not registered.", NSStringFromClass(self.class), getterName, setterName);
            continue;
        }
        if (!self.cyl_themeColorProperties) {
            self.cyl_themeColorProperties = [NSMutableDictionary dictionary];
        }
        self.cyl_themeColorProperties[getterName] = setterName;
    }
}

- (void)cyl_unregisterThemeColorProperties:(NSArray<NSString *> *)getters {
    [self.cyl_themeColorProperties removeObjectsForKeys:getters];
}

- (void)cyl_themeDidChangeByManager:(nullable CYLThemeManager *)manager identifier:(nullable __kindof NSObject<NSCopying> *)identifier theme:(nullable __kindof NSObject *)theme {
    [self.cyl_themeColorProperties enumerateKeysAndObjectsUsingBlock:^(NSString *getterName, NSString *setterName, BOOL *stop) {
        SEL getter = NSSelectorFromString(getterName);
        SEL setter = NSSelectorFromString(setterName);
        // [EN] A tab button's image view swaps between the normal and the selected image itself: setting its image again
        //      would show the normal image on a selected tab.
        // [CN] Tab 按钮的图片视图自己在普通图片与选中图片之间切换：重新设置其 image 会让选中的 Tab 显示普通图片。
        if (getter == @selector(image) && [self isKindOfClass:NSClassFromString(@"UITabBarSwappableImageView")]) {
            return;
        }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id value = [self performSelector:getter];
        if (!value) {
            return;
        }
        if ([value isKindOfClass:[UIColor class]]) {
            UIColor *color = (UIColor *)value;
            if (color.cyl_isThemeColor && (!manager || [CYLThemeColorManagerName(color) isEqual:manager.name])) {
                [self performSelector:setter withObject:CYLThemeColorRefreshedColor(color)];
            }
        } else if ([value isKindOfClass:[UIImage class]]) {
            // [EN] A theme image gets the image of the new theme; any other image is left alone.
            // [CN] 主题图片换成新主题的图片；其他图片不处理。
            if (CYLThemeFollowsManager(CYLThemeImageManagerName(value), manager)) {
                [self performSelector:setter withObject:CYLThemeImageRefreshedImage(value)];
            }
        } else if ([value isKindOfClass:[UIVisualEffect class]]) {
            if (CYLThemeFollowsManager(CYLThemeVisualEffectManagerName(value), manager)) {
                [self performSelector:setter withObject:CYLThemeVisualEffectRefreshedEffect(value)];
            }
        } else {
            [self performSelector:setter withObject:value];
        }
#pragma clang diagnostic pop
    }];
    if ([self isKindOfClass:[UILabel class]] || [self isKindOfClass:[UITextView class]]) {
        [self setNeedsDisplay];
    }
    CYLThemeRefreshBarAppearances(self);
    CYLThemeRefreshImagesAndEffects(self, manager);
    // [EN] Layer colors set with `-[CALayer cyl_setThemeColor:forKeyPath:]`, sublayers included.
    // [CN] 通过 `-[CALayer cyl_setThemeColor:forKeyPath:]` 设置的 layer 颜色，包括子 layer。
    [self.layer cyl_refreshThemeColors];
    if (self.cyl_themeDidChangeBlock) {
        self.cyl_themeDidChangeBlock();
    }
}

- (nullable void (^)(void))cyl_themeDidChangeBlock {
    return objc_getAssociatedObject(self, @selector(cyl_themeDidChangeBlock));
}

- (void)setCyl_themeDidChangeBlock:(nullable void (^)(void))themeDidChangeBlock {
    objc_setAssociatedObject(self, @selector(cyl_themeDidChangeBlock), themeDidChangeBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@implementation UIView (CYLThemePrivate)

- (nullable NSMutableDictionary<NSString *, NSString *> *)cyl_themeColorProperties {
    return objc_getAssociatedObject(self, @selector(cyl_themeColorProperties));
}

- (void)setCyl_themeColorProperties:(nullable NSMutableDictionary<NSString *, NSString *> *)themeColorProperties {
    objc_setAssociatedObject(self, @selector(cyl_themeColorProperties), themeColorProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cyl_themeDidChangeByManager:(nullable CYLThemeManager *)manager
                         identifier:(nullable __kindof NSObject<NSCopying> *)identifier
                              theme:(nullable __kindof NSObject *)theme
                 enumeratesSubviews:(BOOL)enumeratesSubviews {
    [self cyl_themeDidChangeByManager:manager identifier:identifier theme:theme];
    if (!enumeratesSubviews) {
        return;
    }
    // [EN] A copy: a view may add or remove subviews when the theme changes.
    // [CN] 使用副本：视图可能在主题切换时增删子视图。
    for (UIView *subview in [self.subviews copy]) {
        [subview cyl_themeDidChangeByManager:manager identifier:identifier theme:theme enumeratesSubviews:YES];
    }
}

@end

NS_ASSUME_NONNULL_END
