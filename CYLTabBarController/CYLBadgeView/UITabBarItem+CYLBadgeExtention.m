/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "UITabBarItem+CYLBadgeExtention.h"
#import <objc/runtime.h>
#import "CYLBadgeProtocol.h"
#import "UIControl+CYLBadgeExtention.h"
// FIX: issue #535 — Core (tab bar) code only when CYLTabBarController is part of the build; see CYLBadgeViewDefines.h.
// FIX: issue #535 — 只有 CYLTabBarController 参与编译时才使用 Core（TabBar）代码，见 CYLBadgeViewDefines.h。
#import "CYLBadgeViewDefines.h"

#if !CYL_BADGE_CORE_AVAILABLE
/// The icon inside a tab button, where the badge goes; the button itself when there is none. 角标所在的 Tab 图标；没有时为按钮本身。
static UIView *CYLBadgeIconViewInView(UIView *view) {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIImageView class]] && !subview.hidden && subview.frame.size.width > 0) {
            return subview;
        }
        UIView *iconView = CYLBadgeIconViewInView(subview);
        if (iconView != subview) {
            return iconView;
        }
    }
    return view;
}
#endif

#define kActualView ((UIView *)[self cyl_getActualBadgeSuperView])
#define CYL_ACTUAL_BARBUTTON kActualView

@implementation UITabBarItem (CYLBadgeExtention) 

- (void)cyl_setBadgeValue:(NSString *)badgeValue {
#if CYL_BADGE_CORE_AVAILABLE
    UIControl *tabButton = self.cyl_tabButton;
    CYL_DEPRECATED_DECLARATIONS_PUSH
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     // [CN] 不再必须， 因此， 并非核心逻辑， 未来考虑删除。
     // [EN] No longer required, so this is not core logic; may be removed in the future.
     if (tabButton && [tabButton respondsToSelector:@selector(cyl_removeTabBadgePoint)]) {
         [tabButton cyl_removeTabBadgePoint];
     }
     );
    CYL_DEPRECATED_DECLARATIONS_POP
#endif
    
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
    // [kActualView cyl_showBadge];
    SEL selector = @selector(cyl_showBadge);
    [self cyl_performSelector:selector];
}

- (void)cyl_showBadgeValue:(NSString *)value
             animationTypeValue:(NSNumber *)animationTypeValue {
//    [kActualView cyl_showBadgeValue:value animationType:animationType];
    SEL selector = @selector(cyl_showBadgeValue:animationTypeValue:);
    [self cyl_performSelector:selector withObject:value withObject:animationTypeValue];
}

- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType {
    [self cyl_showBadgeValue:value animationTypeValue:@(animationType)];
}

- (void)cyl_clearBadge {
//    [kActualView cyl_clearBadge];
    SEL selector = @selector(cyl_clearBadge);
    [self cyl_performSelector:selector];
}

- (void)cyl_resumeBadge {
//    [kActualView cyl_resumeBadge];
    SEL selector = @selector(cyl_resumeBadge);
    [self cyl_performSelector:selector];
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
    UIControl *tabButton = self.cyl_tabButton;
//    UIView *actualBadgeSuperView = [self cyl_getActualBadgeSuperViewFromControl:tabButton];
    UIView *actualBadgeSuperView;
    if ([tabButton isKindOfClass:[UIControl class]]) {
#if CYL_BADGE_CORE_AVAILABLE
        actualBadgeSuperView = [tabButton cyl_getActualBadgeSuperView];
#else
        actualBadgeSuperView = CYLBadgeIconViewInView(tabButton);
#endif
        if (![CYLUtils isLiquidGlassActive]) {
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

- (void)cyl_performSelector:(SEL)aSelector withObject:(nullable id)object {
    if (aSelector == NULL) { return; }
    NSObject *object2 = nil;
    [self cyl_performSelector:aSelector withObject:object withObject:object2];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(nullable id)object1 withObject:(nullable id)object2 {
    if (aSelector == NULL) { return; }
#if !CYL_BADGE_CORE_AVAILABLE
    // On its own there is no Liquid Glass platter to mirror. 单独使用时没有需要同步的液态玻璃 platter。
    UIView *actualBadgeSuperView = [self cyl_getActualBadgeSuperView];
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     [actualBadgeSuperView performSelector:aSelector withObject:object1 withObject:object2];
     )
#else
    UIControl *normalControl = nil;
    UIControl *selectedControl = nil;
    
    UIControl *selfControl = self.cyl_tabButton;
    if (![selfControl isKindOfClass:[UIControl class]] || ![CYLUtils isLiquidGlassActive]) {
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
#endif
}

/*!
 * FIX: issue #535
 * [EN] Returns YES once the item's image view or title label has been laid out (width > 10). This was implemented both
 *      here and in Core's `UITabBarItem+CYLTabBarControllerExtention.m`, and the one that ran depended on link order
 *      (Core's, in CocoaPods builds). It is now this single implementation, keeping Core's check; without Core it asks
 *      the tab button.
 * [CN] 该 Item 的图片视图或标题 Label 完成布局（宽度大于 10）后返回 YES。此方法原先在这里和 Core 的
 *      `UITabBarItem+CYLTabBarControllerExtention.m` 中各实现了一次，实际生效的取决于链接顺序（CocoaPods 构建中为 Core 的实现）。
 *      现在只保留这一个实现，沿用 Core 的判断；没有 Core 时询问 Tab 按钮。
 */
- (BOOL)cyl_isReady {
#if CYL_BADGE_CORE_AVAILABLE
    return self.cyl_imageView.frame.size.width > 10 || self.cyl_view.cyl_tabLabel.frame.size.width > 10 ;
#else
    UIControl *selfControl = self.cyl_tabButton;
    return selfControl.cyl_isReady;
#endif
}

#pragma mark -- setter/getter

// FIX: issue #481
// [EN] The setters go through `-cyl_performSelector:withObject:` (as `UIViewController`'s, which call this item): with
//      Liquid Glass it applies them to the badge host of the normal layer and of its counterpart in the selected layer,
//      so a badge styled on the tab item directly is styled in both layers. They used to reach only the normal layer,
//      and the selected layer showed the default style. Values that are not objects use the `…Value:` setters.
// [CN] setter 通过 `-cyl_performSelector:withObject:` 设置（与调用本 item 的 `UIViewController` 相同）：液态玻璃下同时作用于普通图层
//      及其在选中图层中的对应按钮上的角标宿主，因此直接在 TabBarItem 上设置的角标样式在两个图层中都生效。原先只作用于普通图层，选中图层
//      显示默认样式。非对象的值使用 `…Value:` setter。
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
    [self cyl_performSelector:@selector(cyl_setBadgeFont:) withObject:badgeFont];
}

- (UIColor *)cyl_badgeBackgroundColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeBackgroundColor];
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    [self cyl_performSelector:@selector(cyl_setBadgeBackgroundColor:) withObject:badgeBackgroundColor];
}

- (UIColor *)cyl_badgeTextColor {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeTextColor];
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    [self cyl_performSelector:@selector(cyl_setBadgeTextColor:) withObject:badgeTextColor];
}

