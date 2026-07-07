/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "UIView+CYLBadgeExtention.h"
#import <objc/runtime.h>
#import "CAAnimation+CYLBadgeExtention.h"
#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"
#import "UIView+CYLTabBarControllerExtention.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "CYLTabBarBadgeView.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#endif


#define kCYLBadgeDefaultMaximumBadgeNumber 99
#define kCYLBadgeDefaultMargin (8.0)
#define kCYLBadgeDefaultDelayIfNeededForSeconds (0.5)

static const CGFloat kCYLBadgeDefaultRedDotRadius = 4.f;

@implementation UIView (CYLBadgeExtention)

#pragma mark -- public methods

- (BOOL)cyl_isReady {

    if (![self cyl_badgeClass]) {
        return NO;
    }
//    if (!CYLGetRootViewController()) {
    //UIBarButton not ready, so if you use for BarButton, we cannot add redpoint. so i delete this judge.
//        return NO;
//    }
    UIView *view = [self cyl_getActualBadgeSuperView];

    if (view && [view isKindOfClass:[UIView class]]) {
        return view.frame.size.width > 10;
    }
    return [view cyl_findBarButtonContentView].frame.size.width > 10;
}
/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
- (void)cyl_showBadge {
    [self cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeNone];
}

- (void)cyl_showBadgeValue:(NSString *)value
        animationTypeValue:(NSNumber *)animationTypeValue {
    CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
    (
     [[[self cyl_badge] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
     if ([self cyl_shouldUpdateBadgeSubviews]) {
         [[self cyl_badge] removeFromSuperview];
         id view = nil;
         [self cyl_setBadge:view];
     }
     );
    CYLBadgeAnimationType animationType = [animationTypeValue intValue];
    [self  cyl_setBadgeAnimationTypeValue:@(animationType)];
    [self cyl_showBadgeWithValue:value];
    
    if (animationType != CYLBadgeAnimationTypeNone) {
        [self cyl_beginAnimation];
    }
}

- (void)cyl_showBadgeValue:(NSString *)value animationType:(CYLBadgeAnimationType)animationType {
    [self cyl_showBadgeValue:value animationTypeValue:@(animationType)];
}

- (void)cyl_showBadgeValue:(NSString *)value {
    [self cyl_showBadgeValue:value animationType:CYLBadgeAnimationTypeNone];
}

#pragma mark -- private methods
/**
 By swizzling the original method - (void)willMoveToSuperview:(UIView *)newSuperview;
 Move the badge view on top of its siblings when its super view appears every time for adjustment on iOS 11.
 */
- (void)cyl_willMoveToSuperview:(UIView *)newSuperview __IOS_AVAILABLE(11.0) {
    [self cyl_willMoveToSuperview:newSuperview];
    
    if (newSuperview && self.cyl_badge) {
        [self cyl_bringBadgeToFront:self.cyl_badge];
    }
}

- (void)cyl_showBadgeWithValue:(NSString *)value {
    if (!value) {
        return;
    }
    NSCharacterSet *numberSet = [NSCharacterSet decimalDigitCharacterSet];
    NSString *trimmedString = [value stringByTrimmingCharactersInSet:numberSet];
    BOOL isNumber = NO;
    if ((trimmedString.length == 0) && (value.length > 0)) {
        isNumber = YES;
    }
    if (isNumber) {
        [self cyl_showNumberBadgeWithValue:[value integerValue]];
        return;
    }
    
    if ([value isEqualToString:@""]) {
        [self cyl_showRedDotBadge];
        return;
    }
    if ([value isEqualToString:@"new"] || [value isEqualToString:@"NEW"] ) {
        [self cyl_showNewBadge:value];
        return;
    }
    [self cyl_showTextBadge:value];
}

/**
 *  clear badge
 */
- (void)cyl_clearBadge {
    [self.cyl_badge cyl_setHidden:YES];
}

- (BOOL)cyl_isShowBadge {
    return (self.cyl_badge && !self.cyl_badge.cyl_isHidden);
}

/**
 *  make bage(if existing) not hiden
 */
- (void)cyl_resumeBadge {
    if (self.cyl_isPauseBadge) {
        [self.cyl_badge cyl_setHidden:NO];
    }
}

- (BOOL)cyl_isPauseBadge {
    return (self.cyl_badge && self.cyl_badge.cyl_isHidden);
}

- (id)cyl_getActualBadgeSuperView {
    //建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame.自动布局 cell 需要调用 [self layoutIfNeeded] frame才有值，角标才能找到对应的位置。 需要确保view showBadge的方法 在layoutIfNeeded之后调用
    [self layoutIfNeeded];
    return self;
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

#pragma mark -- private methods

- (void)cyl_addMargin {
    CGRect frame = self.cyl_badge.frame;
    frame.size.width += self.cyl_badgeMargin;
    frame.size.height += self.cyl_badgeMargin;
    if(CGRectGetWidth(frame) < CGRectGetHeight(frame)) {
        frame.size.width = CGRectGetHeight(frame);
    }
    self.cyl_badge.frame = frame;
}

- (void)cyl_showRedDotBadge {
    if (![self cyl_isReady]) {
        return;
    }
    [self cyl_badgeInit];
    //if badge has been displayed and, in addition, is was not red dot style, we must update UI.
    if (self.cyl_badge.tag != CYLBadgeStyleRedDot) {
        self.cyl_badge.text = @"";
        self.cyl_badge.tag = CYLBadgeStyleRedDot;
        [self cyl_resetRedDotBadgeFrame];
        self.cyl_badge.layer.cornerRadius = CGRectGetWidth(self.cyl_badge.frame) / 2;
    }
    [self.cyl_badge cyl_setHidden:NO];
}

- (void)cyl_showNewBadge:(NSString *)value {
    if (![self cyl_badgeClass]) {
        return;
    }
    CGSize size = [value sizeWithAttributes:
                   @{NSFontAttributeName:
                         self.cyl_badgeFont}];
    float labelHeight = ceilf(size.height)+ self.cyl_badgeMargin;
    [self cyl_setBadgeCornerRadius:labelHeight/3];
    [self cyl_showTextBadge:value];
}

- (void)cyl_showTextBadge:(NSString *)value {
    if (![self cyl_isReady]) {
        return;
    }
    if (value == 0 || !value ||value.length == 0) {
        [self.cyl_badge cyl_setHidden:YES];

        return;
    }
    [self cyl_badgeInit];
    self.cyl_badge.tag = CYLBadgeStyleOther;
    self.cyl_badge.text = value;
    self.cyl_badge.font = self.cyl_badgeFont;
    [self cyl_adjustLabelWidth:self.cyl_badge];
    [self cyl_addMargin];
    self.cyl_badge.center = CGPointMake(CGRectGetWidth(self.frame) + 2 + self.cyl_badgeCenterOffset.x, self.cyl_badgeCenterOffset.y);
    //FIXME:  to delete
    self.cyl_badge.layer.cornerRadius = (self.cyl_badgeCornerRadius !=0 ) ? self.cyl_badgeCornerRadius : CGRectGetHeight(self.cyl_badge.frame) / 2;
    [self.cyl_badge cyl_setHidden:NO];
}

- (void)cyl_showNumberBadgeWithValue:(NSInteger)value {
    if (![self cyl_badgeClass]) {
        return;
    }
    if (value <= 0) {
        [self.cyl_badge cyl_setHidden:YES];
        return;
    }
    [self cyl_badgeInit];
    [self.cyl_badge cyl_setHidden:(value == 0)];
    self.cyl_badge.tag = CYLBadgeStyleNumber;
    NSString *text = (value > self.cyl_badgeMaximumBadgeNumber ?
                      [NSString stringWithFormat:@"%@+", @(self.cyl_badgeMaximumBadgeNumber)] :
                      [NSString stringWithFormat:@"%@", @(value)]);
    [self cyl_showTextBadge:text];
}

//lazy loading
- (void)cyl_badgeInit {
    if (![self cyl_isReady]) {
        return;
    }
    if (self.cyl_badgeBackgroundColor == nil) {
        self.cyl_badgeBackgroundColor = [UIColor redColor];
    }
    if (self.cyl_badgeTextColor == nil) {
        self.cyl_badgeTextColor = [UIColor whiteColor];
    }
    
    if (!self.cyl_badge) {
        if (![self cyl_isReady]) {
            return;
        }
        Class class = [self cyl_badgeClass];
        self.cyl_badge = [[class alloc] initWithFrame:(self.frame)];
//        self.cyl_badge = [[class alloc] init];

        [self cyl_resetRedDotBadgeFrame];
        self.cyl_badge.textAlignment = NSTextAlignmentCenter;
        self.cyl_badge.textColor = self.cyl_badgeTextColor;
        self.cyl_badge.text = @"";
        self.cyl_badge.layer.cornerRadius = CGRectGetWidth(self.cyl_badge.frame) / 2;
        self.cyl_badge.layer.masksToBounds = YES;//very important
        [self.cyl_badge cyl_setHidden:YES];
        
        self.cyl_badge.backgroundColor = self.cyl_badgeBackgroundColor;
        
        [self cyl_bringBadgeToFront:self.cyl_badge];
    }
}

- (void)cyl_bringBadgeToFront:(CYLTabBarBadgeView *)view {
    if (![self cyl_isReady]) {
        return;
    }
    [self addSubview:view];
    [self bringSubviewToFront:view];
    view.layer.zPosition = MAXFLOAT;
    __weak __typeof(self) weakSelf = self;
    void (^CYLTabBarItemLottieAnimationPlayingNotificationBlock)(NSNotification *) = ^(NSNotification *notification) {
        __strong typeof(self) self = weakSelf;
        if (!self) {
             return;
        }
//        [self cyl_setBadge:nil];
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
//             [[[self cyl_badge] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
//             if ([self cyl_shouldUpdateBadgeSubviews]) {
//                 [[self cyl_badge] removeFromSuperview];
//                 id view = nil;
//                 [self cyl_setBadge:view];
//             }
             );
    };
    [[NSNotificationCenter defaultCenter] addObserverForName:CYLTabBarStyleTypeDidChangeNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:CYLTabBarItemLottieAnimationPlayingNotificationBlock];
//    [self cyl_setBadge:view];

}

- (void)cyl_resetRedDotBadgeFrame {
    CGFloat redotWidth = kCYLBadgeDefaultRedDotRadius *2;
    if (self.cyl_badgeRadius) {
        redotWidth = self.cyl_badgeRadius * 2;
    }
    if (!self.cyl_badge) {
        return;
    }
    CGRect frame = CGRectMake(CGRectGetWidth(self.frame), -redotWidth, redotWidth, redotWidth);
    self.cyl_badge.frame = frame;
    //更新frame
    [self.cyl_badge layoutIfNeeded];
    self.cyl_badge.center = CGPointMake(CGRectGetWidth(self.frame) + 2 + self.cyl_badgeCenterOffset.x, self.cyl_badgeCenterOffset.y);
    self.cyl_badge.layer.masksToBounds = YES;//very important
    
}

#pragma mark --  other private methods
- (void)cyl_adjustLabelWidth:(CYLTabBarBadgeView *)badgeSuperView {
    if (!badgeSuperView) {
        return;
    }
    //获得子视图的Label以获得字符长度。用以拉伸父视图
    UILabel *label;
    if ([badgeSuperView isKindOfClass:[UILabel class] ]) {
        label = (UILabel *)badgeSuperView;
    } else {
        
        SEL actoin = NSSelectorFromString(@"badgeLabel");
        if ([badgeSuperView respondsToSelector:actoin]) {
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
             label = [badgeSuperView performSelector:actoin];

                                                    )
        }
    }
    if (!label.text || 0 == label.text.length) {
        return;
    }
    CGSize labelsize = [self cyl_getLabelSize:label];
    if (CGSizeEqualToSize(CGSizeZero, labelsize)) {
        return;
    }
//    CGSize labelsize = [self sizeThatFits:CGSizeMake(CYLScreenWidth() ,CYLScreenHeight())];
    CGRect frame = label.frame;
    frame.size = CGSizeMake(ceilf(labelsize.width), ceilf(labelsize.height));
//    获得字符长度后， 需要修改父视图的宽度， 仅仅修改Label无法达到真正的拉伸效果
        [label setFrame:frame];

    [badgeSuperView setFrame:frame];

}

- (CGSize)cyl_getLabelSize:(UILabel *)label {
    [label setNumberOfLines:0];
    NSString *s = label.text;
    UIFont *font = label.font;
    CGSize size = CGSizeMake(CYLScreenWidth() ,CYLScreenHeight());
    CGSize labelsize;
    
    if (![s respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
        
        CYL_DEPRECATED_DECLARATIONS_PUSH
        labelsize = [s sizeWithFont:font constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];
        CYL_DEPRECATED_DECLARATIONS_POP
    } else {
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [style setLineBreakMode:NSLineBreakByWordWrapping];
        
        labelsize = [s boundingRectWithSize:size
                                    options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                 attributes:@{ NSFontAttributeName:font, NSParagraphStyleAttributeName : style}
                                    context:nil].size;
    }
    return labelsize;
}

#pragma mark -- animation

//if u want to add badge animation type, follow steps bellow:
//1. go to definition of CYLBadgeAnimationType and add new type
//2. go to category of CAAnimation+CYLBadgeExtention to add new animation interface
//3. call that new interface here
- (void)cyl_beginAnimation {
    CGFloat moveDistance = self.cyl_badge.frame.size.width * 1.5;
    if (!self.cyl_badge) {
        return;
    }
    switch(self.cyl_badgeAnimationType) {
        case CYLBadgeAnimationTypeBreathe:
            [self.cyl_badge.layer addAnimation:[CAAnimation cyl_opacityForever_Animation:1.4]
                                        forKey:CYLBadgeBreatheAnimationKey];
            break;
        case CYLBadgeAnimationTypeShake:
            [self.cyl_badge.layer addAnimation:[CAAnimation cyl_shake_AnimationRepeatTimes:CGFLOAT_MAX
                                                                                  durTimes:1
                                                                                    forObj:self.cyl_badge.layer]
                                        forKey:CYLBadgeShakeAnimationKey];
            break;
        case CYLBadgeAnimationTypeScale:
            [self.cyl_badge.layer addAnimation:[CAAnimation cyl_scaleFrom:1.4
                                                                  toScale:0.6
                                                                 durTimes:1
                                                                      rep:MAXFLOAT]
                                        forKey:CYLBadgeScaleAnimationKey];
            break;
        case CYLBadgeAnimationTypeBounce:
            [self.cyl_badge.layer addAnimation:[CAAnimation cyl_bounce_AnimationRepeatTimes:CGFLOAT_MAX
                                                                                   durTimes:1
                                                                                     forObj:self.cyl_badge.layer]
                                        forKey:CYLBadgeBounceAnimationKey];
            break;
            
            
            /*!
             *
             
             
             
             
             
             
             
             
             */
        case CYLBadgeAnimationTypeLeftRightOnce:        /* left to right animation*/
            
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_leftRight_AnimationMoveDistance:moveDistance
                                                             repeatTimes:1
                                                                durTimes:0.5]
                                        forKey:CYLBadgeLeftRightOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeRightLeftOnce:        /* right to left animation*/
            
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_rightLeft_AnimationMoveDistance:moveDistance
                                                             repeatTimes:1
                                                                durTimes:0.5]
                                        forKey:CYLBadgeRightLeftOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeFadeInOnce:           /* fade in animation */
            
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_fadeIn_AnimationRepeatTimes:1
                                                            durTimes:1.5]
                                        forKey:CYLBadgeFadeInOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeRollingOnce:           /*rolling animation*/
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_rolling_AnimationRepeatTimes:1
                                                             durTimes:0.5]
                                        forKey:CYLBadgeRollingOnceAnimationKey];
            break;
            
        case CYLBadgeAnimationTypeScaleOnce:           /*ScaleOnce animation*/
            [self.cyl_badge.layer addAnimation:
             [CAAnimation cyl_badge_once_scale_AnimationRepeatTimes:1
                                                           durTimes:0.5]
                                        forKey:CYLBadgeScaleOnceAnimationKey];
            
            
            break;
            
            
            
        case CYLBadgeAnimationTypeNone:
        default:
            
            break;
    }
}


