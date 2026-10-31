//
//  UIViewController+CYLTabBarControllerExtention.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 16/2/26.
//  Copyright © 2026年 https://github.com/ChenYilong .All rights reserved.
//

#import "CYLBadgeProtocol.h"
#import "CYLConstants.h"
#if CYL_FLATDESIGN_AVAILABLE
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#endif

NS_ASSUME_NONNULL_BEGIN

typedef void (^CYLPopSelectTabBarChildViewControllerCompletion)(__kindof UIViewController *selectedTabBarChildViewController);

typedef void (^CYLPushOrPopCompletionHandler)(BOOL shouldPop,
                                              __kindof UIViewController *viewControllerPopTo,
                                              BOOL shouldPopSelectTabBarChildViewController,
                                              NSUInteger index
                                              );

typedef void (^CYLPushOrPopCallback)(NSArray<__kindof UIViewController *> *viewControllers, CYLPushOrPopCompletionHandler completionHandler);

@interface UIViewController (CYLTabBarControllerExtention)<CYLBadgeProtocol>

#if CYL_FLATDESIGN_AVAILABLE

//TODO: 分类统一放置到一个独立的文件中， 方便管理。

// 如果未显式设置，则根据视图控制器的标题自动延迟创建
@property (null_resettable, nonatomic, strong, getter=cyl_tabBarItem, setter=cyl_setTabBarItem:) CYLFlatDesignTabBarItem *cyl_tabBarItem;

// 返回控制器的tabBarController，可能为nil
// [EN] Shares one lookup with `-cyl_tabBarController`, see `-[NSObject cyl_tabBarControllerForStyleType:]` in CYLTabBarController.h.
// [CN] 与 `-cyl_tabBarController` 共用同一个查找，见 CYLTabBarController.h 中的 `-[NSObject cyl_tabBarControllerForStyleType:]`。
@property (nullable, nonatomic, weak, getter=cylflatdesign_tabBarController, setter=cylflatdesign_setTabBarController:) UIViewController __kindof *cylflatdesign_tabBarController;




#endif

/*!
 * [EN] Returns YES if the receiver is a CYLTabBarController that is NOT in flat-design style (system / Liquid Glass style).
 * [CN] 判断当前对象是否为非扁平化样式（系统样式/液态玻璃）的 CYLTabBarController。
 */
- (BOOL)cyl_isSystemStyleTabBar;

/*!
 * [EN] Returns YES if the receiver is a CYLTabBarController in flat-design style.
 * [CN] 判断当前对象是否为扁平化样式的 CYLTabBarController。
 */
- (BOOL)cyl_isFlatDesignStyleTabBar;

@property (nonatomic, readonly, getter=cyl_isEmbedInTabBarController) BOOL cyl_embedInTabBarController;

@property (nonatomic, readonly, getter=cyl_tabIndex) NSInteger cyl_tabIndex;

@property (nonatomic, strong, getter=cyl_tabButton, setter=cyl_setTabButton:) UIControl *cyl_tabButton;

@property (nonatomic, assign, setter=cyl_setPlusViewControllerEverAdded:, getter=cyl_plusViewControllerEverAdded) BOOL cyl_plusViewControllerEverAdded;

/*!
 * [EN] Returns YES if a badge is currently shown on this view controller's tab.
 * [CN] 判断当前控制器对应的 Tab 上是否正在显示角标。
 */
