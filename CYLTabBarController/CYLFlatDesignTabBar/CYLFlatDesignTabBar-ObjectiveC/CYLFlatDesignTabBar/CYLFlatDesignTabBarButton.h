//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLFlatDesignTabBarItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CYLFlatDesignTabBarButton : UIControl

- (instancetype)initWithTabBarItem:(CYLFlatDesignTabBarItem *)tabBarItem;
@property (nonatomic, strong) CYLFlatDesignTabBarItem *tabBarItem;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;

- (UIView *)actualBadgeSuperView;

@end

NS_ASSUME_NONNULL_END
