//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CYLConstants.h"

NS_ASSUME_NONNULL_BEGIN

@interface UIView (CYLTabBarControllerExtention)

/*!
 * [EN] Returns YES if the receiver is the plus button (CYLPlusButton).
 * [CN] 判断当前视图是否为中间凸起的 PlusButton。
 */
- (BOOL)cyl_isPlusButton;

/*!
 * [EN] Returns YES if the receiver lays out right-to-left (e.g. Arabic, Hebrew), based on `effectiveUserInterfaceLayoutDirection`.
 * [CN] 判断当前视图是否为从右到左布局（如阿拉伯语、希伯来语），依据 `effectiveUserInterfaceLayoutDirection` 判断。
 */
- (BOOL)cyl_isRightToLeftLayout;

/*!
 * [EN] Returns YES if the receiver is a system tab bar button (UITabBarButton).
 * [CN] 判断当前视图是否为系统 TabBar 按钮（UITabBarButton）。
 */
- (BOOL)cyl_isTabButton;

/*!
 * [EN] Returns YES if the receiver is the iOS 26 Liquid Glass platter view that hosts the tab items.
 * [CN] 判断当前视图是否为 iOS 26 液态玻璃下承载 TabBar 按钮的 Platter 视图。
 */
- (BOOL)cyl_isPlatterView;

/*!
 * [EN] Returns YES if the receiver is the platter's content view (normal-state tab content).
 * [CN] 判断当前视图是否为 Platter 的内容视图（常态下的 Tab 内容）。
 */
- (BOOL)cyl_isPlatterContentView;

/*!
 * [EN] Returns YES if the receiver is the platter's selected content view (selected-state tab content).
 * [CN] 判断当前视图是否为 Platter 的选中态内容视图。
 */
- (BOOL)cyl_isPlatterSelectedContentView;

/*!
 * [EN] Returns YES if the receiver is a Liquid Glass portal view; always NO when Liquid Glass is inactive.
 * [CN] 判断当前视图是否为液态玻璃的 Portal 视图；未启用液态玻璃时始终返回 NO。
 */
- (BOOL)cyl_isPlatterPortalView;

/*!
 * [EN] Returns YES if the receiver is the Liquid Glass lens view (the moving selection bubble).
 * [CN] 判断当前视图是否为液态玻璃的 LiquidLens 视图（随选中项移动的玻璃气泡）。
 */
- (BOOL)cyl_isPlatterLiquidLensView;

/*!
 * [EN] Returns YES if the receiver is a visible Liquid Glass `DestOutView`; always NO when Liquid Glass is inactive.
 * [CN] 判断当前视图是否为可见的液态玻璃 DestOutView；未启用液态玻璃时始终返回 NO。
 */
- (BOOL)cyl_isPlatterDestOutView;

/*!
 * [EN] Returns YES if the receiver is the clear-glass layer of the Liquid Glass lens view.
 * [CN] 判断当前视图是否为液态玻璃 LiquidLens 的透明玻璃层。
 */
- (BOOL) cyl_isPlatterLiquidLensClearGlassView;

/*!
 * [EN] Returns YES if the receiver is the tab selection view inside the Liquid Glass lens.
 * [CN] 判断当前视图是否为液态玻璃 LiquidLens 中的 Tab 选中视图。
 */
- (BOOL) cyl_isPlatterLiquidLensTabSelectionView;

/*!
 * [EN] Returns YES if the receiver is the backdrop view of the Liquid Glass lens.
 * [CN] 判断当前视图是否为液态玻璃 LiquidLens 的背景（Backdrop）视图。
 */
- (BOOL) cyl_isPlatterLiquidLensBackdropView;

/*!
 * [EN] Returns YES if the receiver is a visible floating selected content view of the tab bar visual provider (Liquid Glass only).
 * [CN] 判断当前视图是否为 TabBar VisualProvider 中可见的悬浮选中内容视图（仅液态玻璃下生效）。
 */
- (BOOL)cyl_isPlatterVisualProviderFloatingSelectedContentView;

/*!
 * [EN] Returns the first UIImageView among the receiver's direct subviews, or nil.
 * [CN] 返回当前视图直接子视图中的第一个 UIImageView，没有则返回 nil。
 */
- (UIImageView *)cyl_imageView;

/*!
 * [EN] Returns YES if the receiver is the image view inside a tab bar button.
 * [CN] 判断当前视图是否为 TabBar 按钮内部的图片视图。
 */
- (BOOL)cyl_isTabImageView;

/*!
 * [EN] Returns YES if the receiver is the title label inside a tab bar button.
 * [CN] 判断当前视图是否为 TabBar 按钮内部的标题 Label。
 */
- (BOOL)cyl_isTabLabel;

/*!
 * UIBarButtonContentView.titleLabel;
 * [EN] Returns YES if the receiver is the title label of a bar button content view.
 * [CN] 判断当前视图是否为 BarButton 内容视图的标题 Label。
 */
- (BOOL)cyl_isButtonLabel;

/*!
 * [EN] Returns YES if the receiver is the system badge view of a tab bar button.
 * [CN] 判断当前视图是否为 TabBar 按钮上的系统角标视图。
 */
- (BOOL)cyl_isTabBadgeView;

/*!
 * [EN] Returns the system badge view among the receiver's subviews, or nil.
 * [CN] 返回子视图中的系统角标视图，没有则返回 nil。
 */
- (UIView *)cyl_tabBadgeView;

/*!
 * [EN] Returns YES if the receiver is the tab bar's private background view (`_UIBarBackground`).
 * [CN] 判断当前视图是否为 TabBar 的私有背景视图（_UIBarBackground）。
 */
