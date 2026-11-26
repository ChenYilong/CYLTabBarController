//
//  CYLTabBarItemViewAnimator.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarItemViewAnimator.h"
// [EN] The shared reader of a URL's options, from CYLUtils: no Core. [CN] 读取 URL 选项的共用函数，来自 CYLUtils：不依赖 Core。
#if __has_include("../CYLUtils/CYLAnimationKeys.h")
#import "../CYLUtils/CYLAnimationKeys.h"
#else
#import "CYLAnimationKeys.h"
#endif

/*!
 * [EN] The options in `URL`'s fragment, as written by `CYLTabBarAnimationURLWithOptions()` ("name=value&…",
 *      percent-encoded).
 * [CN] `URL` 的 fragment 中的选项，格式与 `CYLTabBarAnimationURLWithOptions()` 写入的相同（「名称=值&…」，百分号编码）。
 */
static NSDictionary<NSString *, NSString *> *CYLTabBarItemAnimationOptionsFromURL(NSURL *URL) {
    return CYLTabBarAnimationOptionsFromURL(URL);
}

/// [EN] `URL` without its options (the fragment, and a file URL's query): the animation file itself. [CN] 去掉选项（fragment，以及文件 URL 的 query）的 `URL`，即动画文件本身。
static NSURL *CYLTabBarItemAnimationFileURLFromURL(NSURL *URL) {
    NSURLComponents *components = [NSURLComponents componentsWithURL:URL resolvingAgainstBaseURL:YES];
    components.fragment = nil;
    if (URL.isFileURL) {
        components.query = nil;
    }
    return components.URL ?: URL;
}

/// [EN] Plays any `CYLTabBarItemAnimationPlayableView`. [CN] 播放任意 `CYLTabBarItemAnimationPlayableView`。
@interface CYLTabBarItemPlayableViewPlayer : CYLTabBarItemAnimationBasePlayer <CYLTabBarItemAnimationPlayer>
@end

@implementation CYLTabBarItemPlayableViewPlayer {
    /// [EN] Whether the dark colors are applied now. [CN] 当前是否已应用深色颜色。
    BOOL _darkColorsApplied;
    BOOL _loops;
    CGFloat _animationSpeed;
}

/*
 * [EN] `loops` exists only when the view loops itself (`-cyl_setAnimationViewLoops:`, e.g. Rive): otherwise the host keeps
 *      its own loop (CYLAnimatedItemView restarts a player with `progress`).
 * [CN] 只有视图自己会循环时（`-cyl_setAnimationViewLoops:`，例如 Rive）才提供 `loops`；否则宿主保留自己的循环（CYLAnimatedItemView 会重新开始
 *      带 `progress` 的播放器）。
 */
- (BOOL)respondsToSelector:(SEL)aSelector {
    if (aSelector == @selector(setLoops:) || aSelector == @selector(loops)) {
        return [self.playableView respondsToSelector:@selector(cyl_setAnimationViewLoops:)];
    }
    // [EN] `progress` and `animationSpeed` likewise exist only when the view can seek (both progress methods) or change
    //      its rate (e.g. SVGA): otherwise the host keeps its own fallback (no seeking, the file's own speed).
    // [CN] `progress` 与 `animationSpeed` 同样只在视图能定位（两个进度方法）或能改变速率（例如 SVGA）时提供；否则宿主保持自己的回退（不定位、文件自身速度）。
    if (aSelector == @selector(progress) || aSelector == @selector(setProgress:)) {
        id<CYLTabBarItemAnimationPlayableView> view = self.playableView;
        return [view respondsToSelector:@selector(cyl_animationViewProgress)]
            && [view respondsToSelector:@selector(cyl_setAnimationViewProgress:)];
    }
    if (aSelector == @selector(animationSpeed) || aSelector == @selector(setAnimationSpeed:)) {
        return [self.playableView respondsToSelector:@selector(cyl_setAnimationViewSpeed:)];
    }
    return [super respondsToSelector:aSelector];
}

- (CGFloat)progress {
    id<CYLTabBarItemAnimationPlayableView> view = self.playableView;
    return [view respondsToSelector:@selector(cyl_animationViewProgress)] ? [view cyl_animationViewProgress] : 0;
}

