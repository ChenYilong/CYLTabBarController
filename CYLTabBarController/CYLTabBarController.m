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

// [EN] The plus button's slot (see "Plus slot" below): the guards every count and index goes through.
// [CN] PlusButton 的 slot（见下文 "Plus slot"）：所有数量与下标都经过这些判断。
- (BOOL)cyl_isPlusSlotViewController:(UIViewController *)viewController;
- (NSUInteger)cyl_plusSlotIndexInViewControllers;
- (BOOL)cyl_tabBarItemsAttributesIncludePlusSlot;

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

/// FIX: issue #475. The title offset a tab asked for itself; see `-setTitlePositionAdjustment:`.
/// Tab 自身设置的标题偏移，见 `-setTitlePositionAdjustment:`。
static void CYLRememberItemTitlePositionAdjustment(id _Nullable item, UIOffset offset);
/// FIX: issue #95. The image insets a tab asked for itself; see `-updateImageInsets:`.
/// Tab 自身设置的图片内边距，见 `-updateImageInsets:`。
static void CYLRememberItemImageInsets(id _Nullable item, UIEdgeInsets insets);

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

/*!
 * [EN] The tabs that may get a page: placeholders for invalid tabs (B4) and tabs left out by their platforms or minimum
 *      version (B22) are reported in `skipped` instead. The lookup itself is `+[CYLTabBarPageRegistry pagesOfTabs:...]`.
 * [CN] 可以获得页面的 Tab：无效 Tab 的占位（B4）与因平台或最低版本被排除的 Tab（B22）记录到 `skipped` 中。查找本身见
 *      `+[CYLTabBarPageRegistry pagesOfTabs:...]`。
 */
static NSArray<NSDictionary *> *CYLResolvableTabs(NSArray<NSDictionary *> *items, NSMutableArray<CYLTabBarSkippedTab *> *skipped) {
    NSMutableArray<NSDictionary *> *tabs = [NSMutableArray array];
    for (id item in items) {
        if (![item isKindOfClass:[NSDictionary class]] || [(NSDictionary *)item count] == 0) {
            [skipped addObject:[CYLTabBarSkippedTab skippedTabWithReason:CYLTabBarPageSkipReasonInvalidTab pageIdentifier:nil attributes:nil
                                                                  detail:@"a placeholder for a tab that is not a dictionary"]];
            continue;
        }
        NSDictionary *attributes = item;
        if ([attributes[CYLTabBarItemExcludedKey] boolValue]) {
            [skipped addObject:[CYLTabBarSkippedTab skippedTabWithReason:CYLTabBarPageSkipReasonExcluded
                                                          pageIdentifier:[CYLTabBarPageRegistry pageIdentifierOfTab:attributes]
                                                              attributes:attributes detail:attributes[CYLTabBarItemExclusionReasonKey]]];
            continue;
        }
        [tabs addObject:attributes];
    }
    return tabs;
}

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

/// [EN] The pages by page ID, in tab order (one ID may have several pages). [CN] 按页面 ID 分组的页面（按 Tab 顺序；一个 ID 可以有多个页面）。
static NSMutableDictionary<NSString *, NSMutableArray<UIViewController *> *> *CYLPagesByPageIdentifier(NSArray<UIViewController *> *pages,
                                                                                                        NSArray<NSDictionary *> *tabs) {
    NSMutableDictionary<NSString *, NSMutableArray<UIViewController *> *> *pagesByIdentifier = [NSMutableDictionary dictionary];
    for (NSUInteger index = 0; index < MIN(pages.count, tabs.count); index++) {
        NSString *pageIdentifier = [CYLTabBarPageRegistry pageIdentifierOfTab:tabs[index]];
        if (!pageIdentifier) {
            continue;
        }
        NSMutableArray<UIViewController *> *list = pagesByIdentifier[pageIdentifier] ?: [NSMutableArray array];
        [list addObject:pages[index]];
        pagesByIdentifier[pageIdentifier] = list;
    }
    return pagesByIdentifier;
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
        viewControllers = [CYLTabBarPageRegistry pagesOfTabs:CYLResolvableTabs(tabBarItemsAttributes, skippedTabs)
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
        _pagesByPageIdentifier = viewControllersFromCode ? nil : CYLPagesByPageIdentifier(viewControllers, tabBarItemsAttributes);
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

// [EN] MARK: Plus slot. The plus button's tab in `viewControllers`: the plus child view controller, or a placeholder for a
//      plus button without one (Liquid Glass, FlatDesign). It is DERIVED state: `-setViewControllers:` removes any slot
//      the array already carries and inserts exactly one, at the index of `-cyl_plusSlotIndexForTabCount:`. Every other
//      place reads the slot's index from `viewControllers` (`-[UIView cyl_plusButtonIndex]`), never computes its own.
// [CN] MARK: 加号 slot。PlusButton 在 `viewControllers` 中对应的 Tab：PlusButton 子控制器，或没有子控制器时的占位控制器（液态玻璃、
//      扁平样式）。它是派生状态：`-setViewControllers:` 先移除传入数组中已有的 slot，再在 `-cyl_plusSlotIndexForTabCount:` 的位置
//      插入且只插入一个。其他地方都从 `viewControllers` 中读取 slot 的下标（`-[UIView cyl_plusButtonIndex]`），不再各自计算。

/*!
 * [EN] Marks the tab item attributes inserted for the slot (Liquid Glass, FlatDesign), so a re-assignment can remove them.
 * [CN] 标记为 slot 插入的 TabBarItem 属性（液态玻璃、扁平样式），重新赋值时据此移除。
 */
static NSString *const CYLTabBarItemPlusSlotPlaceholderKey = @"CYLTabBarItemPlusSlotPlaceholder";

/*!
 * [EN] FIX: placeholder count mismatch. Why one rule: the slot used to be inserted by three methods with different
 *      conditions and indexes, and was not removed first, so
 *      - re-assigning `viewControllers` (login, `-reloadTabBarItemsWithAttributes:`, `vc.viewControllers = vc.viewControllers`)
 *        dropped the plus child view controller (classic style: guarded by `cyl_plusViewControllerEverAdded`) or added a
 *        second slot (Liquid Glass placeholder, FlatDesign), with `tabBarItemsAttributes` one entry off;
 *      - FlatDesign did not insert a slot after the last tab (`>` instead of `>=`), nor with an odd tab count without
 *        `+indexOfPlusButtonInTabBar`, while its tab bar indexed `_buttons` with that index: "index beyond bounds";
 *      - `cyl_tabbarItemsCount` counted a slot carried by the array, so `+indexForTabbarItemsCount:` got the wrong count;
 *      - Liquid Glass keeps the slot in the middle, while `-[UIView cyl_plusButtonIndex]` returned the custom index.
 * [CN] FIX：占位导致的数量不匹配。为什么只用一条规则：以前 slot 由三个方法插入，条件和下标各不相同，且插入前不移除旧的，因此
 *      - 重新赋值 `viewControllers`（登录、`-reloadTabBarItemsWithAttributes:`、`vc.viewControllers = vc.viewControllers`）时，
 *        经典样式丢失 PlusButton 子控制器（被 `cyl_plusViewControllerEverAdded` 拦住），液态玻璃占位与扁平样式则多出第二个 slot，
 *        `tabBarItemsAttributes` 也错位一个；
 *      - 扁平样式在最后一个 Tab 之后（`>` 而不是 `>=`）、或 Tab 数为奇数且未实现 `+indexOfPlusButtonInTabBar` 时不插入 slot，
 *        而 TabBar 仍用该下标访问 `_buttons`：数组越界；
 *      - `cyl_tabbarItemsCount` 把数组自带的 slot 也计算在内，`+indexForTabbarItemsCount:` 得到错误的数量；
 *      - 液态玻璃把 slot 放在中间，而 `-[UIView cyl_plusButtonIndex]` 返回的是自定义下标。
 */
- (BOOL)cyl_isPlusSlotViewController:(UIViewController *)viewController {
    if (!viewController) {
        return NO;
    }
    UIViewController *contentViewController = [viewController cyl_getViewControllerInsteadOfNavigationController];
    if (viewController.cyl_isPlaceholder || contentViewController.cyl_isPlaceholder) {
        return YES;
    }
    // [EN] Also the plus child view controller seen through a navigation controller. [CN] 也包括被导航控制器包裹的 PlusButton 子控制器。
    UIViewController *plusChildViewController = [self cyl_contextPlusChildViewController];
    return plusChildViewController && (viewController == plusChildViewController || contentViewController == plusChildViewController);
}

/// [EN] The app's own tabs: `viewControllers` without any slot. [CN] App 自己的 Tab：去掉所有 slot 的 `viewControllers`。
- (NSArray<UIViewController *> *)cyl_viewControllersByRemovingPlusSlot:(NSArray<UIViewController *> *)viewControllers {
    if (![viewControllers isKindOfClass:[NSArray class]]) {
        return @[];
    }
    NSMutableArray<UIViewController *> *tabs = [NSMutableArray arrayWithCapacity:viewControllers.count];
    for (UIViewController *viewController in viewControllers) {
        if (![self cyl_isPlusSlotViewController:viewController]) {
            [tabs addObject:viewController];
        }
    }
    return [tabs copy];
}

/// [EN] The slot's index in `viewControllers`, or NSNotFound. [CN] slot 在 `viewControllers` 中的下标，没有时返回 NSNotFound。
- (NSUInteger)cyl_plusSlotIndexInViewControllers {
    return [_viewControllers indexOfObjectPassingTest:^BOOL(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        return [self cyl_isPlusSlotViewController:viewController];
    }];
}

/*!
 * [EN] Whether `tabBarItemsAttributes` has an entry for the slot, read from the data (the marked entry), not guessed from
 *      the style: `isLiquidGlassActive && hasPlusButton` was used for it, which is wrong for attributes assigned after
 *      `viewControllers` (no slot entry), and for a Liquid Glass controller whose tab bar is not a CYLTabBar.
 * [CN] `tabBarItemsAttributes` 中是否有 slot 的一项，根据数据（带标记的一项）判断，而不是按样式猜测：以前用的是
 *      `isLiquidGlassActive && hasPlusButton`，对 `viewControllers` 之后才赋值的属性（没有 slot 项），以及 TabBar 不是 CYLTabBar
 *      的液态玻璃控制器都不成立。
 */
- (BOOL)cyl_tabBarItemsAttributesIncludePlusSlot {
    if (![_tabBarItemsAttributes isKindOfClass:[NSArray class]]) {
        return NO;
    }
    return [_tabBarItemsAttributes indexOfObjectPassingTest:^BOOL(NSDictionary *attributes, NSUInteger idx, BOOL *stop) {
        return [attributes isKindOfClass:[NSDictionary class]] && [attributes[CYLTabBarItemPlusSlotPlaceholderKey] boolValue];
    }] != NSNotFound;
}

/// [EN] The app's own tab item attributes: without the entries inserted for the slot. [CN] 去掉为 slot 插入的属性。
- (NSArray<NSDictionary *> *)cyl_tabBarItemsAttributesByRemovingPlusSlot:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    if (![tabBarItemsAttributes isKindOfClass:[NSArray class]]) {
        return tabBarItemsAttributes;
    }
    NSIndexSet *slotIndexes = [tabBarItemsAttributes indexesOfObjectsPassingTest:^BOOL(NSDictionary *attributes, NSUInteger idx, BOOL *stop) {
        return [attributes isKindOfClass:[NSDictionary class]] && [attributes[CYLTabBarItemPlusSlotPlaceholderKey] boolValue];
    }];
    if (slotIndexes.count == 0) {
        return tabBarItemsAttributes;
    }
    NSMutableArray<NSDictionary *> *attributes = [tabBarItemsAttributes mutableCopy];
    [attributes removeObjectsAtIndexes:slotIndexes];
    return [attributes copy];
}

/// [EN] Liquid Glass with a CYLTabBar. [CN] 液态玻璃且使用 CYLTabBar。
- (BOOL)cyl_isLiquidGlassPlusSlotStyle {
    return CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType && [CYLConstants isLiquidGlassActive] &&
           [self.cyl_tabBar isKindOfClass:[CYLTabBar class]];
}

/*!
 * [EN] The view controller of the slot, or nil when this style shows the plus button without one: the classic style only
 *      needs it for a plus child view controller; Liquid Glass (CYLTabBar) and FlatDesign always do, the plus button covers it.
 * [CN] slot 对应的控制器；该样式不需要 slot 时返回 nil：经典样式只在有 PlusButton 子控制器时需要；液态玻璃（CYLTabBar）与扁平样式
 *      始终需要，PlusButton 覆盖在它上面。
 */
- (UIViewController *)cyl_plusSlotViewController {
    if (![self hasPlusButton]) {
        return nil;
    }
    BOOL isFlatDesign = (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType);
#if CYL_FLATDESIGN_AVAILABLE
    isFlatDesign = isFlatDesign && [_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]];
#else
    isFlatDesign = NO;
#endif
    UIViewController *plusChildViewController = [self cyl_contextPlusChildViewController];
    if (plusChildViewController) {
        return plusChildViewController;
    }
    if (!isFlatDesign && ![self cyl_isLiquidGlassPlusSlotStyle]) {
        return nil;
    }
    UIViewController *placeholderViewController = [UIViewController new];
    [placeholderViewController cyl_setIsPlaceholder:YES];
    return placeholderViewController;
}

