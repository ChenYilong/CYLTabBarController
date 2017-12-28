//
//  UIViewController+CYLTabBarControllerExtention.h
//  CYLTabBarController
//
//  v1.16.0 Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 16/2/26.
//  Copyright © 2016年 https://github.com/ChenYilong .All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^CYLPopSelectTabBarChildViewControllerCompletion)(__kindof UIViewController *selectedTabBarChildViewController);

typedef void (^CYLPushOrPopCompletionHandler)(BOOL shouldPop,
                                              __kindof UIViewController *viewControllerPopTo,
                                              BOOL shouldPopSelectTabBarChildViewController,
                                              NSUInteger index
                                              );

typedef void (^CYLPushOrPopCallback)(NSArray<__kindof UIViewController *> *viewControllers, CYLPushOrPopCompletionHandler completionHandler);

@interface UIViewController (CYLTabBarControllerExtention)

@property (nonatomic, strong, setter=cyl_setTabBadgePointView:, getter=cyl_tabBadgePointView) UIView *cyl_tabBadgePointView;

@property (nonatomic, assign, setter=cyl_setTabBadgePointViewOffset:, getter=cyl_tabBadgePointViewOffset) UIOffset cyl_tabBadgePointViewOffset;

@property (nonatomic, readonly, getter=cyl_isEmbedInTabBarController) BOOL cyl_embedInTabBarController;

@property (nonatomic, readonly, getter=cyl_tabIndex) NSInteger cyl_tabIndex;

@property (nonatomic, readonly) UIControl *cyl_tabButton;

@property (nonatomic, copy, setter=cyl_setContext:, getter=cyl_context) NSString *cyl_context;

@property (nonatomic, assign, setter=cyl_setPlusViewControllerEverAdded:, getter=cyl_plusViewControllerEverAdded) BOOL cyl_plusViewControllerEverAdded;

/*!
 * @attention 
   - 调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
   - 不支持 CYLPlusChildViewController 对应的 TabBarItem 角标设置，调用会被忽略。
 */
- (void)cyl_showTabBadgePoint;

- (void)cyl_removeTabBadgePoint;

- (BOOL)cyl_isShowTabBadgePoint;

/*!
 * Pop 到当前 `NavigationController` 的栈底，并改变 `TabBarController` 的 `selectedViewController` 属性，并将被选择的控制器作为返回值返回。
 @param index 需要选择的控制器在 `TabBar` 中的 index。
 @return 最终被选择的控制器。
 @attention 注意：方法中的参数和返回值都是 `UIViewController` 的子类，但并非 `UINavigationController` 的子类。
 */
- (UIViewController *)cyl_popSelectTabBarChildViewControllerAtIndex:(NSUInteger)index;

/*!
 * Pop 到当前 `NavigationController` 的栈底，并改变 `TabBarController` 的 `selectedViewController` 属性，并将被选择的控制器在 `Block` 回调中返回。
 @param index 需要选择的控制器在 `TabBar` 中的 index。
 @attention 注意：方法中的参数和返回值都是 `UIViewController` 的子类，但并非 `UINavigationController` 的子类。
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
 
 */
- (UIViewController *)cyl_popSelectTabBarChildViewControllerForClassType:(Class)classType;

/*!
 * Pop 到当前 `NavigationController` 的栈底，并改变 `TabBarController` 的 `selectedViewController` 属性，并将被选择的控制器在 `Block` 回调中返回。
 @param classType 需要选择的控制器所属的类。
 @attention 注意：
                - 方法中的参数和返回值都是 `UIViewController` 的子类，但并非 `UINavigationController` 的子类。
                - 如果 TabBarViewController 的 viewControllers 中包含多个相同的 `classType` 类型，会返回最左端的一个。
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
*/
- (void)cyl_pushOrPopToViewController:(UIViewController *)viewController
                             animated:(BOOL)animated
                             callback:(CYLPushOrPopCallback)callback;

/*!
 * 如果正要 Push 的页面与当前栈顶的页面类型相同则取消 Push
 * 这样做防止主界面卡顿时，导致一个 ViewController 被 Push 多次
 */
- (void)cyl_pushViewController:(UIViewController *)viewController animated:(BOOL)animated;

- (UIViewController *)cyl_getViewControllerInsteadOfNavigationController;

@end
