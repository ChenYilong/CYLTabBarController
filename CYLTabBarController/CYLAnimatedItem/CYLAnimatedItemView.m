//
//  CYLAnimatedItemView.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLAnimatedItemView.h"
#if __has_include("../CYLUtils/CYLLocalizedString.h")
#import "../CYLUtils/CYLLocalizedString.h"
#else
#import "CYLLocalizedString.h"
#endif

/*
 * [EN] How often a looping animation whose player has no `loops` checks whether it reached the end.
 * [CN] 播放器没有 `loops` 时，循环动画检查是否播放到末尾的间隔。
 */
#if CYL_ANIMATION_ENGINE_AVAILABLE
static const NSTimeInterval CYLAnimatedItemLoopCheckInterval = 0.05;
#endif

/*
 * [EN] The default animation size, as the tab bar's. [CN] 默认动画尺寸，与 TabBar 一致。
 */
static const CGFloat CYLAnimatedItemDefaultAnimationSide = 24;

@interface CYLAnimatedItemView () <UIGestureRecognizerDelegate>
@property (nonatomic, strong, readwrite) UIImageView *imageView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite, nullable) UIView *animationView;
@property (nonatomic, strong, readwrite) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong, readwrite) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, strong, nullable) NSTimer *loopTimer;
@property (nonatomic, assign) BOOL playing;
@end

#if CYL_ANIMATION_ENGINE_AVAILABLE
// [EN] Told by the engine when the animation file fails after the view was made. [CN] 动画文件在视图创建后失败时由引擎通知。
@interface CYLAnimatedItemView () <CYLTabBarItemAnimationFailureHandling>
@end

/*
 * [EN] Whether `URL` is a local file that is missing, not a regular file, or empty: no animation view is made for it, so
 *      the static image or the placeholder shows at once. Remote files are checked by the animator, which reports a failed
 *      download or a corrupted file (`CYLTabBarItemAnimationReportFailure`).
 * [CN] `URL` 是否为不存在、不是普通文件或为空的本地文件：不为其创建动画视图，立即显示静态图片或占位图。远程文件由 animator 检查，下载失败或文件损坏时报告
 *      （`CYLTabBarItemAnimationReportFailure`）。
 */
static BOOL CYLAnimatedItemLocalFileIsMissing(NSURL *URL) {
    if (!URL.isFileURL) {
        return NO;
    }
    NSString *path = URL.path;
    if (path.length == 0) {
        return YES;
    }
    NSDictionary<NSFileAttributeKey, id> *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
    return !attributes || ![attributes.fileType isEqualToString:NSFileTypeRegular] || attributes.fileSize == 0;
}
#endif

@implementation CYLAnimatedItemView

@synthesize title = _title;
@synthesize placeholderImage = _placeholderImage;
@synthesize image = _image;
@synthesize selectedImage = _selectedImage;
@synthesize animationURL = _animationURL;
@synthesize animationSpeed = _animationSpeed;
@synthesize animationLoops = _animationLoops;
@synthesize animationRestingProgress = _animationRestingProgress;
#if CYL_ANIMATION_ENGINE_AVAILABLE
@synthesize animationSource = _animationSource;
#endif

#pragma mark - Life cycle 生命周期

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self cyl_animatedItemSetUp];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self cyl_animatedItemSetUp];
    }
    return self;
}

- (void)dealloc {
    [_loopTimer invalidate];
}

