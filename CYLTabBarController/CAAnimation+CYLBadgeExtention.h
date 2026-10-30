/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CYLAxis) {
    CYLAxisX = 0,
    CYLAxisY,
    CYLAxisZ
};

// Degrees to radians
#define CYL_DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)
#define CYL_RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))

@interface CAAnimation (CYLBadgeExtention)

/**
 *  breathing forever
 *
 *  @param time duritaion, from clear to fully seen
 *
 *  @return animation obj
 * [EN] Returns an opacity "breathing" animation that repeats forever; `time` is the fade duration.
 * [CN] 返回无限循环的透明度“呼吸”动画，time 为渐变时长。
 */
+ (CABasicAnimation *)cyl_opacityForever_Animation:(float)time;

/**
 *  breathing with fixed repeated times
 *
 *  @param repeatTimes times
 *  @param time        duritaion, from clear to fully seen
 *
 *  @return animation obj
 * [EN] Returns an opacity "breathing" animation repeated `repeatTimes` times.
 * [CN] 返回重复 repeatTimes 次的透明度“呼吸”动画。
 */
+ (CABasicAnimation *)cyl_opacityTimes_Animation:(float)repeatTimes durTimes:(float)time;

/**
 *  //rotate
 *
 *  @param dur         duration
 *  @param degree      rotate degree in radian(弧度)
 *  @param axis        axis
 *  @param repeatCount repeat count
 *
 *  @return animation obj
 * [EN] Returns a rotation animation of `degree` radians around `axis`.
 * [CN] 返回绕 axis 轴旋转 degree 弧度的旋转动画。
 */
+ (CABasicAnimation *)cyl_rotation:(float)dur degree:(float)degree direction:(CYLAxis)axis repeatCount:(int)repeatCount;


/**
 *  scale animation
 *
 *  @param fromScale   the original scale value, 1.0 by default
 *  @param toScale     target scale
 *  @param time        duration
 *  @param repeatTimes repeat counts
 *
 *  @return animaiton obj
 * [EN] Returns a scale animation from `fromScale` to `toScale`.
 * [CN] 返回从 fromScale 缩放到 toScale 的缩放动画。
 */
+ (CABasicAnimation *)cyl_scaleFrom:(CGFloat)fromScale toScale:(CGFloat)toScale durTimes:(float)time rep:(float)repeatTimes;
/**
 *  shake
 *
 *  @param repeatTimes time
 *  @param time        duration
 *  @param obj         always be CALayer at present
 *  @return aniamtion obj
 * [EN] Returns a horizontal shake animation for the given layer.
 * [CN] 返回作用于指定 layer 的水平抖动动画。
 */
+ (CAKeyframeAnimation *)cyl_shake_AnimationRepeatTimes:(float)repeatTimes durTimes:(float)time forObj:(id)obj;

/**
 *  bounce
 *
 *  @param repeatTimes time
 *  @param time        duration
 *  @param obj         always be CALayer at present
 *  @return aniamtion obj
 * [EN] Returns a vertical bounce animation for the given layer.
 * [CN] 返回作用于指定 layer 的上下弹跳动画。
 */
+ (CAKeyframeAnimation *)cyl_bounce_AnimationRepeatTimes:(float)repeatTimes durTimes:(float)time forObj:(id)obj;

/*!
 * [EN] Horizontal shake that moves the layer relative to where it is (`transform.translation.x`), so it keeps
 *      working when the layer is repositioned while shaking (Auto Layout, rotation, iPhone Duo fold). Unlike
 *      `+cyl_shake_AnimationRepeatTimes:durTimes:forObj:`, it does not capture the layer's position. Invalid inputs are
 *      clamped: a non-finite or non-positive duration becomes 1 s (minimum 0.01 s), a NaN or negative repeat count 0,
 *      a non-finite offset 0. `removedOnCompletion` is NO.
 * [CN] 相对当前位置的水平抖动（`transform.translation.x`），抖动过程中 layer 被重新定位（自动布局、旋转、iPhone Duo 折叠）
 *      时依然正确。与 `+cyl_shake_AnimationRepeatTimes:durTimes:forObj:` 不同，它不记录 layer 的位置。非法参数会被修正：
 *      非有限或非正的时长取 1 秒（最小 0.01 秒），NaN 或负的重复次数取 0，非有限的偏移取 0。`removedOnCompletion` 为 NO。
 */
+ (CAKeyframeAnimation *)cyl_shakeAnimationRepeatTimes:(float)repeatTimes duration:(CFTimeInterval)duration offset:(CGFloat)offset;

/*!
 * [EN] Vertical bounce, relative like `+cyl_shakeAnimationRepeatTimes:duration:offset:` (`transform.translation.y`).
 * [CN] 上下弹跳，与 `+cyl_shakeAnimationRepeatTimes:duration:offset:` 一样相对当前位置（`transform.translation.y`）。
 */
+ (CAKeyframeAnimation *)cyl_bounceAnimationRepeatTimes:(float)repeatTimes duration:(CFTimeInterval)duration offset:(CGFloat)offset;

