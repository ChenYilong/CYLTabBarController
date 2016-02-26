//
//  CYLTabBarController.h
//  CYLCustomTabBarDemo
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//

@import Foundation;

static NSString * const CYLTabBarItemTitle = @"tabBarItemTitle";
static NSString * const CYLTabBarItemImage = @"tabBarItemImage";
static NSString * const CYLTabBarItemSelectedImage = @"tabBarItemSelectedImage";

extern NSUInteger CYLTabbarItemsCount;

@import UIKit;

@interface CYLTabBarController : UITabBarController

/**
 * An array of the root view controllers displayed by the tab bar interface.
 */
@property (nonatomic, readwrite, copy) IBOutletCollection(UIViewController) NSArray *viewControllers;
/**
 * The Attributes of items which is displayed on the tab bar.
 */
@property (nonatomic, readwrite, copy) IBOutletCollection(NSDictionary) NSArray *tabBarItemsAttributes;

/*!
 * Judge if there is plus button.
 */
+ (BOOL)havePlusButton;

/*!
 * Include plusButton if exists.
 */
+ (NSUInteger)allItemsInTabBarCount;

- (id<UIApplicationDelegate>)appDelegate;
- (UIWindow *)rootWindow;

@end

@interface UIViewController (CYLTabBarController)

/**
 * The nearest ancestor in the view controller hierarchy that is a tab bar controller. (read-only)
 */
@property (nonatomic, readonly) CYLTabBarController *cyl_tabBarController;

@end
