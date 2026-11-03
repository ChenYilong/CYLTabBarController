//
//  UIView+CYLUtils.m
//  CYLUtils
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "UIView+CYLUtils.h"

@implementation UIView (CYLUtils)

- (void)cyl_setHidden:(BOOL)hidden {
    if (hidden) {
        self.opaque = NO;
        self.hidden = YES;
        self.alpha = 0.0f;
        self.userInteractionEnabled = NO;
        [self cyl_setIsPlaceholder:NO];
    } else {
        self.opaque = YES;
        self.hidden = NO;
        self.alpha = 1.0f;
        self.userInteractionEnabled = YES;
        [self cyl_setIsPlaceholder:YES];
    }
}

- (BOOL)cyl_isInvisiable {
    BOOL isSizeZero = CGSizeEqualToSize(CGSizeZero, self.frame.size);
    //这里删除(NO == obj.opaque) ，因为iOS27以上的视图，渲染会通过通过 opaque 设置为 NO 进行，所以这里删除涉及关于 opaque 的判断。
    BOOL isInvisible = (YES == self.hidden ) || (self.alpha <= 0.01f)  || (!self.superview) || isSizeZero;
    return isInvisible;
}

- (BOOL)cyl_canNotResponseEvent {
    return self.cyl_isInvisiable || (NO == self.userInteractionEnabled ) || self.cyl_isPlaceholder;
}

@end
