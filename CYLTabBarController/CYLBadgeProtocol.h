/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

//CYLBadgeProtocol is a protocol which any Class supported (such UIView, UITabBarItem and UIBarButtonItem) should confirm
//At present, there are same classes support CYLBadgeExtention(UIView, UITabBarItem and UIBarButtonItem). However, there may be more classes to support. Thus, it is necessary to abstract a protocol. 20260812.


#ifndef CYLBadgeDemo_CYLBadgeProtocol_h
#define CYLBadgeDemo_CYLBadgeProtocol_h

#import <UIKit/UIKit.h>

#pragma mark -- types definition

#define CYLBadgeBreatheAnimationKey     @"cyl.badge.breathe"
#define CYLBadgeRotateAnimationKey      @"cyl.badge.rotate"
#define CYLBadgeShakeAnimationKey       @"cyl.badge.shake"
#define CYLBadgeScaleAnimationKey       @"cyl.badge.scale"
#define CYLBadgeBounceAnimationKey      @"cyl.badge.bounce"
#define CYLBadgeLeftRightOnceAnimationKey   @"cyl.badge.LeftRightOnce"
#define CYLBadgeRightLeftOnceAnimationKey   @"cyl.badge.RightLeftOnce"
#define CYLBadgeFadeInOnceAnimationKey      @"cyl.badge.FadeInOnce"
#define CYLBadgeRollingOnceAnimationKey     @"cyl.badge.RollingOnce"
#define CYLBadgeScaleOnceAnimationKey     @"cyl.badge.ScaleOnce"

typedef NS_ENUM(NSUInteger, CYLBadgeStyle) {
    CYLBadgeStyleRedDot = 1,          /* red dot style */
    CYLBadgeStyleNumber,              /* badge with number */
    CYLBadgeStyleNew,                 /* badge with a fixed text "new" */
    CYLBadgeStyleOther                /* badge with a fixed text */
};

typedef NS_ENUM(NSUInteger, CYLBadgeAnimationType) {
    CYLBadgeAnimationTypeNone = 0,         /* without animation, badge stays still */
    CYLBadgeAnimationTypeScale,            /* scale effect */
    CYLBadgeAnimationTypeShake,            /* shaking effect */
    CYLBadgeAnimationTypeBounce,           /* bouncing effect */
    CYLBadgeAnimationTypeBreathe,          /* breathing light effect, which makes badge more attractive */
    CYLBadgeAnimationTypeLeftRightOnce,    /* left to right animation*/
    CYLBadgeAnimationTypeRightLeftOnce,    /* right to left animation*/
    CYLBadgeAnimationTypeFadeInOnce,       /* fade in animation */
    CYLBadgeAnimationTypeRollingOnce,      /*rolling animation*/
    CYLBadgeAnimationTypeScaleOnce         /*ScaleOnce animation*/
};

#pragma mark -- protocol definition

@protocol CYLBadgeProtocol <NSObject>

@required
/** badge entity, which is adviced not to set manually */
//@property (nonatomic, strong, getter=cyl_badge, setter=cyl_setBadge:) UIView __kindof *cyl_badge;
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
 * [EN] Returns YES if a badge is currently shown.
 * [CN] 判断当前是否正在显示角标。
 */
- (BOOL)cyl_isShowBadge;

/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 *  @attention 展示红点，注意该方法是基于 UIViewController ，所以内部使用[self cyl_getViewControllerInsteadOfNavigationController] 以防止将红点展示在 UINavigationController上，而导致展示与隐藏红点不一致。
 * [EN] Shows a red-dot badge with no animation.
 * [CN] 显示红点角标，无动画。
 */
- (void)cyl_showBadge;

/**
 *
 *  @param value String value, default is `nil`. if value equal @"" means red dot style.
 *  @param animationType  animationType
 *  @attention
 - 调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 - 不支持 CYLPlusChildViewController 对应的 TabBarItem 角标设置，调用会被忽略。
 * [EN] Shows a badge with `value` (@"" for a red dot) and the given animation.
 * [CN] 显示值为 value 的角标（传 @"" 为红点），并使用指定动画。
 */
- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType;
//- (void)cyl_showBadgeValue:(NSString *)value
//             animationTypeValue:(NSNumber *)animationTypeValue;

/**
 *  clear badge(hide badge)
 *  @attention 隐藏红点，注意该方法是基于 UIViewController ，所以内部使用[self cyl_getViewControllerInsteadOfNavigationController] 以防止将红点展示在 UINavigationController上，而导致展示与隐藏红点不一致。
 * [EN] Hides the badge.
 * [CN] 隐藏角标。
 */
- (void)cyl_clearBadge;

/**
 *  make bage(if existing) not hiden
 * [EN] Shows the badge again if one exists and was hidden.
 * [CN] 若角标存在且被隐藏，则重新显示。
 */
- (void)cyl_resumeBadge;

/*!
 * [EN] Returns YES if the badge is paused (hidden but kept).
 * [CN] 判断角标是否处于暂停（隐藏但保留）状态。
 */
- (BOOL)cyl_isPauseBadge;


/*!
 * @return UIView or UITabBarItem
 * [EN] Returns the view (or UITabBarItem) that actually hosts the badge.
 * [CN] 返回实际承载角标的视图（或 UITabBarItem）。
 */
- (id)cyl_getActualBadgeSuperView;

/*!
 * [EN] Returns YES once the badge host view has been laid out (width > 10), so the badge can be positioned.
 * [CN] 判断角标承载视图是否已完成布局（宽度大于 10），可以正确定位角标。
 */
- (BOOL)cyl_isReady;

/*!
 * iOS26+ only
 * [EN] Performs `aSelector` on the badge host; under Liquid Glass it runs on both the normal and the selected-state control so their badges stay in sync.
 * [CN] 在角标承载对象上执行 aSelector；液态玻璃下会同时作用于常态与选中态控件，保证两者角标一致。
 */
- (void)cyl_performSelector:(SEL)aSelector;
/*!
 * iOS26+ only
 * [EN] Same as `-cyl_performSelector:`, passing one argument.
 * [CN] 同 -cyl_performSelector:，携带一个参数。
 */
- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object;
/*!
 * iOS26+ only
 * [EN] Same as `-cyl_performSelector:`, passing two arguments.
 * [CN] 同 -cyl_performSelector:，携带两个参数。
 */
- (void)cyl_performSelector:(SEL)aSelector withObject:(id)object1 withObject:(id)object2;

@end

#endif
