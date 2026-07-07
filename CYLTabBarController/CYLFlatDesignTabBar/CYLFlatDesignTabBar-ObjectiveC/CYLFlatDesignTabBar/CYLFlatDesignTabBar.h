//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLFlatDesignTabBarButton.h"

NS_ASSUME_NONNULL_BEGIN

@class CYLFlatDesignTabBar;

@protocol CYLFlatDesignTabBarDelegate<NSObject>
@optional

// 当用户点击时调用（而非通过编程）
- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItem:(CYLFlatDesignTabBarItem *)item;

@end

@interface CYLFlatDesignTabBar : UIView

@property (nullable, nonatomic, weak) id<CYLFlatDesignTabBarDelegate> delegate;
@property (nullable, nonatomic, copy) NSArray<CYLFlatDesignTabBarItem *> *items;

/*!
 * tabBarItems is same as items， 作用是兼容CYLTabBar，实际效果以items为准。
 */
@property (nullable, nonatomic, copy) NSArray<CYLFlatDesignTabBarButton *> *tabBarItems;

- (CYLFlatDesignTabBarItem *)addItemWithTitle:(NSString *)title
                              tabBarItemImage:(id)tabBarItemImage
                      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                                        index:(NSInteger)index
                      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                  imageInsets:(UIEdgeInsets)imageInsets
                               lottieFilePath:(NSString *)lottieFilePath
                              lottieSizeValue:(NSValue *)lottieSizeValue;

@property (nullable, nonatomic, weak) CYLFlatDesignTabBarItem *selectedItem;

@property (nonatomic, assign) NSUInteger selectedIndex;

@property (nonatomic, strong, readonly) NSArray<CYLFlatDesignTabBarButton *> *tabBarButtons;

@property (null_resettable, nonatomic, strong) UIColor *tintColor;
@property (nullable, nonatomic, strong) UIColor *barTintColor UI_APPEARANCE_SELECTOR;  // default is nil

/* The background image will be tiled to fit, even if it was not created via the UIImage resizableImage methods.
 */
@property (nullable, nonatomic, strong) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;


/* Default is nil. When non-nil, a custom shadow image to show instead of the default shadow image. For a custom shadow to be shown, a custom background image must also be set with -setBackgroundImage: (if the default background image is used, the default shadow image will be used).
 */
@property (nullable, nonatomic, strong) UIImage *shadowImage UI_APPEARANCE_SELECTOR;

/* default is YES.
    当横屏时左右两边是否使用安全区域
 */
@property (nonatomic, assign) BOOL useLayoutSafeAreaInsets UI_APPEARANCE_SELECTOR;

/*!
 [EN] This can be left unset; the default is CYLTabBarController. If set, please implement the `+[CYLPlusButton tabBarContext]` method in CYLPlusButton and ensure consistency. If neither is implemented, the default is CYLTabBarController for both.

 [CN] 可以不设置， 默认为 CYLTabBarController，如果设置了，请实现 CYLPlusButton 里 的 `+[CYLPlusButton tabBarContext]` 并保持一致。如果两个都不是实现，默认为一致均为 CYLTabBarController
 */
@property (nonatomic, copy, nullable) NSString *context;

- (BOOL)hasPlusButton;

- (BOOL)hasPlusChildViewController;

@end

NS_ASSUME_NONNULL_END
