//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"
#import "CYLTabBarController+CYLPrivate.h"
#import "CYLTabBar.h"
#import "UIViewController+CYLSettingsSection.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarItemAnimation.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "NSObject+CYLTabBarControllerExtention.h"
// [EN] The animated item component (Core depends on it) gives the placeholder; the engine registry only with an animation
//      subspec (`CYL_ANIMATION_ENGINE_AVAILABLE`), looked up through the header search paths only.
// [CN] 动效组件（Core 依赖它）提供占位图；引擎注册表只在引入动画子库时存在（`CYL_ANIMATION_ENGINE_AVAILABLE`），只通过头文件搜索路径查找。
#if (defined(COCOAPODS) || defined(CYL_ANIMATED_ITEM_SEPARATE_MODULE)) && __has_include(<CYLAnimatedItem/CYLAnimatedItemView.h>)
#import <CYLAnimatedItem/CYLAnimatedItemView.h>
#elif __has_include("CYLAnimatedItem/CYLAnimatedItemView.h")
#import "CYLAnimatedItem/CYLAnimatedItemView.h"
#elif __has_include(<CYLAnimatedItem/CYLAnimatedItemView.h>)
#import <CYLAnimatedItem/CYLAnimatedItemView.h>
#else
#import "CYLAnimatedItemView.h"
#endif
#if CYL_ANIMATION_ENGINE_AVAILABLE
#if __has_include(<CYLTabBarController/CYLTabBarItemAnimatorRegistry.h>)
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimatorRegistry.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimatorRegistry.h>
#else
#import <CYLTabBarController/CYLTabBarItemAnimatorRegistry.h>
#endif
#else
#if __has_include(<CYLAnimatedItem/CYLTabBarItemAnimatorRegistry.h>)
#import <CYLAnimatedItem/CYLTabBarItemAnimatorRegistry.h>
#else
#import "CYLTabBarItemAnimatorRegistry.h"
#endif
#endif
#endif

/*
 * [EN] Whether a tab's animation file can play: an engine with an animator for its type. Without the engine nothing can.
 * [CN] Tab 的动画文件能否播放：有引擎且有该类型的 animator。没有引擎时都不能播放。
 */
FOUNDATION_EXTERN NSURL *_Nullable CYLTabBarItemAnimationURLOfAnyType(NSDictionary *_Nullable attributes);
// [EN] `CYLTabBarItemAnimationURLOfAnyType` is Swift (CYLTabBarController+CYLTabBarItemUpdate.swift, step 73).

// [EN] `CYLTabBarAnimationCanPlay` is Swift (step 76).



#if CYL_FLATDESIGN_AVAILABLE
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#import "CYLFlatDesignTabBar.h"

#else
#endif


//#import "CYLFlatDesignTabBarItem.h"
//#import "UINavigationController+CYLFlatDesignTabBarPrivate.h"
//#import "_CYLFlatDesignTabBarParallaxOverlayView.h"
//#import "CYLFlatDesignTabBarHideTabBar.h"


#if CYL_FLATDESIGN_AVAILABLE
//#import <CYLTabBarController/CYLTabBarController.h>
#import <CYLTabBarController/CYLFlatDesignTabBarItem.h>
#import <CYLTabBarController/UINavigationController+CYLFlatDesignTabBarPrivate.h>
#import <CYLTabBarController/_CYLFlatDesignTabBarParallaxOverlayView.h>
#import <CYLTabBarController/CYLFlatDesignTabBarHideTabBar.h>

#endif

#pragma mark - Animated images rest until played

// [EN] Selector-based keys, shared with Swift/CYLTabBarController+CYLAnimatedImages.swift (step 65). [CN] 基于 selector 的 key，与 Swift 共用（第 65 步）。
#define CYLTabBarItemAnimatedImageKey ((const void *)sel_registerName("cyl_tabBarItemAnimatedImage"))
#define CYLTabBarItemAnimatedSelectedImageKey ((const void *)sel_registerName("cyl_tabBarItemAnimatedSelectedImage"))

// [EN] `CYLRestingTabBarItemImage` is Swift: `+cyl_restingTabBarItemImage:forItem:selected:` (step 66). [CN] 已迁移到 Swift（第 66 步）。

// [EN] The template tint color, the tintable and animated icon views, and the frame player are Swift
//      (Swift/CYLTabBarController+CYLAnimatedImages.swift, docs/Swift-Migration.md, step 65). [CN] 已迁移到 Swift（第 65 步）。

#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
//#import <CYLTabBarController/CYLTabBarController.h>
//#import <CYLTabBarController/UIImage+CYLTabBarControllerExtention.h>
//#import <CYLTabBarController/NSObject+CYLTabBarControllerExtention.h>
#else
//#import "CYLTabBarController.h"
//#import "UIImage+CYLTabBarControllerExtention.h"
//#import "NSObject+CYLTabBarControllerExtention.h"
#endif

/// [EN] Set from `CYLPlusButtonShowsSelection` of a configuration. [CN] 由配置中的 `CYLPlusButtonShowsSelection` 设置。
#define CYLPlusButtonShowsSelectionKey ((const void *)sel_registerName("cyl_plusButtonShowsSelection"))
/// [EN] Private: marks a tab left out by `CYLTabBarItemPlatforms` / `CYLTabBarItemMinimumAppVersion` (set by the normalization).
/// [CN] 私有：标记被 `CYLTabBarItemPlatforms` / `CYLTabBarItemMinimumAppVersion` 排除的 Tab（由规范化设置）。
static NSString *const CYLTabBarItemExcludedKey = @"_CYLTabBarItemExcluded";
/// [EN] Private: set by the parameter initializers, which keep an empty view controller list (C9). [CN] 私有：由参数初始化方法设置，保持空的子控制器列表（C9）。
static NSString *const CYLTabBarControllerKeepsEmptyViewControllersKey = @"_CYLTabBarControllerKeepsEmptyViewControllers";

#pragma mark - Selected title (FIX: issue #433)

FOUNDATION_EXTERN void CYLRememberTabBarItemSelectedTitle(UIViewController *_Nullable viewController, NSDictionary *_Nullable attributes, NSString *_Nullable normalTitle);
FOUNDATION_EXTERN void CYLApplyTabBarItemSelectedTitles(CYLTabBarController *_Nullable tabBarController);
// [EN] `CYLRememberTabBarItemSelectedTitle` and `CYLApplyTabBarItemSelectedTitles` are Swift (CYLTabBarController+CYLTabBarItemUpdate.swift,
//      step 73), with their C names; the keys are selector-based (`cyl_tabBarItemSelectedTitle`, `cyl_tabBarItemNormalTitle`).
// [CN] 这两个函数已迁移到 Swift（第 73 步），保留 C 名称；key 基于 selector。

// [EN] `CYLSetNeedsUpdateTabBarItemSelectedTitles` is Swift (CYLTabBarController+CYLLifeCycle.swift, step 74). [CN] 已迁移到 Swift（第 74 步）。
FOUNDATION_EXTERN void CYLSetNeedsUpdateTabBarItemSelectedTitles(CYLTabBarController *_Nullable tabBarController);

#define CYLNavigationTitleFollowsTabBarItemTitleKey ((const void *)sel_registerName("cyl_navigationTitleFollowsTabBarItemTitle"))

// [EN] `CYLApplyNavigationTitleOfFollowingPage` is Swift: `+cyl_applyNavigationTitleOfFollowingPage:title:` (step 68). [CN] 已迁移到 Swift（第 68 步）。

// [EN] `CYLPostTabBarItemNotification` is Swift: `-cyl_postTabBarItemNotification:atIndex:extra:` (step 67). [CN] 已迁移到 Swift（第 67 步）。

// [EN] `CYLTabBarItemIconAttributes` is Swift: `+cyl_iconAttributesOfAttributes:` (step 68). [CN] 已迁移到 Swift（第 68 步）。

NSUInteger CYLTabbarItemsCount = 0;
NSUInteger CYLPlusButtonIndex = 0;
CGFloat CYLTabBarItemWidth = 0.0f;
CGFloat CYLTabBarHeight = 49.0f;
static const CGFloat kCYLDefaultTabBarHeight = 49.0f;

NSString *const CYLTabBarItemLottieAnimationPlayingNotification = @"CYLTabBarItemLottieAnimationPlayingNotification";
NSString *const CYLTabBarItemLottieAnimationViewDidAddNotification = @"CYLTabBarItemLottieAnimationViewDidAddNotification";
// [EN] The same values as the Lottie names, so both names reach the same observers. [CN] 与 Lottie 名称取值相同，两个名称对应同一批观察者。

NSString *const CYLTabBarStyleTypeDidChangeNotification = @"CYLTabBarStyleTypeDidChangeNotification";
static void * const CYLTabImageViewDefaultOffsetContext = (void*)&CYLTabImageViewDefaultOffsetContext;
static void * const CYLFlatDesignTabBarContext = (void*)&CYLFlatDesignTabBarContext;
/// The system tab bar's `standardAppearance` / `scrollEdgeAppearance`: synced to the tabs' title offsets (issue #475) and to
/// the flat design tab bar. 系统 TabBar 的 `standardAppearance` / `scrollEdgeAppearance`：同步到 Tab 的标题偏移（issue #475）与扁平样式 TabBar。
static void * const CYLStandardAppearanceContext = (void*)&CYLStandardAppearanceContext;
//static void * const CYLTabBarControllerVisiableItemsCountContext = (void*)&CYLTabBarControllerVisiableItemsCountContext;

// [EN] The classic hide / show duration and distance are Swift (CYLTabBarController+CYLTabBarHidden.swift, step 75).

#if CYL_FLATDESIGN_AVAILABLE

// [EN] `CYLSetAdditionalSafeAreaBottom` (FIX: issue #662) is Swift, in CYLTabBarController+CYLFlatDesign.swift (step 72).
#else
#endif

/*!
 * [EN] FIX: issue #91 — iOS 26 and later put the tab bar in a wrapper view only as tall as the bar, so UIKit never asks
 *      `-[CYLTabBar hitTest:withEvent:]` about a point above the bar: the raised part of the plus button and a touchable
 *      area grown with `touchableAreaOutsets` / `touchableAreaScale` went to the page behind (or to the scroll edge
 *      effect's touch blocker). This transparent view, in front of everything in the controller's view, asks the tab bar
 *      about points above the bar and keeps only the plus button (and its subviews); every other point returns nil, so
 *      the pages get their touches as before. The classic style and FlatDesign do not need it: their bar's superview is
 *      the controller's view, which already asks the tab bar.
 * [CN] FIX: issue #91 — iOS 26 及以上把 TabBar 放在只有 TabBar 高度的容器视图中，UIKit 不会就 TabBar 上方的点询问
 *      `-[CYLTabBar hitTest:withEvent:]`：PlusButton 凸出的部分、以及用 `touchableAreaOutsets` / `touchableAreaScale` 扩大的点击区域，
 *      触摸会交给后面的页面（或滚动边缘效果的触摸拦截视图）。这个透明视图位于控制器视图的最前面，就 TabBar 上方的点询问 TabBar，
 *      只保留 PlusButton（及其子视图）；其他点返回 nil，页面照常接收触摸。经典样式与扁平样式不需要它：其 TabBar 的父视图就是控制器的视图，
 *      已经会询问 TabBar。
 */
@interface CYLTabBarOverflowTouchView : UIView
@property (nonatomic, weak) UITabBar *tabBar;
@end

@implementation CYLTabBarOverflowTouchView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UITabBar *tabBar = self.tabBar;
    if (!tabBar.window || tabBar.hidden || tabBar.alpha < 0.01 || !tabBar.userInteractionEnabled
        || ![tabBar isKindOfClass:[CYLTabBar class]]) {
        return nil;
    }
    CGPoint tabBarPoint = [self convertPoint:point toView:tabBar];
    // [EN] On the bar itself UIKit already routes the touch. [CN] TabBar 本身范围内的触摸 UIKit 已经能正确分发。
    if ([tabBar pointInside:tabBarPoint withEvent:event]) {
        return nil;
    }
    UIView *plusButton = ((CYLTabBar *)tabBar).plusButton;
    if (!plusButton) {
        return nil;
    }
    UIView *hit = [tabBar hitTest:tabBarPoint withEvent:event];
    return [hit isDescendantOfView:plusButton] ? hit : nil;
}

@end

// [EN] `CYLTabBarControllerMemoryWarningSeam` (Swift, docs/Swift-Migration.md): lets the Swift memory warning demo read
//      `unloadsUnselectedViewsOnMemoryWarning` and `-shouldUnloadViewOfViewController:`; removed when this class is Swift.
// [CN] `CYLTabBarControllerMemoryWarningSeam`（Swift，docs/Swift-Migration.md）：让 Swift 版内存警告示例读取
//      `unloadsUnselectedViewsOnMemoryWarning` 与 `-shouldUnloadViewOfViewController:`；本类迁移到 Swift 后删除。
@interface CYLTabBarController () <UITabBarControllerDelegate, CYLTabBarControllerMemoryWarningSeam>

/// [EN] iOS 26+: routes points above the bar to the plus button (issue #91). [CN] iOS 26+：把 TabBar 上方的点交给 PlusButton（issue #91）。
@property (nonatomic, strong, nullable) CYLTabBarOverflowTouchView *cyl_overflowTouchView;

/// [EN] Page registry state (docs/Tab-Page-Registry.md): whether the tabs came from page IDs, the sources, the pages by
///      ID (for `-reloadTabBarItemsWithAttributes:`) and the skipped tabs.
/// [CN] 页面注册表状态（docs/Tab-Page-Registry.md）：Tab 是否来自页面 ID、页面来源、按 ID 分组的页面（供
///      `-reloadTabBarItemsWithAttributes:` 使用）与被跳过的 Tab。
@property (nonatomic, assign) BOOL pagesFromPageIdentifiers;
@property (nonatomic, strong, nullable) id<CYLTabBarPageProviding> pageRegistry;
@property (nonatomic, copy, nullable) CYLTabBarPageProvider pageResolver;
@property (nonatomic, copy, nullable) NSArray<CYLTabBarPageSource> *pageLookupOrder;
@property (nonatomic, strong, nullable) NSMutableDictionary<NSString *, NSMutableArray<UIViewController *> *> *pagesByPageIdentifier;
@property (nonatomic, copy) NSArray<CYLTabBarSkippedTab *> *skippedTabs;

@property (nonatomic, assign, getter=isObservingTabImageViewDefaultOffset) BOOL observingTabImageViewDefaultOffset;
/// [EN] Backing flag of `automaticallyAdjustsImageOnlyTabs`, negated so that the default (NO) means YES (issue #257, #522).
/// [CN] `automaticallyAdjustsImageOnlyTabs` 的存储标记，取反存储，使默认值 NO 表示 YES（issue #257、#522）。
@property (nonatomic, assign) BOOL cyl_imageOnlyTabsAdjustmentDisabled;
@property (nonatomic, assign, getter=shouldInvokeOnceViewDidLayoutSubViewsBlock) BOOL invokeOnceViewDidLayoutSubViewsBlock;
/// [EN] The control last reported through `tabBarController:didSelectControl:` in the current run loop turn (one report per tap).
/// [CN] 当前 runloop 中已通过 `tabBarController:didSelectControl:` 上报的控件（每次点击只上报一次）。
@property (nonatomic, weak) UIControl *cyl_controlReportedInCurrentRunLoop;
@property (nonatomic, strong) NSMutableArray<NSURL *> *tabBarItemAnimationURLs;
@property (nonatomic, strong) NSMutableArray *tabBarItemAnimationSizes;
@property (nonatomic, assign, getter=isTabBarItemAnimationViewAdded) BOOL tabBarItemAnimationViewAdded;
@property (nonatomic, strong) UIImage *tabItemPlaceholderImage;
@property (nonatomic, copy) NSString *context;
@property (nonatomic, strong) CYLTabBar *tabBar;
@property (nonatomic, assign, readonly) CGRect tabBarFrame;

