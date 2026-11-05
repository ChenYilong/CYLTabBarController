//
//  UIVisualEffect+CYLTheme.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/05/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIVisualEffect+CYLTheme.h"
#import "CYLThemeManagerCenter.h"
#import "CYLThemePrivate.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

/// [EN] What a theme effect is made of. [CN] 主题效果的组成。
@interface CYLThemeEffectInfo : NSObject
@property (nonatomic, copy) NSObject<NSCopying> *managerName;
@property (nonatomic, copy) CYLThemeEffectProvider provider;
@end

@implementation CYLThemeEffectInfo
@end

static char CYLThemeEffectInfoKey;

static CYLThemeEffectInfo *_Nullable CYLThemeEffectInfoOfEffect(UIVisualEffect *effect) {
    return objc_getAssociatedObject(effect, &CYLThemeEffectInfoKey);
}

/// [EN] The provider's effect for the current theme, a nested theme effect resolved. [CN] provider 在当前主题下的效果，嵌套的主题效果也会被解析。
static UIVisualEffect *CYLThemeEffectResolve(NSObject<NSCopying> *managerName, CYLThemeEffectProvider provider) {
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:managerName];
    UIVisualEffect *effect = provider(manager, manager.currentThemeIdentifier, manager.currentTheme);
    for (NSUInteger depth = 0; depth < 8 && effect; depth++) {
        CYLThemeEffectInfo *info = CYLThemeEffectInfoOfEffect(effect);
        if (!info) {
            break;
        }
        CYLThemeManager *nestedManager = [CYLThemeManagerCenter themeManagerWithName:info.managerName];
        effect = info.provider(nestedManager, nestedManager.currentThemeIdentifier, nestedManager.currentTheme);
    }
    return effect ?: [[UIVisualEffect alloc] init];
}

/*!
 * [EN] A new effect object equal to `effect`. `-copy` returns the receiver, so the effect is archived and unarchived
 *      (`UIVisualEffect` adopts `NSSecureCoding`); the provider's effect is often shared by a theme and must not carry the
 *      info.
 * [CN] 与 `effect` 相同的新效果对象。`-copy` 返回自身，因此通过归档再解档得到新对象（`UIVisualEffect` 遵守 `NSSecureCoding`）；
 *      provider 返回的效果通常被主题共享，不能在其上保存信息。
 */
static UIVisualEffect *CYLThemeEffectNewObject(UIVisualEffect *effect) {
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:effect requiringSecureCoding:YES error:&error];
    UIVisualEffect *copy = data ? [NSKeyedUnarchiver unarchivedObjectOfClass:[UIVisualEffect class] fromData:data error:&error] : nil;
    if (![copy isKindOfClass:[UIVisualEffect class]] || copy == effect) {
        // [EN] Only for an effect that cannot be archived: the effect itself is used (and carries the info), so it works.
        // [CN] 仅在效果无法归档时发生：直接使用该效果本身（信息保存在其上），保证其仍然可用。
        return effect;
    }
    return copy;
}

static UIVisualEffect *CYLThemeEffectMake(NSObject<NSCopying> *managerName, CYLThemeEffectProvider provider) {
    UIVisualEffect *effect = CYLThemeEffectNewObject(CYLThemeEffectResolve(managerName, provider));
    CYLThemeEffectInfo *info = [[CYLThemeEffectInfo alloc] init];
    info.managerName = managerName;
    info.provider = provider;
    objc_setAssociatedObject(effect, &CYLThemeEffectInfoKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return effect;
}

UIVisualEffect *CYLThemeEffectRefreshedEffect(UIVisualEffect *effect) {
    CYLThemeEffectInfo *info = CYLThemeEffectInfoOfEffect(effect);
    if (!info) {
        return effect;
    }
    return CYLThemeEffectMake(info.managerName, info.provider);
}

NSObject<NSCopying> *_Nullable CYLThemeEffectManagerName(UIVisualEffect *effect) {
    return CYLThemeEffectInfoOfEffect(effect).managerName;
}

@implementation UIVisualEffect (CYLTheme)

+ (UIVisualEffect *)cyl_effectWithThemeProvider:(CYLThemeEffectProvider)provider {
    return [self cyl_effectWithThemeManagerName:CYLThemeManagerNameDefault provider:provider];
}

+ (UIVisualEffect *)cyl_effectWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeEffectProvider)provider {
    return CYLThemeEffectMake(managerName ?: CYLThemeManagerNameDefault, provider);
}

- (BOOL)cyl_isThemeEffect {
    return CYLThemeEffectInfoOfEffect(self) != nil;
}

- (UIVisualEffect *)cyl_rawEffect {
    CYLThemeEffectInfo *info = CYLThemeEffectInfoOfEffect(self);
    if (!info) {
        return self;
    }
    return CYLThemeEffectResolve(info.managerName, info.provider);
}

@end

NS_ASSUME_NONNULL_END
