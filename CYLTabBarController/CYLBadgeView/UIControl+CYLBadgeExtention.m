/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "UIControl+CYLBadgeExtention.h"
#import <objc/runtime.h>
#import "CYLBadgeProtocol.h"
#import "CYLBadgeViewDefines.h"

/*!
 * FIX: issue #535
 * [EN] This category puts a tab button's badge on its icon (image or Lottie view) and mirrors it to the Liquid Glass
 *      platter, which needs Core. Without Core (`pod 'CYLTabBarController/CYLBadgeView'`) it is left out, and every
 *      `UIControl`, e.g. a `UIButton`, uses the `UIView (CYLBadgeExtention)` implementation: the badge goes on the
 *      control itself.
 * [CN] 该分类把 Tab 按钮的角标放在图标（图片或 Lottie 视图）上，并同步到液态玻璃 platter，这些都依赖 Core。没有 Core 时
 *      （`pod 'CYLTabBarController/CYLBadgeView'`）不编译该分类，所有 `UIControl`（例如 `UIButton`）使用
 *      `UIView (CYLBadgeExtention)` 的实现，角标显示在控件本身上。
 */
#if CYL_BADGE_CORE_AVAILABLE

#define kActualView ((UIView *)[self cyl_getActualBadgeSuperView])
#define CYL_ACTUAL_BARBUTTON kActualView

@implementation UIControl (CYLBadgeExtention) 

- (void)cyl_setBadgeValue:(NSString *)badgeValue {
    CYL_DEPRECATED_DECLARATIONS_PUSH
    
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     // [CN] 不再必须， 因此， 并非核心逻辑， 未来考虑删除。
     // [EN] No longer required, so this is not core logic; may be removed in the future.
     if (self && [self respondsToSelector:@selector(cyl_removeTabBadgePoint)]) {
         [self cyl_removeTabBadgePoint];
     }
     );
    
    
    CYL_DEPRECATED_DECLARATIONS_POP
    
    [self cyl_clearBadge];
    // FIX: this used to call itself and never return. 之前这里调用自身，导致无限递归。
    [self cyl_showBadgeValue:badgeValue animationType:CYLBadgeAnimationTypeNone];
}

- (void)cyl_setBadgeAnimationTypeValue:(NSNumber *)cyl_badgeAnimationTypeValue {
    CYLBadgeAnimationType badgeAnimationType = [cyl_badgeAnimationTypeValue integerValue];
    [self cyl_setBadgeAnimationType:badgeAnimationType];
}

// Bridge getters for KVC/KVO compliance if accessed as properties
- (NSNumber *)cyl_badgeAnimationTypeValue {
    return @(self.cyl_badgeAnimationType);
}

- (NSValue *)cyl_badgeCenterOffsetValue {
    return [NSValue valueWithCGPoint:self.cyl_badgeCenterOffset];
}

- (NSNumber *)cyl_badgeCornerRadiusValue {
    return @(self.cyl_badgeCornerRadius);
}

- (NSValue *)cyl_badgeFrameValue {
    return [NSValue valueWithCGRect:self.cyl_badgeFrame];
}

- (NSNumber *)cyl_badgeMarginValue {
    return @(self.cyl_badgeMargin);
}

- (NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    return @(self.cyl_badgeMaximumBadgeNumber);
}

- (NSNumber *)cyl_badgeRadiusValue {
    return @(self.cyl_badgeRadius);
}

// delayIfNeededForSeconds getter/setter to satisfy warnings
- (NSTimeInterval)cyl_delayIfNeededForSeconds {
    // Default to 0 if not managed elsewhere; adjust if there is a backing store
    NSNumber *value = objc_getAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds));
    return value != nil ? value.doubleValue : 0;
}

- (void)cyl_setDelayIfNeededForSeconds:(NSTimeInterval)seconds {
    objc_setAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds), @(seconds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)cyl_delayIfNeededForSecondsValue {
    return @(self.cyl_delayIfNeededForSeconds);
}

