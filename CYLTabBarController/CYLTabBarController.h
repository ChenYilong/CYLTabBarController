//
//  CYLTabBarController.h
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLPlusButton.h"
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "UIViewController+CYLNavigationControllerExtention.h"
#import "UIView+CYLTabBarControllerExtention.h"
#import "UITabBarItem+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "CYLBaseViewController.h"
#import "CYLBaseTableViewController.h"
#import "CYLBaseNavigationController.h"
#import "CYLTabBar+CYLTabBarControllerExtention.h"
#import "UITabBarItem+CYLBadgeExtention.h"
#import "UIControl+CYLBadgeExtention.h"
#import "UIBarButtonItem+CYLBadgeExtention.h"
#import "UIView+CYLBadgeExtention.h"
#import "NSObject+CYLTabBarControllerExtention.h"
#import "UIColor+CYLTabBarControllerExtention.h"
#import "CYLConstants.h"

#if CYL_FLATDESIGN_AVAILABLE
//#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#else
#endif

NS_ASSUME_NONNULL_BEGIN

//typedef NS_ENUM(NSInteger, CYLTabBarStyleType) {
//    CYLTabBarStyleTypeDefault = 0,
//    CYLTabBarStyleTypeSystem,
//    CYLTabBarStyleTypeFlatDesign,
//    CYLTabBarStyleTypeLiquidGlass
//};

@class CYLTabBarController;
typedef void(^CYLViewDidLayoutSubViewsBlock)(CYLTabBarController *tabBarController);

FOUNDATION_EXTERN NSString *const CYLTabBarItemTitle;
FOUNDATION_EXTERN NSString *const CYLTabBarItemImage;
FOUNDATION_EXTERN NSString *const CYLTabBarItemSelectedImage;
FOUNDATION_EXTERN NSString *const CYLTabBarLottieFilePath;
FOUNDATION_EXTERN NSString *const CYLTabBarLottieURL;
FOUNDATION_EXTERN NSString *const CYLTabBarLottieSize;
FOUNDATION_EXTERN NSString *const CYLTabBarItemImageInsets;
FOUNDATION_EXTERN NSString *const CYLTabBarItemTitlePositionAdjustment;
FOUNDATION_EXTERN NSString *const CYLTabBarItemImagePositionAdjustment;
/*!
 * [EN] These globals hold what was written LAST, by whichever tab bar controller or plus button wrote last. The library
 *      no longer lays out with them: with several tab bar controllers they overwrote each other (a tab bar with 5 items
 *      was laid out with the 3 of the one pushed after it, issues #414, #489). Each tab bar keeps its own values:
 *      `-[UIView cyl_tabbarItemsCount]`, `-[UIView cyl_tabBarItemWidth]`, `-[UIView cyl_plusButtonIndex]`,
 *      `-[UIView cyl_plusButtonWidth]` (see UIView+CYLTabBarControllerExtention.h) and `-[CYLTabBarController tabBarHeight]`.
 *      With one tab bar controller they are what they always were.
 * [CN] 这些全局变量保存的是 **最后一次** 写入的值，由最后写入的 TabBarController 或 PlusButton 决定。库不再使用它们来布局：
 *      存在多个 TabBarController 时它们会互相覆盖（5 个 item 的 TabBar 按后面 push 进来的 3 个 item 来布局，issue #414、#489）。
 *      每个 TabBar 保存自己的值：`-[UIView cyl_tabbarItemsCount]`、`-[UIView cyl_tabBarItemWidth]`、`-[UIView cyl_plusButtonIndex]`、
 *      `-[UIView cyl_plusButtonWidth]`（见 UIView+CYLTabBarControllerExtention.h）和 `-[CYLTabBarController tabBarHeight]`。
 *      只有一个 TabBarController 时，它们与以前完全一致。
 */
FOUNDATION_EXTERN NSUInteger CYLTabbarItemsCount;
FOUNDATION_EXTERN NSUInteger CYLPlusButtonIndex;
FOUNDATION_EXTERN CGFloat CYLPlusButtonWidth;
FOUNDATION_EXTERN CGFloat CYLTabBarItemWidth;
FOUNDATION_EXTERN CGFloat CYLTabBarHeight;

