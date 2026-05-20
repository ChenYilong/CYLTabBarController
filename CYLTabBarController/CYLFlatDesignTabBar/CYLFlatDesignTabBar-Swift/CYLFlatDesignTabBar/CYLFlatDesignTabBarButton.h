//
//  CYLFlatDesignTabBarButton.h
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/6.
//

#import <UIKit/UIKit.h>
#import "CYLFlatDesignTabBarItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CYLFlatDesignTabBarButton : UIControl

- (instancetype)initWithTabBarItem:(CYLFlatDesignTabBarItem *)tabBarItem;
@property (nonatomic, strong) CYLFlatDesignTabBarItem *tabBarItem;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;

@end

NS_ASSUME_NONNULL_END
