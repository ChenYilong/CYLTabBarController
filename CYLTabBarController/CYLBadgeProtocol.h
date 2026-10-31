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

/*!
 * [EN] Animation keys: the `forKey:` a badge animation is added to the badge's layer under. They are strings, defined
 *      here with `CYLBadgeAnimationType` (below) because they are two views of the same thing: each type has one key,
 *      listed in `CYLBadgeAnimationKeyForType`. The difference in use:
 *      - the enum picks WHICH animation a badge plays: `[view cyl_showBadgeValue:@"3" animationType:CYLBadgeAnimationTypeShake]`;
 *      - the key IDENTIFIES a running animation on `view.cyl_badge.layer`, to query or stop it:
 *        `[view.cyl_badge.layer animationForKey:CYLBadgeShakeAnimationKey]`,
 *        `[view.cyl_badge.layer removeAnimationForKey:CYLBadgeShakeAnimationKey]`.
 *      Repeating types (Scale, Shake, Bounce, Breathe) can be queried like this; the "Once" types finish by themselves.
 *      `CYLBadgeRotateAnimationKey` belongs to no type: it is reserved for a rotation you add yourself with
 *      `+[CAAnimation cyl_rotation:degree:direction:repeatCount:]`.
 *      To add an animation type: add it to the enum, add its key here, and add it to the three functions below.
 * [CN] 动画 key：角标动画添加到角标 layer 时使用的 `forKey:`。它们是字符串，与 `CYLBadgeAnimationType`（见下）定义在一起，
 *      因为二者描述同一件事：每个类型对应一个 key，见 `CYLBadgeAnimationKeyForType`。用法不同：
 *      - 枚举决定角标播放哪种动画：`[view cyl_showBadgeValue:@"3" animationType:CYLBadgeAnimationTypeShake]`；
 *      - key 用来标识 `view.cyl_badge.layer` 上正在运行的动画，用于查询或停止：
 *        `[view.cyl_badge.layer animationForKey:CYLBadgeShakeAnimationKey]`、
 *        `[view.cyl_badge.layer removeAnimationForKey:CYLBadgeShakeAnimationKey]`。
 *      可以这样查询的是循环类型（Scale、Shake、Bounce、Breathe）；"Once" 类型会自行结束。
 *      `CYLBadgeRotateAnimationKey` 不对应任何类型：留给你用 `+[CAAnimation cyl_rotation:degree:direction:repeatCount:]` 自行添加的旋转动画。
 *      新增动画类型时：在枚举中添加，在这里添加它的 key，并更新下面的三个函数。
 */
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

/// The key of the animation a type plays, nil for `CYLBadgeAnimationTypeNone` (and unknown values).
static inline NSString * _Nullable CYLBadgeAnimationKeyForType(CYLBadgeAnimationType animationType) {
    switch (animationType) {
        case CYLBadgeAnimationTypeScale:         return CYLBadgeScaleAnimationKey;
        case CYLBadgeAnimationTypeShake:         return CYLBadgeShakeAnimationKey;
        case CYLBadgeAnimationTypeBounce:        return CYLBadgeBounceAnimationKey;
        case CYLBadgeAnimationTypeBreathe:       return CYLBadgeBreatheAnimationKey;
        case CYLBadgeAnimationTypeLeftRightOnce: return CYLBadgeLeftRightOnceAnimationKey;
        case CYLBadgeAnimationTypeRightLeftOnce: return CYLBadgeRightLeftOnceAnimationKey;
        case CYLBadgeAnimationTypeFadeInOnce:    return CYLBadgeFadeInOnceAnimationKey;
        case CYLBadgeAnimationTypeRollingOnce:   return CYLBadgeRollingOnceAnimationKey;
        case CYLBadgeAnimationTypeScaleOnce:     return CYLBadgeScaleOnceAnimationKey;
        case CYLBadgeAnimationTypeNone:
        default:                                 return nil;
    }
}

/// YES for the types that repeat until stopped (Scale, Shake, Bounce, Breathe); NO for None and the "Once" types.
static inline BOOL CYLBadgeAnimationTypeRepeats(CYLBadgeAnimationType animationType) {
    switch (animationType) {
        case CYLBadgeAnimationTypeScale:
        case CYLBadgeAnimationTypeShake:
        case CYLBadgeAnimationTypeBounce:
        case CYLBadgeAnimationTypeBreathe:
            return YES;
        default:
            return NO;
    }
}

/// Every key a badge animation may be under (including `CYLBadgeRotateAnimationKey`), to remove them all at once.
static inline NSArray<NSString *> * CYLBadgeAllAnimationKeys(void) {
    return @[CYLBadgeScaleAnimationKey, CYLBadgeShakeAnimationKey, CYLBadgeBounceAnimationKey,
             CYLBadgeBreatheAnimationKey, CYLBadgeRotateAnimationKey, CYLBadgeLeftRightOnceAnimationKey,
             CYLBadgeRightLeftOnceAnimationKey, CYLBadgeFadeInOnceAnimationKey, CYLBadgeRollingOnceAnimationKey,
             CYLBadgeScaleOnceAnimationKey];
}

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

@optional

/*!
 * [EN] `cyl_delayIfNeededForSeconds` (seconds, a `CGFloat`, which is a `double`) boxed in an `NSNumber`, like the other
 *      `…Value` properties. Use it where only objects can be passed, e.g. `-cyl_performSelector:withObject:`, KVC or
 *      `performSelector:`. The setter calls `-cyl_setDelayIfNeededForSeconds:`. Optional: classes of yours that adopt
 *      this protocol are not required to implement it.
 * [CN] `cyl_delayIfNeededForSeconds`（秒，`CGFloat`，即 `double`）装箱成 `NSNumber`，与其他 `…Value` 属性一致。
 *      在只能传对象的场景使用，如 `-cyl_performSelector:withObject:`、KVC 或 `performSelector:`。
 *      setter 内部调用 `-cyl_setDelayIfNeededForSeconds:`。可选：你自己采用该协议的类不必实现它。
 */
@property (nonatomic, strong, getter=cyl_delayIfNeededForSecondsValue, setter=cyl_setDelayIfNeededForSecondsValue:) NSNumber *cyl_delayIfNeededForSecondsValue;

@end

#endif
