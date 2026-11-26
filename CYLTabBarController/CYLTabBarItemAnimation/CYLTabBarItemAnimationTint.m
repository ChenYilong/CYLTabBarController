//
//  CYLTabBarItemAnimationTint.m
//  CYLAnimatedItem
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//
//  [EN] The template tint of an animation view for every animation library, part of the CYLAnimatedItem component (Engine): CYLAnimatedItemView
//       calls it with its `animationTint` / `animationDarkTint`, and the tab bar's animation flow calls it with the options of a tab's
//       animation URL, so the tab bar gets its tint from the component and not the other way round.
//  [CN] 所有动画库的动画视图模板着色，属于 CYLAnimatedItem 组件（Engine）：CYLAnimatedItemView 以 `animationTint` / `animationDarkTint` 调用它，
//       TabBar 的动画流程以 Tab 动画 URL 的选项调用它，因此 TabBar 从组件获得着色，而不是反过来。
//

#import "CYLTabBarItemAnimationTint.h"
#if __has_include("../CYLUtils/CYLAnimationKeys.h")
#import "../CYLUtils/CYLAnimationKeys.h"
#else
#import "CYLAnimationKeys.h"
#endif
#import "CYLTabBarItemAnimationPlayer.h"
#import <objc/runtime.h>

#pragma mark - Template tint for every library 所有动画库的模板着色

/*
 * [EN] The `tint` / `darkTint` options (`CYLTabBarAnimationOptionTint`, `CYLTabBarAnimationOptionDarkTint`) for the
 *      libraries that do not read them in their own view (Lottie, PAG, SVGA, GIF; Rive does), each through its official
 *      means when it has one: GIF frames become template images drawn in the view's `tintColor` (UIKit); Lottie 4.x takes
 *      a `ColorValueProvider` on the keypath "**.Color" (its player's `-applyColors:traitCollection:`); a library without
 *      a tint API (PAG, SVGA, Lottie 2.x) gets a layer of that color composited "sourceAtop" over its view, so only the
 *      icon's pixels take it. "title" follows the color the tab bar (or CYLAnimatedItemView's `iconColor`) passes to
 *      `-cyl_applyAnimationViewTintColor:`; "#RRGGBB(AA)" is fixed, with `darkTint` in Dark Mode. The method is added to the
 *      view's class at run time when it lacks one, so no library header is imported; it does nothing on a view without
 *      these options.
 * [CN] 为不在自身视图中读取 `tint` / `darkTint` 选项的动画库（Lottie、PAG、SVGA、GIF；Rive 自己读取）提供着色，有官方方式时使用官方方式：GIF 帧变为
 *      模板图片，以视图的 `tintColor` 绘制（UIKit）；Lottie 4.x 在 keypath "**.Color" 上使用 `ColorValueProvider`（其播放器的
 *      `-applyColors:traitCollection:`）；没有着色 API 的动画库（PAG、SVGA、Lottie 2.x）在视图上方叠加一层该颜色并以 "sourceAtop" 合成，只有图标的像素
 *      取该颜色。"title" 跟随 TabBar（或 CYLAnimatedItemView 的 `iconColor`）传给 `-cyl_applyAnimationViewTintColor:` 的颜色；"#RRGGBB(AA)" 为固定颜色，
 *      深色模式下使用 `darkTint`。视图类没有该方法时在运行时添加，因此不导入任何动画库的头文件；没有这些选项的视图不做任何事。
 */
static const void *CYLTabBarItemAnimationTintOptionsKey = &CYLTabBarItemAnimationTintOptionsKey;
/// [EN] Set by a `CYLAnimatedItemView`: the color it hands over is final (already resolved with its own traits), so the view draws it as is. [CN] 由 `CYLAnimatedItemView` 设置：它交来的颜色是最终颜色（已按自身 trait 解析），视图原样绘制。
static const void *CYLTabBarItemAnimationTintFinalKey = &CYLTabBarItemAnimationTintFinalKey;
static const void *CYLTabBarItemAnimationTintPlayerKey = &CYLTabBarItemAnimationTintPlayerKey;
static const void *CYLTabBarItemAnimationTintOverlayKey = &CYLTabBarItemAnimationTintOverlayKey;
static const void *CYLTabBarItemAnimationTintOriginalFramesKey = &CYLTabBarItemAnimationTintOriginalFramesKey;