- (void)setProgress:(CGFloat)progress {
    id<CYLTabBarItemAnimationPlayableView> view = self.playableView;
    if ([view respondsToSelector:@selector(cyl_setAnimationViewProgress:)]) {
        [view cyl_setAnimationViewProgress:MIN(MAX(progress, 0), 1)];
    }
}

- (CGFloat)animationSpeed {
    return _animationSpeed > 0 ? _animationSpeed : 1;
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed {
    if (!(animationSpeed > 0) || !isfinite(animationSpeed)) {
        return;
    }
    _animationSpeed = animationSpeed;
    id<CYLTabBarItemAnimationPlayableView> view = self.playableView;
    if ([view respondsToSelector:@selector(cyl_setAnimationViewSpeed:)]) {
        [view cyl_setAnimationViewSpeed:animationSpeed];
    }
}

- (BOOL)loops {
    return _loops;
}

/*
 * [EN] The cross-platform members: `supportsColors` is the view's (this class answers `-applyColors:traitCollection:` for
 *      every view), `isPlaying` and the end of a pass come from the view when it can tell.
 * [CN] 跨平台成员：`supportsColors` 取决于视图（本类对每个视图都响应 `-applyColors:traitCollection:`），`isPlaying` 与一遍播放的结束在视图
 *      能判断时由视图提供。
 */
- (BOOL)supportsColors {
    return [self.playableView respondsToSelector:@selector(cyl_applyAnimationViewColors:)];
}

- (BOOL)isPlaying {
    id<CYLTabBarItemAnimationPlayableView> view = self.playableView;
    return [view respondsToSelector:@selector(cyl_animationViewIsPlaying)] && [view cyl_animationViewIsPlaying];
}

- (instancetype)initWithAnimationView:(UIView *)animationView {
    if (self = [super initWithAnimationView:animationView]) {
        id<CYLTabBarItemAnimationPlayableView> view = self.playableView;
        if ([view respondsToSelector:@selector(cyl_setAnimationViewEndHandler:)]) {
            __weak typeof(self) weakSelf = self;
            [view cyl_setAnimationViewEndHandler:^{
                [weakSelf notifyPlaybackEnded];
            }];
        }
    }
    return self;
}

- (void)setLoops:(BOOL)loops {
    _loops = loops;
    id<CYLTabBarItemAnimationPlayableView> view = self.playableView;
    if ([view respondsToSelector:@selector(cyl_setAnimationViewLoops:)]) {
        [view cyl_setAnimationViewLoops:loops];
    }
}

- (id<CYLTabBarItemAnimationPlayableView>)playableView {
    UIView *view = self.animationView;
    return [view conformsToProtocol:@protocol(CYLTabBarItemAnimationPlayableView)] ? (id<CYLTabBarItemAnimationPlayableView>)view : nil;
}

- (void)play {
    [self.playableView cyl_playAnimationView];
}

- (void)showLastFrame {
    [self.playableView cyl_showAnimationViewLastFrame];
}

- (void)stop {
    [self.playableView cyl_stopAnimationView];
}

- (void)applyDarkColors:(NSDictionary<NSString *, UIColor *> *)darkColors traitCollection:(UITraitCollection *)traitCollection {
    id<CYLTabBarItemAnimationPlayableView> view = self.playableView;
    if (darkColors.count == 0 || ![view respondsToSelector:@selector(cyl_applyAnimationViewColors:)]) {
        return;
    }
    BOOL dark = NO;
    if (@available(iOS 13.0, *)) {
        dark = (traitCollection.userInterfaceStyle == UIUserInterfaceStyleDark);
    }
    if (_darkColorsApplied == dark) {
        return;
    }
    _darkColorsApplied = dark;
    if (!dark) {
        [view cyl_applyAnimationViewColors:nil];
        return;
    }
    NSMutableDictionary<NSString *, UIColor *> *colors = [NSMutableDictionary dictionaryWithCapacity:darkColors.count];
    [darkColors enumerateKeysAndObjectsUsingBlock:^(NSString *path, UIColor *color, BOOL *stop) {
        (void)stop;
        if ([path isKindOfClass:[NSString class]] && [color isKindOfClass:[UIColor class]]) {
            UIColor *resolvedColor = color;
            if (@available(iOS 13.0, *)) {
                resolvedColor = [color resolvedColorWithTraitCollection:traitCollection];
            }
            colors[path] = resolvedColor;
        }
    }];
    [view cyl_applyAnimationViewColors:colors];
}

/// FIX: issue #216 — already resolved: handed to the view as they are; nil removes them. 已解析：原样交给视图；nil 移除。
- (void)applyColors:(nullable NSDictionary<NSString *, UIColor *> *)colors traitCollection:(UITraitCollection *)traitCollection {
    id<CYLTabBarItemAnimationPlayableView> view = self.playableView;
    if (![view respondsToSelector:@selector(cyl_applyAnimationViewColors:)]) {
        return;
    }
    _darkColorsApplied = NO;
    [view cyl_applyAnimationViewColors:colors.count > 0 ? colors : nil];
}

@end

@implementation CYLTabBarItemViewAnimator {
    NSString *_identifier;
    NSArray<NSString *> *_fileExtensions;
    NSDictionary<NSString *, NSString *> *_attributeKeys;
    /// [EN] The class given at initialization. [CN] 初始化时传入的类。
    Class<CYLTabBarItemAnimationViewProviding> _defaultViewProvider;
    /// [EN] The injected provider; nil: the default. [CN] 注入的 provider；nil 表示默认值。
    Class<CYLTabBarItemAnimationViewProviding> _injectedViewProvider;
}

- (instancetype)initWithIdentifier:(NSString *)identifier
                    fileExtensions:(NSArray<NSString *> *)fileExtensions
                     attributeKeys:(NSDictionary<NSString *, NSString *> *)attributeKeys
                      viewProvider:(Class<CYLTabBarItemAnimationViewProviding>)viewProvider {
    if (self = [super init]) {
        _identifier = [identifier copy];
        NSMutableArray<NSString *> *extensions = [NSMutableArray arrayWithCapacity:fileExtensions.count];
        for (NSString *extension in fileExtensions) {
            [extensions addObject:extension.lowercaseString];
        }
        _fileExtensions = [extensions copy];
        _attributeKeys = [attributeKeys copy] ?: @{};
        _defaultViewProvider = [viewProvider conformsToProtocol:@protocol(CYLTabBarItemAnimationViewProviding)] ? viewProvider : nil;
    }
    return self;
}

- (Class<CYLTabBarItemAnimationViewProviding>)viewProvider {
    if (_injectedViewProvider) {
        return _injectedViewProvider;
    }
    return _defaultViewProvider;
}

- (void)setViewProvider:(Class<CYLTabBarItemAnimationViewProviding>)viewProvider {
    _injectedViewProvider = [viewProvider conformsToProtocol:@protocol(CYLTabBarItemAnimationViewProviding)] ? viewProvider : nil;
}

#pragma mark - CYLTabBarItemAnimationFileMatching

- (NSString *)identifier {
    return _identifier;
}

- (NSArray<NSString *> *)fileExtensions {
    return _fileExtensions;
}

- (NSDictionary<NSString *, NSString *> *)attributeKeys {
    return _attributeKeys;
}

- (BOOL)canAnimateFileAtURL:(NSURL *)URL {
    // [EN] `pathExtension` leaves out the fragment (the options). [CN] `pathExtension` 不包含 fragment（选项）。
    NSString *extension = URL.pathExtension.lowercaseString;
    return extension.length > 0 && [_fileExtensions containsObject:extension];
}

#pragma mark - CYLTabBarItemAnimationViewFactory

- (UIView *)animationViewWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode {
    Class<CYLTabBarItemAnimationViewProviding> provider = self.viewProvider;
    if (!URL || !provider) {
        return nil;
    }
    UIView<CYLTabBarItemAnimationPlayableView> *view = [provider cyl_animationViewWithFileURL:CYLTabBarItemAnimationFileURLFromURL(URL)
                                                                                      options:CYLTabBarItemAnimationOptionsFromURL(URL)
                                                                                  contentMode:contentMode];
    view.frame = CGRectMake(0, 0, size.width, size.height);
    return view;
}

- (id<CYLTabBarItemAnimationPlayer>)playerForAnimationView:(UIView *)view {
    // [EN] Every playable view plays the same way, whichever view animator recognizes it.
    // [CN] 所有可播放视图的播放方式相同，无论由哪个视图 animator 识别。
    return [view conformsToProtocol:@protocol(CYLTabBarItemAnimationPlayableView)] ? [[CYLTabBarItemPlayableViewPlayer alloc] initWithAnimationView:view] : nil;
}

@end