- (void)cyl_setDelayIfNeededForSecondsValue:(NSNumber *)delayIfNeededForSecondsValue {
    [self cyl_setDelayIfNeededForSeconds:[delayIfNeededForSecondsValue doubleValue]];
}

#pragma mark -- public methods

/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
- (void)cyl_showBadge {
    [CYL_ACTUAL_BARBUTTON cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeNone];
}

- (void)cyl_showBadgeValue:(NSString *)value animationType:(CYLBadgeAnimationType)animationType {
    [CYL_ACTUAL_BARBUTTON cyl_showBadgeValue:value animationType:animationType];
}

- (BOOL)cyl_isShowBadge {
    return [CYL_ACTUAL_BARBUTTON cyl_isShowBadge];
}

- (BOOL)cyl_isPauseBadge {
    return [CYL_ACTUAL_BARBUTTON cyl_isPauseBadge];
}

/**
 *  clear badge
 */
- (void)cyl_clearBadge {
    [CYL_ACTUAL_BARBUTTON cyl_clearBadge];
}

- (void)cyl_resumeBadge {
    [CYL_ACTUAL_BARBUTTON cyl_resumeBadge];
}

- (void)cyl_refreshBadge {
    [CYL_ACTUAL_BARBUTTON cyl_refreshBadge];
}

#pragma mark -- private method

- (UIView *)cyl_getActualBadgeSuperViewFromControl:(UIControl *)tabButton {
    return [tabButton cyl_getActualBadgeSuperView];
}
/**
 *  Because UIBarButtonItem is kind of NSObject, it is not able to directly attach badge.
 This method is used to find actual view (non-nil) inside UIBarButtonItem instance.
 *
 *  @return view
 */
- (UIView *)cyl_getActualBadgeSuperView {
    // badge label will be added onto imageView
    //只有在TabBar选中状态下才能取到SwappableImageView
    UIControl *tabButton = self;
    UIImageView *tabImageView = [tabButton cyl_tabImageView];
    UIView *lottieAnimationView = (UIView *)tabButton.cyl_lottieAnimationView;
    
    UIView *actualBadgeSuperView = nil;
    
    do {
        // [EN] Issue #601: an icon hidden for the view shown in its place still takes the badge.
        // [CN] 被替换显示而隐藏的图标仍承载角标。
        if (lottieAnimationView && (!lottieAnimationView.cyl_isInvisiable || lottieAnimationView.cyl_isBadgeHostReplacedByIconView)) {
            actualBadgeSuperView = lottieAnimationView;

            break;
        }
        if (tabImageView && (!tabImageView.cyl_isInvisiable || tabImageView.cyl_isBadgeHostReplacedByIconView)) {
            actualBadgeSuperView = tabImageView;

            break;
        }
    } while (NO);
    // By class name: `-cyl_isTabButton` is YES for every UIControl before iOS 26. UITabBarButton, _UITabButton and
    // CYLFlatDesignTabBarButton are tab buttons. 按类名判断：iOS 26 以前 `-cyl_isTabButton` 对所有 UIControl 都返回 YES。
    NSString *controlClassName = NSStringFromClass(tabButton.class);
    BOOL isTabBarButton = [controlClassName containsString:@"TabButton"] || [controlClassName containsString:@"TabBarButton"];
    if (!isTabBarButton) {
        /*!
         * FIX: badges of plus buttons and other controls were covered or clipped
         * [EN] The badge of a control that is not a tab button (a plus button, any UIButton) went inside its icon. That
         *      view can lie under the control's other content: a UIButton with a configuration draws its image above
         *      the first image view found, so the plus button's "+" covered most of its badge. It also changed the
         *      icon's `clipsToBounds`. The badge now goes on a transparent anchor that is the control's top-most
         *      subview (zPosition MAXFLOAT, so content the control adds later stays below it), aligned to the icon or,
         *      without one, to the whole control: it is always drawn above everything in the control, at the icon's
         *      top-right corner as before. When the control clips (clipsToBounds, masksToBounds or a mask), the anchor
         *      goes right above the control in its superview instead, so the clipping does not cut the badge. Tab
         *      buttons are unchanged.
         * [CN] 非 Tab 按钮的控件（PlusButton、任意 UIButton）的角标原先放在其图标视图中。该视图可能位于控件其他内容之下：使用
         *      configuration 的 UIButton 会在找到的第一个图片视图之上绘制图片，因此 PlusButton 的「+」遮住了大部分角标；原逻辑还会
         *      修改图标的 `clipsToBounds`。现在角标放在一个透明的锚点视图上，它是控件最上层的子视图（zPosition 为 MAXFLOAT，控件之后
         *      添加的内容也位于其下），与图标对齐，没有图标时与整个控件对齐：角标总是绘制在控件所有内容之上，位置仍在图标右上角。
         *      控件本身会裁剪（clipsToBounds、masksToBounds 或 mask）时，锚点改为放在父视图中、紧贴控件之上，角标不再被裁剪。
         *      Tab 按钮不变。
         */
        return [tabButton cyl_badgeAnchorViewAlignedToView:actualBadgeSuperView];
    }
    if (actualBadgeSuperView) {
        [actualBadgeSuperView setClipsToBounds:NO];
        // [CN] 建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame.自动布局 cell 需要调用 [self layoutIfNeeded] frame才有值，角标才能找到对应的位置。 需要确保view showBadge的方法 在layoutIfNeeded之后调用
        // [EN] It is recommended to call layoutIfNeeded after the autolayout code before trying to read the frame.
        //      Auto layout cells
        //      need [self layoutIfNeeded] for the frame to have a value, so the badge can find its position.
        //      Make sure the view's showBadge method is called after layoutIfNeeded
        [actualBadgeSuperView layoutIfNeeded];// [CN] 建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame
        // [EN] It is recommended to call layoutIfNeeded after the autolayout code before trying to read the frame
    }

    return actualBadgeSuperView;
}