- (void)cyl_removeAnimation {
    if (self.cyl_badge) {
        [self.cyl_badge.layer removeAllAnimations];
    }
}

#pragma mark -- setter/getter

- (UIView *)cyl_badge {
    return objc_getAssociatedObject(self, @selector(cyl_badge));
}

- (void)cyl_setBadge:(UIView *)label {
    objc_setAssociatedObject(self, @selector(cyl_badge), label, OBJC_ASSOCIATION_RETAIN);
}

- (UIFont *)cyl_badgeFont {
    id font = objc_getAssociatedObject(self, @selector(cyl_badgeFont));
    return font ?: kCYLBadgeDefaultFont;
}

- (void)cyl_setBadgeFont:(UIFont *)badgeFont {
    objc_setAssociatedObject(self, @selector(cyl_badgeFont), badgeFont, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.font = badgeFont;
}

- (UIColor *)cyl_badgeBackgroundColor {
    return objc_getAssociatedObject(self, @selector(cyl_badgeBackgroundColor));
}

- (void)cyl_setBadgeBackgroundColor:(UIColor *)badgeBackgroundColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeBackgroundColor), badgeBackgroundColor, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.backgroundColor = badgeBackgroundColor;
}

- (UIColor *)cyl_badgeTextColor {
    return objc_getAssociatedObject(self, @selector(cyl_badgeTextColor));
}