- (void)cyl_animatedItemSetUp {
    _animationSpeed = 1;
    _spacing = 4;
    _accessorySize = CGSizeMake(18, 18);
    _accessoryPlacement = CYLAnimatedItemAccessoryPlacementTrailing;

    _imageView = [[UIImageView alloc] init];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    _imageView.isAccessibilityElement = NO;
    _imageView.accessibilityElementsHidden = YES;
    [self addSubview:_imageView];

    _titleLabel = [[UILabel alloc] init];
    _titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
    _titleLabel.adjustsFontForContentSizeCategory = YES;
    _titleLabel.textAlignment = NSTextAlignmentCenter;
    _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    _titleLabel.isAccessibilityElement = NO;
    [self addSubview:_titleLabel];

    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(cyl_handleLongPress:)];
    _longPressGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_longPressGestureRecognizer];

    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(cyl_handlePan:)];
    _panGestureRecognizer.delegate = self;
    _panGestureRecognizer.enabled = NO;
    [self addGestureRecognizer:_panGestureRecognizer];

    [self addTarget:self action:@selector(cyl_handleTap) forControlEvents:UIControlEventTouchUpInside];

    self.isAccessibilityElement = YES;
    self.accessibilityTraits = UIAccessibilityTraitButton;
    self.accessibilityIdentifier = @"CYLAnimatedItemView";
}

#pragma mark - Content 内容

- (void)setTitle:(NSString *)title {
    _title = [title copy];
    self.titleLabel.text = _title;
    [self updateItemAccessibility];
    [self cyl_contentDidChange];
}

- (void)setImage:(UIImage *)image {
    _image = image;
    [self cyl_updateIcon];
    [self cyl_contentDidChange];
}

- (void)setSelectedImage:(UIImage *)selectedImage {
    _selectedImage = selectedImage;
    [self cyl_updateIcon];
}

#pragma mark - Placeholder 占位图

+ (UIImage *)defaultPlaceholderImage {
    static UIImage *image = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = CYLResourceBundleNamed(@"CYLAnimatedItem");
        UIImage *found = bundle ? [UIImage imageNamed:@"cyl_animated_item_placeholder" inBundle:bundle compatibleWithTraitCollection:nil] : nil;
        image = [found imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    });
    return image;
}

- (UIImage *)placeholderImage {
    return _placeholderImage ?: [[self class] defaultPlaceholderImage];
}

- (void)setPlaceholderImage:(UIImage *)placeholderImage {
    _placeholderImage = placeholderImage;
    [self cyl_updateIcon];
    [self cyl_contentDidChange];
}

/*
 * [EN] The placeholder, when there is no static image and the animation file cannot play. [CN] 没有静态图片且动画文件无法播放时的占位图。
 */
- (UIImage *)cyl_placeholderIfNeeded {
    if (self.image || self.selectedImage || !self.animationURL || [self cyl_animationShows]) {
        return nil;
    }
    UIImage *placeholder = self.placeholderImage;
    return (placeholder.size.width > 0 && placeholder.size.height > 0) ? placeholder : nil;
}

/*
 * [EN] Whether the animation is on screen: made, and not waiting for its file (a download). Until then the static image
 *      given, or the placeholder when there is none, shows.
 * [CN] 动画是否已显示：已创建且不在等待其文件（下载）。在此之前显示传入的静态图片，没有时显示占位图。
 */
- (BOOL)cyl_animationShows {
#if CYL_ANIMATION_ENGINE_AVAILABLE
    return self.animationView != nil && !CYLTabBarItemAnimationIsLoading(self.animationView);
#else
    return NO;
#endif
}

- (void)cyl_updateIcon {
    UIImage *icon = (self.isSelected && self.selectedImage) ? self.selectedImage : self.image;
    if (!icon) {
        icon = [self cyl_placeholderIfNeeded];
    }
    self.imageView.image = icon;
    self.imageView.hidden = [self cyl_animationShows];
}

- (void)cyl_contentDidChange {
    [self invalidateIntrinsicContentSize];
    [self setNeedsLayout];
}

#pragma mark - Layout properties 布局属性

