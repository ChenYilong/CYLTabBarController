/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "CAAnimation+CYLBadgeExtention.h"
#import <QuartzCore/QuartzCore.h>

@implementation CAAnimation (CYLBadgeExtention)
/**
 *  breathing forever
 *
 *  @param duration duritaion, from clear to fully seen
 *
 *  @return animation obj
 */
+ (CABasicAnimation *)cyl_opacityForeverAnimationWithDuration:(NSTimeInterval)duration {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:1.0];
    animation.toValue = [NSNumber numberWithFloat:0.1];
    animation.autoreverses = YES;
    animation.duration = duration;
    animation.repeatCount = FLT_MAX;
    animation.removedOnCompletion = NO;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

/**
 *  breathing with fixed repeated times
 *
 *  @param repeatTimes times
 *  @param duration        duritaion, from clear to fully seen
 *
 *  @return animation obj
 */
+ (CABasicAnimation *)cyl_opacityTimesAnimationRepeatTimes:(float)repeatTimes duration:(NSTimeInterval)duration {
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:1.0];
    animation.toValue = [NSNumber numberWithFloat:0.4];
    animation.repeatCount = repeatTimes;
    animation.duration = duration;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animation.autoreverses = YES;
    return  animation;
}

/**
 *  //rotate
 *
 *  @param duration    duration
 *  @param degree      rotate degree in radian(弧度)
 *  @param axis        axis
 *  @param repeatCount repeat count
 *
 *  @return animation obj
 */
+ (CABasicAnimation *)cyl_rotationAnimationWithDuration:(NSTimeInterval)duration degree:(CGFloat)degree direction:(CYLAxis)axis repeatCount:(float)repeatCount {
    CABasicAnimation* animation;
    NSArray *axisArr = @[@"transform.rotation.x", @"transform.rotation.y", @"transform.rotation.z"];
    animation = [CABasicAnimation animationWithKeyPath:axisArr[axis]];
    animation.fromValue = [NSNumber numberWithFloat:0];
    animation.toValue = @(degree);
    animation.duration = duration;
    animation.autoreverses = NO;
    animation.cumulative = YES;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.repeatCount = repeatCount;
    return animation;
}

/**
 *  scale animation
 *
 *  @param fromScale   the original scale value, 1.0 by default
 *  @param toScale     target scale
 *  @param duration        duration
 *  @param repeatTimes repeat counts
 *
 *  @return animaiton obj
 */
+ (CABasicAnimation *)cyl_scaleAnimationFromScale:(CGFloat)fromScale toScale:(CGFloat)toScale duration:(NSTimeInterval)duration repeatTimes:(float)repeatTimes {
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = @(fromScale);
    animation.toValue = @(toScale);
    animation.duration = duration;
    animation.autoreverses = YES;
    animation.repeatCount = repeatTimes;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

/**
 *  shake
 *
 *  @param repeatTimes time
 *  @param duration        duration
 *  @param obj         always be CALayer
 *  @return aniamtion obj
 */
+ (CAKeyframeAnimation *)cyl_shakeAnimationRepeatTimes:(float)repeatTimes duration:(NSTimeInterval)duration forObj:(id)obj {
#if defined(DEBUG) || defined(BETA)
    NSAssert([obj isKindOfClass:[CALayer class]] , @"invalid target");
#endif
    CGPoint originPos = CGPointZero;
    CGSize originSize = CGSizeZero;
    if ([obj isKindOfClass:[CALayer class]]) {
        originPos = [(CALayer *)obj position];
        originSize = [(CALayer *)obj bounds].size;
    }
    CGFloat hOffset = originSize.width / 4;
    CAKeyframeAnimation* anim=[CAKeyframeAnimation animation];
    anim.keyPath=@"position";
    anim.values=@[
        [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y)],
        [NSValue valueWithCGPoint:CGPointMake(originPos.x-hOffset, originPos.y)],
        [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y)],
        [NSValue valueWithCGPoint:CGPointMake(originPos.x+hOffset, originPos.y)],
        [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y)]
    ];
    anim.repeatCount = repeatTimes;
    anim.duration = duration;
    anim.fillMode = kCAFillModeForwards;
    return anim;
}

