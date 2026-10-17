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

/*!
 * [EN] Creates a flat-design tab bar button for `tabBarItem` and links the item back to this button.
 * [CN] 使用 tabBarItem 创建扁平化 TabBar 按钮，并将该 Item 关联回此按钮。
 */
- (instancetype)initWithTabBarItem:(CYLFlatDesignTabBarItem *)tabBarItem;
@property (nonatomic, strong) CYLFlatDesignTabBarItem *tabBarItem;
@property (nonatomic, strong, readonly) UIImageView *imageView;
@property (nonatomic, strong, readonly) UILabel *titleLabel;

/*!
 * [EN] Returns the view that hosts this button's badge.
 * [CN] 返回承载该按钮角标的视图。
 */
- (UIView *)actualBadgeSuperView;

@end

NS_ASSUME_NONNULL_END
