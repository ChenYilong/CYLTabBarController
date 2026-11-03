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
     // 不再必须， 因此， 并非核心逻辑， 未来考虑删除。
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
        if (lottieAnimationView && !lottieAnimationView.cyl_isInvisiable) {
            actualBadgeSuperView = lottieAnimationView;

            break;
        }
        if (tabImageView && !tabImageView.cyl_isInvisiable) {
            actualBadgeSuperView = tabImageView;

            break;
        }
    } while (NO);
    // FIX: a control that is not a tab button and has no visible icon (e.g. a plus button drawn with a background
    // image only) used to get no badge at all. Its badge now goes on a transparent view that fills it, so the badge sits
    // at the control's top-right corner like a tab icon's. Tab buttons are unchanged: they wait for their icon.
    // 不是 Tab 按钮且没有可见图标的控件（例如只设置了背景图的 PlusButton）原先无法显示角标；现在角标放在一个铺满控件的透明视图上，
    // 位于控件右上角，与 Tab 图标的角标一致。Tab 按钮不变，仍等待其图标。
    // By class name: `-cyl_isTabButton` is YES for every UIControl before iOS 26. UITabBarButton, _UITabButton and
    // CYLFlatDesignTabBarButton are tab buttons. 按类名判断：iOS 26 以前 `-cyl_isTabButton` 对所有 UIControl 都返回 YES。
    NSString *controlClassName = NSStringFromClass(tabButton.class);
    BOOL isTabBarButton = [controlClassName containsString:@"TabButton"] || [controlClassName containsString:@"TabBarButton"];
    if (!actualBadgeSuperView && !isTabBarButton) {
        actualBadgeSuperView = [tabButton cyl_badgeAnchorView];
    }
    if (actualBadgeSuperView) {
        [actualBadgeSuperView setClipsToBounds:NO];
        //建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame.自动布局 cell 需要调用 [self layoutIfNeeded] frame才有值，角标才能找到对应的位置。 需要确保view showBadge的方法 在layoutIfNeeded之后调用
        [actualBadgeSuperView layoutIfNeeded];//建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame
    }

    return actualBadgeSuperView;
}

/// A transparent view that fills the control and holds its badge when the control has no icon. 控件没有图标时承载角标的透明视图，铺满控件。
- (UIView *)cyl_badgeAnchorView {
    UIView *anchorView = objc_getAssociatedObject(self, @selector(cyl_badgeAnchorView));
    if (!anchorView) {
        anchorView = [[UIView alloc] initWithFrame:self.bounds];
        anchorView.backgroundColor = UIColor.clearColor;
        anchorView.userInteractionEnabled = NO;
        anchorView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        objc_setAssociatedObject(self, @selector(cyl_badgeAnchorView), anchorView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    if (anchorView.superview != self) {
        [self addSubview:anchorView];
    }
    anchorView.frame = self.bounds;
    [self bringSubviewToFront:anchorView];
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
    //由于 SelectedControl 所在图层的渲染比未选中图层有延迟， 所以必须加延迟，如果不加延迟，可能无法获取到正确的子视图， 有概率获取的子视图为nil
    //由于有几率无法获取到cyl_tabImageView， 只有延迟获取，才能避免获取为空nil。
    
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
