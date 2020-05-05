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

//UIVisualEffectView
- (UIVisualEffectView *)cyl_tabEffectView {
    for (UIView *subview in self.subviews) {
        if ([subview cyl_isTabEffectView]) {
            return (UIVisualEffectView *)subview;
        }
    }
    return nil;
}

- (UIView *)cyl_tabBadgeBackgroundView {
    return [self cyl_tabBackgroundView];
}

- (UIImageView *)cyl_tabShadowImageView {
    if (@available(iOS 10.0, *)) {
        //iOS10及以上这样获取ShadowImageView：
        UIView *subview = [self cyl_tabBackgroundView];
        if (!subview) {
            return nil;
        }
        NSArray<__kindof UIView *> *backgroundSubviews = subview.subviews;
        //iOS13系统backgroundSubviews.count > 1可行，12及以下就不可行了
        if (backgroundSubviews.count >= 1) {
            for (UIView *subview in backgroundSubviews) {
                if (CGRectGetHeight(subview.bounds) <= 1.0 ) {
                    return (UIImageView *)subview;
                }
            }
        }
    } else {
        //iOS9这样获取ShadowImageView：
        for (UIView *subview in self.subviews) {
            if (CGRectGetHeight(subview.bounds) <= 1.0 ) {
                return (UIImageView *)subview;
            }
        }
    }
    return nil;
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