- (void)setAxis:(CYLAnimatedItemAxis)axis { _axis = axis; [self cyl_contentDidChange]; }
- (void)setAlignment:(CYLAnimatedItemAlignment)alignment { _alignment = alignment; [self setNeedsLayout]; }
- (void)setSpacing:(CGFloat)spacing { _spacing = spacing; [self cyl_contentDidChange]; }
- (void)setContentInsets:(UIEdgeInsets)contentInsets { _contentInsets = contentInsets; [self cyl_contentDidChange]; }
- (void)setIconSize:(CGSize)iconSize { _iconSize = iconSize; [self reloadAnimation]; }
- (void)setAccessoryPlacement:(CYLAnimatedItemAccessoryPlacement)accessoryPlacement { _accessoryPlacement = accessoryPlacement; [self cyl_contentDidChange]; }
- (void)setAccessorySize:(CGSize)accessorySize { _accessorySize = accessorySize; [self cyl_contentDidChange]; }

- (void)setAccessoryView:(UIView *)accessoryView {
    if (_accessoryView == accessoryView) {
        return;
    }
    [_accessoryView removeFromSuperview];
    _accessoryView = accessoryView;
    if (accessoryView) {
        accessoryView.userInteractionEnabled = YES;
        accessoryView.isAccessibilityElement = YES;
        if (!(accessoryView.accessibilityTraits & UIAccessibilityTraitButton)) {
            accessoryView.accessibilityTraits |= UIAccessibilityTraitButton;
        }
        if ([accessoryView isKindOfClass:[UIControl class]]) {
            [(UIControl *)accessoryView addTarget:self action:@selector(cyl_handleAccessoryTap) forControlEvents:UIControlEventTouchUpInside];
        } else {
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cyl_handleAccessoryTap)];
            [accessoryView addGestureRecognizer:tap];
        }
        [self addSubview:accessoryView];
    }
    [self cyl_contentDidChange];
}

- (void)setDragEnabled:(BOOL)dragEnabled {
    _dragEnabled = dragEnabled;
    self.panGestureRecognizer.enabled = dragEnabled;
}

#pragma mark - Measuring and layout 测量与布局

- (BOOL)cyl_showsIcon {
    return self.animationView != nil || self.imageView.image != nil;
}

- (BOOL)cyl_showsTitle {
    return self.title.length > 0;
}

- (BOOL)cyl_accessoryInline {
    return self.accessoryView != nil && self.accessoryPlacement != CYLAnimatedItemAccessoryPlacementTopTrailing;
}

- (CGSize)cyl_currentIconSize {
    if (![self cyl_showsIcon]) {
        return CGSizeZero;
    }
    if (self.iconSize.width > 0 && self.iconSize.height > 0) {
        return self.iconSize;
    }
    if (self.animationView) {
        return CGSizeMake(CYLAnimatedItemDefaultAnimationSide, CYLAnimatedItemDefaultAnimationSide);
    }
    return self.imageView.image.size;
}

- (CGSize)contentSizeThatFits:(CGSize)size {
    CGSize icon = [self cyl_currentIconSize];
    BOOL showsIcon = [self cyl_showsIcon];
    BOOL showsTitle = [self cyl_showsTitle];
    CGFloat spacing = (showsIcon && showsTitle) ? self.spacing : 0;
    CGFloat accessory = [self cyl_accessoryInline] ? self.accessorySize.width : 0;
    CGFloat accessorySpacing = (accessory > 0 && (showsIcon || showsTitle)) ? self.spacing : 0;
    CGFloat titleLimit = MAX(0, size.width - accessory - accessorySpacing - (self.axis == CYLAnimatedItemAxisHorizontal ? icon.width + spacing : 0));
    CGSize title = showsTitle ? [self.titleLabel sizeThatFits:CGSizeMake(titleLimit, CGFLOAT_MAX)] : CGSizeZero;
    title.width = MIN(ceil(title.width), titleLimit);
    title.height = ceil(title.height);
    CGFloat accessoryHeight = [self cyl_accessoryInline] ? self.accessorySize.height : 0;
    if (self.axis == CYLAnimatedItemAxisHorizontal) {
        return CGSizeMake(icon.width + spacing + title.width + accessory + accessorySpacing,
                          MAX(MAX(icon.height, title.height), accessoryHeight));
    }
    return CGSizeMake(MAX(icon.width, title.width) + accessory + accessorySpacing,
                      MAX(icon.height + spacing + title.height, accessoryHeight));
}

