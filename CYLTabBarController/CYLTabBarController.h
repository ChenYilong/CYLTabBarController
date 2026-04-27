//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
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
#import "CYLFlatDesignTabBar.h"

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
 * @param control Selected UIControl in TabBar. 与 `-[UITaBar  tabBar: didSelectItem:]` 相比，差别在于该参数UIControl可能包含自定义加号➕按钮。且支持如果是代码或者用户交互切换index时都进行回调。弥补了 `-[UITaBar  tabBar: didSelectItem:]` 仅在用户点击时调用的不足。
 
 * @attention 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。可在PlusButton初始化时使用 CYLExternPlusButton.cyl_shouldNotSelect = YES; 来禁止该协议方法触发涉及plusButton的回调
 */
- (void)tabBarController:(UITabBarController *)tabBarController didSelectControl:(UIControl *)control;

@end

@interface CYLTabBarController : UITabBarController <CYLTabBarControllerDelegate, CYLFlatDesignTabBarDelegate>

typedef NS_ENUM(NSInteger, CYLTabBarStyleType) {
    CYLTabBarStyleTypeDefault = 0,
    CYLTabBarStyleTypeSystem,
    CYLTabBarStyleTypeFlatDesign,
    CYLTabBarStyleTypeLiquidGlass
};

/*!
 * 设置为CYLTabBarStyleTypeFlatDesign，表示扁平化设计， 本属性相当于UI兼容模式的代码替代版本，仅仅在 iOS26+ 系统有效。   其内部会设置noNeedUIDesignCompatibility该属性用于决定是否使用扁平设计。
 * @return means noNeedUIDesignCompatibility == YES if return CYLTabBarStyleTypeLiquidGlass, means noNeedUIDesignCompatibility == NO if return CYLTabBarStyleTypeFlatDesign;
 * @attention 请在父类的 ViewDidLoad 调用之前设置 CYLTabBarStyleType 。也就是在 `-[super viewDidLoad];` 之前调用。因为 需要在 tabBar 的KVC操作之前确定自定义样式，否则， 就会执行默认逻辑， 可能会导致你的自定义样式失效。
 */
@property (nonatomic, assign) CYLTabBarStyleType tabBarStyleType;

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

@property (nonatomic, strong, readonly) CYLTabBar *tabBar;

/*!
 * To set both UIBarItem label text attributes in the tabBar,
 * use the following to tweak the relative position of the label within the tab button (for handling visual centering corrections if needed because of custom text attributes)
 */
@property (nonatomic, readonly, assign) UIOffset titlePositionAdjustment;

/** 可以不设置， 默认为 CYLTabBarController，如果设置了，请实现 CYLPlusButton 里 的 +[CYLPlusButton tabBarContext] 并保持一致。如果两个都不是实现，默认为一致均为 CYLTabBarController */
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

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                              styleType:(CYLTabBarStyleType)styleType
                                context:(NSString *)context;

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                          styleType:(CYLTabBarStyleType)styleType
                                            context:(NSString *)context;

- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController;

- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController
                                            shouldSelect:(BOOL)shouldSelect;

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

- (CGSize)visiableTabBarSize;

/*!
 * double-check if to use CYLTabBarStyleTypeLiquidGlass or not:
 * UIDesignCompatibility == FlatDesign , noNeedUIDesignCompatibility == noNeed FlatDesign == LiquidGlass
 * 设置为 NO，表示扁平化设计， 本属性相当于UI兼容模式的代码替代版本，仅仅在 iOS26+ 系统有效。
 * 由于 UI 兼容模式的命名晦涩， 更优雅直观的方式为 设置 CYLTabBarStyleType，其内部会设置该属性用于决定是否使用扁平设计。
 
 * @return means  CYLTabBarStyleType == CYLTabBarStyleTypeFlatDesign if return NO, means  CYLTabBarStyleType == CYLTabBarStyleTypeLiquidGlass if return YES;
 * @attention better switch to property CYLTabBarStyleType
 */
@property (nonatomic, assign) BOOL noNeedUIDesignCompatibility;
@property (nonatomic, assign, getter=isLottieViewAdded, readonly) BOOL lottieViewAdded;

@property (nonatomic, strong, readonly) NSMutableArray<NSURL *> *lottieURLs;
@property (nonatomic, strong, readonly) NSMutableArray *lottieSizes;
@end

@interface NSObject (CYLTabBarControllerReferenceExtension)

/*!
 * If `self` is kind of `UIViewController`, this method will return the nearest ancestor in the view controller hierarchy that is a tab bar controller. If `self` is not kind of `UIViewController`, it will return the `rootViewController` of the `rootWindow` as long as you have set the `CYLTabBarController` as the  `rootViewController`. Otherwise return nil. (read-only)
 */
@property (nonatomic, setter=cyl_setTabBarController:) CYLTabBarController *cyl_tabBarController;

@end

#pragma mark - Deprecated API

@interface CYLTabBarController (CYLTabBarControllerDeprecated)

- (void)hideTabBadgeBackgroundSeparator CYL_DEPRECATED("Deprecated in 1.27.0. Use `-[CYLTabBarController hideTabBarShadowImageView]` instead.");

@end

FOUNDATION_EXTERN NSString *const CYLTabBarItemWidthDidChangeNotification;

NS_ASSUME_NONNULL_END

