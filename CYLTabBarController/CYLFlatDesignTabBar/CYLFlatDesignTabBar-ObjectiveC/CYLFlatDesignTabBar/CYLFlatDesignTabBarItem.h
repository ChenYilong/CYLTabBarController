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

- (instancetype)initWithTitle:(nullable NSString *)title
                        image:(nullable UIImage *)image;

- (instancetype)initWithTitle:(nullable NSString *)title
                        image:(nullable UIImage *)image
                selectedImage:(nullable UIImage *)selectedImage;

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

- (void)setTitleTextAttributes:(nullable NSDictionary<NSAttributedStringKey,id> *)attributes forState:(UIControlState)state UI_APPEARANCE_SELECTOR;
- (nullable NSDictionary<NSAttributedStringKey,id> *)titleTextAttributesForState:(UIControlState)state;

- (void)setBadgeTextAttributes:(nullable NSDictionary<NSAttributedStringKey,id> *)textAttributes forState:(UIControlState)state UI_APPEARANCE_SELECTOR;
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
- (UIView *)actualBadgeSuperView;

@end

NS_ASSUME_NONNULL_END