/// [EN] The options in a URL's fragment ("name=value&…", percent-encoded). [CN] URL fragment 中的选项（「名称=值&…」，百分号编码）。
static NSDictionary<NSString *, NSString *> *CYLTabBarItemAnimationTintOptionsFromURL(NSURL *URL) {
    NSMutableDictionary<NSString *, NSString *> *options = [NSMutableDictionary dictionary];
    // [EN] Keys and values are strings (CYLAnimationKeys.h). [CN] 键与值都是字符串（CYLAnimationKeys.h）。
    NSDictionary<NSString *, NSString *> *parsed = CYLTabBarAnimationOptionsFromURL(URL);
    [parsed enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSString *value, BOOL *stop) {
        NSString *trimmed = [value stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (trimmed.length > 0) {
            options[name] = trimmed;
        }
    }];
    return [options copy];
}

/// [EN] "#RRGGBB" or "#RRGGBBAA" ("#" optional), else nil. [CN] "#RRGGBB" 或 "#RRGGBBAA"（"#" 可省略），否则为 nil。
static UIColor *CYLTabBarItemAnimationTintColorFromHex(NSString *hex) {
    // [EN] The same rule on every platform: a "#" and exactly 6 (RRGGBB) or 8 (RRGGBBAA) hex digits. [CN] 各平台相同的规则：必须有 "#"，且恰好 6 位（RRGGBB）或 8 位（RRGGBBAA）十六进制。
    if (![hex hasPrefix:@"#"]) {
        return nil;
    }
    NSString *digits = [hex substringFromIndex:1];
    if (digits.length != 6 && digits.length != 8) {
        return nil;
    }
    unsigned long long value = 0;
    NSScanner *scanner = [NSScanner scannerWithString:digits];
    if (![scanner scanHexLongLong:&value] || !scanner.isAtEnd) {
        return nil;
    }
    if (digits.length == 6) {
        value = (value << 8) | 0xFF;
    }
    return [UIColor colorWithRed:((value >> 24) & 0xFF) / 255.0 green:((value >> 16) & 0xFF) / 255.0
                            blue:((value >> 8) & 0xFF) / 255.0 alpha:(value & 0xFF) / 255.0];
}

/// [EN] The fixed tint (`tint` "#…", with `darkTint` in Dark Mode), nil for "title" or none. [CN] 固定着色（`tint` "#…"，深色模式用 `darkTint`）；"title" 或未设置时为 nil。
static UIColor *CYLTabBarItemAnimationFixedTintColor(NSDictionary<NSString *, NSString *> *options) {
    NSString *tint = options[@"tint"];
    UIColor *light = [tint isEqualToString:@"title"] ? nil : CYLTabBarItemAnimationTintColorFromHex(tint);
    if (!light) {
        return nil;
    }
    UIColor *dark = CYLTabBarItemAnimationTintColorFromHex(options[@"darkTint"]);
    if (!dark) {
        return light;
    }
    return [UIColor colorWithDynamicProvider:^UIColor *(UITraitCollection *traits) {
        return traits.userInterfaceStyle == UIUserInterfaceStyleDark ? dark : light;
    }];
}

CYLTabBarItemAnimationRenderingMode CYLTabBarItemAnimationRenderingModeFromString(NSString *text, CYLTabBarItemAnimationRenderingMode fallback) {
    NSString *trimmed = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if (trimmed.length == 0) {
        return fallback;
    }
    if ([trimmed caseInsensitiveCompare:@"automatic"] == NSOrderedSame) {
        return CYLTabBarItemAnimationRenderingModeAutomatic;
    }
    if ([trimmed caseInsensitiveCompare:@"alwaysTemplate"] == NSOrderedSame) {
        return CYLTabBarItemAnimationRenderingModeAlwaysTemplate;
    }
    if ([trimmed caseInsensitiveCompare:@"alwaysOriginal"] == NSOrderedSame) {
        return CYLTabBarItemAnimationRenderingModeAlwaysOriginal;
    }
    return fallback;
}

static const void *CYLTabBarItemAnimationTabFlowModeKey = &CYLTabBarItemAnimationTabFlowModeKey;