/**
 *  bounce
 *
 *  @param repeatTimes time
 *  @param duration        duration
 *  @param obj         always be CALayer
 *  @return aniamtion obj
 */
+ (CAKeyframeAnimation *)cyl_bounceAnimationRepeatTimes:(float)repeatTimes duration:(NSTimeInterval)duration forObj:(id)obj {
#if defined(DEBUG) || defined(BETA)
    NSAssert([obj isKindOfClass:[CALayer class]] , @"invalid target");
#endif
    CGPoint originPos = CGPointZero;
    CGSize originSize = CGSizeZero;
    if ([obj isKindOfClass:[CALayer class]]) {
        originPos = [(CALayer *)obj position];
        originSize = [(CALayer *)obj bounds].size;
    }
    CGFloat hOffset = originSize.height / 4;
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animation];
    anim.keyPath = @"position";
    anim.values = @[
        [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y)],
        [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y - hOffset)],
        [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y)],
        [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y + hOffset)],
        [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y)]
    ];
    anim.repeatCount = repeatTimes;
    anim.duration = duration;
    anim.fillMode = kCAFillModeForwards;
    return anim;
}

//+ (CABasicAnimation *)cyl_scaleAnimationFrom:(CGFloat)fromScale
//                                          to:(CGFloat)toScale
//                                   duration:(NSTimeInterval)duration
//                                repeatTimes:(float)repeatTimes {
//    
//    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
//    
//    animation.fromValue = @(fromScale);
//    animation.toValue = @(toScale);
//    animation.duration = duration;
//    animation.repeatCount = repeatTimes;
//    animation.removedOnCompletion = NO;
//    animation.fillMode = kCAFillModeForwards;
//    animation.autoreverses = NO;
//    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//    
//    return animation;
//}
//
//+ (CABasicAnimation *)cyl_horizontalMoveAnimationFrom:(CGFloat)fromX
//                                                   to:(CGFloat)toX
//                                            duration:(NSTimeInterval)duration
//                                         repeatTimes:(float)repeatTimes {
//    
//    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
//    
//    animation.fromValue = @(fromX);
//    animation.toValue = @(toX);
//    animation.duration = duration;
//    animation.repeatCount = repeatTimes;
//    animation.removedOnCompletion = NO;
//    animation.fillMode = kCAFillModeForwards;
//    animation.autoreverses = NO;
//    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
//    
//    return animation;
//}
//
//+ (CABasicAnimation *)cyl_opacityAnimationFrom:(CGFloat)fromAlpha
//                                            to:(CGFloat)toAlpha
//                                     duration:(NSTimeInterval)duration
//                                  repeatTimes:(float)repeatTimes {
//    
//    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
//    
//    animation.fromValue = @(fromAlpha);
//    animation.toValue = @(toAlpha);
//    animation.duration = duration;
//    animation.repeatCount = repeatTimes;
//    animation.removedOnCompletion = NO;
//    animation.fillMode = kCAFillModeForwards;
//    animation.autoreverses = NO;
//    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
//    
//    return animation;
//}
//
//+ (CABasicAnimation *)cyl_rotationAnimationFrom:(CGFloat)fromAngle
//                                             to:(CGFloat)toAngle
//                                      duration:(NSTimeInterval)duration
//                                   repeatTimes:(float)repeatTimes {
//    
//    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
//    
//    animation.fromValue = @(fromAngle);
//    animation.toValue = @(toAngle);
//    animation.duration = duration;
//    animation.repeatCount = repeatTimes;
//    animation.removedOnCompletion = NO;
//    animation.fillMode = kCAFillModeForwards;
//    animation.autoreverses = NO;
//    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//    
//    return animation;
//}

#pragma mark - Relative shake / bounce

