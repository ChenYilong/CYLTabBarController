/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "UIView+CYLBadgeExtention.h"
#import <objc/runtime.h>
#import "CAAnimation+CYLBadgeExtention.h"
#import "CYLTabBarBadgeView.h"
#import "CYLBadgeAppearance.h"
// FIX: issue #535 — Core (tab bar) code only when CYLTabBarController is part of the build; see CYLBadgeViewDefines.h.
// FIX: issue #535 — 只有 CYLTabBarController 参与编译时才使用 Core（TabBar）代码，见 CYLBadgeViewDefines.h。
#import "CYLBadgeViewDefines.h"

#if CYL_BADGE_CORE_AVAILABLE && CYL_FLATDESIGN_AVAILABLE
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#endif

static const CGFloat kCYLBadgeDefaultRedDotRadius = 4.f;
static const NSTimeInterval kCYLBadgeDefaultDelayIfNeededForSeconds = 0.5;
static const NSUInteger kCYLBadgeMaximumLayoutRetryCount = 3;

@interface UIView (CYLBadgeEnvironmentPrivate)
- (void)cyl_badgeEnvironmentDidChange;
- (void)cyl_notifyBadgeHostOfEnvironmentChange;
@end

/*!
 * [EN] The default badge view. A `UILabel` in every way; it only tells its host when it enters a window or its
 *      traits change (e.g. Dark Mode), so the host can re-resolve the border color and restore a repeating animation
 *      that UIKit stripped. `CYLTabBarBadgeView` (the Liquid Glass badge on iOS 27) does the same.
 * [CN] 默认的角标视图。完全等同于 `UILabel`，只是在进入 window 或 trait 改变（如深色模式）时通知宿主，以便宿主重新解析
 *      边框颜色，并恢复被 UIKit 移除的循环动画。`CYLTabBarBadgeView`（iOS 27 液态玻璃角标）也会这样做。
 */
@interface CYLBadgeLabel : UILabel
@end

@implementation CYLBadgeLabel

- (void)didMoveToWindow {
    [super didMoveToWindow];
    [self cyl_notifyBadgeHostOfEnvironmentChange];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self cyl_notifyBadgeHostOfEnvironmentChange];
}
#pragma clang diagnostic pop

@end

NSString *CYLBadgeAccessibilityDescription(NSString *value) {
    if (!value) {
        return nil;
    }
    if (value.length == 0) {
        return CYLLocalizedString(@"有新内容");
    }
    if ([value rangeOfString:@"^[0-9]+\\+?$" options:NSRegularExpressionSearch].location != NSNotFound) {
        return value.integerValue > 0 ? [NSString stringWithFormat:CYLLocalizedString(@"%@ 条新消息"), value] : nil;
    }
    return CYLLocalizedString(value);
}

/*!
 * FIX: badges cut by a host view that clips
 * [EN] A badge is a subview of its host and sits half outside the host's top-right corner, so a host that clips
 *      (`clipsToBounds`, `layer.masksToBounds` or a `layer.mask`, e.g. a round avatar) cut it. For such a host the badge
 *      goes on this transparent view instead: it is inserted right above the host in the host's superview and pinned to
 *      the host's frame with constraints, so the badge is drawn above the host at the same place and is not clipped,
 *      while the host keeps its own clipping. It follows the host's `hidden` and `alpha` (KVO on the host's layer) and
 *      goes away with the host. A host that does not clip keeps the badge inside it, as before.
 * [CN] 角标是宿主视图的子视图，且有一半位于宿主右上角之外，因此会裁剪的宿主（`clipsToBounds`、`layer.masksToBounds` 或
 *      `layer.mask`，例如圆形头像）会把角标裁掉。对这类宿主，角标改为放在这个透明视图上：它插入在宿主父视图中、紧贴宿主之上，并
 *      用约束与宿主的 frame 对齐，因此角标仍在原位置、绘制在宿主之上且不被裁剪，宿主自身的裁剪不受影响。它跟随宿主的 `hidden`、
 *      `alpha`（KVO 宿主的 layer），并随宿主一起销毁。不裁剪的宿主仍把角标放在自身内部，与以前相同。
 */
@interface CYLBadgeHostOverlayView : UIView
@property (nonatomic, weak, readonly) UIView *host;
- (void)cyl_attachToHost:(UIView *)host;
- (void)cyl_detach;
@end

/// Removes the overlay when its host is deallocated (an associated object of the host). 宿主销毁时移除浮层（宿主的关联对象）。
@interface CYLBadgeHostOverlayToken : NSObject
@property (nonatomic, weak) CYLBadgeHostOverlayView *overlay;
@end

@implementation CYLBadgeHostOverlayToken
- (void)dealloc {
    CYLBadgeHostOverlayView *overlay = self.overlay;
    [overlay cyl_detach];
    [overlay removeFromSuperview];
}
@end

static void *CYLBadgeHostOverlayKVOContext = &CYLBadgeHostOverlayKVOContext;
static char CYLBadgeHostOverlayTokenKey;

