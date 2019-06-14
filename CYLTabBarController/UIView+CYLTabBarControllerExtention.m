//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UIView+CYLTabBarControllerExtention.h"
#import "CYLPlusButton.h"
#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#else
#endif
#import "NSObject+CYLTabBarControllerExtention.h"

@implementation UIView (CYLTabBarControllerExtention)

- (BOOL)cyl_isPlusButton {
    return [self isKindOfClass:[CYLExternPlusButton class]];
}

- (BOOL)cyl_isTabButton {
    BOOL isKindOfButton = [self cyl_isKindOfClass:[UIControl class]];
    return isKindOfButton;
}

- (BOOL)cyl_isTabImageView {
    BOOL isKindOfImageView = [self cyl_isKindOfClass:[UIImageView class]];
    if (!isKindOfImageView) {
        return NO;
    }
    NSString *subString = [NSString stringWithFormat:@"%@cat%@ew", @"Indi" , @"orVi"];
    BOOL isBackgroundImage = [self cyl_classStringHasSuffix:subString];
    BOOL isTabImageView = !isBackgroundImage;
    return isTabImageView;
}

- (BOOL)cyl_isTabLabel {
    BOOL isKindOfLabel = [self cyl_isKindOfClass:[UILabel class]];
    return isKindOfLabel;
}

- (BOOL)cyl_isTabBadgeView {
    BOOL isKindOfClass = [self isKindOfClass:[UIView class]];
    BOOL isClass = [self isMemberOfClass:[UIView class]];
    BOOL isKind = isKindOfClass && !isClass;
    if (!isKind) {
        return NO;
    }
    NSString *tabBarClassString = [NSString stringWithFormat:@"%@IB%@", @"_U" , @"adg"];
    BOOL isTabBadgeView = [self cyl_classStringHasPrefix:tabBarClassString];;
    return isTabBadgeView;
}

- (BOOL)cyl_isTabBackgroundView {
    BOOL isKindOfClass = [self isKindOfClass:[UIView class]];
    BOOL isClass = [self isMemberOfClass:[UIView class]];
    BOOL isKind = isKindOfClass && !isClass;
    if (!isKind) {
        return NO;
    }
    NSString *tabBackgroundViewString = [NSString stringWithFormat:@"%@IB%@", @"_U" , @"arBac"];
    BOOL isTabBackgroundView = [self cyl_classStringHasPrefix:tabBackgroundViewString] && [self cyl_classStringHasSuffix:@"nd"];
    return isTabBackgroundView;
}

- (UIImageView *)cyl_tabImageView {
    for (UIImageView *subview in self.cyl_allSubviews) {
        if ([subview cyl_isTabImageView]) {
            return (UIImageView *)subview;
        }
    }
    return nil;
}

- (NSArray *)cyl_allSubviews {
    __block NSArray* allSubviews = [NSArray arrayWithObject:self];
    [self.subviews enumerateObjectsUsingBlock:^(UIView* view, NSUInteger idx, BOOL*stop) {
        allSubviews = [allSubviews arrayByAddingObjectsFromArray:[view cyl_allSubviews]];
    }];
    return allSubviews;
}

- (UIView *)cyl_tabBadgeView {
    for (UIView *subview in self.cyl_allSubviews) {
        if ([subview cyl_isTabBadgeView]) {
            return (UIView *)subview;
        }
    }
    return nil;
}

- (UILabel *)cyl_tabLabel {
    for (UILabel *subview in self.cyl_allSubviews) {
        if ([subview cyl_isTabLabel]) {
            return (UILabel *)subview;
        }
    }
    return nil;
}

//UIVisualEffectView
- (BOOL)cyl_isTabEffectView {
    BOOL isClass = [self isMemberOfClass:[UIVisualEffectView class]];
    return isClass;
}

//_UIVisualEffectContentView
- (BOOL)cyl_isTabEffectContentView {
    BOOL isKindOfClass = [self isKindOfClass:[UIView class]];
    BOOL isClass = [self isMemberOfClass:[UIView class]];
    BOOL isKind = isKindOfClass && !isClass;
    if (!isKind) {
        return NO;
    }
    NSString *tabBackgroundViewString = [NSString stringWithFormat:@"%@IVisualE%@", @"_U" , @"ffectC"];
    BOOL isTabBackgroundView = [self cyl_classStringHasPrefix:tabBackgroundViewString] && [self cyl_classStringHasSuffix:@"entView"];
    return isTabBackgroundView;
}

//_UIVisualEffectBackdropView
//- (BOOL)cyl_isTabEffectBackdropView {
//    BOOL isKindOfClass = [self isKindOfClass:[UIView class]];
//    BOOL isClass = [self isMemberOfClass:[UIView class]];
//    BOOL isKind = isKindOfClass && !isClass;
//    if (!isKind) {
//        return NO;
//    }
//    NSString *tabBackgroundViewString = [NSString stringWithFormat:@"%@IVisualE%@", @"_U" , @"ffectC"];
//    BOOL isTabBackgroundView = [self cyl_classStringHasPrefix:tabBackgroundViewString] && [self cyl_classStringHasSuffix:@"dropView"];
//    return isTabBackgroundView;
//}