static NSTimeInterval CYLBadgeSafeDuration(NSTimeInterval duration) {
    if (!isfinite(duration) || duration <= 0) {
        return 1;
    }
    return MAX(0.01, duration);
}

static float CYLBadgeSafeRepeatCount(float repeatCount) {
    if (isnan(repeatCount)) {
        return 0;
    }
    return MAX(0, repeatCount);
}

static CGFloat CYLBadgeSafeOffset(CGFloat offset) {
    return isfinite(offset) ? offset : 0;
}

+ (CAKeyframeAnimation *)cyl_translationAnimationWithKeyPath:(NSString *)keyPath
                                                 repeatTimes:(float)repeatTimes
                                                    duration:(NSTimeInterval)duration
                                                      offset:(CGFloat)offset {
    CGFloat safeOffset = CYLBadgeSafeOffset(offset);
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:keyPath];
    animation.values = @[@0, @(-safeOffset), @0, @(safeOffset), @0];
    animation.repeatCount = CYLBadgeSafeRepeatCount(repeatTimes);
    animation.duration = CYLBadgeSafeDuration(duration);
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

+ (CAKeyframeAnimation *)cyl_shakeAnimationRepeatTimes:(float)repeatTimes duration:(NSTimeInterval)duration offset:(CGFloat)offset {
    return [self cyl_translationAnimationWithKeyPath:@"transform.translation.x" repeatTimes:repeatTimes duration:duration offset:offset];
}

+ (CAKeyframeAnimation *)cyl_bounceAnimationRepeatTimes:(float)repeatTimes duration:(NSTimeInterval)duration offset:(CGFloat)offset {
    return [self cyl_translationAnimationWithKeyPath:@"transform.translation.y" repeatTimes:repeatTimes duration:duration offset:offset];
}

#pragma mark - Badge Default

+ (CABasicAnimation *)cyl_badge_once_scale_AnimationRepeatTimes:(float)repeatTimes
                                                       duration:(NSTimeInterval)duration {
    
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    animation.fromValue = @(2.7);
    animation.toValue = @(1.0);
    animation.repeatCount = repeatTimes;
    animation.duration = duration;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    return animation;
}

#pragma mark - Badge Left Right

+ (CABasicAnimation *)cyl_badge_once_leftRight_AnimationMoveDistance:(CGFloat)moveDistance
                                                         repeatTimes:(float)repeatTimes
                                                            duration:(NSTimeInterval)duration {
    
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    
    animation.fromValue = @(-moveDistance);
    animation.toValue = @(0);
    animation.repeatCount = repeatTimes;
    animation.duration = duration;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    return animation;
}

#pragma mark - Badge Right Left

+ (CABasicAnimation *)cyl_badge_once_rightLeft_AnimationMoveDistance:(CGFloat)moveDistance
                                                         repeatTimes:(float)repeatTimes
                                                            duration:(NSTimeInterval)duration {
    
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    
    animation.fromValue = @(moveDistance);
    animation.toValue = @(0);
    animation.repeatCount = repeatTimes;
    animation.duration = duration;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    return animation;
}

#pragma mark - Badge Fade In

+ (CABasicAnimation *)cyl_badge_once_fadeIn_AnimationRepeatTimes:(float)repeatTimes
                                                        duration:(NSTimeInterval)duration {
    
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"opacity"];
    
    animation.fromValue = @(0);
    animation.toValue = @(1);
    animation.repeatCount = repeatTimes;
    animation.duration = duration;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    return animation;
}

#pragma mark - Badge RollingOnce

+ (CABasicAnimation *)cyl_badge_once_rolling_AnimationRepeatTimes:(float)repeatTimes
                                                         duration:(NSTimeInterval)duration {
    
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    
    animation.fromValue = @(M_PI);
    animation.toValue = @(0);
    animation.repeatCount = repeatTimes;
    animation.duration = duration;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    return animation;
}

#pragma mark - Spring Animation

