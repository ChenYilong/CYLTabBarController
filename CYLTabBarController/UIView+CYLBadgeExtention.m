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
#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"
#import "UIView+CYLTabBarControllerExtention.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "CYLBadge/CYLTabBarBadgeView.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

#if CYL_FLATDESIGN_AVAILABLE
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#endif


#define kCYLBadgeDefaultMaximumBadgeNumber 99
#define kCYLBadgeDefaultMargin (8.0)

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

- (id)cyl_getActualBadgeSuperView {
    //建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame.自动布局 cell 需要调用 [self layoutIfNeeded] frame才有值，角标才能找到对应的位置。 需要确保view showBadge的方法 在layoutIfNeeded之后调用
    [self layoutIfNeeded];
    return self;
}


- (void)cyl_performSelector:(SEL)aSelector {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 {
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
    self.cyl_badge.isAccessibilityElement = NO;
    [self cyl_applyBadgeBorder];
    [self.cyl_badge cyl_setHidden:NO];
}

- (void)cyl_showNewBadge:(NSString *)value {
    if (![self cyl_badgeClass]) {
        return;
    }
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
    self.cyl_badge.isAccessibilityElement = YES;
    self.cyl_badge.accessibilityLabel = value;
    [self cyl_applyBadgeBorder];
    [self.cyl_badge cyl_setHidden:NO];
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
    if (self.cyl_badgeBackgroundColor == nil) {
        self.cyl_badgeBackgroundColor = [UIColor redColor];
    }
    if (self.cyl_badgeTextColor == nil) {
        self.cyl_badgeTextColor = [UIColor whiteColor];
    }
    
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
    }
}