- (BOOL)cyl_isShowBadge;
/**
 *  show badge with red dot style and CYLBadgeAnimationTypeNone by default.
 *
 * @attention 如果如果涉及到outlayout， 建议在autolayout布局方法后面，添加layoutIfNeeded方法，再去尝试获取frame。 推荐使用 UIViewController 进行调用该方法， 并在 setViewDidLayoutSubViewsBlockInvokeOnce  展示， 因为 如果使用 UIViewController setViewDidLayoutSubViewsBlockInvokeOnce中调用， 可以保证 cyl_showBadge 在 layoutSubviews之后调用。
 *  layoutSubviews
 * 效果与下面的调用方式一致：
 *  // ====================== ZJ添加:修正xib控件显示角标位置不正确问题 ======================
 
 - (void)load {
    [super load];
    Method m1 = class_getInstanceMethod(self, @selector(layoutSubviews));
    Method m2 = class_getInstanceMethod(self, @selector(cyl_layoutSubviews));
    method_exchangeImplementations(m1, m2);
 }
 
 - (void)cyl_layoutSubviews {
    [self cyl_layoutSubviews];
    self.badge.center = CGPointMake(CGRectGetWidth(self.frame) + 2 + self.badgeCenterOffset.x, self.badgeCenterOffset.y);
 }
 // ====================== end ======================


 
 * [EN] Shows a red-dot badge on this view controller's tab, with no animation.
 * [CN] 在当前控制器对应的 Tab 上显示红点角标，无动画。
 */
- (void)cyl_showBadge;

/**
 *
 *  @param value String value, default is `nil`. if value equal @"" means red dot style.
 *  @param animationType animationType
 *  @attention
 - 调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 - 不支持 CYLPlusChildViewController 对应的 TabBarItem 角标设置，调用会被忽略。
 * [EN] Shows a badge with `value` (@"" for a red dot) and the given animation on this view controller's tab.
 * [CN] 在当前控制器对应的 Tab 上显示值为 value 的角标（传 @"" 为红点），并使用指定动画。
 */
- (void)cyl_showBadgeValue:(NSString *)value
             animationType:(CYLBadgeAnimationType)animationType;

/**
 *  clear badge(hide badge)
 * [EN] Hides the badge on this view controller's tab.
 * [CN] 隐藏当前控制器对应 Tab 上的角标。
 */
- (void)cyl_clearBadge;

/**
 *  make bage(if existing) not hiden
 * [EN] Shows the badge again if one exists and was hidden.
 * [CN] 若角标存在且被隐藏，则重新显示。
 */
- (void)cyl_resumeBadge;

/*!
 * [EN] Returns YES if the badge on this view controller's tab is paused (hidden but kept).
 * [CN] 判断当前控制器对应 Tab 上的角标是否处于暂停（隐藏但保留）状态。
 */
- (BOOL)cyl_isPauseBadge;


/*!
 * Pop 到当前 `NavigationController` 的栈底，并改变 `TabBarController` 的 `selectedViewController` 属性，并将被选择的控制器作为返回值返回。
 @param index 需要选择的控制器在 `TabBar` 中的 index。
 @return 最终被选择的控制器。
 @attention 注意：方法中的参数和返回值都是 `UIViewController` 的子类，但并非 `UINavigationController` 的子类，该方法无 pop 动画。
 * [EN] Pops to the root of the current navigation stack, selects the tab at `index` without animation, and returns the selected view controller.
 * [CN] Pop 到当前导航栈底，无动画地选中 index 对应的 Tab，并返回被选中的控制器。
 */
- (UIViewController *)cyl_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index;

/*!
 * Pop 到当前 `NavigationController` 的栈底，并改变 `TabBarController` 的 `selectedViewController` 属性，并将被选择的控制器作为返回值返回。
 @param index 需要选择的控制器在 `TabBar` 中的 index。
 @param animated 动画
 @return 最终被选择的控制器。
 @attention 注意：方法中的参数和返回值都是 `UIViewController` 的子类，但并非 `UINavigationController` 的子类。
 * [EN] Pops to the root of the current navigation stack, selects the tab at `index`, and returns the selected view controller.
 * [CN] Pop 到当前导航栈底，选中 index 对应的 Tab，并返回被选中的控制器。
 */
- (UIViewController *)cyl_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index animated:(BOOL)animated;

