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

/*!
 * [EN] Returns the full tab bar height, including the bottom safe area.
 * [CN] 返回 TabBar 的完整高度（包含底部安全区）。
 */
- (CGFloat)cyl_fullHeight;

/*!
 * [EN] Returns the usable tab bar size: bounds minus the bottom safe area, or the platter size under Liquid Glass.
 * [CN] 返回 TabBar 的可用尺寸：非液态玻璃时为去掉底部安全区后的 bounds，液态玻璃下为 Platter 的尺寸。
 */
- (CGSize)cyl_boundsSize;

/*!
 * [EN] Returns half of the width difference between the screen and the tab bar content under Liquid Glass; 0 otherwise.
 * [CN] 液态玻璃下返回屏幕宽度与 TabBar 内容宽度差值的一半，否则返回 0。
 */
- (CGFloat)cyl_boundsWidthOffset;

/*!
 * [EN] Returns YES if the tab bar lays out right-to-left (e.g. Arabic, Hebrew), based on its `semanticContentAttribute`.
 * [CN] 判断 TabBar 是否为从右到左布局（如阿拉伯语、希伯来语），依据 `semanticContentAttribute` 判断。
 */
- (BOOL)cyl_isRightToLeftLayout;

/*!
 * [EN] Returns the Liquid Glass platter views. Currently a placeholder that returns an empty array.
 * [CN] 返回液态玻璃 Platter 视图数组。当前为占位实现，返回空数组。
 */
- (NSArray *)cyl_platterViews;

/*!
 * [EN] Returns the platter view at `index`, or nil if out of range.
 * [CN] 返回指定索引的 Platter 视图，越界时返回 nil。
 */
- (UIView *)cyl_platterViewWithIndex:(NSInteger)index;

/*!
 * [EN] Returns the platter content views (normal-state tab buttons), i.e. the unfiltered `cyl_tabBarSubviews`.
 * [CN] 返回 Platter 内容视图（常态 Tab 按钮），即未过滤的 cyl_tabBarSubviews。
 */
- (NSArray<UIControl *> *)cyl_platterContentViews;

/*!
 * [EN] Returns the platter content view at `index`, or nil if out of range.
 * [CN] 返回指定索引的 Platter 内容视图，越界时返回 nil。
 */
- (UIControl *)cyl_platterContentViewWithIndex:(NSInteger)index;

/*!
 * [EN] Returns the platter selected content views (selected-state tab buttons).
 * [CN] 返回 Platter 选中态内容视图数组（选中态 Tab 按钮）。
 */
- (NSArray<UIControl *> *)cyl_platterSelectedContentViews;

/*!
 * [EN] Returns the floating selected content view provided by the tab bar visual provider (Liquid Glass).
 * [CN] 返回 TabBar VisualProvider 提供的悬浮选中内容视图（液态玻璃）。
 */
- (UIView *)cyl_platterVisualProviderFloatingSelectedContentView;

/*!
 * [EN] Returns the platter selected content view at `index`, or nil if out of range.
 * [CN] 返回指定索引的 Platter 选中态内容视图，越界时返回 nil。
 */
- (UIControl *)cyl_platterSelectedContentViewWithIndex:(NSInteger)index;

/*!
 * [EN] Returns the platter selected content view at `index`, counting without the plus button; nil if out of range.
 * [CN] 返回不计 PlusButton 时指定索引的 Platter 选中态内容视图，越界时返回 nil。
 */
- (UIControl *)cyl_platterSelectedContentViewWithoutPlusButttonWithIndex:(NSInteger)index;

/*!
 * [EN] Returns the Liquid Glass portal views. Currently a placeholder that returns an empty array.
 * [CN] 返回液态玻璃 Portal 视图数组。当前为占位实现，返回空数组。
 */
- (NSArray *)cyl_platterPortalViews;

/*!
 * [EN] Returns the portal view at `index`, or nil if out of range.
 * [CN] 返回指定索引的 Portal 视图，越界时返回 nil。
 */
- (UIView *)cyl_platterPortalViewWithIndex:(NSInteger)index;