/// The transparent view that holds the badge of a control that is not a tab button, aligned to `referenceView` (the
/// icon) or to the whole control. 承载非 Tab 按钮控件角标的透明视图，与 `referenceView`（图标）或整个控件对齐。
- (UIView *)cyl_badgeAnchorViewAlignedToView:(UIView *)referenceView {
    UIView *anchorView = objc_getAssociatedObject(self, @selector(cyl_badgeAnchorViewAlignedToView:));
    if (!anchorView) {
        anchorView = [[UIView alloc] initWithFrame:self.bounds];
        anchorView.backgroundColor = UIColor.clearColor;
        anchorView.userInteractionEnabled = NO;
        anchorView.clipsToBounds = NO;
        anchorView.isAccessibilityElement = NO;
        anchorView.translatesAutoresizingMaskIntoConstraints = NO;
        objc_setAssociatedObject(self, @selector(cyl_badgeAnchorViewAlignedToView:), anchorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    BOOL controlClips = self.clipsToBounds || self.layer.masksToBounds || self.layer.mask;
    UIView *container = (controlClips && self.superview) ? self.superview : self;
    if (container == self) {
        if (anchorView.superview != self) {
            [anchorView removeFromSuperview];
            [self addSubview:anchorView];
        }
        [self bringSubviewToFront:anchorView];
        anchorView.layer.zPosition = MAXFLOAT;
    } else {
        if (anchorView.superview != container) {
            [anchorView removeFromSuperview];
        }
        [container insertSubview:anchorView aboveSubview:self];
        anchorView.layer.zPosition = self.layer.zPosition;
        anchorView.hidden = self.hidden;
        anchorView.alpha = self.alpha;
    }
    UIView *target = (referenceView && referenceView != anchorView) ? referenceView : self;
    NSArray<NSLayoutConstraint *> *constraints = objc_getAssociatedObject(anchorView, @selector(cyl_badgeAnchorViewAlignedToView:));
    BOOL isPinnedToTarget = constraints.count > 0 && constraints.firstObject.active && constraints.firstObject.secondItem == target;
    if (!isPinnedToTarget) {
        [NSLayoutConstraint deactivateConstraints:constraints ?: @[]];
        // Constraints keep the anchor on the icon as the control lays out again. 约束让锚点在控件重新布局后仍与图标对齐。
        constraints = @[
            [anchorView.leadingAnchor constraintEqualToAnchor:target.leadingAnchor],
            [anchorView.topAnchor constraintEqualToAnchor:target.topAnchor],
            [anchorView.widthAnchor constraintEqualToAnchor:target.widthAnchor],
            [anchorView.heightAnchor constraintEqualToAnchor:target.heightAnchor],
        ];
        [NSLayoutConstraint activateConstraints:constraints];
        objc_setAssociatedObject(anchorView, @selector(cyl_badgeAnchorViewAlignedToView:), constraints, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    // Right away too, so the badge can be laid out before the next layout pass. 同时立即设置 frame，角标无需等到下一次布局。
    anchorView.frame = [target convertRect:target.bounds toView:container];
    return anchorView;
}

- (void)cyl_performSelector:(SEL)aSelector {
    if (aSelector == NULL) { return; }
    NSObject *obj = nil;
    [self cyl_performSelector:aSelector withObject:obj];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(nullable id)object {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(nullable id)object1 withObject:(nullable id)object2 {
    if (aSelector == NULL) { return; }
    UIControl *normalControl = nil;
    UIControl *selectedControl = nil;
    if (![self isKindOfClass:[UIControl class]] || ![CYLUtils isLiquidGlassActive]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         [self performSelector:aSelector withObject:object1 withObject:object2];
         )
        return;
    }
    if ([self cyl_isPlatterSelectedControl]) {
        selectedControl = self;
    } else {
        normalControl = self;
    }
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     if (normalControl) {
         [normalControl performSelector:aSelector withObject:object1 withObject:object2];
         UIControl *counterpart = normalControl.cyl_platterSelectedControl;
         if (counterpart) {
             [counterpart performSelector:aSelector withObject:object1 withObject:object2];
         }
     } else if (selectedControl) {
         [selectedControl performSelector:aSelector withObject:object1 withObject:object2];
         UIControl *counterpart = selectedControl.cyl_platterNormalControl;
         if (counterpart) {
             [counterpart performSelector:aSelector withObject:object1 withObject:object2];
         }
     }
     );
}
 
- (BOOL)cyl_isReady {
    if (![CYLUtils isLiquidGlassActive]) {
        return YES;
    }
    // [CN] 由于 SelectedControl 所在图层的渲染比未选中图层有延迟， 所以必须加延迟，如果不加延迟，可能无法获取到正确的子视图， 有概率获取的子视图为nil
    //由于有几率无法获取到cyl_tabImageView， 只有延迟获取，才能避免获取为空nil。
    // [EN] Because the layer of the SelectedControl renders later than the unselected layer, a delay is
    //      required. Without it
    //      the correct subview may not be obtained, and the subview may sometimes be nil
    //      cyl_tabImageView sometimes cannot be obtained; only fetching it after a delay avoids getting nil.
    
    UIView *view = self.cyl_platterSelectedControl.cyl_tabImageView;
    if (!view) {
        return NO;
    }
    BOOL isTabImageViewReady = self.cyl_tabImageView.frame.size.width > 10 || self.cyl_tabLabel.frame.size.width > 10;
    BOOL isLottieReady = YES;
    if (self.cyl_tabBarController.lottieURLs.count > 0) {
        isLottieReady = self.cyl_isLottieReady;
    }
    return isTabImageViewReady && isLottieReady;
}

#pragma mark -- setter/getter
- (UIView<CYLBadgeTextDisplaying> *)cyl_badge {
    return CYL_ACTUAL_BARBUTTON.cyl_badge;
}

- (void)cyl_setBadge:(UIView<CYLBadgeTextDisplaying> *)label {
    [CYL_ACTUAL_BARBUTTON cyl_setBadge:label];
}

- (UIFont *)cyl_badgeFont {
    return CYL_ACTUAL_BARBUTTON.cyl_badgeFont;
}

- (void)cyl_setBadgeFont:(UIFont *)badgeFont {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeFont:badgeFont];
}

- (UIColor *)cyl_badgeBackgroundColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeBackgroundColor];
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeBackgroundColor:badgeBackgroundColor];
}

