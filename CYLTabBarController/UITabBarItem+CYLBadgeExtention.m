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
#import "UIControl+CYLBadgeExtention.h"

#define kActualView ((UIView *)[self cyl_getActualBadgeSuperView])
#define CYL_ACTUAL_BARBUTTON kActualView

@implementation UITabBarItem (CYLBadgeExtention) 

- (void)cyl_setBadgeValue:(NSString *)badgeValue {
    CYL_DEPRECATED_DECLARATIONS_PUSH
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     // 不再必须， 因此， 并非核心逻辑， 未来考虑删除。
     if (self.cyl_tabButton && [self.cyl_tabButton respondsToSelector:@selector(cyl_removeTabBadgePoint)]) {
         [self.cyl_tabButton cyl_removeTabBadgePoint];
     }
     );
    CYL_DEPRECATED_DECLARATIONS_POP
    
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
    // [kActualView cyl_showBadge];
    SEL selector = @selector(cyl_showBadge);
    [kActualView cyl_performSelector:selector];
}

- (void)cyl_showBadgeValue:(NSString *)value
             animationTypeValue:(NSNumber *)animationTypeValue {
//    [kActualView cyl_showBadgeValue:value animationType:animationType];
    SEL selector = @selector(cyl_showBadgeValue:animationTypeValue:);
    [kActualView cyl_performSelector:selector withObject:value withObject:animationTypeValue];
}

- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType {
    [self cyl_showBadgeValue:value animationTypeValue:@(animationType)];
}

- (void)cyl_clearBadge {
//    [kActualView cyl_clearBadge];
    SEL selector = @selector(cyl_clearBadge);
    [kActualView cyl_performSelector:selector];
}

- (void)cyl_resumeBadge {
//    [kActualView cyl_resumeBadge];
    SEL selector = @selector(cyl_resumeBadge);
    [kActualView cyl_performSelector:selector];
}

- (BOOL)cyl_isShowBadge {
    return [kActualView cyl_isShowBadge];
}

- (BOOL)cyl_isPauseBadge {
    return [kActualView cyl_isPauseBadge];
}

#pragma mark -- private method

/**
 *  Because UIBarButtonItem is kind of NSObject, it is not able to directly attach badge.
 This method is used to find actual view (non-nil) inside UIBarButtonItem instance.
 *
 *  @return view
 */
- (UIView *)cyl_getActualBadgeSuperView {
    //_UITabButton
    UIControl *tabButton = [self cyl_tabButton];
//    UIView *actualBadgeSuperView = [self cyl_getActualBadgeSuperViewFromControl:tabButton];
    UIView *actualBadgeSuperView;
    if ([tabButton isKindOfClass:[UIControl class]]) {
        actualBadgeSuperView = [tabButton cyl_getActualBadgeSuperView];
        if (![CYLConstants isLiquidGlassActive]) {
            return actualBadgeSuperView;
        }
    }
    return tabButton;
}

- (UIView *)cyl_getActualBadgeSuperViewFromControl:(UIControl *)tabButton {
    // badge label will be added onto imageView
    //只有在TabBar选中状态下才能取到SwappableImageView
    UIView *actualBadgeSuperView = [tabButton cyl_getActualBadgeSuperView];
    return actualBadgeSuperView;
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
    UIControl *normalControl = nil;
    UIControl *selectedControl = nil;
    
    UIControl *selfControl = [self cyl_tabButton];
    
    if (![selfControl isKindOfClass:[UIControl class]] || ![CYLConstants isLiquidGlassActive]) {
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
    UIControl *selfControl = [self cyl_tabButton];
    return selfControl.cyl_isReady;
}

#pragma mark -- setter/getter
- (CYLTabBarBadgeView *)cyl_badge {
    return CYL_ACTUAL_BARBUTTON.cyl_badge;
}

- (void)cyl_setBadge:(CYLTabBarBadgeView *)label {
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

