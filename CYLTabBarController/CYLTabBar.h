//
//  CYLTabBar.h
//  CYLTabBarController
//
//  v1.14.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CYLTabBar : UITabBar

/*!
 * 让 `TabImageView` 垂直居中时，所需要的默认偏移量。
 * @attention 该值将在设置 top 和 bottom 时被同时使用，具体的操作等价于如下行为：
 * `viewController.tabBarItem.imageInsets = UIEdgeInsetsMake(tabImageViewDefaultOffset, 0, -tabImageViewDefaultOffset, 0);`
 */
@property (nonatomic, assign, readonly) CGFloat tabImageViewDefaultOffset;

@end