- (void)cyl_setBadgeTextColor:(UIColor *)badgeTextColor {
    objc_setAssociatedObject(self, @selector(cyl_badgeTextColor), badgeTextColor, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.textColor = badgeTextColor;
}

- (CYLBadgeAnimationType)cyl_badgeAnimationType {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeAnimationType));
    if(obj != nil && [obj isKindOfClass:[NSNumber class]]) {
        return [obj integerValue];
    }
    return CYLBadgeAnimationTypeNone;
}

- (void)cyl_setBadgeAnimationType:(CYLBadgeAnimationType)animationType {
    NSNumber *numObj = @(animationType);
    objc_setAssociatedObject(self, @selector(cyl_badgeAnimationType), numObj, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    [self cyl_removeAnimation];
    [self cyl_beginAnimation];
}

- (void)cyl_setBadgeAnimationTypeValue:(NSNumber *)cyl_badgeAnimationTypeValue {
    CYLBadgeAnimationType badgeAnimationType = [cyl_badgeAnimationTypeValue integerValue];
    [self cyl_setBadgeAnimationType:badgeAnimationType];
}
- (NSNumber *)cyl_badgeAnimationTypeValue {
    return @([self cyl_badgeAnimationType]);
}

- (CGRect)cyl_badgeFrame {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeFrame));
    if (obj != nil && [obj isKindOfClass:[NSDictionary class]] && [obj count] == 4) {
        CGFloat x = [obj[@"x"] floatValue];
        CGFloat y = [obj[@"y"] floatValue];
        CGFloat width = [obj[@"width"] floatValue];
        CGFloat height = [obj[@"height"] floatValue];
        return  CGRectMake(x, y, width, height);
    }
    return CGRectZero;
}