- (CGSize)sizeThatFits:(CGSize)size {
    UIEdgeInsets insets = self.contentInsets;
    CGFloat limit = (size.width > 0 ? size.width : CGFLOAT_MAX) - insets.left - insets.right;
    CGSize content = [self contentSizeThatFits:CGSizeMake(MAX(0, limit), size.height)];
    return CGSizeMake(ceil(content.width + insets.left + insets.right), ceil(content.height + insets.top + insets.bottom));
}

- (CGSize)intrinsicContentSize {
    return [self sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self layoutContentInRect:UIEdgeInsetsInsetRect(self.bounds, self.contentInsets)];
}

- (void)layoutContentInRect:(CGRect)rect {
    BOOL rtl = (self.effectiveUserInterfaceLayoutDirection == UIUserInterfaceLayoutDirectionRightToLeft);
    BOOL showsIcon = [self cyl_showsIcon];
    BOOL showsTitle = [self cyl_showsTitle];
    CGSize accessory = self.accessorySize;
    CGFloat accessorySpacing = ([self cyl_accessoryInline] && (showsIcon || showsTitle)) ? self.spacing : 0;
    CGRect content = rect;
    if ([self cyl_accessoryInline]) {
        BOOL leading = (self.accessoryPlacement == CYLAnimatedItemAccessoryPlacementLeading);
        CGFloat reserved = accessory.width + accessorySpacing;
        content.size.width = MAX(0, content.size.width - reserved);
        if (leading != rtl) {
            content.origin.x += reserved;
        }
    }
    CGSize icon = [self cyl_currentIconSize];
    CGFloat spacing = (showsIcon && showsTitle) ? self.spacing : 0;
    CGFloat titleLimit = self.axis == CYLAnimatedItemAxisHorizontal ? MAX(0, CGRectGetWidth(content) - icon.width - spacing) : CGRectGetWidth(content);
    CGSize title = showsTitle ? [self.titleLabel sizeThatFits:CGSizeMake(titleLimit, CGRectGetHeight(content))] : CGSizeZero;
    title.width = MIN(ceil(title.width), titleLimit);
    title.height = MIN(ceil(title.height), CGRectGetHeight(content));
    BOOL leadingAligned = (self.alignment == CYLAnimatedItemAlignmentLeading);
    CGRect iconFrame;
    CGRect titleFrame;
    if (self.axis == CYLAnimatedItemAxisHorizontal) {
        CGFloat group = icon.width + spacing + title.width;
        CGFloat start = leadingAligned ? 0 : floor((CGRectGetWidth(content) - group) / 2);
        CGFloat iconX = rtl ? CGRectGetMaxX(content) - start - icon.width : CGRectGetMinX(content) + start;
        CGFloat titleX = rtl ? iconX - spacing - title.width : iconX + icon.width + spacing;
        iconFrame = CGRectMake(iconX, CGRectGetMidY(content) - icon.height / 2, icon.width, icon.height);
        titleFrame = CGRectMake(titleX, CGRectGetMidY(content) - title.height / 2, title.width, title.height);
    } else {
        CGFloat group = icon.height + spacing + title.height;
        CGFloat top = CGRectGetMinY(content) + floor((CGRectGetHeight(content) - group) / 2);
        CGFloat iconX = leadingAligned ? (rtl ? CGRectGetMaxX(content) - icon.width : CGRectGetMinX(content)) : CGRectGetMidX(content) - icon.width / 2;
        CGFloat titleX = leadingAligned ? (rtl ? CGRectGetMaxX(content) - title.width : CGRectGetMinX(content)) : CGRectGetMidX(content) - title.width / 2;
        iconFrame = CGRectMake(iconX, top, icon.width, icon.height);
        titleFrame = CGRectMake(titleX, top + icon.height + spacing, title.width, title.height);
    }
    self.imageView.frame = iconFrame;
    self.animationView.frame = iconFrame;
    self.titleLabel.frame = titleFrame;
    [self cyl_layoutAccessoryInRect:rect iconFrame:iconFrame rightToLeft:rtl];
}

