/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
 */

#import "UIView+CYLBadgeExtention.h"
#import <objc/runtime.h>
#import "CAAnimation+CYLBadgeExtention.h"

#define kCYLBadgeDefaultFont				([UIFont boldSystemFontOfSize:9])

#define kCYLBadgeDefaultMaximumBadgeNumber                     99
#define kCYLBadgeDefaultMargin                (8.0)


static const CGFloat kCYLBadgeDefaultRedDotRadius = 4.f;

@implementation UIView (CYLBadgeExtention)

#pragma mark -- public methods
/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 */
- (void)cyl_showBadge {
    [self cyl_showBadgeValue:@"" animationType:CYLBadgeAnimationTypeNone];
}

- (void)cyl_showBadgeValue:(NSString *)value animationType:(CYLBadgeAnimationType)animationType {
    [[[self cyl_badge] subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

    self.cyl_badgeAnimationType = animationType;
    [self cyl_showBadgeWithValue:value];

    if (animationType != CYLBadgeAnimationTypeNone) {
        [self cyl_beginAnimation];
    }
}

- (void)cyl_showBadgeValue:(NSString *)value {
    [self cyl_showBadgeValue:value animationType:CYLBadgeAnimationTypeNone];
}

#pragma mark -- private methods
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
    self.cyl_badge.hidden = YES;
}

- (BOOL)cyl_isShowBadge {
    return (self.cyl_badge && !self.cyl_badge.hidden );
}

/**
 *  make bage(if existing) not hiden
 */
- (void)cyl_resumeBadge {
    if (self.cyl_isPauseBadge) {
        self.cyl_badge.hidden = NO;
    }
}

- (BOOL)cyl_isPauseBadge {
    return (self.cyl_badge && self.cyl_badge.hidden == YES);
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
    [self cyl_badgeInit];
    //if badge has been displayed and, in addition, is was not red dot style, we must update UI.
    if (self.cyl_badge.tag != CYLBadgeStyleRedDot) {
        self.cyl_badge.text = @"";
        self.cyl_badge.tag = CYLBadgeStyleRedDot;
        [self cyl_resetRedDotBadgeFrame];
        self.cyl_badge.layer.cornerRadius = CGRectGetWidth(self.cyl_badge.frame) / 2;
    }
    self.cyl_badge.hidden = NO;
}

- (void)cyl_showNewBadge:(NSString *)value {
    CGSize size = [value sizeWithAttributes:
                   @{NSFontAttributeName:
                         self.cyl_badgeFont}];
    float labelHeight = ceilf(size.height)+ self.cyl_badgeMargin;
    [self cyl_setBadgeCornerRadius:labelHeight/3];
    [self cyl_showTextBadge:value];
}

- (void)cyl_showTextBadge:(NSString *)value {
    if (value == 0 || !value ||value.length == 0) {
        self.cyl_badge.hidden = YES;
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
    self.cyl_badge.hidden = NO;
}
    
- (void)cyl_showNumberBadgeWithValue:(NSInteger)value {
    if (value <= 0) {
        self.cyl_badge.hidden = YES;
        return;
    }
    [self cyl_badgeInit];
    self.cyl_badge.hidden = (value == 0);
    self.cyl_badge.tag = CYLBadgeStyleNumber;
    NSString *text = (value > self.cyl_badgeMaximumBadgeNumber ?
                      [NSString stringWithFormat:@"%@+", @(self.cyl_badgeMaximumBadgeNumber)] :
                      [NSString stringWithFormat:@"%@", @(value)]);
    [self cyl_showTextBadge:text];
}

//lazy loading
- (void)cyl_badgeInit {
    if (self.cyl_badgeBackgroundColor == nil) {
        self.cyl_badgeBackgroundColor = [UIColor redColor];
    }
    if (self.cyl_badgeTextColor == nil) {
        self.cyl_badgeTextColor = [UIColor whiteColor];
    }
    
    if (!self.cyl_badge) {
        self.cyl_badge = [[UILabel alloc] init];
        [self cyl_resetRedDotBadgeFrame];
        self.cyl_badge.textAlignment = NSTextAlignmentCenter;
        self.cyl_badge.backgroundColor = self.cyl_badgeBackgroundColor;
        self.cyl_badge.textColor = self.cyl_badgeTextColor;
        self.cyl_badge.text = @"";
        self.cyl_badge.layer.cornerRadius = CGRectGetWidth(self.cyl_badge.frame) / 2;
        self.cyl_badge.layer.masksToBounds = YES;//very important
        self.cyl_badge.hidden = YES;
        self.cyl_badge.layer.zPosition = MAXFLOAT;
        [self addSubview:self.cyl_badge];
        [self bringSubviewToFront:self.cyl_badge];
    }
}

- (void)cyl_resetRedDotBadgeFrame {
    CGFloat redotWidth = kCYLBadgeDefaultRedDotRadius *2;
    if (self.cyl_badgeRadius) {
        redotWidth = self.cyl_badgeRadius * 2;
    }
    CGRect frame = CGRectMake(CGRectGetWidth(self.frame), -redotWidth, redotWidth, redotWidth);
    self.cyl_badge.frame = frame;
    self.cyl_badge.center = CGPointMake(CGRectGetWidth(self.frame) + 2 + self.cyl_badgeCenterOffset.x, self.cyl_badgeCenterOffset.y);
}

#pragma mark --  other private methods
- (void)cyl_adjustLabelWidth:(UILabel *)label {
    CGSize labelsize = [self cyl_getLabelSize:label];
    CGRect frame = label.frame;
    frame.size = CGSizeMake(ceilf(labelsize.width), ceilf(labelsize.height));
    [label setFrame:frame];
}

- (CGSize)cyl_getLabelSize:(UILabel *)label {
    [label setNumberOfLines:0];
    NSString *s = label.text;
    UIFont *font = label.font;
    CGSize size = CGSizeMake(CGRectGetWidth([UIScreen mainScreen].bounds) ,CGFLOAT_MAX);
    CGSize labelsize;
    
    if (![s respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        labelsize = [s sizeWithFont:font constrainedToSize:size lineBreakMode:NSLineBreakByWordWrapping];
#pragma clang diagnostic pop
        
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

- (UILabel *)cyl_badge {
    return objc_getAssociatedObject(self, @selector(cyl_badge));
}

- (void)cyl_setBadge:(UILabel *)label {
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

- (CGPoint)cyl_badgeCenterOffset {
    id obj = objc_getAssociatedObject(self, @selector(cyl_badgeCenterOffset));
    if (obj != nil && [obj isKindOfClass:[NSDictionary class]] && [obj count] == 2) {
        CGFloat x = [obj[@"x"] floatValue];
        CGFloat y = [obj[@"y"] floatValue];
        return CGPointMake(x, y);
    } 
        return CGPointZero;
}

- (void)cyl_setBadgeCenterOffset:(CGPoint)badgeCenterOff {
    NSDictionary *cenerInfo = @{@"x" : @(badgeCenterOff.x), @"y" : @(badgeCenterOff.y)};
    objc_setAssociatedObject(self, @selector(cyl_badgeCenterOffset), cenerInfo, OBJC_ASSOCIATION_RETAIN);
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

- (CGFloat)cyl_badgeRadius {
    return [objc_getAssociatedObject(self, @selector(cyl_badgeRadius)) floatValue];
}

- (void)cyl_setBadgeMargin:(CGFloat)badgeMargin {
    objc_setAssociatedObject(self, @selector(cyl_badgeMargin), [NSNumber numberWithFloat:badgeMargin], OBJC_ASSOCIATION_RETAIN);
    if (!self.cyl_badge) {
        [self cyl_badgeInit];
    }
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

- (BOOL)cyl_isInvisiable {
    UIView *obj = self;
    CGFloat width = obj.frame.size.width;
    CGFloat height = obj.frame.size.height;
    BOOL isSizeZero = (width == 0 || height == 0);
    BOOL isInvisible = (obj.hidden == YES) || (obj.alpha <= 0.01f)  || (!obj.superview) || isSizeZero;
    return isInvisible;
}

- (BOOL)cyl_canNotResponseEvent {
    return self.cyl_isInvisiable || (self.userInteractionEnabled == NO);
}

@end