/*!
 * [EN] The one rule for where the slot goes among `tabCount` tabs (0 ... tabCount). Liquid Glass: the middle, where the
 *      plus button covers the tab item (custom positions are not supported there yet). Classic and FlatDesign: the plus
 *      button's own position (`+indexForTabbarItemsCount:`, issue #515), else the middle.
 * [CN] slot 在 `tabCount` 个 Tab 中位置的唯一规则（0 ... tabCount）。液态玻璃：中间，PlusButton 覆盖该 TabBarItem（暂不支持自定义位置）。
 *      经典样式与扁平样式：PlusButton 自己的位置（`+indexForTabbarItemsCount:`，issue #515），否则为中间。
 */
- (NSUInteger)cyl_plusSlotIndexForTabCount:(NSUInteger)tabCount {
    NSUInteger slotIndex = tabCount / 2;
    if ([self cyl_isLiquidGlassPlusSlotStyle]) {
        return slotIndex;
    }
    CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [self cyl_contextPlusButton];
    BOOL implementsCustomIndex = [[plusButton class] respondsToSelector:@selector(indexOfPlusButtonInTabBar)];
    // [EN] `+indexForTabbarItemsCount:` asserts for an odd count without a custom index: only ask when it can answer.
    // [CN] Tab 数为奇数且没有自定义下标时 `+indexForTabbarItemsCount:` 会断言：只在它能给出结果时调用。
    if (plusButton && (implementsCustomIndex || tabCount % 2 == 0)) {
        NSUInteger customIndex = [[plusButton class] indexForTabbarItemsCount:tabCount];
        if (customIndex != NSNotFound && customIndex <= tabCount) {
            slotIndex = customIndex;
        }
    }
    return slotIndex;
}

/// [EN] The attributes of the slot's tab item. [CN] slot 对应 TabBarItem 的属性。
- (NSDictionary *)cyl_plusSlotTabBarItemAttributes {
    return @{
        CYLTabBarItemTitle : @"",
        CYLTabBarItemImage : [UIImage cyl_tabItemPlaceholderImage],
        CYLTabBarItemSelectedImage : [UIImage cyl_tabItemPlaceholderImage],
        CYLTabBarItemPlusSlotPlaceholderKey : @YES,
    };
}

/*!
 * [EN] Sets `_viewControllers` to `viewControllers` (the app's tabs, slot already removed) with exactly one slot, and
 *      keeps `_tabBarItemsAttributes` in step (Liquid Glass and FlatDesign give the slot its own entry; the classic style
 *      skips it, `-cyl_tabBarItemsAttributesIndexOfViewControllerAtIndex:`).
 * [CN] 把 `_viewControllers` 设为 `viewControllers`（App 的 Tab，已去掉 slot）加上唯一一个 slot，并同步 `_tabBarItemsAttributes`
 *      （液态玻璃与扁平样式为 slot 提供单独的一项；经典样式跳过它，见 `-cyl_tabBarItemsAttributesIndexOfViewControllerAtIndex:`）。
 */
- (void)alignTabControlIfNeededWithViewControllers:(NSArray *)viewControllers {
    NSArray<UIViewController *> *tabs = [self cyl_viewControllersByRemovingPlusSlot:viewControllers];
    _tabBarItemsAttributes = [self cyl_tabBarItemsAttributesByRemovingPlusSlot:_tabBarItemsAttributes];
    CYLPlusButton<CYLPlusButtonSubclassing> *plusButton = [self cyl_contextPlusButton];
    if (plusButton) {
        // FIX: issue #481 — checked before the alignment, with the app's own tabs.
        // 在对齐之前用 App 自己的 Tab 检查。
        [self doubleCheckTabControlAlignWithViewControllers:tabs];
    }
    UIViewController *slotViewController = [self cyl_plusSlotViewController];
    if (!slotViewController) {
        _viewControllers = tabs;
        [plusButton cyl_setTabBarChildViewControllerIndex:NSNotFound];
        return;
    }
    NSUInteger slotIndex = MIN([self cyl_plusSlotIndexForTabCount:tabs.count], tabs.count);
    NSMutableArray<UIViewController *> *viewControllersWithSlot = [tabs mutableCopy];
    [viewControllersWithSlot insertObject:slotViewController atIndex:slotIndex];
    _viewControllers = [viewControllersWithSlot copy];
    [self cyl_addChildViewController:slotViewController];
    [plusButton cyl_setTabBarItemVisibleIndex:(NSInteger)slotIndex];
    // [EN] As the tab bars set it on layout (`-[CYLTabBar plusButtonIndex]`): the slot's index, placeholder or not.
    // [CN] 与 TabBar 布局时设置的一致（`-[CYLTabBar plusButtonIndex]`）：slot 的下标，无论是否为占位控制器。
    [plusButton cyl_setTabBarChildViewControllerIndex:(NSInteger)slotIndex];
    BOOL isPlusChildViewController = !slotViewController.cyl_isPlaceholder;
    if (isPlusChildViewController) {
        [slotViewController cyl_setPlusViewControllerEverAdded:YES];
    }
    BOOL isFlatDesign = (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType);
    if ((isFlatDesign || [self cyl_isLiquidGlassPlusSlotStyle]) && _tabBarItemsAttributes.count > 0) {
        NSMutableArray<NSDictionary *> *attributes = [_tabBarItemsAttributes mutableCopy];
        [attributes insertObject:[self cyl_plusSlotTabBarItemAttributes] atIndex:MIN(slotIndex, attributes.count)];
        _tabBarItemsAttributes = [attributes copy];
    }
}

- (void)doubleCheckTabControlAlignWithViewControllers:(NSArray *)viewControllers {
    //FIXME:  to delete
    if (!viewControllers) {
        viewControllers = _viewControllers;
    }
    if ((!_tabBarItemsAttributes) || (_tabBarItemsAttributes.count != viewControllers.count)) {
#if defined(DEBUG) || defined(BETA)
        NSAssert(NO, CYLLocalizedString(@"[DEBUG] 设置 tabBarItemsAttributes 时，请确保元素个数与控制器的个数相同，并在 `-setViewControllers:` 之前设置。"));
#endif
        return;
    }
}

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

- (BOOL)replaceViewControllerAtIndex:(NSUInteger)index
                  withViewController:(UIViewController *)viewController
                          attributes:(NSDictionary<NSString *, id> *)attributes {
    if (index >= _viewControllers.count || !viewController || [_viewControllers containsObject:viewController]) {
        return NO;
    }
    UIViewController *oldViewController = _viewControllers[index];
    if (oldViewController.cyl_isPlaceholder || oldViewController == [self cyl_contextPlusChildViewController]) {
        return NO;
    }
    UIViewController *selectedViewController = self.selectedViewController;
    UIViewController *plusChildViewController = [self cyl_contextPlusChildViewController];
    // [EN] The shape the tab bar controller was created with: no entry for the plus button's tab, which
    //      `-setViewControllers:` inserts again (it would be inserted twice otherwise).
    // [CN] 与创建 TabBarController 时相同的结构：不含 PlusButton 的 Tab，`-setViewControllers:` 会重新插入它（否则会插入两次）。
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    NSMutableArray<NSDictionary *> *tabBarItemsAttributes = [NSMutableArray array];
    for (NSUInteger tabIndex = 0; tabIndex < _viewControllers.count; tabIndex++) {
        UIViewController *tabViewController = _viewControllers[tabIndex];
        if (tabViewController.cyl_isPlaceholder || tabViewController == plusChildViewController) {
            continue;
        }
        NSDictionary *tabAttributes = [self tabBarItemAttributesAtIndex:tabIndex] ?: @{};
        if (tabIndex == index) {
            // [EN] The new tab's own entry (a Lottie animation of the old tab must not stay); nil keeps the old one.
            // [CN] 使用新 Tab 自己的属性（旧 Tab 的 Lottie 动画等不能保留）；为 nil 时保留旧的属性。
            tabViewController = viewController;
            tabAttributes = attributes ?: tabAttributes;
        }
        [viewControllers addObject:tabViewController];
        [tabBarItemsAttributes addObject:tabAttributes];
    }
    [plusChildViewController cyl_setPlusViewControllerEverAdded:NO];
    _tabBarItemsAttributes = [tabBarItemsAttributes copy];
    // [EN] As `-reloadTabBarItemsWithAttributes:`: the Lottie views are added again, and the one-time layout block
    //      (`-setViewDidLayoutSubViewsBlockInvokeOnce:block:`, e.g. covers and badges) runs again for the new tab buttons.
    // [CN] 与 `-reloadTabBarItemsWithAttributes:` 相同：重新添加 Lottie 视图，并为新的 Tab 按钮再执行一次只执行一次的布局 block
    //      （`-setViewDidLayoutSubViewsBlockInvokeOnce:block:`，如封面与角标）。
    [self cyl_rearmViewDidLayoutSubviewsBlockInvokeOnce];
    self.tabBarItemAnimationViewAdded = NO;
    [_tabBarItemAnimationURLs removeAllObjects];
    [_tabBarItemAnimationSizes removeAllObjects];
    // [EN] As a new set of tabs (#608): the tab items, icons and Lottie views are set up again from the attributes.
    // [CN] 与重新设置一组 Tab 相同（#608）：TabBarItem、图标与 Lottie 视图按属性重新设置。
    self.viewControllers = viewControllers;
    // FIX: issue #433
    // [EN] The new tab may be the selected one: show its selected title.
    // [CN] 新的 Tab 可能正是选中的 Tab：显示其选中标题。
    CYLSetNeedsUpdateTabBarItemSelectedTitles(self);
    // [EN] The tabs were installed as child view controllers after UIKit's list was cleared (#608): hand UIKit's own
    //      setter the same tabs, so it builds their tab items again (Liquid Glass and the classic style).
    // [CN] UIKit 的 Tab 列表被清空后（#608），Tab 以子控制器方式重新添加：把同样的 Tab 交给 UIKit 自身的 setter，使其重新生成
    //      TabBarItem（液态玻璃与经典样式）。
    if (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType && self.tabBar.items.count != [super viewControllers].count) {
        [super setViewControllers:[super viewControllers] animated:NO];
    }
    UIViewController *viewControllerToSelect = (selectedViewController == oldViewController) ? viewController : selectedViewController;
    NSUInteger selectedIndex = [self.viewControllers indexOfObject:viewControllerToSelect];
    if (selectedIndex != NSNotFound) {
        // [EN] Setting the tabs removed the selected page's view; selecting its index again would do nothing, so the
        //      selection goes through another tab first and the page is shown again.
        // [CN] 重新设置 Tab 时移除了选中页面的视图；再次选中同一索引不会有任何变化，所以先选中另一个 Tab，再选回来以重新显示该页面。
        if (self.selectedIndex == selectedIndex && self.viewControllers.count > 1) {
            [super setSelectedIndex:(selectedIndex == 0 ? 1 : 0)];
        }
        self.selectedIndex = selectedIndex;
    }
    [self.view setNeedsLayout];
    return YES;
}

// [EN] `-cyl_plusButton:didChangeWithNotification:info:` and `-updatePlusButtonWithAttributes:` are Swift
//      (Swift/CYLTabBarController+CYLTabBarItemIconViews.swift, step 68). [CN] 已迁移到 Swift（第 68 步）。