- (void)cyl_layoutAccessoryInRect:(CGRect)rect iconFrame:(CGRect)iconFrame rightToLeft:(BOOL)rtl {
    UIView *accessory = self.accessoryView;
    if (!accessory) {
        return;
    }
    CGSize size = self.accessorySize;
    CGFloat midY = CGRectGetMidY(rect) - size.height / 2;
    switch (self.accessoryPlacement) {
        case CYLAnimatedItemAccessoryPlacementLeading:
            accessory.frame = CGRectMake(rtl ? CGRectGetMaxX(rect) - size.width : CGRectGetMinX(rect), midY, size.width, size.height);
            break;
        case CYLAnimatedItemAccessoryPlacementTrailing:
            accessory.frame = CGRectMake(rtl ? CGRectGetMinX(rect) : CGRectGetMaxX(rect) - size.width, midY, size.width, size.height);
            break;
        case CYLAnimatedItemAccessoryPlacementTopTrailing: {
            CGFloat x = rtl ? CGRectGetMinX(iconFrame) - size.width / 2 : CGRectGetMaxX(iconFrame) - size.width / 2;
            accessory.frame = CGRectMake(x, MAX(0, CGRectGetMinY(iconFrame) - size.height / 2), size.width, size.height);
            break;
        }
    }
}

#pragma mark - State 状态

