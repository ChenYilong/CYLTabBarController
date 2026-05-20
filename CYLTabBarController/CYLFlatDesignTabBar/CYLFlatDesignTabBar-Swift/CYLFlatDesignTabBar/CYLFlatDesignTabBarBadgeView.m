//
//  CYLFlatDesignTabBarBadgeView.m
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/11.
//

#import "CYLFlatDesignTabBarBadgeView.h"

@interface CYLFlatDesignTabBarBadgeView ()

@property (nonatomic, strong) UILabel *badgeLabel;

@end

@implementation CYLFlatDesignTabBarBadgeView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor systemRedColor];
        self.layer.masksToBounds = YES;
        _badgeLabel = [[UILabel alloc] init];
        _badgeLabel.textAlignment = NSTextAlignmentCenter;
        _badgeLabel.font = [UIFont systemFontOfSize:11];
        _badgeLabel.textColor = [UIColor whiteColor];
        [self addSubview:_badgeLabel];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    _badgeLabel.frame = self.bounds;
    self.layer.cornerRadius = self.bounds.size.height / 2;
}

- (void)setBadgeValue:(NSString *)badgeValue {
    if (![_badgeValue isEqualToString:badgeValue]) {
        _badgeValue = [badgeValue copy];
        _badgeLabel.text = badgeValue;
    }
}

- (void)setBadgeContentInset:(UIEdgeInsets)badgeContentInset {
    if (!UIEdgeInsetsEqualToEdgeInsets(_badgeContentInset, badgeContentInset)) {
        _badgeContentInset = badgeContentInset;
    }
}

- (void)setBadgeTextColor:(UIColor *)badgeTextColor {
    _badgeTextColor = badgeTextColor;
    if (badgeTextColor) {
        _badgeLabel.textColor = badgeTextColor;
    }
}

- (void)setBadgeTextFont:(UIFont *)badgeTextFont {
    _badgeTextFont = badgeTextFont;
    if (badgeTextFont) {
        _badgeLabel.font = badgeTextFont;
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    if (_badgeValue.length == 0) {
        return CGSizeZero;
    }
    CGSize badgeSize = [_badgeValue boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:0 attributes:@{NSFontAttributeName:_badgeLabel.font} context:nil].size;
    CGFloat width = badgeSize.width + _badgeContentInset.left + _badgeContentInset.right;
    CGFloat height = badgeSize.height + _badgeContentInset.top + _badgeContentInset.bottom;
    height = MAX(height, 18.0);
    width = MAX(width, height);
    return CGSizeMake(width, height);
}


@end