// [EN] `-cyl_tabButtonsOfViewController:`, the icon view updates and `-cyl_setTabImageView:lottieView:replacedByIconView:`
//      are Swift (step 66). [CN] 已迁移到 Swift（第 66 步）。

/*!
 * [EN] Index into `tabBarItemsAttributes` of the tab at `index` in `viewControllers`, as `-setViewControllers:` pairs them:
 *      with a plus button, Liquid Glass and FlatDesign insert an entry for the plus button's tab; the system tab bar has
 *      none for a plus child view controller.
 * [CN] `viewControllers` 中第 `index` 个 Tab 在 `tabBarItemsAttributes` 中的索引，与 `-setViewControllers:` 的对应方式一致：有 PlusButton
 *      时，液态玻璃与扁平样式会为其 Tab 插入一项；系统 TabBar 不为 PlusButton 子控制器保留一项。
 */
- (NSUInteger)cyl_tabBarItemsAttributesIndexOfViewControllerAtIndex:(NSUInteger)index {
    // [EN] FIX: placeholder count mismatch — guarded by the data: with a slot entry the attributes match
    //      `viewControllers` one to one; without one, tabs after the slot (placeholder or plus child) are one entry earlier.
    // [CN] FIX：占位导致的数量不匹配——按数据判断：有 slot 项时属性与 `viewControllers` 一一对应；没有时，slot（占位或 PlusButton
    //      子控制器）之后的 Tab 对应的属性前移一项。
    if ([self cyl_tabBarItemsAttributesIncludePlusSlot]) {
        return index;
    }
    NSUInteger slotIndex = [self cyl_plusSlotIndexInViewControllers];
    return (slotIndex != NSNotFound && slotIndex < index) ? index - 1 : index;
}

- (NSDictionary<NSString *, id> *)tabBarItemAttributesAtIndex:(NSUInteger)index {
    if (index >= _viewControllers.count) {
        return nil;
    }
    UIViewController *viewController = _viewControllers[index];
    if (viewController.cyl_isPlaceholder || viewController == [self cyl_contextPlusChildViewController]) {
        return nil;
    }
    NSUInteger attributesIndex = [self cyl_tabBarItemsAttributesIndexOfViewControllerAtIndex:index];
    return (attributesIndex < _tabBarItemsAttributes.count) ? _tabBarItemsAttributes[attributesIndex] : nil;
}

- (void)reloadTabBarItemsWithAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    NSArray<UIViewController *> *resolvedPages = nil;
    if (self.pagesFromPageIdentifiers) {
        // [EN] Created from page IDs: the new tabs get their pages from the same sources; a tab whose page ID already has a
        //      page keeps it (its state too), the others are created, the rest are skipped (docs/Tab-Page-Registry.md).
        // [CN] 由页面 ID 创建：新的 Tab 从同样的来源获得页面；页面 ID 已有页面的 Tab 继续使用它（状态保留），其余创建，找不到的跳过
        //      （docs/Tab-Page-Registry.md）。
        NSMutableArray<NSDictionary *> *keptItems = [NSMutableArray array];
        resolvedPages = [self cyl_pagesOfReloadedTabs:tabBarItemsAttributes keptTabs:keptItems];
        tabBarItemsAttributes = keptItems;
    }
    _tabBarItemsAttributes = tabBarItemsAttributes;
    // [EN] The tab buttons are built again: their covers and badges too. [CN] Tab 按钮会重新创建：其封面与角标也需要重新添加。
    [self cyl_rearmViewDidLayoutSubviewsBlockInvokeOnce];
    self.tabBarItemAnimationViewAdded = NO;
    [_tabBarItemAnimationURLs removeAllObjects];
    [_tabBarItemAnimationSizes removeAllObjects];
    NSInteger index = [self selectedIndex];
    // FIX: issue #618 — `selectedIndex` is not always a valid index into `_viewControllers` (e.g. NSNotFound, or an
    // extra tab UIKit created for a child that is not in `viewControllers`). Do not index out of range.
    UIViewController *selected = (index >= 0 && index < (NSInteger)_viewControllers.count) ? _viewControllers[index] : nil;
    UIView *superView = selected.view.superview;
    NSMutableArray<UIViewController *> *viewControllers = resolvedPages ? [resolvedPages mutableCopy] : [_viewControllers mutableCopy];
    if (resolvedPages && selected && [viewControllers indexOfObjectIdenticalTo:selected] == NSNotFound) {
        // [EN] The selected tab is gone: select the first one. [CN] 选中的 Tab 已不存在：选中第一个。
        selected = nil;
        superView = nil;
        index = 0;
    }
    if (!resolvedPages && [self hasPlusChildViewController]) {
        // [EN] FIX: issue #515 — remove the plus child view controller itself: with a custom plus button position its index
        //      is not always `cyl_plusButtonIndex` (Liquid Glass keeps it in the middle), and another tab was removed.
        // [CN] 直接移除 PlusButton 子控制器本身：自定义 PlusButton 位置时，其下标不一定等于 `cyl_plusButtonIndex`（液态玻璃中位于中间），以前会移除其他 Tab。
        UIViewController *plusChildViewController = [self cyl_contextPlusChildViewController];
        NSUInteger plusChildIndex = plusChildViewController ? [viewControllers indexOfObject:plusChildViewController] : NSNotFound;
        if (plusChildIndex != NSNotFound) {
            [viewControllers removeObjectAtIndex:plusChildIndex];
        }
    }
    [self setViewControllers:viewControllers];
    [self cyl_adoptPendingPages];
    // FIX: issue #433
    // [EN] The reloaded tabs show the selected title on the selected tab.
    // [CN] 重新加载后，选中的 Tab 显示选中标题。
    CYLSetNeedsUpdateTabBarItemSelectedTitles(self);
    [self.view setNeedsLayout];
    if (!resolvedPages || (index >= 0 && index < (NSInteger)self.viewControllers.count)) {
        self.selectedIndex = index;
    }
    if (superView && selected) {
        [superView addSubview:selected.view];
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/*!
 * [EN] The pages of reloaded tabs (`-reloadTabBarItemsWithAttributes:` on a controller created from page IDs): the
 *      attributes are normalized like a configuration (platforms, version, placeholders), a tab reuses an existing page of
 *      its page ID when one is left (in tab order), the other tabs are resolved through the controller's sources, and
 *      `cyl_skippedTabs` is replaced.
 * [CN] 重新加载的 Tab 的页面（由页面 ID 创建的控制器调用 `-reloadTabBarItemsWithAttributes:`）：属性像配置一样规范化（平台、版本、占位），
 *      页面 ID 还有剩余已有页面的 Tab 复用它（按 Tab 顺序），其余 Tab 通过控制器的页面来源解析，`cyl_skippedTabs` 被替换。
 */
- (NSArray<UIViewController *> *)cyl_pagesOfReloadedTabs:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                                keptTabs:(NSMutableArray<NSDictionary *> *)keptTabs {
    NSDictionary<NSString *, id> *normalized = [CYLTabBarController cyl_normalizedConfiguration:@{
        CYLTabBarControllerTabBarItemsAttributes : [tabBarItemsAttributes isKindOfClass:[NSArray class]] ? tabBarItemsAttributes : @[],
    }];
    NSMutableArray<CYLTabBarSkippedTab *> *skipped = [NSMutableArray array];
    NSArray<NSDictionary *> *tabs = CYLResolvableTabs(normalized[CYLTabBarControllerTabBarItemsAttributes] ?: @[], skipped);
    NSMutableDictionary<NSString *, NSMutableArray<UIViewController *> *> *available = [NSMutableDictionary dictionary];
    [self.pagesByPageIdentifier enumerateKeysAndObjectsUsingBlock:^(NSString *pageIdentifier, NSMutableArray<UIViewController *> *pages, BOOL *stop) {
        available[pageIdentifier] = [pages mutableCopy];
    }];
    // [EN] One entry per tab: the reused page, or NSNull for a tab to resolve. [CN] 每个 Tab 一项：复用的页面，或待解析时为 NSNull。
    NSMutableArray<id> *reusedPages = [NSMutableArray array];
    NSMutableArray<NSDictionary<NSString *, id> *> *tabsToResolve = [NSMutableArray array];
    for (NSDictionary *tab in tabs) {
        NSString *pageIdentifier = [CYLTabBarPageRegistry pageIdentifierOfTab:tab];
        UIViewController *page = pageIdentifier ? available[pageIdentifier].firstObject : nil;
        if (page) {
            [available[pageIdentifier] removeObjectAtIndex:0];
            [reusedPages addObject:page];
        } else {
            [reusedPages addObject:[NSNull null]];
            [tabsToResolve addObject:tab];
        }
    }
    NSMutableArray<NSDictionary<NSString *, id> *> *keptNewTabs = [NSMutableArray array];
    NSArray<UIViewController *> *newPages = [CYLTabBarPageRegistry pagesOfTabs:tabsToResolve registry:self.pageRegistry resolver:self.pageResolver
                                                                   lookupOrder:self.pageLookupOrder keptTabs:keptNewTabs skipped:skipped];
    NSMutableArray<UIViewController *> *pages = [NSMutableArray array];
    NSUInteger newIndex = 0;
    for (NSUInteger index = 0; index < tabs.count; index++) {
        NSDictionary *tab = tabs[index];
        if (reusedPages[index] != [NSNull null]) {
            [pages addObject:reusedPages[index]];
            [keptTabs addObject:tab];
        } else if (newIndex < keptNewTabs.count && keptNewTabs[newIndex] == tab) {
            UIViewController *page = newPages[newIndex];
            newIndex++;
            if ([reusedPages indexOfObjectIdenticalTo:page] != NSNotFound) {
                // [EN] A provider returned a page another tab keeps. [CN] 提供者返回了其他 Tab 继续使用的页面。
                [skipped addObject:[CYLTabBarSkippedTab skippedTabWithReason:CYLTabBarPageSkipReasonProviderFailed
                                                              pageIdentifier:[CYLTabBarPageRegistry pageIdentifierOfTab:tab] attributes:tab
                                                                      detail:@"the page is already the page of another tab"]];
                continue;
            }
            [pages addObject:page];
            [keptTabs addObject:tab];
        }
    }
    self.pagesByPageIdentifier = CYLPagesByPageIdentifier(pages, keptTabs);
    self.skippedTabs = [skipped copy];
    return pages;
}

/**
 * [CN] 利用 KVC 把系统的 tabBar 类型改为自定义类型。
 *  仅限 CYLTabBar，在ViewDidLoad中调用
 *  不涉及 CYLTabBarStyleTypeFlatDesign样式（ 会在 setViewControllers 内部设置。）
 * [EN] Use KVC to change the system tabBar's type to a custom type.
 *      CYLTabBar only; called in ViewDidLoad
 *      Does not cover the CYLTabBarStyleTypeFlatDesign style (that is set inside setViewControllers.)
 */
- (void)setUpDefaultStyleTabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self setUpTabBar:nil];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/**
 * [CN] 利用 KVC 把系统的 tabBar 类型改为自定义类型。
 *  包含所有样式类型：
 *   CYLTabBar，在ViewDidLoad中调用；因为考虑到PlusButton的逻辑， 涉及坐标计算，还有运行中增删 PlusButton的逻辑，需要涉及重新布局，需要layoutSubviews中进行。故延迟调用。
 *   CYLTabBarStyleTypeFlatDesign样式 会在 setViewControllers 内部调用，调用时机靠前。
 * [EN] Use KVC to change the system tabBar's type to a custom type.
 *      Covers all style types:
 *      CYLTabBar: called in ViewDidLoad. Because the PlusButton logic involves coordinate calculation, plus
 *      adding and removing
 *      the PlusButton at runtime, which requires relayout, this must happen in layoutSubviews, so the call
 *      is deferred.
 *      CYLTabBarStyleTypeFlatDesign style: called inside setViewControllers, which happens earlier.
 */
