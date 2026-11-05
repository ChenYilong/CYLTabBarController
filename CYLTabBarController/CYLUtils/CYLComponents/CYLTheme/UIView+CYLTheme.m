//
//  UIView+CYLTheme.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIView+CYLTheme.h"
#import "UIColor+CYLTheme.h"
#import "CYLThemeManager.h"
#import "UIImage+CYLTheme.h"
#import "UIVisualEffect+CYLTheme.h"
#import "CALayer+CYLTheme.h"
#import "CYLThemePrivate.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/// [EN] `backgroundColor` → `setBackgroundColor:`. [CN] `backgroundColor` → `setBackgroundColor:`。
static NSString *CYLThemeSetterNameForGetterName(NSString *getterName) {
    if (getterName.length == 0) {
        return getterName;
    }
    NSString *first = [[getterName substringToIndex:1] uppercaseString];
    return [NSString stringWithFormat:@"set%@%@:", first, [getterName substringFromIndex:1]];
}

/*!
 * [EN] The button states whose images follow the theme. A state without its own image returns the normal one: such a
 *      state is skipped, so it keeps following the normal image.
 * [CN] 图片跟随主题的按钮状态。没有单独设置图片的状态返回 normal 状态的图片：跳过这类状态，使其继续跟随 normal 状态的图片。
 */
static const UIControlState CYLThemeButtonStates[] = {
    UIControlStateNormal, UIControlStateHighlighted, UIControlStateSelected, UIControlStateSelected | UIControlStateHighlighted, UIControlStateDisabled,
};

/*!
 * [EN] Replaces the theme images and effects that UIKit views hold (image views, buttons, effect views) by those of the
 *      new theme. Returns YES when the view holds any, so it is remembered for the next theme change.
 * [CN] 把 UIKit 视图（图片视图、按钮、效果视图）持有的主题图片与主题效果替换为新主题的值。视图持有这类值时返回 YES，以便下一次主题切换时记住它。
 */
static BOOL CYLThemeRefreshBuiltInValues(UIView *view, CYLThemeManager *_Nullable manager) {
    BOOL holdsThemeValues = NO;
    if ([view isKindOfClass:[UIImageView class]]) {
        UIImageView *imageView = (UIImageView *)view;
        // [EN] A tab button's image view swaps between the normal and the selected image itself (see below).
        // [CN] Tab 按钮的图片视图自己在普通图片与选中图片之间切换（见下文）。
        if (![imageView isKindOfClass:NSClassFromString(@"UITabBarSwappableImageView")]) {
            holdsThemeValues |= imageView.image.cyl_isThemeImage || imageView.highlightedImage.cyl_isThemeImage;
            UIImage *image = CYLThemeRefreshedValue(imageView.image, manager);
            if (image) {
                imageView.image = image;
            }
            UIImage *highlightedImage = CYLThemeRefreshedValue(imageView.highlightedImage, manager);
            if (highlightedImage) {
                imageView.highlightedImage = highlightedImage;
            }
        }
    } else if ([view isKindOfClass:[UIButton class]]) {
        UIButton *button = (UIButton *)view;
        UIImage *normalImage = [button imageForState:UIControlStateNormal];
        UIImage *normalBackgroundImage = [button backgroundImageForState:UIControlStateNormal];
        for (size_t index = 0; index < sizeof(CYLThemeButtonStates) / sizeof(CYLThemeButtonStates[0]); index++) {
            UIControlState state = CYLThemeButtonStates[index];
            UIImage *image = [button imageForState:state];
            if (state == UIControlStateNormal || image != normalImage) {
                holdsThemeValues |= image.cyl_isThemeImage;
                UIImage *refreshedImage = CYLThemeRefreshedValue(image, manager);
                if (refreshedImage) {
                    [button setImage:refreshedImage forState:state];
                }
            }
            UIImage *backgroundImage = [button backgroundImageForState:state];
            if (state == UIControlStateNormal || backgroundImage != normalBackgroundImage) {
                holdsThemeValues |= backgroundImage.cyl_isThemeImage;
                UIImage *refreshedBackgroundImage = CYLThemeRefreshedValue(backgroundImage, manager);
                if (refreshedBackgroundImage) {
                    [button setBackgroundImage:refreshedBackgroundImage forState:state];
                }
            }
        }
    } else if ([view isKindOfClass:[UIVisualEffectView class]]) {
        UIVisualEffectView *effectView = (UIVisualEffectView *)view;
        holdsThemeValues |= effectView.effect.cyl_isThemeEffect;
        UIVisualEffect *effect = CYLThemeRefreshedValue(effectView.effect, manager);
        if (effect) {
            effectView.effect = effect;
        }
    }
    return holdsThemeValues;
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
        // [EN] Reached by the next theme change even when it is not in a window. [CN] 即使不在 window 中，下一次主题切换也能到达。
        CYLThemeTrackView(self);
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
        // [EN] A theme color, image or effect gets the value of the new theme; plain colors, images and effects are left
        //      alone; any other object is set again as is.
        // [CN] 主题颜色、图片、效果得到新主题的值；普通颜色、图片与效果保持不变；其他对象原样重新设置。
        if ([value isKindOfClass:[UIColor class]] || [value isKindOfClass:[UIImage class]] || [value isKindOfClass:[UIVisualEffect class]]) {
            id refreshedValue = CYLThemeRefreshedValue(value, manager);
            if (refreshedValue) {
                [self performSelector:setter withObject:refreshedValue];
            }
        } else {
            [self performSelector:setter withObject:value];
        }
#pragma clang diagnostic pop
    }];
    if (CYLThemeRefreshBuiltInValues(self, manager)) {
        // [EN] Reached by the next theme change even when it is no longer in a window (e.g. a tab not selected).
        // [CN] 即使之后不在 window 中（例如未选中的 Tab），下一次主题切换也能到达。
        CYLThemeTrackView(self);
    }
    // [EN] Layer colors set with `-[CALayer cyl_setThemeColor:forKey:]`, on this view's layer and its own sublayers.
    // [CN] 通过 `-[CALayer cyl_setThemeColor:forKey:]` 设置的 layer 颜色：本视图的 layer 及其自身的 sublayer。
    [self.layer cyl_updateThemeColors];
    if ([self isKindOfClass:[UILabel class]] || [self isKindOfClass:[UITextView class]]) {
        [self setNeedsDisplay];
    }
    CYLThemeRefreshBarAppearances(self);
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

- (NSUInteger)cyl_themeChangeGeneration {
    return [objc_getAssociatedObject(self, @selector(cyl_themeChangeGeneration)) unsignedIntegerValue];
}

- (void)setCyl_themeChangeGeneration:(NSUInteger)themeChangeGeneration {
    objc_setAssociatedObject(self, @selector(cyl_themeChangeGeneration), @(themeChangeGeneration), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cyl_themeDidChangeByManager:(nullable CYLThemeManager *)manager
                         identifier:(nullable __kindof NSObject<NSCopying> *)identifier
                              theme:(nullable __kindof NSObject *)theme
                 enumeratesSubviews:(BOOL)enumeratesSubviews {
    // [EN] Once per theme change: a view can be reached from its window, its view controller and the tracked views.
    // [CN] 每次主题切换只处理一次：视图可能从 window、控制器以及记住的视图多处到达。
    NSUInteger generation = CYLThemeCurrentChangeGeneration();
    if (generation != 0) {
        if (self.cyl_themeChangeGeneration == generation) {
            return;
        }
        self.cyl_themeChangeGeneration = generation;
    }
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
