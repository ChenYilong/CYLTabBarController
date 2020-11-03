//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import "UIControl+CYLTabBarControllerExtention.h"
#import <objc/runtime.h>
#import "UIView+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"
#import "CYLTabBarController.h"
#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#else
#endif

@implementation UIControl (CYLTabBarControllerExtention)

- (BOOL)cyl_isChildViewControllerPlusButton {
    BOOL isChildViewControllerPlusButton = ([self cyl_isPlusButton] && CYLPlusChildViewController.cyl_plusViewControllerEverAdded);
    return isChildViewControllerPlusButton;
}

- (BOOL)cyl_shouldNotSelect {
    NSNumber *shouldNotSelectObject = objc_getAssociatedObject(self, @selector(cyl_shouldNotSelect));
    return [shouldNotSelectObject boolValue];
}

- (void)cyl_setShouldNotSelect:(BOOL)shouldNotSelect {
    NSNumber *shouldNotSelectObject = @(shouldNotSelect);
    objc_setAssociatedObject(self, @selector(cyl_shouldNotSelect), shouldNotSelectObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)cyl_tabBarItemVisibleIndex {
    if (!self.cyl_isTabButton && !self.cyl_isPlusButton ) {
        return NSNotFound;
    }
    NSNumber *tabBarItemVisibleIndexObject = objc_getAssociatedObject(self, @selector(cyl_tabBarItemVisibleIndex));
    return [tabBarItemVisibleIndexObject integerValue];
}

- (void)cyl_setTabBarItemVisibleIndex:(NSInteger)tabBarItemVisibleIndex {
    NSNumber *tabBarItemVisibleIndexObject = [NSNumber numberWithInteger:tabBarItemVisibleIndex];
    objc_setAssociatedObject(self, @selector(cyl_tabBarItemVisibleIndex), tabBarItemVisibleIndexObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSInteger)cyl_tabBarChildViewControllerIndex {
    if (!self.cyl_isTabButton && !self.cyl_isPlusButton ) {
        return NSNotFound;
    }
    NSNumber *tabBarChildViewControllerIndexObject = objc_getAssociatedObject(self, @selector(cyl_tabBarChildViewControllerIndex));
    return [tabBarChildViewControllerIndexObject integerValue];
}

- (void)cyl_setTabBarChildViewControllerIndex:(NSInteger)tabBarChildViewControllerIndex {
    NSNumber *tabBarChildViewControllerIndexObject = [NSNumber numberWithInteger:tabBarChildViewControllerIndex];
    objc_setAssociatedObject(self, @selector(cyl_tabBarChildViewControllerIndex), tabBarChildViewControllerIndexObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cyl_showTabBadgePoint {
    [self cyl_setShowTabBadgePointIfNeeded:YES];
}

- (void)cyl_removeTabBadgePoint {
    [self cyl_setShowTabBadgePointIfNeeded:NO];
}

- (BOOL)cyl_isShowTabBadgePoint {
    return !self.cyl_tabBadgePointView.hidden;
}

- (BOOL)cyl_isSelected {
    NSUInteger tabBarSelectedIndex = self.cyl_tabBarController.selectedIndex;
    NSUInteger tabBarChildViewControllerIndex = self.cyl_tabBarChildViewControllerIndex;
    BOOL isSelected = (tabBarSelectedIndex == tabBarChildViewControllerIndex) && self.selected;
    if (self.cyl_tabBarController.tabBar.cyl_hasPlusChildViewController) {
        isSelected = isSelected && CYLPlusChildViewController.cyl_plusViewControllerEverAdded;
    }
    return isSelected;
}

- (void)cyl_setShowTabBadgePointIfNeeded:(BOOL)showTabBadgePoint {
    @try {
        [self cyl_setShowTabBadgePoint:showTabBadgePoint];
    } @catch (NSException *exception) {
        NSLog(@"CYLPlusChildViewController do not support set TabBarItem red point");
    }
}

- (void)cyl_setShowTabBadgePoint:(BOOL)showTabBadgePoint {
    if (showTabBadgePoint && self.cyl_tabBadgePointView.superview == nil) {
        [self addSubview:self.cyl_tabBadgePointView];
        [self bringSubviewToFront:self.cyl_tabBadgePointView];
        self.cyl_tabBadgePointView.layer.zPosition = MAXFLOAT;
        // X constraint
        [self addConstraint:
         [NSLayoutConstraint constraintWithItem:self.cyl_tabBadgePointView
                                      attribute:NSLayoutAttributeCenterX
                                      relatedBy:0
                                         toItem:self.cyl_tabImageView
                                      attribute:NSLayoutAttributeRight
                                     multiplier:1
                                       constant:self.cyl_tabBadgePointViewOffset.horizontal]];
        //Y constraint
        [self addConstraint:
         [NSLayoutConstraint constraintWithItem:self.cyl_tabBadgePointView
                                      attribute:NSLayoutAttributeCenterY
                                      relatedBy:0
                                         toItem:self.cyl_tabImageView
                                      attribute:NSLayoutAttributeTop
                                     multiplier:1
                                       constant:self.cyl_tabBadgePointViewOffset.vertical]];
    }
    self.cyl_tabBadgePointView.hidden = showTabBadgePoint == NO;
    self.cyl_tabBadgeView.hidden = showTabBadgePoint == YES;
}

- (void)cyl_setTabBadgePointView:(UIView *)tabBadgePointView {
    UIView *tempView = objc_getAssociatedObject(self, @selector(cyl_tabBadgePointView));
    if (tempView) {
        [tempView removeFromSuperview];
    }
    if (tabBadgePointView.superview) {
        [tabBadgePointView removeFromSuperview];
    }
    
    tabBadgePointView.hidden = YES;
    objc_setAssociatedObject(self, @selector(cyl_tabBadgePointView), tabBadgePointView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)cyl_tabBadgePointView {
    UIView *tabBadgePointView = objc_getAssociatedObject(self, @selector(cyl_tabBadgePointView));
    
    if (tabBadgePointView == nil) {
        tabBadgePointView = self.cyl_defaultTabBadgePointView;
        objc_setAssociatedObject(self, @selector(cyl_tabBadgePointView), tabBadgePointView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return tabBadgePointView;
}

- (void)cyl_setTabBadgePointViewOffset:(UIOffset)tabBadgePointViewOffset {
    objc_setAssociatedObject(self, @selector(cyl_tabBadgePointViewOffset), [NSValue valueWithUIOffset:tabBadgePointViewOffset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//offset如果都是正数，则往右下偏移
- (UIOffset)cyl_tabBadgePointViewOffset {
    id tabBadgePointViewOffsetObject = objc_getAssociatedObject(self, @selector(cyl_tabBadgePointViewOffset));
    UIOffset tabBadgePointViewOffset = [tabBadgePointViewOffsetObject UIOffsetValue];
    return tabBadgePointViewOffset;
}

- (LOTAnimationView *)cyl_lottieAnimationView {
    for (UILabel *subview in self.subviews) {
        if ([subview cyl_isLottieAnimationView]) {
            return (LOTAnimationView *)subview;
        }
    }
    return nil;
}

- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                             show:(BOOL)show {
    [self cyl_replaceTabImageViewWithNewView:newView offset:UIOffsetZero show:show completion:^(BOOL isReplaced, UIControl *tabBarButton, UIView *newView) {
    }];
}

- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                           offset:(UIOffset)offset
                                    show:(BOOL)theShow
                                        completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [self cyl_replaceTabImageViewOrTabButton:NO newView:newView offset:offset show:theShow completion:completion];
}

- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [self cyl_replaceTabImageViewOrTabButton:YES newView:newView offset:offset show:theShow completion:completion];
}

- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                      show:(BOOL)show {
    [self cyl_replaceTabButtonWithNewView:newView offset:UIOffsetZero show:show completion:^(BOOL isReplaced, UIControl *tabBarButton, UIView *newView) {
    }];
}

- (void)cyl_replaceTabImageViewOrTabButton:(BOOL)isTabButton
                               newView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    UIControl *tabBarButton = self;
    UIImageView *swappableImageView = tabBarButton.cyl_tabImageView;
    UIView *replacedView = swappableImageView;
    if (isTabButton) {
        replacedView = tabBarButton;
    }
    if (!replacedView) {
        return;
    }
    if (newView.frame.size.width == 0 || newView.frame.size.height == 0 || newView.frame.size.width > tabBarButton.frame.size.width || newView.frame.size.height > tabBarButton.frame.size.height) {
        UIImage *image = swappableImageView.image;
        newView.frame = ({
            CGRect frame = newView.frame;
            frame.size = CGSizeMake(image.size.width, image.size.height);
            frame;
        });
    }
    BOOL newViewCreated = (newView.superview);
    BOOL newViewAddedToTabButton = [self.subviews containsObject:newView];
    BOOL isNewViewAddedToTabButton = newViewCreated && newViewAddedToTabButton;
    if (newView.superview && !newViewAddedToTabButton) {
        [newView removeFromSuperview];
    }
    if (isNewViewAddedToTabButton && theShow) {
        !completion?:completion(YES, self, newView);
        return;
    }
    BOOL show = (newView && theShow);
    swappableImageView.hidden = (show);
    if (isTabButton) {
        tabBarButton.cyl_tabLabel.hidden = show;
    }
    BOOL shouldShowNewView = show && !newView.superview;
    BOOL shouldRemoveNewView = newView.superview;
    if (shouldShowNewView) {
        [tabBarButton addSubview:newView];
        [tabBarButton bringSubviewToFront:newView];
        CGSize newViewSize = newView.frame.size;
        if (@available(iOS 9.0, *)) {
            [NSLayoutConstraint activateConstraints:@[
                                                      [newView.centerXAnchor constraintEqualToAnchor:swappableImageView.centerXAnchor constant:offset.horizontal],
                                                      [newView.centerYAnchor constraintEqualToAnchor:replacedView.centerYAnchor constant:offset.vertical],
                                                      [newView.widthAnchor constraintEqualToConstant:newViewSize.width],
                                                      [newView.heightAnchor constraintEqualToConstant:newViewSize.height],
                                                      ]
             ];
        } else {
            [self addConstraints:@[
                                   [NSLayoutConstraint constraintWithItem:newView
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:swappableImageView
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0
                                                                 constant:offset.horizontal],
                                   [NSLayoutConstraint constraintWithItem:newView
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:replacedView
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1.0
                                                                 constant:offset.vertical],
                                   [NSLayoutConstraint constraintWithItem:newView
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:replacedView
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1.0
                                                                 constant:offset.vertical],
                                   [NSLayoutConstraint constraintWithItem:newView
                                                                attribute:NSLayoutAttributeWidth
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:newViewSize.width],
                                   [NSLayoutConstraint constraintWithItem:newView
                                                                attribute:NSLayoutAttributeHeight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:nil
                                                                attribute:NSLayoutAttributeNotAnAttribute
                                                               multiplier:1.0
                                                                 constant:newViewSize.height]
                                   ]];
        }
        !completion?:completion(YES, self, newView);
        return;
    }
    if (shouldRemoveNewView) {
        [newView removeFromSuperview];
        newView = nil;
        !completion?:completion(NO, self, nil);
        return;
    }
}

- (void)cyl_addLottieImageWithLottieURL:(NSURL *)lottieURL
                                   size:(CGSize)size {
#if __has_include(<Lottie/Lottie.h>)
    if (self.cyl_lottieAnimationView) {
        return;
    }
    UIControl *tabButton = self;
    LOTAnimationView *lottieView = [[LOTAnimationView alloc] initWithContentsOfURL:lottieURL];
    lottieView.frame = CGRectMake(0, 0, size.width, size.height);
    lottieView.userInteractionEnabled = NO;
    lottieView.contentMode = UIViewContentModeScaleAspectFill;
    lottieView.translatesAutoresizingMaskIntoConstraints = NO;
    [lottieView setClipsToBounds:NO];
    [tabButton cyl_replaceTabImageViewWithNewView:lottieView show:YES];
#else
#endif

}

#pragma mark - private method

- (UIView *)cyl_defaultTabBadgePointView {
    UIView *defaultRedTabBadgePointView = [UIView cyl_tabBadgePointViewWithClolor:[UIColor redColor] radius:4.5];
    return defaultRedTabBadgePointView;
}

@end

