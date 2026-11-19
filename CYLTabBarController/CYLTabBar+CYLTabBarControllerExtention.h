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
- (nullable NSArray<UIControl *> *)cyl_platterSelectedContentViews;

/*!
 * [EN] Returns the floating selected content view provided by the tab bar visual provider (Liquid Glass).
 * [CN] 返回 TabBar VisualProvider 提供的悬浮选中内容视图（液态玻璃）。
 */
- (nullable UIView *)cyl_platterVisualProviderFloatingSelectedContentView;

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
- (nullable UIView *)cyl_platterLiquidLensView;

/*!
 * [EN] Returns the subviews of the lens content view, or nil if there is no content view.
 * [CN] 返回 LiquidLens 内容视图的子视图，没有内容视图时返回 nil。
 */
- (nullable NSArray<UIView *> *)cyl_platterLiquidLensViewSubViews;

/*!
 * [EN] Returns the lens content view: the portal's `sourceView`, or the first subview of the lens view.
 * [CN] 返回 LiquidLens 内容视图：优先取 Portal 的 sourceView，否则取 LiquidLens 的第一个子视图。
 */
- (nullable UIView *)cyl_platterLiquidLensViewContentView;

/*!
 * [EN] Returns the visible `DestOutView` inside the platter, or nil.
 * [CN] 返回 Platter 中可见的 DestOutView，没有则返回 nil。
 */
- (nullable UIView *)cyl_platterDestOutView;

/*!
 * [EN] Returns the view that hosts tab content: the platter view under Liquid Glass, otherwise the tab bar itself.
 * [CN] 返回承载 Tab 内容的视图：液态玻璃下为 Platter 视图，否则为 TabBar 自身。
 */
- (UIView *)cyl_contentView;

/*!
 * [EN] Returns the clear-glass layer of the Liquid Glass lens.
 * [CN] 返回液态玻璃 LiquidLens 的透明玻璃层视图。
 */
- (nullable UIView *)cyl_platterLiquidLensClearGlassView;

/*!
 * [EN] Returns the platter's selected content view container, or nil.
 * [CN] 返回 Platter 中的选中态内容容器视图，没有则返回 nil。
 */
- (nullable UIView *)cyl_platterSelectedContentView;

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

/*!
 * [EN] The `CYLTabBar (CYLTabBarControllerExtention)` members (`cyl_selectedControl`, `-cyl_selectedIndex`, `-cyl_visibleControls`,
 *      `-cyl_subTabBarButtons`, `-cyl_tabBarButtonWithTabIndex:` and the others) are implemented in Swift
 *      (`Swift/CYLTabBar+CYLTabBarControllerExtention.swift`); since `CYLTabBar` itself is Swift (step 100), Objective-C callers get
 *      them from the generated Swift interface (imported by `CYLTabBar.h`), as a category of a Swift class cannot be declared here.
 * [CN] `CYLTabBar (CYLTabBarControllerExtention)` 的成员在 Swift 中实现（`Swift/CYLTabBar+CYLTabBarControllerExtention.swift`）；由于 `CYLTabBar`
 *      本身已是 Swift（第 100 步），Objective-C 调用方从生成的 Swift 接口（由 `CYLTabBar.h` 导入）获得它们，因为这里不能为 Swift 类声明类别。
 */

NS_ASSUME_NONNULL_END