- (BOOL)cyl_isTabBackgroundView;

/*!
 * [EN] Returns the image view of the tab bar button.
 * [CN] 返回 TabBar 按钮的图片视图。
 */
- (UIImageView *)cyl_tabImageView;

/*!
 * [EN] Returns the title label of the tab bar button.
 * [CN] 返回 TabBar 按钮的标题 Label。
 */
- (UILabel *)cyl_tabLabel;

/*!
 * [EN] Returns the shadow (top separator line) image view of the tab bar background.
 * [CN] 返回 TabBar 背景中的阴影（顶部分割线）图片视图。
 */
- (UIImageView *)cyl_tabShadowImageView;

/*!
 * [EN] Returns the first blur effect view among the receiver's subviews, or nil.
 * [CN] 返回子视图中的第一个毛玻璃效果视图，没有则返回 nil。
 */
- (UIVisualEffectView *)cyl_tabEffectView;

/*!
 * [EN] Returns YES if the receiver is a Lottie animation view.
 * [CN] 判断当前视图是否为 Lottie 动画视图。
 */
- (BOOL)cyl_isLottieAnimationView;

/*!
 * [EN] Returns the tab bar's background view.
 * [CN] 返回 TabBar 的背景视图。
 */
- (UIView *)cyl_tabBackgroundView;

/*!
 * [EN] Returns the receiver and all of its descendants, flattened recursively.
 * [CN] 递归返回当前视图及其所有后代视图组成的扁平数组。
 */
- (NSArray *)cyl_allSubviews;

/*!
 * [EN] Returns the image view inside the tab bar button, trying KVC first and then the subviews.
 * [CN] 返回 TabBar 按钮内的图片视图，优先通过 KVC 获取，失败再遍历子视图。
 */
- (UIImageView *)cyl_imageViewInTabBarButton;

/*!
 * [EN] Brings `view` to the front, but keeps it below the Liquid Glass platter view when one exists.
 * [CN] 将 view 置于前面；若存在液态玻璃 Platter 视图，则插入到 Platter 之下。
 */
- (void)cyl_bringSubviewToFront:(UIView *)view;

/*!
 * [EN] Adds `view` as a subview, brings it to the front, and sets its layer zPosition to MAXFLOAT so it stays on top.
 * [CN] 添加 view 为子视图并置顶，同时将 layer.zPosition 设为 MAXFLOAT，确保始终在最上层。
 */
- (void)cyl_bringSubviewToTop:(UIView *)view;

/**
 使用 cyl_isViewAddedToPlatterView判断是否添加view成功
 * [EN] Adds `view` to the Liquid Glass platter view (or to the receiver when there is none), then brings it to the front.
 * [CN] 将 view 添加到液态玻璃 Platter 视图上（没有 Platter 时添加到自身），然后置于前面。
 **/
- (void)cyl_addPlatterViewThenBringSubviewToFront:(UIView *)view;

/*!
 * [EN] Returns YES if `view` was added to the platter content view (or to the receiver when there is no platter).
 * [CN] 判断 view 是否已添加到 Platter 内容视图上（没有 Platter 时判断是否添加到自身）。
 */
- (BOOL)cyl_isViewAddedToPlatterView:(UIView *)view;

/*!
 * [EN] Returns the swappable image view inside the tab bar button, used when replacing the icon with a custom view.
 * [CN] 返回 TabBar 按钮内可替换的图片视图，用于把图标替换为自定义视图。
 */
- (UIImageView *)cyl_swappableImageViewViewInTabBarButton;

/*!
 * [EN] Renders the receiver into a UIImage snapshot.
 * [CN] 将当前视图渲染为 UIImage 截图。
 */
- (UIImage *)cyl_takeSnapshot;

/*!
 * [EN] Renders the receiver into a UIImage while temporarily hiding `hideViews`.
 * [CN] 截图时临时隐藏 hideViews 中的视图，再将当前视图渲染为 UIImage。
 */
- (UIImage *)cyl_takeSnapshotWithoutViews:(NSArray<UIView __kindof *> *)hideViews;

/*!
 * [EN] Hides or shows the receiver, also updating alpha, opaque and userInteractionEnabled together.
 * [CN] 隐藏或显示当前视图，同时联动修改 alpha、opaque 与 userInteractionEnabled。
 */
- (void)cyl_setHidden:(BOOL)hidden;


@end

@interface UIView (CYLTabBarControllerExtentionDeprecated)

/*!
 * [EN] Deprecated. Returns the tab bar's background view.
 * [CN] 已废弃。返回 TabBar 的背景视图。
 */
- (UIView *)cyl_tabBadgeBackgroundView CYL_DEPRECATED("Deprecated in 1.6.0. Use `+[CYLPlusButton cyl_tabBackgroundView]` instead.");

/*!
 * [EN] Deprecated. Returns the tab bar's shadow (separator) image view.
 * [CN] 已废弃。返回 TabBar 的阴影（分割线）图片视图。
 */
- (UIView *)cyl_tabBadgeBackgroundSeparator CYL_DEPRECATED("Deprecated in 1.6.0. Use `+[CYLPlusButton cyl_tabShadowImageView]` instead.");

/*!
 * [EN] Deprecated. Creates a round badge dot view with the given color and radius.
 * [CN] 已废弃。创建指定颜色与半径的圆形角标红点视图。
 */
+ (UIView *)cyl_tabBadgePointViewWithClolor:(UIColor *)color radius:(CGFloat)radius CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
@end

NS_ASSUME_NONNULL_END
