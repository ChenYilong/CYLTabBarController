//
//  CALayer+CYLTheme.m
//  CYLUtils
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/05/26.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CALayer+CYLTheme.h"
#import "CYLThemePrivate.h"
#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

static char CYLThemeLayerColorsKey;
static char CYLThemeTraitRegistrationKey;

/// [EN] The view whose layer is `layer` or contains it. [CN] layer 所属（或包含它）的视图。
static UIView *_Nullable CYLThemeViewOfLayer(CALayer *layer) {
    for (CALayer *current = layer; current; current = current.superlayer) {
        if ([current.delegate isKindOfClass:[UIView class]]) {
            return (UIView *)current.delegate;
        }
    }
    return nil;
}

@implementation CALayer (CYLTheme)

- (nullable NSMutableDictionary<NSString *, UIColor *> *)cyl_themeLayerColors {
    return objc_getAssociatedObject(self, &CYLThemeLayerColorsKey);
}

- (void)cyl_setThemeColor:(nullable UIColor *)color forKey:(NSString *)key {
    if (key.length == 0) {
        return;
    }
    NSMutableDictionary<NSString *, UIColor *> *colors = [self cyl_themeLayerColors];
    if (!color) {
        [colors removeObjectForKey:key];
        [self setValue:nil forKey:key];
        return;
    }
    if (!colors) {
        colors = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &CYLThemeLayerColorsKey, colors, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    colors[key] = color;
    [self cyl_applyThemeColor:color forKey:key];
    UIView *view = CYLThemeViewOfLayer(self);
    if (view) {
        CYLThemeTrackView(view);
        [self cyl_followTraitChangesOfView:view];
    }
}

- (nullable UIColor *)cyl_themeColorForKey:(NSString *)key {
    return [self cyl_themeLayerColors][key];
}

- (void)cyl_applyThemeColor:(UIColor *)color forKey:(NSString *)key {
    UIColor *resolvedColor = color;
    if (@available(iOS 13.0, *)) {
        // [EN] The traits of the view the layer is in, not the current ones (which may be another window's).
        // [CN] 使用 layer 所在视图的 trait，而不是当前 trait（可能属于其他 window）。
        UITraitCollection *traitCollection = CYLThemeViewOfLayer(self).traitCollection ?: UITraitCollection.currentTraitCollection;
        resolvedColor = [color resolvedColorWithTraitCollection:traitCollection];
    }
    [self setValue:(__bridge id)resolvedColor.CGColor forKey:key];
}

/*!
 * [EN] iOS 17+: set the colors again when the Dark Mode of `view` changes. Once per layer.
 * [CN] iOS 17+：`view` 的深色模式变化时重新设置颜色。每个 layer 只注册一次。
 */
- (void)cyl_followTraitChangesOfView:(UIView *)view {
    if (@available(iOS 17.0, *)) {
        if (objc_getAssociatedObject(self, &CYLThemeTraitRegistrationKey)) {
            return;
        }
        __weak CALayer *weakLayer = self;
        id<UITraitChangeRegistration> registration = [view registerForTraitChanges:@[ UITraitUserInterfaceStyle.class ]
                                                                       withHandler:^(__kindof id<UITraitEnvironment> traitEnvironment, UITraitCollection *previousTraitCollection) {
            [weakLayer cyl_updateThemeColors];
        }];
        objc_setAssociatedObject(self, &CYLThemeTraitRegistrationKey, registration, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)cyl_updateThemeColors {
    [[[self cyl_themeLayerColors] copy] enumerateKeysAndObjectsUsingBlock:^(NSString *key, UIColor *color, BOOL *stop) {
        [self cyl_applyThemeColor:color forKey:key];
    }];
    // [EN] The layer of a subview is updated by its own view. [CN] 子视图的 layer 由该子视图自己更新。
    for (CALayer *sublayer in [self.sublayers copy]) {
        if (![sublayer.delegate isKindOfClass:[UIView class]]) {
            [sublayer cyl_updateThemeColors];
        }
    }
}

- (nullable UIColor *)cyl_themeBackgroundColor {
    return [self cyl_themeColorForKey:@"backgroundColor"];
}

- (void)cyl_setThemeBackgroundColor:(nullable UIColor *)color {
    [self cyl_setThemeColor:color forKey:@"backgroundColor"];
}

- (nullable UIColor *)cyl_themeBorderColor {
    return [self cyl_themeColorForKey:@"borderColor"];
}

- (void)cyl_setThemeBorderColor:(nullable UIColor *)color {
    [self cyl_setThemeColor:color forKey:@"borderColor"];
}

- (nullable UIColor *)cyl_themeShadowColor {
    return [self cyl_themeColorForKey:@"shadowColor"];
}

- (void)cyl_setThemeShadowColor:(nullable UIColor *)color {
    [self cyl_setThemeColor:color forKey:@"shadowColor"];
}

@end

NS_ASSUME_NONNULL_END