#if CYL_FLATDESIGN_AVAILABLE
@property (nonatomic, strong) NSMutableArray<CYLFlatDesignTabBarItem *> *items;
@property (nonatomic, assign) BOOL cyl_tabBarHidden;
// [EN] Former instance variables (step 69): same backing names, so the Objective-C code reading `_name` is unchanged.
// [CN] 原先的实例变量（第 69 步）：后备变量名不变，读取 `_name` 的 Objective-C 代码无需修改。
#if CYL_FLATDESIGN_AVAILABLE
@property (nonatomic, assign) BOOL cylDelegateHasWillShowTabBar;
@property (nonatomic, assign) BOOL cylDelegateHasDidShowTabBar;
@property (nonatomic, assign) BOOL cylDelegateHasWillHideTabBar;
@property (nonatomic, assign) BOOL cylDelegateHasDidHideTabBar;
@property (nonatomic, assign) BOOL tabBarIsAnimating;
/// [EN] The last state of quick show / hide requests. [CN] 用于记录快速设置 tabBar 显示和隐藏最后一次的状态。
@property (nonatomic, assign) BOOL lastShowHideTabBar;
/// [EN] `animated` of the request queued while `_tabBarIsAnimating`; replayed with its own value.
/// [CN] 动画期间排队的那次请求自己的 animated 参数，动画结束后按它重放。
@property (nonatomic, assign) BOOL lastShowHideTabBarAnimated;
@property (nonatomic, assign) BOOL needsReloadItems;
@property (nonatomic, assign) BOOL cylDidRefreshSystemTabBarVisibility;
@property (nonatomic, assign) BOOL cylRefreshingSystemTabBarVisibility;
@property (nonatomic, assign) BOOL cylWaitingForVisibilityTransition;
@property (nonatomic, weak) UIWindow *cylRefreshedSystemTabBarWindow;
@property (nonatomic, strong) _CYLFlatDesignTabBarParallaxOverlayView *parallaxOverlayView;
#endif
//@property (nonatomic, assign) CYLTabBarStyleType tabBarStyleType;
//@property (nonatomic, readwrite) CYLFlatDesignTabBar *cyl_tabBar;
#else
#endif
// [EN] Outside every `#if`: the classic tab bar uses them in every build (step 69 had them inside the FlatDesign `#if`).
// [CN] 位于所有 `#if` 之外：经典 TabBar 在所有构建中都使用它们（第 69 步曾误放在 FlatDesign 的 `#if` 内）。
/// [EN] Classic tab bar before iOS 18: the animated `-setTabBarHidden:animated:` (see `-cyl_setClassicTabBarHidden:animated:`).
/// [CN] iOS 18 以前的经典 TabBar：带动画的 `-setTabBarHidden:animated:`（见 `-cyl_setClassicTabBarHidden:animated:`）。
@property (nonatomic, assign) BOOL cylClassicTabBarIsAnimating;
@property (nonatomic, assign) BOOL cylClassicTabBarHiddenRequest;
@property (nonatomic, assign) NSUInteger cylClassicTabBarAnimationGeneration;
@end


/// [EN] Asynchronous pages (docs/Tab-Page-Registry.md); implemented at the end of this file. [CN] 异步页面（docs/Tab-Page-Registry.md）；实现见本文件末尾。
@interface CYLTabBarController (CYLPendingPages)
- (void)cyl_adoptPendingPages;
- (void)cyl_placeholderDidFinishLoading:(UIViewController *)placeholder;
@end



/// [EN] Per-tab colors, implemented in the main implementation. [CN] 单个 Tab 的颜色，在主实现中实现。

/// Which tab bar controllers a lookup accepts; nil accepts any CYLTabBarController.
typedef BOOL (^CYLTabBarControllerMatcher)(CYLTabBarController *tabBarController);

/// Implemented below (CYLActiveTabBarController): the registry of live tab bar controllers.
/// FIX: issue #152 — implemented in `CYLTabBarController (CYLTabBarItemGesture)` below. 实现见下方的分类。


/// [EN] FIX: issue #535 — implemented in CYLTabBarController+CYLInteraction.m. [CN] 实现位于 CYLTabBarController+CYLInteraction.m。

/// FIX: issue #475, #95. `CYLRememberItemTitlePositionAdjustment()` / `CYLRememberItemImageInsets()` (the offset and insets a tab
/// asked for itself) are `@_cdecl` Swift since step 125 (Swift/CYLTabBarController+CYLItemAppearance.swift).
/// Tab 自身设置的标题偏移与图片内边距的记录函数自第 125 步起为 `@_cdecl` 的 Swift 函数。

/// FIX: issue #257, #522. What the automatic adjustment of image-only tabs wrote into an item; see
/// `-offsetTabBarTabImageViewToFit:`. 纯图标 Tab 自动调整写入 item 的记录，见 `-offsetTabBarTabImageViewToFit:`。
#define CYLImageOnlyTabAdjustmentKey ((const void *)sel_registerName("cyl_imageOnlyTabAdjustment"))
static NSString *const CYLImageOnlyTabOriginalInsetsKey = @"insets";
static NSString *const CYLImageOnlyTabAppliedInsetsKey = @"appliedInsets";
static NSString *const CYLImageOnlyTabOriginalTitleKey = @"title";
static NSString *const CYLImageOnlyTabAppliedTitleKey = @"appliedTitle";

// [EN] `CYLTabBarItemSetup` is a Swift class (CYLTabBarController+CYLTabBarItemSetup.swift, step 76), declared in +CYLPrivate.h.


/// [EN] Implemented in CYLTabBar.m: YES during More editing. [CN] 在 CYLTabBar.m 中实现：「More」编辑期间为 YES。
@interface CYLTabBar (CYLCustomizingItems)
@property (nonatomic, assign, readonly) BOOL cyl_isCustomizingItems;
@end

/*!
 * [EN] The object at `index`, or nil when `array` is nil or `index` is out of range. Used instead of `@try` / `@catch`
 *      around subscripts (under ARC an exception can leak).
 * [CN] 返回 `index` 处的对象；`array` 为 nil 或 `index` 越界时返回 nil。用来代替下标外的 `@try` / `@catch`（ARC 下抛出异常可能泄漏内存）。
 */
static inline id _Nullable CYLObjectAtIndex(NSArray * _Nullable array, NSUInteger index) {
    return index < array.count ? array[index] : nil;
}

// [EN] The icon rendering mode (FIX: issue #787) is Swift: `+cyl_imageInfosOfAttributes:applyingIconRenderingModeToImageInfo:selectedImageInfo:` (step 73).

// [EN] `-shouldUnloadViewOfViewController:` of `CYLTabBarControllerMemoryWarningSeam` is implemented in Swift (step 103), which
//      clang cannot see here; the class conforms at run time (`testMemoryWarningReportThroughTheSeam`).
// [CN] `CYLTabBarControllerMemoryWarningSeam` 的 `-shouldUnloadViewOfViewController:` 在 Swift 中实现（第 103 步），clang 在这里看不到；
//      运行时该类是遵守协议的（`testMemoryWarningReportThroughTheSeam`）。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wprotocol"
@implementation CYLTabBarController {
#pragma clang diagnostic pop
// [EN] The former instance variables are private properties below (class extension), with the same backing names,
//      so Swift extensions reach them through their accessors (docs/Swift-Migration.md, step 69).
// [CN] 原先的实例变量已改为下面类扩展中的私有属性，后备变量名不变，Swift 扩展可以通过存取方法访问它们（第 69 步）。
}

@synthesize viewControllers = _viewControllers;
@synthesize tabBarHeight = _tabBarHeight;
@synthesize cyl_tabBar = _cyl_tabBar;
// [EN] Implemented in Swift (step 58). [CN] 由 Swift 实现（第 58 步）。
@dynamic automaticallyAdjustsImageOnlyTabs;

/// [EN] The tab bar if one was set up, without creating one (Swift reads it). [CN] 已创建的 TabBar，不会新建（供 Swift 读取）。
- (nullable UIView *)cyl_storedTabBar {
    return _cyl_tabBar;
}
@synthesize selectedViewController = _selectedViewController;
@dynamic tabBar;

#if CYL_FLATDESIGN_AVAILABLE
//@synthesize viewControllers = _viewControllers;
@synthesize selectedIndex = _selectedIndex;
@dynamic delegate;

//@synthesize tabBarHeight = _tabBarHeight;
#else
#endif

#pragma mark -
#pragma mark - Life Cycle

// [EN] The life cycle and the tab change are Swift (Swift/CYLTabBarController+CYLLifeCycle.swift, step 74); the FlatDesign
//      `-_cyl_refreshSystemTabBarVisibilityIfNeeded` is in CYLTabBarController+CYLFlatDesign.swift. The UIKit overrides stay here
//      as one-line forwarders until the class is Swift: a public Swift override would put an extension of this class into the
//      generated header before the class.
// [CN] 生命周期与 Tab 切换已迁移到 Swift（第 74 步）；UIKit 重写在类迁移到 Swift 之前保留为一行转发。
- (void)viewWillAppear:(BOOL)animated { [self cyl_viewWillAppear:animated]; }
- (void)viewDidAppear:(BOOL)animated { [self cyl_viewDidAppear:animated]; }
- (void)viewWillDisappear:(BOOL)animated { [self cyl_viewWillDisappear:animated]; }
- (void)viewDidDisappear:(BOOL)animated { [self cyl_viewDidDisappear:animated]; }

- (void)setViewDidLayoutSubViewsBlock:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock {
    _viewDidLayoutSubviewsBlock = [viewDidLayoutSubviewsBlock copy];
}

#pragma mark - Reload badges (#404)

// [EN] `-reloadBadgesWithBlock:`, `-performWhenTabBarItemsReady:`, the pending blocks, `-cyl_adoptTabButton:forTabBarItem:`,
//      `-cyl_tabButtonReplacingTappedControl:` and `-cyl_bindTabControlActions` are Swift
//      (`Swift/CYLTabBarController+CYLReloadBadges.swift`, step 105).
// [CN] 上述方法已改为 Swift（`Swift/CYLTabBarController+CYLReloadBadges.swift`，第 105 步）。

#pragma mark - Plus button in the Liquid Glass layers

// [EN] `-cyl_layOutPlusButtonInLiquidGlassLayers` and its retry are Swift (Swift/CYLTabBarController+CYLInteraction.swift, step 70).
// [CN] `-cyl_layOutPlusButtonInLiquidGlassLayers` 及其重试已迁移到 Swift（第 70 步）。

/*!
 * FIX: issue #216
 * [EN] The theme callback of every view controller. The override stays here, in Objective-C: a public Swift override of it would put an
 *      extension of this class into the generated Swift header, before the class. The work is `-cyl_tabBarThemeDidChangeByManager:theme:`
 *      (CYLTabBarController+CYLTheme.swift).
 * [CN] 每个控制器的主题回调。重写保留在这里（Objective-C）：public 的 Swift 重写会让生成的 Swift 头文件在该类之前出现它的 extension。实际工作在
 *      `-cyl_tabBarThemeDidChangeByManager:theme:`（CYLTabBarController+CYLTheme.swift）。
 */
- (void)cyl_themeDidChangeByManager:(CYLThemeManager *)manager identifier:(nullable __kindof NSObject<NSCopying> *)identifier theme:(nullable __kindof NSObject *)theme {
    [super cyl_themeDidChangeByManager:manager identifier:identifier theme:theme];
    [self cyl_tabBarThemeDidChangeByManager:manager theme:theme];
}

#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
/*!
 * Issue #13
 * [EN] Apple's `tabBarMinimizeBehavior` is the same switch as `cyl_tabBarMinimizeBehavior`. The overrides stay here, in Objective-C, for
 *      the reason above; the work is in CYLTabBarController+CYLTabBarMinimize.swift.
 * [CN] Apple 的 `tabBarMinimizeBehavior` 与 `cyl_tabBarMinimizeBehavior` 是同一个开关。重写保留在这里（Objective-C），原因同上；实际工作在
 *      CYLTabBarController+CYLTabBarMinimize.swift。
 */
- (void)setTabBarMinimizeBehavior:(UITabBarMinimizeBehavior)tabBarMinimizeBehavior {
    if (@available(iOS 26.0, *)) {
        [self cyl_setSystemTabBarMinimizeBehaviorFromApp:tabBarMinimizeBehavior];
    }
}

- (UITabBarMinimizeBehavior)tabBarMinimizeBehavior {
    if (@available(iOS 26.0, *)) {
        return [self cyl_systemTabBarMinimizeBehaviorForApp];
    }
    return 0;
}
#endif

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // [EN] Lottie views are added during layout: start the looping ones (`CYLTabBarLottieLoopsWhenUnselected`).
    // [CN] Lottie 视图在布局时添加：启动需要循环播放的视图（`CYLTabBarLottieLoopsWhenUnselected`）。
    [self cyl_updateLoopingLottieViews];
    // [EN] Animation views added during layout get the tab's template tint (`CYLTabBarAnimationOptionTint`).
    // [CN] 布局时添加的动画视图获得 Tab 的模板着色。
    [self cyl_setNeedsApplyTabBarItemAnimationTintColors];
    // [EN] FIX: issue #535 — long press and swipe to switch tabs, once the view exists (every style).
    // [CN] FIX: issue #535 — view 已存在时安装长按与滑动切换手势（所有样式）。
    [self cyl_installInteractionGestureRecognizersIfNeeded];
    // [EN] FlatDesign `cyl_tabBarMinimizeBehavior` (issue #13): follow the scroll view of the page now on screen.
    // [CN] 扁平样式的 `cyl_tabBarMinimizeBehavior`（issue #13）：跟随当前显示页面的滚动视图。
    [self cyl_updateTabBarMinimizeTracking];
    // Issue #601: tab buttons created again (e.g. after a rotation) get their icon views again.
    [self cyl_setNeedsUpdateTabBarItemIconViews];
    [self cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded];
    // [EN] FIX: issue #91 — points above the bar reach the plus button on iOS 26+ too. [CN] iOS 26+ 上 TabBar 上方的点也能到达 PlusButton。
    [self cyl_updateOverflowTouchView];
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        // FIX: issue #585, #543 (follow-up to #93, #392)
        // [EN] The forced `-layoutSubviews` below is an iOS 10 workaround: #93 (iOS 10.0–10.2) and #392 (iOS 10.3.x, items
        //      misplaced next to the plus button) needed the tab bar laid out again after this controller. It later ran on
        //      every layout pass on every system. On iOS 11+ notched iPhones that re-laid the tab bar out synchronously in
        //      the middle of push/pop (#585: tab images flicker after `cyl_replaceTabImageView`) and rotation (#543: the tab
        //      bar flickers when turning from landscape to portrait). From iOS 11 UIKit lays the tab bar out itself, so skip
        //      it for the classic system tab bar on iOS 11 and later.
        //      Scope: the classic (pre-Liquid Glass) system tab bar, i.e. iOS 25 and earlier plus iOS 26 in UI compatibility
        //      mode (`UIDesignRequiresCompatibility`); `+[CYLConstants isLiquidGlassActive]` is NO exactly then. Liquid Glass
        //      (iOS 26 without compatibility mode, every iOS 27+ system, the iPhone Duo) keeps the previous behavior, and
        //      FlatDesign never reaches this code.
        // [CN] 下面强制调用 `-layoutSubviews` 是针对 iOS 10 的处理：#93（iOS 10.0–10.2）与 #392（iOS 10.3.x，PlusButton 旁的 item
        //      位置错误）需要在本控制器布局后再布局一次 TabBar。之后它在所有系统的每次布局中都会执行，iOS 11+ 刘海屏上会在
        //      push/pop（#585：调用 `cyl_replaceTabImageView` 后 Tab 图片闪动）和旋转（#543：横屏转竖屏时 TabBar 闪动）过程中
        //      同步地重新布局 TabBar。iOS 11 起 UIKit 会自行布局 TabBar，因此 iOS 11 及以上的经典系统 TabBar 不再执行。
        //      范围：经典（液态玻璃之前的）系统 TabBar，即 iOS 25 及以前，以及 iOS 26 的 UI 兼容模式
        //      （`UIDesignRequiresCompatibility`），此时 `+[CYLConstants isLiquidGlassActive]` 恰好为 NO。液态玻璃（未开启兼容模式
        //      的 iOS 26、所有 iOS 27+、iPhone Duo）保持原有行为；扁平样式不会执行到这里。
        BOOL isClassicSystemTabBar = ![CYLConstants isLiquidGlassActive];
        BOOL needsIOS10Workaround = !CYL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0");
        if (!isClassicSystemTabBar || needsIOS10Workaround) {
            [self.cyl_tabBar layoutSubviews];//Fix issue #93 #392
        }
        if ([self.cyl_tabBar isKindOfClass:[CYLTabBar class]] ) {
            CYLTabBar *tabBar = (CYLTabBar *)self.cyl_tabBar;
            [self cyl_bindTabControlActions];
            // VoiceOver: the tab under the plus button has no title, so it was read as an empty tab.
            // 加号按钮下方的占位 Tab 没有标题，VoiceOver 会读成空 Tab。
            // [EN] Also the plus button's own view controller: its tab item has no title when the plus button keeps its
            //      title (e.g. drawn on its background image).
            // [CN] PlusButton 自己的子控制器也一样：PlusButton 保留自己的标题时（如画在背景图上），其 TabBarItem 没有标题。
            UIViewController *plusChildViewController = [CYLPlusButton plusChildViewControllerForOwner:self];
            for (UIViewController *viewController in self.viewControllers) {
                if (viewController.cyl_isPlaceholder) {
                    // Classic tab bar: the button is the element. Liquid Glass: the element comes from the item, which
                    // then reads as the plus button it is covered by (a tap on it is forwarded to the plus button).
                    viewController.cyl_tabButton.accessibilityElementsHidden = YES;
                    viewController.cyl_tabButton.isAccessibilityElement = NO;
                } else if (viewController != plusChildViewController || viewController.tabBarItem.title.length > 0) {
                    continue;
                }
                viewController.tabBarItem.accessibilityLabel = [self cyl_contextPlusButton].accessibilityLabel;
            }
        
            do {
                if (self.isTabBarItemAnimationViewAdded) {
                    break;
                }
                BOOL isLottieEnabled = [self isLottieEnabled];
            
                // FIX: issue #477 — only some tabs may have an animation (Lottie or PAG): each tab takes its own file
                // (`-addLottieImageWithControl:…`), and the others keep their images. The classic tab bar used to need one
                // file per tab button and turned every animation off otherwise. 只有部分 Tab 有动画（Lottie 或 PAG）时，
                // 每个 Tab 使用自己的文件，其余 Tab 保持图片。经典 TabBar 以前要求每个 Tab 按钮都有文件，否则关闭全部动画。
                if (!isLottieEnabled) {
                    self.tabBarItemAnimationViewAdded = YES;
                    break;
                }
                [self initLottieTabBar:tabBar];
                break;
            } while (NO);
        }
    
    
        // [EN] The plus button in the Liquid Glass layers; also run from `-[CYLTabBar layoutSubviews]`, see the method.
        // [CN] 液态玻璃图层中的 PlusButton；`-[CYLTabBar layoutSubviews]` 中也会调用，见该方法。
        [self cyl_layOutPlusButtonInLiquidGlassLayers];
    

    } else {/**  CYLTabBarStyleTypeFlatDesign*/}

    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (!_tabBarIsAnimating && !CGRectEqualToRect(self.cyl_tabBar.frame, self.tabBarFrame) && self.cyl_tabBar.superview == self.view) {
            //目的是动态更新tabbar高度 ， 测试方法为 修改 tabBarController.tabBarHeight ， 预期为实时跟新UI中的tabbar高度。// The goal is to dynamically update the tab bar height. The test method involves modifying `tabBarController.tabBarHeight`; the expected result is that the tab bar height in the UI updates in real time.
            self.cyl_tabBar.frame = self.tabBarFrame;
        }
        [self _cyl_refreshSystemTabBarVisibilityIfNeeded];

