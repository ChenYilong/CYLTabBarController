//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignTabBarButton.h"
#import "CYLFlatDesignTabBarItem.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

@interface CYLFlatDesignTabBarButton ()

@end

@implementation CYLFlatDesignTabBarButton
@synthesize selected = _selected;
//@synthesize enabled = _enabled;

- (instancetype)initWithTabBarItem:(CYLFlatDesignTabBarItem *)tabBarItem {
    if (self = [super init]) {
        _tabBarItem = tabBarItem;
        self.clipsToBounds = NO;
        if (tabBarItem) {
            [self _updateTabBarButton];
        }
        if (_tabBarItem) {
            [_tabBarItem cyl_setValue:self forKey:@"tabBarButton"];
        }
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _imageView = [[UIImageView alloc] init];
        _imageView.clipsToBounds = NO;
        [self addSubview:_imageView];
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.clipsToBounds = NO;
//        [self.actualBadgeSuperView cyl_showBadgeValue:_tabBarItem.badgeValue];
        [self addSubview:_titleLabel];
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
    if (![self.tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
        return;
    }
    _tabBarItem = tabBarItem;
    [self _updateTabBarButton];
    if (_tabBarItem && !(_tabBarItem.tabBarButton)) {
        [_tabBarItem cyl_setValue:self forKey:@"tabBarButton"];
    }
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
    if (_tabBarItem) {
        //        [_tabBarItem cyl_setTabButton:self];
    }
#else
#endif
}

- (void)setSelected:(BOOL)selected {
    if (self.selected != selected) {
        [super setSelected:selected];
        _selected = selected;
        [self _updateTabBarButton];
    }
}

/*!
 * // badge 请使用VC 调用， 暂不支持 _tabBarItem 设置。
 if (self.actualBadgeSuperView.cyl_isShowBadge) {
     if (_tabBarItem.badgeColor) {
         [self cyl_setBadgeBackgroundColor:_tabBarItem.badgeColor];
     }
     [self cyl_showBadgeValue:_tabBarItem.badgeValue];
     NSDictionary *badgeTextAttributes = [self _badgeTextAttributesForState];
     [self cyl_setBadgeFont:badgeTextAttributes[NSFontAttributeName]];
     [self cyl_setBadgeTextColor:badgeTextAttributes[NSForegroundColorAttributeName]];
     if (isCYLFlatDesignTabBarItem) {
         //            [self.actualBadgeSuperView setInset = _tabBarItem.badgeContentInset;
         [self cyl_setBadgeMargin:_tabBarItem.badgeContentInset.left];
     }
 }

 */
- (void)_updateTabBarButton {
    if (CGRectIsEmpty(self.bounds)) {
//        return;
    }
    BOOL isCYLFlatDesignTabBarItem = [_tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]];
    self.enabled = _tabBarItem.enabled;
    
    // image
    UIImage *image = _tabBarItem.image;
    if (self.isSelected && _tabBarItem.selectedImage) {
        image = _tabBarItem.selectedImage;
    }
    _imageView.image = image;
    if (self.isSelected) {
        _imageView.tintColor = self.tintColor;
    } else {
        _imageView.tintColor = [UIColor systemGrayColor];
    }

    // title
    _titleLabel.text = _tabBarItem.title;
    _titleLabel.textColor = [self _titleTextAttributesForState][NSForegroundColorAttributeName];
    _titleLabel.font = [self _titleTextAttributesForState][NSFontAttributeName];
   
    // background
    if (isCYLFlatDesignTabBarItem) {
        UIColor *backgroundColor = _tabBarItem.backgroundColor;
        if (self.isSelected) {
            backgroundColor = _tabBarItem.selectedBackgroundColor ?: _tabBarItem.backgroundColor;
        }
        self.backgroundColor = backgroundColor;
    }
    [self updateLottie];
    [self setNeedsLayout];
//    [self layoutIfNeeded];
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
    
    NSString *title = isShowTitleLabel ? _titleLabel.text : @"height";
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
        
        UIEdgeInsets imageInsets = _tabBarItem.imageInsets;
        if (!UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, imageInsets)) {
            //仅修改的size,xy值不变
            _imageView.frame = ({
                CGRect frame = _imageView.frame;
                frame.size.width = frame.size.width - imageInsets.left - imageInsets.right;
                frame.size.height = frame.size.height - imageInsets.top - imageInsets.bottom;
                
                frame;
            });
        }
    } else {
        _imageView.frame = CGRectZero;
    }
    [self initLottie];
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

#pragma mark - initLottie

- (NSValue *)_lottieSizeValue {
    NSValue *lottieSizeValue;
    if ([_tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
        lottieSizeValue = _tabBarItem.lottieSizeValue;
    }
    return lottieSizeValue;
}

- (NSString *)_lottieFilePath {
    NSString *lottieFilePath;
    
    if ([_tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
        lottieFilePath = _tabBarItem.lottieFilePath;
    }
    return lottieFilePath;
}

- (void)initLottie {
    NSString *lottieFilePath = [self _lottieFilePath];
    
    NSValue *lottieSizeValue = [self _lottieSizeValue];
    
    NSURL *lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
    if (!lottieURL) {
        return;
    }

    if (lottieURL) {
#if __has_include(<Lottie/Lottie.h>)
        CGSize lottieSize = [lottieSizeValue CGSizeValue];
        [self cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.cyl_tabBarController.lottieAnimationViewContentMode];
#endif
     
#if __has_include(<Lottie/Lottie-Swift.h>)
        CGSize lottieSize = [lottieSizeValue CGSizeValue];
        [self cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.cyl_tabBarController.lottieAnimationViewContentMode];
#endif
    }
}

- (void)updateLottie {
    if (![self.tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
        return;
    }
    if (self.isSelected) {
        NSValue *lottieSizeValue = [self _lottieSizeValue];
        NSString *lottieFilePath = [self _lottieFilePath];
        CGSize lottieSize = [lottieSizeValue CGSizeValue];
        NSURL *lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
        if (!lottieURL) {
            return;
        }
        [self cyl_animationLottieImageWithLottieURL:lottieURL size:lottieSize defaultSelected:NO contentMode:self.cyl_tabBarController.lottieAnimationViewContentMode];
    }
    else {
//        [self cyl_stopAnimationOfLottieView];
    }
}

- (UIView *)actualBadgeSuperView {
    return self.cyl_getActualBadgeSuperView;
}

@end
