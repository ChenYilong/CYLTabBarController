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

/// [EN] The view whose trait collection resolves the colors of `layer`: its own view, or the nearest one above.
/// [CN] 用其 trait collection 解析 `layer` 颜色的视图：layer 自己的视图，或上层最近的视图。
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

- (void)cyl_setThemeColor:(nullable UIColor *)color forKeyPath:(NSString *)keyPath {
    NSMutableDictionary<NSString *, UIColor *> *colors = [self cyl_themeLayerColors];
    if (!color) {
        [colors removeObjectForKey:keyPath];
        [self setValue:nil forKeyPath:keyPath];
        return;
    }
    if (!colors) {
        colors = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &CYLThemeLayerColorsKey, colors, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    colors[keyPath] = color;
    [self cyl_applyThemeColor:color forKeyPath:keyPath];
}

- (nullable UIColor *)cyl_themeColorForKeyPath:(NSString *)keyPath {
    return [self cyl_themeLayerColors][keyPath];
}

/// [EN] Writes the `CGColor` of `color` for the current theme and traits. [CN] 写入 `color` 在当前主题与 trait 下的 `CGColor`。
- (void)cyl_applyThemeColor:(UIColor *)color forKeyPath:(NSString *)keyPath {
    UIColor *resolvedColor = color;
    if (@available(iOS 13.0, *)) {
        UIView *view = CYLThemeViewOfLayer(self);
        resolvedColor = [color resolvedColorWithTraitCollection:(view ? view.traitCollection : UITraitCollection.currentTraitCollection)];
    }
    [self setValue:(__bridge id)resolvedColor.CGColor forKeyPath:keyPath];
}

- (nullable UIColor *)cyl_themeBackgroundColor {
    return [self cyl_themeColorForKeyPath:@"backgroundColor"];
}

- (void)cyl_setThemeBackgroundColor:(nullable UIColor *)color {
    [self cyl_setThemeColor:color forKeyPath:@"backgroundColor"];
}

- (nullable UIColor *)cyl_themeBorderColor {
    return [self cyl_themeColorForKeyPath:@"borderColor"];
}

- (void)cyl_setThemeBorderColor:(nullable UIColor *)color {
    [self cyl_setThemeColor:color forKeyPath:@"borderColor"];
}

- (nullable UIColor *)cyl_themeShadowColor {
    return [self cyl_themeColorForKeyPath:@"shadowColor"];
}

- (void)cyl_setThemeShadowColor:(nullable UIColor *)color {
    [self cyl_setThemeColor:color forKeyPath:@"shadowColor"];
}

- (void)cyl_refreshThemeColors {
    // [EN] No implicit animation for a sublayer of its own. [CN] 独立的子 layer 不做隐式动画。
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self cyl_refreshThemeColorsOfLayerTree];
    [CATransaction commit];
}

- (void)cyl_refreshThemeColorsOfLayerTree {
    NSMutableDictionary<NSString *, UIColor *> *colors = [self cyl_themeLayerColors];
    for (NSString *keyPath in colors.allKeys) {
        // [EN] Before iOS 13 a theme color holds one value: take the one of the new theme.
        // [CN] iOS 13 以前主题颜色只有一个值：取新主题的值。
        UIColor *color = CYLThemeColorRefreshedColor(colors[keyPath]);
        colors[keyPath] = color;
        [self cyl_applyThemeColor:color forKeyPath:keyPath];
    }
    for (CALayer *sublayer in [self.sublayers copy]) {
        // [EN] The layer of a view is refreshed with that view. [CN] 视图的 layer 随视图刷新。
        if ([sublayer.delegate isKindOfClass:[UIView class]]) {
            continue;
        }
        [sublayer cyl_refreshThemeColorsOfLayerTree];
    }
}

@end

NS_ASSUME_NONNULL_END
