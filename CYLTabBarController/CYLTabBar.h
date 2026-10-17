//
//  CYLTabBar.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLPlusButton.h"
#import "NSObject+CYLTabBarControllerExtention.h"

NS_ASSUME_NONNULL_BEGIN
@class CYLTabBar;
// CYLConstants.h 里的前向声明被包在 `__has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)`
// 里，未引入 CYLFlatDesignTabBar 子库的用法（如 LottieSwift subspec）拿不到该类型，
// 因此这里显式再声明一次，保证本头文件可独立编译。
@class CYLTabBarController;
typedef void(^CYLTabBarDidLayoutSubViewsBlock)(CYLTabBar *tabBar);

@interface CYLTabBar : UITabBar

/*!
 * 让 `TabImageView` 垂直居中时，所需要的默认偏移量。
 * @attention 该值将在设置 top 和 bottom 时被同时使用，具体的操作等价于如下行为：
 * `viewController.tabBarItem.imageInsets = UIEdgeInsetsMake(tabImageViewDefaultOffset, 0, -tabImageViewDefaultOffset, 0);`
 */
@property (nonatomic, assign, readonly) CGFloat tabImageViewDefaultOffset;

/*!
 [EN] This can be left unset; the default is CYLTabBarController. If set, please implement the `+[CYLPlusButton tabBarContext]` method in CYLPlusButton and ensure consistency. If neither is implemented, the default is CYLTabBarController for both.

 [CN] 可以不设置， 默认为 CYLTabBarController，如果设置了，请实现 CYLPlusButton 里 的 `+[CYLPlusButton tabBarContext]` 并保持一致。如果两个都不是实现，默认为一致均为 CYLTabBarController
 */
@property (nonatomic, copy, nullable) NSString *context;

@property (nonatomic, copy, nullable) CYLTabBarDidLayoutSubViewsBlock didLayoutSubViewsBlock;

/** 发布按钮 */
@property (nonatomic, strong) CYLPlusButton<CYLPlusButtonSubclassing> *plusButton;
@property (nonatomic, assign) CGFloat tabBarItemWidth;
@property (nonatomic, copy) NSArray<UIControl *> *tabBarButtonArray;

/*!
 * plusButton state:
 * Register + Context match == Active
 */
@property (nonatomic, assign, getter=isPlusButtonActive) BOOL plusButtonActive;
@property (nonatomic, assign) BOOL isLensViewLifed;
@property (nonatomic, strong) UIGestureRecognizer *liquidGlassContinuousGestureRecognizer;

/*!
 *TODO:
 * 之前 tabbar 上有长按手势，iOS 26 液态玻璃，长按手势都不起作用了，需要重新增加自定义手势。
  */
@property (nonatomic, strong) UIGestureRecognizer *liquidGlassLongGestureRecognizer;

/*!
 * [EN] Returns the plus button's index in the tab bar. Note: it also repositions the plus button as a side effect.
 * [CN] 返回 PlusButton 在 TabBar 中的索引。注意：调用时会顺带重新设置 PlusButton 的位置。
 */
- (NSUInteger)plusButtonIndex;

/*!
 * [EN] Returns YES if the registered plus button's context matches this tab bar's context.
 * [CN] 判断已注册 PlusButton 的 context 是否与当前 TabBar 的 context 一致。
 */
- (BOOL)hasPlusButton;

/*!
 * [EN] Returns YES if the plus child view controller exists and matches this tab bar's context.
 * [CN] 判断 PlusButton 子控制器是否存在且与当前 TabBar 的 context 一致。
 */
- (BOOL)hasPlusChildViewController;

/*!
 * [EN] Returns YES if the plus button is vertically centered in the tab bar.
 * [CN] 判断 PlusButton 是否在 TabBar 中垂直居中。
 */
- (BOOL)isPlusButtonLayoutCentered;

/*!
 * [EN] Returns the owning CYLTabBarController (the delegate if it is one, otherwise `cyl_tabBarController`).
 * [CN] 返回所属的 CYLTabBarController（优先取 delegate，否则取 cyl_tabBarController）。
 */
- (CYLTabBarController *)tabBarController;

@end

NS_ASSUME_NONNULL_END
