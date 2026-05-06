//
//  CYLTabBar.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLBaseView.h"
#import "CYLTabBar.h"

@class CYLFlatDesignTabBar;
@class CYLFlatDesignTabBarItem;

@protocol CYLFlatDesignTabBarDelegate <NSObject>
- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItemAt:(NSInteger)index;
@end

@interface CYLFlatDesignTabBar : UITabBar

@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, assign) NSInteger defaultSelectedIndex;

@property (nonatomic, weak) id<CYLFlatDesignTabBarDelegate> wlDelegate;
@property (nonatomic, copy) NSString *context;

@property (nonatomic, strong) NSMutableArray<CYLFlatDesignTabBarItem *> *tabBarItems;
- (CYLFlatDesignTabBarItem *)addItemWithTitle:(NSString *)title
                              tabBarItemImage:(id)tabBarItemImage
                      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                                        index:(NSInteger)index
                      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                  imageInsets:(UIEdgeInsets)imageInsets
                               lottieFilePath:(NSString *)lottieFilePath
                              lottieSizeValue:(NSValue *)lottieSizeValue;
@property (nonatomic, weak) UIView *plusSuperView;
@property (nonatomic, weak) UIButton<CYLPlusButtonSubclassing> *plusView;
@property (nonatomic, assign, readonly) BOOL isAnimating;
@property (nonatomic, assign, readonly) BOOL plusing;
- (void)showPlus:(BOOL)isAnimated;
- (void)closePlus:(BOOL)isAnimated;

@end

@interface CYLFlatDesignTabBarItem : CYLBaseView

@property (nonatomic, weak) UIStackView *stackView;

@property (nonatomic, weak) UIImageView *imageView;

@property (nonatomic, strong) UIImage *tabBarItemImage;
@property (nonatomic, strong) UIImage *tabBarItemSelectedImage;
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, assign) UIOffset titlePositionAdjustment;
@property (nonatomic, assign) UIEdgeInsets imageInsets;
//@property (nonatomic, strong) NSURL *lottieURL;
@property (nonatomic, copy) NSString *lottieFilePath;

@property (nonatomic, strong) NSValue *lottieSizeValue;

- (instancetype)initWithFrame:(CGRect)frame
                        title:(NSString *)title
              tabBarItemImage:(id)tabBarItemImage
      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                        index:(NSInteger)index
      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                  imageInsets:(UIEdgeInsets)imageInsets
               lottieFilePath:(NSString *)lottieFilePath
              lottieSizeValue:(NSValue *)lottieSizeValue;

@property (nonatomic, weak, readonly) UIViewController *childVC;
@property (nonatomic, assign, readonly) NSInteger *index;

@property (nonatomic, assign) BOOL isSelected;
- (void)setIsSelected:(BOOL)isSelected animated:(BOOL)animated;

@property (nonatomic, assign) BOOL isHasBadge;
- (void)setIsHasBadge:(BOOL)isHasBadge animated:(BOOL)animated;
- (UIView *)actualBadgeSuperView;

@end
