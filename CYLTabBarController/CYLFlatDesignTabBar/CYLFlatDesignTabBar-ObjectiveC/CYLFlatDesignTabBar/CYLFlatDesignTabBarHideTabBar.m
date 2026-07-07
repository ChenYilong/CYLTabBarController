//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLFlatDesignTabBarHideTabBar.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

@interface CYLFlatDesignTabBarHideTabBar ()
@property (nonatomic, weak) UIView *platterView;

@end
@implementation CYLFlatDesignTabBarHideTabBar

#pragma mark - 重写父类方法

- (void)setHidden:(BOOL)hidden {
    hidden = YES;
    [super setHidden:hidden];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self.cyl_platterView cyl_setHidden:YES];
    [self.platterView cyl_setHidden:YES];

}

- (void)addSubview:(UIView *)view {
    if (![self isKindOfClass:[UITabBar class]]) {
        [super addSubview:view];
        return;
    }
    if ([view isKindOfClass:[UITabBar class]]) {
        //为了防止类似这样的异常代码，自己添加自己：`[self.tabBar addSubview:myTabBar]`(这是异常逻辑， 解决办法是请使用  KVC: `[self cyl_setValue:myTabBar forKey:@"tabBar"]`)
        return;
    }
  
    if ([view cyl_isPlatterView]) {
        view.hidden = YES;
        [self cyl_setPlatterView:view];
        [self setPlatterView:view];
        return;
    }
    
    [super addSubview:view];
}

- (void)addGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if ([self isKindOfClass:[UITabBar class]]) {
        
        NSString *gestureRecognizerClassString = NSStringFromClass([gestureRecognizer class]);
        if ([gestureRecognizer cyl_isContinuousGestureRecognizer]) {
            gestureRecognizer.enabled = NO;
        }
        if ([gestureRecognizer cyl_isLongGestureRecognizer]) {
            gestureRecognizer.enabled = NO;
        }
    }
    [super addGestureRecognizer:gestureRecognizer];
}

@end

