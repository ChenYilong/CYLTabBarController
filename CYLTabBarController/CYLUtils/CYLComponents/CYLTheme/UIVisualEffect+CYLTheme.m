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

/*!
 * [EN] What a theme effect is made of, kept on the effect: enough to make the effect of another theme.
 * [CN] 主题效果的组成，保存在效果上：足以生成其他主题下的效果。
 */
@interface CYLThemeVisualEffectInfo : NSObject
@property (nonatomic, copy) NSObject<NSCopying> *managerName;
@property (nonatomic, copy) CYLThemeVisualEffectProvider provider;
@end

@implementation CYLThemeVisualEffectInfo
@end

static char CYLThemeVisualEffectInfoKey;

static CYLThemeVisualEffectInfo *_Nullable CYLThemeVisualEffectInfoOfEffect(UIVisualEffect *effect) {
    return objc_getAssociatedObject(effect, &CYLThemeVisualEffectInfoKey);
}

/*!
 * [EN] A new effect object equal to `effect`, through `NSSecureCoding` (effects are immutable and may be shared, e.g. one
 *      per blur style, so the provider's object itself is never marked). nil when that is not possible.
 * [CN] 通过 `NSSecureCoding` 得到与 `effect` 相同的新效果对象（效果对象不可变，可能被共享，例如每种模糊样式一个，因此不会标记 provider
 *      返回的对象本身）。无法做到时为 nil。
 */
static UIVisualEffect *_Nullable CYLThemeVisualEffectDistinctCopy(UIVisualEffect *effect) {
    NSError *error = nil;
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:effect requiringSecureCoding:YES error:&error];
    if (!data) {
        return nil;
    }
    UIVisualEffect *copy = [NSKeyedUnarchiver unarchivedObjectOfClass:[effect class] fromData:data error:&error];
    return ([copy isKindOfClass:[UIVisualEffect class]] && copy != effect) ? copy : nil;
}

static UIVisualEffect *CYLThemeVisualEffectMake(NSObject<NSCopying> *managerName, CYLThemeVisualEffectProvider provider) {
    CYLThemeManager *manager = [CYLThemeManagerCenter themeManagerWithName:managerName];
    UIVisualEffect *providedEffect = provider(manager, manager.currentThemeIdentifier, manager.currentTheme);
    // [EN] A theme effect returned by the provider: its own effect of this theme. [CN] provider 返回主题效果时：使用其当前主题的效果。
    for (NSUInteger depth = 0; depth < 8 && providedEffect; depth++) {
        CYLThemeVisualEffectInfo *nestedInfo = CYLThemeVisualEffectInfoOfEffect(providedEffect);
        if (!nestedInfo) {
            break;
        }
        CYLThemeManager *nestedManager = [CYLThemeManagerCenter themeManagerWithName:nestedInfo.managerName];
        providedEffect = nestedInfo.provider(nestedManager, nestedManager.currentThemeIdentifier, nestedManager.currentTheme);
    }
    // [EN] No effect: a new empty `UIVisualEffect`, which shows nothing. [CN] 没有效果：新建空的 `UIVisualEffect`，不显示任何效果。
    UIVisualEffect *effect = providedEffect ? CYLThemeVisualEffectDistinctCopy(providedEffect) : [[UIVisualEffect alloc] init];
    if (!effect) {
        NSLog(@"🔴 UIVisualEffect (CYLTheme): could not copy %@; it will not follow the theme.", providedEffect);
        return providedEffect ?: [[UIVisualEffect alloc] init];
    }
    CYLThemeVisualEffectInfo *info = [[CYLThemeVisualEffectInfo alloc] init];
    info.managerName = managerName;
    info.provider = provider;
    objc_setAssociatedObject(effect, &CYLThemeVisualEffectInfoKey, info, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return effect;
}

UIVisualEffect *CYLThemeVisualEffectRefreshedEffect(UIVisualEffect *effect) {
    CYLThemeVisualEffectInfo *info = CYLThemeVisualEffectInfoOfEffect(effect);
    return info ? CYLThemeVisualEffectMake(info.managerName, info.provider) : effect;
}

NSObject<NSCopying> *_Nullable CYLThemeVisualEffectManagerName(UIVisualEffect *effect) {
    return CYLThemeVisualEffectInfoOfEffect(effect).managerName;
}

@implementation UIVisualEffect (CYLTheme)

+ (UIVisualEffect *)cyl_effectWithThemeProvider:(CYLThemeVisualEffectProvider)provider {
    return CYLThemeVisualEffectMake(CYLThemeManagerNameDefault, provider);
}

+ (UIVisualEffect *)cyl_effectWithThemeManagerName:(__kindof NSObject<NSCopying> *)managerName provider:(CYLThemeVisualEffectProvider)provider {
    return CYLThemeVisualEffectMake(managerName, provider);
}

- (BOOL)cyl_isThemeEffect {
    return CYLThemeVisualEffectInfoOfEffect(self) != nil;
}

- (UIVisualEffect *)cyl_effectForCurrentTheme {
    return CYLThemeVisualEffectRefreshedEffect(self);
}

@end

NS_ASSUME_NONNULL_END
