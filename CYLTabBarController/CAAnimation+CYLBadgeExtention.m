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
 *  @param time duritaion, from clear to fully seen
 *
 *  @return animation obj
 */
+ (CABasicAnimation *)cyl_opacityForever_Animation:(float)time {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:1.0];
    animation.toValue = [NSNumber numberWithFloat:0.1];
    animation.autoreverses = YES;
    animation.duration = time;
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
 *  @param time        duritaion, from clear to fully seen
 *
 *  @return animation obj
 */
+ (CABasicAnimation *)cyl_opacityTimes_Animation:(float)repeatTimes durTimes:(float)time {
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = [NSNumber numberWithFloat:1.0];
    animation.toValue = [NSNumber numberWithFloat:0.4];
    animation.repeatCount = repeatTimes;
    animation.duration = time;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animation.autoreverses = YES;
    return  animation;
}

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
+ (CABasicAnimation *)cyl_rotation:(float)dur degree:(float)degree direction:(CYLAxis)axis repeatCount:(int)repeatCount {
    CABasicAnimation* animation;
    NSArray *axisArr = @[@"transform.rotation.x", @"transform.rotation.y", @"transform.rotation.z"];
    animation = [CABasicAnimation animationWithKeyPath:axisArr[axis]];
    animation.fromValue = [NSNumber numberWithFloat:0];
    animation.toValue = [NSNumber numberWithFloat:degree];
    animation.duration = dur;
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
 *  @param time        duration
 *  @param repeatTimes repeat counts
 *
 *  @return animaiton obj
 */
+ (CABasicAnimation *)cyl_scaleFrom:(CGFloat)fromScale toScale:(CGFloat)toScale durTimes:(float)time rep:(float)repeatTimes {
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue = @(fromScale);
    animation.toValue = @(toScale);
    animation.duration = time;
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
 *  @param time        duration
 *  @param obj         always be CALayer
 *  @return aniamtion obj
 */
+ (CAKeyframeAnimation *)cyl_shake_AnimationRepeatTimes:(float)repeatTimes durTimes:(float)time forObj:(id)obj {
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
    anim.duration = time;
    anim.fillMode = kCAFillModeForwards;
    return anim;
}

/**
 *  bounce
 *
 *  @param repeatTimes time
 *  @param time        duration
 *  @param obj         always be CALayer
 *  @return aniamtion obj
 */
+ (CAKeyframeAnimation *)cyl_bounce_AnimationRepeatTimes:(float)repeatTimes durTimes:(float)time forObj:(id)obj {
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
    anim.duration = time;
    anim.fillMode = kCAFillModeForwards;
    return anim;
}

//+ (CABasicAnimation *)cyl_scaleAnimationFrom:(CGFloat)fromScale
//                                          to:(CGFloat)toScale
//                                   duration:(CFTimeInterval)duration
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
//                                            duration:(CFTimeInterval)duration
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
//                                     duration:(CFTimeInterval)duration
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
//                                      duration:(CFTimeInterval)duration
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

#pragma mark - Badge Default

+ (CABasicAnimation *)cyl_badge_once_scale_AnimationRepeatTimes:(float)repeatTimes
                                                    durTimes:(float)time {
    
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    animation.fromValue = @(2.7);
    animation.toValue = @(1.0);
    animation.repeatCount = repeatTimes;
    animation.duration = time;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    
    return animation;
}

#pragma mark - Badge Left Right

+ (CABasicAnimation *)cyl_badge_once_leftRight_AnimationMoveDistance:(CGFloat)moveDistance
                                                    repeatTimes:(float)repeatTimes
                                                       durTimes:(float)time {
    
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    
    animation.fromValue = @(-moveDistance);
    animation.toValue = @(0);
    animation.repeatCount = repeatTimes;
    animation.duration = time;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    return animation;
}

#pragma mark - Badge Right Left

+ (CABasicAnimation *)cyl_badge_once_rightLeft_AnimationMoveDistance:(CGFloat)moveDistance
                                                    repeatTimes:(float)repeatTimes
                                                       durTimes:(float)time {
    
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    
    animation.fromValue = @(moveDistance);
    animation.toValue = @(0);
    animation.repeatCount = repeatTimes;
    animation.duration = time;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    return animation;
}

#pragma mark - Badge Fade In

+ (CABasicAnimation *)cyl_badge_once_fadeIn_AnimationRepeatTimes:(float)repeatTimes
                                                   durTimes:(float)time {
    
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"opacity"];
    
    animation.fromValue = @(0);
    animation.toValue = @(1);
    animation.repeatCount = repeatTimes;
    animation.duration = time;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction =
    [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    
    return animation;
}

#pragma mark - Badge RollingOnce

+ (CABasicAnimation *)cyl_badge_once_rolling_AnimationRepeatTimes:(float)repeatTimes
                                                    durTimes:(float)time {
    
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    
    animation.fromValue = @(M_PI);
    animation.toValue = @(0);
    animation.repeatCount = repeatTimes;
    animation.duration = time;
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

@end
