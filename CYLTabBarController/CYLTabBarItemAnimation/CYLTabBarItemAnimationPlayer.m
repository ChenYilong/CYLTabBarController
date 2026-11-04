//
//  CYLTabBarItemAnimationPlayer.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarItemAnimationPlayer.h"

@implementation CYLTabBarItemAnimationBasePlayer

- (instancetype)initWithAnimationView:(UIView *)animationView {
    if (self = [super init]) {
        _animationView = animationView;
    }
    return self;
}

@end