- (UIColor *)cyl_badgeTextColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeTextColor];
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeTextColor:badgeTextColor];
}

- (CYLBadgeAnimationType)cyl_badgeAnimationType {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeAnimationType];
}

- (void)cyl_setBadgeAnimationType:(CYLBadgeAnimationType)animationType {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeAnimationType:animationType];
}

// The badge lives on the actual badge super view (tab image / Lottie view), like the properties above.
- (UIColor *)cyl_badgeBorderColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeBorderColor];
}

- (void)cyl_setBadgeBorderColor:(UIColor *)badgeBorderColor {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeBorderColor:badgeBorderColor];
}

- (CGFloat)cyl_badgeBorderWidth {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeBorderWidth];
}

- (void)cyl_setBadgeBorderWidth:(CGFloat)badgeBorderWidth {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeBorderWidth:badgeBorderWidth];
}

- (BOOL)cyl_badgeRespectsReduceMotion {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeRespectsReduceMotion];
}

- (void)cyl_setBadgeRespectsReduceMotion:(BOOL)badgeRespectsReduceMotion {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeRespectsReduceMotion:badgeRespectsReduceMotion];
}

- (CGRect)cyl_badgeFrame {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeFrame];
}

- (void)cyl_setBadgeFrame:(CGRect)badgeFrame {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeFrame:badgeFrame];
}

