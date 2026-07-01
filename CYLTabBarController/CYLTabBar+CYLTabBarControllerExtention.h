/*
 //  CYLTabBarController
 //  CYLTabBarController
 //
 //  Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 03/06/19.
 //  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
 */

#import <UIKit/UIKit.h>
#import "CYLTabBar.h"

NS_ASSUME_NONNULL_BEGIN
@interface UITabBar (CYLTabBarControllerExtention)

- (CGFloat)cyl_fullHeight;
- (CGSize)cyl_boundsSize;
- (CGFloat)cyl_boundsWidthOffset;

- (NSArray *)cyl_platterViews;
- (UIView *)cyl_platterViewWithIndex:(NSInteger)index;
- (NSArray<UIControl *> *)cyl_platterContentViews;
- (UIControl *)cyl_platterContentViewWithIndex:(NSInteger)index;
- (NSArray<UIControl *> *)cyl_platterSelectedContentViews;
- (UIView *)cyl_platterVisualProviderFloatingSelectedContentView;
- (UIControl *)cyl_platterSelectedContentViewWithIndex:(NSInteger)index;
- (UIControl *)cyl_platterSelectedContentViewWithoutPlusButttonWithIndex:(NSInteger)index;

- (NSArray *)cyl_platterPortalViews;
- (UIView *)cyl_platterPortalViewWithIndex:(NSInteger)index;
- (UIView *)cyl_platterLiquidLensView;
- (NSArray<UIView *> *)cyl_platterLiquidLensViewSubViews;
- (UIView *)cyl_platterLiquidLensViewContentView;

- (UIView *)cyl_platterDestOutView;
- (UIView *)cyl_contentView;
- (UIView *)cyl_platterLiquidLensClearGlassView;
- (UIView *)cyl_platterSelectedContentView;

@property (nonatomic, weak, getter=cyl_platterView, setter=cyl_setPlatterView:) UIView *cyl_platterView;
@property (nonatomic, weak, getter=cyl_portalView, setter=cyl_setPortalView:) UIView *cyl_portalView;
@property (nonatomic, weak, getter=cyl_platterContentView, setter=cyl_setPlatterContentView:) UIView *cyl_platterContentView;

@property (nonatomic, assign, getter=cyl_platterViewWidth, setter=cyl_setPlatterViewWidth:) CGFloat cyl_platterViewWidth;
@property (nonatomic, strong, getter=cyl_platterViewSize, setter=cyl_setPlatterViewSize:) NSValue *cyl_platterViewSize;
@property (nonatomic, weak, getter=cyl_portalLayer, setter=cyl_setPortalLayer:) CALayer *cyl_portalLayer;
- (NSArray<UIControl *> *)cyl_platterSelectedContentViewsWithoutPlusButton;
/*!
 * cyl_tabBarSubviews 为未经过滤后的结果，可理解为original
 */
- (NSArray<UIControl *> *)cyl_tabBarSubviews;
@end

@interface CYLTabBar (CYLTabBarControllerExtention)


@property (nonatomic, strong, getter=cyl_context, setter=cyl_setContext:) NSString *cyl_context;
@property (nonatomic, strong, getter=cyl_selectedControl, setter=cyl_setSelectedControl:) UIControl *cyl_selectedControl;

- (UIControl *)cyl_selectedControl;
- (NSInteger)cyl_selectedIndex;
- (NSArray<UIControl *> *)cyl_visibleControls;
/*!
 * cyl_tabBarSubviews 的过滤后的结果， sub表示过滤， 可理解为filtered，子集合。
 */
- (NSArray<UIControl *> *)cyl_subTabBarButtons;
- (NSArray<UIControl *> *)cyl_subTabBarButtonsWithoutPlusButton;
- (UIControl *)cyl_tabBarButtonWithTabIndex:(NSUInteger)tabIndex;
- (UIControl *)cyl_normalContentControlFromSelectedContentControl:(UIControl *)selectedContentControl;
- (UIControl *)cyl_selectedContentControlFromContentControl:(UIControl *)contentControl;
- (void)cyl_animationLottieImageWithSelectedControl:(UIControl *)selectedControl
                                          lottieURL:(NSURL *)lottieURL
                                               size:(CGSize)size
                                          defaultSelected:(BOOL)defaultSelected
                                        contentMode:(UIViewContentMode)contentMode;

- (void)cyl_stopAnimationOfAllLottieView;

/*!
 *  原生 TabButton 数量，不包含PlusButton。
 */
- (NSArray *)cyl_originalTabBarButtons;
- (BOOL)cyl_hasPlusChildViewController;
- (CGFloat)cyl_cachedXOffsetWithIndex:(CGFloat)index;
- (CGFloat)cyl_cachedWidthOffsetWithIndex:(CGFloat)index;


@end

NS_ASSUME_NONNULL_END
