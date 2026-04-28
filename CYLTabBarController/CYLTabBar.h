//
//  CYLTabBar.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLPlusButton.h"

NS_ASSUME_NONNULL_BEGIN
@class CYLTabBar;
typedef void(^CYLTabBarDidLayoutSubViewsBlock)(CYLTabBar *tabBar);

@interface CYLTabBar : UITabBar

/*!
 * 让 `TabImageView` 垂直居中时，所需要的默认偏移量。
 * @attention 该值将在设置 top 和 bottom 时被同时使用，具体的操作等价于如下行为：
 * `viewController.tabBarItem.imageInsets = UIEdgeInsetsMake(tabImageViewDefaultOffset, 0, -tabImageViewDefaultOffset, 0);`
 */
@property (nonatomic, assign, readonly) CGFloat tabImageViewDefaultOffset;

/** 可以不设置， 默认为 CYLTabBarController，如果设置了，请实现 CYLPlusButton 里 的 +[CYLPlusButton tabBarContext] 并保持一致。如果两个都不是实现，默认为一致均为 CYLTabBarController */
@property (nonatomic, copy) NSString *context;

@property (nonatomic, copy, nullable) CYLTabBarDidLayoutSubViewsBlock didLayoutSubViewsBlock;

/** 发布按钮 */
@property (nonatomic, strong) UIButton<CYLPlusButtonSubclassing> *plusButton;
@property (nonatomic, assign) CGFloat tabBarItemWidth;
@property (nonatomic, copy) NSArray<UIControl *> *tabBarButtonArray;
@property (nonatomic, assign, getter=hasAddPlusButton) BOOL addPlusButton;
@property (nonatomic, assign) BOOL isLensViewLifed;

- (NSUInteger)plusButtonIndex;

@end

NS_ASSUME_NONNULL_END
