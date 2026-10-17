//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (CYLTabBarControllerExtention)

@property (nonatomic, copy, getter=cyl_context, setter=cyl_setContext:) NSString *cyl_context;

@property (nonatomic, assign, getter=cyl_isForceLandscape, setter=cyl_setIsForceLandscape:) BOOL cyl_isForceLandscape;

/*!
 * [EN] Forces the interface to rotate to `orientation`, updating the app delegate's forced-landscape flag.
 * [CN] 强制将界面旋转到指定方向，同时更新 AppDelegate 的强制横屏标记。
 */
- (void)cyl_forceUpdateInterfaceOrientation:(UIInterfaceOrientation)orientation;

/*!
 * [EN] Returns the shared application delegate.
 * [CN] 返回应用的 AppDelegate 单例。
 */
- (UIResponder<UIApplicationDelegate> *)cyl_sharedAppDelegate;

/*!
 * [EN] Returns the topmost visible view controller, following presented, navigation and tab bar controllers from the root.
 * [CN] 从根控制器开始，沿 present、导航与 TabBar 控制器查找并返回最顶层可见的控制器。
 */
+ (UIViewController * __nullable)cyl_topmostViewController;

/*!
 * [EN] Returns the navigation controller of the topmost view controller.
 * [CN] 返回最顶层控制器所在的导航控制器。
 */
+ (UINavigationController * __nullable)cyl_currentNavigationController;

/*!
 * [EN] Dismisses all presented view controllers from the root, then calls `completion`.
 * [CN] 从根控制器开始 dismiss 所有被 present 的控制器，完成后调用 completion。
 */
+ (void)cyl_dismissAll:(void (^ __nullable)(void))completion;

/*!
 * [EN] KVC `valueForKey:` that catches exceptions and returns nil instead of crashing.
 * [CN] 安全的 KVC 取值，捕获异常，失败时返回 nil 而不是崩溃。
 */
- (id)cyl_valueForKey:(NSString *)key;

/*!
 * [EN] KVC `setValue:forKey:` that catches exceptions instead of crashing.
 * [CN] 安全的 KVC 赋值，捕获异常而不是崩溃。
 */
- (void)cyl_setValue:(id)value forKey:(NSString *)key;

/*!
 * [EN] Returns a readable list of the object's ivars (debugging aid, uses a private API).
 * [CN] 返回对象成员变量列表的可读字符串（调试用，依赖私有 API）。
 */
- (NSString *)cyl_ivarList;

/*!
 * [EN] Returns YES if the receiver is a private continuous gesture recognizer used by the system tab bar.
 * [CN] 判断当前对象是否为系统 TabBar 使用的私有连续手势识别器。
 */
- (BOOL)cyl_isContinuousGestureRecognizer;

/*!
 * [EN] Returns YES if the receiver is a UILongPressGestureRecognizer.
 * [CN] 判断当前对象是否为长按手势识别器（UILongPressGestureRecognizer）。
 */
- (BOOL)cyl_isLongGestureRecognizer;

/*!
 * [EN] Returns YES if `viewControllers` contains the plus child view controller (directly or wrapped in a navigation controller).
 * [CN] 判断 viewControllers 中是否包含 PlusButton 子控制器（直接包含或被导航控制器包裹）。
 */
- (BOOL)cyl_isPlusViewControllerAdded:(NSArray *)viewControllers;
@property (nonatomic, assign, getter=cyl_isPlaceholder, setter=cyl_setIsPlaceholder:) BOOL cyl_isPlaceholder;

/*!
 * [EN] `removeObserver:forKeyPath:` that catches exceptions (e.g. when the observer was not registered).
 * [CN] 安全地移除 KVO 观察者，捕获异常（例如观察者未注册时）。
 */
- (void)cyl_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath;

@end

NS_ASSUME_NONNULL_END