@protocol CYLTabBarControllerDelegate <NSObject, UITabBarControllerDelegate>
@optional
/*!
 * @param tabBarController The tab bar controller containing viewController.
 * @param control Selected UIControl in TabBar. 与 `-[UITaBar  tabBar: didSelectItem:]` 相比，差别在于该参数UIControl可能包含自定义加号➕按钮。且支持如果是代码或者用户交互切换index时都进行回调。弥补了 `-[UITaBar  tabBar: didSelectItem:]` 仅在用户点击时调用的不足。
 *
 *调用时机与shouldSelectViewController 代理方法一致。
  * 三个地方 ， 时机会调用：
  *  选中状态下的重新点击，（iOS26 需要在手势代理方法中进行hook追加该方法）
  *  用户切换index时 ，底层通过 `-setSelectedViewController`方法来实现。
  *  代码切换index 时，底层通过 `-setSelectedIndex` 方法来实现。
 * @attention 即使 PlusButton 也添加了点击事件，点击 PlusButton 后也会触发该代理方法。可在PlusButton初始化时使用 CYLExternPlusButton.cyl_userInteractionDisabled = YES; 来禁止该协议方法触发涉及plusButton的回调
 * [EN] Called after the selected control changes, whether by a tap or by code. Unlike `-tabBar:didSelectItem:`, `control` may be the plus button.
 * [CN] 选中控件变化后回调，无论是用户点击还是代码切换。与 -tabBar:didSelectItem: 不同，control 可能是 PlusButton。
 */
