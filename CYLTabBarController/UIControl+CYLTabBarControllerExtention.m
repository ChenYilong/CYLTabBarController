//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
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
#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import "CYLPlusButton.h"

@implementation UIControl (CYLTabBarControllerExtention)

- (BOOL)cyl_isChildViewControllerPlusButton {
    if (!CYLPlusChildViewController.cyl_plusViewControllerEverAdded) {
        return NO;
    }
    BOOL isChildViewControllerPlusButton = ([self cyl_isPlusButton] && CYLPlusChildViewController.cyl_plusViewControllerEverAdded);
    if (isChildViewControllerPlusButton) {
        return YES;
    }
    
    if (CYLExternPlusButton.cyl_tabBarItemVisibleIndex == self.cyl_tabBarItemVisibleIndex) {
        return YES;
    }
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

- (BOOL)cyl_isReady {
    if (self.cyl_tabBarController.lottieURLs.count > 0) {
        return self.cyl_isLottieReady;
    }
    return self.cyl_tabImageView.frame.size.width > 10 || self.cyl_tabLabel.frame.size.width > 10 ;
}

- (BOOL)cyl_isLottieReady {
    if (self.cyl_tabBarController.lottieURLs.count > 0) {
        return self.cyl_tabBarController.lottieViewAdded;
    }
    if (self.cyl_lottieAnimationView) {
        UIView *view = self.cyl_lottieAnimationView;
        return view.frame.size.width > 10;

    }
    return NO;
}


+ (NSString *)cyl_createUILabelTextFromPlusButtonWithStateAppearance:(UITabBarItemStateAppearance *)state {
    return [self cyl_createUILabelTextFromSize:CYLExternPlusButton.bounds.size stateAppearance:state];
}

+ (NSString *)cyl_createUILabelTextFromSize:(CGSize)size stateAppearance:(UITabBarItemStateAppearance *)state {
    
    if (size.width <= 0 || size.height <= 0) {
        return @"";
    }
    /*!
     * //                    [[UITabBarItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"AmericanTypewriter" size:20.0f]} forState:UIControlStateNormal];

     */
//    UIFont *font = state.titleTextAttributes[NSFontAttributeName];
    NSString *baseString = @".";
    
    NSDictionary *attrs = state.titleTextAttributes;//@{NSFontAttributeName : font};
    
    NSMutableString *result = [NSMutableString string];
    
    CGSize currentSize = CGSizeZero;
    
    while (currentSize.height < size.height) {
        
        [result appendString:baseString];
        
        CGRect rect = [result boundingRectWithSize:CGSizeMake(size.width, CGFLOAT_MAX)
                                           options:NSStringDrawingUsesLineFragmentOrigin |
                                                   NSStringDrawingUsesFontLeading
                                        attributes:attrs
                                           context:nil];
        
        currentSize = rect.size;
        
        if (currentSize.height >= size.height) {
            break;
        }
    }
    
    return result;
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

- (BOOL)cyl_isPlusControl {
    return [self isKindOfClass:[CYLExternPlusButton class]] || [self cyl_isChildViewControllerPlusButton];
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
        [self cyl_bringSubviewToFront:self.cyl_tabBadgePointView];
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
    LOTAnimationView *animationView = nil;
    for (UILabel *subview in self.subviews) {
        if ([subview cyl_isLottieAnimationView]) {
            animationView = (LOTAnimationView *)subview;
            return animationView;
        }
        for (UILabel *subsubview in subview.subviews) {
            if ([subsubview cyl_isLottieAnimationView]) {
                animationView = (LOTAnimationView *)subsubview;
                return animationView;
            }
        }
    }
    return nil;
}

#define cyl_replaceTabImageViewWithNewViewcyl_isReadydelaySeconds 0
- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                      show:(BOOL)show {
    [self cyl_replaceTabImageViewWithNewView:newView offset:UIOffsetZero show:show completion:^(BOOL isReplaced, UIControl *tabBarButton, UIView *newView) {
    }];
}

- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                           offset:(UIOffset)offset
                                    show:(BOOL)theShow
                                        completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [self cyl_replaceTabImageViewOrTabButton:NO newView:newView offset:offset show:theShow shouldAutoHideNewView:YES completion:completion];
}

- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [self cyl_replaceTabImageViewOrTabButton:YES newView:newView offset:offset show:theShow shouldAutoHideNewView:YES completion:completion];
}

- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                      show:(BOOL)show {
        [self cyl_replaceTabButtonWithNewView:newView offset:UIOffsetZero show:show completion:^(BOOL isReplaced, UIControl *tabBarButton, UIView *newView) {
            if (isReplaced) {
                tabBarButton.cyl_swappableImageViewViewInTabBarButton.hidden = YES;
            }
        }];
}

- (void)cyl_coverVisiableTabImageViewOrTabButton:(BOOL)isTabButton
                               newView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                           delayIfNeededForSeconds:(CGFloat)delay
                              completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [(self.cyl_platterSelectedControl ?: self) cyl_coverTabImageViewOrTabButton:isTabButton newView:newView offset:offset show:theShow delayIfNeededForSeconds:delay completion:completion];
}

- (void)cyl_coverTabImageViewOrTabButton:(BOOL)isTabButton
                               newView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                           delayIfNeededForSeconds:(CGFloat)delay
                              completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    UIControl *selectedTabButton = self;
    NSUInteger delaySeconds = selectedTabButton.cyl_isReady ? 0 : delay;
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySeconds * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^{
        //如果是Lottie 动画icon需要添加延迟， 否则， 会在lottie动画未初始化完成前， 就替换， 位置错误。
        [self cyl_replaceTabImageViewOrTabButton:isTabButton newView:newView offset:offset show:theShow shouldAutoHideNewView:NO shouldHideOriginalView:NO completion:^(BOOL isReplaced, UIControl *tabBarButton, UIView *newView) {
            //FIXME:  #480
            if (isReplaced) {
                tabBarButton.cyl_swappableImageViewViewInTabBarButton.hidden = YES;
                // tabBarButton.cyl_platterNormalControl.cyl_swappableImageViewViewInTabBarButton.hidden = YES;
            }
            if (theShow) {
//                [tabBarButton cyl_clearBadge];
                [tabBarButton cyl_performSelector:@selector(cyl_clearBadge)];
            } else {
                [tabBarButton cyl_performSelector:@selector(cyl_resumeBadge)];

            }
            !completion?:completion(isReplaced, tabBarButton, newView);
            
        }];
    });
}

- (void)cyl_replaceTabImageViewOrTabButton:(BOOL)isTabButton
                               newView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                     shouldAutoHideNewView:(BOOL)shouldAutoHideNewView
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    [self cyl_replaceTabImageViewOrTabButton:isTabButton newView:newView offset:offset show:theShow shouldAutoHideNewView:shouldAutoHideNewView shouldHideOriginalView:YES completion:completion];
}

