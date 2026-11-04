//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
// [CN] FIX: issue #535 — shared with CYLBadgeView through CYLUtils. 通过 CYLUtils 与 CYLBadgeView 共用。
// [EN] FIX: issue #535 — shared with CYLBadgeView through CYLUtils.
#if __has_include("CYLUtils/UIBarItem+CYLUtils.h")
#import "CYLUtils/UIBarItem+CYLUtils.h"
#else
#import "UIBarItem+CYLUtils.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface UITabBarItem (CYLTabBarControllerExtention)

@property (nonatomic, readonly, nullable) UIControl *cyl_selectedTabButton;
@property (nonatomic, readonly) UIControl *cyl_visiableTabButton;
@property (nonatomic, strong, getter=cyl_lottieURL, setter=cyl_setLottieURL:) NSURL *cyl_lottieURL;

@property (nonatomic, strong, getter=cyl_lottieSizeValue, setter=cyl_setLottieSizeValue:) NSValue *cyl_lottieSizeValue;
@property (nonatomic, assign, getter=cyl_imagePositionAdjustment, setter=cyl_setImagePositionAdjustment:) UIOffset cyl_imagePositionAdjustment;

/**
 * 获取一个UITabBarItem内显示图标的UIImageView，如果找不到则返回nil
 * [EN] Returns the image view that shows this item's icon, or nil.
 * [CN] 返回该 Item 用于显示图标的图片视图，找不到时返回 nil。
 */
- (nullable UIImageView *)cyl_imageView;

/*!
 * [EN] Same as `-cyl_imageView`.
 * [CN] 同 -cyl_imageView。
 */
- (nullable UIImageView *)cyl_imageViewInTabBarButton;

/*!
 * [EN] Runs when the user taps this tab twice quickly while it is selected, e.g. to scroll to the top and refresh.
 *      Set it on the tab's item: the navigation controller's `tabBarItem` (the root view controller's also works).
 *      `index` is the tab's index in `viewControllers`. See also
 *      `-[CYLTabBarControllerDelegate tabBarController:didDoubleTapViewController:atIndex:]`. Every style.
 * [CN] 该 Tab 处于选中状态时被快速连续点击两次时执行，例如回到顶部并刷新。设置在该 Tab 的 item 上：导航控制器的 `tabBarItem`
 *      （根控制器的也可以）。`index` 为该 Tab 在 `viewControllers` 中的下标。另见
 *      `-[CYLTabBarControllerDelegate tabBarController:didDoubleTapViewController:atIndex:]`。适用于所有样式。
 */
@property (nonatomic, copy, nullable, getter=cyl_doubleTapBlock, setter=cyl_setDoubleTapBlock:) void (^cyl_doubleTapBlock)(UITabBarItem *tabBarItem, NSInteger index);

/*!
 * [EN] Runs after every layout of the tab bar with the button UIKit draws for this item (`cyl_tabButton`), e.g. to add or
 *      place a view of your own on it, which UIKit's layout would otherwise move or cover. The button can be a new one
 *      after UIKit rebuilt it (e.g. after the item's image changed): look subviews up again each time. The system tab
 *      bar (Liquid Glass, classic); FlatDesign items are views of the library and are laid out by it.
 * [CN] TabBar 每次布局之后执行，参数为 UIKit 为该 item 绘制的按钮（`cyl_tabButton`），例如在按钮上添加或摆放自己的视图，避免被 UIKit
 *      的布局移动或遮挡。UIKit 重建按钮后（例如修改了 item 的图片）可能是新的按钮：每次都请重新查找子视图。适用于系统 TabBar
 *      （液态玻璃、经典样式）；扁平样式的 item 是本库自己的视图，由本库布局。
 */
@property (nonatomic, copy, nullable, getter=cyl_viewDidLayoutSubviewsBlock, setter=cyl_setViewDidLayoutSubviewsBlock:) void (^cyl_viewDidLayoutSubviewsBlock)(UITabBarItem *tabBarItem, UIView *view);

@end

/*!
 * [EN] Item styles of a `UITabBarAppearance` in one go.
 * [CN] 一次设置 `UITabBarAppearance` 的 item 样式。
 */
API_AVAILABLE(ios(13.0))
@interface UITabBarAppearance (CYLTabBarControllerExtention)

/*!
 * [EN] Runs `block` on `stackedLayoutAppearance`, `inlineLayoutAppearance` and `compactInlineLayoutAppearance`, so a style
 *      applies whether the items are stacked (iPhone portrait) or inline (iPad, landscape):
 *          [appearance cyl_applyItemAppearanceWithBlock:^(UITabBarItemAppearance *itemAppearance) {
 *              itemAppearance.selected.iconColor = UIColor.systemRedColor;
 *          }];
 * [CN] 对 `stackedLayoutAppearance`、`inlineLayoutAppearance`、`compactInlineLayoutAppearance` 依次执行 `block`，使样式在 item
 *      纵向排列（iPhone 竖屏）与横向排列（iPad、横屏）时都生效（示例见上方英文）。
 */
- (void)cyl_applyItemAppearanceWithBlock:(void (NS_NOESCAPE ^)(UITabBarItemAppearance *itemAppearance))block;

@end

NS_ASSUME_NONNULL_END
