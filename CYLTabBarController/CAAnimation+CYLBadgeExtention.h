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
 */
+ (CABasicAnimation *)cyl_opacityForever_Animation:(float)time;

/**
 *  breathing with fixed repeated times
 *
 *  @param repeatTimes times
 *  @param time        duritaion, from clear to fully seen
 *
 *  @return animation obj
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
 */
+ (CABasicAnimation *)cyl_scaleFrom:(CGFloat)fromScale toScale:(CGFloat)toScale durTimes:(float)time rep:(float)repeatTimes;
/**
 *  shake
 *
 *  @param repeatTimes time
 *  @param time        duration
 *  @param obj         always be CALayer at present
 *  @return aniamtion obj
 */
+ (CAKeyframeAnimation *)cyl_shake_AnimationRepeatTimes:(float)repeatTimes durTimes:(float)time forObj:(id)obj;

/**
 *  bounce
 *
 *  @param repeatTimes time
 *  @param time        duration
 *  @param obj         always be CALayer at present
 *  @return aniamtion obj
 */
+ (CAKeyframeAnimation *)cyl_bounce_AnimationRepeatTimes:(float)repeatTimes durTimes:(float)time forObj:(id)obj;

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
 */
+ (CABasicAnimation *)cyl_badge_once_rolling_AnimationRepeatTimes:(float)repeatTimes
                                                    durTimes:(float)time;

 
@end

NS_ASSUME_NONNULL_END

