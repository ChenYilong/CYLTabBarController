//
//  UIColor+CYLTheme.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/04/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIColor+CYLTheme.h"
#import "CYLThemeManagerCenter.h"
#import "CYLThemePrivate.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 * [EN] What a theme color is made of, kept on the color: enough to make a fresh copy of it.
 * [CN] 主题颜色的组成，保存在颜色上：足以重新生成一个副本。
 */
@interface CYLThemeColorInfo : NSObject
@property (nonatomic, copy, nullable) NSString *name;
@property (nonatomic, copy) NSObject<NSCopying> *managerName;
@property (nonatomic, copy) CYLThemeColorProvider provider;
@end

@implementation CYLThemeColorInfo
@end

static char CYLThemeColorInfoKey;

static CYLThemeColorInfo *_Nullable CYLThemeColorInfoOfColor(UIColor *color) {
    return objc_getAssociatedObject(color, &CYLThemeColorInfoKey);
}

/*!
 * [EN] The color the provider returns for the current theme, with nested theme colors resolved (a few levels at most,
 *      so a provider returning its own color cannot loop forever).
 * [CN] provider 在当前主题下返回的颜色，嵌套的主题颜色也会被解析（最多几层，避免 provider 返回自身导致死循环）。
 */
static UIColor *CYLThemeColorResolve(NSObject<NSCopying> *managerName, CYLThemeColorProvider provider) {
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:managerName];
    UIColor *color = provider(manager, manager.currentThemeIdentifier, manager.currentTheme);
    for (NSUInteger depth = 0; depth < 8 && color; depth++) {
        CYLThemeColorInfo *info = CYLThemeColorInfoOfColor(color);
        if (!info) {
            break;
        }
        CYLThemeManager *nestedManager = [CYLThemeManagerCenter themeManagerWithName:info.managerName];
        color = info.provider(nestedManager, nestedManager.currentThemeIdentifier, nestedManager.currentTheme);
    }
    return color ?: [UIColor clearColor];
}

static UIColor *CYLThemeColorMake(NSString *_Nullable name, NSObject<NSCopying> *managerName, CYLThemeColorProvider provider) {
    UIColor *color = nil;
    if (@available(iOS 13.0, *)) {
        color = [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traitCollection) {
            // [EN] A system dynamic color returned by the provider follows the traits (Dark Mode).
            // [CN] provider 返回的系统动态颜色跟随 trait（深色模式）。
            return [CYLThemeColorResolve(managerName, provider) resolvedColorWithTraitCollection:traitCollection];
        }];
    } else {
        // [EN] No dynamic colors before iOS 13: a new color object (never a shared one such as `redColor`, which must not
        //      carry the info) with the value of the current theme.
        // [CN] iOS 13 以前没有动态颜色：使用当前主题的值创建一个新的颜色对象（不能是 `redColor` 这类共享对象，不能在其上保存信息）。
        color = [UIColor colorWithCGColor:CYLThemeColorResolve(managerName, provider).CGColor];
    }
    CYLThemeColorInfo *info = [[CYLThemeColorInfo alloc] init];
    info.name = name;
    info.managerName = managerName;
    info.provider = provider;
    objc_setAssociatedObject(color, &CYLThemeColorInfoKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return color;
}

UIColor *CYLThemeColorRefreshedColor(UIColor *color) {
    CYLThemeColorInfo *info = CYLThemeColorInfoOfColor(color);
    if (!info) {
        return color;
    }
    return CYLThemeColorMake(info.name, info.managerName, info.provider);
}

NSObject<NSCopying> *_Nullable CYLThemeColorManagerName(UIColor *color) {
    return CYLThemeColorInfoOfColor(color).managerName;
}

@implementation UIColor (CYLTheme)

+ (UIColor *)cyl_colorWithThemeProvider:(CYLThemeColorProvider)provider {
    return [self cyl_colorWithName:nil themeManagerName:CYLThemeManagerNameDefault provider:provider];
}

+ (UIColor *)cyl_colorWithName:(nullable NSString *)name themeProvider:(CYLThemeColorProvider)provider {
    return [self cyl_colorWithName:name themeManagerName:CYLThemeManagerNameDefault provider:provider];
}

+ (UIColor *)cyl_colorWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeColorProvider)provider {
    return [self cyl_colorWithName:nil themeManagerName:managerName provider:provider];
}

+ (UIColor *)cyl_colorWithName:(nullable NSString *)name themeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeColorProvider)provider {
    return CYLThemeColorMake(name, managerName ?: CYLThemeManagerNameDefault, provider);
}

- (BOOL)cyl_isThemeColor {
    return CYLThemeColorInfoOfColor(self) != nil;
}

- (nullable NSString *)cyl_themeColorName {
    return CYLThemeColorInfoOfColor(self).name;
}

- (UIColor *)cyl_rawColor {
    CYLThemeColorInfo *info = CYLThemeColorInfoOfColor(self);
    if (!info) {
        return self;
    }
    return CYLThemeColorResolve(info.managerName, info.provider);
}

@end

NS_ASSUME_NONNULL_END