- (void)cyl_bringBadgeToFront:(UIView *)view {
    if (![self cyl_isReady]) {
        return;
    }
    [self addSubview:view];
    [self bringSubviewToFront:view];
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
    //更新frame
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
    if (!badge || badge.superview != self) {
        return;
    }
    [self bringSubviewToFront:badge];
    [self cyl_layoutBadgeAtTopRightCorner];
    [self cyl_badgeEnvironmentDidChange];
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
    //获得子视图的Label以获得字符长度。用以拉伸父视图
    //UILabel 与 CYLTabBarBadgeView 没有继承关系，各自检查类型后再向下转换（两者都是 UIView 的子类）。
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
//    获得字符长度后， 需要修改父视图的宽度， 仅仅修改Label无法达到真正的拉伸效果
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

/*!
 * FIX: issue #583, #271
 * [EN] The badge's Shake and Bounce animations (`+cyl_shake_AnimationRepeatTimes:…`, `+cyl_bounce_AnimationRepeatTimes:…`)
 *      kept the default `removedOnCompletion = YES`, unlike Breathe and Scale. Core Animation removes such animations when
 *      the app goes to the background, so after returning a badge with text stopped shaking/bouncing. Keep them. Set here,
 *      not in those public factories, so apps that use the factories themselves see no change.
 *      Scope: every badge, whatever the tab bar style (classic, iOS 26 UI compatibility mode, Liquid Glass on iOS 26+ and
 *      the iPhone Duo, FlatDesign): they all share this code, and the problem does not depend on the style. No style check
 *      on purpose: looking up the tab bar controller from a badge finds the root one, which can be the wrong one with
 *      nested tab bar controllers.
 * [CN] 角标的 Shake、Bounce 动画（`+cyl_shake_AnimationRepeatTimes:…`、`+cyl_bounce_AnimationRepeatTimes:…`）与 Breathe、Scale 不同，
 *      保留了默认的 `removedOnCompletion = YES`。App 进入后台时 Core Animation 会移除这类动画，回到前台后带文字的角标不再抖动/弹跳。
 *      这里将其保留。在此处设置而不修改这两个公开的工厂方法，App 自行使用这些方法时行为不变。
 *      范围：所有角标，与 TabBar 样式无关（经典、iOS 26 UI 兼容模式、iOS 26+ 液态玻璃与 iPhone Duo、扁平样式）：它们共用这段代码，
 *      且该问题与样式无关。有意不判断样式：从角标查找 TabBarController 会找到根控制器，嵌套 TabBarController 时可能找错。
 */
- (void)cyl_keepBadgeAnimationAfterBackground:(CAAnimation *)animation {
    animation.removedOnCompletion = NO;
}

//if u want to add badge animation type, follow steps bellow:
//1. go to definition of CYLBadgeAnimationType and add new type, with its key (see the note above the keys in
//   CYLBadgeProtocol.h: CYLBadgeAnimationKeyForType, CYLBadgeAnimationTypeRepeats, CYLBadgeAllAnimationKeys)
//2. go to category of CAAnimation+CYLBadgeExtention to add new animation interface
//3. call that new interface here
- (void)cyl_beginAnimation {
    CGFloat moveDistance = self.cyl_badge.frame.size.width * 1.5;
    if (!self.cyl_badge) {
        return;
    }
    // Replace, don't stack: showing a value with another animation type used to add it on top of the previous one.
    [self cyl_removeBadgeAnimations];
    if ([self cyl_shouldReduceBadgeMotion]) {
        return;
    }
    switch(self.cyl_badgeAnimationType) {
        case CYLBadgeAnimationTypeBreathe:
            [self.cyl_badge.layer addAnimation:[CAAnimation cyl_opacityForeverAnimationWithDuration:1.4]
                                        forKey:CYLBadgeBreatheAnimationKey];
            break;
        case CYLBadgeAnimationTypeShake: {
            // Relative (`transform.translation.x`), so the anchored badge can still move with its host while shaking;
            // `-cyl_shake_AnimationRepeatTimes:…` animated `position` and pinned it to where it was. Same amplitude.
            CAAnimation *animation = [CAAnimation cyl_shakeAnimationRepeatTimes:HUGE_VALF
                                                                       duration:1
                                                                         offset:CGRectGetWidth(self.cyl_badge.bounds) / 4];
            [self cyl_keepBadgeAnimationAfterBackground:animation];
            [self.cyl_badge.layer addAnimation:animation forKey:CYLBadgeShakeAnimationKey];
            break;
        }
        case CYLBadgeAnimationTypeScale:
            [self.cyl_badge.layer addAnimation:[CAAnimation cyl_scaleAnimationFromScale:1.4
                                                                  toScale:0.6
                                                                 duration:1
                                                              repeatTimes:MAXFLOAT]
                                        forKey:CYLBadgeScaleAnimationKey];
            break;
        case CYLBadgeAnimationTypeBounce: {
            // Relative (`transform.translation.y`), see Shake. Same amplitude.
            CAAnimation *animation = [CAAnimation cyl_bounceAnimationRepeatTimes:HUGE_VALF
                                                                        duration:1
                                                                          offset:CGRectGetHeight(self.cyl_badge.bounds) / 4];
            [self cyl_keepBadgeAnimationAfterBackground:animation];
            [self.cyl_badge.layer addAnimation:animation forKey:CYLBadgeBounceAnimationKey];
            break;
        }
            
            
            /*!
             *
             
             
             
             
             
             
             
             
             */
        case CYLBadgeAnimationTypeLeftRightOnce:        /* left to right animation*/
            
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_leftRight_AnimationMoveDistance:moveDistance
                                                             repeatTimes:1
                                                                duration:0.5]
                                        forKey:CYLBadgeLeftRightOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeRightLeftOnce:        /* right to left animation*/
            
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_rightLeft_AnimationMoveDistance:moveDistance
                                                             repeatTimes:1
                                                                duration:0.5]
                                        forKey:CYLBadgeRightLeftOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeFadeInOnce:           /* fade in animation */
            
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_fadeIn_AnimationRepeatTimes:1
                                                            duration:1.5]
                                        forKey:CYLBadgeFadeInOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeRollingOnce:           /*rolling animation*/
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_rolling_AnimationRepeatTimes:1
                                                             duration:0.5]
                                        forKey:CYLBadgeRollingOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeScaleOnce:           /*ScaleOnce animation*/
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_scale_AnimationRepeatTimes:1
                                                           duration:0.5]
                                        forKey:CYLBadgeScaleOnceAnimationKey];
            
            
            break;
            
            
            
        case CYLBadgeAnimationTypeNone:
        default:
            
            break;
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
    return font ?: kCYLBadgeDefaultFont;
}

