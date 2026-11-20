//
//  CYLTabBarItemAnimationEngine.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarItemAnimationEngine.h"
#if __has_include("../CYLUtils/CYLUtilsMacros.h")
#import "../CYLUtils/CYLUtilsMacros.h"
#else
#import "CYLUtilsMacros.h"
#endif

// [EN] The tab buttons' side of the engine, part of Core: compiled only when an animation subspec brings the engine.
// [CN] Tab 按钮使用引擎的部分，属于 Core：只有动画子库带入引擎时才编译。
#if CYL_ANIMATION_ENGINE_AVAILABLE
#import <objc/runtime.h>
// [EN] `CYLTabBarItemAnimationSetService()`, `…DefaultStyleSource()` and `…DefaultHost()` are `@_cdecl` Swift functions (step 118): declared by the
//      generated Swift interface, which this file must import itself (CI built it without any other header importing it).
// [CN] 这三个函数是 `@_cdecl` 的 Swift 函数（第 118 步）：由生成的 Swift 接口声明，本文件必须自己导入它（CI 构建时没有其他头文件导入它）。
#if __has_include("../CYLUtils/CYLSwiftInterface.h")
#import "../CYLUtils/CYLSwiftInterface.h"
#else
#import "CYLSwiftInterface.h"
#endif
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimatorRegistry.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimatorRegistry.h>
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#endif
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimationFactory.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimationFactory.h>
#else
#import "CYLTabBarItemAnimationFactory.h"
#endif

static const void *CYLTabBarItemAnimationSourceURLKey = &CYLTabBarItemAnimationSourceURLKey;
static const void *CYLTabBarItemAnimationShownURLKey = &CYLTabBarItemAnimationShownURLKey;

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
static const void *CYLTabBarItemAnimationTintPlayerKey = &CYLTabBarItemAnimationTintPlayerKey;
static const void *CYLTabBarItemAnimationTintOverlayKey = &CYLTabBarItemAnimationTintOverlayKey;
static const void *CYLTabBarItemAnimationTintOriginalFramesKey = &CYLTabBarItemAnimationTintOriginalFramesKey;

/// [EN] The options in a URL's fragment ("name=value&…", percent-encoded). [CN] URL fragment 中的选项（「名称=值&…」，百分号编码）。
static NSDictionary<NSString *, NSString *> *CYLTabBarItemAnimationTintOptionsFromURL(NSURL *URL) {
    NSString *fragment = URL ? [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES].percentEncodedFragment : nil;
    NSMutableDictionary<NSString *, NSString *> *options = [NSMutableDictionary dictionary];
    for (NSString *item in [fragment componentsSeparatedByString:@"&"]) {
        NSRange separator = [item rangeOfString:@"="];
        if (separator.location == NSNotFound || separator.location == 0) {
            continue;
        }
        NSString *name = [[item substringToIndex:separator.location] stringByRemovingPercentEncoding];
        NSString *value = [[[item substringFromIndex:NSMaxRange(separator)] stringByRemovingPercentEncoding]
                           stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceCharacterSet];
        if (name.length > 0 && value.length > 0) {
            options[name] = value;
        }
    }
    return [options copy];
}

