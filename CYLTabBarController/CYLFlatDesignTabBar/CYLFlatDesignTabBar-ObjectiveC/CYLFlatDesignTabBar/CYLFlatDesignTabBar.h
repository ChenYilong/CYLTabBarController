//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLFlatDesignTabBarButton.h"

NS_ASSUME_NONNULL_BEGIN

@class CYLFlatDesignTabBar;

@protocol CYLFlatDesignTabBarDelegate<NSObject>
@optional

// 当用户点击时调用（而非通过编程）

/*!
 * [EN] Called when the user taps an item (not when selection changes in code).
 * [CN] 用户点击 Item 时回调（通过代码切换选中项时不会回调）。
 */
- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItem:(CYLFlatDesignTabBarItem *)item;

@end

@interface CYLFlatDesignTabBar : UIView

@property (nullable, nonatomic, weak) id<CYLFlatDesignTabBarDelegate> delegate;
@property (nullable, nonatomic, copy) NSArray<CYLFlatDesignTabBarItem *> *items;

/*!
 * tabBarItems is same as items， 作用是兼容CYLTabBar，实际效果以items为准。
 */
@property (nullable, nonatomic, copy) NSArray<CYLFlatDesignTabBarButton *> *tabBarItems;

/*!
 * [EN] Creates and returns a new item with the given attributes. It does NOT add the item to `items`; assign `items` yourself.
 * [CN] 使用给定属性创建并返回一个新 Item。注意：不会自动加入 items，需自行设置 items。
 */
- (CYLFlatDesignTabBarItem *)addItemWithTitle:(NSString *)title
                              tabBarItemImage:(id)tabBarItemImage
                      tabBarItemSelectedImage:(id)tabBarItemSelectedImage
                                        index:(NSInteger)index
                      titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                  imageInsets:(UIEdgeInsets)imageInsets
                               lottieFilePath:(NSString *)lottieFilePath
                              lottieSizeValue:(NSValue *)lottieSizeValue;

@property (nullable, nonatomic, weak) CYLFlatDesignTabBarItem *selectedItem;

@property (nonatomic, assign) NSUInteger selectedIndex;

@property (nonatomic, strong, readonly) NSArray<CYLFlatDesignTabBarButton *> *tabBarButtons;

@property (null_resettable, nonatomic, strong) UIColor *tintColor;
@property (nullable, nonatomic, strong) UIColor *barTintColor UI_APPEARANCE_SELECTOR;  // default is nil

/* The background image will be tiled to fit, even if it was not created via the UIImage resizableImage methods.
 */
@property (nullable, nonatomic, strong) UIImage *backgroundImage UI_APPEARANCE_SELECTOR;


/* Default is nil. When non-nil, a custom shadow image to show instead of the default shadow image. For a custom shadow to be shown, a custom background image must also be set with -setBackgroundImage: (if the default background image is used, the default shadow image will be used).
 */
@property (nullable, nonatomic, strong) UIImage *shadowImage UI_APPEARANCE_SELECTOR;

/* default is YES.
    按钮是否避开左右安全区域（如横屏刘海）。背景始终铺满整个宽度。
    竖向状态栏（iPhone Duo 折叠竖屏右侧竖列）的单侧安全区另由 `respectsVerticalStatusBarSafeArea` 控制（默认忽略）。
    [EN] Whether the buttons stay clear of the left/right safe area (e.g. a landscape notch). The background
    always spans the full width. The one-sided inset of a vertical status bar (the folded iPhone Duo's
    right-hand status column) is controlled separately by `respectsVerticalStatusBarSafeArea` (ignored by default).
 */
@property (nonatomic, assign) BOOL useLayoutSafeAreaInsets UI_APPEARANCE_SELECTOR;

/*!
 * FIX: issue #672
 * [EN] Default is NO. Whether the buttons also stay clear of the inset that a vertical status bar adds on
 *      one side, e.g. the 84 pt column on the right of the folded iPhone Duo held upright (iOS 27.1 SDK),
 *      where the status bar (Wi-Fi, battery) moves to the trailing edge.
 *      NO: that one-sided inset is ignored, so the buttons span the full width and stay centered on screen;
 *      the last button can sit partly under the status column.
 *      YES: the buttons stay inside the safe area, so the row is shifted left by that column.
 *      A vertical status bar is told apart by its inset being on one side only; a landscape notch insets
 *      both sides and is still handled by `useLayoutSafeAreaInsets`. Has no effect when
 *      `useLayoutSafeAreaInsets` is NO.
 *      Only matters while the vertical bar is shown. This property does not switch the vertical bar on or off; that is
 *      `CYLTabBarController.allowsVerticalBar` (or a screen's own `preferredVerticalBarBehavior`). With the vertical bar
 *      off the status bar is horizontal, there is no one-sided inset, and both values give the same layout.
 * [CN] 默认 NO。按钮是否同时避开竖向状态栏在单侧产生的安全区，例如 iPhone Duo 折叠且竖屏时
 *      （iOS 27.1 SDK）状态栏（Wi-Fi、电量）移到右侧形成的 84pt 竖列。
 *      NO：忽略这侧安全区，按钮铺满整个宽度、在屏幕上居中；最后一个按钮可能部分位于状态栏下方。
 *      YES：按钮留在安全区内，整行会因该竖列向左偏移。
 *      竖向状态栏的判断依据是只有一侧有安全区；横屏刘海两侧都有安全区，仍由 `useLayoutSafeAreaInsets` 处理。
 *      `useLayoutSafeAreaInsets` 为 NO 时此属性无效。
 *      只在竖向栏显示时起作用。本属性不负责开关竖向栏，开关由 `CYLTabBarController.allowsVerticalBar`（或页面自己的
 *      `preferredVerticalBarBehavior`）决定。竖向栏关闭时状态栏是横向的，没有单侧安全区，YES 和 NO 布局相同。
 */
@property (nonatomic, assign) BOOL respectsVerticalStatusBarSafeArea UI_APPEARANCE_SELECTOR;

/*!
 [EN] This can be left unset; the default is CYLTabBarController. If set, please implement the `+[CYLPlusButton tabBarContext]` method in CYLPlusButton and ensure consistency. If neither is implemented, the default is CYLTabBarController for both.

 [CN] 可以不设置， 默认为 CYLTabBarController，如果设置了，请实现 CYLPlusButton 里 的 `+[CYLPlusButton tabBarContext]` 并保持一致。如果两个都不是实现，默认为一致均为 CYLTabBarController
 */
@property (nonatomic, copy, nullable) NSString *context;

/*!
 * [EN] Returns YES if a plus button is registered for the context of the CYLTabBarController that owns this tab bar
 *      (its `delegate`). The plus button is bound to the controller, not to the tab bar, so this always agrees with
 *      `-[CYLTabBarController hasPlusButton]`, also when several plus buttons are registered.
 * [CN] 判断是否为拥有本 TabBar 的 CYLTabBarController（即它的 `delegate`）的 context 注册了 PlusButton。
 *      PlusButton 绑定的是控制器而不是 TabBar，因此始终与 `-[CYLTabBarController hasPlusButton]` 一致，注册了多个 PlusButton 时也是如此。
 */
- (BOOL)hasPlusButton;

/*!
 * [EN] Returns YES if a plus child view controller is registered for the context of the CYLTabBarController that owns this tab bar.
 * [CN] 判断是否为拥有本 TabBar 的 CYLTabBarController 的 context 注册了 PlusButton 子控制器。
 */
- (BOOL)hasPlusChildViewController;

@end

NS_ASSUME_NONNULL_END
