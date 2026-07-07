//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "_CYLFlatDesignTabBarParallaxOverlayView.h"
#import "CYLTabBarController.h"
//#import "CYLFlatDesignUIViewController.h"
#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
#import <CYLTabBarController/CYLTabBarController.h>
#else
#import "CYLTabBarController.h"
#endif

@implementation _CYLFlatDesignTabBarParallaxOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (UIEdgeInsets)safeAreaInsets {
    UIViewController *currentViewController = [self cyl_parallaxCurrentViewController];
    /*!
     *
        CYLFlatDesignUIViewController *customTabBarController = currentViewController.cylflatdesign_tabBarController;
        if (customTabBarController) {
            return customTabBarController.view.safeAreaInsets;
        }

     */
    UITabBarController *tabBarController = currentViewController.cylflatdesign_tabBarController;
    if (tabBarController) {
        return tabBarController.view.safeAreaInsets;
    }
    return [super safeAreaInsets];
}

- (UIViewController *)cyl_parallaxCurrentViewController {
    UIResponder *next = self.nextResponder;
    do {
        if ([next isKindOfClass:[UIViewController class]]) {
            return (UIViewController *)next;
        }
        next = next.nextResponder;
    } while (next != nil);
    return nil;
}

@end