/*!
 * [EN] Returns the Liquid Glass lens view (the moving selection bubble) inside the platter.
 * [CN] 返回 Platter 中的液态玻璃 LiquidLens 视图（随选中项移动的玻璃气泡）。
 */
- (UIView *)cyl_platterLiquidLensView;

/*!
 * [EN] Returns the subviews of the lens content view, or nil if there is no content view.
 * [CN] 返回 LiquidLens 内容视图的子视图，没有内容视图时返回 nil。
 */
- (NSArray<UIView *> *)cyl_platterLiquidLensViewSubViews;

/*!
 * [EN] Returns the lens content view: the portal's `sourceView`, or the first subview of the lens view.
 * [CN] 返回 LiquidLens 内容视图：优先取 Portal 的 sourceView，否则取 LiquidLens 的第一个子视图。
 */
- (UIView *)cyl_platterLiquidLensViewContentView;

/*!
 * [EN] Returns the visible `DestOutView` inside the platter, or nil.
 * [CN] 返回 Platter 中可见的 DestOutView，没有则返回 nil。
 */
- (UIView *)cyl_platterDestOutView;

/*!
 * [EN] Returns the view that hosts tab content: the platter view under Liquid Glass, otherwise the tab bar itself.
 * [CN] 返回承载 Tab 内容的视图：液态玻璃下为 Platter 视图，否则为 TabBar 自身。
 */
- (UIView *)cyl_contentView;

/*!
 * [EN] Returns the clear-glass layer of the Liquid Glass lens.
 * [CN] 返回液态玻璃 LiquidLens 的透明玻璃层视图。
 */
- (UIView *)cyl_platterLiquidLensClearGlassView;

/*!
 * [EN] Returns the platter's selected content view container, or nil.
 * [CN] 返回 Platter 中的选中态内容容器视图，没有则返回 nil。
 */
- (UIView *)cyl_platterSelectedContentView;

@property (nonatomic, weak, getter=cyl_platterView, setter=cyl_setPlatterView:) UIView *cyl_platterView;
@property (nonatomic, weak, getter=cyl_portalView, setter=cyl_setPortalView:) UIView *cyl_portalView;
@property (nonatomic, weak, getter=cyl_platterContentView, setter=cyl_setPlatterContentView:) UIView *cyl_platterContentView;
@property (nonatomic, assign, getter=cyl_platterViewWidth, setter=cyl_setPlatterViewWidth:) CGFloat cyl_platterViewWidth;
@property (nonatomic, strong, getter=cyl_platterViewSize, setter=cyl_setPlatterViewSize:) NSValue *cyl_platterViewSize;
@property (nonatomic, weak, getter=cyl_portalLayer, setter=cyl_setPortalLayer:) CALayer *cyl_portalLayer;

/*!
 * [EN] Returns the platter selected content views excluding the plus button.
 * [CN] 返回剔除 PlusButton 后的 Platter 选中态内容视图数组。
 */
- (NSArray<UIControl *> *)cyl_platterSelectedContentViewsWithoutPlusButton;
/*!
 * cyl_tabBarSubviews 为未经过滤后的结果，可理解为original
 * [EN] Returns the tab bar button subviews, unfiltered.
 * [CN] 返回未经过滤的 TabBar 按钮子视图数组。
 */
- (NSArray<UIControl *> *)cyl_tabBarSubviews;
@end

@interface CYLTabBar (CYLTabBarControllerExtention)


@property (nonatomic, strong, getter=cyl_selectedControl, setter=cyl_setSelectedControl:) UIControl *cyl_selectedControl;

/*!
 * [EN] Returns the currently selected control.
 * [CN] 返回当前选中的控件。
 */
- (UIControl *)cyl_selectedControl;

/*!
 * [EN] Returns the visible index of the selected control.
 * [CN] 返回当前选中控件的可见索引。
 */
- (NSInteger)cyl_selectedIndex;

/*!
 * [EN] Returns the visible tab controls, including the plus button when the tab bar has one.
 * [CN] 返回可见的 Tab 控件数组；TabBar 含 PlusButton 时也包含 PlusButton。
 */
