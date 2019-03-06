/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2019 https://github.com/ChenYilong . All rights reserved.
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
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue=[NSNumber numberWithFloat:1.0];
    animation.toValue=[NSNumber numberWithFloat:0.1];
    animation.autoreverses=YES;
    animation.duration=time;
    animation.repeatCount=FLT_MAX;
    animation.removedOnCompletion=NO;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    animation.fillMode=kCAFillModeForwards;
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
    animation.fromValue=[NSNumber numberWithFloat:1.0];
    animation.toValue=[NSNumber numberWithFloat:0.4];
    animation.repeatCount=repeatTimes;
    animation.duration=time;
    animation.removedOnCompletion=NO;
    animation.fillMode=kCAFillModeForwards;
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animation.autoreverses=YES;
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
    animation.toValue= [NSNumber numberWithFloat:degree];
    animation.duration= dur;
    animation.autoreverses= NO;
    animation.cumulative= YES;
    animation.removedOnCompletion=NO;
    animation.fillMode=kCAFillModeForwards;
    animation.repeatCount= repeatCount;
    
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
    NSAssert([obj isKindOfClass:[CALayer class]] , @"invalid target");
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
    NSAssert([obj isKindOfClass:[CALayer class]] , @"invalid target");
    CGPoint originPos = CGPointZero;
    CGSize originSize = CGSizeZero;
    if ([obj isKindOfClass:[CALayer class]]) {
        originPos = [(CALayer *)obj position];
        originSize = [(CALayer *)obj bounds].size;
    }
    CGFloat hOffset = originSize.height / 4;
    CAKeyframeAnimation* anim=[CAKeyframeAnimation animation];
    anim.keyPath=@"position";
    anim.values=@[
                  [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y)],
                  [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y-hOffset)],
                  [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y)],
                  [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y+hOffset)],
                  [NSValue valueWithCGPoint:CGPointMake(originPos.x, originPos.y)]
                  ];
    anim.repeatCount=repeatTimes;
    anim.duration=time;
    anim.fillMode = kCAFillModeForwards;
    return anim;
}

@end
