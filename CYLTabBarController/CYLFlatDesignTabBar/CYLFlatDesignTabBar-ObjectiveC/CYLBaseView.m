/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "CYLBaseView.h"
//#import "POP.h"

@interface CYLBaseView ()
@property (nonatomic, assign) BOOL isBegin;
@end

@implementation CYLBaseView
{
    UIImage *_image;
}

- (instancetype)init {
    if (self = [super init]) {
        [self baseSetup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self baseSetup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self baseSetup];
    }
    return self;
}

- (void)baseSetup {
    _isJudgeBegin = NO;
    _isCanTouchesBegan = YES;
    _isBounce = YES;
    _scale = 1.13;
    _scaleDuration = 0.27;
    _recoverSpeed = 20.0;
    _recoverBounciness = 17.0;
    _imageSetterDuration = 0.15;
}

- (void)setImage:(UIImage *)image {
    [self setImage:image animated:NO];
}

- (void)setImage:(UIImage *)image animated:(BOOL)animated {
    if (_image == image) return;
    _image = image;
    if (animated && self.imageSetterDuration > 0) {
        CATransition *transition = [CATransition animation];
        transition.duration = self.imageSetterDuration;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        transition.type = kCATransitionFade;
        [self.layer addAnimation:transition forKey:@"JPFadeAnimation"];
    }
    self.layer.contents = (id)image.CGImage;
}

- (UIImage *)image {
    id content = self.layer.contents;
    if (content != (id)_image.CGImage) {
        CGImageRef ref = (__bridge CGImageRef)(content);
        if (ref && CFGetTypeID(ref) == CGImageGetTypeID()) {
            _image = [UIImage imageWithCGImage:ref scale:self.layer.contentsScale orientation:UIImageOrientationUp];
        } else {
            _image = nil;
        }
    }
    return _image;
}

- (void)setIsBounce:(BOOL)isBounce {
    if (_isBounce == isBounce) { return; }
    _isBounce = isBounce;
    if (!isBounce) { [self recover]; }
}

- (void)setIsTouching:(BOOL)isTouching {
    if (!self.isBounce) isTouching = NO;
    if (_isTouching == isTouching) { return; }
    _isTouching = isTouching;
    if (self.scale == 1) { return; }
    if (isTouching) {
//        POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
//        anim.toValue = @(CGPointMake(self.scale, self.scale));
//        anim.duration = self.scaleDuration;
//        [self.layer pop_addAnimation:anim forKey:kPOPLayerScaleXY];
    } else {
//        POPSpringAnimation *anim = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
//        anim.toValue = @(CGPointMake(1.0, 1.0));
//        anim.springSpeed = self.recoverSpeed;
//        anim.springBounciness = self.recoverBounciness;
//        [self.layer pop_addAnimation:anim forKey:kPOPLayerScaleXY];
    }
    !self.touchingDidChanged ? : self.touchingDidChanged(isTouching);
}

- (void)setIsCanTouchesBegan:(BOOL)isCanTouchesBegan {
    _isCanTouchesBegan = isCanTouchesBegan;
    if (!isCanTouchesBegan) {
        self.isBegin = isCanTouchesBegan;
        self.isTouching = isCanTouchesBegan;
    }
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.isBegin = self.isCanTouchesBegan;
    self.isTouching = self.isCanTouchesBegan;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    if (self.isJudgeBegin && !self.isBegin) {
        self.isTouching = NO;
        return;
    }
    NSSet *allTouches = [event allTouches];   
    UITouch *touch = [allTouches anyObject];
    CGPoint point = [touch locationInView:self];
    self.isTouching = CGRectContainsPoint(self.bounds, point);
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if (self.isTouching && self.viewTouchUpInside) {
        if (self.isJudgeBegin) {
            if (self.isBegin) { self.viewTouchUpInside(self); }
        } else {
            self.viewTouchUpInside(self);
        }
    }
    self.isBegin = NO;
    self.isTouching = NO;
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self recover];
}

- (void)recover {
    self.isBegin = NO;
    if (!_isTouching) return;
    _isTouching = NO;
//    POPBasicAnimation *anim = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
//    anim.toValue = @(CGPointMake(1.0, 1.0));
//    anim.duration = self.scaleDuration;
//    [self.layer pop_addAnimation:anim forKey:kPOPLayerScaleXY];
}

@end