///**
// *  scale animation
// *
// *  @param fromScale   from scale
// *  @param toScale     to scale
// *  @param duration    animation duration
// *  @param repeatTimes repeat count
// *
// *  @return animation obj
// */
//+ (CABasicAnimation *)cyl_scaleAnimationFrom:(CGFloat)fromScale
//                                          to:(CGFloat)toScale
//                                   duration:(CFTimeInterval)duration
//                                repeatTimes:(float)repeatTimes;
//
///**
// *  horizontal move animation
// *
// *  @param fromX       start x offset
// *  @param toX         end x offset
// *  @param duration    animation duration
// *  @param repeatTimes repeat count
// *
// *  @return animation obj
// */
//+ (CABasicAnimation *)cyl_horizontalMoveAnimationFrom:(CGFloat)fromX
//                                                   to:(CGFloat)toX
//                                            duration:(CFTimeInterval)duration
//                                         repeatTimes:(float)repeatTimes;
//
///**
// *  fade animation
// *
// *  @param fromAlpha   from opacity
// *  @param toAlpha     to opacity
// *  @param duration    animation duration
// *  @param repeatTimes repeat count
// *
// *  @return animation obj
// */
//+ (CABasicAnimation *)cyl_opacityAnimationFrom:(CGFloat)fromAlpha
//                                            to:(CGFloat)toAlpha
//                                     duration:(CFTimeInterval)duration
//                                  repeatTimes:(float)repeatTimes;
//
///**
// *  rotation animation
// *
// *  @param fromAngle   start angle
// *  @param toAngle     end angle
// *  @param duration    animation duration
// *  @param repeatTimes repeat count
// *
// *  @return animation obj
// */
//+ (CABasicAnimation *)cyl_rotationAnimationFrom:(CGFloat)fromAngle
//                                             to:(CGFloat)toAngle
//                                      duration:(CFTimeInterval)duration
//                                   repeatTimes:(float)repeatTimes;

/*!
 * [EN] Returns a spring scale animation (0.85 → 1.15 → 0.9 → 1.0) lasting `duration` seconds.
 * [CN] 返回时长为 duration 秒的弹簧缩放动画（0.85 → 1.15 → 0.9 → 1.0）。
 */
+ (CAKeyframeAnimation *)cyl_springAnimationForDuration:(NSTimeInterval)duration;

/*!
 *

 CGFloat moveDistance = badgeView.frame.size.width * 1.5;

[badgeView.layer addAnimation:
 [CAAnimation cyl_badge_once_scale_AnimationRepeatTimes:1
                                            durTimes:0.5]
                       forKey:@"cyl.badge.default"];


[badgeView.layer addAnimation:
 [CAAnimation cyl_badge_once_leftRight_AnimationMoveDistance:moveDistance
                                            repeatTimes:1
                                               durTimes:0.5]
                       forKey:@"cyl.badge.leftRight"];


[badgeView.layer addAnimation:
 [CAAnimation cyl_badge_once_rightLeft_AnimationMoveDistance:moveDistance
                                            repeatTimes:1
                                               durTimes:0.5]
                       forKey:@"cyl.badge.rightLeft"];


[badgeView.layer addAnimation:
 [CAAnimation cyl_badge_once_fadeIn_AnimationRepeatTimes:1
                                           durTimes:1.5]
                       forKey:@"cyl.badge.fadeIn"];


[badgeView.layer addAnimation:
 [CAAnimation cyl_badge_once_rolling_AnimationRepeatTimes:1
                                            durTimes:0.5]
                       forKey:@"cyl.badge.rolling"];
 */
 
/**
 *  default scale animation
 *
 *  @param repeatTimes repeat counts
 *  @param time        duration
 *
 *  @return animation obj
 * [EN] Returns the default one-shot badge scale animation.
 * [CN] 返回角标默认的单次缩放动画。
 */
+ (CABasicAnimation *)cyl_badge_once_scale_AnimationRepeatTimes:(float)repeatTimes
                                                    durTimes:(float)time;

/**
 *  left to right animation
 *
 *  @param moveDistance move distance
 *  @param repeatTimes  repeat counts
 *  @param time         duration
 *
 *  @return animation obj
 * [EN] Returns a one-shot badge animation that moves left to right by `moveDistance`.
 * [CN] 返回角标从左向右移动 moveDistance 的单次动画。
 */
+ (CABasicAnimation *)cyl_badge_once_leftRight_AnimationMoveDistance:(CGFloat)moveDistance
                                                    repeatTimes:(float)repeatTimes
                                                       durTimes:(float)time;

/**
 *  right to left animation
 *
 *  @param moveDistance move distance
 *  @param repeatTimes  repeat counts
 *  @param time         duration
 *
 *  @return animation obj
 * [EN] Returns a one-shot badge animation that moves right to left by `moveDistance`.
 * [CN] 返回角标从右向左移动 moveDistance 的单次动画。
 */
+ (CABasicAnimation *)cyl_badge_once_rightLeft_AnimationMoveDistance:(CGFloat)moveDistance
                                                    repeatTimes:(float)repeatTimes
                                                       durTimes:(float)time;

/**
 *  fade in animation
 *
 *  @param repeatTimes repeat counts
 *  @param time        duration
 *
 *  @return animation obj
 * [EN] Returns a one-shot badge fade-in animation.
 * [CN] 返回角标的单次淡入动画。
 */
+ (CABasicAnimation *)cyl_badge_once_fadeIn_AnimationRepeatTimes:(float)repeatTimes
                                                   durTimes:(float)time;

/**
 *  rolling animation
 *
 *  @param repeatTimes repeat counts
 *  @param time        duration
 *
 *  @return animation obj
 * [EN] Returns a one-shot badge rolling animation (rotates from π to 0 around z).
 * [CN] 返回角标的单次滚动动画（绕 z 轴从 π 旋转到 0）。
 */
+ (CABasicAnimation *)cyl_badge_once_rolling_AnimationRepeatTimes:(float)repeatTimes
                                                    durTimes:(float)time;

 
@end

NS_ASSUME_NONNULL_END