- (void)setSelected:(BOOL)selected {
    BOOL changed = (selected != self.isSelected);
    [super setSelected:selected];
    if (changed) {
        [self cyl_updateIcon];
        [self itemStateDidChange];
        [self updateItemAccessibility];
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    BOOL changed = (highlighted != self.isHighlighted);
    [super setHighlighted:highlighted];
    if (changed) {
        [self itemStateDidChange];
    }
}

- (void)setEnabled:(BOOL)enabled {
    BOOL changed = (enabled != self.isEnabled);
    [super setEnabled:enabled];
    if (changed) {
        [self itemStateDidChange];
        [self updateItemAccessibility];
    }
}

- (void)itemStateDidChange {
    // [EN] Subclass hook; nothing by default. [CN] 子类钩子；默认不做任何事。
}

#pragma mark - Animation 动画

#if CYL_ANIMATION_ENGINE_AVAILABLE

- (id<CYLTabBarItemAnimationViewMaking>)animationSource {
    return _animationSource ?: [CYLTabBarItemAnimationFactory sharedFactory];
}

- (void)setAnimationSource:(id<CYLTabBarItemAnimationViewMaking>)animationSource {
    _animationSource = animationSource;
    [self reloadAnimation];
}

- (void)setAnimationURL:(NSURL *)animationURL {
    if (animationURL == _animationURL || [animationURL isEqual:_animationURL]) {
        return;
    }
    _animationURL = [animationURL copy];
    [self reloadAnimation];
}

- (id<CYLTabBarItemAnimationPlayer>)animationPlayer {
    return self.animationView ? [self.animationSource playerForView:self.animationView] : nil;
}

- (BOOL)isAnimationReady {
    return self.animationView != nil;
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed {
    _animationSpeed = animationSpeed;
    [self cyl_applyPlayerSettings];
}

- (void)setAnimationLoops:(BOOL)animationLoops {
    _animationLoops = animationLoops;
    [self cyl_applyPlayerSettings];
    if (!animationLoops) {
        [self cyl_stopLoopTimer];
    } else if (self.playing) {
        [self cyl_startLoopTimerIfNeeded];
    }
}

- (void)setAnimationRestingProgress:(CGFloat)animationRestingProgress {
    _animationRestingProgress = MIN(1, MAX(0, animationRestingProgress));
    id<CYLTabBarItemAnimationPlayer> player = self.animationPlayer;
    if (!self.playing && [player respondsToSelector:@selector(setProgress:)]) {
        player.progress = _animationRestingProgress;
    }
}

- (void)cyl_applyPlayerSettings {
    id<CYLTabBarItemAnimationPlayer> player = self.animationPlayer;
    if (!player) {
        return;
    }
    if (self.animationSpeed > 0 && [player respondsToSelector:@selector(setAnimationSpeed:)]) {
        player.animationSpeed = self.animationSpeed;
    }
    if ([player respondsToSelector:@selector(setLoops:)]) {
        player.loops = self.animationLoops;
    }
}

- (void)reloadAnimation {
    [self cyl_stopLoopTimer];
    [self.animationView removeFromSuperview];
    self.animationView = nil;
    self.playing = NO;
    NSURL *URL = self.animationURL;
    if (URL && !CYLAnimatedItemLocalFileIsMissing(URL)) {
        CGSize size = (self.iconSize.width > 0 && self.iconSize.height > 0)
            ? self.iconSize : CGSizeMake(CYLAnimatedItemDefaultAnimationSide, CYLAnimatedItemDefaultAnimationSide);
        UIView *view = [self.animationSource animationViewWithURL:URL size:size contentMode:UIViewContentModeScaleAspectFit];
        if (view) {
            view.userInteractionEnabled = NO;
            view.isAccessibilityElement = NO;
            view.accessibilityElementsHidden = YES;
            [self insertSubview:view aboveSubview:self.imageView];
            self.animationView = view;
            [self cyl_applyPlayerSettings];
            id<CYLTabBarItemAnimationPlayer> player = self.animationPlayer;
            if ([player respondsToSelector:@selector(setProgress:)]) {
                player.progress = self.animationRestingProgress;
            }
        }
    }
    [self cyl_updateIcon];
    [self cyl_contentDidChange];
}

- (void)cylAnimationViewDidLoad:(UIView *)animationView {
    if (animationView == self.animationView) {
        [self cyl_updateIcon];
        [self cyl_contentDidChange];
    }
}

- (void)cylAnimationViewDidFail:(UIView *)animationView error:(NSError *)error {
    if (animationView != self.animationView) {
        return;
    }
    // [EN] A corrupted file, a parse error or a failed download: drop the animation; the static image or the placeholder shows.
    // [CN] 文件损坏、解析错误或下载失败：移除动画，显示静态图片或占位图。
    [self cyl_stopLoopTimer];
    [animationView removeFromSuperview];
    self.animationView = nil;
    self.playing = NO;
    [self cyl_updateIcon];
    [self cyl_contentDidChange];
}

- (void)playAnimation {
    id<CYLTabBarItemAnimationPlayer> player = self.animationPlayer;
    if (!player) {
        return;
    }
    self.playing = YES;
    [self cyl_applyPlayerSettings];
    [player play];
    [self cyl_startLoopTimerIfNeeded];
}

- (void)restartAnimation {
    id<CYLTabBarItemAnimationPlayer> player = self.animationPlayer;
    if ([player respondsToSelector:@selector(setProgress:)]) {
        player.progress = 0;
    }
    [self playAnimation];
}

- (void)stopAnimation {
    id<CYLTabBarItemAnimationPlayer> player = self.animationPlayer;
    self.playing = NO;
    [self cyl_stopLoopTimer];
    [player stop];
    if ([player respondsToSelector:@selector(setProgress:)]) {
        player.progress = self.animationRestingProgress;
    }
}

- (void)showAnimationLastFrame {
    self.playing = NO;
    [self cyl_stopLoopTimer];
    [self.animationPlayer showLastFrame];
}

/*
 * [EN] A player without `loops` (or with a `loops` it ignores) is restarted when it reaches the end, as
 *      CollectionViewClassifyMenu's tags did.
 * [CN] 没有 `loops`（或忽略 `loops`）的播放器，在播放到末尾时重新开始，与 CollectionViewClassifyMenu 的标签做法一致。
 */
- (void)cyl_startLoopTimerIfNeeded {
    id<CYLTabBarItemAnimationPlayer> player = self.animationPlayer;
    if (!self.animationLoops || self.loopTimer || [player respondsToSelector:@selector(setLoops:)] || ![player respondsToSelector:@selector(progress)]) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    self.loopTimer = [NSTimer timerWithTimeInterval:CYLAnimatedItemLoopCheckInterval repeats:YES block:^(NSTimer *timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        id<CYLTabBarItemAnimationPlayer> current = strongSelf.animationPlayer;
        if (!strongSelf || !strongSelf.playing || !current) {
            [timer invalidate];
            return;
        }
        if (current.progress >= 0.999) {
            current.progress = 0;
            [current play];
        }
    }];
    [[NSRunLoop mainRunLoop] addTimer:self.loopTimer forMode:NSRunLoopCommonModes];
}

- (void)cyl_stopLoopTimer {
    [self.loopTimer invalidate];
    self.loopTimer = nil;
}

#else

/*
 * [EN] Without the animation engine: static images only. The properties keep their values, so a subclass behaves the
 *      same and starts animating as soon as an animation subspec is added; nothing plays meanwhile.
 * [CN] 没有动画引擎：只显示静态图片。属性仍保存设置的值，子类行为一致，加入动画子库后即开始播放；在此之前不播放任何动画。
 */
- (void)setAnimationURL:(NSURL *)animationURL {
    _animationURL = [animationURL copy];
    // [EN] No engine: the file cannot play, so the placeholder shows when there is no static image.
    // [CN] 没有引擎：文件无法播放，没有静态图片时显示占位图。
    [self cyl_updateIcon];
    [self cyl_contentDidChange];
}

- (BOOL)isAnimationReady {
    return NO;
}

- (void)setAnimationSpeed:(CGFloat)animationSpeed {
    _animationSpeed = animationSpeed;
}

- (void)setAnimationLoops:(BOOL)animationLoops {
    _animationLoops = animationLoops;
}

- (void)setAnimationRestingProgress:(CGFloat)animationRestingProgress {
    _animationRestingProgress = MIN(1, MAX(0, animationRestingProgress));
}

- (void)reloadAnimation {
    [self cyl_updateIcon];
    [self cyl_contentDidChange];
}

- (void)playAnimation {
    // [EN] No engine: nothing to play. [CN] 没有引擎：没有可播放的内容。
}

- (void)restartAnimation {
    // [EN] No engine: nothing to play. [CN] 没有引擎：没有可播放的内容。
}

- (void)stopAnimation {
    // [EN] No engine: nothing to stop. [CN] 没有引擎：没有可停止的内容。
}

- (void)showAnimationLastFrame {
    // [EN] No engine: nothing to show. [CN] 没有引擎：没有可显示的内容。
}

- (void)cyl_stopLoopTimer {
    [self.loopTimer invalidate];
    self.loopTimer = nil;
}

#endif

#pragma mark - Gestures 手势

- (void)cyl_handleTap {
    if ([self.delegate respondsToSelector:@selector(animatedItemViewDidTap:)]) {
        [self.delegate animatedItemViewDidTap:self];
    }
}

- (void)cyl_handleAccessoryTap {
    if ([self.delegate respondsToSelector:@selector(animatedItemViewDidTapAccessory:)]) {
        [self.delegate animatedItemViewDidTapAccessory:self];
    }
}

- (void)cyl_handleLongPress:(UILongPressGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan && [self.delegate respondsToSelector:@selector(animatedItemViewDidLongPress:)]) {
        [self.delegate animatedItemViewDidLongPress:self];
    }
}

- (void)cyl_handlePan:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView:self.superview];
    id<CYLAnimatedItemViewDelegate> delegate = self.delegate;
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            if ([delegate respondsToSelector:@selector(animatedItemViewDidBeginDrag:)]) {
                [delegate animatedItemViewDidBeginDrag:self];
            }
            break;
        case UIGestureRecognizerStateChanged:
            if (self.dragMovesView) {
                self.transform = CGAffineTransformMakeTranslation(translation.x, translation.y);
            }
            if ([delegate respondsToSelector:@selector(animatedItemView:didDragWithTranslation:)]) {
                [delegate animatedItemView:self didDragWithTranslation:translation];
            }
            break;
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed: {
            BOOL cancelled = (recognizer.state != UIGestureRecognizerStateEnded);
            if (self.dragMovesView) {
                BOOL reduceMotion = UIAccessibilityIsReduceMotionEnabled();
                [UIView animateWithDuration:(reduceMotion ? 0 : 0.2) animations:^{
                    self.transform = CGAffineTransformIdentity;
                }];
            }
            if ([delegate respondsToSelector:@selector(animatedItemView:didEndDragWithTranslation:cancelled:)]) {
                [delegate animatedItemView:self didEndDragWithTranslation:translation cancelled:cancelled];
            }
            break;
        }
        default:
            break;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == self.panGestureRecognizer) {
        if (!self.dragEnabled) {
            return NO;
        }
        if ([self.delegate respondsToSelector:@selector(animatedItemViewShouldBeginDrag:)]) {
            return [self.delegate animatedItemViewShouldBeginDrag:self];
        }
        return YES;
    }
    if (gestureRecognizer == self.longPressGestureRecognizer) {
        return [self.delegate respondsToSelector:@selector(animatedItemViewDidLongPress:)];
    }
    return [super gestureRecognizerShouldBegin:gestureRecognizer];
}

