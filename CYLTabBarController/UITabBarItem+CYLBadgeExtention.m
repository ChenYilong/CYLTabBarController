/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
 */

#import "UITabBarItem+CYLBadgeExtention.h"
#import "CYLTabBarController.h"
#import <objc/runtime.h>

#define kActualView     [self cyl_getActualBadgeSuperView]

@implementation UITabBarItem (CYLBadgeExtention)
+ (void)load {
    [self cyl_swizzleSetBadgeValue];
}

+ (void)cyl_swizzleSetBadgeValue {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cyl_ClassMethodSwizzle([self class], @selector(setBadgeValue:), @selector(cyl_setBadgeValue:));
    });
}

- (void)cyl_setBadgeValue:(NSString *)badgeValue {
    [self.cyl_tabButton cyl_removeTabBadgePoint];
    [self cyl_clearBadge];
    [self cyl_setBadgeValue:badgeValue];
}

#pragma mark -- public methods

/**
 *  show badge with red dot style and CYLBadgeAnimTypeNone by default.
 */
- (void)cyl_showBadge {
    [kActualView cyl_showBadgeValue:@"" animationType:CYLBadgeAnimTypeNone];
}

- (void)cyl_showBadgeValue:(NSString *)value animationType:(CYLBadgeAnimType)aniType {
    [kActualView cyl_showBadgeValue:value animationType:aniType];
    self.cyl_tabButton.cyl_tabBadgeView.hidden = YES;
}

- (BOOL)cyl_isShowBadge {
    return [kActualView cyl_isShowBadge];
}

- (BOOL)cyl_isPauseBadge {
    return [kActualView cyl_isPauseBadge];
}

/**
 *  clear badge
 */
- (void)cyl_clearBadge {
    [kActualView cyl_clearBadge];
    self.cyl_tabButton.cyl_tabBadgeView.hidden = NO;
}

- (void)cyl_resumeBadge {
    [kActualView cyl_resumeBadge];
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
    // 1.get UITabbarButtion
    UIControl *cyl_tabButton  = [self cyl_tabButton];
    //    return cyl_tabButton;
    // badge label will be added onto imageView
    return [cyl_tabButton cyl_tabImageView];
}

- (UIView *)cyl_find:(UIView *)view firstSubviewWithClass:(Class)cls {
    __block UIView *targetView = nil;
    [view.subviews enumerateObjectsUsingBlock:^(UIView *subview, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([subview isKindOfClass:cls]) {
            targetView = subview;
            *stop = YES;
        }
    }];
    return targetView;
}

#pragma mark -- setter/getter
- (UILabel *)cyl_badge {
    return kActualView.cyl_badge;
}

- (void)cyl_setBadge:(UILabel *)label {
    [kActualView cyl_setBadge:label];
}

- (UIFont *)cyl_badgeFont {
    return kActualView.cyl_badgeFont;
}

- (void)cyl_setBadgeFont:(UIFont *)badgeFont {
    [kActualView cyl_setBadgeFont:badgeFont];
}

- (UIColor *)cyl_badgeBackgroundColor {
    return [kActualView cyl_badgeBackgroundColor];
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    [kActualView cyl_setBadgeBackgroundColor:badgeBackgroundColor];
}

- (UIColor *)cyl_badgeTextColor {
    return [kActualView cyl_badgeTextColor];
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    [kActualView cyl_setBadgeTextColor:badgeTextColor];
}

- (CYLBadgeAnimType)cyl_aniType {
    return [kActualView cyl_aniType];
}

- (void)cyl_setAniType:(CYLBadgeAnimType)aniType {
    [kActualView cyl_setAniType:aniType];
}

- (CGRect)cyl_badgeFrame {
    return [kActualView cyl_badgeFrame];
}

- (void)cyl_setBadgeFrame:(CGRect)badgeFrame {
    [kActualView cyl_setBadgeFrame:badgeFrame];
}

- (CGPoint)cyl_badgeCenterOffset {
    return [kActualView cyl_badgeCenterOffset];
}

- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOffset {
    [kActualView cyl_setBadgeCenterOffset:badgeCenterOffset];
}

- (NSInteger)cyl_badgeMaximumBadgeNumber {
    return [kActualView cyl_badgeMaximumBadgeNumber];
}

- (void)cyl_setBadgeMaximumBadgeNumber:(NSInteger)badgeMaximumBadgeNumber {
    [kActualView cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (CGFloat)cyl_badgeMargin {
    return [kActualView cyl_badgeMargin];
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    [kActualView cyl_setBadgeMargin:badgeMargin];
}

- (CGFloat)cyl_badgeRadius {
    return [kActualView cyl_badgeRadius];
}

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    [kActualView cyl_setBadgeRadius:badgeRadius];
}

#pragma mark - private method

BOOL cyl_ClassMethodSwizzle(Class aClass, SEL originalSelector, SEL swizzleSelector) {
    Method originalMethod = class_getInstanceMethod(aClass, originalSelector);
    Method swizzleMethod = class_getInstanceMethod(aClass, swizzleSelector);
    BOOL didAddMethod =
    class_addMethod(aClass,
                    originalSelector,
                    method_getImplementation(swizzleMethod),
                    method_getTypeEncoding(swizzleMethod));
    if (didAddMethod) {
        class_replaceMethod(aClass,
                            swizzleSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzleMethod);
    }
    return YES;
}

@end
