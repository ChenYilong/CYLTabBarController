//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"

NS_ASSUME_NONNULL_BEGIN

// 继承自 CYLTabBarController
@interface CYLFlatDesignMainTabBarController : CYLTabBarController


- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                context:(NSString *)context;

@end



NS_ASSUME_NONNULL_END