- (void)cyl_setBadgeFrameValue:(NSValue *)cyl_badgeFrameValue {
    CGRect badgeFrame = cyl_badgeFrameValue.CGRectValue;
    [self cyl_setBadgeFrame:badgeFrame];
}

- (NSValue *)cyl_badgeFrameValue {
    return [NSValue valueWithCGRect:[self cyl_badgeFrame]];
}

- (void)cyl_setBadgeFrame:(CGRect)badgeFrame {
    NSDictionary *frameInfo = @{@"x" : @(badgeFrame.origin.x), @"y" : @(badgeFrame.origin.y),
                                @"width" : @(badgeFrame.size.width), @"height" : @(badgeFrame.size.height)};
    objc_setAssociatedObject(self, @selector(cyl_badgeFrame), frameInfo, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.frame = badgeFrame;
}

- (CGFloat)cyl_badgeCornerRadius {
    NSNumber *badgeCornerRadiusObject = objc_getAssociatedObject(self, @selector(cyl_badgeCornerRadius));
    return [badgeCornerRadiusObject floatValue];
}

- (void)cyl_setBadgeCornerRadius:(CGFloat)badgeCornerRadius {
    NSNumber *badgeCornerRadiusObject = @(badgeCornerRadius);
    objc_setAssociatedObject(self, @selector(cyl_badgeCornerRadius), badgeCornerRadiusObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cyl_setBadgeCornerRadiusValue:(NSNumber *)cyl_badgeCornerRadiusValue {
    CGFloat cyl_badgeCornerRadius = [cyl_badgeCornerRadiusValue floatValue];
    [self cyl_setBadgeCornerRadius:cyl_badgeCornerRadius];
}
- (NSNumber *)cyl_badgeCornerRadiusValue {
    return @([self cyl_badgeCornerRadius]);
}

- (CGPoint)cyl_badgeCenterOffset {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeCenterOffset));
    if (obj != nil && [obj isKindOfClass:[NSDictionary class]] && [obj count] == 2) {
        CGFloat x = [obj[@"x"] floatValue];
        CGFloat y = [obj[@"y"] floatValue];
        return CGPointMake(x, y);
    }
    return CGPointZero;
}

- (void)cyl_setBadgeCenterOffsetValue:(NSValue *)badgeCenterOffsetValue {
    //    [CYL_ACTUAL_BARBUTTON cyl_setBadgeCenterOffset:badgeCenterOffset];
    CGPoint badgeCenterOffset = badgeCenterOffsetValue.CGPointValue;
    [self cyl_setBadgeCenterOffset:badgeCenterOffset];
}

- (NSValue *)cyl_badgeCenterOffsetValue {
    return [NSValue valueWithCGPoint:[self cyl_badgeCenterOffset]];
}

//FIXME:  to delete ios27_ bug
- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOff {
    NSDictionary *cenerInfo = @{@"x" : @(badgeCenterOff.x), @"y" : @(badgeCenterOff.y)};
    objc_setAssociatedObject(self, @selector(cyl_badgeCenterOffset), cenerInfo, OBJC_ASSOCIATION_RETAIN);
    if ([self cyl_shouldUpdateBadgeSubviews]) {
        return;
    }
    //FIXME:  to delete 如果在这里提前初始化， 那么就会导致
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
    self.cyl_badge.center = CGPointMake(CGRectGetWidth(self.frame) + 2 + badgeCenterOff.x, badgeCenterOff.y);
 }

//badgeRadiusKey

- (void)cyl_setBadgeRadius:(CGFloat)badgeRadius {
    objc_setAssociatedObject(self, @selector(cyl_badgeRadius), [NSNumber numberWithFloat:badgeRadius], OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
}

- (void)cyl_setBadgeRadiusValue:(NSNumber *)cyl_badgeRadiusValue {
    CGFloat badgeRadius = [cyl_badgeRadiusValue floatValue];
    [self cyl_setBadgeRadius:badgeRadius];
}

- (NSNumber *)cyl_badgeRadiusValue {
    return @([self cyl_badgeRadius]);
}

- (CGFloat)cyl_badgeRadius {
    return [objc_getAssociatedObject(self, @selector(cyl_badgeRadius)) floatValue];
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    objc_setAssociatedObject(self, @selector(cyl_badgeMargin), [NSNumber numberWithFloat:badgeMargin], OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
}

- (void)cyl_setBadgeMarginValue:(NSNumber *)cyl_badgeMarginValue {
    CGFloat badgeMargin = [cyl_badgeMarginValue floatValue];
    [self cyl_setBadgeMargin:badgeMargin];
}

- (NSNumber *)cyl_badgeMarginValue {
    return @([self cyl_badgeMargin]);
}

- (CGFloat)cyl_badgeMargin {
    id margin = objc_getAssociatedObject(self, @selector(cyl_badgeMargin));
    return margin == nil ? kCYLBadgeDefaultMargin : [margin floatValue];
}

- (NSInteger)cyl_badgeMaximumBadgeNumber {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeMaximumBadgeNumber));
    if(obj != nil && [obj isKindOfClass:[NSNumber class]]) {
        return [obj integerValue];
    }
    return kCYLBadgeDefaultMaximumBadgeNumber;
}

- (void)cyl_setBadgeMaximumBadgeNumber:(NSInteger)badgeMaximumBadgeNumber {
    NSNumber *numObj = @(badgeMaximumBadgeNumber);
    objc_setAssociatedObject(self, @selector(cyl_badgeMaximumBadgeNumber), numObj, OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
}

- (void)cyl_setBadgeMaximumBadgeNumberValue:(NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    NSInteger badgeMaximumBadgeNumber = [cyl_badgeMaximumBadgeNumberValue integerValue];
    [self cyl_setBadgeMaximumBadgeNumber:badgeMaximumBadgeNumber];
}

- (NSNumber *)cyl_badgeMaximumBadgeNumberValue {
    return @([self cyl_badgeMaximumBadgeNumber]);
}

- (CGFloat)cyl_delayIfNeededForSeconds {
    NSNumber *delayIfNeededForSecondsObject = objc_getAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds));
    if (!delayIfNeededForSecondsObject) {
        return kCYLBadgeDefaultDelayIfNeededForSeconds;
    }
    return [delayIfNeededForSecondsObject floatValue];
}

