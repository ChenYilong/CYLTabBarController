//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
@class CYLFlatDesignTabBarButton;

NS_ASSUME_NONNULL_BEGIN

extern NSString *const CYLFlatDesignTabBarItemDidChange;

@interface CYLFlatDesignTabBarItem : NSObject

/*!
 * [EN] Creates a flat-design tab bar item with a title and image.
 * [CN] 使用标题与图片创建扁平化 TabBarItem。
 */
- (instancetype)initWithTitle:(nullable NSString *)title
                        image:(nullable UIImage *)image;

/*!
 * [EN] Creates a flat-design tab bar item with a title, image and selected image.
 * [CN] 使用标题、图片与选中态图片创建扁平化 TabBarItem。
 */
- (instancetype)initWithTitle:(nullable NSString *)title
                        image:(nullable UIImage *)image
                selectedImage:(nullable UIImage *)selectedImage;

/*!
 * [EN] Designated initializer: title, images, index, title/image offsets, image insets and optional Lottie file path and size.
 * [CN] 指定初始化方法：设置标题、图片、索引、标题/图片偏移、图片内边距，以及可选的 Lottie 文件路径与尺寸。
 */
- (instancetype)initWithTitle:(NSString *)title
                        image:(id)image
                selectedImage:(id)selectedImage
                        index:(NSInteger)index
      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
      imagePositionAdjustment:(UIOffset)imagePositionAdjustment
                  imageInsets:(UIEdgeInsets)imageInsets
               lottieFilePath:(NSString *)lottieFilePath
              lottieSizeValue:(NSValue *)lottieSizeValue;

//- (UIControl *)getTabBarControl;
//FIXME:  to delete @property (nullable, nonatomic, weak) UIControl *view;

@property (nullable, nonatomic, strong) CYLFlatDesignTabBarButton *tabBarButton;

#pragma mark - 系统 UITabBarItem 有的属性
// default is YES
@property (nonatomic, assign, getter=isEnabled) BOOL enabled;
@property (nonatomic, assign) NSUInteger index;

@property (nullable, nonatomic, copy) NSString *title;
@property (nullable, nonatomic, strong) UIImage *image;
@property (nullable, nonatomic, strong) UIImage *selectedImage;
@property (nullable, nonatomic, strong) UIViewController *childViewController;
// default is nil, badgeValue为nil并且badgeSize为CGSizeZero时，badge隐藏
@property (nullable, nonatomic, copy) NSString *badgeValue;
@property (nonatomic, readwrite, copy, nullable) UIColor *badgeColor;

@property (nullable, nonatomic, weak, getter=cylflatdesign_tabBarController, setter=cylflatdesign_setTabBarController:) UIViewController __kindof *cylflatdesign_tabBarController;

@property (nonatomic, readwrite, assign) UIOffset titlePositionAdjustment UI_APPEARANCE_SELECTOR;

/*!
 * [EN] Sets the title text attributes for `state` (like UITabBarItem).
 * [CN] 设置指定状态下的标题文字属性（同 UITabBarItem）。
 */
- (void)setTitleTextAttributes:(nullable NSDictionary<NSAttributedStringKey,id> *)attributes forState:(UIControlState)state UI_APPEARANCE_SELECTOR;

/*!
 * [EN] Returns the title text attributes for `state`.
 * [CN] 返回指定状态下的标题文字属性。
 */
- (nullable NSDictionary<NSAttributedStringKey,id> *)titleTextAttributesForState:(UIControlState)state;

/*!
 * [EN] Sets the badge text attributes for `state`.
 * [CN] 设置指定状态下的角标文字属性。
 */
- (void)setBadgeTextAttributes:(nullable NSDictionary<NSAttributedStringKey,id> *)textAttributes forState:(UIControlState)state UI_APPEARANCE_SELECTOR;

/*!
 * [EN] Returns the badge text attributes for `state`.
 * [CN] 返回指定状态下的角标文字属性。
 */
- (nullable NSDictionary<NSAttributedStringKey,id> *)badgeTextAttributesForState:(UIControlState)state;

#pragma mark - CYLFlatDesignTabBarItem 新增属性
// 若设置badgeSize为CGSizeZero，则badge自动计算大小，默认为CGSizeZero
@property (nonatomic, readwrite, assign) CGSize badgeSize;
// default {1, 6, 1, 6}
@property (nonatomic, readwrite, assign) UIEdgeInsets badgeContentInset UI_APPEARANCE_SELECTOR;
@property (nonatomic, readwrite, assign) UIOffset badgePositionAdjustment UI_APPEARANCE_SELECTOR;
@property (nonatomic, readwrite, assign) UIOffset imagePositionAdjustment UI_APPEARANCE_SELECTOR;

/*
 没有image时，title是否居中显示
 或没有title时，image是否居中显示，默认为NO
 */
@property (nonatomic, readwrite, assign) BOOL layoutCentered UI_APPEARANCE_SELECTOR;

@property (nullable, nonatomic, strong) UIColor *backgroundColor;
@property (nullable, nonatomic, strong) UIColor *selectedBackgroundColor;

@property (nonatomic, assign) UIEdgeInsets imageInsets;

@property (nonatomic, strong) NSURL *lottieURL;

@property (nonatomic, copy) NSString *lottieFilePath;

@property (nonatomic, strong) NSValue *lottieSizeValue;

/*!
 * [EN] Returns the view that hosts this item's badge (from its tab bar button).
 * [CN] 返回承载该 Item 角标的视图（取自其 TabBar 按钮）。
 */
- (UIView *)actualBadgeSuperView;

@end

NS_ASSUME_NONNULL_END
