/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 11/01/26.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import "CYLBadgeAppearance.h"
#import "CYLTabBarBadgeView.h"

static const CGFloat kCYLBadgeAppearanceDefaultRadius = 4.f;
static const CGFloat kCYLBadgeAppearanceDefaultMargin = 8.f;
static const NSInteger kCYLBadgeAppearanceDefaultMaximumBadgeNumber = 99;

/// A non-negative finite value, else 0.
static CGFloat CYLBadgeAppearanceNonNegative(CGFloat value) {
    return isfinite(value) ? MAX(0, value) : 0;
}

@implementation CYLBadgeAppearance

@synthesize backgroundColor = _backgroundColor;
@synthesize textColor = _textColor;
@synthesize font = _font;

+ (CYLBadgeAppearance *)globalAppearance {
    static CYLBadgeAppearance *globalAppearance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalAppearance = [[self alloc] init];
    });
    return globalAppearance;
}

- (instancetype)init {
    if (self = [super init]) {
        [self reset];
    }
    return self;
}

- (void)reset {
    _backgroundColor = nil;
    _textColor = nil;
    _font = nil;
    _centerOffset = CGPointZero;
    _radius = kCYLBadgeAppearanceDefaultRadius;
    _margin = kCYLBadgeAppearanceDefaultMargin;
    _maximumBadgeNumber = kCYLBadgeAppearanceDefaultMaximumBadgeNumber;
    _cornerRadius = 0;
    _borderColor = nil;
    _borderWidth = 0;
}

- (UIColor *)backgroundColor {
    return _backgroundColor ?: [UIColor redColor];
}

- (UIColor *)textColor {
    return _textColor ?: [UIColor whiteColor];
}

- (UIFont *)font {
    return _font ?: kCYLBadgeDefaultFont;
}

- (void)setCenterOffset:(CGPoint)centerOffset {
    _centerOffset = CGPointMake(isfinite(centerOffset.x) ? centerOffset.x : 0,
                                isfinite(centerOffset.y) ? centerOffset.y : 0);
}

- (void)setRadius:(CGFloat)radius {
    _radius = (radius > 0 && isfinite(radius)) ? radius : kCYLBadgeAppearanceDefaultRadius;
}

- (void)setMargin:(CGFloat)margin {
    _margin = CYLBadgeAppearanceNonNegative(margin);
}

- (void)setMaximumBadgeNumber:(NSInteger)maximumBadgeNumber {
    _maximumBadgeNumber = MAX(1, maximumBadgeNumber);
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = CYLBadgeAppearanceNonNegative(cornerRadius);
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _borderWidth = CYLBadgeAppearanceNonNegative(borderWidth);
}

@end