//UIVisualEffectView
- (UIVisualEffectView *)cyl_tabEffectView {
    for (UIView *subview in self.subviews) {
        if ([subview cyl_isTabEffectView]) {
            return (UIVisualEffectView *)subview;
        }
    }
    return nil;
}

////_UIVisualEffectContentView
//- (UIView *)cyl_tabEffectContentView {
//    for (UIView *subview in self.subviews) {
//        if ([subview cyl_isTabEffectContentView]) {
//            return subview;
//        }
//    }
//    return nil;
//}
//
////_UIVisualEffectBackdropView
//- (UIView *)cyl_tabEffectBackdropView {
//    for (UIView *subview in self.cyl_allSubviews) {
//        if ([subview cyl_isTabEffectBackdropView]) {
//            return subview;
//        }
//    }
//    return nil;
//}

- (UIView *)cyl_tabBadgeBackgroundView {
    return [self cyl_tabBackgroundView];
}

- (UIImageView *)cyl_tabShadowImageView {
    if (@available(iOS 13, *)) {
        return [self.cyl_tabBackgroundView cyl_valueForKey:@"_shadowView1"];
    } else if (@available(iOS 10, *)) {
        // iOS 10 及以后，在 UITabBar 初始化之后就能获取到 backgroundView 和 shadowView 了
        return [self.cyl_tabBackgroundView cyl_valueForKey:@"_shadowView"];
    }
    // iOS 9 及以前，shadowView 要在 UITabBar 第一次 layoutSubviews 之后才会被创建，直至 UITabBarController viewWillAppear: 时仍未能获取到 shadowView，所以为了省去调用时机的考虑，这里获取不到的时候会主动触发一次 tabBar 的布局
    UIImageView *shadowView = [self cyl_valueForKey:@"_shadowView"];
    if (!shadowView) {
        [self setNeedsLayout];
        [self layoutIfNeeded];
        shadowView = [self cyl_valueForKey:@"_shadowView"];
    }
    return shadowView;
}

- (UIView *)cyl_tabBackgroundView {
    for (UIImageView *subview in self.subviews) {
        if ([subview cyl_isTabBackgroundView]) {
            return (UIImageView *)subview;
        }
    }
    return nil;
}

- (BOOL)cyl_isLottieAnimationView {
    BOOL isKindOfClass = [self isKindOfClass:[UIView class]];
    BOOL isClass = [self isMemberOfClass:[UIView class]];
    BOOL isKind = isKindOfClass && !isClass;
    if (!isKind) {
        return NO;
    }
    Class classType = NSClassFromString(@"LOTAnimationView");
    BOOL isLottieAnimationView = ([self isKindOfClass:classType] || [self isMemberOfClass:classType]);
    return isLottieAnimationView;
}

- (UIView *)cyl_tabBadgeBackgroundSeparator {
    return [self cyl_tabShadowImageView];
}

- (BOOL)cyl_isKindOfClass:(Class)class {
    BOOL isKindOfClass = [self isKindOfClass:class];
    BOOL isClass = [self isMemberOfClass:class];
    BOOL isKind = isKindOfClass && !isClass;
    if (!isKind) {
        return NO;
    }
    BOOL isTabBarClass = [self cyl_isTabBarClass];
    return isTabBarClass;
}

- (BOOL)cyl_isTabBarClass {
    NSString *tabBarClassString = [NSString stringWithFormat:@"U%@a%@ar", @"IT" , @"bB"];
    BOOL isTabBarClass = [self cyl_classStringHasPrefix:tabBarClassString];
    return isTabBarClass;
}

- (BOOL)cyl_classStringHasPrefix:(NSString *)prefix {
    NSString *classString = NSStringFromClass([self class]);
    return [classString hasPrefix:prefix];
}

- (BOOL)cyl_classStringHasSuffix:(NSString *)suffix {
    NSString *classString = NSStringFromClass([self class]);
    return [classString hasSuffix:suffix];
}

+ (UIView *)cyl_tabBadgePointViewWithClolor:(UIColor *)color radius:(CGFloat)radius {
    UIView *defaultTabBadgePointView = [[UIView alloc] init];
    [defaultTabBadgePointView setTranslatesAutoresizingMaskIntoConstraints:NO];
    defaultTabBadgePointView.backgroundColor = color;
    defaultTabBadgePointView.layer.cornerRadius = radius;
    defaultTabBadgePointView.layer.masksToBounds = YES;
    defaultTabBadgePointView.hidden = YES;
    // Width constraint
    [defaultTabBadgePointView addConstraint:[NSLayoutConstraint constraintWithItem:defaultTabBadgePointView
                                                                         attribute:NSLayoutAttributeWidth
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute: NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1
                                                                          constant:radius * 2]];
    // Height constraint
    [defaultTabBadgePointView addConstraint:[NSLayoutConstraint constraintWithItem:defaultTabBadgePointView
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute: NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1
                                                                          constant:radius * 2]];
    return defaultTabBadgePointView;
}

@end
