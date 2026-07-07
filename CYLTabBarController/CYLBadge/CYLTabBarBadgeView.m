//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarBadgeView.h"

@interface CYLTabBarBadgeView ()

@property (nonatomic, strong) UILabel *badgeLabel;

@end

@implementation CYLTabBarBadgeView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.layer.masksToBounds = YES;
        [self badgeLabel];
    }
    return self;
}

- (UILabel *)badgeLabel {
    if (!_badgeLabel) {
        _badgeLabel = [[UILabel alloc] initWithFrame:self.frame];
        _badgeLabel.textAlignment = NSTextAlignmentCenter;
        _badgeLabel.backgroundColor = [UIColor clearColor];
        _badgeLabel.text = @"test";
        _badgeLabel.translatesAutoresizingMaskIntoConstraints = NO;

//        _badgeLabel.font = kCYLBadgeDefaultFont;//[UIFont systemFontOfSize:11];
        _badgeLabel.textColor = [UIColor whiteColor];
        
        [self addSubview:_badgeLabel];
        [self bringSubviewToFront:_badgeLabel];
        _badgeLabel.layer.zPosition = MAXFLOAT;
    }
    return _badgeLabel;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (CGRectEqualToRect(CGRectZero, self.bounds)) {
        return;
    }
    if (CGRectEqualToRect(self.badgeLabel.frame, self.bounds)) {
        return;
    }
     
//    self.frame = self.bounds;
//    [self setNeedsDisplay];

    self.badgeLabel.frame = self.bounds;

//    self.badgeLabel.center = self.center;

}
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    if (CGRectEqualToRect(CGRectZero, frame)) {
        return;
    }
    if (CGRectEqualToRect(CGRectZero, CGRectMake(0, 0, frame.size.width, frame.size.height))) {
        return;
    }
    self.badgeLabel.frame = frame;

}

-(void)setCenter:(CGPoint)center {
        [super setCenter:center];
    if (CGPointEqualToPoint(CGPointZero, center)) {
        return;
    }
    self.badgeLabel.center = center;
}

- (void)setTextAlignment:(NSTextAlignment)textAlignment {
    _textAlignment = textAlignment;
    if (textAlignment) {
        [self.badgeLabel setTextAlignment:textAlignment];
    }
}

- (void)setTextColor:(UIColor *)badgeTextColor {
    _textColor = badgeTextColor;
    if (badgeTextColor) {
        self.badgeLabel.textColor = badgeTextColor;
    }
}

- (void)setFont:(UIFont *)badgeTextFont {
    _font = badgeTextFont;
    if (badgeTextFont) {
        self.badgeLabel.font = badgeTextFont;
    }
}

- (void)setText:(NSString *)badgeValue {
    if (![_text isEqualToString:badgeValue]) {
        _text = [badgeValue copy];
        self.badgeLabel.text = [badgeValue copy];
    }
}

- (void)setBadgeContentInset:(UIEdgeInsets)badgeContentInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_badgeContentInset, badgeContentInset)) {
        _badgeContentInset = badgeContentInset;
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (_text.length == 0) {
        return CGSizeZero;
    }
    CGSize badgeSize = [_text boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:0 attributes:@{NSFontAttributeName:self.badgeLabel.font} context:nil].size;
    CGFloat width = badgeSize.width + _badgeContentInset.left + _badgeContentInset.right;
    CGFloat height = badgeSize.height + _badgeContentInset.top + _badgeContentInset.bottom;
    height = MAX(height, 18.0);
    width = MAX(width, height);
    return CGSizeMake(width, height);
}

@end