#else
#endif
    } else {}


    [self cyl_runPendingReloadBadgesBlocksIfReady];

    if (self.shouldInvokeOnceViewDidLayoutSubViewsBlock) {
        // [CN] 在对象生命周期内，不添加 flag 属性的情况下，防止多次调进这个方法
        // [EN] Prevents this method from being called more than once during the object's lifetime, without adding a
        //      flag property
        if (objc_getAssociatedObject(self, _cmd)) {
            return;
        } else {
            !self.viewDidLayoutSubviewsBlock ?: self.viewDidLayoutSubviewsBlock(self);
            objc_setAssociatedObject(self, _cmd, @"shouldInvokeOnceViewDidLayoutSubViewsBlock", OBJC_ASSOCIATION_RETAIN);
        }
    } else {
        !self.viewDidLayoutSubviewsBlock ?: self.viewDidLayoutSubviewsBlock(self);
    }

}

/*!
 * [EN] FIX: issue #91 — installs `CYLTabBarOverflowTouchView` in front of the controller's view while the tab bar lives in
 *      a wrapper view of its own (iOS 26 and later), and removes it otherwise.
 * [CN] FIX: issue #91 — TabBar 位于自己的容器视图中时（iOS 26 及以上）在控制器视图最前面安装 `CYLTabBarOverflowTouchView`，否则移除。
 */
- (void)cyl_updateOverflowTouchView {
    UITabBar *tabBar = self.tabBar;
    BOOL needed = self.isViewLoaded && tabBar.superview && tabBar.superview != self.view;
    CYLTabBarOverflowTouchView *touchView = self.cyl_overflowTouchView;
    if (!needed) {
        [touchView removeFromSuperview];
        self.cyl_overflowTouchView = nil;
        return;
    }
    if (!touchView) {
        touchView = [[CYLTabBarOverflowTouchView alloc] initWithFrame:self.view.bounds];
        touchView.backgroundColor = UIColor.clearColor;
        touchView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        touchView.accessibilityElementsHidden = YES;   // [EN] Not a control: VoiceOver reads the plus button. [CN] 不是控件：VoiceOver 读 PlusButton。
        self.cyl_overflowTouchView = touchView;
    }
    touchView.tabBar = tabBar;
    if (touchView.superview != self.view) {
        [self.view addSubview:touchView];
    } else if (self.view.subviews.lastObject != touchView) {
        [self.view bringSubviewToFront:touchView];
    }
    touchView.frame = self.view.bounds;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self cyl_startObservingStandardAppearance];
    [self cyl_syncTabBarAppearances];
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if ([CYLConstants isLiquidGlassActive]) {
        //如果不是扁平设计风格，也就是液态玻璃不支持自定义高度， 液态玻璃系统样式是固定高度的。// Unless it's a flat design style—in which case Liquid Glass does not support custom heights—the Liquid Glass system style has a fixed height.
        return;
    }
    if (0 == self.tabBarHeight) {
        return;
    }
    self.cyl_tabBar.frame = ({
        CGRect frame = self.cyl_tabBar.frame;
        CGFloat tabBarHeight = self.tabBarFrame.size.height;
        frame.size.height = tabBarHeight;
        // FIX: issue #591
        // [EN] Use `bounds`, not `frame`: the tab bar is laid out in this view's own coordinate space, while `frame` is in
        //      the superview's and includes the view's transform. A custom transition that scales the outgoing view
        //      (`fromView.transform = CGAffineTransformMakeScale(...)`) shrinks `frame.size.height`, which moved the tab bar
        //      up. Newer systems relaid the tab bar afterwards and hid the error; iOS 12 did not. `bounds` also matches
        //      `-tabBarFrame`, and unlike the screen height it is right in Split View / Stage Manager.
        //      Scope: Liquid Glass returns above and FlatDesign never reaches here; elsewhere `bounds` equals the old value
        //      unless the view has a transform, so no version guard is needed.
        // [CN] 使用 `bounds` 而不是 `frame`：TabBar 布局在本视图自身的坐标系中，`frame` 则在父视图坐标系中，并且包含视图的 transform。
        //      自定义转场缩放 from 页面（`fromView.transform = CGAffineTransformMakeScale(...)`）时 `frame.size.height` 变小，
        //      TabBar 因此被上移。高版本系统随后会重新布局 TabBar，掩盖了该问题，iOS 12 不会。`bounds` 也与 `-tabBarFrame` 一致，
        //      且与屏幕高度不同，在分屏 / 台前调度下同样正确。
        //      范围：液态玻璃已在上方返回，扁平样式不会执行到这里；其他情况下除非视图有 transform，`bounds` 与原值相同，无需版本判断。
        frame.origin.y = CGRectGetHeight(self.view.bounds) - tabBarHeight;
        frame;
    });
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/*!
 * [EN] The view controller that decides the orientation now: one presented by this controller (not while it is being
 *      dismissed, and never a `UIAlertController`, which asks its presenting view controller back and would loop), else
 *      nil (the selected tab decides, below). The system's full screen video player (`AVFullScreenViewController`) is
 *      presented too, so a video can turn to landscape in a portrait app.
 * [CN] 当前决定方向的控制器：由本控制器 present 出的控制器（正在 dismiss 时除外，且不包括 `UIAlertController`：它会反过来询问
 *      presenting 控制器，造成循环），否则为 nil（由选中的 Tab 决定，见下方）。系统的全屏视频播放器（`AVFullScreenViewController`）
 *      同样是 present 出来的，因此竖屏 App 中的视频也能横屏。
 */
- (nullable UIViewController *)cyl_presentedViewControllerForOrientation {
    UIViewController *presentedViewController = self.presentedViewController;
    if (!presentedViewController || presentedViewController.isBeingDismissed ||
        presentedViewController.presentingViewController != self ||
        [presentedViewController isKindOfClass:[UIAlertController class]]) {
        return nil;
    }
    return presentedViewController;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
/// [EN] Asks the presented view controller, else the selected tab (the top of its navigation stack).
/// [CN] 询问 present 出的控制器，否则询问选中的 Tab（其导航栈的栈顶）。
- (BOOL)shouldAutorotate {
    UIViewController *presentedViewController = [self cyl_presentedViewControllerForOrientation];
    if (presentedViewController) {
        return presentedViewController.shouldAutorotate;
    }
    UIViewController *controller = self.selectedViewController;
    if ([controller isKindOfClass:[UINavigationController class]]) {
        controller = ((UINavigationController *)controller).topViewController;
    }
    return controller ? controller.shouldAutorotate : YES;
}
#pragma clang diagnostic pop

/// [CN] 控制器支持方向
/// [EN] Orientations supported by the view controller
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    UIViewController *presentedViewController = [self cyl_presentedViewControllerForOrientation];
    if (presentedViewController) {
        return presentedViewController.supportedInterfaceOrientations;
    }
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        UIViewController *controller = self.selectedViewController;
        if ([controller isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)controller;
            return navigationController.topViewController.supportedInterfaceOrientations;
        } else {
            return controller.supportedInterfaceOrientations;
        }
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if ([_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {     return self.selectedViewController.supportedInterfaceOrientations; }
        return self.selectedViewController.supportedInterfaceOrientations;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/ }
    return self.selectedViewController.supportedInterfaceOrientations;
}

#pragma mark - Memory warning (issue #426)

// [EN] `-shouldUnloadViewOfViewController:`, `cyl_keepsLoadedTabBarItemIdentifiers` and `-unloadViewsOfUnselectedViewControllers`
//      are Swift (`Swift/CYLTabBarController+CYLMemoryWarning.swift`, step 103); this override only calls them.
// [CN] 上述方法已改为 Swift（`Swift/CYLTabBarController+CYLMemoryWarning.swift`，第 103 步）；本重写只调用它们。
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    if (self.unloadsUnselectedViewsOnMemoryWarning) {
        [self unloadViewsOfUnselectedViewControllers];
    }
}

- (void)dealloc {
    // Whatever the style is now: the style can change after the observation started.
    // 与当前样式无关：开始观察后样式可能已改变。
    [self cyl_stopObservingStandardAppearance];
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
        // `-removePlusButtonIfNeeded` used to run here: it removed the registered plus button when its context differed from
        // this controller's, which with several tab bar controllers (each with its own plus button) unregistered a plus
        // button that another controller still shows. A controller only uses the plus button of its own context
        // (`-hasPlusButton`, so the contexts were equal and it removed nothing). Removed (#414).
        // 这里原先会执行 `-removePlusButtonIfNeeded`：当已注册 PlusButton 的 context 与本控制器不同时将其移除，存在多个 TabBarController
        // （各自有自己的 PlusButton）时，会注销另一个控制器仍在展示的 PlusButton。控制器只使用自己 context 的 PlusButton
        // （`-hasPlusButton`，因此 context 本来就相同，什么也不会移除）。已删除（#414）。
        /// MARK: 这里是全局处理，如果生成新的，这里操作时会破坏新的视图展示
        //    BOOL isAdded = [self isPlusViewControllerAdded:_viewControllers];
        //    BOOL hasPlusChildViewController = [self hasPlusChildViewController] && isAdded;
        //    if (isAdded && hasPlusChildViewController && [self cyl_contextPlusChildViewController].cyl_plusViewControllerEverAdded == YES) {
        //        [[self cyl_contextPlusChildViewController] cyl_setPlusViewControllerEverAdded:NO];
        //    }
        // [CN] KVO反注册
        // [EN] Remove KVO observers
        [self cyl_stopObservingTabImageViewDefaultOffset];
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}

    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        [self cyl_removeObserver:self forKeyPath:@"cyl_tabBar" context:CYLFlatDesignTabBarContext];
#else
#endif
    } else { }
}

#pragma mark - Overrides

// [EN] Hiding the tab bar and the delegate are Swift (Swift/CYLTabBarController+CYLTabBarHidden.swift; the FlatDesign parts and
//      `-_checkHidesBottomBarWhenPushed` in CYLTabBarController+CYLFlatDesign.swift; step 75). The UIKit overrides stay as
//      one-line forwarders until the class is Swift.
// [CN] 隐藏 TabBar 与 delegate 已迁移到 Swift（第 75 步）；UIKit 重写在类迁移到 Swift 之前保留为一行转发。
- (BOOL)isTabBarHidden { return [self cyl_isTabBarHidden]; }
- (void)setTabBarHidden:(BOOL)tabBarHidden { [self cyl_setTabBarHidden:tabBarHidden animated:NO]; }
- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated { [self cyl_setTabBarHidden:hidden animated:animated]; }
#if CYL_FLATDESIGN_AVAILABLE
- (void)setDelegate:(id<CYLTabBarControllerDelegate, CYLFlatDesignUITabBarControllerDelegate>)delegate { [self cyl_setDelegate:delegate]; }
#else
- (void)setDelegate:(id<CYLTabBarControllerDelegate>)delegate { [self cyl_setDelegate:delegate]; }
#endif

/// [EN] Reads the attributes of the tab item at `idx` for `viewController` (and sets its identifier, #408).
/// [CN] 读取 `idx` 处 Tab item 的属性（并设置 `viewController` 的标识，#408）。
// [EN] `-cyl_tabBarItemSetupForViewController:idx:` (every style) is Swift (CYLTabBarController+CYLTabBarItemSetup.swift) and the
//      FlatDesign `-setupChildViewController:idx:` is in CYLTabBarController+CYLFlatDesign.swift (step 76).
// [CN] 已迁移到 Swift（第 76 步）。

/**
 * [CN] 添加一个子控制器
 * [EN] Add a child view controller
 *
 * @param viewController    [EN] View controller. [CN] 控制器。
 * @param title             [EN] Title. [CN] 标题。
 * @param normalImageInfo   [EN] Image. [CN] 图片。
 * @param selectedImageInfo [EN] Selected image. [CN] 选中图片。
 */