/*!
 * Pop 到当前 `NavigationController` 的栈底，并改变 `TabBarController` 的 `selectedViewController` 属性，并将被选择的控制器在 `Block` 回调中返回。
 @param index 需要选择的控制器在 `TabBar` 中的 index。
 @attention 注意：方法中的参数和返回值都是 `UIViewController` 的子类，但并非 `UINavigationController` 的子类。
 * [EN] Pops to the root of the current navigation stack, selects the tab at `index`, and passes the selected view controller to `completion`.
 * [CN] Pop 到当前导航栈底，选中 index 对应的 Tab，并在 completion 中返回被选中的控制器。
 */
- (void)cyl_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index
                                           completion:(CYLPopSelectTabBarChildViewControllerCompletion)completion;

/*!
 * Pop 到当前 `NavigationController` 的栈底，并改变 `TabBarController` 的 `selectedViewController` 属性，并将被选择的控制器作为返回值返回。
 @param classType 需要选择的控制器所属的类。
 @return 最终被选择的控制器。
 @attention 注意：
                - 方法中的参数和返回值都是 `UIViewController` 的子类，但并非 `UINavigationController` 的子类。
                - 如果 TabBarViewController 的 viewControllers 中包含多个相同的 `classType` 类型，会返回最左端的一个。
 
 * [EN] Pops to the root and selects the first tab whose view controller is of `classType`; returns it.
 * [CN] Pop 到栈底，选中第一个类型为 classType 的子控制器所在 Tab，并返回该控制器。
 */
- (UIViewController *)cyl_popSelectTabBarChildViewControllerForClassType:(Class)classType;

/*!
 * Pop 到当前 `NavigationController` 的栈底，并改变 `TabBarController` 的 `selectedViewController` 属性，并将被选择的控制器在 `Block` 回调中返回。
 @param classType 需要选择的控制器所属的类。
 @attention 注意：
                - 方法中的参数和返回值都是 `UIViewController` 的子类，但并非 `UINavigationController` 的子类。
                - 如果 TabBarViewController 的 viewControllers 中包含多个相同的 `classType` 类型，会返回最左端的一个。
 * [EN] Pops to the root and selects the first tab whose view controller is of `classType`; passes it to `completion`.
 * [CN] Pop 到栈底，选中第一个类型为 classType 的子控制器所在 Tab，并在 completion 中返回。
 */
- (void)cyl_popSelectTabBarChildViewControllerForClassType:(Class)classType
                                                completion:(CYLPopSelectTabBarChildViewControllerCompletion)completion;

/*!
 *@brief 如果当前的 `NavigationViewController` 栈中包含有准备 Push 到的目标控制器，可以选择 Pop 而非 Push。
 *@param viewController Pop 或 Push 到的“目标控制器”，由 completionHandler 的参数控制 Pop 和 Push 的细节。
 *@param animated Pop 或 Push 时是否带动画
 *@param callback 回调，如果传 nil，将进行 Push。callback 包含以下几个参数：
                 * param : viewControllers 表示与“目标控制器”相同类型的控制器；
                 * param : completionHandler 包含以下几个参数：
                                            * param : shouldPop 是否 Pop
                                            * param : viewControllerPopTo Pop 回的控制器
                                            * param : shouldPopSelectTabBarChildViewController 在进行 Push 行为之前，是否 Pop 到当前 `NavigationController` 的栈底。
                                                                                             可能的值如下：
                                                                                             NO 如果上一个参数为 NO，下一个参数 index 将被忽略。
                                                                                             YES 会根据 index 参数改变 `TabBarController` 的 `selectedViewController` 属性。
                                                                                             注意：该属性在 Pop 行为时不起作用。
                                             * param : index Pop 改变 `TabBarController` 的 `selectedViewController` 属性。
                                                           注意：该属性在 Pop 行为时不起作用。
 * [EN] Pops back to an existing controller of the same type if the stack has one, otherwise pushes `viewController`; `callback` decides the details.
 * [CN] 若导航栈中已有同类型控制器可选择 Pop 回去，否则 Push viewController，具体行为由 callback 决定。
*/
- (void)cyl_pushOrPopToViewController:(UIViewController *)viewController
                             animated:(BOOL)animated
                             callback:(CYLPushOrPopCallback)callback;

