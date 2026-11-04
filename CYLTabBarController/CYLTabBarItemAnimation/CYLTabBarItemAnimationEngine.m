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
// Core, which this subspec depends on (the source tree, or flattened by CocoaPods). 本子库依赖的 Core（源码目录，或 CocoaPods 展平后）。
#if __has_include("../CYLTabBarController.h")
#import "../CYLTabBarController.h"
#import "../UIControl+CYLTabBarItemAnimation.h"
#else
#import "CYLTabBarController.h"
#import "UIControl+CYLTabBarItemAnimation.h"
#endif

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
                     styleSource:(id<CYLTabBarItemAnimationStyleSource>)styleSource {
    if (self = [super init]) {
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
                      styleSource:CYLTabBarItemAnimationDefaultStyleSource()];
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
    // Remembered only for animations that use a #442 key. 仅为使用了 #442 新增 key 的动画记录。
    if (animationView && [self.styleSource hasStyleVariantForURL:sourceURL]) {
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
    if (darkColors.count == 0) {
        return;
    }
    id<CYLTabBarItemAnimationPlayer> player = [self.factory playerForView:animationView];
    if ([player respondsToSelector:@selector(applyDarkColors:traitCollection:)]) {
        [player applyDarkColors:darkColors traitCollection:traitCollection];
    }
}

#pragma mark - Views

- (UIView *)animationViewInControl:(UIControl *)control {
    if (!control || [control cyl_isPlusControl]) {
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
    if (control.cyl_tabBarController.lottieURLs.count > 0) {
        return control.cyl_tabBarController.lottieViewAdded;
    }
    UIView *view = [self animationViewInControl:control];
    return view ? view.frame.size.width > 10 : NO;
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
    if (!animationURL || !control || [control cyl_isPlusControl]) {
        return;
    }
    // FIX: Lottie icons invisible in FlatDesign. No size means a zero size; every animation view needs the placeholder
    // size, otherwise it is 0 x 0. 未设置尺寸时 size 为 0，所有动画视图都需要使用占位尺寸，否则为 0 x 0（扁平样式下图标不显示）。
    if (CGSizeEqualToSize(CGSizeZero, size)) {
        size = CGSizeMake(CYLTabBarItemImagePlaceholderWidth, CYLTabBarItemImagePlaceholderHeight);
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
    [control cyl_replaceTabImageViewWithNewView:animationView show:YES];
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
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationViewDidAddNotification object:tabButton];
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
    UIView *newAnimationView = [self makeAnimationViewWithSourceURL:sourceURL shownURL:URL size:animationView.bounds.size contentMode:animationView.contentMode];
    if (!newAnimationView) {
        return;
    }
    newAnimationView.center = animationView.center;
    newAnimationView.transform = animationView.transform;
    newAnimationView.autoresizingMask = animationView.autoresizingMask;
    newAnimationView.hidden = animationView.hidden;
    newAnimationView.alpha = animationView.alpha;
    [self copyAnimationStateFromView:animationView toView:newAnimationView];
    [superview insertSubview:newAnimationView aboveSubview:animationView];
    // The layout tracking of Core (#653) moves to the new view. Core 的布局跟踪（#653）改为跟随新视图。
    [superview cyl_replaceTrackedSubview:animationView withView:newAnimationView];
    [animationView removeFromSuperview];
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
    if (!URL || !control || [control cyl_isPlusControl]) {
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
    // [CN] 统一使用 CYLTabBarItemLottieAnimationPlayingNotification 重置其他 Tab 的动画。
    // [EN] The other tabs' animations are reset through CYLTabBarItemLottieAnimationPlayingNotification.
    [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:control];
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