- (void)cyl_setBadgeFont:(UIFont *)badgeFont {
    objc_setAssociatedObject(self, @selector(cyl_badgeFont), badgeFont, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.font = badgeFont;
}

- (UIColor *)cyl_badgeBackgroundColor {
    return objc_getAssociatedObject(self, @selector(cyl_badgeBackgroundColor));
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeBackgroundColor), badgeBackgroundColor, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.backgroundColor = badgeBackgroundColor;
}

- (UIColor *)cyl_badgeTextColor {
    return objc_getAssociatedObject(self, @selector(cyl_badgeTextColor));
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeTextColor), badgeTextColor, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.textColor = badgeTextColor;
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
    return [badgeCornerRadiusObject doubleValue];
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
    return CGPointZero;
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
    //FIXME:  to delete 如果在这里提前初始化， 那么就会导致
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
    return [objc_getAssociatedObject(self, @selector(cyl_badgeRadius)) doubleValue];
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
    return margin == nil ? kCYLBadgeDefaultMargin : [margin doubleValue];
}

- (NSInteger)cyl_badgeMaximumBadgeNumber {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeMaximumBadgeNumber));
    if(obj != nil && [obj isKindOfClass:[NSNumber class]]) {
        return [obj integerValue];
    }
    return kCYLBadgeDefaultMaximumBadgeNumber;
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
    return objc_getAssociatedObject(self, @selector(cyl_badgeBorderColor));
}

- (void)cyl_setBadgeBorderColor:(UIColor *)badgeBorderColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeBorderColor), badgeBorderColor, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_applyBadgeBorder];
}

- (CGFloat)cyl_badgeBorderWidth {
    return [objc_getAssociatedObject(self, @selector(cyl_badgeBorderWidth)) doubleValue];
}

- (void)cyl_setBadgeBorderWidth:(CGFloat)badgeBorderWidth {
    CGFloat borderWidth = isfinite(badgeBorderWidth) ? MAX(0, badgeBorderWidth) : 0;
    objc_setAssociatedObject(self, @selector(cyl_badgeBorderWidth), @(borderWidth), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_applyBadgeBorder];
}

- (BOOL)cyl_badgeRespectsReduceMotion {
    NSNumber *value = objc_getAssociatedObject(self, @selector(cyl_badgeRespectsReduceMotion));
    return value ? value.boolValue : YES;
}

- (void)cyl_setBadgeRespectsReduceMotion:(BOOL)badgeRespectsReduceMotion {
    objc_setAssociatedObject(self, @selector(cyl_badgeRespectsReduceMotion), @(badgeRespectsReduceMotion), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)cyl_delayIfNeededForSeconds {
    NSNumber *delayIfNeededForSecondsObject = objc_getAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds));
    if (!delayIfNeededForSecondsObject) {
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

- (BOOL)cyl_isInvisiable {
    BOOL isSizeZero = CGSizeEqualToSize(CGSizeZero, self.frame.size);
    //这里删除(NO == obj.opaque) ，因为iOS27以上的视图，渲染会通过通过 opaque 设置为 NO 进行，所以这里删除涉及关于 opaque 的判断。
    BOOL isInvisible = (YES == self.hidden ) || (self.alpha <= 0.01f)  || (!self.superview) || isSizeZero;
    return isInvisible;
}

- (BOOL)cyl_canNotResponseEvent {
    return self.cyl_isInvisiable || (NO == self.userInteractionEnabled ) || self.cyl_isPlaceholder;
}

// 不管 image 还是 text 的 UIBarButtonItem 都获取内部的 _UIModernBarButton 即可
- (UIView *)cyl_findBarButtonContentView {
    NSString *classString = NSStringFromClass(self.class);
    if ([classString isEqualToString:@"UITabBarButton"] || [classString isEqualToString:@"_UITabButton"]) {
        // 特别的，对于 UITabBarItem，将 imageView 作为参考 view
        UIView *imageView = [self cyl_tabImageView];
        return imageView;
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
    if (![CYLConstants isLiquidGlassActive]) {
        return NO;
    }
    return YES;
}

- (BOOL)cyl_shouldUpdateBadgeSubviews {
    
//    return YES;

    if (![CYLConstants isLiquidGlassActive]) {
        return NO;
    }
    if (CYL_IS_IOS_27 && ![self.cyl_badge isKindOfClass:[UILabel class]]) {
        return YES;
    }
    return YES;
}

@end