/*!
 * 如果正要 Push 的页面与当前栈顶的页面类型相同则取消 Push
 * 这样做防止主界面卡顿时，导致一个 ViewController 被 Push 多次
 * [EN] Pushes `viewController`, unless the top of the stack is already of the same class (prevents double pushes).
 * [CN] Push viewController；若栈顶已是同类型控制器则忽略，防止重复 Push。
 */
- (void)cyl_pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

/*!
 * [EN] Returns the first view controller of a navigation controller, or the receiver itself if it is not one.
 * [CN] 若自身是导航控制器则返回其第一个子控制器，否则返回自身。
 */
- (UIViewController *)cyl_getViewControllerInsteadOfNavigationController;

/*!
 * [EN] Handles the back action with animation: pops, or dismisses when presented at the root.
 * [CN] 带动画处理返回操作：Pop；若为 present 出来的栈底页面则 dismiss。
 */
- (void)cyl_handleNavigationBackAction;

/*!
 * [EN] Handles the back action: pops, or dismisses when presented at the root.
 * [CN] 处理返回操作：Pop；若为 present 出来的栈底页面则 dismiss。
 */
- (void)cyl_handleNavigationBackActionWithAnimated:(BOOL)animated;

/*!
 * [EN] Returns the visible tab button for this view controller (the selected-state button under Liquid Glass).
 * [CN] 返回当前控制器对应的可见 Tab 按钮（液态玻璃下为选中态按钮）。
 */
- (UIControl *)cyl_visiableTabButton;

/*!
 * [EN] Returns YES if both are the same controller, or share the same root after unwrapping navigation controllers.
 * [CN] 判断两者是否为同一控制器，或解包导航控制器后根控制器相同。
 */
- (BOOL)cyl_isEqualToViewController:(UIViewController *)compairedViewController;

/*
  If the child controller has a different parent controller, it will first be removed from its current parent
  by calling removeFromParentViewController. If this method is overridden then the super implementation must
  be called.
*/

/*!
 * [EN] Adds `childController` as a child, skipping non-UIViewController objects and placeholder controllers.
 * [CN] 添加子控制器；非 UIViewController 对象或占位控制器会被忽略。
 */
- (void)cyl_addChildViewController:(id)childController;

@end

@interface UIViewController (CYLTabBarControllerExtentionDeprecated)

/*!
 * [EN] Deprecated. Use `-cyl_showBadgeValue:animationType:` instead.
 * [CN] 已废弃，请改用 -cyl_showBadgeValue:animationType:。
 */
- (void)cyl_showTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol>, such as `-[UIViewController cyl_showBadgeValue:animationType:]` instead.");

/*!
 * [EN] Deprecated. Use `-cyl_clearBadge` instead.
 * [CN] 已废弃，请改用 -cyl_clearBadge。
 */
- (void)cyl_removeTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol>, such as `-[UIViewController cyl_clearBadge]` instead.");

/*!
 * [EN] Deprecated. Use `-cyl_isShowBadge` instead.
 * [CN] 已废弃，请改用 -cyl_isShowBadge。
 */
- (BOOL)cyl_isShowTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol>, such as `-[UIViewController cyl_isShowBadge]` instead.");

@property (nonatomic, strong, setter=cyl_setTabBadgePointView:, getter=cyl_tabBadgePointView) UIView *cyl_tabBadgePointView CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");

@property (nonatomic, assign, setter=cyl_setTabBadgePointViewOffset:, getter=cyl_tabBadgePointViewOffset) UIOffset cyl_tabBadgePointViewOffset CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");

@end

NS_ASSUME_NONNULL_END
