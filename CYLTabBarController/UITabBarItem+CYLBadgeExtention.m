/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "UITabBarItem+CYLBadgeExtention.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>
#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import "CYLBadgeProtocol.h"

#define kActualView ((UIView *)[self cyl_getActualBadgeSuperView])
#define CYL_ACTUAL_BARBUTTON kActualView

@implementation UITabBarItem (CYLBadgeExtention) 

- (void)cyl_setBadgeValue:(NSString *)badgeValue {
    [self.cyl_tabButton cyl_removeTabBadgePoint];
    [self cyl_clearBadge];
    [self cyl_setBadgeValue:badgeValue];
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
    return value ? value.doubleValue : 0;
}

- (void)cyl_setDelayIfNeededForSeconds:(NSTimeInterval)seconds {
    objc_setAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds), @(seconds), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    self.cyl_tabButton.cyl_tabBadgeView.hidden = YES;
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
    self.cyl_tabButton.cyl_tabBadgeView.hidden = NO;
}

- (void)cyl_resumeBadge {
    [CYL_ACTUAL_BARBUTTON cyl_resumeBadge];
    self.cyl_tabButton.cyl_tabBadgeView.hidden = YES;
}

#pragma mark -- private method

/**
 *  Because UIBarButtonItem is kind of NSObject, it is not able to directly attach badge.
 This method is used to find actual view (non-nil) inside UIBarButtonItem instance.
 *
 *  @return view
 */
- (UIView *)cyl_getActualBadgeSuperView {
    UIControl *tabButton = [self cyl_tabButton];
    return [self cyl_getActualBadgeSuperViewFromControl:tabButton];
}

- (UIView *)cyl_getActualBadgeSuperViewFromControl:(UIControl *)tabButton {
    // badge label will be added onto imageView
    //只有在TabBar选中状态下才能取到SwappableImageView
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
    if (actualBadgeSuperView) {
        [actualBadgeSuperView setClipsToBounds:NO];
    }
    return actualBadgeSuperView;
}

- (void)cyl_performSelector:(SEL)aSelector {
    if (aSelector == NULL) { return; }
    [self cyl_performSelector:aSelector withObject:nil];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object {
    if (aSelector == NULL) { return; }
    [self cyl_performSelector:aSelector withObject:object withObject:nil];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 {
    if (aSelector == NULL) { return; }
    UIControl *normalControl = nil;
    UIControl *selectedControl = nil;
    
    UIControl *selfControl = [self cyl_tabButton];
    if (![selfControl isKindOfClass:[UIControl class]]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         [selfControl performSelector:aSelector withObject:object1 withObject:object2];
         )
        return;
    }
    if ([selfControl cyl_isPlatterSelectedControl]) {
        selectedControl = selfControl;
    } else {
        normalControl = selfControl;
    }
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     if (normalControl) {
         
         UIView *actualBadgeSuperViewFromNormalControl = [self cyl_getActualBadgeSuperViewFromControl:normalControl];
         [actualBadgeSuperViewFromNormalControl performSelector:aSelector withObject:object1 withObject:object2];
         UIControl *counterpart = normalControl.cyl_platterSelectedControl;
         if (counterpart) {
             UIView *actualBadgeSuperViewFromSelectedControl = [self cyl_getActualBadgeSuperViewFromControl:counterpart];
             
             [actualBadgeSuperViewFromSelectedControl performSelector:aSelector withObject:object1 withObject:object2];
         }
     } else if (selectedControl) {
         UIView *actualBadgeSuperViewFromSelectedControl = [self cyl_getActualBadgeSuperViewFromControl:selectedControl];
         
         
         [actualBadgeSuperViewFromSelectedControl performSelector:aSelector withObject:object1 withObject:object2];
         UIControl *counterpart = selectedControl.cyl_platterNormalControl;
         if (counterpart) {
             UIView *actualBadgeSuperViewFromNormalControl = [self cyl_getActualBadgeSuperViewFromControl:counterpart];
             
             [actualBadgeSuperViewFromNormalControl performSelector:aSelector withObject:object1 withObject:object2];
         }
     }
     );
}

- (BOOL)cyl_isReady { 
    return YES;
}

#pragma mark -- setter/getter
- (UILabel *)cyl_badge {
    return CYL_ACTUAL_BARBUTTON.cyl_badge;
}

- (void)cyl_setBadge:(UILabel *)label {
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
    CGFloat badgeMargin = [cyl_badgeMarginValue floatValue];
    [self cyl_setBadgeMargin:badgeMargin];
}

- (CGFloat)cyl_badgeRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeRadius];
}

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeRadius:badgeRadius];
}

- (void)cyl_setBadgeRadiusValue:(NSNumber *)cyl_badgeRadiusValue {
    CGFloat badgeRadius = [cyl_badgeRadiusValue floatValue];
    [self cyl_setBadgeRadius:badgeRadius];
}

- (CGFloat)cyl_badgeCornerRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCornerRadius];
}

- (void)cyl_setBadgeCornerRadius:(CGFloat)cyl_badgeCornerRadius {
    [CYL_ACTUAL_BARBUTTON cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}

- (void)cyl_setBadgeCornerRadiusValue:(NSNumber *)cyl_badgeCornerRadiusValue {
    CGFloat cyl_badgeCornerRadius = [cyl_badgeCornerRadiusValue floatValue];
    [self cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}

@end