@implementation CYLBadgeHostOverlayView {
    __weak UIView *_host;
    CALayer *_observedLayer;    // strong, so the observers are always removed from a live layer
    NSArray<NSLayoutConstraint *> *_hostConstraints;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = UIColor.clearColor;
        self.userInteractionEnabled = NO;
        self.clipsToBounds = NO;
        self.isAccessibilityElement = NO;
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (UIView *)host {
    return _host;
}

- (void)cyl_attachToHost:(UIView *)host {
    UIView *container = host.superview;
    if (!container) {
        return;
    }
    if (self.host != host || self.superview != container || !_hostConstraints.firstObject.active) {
        [self cyl_detach];
        _host = host;
        [container insertSubview:self aboveSubview:host];
        _hostConstraints = @[
            [self.leadingAnchor constraintEqualToAnchor:host.leadingAnchor],
            [self.topAnchor constraintEqualToAnchor:host.topAnchor],
            [self.widthAnchor constraintEqualToAnchor:host.widthAnchor],
            [self.heightAnchor constraintEqualToAnchor:host.heightAnchor],
        ];
        [NSLayoutConstraint activateConstraints:_hostConstraints];
        _observedLayer = host.layer;
        [_observedLayer addObserver:self forKeyPath:@"hidden" options:0 context:CYLBadgeHostOverlayKVOContext];
        [_observedLayer addObserver:self forKeyPath:@"opacity" options:0 context:CYLBadgeHostOverlayKVOContext];
    } else {
        [container insertSubview:self aboveSubview:host];
    }
    self.frame = host.frame;
    self.layer.zPosition = host.layer.zPosition;
    [self cyl_followHostVisibility];
}

- (void)cyl_followHostVisibility {
    CALayer *hostLayer = _observedLayer;
    self.hidden = hostLayer.hidden;
    self.alpha = hostLayer.opacity;
}

- (void)cyl_detach {
    if (_observedLayer) {
        [_observedLayer removeObserver:self forKeyPath:@"hidden" context:CYLBadgeHostOverlayKVOContext];
        [_observedLayer removeObserver:self forKeyPath:@"opacity" context:CYLBadgeHostOverlayKVOContext];
        _observedLayer = nil;
    }
    [NSLayoutConstraint deactivateConstraints:_hostConstraints ?: @[]];
    _hostConstraints = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context != CYLBadgeHostOverlayKVOContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    [self cyl_followHostVisibility];
}

- (void)dealloc {
    [self cyl_detach];
}

@end

/// The view the badge of `host` is added to: `host` itself, or an overlay above it when `host` clips. 承载 `host` 角标的视图。
static UIView *CYLBadgeContainerForHost(UIView *host) {
    CYLBadgeHostOverlayToken *token = objc_getAssociatedObject(host, &CYLBadgeHostOverlayTokenKey);
    BOOL hostClips = host.clipsToBounds || host.layer.masksToBounds || host.layer.mask != nil;
    if (!hostClips || !host.superview) {
        if (token.overlay) {
            [token.overlay cyl_detach];
            [token.overlay removeFromSuperview];
            token.overlay = nil;
        }
        return host;
    }
    if (!token) {
        token = [[CYLBadgeHostOverlayToken alloc] init];
        objc_setAssociatedObject(host, &CYLBadgeHostOverlayTokenKey, token, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    CYLBadgeHostOverlayView *overlay = token.overlay;
    if (!overlay) {
        overlay = [[CYLBadgeHostOverlayView alloc] initWithFrame:host.frame];
        token.overlay = overlay;
    }
    [overlay cyl_attachToHost:host];
    return overlay.superview ? overlay : host;
}

@implementation UIView (CYLBadgeExtention)

#pragma mark -- public methods

- (BOOL)cyl_isReady {

    if (![self cyl_badgeClass]) {
        return NO;
    }
//    if (!CYLGetRootViewController()) {
    //UIBarButton not ready, so if you use for BarButton, we cannot add redpoint. so i delete this judge.
//        return NO;
//    }
    UIView *view = [self cyl_getActualBadgeSuperView];

    if (view && [view isKindOfClass:[UIView class]]) {
        return view.frame.size.width > 10;
    }
    return [view cyl_findBarButtonContentView].frame.size.width > 10;
}
/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
- (void)cyl_showBadge {
    [self cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeNone];
}

- (void)cyl_showBadgeValue:(NSString *)value
        animationTypeValue:(NSNumber *)animationTypeValue {
    NSUInteger generation = [self cyl_invalidatePendingBadgeValue];
    if ([self cyl_shouldWaitForLayoutBeforeShowingBadgeValue:value]) {
        [self cyl_showBadgeValue:value animationTypeValue:animationTypeValue afterLayoutWithGeneration:generation attempt:0];
        return;
    }
    [self cyl_showBadgeValueNow:value animationTypeValue:animationTypeValue];
}

/*!
 * FIX: badge position with Auto Layout (xib / storyboard / constraints, e.g. a label with a relative width in a cell)
 * [EN] The badge was placed once, from the host view's frame at the moment it was shown. With Auto Layout that frame
 *      is often still zero (the badge was then dropped, so apps waited with `dispatch_after`) or changes later (the
 *      badge stayed where the old right edge was). Now:
 *      1. A host that is not laid out yet (`-cyl_isReady` is NO even after `-layoutIfNeeded`) shows the badge on the
 *         next run loop, then after `cyl_delayIfNeededForSeconds`, at most `kCYLBadgeMaximumLayoutRetryCount` times.
 *         Only the latest value is shown: a newer show or a clear cancels a pending one.
 *      2. The badge is anchored to the host's top-right corner (`-cyl_layoutBadgeAtTopRightCorner`), so it follows
 *         later size changes.
 *      Scope: every badge, whatever the tab bar style (classic, iOS 26 UI compatibility mode, Liquid Glass on iOS 26+
 *      and the iPhone Duo, FlatDesign) and any other view: they all share this code. On the Duo, folding changes the
 *      tab button widths, and Liquid Glass relays out its buttons; the anchored badge follows both.
 * [CN] 角标只在显示时按宿主视图当时的 frame 定位一次。使用自动布局时，这个 frame 往往还是 0（角标因此不显示，App 只能用
 *      `dispatch_after` 延迟），或者之后才改变（角标停留在原来的右边缘）。现在：
 *      1. 宿主尚未完成布局时（调用 `-layoutIfNeeded` 后 `-cyl_isReady` 仍为 NO），先在下一个 run loop、再按
 *         `cyl_delayIfNeededForSeconds` 延迟重试，最多 `kCYLBadgeMaximumLayoutRetryCount` 次。只显示最新的值：
 *         新的显示或清除会取消等待中的显示。
 *      2. 角标固定在宿主的右上角（`-cyl_layoutBadgeAtTopRightCorner`），宿主尺寸之后改变时角标跟随移动。
 *      范围：所有角标，与 TabBar 样式无关（经典、iOS 26 UI 兼容模式、iOS 26+ 液态玻璃与 iPhone Duo、扁平样式），
 *      以及其他任意视图：它们共用这段代码。iPhone Duo 折叠时 Tab 按钮宽度会变，液态玻璃也会重新布局按钮，角标都会跟随。
 */
- (BOOL)cyl_shouldWaitForLayoutBeforeShowingBadgeValue:(NSString *)value {
    if (!value || ![self cyl_badgeClass]) {
        return NO;
    }
    // A number <= 0 hides the badge, which needs no layout.
    NSString *nonDigits = [value stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
    if (value.length > 0 && nonDigits.length == 0 && [value integerValue] <= 0) {
        return NO;
    }
    return ![self cyl_isReady];
}

- (void)cyl_showBadgeValue:(NSString *)value
        animationTypeValue:(NSNumber *)animationTypeValue
 afterLayoutWithGeneration:(NSUInteger)generation
                   attempt:(NSUInteger)attempt {
    NSTimeInterval delay = (attempt == 0) ? 0 : MAX(self.cyl_delayIfNeededForSeconds, 0.1);
    __weak __typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) self = weakSelf;
        if (!self || [self cyl_pendingBadgeGeneration] != generation) {
            return;
        }
        if ((attempt + 1 < kCYLBadgeMaximumLayoutRetryCount) && [self cyl_shouldWaitForLayoutBeforeShowingBadgeValue:value]) {
            [self cyl_showBadgeValue:value animationTypeValue:animationTypeValue afterLayoutWithGeneration:generation attempt:attempt + 1];
            return;
        }
        [self cyl_showBadgeValueNow:value animationTypeValue:animationTypeValue];
    });
}

- (NSUInteger)cyl_pendingBadgeGeneration {
    return [objc_getAssociatedObject(self, @selector(cyl_pendingBadgeGeneration)) unsignedIntegerValue];
}

/// Cancels a badge value waiting for layout; returns the new generation.
- (NSUInteger)cyl_invalidatePendingBadgeValue {
    NSUInteger generation = [self cyl_pendingBadgeGeneration] + 1;
    objc_setAssociatedObject(self, @selector(cyl_pendingBadgeGeneration), @(generation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return generation;
}

- (void)cyl_showBadgeValueNow:(NSString *)value
           animationTypeValue:(NSNumber *)animationTypeValue {
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     [[[self cyl_badge] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
     if ([self cyl_shouldUpdateBadgeSubviews]) {
         [[self cyl_badge] removeFromSuperview];
         id view = nil;
         [self cyl_setBadge:view];
     }
     );
    CYLBadgeAnimationType animationType = [animationTypeValue intValue];
    [self  cyl_setBadgeAnimationTypeValue:@(animationType)];
    [self cyl_showBadgeWithValue:value];
    
    if (animationType != CYLBadgeAnimationTypeNone) {
        [self cyl_beginAnimation];
    }
}

- (void)cyl_showBadgeValue:(NSString *)value animationType:(CYLBadgeAnimationType)animationType {
    [self cyl_showBadgeValue:value animationTypeValue:@(animationType)];
}

- (void)cyl_showBadgeValue:(NSString *)value {
    [self cyl_showBadgeValue:value animationType:CYLBadgeAnimationTypeNone];
}

- (BOOL)cyl_keepShowingPlusButtonLabel {
    NSNumber *keepShowingPlusButtonLabelObject = objc_getAssociatedObject(self, @selector(cyl_keepShowingPlusButtonLabel));
    return [keepShowingPlusButtonLabelObject boolValue];
}

- (void)cyl_setKeepShowingPlusButtonLabel:(BOOL)keepShowingPlusButtonLabel {
    NSNumber *keepShowingPlusButtonLabelObject = @(keepShowingPlusButtonLabel);
    objc_setAssociatedObject(self, @selector(cyl_keepShowingPlusButtonLabel), keepShowingPlusButtonLabelObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -- private methods
/**
 By swizzling the original method - (void)willMoveToSuperview:(UIView *)newSuperview;
 Move the badge view on top of its siblings when its super view appears every time for adjustment on iOS 11.
 */
- (void)cyl_willMoveToSuperview:(UIView *)newSuperview __IOS_AVAILABLE(11.0) {
    [self cyl_willMoveToSuperview:newSuperview];
    
    if (newSuperview && self.cyl_badge) {
        [self cyl_bringBadgeToFront:self.cyl_badge];
    }
}

- (void)cyl_showBadgeWithValue:(NSString *)value {
    if (!value) {
        return;
    }
    NSCharacterSet *numberSet = [NSCharacterSet decimalDigitCharacterSet];
    NSString *trimmedString = [value stringByTrimmingCharactersInSet:numberSet];
    BOOL isNumber = NO;
    if ((trimmedString.length == 0) && (value.length > 0)) {
        isNumber = YES;
    }
    if (isNumber) {
        [self cyl_showNumberBadgeWithValue:[value integerValue]];
        return;
    }
    
    if ([value isEqualToString:@""]) {
        [self cyl_showRedDotBadge];
        return;
    }
    // Only spaces or line breaks: nothing to read, so hide instead of showing an empty pill.
    if ([value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].length == 0) {
        [self.cyl_badge cyl_setHidden:YES];
        return;
    }
    if ([value isEqualToString:@"new"] || [value isEqualToString:@"NEW"] ) {
        [self cyl_showNewBadge:value];
        return;
    }
    [self cyl_showTextBadge:value];
}

/**
 *  clear badge
 */
- (void)cyl_clearBadge {
    [self cyl_invalidatePendingBadgeValue];
    [self.cyl_badge cyl_setHidden:YES];
    [self cyl_updateBadgeAccessibility];
}

- (BOOL)cyl_isShowBadge {
    return (self.cyl_badge && !self.cyl_badge.cyl_isHidden);
}

/**
 *  make bage(if existing) not hiden
 */
- (void)cyl_resumeBadge {
    if (self.cyl_isPauseBadge) {
        [self.cyl_badge cyl_setHidden:NO];
        [self cyl_badgeEnvironmentDidChange];
    }
}

- (BOOL)cyl_isPauseBadge {
    return (self.cyl_badge && self.cyl_badge.cyl_isHidden);
}

- (nullable id)cyl_getActualBadgeSuperView {
    // [CN] 建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame.自动布局 cell 需要调用 [self layoutIfNeeded] frame才有值，角标才能找到对应的位置。 需要确保view showBadge的方法 在layoutIfNeeded之后调用
    // [EN] It is recommended to add a layoutIfNeeded call after the autolayout code before trying to get the frame. Auto
    //      layout cells must call [self layoutIfNeeded] for the frame to have a value, so the badge can find its position.
    //      Make sure the view's showBadge method is called after layoutIfNeeded.
    [self layoutIfNeeded];
    return self;
}

- (void)cyl_performSelector:(SEL)aSelector {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(nullable id)object {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(nullable id)object1 withObject:(nullable id)object2 {
    if (aSelector == NULL) { return; }
    
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     [self performSelector:aSelector withObject:object1 withObject:object2];
     )
}

#pragma mark -- private methods

- (void)cyl_addMargin {
    CGRect frame = self.cyl_badge.frame;
    frame.size.width += self.cyl_badgeMargin;
    frame.size.height += self.cyl_badgeMargin;
    if(CGRectGetWidth(frame) < CGRectGetHeight(frame)) {
        frame.size.width = CGRectGetHeight(frame);
    }
    self.cyl_badge.frame = frame;
}

- (void)cyl_showRedDotBadge {
    if (![self cyl_isReady]) {
        return;
    }
    [self cyl_badgeInit];
    //if badge has been displayed and, in addition, is was not red dot style, we must update UI.
    if (self.cyl_badge.tag != CYLBadgeStyleRedDot) {
        self.cyl_badge.text = @"";
        self.cyl_badge.tag = CYLBadgeStyleRedDot;
        [self cyl_resetRedDotBadgeFrame];
        self.cyl_badge.layer.cornerRadius = CGRectGetWidth(self.cyl_badge.frame) / 2;
    }
    [self cyl_applyBadgeBorder];
    [self.cyl_badge cyl_setHidden:NO];
    [self cyl_updateBadgeAccessibility];
}

- (void)cyl_showNewBadge:(NSString *)value {
    if (![self cyl_badgeClass]) {
        return;
    }
    // "new" / "NEW" are tokens; show them in the app's language.
    value = CYLLocalizedString(value);
    CGSize size = [value sizeWithAttributes:
                   @{NSFontAttributeName:
                         self.cyl_badgeFont}];
    CGFloat labelHeight = ceil(size.height) + self.cyl_badgeMargin;
    [self cyl_setBadgeCornerRadius:labelHeight/3];
    [self cyl_showTextBadge:value];
}

- (void)cyl_showTextBadge:(NSString *)value {
    if (![self cyl_isReady]) {
        return;
    }
    if (value == 0 || !value ||value.length == 0) {
        [self.cyl_badge cyl_setHidden:YES];
        [self cyl_updateBadgeAccessibility];
        return;
    }
    [self cyl_badgeInit];
    self.cyl_badge.tag = CYLBadgeStyleOther;
    self.cyl_badge.text = value;
    self.cyl_badge.font = self.cyl_badgeFont;
    [self cyl_adjustLabelWidth:self.cyl_badge];
    [self cyl_addMargin];
    [self cyl_layoutBadgeAtTopRightCorner];
    self.cyl_badge.layer.cornerRadius = [self cyl_textBadgeCornerRadius];
    [self cyl_applyBadgeBorder];
    [self.cyl_badge cyl_setHidden:NO];
    [self cyl_updateBadgeAccessibility];
}

/*!
 * [EN] VoiceOver. The badge label sits deep inside its host, and when an ancestor is an accessibility element (a tab
 *      button, a table view cell, a bar button), VoiceOver never reads that element's subviews, so the badge was silent.
 *      Its meaning ("3 new messages", "New content", "New") becomes the `accessibilityValue` of the nearest accessible
 *      ancestor, e.g. "Messages, 3 new messages"; that element's own value comes back when the badge is cleared. With no
 *      such ancestor, the badge label itself is the element.
 * [CN] VoiceOver：角标 label 位于宿主视图深处，当祖先视图是无障碍元素（Tab 按钮、cell、导航栏按钮）时，VoiceOver 不会读取
 *      其子视图，角标因此无法被读到。现在把角标含义（“3 条新消息”“有新内容”“新”）设为最近的无障碍祖先的
 *      `accessibilityValue`，例如“消息，3 条新消息”；清除角标时恢复该元素原有的值。没有这样的祖先时，角标 label 自身作为元素。
 */
- (void)cyl_updateBadgeAccessibility {
    UIView<CYLBadgeTextDisplaying> *badge = self.cyl_badge;
    NSString *description = (badge && !badge.cyl_isHidden) ?
        CYLBadgeAccessibilityDescription(badge.tag == CYLBadgeStyleRedDot ? @"" : badge.text) : nil;
    UIView *element = self.isAccessibilityElement ? self : nil;
    for (UIView *view = self.superview; !element && view && ![view isKindOfClass:[UIWindow class]]; view = view.superview) {
        if (view.isAccessibilityElement) {
            element = view;
        }
    }
    badge.isAccessibilityElement = (element == nil && description != nil);
    badge.accessibilityLabel = description;
    if (!element) {
        return;
    }
    static const void *CYLBadgeOriginalAccessibilityValueKey = &CYLBadgeOriginalAccessibilityValueKey;
    id saved = objc_getAssociatedObject(element, CYLBadgeOriginalAccessibilityValueKey);
    if (description) {
        if (!saved) {
            // NSNull marks "had no value", so the original nil can be restored too.
            objc_setAssociatedObject(element, CYLBadgeOriginalAccessibilityValueKey, element.accessibilityValue ?: [NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        element.accessibilityValue = description;
    } else if (saved) {
        element.accessibilityValue = [saved isKindOfClass:[NSString class]] ? (NSString *)saved : nil;
        objc_setAssociatedObject(element, CYLBadgeOriginalAccessibilityValueKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)cyl_showNumberBadgeWithValue:(NSInteger)value {
    if (![self cyl_badgeClass]) {
        return;
    }
    if (value <= 0) {
        [self.cyl_badge cyl_setHidden:YES];
        return;
    }
    [self cyl_badgeInit];
    [self.cyl_badge cyl_setHidden:(value == 0)];
    self.cyl_badge.tag = CYLBadgeStyleNumber;
    // A maximum below 1 would turn every number into "0+".
    NSInteger maximumBadgeNumber = MAX(1, self.cyl_badgeMaximumBadgeNumber);
    NSString *text = (value > maximumBadgeNumber ?
                      [NSString stringWithFormat:@"%@+", @(maximumBadgeNumber)] :
                      [NSString stringWithFormat:@"%@", @(value)]);
    [self cyl_showTextBadge:text];
}

//lazy loading
- (void)cyl_badgeInit {
    if (![self cyl_isReady]) {
        return;
    }
    // The colors are not written back here: unset, they resolve to `CYLBadgeAppearance` (#425) every time.
    // 这里不再把颜色写回对象：未设置时每次都从 `CYLBadgeAppearance` 取值（#425）。
    if (!self.cyl_badge) {
        Class class = [self cyl_badgeClass];
        self.cyl_badge = [[class alloc] initWithFrame:(self.frame)];
//        self.cyl_badge = [[class alloc] init];

        [self cyl_resetRedDotBadgeFrame];
        self.cyl_badge.textAlignment = NSTextAlignmentCenter;
        self.cyl_badge.textColor = self.cyl_badgeTextColor;
        self.cyl_badge.text = @"";
        self.cyl_badge.layer.cornerRadius = CGRectGetWidth(self.cyl_badge.frame) / 2;
        self.cyl_badge.layer.masksToBounds = YES;//very important
        [self.cyl_badge cyl_setHidden:YES];
        self.cyl_badge.isAccessibilityElement = NO;
        
        self.cyl_badge.backgroundColor = self.cyl_badgeBackgroundColor;
        [self cyl_applyBadgeBorder];
        
        [self cyl_bringBadgeToFront:self.cyl_badge];
        return;
    }
    // An existing badge picks up a global color changed since it was created.
    // 已存在的角标同步创建之后修改过的全局颜色。
    self.cyl_badge.backgroundColor = self.cyl_badgeBackgroundColor;
    self.cyl_badge.textColor = self.cyl_badgeTextColor;
}

- (void)cyl_bringBadgeToFront:(UIView *)view {
    if (![self cyl_isReady]) {
        return;
    }
    // Above everything in the host, or in an overlay above the host when the host clips (CYLBadgeHostOverlayView).
    // 位于宿主所有内容之上；宿主会裁剪时放在宿主之上的浮层中（CYLBadgeHostOverlayView）。
    UIView *container = CYLBadgeContainerForHost(self);
    if (view.superview != container) {
        [container addSubview:view];
    }
    [container bringSubviewToFront:view];
    view.layer.zPosition = MAXFLOAT;
    // This used to add a `CYLTabBarStyleTypeDidChangeNotification` observer whose block did nothing, on every call,
    // including every `-willMoveToSuperview:`, and never removed it: observers piled up for the app's lifetime.
    // 这里原先每次调用（包括每次 `-willMoveToSuperview:`）都会注册一个空操作的通知观察者且从不移除，观察者随 App 运行不断累积。
}

- (void)cyl_resetRedDotBadgeFrame {
    CGFloat redotWidth = kCYLBadgeDefaultRedDotRadius *2;
    CGFloat badgeRadius = self.cyl_badgeRadius;
    if (badgeRadius > 0 && isfinite(badgeRadius)) {
        redotWidth = badgeRadius * 2;
    }
    if (!self.cyl_badge) {
        return;
    }
    CGRect frame = CGRectMake(CGRectGetWidth(self.bounds), -redotWidth, redotWidth, redotWidth);
    self.cyl_badge.frame = frame;
    // [CN] 更新frame
    // [EN] Update the frame
    [self.cyl_badge layoutIfNeeded];
    [self cyl_layoutBadgeAtTopRightCorner];
    self.cyl_badge.layer.masksToBounds = YES;//very important
    
}

/*!
 * [EN] Centers the badge on the host's top-right corner (plus `cyl_badgeCenterOffset`) and keeps it there: the flexible
 *      left and bottom margins move it with the right edge when the host is resized later, by Auto Layout too (the
 *      mask is turned into constraints). `bounds`, not `frame`: a transform on the host (e.g. a tab image animation)
 *      must not move the badge.
 * [CN] 将角标中心放在宿主右上角（加上 `cyl_badgeCenterOffset`），并保持在那里：左边距和下边距可变，宿主之后尺寸改变时
 *      （包括自动布局，mask 会转换为约束）角标随右边缘移动。使用 `bounds` 而不是 `frame`：宿主上的 transform
 *      （如 Tab 图片动画）不应移动角标。
 */
- (void)cyl_layoutBadgeAtTopRightCorner {
    UIView *badge = self.cyl_badge;
    if (!badge) {
        return;
    }
    badge.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    CGPoint badgeCenterOffset = self.cyl_badgeCenterOffset;
    CGFloat offsetX = isfinite(badgeCenterOffset.x) ? badgeCenterOffset.x : 0;
    CGFloat offsetY = isfinite(badgeCenterOffset.y) ? badgeCenterOffset.y : 0;
    badge.center = CGPointMake(CGRectGetWidth(self.bounds) + 2 + offsetX, offsetY);
}

/*!
 * [EN] A custom `cyl_badgeCornerRadius` is kept within half the badge's shorter side (anything larger draws a
 *      distorted shape); 0, negative or non-finite means automatic: half the height.
 * [CN] 自定义的 `cyl_badgeCornerRadius` 不超过角标短边的一半（更大会导致形状变形）；0、负数或非有限值表示自动：高度的一半。
 */
- (CGFloat)cyl_textBadgeCornerRadius {
    CGSize size = self.cyl_badge.bounds.size;
    CGFloat maximumRadius = MAX(0, MIN(size.width, size.height) / 2);
    CGFloat customRadius = self.cyl_badgeCornerRadius;
    if (customRadius > 0 && isfinite(customRadius)) {
        return MIN(customRadius, maximumRadius);
    }
    return MAX(0, size.height / 2);
}

#pragma mark -- border, environment, refresh

/*!
 * [EN] Applies `cyl_badgeBorderWidth` / `cyl_badgeBorderColor`. `CALayer.borderColor` is a `CGColor`, which does not
 *      follow Dark Mode by itself, so a dynamic color is resolved against the badge's traits here, and again whenever
 *      they change (see `CYLBadgeLabel`).
 * [CN] 应用 `cyl_badgeBorderWidth` / `cyl_badgeBorderColor`。`CALayer.borderColor` 是 `CGColor`，不会自动跟随深色模式，
 *      因此在这里按角标的 trait 解析动态颜色，并在 trait 改变时重新解析（见 `CYLBadgeLabel`）。
 */
- (void)cyl_applyBadgeBorder {
    UIView *badge = self.cyl_badge;
    if (!badge) {
        return;
    }
    CGFloat borderWidth = self.cyl_badgeBorderWidth;
    badge.layer.borderWidth = borderWidth;
    UIColor *borderColor = self.cyl_badgeBorderColor;
    if (borderWidth <= 0 || !borderColor) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        borderColor = [borderColor resolvedColorWithTraitCollection:badge.traitCollection];
    }
    badge.layer.borderColor = borderColor.CGColor;
}

/// Called by the badge view itself (`CYLBadgeLabel`, `CYLTabBarBadgeView`) when it enters a window or its traits change.
- (void)cyl_notifyBadgeHostOfEnvironmentChange {
    UIView *host = self.superview;
    if ([host isKindOfClass:[CYLBadgeHostOverlayView class]]) {
        host = ((CYLBadgeHostOverlayView *)host).host;
    }
    if (host && host.cyl_badge == self) {
        [host cyl_badgeEnvironmentDidChange];
    }
}

/*!
 * [EN] Re-resolves the border color, and keeps the repeating animation in step with the environment: restores it if
 *      UIKit stripped it (e.g. a Liquid Glass platter rebuild, a cell moved to another window), removes it while
 *      Reduce Motion is on. One-shot animations are never replayed here.
 * [CN] 重新解析边框颜色，并使循环动画与环境保持一致：被 UIKit 移除时恢复（如液态玻璃重建 platter、cell 移到其他 window），
 *      开启"减弱动态效果"时移除。一次性动画不会在这里重播。
 */
- (void)cyl_badgeEnvironmentDidChange {
    UIView *badge = self.cyl_badge;
    if (!badge) {
        return;
    }
    [self cyl_applyBadgeBorder];
    NSString *repeatingAnimationKey = CYLBadgeAnimationTypeRepeats(self.cyl_badgeAnimationType) ? CYLBadgeAnimationKeyForType(self.cyl_badgeAnimationType) : nil;
    if (!repeatingAnimationKey || !badge.window || badge.hidden || badge.alpha <= 0.01f) {
        return;
    }
    if ([self cyl_shouldReduceBadgeMotion]) {
        [self cyl_removeBadgeAnimations];
        return;
    }
    if (![badge.layer animationForKey:repeatingAnimationKey]) {
        [self cyl_beginAnimation];
    }
}

- (void)cyl_refreshBadge {
    UIView *badge = self.cyl_badge;
    BOOL isInOverlay = [badge.superview isKindOfClass:[CYLBadgeHostOverlayView class]] && ((CYLBadgeHostOverlayView *)badge.superview).host == self;
    if (!badge || (badge.superview != self && !isInOverlay)) {
        return;
    }
    UIView *container = CYLBadgeContainerForHost(self);
    if (badge.superview != container) {
        [container addSubview:badge];
    }
    [container bringSubviewToFront:badge];
    [self cyl_layoutBadgeAtTopRightCorner];
    [self cyl_badgeEnvironmentDidChange];
}

- (void)cyl_resetBadgeAppearance {
    SEL keys[] = {
        @selector(cyl_badgeFont), @selector(cyl_badgeBackgroundColor), @selector(cyl_badgeTextColor),
        @selector(cyl_badgeCenterOffset), @selector(cyl_badgeRadius), @selector(cyl_badgeMargin),
        @selector(cyl_badgeCornerRadius), @selector(cyl_badgeMaximumBadgeNumber),
        @selector(cyl_badgeBorderColor), @selector(cyl_badgeBorderWidth),
    };
    for (size_t i = 0; i < sizeof(keys) / sizeof(keys[0]); i++) {
        objc_setAssociatedObject(self, keys[i], nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    UIView<CYLBadgeTextDisplaying> *badge = self.cyl_badge;
    if (!badge) {
        return;
    }
    badge.backgroundColor = self.cyl_badgeBackgroundColor;
    badge.textColor = self.cyl_badgeTextColor;
    badge.font = self.cyl_badgeFont;
    [self cyl_applyBadgeBorder];
}

- (BOOL)cyl_shouldReduceBadgeMotion {
    return self.cyl_badgeRespectsReduceMotion && UIAccessibilityIsReduceMotionEnabled();
}

- (void)cyl_removeBadgeAnimations {
    CALayer *layer = self.cyl_badge.layer;
    for (NSString *key in CYLBadgeAllAnimationKeys()) {
        [layer removeAnimationForKey:key];
    }
}

#pragma mark --  other private methods
- (void)cyl_adjustLabelWidth:(UIView<CYLBadgeTextDisplaying> *)badgeSuperView {
    if (!badgeSuperView) {
        return;
    }
    // [CN] 获得子视图的Label以获得字符长度。用以拉伸父视图
    //UILabel 与 CYLTabBarBadgeView 没有继承关系，各自检查类型后再向下转换（两者都是 UIView 的子类）。
    // [EN] Get the subview's Label to get the text length, used to stretch the superview.
    //      UILabel and CYLTabBarBadgeView are unrelated by inheritance; check each type before downcasting (both are
    //      UIView subclasses).
    UILabel *label = nil;
    if ([badgeSuperView isKindOfClass:[UILabel class]]) {
        label = (UILabel *)badgeSuperView;
    } else if ([badgeSuperView isKindOfClass:[CYLTabBarBadgeView class]]) {
        label = ((CYLTabBarBadgeView *)badgeSuperView).badgeLabel;
    }
    if (!label.text || 0 == label.text.length) {
        return;
    }
    CGSize labelsize = [self cyl_getLabelSize:label];
    if (CGSizeEqualToSize(CGSizeZero, labelsize)) {
        return;
    }
//    CGSize labelsize = [self sizeThatFits:CGSizeMake(CYLScreenWidth() ,CYLScreenHeight())];
    CGRect frame = label.frame;
    frame.size = CGSizeMake(ceil(labelsize.width), ceil(labelsize.height));
// [CN] 获得字符长度后， 需要修改父视图的宽度， 仅仅修改Label无法达到真正的拉伸效果
// [EN] After getting the text length, the superview's width must be changed; changing only the Label does not
//      actually stretch it.
        [label setFrame:frame];

    [badgeSuperView setFrame:frame];

}

/*!
 * [EN] A badge is one line: measure the text as one line (`-sizeWithAttributes:`) and keep the label on one line.
 *
 *      `UILabel.numberOfLines`: 0 means "as many lines as the text needs", so the text wraps whenever the label is
 *      narrower than it; 1 means exactly one line, which never wraps and, if it does not fit, is cut at the end with "…".
 *
 *      What 1 fixes: `-cyl_adjustLabelWidth:` sizes the badge to the measured text width (plus `cyl_badgeMargin`).
 *      With 0, any shortfall, a host that resizes the badge, rounding, or a bold font measured a hair narrower than it
 *      draws ("99+", "new"), made the label wrap into two lines; the second line was clipped by `masksToBounds`,
 *      or the badge turned taller than a one-line badge. The text was also measured with word wrapping in a screen-sized
 *      box, which let a long text report a multi-line size. With 1 the height is always one line.
 *
 *      Trade-off: a text with a line break shows only its first line (and the size follows the text as measured).
 *      Badges are short by design; use `cyl_badgeMaximumBadgeNumber` for numbers and keep text badges to a few characters.
 * [CN] 角标只有一行：按单行测量文本（`-sizeWithAttributes:`），并让 Label 保持单行。
 *
 *      `UILabel.numberOfLines`：0 表示"文本需要几行就显示几行"，Label 比文本窄时就会换行；1 表示固定一行，永不换行，
 *      放不下时在末尾用 "…" 截断。
 *
 *      设为 1 解决的问题：`-cyl_adjustLabelWidth:` 按测量出的文本宽度（加上 `cyl_badgeMargin`）确定角标宽度。
 *      设为 0 时，只要宽度稍有不足（宿主调整了角标大小、取整误差、粗体测量值比实际绘制略窄，如 "99+"、"new"），
 *      Label 就会换成两行：第二行被 `masksToBounds` 裁掉，或角标比单行角标更高。此外原先在屏幕大小的区域内按单词换行测量，
 *      长文本会得到多行的尺寸。设为 1 后高度始终是一行。
 *
 *      代价：含换行符的文本只显示第一行（尺寸仍按测量值）。角标本就应该很短；数字用 `cyl_badgeMaximumBadgeNumber` 限制，文本角标保持几个字符。
 */
- (CGSize)cyl_getLabelSize:(UILabel *)label {
    label.numberOfLines = 1;
    NSString *text = label.text;
    UIFont *font = label.font;
    if (text.length == 0 || !font) {
        return CGSizeZero;
    }
    CGSize size = [text sizeWithAttributes:@{NSFontAttributeName : font}];
    return CGSizeMake(ceil(size.width), ceil(size.height));
}

#pragma mark -- animation

//if u want to add badge animation type, follow steps bellow:
//1. go to definition of CYLBadgeAnimationType and add new type, with its key (see the note above the keys in
//   CYLBadgeProtocol.h: CYLBadgeAnimationKeyForType, CYLBadgeAnimationTypeRepeats, CYLBadgeAllAnimationKeys)
//2. go to category of CAAnimation+CYLBadgeExtention to add new animation interface
//3. call that new interface here
- (void)cyl_beginAnimation {
    if (!self.cyl_badge) {
        return;
    }
    // Replace, don't stack: showing a value with another animation type used to add it on top of the previous one.
    [self cyl_removeBadgeAnimations];
    if ([self cyl_shouldReduceBadgeMotion]) {
        return;
    }
    // One factory for every badge, also the system badge of a bar button item on iOS 26+ (CYLBadgeViewDefines.h).
    // 所有角标共用同一个工厂方法，包括 iOS 26+ 上 bar button item 的系统角标。
    CYLBadgeAnimationType animationType = self.cyl_badgeAnimationType;
    CAAnimation *animation = CYLBadgeAnimationForType(animationType, self.cyl_badge.bounds.size);
    NSString *animationKey = CYLBadgeAnimationKeyForType(animationType);
    if (animation && animationKey) {
        [self.cyl_badge.layer addAnimation:animation forKey:animationKey];
    }
}

- (void)cyl_removeAnimation {
    if (self.cyl_badge) {
        [self.cyl_badge.layer removeAllAnimations];
    }
}

#pragma mark -- setter/getter

- (UIView<CYLBadgeTextDisplaying> *)cyl_badge {
    return objc_getAssociatedObject(self, @selector(cyl_badge));
}

- (void)cyl_setBadge:(UIView<CYLBadgeTextDisplaying> *)label {
    objc_setAssociatedObject(self, @selector(cyl_badge), label, OBJC_ASSOCIATION_RETAIN);
}

- (UIFont *)cyl_badgeFont {
    id font = objc_getAssociatedObject(self, @selector(cyl_badgeFont));
    return font ?: [CYLBadgeAppearance globalAppearance].font;
}

- (void)cyl_setBadgeFont:(UIFont *)badgeFont {
    objc_setAssociatedObject(self, @selector(cyl_badgeFont), badgeFont, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    // nil restores the global font.
    self.cyl_badge.font = self.cyl_badgeFont;
}

- (UIColor *)cyl_badgeBackgroundColor {
    return objc_getAssociatedObject(self, @selector(cyl_badgeBackgroundColor)) ?: [CYLBadgeAppearance globalAppearance].backgroundColor;
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeBackgroundColor), badgeBackgroundColor, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    // nil restores the global color.
    self.cyl_badge.backgroundColor = self.cyl_badgeBackgroundColor;
}

- (UIColor *)cyl_badgeTextColor {
    return objc_getAssociatedObject(self, @selector(cyl_badgeTextColor)) ?: [CYLBadgeAppearance globalAppearance].textColor;
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeTextColor), badgeTextColor, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    // nil restores the global color.
    self.cyl_badge.textColor = self.cyl_badgeTextColor;
}

- (CYLBadgeAnimationType)cyl_badgeAnimationType {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeAnimationType));
    if(obj != nil && [obj isKindOfClass:[NSNumber class]]) {
        return [obj integerValue];
    }
    return CYLBadgeAnimationTypeNone;
}

- (void)cyl_setBadgeAnimationType:(CYLBadgeAnimationType)animationType {
    NSNumber *numObj = @(animationType);
    objc_setAssociatedObject(self, @selector(cyl_badgeAnimationType), numObj, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    [self cyl_removeAnimation];
    [self cyl_beginAnimation];
}

- (void)cyl_setBadgeAnimationTypeValue:(NSNumber *)cyl_badgeAnimationTypeValue {
    CYLBadgeAnimationType badgeAnimationType = [cyl_badgeAnimationTypeValue integerValue];
    [self cyl_setBadgeAnimationType:badgeAnimationType];
}
- (NSNumber *)cyl_badgeAnimationTypeValue {
    return @([self cyl_badgeAnimationType]);
}

- (CGRect)cyl_badgeFrame {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeFrame));
    if (obj != nil && [obj isKindOfClass:[NSDictionary class]] && [obj count] == 4) {
        CGFloat x = [obj[@"x"] doubleValue];
        CGFloat y = [obj[@"y"] doubleValue];
        CGFloat width = [obj[@"width"] doubleValue];
        CGFloat height = [obj[@"height"] doubleValue];
        return  CGRectMake(x, y, width, height);
    }
    return CGRectZero;
}

- (void)cyl_setBadgeFrameValue:(NSValue *)cyl_badgeFrameValue {
    CGRect badgeFrame = cyl_badgeFrameValue.CGRectValue;
    [self cyl_setBadgeFrame:badgeFrame];
}

- (NSValue *)cyl_badgeFrameValue {
    return [NSValue valueWithCGRect:[self cyl_badgeFrame]];
}

- (void)cyl_setBadgeFrame:(CGRect)badgeFrame {
    // Ignore a frame UIKit cannot draw (NaN / infinite, or an empty size).
    BOOL isFinite = isfinite(badgeFrame.origin.x) && isfinite(badgeFrame.origin.y) &&
                    isfinite(badgeFrame.size.width) && isfinite(badgeFrame.size.height);
    if (!isFinite || badgeFrame.size.width <= 0 || badgeFrame.size.height <= 0) {
        return;
    }
    NSDictionary *frameInfo = @{@"x" : @(badgeFrame.origin.x), @"y" : @(badgeFrame.origin.y),
                                @"width" : @(badgeFrame.size.width), @"height" : @(badgeFrame.size.height)};
    objc_setAssociatedObject(self, @selector(cyl_badgeFrame), frameInfo, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.frame = badgeFrame;
}

- (CGFloat)cyl_badgeCornerRadius {
    NSNumber *badgeCornerRadiusObject = objc_getAssociatedObject(self, @selector(cyl_badgeCornerRadius));
    return badgeCornerRadiusObject != nil ? [badgeCornerRadiusObject doubleValue] : [CYLBadgeAppearance globalAppearance].cornerRadius;
}

- (void)cyl_setBadgeCornerRadius:(CGFloat)badgeCornerRadius {
    NSNumber *badgeCornerRadiusObject = @(badgeCornerRadius);
    objc_setAssociatedObject(self, @selector(cyl_badgeCornerRadius), badgeCornerRadiusObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cyl_setBadgeCornerRadiusValue:(NSNumber *)cyl_badgeCornerRadiusValue {
    CGFloat cyl_badgeCornerRadius = [cyl_badgeCornerRadiusValue doubleValue];
    [self cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}
- (NSNumber *)cyl_badgeCornerRadiusValue {
    return @([self cyl_badgeCornerRadius]);
}

- (CGPoint)cyl_badgeCenterOffset {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeCenterOffset));
    if (obj != nil && [obj isKindOfClass:[NSDictionary class]] && [obj count] == 2) {
        CGFloat x = [obj[@"x"] doubleValue];
        CGFloat y = [obj[@"y"] doubleValue];
        return CGPointMake(x, y);
    }
    return [CYLBadgeAppearance globalAppearance].centerOffset;
}

- (void)cyl_setBadgeCenterOffsetValue:(NSValue *)badgeCenterOffsetValue {
    //    [CYL_ACTUAL_BARBUTTON cyl_setBadgeCenterOffset:badgeCenterOffset];
    CGPoint badgeCenterOffset = badgeCenterOffsetValue.CGPointValue;
    [self cyl_setBadgeCenterOffset:badgeCenterOffset];
}

- (NSValue *)cyl_badgeCenterOffsetValue {
    return [NSValue valueWithCGPoint:[self cyl_badgeCenterOffset]];
}

//FIXME:  to delete ios27_ bug
- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOff {
    NSDictionary *cenerInfo = @{@"x" : @(badgeCenterOff.x), @"y" : @(badgeCenterOff.y)};
    objc_setAssociatedObject(self, @selector(cyl_badgeCenterOffset), cenerInfo, OBJC_ASSOCIATION_RETAIN);
    if ([self cyl_shouldUpdateBadgeSubviews]) {
        return;
    }
    // [CN] FIXME:  to delete 如果在这里提前初始化， 那么就会导致
    // [EN] FIXME:  to delete If it is initialized early here, it will cause
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    [self cyl_layoutBadgeAtTopRightCorner];
 }

//badgeRadiusKey

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    objc_setAssociatedObject(self, @selector(cyl_badgeRadius), @(badgeRadius), OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
}

- (void)cyl_setBadgeRadiusValue:(NSNumber *)cyl_badgeRadiusValue {
    CGFloat badgeRadius = [cyl_badgeRadiusValue doubleValue];
    [self cyl_setBadgeRadius:badgeRadius];
}

- (NSNumber *)cyl_badgeRadiusValue {
    return @([self cyl_badgeRadius]);
}

- (CGFloat)cyl_badgeRadius {
    NSNumber *badgeRadiusObject = objc_getAssociatedObject(self, @selector(cyl_badgeRadius));
    return badgeRadiusObject != nil ? [badgeRadiusObject doubleValue] : [CYLBadgeAppearance globalAppearance].radius;
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    objc_setAssociatedObject(self, @selector(cyl_badgeMargin), @(badgeMargin), OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
}

- (void)cyl_setBadgeMarginValue:(NSNumber *)cyl_badgeMarginValue {
    CGFloat badgeMargin = [cyl_badgeMarginValue doubleValue];
    [self cyl_setBadgeMargin:badgeMargin];
}

- (NSNumber *)cyl_badgeMarginValue {
    return @([self cyl_badgeMargin]);
}

- (CGFloat)cyl_badgeMargin {
    id margin = objc_getAssociatedObject(self, @selector(cyl_badgeMargin));
    return margin == nil ? [CYLBadgeAppearance globalAppearance].margin : [margin doubleValue];
}

- (NSInteger)cyl_badgeMaximumBadgeNumber {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeMaximumBadgeNumber));
    if(obj != nil && [obj isKindOfClass:[NSNumber class]]) {
        return [obj integerValue];
    }
    return [CYLBadgeAppearance globalAppearance].maximumBadgeNumber;
}

- (void)cyl_setBadgeMaximumBadgeNumber:(NSInteger)badgeMaximumBadgeNumber {
    NSNumber *numObj = @(badgeMaximumBadgeNumber);
    objc_setAssociatedObject(self, @selector(cyl_badgeMaximumBadgeNumber), numObj, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
}

- (void)cyl_setBadgeMaximumBadgeNumberValue:(NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    NSInteger badgeMaximumBadgeNumber = [cyl_badgeMaximumBadgeNumberValue integerValue];
    [self cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    return @([self cyl_badgeMaximumBadgeNumber]);
}

- (UIColor *)cyl_badgeBorderColor {
    return objc_getAssociatedObject(self, @selector(cyl_badgeBorderColor)) ?: [CYLBadgeAppearance globalAppearance].borderColor;
}

- (void)cyl_setBadgeBorderColor:(UIColor *)badgeBorderColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeBorderColor), badgeBorderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_applyBadgeBorder];
}

- (CGFloat)cyl_badgeBorderWidth {
    NSNumber *badgeBorderWidthObject = objc_getAssociatedObject(self, @selector(cyl_badgeBorderWidth));
    return badgeBorderWidthObject != nil ? [badgeBorderWidthObject doubleValue] : [CYLBadgeAppearance globalAppearance].borderWidth;
}

- (void)cyl_setBadgeBorderWidth:(CGFloat)badgeBorderWidth {
    CGFloat borderWidth = isfinite(badgeBorderWidth) ? MAX(0, badgeBorderWidth) : 0;
    objc_setAssociatedObject(self, @selector(cyl_badgeBorderWidth), @(borderWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_applyBadgeBorder];
}

- (BOOL)cyl_badgeRespectsReduceMotion {
    NSNumber *value = objc_getAssociatedObject(self, @selector(cyl_badgeRespectsReduceMotion));
    return value != nil ? value.boolValue : YES;
}

- (void)cyl_setBadgeRespectsReduceMotion:(BOOL)badgeRespectsReduceMotion {
    objc_setAssociatedObject(self, @selector(cyl_badgeRespectsReduceMotion), @(badgeRespectsReduceMotion), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)cyl_delayIfNeededForSeconds {
    NSNumber *delayIfNeededForSecondsObject = objc_getAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds));
    if (delayIfNeededForSecondsObject == nil) {
        return kCYLBadgeDefaultDelayIfNeededForSeconds;
    }
    return [delayIfNeededForSecondsObject doubleValue];
}

- (void)cyl_setDelayIfNeededForSeconds:(CGFloat)delayIfNeededForSeconds {
    // A negative or non-finite delay is meaningless; treat it as no delay.
    NSNumber *delayIfNeededForSecondsObject = @(isfinite(delayIfNeededForSeconds) ? MAX(0, delayIfNeededForSeconds) : 0);
    objc_setAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds), delayIfNeededForSecondsObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)cyl_delayIfNeededForSecondsValue {
    return @(self.cyl_delayIfNeededForSeconds);
}

- (void)cyl_setDelayIfNeededForSecondsValue:(NSNumber *)delayIfNeededForSecondsValue {
    [self cyl_setDelayIfNeededForSeconds:[delayIfNeededForSecondsValue doubleValue]];
}

- (BOOL)cyl_isHidden {
    return self.cyl_isInvisiable;
}

// [CN] 不管 image 还是 text 的 UIBarButtonItem 都获取内部的 _UIModernBarButton 即可
// [EN] For UIBarButtonItem, whether image or text, just get the inner _UIModernBarButton.
- (UIView *)cyl_findBarButtonContentView {
    NSString *classString = NSStringFromClass(self.class);
    if ([classString isEqualToString:@"UITabBarButton"] || [classString isEqualToString:@"_UITabButton"]) {
        // [CN] 特别的，对于 UITabBarItem，将 imageView 作为参考 view
        // [EN] In particular, for UITabBarItem, use the imageView as the reference view.
#if CYL_BADGE_CORE_AVAILABLE
        UIView *imageView = [self cyl_tabImageView];
        return imageView;
#else
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UIImageView class]]) {
                return subview;
            }
        }
        return self;
#endif
    }
    
    if ([classString isEqualToString:@"_UIButtonBarButton"]) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:UIButton.class]) {
                return subview;
            }
        }
    }
    
    return self;
}

- (Class)cyl_badgeClass {
    //    return [UILabel class];

    //    return [CYLTabBarBadgeView class];
    Class badgeClass = nil;
    if (!CYL_IS_IOS_27) {
        return [CYLBadgeLabel class];
    }
    BOOL isCYLTabBarStyleTypeLiquidGlass = [self cyl_isCYLTabBarStyleTypeLiquidGlass];
    
    
     
    if (isCYLTabBarStyleTypeLiquidGlass) {
        badgeClass = [CYLTabBarBadgeView class];
    } else {
#if CYL_FLATDESIGN_AVAILABLE
        badgeClass = [CYLBadgeLabel class];
#endif
    }
    return badgeClass;
}

- (BOOL)cyl_isCYLTabBarStyleTypeLiquidGlass {
    if (![CYLUtils isLiquidGlassActive]) {
        return NO;
    }
    return YES;
}

- (BOOL)cyl_shouldUpdateBadgeSubviews {
    
//    return YES;

    if (![CYLUtils isLiquidGlassActive]) {
        return NO;
    }
    if (CYL_IS_IOS_27 && ![self.cyl_badge isKindOfClass:[UILabel class]]) {
        return YES;
    }
    return YES;
}

@end