- (void)cyl_replaceTabImageViewOrTabButton:(BOOL)isTabButton
                               newView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                    shouldAutoHideNewView:(BOOL)shouldAutoHideNewView
                    shouldHideOriginalView:(BOOL)shouldHideOriginalView
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion {
    UIControl *tabBarButton = self;//_UITabButton
     UIImageView *swappableImageView = tabBarButton.cyl_tabImageView;

    if (swappableImageView) {
        // swappableImageView.hidden = theShow;
    }
    UIView *replacedView = swappableImageView;
    if (isTabButton) {
        replacedView = tabBarButton;
    }
    if (!replacedView) {
        !completion?:completion(NO, self, nil);

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
    if (shouldHideOriginalView) {
        swappableImageView.hidden = (show);
    }
    if (isTabButton && shouldHideOriginalView) {
        tabBarButton.cyl_tabLabel.hidden = (show);
    }
    BOOL shouldShowNewView = show && !newView.superview;
    BOOL shouldRemoveNewView = newView.superview;
    if (shouldShowNewView) {
        [tabBarButton addSubview:newView];
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
    if (shouldRemoveNewView && shouldAutoHideNewView) {
        [newView removeFromSuperview];
        newView = nil;
        !completion?:completion(NO, self, nil);
        return;
    }
    //    });
    !completion?:completion(NO, self, nil);
}

- (void)cyl_addLottieImageWithLottieURL:(NSURL *)lottieURL
                                   size:(CGSize)size {
#if __has_include(<Lottie/Lottie.h>)
    if (!lottieURL) {
        return;
    }
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

- (void)cyl_animationLottieImageWithLottieURL:(NSURL *)lottieURL
                                               size:(CGSize)size
                                    defaultSelected:(BOOL)defaultSelected {
#if __has_include(<Lottie/Lottie.h>)
    if (!lottieURL) {
        return;
    }
    //_UITabButton
    [self cyl_addLottieImageWithLottieURL:lottieURL size:size];
    LOTAnimationView *lottieView = self.cyl_lottieAnimationView;
    if (!lottieView) {
        [self cyl_addLottieImageWithLottieURL:lottieURL size:size];
    }
    
    if (lottieView && [lottieView isKindOfClass:[LOTAnimationView class]]) {
        if (defaultSelected) {
            lottieView.animationProgress = 1;
            [lottieView forceDrawingUpdate];
            return;
        }
        lottieView.animationProgress = 0;
        [lottieView play];
    }
#else
#endif
}

- (void)cyl_stopAnimationOfLottieView {
#if __has_include(<Lottie/Lottie.h>)
    if ([self.cyl_tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        if (self.cyl_lottieAnimationView) {
            [self.cyl_lottieAnimationView stop];
        }
    } else
        if ([self.cyl_tabBarController.tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
            if (self.cyl_lottieAnimationView) {
                [self.cyl_lottieAnimationView stop];
            }
        }
#else
#endif
}

#pragma mark - private method

- (UIView *)cyl_defaultTabBadgePointView {
    UIView *defaultRedTabBadgePointView = [UIView cyl_tabBadgePointViewWithClolor:[UIColor redColor] radius:4.5];
    return defaultRedTabBadgePointView;
}

//- (CGFloat)cyl_xOffset {
//    if (![CYLConstants isUsedLiquidGlass]) {
//        return 0.0f;
//    }
//    CGFloat boundsWidthOffset;// = (CYLScreenWidth() - self.cyl_boundsSize.width) * 0.5;
//    
//    return boundsWidthOffset;
//}

- (UIControl *)cyl_platterSelectedControl {
    if (![self.cyl_tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return nil;
    }
    UIControl *selectedContentControl = [self.cyl_tabBarController.tabBar cyl_selectedContentControlFromContentControl:self];
    if (!selectedContentControl) {
        selectedContentControl = self;
    }
    return selectedContentControl;
}

- (BOOL)cyl_isPlatterSelectedControl {
    if (self.cyl_tabBarController.tabBar && [self.cyl_tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return [self.superview cyl_isPlatterSelectedContentView];

    }
    return NO;
}

- (BOOL)cyl_isPlatterNormalControl {
    if (self.cyl_tabBarController.tabBar && [self.cyl_tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return [self.superview cyl_isPlatterContentView];
    }
    return NO;
}

- (UIControl *)cyl_platterNormalControl {
    UIControl *platterNormalControl = [self.cyl_tabBarController.tabBar cyl_normalContentControlFromSelectedContentControl:self];
    if (!platterNormalControl) {
        platterNormalControl = self;
    }
    return platterNormalControl;
}

- (void)cyl_hideControl {
    UIControl *control = self;
    UIControl *selectedControl = self.cyl_platterSelectedControl;
    //            control.layer.zPosition = - MAXFLOAT;
    //            selectedControl.layer.zPosition = - MAXFLOAT;
    //            [self sendSubviewToBack:control];
    control.hidden = YES;
    control.cyl_tabLabel.hidden = YES;
    control.cyl_swappableImageViewViewInTabBarButton.hidden = YES;
    //            [control.superview sendSubviewToBack:control];
    //            control.cyl_shouldNotSelect = YES;
    //            control.backgroundColor = [UIColor greenColor];
    control.userInteractionEnabled = NO;
    //            control.focused = NO;
    //            control.focused = NO;
    //            selectedControl.userInteractionEnabled = NO;
    //            [self sendSubviewToBack:selectedControl];
    
    selectedControl.hidden = YES;
    selectedControl.cyl_swappableImageViewViewInTabBarButton.hidden = YES;
    selectedControl.cyl_tabLabel.hidden = YES;
    selectedControl.userInteractionEnabled = NO;
    
    //            selectedControl.cyl_shouldNotSelect = YES;
    
    //            selectedControl.backgroundColor = [UIColor redColor];
    
}
- (void)cyl_performSelector:(SEL)aSelector {
    if (aSelector == NULL) { return; }
    NSObject *obj = nil;
    [self cyl_performSelector:aSelector withObject:obj];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object {
    if (aSelector == NULL) { return; }
    NSObject *obj = nil;
    [self cyl_performSelector:aSelector withObject:object withObject:obj];
}

- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2 {
    if (aSelector == NULL) { return; }
    UIControl *normalControl = nil;
    UIControl *selectedControl = nil;
    if (![self isKindOfClass:[UIControl class]]) {
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

@end