- (void)setUpTabBar:(UIView __kindof *)_tabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN //Not CYLTabBarStyleTypeFlatDesign
    @try {
        CYLTabBar *tabBar = (CYLTabBar *)_tabBar;
        if (!tabBar) {
            tabBar = [[CYLTabBar alloc] init];
            [tabBar cyl_setTabBarController:self];
            _cyl_tabBar = tabBar;
        }
        [self cyl_setValue:tabBar forKey:@"tabBar"];
        [self setUpIPADForTabBar:tabBar];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@: reason %@"), @(__PRETTY_FUNCTION__), @(__LINE__), @"setUpTabBar failed", exception.reason);
#endif
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/** [CN] ipados 18 固定tabbar 在底部 */
/* [EN] Pin the tabbar to the bottom on iPadOS 18 */
- (void)setUpIPADForTabBar:(CYLTabBar *)tabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if (@available(iOS 18.0, *)) {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            self.mode = UITabBarControllerModeTabBar;
            self.traitOverrides.horizontalSizeClass = UIUserInterfaceSizeClassCompact;
            BOOL setupSuccess = NO;
            [self.view addSubview:tabBar];
            for (UIView *subview in self.view.subviews) {
                NSString *tabContainerClassName = [NSString stringWithFormat:@"%@%@%@", @"_UITab", @"Container", @"View"];
                if ([NSStringFromClass(subview.class) isEqualToString:tabContainerClassName]) {
                    [subview setHidden:YES];
                    setupSuccess = YES;
                }
            }
            if (!setupSuccess) {
                // [CN] 防止未来类名变动， 暂时不会调用。
                // [EN] Guards against future class name changes; not called for now.
                [self.cyl_tabBar removeFromSuperview];
                [self.view addSubview:self.cyl_tabBar];
            }
        }
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (BOOL)hasPlusChildViewController {
    // Bound to this controller by its `context`, see `-hasPlusButton`.
    // 通过本控制器的 `context` 绑定，见 `-hasPlusButton`。
    return [self cyl_contextPlusChildViewController] != nil;
}

- (BOOL)isPlusViewControllerAdded:(NSArray *)viewControllers {
    BOOL isAdded = [self cyl_isPlusViewControllerAdded:viewControllers];
    return isAdded;
}

/*!
 * FIX: issue #618 — diagnostics only (DEBUG / BETA builds); release behavior is unchanged.
 * [EN] In the classic style, `viewControllers` is CYL's own list (`@synthesize viewControllers = _viewControllers`) and
 *      each tab is installed with `-addChildViewController:`. Any other child added to the tab bar controller (by app
 *      code, or by a library such as ZFPlayer during rotation) can become an extra, untitled tab when UIKit rebuilds the
 *      tab bar, e.g. after a rotation on iOS 18. That tab has no entry in `viewControllers`, and tapping it crashes inside
 *      UIKit, where no breakpoint stops. CYL cannot refuse the child (players rely on it), so it reports it here.
 *      A `tabBarItemsAttributes` array whose count differs from the tabs is reported too: the extra entries draw tab
 *      content (title, image) for tabs that have no view controller.
 * [CN] 经典样式下，`viewControllers` 是 CYL 自己维护的数组（`@synthesize viewControllers = _viewControllers`），每个 Tab
 *      通过 `-addChildViewController:` 添加。若有其他子控制器被直接添加到 TabBarController（App 代码，或横屏切换时的
 *      ZFPlayer 等第三方库），UIKit 重建 TabBar 时（如 iOS 18 旋转后）可能多出一个无标题的 Tab。该 Tab 在
 *      `viewControllers` 中没有对应项，点击后在 UIKit 内部崩溃，无法断点。CYL 不能拒绝该子控制器（播放器依赖它），因此在此提示。
 *      `tabBarItemsAttributes` 数量与 Tab 数量不一致时同样提示：多出的配置会为不存在控制器的 Tab 显示标题和图标。
 */
- (void)addChildViewController:(UIViewController *)childController {
    [super addChildViewController:childController];
#if defined(DEBUG) || defined(BETA)
    [self cyl_logChildViewControllerThatIsNotATabIfNeeded:childController];
#endif
}

#if defined(DEBUG) || defined(BETA)
- (void)cyl_logChildViewControllerThatIsNotATabIfNeeded:(UIViewController *)childController {
    if (!childController || CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
        return;
    }
    if ([_viewControllers containsObject:childController] ||
        childController == [self cyl_contextPlusChildViewController] ||
        childController.cyl_isPlaceholder) {
        return;
    }
    // UIKit adds controllers of its own (the "More" navigation controller, the iPad sidebar on iOS 18); those are not
    // app tabs. Matched by class name so that the lazy `moreNavigationController` getter is never triggered from here.
    NSString *className = NSStringFromClass([childController class]);
    if ([className hasPrefix:@"_"] || [className hasPrefix:@"UI"]) {
        return;
    }
    NSLog(@"🔴[CYL #618] %@ was added to %@ with -addChildViewController:, not through `viewControllers`. UIKit can turn it into an extra, untitled tab (e.g. after a rotation), and tapping that tab crashes. Present it, or push it from a tab's navigation controller, instead. See https://github.com/ChenYilong/CYLTabBarController/issues/618",
          className, NSStringFromClass([self class]));
}

- (void)cyl_logTabBarItemsAttributesMismatchIfNeeded {
    NSUInteger attributesCount = _tabBarItemsAttributes.count;
    if (attributesCount == 0) {
        return;
    }
    // [EN] The slot's own entry (Liquid Glass, FlatDesign) is not counted either. [CN] slot 自己的属性项（液态玻璃、扁平样式）同样不计。
    attributesCount = [self cyl_tabBarItemsAttributesByRemovingPlusSlot:_tabBarItemsAttributes].count;
    NSUInteger tabCount = [self cyl_viewControllersByRemovingPlusSlot:_viewControllers].count;
    if (attributesCount == tabCount) {
        return;
    }
    NSLog(@"🔴[CYL #618] tabBarItemsAttributes has %lu entries for %lu tab view controllers (the plus button's view controller not counted). Each tab needs exactly one entry; a mismatch shows tabs without a view controller, and tapping one can crash. See https://github.com/ChenYilong/CYLTabBarController/issues/618",
          (unsigned long)attributesCount, (unsigned long)tabCount);
}
#endif

/*!
 * [EN] FIX: more than five tabs showed only the first five on the classic style and Liquid Glass, with no "More": that
 *      path installs the tabs with -addChildViewController:, and UIKit builds its "More" tab only in -setViewControllers:,
 *      so the sixth tab and later could not be reached. With more than five tabs they are handed to UIKit too, as
 *      FlatDesign does; five or fewer keep the old path unchanged.
 * [CN] FIX：经典样式与液态玻璃下超过 5 个 Tab 时只显示前 5 个且没有「More」：这条路径用 -addChildViewController: 安装 Tab，而 UIKit
 *      只在 -setViewControllers: 中生成「More」，因此第 6 个及之后的 Tab 无法访问。超过 5 个时也交给 UIKit（与扁平样式相同）；
 *      5 个及以内保持原来的路径不变。
 */
- (void)cyl_handTabsToUIKitIfMoreThanFive {
    if (_viewControllers.count <= 5) {
        return;
    }
    // [EN] UIKit adds "More" only for view controllers that are not children yet (found with a plain
    //      UITabBarController: -addChildViewController: then -setViewControllers: gives five tabs and no More), so the
    //      children this path added are taken out first; UIKit adds them back.
    // [CN] UIKit 只为尚未成为子控制器的视图控制器生成「More」（用普通 UITabBarController 验证：先 -addChildViewController: 再
    //      -setViewControllers: 只有 5 个 Tab 且没有 More），因此先移除这条路径添加的子控制器，由 UIKit 重新添加。
    NSArray<UIViewController *> *tabs = _viewControllers;
    for (UIViewController *viewController in tabs) {
        if (viewController.parentViewController == self) {
            [viewController willMoveToParentViewController:nil];
            [viewController removeFromParentViewController];
        }
    }
    // [EN] `viewControllers` is this class's own list (`@synthesize`), which UIKit reads as the old tabs: with the same
    //      array it saw no change and added nothing. The list is empty while UIKit takes the tabs, then restored.
    // [CN] `viewControllers` 是本类自己的数组（`@synthesize`），UIKit 会把它当作旧 Tab 读取：数组相同时它认为没有变化，什么也不添加。
    //      UIKit 接收 Tab 期间该数组为空，之后恢复。
    _viewControllers = nil;
    [super setViewControllers:tabs animated:NO];
    _viewControllers = tabs;
}

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    // Known from now on (`+cyl_tabBarControllerForContext:`), but not "active" until it appears. Only with view
    // controllers: a nil / empty array is also what a tear-down sends, when no weak reference may be formed.
    // 从现在起可以被查到（`+cyl_tabBarControllerForContext:`），但在显示之前不算“活跃”。只在有 viewControllers 时记录：
    // 销毁过程中传入的也是 nil / 空数组，此时不能再建立弱引用。
    if (viewControllers.count > 0) {
        [CYLTabBarController cyl_registerTabBarController:self];
    }
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
        //#if CYL_FLATDESIGN_AVAILABLE
        //    CYLFlatDesignTabBar *pureCustomTabBar;
        //    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType && [_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        //        pureCustomTabBar = [CYLFlatDesignTabBar new];
        //        [self setUpTabBar:pureCustomTabBar];
        //    }
        //#endif
    
        if (_viewControllers && (_viewControllers.count > 0)) {
            for (UIViewController *viewController in _viewControllers) {
                [viewController willMoveToParentViewController:nil];
                [viewController.view removeFromSuperview];
                [viewController removeFromParentViewController];
            }
            BOOL isAdded = [self isPlusViewControllerAdded:_viewControllers];
            BOOL hasPlusChildViewController = [self hasPlusChildViewController] && !isAdded;
            if (hasPlusChildViewController) {
                [[self cyl_contextPlusChildViewController] willMoveToParentViewController:nil];
                [[self cyl_contextPlusChildViewController].view removeFromSuperview];
                [[self cyl_contextPlusChildViewController] removeFromParentViewController];
            }
            // FIX: issue #608
            // [EN] Re-assigning `viewControllers` (e.g. a new set of tabs after login) crashed on the next tap on iOS 16 with
            //      "Inconsistency in UITabBar items and view controllers detected. No view controller matches the
            //      UITabBarItem". The classic style installs tabs with -addChildViewController: and never calls super's
            //      -setViewControllers:, so removing the old children above does not tell UIKit those tabs are gone: the tab
            //      bar kept the old items while `viewControllers` (CYL's own list) held only the new controllers, and
            //      UIKit's tap handling found no controller for the tapped item. Clear UIKit's tab list too, so the new
            //      tabs are installed exactly as on the first assignment.
            // [CN] 重新给 `viewControllers` 赋值（如登录后换成另一组 Tab）后，iOS 16 上再点击会崩溃：
            //      "Inconsistency in UITabBar items and view controllers detected. No view controller matches the UITabBarItem"。
            //      经典样式用 -addChildViewController: 添加 Tab，从不调用父类的 -setViewControllers:，上面移除旧子控制器并不会
            //      让 UIKit 知道旧 Tab 已不存在：TabBar 仍保留旧的 item，而 `viewControllers`（CYL 自己的数组）只有新控制器，
            //      UIKit 处理点击时找不到对应的控制器。这里同时清空 UIKit 的 Tab 列表，让新 Tab 与首次赋值时一样安装。
            [super setViewControllers:nil animated:NO];
        }
    
        if (!viewControllers || viewControllers.count == 0 || ![viewControllers isKindOfClass:[NSArray class]]) {
            for (UIViewController *viewController in _viewControllers) {
                CYLTabBarController *tabBarController = nil;
                [[viewController cyl_getViewControllerInsteadOfNavigationController] cyl_setTabBarController:tabBarController];
                [viewController cyl_setTabBarController:tabBarController];
            }
            _viewControllers = nil;
            return;
        }
    
        [self alignTabControlIfNeededWithViewControllers:viewControllers];
#if defined(DEBUG) || defined(BETA)
        [self cyl_logTabBarItemsAttributesMismatchIfNeeded];
#endif
    
        // [EN] The app's own tabs: a slot carried by `viewControllers` (a re-assignment) is not a tab.
        // [CN] App 自己的 Tab 数：`viewControllers` 自带的 slot（重新赋值时）不算 Tab。
        [self.cyl_tabBar cyl_setTabbarItemsCount:[self cyl_viewControllersByRemovingPlusSlot:viewControllers].count];
        if (![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
            // [EN] FIX: placeholder count mismatch — `_viewControllers` is already aligned above; assigning the array passed
            //      in again dropped the plus child view controller (or kept a stale slot it carried).
            // [CN] FIX：占位导致的数量不匹配——`_viewControllers` 已在上面对齐；以前这里又赋值为传入的数组，丢失 PlusButton 子控制器
            //      （或保留了数组自带的旧 slot）。
            [self cyl_handTabsToUIKitIfMoreThanFive];
            return;
        }
        CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;

        [cyl_tabBar cyl_setTabBarItemWidth:(cyl_tabBar.cyl_boundsSize.width - cyl_tabBar.cyl_plusButtonWidth) / (cyl_tabBar.cyl_tabbarItemsCount)];
        NSUInteger idx = 0;
        for (UIViewController *viewController in _viewControllers) {
            // [EN] FIX: issue #604 — one place reads a tab item's attributes, for every style. [CN] 所有样式共用同一处读取 Tab item 属性的代码。
            CYLTabBarItemSetup *setup = [self cyl_tabBarItemSetupForViewController:viewController idx:idx];
            idx = setup.idx;
            NSString *title = setup.title;
            id normalImageInfo = setup.normalImageInfo;
            id selectedImageInfo = setup.selectedImageInfo;
            UIOffset titlePositionAdjustment = setup.titlePositionAdjustment;
            UIOffset imagePositionAdjustment = setup.imagePositionAdjustment;
            UIEdgeInsets imageInsets = setup.imageInsets;
            NSURL *lottieURL = setup.animationURL;
            NSValue *lottieSizeValue = setup.animationSizeValue;
            // [EN] A placeholder without its own slot entry keeps the placeholder image (same tab item layout with or without
            //      that entry).
            // [CN] 没有自己 slot 属性项的占位控制器使用占位图片（有无该项时 TabBarItem 的布局相同）。
            if (viewController.cyl_isPlaceholder && ![self cyl_tabBarItemsAttributesIncludePlusSlot]) {
                normalImageInfo = [UIImage cyl_tabItemPlaceholderImage];
                selectedImageInfo = [UIImage cyl_tabItemPlaceholderImage];
            }
        
            [self addOneChildViewController:viewController
                                  WithTitle:title
                            normalImageInfo:normalImageInfo
                          selectedImageInfo:selectedImageInfo
                    titlePositionAdjustment:titlePositionAdjustment
                    imagePositionAdjustment:imagePositionAdjustment
                                imageInsets:imageInsets
                                  lottieURL:lottieURL
                            lottieSizeValue:lottieSizeValue
         
            ];
        
        
            //        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType && [_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
            // [CN] //已经在addOneChildViewController 中操作， 这里无需重复处理
            // [EN] Already handled in addOneChildViewController, no need to handle it again here
            //            // [self addChildViewController:viewController];
            //
            //            if (!viewController.cyl_isPlaceholder && ![viewController cyl_isEqualToViewController:[self cyl_contextPlusChildViewController]]) {
            //#if CYL_FLATDESIGN_AVAILABLE
            //                pureCustomTabBar.delegate = self;
            //                CYLFlatDesignTabBarItem *tabItem = [pureCustomTabBar addItemWithTitle:title
            //                                                                      tabBarItemImage:normalImageInfo
            //                                                              tabBarItemSelectedImage:selectedImageInfo
            //                                                                                index:idx
            //                                                              titlePositionAdjustment:titlePositionAdjustment
            //                                                                          imageInsets:imageInsets
            //                                                                       lottieFilePath:lottieFilePath
            //                                                                      lottieSizeValue:lottieSizeValue];
            //                [viewController cyl_setTabButton:tabItem];
            //                [[viewController cyl_getViewControllerInsteadOfNavigationController] cyl_setTabButton:tabItem];
            //#endif
            //
            //            }
            //        }
            [viewController cyl_setTabBarController:self];
            [[viewController cyl_getViewControllerInsteadOfNavigationController] cyl_setTabBarController:self];
            [viewController.cyl_getActualBadgeSuperView cyl_setTabBarController:self];
            [[viewController cyl_getViewControllerInsteadOfNavigationController].cyl_getActualBadgeSuperView cyl_setTabBarController:self];
            [viewController.tabBarItem.cyl_getActualBadgeSuperView cyl_setTabBarController:self];
            [[viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem.cyl_getActualBadgeSuperView cyl_setTabBarController:self];
        
            idx++;
        }
        [self cyl_handTabsToUIKitIfMoreThanFive];
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}

    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        _needsReloadItems = YES;
        // [EN] The app's own tabs and their attributes: a re-assignment may carry the slot (and its attributes), which
        //      shifted `idx` below by one after the slot, and inserted a second slot.
        // [CN] App 自己的 Tab 及其属性：重新赋值时可能带有 slot（及其属性），以前会使下面 slot 之后的 `idx` 错位一个，并插入第二个 slot。
        viewControllers = [self cyl_viewControllersByRemovingPlusSlot:viewControllers];
        _tabBarItemsAttributes = [self cyl_tabBarItemsAttributesByRemovingPlusSlot:_tabBarItemsAttributes];
        __weak __typeof(self) weakSelf = self;
        [viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull childVC, NSUInteger idx, BOOL * _Nonnull stop) {
            __strong typeof(self) self = weakSelf;
            if (!self) {
                return;
            }
            [childVC cylflatdesign_setTabBarController:self];
            [self setupChildViewController:childVC idx:idx];;
            [childVC cyl_setTabButton:childVC.cyl_tabBarItem.tabBarButton];
            //TODO: if (_tabBarItemsAttributes.count > idx)
        }];
        [self.cyl_tabBar cyl_setTabbarItemsCount:[viewControllers count]];
        [super setViewControllers:viewControllers];
        if (@available(iOS 27.1, *)) {
            _cylDidRefreshSystemTabBarVisibility = NO;
            if (self.isViewLoaded) { [self.view setNeedsLayout]; }
        }
        //    _viewControllers = viewControllers;
        [self alignTabControlIfNeededWithViewControllers:viewControllers];
        // Legacy global (what was written last); this tab bar's own index is `-[UIView cyl_plusButtonIndex]`. Read after
        // the slot is inserted: it is the slot's index in `viewControllers`.
        // 旧的全局变量（最后写入的值）；本 TabBar 自己的下标见 `-[UIView cyl_plusButtonIndex]`。在插入 slot 之后读取：即 slot 在 `viewControllers` 中的下标。
        CYLPlusButtonIndex = [self.cyl_tabBar cyl_plusButtonIndex];
        if (_needsReloadItems) {
            [self _captureItems];
            [self.cyl_tabBar setItems:self.items];
            _needsReloadItems = NO;
        }
        CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;

        cyl_tabBar.selectedItem = self.selectedViewController.cyl_tabBarItem;
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    [self cyl_loadTabBarItemImageURLs];
}

