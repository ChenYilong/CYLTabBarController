/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

//CYLBadgeProtocol is a protocol which any Class supported (such UIView and UIBarButtonItem) should confirm
//At present, there are two classes support CYLBadgeExtention(UIView and UIBarButtonItem). However, there may be more classes to support. Thus, it is necessary to abstract a protocol. 20260812.


#ifndef CYLBadgeDemo_CYLBadgeProtocol_h
#define CYLBadgeDemo_CYLBadgeProtocol_h

#pragma mark -- types definition

#define CYLBadgeBreatheAnimationKey     @"breathe"
#define CYLBadgeRotateAnimationKey      @"rotate"
#define CYLBadgeShakeAnimationKey       @"shake"
#define CYLBadgeScaleAnimationKey       @"scale"
#define CYLBadgeBounceAnimationKey      @"bounce"

typedef NS_ENUM(NSUInteger, CYLBadgeStyle) {
    CYLBadgeStyleRedDot = 1,          /* red dot style */
    CYLBadgeStyleNumber,              /* badge with number */
    CYLBadgeStyleNew,                  /* badge with a fixed text "new" */
    CYLBadgeStyleOther                /* badge with a fixed text */
};

typedef NS_ENUM(NSUInteger, CYLBadgeAnimationType) {
    CYLBadgeAnimationTypeNone = 0,         /* without animation, badge stays still */
    CYLBadgeAnimationTypeScale,            /* scale effect */
    CYLBadgeAnimationTypeShake,            /* shaking effect */
    CYLBadgeAnimationTypeBounce,           /* bouncing effect */
    CYLBadgeAnimationTypeBreathe           /* breathing light effect, which makes badge more attractive */
};

#pragma mark -- protocol definition

@protocol CYLBadgeProtocol <NSObject>

@required
/** badge entity, which is adviced not to set manually */
@property (nonatomic, strong, getter=cyl_badge, setter=cyl_setBadge:) UILabel *cyl_badge;
/** [UIFont boldSystemFontOfSize:9] by default if not set */
@property (nonatomic, strong, getter=cyl_badgeFont, setter=cyl_setBadgeFont:) UIFont *cyl_badgeFont;
/** red color by default if not set */
@property (nonatomic, strong, getter=cyl_badgeBackgroundColor, setter=cyl_setBadgeBackgroundColor:) UIColor *cyl_badgeBackgroundColor;
/** white color by default if not set */
@property (nonatomic, strong, getter=cyl_badgeTextColor, setter=cyl_setBadgeTextColor:) UIColor *cyl_badgeTextColor;
/** we have optimized the badge frame and center. This property is adviced not to set manually */
@property (nonatomic, assign, getter=cyl_badgeFrame, setter=cyl_setBadgeFrame:) CGRect cyl_badgeFrame;

@property (nonatomic, strong, getter=cyl_badgeFrameValue, setter=cyl_setBadgeFrameValue:) NSValue *cyl_badgeFrameValue;

/** offset from right-top corner. {0,0} by default
 For x, negative number means left offset
 For y, negative number means bottom offset
 */
@property (nonatomic, assign, getter=cyl_badgeCenterOffset, setter=cyl_setBadgeCenterOffset:) CGPoint cyl_badgeCenterOffset;
@property (nonatomic, strong, getter=cyl_badgeCenterOffsetValue, setter=cyl_setBadgeCenterOffsetValue:) NSValue *cyl_badgeCenterOffsetValue;

/** NOTE that this is not animation type of badge's appearing, nor  hidding*/
@property (nonatomic, assign, getter=cyl_badgeAnimationType, setter=cyl_setBadgeAnimationType:) CYLBadgeAnimationType cyl_badgeAnimationType;

@property (nonatomic, strong, getter=cyl_badgeAnimationTypeValue, setter=cyl_setBadgeAnimationTypeValue:) NSNumber *cyl_badgeAnimationTypeValue;

/** for CYLBadgeStyleNumber style badge,if badge value is above badgeMaximumBadgeNumber, "badgeMaximumBadgeNumber+" will be printed. */
@property (nonatomic, assign, getter=cyl_badgeMaximumBadgeNumber, setter=cyl_setBadgeMaximumBadgeNumber:) NSInteger cyl_badgeMaximumBadgeNumber;

@property (nonatomic, strong, getter=cyl_badgeMaximumBadgeNumberValue, setter=cyl_setBadgeMaximumBadgeNumberValue:) NSNumber *cyl_badgeMaximumBadgeNumberValue;

@property (nonatomic, assign, getter=cyl_badgeRadius, setter=cyl_setBadgeRadius:) CGFloat cyl_badgeRadius;

@property (nonatomic, strong, getter=cyl_badgeRadiusValue, setter=cyl_setBadgeRadiusValue:) NSNumber *cyl_badgeRadiusValue;

/** normal use for text and number style of badge, 8 by default*/
@property (nonatomic, assign, getter=cyl_badgeMargin, setter=cyl_setBadgeMargin:) CGFloat cyl_badgeMargin;

@property (nonatomic, strong, getter=cyl_badgeMarginValue, setter=cyl_setBadgeMarginValue:) NSNumber *cyl_badgeMarginValue;

@property (nonatomic, assign, getter=cyl_badgeCornerRadius, setter=cyl_setBadgeCornerRadius:) CGFloat cyl_badgeCornerRadius;

@property (nonatomic, strong, getter=cyl_badgeCornerRadiusValue, setter=cyl_setBadgeCornerRadiusValue:) NSNumber *cyl_badgeCornerRadiusValue;

@property (nonatomic, assign, getter=cyl_delayIfNeededForSeconds, setter=cyl_setDelayIfNeededForSeconds:) CGFloat cyl_delayIfNeededForSeconds;

/**
 *  @attention 展示红点，注意该方法是基于 UIViewController ，所以内部使用[self cyl_getViewControllerInsteadOfNavigationController] 以防止将红点展示在 UINavigationController上，而导致展示与隐藏红点不一致。
 */
- (BOOL)cyl_isShowBadge;

/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 *  @attention 展示红点，注意该方法是基于 UIViewController ，所以内部使用[self cyl_getViewControllerInsteadOfNavigationController] 以防止将红点展示在 UINavigationController上，而导致展示与隐藏红点不一致。
 */
- (void)cyl_showBadge;

/**
 *
 *  @param value String value, default is `nil`. if value equal @"" means red dot style.
 *  @param animationType  animationType
 *  @attention
 - 调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 - 不支持 CYLPlusChildViewController 对应的 TabBarItem 角标设置，调用会被忽略。
 */
- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType;
//- (void)cyl_showBadgeValue:(NSString *)value
//             animationTypeValue:(NSNumber *)animationTypeValue;

/**
 *  clear badge(hide badge)
 *  @attention 隐藏红点，注意该方法是基于 UIViewController ，所以内部使用[self cyl_getViewControllerInsteadOfNavigationController] 以防止将红点展示在 UINavigationController上，而导致展示与隐藏红点不一致。
 */
- (void)cyl_clearBadge;

/**
 *  make bage(if existing) not hiden
 */
- (void)cyl_resumeBadge;

- (BOOL)cyl_isPauseBadge;


/*!
 * @return UIView or UITabBarItem
 */
- (id)cyl_getActualBadgeSuperView;

- (BOOL)cyl_isReady;

- (void)cyl_performSelector:(SEL)aSelector;
- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object;
- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;
@end

#endif