+ (CAKeyframeAnimation *)cyl_springAnimationForDuration:(NSTimeInterval)duration {
    CAKeyframeAnimation *springAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    springAnimation.values = @[@.85, @1.15, @.9, @1.0,];
    springAnimation.keyTimes = @[@(0.0 / duration), @(0.15 / duration) , @(0.3 / duration), @(0.45 / duration),];
    springAnimation.duration = duration;
    return springAnimation;
}

#pragma mark - Original signatures (kept for compatibility)

/*!
 * [EN] The factories below keep their original names and `float` parameters, so existing callers keep compiling and
 *      linking. Each only forwards to the `NSTimeInterval` method defined above (see the note in the header).
 * [CN] 下面的工厂方法保持原来的名称和 `float` 参数，现有调用方可以继续编译和链接。每个方法只是转发给上面定义的 `NSTimeInterval` 方法（见头文件中的说明）。
 */
+ (CABasicAnimation *)cyl_opacityForever_Animation:(float)time {
    return [self cyl_opacityForeverAnimationWithDuration:time];
}

+ (CABasicAnimation *)cyl_opacityTimes_Animation:(float)repeatTimes durTimes:(float)time {
    return [self cyl_opacityTimesAnimationRepeatTimes:repeatTimes duration:time];
}

+ (CABasicAnimation *)cyl_rotation:(float)dur degree:(float)degree direction:(CYLAxis)axis repeatCount:(int)repeatCount {
    return [self cyl_rotationAnimationWithDuration:dur degree:degree direction:axis repeatCount:repeatCount];
}

+ (CABasicAnimation *)cyl_scaleFrom:(CGFloat)fromScale toScale:(CGFloat)toScale durTimes:(float)time rep:(float)repeatTimes {
    return [self cyl_scaleAnimationFromScale:fromScale toScale:toScale duration:time repeatTimes:repeatTimes];
}

+ (CAKeyframeAnimation *)cyl_shake_AnimationRepeatTimes:(float)repeatTimes durTimes:(float)time forObj:(id)obj {
    return [self cyl_shakeAnimationRepeatTimes:repeatTimes duration:time forObj:obj];
}

+ (CAKeyframeAnimation *)cyl_bounce_AnimationRepeatTimes:(float)repeatTimes durTimes:(float)time forObj:(id)obj {
    return [self cyl_bounceAnimationRepeatTimes:repeatTimes duration:time forObj:obj];
}

+ (CABasicAnimation *)cyl_badge_once_scale_AnimationRepeatTimes:(float)repeatTimes
                                                    durTimes:(float)time {
    return [self cyl_badge_once_scale_AnimationRepeatTimes:repeatTimes duration:time];
}

+ (CABasicAnimation *)cyl_badge_once_leftRight_AnimationMoveDistance:(CGFloat)moveDistance
                                                    repeatTimes:(float)repeatTimes
                                                       durTimes:(float)time {
    return [self cyl_badge_once_leftRight_AnimationMoveDistance:moveDistance repeatTimes:repeatTimes duration:time];
}

+ (CABasicAnimation *)cyl_badge_once_rightLeft_AnimationMoveDistance:(CGFloat)moveDistance
                                                    repeatTimes:(float)repeatTimes
                                                       durTimes:(float)time {
    return [self cyl_badge_once_rightLeft_AnimationMoveDistance:moveDistance repeatTimes:repeatTimes duration:time];
}

+ (CABasicAnimation *)cyl_badge_once_fadeIn_AnimationRepeatTimes:(float)repeatTimes
                                                   durTimes:(float)time {
    return [self cyl_badge_once_fadeIn_AnimationRepeatTimes:repeatTimes duration:time];
}

+ (CABasicAnimation *)cyl_badge_once_rolling_AnimationRepeatTimes:(float)repeatTimes
                                                    durTimes:(float)time {
    return [self cyl_badge_once_rolling_AnimationRepeatTimes:repeatTimes duration:time];
}

@end
