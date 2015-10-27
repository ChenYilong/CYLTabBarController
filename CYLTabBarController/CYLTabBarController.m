//
//  CYLTabBarController.m
//  CYLCustomTabBarDemo
//
//  Created by 微博@iOS程序犭袁 (http://weibo.com/luohanchenyilong/) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"

#import "CYLTabBar.h"
#import <objc/runtime.h>
NSUInteger CYLTabbarItemsCount = 0;

@interface UIViewController (CYLTabBarControllerItemInternal)

- (void)cyl_setTabBarController:(CYLTabBarController *)tabBarController;

@end

@interface CYLTabBarController ()

@end
@implementation CYLTabBarController
@synthesize viewControllers = _viewControllers;

#pragma mark -
#pragma mark - Life Cycle

-(void)viewDidLoad{
    [super viewDidLoad];
    // 设置 TabBarItemTestAttributes 的颜色。
    [self setUpTabBarItemTextAttributes];
    // 处理tabBar，使用自定义 tabBar 添加 发布按钮
    [self setUpTabBar];
    [[UITabBar appearance] setBackgroundImage:[self imageWithColor:[UIColor whiteColor]]];
    //去除 TabBar 自带的顶部阴影
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
}

#pragma mark -
#pragma mark - Private Methods

/**
 *  利用 KVC 把 系统的 tabBar 类型改为自定义类型。
 */
- (void)setUpTabBar {
    [self setValue:[[CYLTabBar alloc] init] forKey:@"tabBar"];
}

/**
 *  tabBarItem 的选中和不选中文字属性
 */
- (void)setUpTabBarItemTextAttributes{
    
    // 普通状态下的文字属性
    NSMutableDictionary *normalAttrs = [NSMutableDictionary dictionary];
    normalAttrs[NSForegroundColorAttributeName] = [UIColor grayColor];
    
    // 选中状态下的文字属性
    NSMutableDictionary *selectedAttrs = [NSMutableDictionary dictionary];
    selectedAttrs[NSForegroundColorAttributeName] = [UIColor darkGrayColor];
    
    // 设置文字属性
    UITabBarItem *tabBar = [UITabBarItem appearance];
    [tabBar setTitleTextAttributes:normalAttrs forState:UIControlStateNormal];
    [tabBar setTitleTextAttributes:normalAttrs forState:UIControlStateHighlighted];
    
}

- (void)setViewControllers:(NSArray *)viewControllers {
    if (_viewControllers && _viewControllers.count) {
        for (UIViewController *viewController in _viewControllers) {
            [viewController willMoveToParentViewController:nil];
            [viewController.view removeFromSuperview];
            [viewController removeFromParentViewController];
        }
    }
    
    if (viewControllers && [viewControllers isKindOfClass:[NSArray class]]) {
        _viewControllers = [viewControllers copy];
        if (_tabBarItemsAttributes) {
            if (_tabBarItemsAttributes.count != _viewControllers.count) {
                [NSException raise:@"CYLTabBarController" format:@"The count of CYLTabBarControllers is not equal to the count of tabBarItemsAttributes 设置_tabBarItemsAttributes属性时，请确保元素个数与控制器的个数相同，并在方法`-setViewControllers:`之前设置"];
            }
        }
        CYLTabbarItemsCount = [viewControllers count];
        NSUInteger idx = 0;
        for (UIViewController *viewController in viewControllers) {
            [self addOneChildViewController:viewController
                                  WithTitle:_tabBarItemsAttributes[idx][CYLTabBarItemTitle]
                            normalImageName:_tabBarItemsAttributes[idx][CYLTabBarItemImage]
                          selectedImageName:_tabBarItemsAttributes[idx][CYLTabBarItemSelectedImage]];
            [viewController cyl_setTabBarController:self];
            idx++;
        }
    } else {
        for (UIViewController *viewController in _viewControllers) {
            [viewController cyl_setTabBarController:nil];
        }
        _viewControllers = nil;
    }
}

/**
 *  添加一个子控制器
 *
 *  @param viewController    控制器
 *  @param title             标题
 *  @param normalImageName   图片
 *  @param selectedImageName 选中图片
 */
- (void)addOneChildViewController:(UIViewController *)viewController
                        WithTitle:(NSString *)title
                  normalImageName:(NSString *)normalImageName
                selectedImageName:(NSString *)selectedImageName {
    
    viewController.tabBarItem.title         = title;
    UIImage *normalImage = [UIImage imageNamed:normalImageName];
    normalImage = [normalImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    viewController.tabBarItem.image         = normalImage;
    UIImage *selectedImage = [UIImage imageNamed:selectedImageName];
    selectedImage = [selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    viewController.tabBarItem.selectedImage = selectedImage;
    
    [self addChildViewController:viewController];
    
}

- (UIImage *)imageWithColor:(UIColor *)color
{
    NSParameterAssert(color != nil);
    
    CGRect rect = CGRectMake(0, 0, 1, 1);
    // Create a 1 by 1 pixel context
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color setFill];
    UIRectFill(rect);   // Fill it with your color
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

@end

#pragma mark - UIViewController+CYLTabBarControllerItem

@implementation UIViewController (CYLTabBarControllerItemInternal)

- (void)cyl_setTabBarController:(CYLTabBarController *)tabBarController {
    objc_setAssociatedObject(self, @selector(cyl_tabBarController), tabBarController, OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation UIViewController (CYLTabBarController)

- (CYLTabBarController *)cyl_tabBarController {
    CYLTabBarController *tabBarController = objc_getAssociatedObject(self, @selector(cyl_tabBarController));
    
    if (!tabBarController && self.parentViewController) {
        tabBarController = [self.parentViewController cyl_tabBarController];
    }
    
    return tabBarController;
}

@end