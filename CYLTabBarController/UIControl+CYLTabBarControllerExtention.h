//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.21.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2018 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
@class LOTAnimationView;
@interface UIControl (CYLTabBarControllerExtention)

- (UIView *)cyl_tabBadgeView;
- (UIImageView *)cyl_tabImageView;
- (UILabel *)cyl_tabLabel;
- (LOTAnimationView *)cyl_lottieAnimationView;
- (BOOL)cyl_isChildViewControllerPlusButton;

/*!
 * 调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 */
- (void)cyl_showTabBadgePoint;
- (void)cyl_removeTabBadgePoint;
- (BOOL)cyl_isShowTabBadgePoint;
- (BOOL)cyl_isSelected;
@property (nonatomic, strong, setter=cyl_setTabBadgePointView:, getter=cyl_tabBadgePointView) UIView *cyl_tabBadgePointView;
@property (nonatomic, assign, setter=cyl_setTabBadgePointViewOffset:, getter=cyl_tabBadgePointViewOffset) UIOffset cyl_tabBadgePointViewOffset;
/*!
 * PlusButton without plusViewController equals NSNotFound
 */
@property (nonatomic, assign, getter=cyl_tabBarChildViewControllerIndex, setter=cyl_setTabBarChildViewControllerIndex:) NSInteger cyl_tabBarChildViewControllerIndex;

/*!
 * PlusButton has its own visible index,
 * in this case PlusButton is same as TabBarItem
 */
@property (nonatomic, assign, getter=cyl_tabBarItemVisibleIndex, setter=cyl_setTabBarItemVisibleIndex:) NSInteger cyl_tabBarItemVisibleIndex;

@property (nonatomic, assign, getter=cyl_shouldNotSelect, setter=cyl_setShouldNotSelect:) BOOL cyl_shouldNotSelect;

- (void)cyl_addLottieImageWithLottieURL:(NSURL *)lottieURL
                                   size:(CGSize)size;

- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                             show:(BOOL)show;

- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                           offset:(UIOffset)offset
                                    show:(BOOL)show
                                       completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                   show:(BOOL)show;

- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                 offset:(UIOffset)offset
                                   show:(BOOL)theShow
                             completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

@end

NS_ASSUME_NONNULL_END