- (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control;
//- (void)tabBarController:(CYLTabBarController *)tabBarController didLongPressControl:(UIControl *)control;

/*!
 * [EN] Asks whether the Liquid Glass lens (selection bubble) should be shown for `control`. Default: NO without Liquid Glass; NO when the plus child view controller is selected and the plus button is not centered; otherwise YES.
 * [CN] 询问是否为 control 显示液态玻璃 LiquidLens（选中气泡）。默认：未启用液态玻璃时返回 NO；选中 PlusButton 子控制器且 PlusButton 未居中时返回 NO；其余返回 YES。
 */
- (BOOL)tabBarController:(CYLTabBarController *)tabBarController shouldShowPlatterLiquidLensViewForControl:(UIControl *)control;

@end

#if CYL_FLATDESIGN_AVAILABLE

//TODO:  , CYLFlatDesignUITabBarControllerDelegate
@interface CYLTabBarController : UITabBarController <CYLTabBarControllerDelegate, CYLFlatDesignTabBarDelegate>

#else
@interface CYLTabBarController : UITabBarController <CYLTabBarControllerDelegate>
#endif


/*!
 * 设置为CYLTabBarStyleTypeFlatDesign，表示扁平化设计， 本属性相当于UI兼容模式的代码替代版本，仅仅在 iOS26+ 系统有效。   其内部会设置noNeedUIDesignCompatibility该属性用于决定是否使用扁平设计。
 * @return means noNeedUIDesignCompatibility == YES if return CYLTabBarStyleTypeLiquidGlass, means noNeedUIDesignCompatibility == NO if return CYLTabBarStyleTypeFlatDesign;
 * @attention 请在父类的 ViewDidLoad 调用之前设置 CYLTabBarStyleType 。也就是在 `-[super viewDidLoad];` 之前调用。因为 需要在 tabBar 的KVC操作之前确定自定义样式，否则， 就会执行默认逻辑， 可能会导致你的自定义样式失效。
 */
@property (nonatomic, assign) CYLTabBarStyleType tabBarStyleType;

@property (nonatomic, copy) CYLViewDidLayoutSubViewsBlock viewDidLayoutSubviewsBlock;

/*!
 * [EN] Sets the block invoked in `-viewDidLayoutSubviews`.
 * [CN] 设置在 -viewDidLayoutSubviews 中回调的 block。
 */
- (void)setViewDidLayoutSubViewsBlock:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock;

/*!
 * [EN] Sets the block invoked in `-viewDidLayoutSubviews`, marked to run only once. Note: `invokeOnce` is currently ignored and always treated as YES.
 * [CN] 设置在 -viewDidLayoutSubviews 中回调的 block，并标记为只执行一次。注意：目前 invokeOnce 参数未被使用，始终按 YES 处理。
 */
- (void)setViewDidLayoutSubViewsBlockInvokeOnce:(BOOL)invokeOnce block:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock;
/*!
 * An array of the root view controllers displayed by the tab bar interface.
 */
@property (nullable, nonatomic, copy) NSArray<__kindof UIViewController *> *viewControllers;

/*!
 * The Attributes of items which is displayed on the tab bar.
 */
@property (nonatomic, readwrite, copy) NSArray<NSDictionary *> *tabBarItemsAttributes;

/*!
 * Customize UITabBar height
 */
@property (nonatomic, assign) CGFloat tabBarHeight;

/*!
 * To set both Item image view attributes in the tabBar,
 * default is UIEdgeInsetsZero.
 */
@property (nonatomic, readonly, assign) UIEdgeInsets imageInsets;

@property (nonatomic, strong, readonly) CYLTabBar *tabBar;
@property (nonatomic, strong, setter=cyl_setTabBar:) UIView __kindof *cyl_tabBar;

/*!
 *  动画视图的渲染模式 只有集成了lottie动画才会生效
 * [EN] Content mode of the Lottie animation views. Default is UIViewContentModeScaleAspectFit; override in a subclass to change it.
 * [CN] Lottie 动画视图的 contentMode，默认 UIViewContentModeScaleAspectFit，可在子类中重写修改。
 */
- (UIViewContentMode)lottieAnimationViewContentMode;

/*!
 * To set both Item label text attributes in the tabBar,
 * use the following to tweak the relative position of the label within the tab button (for handling visual centering corrections if needed because of custom text attributes)
 */
@property (nonatomic, readonly, assign) UIOffset titlePositionAdjustment;

/*!
 * To set both Item label text attributes in the tabBar,
 * use the following to tweak the relative position of the label within the tab button (for handling visual centering corrections if needed because of custom text attributes)
 */
@property (nonatomic, readonly, assign) UIOffset imagePositionAdjustment;

/*!
 * /// 如果用户设置的TabBarItemImageViewSize不合规，则依据父视图大小来调整，否则依据默认的imageView的大小来调整
 */
@property (nonatomic, assign) BOOL adjustTabBarItemImageViewSizeDependOnSuperView;

/** 可以不设置， 默认为 CYLTabBarController，如果设置了，请实现 CYLPlusButton 里 的 +[CYLPlusButton tabBarContext] 并保持一致。如果两个都不是实现，默认为一致均为 CYLTabBarController
 *
 * [EN] The key that binds a tab bar controller to its plus button. Several plus buttons can be registered at the same
 *      time (one per `+[CYLPlusButton tabBarContext]`), and each tab bar controller uses the one registered for its own
 *      `context`: give every tab bar controller that has a plus button its own context. See `+[CYLPlusButton plusButtonForTabBarContext:]`.
 * [CN] 将 TabBarController 与其 PlusButton 绑定的 key。可以同时注册多个 PlusButton（每个 `+[CYLPlusButton tabBarContext]` 一个），
 *      每个 TabBarController 使用为自己 `context` 注册的那一个：请给每个带 PlusButton 的 TabBarController 设置不同的 context。
 *      见 `+[CYLPlusButton plusButtonForTabBarContext:]`。
 */
@property (nonatomic, readonly, copy, nullable) NSString *context;

/*!
 * [EN] Creates a tab bar controller with view controllers and matching item attributes.
 * [CN] 使用子控制器数组与对应的 TabBarItem 属性数组初始化。
 */
- (nonnull instancetype)initWithViewControllers:(nonnull NSArray<UIViewController *> *)viewControllers
                          tabBaritemsAttributes:(nonnull NSArray<NSDictionary *> *)tabBarItemsAttributes;

/*!
 * [EN] Convenience constructor with view controllers and matching item attributes.
 * [CN] 便利构造方法：传入子控制器数组与对应的 TabBarItem 属性数组。
 */
+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes;

/*!
 * [EN] Creates a tab bar controller, also setting the image insets and title offset shared by all items.
 * [CN] 初始化，同时设置所有 TabBarItem 共用的图片内边距与标题偏移。
 */
- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment;

/*!
 * [EN] Convenience constructor that also sets the image insets and title offset shared by all items.
 * [CN] 便利构造方法，同时设置所有 TabBarItem 共用的图片内边距与标题偏移。
 */
+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment;

/*!
 * [EN] Creates a tab bar controller with shared image insets, title offset and a context that must match `+[CYLPlusButton tabBarContext]`.
 * [CN] 初始化，设置共用的图片内边距、标题偏移，以及需与 +[CYLPlusButton tabBarContext] 保持一致的 context。
 */
- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                context:(NSString *)context;

/*!
 * [EN] Convenience constructor with shared image insets, title offset and context.
 * [CN] 便利构造方法：设置共用的图片内边距、标题偏移与 context。
 */
+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                            context:(NSString *)context;

/*!
 * [EN] Creates a tab bar controller with a style type (e.g. flat design or Liquid Glass) and context.
 * [CN] 初始化，指定 TabBar 样式（如扁平化或液态玻璃）与 context。
 */
- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                              styleType:(CYLTabBarStyleType)styleType
                                context:(NSString *)context;

/*!
 * [EN] Convenience constructor with a style type and context.
 * [CN] 便利构造方法：指定 TabBar 样式与 context。
 */
+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                          styleType:(CYLTabBarStyleType)styleType
                                            context:(NSString *)context;

/*!
 * [EN] Designated-style initializer with image insets, title offset, style type and context.
 * [CN] 完整初始化方法：指定图片内边距、标题偏移、TabBar 样式与 context。
 */
- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                              styleType:(CYLTabBarStyleType)styleType
                                context:(NSString *)context;

/*!
 * [EN] Convenience constructor with image insets, title offset, style type and context.
 * [CN] 便利构造方法：指定图片内边距、标题偏移、TabBar 样式与 context。
 */
+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                          styleType:(CYLTabBarStyleType)styleType
                                            context:(NSString *)context;

/*!
 * [EN] Updates the plus button's selection state before `viewController` is selected. Call it from `-tabBarController:shouldSelectViewController:`. No effect in flat-design mode.
 * [CN] 在选中 viewController 之前更新 PlusButton 的选中状态，请在 -tabBarController:shouldSelectViewController: 中调用。扁平化模式下无效。
 */
- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController;

/*!
 * [EN] Same as above, but with an explicit `shouldSelect`; when NO, the target tab button's user interaction is disabled and nothing else changes.
 * [CN] 同上，但显式传入 shouldSelect；为 NO 时仅禁用目标 Tab 按钮的交互，不做其他处理。
 */
- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController
                                            shouldSelect:(BOOL)shouldSelect;

/*!
 * [EN] Hides the tab bar's top shadow (separator line). No effect in flat-design mode.
 * [CN] 隐藏 TabBar 顶部的阴影（分割线）。扁平化模式下无效。
 */
- (void)hideTabBarShadowImageView;

/*!
 * [EN] Sets the tab bar tint color. No effect in flat-design mode.
 * [CN] 设置 TabBar 的 tintColor。扁平化模式下无效。
 */
- (void)setTintColor:(UIColor *)tintColor;

/*!
 * Judge if there is plus button.
 * [EN] Returns YES if the tab bar has a plus button.
 * [CN] 判断 TabBar 是否包含 PlusButton。
 */
- (BOOL)hasPlusButton;

/*!
 * @attention Include plusButton if exists.
 * [EN] Returns the number of tab bar items, plus one when there is a plus button.
 * [CN] 返回 TabBar 按钮总数，含 PlusButton 时加 1。
 */
- (NSUInteger)allItemsInTabBarCount;

/*!
 * [EN] Returns the application delegate.
 * [CN] 返回应用的 AppDelegate。
 */
- (id<UIApplicationDelegate>)appDelegate;

/*!
 * [EN] Returns the application's root window.
 * [CN] 返回应用的根 window。
 */
- (UIWindow *)rootWindow;

/*!
 *更新TabBarItems
 *@attention 其内部其实也重新设置了viewControllers
 *@param tabBarItemsAttributes tabBarItemsAttributes
 * [EN] Reloads the tab bar items with new attributes; view controllers are set again internally.
 * [CN] 使用新的属性数组刷新 TabBarItems，内部会重新设置 viewControllers。
 */
- (void)reloadTabBarItemsWithAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes;

/*!
 * [EN] Returns the visible tab bar size (see `-[UITabBar cyl_boundsSize]`).
 * [CN] 返回 TabBar 的可见尺寸（见 -[UITabBar cyl_boundsSize]）。
 */
- (CGSize)visiableTabBarSize;

/*!
 * [EN] Notifies that the selected tab changed to `control` and triggers the related callbacks. No effect in flat-design mode.
 * [CN] 通知选中 Tab 已切换到 control，并触发相关回调。扁平化模式下无效。
 */
- (void)tabChangedToControl:(UIControl *)control;
/*!
 * double-check if to use CYLTabBarStyleTypeLiquidGlass or not:
 * UIDesignCompatibility == FlatDesign , noNeedUIDesignCompatibility == noNeed FlatDesign == LiquidGlass
 * 设置为 NO，表示扁平化设计， 本属性相当于UI兼容模式的代码替代版本，仅仅在 iOS26+ 系统有效。
 * 由于 UI 兼容模式的命名晦涩， 更优雅直观的方式为 设置 CYLTabBarStyleType，其内部会设置该属性用于决定是否使用扁平设计。
 
 * @return means  CYLTabBarStyleType == CYLTabBarStyleTypeFlatDesign if return NO, means  CYLTabBarStyleType == CYLTabBarStyleTypeLiquidGlass if return YES;
 * @attention better switch to property CYLTabBarStyleType
 */
@property (nonatomic, assign) BOOL noNeedUIDesignCompatibility;

/*!
 * FIX: issue #653, #672 (iPhone Duo, iOS 27.1+)
 * [EN] Whether the system may show the bars in the vertical bar: a column on the leading or trailing edge that iOS 27.1
 *      uses on some devices, such as the folded iPhone Duo. Defaults to NO.
 *      - NO: CYLTabBarController returns `UIVerticalBarBehaviorDisabled` from `preferredVerticalBarBehavior`, so the tab
 *        bar stays at the bottom and the status bar stays horizontal. Exception (issue #672): a screen that overrides
 *        `preferredVerticalBarBehavior` itself (the selected view controller, or the top view controller of a selected
 *        navigation controller) still decides for itself, e.g. return `UIVerticalBarBehaviorAutomatic` to opt in.
 *      - YES: the system default behaviour, as in 1.99.65 and earlier. `UITabBarController` passes the choice to the
 *        selected view controller, so each screen can still opt out by overriding `preferredVerticalBarBehavior`.
 *      This is a convenience switch for UIKit's `preferredVerticalBarBehavior`; a subclass may override that property
 *      directly instead. Changes apply immediately: the setter calls `setNeedsUpdateOfVerticalBarConfiguration`.
 *      Not related to `tabBarController.sidebar.preferredPlacement` / `sidebar.isAvailable` (iOS 27): those choose between
 *      the tab bar and an iPad-style sidebar when there is room for one (regular width) and need the `UITab` API; the
 *      vertical bar is used in compact width, where the sidebar is not available.
 *      Status with YES: Liquid Glass style verified on the iPhone Duo simulator (layout, Lottie icons, badges, plus button,
 *      re-tap, long press and drag). FlatDesign style verified on the iPhone Duo simulator: the status bar moves to the
 *      trailing column and the FlatDesign bar stays at the bottom with its items centered across the full width
 *      (see `CYLFlatDesignTabBar.respectsVerticalStatusBarSafeArea`).
 *      Folded iPhone Duo, FlatDesign, vertical status bar with centered items:
 *          tabBarController.allowsVerticalBar = YES; // respectsVerticalStatusBarSafeArea keeps its default NO
 *      No effect below iOS 27.1 or when built with an SDK older than iOS 27.1.
 * [CN] 是否允许系统以竖向栏显示导航栏/TabBar：iOS 27.1 在部分设备（如 iPhone Duo 折叠状态）上把栏放到屏幕左/右侧的一列。默认 NO。
 *      - NO：CYLTabBarController 的 `preferredVerticalBarBehavior` 返回 `UIVerticalBarBehaviorDisabled`，TabBar 保持在底部、
 *        状态栏保持横向。例外（issue #672）：自己重写了 `preferredVerticalBarBehavior` 的页面（选中的控制器，或选中的导航控制器的
 *        栈顶控制器）仍由该页面决定，例如返回 `UIVerticalBarBehaviorAutomatic` 即可单独开启竖向栏。
 *      - YES：系统默认行为（与 1.99.65 及更早版本一致）。`UITabBarController` 把决定权交给当前选中的控制器，
 *        各页面仍可通过重写 `preferredVerticalBarBehavior` 关闭。
 *      本属性是 UIKit `preferredVerticalBarBehavior` 的便捷开关；子类也可以直接重写该属性。修改后无需其他调用，
 *      setter 内部会调用 `setNeedsUpdateOfVerticalBarConfiguration`。
 *      与 `tabBarController.sidebar.preferredPlacement` / `sidebar.isAvailable`（iOS 27）无关：后者在空间足够（regular 宽度）时
 *      在 TabBar 与 iPad 式侧边栏之间选择，并依赖 `UITab` API；竖向栏用于 compact 宽度，此时侧边栏不可用。
 *      设为 YES 时的验证情况：液态玻璃样式已在 iPhone Duo 模拟器验证（布局、Lottie 图标、角标、加号按钮、重复点击、长按与拖拽）；
 *      扁平样式已在 iPhone Duo 模拟器验证：状态栏移到右侧竖列，扁平 TabBar 留在底部，按钮铺满整个宽度并居中
 *      （见 `CYLFlatDesignTabBar.respectsVerticalStatusBarSafeArea`）。
 *      iPhone Duo 折叠、扁平样式，想要竖向状态栏且按钮居中：
 *          tabBarController.allowsVerticalBar = YES; // respectsVerticalStatusBarSafeArea 保持默认 NO
 *      iOS 27.1 以下或使用 iOS 27.1 以下 SDK 编译时无效。
 */
@property (nonatomic, assign) BOOL allowsVerticalBar;

@property (nonatomic, assign, getter=isLottieViewAdded, readonly) BOOL lottieViewAdded;

@property (nonatomic, strong, readonly) NSMutableArray<NSURL *> *lottieURLs;
@property (nonatomic, strong, readonly) NSMutableArray *lottieSizes;

#if CYL_FLATDESIGN_AVAILABLE

//TODO:  , CYLFlatDesignUITabBarControllerDelegate

// 代理
@property (nonatomic, weak, nullable) id<CYLTabBarControllerDelegate, CYLFlatDesignUITabBarControllerDelegate> delegate;

/**
 设置CYLFlatDesignTabBar显示或隐藏
 如果设置了 hidesBottomBarWhenPushed，则 hidesBottomBarWhenPushed 优先级更高
 */
@property (nonatomic, assign, getter=isTabBarHidden) BOOL tabBarHidden;

//@property (nonatomic, assign, readonly) CYLTabBarStyleType tabBarStyleType;

/*!
 * [EN] Shows or hides the flat-design tab bar, optionally animated. `hidesBottomBarWhenPushed` takes priority.
 * [CN] 显示或隐藏扁平化 TabBar，可选是否动画；hidesBottomBarWhenPushed 优先级更高。
 */
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated;

//@property (nonatomic, readonly) CYLFlatDesignTabBar *cyl_tabBar;

// tabBar内容高度，默认49.0，真实高度会加上view.safeAreaInsets.bottom安全区域
//@property (nonatomic, assign) CGFloat tabBarHeight;

/*!
 * [EN] Replaces `item` with `toItem` in the flat-design tab bar. Only works in flat-design mode.
 * [CN] 在扁平化 TabBar 中用 toItem 替换 item，仅在扁平化模式下生效。
 */
- (void)changeItem:(CYLFlatDesignTabBarItem *)item toItem:(CYLFlatDesignTabBarItem *)toItem;

/*!
 [EN] This can be left unset; the default is CYLTabBarController. If set, please implement the `+[CYLPlusButton tabBarContext]` method in CYLPlusButton and ensure consistency. If neither is implemented, the default is CYLTabBarController for both.
 
 [CN] 可以不设置， 默认为 CYLTabBarController，如果设置了，请实现 CYLPlusButton 里 的 `+[CYLPlusButton tabBarContext]` 并保持一致。如果两个都不是实现，默认为一致均为 CYLTabBarController
 */
//@property (nonatomic, copy, nullable) NSString *context;

//+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
//                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes;
//
//- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
//                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
//                            imageInsets:(UIEdgeInsets)imageInsets
//                titlePositionAdjustment:(UIOffset)titlePositionAdjustment;
//
//+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
//                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
//                                        imageInsets:(UIEdgeInsets)imageInsets
//                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment;
//
//- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
//                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
//                            imageInsets:(UIEdgeInsets)imageInsets
//                titlePositionAdjustment:(UIOffset)titlePositionAdjustment
//                                context:(NSString *)context;
//
//+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
//                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
//                                        imageInsets:(UIEdgeInsets)imageInsets
//                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment
//                                            context:(NSString *)context;

/*!
 * An array of the root view controllers displayed by the tab bar interface.
 */
//@property (nullable, nonatomic, copy) NSArray<__kindof UIViewController *> *viewControllers;

/*!
 * The Attributes of items which is displayed on the tab bar.
 */
//@property (nonatomic, readwrite, copy) NSArray<NSDictionary *> *tabBarItemsAttributes;

/*!
 * Customize UITabBar height
 */
//@property (nonatomic, assign) CGFloat tabBarHeight;

/*!
 * To set both UIBarItem image view attributes in the tabBar,
 * default is UIEdgeInsetsZero.
 */
//@property (nonatomic, readonly, assign) UIEdgeInsets imageInsets;

/*!
 * To set both UIBarItem label text attributes in the tabBar,
 * use the following to tweak the relative position of the label within the tab button (for handling visual centering corrections if needed because of custom text attributes)
 */
//@property (nonatomic, readonly, assign) UIOffset titlePositionAdjustment;

/*!
 * To set both Item label text attributes in the tabBar,
 * use the following to tweak the relative position of the label within the tab button (for handling visual centering corrections if needed because of custom text attributes)
 */
//@property (nonatomic, readonly, assign) UIOffset imagePositionAdjustment;

/*!
 * /// 如果用户设置的TabBarItemImageViewSize不合规，则依据父视图大小来调整，否则依据默认的imageView的大小来调整
 */
//@property (nonatomic, assign) BOOL adjustTabBarItemImageViewSizeDependOnSuperView;

//@property (nonatomic, strong) NSMutableArray<NSURL *> *lottieURLs;

//@property (nonatomic, strong) NSMutableArray *lottieSizes;

//@property (nonatomic, assign, getter=isLottieViewAdded) BOOL lottieViewAdded;

#endif

@end

@interface CYLTabBarController (CYLActiveTabBarController)

/*!
 * [EN] The most recently active CYLTabBarController whose `context` is `context` (any context when nil), or nil.
 *      Every CYLTabBarController that has view controllers is known, held weakly; the one that appeared last
 *      (`-viewWillAppear:`) is the most recently active. Precise when every tab bar controller has its own context, as
 *      several plus buttons need anyway; with a shared context (the default one) it is the last of them that appeared.
 * [CN] `context` 为指定值（nil 表示任意）的最近活跃的 CYLTabBarController，没有则为 nil。所有已设置 viewControllers 的
 *      CYLTabBarController 都会被弱引用记录；最后显示（`-viewWillAppear:`）的就是最近活跃的。每个 TabBarController 有自己的 context
 *      时（多个 PlusButton 本来就需要）结果是精确的；共用 context（默认 context）时，是其中最后显示的那个。
 */
+ (nullable CYLTabBarController *)cyl_tabBarControllerForContext:(nullable NSString *)context;

/*!
 * [EN] The most recently active CYLTabBarController, of any context: `+cyl_tabBarControllerForContext:` with nil.
 * [CN] 最近活跃的 CYLTabBarController（任意 context），即 `+cyl_tabBarControllerForContext:` 传 nil。
 */
+ (nullable CYLTabBarController *)cyl_activeTabBarController;

@end

@interface NSObject (CYLTabBarControllerReferenceExtension)

/*!
 * [EN] The CYLTabBarController of a system style (Default, System, LiquidGlass) `self` belongs to, made for several
 *      tab bar controllers (#414) rather than one:
 *      0. a system style CYLTabBarController is its own;
 *      1. the reference set with `-cyl_setTabBarController:`;
 *      2. where `self` is: a view controller's nearest tab bar controller above it; a view's, through the view controller
 *         that owns it (so a tab button or the plus button finds its own controller, not the root one);
 *      3. otherwise the most recently active one (`+cyl_activeTabBarController`), then, as before, the root view controller.
 *      Same lookup as `-cylflatdesign_tabBarController`, see `-cyl_tabBarControllerForStyleType:`.
 * [CN] `self` 所属的系统样式（Default、System、LiquidGlass）CYLTabBarController，按多个 TabBarController 的场景（#414）设计，而不是单例式：
 *      0. 系统样式的 CYLTabBarController 就是它自己；
 *      1. 通过 `-cyl_setTabBarController:` 设置的引用；
 *      2. `self` 所在的位置：ViewController 取上方最近的 TabBarController；View 通过拥有它的 ViewController 查找
 *         （因此 Tab 按钮或 PlusButton 找到的是自己的控制器，而不是根控制器）；
 *      3. 否则取最近活跃的那个（`+cyl_activeTabBarController`），最后与以前一样取根控制器。
 *      与 `-cylflatdesign_tabBarController` 使用同一个查找，见 `-cyl_tabBarControllerForStyleType:`。
 */
@property (nonatomic, setter=cyl_setTabBarController:) CYLTabBarController *cyl_tabBarController;

/*!
 * [EN] The lookup behind `-cyl_tabBarController` and `-cylflatdesign_tabBarController`, merged into one: the type picks
 *      the style family, `CYLTabBarStyleTypeFlatDesign` for flat design, any other value for the system styles
 *      (Default, System, LiquidGlass, as `-cyl_isSystemStyleTabBar` counts them). It falls back to the most recently
 *      active controller of that family. `-cylflatdesign_tabBarController` keeps returning nil instead, as before.
 * [CN] `-cyl_tabBarController` 与 `-cylflatdesign_tabBarController` 合并后的查找：类型决定样式类别，`CYLTabBarStyleTypeFlatDesign`
 *      表示扁平样式，其他任意值表示系统样式（Default、System、LiquidGlass，与 `-cyl_isSystemStyleTabBar` 的判断一致）。
 *      最后会回退到该类别中最近活跃的控制器；`-cylflatdesign_tabBarController` 则与以前一样返回 nil。
 */
- (nullable CYLTabBarController *)cyl_tabBarControllerForStyleType:(CYLTabBarStyleType)styleType;

/*!
 * [EN] The same lookup for a CYLTabBarController of any style, without a fallback: the one `self` is in (or is), nil if
 *      it is not inside one. The plus button registry uses it to find the context of a tab button, a view in a tab or a
 *      view controller.
 * [CN] 同一个查找，但不限样式、没有回退：`self` 所在（或本身就是）的 CYLTabBarController，不在任何一个之内时为 nil。
 *      PlusButton 注册表用它确定 Tab 按钮、Tab 内的 View 或 ViewController 的 context。
 */
- (nullable CYLTabBarController *)cyl_owningTabBarController;

#if CYL_FLATDESIGN_AVAILABLE

/*!
 * [EN] Flat design. The flat design CYLTabBarController `self` belongs to, nil if none. Same lookup as
 *      `-cyl_tabBarController` (`-cyl_tabBarControllerForStyleType:` with `CYLTabBarStyleTypeFlatDesign`), except that an
 *      explicit reference is returned as it is and there is no fallback, as before.
 * [CN] 扁平样式。`self` 所属的扁平样式 CYLTabBarController，没有则为 nil。与 `-cyl_tabBarController` 使用同一个查找
 *      （`-cyl_tabBarControllerForStyleType:` 传 `CYLTabBarStyleTypeFlatDesign`），区别是显式设置的引用原样返回、没有回退，与以前一致。
 */
@property (nullable, nonatomic, weak, getter=cylflatdesign_tabBarController, setter=cylflatdesign_setTabBarController:) UIViewController __kindof *cylflatdesign_tabBarController;

#endif

@end

#pragma mark - Deprecated API

@interface CYLTabBarController (CYLTabBarControllerDeprecated)

/*!
 * [EN] Deprecated. Use `-hideTabBarShadowImageView` instead.
 * [CN] 已废弃，请改用 -hideTabBarShadowImageView。
 */
- (void)hideTabBadgeBackgroundSeparator CYL_DEPRECATED("Deprecated in 1.27.0. Use `-[CYLTabBarController hideTabBarShadowImageView]` instead.");

@end

FOUNDATION_EXTERN NSString *const CYLTabBarItemLottieAnimationPlayingNotification;

// * 液态玻璃开关变化
 //TODO:  
 FOUNDATION_EXTERN NSString *const CYLTabBarStyleTypeDidChangeNotification;
// FxxOUNDATION_EXTERN NSString *const CYLTabBarDarkModeShowDarkDidChangeNotification;
FOUNDATION_EXTERN NSString *const CYLTabBarItemWidthDidChangeNotification;

NS_ASSUME_NONNULL_END

