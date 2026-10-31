/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "UIBarButtonItem+CYLBadgeExtention.h"
#import <objc/runtime.h>
#import "NSObject+CYLTabBarControllerExtention.h"
#import "UIControl+CYLBadgeExtention.h"
#import "CYLConstants.h"

#define kActualView ((UIView *)[self cyl_getActualBadgeSuperView])
#define CYL_ACTUAL_BARBUTTON kActualView


@implementation UIBarButtonItem (CYLBadgeExtention)

#pragma mark -- public methods
- (BOOL)cyl_isReady {
    UIView *view = [self cyl_getActualBadgeSuperView];
    if (view && [view isKindOfClass:[UIView class]]) {
        return view.frame.size.width > 10;
    }
    return [view cyl_findBarButtonContentView].frame.size.width > 10;
}
/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
/*!
 * FIX: badge position with Auto Layout
 * [EN] `delaySeconds` was an `NSUInteger`, so the 0.5 s wait for a bar button that is not laid out yet became 0.
 * [CN] `delaySeconds` 原为 `NSUInteger`，尚未完成布局的 bar button 本应等待 0.5 秒，实际变成了 0 秒。
 */
- (void)cyl_showBadge {
    if (@available(iOS 11.0, *)) {
        [self swizzling_willMoveToSuperview];
    }
    NSTimeInterval delaySeconds = self.cyl_isReady ? 0 : 0.5;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [CYL_ACTUAL_BARBUTTON cyl_showBadge];

    });
}

- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType {
    if (@available(iOS 11.0, *)) {
        [self swizzling_willMoveToSuperview];
    }
    NSTimeInterval delaySeconds = self.cyl_isReady ? 0 : 0.5;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        [CYL_ACTUAL_BARBUTTON cyl_showBadgeValue:value animationType:animationType];
    });
}

- (void)cyl_clearBadge {
    [CYL_ACTUAL_BARBUTTON cyl_clearBadge];
}

- (void)cyl_resumeBadge {
    [CYL_ACTUAL_BARBUTTON cyl_resumeBadge];
}

- (BOOL)cyl_isPauseBadge {
    return [CYL_ACTUAL_BARBUTTON cyl_isPauseBadge];
}

- (BOOL)cyl_isShowBadge {
    return [CYL_ACTUAL_BARBUTTON cyl_isShowBadge];
}

#pragma mark -- private method

/**
 *  Because UIBarButtonItem is kind of NSObject, it is not able to directly attach badge.
    This method is used to find actual view (non-nil) inside UIBarButtonItem instance.
 *<_UIModernBarButton: 0x107721500>:
 in _UIModernBarButton:
     _guardAgainstDegenerateBaselineCalculation (BOOL): NO
     _shouldUseButtonPlatters (BOOL): NO
     _enableMonochromaticTreatmentOnImageAndTitle (BOOL): YES
     _usesTintColorCapsuleForSelection (BOOL): YES
     __additionalSelectionInsets (struct UIEdgeInsets): {0, 0, 0, 0}
     _selectionIndicatorViewFrame (struct CGRect): {{-12, -2}, {139, 36}}
 in UIButton:
     _externalFlatEdge (unsigned long): 0
     _but
 *  @return view
 */
