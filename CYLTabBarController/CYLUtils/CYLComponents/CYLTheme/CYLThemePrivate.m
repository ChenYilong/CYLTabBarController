//
//  CYLThemePrivate.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLThemePrivate.h"
#import "UIColor+CYLTheme.h"
#import "UIImage+CYLTheme.h"
#import "UIVisualEffect+CYLTheme.h"

NS_ASSUME_NONNULL_BEGIN

id _Nullable CYLThemeRefreshedValue(id _Nullable value, CYLThemeManager *_Nullable manager) {
    NSObject<NSCopying> *managerName = nil;
    if ([value isKindOfClass:[UIColor class]]) {
        managerName = CYLThemeColorManagerName(value);
        if (managerName && (!manager || [managerName isEqual:manager.name])) {
            return CYLThemeColorRefreshedColor(value);
        }
    } else if ([value isKindOfClass:[UIImage class]]) {
        managerName = CYLThemeImageManagerName(value);
        if (managerName && (!manager || [managerName isEqual:manager.name])) {
            return CYLThemeImageRefreshedImage(value);
        }
    } else if ([value isKindOfClass:[UIVisualEffect class]]) {
        managerName = CYLThemeEffectManagerName(value);
        if (managerName && (!manager || [managerName isEqual:manager.name])) {
            return CYLThemeEffectRefreshedEffect(value);
        }
    }
    return nil;
}

#pragma mark - Tracked views

static NSHashTable<UIView *> *CYLThemeTrackedViewTable(void) {
    static NSHashTable<UIView *> *table;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = [NSHashTable weakObjectsHashTable];
    });
    return table;
}

void CYLThemeTrackView(UIView *view) {
    if (view) {
        [CYLThemeTrackedViewTable() addObject:view];
    }
}

NSArray<UIView *> *CYLThemeTrackedViews(void) {
    return CYLThemeTrackedViewTable().allObjects;
}

#pragma mark - Theme change generation

static NSUInteger CYLThemeLastChangeGeneration = 0;
static NSUInteger CYLThemeChangeGenerationInProgress = 0;

NSUInteger CYLThemeCurrentChangeGeneration(void) {
    return CYLThemeChangeGenerationInProgress;
}

NSUInteger CYLThemeBeginChange(void) {
    CYLThemeChangeGenerationInProgress = ++CYLThemeLastChangeGeneration;
    return CYLThemeChangeGenerationInProgress;
}

void CYLThemeEndChange(void) {
    CYLThemeChangeGenerationInProgress = 0;
}

#pragma mark - Bars

/*!
 * [EN] A copy of `appearance` (a new object: the bar applies it again and resolves the theme colors in it) whose theme
 *      background effect, background image and shadow image are those of the current theme.
 * [CN] `appearance` 的副本（新对象：Bar 会重新应用它，并重新解析其中的主题颜色），其中的主题背景效果、背景图片与阴影图片替换为当前主题的值。
 */
static id _Nullable CYLThemeRefreshedBarAppearance(UIBarAppearance *_Nullable appearance) API_AVAILABLE(ios(13.0)) {
    if (!appearance) {
        return nil;
    }
    UIBarAppearance *copy = [appearance copy];
    UIVisualEffect *backgroundEffect = CYLThemeRefreshedValue(copy.backgroundEffect, nil);
    // [EN] `backgroundEffect` is typed `UIBlurEffect`; a theme effect made from a blur effect is one. [CN] `backgroundEffect` 的类型为 `UIBlurEffect`；由模糊效果生成的主题效果也是。
    if ([backgroundEffect isKindOfClass:[UIBlurEffect class]]) {
        copy.backgroundEffect = (UIBlurEffect *)backgroundEffect;
    }
    UIImage *backgroundImage = CYLThemeRefreshedValue(copy.backgroundImage, nil);
    if (backgroundImage) {
        copy.backgroundImage = backgroundImage;
    }
    UIImage *shadowImage = CYLThemeRefreshedValue(copy.shadowImage, nil);
    if (shadowImage) {
        copy.shadowImage = shadowImage;
    }
    return copy;
}

void CYLThemeRefreshBarAppearances(UIView *view) {
    if (@available(iOS 13.0, *)) {
        if ([view isKindOfClass:[UITabBar class]]) {
            UITabBar *tabBar = (UITabBar *)view;
            tabBar.standardAppearance = CYLThemeRefreshedBarAppearance(tabBar.standardAppearance);
            if (@available(iOS 15.0, *)) {
                if (tabBar.scrollEdgeAppearance) {
                    tabBar.scrollEdgeAppearance = CYLThemeRefreshedBarAppearance(tabBar.scrollEdgeAppearance);
                }
            }
        } else if ([view isKindOfClass:[UINavigationBar class]]) {
            UINavigationBar *navigationBar = (UINavigationBar *)view;
            navigationBar.standardAppearance = CYLThemeRefreshedBarAppearance(navigationBar.standardAppearance);
            if (navigationBar.scrollEdgeAppearance) {
                navigationBar.scrollEdgeAppearance = CYLThemeRefreshedBarAppearance(navigationBar.scrollEdgeAppearance);
            }
            if (navigationBar.compactAppearance) {
                navigationBar.compactAppearance = CYLThemeRefreshedBarAppearance(navigationBar.compactAppearance);
            }
        } else if ([view isKindOfClass:[UIToolbar class]]) {
            UIToolbar *toolbar = (UIToolbar *)view;
            toolbar.standardAppearance = CYLThemeRefreshedBarAppearance(toolbar.standardAppearance);
            if (toolbar.compactAppearance) {
                toolbar.compactAppearance = CYLThemeRefreshedBarAppearance(toolbar.compactAppearance);
            }
        }
    }
}

NS_ASSUME_NONNULL_END