- (void)addOneChildViewController:(UIViewController *)viewController
                              idx:(NSUInteger)idx
                        WithTitle:(NSString *)title
                  normalImageInfo:(id)normalImageInfo
                selectedImageInfo:(id)selectedImageInfo
          titlePositionAdjustment:(UIOffset)titlePositionAdjustment
          imagePositionAdjustment:(UIOffset)imagePositionAdjustment
                      imageInsets:(UIEdgeInsets)imageInsets
                        lottieURL:(nullable NSURL *)lottieURL
                   lottieFilePath:(NSString *)lottieFilePath
                  lottieSizeValue:(NSValue *)lottieSizeValue {
    
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
                
        UIImage *normalImage = [UIImage cyl_imageNamed:normalImageInfo];
                
        UIImage *selectedImage = [UIImage cyl_imageNamed:selectedImageInfo];;
                
        UIEdgeInsets insets = self.imageInsets;
        BOOL shouldCustomizeImageInsets = !(UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, imageInsets));
        if (shouldCustomizeImageInsets) {
            insets = imageInsets;
        }
                
        UIOffset titleoffset = self.titlePositionAdjustment;
        BOOL shouldCustomizeTitlePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, titlePositionAdjustment));
        if (shouldCustomizeTitlePositionAdjustment) {
            titleoffset = titlePositionAdjustment;
        }
                
        UIOffset imageoffset = self.imagePositionAdjustment;
        BOOL shouldCustomizeImagePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, imagePositionAdjustment));
        if (shouldCustomizeImagePositionAdjustment) {
            imageoffset = imagePositionAdjustment;
        }
                
        if (lottieURL) {
            [self.tabBarItemAnimationURLs addObject:lottieURL];
            NSValue *tureLottieSizeValue = [CYLConstants cyl_tabBarItemAnimationSizeValue:lottieSizeValue fromNormalImage:normalImage];
            [self.tabBarItemAnimationSizes addObject:tureLottieSizeValue];
        }        // [CN] cyl_setTabBarItem 方法内部需要获取到tabbarvc但是， cyl_setTabBarItem是在初始化完成前的配置， 所以需要手动指定tabbarvc，否则cyl_setTabBarItem会初始化失败。
        // [EN] cyl_setTabBarItem needs the tabbarvc internally, but cyl_setTabBarItem is configured before
        //      initialization is complete,
        //      so the tabbarvc must be specified manually, otherwise cyl_setTabBarItem fails to initialize.
        CYLFlatDesignTabBarItem *cyl_tabBarItem = [[CYLFlatDesignTabBarItem alloc] initWithTitle:title
                                                                                           image:normalImage
                                                                                   selectedImage:selectedImage
                                                                                           index:idx
                                                                         titlePositionAdjustment:titleoffset
                                                                         imagePositionAdjustment:imageoffset
                                                                                     imageInsets:insets
                                                                                  lottieFilePath:lottieFilePath
                                                                                 lottieSizeValue:lottieSizeValue];
        cyl_tabBarItem.lottieURL = lottieURL;
        CYLRememberItemTitlePositionAdjustment(cyl_tabBarItem, titlePositionAdjustment);
        CYLRememberItemImageInsets(cyl_tabBarItem, imageInsets);

        [cyl_tabBarItem cylflatdesign_setTabBarController:self];
        cyl_tabBarItem.childViewController = viewController;
        [cyl_tabBarItem setTitleTextAttributes:
         @{
            NSForegroundColorAttributeName : UIColor.systemYellowColor
        }
                                      forState:UIControlStateSelected];
                
        [viewController cyl_setTabBarItem:cyl_tabBarItem];
        //    [self.items addObject:cyl_tabBarItem];
        //    [self addChildViewController:viewController];
            
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/    }
    
}



#pragma mark -
#pragma mark - public Methods
- (nonnull instancetype)initWithViewControllers:(nonnull NSArray<__kindof UIViewController *> *)viewControllers
                          tabBaritemsAttributes:(nonnull NSArray<NSDictionary *> *)tabBarItemsAttributes {
    return [self initWithViewControllers:viewControllers tabBarItemsAttributes:tabBarItemsAttributes];
}

- (nonnull instancetype)initWithViewControllers:(nonnull NSArray<__kindof UIViewController *> *)viewControllers
                          tabBarItemsAttributes:(nonnull NSArray<NSDictionary *> *)tabBarItemsAttributes {
    NSString *context = nil;
    CYLTabBarStyleType type = CYLTabBarStyleTypeDefault;
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:UIEdgeInsetsZero
                 titlePositionAdjustment:UIOffsetZero
                               styleType:type
                                 context:context];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    NSString *context = nil;
    CYLTabBarStyleType type = CYLTabBarStyleTypeDefault;
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:imageInsets
                 titlePositionAdjustment:titlePositionAdjustment
                               styleType:type
                                 context:context];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                context:(nullable NSString *)context {
    CYLTabBarStyleType type = CYLTabBarStyleTypeDefault;
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:imageInsets
                 titlePositionAdjustment:titlePositionAdjustment
                               styleType:type
                                 context:context];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                              styleType:(CYLTabBarStyleType)styleType
                                context:(nullable NSString *)context {
    return [self initWithViewControllers:viewControllers
                   tabBarItemsAttributes:tabBarItemsAttributes
                             imageInsets:UIEdgeInsetsZero
                 titlePositionAdjustment:UIOffsetZero
                               styleType:styleType
                                 context:context];
}

- (instancetype)initWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                  tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                            imageInsets:(UIEdgeInsets)imageInsets
                titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                              styleType:(CYLTabBarStyleType)styleType
                                context:(nullable NSString *)context {
    // [EN] Every initializer ends here, with its parameters as one configuration.
    // [CN] 所有初始化方法都汇集到这里，参数组成一个配置字典。
    NSMutableDictionary<NSString *, id> *configuration = [NSMutableDictionary dictionary];
    configuration[CYLTabBarControllerViewControllers] = viewControllers ?: @[];
    configuration[CYLTabBarControllerTabBarItemsAttributes] = tabBarItemsAttributes ?: @[];
    configuration[CYLTabBarControllerImageInsets] = [NSValue valueWithUIEdgeInsets:imageInsets];
    configuration[CYLTabBarControllerTitlePositionAdjustment] = [NSValue valueWithUIOffset:titlePositionAdjustment];
    configuration[CYLTabBarControllerStyleType] = @(styleType);
    configuration[CYLTabBarControllerContext] = context;
    // These initializers keep an empty view controller list empty (C9 is for configurations).
    // 这些初始化方法保持空的子控制器列表不变（C9 只针对配置）。
    configuration[CYLTabBarControllerKeepsEmptyViewControllersKey] = @YES;
    return [self initWithConfiguration:configuration];
}

+ (instancetype)tabBarControllerWithConfiguration:(NSDictionary<NSString *, id> *)configuration {
    return [[self alloc] initWithConfiguration:configuration];
}

/// [EN] Private: the reason of a left-out tab; the same key as in CYLTabBarController+CYLConfiguration.m. [CN] 私有：被排除的 Tab 的原因；与 CYLTabBarController+CYLConfiguration.m 中的键相同。
static NSString *const CYLTabBarItemExclusionReasonKey = @"_CYLTabBarItemExclusionReason";

// [EN] `CYLResolvableTabs()` and `CYLPagesByPageIdentifier()` are Swift (`+cyl_resolvableTabs:skipped:`,
//      `+cyl_pagesByPageIdentifierOfPages:tabs:`, step 126). [CN] 已改为 Swift（第 126 步）。

/*!
 * [EN] The lookup order of a normalized configuration: `CYLTabBarControllerPageLookupOrder` (else the default), without
 *      "automatic" when `CYLTabBarControllerAutomaticPageRegistration` is NO.
 * [CN] 规范化配置的查找顺序：`CYLTabBarControllerPageLookupOrder`（否则默认顺序）；`CYLTabBarControllerAutomaticPageRegistration` 为 NO 时
 *      去掉 "automatic"。
 */
static NSArray<CYLTabBarPageSource> *CYLPageLookupOrderOfConfiguration(NSDictionary<NSString *, id> *normalized) {
    NSArray<CYLTabBarPageSource> *order = [normalized[CYLTabBarControllerPageLookupOrder] isKindOfClass:[NSArray class]]
        ? normalized[CYLTabBarControllerPageLookupOrder] : CYLTabBarPageRegistry.defaultPageLookupOrder;
    id automatic = normalized[CYLTabBarControllerAutomaticPageRegistration];
    if (automatic && ![automatic boolValue]) {
        NSMutableArray<CYLTabBarPageSource> *withoutAutomatic = [order mutableCopy];
        [withoutAutomatic removeObject:CYLTabBarPageSourceAutomaticRegistration];
        order = withoutAutomatic;
    }
    return [order copy];
}

