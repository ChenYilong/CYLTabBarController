//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2015 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButton.h"
#import "UIViewController+CYLTabBarControllerExtention.h"

FOUNDATION_EXTERN NSString *const CYLTabBarItemTitle;
FOUNDATION_EXTERN NSString *const CYLTabBarItemImage;
FOUNDATION_EXTERN NSString *const CYLTabBarItemSelectedImage;
FOUNDATION_EXTERN NSUInteger CYLTabbarItemsCount;
FOUNDATION_EXTERN NSUInteger CYLPlusButtonIndex;
FOUNDATION_EXTERN CGFloat CYLPlusButtonWidth;
FOUNDATION_EXTERN CGFloat CYLTabBarItemWidth;

@interface CYLTabBarController : UITabBarController

/*!
 * An array of the root view controllers displayed by the tab bar interface.
 */
@property (nonatomic, readwrite, copy) NSArray<UIViewController *> *viewControllers;

/*!
 * The Attributes of items which is displayed on the tab bar.
 */
@property (nonatomic, readwrite, copy) NSArray<NSDictionary *> *tabBarItemsAttributes;

/*!
 * Customize UITabBar height
 */
@property (nonatomic, assign) CGFloat tabBarHeight;

/*!
 * To set both UIBarItem image view attributes in the tabBar,
 * default is UIEdgeInsetsZero.
 */
@property (nonatomic, readwrite, assign) UIEdgeInsets imageInsets;

/*! 
 * To set both UIBarItem label text attributes in the tabBar,
 * use the following to tweak the relative position of the label within the tab button (for handling visual centering corrections if needed because of custom text attributes)
 */
@property (nonatomic, readwrite, assign) UIOffset titlePositionAdjustment;

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes;

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes;

/*!
 * Judge if there is plus button.
 */
+ (BOOL)havePlusButton;

/*!
 * @attention Include plusButton if exists.
 */
+ (NSUInteger)allItemsInTabBarCount;

- (id<UIApplicationDelegate>)appDelegate;

- (UIWindow *)rootWindow;

@end

@interface NSObject (CYLTabBarController)

/*!
 * If `self` is kind of `UIViewController`, this method will return the nearest ancestor in the view controller hierarchy that is a tab bar controller. If `self` is not kind of `UIViewController`, it will return the `rootViewController` of the `rootWindow` as long as you have set the `CYLTabBarController` as the  `rootViewController`. Otherwise return nil. (read-only)
 */
@property (nonatomic, readonly) CYLTabBarController *cyl_tabBarController;

@end

FOUNDATION_EXTERN NSString *const CYLTabBarItemWidthDidChangeNotification;
