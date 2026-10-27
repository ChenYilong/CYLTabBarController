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

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)

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

/** 可以不设置， 默认为 CYLTabBarController，如果设置了，请实现 CYLPlusButton 里 的 +[CYLPlusButton tabBarContext] 并保持一致。如果两个都不是实现，默认为一致均为 CYLTabBarController */
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
 * FIX: issue #653 (iPhone Duo, iOS 27.1+)
 * [EN] Whether the system may move the bars to the vertical edge (the "vertical bar") on devices that support it,
 *      such as the folded iPhone Duo. Defaults to NO: CYLTabBarController returns `UIVerticalBarBehaviorDisabled`,
 *      so the tab bar stays at the bottom and the status bar stays horizontal. The custom tab bar (plus button,
 *      Lottie items, FlatDesign bar) is laid out for a horizontal bar only; when the system moved it to the
 *      vertical edge, the Liquid Glass bar became a tall panel over the content and the FlatDesign bar shrank
 *      during push/pop. Set to YES to let the selected view controller decide (system default behaviour).
 *      No effect below iOS 27.1 or when built with an SDK older than iOS 27.1.
 * [CN] 是否允许系统把导航栏/TabBar 放到竖向边缘（竖向栏，如 iPhone Duo 折叠状态）。默认 NO：
 *      CYLTabBarController 返回 `UIVerticalBarBehaviorDisabled`，TabBar 保持在底部，状态栏保持横向。
 *      自定义 TabBar（加号按钮、Lottie、扁平 TabBar）只按横向布局；被系统放到竖向边缘时，
 *      液态玻璃 TabBar 会变成盖住内容的竖长面板，扁平 TabBar 在 push/pop 时会变矮。
 *      设为 YES 则交给当前选中的控制器决定（系统默认行为）。iOS 27.1 以下或使用 iOS 27.1 以下 SDK 编译时无效。
 */
@property (nonatomic, assign) BOOL allowsVerticalBar;

@property (nonatomic, assign, getter=isLottieViewAdded, readonly) BOOL lottieViewAdded;

@property (nonatomic, strong, readonly) NSMutableArray<NSURL *> *lottieURLs;
@property (nonatomic, strong, readonly) NSMutableArray *lottieSizes;

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)

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

@interface NSObject (CYLTabBarControllerReferenceExtension)

/*!
 * If `self` is kind of `UIViewController`, this method will return the nearest ancestor in the view controller hierarchy that is a tab bar controller. If `self` is not kind of `UIViewController`, it will return the `rootViewController` of the `rootWindow` as long as you have set the `CYLTabBarController` as the  `rootViewController`. Otherwise return nil. (read-only)
 */
@property (nonatomic, setter=cyl_setTabBarController:) CYLTabBarController *cyl_tabBarController;

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)

// 返回控制器的tabBarController，可能为nil
//TODO:  更换为统一的 cyl_tabBarController
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

