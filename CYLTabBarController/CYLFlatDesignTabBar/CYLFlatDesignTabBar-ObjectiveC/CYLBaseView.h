/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>

@interface CYLBaseView : UIControl
/** 默认0.15 */
@property (nonatomic, assign) NSTimeInterval imageSetterDuration;
@property (nonatomic, strong) UIImage *image;
- (void)setImage:(UIImage *)image animated:(BOOL)animated;

/** 默认YES */
@property (nonatomic, assign) BOOL isBounce;
/** 默认1.13 */
@property (nonatomic, assign) CGFloat scale;
/** 默认0.27 */
@property (nonatomic, assign) NSTimeInterval scaleDuration;
/** 默认20.0 */
@property (nonatomic, assign) CGFloat recoverSpeed;
/** 默认17.0 */
@property (nonatomic, assign) CGFloat recoverBounciness;
/** 默认NO */
@property (nonatomic, assign) BOOL isJudgeBegin;
/** 默认YES */
@property (nonatomic, assign) BOOL isCanTouchesBegan;

@property (nonatomic, copy) void (^viewTouchUpInside)(CYLBaseView *bounceView);

- (void)recover;

@property (nonatomic, assign) BOOL isTouching;

@property (nonatomic, copy) void (^touchingDidChanged)(BOOL isTouching);

@end
