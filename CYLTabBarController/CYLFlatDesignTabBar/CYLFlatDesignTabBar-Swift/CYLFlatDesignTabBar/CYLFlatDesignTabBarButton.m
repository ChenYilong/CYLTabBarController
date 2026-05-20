//
//  CYLFlatDesignTabBarButton.m
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/6.
//

#import "CYLFlatDesignTabBarButton.h"
#import "CYLFlatDesignTabBarBadgeView.h"
#import "CYLFlatDesignTabBarItem.h"

@interface CYLFlatDesignTabBarButton ()

@property (nonatomic, strong) CYLFlatDesignTabBarBadgeView *badgeView;

@end

@implementation CYLFlatDesignTabBarButton

- (instancetype)initWithTabBarItem:(CYLFlatDesignTabBarItem *)tabBarItem {
    if (self = [super init]) {
        _tabBarItem = tabBarItem;
        if (tabBarItem) {
            [self _updateTabBarButton];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _imageView = [[UIImageView alloc] init];
        [self addSubview:_imageView];
        
        _titleLabel = [[UILabel alloc] init];
        [self addSubview:_titleLabel];
        
        _badgeView = [[CYLFlatDesignTabBarBadgeView alloc] init];
        _badgeView.hidden = YES;
        [self addSubview:_badgeView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self _updateLayout];
}

- (void)tintColorDidChange {
    [super tintColorDidChange];
    if (self.isSelected) {
        _titleLabel.textColor = [self _titleTextAttributesForState][NSForegroundColorAttributeName];
        _imageView.tintColor = self.tintColor;
    }
}

- (void)setTabBarItem:(CYLFlatDesignTabBarItem *)tabBarItem {
    _tabBarItem = tabBarItem;
    [self _updateTabBarButton];
}

- (void)setSelected:(BOOL)selected {
    if (self.selected != selected) {
        [super setSelected:selected];
        [self _updateTabBarButton];
    }
}

- (void)_updateTabBarButton {
    
    BOOL isCYLFlatDesignTabBarItem = [_tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]];
    self.enabled = _tabBarItem.enabled;
    
    // image
    UIImage *image = _tabBarItem.image;
    if (self.selected && _tabBarItem.selectedImage) {
        image = _tabBarItem.selectedImage;
    }
    _imageView.image = image;
    if (self.selected) {
        _imageView.tintColor = self.tintColor;
    } else {
        _imageView.tintColor = [UIColor systemGrayColor];
    }
    
    // title
    _titleLabel.text = _tabBarItem.title;
    _titleLabel.textColor = [self _titleTextAttributesForState][NSForegroundColorAttributeName];
    _titleLabel.font = [self _titleTextAttributesForState][NSFontAttributeName];
    
    // badge
    _badgeView.hidden = (_tabBarItem.badgeValue.length == 0);
    if (isCYLFlatDesignTabBarItem) {
        _badgeView.hidden = (_tabBarItem.badgeValue.length == 0 && CGSizeEqualToSize(_tabBarItem.badgeSize, CGSizeZero));
    }
    if (!_badgeView.hidden) {
        if (_tabBarItem.badgeColor) {
            _badgeView.backgroundColor = _tabBarItem.badgeColor;
        }
        _badgeView.badgeValue = _tabBarItem.badgeValue;
        NSDictionary *badgeTextAttributes = [self _badgeTextAttributesForState];
        _badgeView.badgeTextFont = badgeTextAttributes[NSFontAttributeName];
        _badgeView.badgeTextColor = badgeTextAttributes[NSForegroundColorAttributeName];
        if (isCYLFlatDesignTabBarItem) {
            _badgeView.badgeContentInset = _tabBarItem.badgeContentInset;
        }
    }
    
    // background
    if (isCYLFlatDesignTabBarItem) {
        UIColor *backgroundColor = _tabBarItem.backgroundColor;
        if (self.selected) {
            backgroundColor = _tabBarItem.selectedBackgroundColor ?: _tabBarItem.backgroundColor;
        }
        self.backgroundColor = backgroundColor;
    }
    
    [self setNeedsLayout];
}

- (void)_updateLayout {
    if (CGRectIsEmpty(self.bounds)) {
        return;
    }
    
    BOOL isShowImageView = _imageView.image != nil;
    BOOL isShowTitleLabel = _titleLabel.text.length > 0;
    BOOL isCYLFlatDesignTabBarItem = [_tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]];
    
    if (isShowImageView) {
        [_imageView sizeToFit];
    }
    
    /*
     好像系统UITabBar是这样计算的，但也不太清楚...
     如果没有title，也需要根据font计算title高度，用于占位。
     */
    NSString *title = isShowTitleLabel ? _titleLabel.text : @"高度";
    CGSize titleSize = [title boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_titleLabel.font} context:nil].size;
    
    CGFloat titleLabelWidth = titleSize.width;
    CGFloat titleLabelHeight = titleSize.height;
    CGFloat titleLabelX = (CGRectGetWidth(self.bounds) - titleLabelWidth) / 2;
    CGFloat titleLabelY = CGRectGetHeight(self.bounds) - titleLabelHeight - 2;
    if (!isShowImageView && _tabBarItem.layoutCentered) {
        titleLabelY = (CGRectGetHeight(self.bounds) - titleLabelHeight) / 2;
    }
    titleLabelX += _tabBarItem.titlePositionAdjustment.horizontal;
    titleLabelY += _tabBarItem.titlePositionAdjustment.vertical;
    _titleLabel.frame = CGRectMake(titleLabelX, titleLabelY, titleLabelWidth, titleLabelHeight);
    
    if (isShowImageView) {
        CGFloat imageViewWidth = CGRectGetWidth(_imageView.frame);
        CGFloat imageViewHeight = CGRectGetHeight(_imageView.frame);
        
        CGFloat imageViewX = (CGRectGetWidth(self.bounds) - imageViewWidth) / 2;
        CGFloat imageViewY = (CGRectGetMinY(_titleLabel.frame) - imageViewHeight) / 2;
        if (!isShowTitleLabel && isCYLFlatDesignTabBarItem && _tabBarItem.layoutCentered) {
            imageViewY = (CGRectGetHeight(self.bounds) - imageViewHeight) / 2;
        }
        if (isCYLFlatDesignTabBarItem) {
            imageViewX += _tabBarItem.imagePositionAdjustment.horizontal;
            imageViewY += _tabBarItem.imagePositionAdjustment.vertical;
        }
        _imageView.frame = CGRectMake(imageViewX, imageViewY, imageViewWidth, imageViewHeight);
    } else {
        _imageView.frame = CGRectZero;
    }
   
    // Layout Badge
    CGSize badgeSize = CGSizeZero;
    if (isCYLFlatDesignTabBarItem && !CGSizeEqualToSize(_tabBarItem.badgeSize, CGSizeZero)) {
        badgeSize = _tabBarItem.badgeSize;
    } else {
        badgeSize = [_badgeView sizeThatFits:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)];
    }
    
    CGFloat badgeViewX = CGRectGetMidX(self.frame) - 5;
    CGFloat badgeViewY = 2.0;
    if (isShowImageView) {
        // 以image为基准
        badgeViewX = CGRectGetMaxX(_imageView.frame) - 5;
    } else if (isShowTitleLabel) {
        // 以title为基准
        badgeViewX = CGRectGetMaxX(_titleLabel.frame) - 5;
    }
    
    if (isCYLFlatDesignTabBarItem) {
        badgeViewX += _tabBarItem.badgePositionAdjustment.horizontal;
        badgeViewY += _tabBarItem.badgePositionAdjustment.vertical;
    }
    _badgeView.frame = CGRectMake(badgeViewX, badgeViewY, badgeSize.width, badgeSize.height);
}

