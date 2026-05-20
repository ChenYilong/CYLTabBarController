//
//  _CYLFlatDesignTabBarParallaxOverlayView.m
//  CYLFlatDesignTabBarController
//
//  Created by apple on 2026/2/10.
//

#import "_CYLFlatDesignTabBarParallaxOverlayView.h"
#import "CYLFlatDesignTabBarController.h"
#import "CYLFlatDesignTabViewController.h"

@implementation _CYLFlatDesignTabBarParallaxOverlayView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (UIEdgeInsets)safeAreaInsets {
    UIViewController *currentViewController = [self cyl_parallaxCurrentViewController];
    CYLFlatDesignTabViewController *customTabBarController = currentViewController.cyl_tabBarController;
    if (customTabBarController) {
        return customTabBarController.view.safeAreaInsets;
    }
    UITabBarController *tabBarController = currentViewController.tabBarController;
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
