//
//  CYLTabBar.h
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLBaseView.h"
@class CYLPureCustomTabBar;
@class CYLPureCustomTabBarItem;

@protocol CYLPureCustomTabBarDelegate <NSObject>
- (void)tabBar:(CYLPureCustomTabBar *)tabBar didSelectItemAt:(NSInteger)index;
@end

@interface CYLPureCustomTabBar : UITabBar // 方案一
//@interface CYLPureCustomTabBar : UIView // 方案二

@property (nonatomic, assign) NSInteger selectedIndex;
@property (nonatomic, weak) id<CYLPureCustomTabBarDelegate> wlDelegate;

@property (nonatomic, strong) NSMutableArray<CYLPureCustomTabBarItem *> *tabBarItems;
- (void)addItemWithTitle:(NSString *)title
              normalIcon:(NSString *)normalIcon
              selectIcon:(NSString *)selectIcon
                   index:(NSInteger)index;

@property (nonatomic, weak) UIView *plusSuperView;
@property (nonatomic, weak) CYLBaseView *plusView;
@property (nonatomic, assign, readonly) BOOL isAnimating;
@property (nonatomic, assign, readonly) BOOL plusing;
- (void)showPlus:(BOOL)isAnimated;
- (void)closePlus:(BOOL)isAnimated;

@property (nonatomic, weak) CYLBaseView *mobileView;
@property (nonatomic, weak) CYLBaseView *equipmentView;
@property (nonatomic, weak) CYLBaseView *vrEquipmentView;
@end

@interface CYLPureCustomTabBarItem : CYLBaseView

- (instancetype)initWithFrame:(CGRect)frame
                        title:(NSString *)title
                        index:(NSInteger)index
                   normalIcon:(NSString *)normalIcon
                   selectIcon:(NSString *)selectIcon;

@property (nonatomic, weak, readonly) UIViewController *childVC;
@property (nonatomic, assign, readonly) NSInteger *index;

@property (nonatomic, assign) BOOL isSelected;
- (void)setIsSelected:(BOOL)isSelected animated:(BOOL)animated;

@property (nonatomic, assign) BOOL isHasBadge;
- (void)setIsHasBadge:(BOOL)isHasBadge animated:(BOOL)animated;

@end