/*!
 * FIX: issue #601
 * [EN] Every tab whose attributes have `CYLTabBarItemImageURL` shows the downloaded icons once ready; until then, and on
 *      failure, its `CYLTabBarItemImage` (the placeholder).
 * [CN] 属性中带 `CYLTabBarItemImageURL` 的 Tab，在下载完成后显示下载的图标；此前及失败时显示其 `CYLTabBarItemImage`（占位图）。
 */
- (void)cyl_loadTabBarItemImageURLs {
    for (NSUInteger index = 0; index < _viewControllers.count; index++) {
        NSUInteger attributesIndex = [self cyl_tabBarItemsAttributesIndexOfViewControllerAtIndex:index];
        if (attributesIndex < _tabBarItemsAttributes.count) {
            [self cyl_loadImageURLsOfAttributes:_tabBarItemsAttributes[attributesIndex] atIndex:index];
        }
    }
}

- (BOOL)cyl_loadImageURLsOfAttributes:(NSDictionary *)attributes atIndex:(NSUInteger)index {
    id icon = attributes[CYLTabBarItemImageURL];
    if (!icon) {
        return NO;
    }
    NSValue *sizeValue = attributes[CYLTabBarItemImageURLSize];
    CGSize size = [sizeValue isKindOfClass:[NSValue class]] ? sizeValue.CGSizeValue : CGSizeZero;
    // [EN] The same sources as `-setTabBarItemIcon:selectedIcon:size:atIndex:`: a URL, and also a local image.
    // [CN] 与 `-setTabBarItemIcon:selectedIcon:size:atIndex:` 相同的来源：URL，也可以是本地图片。
    return [self setTabBarItemIcon:icon selectedIcon:attributes[CYLTabBarItemSelectedImageURL] size:size atIndex:index];
}

- (void)setTintColor:(UIColor *)tintColor {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 8.f) {
        CYL_DEPRECATED_DECLARATIONS_PUSH
        [self.cyl_tabBar setSelectedImageTintColor:tintColor];
        CYL_DEPRECATED_DECLARATIONS_POP
    }
    self.cyl_tabBar.tintColor = tintColor;
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
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

/*!
 * FIX: issue #475 (titlePositionAdjustment has no effect on iOS 13)
 * [EN] Since iOS 13 a tab bar that uses `UITabBarAppearance` (any `tabBar.standardAppearance = ...`, which most apps do
 *      for dark mode or iOS 15's transparent bar) ignores `-[UITabBarItem titlePositionAdjustment]`: the title offset
 *      comes from the item appearances of the bar appearance instead. So a tab with an offset also gets its own
 *      `standardAppearance` (and `scrollEdgeAppearance` on iOS 15+): a copy of the tab bar's, with the offset written
 *      into every layout and state. The copy is rebuilt when the tab bar's appearance changes (checked on layout), and an
 *      appearance the app installed on the item itself is kept as the base and restored when the offset is reset.
 * [CN] iOS 13 起，使用 `UITabBarAppearance` 的 TabBar（任何 `tabBar.standardAppearance = ...`，多数 App 为深色模式或 iOS 15
 *      透明 TabBar 都会这样设置）会忽略 `-[UITabBarItem titlePositionAdjustment]`，标题偏移改由 bar appearance 中的 item
 *      appearance 决定。因此有偏移的 Tab 还会得到自己的 `standardAppearance`（iOS 15+ 还有 `scrollEdgeAppearance`）：TabBar
 *      appearance 的副本，偏移写入每种布局与状态。TabBar 的 appearance 改变时（布局时检查）会重建副本；App 自己在 item 上
 *      设置的 appearance 会作为基础保留，偏移重置时恢复。
 */
#define CYLTitlePositionAdjustmentItemOffsetKey ((const void *)sel_registerName("cyl_titlePositionAdjustmentItemOffset"))

