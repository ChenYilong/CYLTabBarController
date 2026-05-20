//
//  CYLFlatDesignTabBarBadgeView.h
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CYLFlatDesignTabBarBadgeView : UIView

@property (nonatomic, copy) NSString *badgeValue;
@property (nonatomic, assign) UIEdgeInsets badgeContentInset;
@property (nonatomic, strong) UIColor *badgeTextColor;
@property (nonatomic, strong) UIFont *badgeTextFont;

@end

NS_ASSUME_NONNULL_END
