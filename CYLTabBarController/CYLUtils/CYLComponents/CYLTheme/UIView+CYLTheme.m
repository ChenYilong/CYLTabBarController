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
        } else if (![value isKindOfClass:[UIImage class]] && ![value isKindOfClass:[UIVisualEffect class]]) {
            [self performSelector:setter withObject:value];
        }
#pragma clang diagnostic pop
    }];
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