- (CYLBadgeAnimationType)cyl_badgeAnimationType {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeAnimationType];
}

- (void)cyl_setBadgeAnimationType:(CYLBadgeAnimationType)animationType {
    [self cyl_performSelector:@selector(cyl_setBadgeAnimationTypeValue:) withObject:@(animationType)];
}

- (CGRect)cyl_badgeFrame {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeFrame];
}

- (void)cyl_setBadgeFrame:(CGRect)badgeFrame {
    [self cyl_performSelector:@selector(cyl_setBadgeFrameValue:) withObject:[NSValue valueWithCGRect:badgeFrame]];
}

- (void)cyl_setBadgeFrameValue:(NSValue *)cyl_badgeFrameValue {
    CGRect badgeFrame = cyl_badgeFrameValue.CGRectValue;
    [self cyl_setBadgeFrame:badgeFrame];
}

- (CGPoint)cyl_badgeCenterOffset {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCenterOffset];
}

- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOffset {
    [self cyl_performSelector:@selector(cyl_setBadgeCenterOffsetValue:) withObject:[NSValue valueWithCGPoint:badgeCenterOffset]];
}

- (void)cyl_setBadgeCenterOffsetValue:(NSValue *)badgeCenterOffsetValue {
    CGPoint badgeCenterOffset = badgeCenterOffsetValue.CGPointValue;
    [self cyl_setBadgeCenterOffset:badgeCenterOffset];
}
- (NSInteger)cyl_badgeMaximumBadgeNumber {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeMaximumBadgeNumber];
}

- (void)cyl_setBadgeMaximumBadgeNumber:(NSInteger)badgeMaximumBadgeNumber {
    [self cyl_performSelector:@selector(cyl_setBadgeMaximumBadgeNumberValue:) withObject:@(badgeMaximumBadgeNumber)];
}

- (void)cyl_setBadgeMaximumBadgeNumberValue:(NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    NSInteger badgeMaximumBadgeNumber = [cyl_badgeMaximumBadgeNumberValue integerValue];
    [self cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (CGFloat)cyl_badgeMargin {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeMargin];
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    [self cyl_performSelector:@selector(cyl_setBadgeMarginValue:) withObject:@(badgeMargin)];
}

- (void)cyl_setBadgeMarginValue:(NSNumber *)cyl_badgeMarginValue {
    CGFloat badgeMargin = [cyl_badgeMarginValue doubleValue];
    [self cyl_setBadgeMargin:badgeMargin];
}

- (CGFloat)cyl_badgeRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeRadius];
}

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    [self cyl_performSelector:@selector(cyl_setBadgeRadiusValue:) withObject:@(badgeRadius)];
}

- (void)cyl_setBadgeRadiusValue:(NSNumber *)cyl_badgeRadiusValue {
    CGFloat badgeRadius = [cyl_badgeRadiusValue doubleValue];
    [self cyl_setBadgeRadius:badgeRadius];
}

- (CGFloat)cyl_badgeCornerRadius {
    return [CYL_ACTUAL_BARBUTTON cyl_badgeCornerRadius];
}

- (void)cyl_setBadgeCornerRadius:(CGFloat)cyl_badgeCornerRadius {
    [self cyl_performSelector:@selector(cyl_setBadgeCornerRadiusValue:) withObject:@(cyl_badgeCornerRadius)];
}

- (void)cyl_setBadgeCornerRadiusValue:(NSNumber *)cyl_badgeCornerRadiusValue {
    CGFloat cyl_badgeCornerRadius = [cyl_badgeCornerRadiusValue doubleValue];
    [self cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}

@end