#pragma mark - Accessibility 无障碍

- (NSString *)itemAccessibilityLabel {
    return self.title.length > 0 ? self.title : nil;
}

- (void)updateItemAccessibility {
    self.accessibilityLabel = [self itemAccessibilityLabel];
    UIAccessibilityTraits traits = UIAccessibilityTraitButton;
    if (self.isSelected) {
        traits |= UIAccessibilityTraitSelected;
    }
    if (!self.isEnabled) {
        traits |= UIAccessibilityTraitNotEnabled;
    }
    self.accessibilityTraits = traits;
}

- (NSArray<UIAccessibilityCustomAction *> *)accessibilityCustomActions {
    NSArray<UIAccessibilityCustomAction *> *existing = [super accessibilityCustomActions];
    UIView *accessory = self.accessoryView;
    if (!accessory || accessory.accessibilityLabel.length == 0) {
        return existing;
    }
    // [EN] VoiceOver reaches the accessory from the control's actions, since the control is one element.
    // [CN] 控件是一个无障碍元素，VoiceOver 通过控件的操作访问附加图标。
    // [EN] Target / selector: the block form needs iOS 13, the pod supports iOS 12. [CN] 使用 target / selector：block 形式需要 iOS 13，本 pod 支持 iOS 12。
    UIAccessibilityCustomAction *action = [[UIAccessibilityCustomAction alloc] initWithName:accessory.accessibilityLabel
                                                                                     target:self
                                                                                   selector:@selector(cyl_performAccessoryAction:)];
    return existing.count > 0 ? [existing arrayByAddingObject:action] : @[ action ];
}

- (BOOL)cyl_performAccessoryAction:(UIAccessibilityCustomAction *)action {
    [self cyl_handleAccessoryTap];
    return YES;
}

@end