/// [EN] "#RRGGBB" or "#RRGGBBAA" ("#" optional), else nil. [CN] "#RRGGBB" 或 "#RRGGBBAA"（"#" 可省略），否则为 nil。
static UIColor *CYLTabBarItemAnimationTintColorFromHex(NSString *hex) {
    NSString *digits = [hex hasPrefix:@"#"] ? [hex substringFromIndex:1] : hex;
    if (digits.length != 6 && digits.length != 8) {
        return nil;
    }
    unsigned long long value = 0;
    if (![[NSScanner scannerWithString:digits] scanHexLongLong:&value]) {
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
    // [EN] GIF: template frames in the view's tint color (UIKit's own tint). [CN] GIF：以视图 tint 颜色绘制的模板帧（UIKit 自身的着色）。
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
    UIColor *fixed = CYLTabBarItemAnimationFixedTintColor(options);
    if (fixed) {
        CYLTabBarItemAnimationApplyTint(view, (selected && color) ? color : fixed);
    } else if ([options[@"tint"] isEqualToString:@"title"]) {
        CYLTabBarItemAnimationApplyTint(view, color);
    }
}

/// [EN] Gives a new animation view its tint options and method, and its fixed tint. [CN] 为新的动画视图设置着色选项与方法，以及固定着色。
static void CYLTabBarItemAnimationPrepareTint(UIView *view, NSURL *sourceURL, id<CYLTabBarItemAnimationPlayer> player) {
    NSDictionary<NSString *, NSString *> *options = CYLTabBarItemAnimationTintOptionsFromURL(sourceURL);
    if (!options[@"tint"]) {
        return;
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
}

@implementation CYLTabBarItemAnimationEngine

/*!
 * [EN] Hands the engine to Core when the subspec loads, so Core gets it without knowing this class (dependency inversion).
 * [CN] 子库加载时把引擎交给 Core，Core 无需认识本类即可获得它（依赖反转）。
 */
+ (void)load {
    CYLTabBarItemAnimationSetService([[self alloc] init]);
}

- (instancetype)initWithRegistry:(id<CYLTabBarItemAnimatorRegistering>)registry
                         factory:(id<CYLTabBarItemAnimationViewMaking>)factory
                     styleSource:(id<CYLTabBarItemAnimationStyleSource>)styleSource
                            host:(id<CYLTabBarItemAnimationHost>)host {
    if (self = [super init]) {
        _host = host;
        _registry = registry;
        _factory = factory;
        _styleSource = styleSource;
        // [EN] A tab's animation that fails after its view was shown (a corrupt file found while parsing): UIKit's tab
        //      buttons do not adopt `CYLTabBarItemAnimationFailureHandling`, so the failure arrives as a notification.
        // [CN] Tab 的动画在视图显示之后才失败（解析时发现文件损坏）：UIKit 的 Tab 按钮不遵守 `CYLTabBarItemAnimationFailureHandling`，
        //      因此失败以通知的形式到达。
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cyl_animationViewDidFail:)
                                                     name:CYLTabBarItemAnimationDidFailNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

/*!
 * [EN] A tab's animation view failed late: it is removed and the tab shows its image again, or the animated item
 *      component's placeholder when the tab has none (the same display rule as before the view was made).
 * [CN] Tab 的动画视图晚些时候失败：移除该视图，Tab 重新显示其图片；没有图片时显示动效组件的占位图（与创建视图之前的显示规则相同）。
 */
- (void)cyl_animationViewDidFail:(NSNotification *)notification {
    UIView *animationView = [notification.object isKindOfClass:[UIView class]] ? notification.object : nil;
    UIControl *control = nil;
    for (UIView *view = animationView.superview; view; view = view.superview) {
        if ([view isKindOfClass:[UIControl class]] && [self animationViewInControl:(UIControl *)view] == animationView) {
            control = (UIControl *)view;
            break;
        }
    }
    if (!control) {
        return;
    }
    [animationView removeFromSuperview];
    SEL imageViewSelector = NSSelectorFromString(@"cyl_swappableImageViewViewInTabBarButton");
    UIImageView *imageView = nil;
    if ([control respondsToSelector:imageViewSelector]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS(imageView = [control performSelector:imageViewSelector]);
    }
    if (![imageView isKindOfClass:[UIImageView class]]) {
        return;
    }
    imageView.hidden = NO;
    imageView.alpha = 1;
    if (!imageView.image) {
        // [EN] The animated item component's placeholder, looked up at run time so that the engine's stand-alone tests
        //      (Tests/CYLTabBarItemAnimation, Foundation only) need no view class.
        // [CN] 动效组件的占位图，在运行时查找，使引擎的独立测试（Tests/CYLTabBarItemAnimation，只链接 Foundation）不需要视图类。
        Class itemViewClass = NSClassFromString(@"CYLAnimatedItemView");
        SEL placeholderSelector = NSSelectorFromString(@"defaultPlaceholderImage");
        if ([itemViewClass respondsToSelector:placeholderSelector]) {
            id placeholder = nil;
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS(placeholder = [itemViewClass performSelector:placeholderSelector]);
            imageView.image = [placeholder isKindOfClass:[UIImage class]] ? placeholder : nil;
        }
    }
}

/// [EN] The composition root: the only place that names the default implementations. [CN] 组合根：唯一指定默认实现的地方。
- (instancetype)init {
    CYLTabBarItemAnimatorRegistry *registry = [CYLTabBarItemAnimatorRegistry sharedRegistry];
    return [self initWithRegistry:registry
                          factory:[[CYLTabBarItemAnimationFactory alloc] initWithRegistry:registry]
                      styleSource:CYLTabBarItemAnimationDefaultStyleSource()
                             host:CYLTabBarItemAnimationDefaultHost()];
}

#pragma mark - Helpers

/*!
 * [EN] An animation view playing `shownURL`, the version of `sourceURL` (the light animation the tab was given) for the
 *      current style. Both URLs are kept on the view, so it can be swapped when the style changes (#442).
 * [CN] 播放 `shownURL` 的动画视图；`shownURL` 是 `sourceURL`（Tab 设置的浅色动画）在当前风格下的版本。两者都保存在视图上，以便风格变化时
 *      替换（#442）。
 */
- (UIView *)makeAnimationViewWithSourceURL:(NSURL *)sourceURL shownURL:(NSURL *)shownURL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    UIView *animationView = [self.factory animationViewWithURL:shownURL size:size contentMode:contentMode];
    // [EN] Always remembered (#216: a theme may replace the file, so the view must know which one it shows); the #442
    //      checks below still ask the style source.
    // [CN] 总是记录（#216：主题可能替换文件，视图需要知道自己显示的是哪一个）；下面 #442 的判断仍然询问风格来源。
    if (animationView) {
        objc_setAssociatedObject(animationView, CYLTabBarItemAnimationSourceURLKey, sourceURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(animationView, CYLTabBarItemAnimationShownURLKey, shownURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        CYLTabBarItemAnimationPrepareTint(animationView, sourceURL, [self.factory playerForView:animationView]);
    }
    return animationView;
}

/// [EN] Copies the playback state (speed, then progress) from one view to another, as far as both players support it.
/// [CN] 把播放状态（速度，然后进度）从一个视图复制到另一个视图，只复制双方播放器都支持的部分。
- (void)copyAnimationStateFromView:(UIView *)fromView toView:(UIView *)toView {
    id<CYLTabBarItemAnimationPlayer> from = [self.factory playerForView:fromView];
    id<CYLTabBarItemAnimationPlayer> to = [self.factory playerForView:toView];
    if (!from || !to) {
        return;
    }
    if ([from respondsToSelector:@selector(animationSpeed)] && [to respondsToSelector:@selector(setAnimationSpeed:)]) {
        to.animationSpeed = from.animationSpeed;
    }
    if ([from respondsToSelector:@selector(progress)] && [to respondsToSelector:@selector(setProgress:)]) {
        to.progress = from.progress;
    }
}

/*!
 * FIX: issue #442
 * [EN] Applies the dark colors registered for the view's animation where `traitCollection` is dark (and removes them
 *      otherwise), when its player supports it. Nothing without dark colors.
 * [CN] `traitCollection` 为深色时应用为该视图动画注册的深色颜色（否则移除），仅在其播放器支持时处理。没有深色颜色时不做处理。
 */
- (void)applyDarkColorsToAnimationView:(UIView *)animationView traitCollection:(UITraitCollection *)traitCollection {
    NSURL *sourceURL = animationView ? objc_getAssociatedObject(animationView, CYLTabBarItemAnimationSourceURLKey) : nil;
    NSDictionary<NSString *, UIColor *> *darkColors = [self.styleSource darkColorsForURL:sourceURL];
    // FIX: issue #216 — the colors of every appearance (`CYLTabBarAnimationColors`), theme colors resolved for the current
    // theme, with the dark colors on top in Dark Mode. 所有外观下的颜色（`CYLTabBarAnimationColors`），主题颜色按当前主题解析，深色模式下再叠加深色颜色。
    NSDictionary<NSString *, UIColor *> *colors = nil;
    if ([self.styleSource respondsToSelector:@selector(colorsForURL:)]) {
        colors = [self.styleSource colorsForURL:sourceURL];
    }
    if (darkColors.count == 0 && colors.count == 0) {
        return;
    }
    id<CYLTabBarItemAnimationPlayer> player = [self.factory playerForView:animationView];
    if ([player respondsToSelector:@selector(applyColors:traitCollection:)]) {
        BOOL dark = NO;
        if (@available(iOS 13.0, *)) {
            dark = (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
        }
        NSMutableDictionary<NSString *, UIColor *> *merged = [NSMutableDictionary dictionary];
        void (^add)(NSDictionary<NSString *, UIColor *> *) = ^(NSDictionary<NSString *, UIColor *> *source) {
            [source enumerateKeysAndObjectsUsingBlock:^(NSString *keypath, UIColor *color, BOOL *stop) {
                (void)stop;
                if (![keypath isKindOfClass:[NSString class]] || ![color isKindOfClass:[UIColor class]]) {
                    return;
                }
                // [EN] A theme color's value for the current theme, without depending on CYLUtils here. [CN] 主题颜色在当前主题下的值，这里不依赖 CYLUtils。
                UIColor *resolvedColor = color;
                if ([resolvedColor respondsToSelector:NSSelectorFromString(@"cyl_rawColor")]) {
                    resolvedColor = [resolvedColor valueForKey:@"cyl_rawColor"] ?: color;
                }
                if (@available(iOS 13.0, *)) {
                    resolvedColor = [resolvedColor resolvedColorWithTraitCollection:traitCollection] ?: resolvedColor;
                }
                merged[keypath] = resolvedColor;
            }];
        };
        add(colors);
        if (dark) {
            add(darkColors);
        }
        [player applyColors:merged traitCollection:traitCollection];
    } else if (darkColors.count > 0 && [player respondsToSelector:@selector(applyDarkColors:traitCollection:)]) {
        [player applyDarkColors:darkColors traitCollection:traitCollection];
    }
}

#pragma mark - Views

- (UIView *)animationViewInControl:(UIControl *)control {
    if (!control || [self.host isPlusControl:control]) {
        return nil;
    }
    for (UIView *subview in control.subviews) {
        if ([self isAnimationView:subview]) {
            return subview;
        }
        for (UIView *subsubview in subview.subviews) {
            if ([self isAnimationView:subsubview]) {
                return subsubview;
            }
        }
    }
    return nil;
}

- (BOOL)isAnimationView:(UIView *)view {
    if (!view || [view isMemberOfClass:[UIView class]]) {
        return NO;
    }
    return [self.factory isAnimationView:view];
}

- (BOOL)isAnimationReadyInControl:(UIControl *)control {
    return [self.host isAnimationView:[self animationViewInControl:control] readyInControl:control];
}

#pragma mark - Adding

- (void)addAnimationWithURL:(NSURL *)URL
                       size:(CGSize)size
                contentMode:(UIViewContentMode)contentMode
             animationSpeed:(CGFloat)animationSpeed
                  toControl:(UIControl *)control {
    BOOL hadAnimationView = ([self animationViewInControl:control] != nil);
    [self addAnimationWithURL:URL size:size contentMode:contentMode toControl:control];
    // FIX: issue #428 — the speed only for a view this call added, so a speed set for one tab is kept.
    // 仅为本次新添加的视图设置速度，为某个 Tab 单独设置的速度不会被覆盖。
    if (!hadAnimationView && animationSpeed > 0) {
        [self setAnimationSpeed:animationSpeed inControl:control];
    }
}

- (void)addAnimationWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode toControl:(UIControl *)control {
    // [EN] A local file that exists, as before, kept as given: its fragment holds a library's options (e.g. Rive's
    //      artboard), and the URL is the key of its Dark Mode version and of its library binding.
    // [CN] 与原来一样：必须是存在的本地文件，并保持原样：其 fragment 中保存动画库的选项（例如 Rive 的画板），且该 URL 是其深色模式版本与
    //      动画库绑定的 key。
    BOOL isLocalFile = [URL isKindOfClass:[NSURL class]] && URL.isFileURL && URL.path.length > 0;
    NSURL *animationURL = (isLocalFile && [[NSFileManager defaultManager] fileExistsAtPath:URL.path]) ? URL : nil;
    if (!animationURL || !control || [self.host isPlusControl:control]) {
        return;
    }
    // FIX: Lottie icons invisible in FlatDesign. No size means a zero size; every animation view needs the placeholder
    // size, otherwise it is 0 x 0. 未设置尺寸时 size 为 0，所有动画视图都需要使用占位尺寸，否则为 0 x 0（扁平样式下图标不显示）。
    if (CGSizeEqualToSize(CGSizeZero, size)) {
        size = [self.host defaultAnimationSize];
    }
    // FIX: issue #442 — first: does this animation use a #442 key (`…DarkURL` / `…DarkFilePath` / `…DarkColors`)?
    // Without one, everything below is the original path. 首先判断该动画是否使用了 #442 新增的 key；没有时，下面的逻辑与原来完全相同。
    BOOL followsDarkMode = [self.styleSource hasStyleVariantForURL:animationURL];
    UIView *shownAnimationView = [self animationViewInControl:control];
    if (shownAnimationView) {
        if (followsDarkMode) {
            [self replaceAnimationView:shownAnimationView
                               withURL:[self.styleSource URL:animationURL forTraitCollection:control.traitCollection]
                             sourceURL:animationURL];
            [self applyDarkColorsToAnimationView:[self animationViewInControl:control] traitCollection:control.traitCollection];
        }
        return;
    }
    // The dark animation where the style is dark. 深色风格下使用深色动画。
    NSURL *styleURL = followsDarkMode ? [self.styleSource URL:animationURL forTraitCollection:control.traitCollection] : animationURL;
    UIView *animationView = [self makeAnimationViewWithSourceURL:animationURL shownURL:styleURL size:size contentMode:contentMode];
    if (!animationView) {
        return;
    }
    if (followsDarkMode) {
        [self applyDarkColorsToAnimationView:animationView traitCollection:control.traitCollection];
    }
    [self.host showAnimationView:animationView inControl:control];
    [self postAnimationViewDidAddNotificationForControl:control];
}

/// FIX: issue #428 — posted asynchronously, so that the default speed is set before observers run, and a speed set by an
/// observer is kept. 异步发送，使观察者执行前已设置默认速度，观察者设置的速度也不会被覆盖。
- (void)postAnimationViewDidAddNotificationForControl:(UIControl *)control {
    __weak UIControl *weakControl = control;
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        UIControl *tabButton = weakControl;
        if (!tabButton || ![weakSelf animationViewInControl:tabButton]) {
            return;
        }
        [weakSelf.host animationViewDidAddInControl:tabButton];
    });
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed inControl:(UIControl *)control {
    if (animationSpeed <= 0) {
        return;
    }
    id<CYLTabBarItemAnimationPlayer> player = [self.factory playerForView:[self animationViewInControl:control]];
    // Libraries without a playback speed (PAG) do not implement it. 没有播放速度的动画库（PAG）不实现该方法。
    if ([player respondsToSelector:@selector(setAnimationSpeed:)]) {
        player.animationSpeed = animationSpeed;
    }
}

#pragma mark - Dark Mode (#442)

/*!
 * [EN] Swaps `animationView` for one playing `URL` in place (frame, layout tracking, visibility, playback state), unless it
 *      already plays it. Only for animations that use a #442 key: `sourceURL` is the light animation the tab was given
 *      (nil: the one recorded on the view).
 * [CN] 若 `animationView` 播放的不是 `URL`，原地替换为播放 `URL` 的视图（保持位置、布局跟踪、可见性和播放状态）。仅用于使用了 #442 新增 key
 *      的动画：`sourceURL` 为 Tab 设置的浅色动画（nil 表示视图上记录的那个）。
 */
- (void)replaceAnimationView:(UIView *)animationView withURL:(NSURL *)URL sourceURL:(nullable NSURL *)sourceURL {
    // First: an animation that uses a #442 key. 首先：使用了 #442 新增 key 的动画。
    if (![self.styleSource hasStyleVariants] || !animationView || !URL) {
        return;
    }
    sourceURL = sourceURL ?: objc_getAssociatedObject(animationView, CYLTabBarItemAnimationSourceURLKey);
    if (![self.styleSource hasStyleVariantForURL:sourceURL]) {
        return;
    }
    // A view made before the key was set plays the light animation. 设置 key 之前创建的视图播放的是浅色动画。
    NSURL *shownURL = objc_getAssociatedObject(animationView, CYLTabBarItemAnimationShownURLKey) ?: sourceURL;
    UIView *superview = animationView.superview;
    if (!superview || [shownURL isEqual:URL]) {
        if (!objc_getAssociatedObject(animationView, CYLTabBarItemAnimationSourceURLKey)) {
            objc_setAssociatedObject(animationView, CYLTabBarItemAnimationSourceURLKey, sourceURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(animationView, CYLTabBarItemAnimationShownURLKey, shownURL, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return;
    }
    [self swapAnimationView:animationView withNewView:[self makeAnimationViewWithSourceURL:sourceURL shownURL:URL size:animationView.bounds.size contentMode:animationView.contentMode]];
}

/*!
 * [EN] Puts `newAnimationView` where `animationView` is (same place, transform, visibility and playback state), moves the
 *      layout tracking of Core (#653) to it, and removes `animationView`. Nothing without a new view.
 * [CN] 把 `newAnimationView` 放到 `animationView` 的位置（相同的位置、transform、可见性与播放状态），把 Core 的布局跟踪（#653）转移给它，
 *      然后移除 `animationView`。没有新视图时不做处理。
 */
- (void)swapAnimationView:(UIView *)animationView withNewView:(nullable UIView *)newAnimationView {
    UIView *superview = animationView.superview;
    if (!newAnimationView || !superview) {
        return;
    }
    newAnimationView.center = animationView.center;
    newAnimationView.transform = animationView.transform;
    newAnimationView.autoresizingMask = animationView.autoresizingMask;
    newAnimationView.hidden = animationView.hidden;
    newAnimationView.alpha = animationView.alpha;
    [self copyAnimationStateFromView:animationView toView:newAnimationView];
    [superview insertSubview:newAnimationView aboveSubview:animationView];
    [self.host replaceTrackedSubview:animationView withView:newAnimationView inSuperview:superview];
    [animationView removeFromSuperview];
}

#pragma mark - Themes (#216)

- (void)replaceAnimationWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode inControl:(UIControl *)control {
    UIView *animationView = [self animationViewInControl:control];
    if (!animationView) {
        [self addAnimationWithURL:URL size:size contentMode:contentMode toControl:control];
        return;
    }
    BOOL isLocalFile = [URL isKindOfClass:[NSURL class]] && URL.isFileURL && URL.path.length > 0 && [[NSFileManager defaultManager] fileExistsAtPath:URL.path];
    if (!isLocalFile) {
        return;
    }
    NSURL *sourceURL = objc_getAssociatedObject(animationView, CYLTabBarItemAnimationSourceURLKey);
    if ([sourceURL isEqual:URL]) {
        // [EN] The same file: only its colors may have changed (theme colors). [CN] 同一个文件：只可能是颜色变了（主题颜色）。
        [self applyDarkColorsToAnimationView:animationView traitCollection:control.traitCollection];
        return;
    }
    CGSize viewSize = CGSizeEqualToSize(size, CGSizeZero) ? animationView.bounds.size : size;
    NSURL *shownURL = [self.styleSource hasStyleVariantForURL:URL] ? [self.styleSource URL:URL forTraitCollection:control.traitCollection] : URL;
    UIView *newAnimationView = [self makeAnimationViewWithSourceURL:URL shownURL:shownURL size:viewSize contentMode:contentMode];
    [self swapAnimationView:animationView withNewView:newAnimationView];
    if (newAnimationView.superview) {
        [self applyDarkColorsToAnimationView:newAnimationView traitCollection:control.traitCollection];
        [self postAnimationViewDidAddNotificationForControl:control];
    }
}

- (void)refreshAnimationColorsInControl:(UIControl *)control {
    UIView *animationView = [self animationViewInControl:control];
    if (animationView) {
        [self applyDarkColorsToAnimationView:animationView traitCollection:control.traitCollection];
    }
}

- (void)reloadAnimationForCurrentStyleInControl:(UIControl *)control {
    // First: only when a #442 key is in use. 首先：仅在使用了 #442 新增的 key 时处理。
    if (![self.styleSource hasStyleVariants]) {
        return;
    }
    UIView *animationView = [self animationViewInControl:control];
    NSURL *sourceURL = animationView ? objc_getAssociatedObject(animationView, CYLTabBarItemAnimationSourceURLKey) : nil;
    if (![self.styleSource hasStyleVariantForURL:sourceURL]) {
        return;
    }
    [self replaceAnimationView:animationView
                       withURL:[self.styleSource URL:sourceURL forTraitCollection:control.traitCollection]
                     sourceURL:sourceURL];
    [self applyDarkColorsToAnimationView:[self animationViewInControl:control] traitCollection:control.traitCollection];
}

#pragma mark - Playing

- (void)playAnimationWithURL:(NSURL *)URL
                        size:(CGSize)size
             defaultSelected:(BOOL)defaultSelected
                 contentMode:(UIViewContentMode)contentMode
                   inControl:(UIControl *)control {
    if (!URL || !control || [self.host isPlusControl:control]) {
        return;
    }
    //_UITabButton
    [self addAnimationWithURL:URL size:size contentMode:contentMode toControl:control];
    UIView *animationView = [self animationViewInControl:control];
    if (!animationView) {
        [self addAnimationWithURL:URL size:size contentMode:contentMode toControl:control];
        animationView = [self animationViewInControl:control];
    }
    id<CYLTabBarItemAnimationPlayer> player = [self.factory playerForView:animationView];
    if (!player) {
        return;
    }
    // [CN] 由宿主通知其他 Tab 重置动画（Core 发送 CYLTabBarItemAnimationPlayingNotification）。
    // [EN] The host tells the other tabs to reset (Core posts CYLTabBarItemAnimationPlayingNotification).
    [self.host animationWillPlayInControl:control];
    // [CN] 启动时选中的 Tab 不播放动画，直接显示最后一帧 #389
    // [EN] The tab selected at launch shows its last frame instead of playing. #389
    if (defaultSelected) {
        [player showLastFrame];
    } else {
        [player play];
    }
}

- (void)stopAnimationInControl:(UIControl *)control {
    [[self.factory playerForView:[self animationViewInControl:control]] stop];
}

- (void)restartAnimationInControl:(UIControl *)control {
    if (!control || [self.host isPlusControl:control]) {
        return;
    }
    // [EN] `-play` starts from the first frame in every library. [CN] 各动画库的 `-play` 都从第一帧开始。
    [[self.factory playerForView:[self animationViewInControl:control]] play];
}

- (void)setAnimationLoops:(BOOL)loops inControl:(UIControl *)control {
    id<CYLTabBarItemAnimationPlayer> player = [self.factory playerForView:[self animationViewInControl:control]];
    // Libraries without a loop mode (Rive, GIF) do not implement it. 没有循环模式的动画库（Rive、GIF）不实现该方法。
    if ([player respondsToSelector:@selector(setLoops:)]) {
        player.loops = loops;
    }
}

#pragma mark - Attributes

- (NSString *)attributeKeyForGenericKey:(NSString *)genericKey inAttributes:(NSDictionary *)attributes {
    return [self.registry attributeKeyForGenericKey:genericKey inAttributes:attributes];
}

- (void)bindAnimationURL:(NSURL *)URL toAttributes:(NSDictionary *)attributes {
    [self.registry bindURL:URL toAnimator:[self.registry animatorForAttributes:attributes]];
}

- (NSArray<NSString *> *)animationFileExtensions {
    return [self.registry fileExtensions];
}

@end

#endif
