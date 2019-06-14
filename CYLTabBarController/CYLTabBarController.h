//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButton.h"
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "UIViewController+CYLNavigationControllerExtention.h"
#import "UIView+CYLTabBarControllerExtention.h"
#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "CYLBaseViewController.h"
#import "CYLBaseTableViewController.h"
#import "CYLBaseNavigationController.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"
#import "UITabBarItem+CYLBadgeExtention.h"
#import "UIBarButtonItem+CYLBadgeExtention.h"
#import "UIView+CYLBadgeExtention.h"
#import "NSObject+CYLTabBarControllerExtention.h"
#import "UIColor+CYLTabBarControllerExtention.h"

NS_ASSUME_NONNULL_BEGIN

@class CYLTabBarController;
typedef void(^CYLViewDidLayoutSubViewsBlock)(CYLTabBarController *tabBarController);

FOUNDATION_EXTERN NSString *const CYLTabBarItemTitle;
FOUNDATION_EXTERN NSString *const CYLTabBarItemImage;
FOUNDATION_EXTERN NSString *const CYLTabBarItemSelectedImage;
FOUNDATION_EXTERN NSString *const CYLTabBarLottieURL;
FOUNDATION_EXTERN NSString *const CYLTabBarLottieSize;
FOUNDATION_EXTERN NSString *const CYLTabBarItemImageInsets;
FOUNDATION_EXTERN NSString *const CYLTabBarItemTitlePositionAdjustment;
FOUNDATION_EXTERN NSUInteger CYLTabbarItemsCount;
FOUNDATION_EXTERN NSUInteger CYLPlusButtonIndex;
FOUNDATION_EXTERN CGFloat CYLPlusButtonWidth;
FOUNDATION_EXTERN CGFloat CYLTabBarItemWidth;
FOUNDATION_EXTERN CGFloat CYLTabBarHeight;

@protocol CYLTabBarControllerDelegate <NSObject, UITabBarControllerDelegate>
@optional
/*!
 * @param tabBarController The tab bar controller containing viewController.
 * @param control Selected UIControl in TabBar.
 */
- (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control;

@end

@interface CYLTabBarController : UITabBarController <CYLTabBarControllerDelegate>

@property (nonatomic, copy) CYLViewDidLayoutSubViewsBlock viewDidLayoutSubviewsBlock;

- (void)setViewDidLayoutSubViewsBlock:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock;
- (void)setViewDidLayoutSubViewsBlockInvokeOnce:(BOOL)invokeOnce block:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock;
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
@property (nonatomic, readonly, assign) UIEdgeInsets imageInsets;

@property (nonatomic, strong) CYLTabBar *tabBar;

/*! 
 * To set both UIBarItem label text attributes in the tabBar,
 * use the following to tweak the relative position of the label within the tab button (for handling visual centering corrections if needed because of custom text attributes)
 */
@property (nonatomic, readonly, assign) UIOffset titlePositionAdjustment;

@property (nonatomic, readonly, copy) NSString *context;

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes;

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes;

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment;

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment;

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                context:(NSString *)context;

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                            context:(NSString *)context;

- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController;

- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController shouldSelect:(BOOL)shouldSelect;

- (void)hideTabBarShadowImageView;

- (void)setTintColor:(UIColor *)tintColor;

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

@interface NSObject (CYLTabBarControllerReferenceExtension)

/*!
 * If `self` is kind of `UIViewController`, this method will return the nearest ancestor in the view controller hierarchy that is a tab bar controller. If `self` is not kind of `UIViewController`, it will return the `rootViewController` of the `rootWindow` as long as you have set the `CYLTabBarController` as the  `rootViewController`. Otherwise return nil. (read-only)
 */
@property (nonatomic, setter=cyl_setTabBarController:) CYLTabBarController *cyl_tabBarController;

@end

#pragma mark - Deprecated API

@interface CYLTabBarController (CYLTabBarControllerDeprecated)

- (void)hideTabBadgeBackgroundSeparator CYL_DEPRECATED("Deprecated in 1.27.0. Use `+[CYLPlusButton hideTabBarShadowImageView]` instead.");

@end

FOUNDATION_EXTERN NSString *const CYLTabBarItemWidthDidChangeNotification;

NS_ASSUME_NONNULL_END