/// The offset a tab asked for itself (`CYLTabBarItemTitlePositionAdjustment`), so a new controller-level offset does not
/// replace it. 记录 Tab 自身设置的偏移，避免被控制器级别的新偏移覆盖。
static void CYLRememberItemTitlePositionAdjustment(id _Nullable item, UIOffset offset) {
    id object = item;
    if (!object) {
        return;
    }
    BOOL isZero = UIOffsetEqualToOffset(UIOffsetZero, offset);
    objc_setAssociatedObject(object, CYLTitlePositionAdjustmentItemOffsetKey, isZero ? nil : [NSValue valueWithUIOffset:offset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static UIOffset CYLTitlePositionAdjustmentForItem(id _Nullable item, UIOffset controllerOffset) {
    id object = item;
    NSValue *itemOffset = object ? objc_getAssociatedObject(object, CYLTitlePositionAdjustmentItemOffsetKey) : nil;
    return itemOffset ? itemOffset.UIOffsetValue : controllerOffset;
}

// [EN] The per-item appearances (title offset and per-tab colors) and `-cyl_syncTitlePositionAdjustmentAppearances` are
//      Swift (Swift/CYLTabBarController+CYLTitlePositionAdjustment.swift, docs/Swift-Migration.md, step 57).
// [CN] 每个 item 的 appearance（标题偏移与单个 Tab 颜色）及 `-cyl_syncTitlePositionAdjustmentAppearances` 已迁移到 Swift（第 57 步）。

- (void)setTitlePositionAdjustment:(UIOffset)titlePositionAdjustment {
    _titlePositionAdjustment = titlePositionAdjustment;
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        for (UIViewController *viewController in self.viewControllers) {
            // Read the stored item: the getter creates a placeholder item when there is none.
            // 读取已保存的 item：没有时 getter 会创建占位 item。
            CYLFlatDesignTabBarItem *flatItem = objc_getAssociatedObject(viewController, @selector(cyl_tabBarItem));
            if (![flatItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
                continue;
            }
            flatItem.titlePositionAdjustment = CYLTitlePositionAdjustmentForItem(flatItem, titlePositionAdjustment);
        }
        // The tab buttons read the offset in `-layoutSubviews`. Tab 按钮在 `-layoutSubviews` 中读取偏移。
        for (UIView *subview in _cyl_tabBar.subviews) {
            [subview setNeedsLayout];
        }
        [_cyl_tabBar setNeedsLayout];
#endif
        return;
    }
    for (UIViewController *viewController in self.viewControllers) {
        UITabBarItem *tabBarItem = viewController.tabBarItem;
        [self cyl_applyTitlePositionAdjustment:CYLTitlePositionAdjustmentForItem(tabBarItem, titlePositionAdjustment) toTabBarItem:tabBarItem];
    }
}

#pragma mark - Image insets at runtime (issue #95)

static char CYLImageInsetsItemKey;

static void CYLRememberItemImageInsets(id _Nullable item, UIEdgeInsets insets) {
    id object = item;
    if (!object) {
        return;
    }
    BOOL isZero = UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, insets);
    objc_setAssociatedObject(object, &CYLImageInsetsItemKey, isZero ? nil : [NSValue valueWithUIEdgeInsets:insets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#if CYL_FLATDESIGN_AVAILABLE
// [EN] Only the FlatDesign branch below reads it; without FlatDesign it would be an unused function.
// [CN] 只有下方的扁平样式分支使用；不包含扁平样式时会成为未使用的函数。
static UIEdgeInsets CYLImageInsetsForItem(id _Nullable item, UIEdgeInsets controllerInsets) {
    id object = item;
    NSValue *itemInsets = object ? objc_getAssociatedObject(object, &CYLImageInsetsItemKey) : nil;
    return itemInsets != nil ? itemInsets.UIEdgeInsetsValue : controllerInsets;
}
#endif

/*!
 * FIX: issue #95
 * [EN] `imageInsets` could only be passed to `-init…imageInsets:titlePositionAdjustment:…`, so an app that creates the
 *      controller with `-initWithViewControllers:tabBarItemsAttributes:` (e.g. in a config class) had no way to set it.
 *      This re-applies the insets to the tabs already added; a tab's own `CYLTabBarItemImageInsets` keeps precedence.
 *      The automatic centering of image-only tabs (`automaticallyAdjustsImageOnlyTabs`) yields to non-zero insets, and
 *      takes over again when they are reset to zero.
 * [CN] 以前 `imageInsets` 只能通过 `-init…imageInsets:titlePositionAdjustment:…` 传入，使用
 *      `-initWithViewControllers:tabBarItemsAttributes:` 创建控制器（例如在 config 类中）的 App 无法设置。
 *      本方法会对已添加的 Tab 重新应用内边距；Tab 自身的 `CYLTabBarItemImageInsets` 仍然优先。
 *      纯图标 Tab 的自动居中（`automaticallyAdjustsImageOnlyTabs`）在内边距非零时让出，重置为零后重新生效。
 */
- (void)updateImageInsets:(UIEdgeInsets)imageInsets {
    _imageInsets = imageInsets;
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        for (UIViewController *viewController in self.viewControllers) {
            // Read the stored item: the getter creates a placeholder item when there is none.
            // 读取已保存的 item：没有时 getter 会创建占位 item。
            CYLFlatDesignTabBarItem *flatItem = objc_getAssociatedObject(viewController, @selector(cyl_tabBarItem));
            if (![flatItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
                continue;
            }
            flatItem.imageInsets = CYLImageInsetsForItem(flatItem, imageInsets);
        }
        for (UIView *subview in _cyl_tabBar.subviews) {
            [subview setNeedsLayout];
        }
        [_cyl_tabBar setNeedsLayout];
#endif
        return;
    }
    for (UIViewController *viewController in self.viewControllers) {
        UITabBarItem *tabBarItem = viewController.tabBarItem;
        if (objc_getAssociatedObject(tabBarItem, &CYLImageInsetsItemKey)) {
            continue;
        }
        // The controller's insets replace what the image-only adjustment wrote: forget that part of its record.
        // 控制器的内边距替换纯图标自动调整写入的值：清除其记录中的这一部分。
        NSDictionary<NSString *, NSValue *> *record = objc_getAssociatedObject(tabBarItem, CYLImageOnlyTabAdjustmentKey);
        if (record) {
            NSMutableDictionary<NSString *, NSValue *> *newRecord = [record mutableCopy];
            [newRecord removeObjectsForKeys:@[ CYLImageOnlyTabOriginalInsetsKey, CYLImageOnlyTabAppliedInsetsKey ]];
            objc_setAssociatedObject(tabBarItem, CYLImageOnlyTabAdjustmentKey, newRecord.count > 0 ? [newRecord copy] : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (!UIEdgeInsetsEqualToEdgeInsets(tabBarItem.imageInsets, imageInsets)) {
            tabBarItem.imageInsets = imageInsets;
        }
    }
    if (UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, imageInsets) && [_cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        CGFloat offset = ((CYLTabBar *)_cyl_tabBar).tabImageViewDefaultOffset;
        if (offset != 0.f) {
            [self offsetTabBarTabImageViewToFit:offset];
        }
    }
}

#pragma mark - tabBar.standardAppearance (all styles)

/// Observed tab bar, see `-cyl_startObservingStandardAppearance`. 被观察的 TabBar，见 `-cyl_startObservingStandardAppearance`。
static char CYLObservedStandardAppearanceTabBarKey;

#if CYL_FLATDESIGN_AVAILABLE
/*!
 * [EN] FlatDesign: the per-tab colors (`CYLTabBarItemTitleColor`, `CYLTabBarItemSelectedTitleColor`,
 *      `CYLTabBarItemSelectedBackgroundColor`) go to the flat item's own title attributes and selected background color.
 *      Only changed values are written, so a layout pass does not trigger another one.
 * [CN] 扁平样式：单个 Tab 的颜色（`CYLTabBarItemTitleColor`、`CYLTabBarItemSelectedTitleColor`、`CYLTabBarItemSelectedBackgroundColor`）
 *      写入扁平 item 自身的标题属性与选中背景色。只写入有变化的值，避免布局时再次触发布局。
 */
- (void)cyl_syncFlatDesignTabBarItemColors {
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    for (NSUInteger index = 0; index < viewControllers.count; index++) {
        NSDictionary *attributes = [self tabBarItemAttributesAtIndex:index];
        if (!attributes) {
            continue;
        }
        // Read the stored item: the getter creates a placeholder item when there is none.
        // 读取已保存的 item：没有时 getter 会创建占位 item。
        CYLFlatDesignTabBarItem *flatItem = objc_getAssociatedObject(viewControllers[index], @selector(cyl_tabBarItem));
        if (![flatItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
            continue;
        }
        NSDictionary<NSNumber *, NSString *> *titleColorKeys = @{ @(UIControlStateNormal) : CYLTabBarItemTitleColor,
                                                                  @(UIControlStateSelected) : CYLTabBarItemSelectedTitleColor };
        [titleColorKeys enumerateKeysAndObjectsUsingBlock:^(NSNumber *stateValue, NSString *key, BOOL *stop) {
            id color = attributes[key];
            if (![color isKindOfClass:[UIColor class]]) {
                return;
            }
            UIControlState state = (UIControlState)stateValue.unsignedIntegerValue;
            NSDictionary<NSAttributedStringKey, id> *current = [flatItem titleTextAttributesForState:state];
            if ([current[NSForegroundColorAttributeName] isEqual:color]) {
                return;
            }
            NSMutableDictionary<NSAttributedStringKey, id> *textAttributes = [current mutableCopy] ?: [NSMutableDictionary dictionary];
            textAttributes[NSForegroundColorAttributeName] = color;
            [flatItem setTitleTextAttributes:textAttributes forState:state];
        }];
        // [EN] Title fonts: the selected state uses the unselected font unless it has its own.
        // [CN] 标题字体：选中状态没有单独设置时使用未选中的字体。
        id titleFont = attributes[CYLTabBarItemTitleFont];
        id selectedTitleFont = attributes[CYLTabBarItemSelectedTitleFont] ?: titleFont;
        NSDictionary<NSNumber *, id> *fontsByState = @{ @(UIControlStateNormal) : titleFont ?: [NSNull null],
                                                        @(UIControlStateSelected) : selectedTitleFont ?: [NSNull null] };
        [fontsByState enumerateKeysAndObjectsUsingBlock:^(NSNumber *stateValue, id font, BOOL *stop) {
            if (![font isKindOfClass:[UIFont class]]) {
                return;
            }
            UIControlState state = (UIControlState)stateValue.unsignedIntegerValue;
            NSDictionary<NSAttributedStringKey, id> *current = [flatItem titleTextAttributesForState:state];
            if ([current[NSFontAttributeName] isEqual:font]) {
                return;
            }
            NSMutableDictionary<NSAttributedStringKey, id> *textAttributes = [current mutableCopy] ?: [NSMutableDictionary dictionary];
            textAttributes[NSFontAttributeName] = font;
            [flatItem setTitleTextAttributes:textAttributes forState:state];
        }];
        id normalBackgroundColor = attributes[CYLTabBarItemBackgroundColor];
        if ([normalBackgroundColor isKindOfClass:[UIColor class]] && ![flatItem.backgroundColor isEqual:normalBackgroundColor]) {
            flatItem.backgroundColor = normalBackgroundColor;
        }
        id selectedBackgroundColor = attributes[CYLTabBarItemSelectedBackgroundColor];
        if ([selectedBackgroundColor isKindOfClass:[UIColor class]] && ![flatItem.selectedBackgroundColor isEqual:selectedBackgroundColor]) {
            flatItem.selectedBackgroundColor = selectedBackgroundColor;
        }
    }
}
#endif

#pragma mark - Tab accessibility (identifiers, labels, hints)

// [EN] `-cyl_syncTabBarItemAccessibility` and its helpers are Swift (Swift/CYLTabBarController+CYLAccessibility.swift,
//      docs/Swift-Migration.md, step 55). [CN] `-cyl_syncTabBarItemAccessibility` 及其辅助函数已迁移到 Swift（第 55 步）。

// [EN] `-cyl_setNeedsUpdateSelectedBackgroundColors`, `-cyl_updateSelectedBackgroundColorsOfTabButtons`,
//      `-cyl_updateBadgesOfSelectedTab`, `cyl_hidesBadgeOfSelectedTab` and `-cyl_syncTabBarAppearances` are Swift
//      (Swift/CYLTabBarController+CYLTabBarItemColors.swift, docs/Swift-Migration.md, step 56).
// [CN] 上述方法已迁移到 Swift（第 56 步）。

#if CYL_LOTTIE_AVAILABLE
/// [EN] Calls a no-argument method only when `object` implements it (Lottie 2.x and 4.x views differ).
/// [CN] 仅当 `object` 实现了该无参方法时才调用（Lottie 2.x 与 4.x 的视图不同）。
static void CYLCallIfImplemented(id object, SEL selector) {
    if (![object respondsToSelector:selector]) {
        return;
    }
    IMP implementation = [object methodForSelector:selector];
    ((void (*)(id, SEL))implementation)(object, selector);
}
#endif

/*!
 * [EN] `CYLTabBarLottieLoopsWhenUnselected`: the Lottie views of those tabs loop while unselected and pause while selected.
 *      Idempotent (a playing view is left playing), so it also runs on layout, once the views exist.
 * [CN] `CYLTabBarLottieLoopsWhenUnselected`：这些 Tab 的 Lottie 视图未选中时循环播放，选中时暂停。可重复调用（正在播放的视图不受影响），
 *      因此在布局时、视图创建之后也会执行。
 */
- (void)cyl_updateLoopingLottieViews {
#if CYL_LOTTIE_AVAILABLE
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    for (NSUInteger index = 0; index < viewControllers.count; index++) {
        NSDictionary *attributes = [self tabBarItemAttributesAtIndex:index];
        if (![attributes[CYLTabBarLottieLoopsWhenUnselected] respondsToSelector:@selector(boolValue)] ||
            ![attributes[CYLTabBarLottieLoopsWhenUnselected] boolValue]) {
            continue;
        }
        UIViewController *viewController = viewControllers[index];
        UIControl *control = viewController.tabBarItem.cyl_tabButton ?: viewController.cyl_tabButton;
        if (!control) {
            continue;
        }
        NSMutableArray<UIControl *> *controls = [NSMutableArray arrayWithObject:control];
        // [EN] Liquid Glass shows the tab twice (normal and selected layer). [CN] 液态玻璃中每个 Tab 显示两份（普通层与选中层）。
        UIControl *selectedLayerControl = [CYLConstants isLiquidGlassActive] ? [control cyl_platterSelectedControl] : nil;
        if (selectedLayerControl && selectedLayerControl != control) {
            [controls addObject:selectedLayerControl];
        }
        BOOL selected = (viewController == self.selectedViewController);
        for (UIControl *eachControl in controls) {
            UIView *lottieView = [eachControl cyl_tabBarItemAnimationView];
            if (!lottieView) {
                continue;
            }
            if (selected) {
                CYLCallIfImplemented(lottieView, NSSelectorFromString(@"pause"));
                continue;
            }
            // [EN] Lottie 4.x bridge: loopAnimationCount -1 loops; Lottie 2.x: loopAnimation.
            // [CN] Lottie 4.x 桥接：loopAnimationCount 为 -1 时循环；Lottie 2.x：loopAnimation。
            if ([lottieView respondsToSelector:NSSelectorFromString(@"setLoopAnimationCount:")]) {
                [lottieView setValue:@(-1) forKey:@"loopAnimationCount"];
            } else if ([lottieView respondsToSelector:NSSelectorFromString(@"setLoopAnimation:")]) {
                [lottieView setValue:@YES forKey:@"loopAnimation"];
            }
            BOOL playing = [lottieView respondsToSelector:NSSelectorFromString(@"isAnimationPlaying")] &&
                [[lottieView valueForKey:@"isAnimationPlaying"] boolValue];
            if (!playing) {
                CYLCallIfImplemented(lottieView, NSSelectorFromString(@"play"));
            }
        }
    }
#endif
}

/// `UITabBar.scrollEdgeAppearance` exists from iOS 15, `standardAppearance` from iOS 13.
/// [CN] `UITabBar.scrollEdgeAppearance` 自 iOS 15 起提供，`standardAppearance` 自 iOS 13 起提供。
/// [EN] `UITabBar.scrollEdgeAppearance` is available since iOS 15, `standardAppearance` since iOS 13.
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

#pragma mark - FlatDesign standardAppearance

/*!
 * [EN] Only compiled when the CYLFlatDesignTabBar subspec is integrated (`CYL_FLATDESIGN_AVAILABLE`), and only run for
 *      `CYLTabBarStyleTypeFlatDesign`: Liquid Glass and the classic style never reach it.
 * [CN] 仅在集成了 CYLFlatDesignTabBar 子库时编译（`CYL_FLATDESIGN_AVAILABLE`），且仅在 `CYLTabBarStyleTypeFlatDesign` 时执行：
 *      液态玻璃与经典样式不会执行这里的代码。
 */
#if CYL_FLATDESIGN_AVAILABLE

/*!
 * [EN] One `UITabBarAppearance` for every style: what the app assigns to `tabBar.standardAppearance` (and to a child's
 *      `tabBarItem.standardAppearance`) is mirrored to the flat design tab bar (and its item), which maps it onto its own
 *      views, see `-[CYLFlatDesignTabBar standardAppearance]`. The system tab bar's default appearance is not mirrored,
 *      so without one the flat design look stays as it was. Synced on layout and, through KVO, as soon as
 *      `tabBar.standardAppearance` is assigned (layout still catches it if KVO is not delivered).
 * [CN] 所有样式共用一个 `UITabBarAppearance`：App 赋给 `tabBar.standardAppearance`（以及子控制器 `tabBarItem.standardAppearance`）
 *      的值会同步到扁平样式 TabBar（及其 item），由其映射到自身视图，见 `-[CYLFlatDesignTabBar standardAppearance]`。系统 TabBar
 *      的默认 appearance 不会同步，因此未设置时扁平样式外观保持不变。在布局时同步；并通过 KVO 在 `tabBar.standardAppearance` 赋值后
 *      立即同步（若未收到 KVO，布局时仍会同步）。
 */
static char CYLDefaultStandardAppearanceKey;
static char CYLSyncedStandardAppearanceKey;
static char CYLSyncedItemStandardAppearanceKey;

- (void)cyl_recordDefaultStandardAppearance {
    if (@available(iOS 13.0, *)) {
        if (!objc_getAssociatedObject(self, &CYLDefaultStandardAppearanceKey)) {
            UITabBarAppearance *standardAppearance = self.tabBar.standardAppearance;
            if (standardAppearance) {
                objc_setAssociatedObject(self, &CYLDefaultStandardAppearanceKey, standardAppearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
}

/// YES when `appearance` is not the system tab bar's default one. `appearance` 不是系统 TabBar 的默认值时为 YES。
- (BOOL)cyl_isCustomizedStandardAppearance:(nullable UITabBarAppearance *)appearance API_AVAILABLE(ios(13.0)) {
    if (!appearance) {
        return NO;
    }
    UITabBarAppearance *defaultAppearance = objc_getAssociatedObject(self, &CYLDefaultStandardAppearanceKey) ?: [[UITabBarAppearance alloc] init];
    return appearance != defaultAppearance && ![appearance isEqual:defaultAppearance];
}

static BOOL CYLAppearanceChanged(id _Nullable appearance, id _Nullable syncedAppearance) {
    if (appearance == syncedAppearance) {
        return NO;
    }
    return !(appearance && [appearance isEqual:syncedAppearance]);
}

- (void)cyl_syncFlatDesignStandardAppearance {
    if (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType || ![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        return;
    }
    if (@available(iOS 13.0, *)) {
        CYLFlatDesignTabBar *flatDesignTabBar = (CYLFlatDesignTabBar *)_cyl_tabBar;
        UITabBarAppearance *standardAppearance = self.tabBar.standardAppearance;
        id syncedAppearance = objc_getAssociatedObject(self, &CYLSyncedStandardAppearanceKey);
        // Back to the default appearance: give the flat design look back, unless the app set the flat bar's own.
        // 恢复为默认 appearance：还原扁平样式外观，除非 App 直接设置了扁平 TabBar 自身的 appearance。
        UITabBarAppearance *mirroredAppearance = [self cyl_isCustomizedStandardAppearance:standardAppearance] ? standardAppearance : nil;
        if (CYLAppearanceChanged(mirroredAppearance, syncedAppearance)) {
            UITabBarAppearance *flatAppearance = flatDesignTabBar.standardAppearance;
            BOOL flatAppearanceIsMirrored = !flatAppearance || [flatAppearance isEqual:syncedAppearance];
            if (mirroredAppearance || flatAppearanceIsMirrored) {
                flatDesignTabBar.standardAppearance = mirroredAppearance;
            }
            objc_setAssociatedObject(self, &CYLSyncedStandardAppearanceKey, mirroredAppearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        for (UIViewController *viewController in self.viewControllers) {
            // Read the stored item: the getter creates a placeholder item when there is none.
            // 读取已保存的 item：没有时 getter 会创建占位 item。
            CYLFlatDesignTabBarItem *flatItem = objc_getAssociatedObject(viewController, @selector(cyl_tabBarItem));
            if (![flatItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
                continue;
            }
            UITabBarAppearance *itemAppearance = viewController.tabBarItem.standardAppearance;
            id syncedItemAppearance = objc_getAssociatedObject(flatItem, &CYLSyncedItemStandardAppearanceKey);
            if (CYLAppearanceChanged(itemAppearance, syncedItemAppearance)) {
                flatItem.standardAppearance = itemAppearance;
                objc_setAssociatedObject(flatItem, &CYLSyncedItemStandardAppearanceKey, itemAppearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }
    }
}


#endif // CYL_FLATDESIGN_AVAILABLE

- (UIImage *)getImageFromImageInfo:(id)imageInfo {
    UIImage *image = [UIImage cyl_getImageFromImageInfo:imageInfo];
    return image;
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

#pragma mark - Override selectedViewController (User initiated)

- (void)setSelectedViewController:(__kindof UIViewController *)selectedViewController {
    [self cyl_setNeedsUpdateTabBarItemIconViews];
    [self cyl_setNeedsUpdateSelectedBackgroundColors];
    NSUInteger indexOfSelectedViewController = [self.childViewControllers indexOfObject:selectedViewController];
    // [EN] A tab shown under "More" (more than five tabs) is a child of the More navigation controller, not of this
    //      controller: it is still one of the tabs, so it can be selected.
    // [CN] 收在「More」下的 Tab（超过 5 个 Tab 时）是 More 导航控制器的子控制器而不是本控制器的：它仍是一个 Tab，可以被选中。
    if (NSNotFound == indexOfSelectedViewController && ![self.viewControllers containsObject:selectedViewController]) { return; }
    [super setSelectedViewController:selectedViewController];
    _selectedViewController = selectedViewController;
    // FIX: issue #433
    // [EN] Show the selected title on the selected tab.
    // [CN] 选中的 Tab 显示选中标题。
    CYLSetNeedsUpdateTabBarItemSelectedTitles(self);

    if (selectedViewController.cyl_isPlaceholder) { return; }

#if CYL_FLATDESIGN_AVAILABLE
    NSArray *viewControllers = self.viewControllers;
    NSUInteger selectedIndex = NSNotFound;
    if (viewControllers) {
        selectedIndex = [viewControllers indexOfObject:selectedViewController];
    }
    if (NSNotFound != selectedIndex) {
        _selectedIndex = selectedIndex;
    }
#endif

    //           NSUInteger indexOfSelectedViewController = [self.childViewControllers indexOfObject:selectedViewController];
    //            if (NSNotFound == indexOfSelectedViewController) { return; }
    
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        // [CN] 必须调用父类逻辑。
        // [EN] Must call the superclass logic.
        //    _selectedViewController = selectedViewController;
        //
        //    [super setSelectedViewController:selectedViewController];
        // [CN] Fix: #574 解决iOS15 扁平风格， 有时候TabBar会变透明的问题
        // [EN] Fix: #574 Fixes an issue where the TabBar sometimes became transparent with the flat style on iOS15
        if (CYL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"15.0") && ![CYLConstants isLiquidGlassActive]) {
            if (nil == [UITabBar appearance].backgroundImage) {
                @try {
                    // [CN] 因为非核心功能， 仅为部分版本的细节修复， 所以用try catch 防止异常， 防止影响主要功能。
                    // [EN] Since this is not a core feature, only a detail fix for some versions, use try catch to prevent exceptions
                    //      from affecting the main functionality.
                    if (self.cyl_tabBar.cyl_tabBackgroundView && self.cyl_tabBar.cyl_tabBackgroundView.cyl_tabEffectView) {
                        self.cyl_tabBar.cyl_tabBackgroundView.cyl_tabEffectView.alpha = 1;
                    }
                    if (self.cyl_tabBar.cyl_tabShadowImageView && (self.cyl_tabBar.cyl_tabShadowImageView.subviews.count > 0)) {
                        self.cyl_tabBar.cyl_tabShadowImageView.subviews.firstObject.alpha = 1;
                    }
                } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
                    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
                }
            }
        }
    
        if (![CYLConstants isLiquidGlassActive]) {
            return;
        }
        //  iOS26 液态玻璃样式 不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
    
        // 用户点击 tab 时会触发 //showing initial vc for every tab :)
        UIControl *control = selectedViewController.cyl_tabButton;
        if ([selectedViewController isEqual:[self cyl_contextPlusChildViewController]]) {
            [self cyl_contextPlusButton].selected = YES;
            [self tabChangedToSelectedIndex:[self.cyl_tabBar cyl_plusButtonIndex]
                             viewController:selectedViewController
                                    control:[self cyl_contextPlusButton]];
        } else {
            [self tabChangedToSelectedIndex:self.selectedIndex
                             viewController:selectedViewController
                                    control:control];
        }
        [self cyl_setNeedsLiquidGlassTabBarResample];
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}


    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (NSNotFound == selectedIndex) { return; }
        //  iOS26 液态玻璃样式 不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
            
        // 用户点击 tab 时会触发 //showing initial vc for every tab :)
        //        UIControl *control = selectedViewController.cyl_tabButton;
        if ([selectedViewController isEqual:[self cyl_contextPlusChildViewController]]) {
            [self cyl_contextPlusButton].selected = YES;
        } else {
        }
            
        [self tabChangedToSelectedIndex:selectedIndex viewController:selectedViewController selectedItem:nil];
        
        [self _updateBottomBarShowHideIfNeeded];
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

/*!
 * FIX: issue #646 — mitigation, not verified on device.
 * [EN] iOS 26 Liquid Glass tab bars switch between light and dark based on the content behind them. Reported:
 *      with one black tab and one white tab whose view is filled by a UIScrollView (bottomEdgeEffect hidden),
 *      switching tabs sometimes leaves the bar tinted for the previous tab's background. `translucent = NO`
 *      avoids it but makes the whole bottom area opaque, not just the capsule.
 *      After the switch, on the next run loop (once the new tab's view is in place), re-lay out the system
 *      tab bar and re-register the new tab's bottom content scroll view (only when it has one), so UIKit
 *      re-evaluates what is behind the glass. A tab without a scroll view is left on automatic detection.
 * [CN] iOS 26 液态玻璃 TabBar 会根据其背后的内容在浅色/深色之间切换。反馈：一个黑色 Tab、一个由铺满的
 *      UIScrollView 构成的白色 Tab（隐藏了 bottomEdgeEffect），切换时偶现 TabBar 仍保持上一个 Tab 的底色。
 *      `translucent = NO` 可以规避，但会让整个底部区域不透明，而不仅是胶囊。
 *      切换后在下一个 runloop（新 Tab 的 view 已就位）重新布局系统 TabBar，并为新 Tab 重新注册底部
 *      content scroll view（仅当存在时），促使 UIKit 重新评估玻璃背后的内容。没有 scroll view 的 Tab 保持自动检测。
 */
- (void)cyl_setNeedsLiquidGlassTabBarResample {
    if (![CYLConstants isLiquidGlassActive]) { return; }
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf) { return; }
        UIViewController *selectedViewController = strongSelf.selectedViewController;
        if ([selectedViewController isKindOfClass:[UINavigationController class]]) {
            selectedViewController = ((UINavigationController *)selectedViewController).topViewController ?: selectedViewController;
        }
        if (@available(iOS 15.0, *)) {
            UIScrollView *contentScrollView = [selectedViewController contentScrollViewForEdge:NSDirectionalRectEdgeBottom];
            if (contentScrollView) {
                [selectedViewController setContentScrollView:contentScrollView forEdge:NSDirectionalRectEdgeBottom];
            }
        }
        [strongSelf.tabBar setNeedsLayout];
        [strongSelf.tabBar layoutIfNeeded];
    });
}

/*!
 * FIX: issue #594 — only when a CYLPlusButton subclass is registered and implements `+plusChildViewController`
 *      (`-hasPlusButton` and `-hasPlusChildViewController` both YES); otherwise nothing changes.
 * [EN] A tab is selected either in code (`-setSelectedIndex:`) or by a tap (`-[CYLPlusButton
 *      plusChildViewControllerButtonClicked:]`, which calls `-setSelectedIndex:` too). Both go through this method.
 *      Selecting the plus button's child view controller in code (e.g. an initial `selectedIndex` equal to the plus
 *      button's index) showed that page, but the plus button was not selected. With no control given,
 *      `-tabChangedToSelectedIndex:viewController:control:` fell back to `CYLPlusChildViewController.cyl_tabButton`, the
 *      system tab button under the plus button, and marked that one selected. A tap (`-plusChildViewControllerButtonClicked:`)
 *      selects the plus button itself. Use the plus button here too, unless `+shouldSelectPlusChildViewController` opts out
 *      (a tap does not select it then either).
 * [CN] 仅适用于注册了 CYLPlusButton 子类并实现了 `+plusChildViewController` 的场景（`-hasPlusButton` 与
 *      `-hasPlusChildViewController` 均为 YES），其他情况不变。Tab 的选中有两种触发方式：代码（`-setSelectedIndex:`）和用户点击
 *      （`-[CYLPlusButton plusChildViewControllerButtonClicked:]`，内部同样调用 `-setSelectedIndex:`），两者都经过本方法。
 *      用代码选中 PlusButton 对应的子控制器（如初始 `selectedIndex` 设为 PlusButton 的下标）时，页面正确显示，但 PlusButton
 *      没有被选中：未传入 control 时，`-tabChangedToSelectedIndex:viewController:control:` 会使用
 *      `CYLPlusChildViewController.cyl_tabButton`，即 PlusButton 下方的系统 Tab 按钮，并把它设为选中。点击 PlusButton
 *      （`-plusChildViewControllerButtonClicked:`）选中的是 PlusButton 本身。这里同样使用 PlusButton，除非
 *      `+shouldSelectPlusChildViewController` 返回 NO（此时点击也不会选中）。
 */
- (UIControl *)cyl_plusButtonControlIfSelectingPlusChildViewController:(UIViewController *)viewController {
    if (!viewController || ![self cyl_contextPlusButton] || ![self hasPlusButton] || ![self hasPlusChildViewController]) {
        return nil;
    }
    if (![viewController cyl_isEqualToViewController:[self cyl_contextPlusChildViewController]]) {
        return nil;
    }
    Class plusButtonClass = [[self cyl_contextPlusButton] class];
    if ([plusButtonClass respondsToSelector:@selector(shouldSelectPlusChildViewController)] &&
        ![plusButtonClass shouldSelectPlusChildViewController]) {
        return nil;
    }
    return [self cyl_contextPlusButton];
}

#pragma mark - Override selectedIndex (Programmatic changes)

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    [self cyl_setNeedsUpdateTabBarItemIconViews];
    [self cyl_setNeedsUpdateSelectedBackgroundColors];
    //    if (self.selectedIndex == selectedIndex) { return; }
    // FIX: issue #441
    // [EN] The index of the placeholder that stands for a plus button without a child view controller (Liquid Glass,
    //      FlatDesign) selects nothing: it used to select that empty placeholder page (or return halfway), so
    //      `setSelectedIndex:` looked like it did nothing. `selectedIndex` counts that placeholder; to use the index in
    //      your own view controllers, set `cyl_selectedIndexIgnoringPlusButton` instead (issue #515).
    // [CN] 没有子控制器的 PlusButton 对应的占位控制器（液态玻璃、扁平样式）的下标不会选中任何内容：以前会选中这个空白占位页（或中途返回），
    //      看起来 `setSelectedIndex:` 没有生效。`selectedIndex` 会计入该占位控制器；如需使用你自己的控制器数组中的下标，请改为设置
    //      `cyl_selectedIndexIgnoringPlusButton`（issue #515）。
    if (selectedIndex < self.viewControllers.count && self.viewControllers[selectedIndex].cyl_isPlaceholder) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"[CYLTabBarController] setSelectedIndex:%@ is the plus button's placeholder and is ignored; use cyl_selectedIndexIgnoringPlusButton for the index without the plus button (issue #441).", @(selectedIndex));
#endif
        return;
    }
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        [super setSelectedIndex:selectedIndex];
    
        UIViewController *selectedViewController;
        if (self.viewControllers && self.viewControllers.count > 0 && self.viewControllers.count > selectedIndex) {
            selectedViewController = [self.viewControllers objectAtIndex:selectedIndex];
            self.selectedViewController = selectedViewController;
        }
        // [CN] iOS26 液态玻璃样式 不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
        // 代码切换 tab 时会触发
        // [EN] The iOS26 Liquid Glass style no longer uses tap events; this is handled in
        //      `-setSelectedViewController` and `-setSelectedIndex` instead
        //      Triggered when the tab is switched in code
        if (YES == _selectedViewController.cyl_isPlaceholder) {
            return;
        }
        [self tabChangedToSelectedIndex:selectedIndex
                         viewController:selectedViewController
                                control:[self cyl_plusButtonControlIfSelectingPlusChildViewController:selectedViewController]];
    
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (self.selectedIndex != selectedIndex) {
            _selectedIndex = selectedIndex;
            // [EN] FIX: placeholder count mismatch — `selectedIndex` counts the slot, the system list (`[super viewControllers]`)
            //      does not have a placeholder and has a plus child view controller at its end: pass super the index of the same
            //      view controller in its own list.
            // [CN] FIX：占位导致的数量不匹配——`selectedIndex` 计入了 slot，而系统列表（`[super viewControllers]`）中没有占位控制器，
            //      PlusButton 子控制器位于末尾：传给 super 的是同一个控制器在系统列表中的下标。
            UIViewController *viewControllerToSelect = (selectedIndex < self.viewControllers.count) ? self.viewControllers[selectedIndex] : nil;
            NSUInteger systemIndex = viewControllerToSelect ? [[super viewControllers] indexOfObject:viewControllerToSelect] : NSNotFound;
            if (systemIndex != NSNotFound) {
                [super setSelectedIndex:systemIndex];
            }
            if (selectedIndex < 0 || selectedIndex >= self.viewControllers.count) { return; }
            // `_selectedIndex` is already the new index, so `-[super setSelectedIndex:]` above sees no change and does not
            // show the tab: in code (`selectedIndex = …`, `cyl_popSelect…`) the tab bar item changed but the old tab
            // stayed on screen. Show it the way a tap does, through super (the override would report it again).
            // `_selectedIndex` 已经是新值，上面的 `-[super setSelectedIndex:]` 认为没有变化，不会显示该 Tab：代码切换
            // （`selectedIndex = …`、`cyl_popSelect…`）时 TabBarItem 变了，屏幕上仍是旧 Tab。这里与点击一样通过 super 显示（重写的方法会再次回调）。
            [super setSelectedViewController:self.viewControllers[selectedIndex]];
            _selectedViewController = self.viewControllers[selectedIndex];
            if (_needsReloadItems) {
                [self _captureItems];
                [self.cyl_tabBar setItems:self.items];
                _needsReloadItems = NO;
            }
            // [CN] TODO:  这里避免使用selectedViewController，因为 self.viewControllers 被经过PlusButton补充，
            // [EN] TODO:  Avoid using selectedViewController here, because self.viewControllers has been supplemented
            //      with the PlusButton,
            //        self.cyl_tabBar.selectedItem = selectedItem;
            [self tabChangedToSelectedIndex:selectedIndex viewController:nil selectedItem:nil];
            
        }
        // FIX: issue #433
        // [EN] Show the selected title on the selected tab.
        // [CN] 选中的 Tab 显示选中标题。
        CYLSetNeedsUpdateTabBarItemSelectedTitles(self);
        [self _updateBottomBarShowHideIfNeeded];
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    
}

- (CGSize)visiableTabBarSize {
    return self.cyl_tabBarController.tabBar.cyl_boundsSize;
}

/*!
 * [CN] 三个地方 ， 都要调用：
 *  选中状态下的重新点击，（iOS26 需要在手势代理方法中进行hook追加该方法）
 *  用户切换index时
 *  代码切换index 时。
 * [EN] Must be called from all three places:
 *      Re-tapping an already selected tab (on iOS26 this needs to be hooked in via the gesture delegate method)
 *      When the user switches the index
 *      When the index is switched in code.
 **/
#if CYL_FLATDESIGN_AVAILABLE
- (void)tabChangedToSelectedIndex:(NSUInteger)selectedIndex
                   viewController:(UIViewController *)viewController
                     selectedItem:(CYLFlatDesignTabBarItem *)selectedItem {
    
    CYL_IF_FLATDESIGN_BEGIN
    
    // [CN] 扁平样式可使用
    // [EN] Available for the flat design style
    if (![self.tabBar isKindOfClass:[UITabBar class]] && ![self.tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        return;
    }
    //    BOOL isChildViewControllerPlusButton = [control cyl_isChildViewControllerPlusButton];
    //    BOOL isLottieEnabled = [self isLottieEnabled];
    
    // [CN] TODO:  setSelectedIndex 这里避免使用selectedViewController，因为 self.viewControllers 被经过PlusButton补充，
    // [EN] TODO:  setSelectedIndex Avoid using selectedViewController here, because self.viewControllers has been
    //      supplemented with the PlusButton,
    
    if (!self.items || self.items.count == 0) {
        return;
    }
    if ([self _showsMoreNavigationController]) {
        NSInteger moreIndex = [self.tabBar.items indexOfObject:self.moreNavigationController.tabBarItem];
        if (selectedIndex >= moreIndex) {
            selectedItem = self.moreNavigationController.cyl_tabBarItem;
        } else {
            selectedItem = self.items[selectedIndex];
        }
    } else {
        selectedItem = self.items[selectedIndex];
    }
    
    CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;

    cyl_tabBar.selectedItem = selectedItem;
    CYL_IF_FLATDESIGN_END
}
#else
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