CYLTabBarItemAnimationRenderingMode CYLTabBarItemAnimationTabFlowRenderingMode(UIView *view) {
    NSNumber *mode = view ? objc_getAssociatedObject(view, CYLTabBarItemAnimationTabFlowModeKey) : nil;
    return mode ? (CYLTabBarItemAnimationRenderingMode)mode.integerValue : CYLTabBarItemAnimationRenderingModeAutomatic;
}

UIColor *CYLTabBarItemAnimationResolveTint(NSString *tint, NSString *darkTint, BOOL selected, BOOL isDark,
                                           UIColor *effectiveIconColor, UIColor *explicitSelectedIconColor) {
    NSString *kind = [tint stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    if ([kind isEqualToString:@"title"]) {
        return effectiveIconColor;
    }
    UIColor *fixed = CYLTabBarItemAnimationTintColorFromHex(kind);
    if (!fixed) {
        return nil;
    }
    // [EN] A fixed color: the selected item yields ONLY to an EXPLICIT selected icon color (never a built-in or subclass one: the table, the same on every platform). [CN] 固定颜色：选中的条目只让位于显式的选中图标颜色（绝不是内置或子类的颜色：真值表，各平台相同）。
    if (selected && explicitSelectedIconColor) {
        return explicitSelectedIconColor;
    }
    UIColor *dark = isDark ? CYLTabBarItemAnimationTintColorFromHex([darkTint stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet]) : nil;
    return dark ?: fixed;
}

/// [EN] Whether the text is a usable tint: "title" or a valid hex. [CN] 文本是否为可用的着色："title" 或有效的十六进制。
static BOOL CYLTabBarItemAnimationTintIsSet(NSString *tint) {
    NSString *kind = [tint stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    return [kind isEqualToString:@"title"] || CYLTabBarItemAnimationTintColorFromHex(kind) != nil;
}

UIColor *CYLTabBarItemAnimationResolveTintWithRenderingMode(NSString *tint, NSString *darkTint, CYLTabBarItemAnimationRenderingMode mode,
                                                            CYLTabBarItemAnimationColorKind colorKind, BOOL selected, BOOL isDark,
                                                            UIColor *effectiveIconColor, UIColor *explicitSelectedIconColor) {
    if (CYLTabBarItemAnimationTintIsSet(tint)) {
        return CYLTabBarItemAnimationResolveTint(tint, darkTint, selected, isDark, effectiveIconColor, explicitSelectedIconColor);
    }
    switch (mode) {
        case CYLTabBarItemAnimationRenderingModeAlwaysTemplate:
            return effectiveIconColor;
        case CYLTabBarItemAnimationRenderingModeAlwaysOriginal:
            return nil;
        case CYLTabBarItemAnimationRenderingModeAutomatic:
        default:
            return colorKind == CYLTabBarItemAnimationColorKindOneColor ? effectiveIconColor : nil;
    }
}

UIColor *CYLTabBarItemAnimationItemTintColor(NSURL *sourceURL, NSString *tintOverride, NSString *darkTintOverride,
                                             CYLTabBarItemAnimationRenderingMode modeOverride,
                                             BOOL selected, BOOL isDark, UIColor *effectiveIconColor, UIColor *explicitSelectedIconColor) {
    NSDictionary<NSString *, NSString *> *options = sourceURL ? CYLTabBarItemAnimationTintOptionsFromURL(sourceURL) : @{};
    NSString *tint = [tintOverride stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSString *darkTint = [darkTintOverride stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
    NSString *resolvedTint = tint.length > 0 ? tint : options[@"tint"];
    CYLTabBarItemAnimationRenderingMode mode = modeOverride != CYLTabBarItemAnimationRenderingModeAutomatic
        ? modeOverride : CYLTabBarItemAnimationRenderingModeFromString(options[@"renderingMode"], CYLTabBarItemAnimationRenderingModeAutomatic);
    CYLTabBarItemAnimationColorKind kind = CYLTabBarItemAnimationColorKindUndetectable;
    if (!CYLTabBarItemAnimationTintIsSet(resolvedTint) && mode == CYLTabBarItemAnimationRenderingModeAutomatic) {
        kind = CYLTabBarItemAnimationColorKindOfURL(sourceURL);
    }
    return CYLTabBarItemAnimationResolveTintWithRenderingMode(resolvedTint, darkTint.length > 0 ? darkTint : options[@"darkTint"], mode, kind,
                                                              selected, isDark, effectiveIconColor, explicitSelectedIconColor);
}

/// [EN] Draws `color` (nil: no tint) over the view by its library's means. [CN] 用动画库的方式在视图上绘制 `color`（nil 表示不着色）。
/*!
 * [EN] Puts the tint overlay right above the library's own layers and below the view's subviews (a badge stays above it):
 *      libraries add their content layers after the overlay is made (Lottie when its composition is set up, SVGA on each
 *      draw), which hid it.
 * [CN] 把着色叠加图层放在动画库自身图层的正上方、视图子视图之下（角标仍在其上方）：动画库在叠加图层创建之后才添加其内容图层（Lottie 在设置 composition 时，
 *      SVGA 在每次绘制时），曾把它遮住。
 */
static void CYLTabBarItemAnimationRaiseTintOverlay(CALayer *hostLayer, CALayer *overlay) {
    if (!overlay || overlay.superlayer != hostLayer) {
        return;
    }
    CALayer *firstSubviewLayer = nil;
    for (CALayer *layer in hostLayer.sublayers) {
        if (layer != overlay && [layer.delegate isKindOfClass:[UIView class]]) {
            firstSubviewLayer = layer;
            break;
        }
    }
    NSArray<CALayer *> *sublayers = hostLayer.sublayers;
    NSUInteger index = [sublayers indexOfObjectIdenticalTo:overlay];
    if (firstSubviewLayer) {
        NSUInteger subviewIndex = [sublayers indexOfObjectIdenticalTo:firstSubviewLayer];
        if (index + 1 != subviewIndex) {
            [hostLayer insertSublayer:overlay below:firstSubviewLayer];
        }
    } else if (index != sublayers.count - 1) {
        [hostLayer addSublayer:overlay];
    }
}

/*!
 * [EN] Keeps the tint overlay the size of its view's layer: the overlay is made when the view is still 0 x 0 (a fixed tint
 *      is applied as the view is created) and most libraries' views (Lottie, PAG) never size their sublayers. Holds the
 *      layer, so the observation is removed before the layer goes.
 * [CN] 让着色叠加图层保持与其视图图层同尺寸：叠加图层在视图仍为 0 x 0 时创建（固定着色在创建视图时应用），而多数动画库的视图（Lottie、PAG）不会调整其子图层尺寸。
 *      持有该图层，使观察在图层释放之前移除。
 */
@interface CYLTabBarItemAnimationTintOverlaySizer : NSObject
@property (nonatomic, strong) CALayer *hostLayer;
@property (nonatomic, weak) CALayer *overlay;
@end

@implementation CYLTabBarItemAnimationTintOverlaySizer

static void *CYLTabBarItemAnimationTintOverlaySizerContext = &CYLTabBarItemAnimationTintOverlaySizerContext;

- (instancetype)initWithHostLayer:(CALayer *)hostLayer overlay:(CALayer *)overlay {
    if (self = [super init]) {
        _hostLayer = hostLayer;
        _overlay = overlay;
        [hostLayer addObserver:self forKeyPath:@"bounds" options:0 context:CYLTabBarItemAnimationTintOverlaySizerContext];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != CYLTabBarItemAnimationTintOverlaySizerContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.overlay.frame = self.hostLayer.bounds;
    CYLTabBarItemAnimationRaiseTintOverlay(self.hostLayer, self.overlay);
    [CATransaction commit];
}

- (void)dealloc {
    [_hostLayer removeObserver:self forKeyPath:@"bounds" context:CYLTabBarItemAnimationTintOverlaySizerContext];
}

@end

static const void *CYLTabBarItemAnimationTintOverlaySizerKey = &CYLTabBarItemAnimationTintOverlaySizerKey;

static void CYLTabBarItemAnimationApplyTint(UIView *view, UIColor *color) {
    UIColor *resolved = [color resolvedColorWithTraitCollection:view.traitCollection];
    // [EN] A view with a KVC-readable `frames` array of template-able images in the view's tint color (UIKit's own tint). NOTE: the shipped GIF view does NOT take this branch:
    //      its `frames` is a `private var` (not `@objc`), so `respondsToSelector:` is NO, and it plays by a keyframe animation of the layer's `contents` (CGImages, which
    //      ignore the rendering mode). The GIF therefore takes the overlay path below, exactly like PAG and SVGA (engine-uniform, one policy); do not "fix" this branch
    //      for GIF, it would change the GIF colors.
    // [CN] 带有可 KVC 读取的 `frames` 图片数组的视图：模板帧以视图 tint 颜色绘制（UIKit 自身的着色）。注意：现有的 GIF 视图不会进入此分支：
    //      其 `frames` 是 `private var`（非 `@objc`），`respondsToSelector:` 为 NO，且它通过 layer `contents` 的关键帧动画播放（CGImage，忽略渲染模式）。
    //      因此 GIF 与 PAG、SVGA 一样走下面的叠加层路径（各引擎统一，一个策略）；不要为 GIF「修复」此分支，否则会改变 GIF 的颜色。
    if ([view isKindOfClass:[UIImageView class]] && [view respondsToSelector:NSSelectorFromString(@"frames")]) {
        UIImageView *imageView = (UIImageView *)view;
        NSArray<UIImage *> *original = objc_getAssociatedObject(view, CYLTabBarItemAnimationTintOriginalFramesKey) ?: [view valueForKey:@"frames"];
        objc_setAssociatedObject(view, CYLTabBarItemAnimationTintOriginalFramesKey, original, OBJC_ASSOCIATION_COPY_NONATOMIC);
        UIImageRenderingMode mode = resolved ? UIImageRenderingModeAlwaysTemplate : UIImageRenderingModeAutomatic;
        NSMutableArray<UIImage *> *frames = [NSMutableArray arrayWithCapacity:original.count];
        for (UIImage *frame in original) {
            [frames addObject:[frame imageWithRenderingMode:mode]];
        }
        NSUInteger shown = imageView.image ? [[view valueForKey:@"frames"] indexOfObjectIdenticalTo:imageView.image] : NSNotFound;
        [view setValue:frames forKey:@"frames"];
        imageView.image = (shown != NSNotFound && shown < frames.count) ? frames[shown] : frames.firstObject;
        imageView.tintColor = resolved;
        return;
    }
    // [EN] Lottie 4.x: a color value provider on every color. [CN] Lottie 4.x：作用于所有颜色的 color value provider。
    id<CYLTabBarItemAnimationPlayer> player = objc_getAssociatedObject(view, CYLTabBarItemAnimationTintPlayerKey);
    // [EN] A CYL playable view (SVGA, GIF) has a generic player that answers `-applyColors:…` for any view: colors work only
    //      when the view itself takes them. [CN] CYL 的可播放视图（SVGA、GIF）使用通用播放器，它对任何视图都响应 `-applyColors:…`：只有视图本身接受颜色时才有效。
    BOOL takesColors = [player respondsToSelector:@selector(applyColors:traitCollection:)]
        && (![view conformsToProtocol:NSProtocolFromString(@"CYLTabBarItemAnimationPlayableView")]
            || [view respondsToSelector:NSSelectorFromString(@"cyl_applyAnimationViewColors:")]);
    if (takesColors) {
        [player applyColors:(resolved ? @{ @"**.Color" : resolved } : nil) traitCollection:view.traitCollection];
        return;
    }
    // [EN] No tint API: a layer composited "sourceAtop" over the library's view (a plain layer: inside the Liquid Glass bar a
    //      view's layer was not composited), sized again on every tint pass and by the view's layout when it has one (the
    //      SVGA view, which also keeps it above the drawing layer it adds later). The resolved color is set again on each
    //      pass, which the tab bar runs on a light / dark switch.
    // [CN] 没有着色 API：在动画库视图上方以 "sourceAtop" 合成的图层（使用普通图层：在液态玻璃 TabBar 中视图的图层不会被合成），每次着色时重新设置尺寸，
    //      有布局方法的视图在布局时也会设置（SVGA 视图，它还让该图层位于之后添加的绘制图层之上）。每次着色都会重新设置解析后的颜色，TabBar 在浅色 / 深色切换时
    //      会执行着色。
    CALayer *overlay = objc_getAssociatedObject(view, CYLTabBarItemAnimationTintOverlayKey);
    if (!resolved) {
        [overlay removeFromSuperlayer];
        objc_setAssociatedObject(view, CYLTabBarItemAnimationTintOverlayKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(view, CYLTabBarItemAnimationTintOverlaySizerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }
    if (!overlay) {
        overlay = [CALayer layer];
        overlay.compositingFilter = @"sourceAtop";
        overlay.name = @"CYLTabBarItemAnimationTintOverlay";
        objc_setAssociatedObject(view, CYLTabBarItemAnimationTintOverlayKey, overlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        CYLTabBarItemAnimationTintOverlaySizer *sizer = [[CYLTabBarItemAnimationTintOverlaySizer alloc] initWithHostLayer:view.layer overlay:overlay];
        objc_setAssociatedObject(view, CYLTabBarItemAnimationTintOverlaySizerKey, sizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    overlay.backgroundColor = resolved.CGColor;
    overlay.frame = view.bounds;
    if (overlay.superlayer != view.layer) {
        [view.layer addSublayer:overlay];
    }
    CYLTabBarItemAnimationRaiseTintOverlay(view.layer, overlay);
}

/// [EN] The `-cyl_applyAnimationViewTintColor:` added to a library's view class. [CN] 添加到动画库视图类上的 `-cyl_applyAnimationViewTintColor:`。
static void CYLTabBarItemAnimationTintMethod(UIView *view, SEL _cmd, UIColor *color) {
    NSDictionary<NSString *, NSString *> *options = objc_getAssociatedObject(view, CYLTabBarItemAnimationTintOptionsKey);
    if (!options) {
        return;
    }
    if ([objc_getAssociatedObject(view, CYLTabBarItemAnimationTintFinalKey) boolValue]) {
        CYLTabBarItemAnimationApplyTint(view, color);
        return;
    }
    UIColor *fixed = CYLTabBarItemAnimationFixedTintColor(options);
    if (fixed) {
        CYLTabBarItemAnimationApplyTint(view, fixed);
    } else if ([options[@"tint"] isEqualToString:@"title"]) {
        CYLTabBarItemAnimationApplyTint(view, color);
    }
}

/*!
 * [EN] The `-cyl_applyAnimationViewTintColor:selected:` added to a library's view class: a fixed tint on the unselected tab
 *      only; the selected tab takes `color`, the title's selected color (2026-11-19).
 * [CN] 添加到动画库视图类上的 `-cyl_applyAnimationViewTintColor:selected:`：固定着色只用于未选中的 Tab；选中的 Tab 使用 `color`（标题的选中颜色，
 *      2026-11-19）。
 */
static void CYLTabBarItemAnimationTintWithStateMethod(UIView *view, SEL _cmd, UIColor *color, BOOL selected) {
    NSDictionary<NSString *, NSString *> *options = objc_getAssociatedObject(view, CYLTabBarItemAnimationTintOptionsKey);
    if (!options) {
        return;
    }
    if ([objc_getAssociatedObject(view, CYLTabBarItemAnimationTintFinalKey) boolValue]) {
        CYLTabBarItemAnimationApplyTint(view, color);
        return;
    }
    UIColor *fixed = CYLTabBarItemAnimationFixedTintColor(options);
    if (fixed) {
        CYLTabBarItemAnimationApplyTint(view, (selected && color) ? color : fixed);
    } else if ([options[@"tint"] isEqualToString:@"title"]) {
        CYLTabBarItemAnimationApplyTint(view, color);
    }
}

/// [EN] Gives a new animation view its tint options and method, and its fixed tint. [CN] 为新的动画视图设置着色选项与方法，以及固定着色。
static BOOL CYLTabBarItemAnimationPrepareTintWithOptions(UIView *view, NSDictionary<NSString *, NSString *> *options, id<CYLTabBarItemAnimationPlayer> player) {
    // [EN] An invalid tint text is unset. [CN] 无效的着色文本等同于未设置。
    NSString *tintText = options[@"tint"];
    if (!tintText || !([tintText isEqualToString:@"title"] || CYLTabBarItemAnimationTintColorFromHex(tintText))) {
        return NO;
    }
    // [EN] Prepared once: a view the tab flow prepared is not prepared again by an item that wraps it. [CN] 只准备一次：Tab 流程已准备过的视图不会被包着它的条目再次准备。
    if (objc_getAssociatedObject(view, CYLTabBarItemAnimationTintOptionsKey)) {
        return YES;
    }
    SEL tintSelector = NSSelectorFromString(@"cyl_applyAnimationViewTintColor:");
    if (![view respondsToSelector:tintSelector]) {
        class_addMethod([view class], tintSelector, (IMP)CYLTabBarItemAnimationTintMethod, "v@:@");
        class_addMethod([view class], NSSelectorFromString(@"cyl_applyAnimationViewTintColor:selected:"),
                        (IMP)CYLTabBarItemAnimationTintWithStateMethod, "v@:@B");
    }
    objc_setAssociatedObject(view, CYLTabBarItemAnimationTintOptionsKey, options, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(view, CYLTabBarItemAnimationTintPlayerKey, player, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (CYLTabBarItemAnimationFixedTintColor(options)) {
        ((void (*)(id, SEL, UIColor *))[view methodForSelector:tintSelector])(view, tintSelector, nil);
    }
    // [EN] Once the library has set its view up (its content layers come after this call). [CN] 在动画库设置好视图之后（其内容图层在本调用之后添加）。
    __weak UIView *weakView = view;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIView *strongView = weakView;
        CYLTabBarItemAnimationRaiseTintOverlay(strongView.layer, objc_getAssociatedObject(strongView, CYLTabBarItemAnimationTintOverlayKey));
    });
    return YES;
}

/// [EN] Tells a view that reads its URL options itself (Rive) to take the title color although the URL has no `tint`. [CN] 让自行读取 URL 选项的视图（Rive）在 URL 没有 `tint` 时也使用标题颜色。
static void CYLTabBarItemAnimationSetTintFollowsTitle(UIView *view, BOOL follows) {
    SEL selector = NSSelectorFromString(@"cyl_setAnimationViewTintFollowsTitle:");
    if ([view respondsToSelector:selector]) {
        ((void (*)(id, SEL, BOOL))[view methodForSelector:selector])(view, selector, follows);
    }
}

void CYLTabBarItemAnimationResetTint(UIView *view) {
    if (objc_getAssociatedObject(view, CYLTabBarItemAnimationTintOptionsKey)) {
        CYLTabBarItemAnimationApplyTint(view, nil);
    }
    objc_setAssociatedObject(view, CYLTabBarItemAnimationTintOptionsKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(view, CYLTabBarItemAnimationTintFinalKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(view, CYLTabBarItemAnimationTabFlowModeKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    CYLTabBarItemAnimationSetTintFollowsTitle(view, NO);
}

BOOL CYLTabBarItemAnimationPrepareTint(UIView *view, NSURL *sourceURL, id<CYLTabBarItemAnimationPlayer> player) {
    return CYLTabBarItemAnimationPrepareTabTint(view, sourceURL, player, CYLTabBarItemAnimationRenderingModeAutomatic);
}

BOOL CYLTabBarItemAnimationPrepareTabTint(UIView *view, NSURL *sourceURL, id<CYLTabBarItemAnimationPlayer> player, NSInteger defaultRenderingMode) {
    NSMutableDictionary<NSString *, NSString *> *options = [CYLTabBarItemAnimationTintOptionsFromURL(sourceURL) mutableCopy];
    // [EN] Tab bars keep today's look: without a tint option the tab flow's rendering mode is alwaysOriginal (the file's own colors), unless the URL
    //      asks for `renderingMode=alwaysTemplate` (tinted like "title") or `renderingMode=automatic` (like "title" for a ONE-color file).
    // [CN] TabBar 保持现有外观：没有着色选项时，Tab 流程的渲染模式为 alwaysOriginal（文件自己的颜色），除非 URL 要求 `renderingMode=alwaysTemplate`
    //      （等同 "title" 着色）或 `renderingMode=automatic`（单色文件等同 "title"）。
    CYLTabBarItemAnimationRenderingMode mode = CYLTabBarItemAnimationRenderingModeAlwaysOriginal;
    BOOL followsTitle = NO;
    if (!CYLTabBarItemAnimationTintIsSet(options[@"tint"])) {
        // [EN] The tab's own `renderingMode` option, else the bar's default, else the file's own colors. [CN] 先取 Tab 自己的 `renderingMode` 选项，再取 TabBar 默认值，最后保持文件自己的颜色。
        CYLTabBarItemAnimationRenderingMode fallback = defaultRenderingMode == CYLTabBarItemAnimationRenderingModeAlwaysTemplate
            ? CYLTabBarItemAnimationRenderingModeAlwaysTemplate : CYLTabBarItemAnimationRenderingModeAlwaysOriginal;
        mode = CYLTabBarItemAnimationRenderingModeFromString(options[@"renderingMode"], fallback);
        if (mode == CYLTabBarItemAnimationRenderingModeAlwaysTemplate
            || (mode == CYLTabBarItemAnimationRenderingModeAutomatic && CYLTabBarItemAnimationColorKindOfURL(sourceURL) == CYLTabBarItemAnimationColorKindOneColor)) {
            options[@"tint"] = @"title";
            // [EN] Stored as template: an item showing this view has no URL to detect the file with. [CN] 记录为模板：显示该视图的条目没有可用于检测文件的 URL。
            mode = CYLTabBarItemAnimationRenderingModeAlwaysTemplate;
            followsTitle = YES;
        }
    }
    if (view) {
        objc_setAssociatedObject(view, CYLTabBarItemAnimationTabFlowModeKey, @(mode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        CYLTabBarItemAnimationSetTintFollowsTitle(view, followsTitle);
    }
    return CYLTabBarItemAnimationPrepareTintWithOptions(view, options, player);
}

/*!
 * [EN] The tint of the animation view of a `CYLAnimatedItemView` (the item path does not go through the tab flow): the options of the source
 *      URL, overridden by the item's own `animationTint` / `animationDarkTint` (Rive's `tint` / `darkTint` values: "title" or "#RRGGBB(AA)"),
 *      prepared again each time so setting or clearing the tint after the file loaded works. Without either the rendering mode decides (automatic: a ONE-color
 *      file takes the effective icon color).
 * [CN] `CYLAnimatedItemView` 的动画视图的着色（条目路径不经过 Tab 流程）：来源 URL 的选项，由条目自己的 `animationTint` / `animationDarkTint`
 *      （与 Rive 的 `tint` / `darkTint` 取值相同："title" 或 "#RRGGBB(AA)"）覆盖；每次都重新准备，因此文件加载之后再设置或清除着色也有效。
 *      两者都没有时不处理视图：文件保持自己的颜色。
 */
BOOL CYLTabBarItemAnimationPrepareItemTint(UIView *view, NSURL *sourceURL, id<CYLTabBarItemAnimationPlayer> player,
                                                                NSString *tintOverride, NSString *darkTintOverride) {
    NSMutableDictionary<NSString *, NSString *> *options = [CYLTabBarItemAnimationTintOptionsFromURL(sourceURL) mutableCopy];
    if (tintOverride.length > 0) {
        options[@"tint"] = tintOverride;
    }
    if (darkTintOverride.length > 0) {
        options[@"darkTint"] = darkTintOverride;
    }
    // [EN] The item hands over the FINAL color (its own resolver decided, rendering mode included), so the view only has to be able to take one:
    //      without a usable tint text the method is still added ("title" stands for any color the item gives).
    // [CN] 条目交来的是最终颜色（由它自己的解析函数决定，包括渲染模式），视图只需要能接受颜色：没有可用的着色文本时仍添加该方法（"title" 代表条目交来的任何颜色）。
    if (!CYLTabBarItemAnimationTintIsSet(options[@"tint"])) {
        options[@"tint"] = @"title";
    }
    // [EN] Prepared again: the previous tint is removed first. [CN] 重新准备：先移除之前的着色。
    if (objc_getAssociatedObject(view, CYLTabBarItemAnimationTintOptionsKey)) {
        objc_setAssociatedObject(view, CYLTabBarItemAnimationTintOptionsKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
        CYLTabBarItemAnimationApplyTint(view, nil);
    }
    objc_setAssociatedObject(view, CYLTabBarItemAnimationTintFinalKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return CYLTabBarItemAnimationPrepareTintWithOptions(view, options, player);
}