- (void)cyl_setDelayIfNeededForSeconds:(CGFloat)delayIfNeededForSeconds {
    NSNumber *delayIfNeededForSecondsObject = @(delayIfNeededForSeconds);
    objc_setAssociatedObject(self, @selector(cyl_delayIfNeededForSeconds), delayIfNeededForSecondsObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)cyl_isHidden {
    return self.cyl_isInvisiable;
}

- (BOOL)cyl_isInvisiable {
    BOOL isSizeZero = CGSizeEqualToSize(CGSizeZero, self.frame.size);
    //这里删除(NO == obj.opaque) ，因为iOS27以上的视图，渲染会通过通过 opaque 设置为 NO 进行，所以这里删除涉及关于 opaque 的判断。
    BOOL isInvisible = (YES == self.hidden ) || (self.alpha <= 0.01f)  || (!self.superview) || isSizeZero;
    return isInvisible;
}

- (BOOL)cyl_canNotResponseEvent {
    return self.cyl_isInvisiable || (NO == self.userInteractionEnabled ) || self.cyl_isPlaceholder;
}

// 不管 image 还是 text 的 UIBarButtonItem 都获取内部的 _UIModernBarButton 即可
- (UIView *)cyl_findBarButtonContentView {
    NSString *classString = NSStringFromClass(self.class);
    if ([classString isEqualToString:@"UITabBarButton"] || [classString isEqualToString:@"_UITabButton"]) {
        // 特别的，对于 UITabBarItem，将 imageView 作为参考 view
        UIView *imageView = [self cyl_tabImageView];
        return imageView;
    }
    
    if ([classString isEqualToString:@"_UIButtonBarButton"]) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:UIButton.class]) {
                return subview;
            }
        }
    }
    
    return self;
}

- (Class)cyl_badgeClass {
//    return [UILabel class];

//    return [CYLTabBarBadgeView class];
    Class badgeClass = nil;
    if (!CYL_IS_IOS_27) {
        return [UILabel class];
    }
    BOOL isCYLTabBarStyleTypeLiquidGlass = [self cyl_isCYLTabBarStyleTypeLiquidGlass];
    
    
     
    if (isCYLTabBarStyleTypeLiquidGlass) {
        badgeClass = [CYLTabBarBadgeView class];
    } else {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        badgeClass = [UILabel class];
#endif
    }
    return badgeClass;
}

- (BOOL)cyl_isCYLTabBarStyleTypeLiquidGlass {
    if (![CYLConstants isLiquidGlassActive]) {
        return NO;
    }
    return YES;
}

- (BOOL)cyl_shouldUpdateBadgeSubviews {
    
//    return YES;

    if (![CYLConstants isLiquidGlassActive]) {
        return NO;
    }
    if (CYL_IS_IOS_27 && ![self.cyl_badge isKindOfClass:[UILabel class]]) {
        return YES;
    }
    return YES;
}

@end