- (NSArray<UIControl *> *)cyl_visibleControls;
/*!
 * cyl_tabBarSubviews 的过滤后的结果， sub表示过滤， 可理解为filtered，子集合。
 * [EN] Returns the filtered tab bar buttons (a subset of `cyl_tabBarSubviews`).
 * [CN] 返回过滤后的 TabBar 按钮数组（cyl_tabBarSubviews 的子集）。
 */
- (NSArray<UIControl *> *)cyl_subTabBarButtons;

/*!
 * [EN] Returns the filtered tab bar buttons excluding the plus button.
 * [CN] 返回过滤后且剔除 PlusButton 的 TabBar 按钮数组。
 */
- (NSArray<UIControl *> *)cyl_subTabBarButtonsWithoutPlusButton;

/*!
 * [EN] Returns the tab bar button for `tabIndex`, accounting for whether the plus button has a child view controller.
 * [CN] 返回 tabIndex 对应的 TabBar 按钮，会考虑 PlusButton 是否添加了子控制器。
 */
- (UIControl *)cyl_tabBarButtonWithTabIndex:(NSUInteger)tabIndex;

/*!
 * [EN] Returns the normal-state content control that matches the given selected-state content control.
 * [CN] 根据选中态内容控件，返回与之对应的常态内容控件。
 */
- (UIControl *)cyl_normalContentControlFromSelectedContentControl:(UIControl *)selectedContentControl;

/*!
 * [EN] Returns the selected-state content control that matches the given normal-state content control.
 * [CN] 根据常态内容控件，返回与之对应的选中态内容控件。
 */
- (UIControl *)cyl_selectedContentControlFromContentControl:(UIControl *)contentControl;

/*!
 * [EN] Plays the Lottie animation on `selectedControl`; shows the final frame without playing when `defaultSelected` is YES.
 * [CN] 在 selectedControl 上播放 Lottie 动画；defaultSelected 为 YES 时直接显示最后一帧而不播放。
 */
- (void)cyl_animationLottieImageWithSelectedControl:(UIControl *)selectedControl
                                          lottieURL:(NSURL *)lottieURL
                                               size:(CGSize)size
                                          defaultSelected:(BOOL)defaultSelected
                                        contentMode:(UIViewContentMode)contentMode;

/*!
 * [EN] Stops the Lottie animations on all visible and selected-state controls.
 * [CN] 停止所有可见控件与选中态控件上的 Lottie 动画。
 */
- (void)cyl_stopAnimationOfAllLottieView;

/*!
 *  原生 TabButton 数量，不包含PlusButton。
 * [EN] Returns the native tab bar buttons, excluding the plus button.
 * [CN] 返回原生 TabBar 按钮数组，不含 PlusButton。
 */
- (NSArray *)cyl_originalTabBarButtons;

/*!
 * [EN] Returns YES if the plus button's child view controller is added to this tab bar's controller in the same context.
 * [CN] 判断 PlusButton 的子控制器是否已添加到同一 context 的 TabBarController 中。
 */
- (BOOL)cyl_hasPlusChildViewController;

/*!
 * [EN] Returns the cached x offset for the item at `index` under Liquid Glass (sign depends on the plus button side); 0 otherwise.
 * [CN] 液态玻璃下返回指定索引按钮的 x 偏移缓存值（正负取决于位于 PlusButton 哪一侧），否则返回 0。
 */
- (CGFloat)cyl_cachedXOffsetWithIndex:(CGFloat)index;

/*!
 * [EN] Returns the width difference between the original and visible item width under Liquid Glass; 0 otherwise.
 * [CN] 液态玻璃下返回原始按钮宽度与可见按钮宽度的差值，否则返回 0。
 */
- (CGFloat)cyl_cachedWidthOffsetWithIndex:(CGFloat)index;

/*!
 * [EN] Returns YES if the plus button's title label visibility needs updating (Liquid Glass only).
 * [CN] 判断是否需要更新 PlusButton 标题 Label 的隐藏状态（仅液态玻璃下生效）。
 */
- (BOOL)cyl_shouldUpdateHiddenStatueForPlusButtonLabel;

@end

NS_ASSUME_NONNULL_END