- (instancetype)initWithConfiguration:(NSDictionary<NSString *, id> *)configuration {
#if defined(DEBUG) || defined(BETA)
    if (![NSThread isMainThread]) {
        NSLog(@"🔴 CYLTabBarController: created off the main thread; UIKit objects must be created on the main thread.");
    }
#endif
    NSDictionary<NSString *, id> *normalized = [CYLTabBarController cyl_normalizedConfiguration:configuration ?: @{}];
    NSArray<NSDictionary *> *tabBarItemsAttributes = normalized[CYLTabBarControllerTabBarItemsAttributes] ?: @[];
    NSArray<UIViewController *> *viewControllers = normalized[CYLTabBarControllerViewControllers];
    if (viewControllers.count == 0 && ![normalized[CYLTabBarControllerKeepsEmptyViewControllersKey] boolValue]) {
        // An empty list (or one with no valid view controller) is treated as missing (C9). 空列表（或没有有效控制器的列表）视为未提供（C9）。
        viewControllers = nil;
    }
    BOOL viewControllersFromCode = (viewControllers != nil);
    NSMutableArray<CYLTabBarSkippedTab *> *skippedTabs = [NSMutableArray array];
    id<CYLTabBarPageProviding> pageRegistry = nil;
    CYLTabBarPageProvider pageResolver = nil;
    NSArray<CYLTabBarPageSource> *pageLookupOrder = nil;
    if (!viewControllersFromCode) {
        // Created from the page IDs: placeholders (B4), left-out tabs (B22) and tabs without a page (C11) are skipped and
        // listed in `cyl_skippedTabs`. 根据页面 ID 创建：跳过占位（B4）、被排除的 Tab（B22）与没有页面的 Tab（C11），记录在 `cyl_skippedTabs` 中。
        pageRegistry = [normalized[CYLTabBarControllerPageRegistry] conformsToProtocol:@protocol(CYLTabBarPageProviding)]
            ? normalized[CYLTabBarControllerPageRegistry] : nil;
        pageResolver = normalized[CYLTabBarControllerPageResolver];
        pageLookupOrder = CYLPageLookupOrderOfConfiguration(normalized);
        NSMutableArray<NSDictionary<NSString *, id> *> *keptItems = [NSMutableArray array];
        viewControllers = [CYLTabBarPageRegistry pagesOfTabs:[CYLTabBarController cyl_resolvableTabs:tabBarItemsAttributes skipped:skippedTabs]
                                                    registry:pageRegistry resolver:pageResolver lookupOrder:pageLookupOrder
                                                    keptTabs:keptItems skipped:skippedTabs];
        tabBarItemsAttributes = keptItems;
    }
    NSValue *imageInsetsValue = normalized[CYLTabBarControllerImageInsets];
    NSValue *titlePositionAdjustmentValue = normalized[CYLTabBarControllerTitlePositionAdjustment];
    UIEdgeInsets imageInsets = imageInsetsValue ? imageInsetsValue.UIEdgeInsetsValue : UIEdgeInsetsZero;
    UIOffset titlePositionAdjustment = titlePositionAdjustmentValue ? titlePositionAdjustmentValue.UIOffsetValue : UIOffsetZero;
    CYLTabBarStyleType styleType = (CYLTabBarStyleType)[normalized[CYLTabBarControllerStyleType] integerValue];
    NSString *context = normalized[CYLTabBarControllerContext];
    // [EN] Before the tab bar is made: it looks up the plus button of its context. [CN] 在创建 TabBar 之前：TabBar 会查找其 context 的 PlusButton。
    BOOL plusButtonShowsSelection = NO;
    if (normalized[CYLTabBarControllerPlusButton]) {
        NSMutableDictionary *plusButtonAttributes = [normalized[CYLTabBarControllerPlusButton] mutableCopy];
        plusButtonShowsSelection = [plusButtonAttributes[CYLPlusButtonShowsSelection] boolValue];
        // [EN] A page of its own (`CYLTabBarItemPageIdentifier`), found like a tab's page; it needs a place among the tabs,
        //      the middle when none is given. [CN] 自己的页面（`CYLTabBarItemPageIdentifier`），按 Tab 页面的方式查找；它需要在各 Tab 中的位置，
        //      未给出时居中。
        NSString *plusPageIdentifier = plusButtonAttributes[CYLTabBarItemPageIdentifier];
        if ([plusPageIdentifier isKindOfClass:[NSString class]] && plusPageIdentifier.length > 0) {
            NSArray<UIViewController *> *pages = [CYLTabBarPageRegistry pagesOfTabs:@[ @{ CYLTabBarItemPageIdentifier : plusPageIdentifier } ]
                                                                           registry:[normalized[CYLTabBarControllerPageRegistry] conformsToProtocol:@protocol(CYLTabBarPageProviding)] ? normalized[CYLTabBarControllerPageRegistry] : nil
                                                                           resolver:normalized[CYLTabBarControllerPageResolver]
                                                                        lookupOrder:CYLPageLookupOrderOfConfiguration(normalized)
                                                                           keptTabs:nil
                                                                            skipped:nil];
            if (pages.firstObject) {
                // [EN] A page without a title takes the plus button's, as `plusChildViewController.title` in the example: on
                //      Liquid Glass the system tab of the selected plus page shows it.
                // [CN] 没有标题的页面使用 PlusButton 的标题，与示例中的 `plusChildViewController.title` 相同：液态玻璃下选中 PlusButton
                //      页面时，系统 Tab 显示该标题。
                NSString *plusTitle = plusButtonAttributes[CYLTabBarItemTitle];
                if (pages.firstObject.title.length == 0 && [plusTitle isKindOfClass:[NSString class]] && plusTitle.length > 0) {
                    pages.firstObject.title = plusTitle;
                }
                plusButtonAttributes[CYLConfigurationPlusButtonPageKey] = pages.firstObject;
                if (!plusButtonAttributes[CYLPlusButtonIndexInTabBar]) {
                    plusButtonAttributes[CYLPlusButtonIndexInTabBar] = @(tabBarItemsAttributes.count / 2);
                }
            }
        }
        [CYLPlusButton cyl_registerPlusButtonWithAttributes:plusButtonAttributes
                                                      action:normalized[CYLTabBarControllerPlusButtonAction]
                                                     context:context];
    }
    if (self = [super init]) {
        _imageInsets = imageInsets;
        _titlePositionAdjustment = titlePositionAdjustment;
        _tabBarItemsAttributes = tabBarItemsAttributes;
        if (plusButtonShowsSelection) {
            objc_setAssociatedObject(self, CYLPlusButtonShowsSelectionKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        _adjustTabBarItemImageViewSizeDependOnSuperView = YES;
        _pagesFromPageIdentifiers = !viewControllersFromCode;
        _pageRegistry = pageRegistry;
        _pageResolver = [pageResolver copy];
        _pageLookupOrder = pageLookupOrder;
        _pagesByPageIdentifier = viewControllersFromCode ? nil : [CYLTabBarController cyl_pagesByPageIdentifierOfPages:viewControllers tabs:tabBarItemsAttributes];
#if CYL_FLATDESIGN_AVAILABLE
        // FlatDesign only. Before a subclass customizes the tab bar: tells an app's `standardAppearance` from the default one.
        // 仅用于扁平样式。在子类自定义 TabBar 之前：用于区分 App 设置的 `standardAppearance` 与默认值。
        [self cyl_recordDefaultStandardAppearance];
#endif
        // [CN] 以下为重要步骤，谨慎修改顺序：
        // [EN] The following steps are important; be careful when changing their order:
        self.tabBarStyleType = styleType;// [CN] 步骤1 must use setter 必须在 self.viewControllers之前设置， 因为 self.viewControllers直接涉及到样式判断逻辑。
        // [EN] Step 1: must use the setter and must be set before self.viewControllers,
        //      because self.viewControllers directly involves the style detection logic.
        [self cyl_tabBar];
        self.context = context; // [CN] 步骤2 must use setter 必须在 self.viewControllers之前设置， 因为 self.viewControllers 直接涉及样式contxt 与 PlusButton的判断逻辑。否则 contxt 永远是默认值
        // [EN] Step 2: must use the setter and must be set before self.viewControllers, because
        //      self.viewControllers directly involves
        //      the style context and PlusButton detection logic. Otherwise the context always stays at its default value
        if (viewControllersFromCode) {
            // [EN] Without the PlusButton slot (#774): the slot of an existing tab bar controller (its `viewControllers`
            //      re-used) is not an app tab, and would shift the index matching below (B26). Needs the context (step 2).
            // [CN] 去掉 PlusButton 的 slot（#774）：已有 TabBarController 的 slot（复用其 `viewControllers`）不是 App 的 Tab，
            //      会让下面按下标的对应错位（B26）。需要先设置 context（步骤 2）。
            viewControllers = [self cyl_viewControllersByRemovingPlusSlot:viewControllers];
            // From code, matched by index: a tab left out by its platforms or minimum version takes its view controller out (B22).
            // 代码传入，按下标对应：因平台或最低版本被排除的 Tab 连同其子控制器一起移除（B22）。
            NSMutableArray<NSDictionary *> *keptItems = [NSMutableArray array];
            NSMutableArray<UIViewController *> *keptViewControllers = [NSMutableArray array];
            for (NSUInteger index = 0; index < MAX(tabBarItemsAttributes.count, viewControllers.count); index++) {
                NSDictionary *item = index < tabBarItemsAttributes.count ? tabBarItemsAttributes[index] : nil;
                if ([item[CYLTabBarItemExcludedKey] boolValue]) {
                    [skippedTabs addObject:[CYLTabBarSkippedTab skippedTabWithReason:CYLTabBarPageSkipReasonExcluded
                                                                      pageIdentifier:[CYLTabBarPageRegistry pageIdentifierOfTab:item]
                                                                          attributes:item detail:item[CYLTabBarItemExclusionReasonKey]]];
                    continue;
                }
                if (item) {
                    [keptItems addObject:item];
                }
                if (index < viewControllers.count) {
                    [keptViewControllers addObject:viewControllers[index]];
                }
            }
            tabBarItemsAttributes = keptItems;
            viewControllers = keptViewControllers;
            _tabBarItemsAttributes = tabBarItemsAttributes;
        }
        _skippedTabs = [skippedTabs copy];
        self.viewControllers = viewControllers;// [CN] 步骤3 must use setter,必须在 self.tabBarStyleType之后设置， 因为 self.viewControllers 直接涉及到扁平TabBar样式KVC逻辑。
        // [EN] Step 3: must use the setter and must be set after self.tabBarStyleType,
        //      because self.viewControllers directly involves the KVC logic of the flat TabBar style.
        [self cyl_adoptPendingPages];
        NSNumber *animationSpeed = normalized[CYLTabBarControllerTabBarItemAnimationSpeed];
        if (animationSpeed) {
            // [EN] Validated by the normalizer (B28). [CN] 已由规范化检查（B28）。
            self.tabBarItemAnimationSpeed = animationSpeed.doubleValue;
        }
        // [EN] Appearance and interactions of the configuration, validated by the normalizer.
        // [CN] 配置中的外观与交互，已由规范化检查。
        NSNumber *userInterfaceStyle = normalized[CYLTabBarControllerUserInterfaceStyle];
        if (userInterfaceStyle) {
            if (@available(iOS 13.0, *)) {
                self.overrideUserInterfaceStyle = (UIUserInterfaceStyle)userInterfaceStyle.integerValue;
            }
        }
        NSNumber *tapAnimation = normalized[CYLTabBarControllerTabButtonTapAnimation];
        if (tapAnimation) {
            self.cyl_tabButtonTapAnimationType = (CYLTabButtonTapAnimationType)tapAnimation.integerValue;
        }
        NSNumber *swipeToSwitchTab = normalized[CYLTabBarControllerSwipeToSwitchTab];
        if (swipeToSwitchTab) {
            self.cyl_swipeToSwitchTabEnabled = swipeToSwitchTab.boolValue;
        }
        NSArray<NSString *> *loginRequired = normalized[CYLTabBarControllerLoginRequiredTabBarItemIdentifiers];
        if (loginRequired) {
            self.cyl_loginRequiredTabBarItemIdentifiers = loginRequired;
        }
        NSNumber *unloads = normalized[CYLTabBarControllerUnloadsUnselectedViewsOnMemoryWarning];
        if (unloads) {
            self.unloadsUnselectedViewsOnMemoryWarning = unloads.boolValue;
        }
        NSArray<NSString *> *keepsLoaded = normalized[CYLTabBarControllerKeepsLoadedTabBarItemIdentifiers];
        if (keepsLoaded) {
            self.cyl_keepsLoadedTabBarItemIdentifiers = keepsLoaded;
        }
        // [EN] Skins of the configuration (`CYLTabBarControllerThemes`): registered with the theme manager, the first one applied.
        // [CN] 配置中的皮肤（`CYLTabBarControllerThemes`）：注册到主题管理器，并应用首个皮肤。
        [self cyl_applyConfigurationThemes:normalized];
        
    }
    return self;
}

// [EN] Deprecated Lottie names kept for compatibility: implemented here, forwarding to the neutral API.
// [CN] 为兼容保留的已废弃 Lottie 名称：在此实现，并转发给通用 API。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (UIViewContentMode)lottieAnimationViewContentMode {
    return UIViewContentModeScaleAspectFit;
}

@synthesize lottieAnimationSpeed = _lottieAnimationSpeed;

- (CGFloat)lottieAnimationSpeed {
    // Unset (0) or invalid means the default speed.
    return (_lottieAnimationSpeed > 0 && isfinite(_lottieAnimationSpeed)) ? _lottieAnimationSpeed : 1.0;
}

- (void)setLottieAnimationSpeed:(CGFloat)lottieAnimationSpeed {
    _lottieAnimationSpeed = lottieAnimationSpeed;
}

#pragma clang diagnostic pop

// [EN] The neutral names go through the deprecated ones, so a subclass that still overrides them keeps working.
// [CN] 通用名称经由已废弃的名称实现，因此仍重写旧方法的子类依然有效。
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
- (UIViewContentMode)tabBarItemAnimationViewContentMode {
    return [self lottieAnimationViewContentMode];
}

- (CGFloat)tabBarItemAnimationSpeed {
    return [self lottieAnimationSpeed];
}

- (void)setTabBarItemAnimationSpeed:(CGFloat)tabBarItemAnimationSpeed {
    self.lottieAnimationSpeed = tabBarItemAnimationSpeed;
    [self cyl_applyTabBarItemAnimationPlayback];
}
#pragma clang diagnostic pop

- (void)setTabBarItemAnimationLoops:(BOOL)tabBarItemAnimationLoops {
    _tabBarItemAnimationLoops = tabBarItemAnimationLoops;
    [self cyl_applyTabBarItemAnimationPlayback];
    // [EN] Animated images: off stops them on their resting frame, on plays the selected tab's (Swift, step 65).
    // [CN] 动图：关闭时停在静止帧，开启时播放选中的 Tab（Swift，第 65 步）。
    [self cyl_applyAnimatedImagesLoops:tabBarItemAnimationLoops];
}

/// [EN] The speed and the loop mode, to the views already added (none before the tab bar is laid out).
/// [CN] 把速度与循环模式应用到已添加的视图（TabBar 布局前没有视图）。
- (void)cyl_applyTabBarItemAnimationPlayback {
    if (!CYLTabBarItemAnimationIsAvailable() || ![self isViewLoaded] || ![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    [(CYLTabBar *)self.cyl_tabBar cyl_setAllTabBarItemAnimationsSpeed:self.tabBarItemAnimationSpeed
                                                                loops:self.tabBarItemAnimationLoops];
}

- (void)cyl_playAllTabBarItemAnimations {
    // [EN] Animated images need no animation subspec. [CN] 动图不需要动画子库。
    for (UIControl *control in [self cyl_allTabButtonsForAnimatedImages]) {
        [self cyl_playAnimatedImagesOfTabButton:control];
    }
    if (!CYLTabBarItemAnimationIsAvailable() || ![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    [self cyl_applyTabBarItemAnimationPlayback];
    [(CYLTabBar *)self.cyl_tabBar cyl_restartAllTabBarItemAnimations];
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                          styleType:(CYLTabBarStyleType)styleType
                                            context:(nullable NSString *)context {
    return [[self alloc] initWithViewControllers:viewControllers
                           tabBarItemsAttributes:tabBarItemsAttributes
                                     imageInsets:imageInsets
                         titlePositionAdjustment:titlePositionAdjustment
                                       styleType:styleType
                                         context:context];
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                            context:(nullable NSString *)context {
    return [[self alloc] initWithViewControllers:viewControllers
                           tabBarItemsAttributes:tabBarItemsAttributes
                                     imageInsets:imageInsets
                         titlePositionAdjustment:titlePositionAdjustment
                                       styleType:CYLTabBarStyleTypeDefault
                                         context:context];
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    NSString *context = nil;
    return [[self alloc] initWithViewControllers:viewControllers
                           tabBarItemsAttributes:tabBarItemsAttributes
                                     imageInsets:imageInsets
                         titlePositionAdjustment:titlePositionAdjustment
                                         context:context];
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                          styleType:(CYLTabBarStyleType)styleType
                                            context:(nullable NSString *)context {
    return [[self alloc] initWithViewControllers:viewControllers
                           tabBarItemsAttributes:tabBarItemsAttributes
                                     imageInsets:UIEdgeInsetsZero
                         titlePositionAdjustment:UIOffsetZero
                                       styleType:styleType
                                         context:context];
}
    
+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    return [self tabBarControllerWithViewControllers:viewControllers
                               tabBarItemsAttributes:tabBarItemsAttributes
                                         imageInsets:UIEdgeInsetsZero
                             titlePositionAdjustment:UIOffsetZero];
}

CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_PUSH
- (void)hideTabBadgeBackgroundSeparator {
    [self hideTabBarShadowImageView];
}
CYL_DEPRECATED_IGNORED_IMPLEMENTATIONS_POP

#pragma mark - Plus slot (the plus button's tab)

/*!
 ** means ( CYL_NoNeed_UIDesignRequiresCompatibility_with_iOS26)
 * useCYL_UIDesignNewCYLTabBar if return YES
 * @return use  CYLTabBarStyleType == CYLTabBarStyleTypeFlatDesign if return NO, use  CYLTabBarStyleType == CYLTabBarStyleTypeLiquidGlass if return YES;
 * @attention //better switch to property CYLTabBarStyleType
 *
 * double-check if to use CYLTabBarStyleTypeLiquidGlass or not:
 * UIDesignCompatibility == FlatDesign , noNeedUIDesignCompatibility == noNeed FlatDesign == LiquidGlass
 * [CN] 设置为 NO，表示扁平化设计， 本属性相当于UI兼容模式的代码替代版本，仅仅在 iOS26+ 系统有效。
 * 由于 UI 兼容模式的命名晦涩， 更优雅直观的方式为 设置 CYLTabBarStyleType，其内部会设置该属性用于决定是否使用扁平设计。
 * [EN] Setting this to NO means flat design. This property is a code replacement for the UI compatibility
 *      mode and only takes
 *      effect on iOS26+. Since the name of the UI compatibility mode is obscure, a more elegant and
 *      intuitive approach is to
 *      set CYLTabBarStyleType, which sets this property internally to decide whether to use flat design.
 
 * @return means  CYLTabBarStyleType == CYLTabBarStyleTypeFlatDesign if return NO, means  CYLTabBarStyleType == CYLTabBarStyleTypeLiquidGlass if return YES;
 * @attention better switch to property CYLTabBarStyleType
 */
- (BOOL)noNeedUIDesignCompatibility {
    if (!CYL_IS_IOS_26) {
        return YES;
    }
    BOOL isLiquidGlass = [CYLConstants isLiquidGlassActive];
    // [CN] ， 这个表示requiresCompatibility，必须使用， 否则iOS26里的兼容模式会错乱。
    // [EN] This means requiresCompatibility and must be used, otherwise the compatibility mode on iOS26 breaks.
    if (!isLiquidGlass) {
        return YES;
    }
    BOOL result = _noNeedUIDesignCompatibility && isLiquidGlass;
    return result;
}

- (void)setTabBarStyleType:(CYLTabBarStyleType)tabBarStyleType {
    if (CYL_IS_IOS_27 && CYLTabBarStyleTypeDefault == tabBarStyleType) {
        BOOL result = [[NSBundle.mainBundle objectForInfoDictionaryKey:@"UIDesignRequiresCompatibility"] boolValue];
        if (result) {
            tabBarStyleType = CYLTabBarStyleTypeFlatDesign;
        }
    }
    switch (tabBarStyleType) {
        case CYLTabBarStyleTypeDefault:
            [self setNoNeedUIDesignCompatibility:YES];
            break;
            
        case CYLTabBarStyleTypeSystem:
            [self setNoNeedUIDesignCompatibility:YES];
            break;
            
        case CYLTabBarStyleTypeFlatDesign:
            [self setNoNeedUIDesignCompatibility:NO];
            break;
            
        case CYLTabBarStyleTypeLiquidGlass:
            [self setNoNeedUIDesignCompatibility:YES];
            break;
            
        default:
            [self setNoNeedUIDesignCompatibility:YES];
            break;
    }
    _tabBarStyleType = tabBarStyleType;
}


#pragma mark -
#pragma mark - Private Methods

- (void)hideTabBarShadowImageView {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
    [self.cyl_tabBar layoutIfNeeded];
    UIImageView *imageView = self.cyl_tabBar.cyl_tabShadowImageView;
    [imageView cyl_setHidden:YES];//iOS13+
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/*!
 * [EN] The plus button and the plus child view controller are bound to the tab bar controller, by its `context`: the
 *      registry of `CYLPlusButton` is asked here. The tab bar (system or flat design) does not hold the binding, it asks
 *      this controller (`+[CYLPlusButton plusButtonForOwner:]`), so both always agree.
 * [CN] PlusButton 与 PlusButton 子控制器绑定的是 TabBarController，通过它的 `context`：这里直接查询 `CYLPlusButton` 的注册表。
 *      TabBar（系统样式或扁平样式）不保存绑定关系，而是向这个控制器询问（`+[CYLPlusButton plusButtonForOwner:]`），因此两者始终一致。
 */
- (BOOL)hasPlusButton {
    return [self cyl_contextPlusButton] != nil;
}

/// The plus button bound to this controller: the one registered for its `context`, or, when another tab bar controller of
/// that context already shows it, this controller's own (`+[CYLPlusButton plusButtonForOwner:]`).
- (CYLPlusButton<CYLPlusButtonSubclassing> *)cyl_contextPlusButton {
    return [CYLPlusButton plusButtonForOwner:self];
}

/// The plus child view controller bound to this controller, see `-cyl_contextPlusButton`.
- (UIViewController *)cyl_contextPlusChildViewController {
    return [CYLPlusButton plusChildViewControllerForOwner:self];
}

- (NSUInteger)allItemsInTabBarCount {
    NSUInteger allItemsInTabBar = [self.cyl_tabBar cyl_tabbarItemsCount];
    if ([self hasPlusButton]) {
        allItemsInTabBar += 1;
    }
    return allItemsInTabBar;
}

- (id<UIApplicationDelegate>)appDelegate {
    return [UIApplication sharedApplication].delegate;
}

#pragma mark - Update a tab item in place (issue #601)

// [EN] The in-place updates (`-updateTabBarItemAtIndex:attributes:`, `-updateTabBarItemForViewController:attributes:`,
//      `-updateTabBarItemsWithAttributes:`, the animation keys, `-cyl_themeRemoveTabBarItemAttributeKeys:atIndex:`) are Swift:
//      Swift/CYLTabBarController+CYLTabBarItemUpdate.swift (step 73).
// [CN] 原地更新已迁移到 Swift（第 73 步）。

#pragma mark - A view of yours in place of a tab's icon (issue #601)


// [EN] The providers, the tab buttons of a tab and the icon views are Swift
//      (Swift/CYLTabBarController+CYLTabBarItemIconViews.swift, docs/Swift-Migration.md, step 66). [CN] 已迁移到 Swift（第 66 步）。

// [EN] `-setTabBarItemIconViewProvider:atIndex:`, `-setTabBarItemIconWithURL:…` and `-setTabBarItemIcon:…` are Swift
//      (Swift/CYLTabBarController+CYLTabBarItemIconViews.swift, step 67). [CN] 已迁移到 Swift（第 67 步）。

// [EN] `CYLLoadTabBarItemIcon` is Swift: `+cyl_loadTabBarItemIcon:completion:` (step 67). [CN] 已迁移到 Swift（第 67 步）。

// [EN] `CYLImageScaledToSize` is Swift (step 68). [CN] 已迁移到 Swift（第 68 步）。

// [EN] Setting the tabs up is Swift (Swift/CYLTabBarController+CYLTabSetup.swift and, for FlatDesign,
//      CYLTabBarController+CYLFlatDesignTabSetup.swift; step 126). The two UIKit overrides stay here as one line each (a Swift
//      extension of an Objective-C class cannot override them); the ivars they write go through
//      `CYLTabBarController (CYLTabSetupStorage)` at the end of this file.
// [CN] 设置 Tab 已改为 Swift（第 126 步）。两个 UIKit 重写保留在这里，各一行（Objective-C 类的 Swift 扩展无法重写它们）；它们写入的实例变量通过本文件末尾的
//      `CYLTabBarController (CYLTabSetupStorage)` 访问。
- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    [self cyl_setViewControllers:viewControllers];
}

- (void)addChildViewController:(UIViewController *)childController {
    [self cyl_overrideAddChildViewController:childController];
}

/**
 * [CN] 添加一个子控制器
 * [EN] Add a child view controller
 *
 * @param viewController    [EN] View controller. [CN] 控制器。
 * @param title             [EN] Title. [CN] 标题。
 * @param normalImageInfo   [EN] Image. [CN] 图片。
 * @param selectedImageInfo [EN] Selected image. [CN] 选中图片。
 */
- (void)addOneChildViewController:(UIViewController *)viewController
                        WithTitle:(NSString *)title
                  normalImageInfo:(id)normalImageInfo
                selectedImageInfo:(id)selectedImageInfo
          titlePositionAdjustment:(UIOffset)titlePositionAdjustment
          imagePositionAdjustment:(UIOffset)imagePositionAdjustment
                      imageInsets:(UIEdgeInsets)imageInsets
                        lottieURL:(nullable NSURL *)lottieURL
                  lottieSizeValue:(NSValue *)lottieSizeValue {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    viewController.tabBarItem.title = title;
    [viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem.title = title;
    UIImage *normalImage = [UIImage cyl_imageNamed:normalImageInfo];
    viewController.tabBarItem.image = [CYLTabBarController cyl_restingTabBarItemImage:normalImage forItem:viewController.tabBarItem selected:NO];
    
    UIImage *selectedImage = [UIImage cyl_imageNamed:selectedImageInfo];;
    viewController.tabBarItem.selectedImage = [CYLTabBarController cyl_restingTabBarItemImage:selectedImage forItem:viewController.tabBarItem selected:YES];
    
    UIEdgeInsets insets = self.imageInsets;
    BOOL shouldCustomizeImageInsets = !(UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, imageInsets));
    if (shouldCustomizeImageInsets) {
        insets = imageInsets;
    }
    viewController.tabBarItem.imageInsets = insets;
    CYLRememberItemImageInsets(viewController.tabBarItem, imageInsets);

    UIOffset offset = self.titlePositionAdjustment;
    BOOL shouldCustomizeTitlePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, titlePositionAdjustment));
    if (shouldCustomizeTitlePositionAdjustment) {
        offset = titlePositionAdjustment;
    }
    CYLRememberItemTitlePositionAdjustment(viewController.tabBarItem, titlePositionAdjustment);
    [self cyl_applyTitlePositionAdjustment:offset toTabBarItem:viewController.tabBarItem];
    
    UIOffset imageoffset = self.imagePositionAdjustment;
    BOOL shouldCustomizeImagePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, imagePositionAdjustment));
    if (shouldCustomizeImagePositionAdjustment) {
        imageoffset = imagePositionAdjustment;
    }
    viewController.tabBarItem.cyl_imagePositionAdjustment = imageoffset;
    
    
    if (lottieURL) {
        [self.tabBarItemAnimationURLs addObject:lottieURL];
        [viewController.tabBarItem cyl_setTabBarItemAnimationURL:lottieURL];
        [[viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem cyl_setTabBarItemAnimationURL:lottieURL];
        
        NSValue *tureLottieSizeValue = [CYLConstants cyl_tabBarItemAnimationSizeValue:lottieSizeValue fromNormalImage:normalImage];
        [self.tabBarItemAnimationSizes addObject:tureLottieSizeValue];
        [viewController.tabBarItem cyl_setTabBarItemAnimationSizeValue:tureLottieSizeValue];
        [[viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem cyl_setTabBarItemAnimationSizeValue:tureLottieSizeValue];
    }
    [self addChildViewController:viewController];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/*!
 * FIX: issue #583 (comment: on iOS 12 `[tabBar setTitlePositionAdjustment:UIOffsetMake(0, -4)]` has no effect)
 * [EN] Each tab's `titlePositionAdjustment` was always assigned, `UIOffsetZero` when nothing was customized. A value set on
 *      the item overrides the `UITabBarItem` appearance proxy, so an app's appearance-level title offset was wiped out.
 *      Assign it only when there is an offset, or to reset one CYL set earlier (e.g. after reloading the items).
 *      Scope: the classic system tab bar (iOS 25 and earlier, iOS 26 UI compatibility mode) and Liquid Glass (iOS 26+,
 *      the iPhone Duo), which both use `UITabBarItem`. FlatDesign never reaches here: its items are
 *      `CYLFlatDesignTabBarItem`, which has no appearance proxy to override.
 * [CN] 以前每个 Tab 的 `titlePositionAdjustment` 总会被赋值，未自定义时为 `UIOffsetZero`。在 item 上设置的值会覆盖 `UITabBarItem`
 *      的 appearance 代理，App 通过 appearance 设置的标题偏移因此失效。现在仅在有偏移时赋值，或用于重置 CYL 之前设置过的值
 *      （如重新加载 item 后）。
 *      范围：经典系统 TabBar（iOS 25 及以前、iOS 26 UI 兼容模式）与液态玻璃（iOS 26+、iPhone Duo），两者都使用 `UITabBarItem`。
 *      扁平样式不会执行到这里：其 item 为 `CYLFlatDesignTabBarItem`，没有可被覆盖的 appearance 代理。
 */
// [EN] `-cyl_applyTitlePositionAdjustment:toTabBarItem:` is Swift (Swift/CYLTabBarController+CYLTitlePositionAdjustment.swift,
//      docs/Swift-Migration.md, step 57); the key is selector based, shared with Swift.
// [CN] `-cyl_applyTitlePositionAdjustment:toTabBarItem:` 已迁移到 Swift（第 57 步）；key 基于 selector，与 Swift 共用。
#define CYLTitlePositionAdjustmentSetByCYLKey ((const void *)sel_registerName("cyl_titlePositionAdjustmentSetByCYL"))

#pragma mark - Title position adjustment (issue #475)

// [EN] The title offsets (issue #475) and image insets (issue #95) of the tabs, the looping Lottie tabs and the FlatDesign item
//      colors / `standardAppearance` mirroring are Swift (Swift/CYLTabBarController+CYLItemAppearance.swift and
//      CYLFlatDesignTabBar-ObjectiveC/Swift/CYLTabBarController+CYLFlatDesignItemAppearance.swift, step 125). The two setters stay
//      here to store the ivar; the observers of `standardAppearance` stay with the KVO context they share.
// [CN] Tab 的标题偏移（issue #475）、图片内边距（issue #95）、循环播放的 Lottie Tab 以及扁平样式 item 的颜色 / `standardAppearance` 映射已改为 Swift
//      （第 125 步）。两个 setter 留在这里保存实例变量；`standardAppearance` 的观察与其共用的 KVO context 一起留在这里。
- (void)setTitlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    _titlePositionAdjustment = titlePositionAdjustment;
    [self cyl_applyTitlePositionAdjustmentToItems:titlePositionAdjustment];
}

- (void)updateImageInsets:(UIEdgeInsets)imageInsets {
    _imageInsets = imageInsets;
    [self cyl_applyImageInsetsToItems:imageInsets];
}

static char CYLObservedStandardAppearanceTabBarKey;

static NSArray<NSString *> *CYLObservedAppearanceKeyPaths(void) {
    if (@available(iOS 15.0, *)) {
        return @[ @"standardAppearance", @"scrollEdgeAppearance" ];
    }
    return @[ @"standardAppearance" ];
}

- (void)cyl_startObservingStandardAppearance {
    UITabBar *tabBar = self.tabBar;
    UITabBar *observedTabBar = objc_getAssociatedObject(self, &CYLObservedStandardAppearanceTabBarKey);
    if (observedTabBar == tabBar) {
        return;
    }
    // The tab bar was replaced (`-setUpTabBar:` swaps in CYLTabBar): observe the current one.
    // TabBar 已被替换（`-setUpTabBar:` 会换成 CYLTabBar）：改为观察当前的 TabBar。
    [self cyl_stopObservingStandardAppearance];
    if (!tabBar) {
        return;
    }
    // The appearances exist from iOS 13. appearance 自 iOS 13 起提供。
    if (@available(iOS 13.0, *)) {
        for (NSString *keyPath in CYLObservedAppearanceKeyPaths()) {
            [tabBar addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew context:CYLStandardAppearanceContext];
        }
        objc_setAssociatedObject(self, &CYLObservedStandardAppearanceTabBarKey, tabBar, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)cyl_stopObservingStandardAppearance {
    UITabBar *tabBar = objc_getAssociatedObject(self, &CYLObservedStandardAppearanceTabBarKey);
    if (!tabBar) {
        return;
    }
    for (NSString *keyPath in CYLObservedAppearanceKeyPaths()) {
        [tabBar cyl_removeObserver:self forKeyPath:keyPath context:CYLStandardAppearanceContext];
    }
    objc_setAssociatedObject(self, &CYLObservedStandardAppearanceTabBarKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark -
#pragma mark - KVO Method

// KVO监听执行
// Dispatched by `context`, not by the current style: an observation outlives a change of `tabBarStyleType`, and an
// observation of ours passed on to `super` raises an exception.
// 按 `context` 分发，而不是按当前样式：观察会在 `tabBarStyleType` 改变后继续存在，把自己的观察交给 `super` 会抛异常。
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context == CYLTabImageViewDefaultOffsetContext) {
        CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
            CGFloat tabImageViewDefaultOffset = [change[NSKeyValueChangeNewKey] doubleValue];
            [self offsetTabBarTabImageViewToFit:tabImageViewDefaultOffset];
        } else {/**  CYLTabBarStyleTypeFlatDesign*/}
        return;
    }
    if (context == CYLStandardAppearanceContext) {
        [self cyl_syncTabBarAppearances];
        return;
    }
    if (context == CYLFlatDesignTabBarContext) {
#if CYL_FLATDESIGN_AVAILABLE
        if (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType || ![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        id oldValue = change[NSKeyValueChangeOldKey];
        id newValue = change[NSKeyValueChangeNewKey];
        CYLFlatDesignTabBar *oldTabBar = (oldValue == [NSNull null]) ? nil : oldValue;
        CYLFlatDesignTabBar *newTabBar = (newValue == [NSNull null]) ? nil : newValue;
        // `-cyl_setTabBar:` already stored `newTabBar`. Setting it again here re-entered this callback forever.
        // `-cyl_setTabBar:` 已经保存了 `newTabBar`，在这里再次赋值会无限重入本回调。
        if (oldTabBar == newTabBar) { return; }
        [oldTabBar removeFromSuperview];
        if (@available(iOS 13.0, *)) {
            newTabBar.standardAppearance = newTabBar.standardAppearance ?: oldTabBar.standardAppearance;
        }
        newTabBar.delegate = self;
        newTabBar.items = oldTabBar.items;
        newTabBar.selectedItem = oldTabBar.selectedItem;
        if (newTabBar) {
            [self.view addSubview:newTabBar];
            [self.view setNeedsLayout];
        }
#endif
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}


#pragma mark - Image-only tabs (issue #257, #522)

/*!
 * FIX: issue #257, issue #522
 * [EN] What the automatic adjustment of image-only tabs wrote into one tab bar item, so it is written only where the app
 *      set nothing, never twice, and can be undone (`automaticallyAdjustsImageOnlyTabs = NO`). Keys:
 *      `insets` / `appliedInsets`: the item's `imageInsets` before / after; `title` / `appliedTitle`: the same for
 *      `titlePositionAdjustment`. A pair is missing when that value was left to the app.
 * [CN] 纯图标 Tab 自动调整写入某个 TabBarItem 的内容：只在 App 未设置的地方写入、不会重复写入、并且可以撤销
 *      （`automaticallyAdjustsImageOnlyTabs = NO`）。键：`insets` / `appliedInsets`：item 原来 / 写入后的 `imageInsets`；
 *      `title` / `appliedTitle`：`titlePositionAdjustment` 的对应值。某一对缺失表示该值留给 App。
 *      The keys are defined at the top of this file. 这些键定义在本文件顶部。
 */

// [EN] `automaticallyAdjustsImageOnlyTabs`, `-cyl_restoreImageOnlyTabItems:` and `-offsetTabBarTabImageViewToFit:` are Swift
//      (Swift/CYLTabBarController+CYLImageOnlyTabs.swift, docs/Swift-Migration.md, step 58).
// [CN] 上述方法已迁移到 Swift（第 58 步）。

#pragma mark - delegate

// [EN] `-updateSelectionStatusIfNeededForTabBarController:shouldSelectViewController:` (both) and
//      `-tabBarController:shouldSelectViewController:` are Swift (Swift/CYLTabBarController+CYLSelection.swift,
//      docs/Swift-Migration.md, step 61). [CN] 已迁移到 Swift（第 61 步）。

/// [EN] Forwards to Swift (`-cyl_tabBarController:shouldSelectViewController:`, step 61): Swift cannot define this UIKit
///      selector on a class whose delegate conformance is declared here. Subclasses override this one and call super.
/// [CN] 转发给 Swift（第 61 步）：代理协议声明在这里时，Swift 无法定义这个 UIKit selector。子类重写本方法并调用 super。
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    return [self cyl_tabBarController:tabBarController shouldSelectViewController:viewController];
}

// [EN] `-cyl_plusButtonTitleIsDrawnByItsTabItem` and `-tabBarController:shouldShowPlatterLiquidLensViewForControl:` are Swift
//      (Swift/CYLTabBarController+CYLInteraction.swift, docs/Swift-Migration.md, step 62). The switch
//      `CYL_PLUS_BUTTON_TITLE_KEEPS_LENS_ENABLED` became the Swift compilation condition `CYL_PLUS_BUTTON_TITLE_KEEPS_LENS_DISABLED`.
// [CN] 已迁移到 Swift（第 62 步）；开关改为 Swift 编译条件 `CYL_PLUS_BUTTON_TITLE_KEEPS_LENS_DISABLED`。

// [EN] `-tabBarController:beginShowPlatterLiquidLensViewForControl:` is Swift (Swift/CYLTabBarController+CYLInteraction.swift,
//      docs/Swift-Migration.md, step 59). [CN] 已迁移到 Swift（第 59 步）。

- (BOOL)isLottieEnabled {
    // [EN] FIX: placeholder count mismatch — without the slot's entry: it is the first one when the plus button is the first tab.
    // [CN] FIX：占位导致的数量不匹配——去掉 slot 的属性项：PlusButton 为第一个 Tab 时它就是第一项。
    return [CYLConstants isTabBarItemAnimationEnabledWithURLs:self.tabBarItemAnimationURLs
                                 tabBarItemsAttributes:[self cyl_tabBarItemsAttributesByRemovingPlusSlot:_tabBarItemsAttributes]];
}

// [EN] `-cyl_reportedControlForControl:` and `-cyl_markControlReportedInCurrentRunLoop:` are Swift
//      (Swift/CYLTabBarController+CYLInteraction.swift, docs/Swift-Migration.md, step 59). [CN] 已迁移到 Swift（第 59 步）。

// [EN] `-cyl_sendDidSelectControl:` is Swift (Swift/CYLTabBarController+CYLInteraction.swift, docs/Swift-Migration.md,
//      step 63). [CN] 已迁移到 Swift（第 63 步）。

// [EN] `-cyl_playAnimatedImagesOfTabButton:` and `-cyl_allTabButtonsForAnimatedImages` are Swift (step 65). [CN] 已迁移到 Swift（第 65 步）。

// [EN] `-cyl_setNeedsApplyTabBarItemAnimationTintColors` is Swift (step 65). [CN] 已迁移到 Swift（第 65 步）。

// [EN] `-didSelectControl:` is Swift (Swift/CYLTabBarController+CYLInteraction.swift, docs/Swift-Migration.md, step 64).
// [CN] 已迁移到 Swift（第 64 步）。

- (void)addLottieImageWithControl:(UIControl *)control
                        animation:(BOOL)animation {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self addLottieImageWithControl:control lottieURL:nil lottieSizeValue:nil animation:animation];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)addLottieImageWithControl:(UIControl *)control
                        lottieURL:(nullable NSURL *)lottieURL
                  lottieSizeValue:(NSValue *)theLottieSizeValue
                        animation:(BOOL)animation {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self addLottieImageWithControl:control
                          lottieURL:lottieURL
                    lottieSizeValue:theLottieSizeValue
                          animation:animation
                    defaultSelected:NO];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

//TODO:  selected content, double add
// [EN] `-cyl_tabBarItemForTabButton:` is Swift (Swift/CYLTabBarController+CYLAnimatedImages.swift, step 65).
// [CN] 已迁移到 Swift（第 65 步）。

/*!
 * FIX: issue #477
 * [EN] YES when every tab (the plus button's placeholder aside) has an animation file, the only case where a tab's file
 *      can be taken by its position in `tabBarItemAnimationURLs`. With only some animated tabs, each one takes its own file.
 * [CN] 每个 Tab（PlusButton 的占位 Tab 除外）都有动画文件时返回 YES；只有这种情况才能按 `tabBarItemAnimationURLs` 中的位置取文件。
 *      只有部分 Tab 有动画时，每个 Tab 使用自己的文件。
 */
- (BOOL)cyl_everyTabHasAnimationFile {
    NSUInteger tabCount = 0;
    for (UIViewController *viewController in self.viewControllers) {
        if (!viewController.cyl_isPlaceholder) {
            tabCount += 1;
        }
    }
    return tabCount > 0 && self.tabBarItemAnimationURLs.count >= tabCount && self.tabBarItemAnimationSizes.count >= tabCount;
}

- (void)addLottieImageWithControl:(UIControl *)control
                        animation:(BOOL)animation
                  defaultSelected:(BOOL)defaultSelected {
    // FIX: issue #604 — the animation code is in the `CYLTabBarItemAnimation` subspec (with a Lottie or a PAG subspec).
    // 动画代码位于 `CYLTabBarItemAnimation` 子库中（随 Lottie 或 PAG 子库引入）。
    if (!CYLTabBarItemAnimationIsAvailable()) {
        return;
    }
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if ([CYLConstants isLiquidGlassActive]) {
        [self addLottieImageWithControl:control lottieURL:nil lottieSizeValue:nil animation:animation defaultSelected:defaultSelected];
    } else {
        CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;

        NSUInteger index = [cyl_tabBar.cyl_subTabBarButtonsWithoutPlusButton indexOfObject:control];
        if (NSNotFound == index) {
            return;
        }
        if (control.cyl_isPlusButton) {
            return;
        }
        // [EN] Issue #423 (hardening) — the file of this button's own tab item first; the position is only a fallback.
        // [CN] 优先使用该按钮所属 tabBarItem 的 Lottie 文件，按位置取仅作为兜底。
        UITabBarItem *tabBarItem = [self cyl_tabBarItemForTabButton:control];
        NSURL *lottieURL = tabBarItem.cyl_tabBarItemAnimationURL;
        NSValue *lottieSizeValue = tabBarItem.cyl_tabBarItemAnimationSizeValue;
        if (!lottieURL) {
            // FIX: issue #477 — by position only when every tab has a file; otherwise a tab without one (a static tab)
            // would take another tab's file. 仅在每个 Tab 都有文件时按位置取；否则没有文件的 Tab（静态 Tab）会取到其他 Tab 的文件。
            // FIX: issue #618 — a tab button without a matching Lottie entry (more tab buttons than
            // `tabBarItemsAttributes`) used to raise NSRangeException here.
            if (![self cyl_everyTabHasAnimationFile] || index >= self.tabBarItemAnimationURLs.count || index >= self.tabBarItemAnimationSizes.count) {
                return;
            }
            lottieURL = self.tabBarItemAnimationURLs[index];
            lottieSizeValue = self.tabBarItemAnimationSizes[index];
        }
        CGSize lottieSize = [lottieSizeValue CGSizeValue];
        [control cyl_addTabBarItemAnimationWithURL:lottieURL size:lottieSize contentMode:self.tabBarItemAnimationViewContentMode animationSpeed:self.tabBarItemAnimationSpeed];
        [control cyl_setTabBarItemAnimationLoops:self.tabBarItemAnimationLoops];
        // [EN] A view added after layout (React Native) gets its tint at once. [CN] 布局之后添加的视图（React Native）立即获得着色。
        [self cyl_setNeedsApplyTabBarItemAnimationTintColors];
        if (animation) {
            // Library-neutral (#604): any animation library (Lottie, PAG). 与动画库无关：任意动画库（Lottie、PAG）。
            [self.cyl_tabBar cyl_playTabBarItemAnimationWithSelectedControl:control URL:lottieURL size:lottieSize defaultSelected:defaultSelected contentMode:self.tabBarItemAnimationViewContentMode];
        }
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

//TODO:  selected content, double add
- (void)addLottieImageWithControl:(UIControl *)control
                        lottieURL:(NSURL *)theLottieURL
                  lottieSizeValue:(NSValue *)theLottieSizeValue
                        animation:(BOOL)animation
                  defaultSelected:(BOOL)defaultSelected {
    // FIX: issue #604 — the animation code is in the `CYLTabBarItemAnimation` subspec (with a Lottie or a PAG subspec).
    // 动画代码位于 `CYLTabBarItemAnimation` 子库中（随 Lottie 或 PAG 子库引入）。
    if (!CYLTabBarItemAnimationIsAvailable()) {
        return;
    }
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    UIControl *contentControl = control;
    UIControl *selectedContentControl;
    //FIXME:  必须为 cyl_subTabBarButtonsWithoutPlusButton （不能 cyl_subTabBarButtons）否则Lottie选中动画不显示，因为Lottie文件数量与tabbaritems 的数量少一个。
    // The plus button offset ("顺延") is fixed by `-cyl_tabBarItemForTabButton:` below (#423).
    if (control.cyl_isPlusControl) {
        return;
    }
    
    NSURL *lottieURL = theLottieURL;
    NSValue *lottieSizeValue = theLottieSizeValue;
    // [EN] Issue #423 (hardening) — no file given: take the one of this button's own tab item, not the one at its position.
    // [CN] 未传入文件时，使用该按钮所属 tabBarItem 的 Lottie 文件，而不是按位置取。
    if (!lottieURL || !lottieSizeValue) {
        UITabBarItem *tabBarItem = [self cyl_tabBarItemForTabButton:contentControl];
        lottieURL = lottieURL ?: tabBarItem.cyl_tabBarItemAnimationURL;
        lottieSizeValue = lottieSizeValue ?: tabBarItem.cyl_tabBarItemAnimationSizeValue;
    }
    // FIX: issue #477 — by position only when every tab has a file (see `-cyl_everyTabHasAnimationFile`).
    // 仅在每个 Tab 都有文件时按位置取。
    if ((!lottieURL || !lottieSizeValue) && [self.cyl_tabBar isKindOfClass:[CYLTabBar class]] && [self cyl_everyTabHasAnimationFile]) {
        
        CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;
        NSUInteger index = contentControl ? [cyl_tabBar.cyl_subTabBarButtons indexOfObject:contentControl] : NSNotFound;
        // [EN] FIX: placeholder count mismatch — the tab buttons include the slot, `lottieURLs` has the app's tabs only:
        //      none for the slot itself, one entry earlier after it.
        // [CN] FIX：占位导致的数量不匹配——Tab 按钮包含 slot，而 `lottieURLs` 只有 App 的 Tab：slot 本身没有，之后的前移一项。
        NSUInteger slotIndex = [self cyl_plusSlotIndexInViewControllers];
        if (slotIndex != NSNotFound && index != NSNotFound) {
            index = (index == slotIndex) ? NSNotFound : ((index > slotIndex) ? index - 1 : index);
        }
        if (NSNotFound != index) {
            // [EN] Fallback only: the position can be off by the plus button; `-cyl_tabBarItemForTabButton:` above is used
            //      first. Bounds-checked: the arrays can be shorter than the tab buttons.
            // [CN] 仅作兜底：按位置可能因 PlusButton 错位，上面优先使用 `-cyl_tabBarItemForTabButton:`。先检查下标：数组可能比
            //      Tab 按钮少。
            lottieURL = lottieURL ?: CYLObjectAtIndex(self.tabBarItemAnimationURLs, index);
            lottieSizeValue = lottieSizeValue ?: CYLObjectAtIndex(self.tabBarItemAnimationSizes, index);
        }
    }
    
    if (!lottieURL) {
        // FIX: issue #477 — a tab without an animation (it shows its images). When it is selected, the animated tabs stop
        // and go back to their first frame, as they do when another animated tab is selected; otherwise the last one kept
        // its last frame, which looks selected.
        // 没有动画的 Tab（显示图片）。选中它时，有动画的 Tab 停止并回到第一帧，与选中其他动画 Tab 时一致；否则上一个动画 Tab
        // 会停在最后一帧，看起来仍是选中状态。
        if (animation && [self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
            [(CYLTabBar *)self.cyl_tabBar cyl_stopAllTabBarItemAnimations];
        }
        return;
    }
    CGSize lottieSize = [lottieSizeValue CGSizeValue];
    [control cyl_addTabBarItemAnimationWithURL:lottieURL size:lottieSize contentMode:self.tabBarItemAnimationViewContentMode animationSpeed:self.tabBarItemAnimationSpeed];
    [control cyl_setTabBarItemAnimationLoops:self.tabBarItemAnimationLoops];
    // [EN] A view added after layout (React Native) gets its tint at once. [CN] 布局之后添加的视图（React Native）立即获得着色。
    [self cyl_setNeedsApplyTabBarItemAnimationTintColors];
    
    if (![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    selectedContentControl = [self.cyl_tabBar cyl_selectedContentControlFromContentControl:contentControl];
    
    if (selectedContentControl) {
        [selectedContentControl cyl_addTabBarItemAnimationWithURL:lottieURL size:lottieSize contentMode:self.tabBarItemAnimationViewContentMode animationSpeed:self.tabBarItemAnimationSpeed];
        [selectedContentControl cyl_setTabBarItemAnimationLoops:self.tabBarItemAnimationLoops];
    }
    
    if (animation) {
        // Library-neutral (#604): any animation library (Lottie, PAG). 与动画库无关：任意动画库（Lottie、PAG）。
        [self.cyl_tabBar cyl_playTabBarItemAnimationWithSelectedControl:contentControl
                                                                    URL:lottieURL
                                                                   size:lottieSize
                                                        defaultSelected:defaultSelected
                                                            contentMode:self.tabBarItemAnimationViewContentMode];
        if (selectedContentControl) {
            [self.cyl_tabBar cyl_playTabBarItemAnimationWithSelectedControl:selectedContentControl
                                                                        URL:lottieURL
                                                                       size:lottieSize
                                                            defaultSelected:defaultSelected
                                                                contentMode:self.tabBarItemAnimationViewContentMode];
        }
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/// Stops observing `tabImageViewDefaultOffset` of the CYLTabBar it was added to (`_cyl_tabBar`, never the lazy getter).
- (void)cyl_stopObservingTabImageViewDefaultOffset {
    if (!self.isObservingTabImageViewDefaultOffset) {
        return;
    }
    if ([_cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        [_cyl_tabBar cyl_removeObserver:self forKeyPath:@"tabImageViewDefaultOffset" context:CYLTabImageViewDefaultOffsetContext];
    }
    self.observingTabImageViewDefaultOffset = NO;
}

#pragma mark -
#pragma mark - getter & setter
// MARK: getter & setter

- (UIView __kindof *)cyl_tabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        
#if CYL_FLATDESIGN_AVAILABLE
        if (_cyl_tabBar && [_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
            _cyl_tabBar = nil;
        }
#else
#endif
    
        if (!_cyl_tabBar) {
            // [CN] 处理tabBar，使用自定义 tabBar 并添加 发布按钮。仅限 CYLTabBar，CYLTabBarStyleTypeFlatDesign 会在 setViewControllers 内部设置。
            // [EN] Set up the tabBar: use the custom tabBar and add the publish button. CYLTabBar only;
            //      CYLTabBarStyleTypeFlatDesign is set inside setViewControllers.
            [self setUpDefaultStyleTabBar];
            // [CN] KVO注册监听
            // [EN] Register KVO observers
            if (!self.isObservingTabImageViewDefaultOffset) {
                @try {
                    //CYLTabBarController may crash when deallocating
                    [_cyl_tabBar addObserver:self forKeyPath:@"tabImageViewDefaultOffset" options:NSKeyValueObservingOptionNew context:CYLTabImageViewDefaultOffsetContext];
                } @catch(NSException *exception) {
#if defined(DEBUG) || defined(BETA)
                    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
                }
                self.observingTabImageViewDefaultOffset = YES;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarStyleTypeDidChangeNotification object:self];
        
        }
        return _cyl_tabBar;
        //    _cyl_tabBar = self.tabBar;
    } else {/**  CYLTabBarStyleTypeFlatDesign*/

    }
    /*!
     * [CN] 添加自定义的 CYLFlatDesignTabBar
     * [EN] Add the custom CYLFlatDesignTabBar
     */


    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (_cyl_tabBar && [_cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
            // Otherwise the flag stays YES and the next CYLTabBar (back to a system style) is never observed.
            // 否则标记一直为 YES，之后（切回系统样式时）新建的 CYLTabBar 永远不会被观察。
            [self cyl_stopObservingTabImageViewDefaultOffset];
            _cyl_tabBar = nil;
        }
        if (!_cyl_tabBar) {
            // [CN] 通过KVC 换成 CYLFlatDesignTabBarHideTabBar 控制系统 UITabBar 永久隐藏
            // [EN] Swap in CYLFlatDesignTabBarHideTabBar via KVC to keep the system UITabBar permanently hidden
            CYLFlatDesignTabBarHideTabBar *tabBar = [[CYLFlatDesignTabBarHideTabBar alloc] init];
            [self cyl_setValue:tabBar forKey:@"tabBar"];
            // KVC can fail silently. Hide the actual system bar, not just the
            // replacement object that may not have been installed.
            if (!self.tabBar.hidden) { self.tabBar.hidden = YES; }
            
            CYLFlatDesignTabBar *flatDesignTabBar = [[CYLFlatDesignTabBar alloc] initWithFrame:self.tabBarFrame];
            flatDesignTabBar.delegate = self;
            // `-setContext:` usually ran before this tab bar existed (it only copies the context to an existing one).
            // `-setContext:` 通常在本 TabBar 创建之前就执行了（它只会复制给已存在的 TabBar）。
            flatDesignTabBar.context = self.cyl_context;
            _cyl_tabBar = (UIView *)flatDesignTabBar;
            _cylDidRefreshSystemTabBarVisibility = NO;
            _cylRefreshedSystemTabBarWindow = nil;
            [self.view addSubview:_cyl_tabBar];
            [self addObserver:self forKeyPath:@"cyl_tabBar" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:CYLFlatDesignTabBarContext];
            
            self.cyl_tabBarHidden = NO;
            [self setTabBarHidden:NO];
            [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarStyleTypeDidChangeNotification object:self];
        }

#else
#endif
    } else {}
    
    return _cyl_tabBar;
}


//- (void)cyl_setTabBar:(CYLTabBar *)cyl_tabBar {
//    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
//    self.tabBar = cyl_tabBar;
//} else {/**  CYLTabBarStyleTypeFlatDesign*/}
//}

- (NSString *)context {
    return self.cyl_context;
}

- (void)setContext:(nullable NSString *)context {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        self.cyl_context = context;
        @try {
            CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;
            cyl_tabBar.context = self.cyl_context;
            [cyl_tabBar setValue:self.cyl_context forKey:@"context"];
        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
            //fix [bug]: #556
            NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@，[DEBUG] 请确保你的 CYLTabBarController 子类在 viewDidLoad 中调用了 `super.viewDidLoad()`，且放在最后一行，否则 CYLTabBar 的 KVC 设置会失败。"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
        }
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}


    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        self.cyl_context = context;
        @try {
            CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;

            cyl_tabBar.context = self.cyl_context;
            [cyl_tabBar setValue:self.cyl_context forKey:@"context"];
        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
            //fix [bug]: #556
            NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@，[DEBUG] 请确保你的 CYLTabBarController 子类在 viewDidLoad 中调用了 `super.viewDidLoad()`，且放在最后一行，否则 CYLTabBar 的 KVC 设置会失败。"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
        }
        
        // A plus button registered for ANOTHER context used to be removed here. With several tab bar controllers, each with its
        // own context and plus button, that unregistered the plus button of the other one as soon as this one loaded (#414).
        // This tab bar controller only uses the plus button of its own context (`-hasPlusButton`), nothing to remove.
        // 这里曾经会移除为 **其他** context 注册的 PlusButton。存在多个 TabBarController（各自有 context 和 PlusButton）时，
        // 一个 TabBarController 加载就会把另一个的 PlusButton 注销（#414）。本 TabBarController 只使用自己 context 的 PlusButton
        // （`-hasPlusButton`），不需要移除任何东西。
#else
#endif
        
    } else {}
}

/// [EN] Lazily created. [CN] 懒加载。
- (NSMutableArray<NSURL *> *)tabBarItemAnimationURLs {
    if (_tabBarItemAnimationURLs == nil) {
        _tabBarItemAnimationURLs = [[NSMutableArray alloc] init];
    }
    return _tabBarItemAnimationURLs;
}

/// [EN] Lazily created. [CN] 懒加载。
- (NSMutableArray *)tabBarItemAnimationSizes {
    if (_tabBarItemAnimationSizes == nil) {
        _tabBarItemAnimationSizes = [[NSMutableArray alloc] init];
    }
    return _tabBarItemAnimationSizes;
}

#pragma mark - Deprecated Lottie names (compatibility) 已废弃的 Lottie 名称（兼容）

// [EN] The deprecated Lottie names (`lottieURLs`, `lottieSizes`, `lottieViewAdded`) and `-rootWindow` are Swift
//      (`Swift/CYLTabBarController+CYLCompatibility.swift`, step 104); `tabBarHeight` and `items` stay here (instance variables).
// [CN] 已废弃的 Lottie 名称与 `-rootWindow` 已改为 Swift（第 104 步）；`tabBarHeight` 与 `items` 留在这里（使用实例变量）。

- (void)setTabBarHeight:(CGFloat)tabBarHeight {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        _tabBarHeight = tabBarHeight;
        CYLTabBarHeight = tabBarHeight;
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}

    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        if (_tabBarHeight != tabBarHeight) {
            _tabBarHeight = tabBarHeight;
            
            [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
            [self.view setNeedsLayout];
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (CGFloat)tabBarHeight {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        if (0 == _tabBarHeight) {
            // Not the global `CYLTabBarHeight`: another tab bar controller with a custom height wrote it.
            // 不使用全局变量 `CYLTabBarHeight`：其他设置了自定义高度的 TabBarController 会改写它。
            _tabBarHeight = kCYLDefaultTabBarHeight;
        }
        return _tabBarHeight;
        
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
    
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return _tabBarHeight; }
        if (0 == _tabBarHeight) {
            // Not the global `CYLTabBarHeight`: another tab bar controller with a custom height wrote it.
            // 不使用全局变量 `CYLTabBarHeight`：其他设置了自定义高度的 TabBarController 会改写它。
            _tabBarHeight = kCYLDefaultTabBarHeight;
        }
        return _tabBarHeight;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    return _tabBarHeight;
}

//#if CYL_FLATDESIGN_AVAILABLE
//- (void)tabBar:(CYLFlatDesignTabBar *)tabBar didSelectItemAt:(NSInteger)index {
//    [self setSelectedIndex:index];
//    if (tabBar.tabBarItems && tabBar.tabBarItems.count > index) {
//        [self tabChangedToSelectedIndex:index
//                         viewController:self.selectedViewController
//                                       control:tabBar.tabBarItems[index]];
//    }
//}
//#endif


/**
 *  lazy load items
 *
 *  @return NSMutableArray<CYLFlatDesignTabBarItem *>
 */
#if CYL_FLATDESIGN_AVAILABLE
- (NSMutableArray<CYLFlatDesignTabBarItem *> *)items {
    if (_items == nil) {
        NSMutableArray<CYLFlatDesignTabBarItem *> *items = [[NSMutableArray<CYLFlatDesignTabBarItem *> alloc] init];
        _items = items;
    }
    return _items;
}
#else
#endif

#pragma mark - Override selectedViewController / selectedIndex

// [EN] The selection overrides are Swift (Swift/CYLTabBarController+CYLSelectionOverrides.swift; the FlatDesign parts in
//      CYLTabBarController+CYLFlatDesign.swift; step 77). The UIKit overrides stay as one-line forwarders until the class is
//      Swift, and so do the two setters below: Swift cannot write the re-synthesized `_selectedViewController` / `_selectedIndex`.
// [CN] 选中相关的重写已迁移到 Swift（第 77 步）；UIKit 重写与下面两个存储 setter 在类迁移到 Swift 之前保留在这里。
- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController { [self cyl_setSelectedViewController:selectedViewController]; }
- (void)setSelectedIndex:(NSUInteger)selectedIndex { [self cyl_setSelectedIndex:selectedIndex]; }
- (void)cyl_setSelectedViewControllerStorage:(nullable UIViewController *)viewController { _selectedViewController = viewController; }
#if CYL_FLATDESIGN_AVAILABLE
// [EN] `selectedIndex` is re-synthesized only with FlatDesign; only the FlatDesign code writes it. [CN] 仅扁平样式重新合成 `selectedIndex`，也只有扁平样式代码写入它。
- (void)cyl_setSelectedIndexStorage:(NSUInteger)selectedIndex { _selectedIndex = selectedIndex; }
#endif

#pragma mark -
#pragma mark - 状态栏
// [CN] MARK: 状态栏
// [EN] MARK: Status bar

- (UIViewController *)childViewControllerForStatusBarStyle {
    UIViewController *childViewController = self.selectedViewController;
    
    do {
        if (!childViewController) {
            childViewController = _viewControllers.lastObject;
            break;
        }
        if (!childViewController) {
            childViewController = CYLGetRootViewController();

            break;
        }
    } while (false); // same as : 0, NO
    if (CYLTabBarStyleTypeFlatDesign == _tabBarStyleType) {     //CYLTabBarStyleTypeFlatDesign
        
#if CYL_FLATDESIGN_AVAILABLE
        return childViewController;
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    
    return childViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    
    UIViewController *childViewController = self.childViewControllerForStatusBarStyle;
    
   
    //    self.topViewController;
    //    self.scene;
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return childViewController; }
        return childViewController;
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    return childViewController;
}

/// [EN] The selected tab decides which edges defer the system gestures. [CN] 由选中的 Tab 决定哪些边缘延迟系统手势。
- (nullable UIViewController *)childViewControllerForScreenEdgesDeferringSystemGestures {
    return self.selectedViewController;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    UIViewController *childViewController = self.childViewControllerForStatusBarStyle;

    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return childViewController.preferredStatusBarUpdateAnimation; }
        return childViewController.preferredStatusBarUpdateAnimation;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/    }
    return childViewController.preferredStatusBarUpdateAnimation;
}

/// HomeIndicator
- (UIViewController *)childViewControllerForHomeIndicatorAutoHidden {
    UIViewController *childViewController = self.childViewControllerForStatusBarStyle;

    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return childViewController; }
        return childViewController;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/    }
    return childViewController;
}


#pragma mark - Vertical bar (iOS 27.1+, iPhone Duo)
// MARK: Vertical bar

/*!
 * FIX: issue #653
 * [EN] On the folded iPhone Duo, iOS 27.1 can move bar content to a vertical bar on the trailing edge.
 *      `allowsVerticalBar` (default NO) is a convenience switch for UIKit's `preferredVerticalBarBehavior`:
 *      NO keeps the tab bar horizontal; YES restores the system default. Returning nil from the child getter
 *      when NO stops UITabBarController from forwarding the choice to the selected view controller (whose default
 *      is Automatic). Unrelated to `sidebar.preferredPlacement` (tab bar vs. iPad-style sidebar, regular width).
 * [CN] iPhone Duo 折叠时，iOS 27.1 可能把栏内容放到右侧竖向栏。`allowsVerticalBar`（默认 NO）是 UIKit
 *      `preferredVerticalBarBehavior` 的便捷开关：NO 保持 TabBar 横向；YES 恢复系统默认行为。为 NO 时子控制器 getter 返回 nil，
 *      避免 UITabBarController 把决定权转交给选中的子控制器（其默认值为 Automatic）。
 *      与 `sidebar.preferredPlacement`（regular 宽度下 TabBar 与 iPad 式侧边栏之间的选择）无关。
 */
- (void)setAllowsVerticalBar:(BOOL)allowsVerticalBar {
    if (_allowsVerticalBar == allowsVerticalBar) { return; }
    _allowsVerticalBar = allowsVerticalBar;
#if defined(__IPHONE_27_1) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_27_1
    if (@available(iOS 27.1, *)) {
        [self setNeedsUpdateOfVerticalBarConfiguration];
    }
#endif
}

#if defined(__IPHONE_27_1) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_27_1
/// FIX: issue #672 YES when `selector` on `cls` comes from app code rather than a system framework such as UIKitCore.
static BOOL CYLIsImplementedOutsideSystemFrameworks(Class cls, SEL selector) {
    IMP imp = class_getMethodImplementation(cls, selector);
    Dl_info info;
    if (!imp || dladdr((const void *)imp, &info) == 0 || !info.dli_fname) { return NO; }
    return strstr(info.dli_fname, "/System/Library/") == NULL && strstr(info.dli_fname, "/usr/lib/") == NULL;
}

- (UIVerticalBarBehavior)preferredVerticalBarBehavior API_AVAILABLE(ios(27.1)) {
    if (self.allowsVerticalBar) { return [super preferredVerticalBarBehavior]; }
    return UIVerticalBarBehaviorDisabled;
}

- (UIViewController *)childViewControllerForPreferredVerticalBarBehavior API_AVAILABLE(ios(27.1)) {
    if (self.allowsVerticalBar) { return [super childViewControllerForPreferredVerticalBarBehavior]; }
    // FIX: issue #672 a screen that overrides `preferredVerticalBarBehavior` makes its own choice.
    if ([self cyl_selectedChildOverridesVerticalBarBehavior]) { return self.selectedViewController; }
    return nil;
}

/*!
 * FIX: issue #672
 * [EN] Whether a view controller on the `childViewControllerForPreferredVerticalBarBehavior` chain that starts at
 *      the selected view controller (e.g. navigation controller -> top view controller) implements
 *      `preferredVerticalBarBehavior` in app code. UIKit's own implementations (UIViewController,
 *      UINavigationController, ...) do not count, so screens without an override still follow `allowsVerticalBar`.
 * [CN] 从选中的子控制器开始，沿 `childViewControllerForPreferredVerticalBarBehavior` 链（如导航控制器 -> 栈顶控制器）
 *      是否有控制器在 App 代码里实现了 `preferredVerticalBarBehavior`。UIKit 自带的实现（UIViewController、UINavigationController 等）
 *      不算，所以没有重写的页面仍按 `allowsVerticalBar` 处理。
 */
- (BOOL)cyl_selectedChildOverridesVerticalBarBehavior API_AVAILABLE(ios(27.1)) {
    UIViewController *viewController = self.selectedViewController;
    NSUInteger depth = 0;
    while (viewController && depth++ < 16) {
        if (CYLIsImplementedOutsideSystemFrameworks(viewController.class, @selector(preferredVerticalBarBehavior))) {
            return YES;
        }
        UIViewController *child = [viewController childViewControllerForPreferredVerticalBarBehavior];
        if (child == viewController) { break; }
        viewController = child;
    }
    return NO;
}
#endif

#pragma mark - Dark Mode Lottie (#442)

// [EN] The work of a light / dark switch and `-cyl_reloadLottieAnimationViewsForCurrentStyle` are Swift
//      (`Swift/CYLTabBarController+CYLDarkModeLottie.swift`, step 106); this override only calls it.
// [CN] 浅色 / 深色切换的处理与 `-cyl_reloadLottieAnimationViewsForCurrentStyle` 已改为 Swift（第 106 步）；本重写只调用它。
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    [self cyl_traitCollectionDidChangeFrom:previousTraitCollection];
}

#pragma mark - UIContentContainer
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    // [EN] Scroll hiding (issue #13): a rotation or a Split View / Stage Manager resize ends any hide session.
    // [CN] 滚动隐藏（issue #13）：旋转或分屏 / 台前调度尺寸变化时结束隐藏会话。
    [self cyl_tabBarMinimizeLifecycleEvent];
#if CYL_FLATDESIGN_AVAILABLE
    // [EN] FlatDesign part in Swift (CYLTabBarController+CYLFlatDesign.swift, step 71). [CN] 扁平样式部分在 Swift 中（第 71 步）。
    [self cyl_flatDesignViewWillTransitionToSize:size withTransitionCoordinator:coordinator];
#endif
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}


#pragma mark - TabBarItem Action, UINavigationControllerExtensionDelegate
// [EN] The FlatDesign tab item action (`-_cyltabBarItemClicked:`, issue #610 reporting, the plus button's selected state) and
//      the navigation transition callbacks are Swift: CYLFlatDesignTabBar-ObjectiveC/Swift/CYLTabBarController+CYLFlatDesign.swift
//      (step 71), compiled only with the FlatDesign subspec.
// [CN] 扁平样式 Tab item 事件与导航转场回调已迁移到 Swift（第 71 步），只随扁平样式子库编译。

#pragma mark - Private

- (CGRect)tabBarFrame {
    CGFloat tabBarHeight = self.tabBarHeight + self.view.safeAreaInsets.bottom;
    CGRect tabBarFrame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - tabBarHeight, CGRectGetWidth(self.view.bounds), tabBarHeight);
    return tabBarFrame;
}

// [EN] The rest of this section (More item detection, item capture and sync, the bottom bar's visibility, the parallax
//      overlay, the additional safe area insets, `-changeItem:toItem:`) is FlatDesign only and Swift:
//      CYLFlatDesignTabBar-ObjectiveC/Swift/CYLTabBarController+CYLFlatDesign.swift (step 72).
// [CN] 本节其余部分仅用于扁平样式，已迁移到 Swift（第 72 步）。

@end

#pragma mark - Item styles in one place

/*!
 * [EN] The initializers of `CYLTabBarController (CYLTabBarItemStyle)`; its other members are Swift
 *      (Swift/CYLTabBarController+CYLTabBarToolkit.swift, with CYLReselect, CYLCustomTabAction and CYLOpaqueTabBarSafeArea;
 *      docs/Swift-Migration.md, step 53). Swift extensions cannot override initializers.
 * [CN] `CYLTabBarController (CYLTabBarItemStyle)` 的初始化方法；其他成员已迁移到 Swift（Swift/CYLTabBarController+CYLTabBarToolkit.swift，
 *      与 CYLReselect、CYLCustomTabAction、CYLOpaqueTabBarSafeArea 一起；docs/Swift-Migration.md，第 53 步）。Swift extension 不能重写初始化方法。
 */
@implementation CYLTabBarController (CYLTabBarItemStyle)

// [EN] Implemented in Swift. [CN] 已在 Swift 中实现。
@dynamic cyl_tabBarItemTitleFont, cyl_tabBarItemSelectedTitleFont, cyl_tabBarItemTitleColor, cyl_tabBarItemSelectedTitleColor,
    cyl_tabBarItemImageColor, cyl_tabBarItemSelectedImageColor, cyl_tabBarBackgroundColor, cyl_tabBarShadowColor;

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self cyl_didInitialize];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super initWithCoder:coder]) {
        [self cyl_didInitialize];
    }
    return self;
}

- (void)cyl_didInitialize {
    // [EN] For subclasses. [CN] 供子类重写。
}

@end

#pragma mark - Attributes storage

@implementation CYLTabBarController (CYLTabBarItemsAttributesStorage)

/*!
 * [EN] Replaces `_tabBarItemsAttributes` without the setter's work, for the Swift asynchronous pages
 *      (Swift/CYLTabBarController+CYLPageRegistry.swift; `CYLPendingPages`, `CYLPageRegistry` and
 *      `UIViewController (CYLTabBarItemTitleSupport)` are Swift since docs/Swift-Migration.md, step 54).
 * [CN] 替换 `_tabBarItemsAttributes`，不执行 setter 的逻辑，供 Swift 的异步页面使用（Swift/CYLTabBarController+CYLPageRegistry.swift；
 *      `CYLPendingPages`、`CYLPageRegistry` 与 `UIViewController (CYLTabBarItemTitleSupport)` 自 docs/Swift-Migration.md 第 54 步起为 Swift）。
 */
- (void)cyl_replaceTabBarItemsAttributesStorage:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    _tabBarItemsAttributes = [tabBarItemsAttributes copy];
}

@end

#pragma mark - Tab setup storage

/*!
 * [EN] The ivars written by the Swift tab setup (Swift/CYLTabBarController+CYLTabSetup.swift, step 126), without any setter's work.
 * [CN] Swift 的 Tab 设置写入的实例变量（第 126 步），不执行 setter 的逻辑。
 */
@implementation CYLTabBarController (CYLTabSetupStorage)

- (void)cyl_setViewControllersStorage:(nullable NSArray<UIViewController *> *)viewControllers {
    _viewControllers = viewControllers;
}

- (void)cyl_setStoredTabBar:(nullable UIView *)tabBar {
    _cyl_tabBar = tabBar;
}

@end