- (NSDictionary *)_titleTextAttributesForState {
    UIControlState state = [self _currentState];
    NSMutableDictionary *titleAttributes = [_tabBarItem titleTextAttributesForState:state].mutableCopy;
    if (!titleAttributes) {
        titleAttributes = [_tabBarItem titleTextAttributesForState:UIControlStateNormal].mutableCopy;
    }
    if (!titleAttributes) {
        if (state == UIControlStateSelected) {
            titleAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:10 weight:UIFontWeightMedium], NSForegroundColorAttributeName:self.tintColor}.mutableCopy;
        } else {
            titleAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:10 weight:UIFontWeightMedium], NSForegroundColorAttributeName:[UIColor systemGrayColor]}.mutableCopy;
        }
        
    }
    if (titleAttributes[NSFontAttributeName] == nil) {
        titleAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:10 weight:UIFontWeightMedium];
    }
    if (titleAttributes[NSForegroundColorAttributeName] == nil) {
        if (state == UIControlStateSelected) {
            titleAttributes[NSForegroundColorAttributeName] = self.tintColor;
        } else {
            titleAttributes[NSForegroundColorAttributeName] = [UIColor systemGrayColor];
        }
    }
    return [titleAttributes copy];
}

- (NSDictionary *)_badgeTextAttributesForState {
    UIControlState state = [self _currentState];
    NSMutableDictionary *badgeAttributes = [_tabBarItem badgeTextAttributesForState:state].mutableCopy;
    if (!badgeAttributes) {
        badgeAttributes = [_tabBarItem badgeTextAttributesForState:UIControlStateNormal].mutableCopy;
    }
    if (!badgeAttributes) {
        badgeAttributes = @{NSFontAttributeName:[UIFont systemFontOfSize:11], NSForegroundColorAttributeName:[UIColor whiteColor]}.mutableCopy;
    }
    if (badgeAttributes[NSFontAttributeName] == nil) {
        badgeAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:11];
    }
    if (badgeAttributes[NSForegroundColorAttributeName] == nil) {
        badgeAttributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    }
    return badgeAttributes;
}

- (UIControlState)_currentState {
    UIControlState state = self.state;
    if (UIControlStateSelected & self.state) {
        state = UIControlStateSelected;
    }
    if (UIControlStateDisabled & self.state) {
        state = UIControlStateDisabled;
    }
    return state;
}

@end
