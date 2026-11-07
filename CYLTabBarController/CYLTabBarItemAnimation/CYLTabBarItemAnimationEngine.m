//
//  CYLTabBarItemAnimationEngine.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarItemAnimationEngine.h"
#import <objc/runtime.h>
#import "CYLTabBarItemAnimatorRegistry.h"
#import "CYLTabBarItemAnimationFactory.h"

static const void *CYLTabBarItemAnimationSourceURLKey = &CYLTabBarItemAnimationSourceURLKey;
static const void *CYLTabBarItemAnimationShownURLKey = &CYLTabBarItemAnimationShownURLKey;

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
    }
    return self;
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