- (UIView *)cyl_getActualBadgeSuperView {
    UIButton *barButtonContentView = (UIButton *)self.cyl_view.cyl_findBarButtonContentView;
    UIView *actualBadgeSuperView = barButtonContentView;

    // 不管 image 还是 text 的 UIBarButtonItem 都获取内部的 _UI+ModernBarButton 即可
    do {
        if (barButtonContentView.imageView && (barButtonContentView.imageView.frame.size.width > 10)) {
            actualBadgeSuperView = barButtonContentView.imageView;
            break;
        }
        if (barButtonContentView.titleLabel && (barButtonContentView.titleLabel.frame.size.width > 10)) {
            //cyl_isButtonLabel
            actualBadgeSuperView = barButtonContentView.titleLabel;
            break;
        }
        
    } while (false); // same as : 0, NO
    //建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame.自动布局 cell 需要调用 [self layoutIfNeeded] frame才有值，角标才能找到对应的位置。 需要确保view showBadge的方法 在layoutIfNeeded之后调用 
    [actualBadgeSuperView layoutIfNeeded];//建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame
    return actualBadgeSuperView;//use KVC to hack actual view
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

/*!
 *  @warning 仅对 UIBarButtonItem、UITabBarItem 有效
 *   UIBarItem 本身没有 view 属性，只有子类 UIBarButtonItem 和 UITabBarItem 才有
 *   iOS11改成了类似懒加载机制，要等到UIBarButtonItem被展示后才能获取到_view
 */
- (UIView *)cyl_view {
    if ([self respondsToSelector:@selector(view)]) {
        return [self cyl_valueForKey:@"view"];
    }
    return nil;
}

#pragma mark -- KVC bridge accessors required by CYLBadgeProtocol

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

/*!
 * [EN] `CYLBadgeProtocol` declares `cyl_delayIfNeededForSeconds` as a `CGFloat`. This returned an `NSNumber *`, so a
 *      caller going through the protocol read an object pointer as a floating-point number. Return the number itself.
 * [CN] `CYLBadgeProtocol` 将 `cyl_delayIfNeededForSeconds` 声明为 `CGFloat`，这里却返回 `NSNumber *`，
 *      通过协议调用时会把对象指针当作浮点数读取。现在直接返回数值。
 */
- (CGFloat)cyl_delayIfNeededForSeconds {
    // Mirror the logic used when delaying badge operations.
    // 0 if ready immediately, otherwise default to 0.5s.
    NSTimeInterval delaySeconds = self.cyl_isReady ? 0 : 0.5;
    return delaySeconds;
}

- (void)cyl_setDelayIfNeededForSeconds:(CGFloat)seconds {
    // Accept and ignore; delay is computed dynamically by cyl_isReady.
    // Provided to satisfy protocol/KVC expectations.
    (void)seconds;
}

/*!
 * [EN] Before, `cyl_delayIfNeededForSeconds` returned an `NSNumber *` from this class although the protocol declares a
 *      `CGFloat`. A caller that used the declared type read a pointer as a number; one that used `performSelector:` /
 *      KVC got the object. The declared type is the contract, so it returns the `CGFloat`. For an object, use this
 *      NSNumber accessor, which also works through `performSelector:` and KVC.
 * [CN] 原先这个类的 `cyl_delayIfNeededForSeconds` 返回 `NSNumber *`，而协议声明的是 `CGFloat`。按声明类型调用的代码会把指针当数字读取；
 *      用 `performSelector:` / KVC 的代码拿到的是对象。声明的类型才是约定，所以现在返回 `CGFloat`。需要对象时请用这个 NSNumber 访问器，
 *      它同样可用于 `performSelector:` 和 KVC。
 */
- (NSNumber *)cyl_delayIfNeededForSecondsValue {
    return @(self.cyl_delayIfNeededForSeconds);
}

- (void)cyl_setDelayIfNeededForSecondsValue:(NSNumber *)delayIfNeededForSecondsValue {
    [self cyl_setDelayIfNeededForSeconds:[delayIfNeededForSecondsValue doubleValue]];
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

- (void)cyl_setBadgeAnimationTypeValue:(NSNumber *)cyl_badgeAnimationTypeValue {
    CYLBadgeAnimationType badgeAnimationType = [cyl_badgeAnimationTypeValue integerValue];
    [self cyl_setBadgeAnimationType:badgeAnimationType];
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

/**
 Swizzling -[_UIButtonBarButton willMoveToSuperview:]
 */
- (void)swizzling_willMoveToSuperview __IOS_AVAILABLE(11.0) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(willMoveToSuperview:);
        SEL swizzledSelector = NSSelectorFromString(@"cyl_willMoveToSuperview:");
        Method originalMethod = class_getInstanceMethod(NSClassFromString(@"_UIButtonBarButton"), originalSelector);
        Method swizzledMethod = class_getInstanceMethod(super.class, swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

@end