- (void)cyl_setBadgeFrameValue:(NSValue *)cyl_badgeFrameValue {
    CGRect badgeFrame = cyl_badgeFrameValue.CGRectValue;
    [self cyl_setBadgeFrame:badgeFrame];
}

- (CGPoint)cyl_badgeCenterOffset {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCenterOffset];
}

- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOffset {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeCenterOffset:badgeCenterOffset];
}

- (void)cyl_setBadgeCenterOffsetValue:(NSValue *)badgeCenterOffsetValue {
//    [CYL_ACTUAL_BARBUTTON cyl_setBadgeCenterOffset:badgeCenterOffset];
    CGPoint badgeCenterOffset = badgeCenterOffsetValue.CGPointValue;
    [self cyl_setBadgeCenterOffset:badgeCenterOffset];
}
- (NSInteger)cyl_badgeMaximumBadgeNumber {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeMaximumBadgeNumber];
}

- (void)cyl_setBadgeMaximumBadgeNumber:(NSInteger)badgeMaximumBadgeNumber {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (void)cyl_setBadgeMaximumBadgeNumberValue:(NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    NSInteger badgeMaximumBadgeNumber = [cyl_badgeMaximumBadgeNumberValue integerValue];
    [self cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (CGFloat)cyl_badgeMargin {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeMargin];
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeMargin:badgeMargin];
}

- (void)cyl_setBadgeMarginValue:(NSNumber *)cyl_badgeMarginValue {
    CGFloat badgeMargin = [cyl_badgeMarginValue doubleValue];
    [self cyl_setBadgeMargin:badgeMargin];
}

- (CGFloat)cyl_badgeRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeRadius];
}

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeRadius:badgeRadius];
}

- (void)cyl_setBadgeRadiusValue:(NSNumber *)cyl_badgeRadiusValue {
    CGFloat badgeRadius = [cyl_badgeRadiusValue doubleValue];
    [self cyl_setBadgeRadius:badgeRadius];
}

- (CGFloat)cyl_badgeCornerRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCornerRadius];
}

- (void)cyl_setBadgeCornerRadius:(CGFloat)cyl_badgeCornerRadius {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}

- (void)cyl_setBadgeCornerRadiusValue:(NSNumber *)cyl_badgeCornerRadiusValue {
    CGFloat cyl_badgeCornerRadius = [cyl_badgeCornerRadiusValue doubleValue];
    [self cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}

@end

#endif /* CYL_BADGE_CORE_AVAILABLE */
