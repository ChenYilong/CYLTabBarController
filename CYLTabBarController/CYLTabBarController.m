//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"
#import "CYLTabBar.h"
#import "UIViewController+CYLSettingsSection.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "NSObject+CYLTabBarControllerExtention.h"

#if __has_include(<Lottie/Lottie.h>)
#import <Lottie/Lottie.h>
#else
#endif

#if __has_include(<Lottie/Lottie-Swift.h>)
#import <Lottie/Lottie-Swift.h>
#else

#endif


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


#if __has_include(<CYLTabBarController/CYLTabBarController.h>)
//#import <CYLTabBarController/CYLTabBarController.h>
//#import <CYLTabBarController/UIImage+CYLTabBarControllerExtention.h>
//#import <CYLTabBarController/NSObject+CYLTabBarControllerExtention.h>
#else
//#import "CYLTabBarController.h"
//#import "UIImage+CYLTabBarControllerExtention.h"
//#import "NSObject+CYLTabBarControllerExtention.h"
#endif

NSString *const CYLTabBarItemTitle = @"CYLTabBarItemTitle";
NSString *const CYLTabBarItemImage = @"CYLTabBarItemImage";
NSString *const CYLTabBarItemSelectedImage = @"CYLTabBarItemSelectedImage";
NSString *const CYLTabBarItemDarkImage = @"CYLTabBarItemDarkImage";
NSString *const CYLTabBarItemSelectedDarkImage = @"CYLTabBarItemSelectedDarkImage";
NSString *const CYLTabBarItemImageURL = @"CYLTabBarItemImageURL";
NSString *const CYLTabBarItemSelectedImageURL = @"CYLTabBarItemSelectedImageURL";
NSString *const CYLTabBarItemImageURLSize = @"CYLTabBarItemImageURLSize";
NSString *const CYLTabBarItemImageInsets = @"CYLTabBarItemImageInsets";
NSString *const CYLTabBarItemTitlePositionAdjustment = @"CYLTabBarItemTitlePositionAdjustment";
NSString *const CYLTabBarItemImagePositionAdjustment = @"CYLTabBarItemImagePositionAdjustment";
NSString *const CYLTabBarLottieFilePath = @"CYLTabBarLottieFilePath";
NSString *const CYLTabBarLottieURL = @"CYLTabBarLottieURL";
NSString *const CYLTabBarLottieSize = @"CYLTabBarLottieSize";
NSString *const CYLTabBarItemIdentifier = @"CYLTabBarItemIdentifier";
NSString *const CYLTabBarItemTitleColor = @"CYLTabBarItemTitleColor";
NSString *const CYLTabBarItemSelectedTitleColor = @"CYLTabBarItemSelectedTitleColor";
NSString *const CYLTabBarItemIconColor = @"CYLTabBarItemIconColor";
NSString *const CYLTabBarItemSelectedIconColor = @"CYLTabBarItemSelectedIconColor";
NSString *const CYLTabBarItemSelectedBackgroundColor = @"CYLTabBarItemSelectedBackgroundColor";
NSString *const CYLTabBarItemBackgroundColor = @"CYLTabBarItemBackgroundColor";
NSString *const CYLTabBarLottieLoopsWhenUnselected = @"CYLTabBarLottieLoopsWhenUnselected";
NSString *const CYLTabBarItemTitleFont = @"CYLTabBarItemTitleFont";
NSString *const CYLTabBarItemSelectedTitleFont = @"CYLTabBarItemSelectedTitleFont";
NSString *const CYLTabBarItemAccessibilityIdentifier = @"CYLTabBarItemAccessibilityIdentifier";
NSString *const CYLTabBarItemAccessibilityLabel = @"CYLTabBarItemAccessibilityLabel";
NSString *const CYLTabBarItemAccessibilityHint = @"CYLTabBarItemAccessibilityHint";
NSString *const CYLTabBarItemSelectedTitle = @"CYLTabBarItemSelectedTitle";

#pragma mark - Selected title (FIX: issue #433)

static const void *CYLTabBarItemSelectedTitleKey = &CYLTabBarItemSelectedTitleKey;
static const void *CYLTabBarItemNormalTitleKey = &CYLTabBarItemNormalTitleKey;

/*!
 * FIX: issue #433
 * [EN] Remembers the tab's `CYLTabBarItemSelectedTitle` and its normal title on the view controller, or forgets them
 *      when the attributes have no selected title (tabs set up again without it).
 * [CN] 在控制器上记录 Tab 的 `CYLTabBarItemSelectedTitle` 与普通标题；属性中没有选中标题时清除（重新设置 Tab 时去掉了该键）。
 */
static void CYLRememberTabBarItemSelectedTitle(UIViewController *viewController, NSDictionary *attributes, NSString *normalTitle) {
    if (!viewController) {
        return;
    }
    id selectedTitle = attributes[CYLTabBarItemSelectedTitle];
    if (![selectedTitle isKindOfClass:[NSString class]]) {
        selectedTitle = nil;
    }
    objc_setAssociatedObject(viewController, CYLTabBarItemSelectedTitleKey, selectedTitle, OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(viewController, CYLTabBarItemNormalTitleKey, selectedTitle ? (normalTitle ?: @"") : nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

/*!
 * FIX: issue #433
 * [EN] Shows the selected title on the selected tab and the normal title on the others. Idempotent and cheap: only tabs
 *      that have a `CYLTabBarItemSelectedTitle` are touched, and a title is set only when it changes. FlatDesign sets
 *      the title of its own item; the classic style and Liquid Glass set `tabBarItem.title` (and the one of the
 *      navigation controller's root), which UIKit shows.
 * [CN] 选中的 Tab 显示选中标题，其他 Tab 显示普通标题。可重复调用、开销很小：只处理设置了 `CYLTabBarItemSelectedTitle` 的 Tab，
 *      标题变化时才设置。FlatDesign 设置其自身 item 的标题；经典样式与液态玻璃设置 `tabBarItem.title`（以及导航控制器根控制器的），
 *      由 UIKit 显示。
 */
static void CYLApplyTabBarItemSelectedTitles(CYLTabBarController *tabBarController) {
    if (!tabBarController) {
        return;
    }
    UIViewController *selectedViewController = tabBarController.selectedViewController;
    for (UIViewController *viewController in tabBarController.viewControllers) {
        NSString *selectedTitle = objc_getAssociatedObject(viewController, CYLTabBarItemSelectedTitleKey);
        if (!selectedTitle) {
            continue;
        }
        NSString *normalTitle = objc_getAssociatedObject(viewController, CYLTabBarItemNormalTitleKey) ?: @"";
        NSString *title = (viewController == selectedViewController) ? selectedTitle : normalTitle;
        if (CYLTabBarStyleTypeFlatDesign == tabBarController.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
            CYLFlatDesignTabBarItem *item = viewController.cyl_tabBarItem;
            if (item && ![item.title isEqualToString:title]) {
                item.title = title;
            }
#endif
            continue;
        }
        UIViewController *contentViewController = [viewController cyl_getViewControllerInsteadOfNavigationController];
        if (![viewController.tabBarItem.title isEqualToString:title]) {
            viewController.tabBarItem.title = title;
        }
        if (contentViewController && contentViewController != viewController &&
            ![contentViewController.tabBarItem.title isEqualToString:title]) {
            contentViewController.tabBarItem.title = title;
        }
    }
}

/*!
 * FIX: issue #433
 * [EN] Applies the selected titles now, and once more on the next main-queue turn: in the classic style the button's
 *      action can run before UIKit has changed `selectedViewController`.
 * [CN] 立即应用选中标题，并在主队列的下一轮再应用一次：经典样式中按钮事件可能在 UIKit 修改 `selectedViewController` 之前执行。
 */
static void CYLSetNeedsUpdateTabBarItemSelectedTitles(CYLTabBarController *tabBarController) {
    if (!tabBarController) {
        return;
    }
    CYLApplyTabBarItemSelectedTitles(tabBarController);
    __weak CYLTabBarController *weakTabBarController = tabBarController;
    dispatch_async(dispatch_get_main_queue(), ^{
        CYLApplyTabBarItemSelectedTitles(weakTabBarController);
    });
}
NSNotificationName const CYLTabBarLoginStateDidChangeNotification = @"CYLTabBarLoginStateDidChangeNotification";
NSString *const CYLTabBarLottieDarkURL = @"CYLTabBarLottieDarkURL";
NSString *const CYLTabBarLottieDarkFilePath = @"CYLTabBarLottieDarkFilePath";
NSString *const CYLTabBarLottieDarkColors = @"CYLTabBarLottieDarkColors";

NSArray<NSDictionary *> *CYLTabBarItemsAttributesAddingLottieFiles(NSArray<NSDictionary *> *attributes,
                                                                    NSArray<NSString *> *lottieFileNames,
                                                                    NSBundle *bundle) {
    if (lottieFileNames.count == 0) {
        return attributes;
    }
    bundle = bundle ?: [NSBundle mainBundle];
    NSString *darkSuffix = [UIImage cyl_darkImageNameSuffix];
    NSMutableArray<NSDictionary *> *result = [NSMutableArray arrayWithCapacity:attributes.count];
    [attributes enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
        (void)stop;
        NSString *name = idx < lottieFileNames.count ? lottieFileNames[idx] : nil;
        NSString *path = name.length > 0 ? [bundle pathForResource:name ofType:@"json"] : nil;
        if (!path) {
            [result addObject:item];
            return;
        }
        NSMutableDictionary *lottieItem = [item mutableCopy];
        lottieItem[CYLTabBarLottieFilePath] = path;
        NSString *darkPath = darkSuffix.length > 0 ? [bundle pathForResource:[name stringByAppendingString:darkSuffix] ofType:@"json"] : nil;
        if (darkPath) {
            lottieItem[CYLTabBarLottieDarkFilePath] = darkPath;
        }
        [result addObject:[lottieItem copy]];
    }];
    return [result copy];
}

/// FIX: issue #442 — registers the item's dark Lottie animation (`CYLTabBarLottieDarkURL`, else
/// `CYLTabBarLottieDarkFilePath`) for `lottieURL`, the light one. 为浅色动画 `lottieURL` 注册该 item 的深色 Lottie 动画。
static void CYLRegisterDarkLottieURLFromAttributes(NSURL *lottieURL, NSDictionary *attributes) {
    if (!lottieURL) {
        return;
    }
    // First: the #442 keys and whether their values are usable. Without any, and with nothing registered before for this
    // animation, nothing else runs. 首先判断 #442 新增的 key 是否存在、值是否有效；都没有且此前也未注册时，直接返回。
    id darkURLValue = attributes[CYLTabBarLottieDarkURL];
    id darkFilePathValue = attributes[CYLTabBarLottieDarkFilePath];
    id darkColorsValue = attributes[CYLTabBarLottieDarkColors];
    NSURL *darkLottieURL = [darkURLValue isKindOfClass:[NSURL class]] ? darkURLValue : nil;
    if (!darkLottieURL && [darkFilePathValue isKindOfClass:[NSString class]] && [(NSString *)darkFilePathValue length] > 0) {
        darkLottieURL = [CYLConstants cyl_getURLFromString:darkFilePathValue];
    }
    NSDictionary *darkColors = ([darkColorsValue isKindOfClass:[NSDictionary class]] && [(NSDictionary *)darkColorsValue count] > 0) ? darkColorsValue : nil;
    if (!darkLottieURL && !darkColors && ![CYLConstants cyl_hasDarkLottieForLottieURL:lottieURL]) {
        return;
    }
    [CYLConstants cyl_registerDarkLottieURL:darkLottieURL forLottieURL:lottieURL];
    [CYLConstants cyl_registerLottieDarkColors:darkColors forLottieURL:lottieURL];
}

NSUInteger CYLTabbarItemsCount = 0;
NSUInteger CYLPlusButtonIndex = 0;
CGFloat CYLTabBarItemWidth = 0.0f;
CGFloat CYLTabBarHeight = 49.0f;
static const CGFloat kCYLDefaultTabBarHeight = 49.0f;

NSString *const CYLTabBarItemWidthDidChangeNotification = @"CYLTabBarItemWidthDidChangeNotification";
NSString *const CYLTabBarItemLottieAnimationPlayingNotification = @"CYLTabBarItemLottieAnimationPlayingNotification";
NSString *const CYLTabBarItemLottieAnimationViewDidAddNotification = @"CYLTabBarItemLottieAnimationViewDidAddNotification";

NSString *const CYLTabBarStyleTypeDidChangeNotification = @"CYLTabBarStyleTypeDidChangeNotification";
static void * const CYLTabImageViewDefaultOffsetContext = (void*)&CYLTabImageViewDefaultOffsetContext;
static void * const CYLFlatDesignTabBarContext = (void*)&CYLFlatDesignTabBarContext;
/// The system tab bar's `standardAppearance` / `scrollEdgeAppearance`: synced to the tabs' title offsets (issue #475) and to
/// the flat design tab bar. 系统 TabBar 的 `standardAppearance` / `scrollEdgeAppearance`：同步到 Tab 的标题偏移（issue #475）与扁平样式 TabBar。
static void * const CYLStandardAppearanceContext = (void*)&CYLStandardAppearanceContext;
//static void * const CYLTabBarControllerVisiableItemsCountContext = (void*)&CYLTabBarControllerVisiableItemsCountContext;

/*!
 * [EN] Classic tab bar before iOS 18 (not FlatDesign, not Liquid Glass): duration of the animated
 *      `-setTabBarHidden:animated:`, the same as FlatDesign (`CYLFlatDesignUITabBarControllerHideShowBarDuration`), so
 *      both styles hide and show alike. Outside the FlatDesign guard: the classic style needs it without that subspec.
 * [CN] iOS 18 以前的经典 TabBar（非扁平样式、非液态玻璃）：带动画的 `-setTabBarHidden:animated:` 的时长，与扁平样式
 *      （`CYLFlatDesignUITabBarControllerHideShowBarDuration`）相同，使两种样式的隐藏、显示效果一致。放在扁平样式的 guard 之外：
 *      不含该子库时经典样式同样需要它。
 */
static const NSTimeInterval CYLClassicTabBarHideShowDuration = 0.2;

/*!
 * [EN] Classic tab bar before iOS 18: how far the tab bar moves down to leave the screen, as FlatDesign moves its bar by
 *      its height: the tab bar's height (without a transform), plus the part of the plus button (or any subview) that
 *      sticks up above it, so a raised plus button leaves the screen too.
 * [CN] iOS 18 以前的经典 TabBar：TabBar 移出屏幕需要下移的距离。与扁平样式按 TabBar 高度下移相同：TabBar 的高度（不计 transform），
 *      再加上 PlusButton（或任何子视图）高出 TabBar 的部分，使凸起的 PlusButton 也完全移出屏幕。
 */
static CGFloat CYLClassicTabBarHideDistance(UITabBar *tabBar) {
    CGFloat overflowAbove = 0;
    for (UIView *subview in tabBar.subviews) {
        if (!subview.hidden) {
            overflowAbove = MAX(overflowAbove, -CGRectGetMinY(subview.frame));
        }
    }
    return CGRectGetHeight(tabBar.bounds) + overflowAbove;
}

#if CYL_FLATDESIGN_AVAILABLE
CGFloat const CYLFlatDesignUITabBarControllerHideShowBarDuration = 0.2;

/*!
 * FIX: issue #662
 * [EN] Sets only the bottom of `viewController.additionalSafeAreaInsets`. The More navigation controller used to get a
 *      copy of the selected child's whole insets, which overwrote its own top/left/right.
 * [CN] 只修改 `additionalSafeAreaInsets.bottom`。以前把选中子控制器的整个 insets 拷给 More 导航控制器，覆盖了它自己的上/左/右。
 */
static void CYLSetAdditionalSafeAreaBottom(UIViewController *viewController, CGFloat bottom) {
    UIEdgeInsets insets = viewController.additionalSafeAreaInsets;
    if (insets.bottom == bottom) { return; }
    insets.bottom = bottom;
    viewController.additionalSafeAreaInsets = insets;
}
#else
#endif

@interface CYLTabBarController () <UITabBarControllerDelegate>

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
/// Blocks passed to `-reloadBadgesWithBlock:` that wait for the tab buttons (#404).
@property (nonatomic, strong) NSMutableArray<CYLViewDidLayoutSubViewsBlock> *pendingReloadBadgesBlocks;
/// [EN] The control last reported through `tabBarController:didSelectControl:` in the current run loop turn (one report per tap).
/// [CN] 当前 runloop 中已通过 `tabBarController:didSelectControl:` 上报的控件（每次点击只上报一次）。
@property (nonatomic, weak) UIControl *cyl_controlReportedInCurrentRunLoop;
@property (nonatomic, strong) NSMutableArray<NSURL *> *lottieURLs;
@property (nonatomic, strong) NSMutableArray *lottieSizes;
@property (nonatomic, assign, getter=isLottieViewAdded) BOOL lottieViewAdded;
@property (nonatomic, strong) UIImage *tabItemPlaceholderImage;
@property (nonatomic, copy) NSString *context;
@property (nonatomic, strong) CYLTabBar *tabBar;
@property (nonatomic, assign, readonly) CGRect tabBarFrame;

#if CYL_FLATDESIGN_AVAILABLE
@property (nonatomic, strong) NSMutableArray<CYLFlatDesignTabBarItem *> *items;
@property (nonatomic, assign) BOOL cyl_tabBarHidden;
- (void)_cyl_refreshSystemTabBarVisibilityIfNeeded;
//@property (nonatomic, assign) CYLTabBarStyleType tabBarStyleType;
//@property (nonatomic, readwrite) CYLFlatDesignTabBar *cyl_tabBar;
#else
#endif
@end

/// [EN] Implemented below (CYLTabBarMinimize, issue #13). [CN] 实现见下方 CYLTabBarMinimize（issue #13）。
@interface CYLTabBarController (CYLTabBarMinimizePrivate)
/// [EN] FlatDesign: observe the scroll view of the page on screen. [CN] 扁平样式：观察当前显示页面的滚动视图。
- (void)cyl_updateTabBarMinimizeTracking;
/// [EN] Liquid Glass: expand a tab bar the system minimized (issue #13 lifecycle restore).
/// [CN] 液态玻璃：恢复被系统缩小的 TabBar（issue #13 生命周期恢复）。
- (void)cyl_expandSystemMinimizedTabBar;
/// [EN] Liquid Glass: a new drag started, give the system its minimize behavior back.
/// [CN] 液态玻璃：新的拖动开始，把缩小行为交还给系统。
- (void)cyl_releaseSystemMinimizeHoldIfNeeded;
/// [EN] A view lifecycle event of this controller (appear, disappear, size change): ends any hide session.
/// [CN] 本控制器的视图生命周期事件（出现、消失、尺寸变化）：结束隐藏会话。
- (void)cyl_tabBarMinimizeLifecycleEvent;
/// [EN] Every `-setTabBarHidden:animated:` call: one not made by scroll hiding is the app taking the tab bar over.
/// [CN] 每次 `-setTabBarHidden:animated:` 调用：不是滚动隐藏发出的调用，即 App 接管 TabBar。
- (void)cyl_tabBarMinimizeDidReceiveTabBarHiddenRequest:(BOOL)hidden;
@end

/// [EN] Implemented below (CYLTheme, issue #216). [CN] 实现见下方 CYLTheme（issue #216）。
@interface CYLTabBarController (CYLThemePrivate)
/// [EN] Once, when first shown: the theme chosen at launch. [CN] 首次显示时执行一次：应用启动时选择的主题。
- (void)cyl_applyLaunchTabBarThemeIfNeeded;
/// [EN] Implemented in the main implementation (tabBar.standardAppearance). [CN] 实现于主 implementation（tabBar.standardAppearance）。
- (void)cyl_syncTabBarAppearances;
/// [EN] Implemented in the main implementation: the icon view providers by view controller (theme icons use them).
/// [CN] 实现于主 implementation：按子控制器保存的图标视图 provider（主题图标会使用）。
- (NSMapTable<UIViewController *, CYLTabBarItemIconViewProvider> *)cyl_tabBarItemIconViewProviders;
/// [EN] The theme's icons, in place of each tab's icon. [CN] 主题图标，替换每个 Tab 的图标。
- (void)cyl_applyThemeIconsOfItemsAttributes:(nullable NSArray<NSDictionary<NSString *, id> *> *)itemsAttributes;
/// [EN] Implemented in the main implementation: the plus button's child view controller. [CN] 实现于主 implementation：PlusButton 的子控制器。
- (nullable UIViewController *)cyl_contextPlusChildViewController;
/// [EN] Implemented below (CYLTabBarItemStyle). [CN] 实现见下方（CYLTabBarItemStyle）。
- (void)cyl_applyTabBarItemStyles;
/// [EN] Implemented below (CYLOpaqueTabBarSafeArea). [CN] 实现见下方（CYLOpaqueTabBarSafeArea）。
- (void)cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded;
@end

// [EN] Implemented in CYLTabBarController+CYLInteraction.m: the pressed (highlight / dehighlight) animation of a button.
// [CN] 在 CYLTabBarController+CYLInteraction.m 中实现：按钮的按下（highlight / dehighlight）动画。
@interface CYLTabBarController (CYLTabButtonHighlight)
- (void)cyl_tabButtonTouchDown:(UIControl *)control;
- (void)cyl_tabButtonTouchUp:(UIControl *)control;
@end

/// [EN] Implemented below (CYLReselect). [CN] 实现见下方 CYLReselect。
@interface CYLTabBarController (CYLReselectPrivate)
/// [EN] The view controller of a tab button (classic or Liquid Glass), nil for the plus button. [CN] Tab 按钮对应的控制器，PlusButton 返回 nil。
- (UIViewController *)cyl_viewControllerForTabControl:(UIControl *)control;
/// [EN] Runs `cyl_reselectBehavior` for a reselected tab. [CN] 为重复点击的 Tab 执行 `cyl_reselectBehavior`。
- (void)cyl_performReselectBehaviorForViewController:(UIViewController *)viewController;
@end

/// [EN] Per-tab colors, implemented in the main implementation. [CN] 单个 Tab 的颜色，在主实现中实现。
@interface CYLTabBarController (CYLTabBarItemColorsPrivate)
- (void)cyl_updateSelectedBackgroundColorsOfTabButtons;
- (void)cyl_setNeedsUpdateSelectedBackgroundColors;
- (void)cyl_updateLoopingLottieViews;
- (void)cyl_updateBadgesOfSelectedTab;
- (void)cyl_syncTabBarItemAccessibility;
#if CYL_FLATDESIGN_AVAILABLE
- (void)cyl_syncFlatDesignTabBarItemColors;
#endif
@end

/// Which tab bar controllers a lookup accepts; nil accepts any CYLTabBarController.
typedef BOOL (^CYLTabBarControllerMatcher)(CYLTabBarController *tabBarController);

/// Implemented below (CYLActiveTabBarController): the registry of live tab bar controllers.
/// FIX: issue #152 — implemented in `CYLTabBarController (CYLTabBarItemGesture)` below. 实现见下方的分类。
@interface CYLTabBarController (CYLTabBarItemGesturePrivate)
- (void)cyl_recognizeTabBarItemGestureForReportedControl:(UIControl *)control;
- (void)cyl_installTabBarItemLongPressIfNeeded;
- (BOOL)cyl_isTabBarItemGestureControl:(UIControl *)control viewController:(UIViewController *__autoreleasing _Nullable *_Nullable)viewController;
- (void)cyl_reportTabBarItemGesture:(CYLTabBarItemGesture)gesture control:(UIControl *)control viewController:(nullable UIViewController *)viewController;
- (void)cyl_recognizeTapOnControl:(UIControl *)control viewController:(nullable UIViewController *)viewController isReselect:(BOOL)isReselect;
- (void)cyl_recognizeTabBarItemTapWillSelectViewController:(UIViewController *)viewController;
- (void)cyl_recognizeTabBarItemTapOnControl:(UIControl *)control viewController:(nullable UIViewController *)viewController isReselect:(BOOL)isReselect;
@end

@interface CYLTabBarController (CYLActiveTabBarControllerPrivate)
+ (void)cyl_registerTabBarController:(CYLTabBarController *)tabBarController;
+ (void)cyl_markTabBarControllerActive:(CYLTabBarController *)tabBarController;
+ (CYLTabBarController *)cyl_tabBarControllerForContext:(NSString *)context matching:(CYLTabBarControllerMatcher)matcher;
@end

/// [EN] FIX: issue #535 — implemented in CYLTabBarController+CYLInteraction.m. [CN] 实现位于 CYLTabBarController+CYLInteraction.m。
@interface CYLTabBarController (CYLInteractionInstall)
- (void)cyl_installInteractionGestureRecognizersIfNeeded;
- (BOOL)cyl_liquidGlassTakesTabTaps;
@end

/// FIX: issue #475. The title offset a tab asked for itself; see `-setTitlePositionAdjustment:`.
/// Tab 自身设置的标题偏移，见 `-setTitlePositionAdjustment:`。
static void CYLRememberItemTitlePositionAdjustment(id _Nullable item, UIOffset offset);
/// FIX: issue #95. The image insets a tab asked for itself; see `-updateImageInsets:`.
/// Tab 自身设置的图片内边距，见 `-updateImageInsets:`。
static void CYLRememberItemImageInsets(id _Nullable item, UIEdgeInsets insets);

/// FIX: issue #257, #522. What the automatic adjustment of image-only tabs wrote into an item; see
/// `-offsetTabBarTabImageViewToFit:`. 纯图标 Tab 自动调整写入 item 的记录，见 `-offsetTabBarTabImageViewToFit:`。
static char CYLImageOnlyTabAdjustmentKey;
static NSString *const CYLImageOnlyTabOriginalInsetsKey = @"insets";
static NSString *const CYLImageOnlyTabAppliedInsetsKey = @"appliedInsets";
static NSString *const CYLImageOnlyTabOriginalTitleKey = @"title";
static NSString *const CYLImageOnlyTabAppliedTitleKey = @"appliedTitle";


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

@implementation CYLTabBarController {
#if CYL_FLATDESIGN_AVAILABLE
    struct {
        unsigned willShowTabBar : 1;
        unsigned didShowTabBar : 1;
        unsigned willHideTabBar : 1;
        unsigned didHideTabBar : 1;
    } _delegateHas;
    
    BOOL _tabBarIsAnimating;
    // 用于记录快速设置tabBar显示和隐藏最后一次的状态
    BOOL _lastShowHideTabBar;
    // `animated` of the request queued while `_tabBarIsAnimating`; replayed with its own value.
    // 动画期间排队的那次请求自己的 animated 参数，动画结束后按它重放。
    BOOL _lastShowHideTabBarAnimated;
    BOOL _needsReloadItems;
    BOOL _cylDidRefreshSystemTabBarVisibility;
    BOOL _cylRefreshingSystemTabBarVisibility;
    BOOL _cylWaitingForVisibilityTransition;
    __weak UIWindow *_cylRefreshedSystemTabBarWindow;
    
    _CYLFlatDesignTabBarParallaxOverlayView *_parallaxOverlayView;
#else
#endif
    // [EN] Classic tab bar before iOS 18: the animated `-setTabBarHidden:animated:` (see `-cyl_setClassicTabBarHidden:animated:`).
    // [CN] iOS 18 以前的经典 TabBar：带动画的 `-setTabBarHidden:animated:`（见 `-cyl_setClassicTabBarHidden:animated:`）。
    BOOL _cylClassicTabBarIsAnimating;
    BOOL _cylClassicTabBarHiddenRequest;
    NSUInteger _cylClassicTabBarAnimationGeneration;
}

@synthesize viewControllers = _viewControllers;
@synthesize tabBarHeight = _tabBarHeight;
@synthesize cyl_tabBar = _cyl_tabBar;
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

#if CYL_FLATDESIGN_AVAILABLE
- (void)_cyl_refreshSystemTabBarVisibilityIfNeeded {
    if (@available(iOS 27.1, *)) {
        if (_cylRefreshingSystemTabBarVisibility || self.tabBarStyleType != CYLTabBarStyleTypeFlatDesign ||
            ![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        UIView *container = self.viewIfLoaded;
        UIViewController *selected = self.selectedViewController;
        UIWindow *window = container.window;
        if (!window || window.hidden || selected.viewIfLoaded.window != window) { return; }
        if (_cylDidRefreshSystemTabBarVisibility && _cylRefreshedSystemTabBarWindow == window) { return; }
        if (_tabBarIsAnimating || _parallaxOverlayView) { return; }

        id<UIViewControllerTransitionCoordinator> coordinator = selected.transitionCoordinator ?: self.transitionCoordinator;
        if (coordinator) {
            if (!_cylWaitingForVisibilityTransition) {
                _cylWaitingForVisibilityTransition = YES;
                __weak __typeof(self) weakSelf = self;
                BOOL registered = [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext> context) {
                    __strong __typeof(weakSelf) strongSelf = weakSelf;
                    if (!strongSelf) { return; }
                    strongSelf->_cylWaitingForVisibilityTransition = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [strongSelf _cyl_refreshSystemTabBarVisibilityIfNeeded];
                    });
                }];
                if (!registered) { _cylWaitingForVisibilityTransition = NO; }
            }
            return;
        }

        // FIX: issue #662 (iOS 27.1+)
        // [EN] 1.99.65 hides the system bar view in `-initWithFrame:` (enough on iOS 27.0). From iOS 27.1, UIKit
        //      still reserves the system bar's height in the children's safe area at first display (observed on the
        //      iOS 27.1 / 27.2 simulators and an iPhone 13 on iOS 27.2): the
        //      `-setTabBarHidden:YES` sent from `viewDidLoad` happens before the controller is in a window and is
        //      not applied to UIKit's controller-level state. Result: 34 + 49 (system) + 49 (CYL) = 132 instead of 83.
        //      Toggle UIKit's state once the selected child is in the window, without animating the system bar.
        // [CN] 1.99.65 只在 `-initWithFrame:` 里隐藏了系统 TabBar 视图（iOS 27.0 够用）。iOS 27.1 起，首次显示时 UIKit
        //      仍按控制器级状态为系统 TabBar 预留高度：`viewDidLoad` 里调用的 `-setTabBarHidden:YES` 发生在进入 window
        //      之前，没有生效。结果 34 + 49（系统）+ 49（CYL）= 132，而不是 83。所以在选中的子控制器进入 window 后，
        //      无动画地把 UIKit 的状态刷新一次。
        _cylRefreshingSystemTabBarVisibility = YES;
        _cylDidRefreshSystemTabBarVisibility = YES;
        _cylRefreshedSystemTabBarWindow = window;
        [UIView performWithoutAnimation:^{
            [super setTabBarHidden:NO animated:NO];
            // If KVC replacement failed, UIKit's original bar lacks the
            // always-hidden setter of CYLFlatDesignTabBarHideTabBar.
            if (!self.tabBar.hidden) { self.tabBar.hidden = YES; }
            [super setTabBarHidden:YES animated:NO];
            if (!self.tabBar.hidden) { self.tabBar.hidden = YES; }
        }];
        _cylRefreshingSystemTabBarVisibility = NO;
    }
}
#endif

/*!
 * [EN] Every style. FlatDesign: refresh the system tab bar's visibility. Scroll hiding (issue #13): appearing ends any
 *      hide session, so the tab bar is shown.
 * [CN] 所有样式。扁平样式：刷新系统 TabBar 的可见性。滚动隐藏（issue #13）：出现时结束隐藏会话，TabBar 恢复显示。
 */
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
#if CYL_FLATDESIGN_AVAILABLE
    [self _cyl_refreshSystemTabBarVisibilityIfNeeded];
#endif
    [self cyl_tabBarMinimizeLifecycleEvent];
    // [EN] Scroll hiding self-test (issue #13), only when launched with `-CYLScrollHideSelfTest YES`: runs once, on the
    //      page on screen. [CN] 滚动隐藏自测（issue #13），仅在以 `-CYLScrollHideSelfTest YES` 启动时：在当前页面上运行一次。
    static BOOL cylDidStartScrollHideSelfTest = NO;
    if (!cylDidStartScrollHideSelfTest && [[NSUserDefaults standardUserDefaults] boolForKey:@"CYLScrollHideSelfTest"]) {
        cylDidStartScrollHideSelfTest = YES;
        [self cyl_startScrollHideSelfTestWhenActiveWithAttempt:0];
    }
}

/*!
 * [EN] Issue #13: the launch self-test starts once the app is active and the first page is laid out. At the first
 *      viewDidAppear the app can still be inactive, and scroll hiding (rightly) refuses to hide an inactive window,
 *      which made every simulation SKIP. Checks every 0.5 s, for at most 20 s.
 * [CN] Issue #13：启动自测在 App 进入活跃状态、首个页面完成布局之后开始。第一次 viewDidAppear 时 App 可能仍未活跃，而滚动隐藏（正确地）
 *      不会隐藏非活跃窗口中的 TabBar，导致所有模拟都为 SKIP。每 0.5 秒检查一次，最多 20 秒。
 */
- (void)cyl_startScrollHideSelfTestWhenActiveWithAttempt:(NSInteger)attempt {
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CYLTabBarController *strongSelf = weakSelf;
        if (!strongSelf) {
            return;
        }
        BOOL active = (UIApplicationStateActive == [UIApplication sharedApplication].applicationState) && strongSelf.view.window != nil;
        if (!active && attempt < 40) {
            [strongSelf cyl_startScrollHideSelfTestWhenActiveWithAttempt:attempt + 1];
            return;
        }
        UIViewController *page = strongSelf.selectedViewController;
        if ([page isKindOfClass:[UINavigationController class]]) {
            page = ((UINavigationController *)page).topViewController;
        }
        [page.view layoutIfNeeded];
        [page cyl_runScrollHideSelfTest];
    });
}

/*!
 * [EN] Scroll hiding (issue #13): disappearing (a full-screen modal, a push over this controller, a tab of an outer
 *      controller) ends any hide session, so the tab bar is shown when this controller comes back.
 * [CN] 滚动隐藏（issue #13）：消失时（全屏模态页面、在本控制器之上 push、外层控制器切换 Tab）结束隐藏会话，回来时 TabBar 正常显示。
 */
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self cyl_tabBarMinimizeLifecycleEvent];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self cyl_tabBarMinimizeLifecycleEvent];
}

/*!
 * [EN] Every style: this controller becomes the most recently active one (`+cyl_activeTabBarController`), which
 *      `-cyl_tabBarController` falls back to for an object that is not inside any tab bar controller.
 * [CN] 所有样式：本控制器成为最近活跃的控制器（`+cyl_activeTabBarController`），对象不在任何 TabBarController 内时，
 *      `-cyl_tabBarController` 会回退到它。
 */
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [CYLTabBarController cyl_markTabBarControllerActive:self];
    // FIX: issue #216
    [self cyl_applyLaunchTabBarThemeIfNeeded];
    [self cyl_setNeedsUpdateSelectedBackgroundColors];
    // FIX: issue #152 — the long press, only when someone listens. 仅在有接收方时添加长按手势。
    [self cyl_installTabBarItemLongPressIfNeeded];
    // FIX: issue #433
    // [EN] Show the selected title on the selected tab.
    // [CN] 选中的 Tab 显示选中标题。
    CYLApplyTabBarItemSelectedTitles(self);
    // [EN] Scroll hiding (issue #13): appearing ends any hide session. [CN] 滚动隐藏（issue #13）：出现时结束隐藏会话。
    [self cyl_tabBarMinimizeLifecycleEvent];
}


- (void)tabChangedToControl:(UIControl *)control {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    // FIX: issue #19 — this action runs after UIKit asked `-tabBarController:shouldSelectViewController:`, also when it was
    // refused: a tab that needs login must not be marked selected or play its animation here. Starting the login again is
    // avoided (once per tap); a delegate that is another object gets it started here.
    // 该事件在 UIKit 询问 `-tabBarController:shouldSelectViewController:` 之后执行，即使被拒绝也会执行：需要登录的 Tab 不能在这里被设为选中
    // 或播放动画。不会重复发起登录（每次点击一次）；代理是其他对象时，由这里发起。
    NSInteger tappedIndex = control.cyl_tabBarChildViewControllerIndex;
    if (![control cyl_isPlusControl] && tappedIndex >= 0 && tappedIndex < (NSInteger)self.viewControllers.count &&
        [self cyl_interceptLoginIfNeededForViewController:self.viewControllers[(NSUInteger)tappedIndex]]) {
        return;
    }
    // [EN] A custom action tab (CYLCustomTabAction): runs the action instead (once per tap), like a tab that needs login. The view
    //      controller is looked up from the button itself: on Liquid Glass without a plus button the button's stored
    //      index can be 0 for every tab.
    // [CN] 使用自定义点击操作的 Tab（CYLCustomTabAction）：改为执行对应操作（每次点击一次），与需要登录的 Tab 相同。控制器按按钮本身查找：
    //      液态玻璃且没有 PlusButton 时，按钮记录的下标可能都是 0。
    // [EN] Liquid Glass calls this from the gesture delegate when a touch begins; the tap itself reaches
    //      `-tabBarController:shouldSelectViewController:`, which checks it, so it is not checked here (it would run twice).
    // [CN] 液态玻璃在手指按下时从手势代理调用本方法；点击本身会到达 `-tabBarController:shouldSelectViewController:` 并在那里检查，
    //      因此这里不再检查（否则会执行两次）。
    UIViewController *customActionCandidate = [CYLConstants isLiquidGlassActive] ? nil : [self cyl_viewControllerForTabControl:control];
    if (customActionCandidate && [self cyl_performCustomTabActionIfNeededForViewController:customActionCandidate]) {
        return;
    }
    // FIX: issue #232
    // [EN] `-tabBarController:shouldSelectViewController:` returned NO for the tapped tab (e.g. a tab that pushes a page
    //      instead of being selected): the selected tab did not change. The code below works on the selected tab, so it
    //      played the selected tab's Lottie on the tapped button, marked the tapped button selected, reported it through
    //      `tabBarController:didSelectControl:`, and deselected the plus button while its page was still shown. Leave the
    //      tab bar as it is, as for a tab that needs login (#19).
    // [CN] `-tabBarController:shouldSelectViewController:` 对被点击的 Tab 返回了 NO（例如点击后 push 页面而不切换的 Tab），选中的
    //      Tab 没有变化。下面的代码按当前选中的 Tab 处理，于是会在被点击的按钮上播放选中 Tab 的 Lottie、把被点击的按钮设为选中、
    //      通过 `tabBarController:didSelectControl:` 上报，并在 PlusButton 的页面仍在显示时取消 PlusButton 的选中状态。
    //      与需要登录的 Tab（#19）一样，保持 TabBar 不变。
    if (![control cyl_isPlusControl] && tappedIndex >= 0 && tappedIndex < (NSInteger)self.viewControllers.count) {
        UIViewController *tappedViewController = self.viewControllers[(NSUInteger)tappedIndex];
        UIViewController *selectedViewController = self.selectedViewController;
        // [EN] The "More" tab selects `moreNavigationController`, which is not in `viewControllers`: not a refusal.
        // [CN] “更多”Tab 选中的是不在 `viewControllers` 中的 `moreNavigationController`，不算被拒绝。
        if (selectedViewController && selectedViewController != self.moreNavigationController &&
            tappedViewController != selectedViewController) {
            return;
        }
    }
    UIViewController *vc = nil;
    [self tabChangedToSelectedViewController:vc control:control];
    [self cyl_setNeedsUpdateSelectedBackgroundColors];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)tabChangedToSelectedViewController:(UIViewController *)viewController
                                   control:(UIControl *)control {
    
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self tabChangedToSelectedIndex:self.selectedIndex viewController:viewController control:control];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
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
 */
- (void)tabChangedToSelectedIndex:(NSUInteger)selectedIndex
                   viewController:(UIViewController *)viewController
                          control:(UIControl *)control {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    // [CN] 扁平样式，与玻璃样式均可使用
    // [EN] Available for both the flat design style and the glass style
    if (![self.cyl_tabBar isKindOfClass:[UITabBar class]] && ![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    if (YES == viewController.cyl_isPlaceholder) {
        return;
    }
    if (!viewController) {
        viewController = self.selectedViewController;
    }
    if (!control) {
        control = [viewController cyl_getViewControllerInsteadOfNavigationController].cyl_tabButton;
    }
    if (!control) {
        control = viewController.cyl_tabButton;
    }
    // Ensure we do not pass nil to a nonnull parameter
    UIViewController *targetVC = viewController ?: self.selectedViewController;
    if (targetVC) {
        UITabBarController *tabBarController = nil;
        [self updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:targetVC];
    }
    if (control) {
        [self didSelectControl:control];
    }
    
    // FIX: issue #433
    // [EN] Classic taps come here, not always through `-setSelectedViewController:`.
    // [CN] 经典样式的点击会到这里，不一定经过 `-setSelectedViewController:`。
    CYLSetNeedsUpdateTabBarItemSelectedTitles(self);
    UITabBarItem *item = viewController.tabBarItem;
    BOOL isChildViewControllerPlusButton = [control cyl_isChildViewControllerPlusButton];
    BOOL isLottieEnabled = [self isLottieEnabled];
    
    if (isLottieEnabled && !isChildViewControllerPlusButton) {
        // [CN] 非液态玻璃 与 液态玻璃逻辑共用，Lottie 播放逻辑都在 tabChangedToSelectedIndex 中。
        // [EN] Shared logic for non-Liquid Glass and Liquid Glass; all Lottie playback logic lives in
        //      tabChangedToSelectedIndex.
        if (NO == self.selectedViewController.cyl_isPlaceholder) {
            [self addLottieImageWithControl:control lottieURL:item.cyl_lottieURL lottieSizeValue:item.cyl_lottieSizeValue animation:YES];
        }
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)initLottieTabBar:(CYLTabBar *)tabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    //CYL_UIDesignClassicCYLTabBar
    dispatch_async(dispatch_get_main_queue(),^{
        if ([CYLConstants isLiquidGlassActive]) {
            [self.viewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
                UIControl *control = viewController.cyl_tabButton;
                NSURL *url = viewController.tabBarItem.cyl_lottieURL;
                NSValue *lottieSizeValue = viewController.tabBarItem.cyl_lottieSizeValue;
                if (!control) {
                    return;
                }
                if (!url) {
                    return;
                }
                if (!viewController.cyl_isEmbedInTabBarController) {
                    return;
                }
                if ([control cyl_isPlusControl]) {
                    return;
                }
                UIControl *tabButton = control;
                BOOL defaultSelected = NO;
                if (idx == self.selectedIndex) {
                    defaultSelected = YES;
                }
                //TODO:  selected content, double add
                [self addLottieImageWithControl:tabButton
                                      lottieURL:url
                                lottieSizeValue:lottieSizeValue
                                      animation:defaultSelected
                                defaultSelected:defaultSelected];
                self.lottieViewAdded = YES;
            }];
        } else {
            NSArray *subTabBarButtonsWithoutPlusButton = tabBar.cyl_subTabBarButtonsWithoutPlusButton;
            [subTabBarButtonsWithoutPlusButton enumerateObjectsUsingBlock:^(UIControl * _Nonnull control, NSUInteger idx, BOOL * _Nonnull stop) {
                UIControl *tabButton = control;
                // [EN] FIX: issue #423 — `idx` counts the buttons without the plus button, `selectedIndex` counts the view
                // controllers, which hold the plus child view controller too. With one before the selected tab, the
                // launch animation played on the wrong tab. Compare the button's own tab item instead; the position is
                // only a fallback.
                // [CN] `idx` 不含 PlusButton，`selectedIndex` 却包含 PlusButton 子控制器；子控制器在选中 Tab
                // 之前时，启动动画会播在错的 Tab 上。改为比较按钮所属的 tabBarItem，按位置比较仅作兜底。
                UITabBarItem *tabBarItem = [self cyl_tabBarItemForTabButton:tabButton];
                BOOL defaultSelected = tabBarItem ? (tabBarItem == self.selectedViewController.tabBarItem)
                                                  : (idx == self.selectedIndex);
                //TODO:  selected content, double add
                [self addLottieImageWithControl:tabButton animation:defaultSelected defaultSelected:defaultSelected];
                self.lottieViewAdded = YES;
            }];
        }
        // [EN] Icon views installed before the Lottie views (e.g. the icons of the theme chosen at launch) hide them now; until
        //      the next layout pass the Lottie view stayed on top of the theme's icon (seen on Liquid Glass).
        // [CN] 在 Lottie 视图之前安装的图标视图（例如启动时所选主题的图标）现在将其隐藏；否则在下一次布局前 Lottie 视图会盖在主题图标之上
        //      （液态玻璃上可见）。
        [self cyl_setNeedsUpdateTabBarItemIconViews];
    });
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)setViewDidLayoutSubViewsBlockInvokeOnce:(BOOL)invokeOnce block:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock  {
    self.invokeOnceViewDidLayoutSubViewsBlock = YES;
    self.viewDidLayoutSubviewsBlock = [viewDidLayoutSubviewsBlock copy];
    // FIX: issue #539
    // [EN] `-viewDidLayoutSubviews` marks a once-block as run with an associated object keyed by its selector, and nothing
    //      cleared it: after one once-block had run, a block set later with this method never ran (e.g. a badge shown from
    //      it never appeared). Re-arm it, so each block set here runs once.
    //      Scope: every tab bar style (classic, iOS 26 UI compatibility mode, Liquid Glass on iOS 26+ and the iPhone Duo,
    //      FlatDesign): the once-block runs at the end of `-viewDidLayoutSubviews` for all of them. `invokeOnce` itself stays
    //      ignored, as documented.
    // [CN] `-viewDidLayoutSubviews` 用以其 selector 为 key 的关联对象标记 once-block 已执行，且从不清除：执行过一次后，之后通过本方法
    //      设置的 block 永远不会执行（如在其中显示的角标不出现）。这里重新启用，使每次设置的 block 都执行一次。
    //      范围：所有样式（经典、iOS 26 UI 兼容模式、iOS 26+ 液态玻璃与 iPhone Duo、扁平样式）：once-block 在
    //      `-viewDidLayoutSubviews` 末尾对它们都会执行。`invokeOnce` 参数按文档说明仍被忽略。
    objc_setAssociatedObject(self, @selector(viewDidLayoutSubviews), nil, OBJC_ASSOCIATION_RETAIN);
}

- (void)setViewDidLayoutSubViewsBlock:(CYLViewDidLayoutSubViewsBlock)viewDidLayoutSubviewsBlock {
    _viewDidLayoutSubviewsBlock = [viewDidLayoutSubviewsBlock copy];
}

#pragma mark - Reload badges (#404)

- (void)reloadBadgesWithBlock:(CYLViewDidLayoutSubViewsBlock)block {
    [self performWhenTabBarItemsReady:block];
}

- (void)performWhenTabBarItemsReady:(CYLViewDidLayoutSubViewsBlock)block {
    if (!block) {
        return;
    }
    if (!self.pendingReloadBadgesBlocks) {
        self.pendingReloadBadgesBlocks = [NSMutableArray array];
    }
    [self.pendingReloadBadgesBlocks addObject:[block copy]];
    [self cyl_runPendingReloadBadgesBlocksIfReady];
    // On screen but not laid out yet: make sure a layout pass comes. Off screen, one comes when it is shown.
    if (self.pendingReloadBadgesBlocks.count > 0 && self.isViewLoaded && self.view.window) {
        [self.view setNeedsLayout];
    }
}

/*!
 * [EN] The tab buttons exist once the first real tab's badge host is a laid-out view: until then it is nil, or a
 *      `UITabBarItem` (Liquid Glass) or a not yet sized control, and a badge shown on it would be dropped.
 * [CN] 第一个真实 Tab 的角标宿主成为已布局的视图时，Tab 按钮即已创建：在此之前它为 nil、`UITabBarItem`（液态玻璃）
 *      或尚未确定尺寸的控件，此时显示的角标会被丢弃。
 */
- (BOOL)cyl_tabButtonsAreReadyForBadges {
    if (!self.isViewLoaded) {
        return NO;
    }
    // FIX: issue #22
    // [EN] `self.tabBar.items` too, for `-performWhenTabBarItemsReady:` (FlatDesign keeps its items in its own tab bar).
    // [CN] 同时要求 `self.tabBar.items` 已生成，供 `-performWhenTabBarItemsReady:` 使用（扁平样式的 item 在其自己的 TabBar 中）。
    if (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType && self.tabBar.items.count == 0) {
        return NO;
    }
    // FIX: issue #22
    // [EN] Any real tab, not only the first: a tab covered by a view (e.g. a logo over the first tab) has no visible
    //      icon, so its badge host stays nil and the blocks never ran.
    // [CN] 任一真实 Tab 即可，而不只是第一个：被覆盖的 Tab（如第一个 Tab 上的 Logo）没有可见图标，其角标宿主一直为 nil，block 从未执行。
    for (UIViewController *viewController in self.viewControllers) {
        if (viewController.cyl_isPlaceholder) {
            continue;
        }
        id host = [viewController cyl_getActualBadgeSuperView];
        // [EN] Liquid Glass returns the tab's `UITabBarItem`: its view is the host once the tab button exists.
        // [CN] 液态玻璃返回 Tab 的 `UITabBarItem`：Tab 按钮创建后，其视图即为宿主。
        if ([host isKindOfClass:[UITabBarItem class]]) {
            host = [(UITabBarItem *)host cyl_getActualBadgeSuperView];
        }
        if ([host isKindOfClass:[UIView class]] && CGRectGetWidth(((UIView *)host).bounds) > 10) {
            return YES;
        }
    }
    return NO;
}

- (void)cyl_runPendingReloadBadgesBlocksIfReady {
    if (self.pendingReloadBadgesBlocks.count == 0) {
        return;
    }
    if (![self cyl_tabButtonsAreReadyForBadges]) {
        // The tab bar lays its buttons out after this controller's view; on screen, do it now instead of waiting.
        if (!self.isViewLoaded || !self.view.window) {
            return;
        }
        [self.cyl_tabBar layoutIfNeeded];
        if (![self cyl_tabButtonsAreReadyForBadges]) {
            return;
        }
    }
    // A block may call -reloadBadgesWithBlock: again: run a copy, so that one waits for its own turn.
    NSArray<CYLViewDidLayoutSubViewsBlock> *blocks = [self.pendingReloadBadgesBlocks copy];
    [self.pendingReloadBadgesBlocks removeAllObjects];
    for (CYLViewDidLayoutSubViewsBlock block in blocks) {
        block(self);
    }
}

/*!
 * FIX: issue #610
 * [EN] Classic (non Liquid Glass) tab buttons report taps through this target-action, which used to be added only in
 *      `-viewDidLayoutSubviews`. Setting `tabBarItem.image` / `selectedImage` at runtime makes UIKit replace the tab
 *      buttons (observed on iOS 17.5: 4 of 5 replaced), and only the tab bar is laid out again, not the controller's
 *      view. The new buttons had no target, so `tabBarController:didSelectControl:` stopped being called until
 *      something called `[tabBarController.view setNeedsLayout]`. `CYLTabBar -layoutSubviews` now calls this method
 *      too, so new buttons get the action in the same layout pass that places them.
 * [CN] 非液态玻璃的 Tab 按钮依靠这里添加的点击事件回调，以前只在 `-viewDidLayoutSubviews` 中添加。运行时修改
 *      `tabBarItem.image` / `selectedImage` 会让 UIKit 重新创建 Tab 按钮（iOS 17.5 实测 5 个中替换了 4 个），而此时只会
 *      重新布局 TabBar，不会触发控制器的 `-viewDidLayoutSubviews`。新按钮没有点击事件，于是不再回调
 *      `tabBarController:didSelectControl:`，直到调用 `[tabBarController.view setNeedsLayout]`。现在 `CYLTabBar -layoutSubviews`
 *      也会调用本方法，新按钮在布局的同时就会加上点击事件。
 */
- (void)cyl_bindTabControlActions {
    if (![self.cyl_tabBar isKindOfClass:[CYLTabBar class]] || [CYLConstants isLiquidGlassActive]) {
        // [CN] 液态玻璃无法添加事件 放进手势响代理里处理。
        // [EN] Liquid Glass does not allow adding events, so this is handled in the gesture recognizer delegate.
        return;
    }
    CYLTabBar *tabBar = (CYLTabBar *)self.cyl_tabBar;
    // add callback for visiable control, included all plusButton.
    SEL action = @selector(tabChangedToControl:);
    // FIX: issue #587
    // [EN] `cyl_visibleControls` holds the tab buttons and the plus button, sorted by x. A plus button without a child view
    //      controller takes a slot but has no view controller index, so for the tabs after it the position in this array is
    //      one more than their index in `viewControllers`. Comparing that position with `selectedIndex` marked the wrong tab
    //      button selected (e.g. [t0, t1, PLUS, t2, t3] with t3 selected set `t2.selected = YES`), and never cleared it. This
    //      runs on every layout pass of the tab bar, which switching to dark mode triggers, so `selected` (and
    //      `-cyl_isSelected`) was wrong after the switch. Count only system tab buttons to get each button's tab index (the
    //      tab of a plus child view controller is the system button under the plus button, so it is counted), and set
    //      `selected` from it.
    //      Scope: the classic (pre-Liquid Glass) system tab bar, i.e. iOS 25 and earlier plus iOS 26 in UI compatibility
    //      mode. The guard at the top of this method already returns for FlatDesign (`cyl_tabBar` is not a `CYLTabBar`) and
    //      for Liquid Glass (iOS 26 without compatibility mode, every iOS 27+ system, the iPhone Duo).
    // [CN] `cyl_visibleControls` 包含按 x 排序的 Tab 按钮和 PlusButton。没有子控制器的 PlusButton 占一个位置，却没有对应的控制器下标，
    //      因此位于它之后的 Tab，在该数组中的位置比其在 `viewControllers` 中的下标大 1。用这个位置与 `selectedIndex` 比较会把错误的
    //      Tab 按钮设为选中（如 [t0, t1, PLUS, t2, t3] 中选中 t3 时设置了 `t2.selected = YES`），且不会清除。TabBar 每次布局都会执行
    //      这里，切换暗黑模式会触发布局，于是切换后 `selected`（以及 `-cyl_isSelected`）出错。这里只对系统 Tab 按钮计数得到每个按钮的
    //      Tab 下标（PlusButton 子控制器对应的 Tab 是 PlusButton 下方的系统按钮，会被计入），并据此设置 `selected`。
    //      范围：经典（液态玻璃之前的）系统 TabBar，即 iOS 25 及以前，以及 iOS 26 的 UI 兼容模式。本方法开头的判断已排除扁平样式
    //      （`cyl_tabBar` 不是 `CYLTabBar`）和液态玻璃（未开启兼容模式的 iOS 26、所有 iOS 27+、iPhone Duo）。
    __block NSUInteger tabIndex = 0;
    [tabBar.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull control, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL isTabButton = [control cyl_isTabButton];
        NSUInteger controlTabIndex = isTabButton ? tabIndex++ : NSNotFound;
        if (isTabButton) {
            // `-cyl_isSelected` compares with this index. `CYLTabBar` stores it only while a plus button is active (same
            // counting: system tab buttons only), so without one every button reported 0. 无 PlusButton 时也记录正确下标。
            [control cyl_setTabBarChildViewControllerIndex:(NSInteger)controlTabIndex];
        }
        // Remove first so repeated layout passes never add the action twice. 先移除，避免多次布局重复添加。
        [control removeTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        //to avoid invoking didSelectControl twice, because plusChildViewControllerButtonClicked will invoke setSelectedIndex
        // The tab bar can lay out before the plus child view controller is added; the removal above then
        // drops an action bound in that earlier pass. 加号子控制器添加前的布局可能已添加了事件，上面的移除会将其去掉。
        if ([control cyl_isChildViewControllerPlusButton]) {
            return;
        }
        UILabel *tabLabel = control.cyl_tabLabel;
        tabLabel.textAlignment = NSTextAlignmentCenter;
        
        // [CN] FIX: iOS26 之前也不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
        // [EN] FIX: Before iOS26 tap events are no longer used either; this is handled in
        //      `-setSelectedViewController` and `-setSelectedIndex` instead
        [control addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        // [EN] The pressed animation (`CYLTabButtonAnimation` highlight / dehighlight), on tab buttons only (the plus button
        //      adds its own, CYLPlusButton.m); removed first, as above.
        // [CN] 按下动画（`CYLTabButtonAnimation` 的 highlight / dehighlight），仅用于 Tab 按钮（PlusButton 自己添加，见
        //      CYLPlusButton.m）；与上面一样先移除。
        [control removeTarget:self action:@selector(cyl_tabButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [control removeTarget:self action:@selector(cyl_tabButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        if (isTabButton) {
            [control addTarget:self action:@selector(cyl_tabButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
            [control addTarget:self action:@selector(cyl_tabButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel];
        }
        
        // `selectedIndex` is NSNotFound while the "More" tab is selected; leave the buttons to UIKit then.
        if (isTabButton && self.selectedIndex != NSNotFound) {
            control.selected = (controlTabIndex == self.selectedIndex);
        }
    }];
    [self cyl_updateSelectedBackgroundColorsOfTabButtons];
}


#pragma mark - Plus button in the Liquid Glass layers

static const void *const CYLLayingOutPlusButtonInGlassLayersKey = &CYLLayingOutPlusButtonInGlassLayersKey;
static const void *const CYLPlusButtonGlassLayoutRetryPendingKey = &CYLPlusButtonGlassLayoutRetryPendingKey;

/*!
 * [EN] Hides the tab icon under the plus button in both Liquid Glass layers and puts the plus button's stand-in
 *      (`selectedContentView`) in the selected layer. Idempotent, and run on every layout pass of the controller and of
 *      the tab bar: the selected layer is rendered later than the normal one, so whatever is missing now is added on a
 *      later pass, instead of after a fixed delay acting on views looked up before it (nil when the layer was not there
 *      yet). Everything is looked up again on each call. When the selected layer is still missing, one retry is
 *      scheduled as a fallback. A stand-in still inside an old tab button (UIKit rebuilds the buttons, e.g. when an item
 *      image changes) is taken out first, so it can be put in the new one.
 * [CN] 在液态玻璃的两个图层中隐藏 PlusButton 下方的 Tab 图标，并把 PlusButton 的替身（`selectedContentView`）放进选中层。可重复调用，
 *      控制器与 TabBar 每次布局都会执行：选中层比普通层渲染得晚，本次缺少的部分会在之后的布局中补上，而不是固定延迟后再操作延迟前
 *      取到的视图（图层尚未出现时为 nil）。每次调用都重新查找全部视图。选中层仍不存在时，安排一次重试作为兜底。替身仍留在旧 Tab
 *      按钮中时（UIKit 会重建按钮，例如修改 item 图片后），先把它移出，才能放进新按钮。
 */
- (void)cyl_layOutPlusButtonInLiquidGlassLayers {
    [self cyl_layOutPlusButtonInLiquidGlassLayersIsRetry:NO];
}

/// [EN] `isRetry`: the fallback run, which acts without waiting for readiness and schedules nothing more, as the old
///      delayed block did. [CN] `isRetry`：兜底执行，与原来延迟执行的 block 一样，不再等待就绪，也不再安排新的重试。
- (void)cyl_layOutPlusButtonInLiquidGlassLayersIsRetry:(BOOL)isRetry {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType || ![CYLConstants isLiquidGlassActive] || ![self hasPlusButton] ||
        ![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    // [EN] More editing: the views are hidden until it ends (`-[CYLTabBar endCustomizingAnimated:]`).
    // [CN] 「More」编辑期间这些视图保持隐藏，直到编辑结束（`-[CYLTabBar endCustomizingAnimated:]`）。
    if (((CYLTabBar *)self.cyl_tabBar).cyl_isCustomizingItems) {
        return;
    }
    // [EN] Re-entrancy guard: adding the stand-in can lay views out again. [CN] 防止重入：添加替身可能再次触发布局。
    if ([objc_getAssociatedObject(self, CYLLayingOutPlusButtonInGlassLayersKey) boolValue]) {
        return;
    }
    objc_setAssociatedObject(self, CYLLayingOutPlusButtonInGlassLayersKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    CYLPlusButton<CYLPlusButtonSubclassing> *contextPlusButton = [self cyl_contextPlusButton];
    UIControl *plusControlOrigin = [self.cyl_tabBar cyl_platterContentViewWithIndex:contextPlusButton.cyl_tabBarItemVisibleIndex];
    UIButton *selectedCover = contextPlusButton.selectedContentView;
    UIControl *plusSelectedControl = plusControlOrigin.cyl_platterSelectedControl;
    [plusControlOrigin.cyl_tabImageView cyl_setHidden:YES];
    [plusControlOrigin.cyl_swappableImageViewViewInTabBarButton cyl_setHidden:YES];

    // [CN] 由于 SelectedControl 所在图层的渲染比未选中图层有延迟，可能暂时取不到；之后的布局或下面的一次重试会补上。
    // [EN] The selected layer renders later than the normal one, so it may be missing now; a later layout pass or the
    //      single retry below adds what is missing.
    NSTimeInterval delaySecondsForSelectedContentView = 0.5;
    BOOL needsRetry = (plusSelectedControl == nil);
    if (plusSelectedControl && [self hasPlusChildViewController]) {
        // [EN] A stand-in left in another (old) tab button is taken out, so it can be put in this one.
        // [CN] 留在其他（旧）Tab 按钮中的替身先移出，才能放进当前按钮。
        if (selectedCover.superview && selectedCover.cyl_insertedForTabControl != plusSelectedControl) {
            [selectedCover removeFromSuperview];
        }
        // [EN] Already in this button: nothing to do (this runs on every layout pass, so nothing is queued again).
        // [CN] 已在当前按钮中：无需处理（每次布局都会执行，因此不再重复排队）。
        if (!isRetry && selectedCover.superview == plusSelectedControl && selectedCover.cyl_insertedForTabControl == plusSelectedControl) {
            objc_setAssociatedObject(self, CYLLayingOutPlusButtonInGlassLayersKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            return;
        }
        /*!
         * [CN] 我要求 selectedCover 的中心坐标 强制与 CYLExternPlusButton坐标一致。 坐标系转换
         * [EN] Force the center of selectedCover to match the CYLExternPlusButton position. Converts between
         *      coordinate systems
         * _UITabBarPlatterView
         ├── SelectedContentView
         │    └── selectedCover
         │
         └── CYLPlusButtonSubclass
         */
        __weak CYLPlusButton *weakPlusButton = contextPlusButton;
        void (^centerOnPlusButton)(BOOL, UIControl *, UIView *) = ^(BOOL isReplaced, UIControl *tabBarButton, UIView *selectedCover) {
            CYLPlusButton *plusButton = weakPlusButton;
            UIView *platterView = plusButton.superview;
            UIView *selectedContainerView = selectedCover.superview;
            if (platterView && selectedContainerView) {
                selectedCover.center = [selectedContainerView convertPoint:plusButton.center fromView:platterView];
            }
        };
        if ([contextPlusButton cyl_showsTitleInTabBarItem]) {
            // [EN] FIX: issue #636 — the tab item shows the plus button's title (`-cyl_showsTitleInTabBarItem`): as the
            //      plus button does in the normal layer, its stand-in replaces only the tab icon, and the tab's title
            //      and the rest of the tab button stay as the system lays them out. Covering the whole tab button hid
            //      all its other subviews, the title's container included, so the title stayed hidden.
            // [CN] TabBarItem 显示 PlusButton 的标题：与普通图层中的 PlusButton 一样，替身只替换 Tab 图标，Tab 的标题及按钮的
            //      其他子视图保持系统布局。覆盖整个 Tab 按钮会隐藏它的其他全部子视图（包括标题的容器），标题因此一直不显示。
            if (isRetry || plusSelectedControl.cyl_isReady) {
                [plusSelectedControl cyl_replaceTabImageViewWithNewView:selectedCover
                                                                 offset:UIOffsetZero
                                                                   show:YES
                                                             completion:centerOnPlusButton];
                [plusSelectedControl.cyl_swappableImageViewViewInTabBarButton cyl_setHidden:YES];
            } else {
                needsRetry = YES;
            }
        } else {
            [plusSelectedControl cyl_coverTabImageViewOrTabButton:YES
                                                          newView:selectedCover
                                                           offset:UIOffsetZero
                                                             show:YES
                                          delayIfNeededForSeconds:delaySecondsForSelectedContentView
                                                       completion:centerOnPlusButton];
        }
    } else if (plusSelectedControl) {
        // [CN] imageView 是主要的；有几率暂时取不到 cyl_tabImageView，此时重试。
        // [EN] imageView is the main one; cyl_tabImageView is sometimes not there yet, then it is retried.
        UIView *tabImageView = plusSelectedControl.cyl_tabImageView;
        [tabImageView cyl_setHidden:YES];
        // [CN] cyl_swappableImageViewViewInTabBarButton这个是防御性的， 理论上可以不隐藏。
        // [EN] cyl_swappableImageViewViewInTabBarButton is defensive; in theory it does not need to be hidden.
        [plusSelectedControl.cyl_swappableImageViewViewInTabBarButton cyl_setHidden:YES];
        needsRetry = (tabImageView == nil);
    }
    objc_setAssociatedObject(self, CYLLayingOutPlusButtonInGlassLayersKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    // [EN] Fallback: one pending retry at a time, which looks everything up again. [CN] 兜底：同一时间只安排一次重试，重试时重新查找全部视图。
    if (needsRetry && !isRetry && ![objc_getAssociatedObject(self, CYLPlusButtonGlassLayoutRetryPendingKey) boolValue]) {
        objc_setAssociatedObject(self, CYLPlusButtonGlassLayoutRetryPendingKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        __weak __typeof(self) weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySecondsForSelectedContentView * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __typeof(self) strongSelf = weakSelf;
            if (!strongSelf) {
                return;
            }
            objc_setAssociatedObject(strongSelf, CYLPlusButtonGlassLayoutRetryPendingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            [strongSelf cyl_layOutPlusButtonInLiquidGlassLayersIsRetry:YES];
        });
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    // [EN] Lottie views are added during layout: start the looping ones (`CYLTabBarLottieLoopsWhenUnselected`).
    // [CN] Lottie 视图在布局时添加：启动需要循环播放的视图（`CYLTabBarLottieLoopsWhenUnselected`）。
    [self cyl_updateLoopingLottieViews];
    // [EN] FIX: issue #535 — long press and swipe to switch tabs, once the view exists (every style).
    // [CN] FIX: issue #535 — view 已存在时安装长按与滑动切换手势（所有样式）。
    [self cyl_installInteractionGestureRecognizersIfNeeded];
    // [EN] FlatDesign `cyl_tabBarMinimizeBehavior` (issue #13): follow the scroll view of the page now on screen.
    // [CN] 扁平样式的 `cyl_tabBarMinimizeBehavior`（issue #13）：跟随当前显示页面的滚动视图。
    [self cyl_updateTabBarMinimizeTracking];
    // Issue #601: tab buttons created again (e.g. after a rotation) get their icon views again.
    [self cyl_setNeedsUpdateTabBarItemIconViews];
    [self cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded];
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
            for (UIViewController *viewController in self.viewControllers) {
                if (viewController.cyl_isPlaceholder) {
                    // Classic tab bar: the button is the element. Liquid Glass: the element comes from the item, which
                    // then reads as the plus button it is covered by (a tap on it is forwarded to the plus button).
                    viewController.cyl_tabButton.accessibilityElementsHidden = YES;
                    viewController.cyl_tabButton.isAccessibilityElement = NO;
                    viewController.tabBarItem.accessibilityLabel = [self cyl_contextPlusButton].accessibilityLabel;
                }
            }
        
            do {
                if (self.isLottieViewAdded) {
                    break;
                }
                //FIXME: ??
                NSArray *subTabBarButtonsWithoutPlusButton = tabBar.cyl_subTabBarButtonsWithoutPlusButton;
                BOOL isLottieEnabled = [self isLottieEnabled];
            
                if (![CYLConstants isLiquidGlassActive]) {
                    // [CN] 因为液态玻璃， 补全了所有的缺失的lottieURLs，所以一定保持一致， 无需要处理。
                    // [EN] Because Liquid Glass fills in all missing lottieURLs, they always stay consistent, so nothing needs
                    //      to be handled.
                    if(!isLottieEnabled || (subTabBarButtonsWithoutPlusButton.count != self.lottieURLs.count)) {
                        self.lottieViewAdded = YES;
                        break;
                    }
                } else {
                    if(!isLottieEnabled) {
                        self.lottieViewAdded = YES;
                        break;
                    }
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    if (self.unloadsUnselectedViewsOnMemoryWarning) {
        [self unloadViewsOfUnselectedViewControllers];
    }
}

- (BOOL)shouldUnloadViewOfViewController:(UIViewController *)viewController {
    return YES;
}

- (void)unloadViewsOfUnselectedViewControllers {
    UIViewController *selectedViewController = self.selectedViewController;
    for (UIViewController *viewController in self.viewControllers) {
        if (viewController == selectedViewController || viewController.cyl_isPlaceholder) {
            continue;
        }
        // A navigation controller's stack is unloaded with it, or not at all.
        NSMutableArray<UIViewController *> *viewControllersToUnload = [NSMutableArray array];
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            [viewControllersToUnload addObjectsFromArray:((UINavigationController *)viewController).viewControllers];
        }
        [viewControllersToUnload addObject:viewController];
        BOOL canUnload = YES;
        for (UIViewController *viewControllerToUnload in viewControllersToUnload) {
            if (viewControllerToUnload.isViewLoaded &&
                (viewControllerToUnload.view.window || viewControllerToUnload.presentedViewController)) {
                canUnload = NO;
                break;
            }
        }
        if (!canUnload || ![self shouldUnloadViewOfViewController:viewController]) {
            continue;
        }
        for (UIViewController *viewControllerToUnload in viewControllersToUnload) {
            if (!viewControllerToUnload.isViewLoaded) {
                continue;
            }
            // Setting `view` to nil does not take the view out of its superview (e.g. the navigation controller's).
            [viewControllerToUnload.view removeFromSuperview];
            viewControllerToUnload.view = nil;
        }
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

- (BOOL)isTabBarHidden {
    if (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType) {
        // FIX: [EN] Liquid Glass and the classic style: the system tab bar's state. [CN] 液态玻璃与经典样式：系统 TabBar 的状态。
        if (@available(iOS 18.0, *)) {
            return [super isTabBarHidden];
        }
        // [EN] Classic before iOS 18: while the hide / show animation runs, the request, not the bar's `hidden` (which
        //      changes when the animation ends), so a caller asking again mid-animation does not restart it.
        // [CN] iOS 18 以前的经典样式：动画进行中返回请求的状态，而不是 TabBar 的 `hidden`（动画结束时才改变），避免动画中途再次请求
        //      时重新开始动画。
        if (_cylClassicTabBarIsAnimating) {
            return _cylClassicTabBarHiddenRequest;
        }
        return self.tabBar.hidden;
    }
#if CYL_FLATDESIGN_AVAILABLE
    return self.cyl_tabBarHidden;
#else
    return NO;
#endif
}

- (void)setTabBarHidden:(BOOL)tabBarHidden {
    [self setTabBarHidden:tabBarHidden animated:NO];
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    // [EN] Scroll hiding (issue #13): a request by the app takes the tab bar over from scroll hiding.
    // [CN] 滚动隐藏（issue #13）：App 自己的请求从滚动隐藏手中接管 TabBar。
    [self cyl_tabBarMinimizeDidReceiveTabBarHiddenRequest:hidden];
    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
                
        // [CN] 隐藏系统 tabBar
        // [EN] Hide the system tabBar
        if (@available(iOS 18.0, *)) {
            [super setTabBarHidden:YES animated:animated];
        } else {
            self.tabBar.hidden = YES;
        }
        // KVC may have left UIKit's original bar installed; the
        // controller-level API does not always hide that view itself.
        if (!self.tabBar.hidden) { self.tabBar.hidden = YES; }
                
        // FIX: issue #662
        // [EN] Record the request before any early return, so `isTabBarHidden` always reports the newest
        //      request: while the hide/show animation runs (replayed in its completion with the request's
        //      own `animated`), and while a navigation transition holds the bar in its overlay (applied by
        //      `_updateBottomBarShowHideIfNeeded` when the bar returns, e.g. on transition end or selection).
        //      Previously both paths dropped the request, so the getter, the bar and the safe area disagreed.
        // [CN] 在任何提前 return 之前先记录请求，`isTabBarHidden` 始终是最新请求：动画进行中（动画结束时按该请求
        //      自己的 animated 重放）、转场把 TabBar 放在 overlay 中（TabBar 回来后由 `_updateBottomBarShowHideIfNeeded`
        //      应用）。以前这两条路径都丢掉了请求，导致 getter、TabBar 与安全区三者不一致。
        self.cyl_tabBarHidden = hidden;
        _lastShowHideTabBar = hidden;
        if (_tabBarIsAnimating) {
            _lastShowHideTabBarAnimated = animated;
            return;
        }
        if (self.cyl_tabBar.superview != self.view) { return; }
        // Compare with what is on screen, not with the recorded state: a request recorded above during an
        // animation is replayed here and must still be applied.
        // 与屏幕上的实际状态比较，而不是与记录值比较：动画期间记录的请求会在这里重放，仍需生效。
        if (self.cyl_tabBar.hidden != hidden) {
            BOOL canShowsBottomBar = [self _checkHidesBottomBarWhenPushed];
            if (!canShowsBottomBar) {
                // [CN] 让 hidesBottomBarWhenPushed 优先级更高
                // [EN] Give hidesBottomBarWhenPushed higher priority
                return;
            }
            // FIX: issue #662 — a bar hidden before the first layout can still have a stale (zero-height)
            // frame; nothing else lays it out again before it is shown (seen on iOS 27.0).
            // 首次布局前就隐藏的 TabBar 可能保留旧的（高度为 0 的）frame，显示前同步一次。
            if (!hidden && !CGRectEqualToRect(self.cyl_tabBar.frame, self.tabBarFrame)) {
                self.cyl_tabBar.frame = self.tabBarFrame;
            }
                    
            if (animated) {
                _tabBarIsAnimating = YES;
                        
                if (hidden) {
                            
                    if (_delegateHas.willHideTabBar) {
                                
                        CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:willHideTabBar:, self, self.cyl_tabBar);
                        //                                [self.delegate tabBarController:self willHideTabBar:self.cyl_tabBar];
                    }
                } else {
                    if (_delegateHas.willShowTabBar) {
                        //                                [self.delegate tabBarController:self willShowTabBar:self.cyl_tabBar];
                        CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:willShowTabBar:, self, self.cyl_tabBar);
                    }

                }
                // FIX: issue #662 — a will-hide/will-show delegate may re-enter with the opposite request. That
                // request was recorded (and queued, since `_tabBarIsAnimating` is already YES); it wins, so do
                // not run this one. 代理回调里可能反向重入，以重入的最新请求为准，不再执行本次。
                if (self.cyl_tabBarHidden != hidden) {
                    _tabBarIsAnimating = NO;
                    [self setTabBarHidden:_lastShowHideTabBar animated:_lastShowHideTabBarAnimated];
                    return;
                }
                        
                CGAffineTransform startTransform = hidden? CGAffineTransformIdentity : CGAffineTransformMakeTranslation(0, self.cyl_tabBar.frame.size.height);
                CGAffineTransform endTransform = hidden? CGAffineTransformMakeTranslation(0, self.cyl_tabBar.frame.size.height) : CGAffineTransformIdentity;
                self.cyl_tabBar.transform = startTransform;
                self.cyl_tabBar.hidden = NO;
                        
                [UIView animateWithDuration:CYLFlatDesignUITabBarControllerHideShowBarDuration animations:^{
                    self.cyl_tabBar.transform = endTransform;
                } completion:^(BOOL finished) {
                    self.cyl_tabBar.transform = CGAffineTransformIdentity;
                    self.cyl_tabBar.hidden = hidden;
                    [self _updateAdditionalSafeAreaInsetsWithAnimated:animated];
                    self->_tabBarIsAnimating = NO;
                            
                    if (hidden) {
                                
                        if (self->_delegateHas.didHideTabBar) {
//                                    [self.delegate tabBarController:self didHideTabBar:self.cyl_tabBar];
                        CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:didHideTabBar:, self, self.cyl_tabBar);
                                                        }

                    } else {
                        if (self->_delegateHas.didShowTabBar) {
//                                    [self.delegate tabBarController:self didShowTabBar:self.cyl_tabBar];
                        CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:didShowTabBar:, self, self.cyl_tabBar);
                                                            }

                    }
                            
                    if (self->_lastShowHideTabBar != hidden) {
                        // 动画结束，如果和最后一次设置显隐状态不一致，使其显示正确的状态，主要解决快速设置bug（两次设置时间间隔<0.2s）
                        // Replay with the queued request's own `animated`. 按排队请求自己的 animated 重放。
                        [self setTabBarHidden:self->_lastShowHideTabBar animated:self->_lastShowHideTabBarAnimated];
                    }
                    [self _cyl_refreshSystemTabBarVisibilityIfNeeded];
                }];
            } else {
                        
                if (hidden) {
                    if (_delegateHas.willHideTabBar) {
                        //                                [self.delegate tabBarController:self willHideTabBar:self.cyl_tabBar];
                        CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:willHideTabBar:, self, self.cyl_tabBar);

                    }

                } else {
                    if (_delegateHas.willShowTabBar) {
                        //                                [self.delegate tabBarController:self willShowTabBar:self.cyl_tabBar];
                        CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:willShowTabBar:, self, self.cyl_tabBar);

                    }

                }
                // FIX: issue #662 — a will-hide/will-show delegate re-entered with the opposite request and
                // already applied it; do not overwrite it. 代理回调已反向重入并生效，不要覆盖。
                if (self.cyl_tabBarHidden != hidden) { return; }
                        
                self.cyl_tabBar.hidden = hidden;
                [self _updateAdditionalSafeAreaInsetsWithAnimated:animated];
                        
                if (hidden) {
                    if (_delegateHas.didHideTabBar) {
                        //                                [self.delegate tabBarController:self didHideTabBar:self.cyl_tabBar];
                        CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:didHideTabBar:, self, self.cyl_tabBar);

                    }

                } else {
                    if (_delegateHas.didShowTabBar) {
                        //                                [self.delegate tabBarController:self didShowTabBar:self.cyl_tabBar];
                        CYL_PERFORM_SELECTOR_2OBJECT(self.delegate, tabBarController:didShowTabBar:, self, self.cyl_tabBar);
                    }

                }
            }
        }
            
#else
#endif
    } else {
        // FIX: [EN] Liquid Glass and the classic style hid nothing: hide or show the system tab bar, with its plus button
        //      (a subview of the tab bar), animated by UIKit on iOS 18 and later.
        // [CN] 液态玻璃与经典样式此前不做任何处理：隐藏或显示系统 TabBar 及其中的 PlusButton，iOS 18 及以上由 UIKit 执行动画。
        if (@available(iOS 18.0, *)) {
            [super setTabBarHidden:hidden animated:animated];
        } else {
            [self cyl_setClassicTabBarHidden:hidden animated:animated];
        }
    }
}

/*!
 * [EN] Classic tab bar before iOS 18 (UIKit's `-setTabBarHidden:animated:` arrives in iOS 18): hides or shows the system
 *      tab bar, with its plus button, animated as FlatDesign does: the same duration
 *      (`CYLClassicTabBarHideShowDuration`), the bar moves down out of the screen and back, and `hidden` is set when the
 *      animation ends. The newest request wins: an older animation's completion does nothing. Not animated when
 *      `animated` is NO or the bar is not on screen. Guards: never FlatDesign (its own path above) and never Liquid Glass
 *      (iOS 26+, so UIKit's path), both checked again here.
 * [CN] iOS 18 以前的经典 TabBar（UIKit 的 `-setTabBarHidden:animated:` 从 iOS 18 起才有）：隐藏或显示系统 TabBar 及其中的 PlusButton，
 *      动画与扁平样式一致：相同时长（`CYLClassicTabBarHideShowDuration`），TabBar 向下移出屏幕再移回，动画结束时设置 `hidden`。以最新
 *      请求为准：旧动画的完成回调不做处理。`animated` 为 NO 或 TabBar 不在屏幕上时不执行动画。Guard：不处理扁平样式（上方有自己的
 *      路径）与液态玻璃（iOS 26+，走 UIKit 的路径），在这里再次检查。
 */
- (void)cyl_setClassicTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    UITabBar *tabBar = self.tabBar;
    // Guard: only the classic tab bar. 只处理经典 TabBar。
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType || [CYLConstants isLiquidGlassActive] || !tabBar) {
        return;
    }
    // Guard: the same request is already animating. 同一请求的动画正在进行。
    if (_cylClassicTabBarIsAnimating && _cylClassicTabBarHiddenRequest == hidden) {
        return;
    }
    NSUInteger generation = ++_cylClassicTabBarAnimationGeneration;
    if (!animated || !tabBar.window || CGRectIsEmpty(tabBar.bounds)) {
        _cylClassicTabBarIsAnimating = NO;
        tabBar.transform = CGAffineTransformIdentity;
        tabBar.hidden = hidden;
        return;
    }
    // Guard: already there, nothing animating. 已是目标状态且没有动画。
    if (!_cylClassicTabBarIsAnimating && tabBar.hidden == hidden) {
        return;
    }
    _cylClassicTabBarIsAnimating = YES;
    _cylClassicTabBarHiddenRequest = hidden;
    CGFloat distance = CYLClassicTabBarHideDistance(tabBar);
    if (!hidden && tabBar.hidden) {
        // [EN] Showing: start below the screen, as FlatDesign does. [CN] 显示：与扁平样式一样，从屏幕下方开始。
        tabBar.transform = CGAffineTransformMakeTranslation(0, distance);
        tabBar.hidden = NO;
    }
    CGAffineTransform endTransform = hidden ? CGAffineTransformMakeTranslation(0, distance) : CGAffineTransformIdentity;
    [UIView animateWithDuration:CYLClassicTabBarHideShowDuration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
        tabBar.transform = endTransform;
    } completion:^(BOOL __unused finished) {
        // [EN] A newer request owns the tab bar now. [CN] 已有更新的请求接管 TabBar。
        if (generation != self->_cylClassicTabBarAnimationGeneration) {
            return;
        }
        self->_cylClassicTabBarIsAnimating = NO;
        // [EN] Reset the transform, so later layouts by UIKit (e.g. rotation) never meet a moved tab bar.
        // [CN] 还原 transform，使 UIKit 之后的布局（如旋转）不会遇到移动过的 TabBar。
        tabBar.transform = CGAffineTransformIdentity;
        tabBar.hidden = hidden;
    }];
}

- (BOOL)_checkHidesBottomBarWhenPushed {
    BOOL showsTabBar = YES;
    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return showsTabBar; }
        UIViewController *selectedViewController = self.selectedViewController;
        if ([self _showsMoreNavigationController]) {
            NSInteger moreIndex = [self.tabBar.items indexOfObject:self.moreNavigationController.tabBarItem];
            if (self.selectedIndex >= moreIndex || self.selectedIndex == NSNotFound) {
                selectedViewController = self.moreNavigationController;
            }
        }
        if ([selectedViewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *navigationController = (UINavigationController *)selectedViewController;
            NSInteger currentIndex = [navigationController.viewControllers indexOfObject:navigationController.topViewController];
            NSInteger showsBottomBarIndex = -1;
            for (NSInteger index = 0; index < navigationController.viewControllers.count; index++) {
                UIViewController *viewController = navigationController.viewControllers[index];
                if (viewController.hidesBottomBarWhenPushed) {
                    showsBottomBarIndex = index - 1;
                    break;
                } else {
                    showsBottomBarIndex = index;
                }
            }
            if (currentIndex <= showsBottomBarIndex) {
                showsTabBar = YES;
            } else {
                showsTabBar = NO;
            }
        } else if ([selectedViewController isKindOfClass:[UIViewController class]]) {
            showsTabBar = !selectedViewController.hidesBottomBarWhenPushed;
        }
        return showsTabBar;
            
#else
#endif
    } else {/*Not CYLTabBarStyleTypeFlatDesign*/}
    return showsTabBar;
}

#if CYL_FLATDESIGN_AVAILABLE
- (void)setDelegate:(id<CYLTabBarControllerDelegate, CYLFlatDesignUITabBarControllerDelegate>)delegate {

#else
    - (void)setDelegate:(id<CYLTabBarControllerDelegate>)delegate {
#endif

        [super setDelegate:delegate];
    
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
            if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
            _delegateHas.willShowTabBar = [delegate respondsToSelector:@selector(tabBarController:willShowTabBar:)];
            _delegateHas.didShowTabBar = [delegate respondsToSelector:@selector(tabBarController:didShowTabBar:)];
            _delegateHas.willHideTabBar = [delegate respondsToSelector:@selector(tabBarController:willHideTabBar:)];
            _delegateHas.didHideTabBar = [delegate respondsToSelector:@selector(tabBarController:didHideTabBar:)];
#else
#endif
        
        } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    }

- (void)setupChildViewController:(UIViewController *)viewController
                             idx:(NSUInteger)idx {
    
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        NSString *title = nil;
        id normalImageInfo = nil;
        id selectedImageInfo = nil;
        UIOffset titlePositionAdjustment = UIOffsetZero;
        UIOffset imagePositionAdjustment = UIOffsetZero;
                
        UIEdgeInsets imageInsets = UIEdgeInsetsZero;
        NSURL *lottieURL = nil;
        NSString *lottieFilePath = nil;
                
        NSValue *lottieSizeValue = nil;
        BOOL readsTabBarItemAttributes = (viewController != [self cyl_contextPlusChildViewController]) &&
            (!viewController.cyl_isPlaceholder || [self cyl_tabBarItemsAttributesIncludePlusSlot]);
        if (readsTabBarItemAttributes) {
                    
            if (_tabBarItemsAttributes.count > idx) {
                if (@available(iOS 13.0, *)) {
                    //fix https://github.com/ChenYilong/CYLTabBarController/issues/437
                    title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle] ?: @"";
                } else {
                    title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle];
                }
                        
                // #620: an optional dark image per state (a name or a UIImage), combined here so both styles get it.
                        
                normalImageInfo = [UIImage cyl_imageWithImageInfo:_tabBarItemsAttributes[idx][CYLTabBarItemImage]
                        
                                                     darkImageInfo:_tabBarItemsAttributes[idx][CYLTabBarItemDarkImage]];
                        
                selectedImageInfo = [UIImage cyl_imageWithImageInfo:_tabBarItemsAttributes[idx][CYLTabBarItemSelectedImage]
                        
                                                       darkImageInfo:_tabBarItemsAttributes[idx][CYLTabBarItemSelectedDarkImage]];
                lottieURL = _tabBarItemsAttributes[idx][CYLTabBarLottieURL];
                lottieFilePath = _tabBarItemsAttributes[idx][CYLTabBarLottieFilePath];
                        
                if (!lottieURL) {
                    lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
                }
                        
                CYLRegisterDarkLottieURLFromAttributes(lottieURL, _tabBarItemsAttributes[idx]);
                lottieSizeValue = _tabBarItemsAttributes[idx][CYLTabBarLottieSize];
                // FIX: issue #408 the tab's identifier. Tab 的标识。
                viewController.cyl_tabBarItemIdentifier = _tabBarItemsAttributes[idx][CYLTabBarItemIdentifier];
                // FIX: issue #433
                // [EN] The title shown while the tab is selected.
                // [CN] 选中时显示的标题。
                CYLRememberTabBarItemSelectedTitle(viewController, _tabBarItemsAttributes[idx], title);
                        
                NSValue *offsetValue = _tabBarItemsAttributes[idx][CYLTabBarItemTitlePositionAdjustment];
                UIOffset offset = [offsetValue UIOffsetValue];
                titlePositionAdjustment = offset;
                        
                NSValue *imagePositionAdjustmentoffsetValue = _tabBarItemsAttributes[idx][CYLTabBarItemImagePositionAdjustment];
                UIOffset imagePositionAdjustmentoffset = [imagePositionAdjustmentoffsetValue UIOffsetValue];
                imagePositionAdjustment = imagePositionAdjustmentoffset;
                        
                NSValue *insetsValue = _tabBarItemsAttributes[idx][CYLTabBarItemImageInsets];
                UIEdgeInsets insets = [insetsValue UIEdgeInsetsValue];
                imageInsets = insets;
            }
                    
        } else {
            /** [CN] 如果是CYLPlusChildViewController ，title设置为空字符串，解决把第一个tabbarItem设置成plusButton后，其他的
             tabbarItem会不显示title问题
              见： https://github.com/ChenYilong/CYLTabBarController/issues/563
             * [EN] If it is a CYLPlusChildViewController, set the title to an empty string. This fixes an issue where,
             *      after making the
             *      first tabbarItem the plusButton, the other tabbarItems would not show their titles
             *      See: https://github.com/ChenYilong/CYLTabBarController/issues/563
             **/
            title = @"";
            // [EN] Guarded by the data (`-cyl_tabBarItemsAttributesIncludePlusSlot`), not by the style.
            // [CN] 按数据判断（`-cyl_tabBarItemsAttributesIncludePlusSlot`），而不是按样式。
            if (![self cyl_tabBarItemsAttributesIncludePlusSlot]) {
                idx--;
            }
        }
        [self addOneChildViewController:viewController
                                    idx:idx
                              WithTitle:title
                        normalImageInfo:normalImageInfo
                      selectedImageInfo:selectedImageInfo
                titlePositionAdjustment:titlePositionAdjustment
                imagePositionAdjustment:imagePositionAdjustment
                            imageInsets:imageInsets
                              lottieURL:lottieURL
                         lottieFilePath:lottieFilePath
                        lottieSizeValue:lottieSizeValue];
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/    }
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
            [self.lottieURLs addObject:lottieURL];
            NSValue *tureLottieSizeValue = [CYLConstants cyl_getTureLottieSizeValue:lottieSizeValue fromNormalImage:normalImage];
            [self.lottieSizes addObject:tureLottieSizeValue];
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
    if (self = [super init]) {
        _imageInsets = imageInsets;
        _titlePositionAdjustment = titlePositionAdjustment;
        _tabBarItemsAttributes = tabBarItemsAttributes;
        _adjustTabBarItemImageViewSizeDependOnSuperView = YES;
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
        self.viewControllers = viewControllers;// [CN] 步骤3 must use setter,必须在 self.tabBarStyleType之后设置， 因为 self.viewControllers 直接涉及到扁平TabBar样式KVC逻辑。
        // [EN] Step 3: must use the setter and must be set after self.tabBarStyleType,
        //      because self.viewControllers directly involves the KVC logic of the flat TabBar style.
        
    }
    return self;
}

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

- (BOOL)updateTabBarItemForViewController:(UIViewController *)viewController attributes:(NSDictionary<NSString *, id> *)attributes {
    NSUInteger index = viewController ? [_viewControllers indexOfObject:viewController] : NSNotFound;
    if (index == NSNotFound) {
        index = [_viewControllers indexOfObjectPassingTest:^BOOL(UIViewController *obj, NSUInteger idx, BOOL *stop) {
            return [obj cyl_getViewControllerInsteadOfNavigationController] == viewController;
        }];
    }
    return index != NSNotFound && [self updateTabBarItemAtIndex:index attributes:attributes];
}

- (void)updateTabBarItemsWithAttributes:(NSArray<NSDictionary<NSString *, id> *> *)tabBarItemsAttributes {
    NSUInteger attributesIndex = 0;
    for (NSUInteger index = 0; index < _viewControllers.count && attributesIndex < tabBarItemsAttributes.count; index++) {
        UIViewController *viewController = _viewControllers[index];
        // [EN] The plus button's tab has no entry.
        // [CN] PlusButton 的 Tab 不占项。
        if (viewController.cyl_isPlaceholder || viewController == [self cyl_contextPlusChildViewController]) {
            continue;
        }
        [self updateTabBarItemAtIndex:index attributes:tabBarItemsAttributes[attributesIndex]];
        attributesIndex++;
    }
}

- (BOOL)updateTabBarItemAtIndex:(NSUInteger)index attributes:(NSDictionary<NSString *, id> *)attributes {
    if (index >= _viewControllers.count || attributes.count == 0) {
        return NO;
    }
    UIViewController *viewController = _viewControllers[index];
    // The plus button's tab shows the plus button (its own title and image); a placeholder has nothing to show.
    if (viewController.cyl_isPlaceholder || viewController == [self cyl_contextPlusChildViewController]) {
        return NO;
    }
    NSUInteger attributesIndex = [self cyl_tabBarItemsAttributesIndexOfViewControllerAtIndex:index];
    NSDictionary *oldAttributes = (attributesIndex < _tabBarItemsAttributes.count) ? _tabBarItemsAttributes[attributesIndex] : @{};
    NSMutableDictionary *newAttributes = [oldAttributes mutableCopy];
    [newAttributes addEntriesFromDictionary:attributes];
    if (attributesIndex < _tabBarItemsAttributes.count) {
        NSMutableArray *tabBarItemsAttributes = [_tabBarItemsAttributes mutableCopy];
        tabBarItemsAttributes[attributesIndex] = [newAttributes copy];
        _tabBarItemsAttributes = [tabBarItemsAttributes copy];
    }
    // FIX: issue #433
    // [EN] A new normal or selected title is remembered, so a later selection change shows the new ones.
    // [CN] 记录新的普通标题或选中标题，之后切换选中时显示新的标题。
    BOOL updatesSelectedTitle = (attributes[CYLTabBarItemTitle] || attributes[CYLTabBarItemSelectedTitle]);
    if (updatesSelectedTitle) {
        CYLRememberTabBarItemSelectedTitle(viewController, newAttributes, newAttributes[CYLTabBarItemTitle]);
    }
    // [EN] Per-tab colors are applied on the next layout pass (`-cyl_syncTabBarAppearances`, `-cyl_bindTabControlActions`).
    // [CN] 单个 Tab 的颜色在下一次布局时生效（`-cyl_syncTabBarAppearances`、`-cyl_bindTabControlActions`）。
    if (self.isViewLoaded && (attributes[CYLTabBarItemTitleColor] || attributes[CYLTabBarItemSelectedTitleColor] ||
                              attributes[CYLTabBarItemIconColor] || attributes[CYLTabBarItemSelectedIconColor] ||
                              attributes[CYLTabBarItemSelectedBackgroundColor] || attributes[CYLTabBarItemBackgroundColor] ||
                              attributes[CYLTabBarItemTitleFont] || attributes[CYLTabBarItemSelectedTitleFont])) {
        [self.view setNeedsLayout];
        [self cyl_updateSelectedBackgroundColorsOfTabButtons];
    }

    // As when the tab was set up (`-setViewControllers:`), so a dark image is combined with its light one (#620).
    NSString *title = attributes[CYLTabBarItemTitle];
    BOOL updatesImage = attributes[CYLTabBarItemImage] || attributes[CYLTabBarItemDarkImage];
    BOOL updatesSelectedImage = attributes[CYLTabBarItemSelectedImage] || attributes[CYLTabBarItemSelectedDarkImage];
    UIImage *image = updatesImage ? [UIImage cyl_imageNamed:[UIImage cyl_imageWithImageInfo:newAttributes[CYLTabBarItemImage]
                                                                               darkImageInfo:newAttributes[CYLTabBarItemDarkImage]]] : nil;
    UIImage *selectedImage = updatesSelectedImage ?
        [UIImage cyl_imageNamed:[UIImage cyl_imageWithImageInfo:newAttributes[CYLTabBarItemSelectedImage]
                                                  darkImageInfo:newAttributes[CYLTabBarItemSelectedDarkImage]]] : nil;

    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        // Each change posts `CYLFlatDesignTabBarItemDidChange`, and its button lays itself out again.
        CYLFlatDesignTabBarItem *tabBarItem = viewController.cyl_tabBarItem;
        if (![tabBarItem isKindOfClass:[CYLFlatDesignTabBarItem class]]) {
            return NO;
        }
        if (title) { tabBarItem.title = title; }
        if (image) { tabBarItem.image = image; }
        if (selectedImage) { tabBarItem.selectedImage = selectedImage; }
        // FIX: issue #433
        // [EN] The selected tab shows its selected title, not the new normal title.
        // [CN] 选中的 Tab 显示选中标题，而不是新的普通标题。
        if (updatesSelectedTitle) {
            CYLApplyTabBarItemSelectedTitles(self);
        }
        if (attributes[CYLTabBarItemImageURL] || attributes[CYLTabBarItemSelectedImageURL] || attributes[CYLTabBarItemImageURLSize]) {
            [self cyl_loadImageURLsOfAttributes:newAttributes atIndex:index];
        }
        return YES;
#else
        return NO;
#endif
    }
    // Liquid Glass and the system tab bar: `UITabBarItem` redraws its tab when a property changes.
    NSMutableArray<UITabBarItem *> *tabBarItems = [NSMutableArray arrayWithObject:viewController.tabBarItem];
    UITabBarItem *rootTabBarItem = [viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem;
    if (rootTabBarItem && rootTabBarItem != viewController.tabBarItem) {
        [tabBarItems addObject:rootTabBarItem];
    }
    for (UITabBarItem *tabBarItem in tabBarItems) {
        if (title) { tabBarItem.title = title; }
        if (image) { tabBarItem.image = image; }
        if (selectedImage) { tabBarItem.selectedImage = selectedImage; }
    }
    // FIX: issue #433
    // [EN] The selected tab shows its selected title, not the new normal title.
    // [CN] 选中的 Tab 显示选中标题，而不是新的普通标题。
    if (updatesSelectedTitle) {
        CYLApplyTabBarItemSelectedTitles(self);
    }
    // FIX: issue #257, #522
    // [EN] An image-only tab that gets a title is no longer image-only: undo the automatic adjustment, or the title stays
    //      off screen (`UIOffsetMake(0, MAXFLOAT)`). A tab whose title becomes empty gets it again.
    // [CN] 纯图标 Tab 设置标题后就不再是纯图标 Tab：撤销自动调整，否则标题会一直在屏幕外（`UIOffsetMake(0, MAXFLOAT)`）。
    //      标题被清空的 Tab 重新获得自动调整。
    if (title) {
        if (title.length > 0) {
            [self cyl_restoreImageOnlyTabItems:tabBarItems];
        } else if ([_cyl_tabBar isKindOfClass:[CYLTabBar class]] && ((CYLTabBar *)_cyl_tabBar).tabImageViewDefaultOffset != 0.f) {
            [self offsetTabBarTabImageViewToFit:((CYLTabBar *)_cyl_tabBar).tabImageViewDefaultOffset];
        }
    }
    // [EN] Liquid Glass may keep the tab buttons' previous layout (a longer title overlapping the plus button and the next
    //      tab) until a tab is tapped: reload them as a tap does.
    // [CN] 液态玻璃可能保持 Tab 按钮原来的布局（较长的标题与 PlusButton 及
    //      后一个 Tab 重叠），直到点击某个 Tab：像点击一样重新加载它们。
    if ([self.tabBar isKindOfClass:[CYLTabBar class]]) {
        [(CYLTabBar *)self.tabBar cyl_reloadTabButtons];
    }
    // [EN] Icons from the network replace the images once downloaded (`CYLTabBarItemImageURL`).
    // [CN] 网络图标下载完成后覆盖图片。
    if (attributes[CYLTabBarItemImageURL] || attributes[CYLTabBarItemSelectedImageURL] || attributes[CYLTabBarItemImageURLSize]) {
        [self cyl_loadImageURLsOfAttributes:newAttributes atIndex:index];
    }
    return YES;
}

#pragma mark - A view of yours in place of a tab's icon (issue #601)

static char CYLTabBarItemIconViewProvidersKey;
static char CYLTabBarItemIconViewsKey;
static char CYLTabBarItemIconViewsProviderKey;

/// [EN] The icon view providers by view controller (weak).
/// [CN] 按子控制器（弱引用）保存的图标视图 provider。
- (NSMapTable<UIViewController *, CYLTabBarItemIconViewProvider> *)cyl_tabBarItemIconViewProviders {
    NSMapTable *providers = objc_getAssociatedObject(self, &CYLTabBarItemIconViewProvidersKey);
    if (!providers) {
        providers = [NSMapTable weakToStrongObjectsMapTable];
        objc_setAssociatedObject(self, &CYLTabBarItemIconViewProvidersKey, providers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return providers;
}

- (BOOL)setTabBarItemIconViewProvider:(CYLTabBarItemIconViewProvider)provider atIndex:(NSUInteger)index {
    if (index >= _viewControllers.count) {
        return NO;
    }
    UIViewController *viewController = _viewControllers[index];
    if (viewController.cyl_isPlaceholder || viewController == [self cyl_contextPlusChildViewController]) {
        return NO;
    }
    NSMapTable *providers = [self cyl_tabBarItemIconViewProviders];
    if (provider) {
        [providers setObject:[provider copy] forKey:viewController];
    } else {
        [providers removeObjectForKey:viewController];
    }
    [self cyl_updateTabBarItemIconViewsOfViewController:viewController];
    // [EN] The tab bar lays its buttons out again, as when a tab is selected.
    // [CN] TabBar 重新布局其按钮，与选中 Tab 时相同。
    [self.tabBar setNeedsLayout];
    [self cyl_setNeedsUpdateTabBarItemIconViews];
    return YES;
}

- (BOOL)setTabBarItemIconWithURL:(NSURL *)URL selectedURL:(NSURL *)selectedURL size:(CGSize)size atIndex:(NSUInteger)index {
    return URL && [self setTabBarItemIcon:URL selectedIcon:selectedURL size:size atIndex:index];
}

/*!
 * [EN] The image of `icon`, on the main queue: a `UIImage` as it is; an `NSURL` or an `http(s)` string loaded through
 *      `CYLImageCache`; any other string by name or absolute path (`+[UIImage cyl_imageNamed:]`, #535). nil when there is none.
 * [CN] 在主队列返回 `icon` 对应的图片：`UIImage` 原样返回；`NSURL` 或 `http(s)` 字符串通过 `CYLImageCache` 加载；其他字符串按图片名或
 *      绝对路径加载（`+[UIImage cyl_imageNamed:]`，#535）。没有图片时为 nil。
 */
static void CYLLoadTabBarItemIcon(id _Nullable icon, void (^completion)(UIImage *_Nullable image)) {
    if ([icon isKindOfClass:[UIImage class]]) {
        completion(icon);
        return;
    }
    NSURL *URL = [icon isKindOfClass:[NSURL class]] ? icon : nil;
    if ([icon isKindOfClass:[NSString class]] && ([icon hasPrefix:@"http://"] || [icon hasPrefix:@"https://"])) {
        URL = [NSURL URLWithString:icon];
    }
    if (URL) {
        [UIImage cyl_loadImageWithURL:URL completion:completion];
        return;
    }
    completion([icon isKindOfClass:[NSString class]] ? [UIImage cyl_imageNamed:icon] : nil);
}

/// [EN] `image` drawn at `size` with its own colors, every frame of an animated one. [CN] 按 `size` 以原图颜色绘制 `image`，动图的每一帧都绘制。
static UIImage *CYLImageScaledToSize(UIImage *image, CGSize size) {
    if (!image || size.width <= 0 || size.height <= 0 || CGSizeEqualToSize(image.size, size)) {
        return [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    }
    UIImage *(^scale)(UIImage *) = ^UIImage *(UIImage *frame) {
        CGFloat ratio = MIN(size.width / frame.size.width, size.height / frame.size.height);
        CGSize fittedSize = CGSizeMake(frame.size.width * ratio, frame.size.height * ratio);
        UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:fittedSize];
        return [renderer imageWithActions:^(UIGraphicsImageRendererContext *context) {
            [frame drawInRect:(CGRect){CGPointZero, fittedSize}];
        }];
    };
    UIImage *scaledImage = nil;
    if (image.images.count > 1) {
        NSMutableArray<UIImage *> *frames = [NSMutableArray arrayWithCapacity:image.images.count];
        for (UIImage *frame in image.images) {
            [frames addObject:scale(frame)];
        }
        scaledImage = [UIImage animatedImageWithImages:frames duration:image.duration];
    } else {
        scaledImage = scale(image);
    }
    return [scaledImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

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
    self.invokeOnceViewDidLayoutSubViewsBlock = YES;
    self.lottieViewAdded = NO;
    [_lottieURLs removeAllObjects];
    [_lottieSizes removeAllObjects];
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

- (BOOL)updatePlusButtonWithAttributes:(NSDictionary<NSString *, id> *)attributes {
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForOwner:self];
    if (!plusButton || attributes.count == 0) {
        return NO;
    }
    NSString *title = attributes[CYLTabBarItemTitle];
    if (title) {
        [plusButton cyl_updateTitle:title image:nil selectedImage:nil];
    }
    id icon = attributes[CYLTabBarItemImageURL] ?: attributes[CYLTabBarItemImage];
    id selectedIcon = attributes[CYLTabBarItemSelectedImageURL] ?: attributes[CYLTabBarItemSelectedImage];
    NSValue *sizeValue = attributes[CYLTabBarItemImageURLSize];
    CGSize size = [sizeValue isKindOfClass:[NSValue class]] ? sizeValue.CGSizeValue : [plusButton imageForState:UIControlStateNormal].size;
    // FIX: issue #601
    // [EN] Never left unscaled: a downloaded image keeps its own size (a 512 px icon is about 170 pt), which resizes the
    //      plus button and moves it. Without a size, the image view's, else the tab icon's.
    // [CN] 不保留原始尺寸：下载的图片会保持自身尺寸（512 px 的图标约 170 pt），导致 PlusButton 尺寸变化并移位。没有尺寸时
    //      使用图片视图的尺寸，否则使用 Tab 图标的尺寸。
    if (size.width <= 0 || size.height <= 0) {
        size = plusButton.imageView.bounds.size;
    }
    if (size.width <= 0 || size.height <= 0) {
        size = CGSizeMake(CYLTabBarItemImagePlaceholderWidth, CYLTabBarItemImagePlaceholderHeight);
    }
    __weak CYLPlusButton *weakPlusButton = plusButton;
    if (icon) {
        CYLLoadTabBarItemIcon(icon, ^(UIImage *image) {
            [weakPlusButton cyl_updateTitle:nil image:CYLImageScaledToSize(image, size) selectedImage:nil];
        });
    }
    if (selectedIcon) {
        CYLLoadTabBarItemIcon(selectedIcon, ^(UIImage *image) {
            [weakPlusButton cyl_updateTitle:nil image:nil selectedImage:CYLImageScaledToSize(image, size)];
        });
    }
    return YES;
}

- (BOOL)setTabBarItemIcon:(id)icon selectedIcon:(id)selectedIcon size:(CGSize)size atIndex:(NSUInteger)index {
    if (index >= _viewControllers.count || !icon) {
        return NO;
    }
    UIViewController *viewController = _viewControllers[index];
    if (viewController.cyl_isPlaceholder || viewController == [self cyl_contextPlusChildViewController]) {
        return NO;
    }
    __weak __typeof(self) weakSelf = self;
    __weak UIViewController *weakViewController = viewController;
    CYLLoadTabBarItemIcon(icon, ^(UIImage *image) {
        if (!image) {
            return;
        }
        void (^show)(UIImage *) = ^(UIImage *selectedImage) {
            __strong __typeof(weakSelf) self = weakSelf;
            // [EN] Still a tab of this controller (the view controllers may have changed meanwhile).
            // [CN] 仍是本控制器的 Tab（期间视图控制器可能已改变）。
            NSUInteger currentIndex = weakViewController ? [self.viewControllers indexOfObject:weakViewController] : NSNotFound;
            if (!self || currentIndex == NSNotFound) {
                return;
            }
            UIImage *originalImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            UIImage *originalSelectedImage = [(selectedImage ?: image) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            [self setTabBarItemIconViewProvider:^UIView *(BOOL selected) {
                UIImageView *iconView = [[UIImageView alloc] initWithImage:(selected ? originalSelectedImage : originalImage)];
                iconView.contentMode = UIViewContentModeScaleAspectFit;
                CGSize iconSize = CGSizeEqualToSize(size, CGSizeZero) ?
                    CGSizeMake(CYLTabBarItemImagePlaceholderWidth, CYLTabBarItemImagePlaceholderHeight) : size;
                iconView.frame = (CGRect){CGPointZero, iconSize};
                return iconView;
            } atIndex:currentIndex];
        };
        if (!selectedIcon || [selectedIcon isEqual:icon]) {
            show(nil);
        } else {
            CYLLoadTabBarItemIcon(selectedIcon, show);
        }
    });
    return YES;
}

/*!
 * [EN] The tab buttons of `viewController`: the tab button, and with Liquid Glass the one in the selected layer (lens).
 * [CN] `viewController` 的 Tab 按钮：Tab 按钮本身，液态玻璃下还有选中图层（放大镜）中的那个。
 */
- (NSArray<UIControl *> *)cyl_tabButtonsOfViewController:(UIViewController *)viewController {
    UIControl *tabButton = nil;
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
        tabButton = viewController.cyl_tabButton;
    } else {
        tabButton = viewController.tabBarItem.cyl_tabButton;
    }
    if (![tabButton isKindOfClass:[UIControl class]]) {
        return @[];
    }
    UIControl *selectedLayerTabButton = [CYLConstants isLiquidGlassActive] ? tabButton.cyl_platterSelectedControl : nil;
    if (selectedLayerTabButton && selectedLayerTabButton != tabButton) {
        return @[tabButton, selectedLayerTabButton];
    }
    return @[tabButton];
}

/// [EN] After layout and selection changes, on the next run loop: UIKit has updated the tab buttons by then.
/// [CN] 布局与选中变化后，在下一个 run loop 执行：此时 UIKit 已更新 Tab 按钮。
- (void)cyl_setNeedsUpdateTabBarItemIconViews {
    if ([self cyl_tabBarItemIconViewProviders].count == 0) {
        return;
    }
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf cyl_updateTabBarItemIconViews];
    });
}

/// [EN] Installs, removes or shows the icon views of every tab with a provider.
/// [CN] 安装、移除或显示所有设置了 provider 的 Tab 的图标视图。
- (void)cyl_updateTabBarItemIconViews {
    for (UIViewController *viewController in [self cyl_tabBarItemIconViewProviders].keyEnumerator.allObjects) {
        [self cyl_updateTabBarItemIconViewsOfViewController:viewController];
    }
}

- (void)cyl_updateTabBarItemIconViewsOfViewController:(UIViewController *)viewController {
    CYLTabBarItemIconViewProvider provider = [[self cyl_tabBarItemIconViewProviders] objectForKey:viewController];
    NSArray<UIControl *> *tabButtons = [self cyl_tabButtonsOfViewController:viewController];
    BOOL isSelected = (viewController == self.selectedViewController);
    [tabButtons enumerateObjectsUsingBlock:^(UIControl *tabButton, NSUInteger idx, BOOL *stop) {
        NSMutableDictionary<NSNumber *, UIView *> *iconViews = objc_getAssociatedObject(tabButton, &CYLTabBarItemIconViewsKey);
        id installedProvider = objc_getAssociatedObject(tabButton, &CYLTabBarItemIconViewsProviderKey);
        UIView *lottieView = tabButton.cyl_lottieAnimationView;
        // [EN] A cover over the tab button (e.g. a logo over the first tab) hides its other views, the tab's own icon too:
        //      the views shown in place of the icon stay hidden under it.
        // [CN] 覆盖 Tab 按钮的封面（如第一个 Tab 上的 Logo）会隐藏按钮
        //      中的其他视图，包括 Tab 自身的图标：替换图标的视图在其下方保持隐藏。
        BOOL isCovered = NO;
        for (UIView *subview in tabButton.subviews) {
            if (subview.cyl_isTabButtonCoverView && !subview.cyl_isInvisiable) {
                isCovered = YES;
                break;
            }
        }
        if (installedProvider != provider) {
            // [EN] Another provider, or none: remove the views of the previous one.
            // [CN] 换了 provider 或已移除：移除之前的视图。
            for (UIView *iconView in iconViews.allValues) {
                [iconView removeFromSuperview];
            }
            iconViews = nil;
            objc_setAssociatedObject(tabButton, &CYLTabBarItemIconViewsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(tabButton, &CYLTabBarItemIconViewsProviderKey, provider, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            if (!provider) {
                // [EN] The tab's own icon and its badge come back, unless the cover hides them.
                // [CN] Tab 自身的图标及其角标恢复，除非被封面隐藏。
                [self cyl_setTabImageView:tabButton.cyl_tabImageView lottieView:lottieView replacedByIconView:NO];
                if (!isCovered) {
                    tabButton.cyl_tabImageView.hidden = (lottieView != nil);
                    lottieView.hidden = NO;
                }
                return;
            }
        }
        if (!provider) {
            return;
        }
        if (!iconViews) {
            iconViews = [NSMutableDictionary dictionary];
            // [EN] Liquid Glass: one look per layer (the second button is the selected layer); other styles: both looks here.
            // [CN] 液态玻璃：每个图层一种样式（第二个按钮是选中图层）；其他样式：两种样式都在这个按钮上。
            NSArray<NSNumber *> *looks = (tabButtons.count > 1) ? @[@(idx == 1)] : @[@NO, @YES];
            for (NSNumber *look in looks) {
                UIView *iconView = provider(look.boolValue);
                if (!iconView) {
                    continue;
                }
                iconView.userInteractionEnabled = NO;
                iconView.cyl_tabBarItemIconView = YES;
                [tabButton cyl_replaceTabImageViewWithNewView:iconView show:YES];
                if (iconView.superview == tabButton) {
                    iconViews[look] = iconView;
                }
            }
            objc_setAssociatedObject(tabButton, &CYLTabBarItemIconViewsKey, iconViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        if (iconViews.count == 0) {
            return;
        }
        // [EN] The tab's own icon stays hidden (the system may show it again when the tab changes); its badge stays visible
        //      above it.
        // [CN] Tab 自身图标保持隐藏（切换 Tab 时系统可能重新显示它）；其角标仍显示在它上方。
        tabButton.cyl_tabImageView.hidden = YES;
        lottieView.hidden = YES;
        // [EN] Under a cover the badge stays as the cover left it (cleared).
        // [CN] 有封面时角标保持封面设置的状态（已清除）。
        [self cyl_setTabImageView:tabButton.cyl_tabImageView lottieView:lottieView replacedByIconView:!isCovered];
        // [EN] Below the tab's own icon, or the subview of the tab button holding it (Liquid Glass), so the badge shown above
        //      that icon stays above this view too.
        // [CN] 位于 Tab 自身图标（或液态玻璃中包含它的 Tab 按钮子视图）之下，使该图标上方的角标也位于此视图之上。
        UIView *iconHolder = lottieView ?: tabButton.cyl_tabImageView;
        while (iconHolder && iconHolder.superview != tabButton) {
            iconHolder = iconHolder.superview;
        }
        for (UIView *iconView in iconViews.allValues) {
            if (iconHolder && iconView.superview == tabButton) {
                [tabButton insertSubview:iconView belowSubview:iconHolder];
            }
        }
        UIView *unselectedView = iconViews[@NO];
        UIView *selectedView = iconViews[@YES];
        if (unselectedView && selectedView) {
            unselectedView.hidden = isCovered || isSelected;
            selectedView.hidden = isCovered || !isSelected;
        } else {
            for (UIView *iconView in iconViews.allValues) {
                iconView.hidden = isCovered;
            }
        }
    }];
}

/// [EN] Marks the tab's own icon as hidden for the view shown in its place, or not, and moves its badge accordingly: onto
///      an overlay above it, or back into it.
/// [CN] 标记 Tab 自身的图标是否因替换显示而隐藏，并相应移动其角标：移到其上方的浮层，或移回图标中。
- (void)cyl_setTabImageView:(UIView *)tabImageView lottieView:(UIView *)lottieView replacedByIconView:(BOOL)replaced {
    for (UIView *host in @[ tabImageView ?: (id)[NSNull null], lottieView ?: (id)[NSNull null] ]) {
        if (![host isKindOfClass:[UIView class]] || host.cyl_isBadgeHostReplacedByIconView == replaced) {
            continue;
        }
        host.cyl_badgeHostReplacedByIconView = replaced;
        [host cyl_refreshBadge];
    }
}

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
    _tabBarItemsAttributes = tabBarItemsAttributes;
    self.invokeOnceViewDidLayoutSubViewsBlock = YES;
    self.lottieViewAdded = NO;
    [_lottieURLs removeAllObjects];
    [_lottieSizes removeAllObjects];
    NSInteger index = [self selectedIndex];
    // FIX: issue #618 — `selectedIndex` is not always a valid index into `_viewControllers` (e.g. NSNotFound, or an
    // extra tab UIKit created for a child that is not in `viewControllers`). Do not index out of range.
    UIViewController *selected = (index >= 0 && index < (NSInteger)_viewControllers.count) ? _viewControllers[index] : nil;
    UIView *superView = selected.view.superview;
    NSMutableArray<UIViewController *> *viewControllers = [_viewControllers mutableCopy];
    if ([self hasPlusChildViewController]) {
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
    // FIX: issue #433
    // [EN] The reloaded tabs show the selected title on the selected tab.
    // [CN] 重新加载后，选中的 Tab 显示选中标题。
    CYLSetNeedsUpdateTabBarItemSelectedTitles(self);
    [self.view setNeedsLayout];
    self.selectedIndex = index;
    [superView addSubview:selected.view];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
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
            return;
        }
        CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;

        [cyl_tabBar cyl_setTabBarItemWidth:(cyl_tabBar.cyl_boundsSize.width - cyl_tabBar.cyl_plusButtonWidth) / (cyl_tabBar.cyl_tabbarItemsCount)];
        NSUInteger idx = 0;
        for (UIViewController *viewController in _viewControllers) {
            NSString *title = nil;
            id normalImageInfo = nil;
            id selectedImageInfo = nil;
            UIOffset titlePositionAdjustment = UIOffsetZero;
            UIOffset imagePositionAdjustment = UIOffsetZero;
            UIEdgeInsets imageInsets = UIEdgeInsetsZero;
            NSURL *lottieURL = nil;
            NSString *lottieFilePath = nil;
        
            NSValue *lottieSizeValue = nil;
            // [EN] FIX: placeholder count mismatch — a placeholder reads its own (marked) entry only when the attributes have
            //      one; otherwise it is skipped like the plus child view controller, so later tabs keep their own entries.
            // [CN] FIX：占位导致的数量不匹配——只有属性中有 slot 项时占位控制器才读取它（带标记的那一项）；否则与 PlusButton
            //      子控制器一样跳过，之后的 Tab 仍对应各自的属性。
            BOOL readsTabBarItemAttributes = (viewController != [self cyl_contextPlusChildViewController]) &&
                (!viewController.cyl_isPlaceholder || [self cyl_tabBarItemsAttributesIncludePlusSlot]);
            if (readsTabBarItemAttributes) {
                if (_tabBarItemsAttributes.count > idx) {
                    if (@available(iOS 13.0, *)) {
                        //fix https://github.com/ChenYilong/CYLTabBarController/issues/437
                        title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle] ?: @"";
                    } else {
                        title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle];
                    }
                
                    // #620: an optional dark image per state (a name or a UIImage), combined here so both styles get it.
                
                    normalImageInfo = [UIImage cyl_imageWithImageInfo:_tabBarItemsAttributes[idx][CYLTabBarItemImage]
                
                                                         darkImageInfo:_tabBarItemsAttributes[idx][CYLTabBarItemDarkImage]];
                
                    selectedImageInfo = [UIImage cyl_imageWithImageInfo:_tabBarItemsAttributes[idx][CYLTabBarItemSelectedImage]
                
                                                           darkImageInfo:_tabBarItemsAttributes[idx][CYLTabBarItemSelectedDarkImage]];
                    lottieURL = _tabBarItemsAttributes[idx][CYLTabBarLottieURL];
                    lottieFilePath = _tabBarItemsAttributes[idx][CYLTabBarLottieFilePath];
                
                    if (!lottieURL) {
                        lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
                    }
                
                    CYLRegisterDarkLottieURLFromAttributes(lottieURL, _tabBarItemsAttributes[idx]);
                    lottieSizeValue = _tabBarItemsAttributes[idx][CYLTabBarLottieSize];
                    // FIX: issue #408 the tab's identifier. Tab 的标识。
                    viewController.cyl_tabBarItemIdentifier = _tabBarItemsAttributes[idx][CYLTabBarItemIdentifier];
                    // FIX: issue #433
                    // [EN] The title shown while the tab is selected.
                    // [CN] 选中时显示的标题。
                    CYLRememberTabBarItemSelectedTitle(viewController, _tabBarItemsAttributes[idx], title);
                
                    NSValue *offsetValue = _tabBarItemsAttributes[idx][CYLTabBarItemTitlePositionAdjustment];
                    UIOffset offset = [offsetValue UIOffsetValue];
                    titlePositionAdjustment = offset;
                
                    NSValue *imagePositionAdjustmentoffsetValue = _tabBarItemsAttributes[idx][CYLTabBarItemImagePositionAdjustment];
                    UIOffset imagePositionAdjustmentoffset = [imagePositionAdjustmentoffsetValue UIOffsetValue];
                    imagePositionAdjustment = imagePositionAdjustmentoffset;
                
                    NSValue *insetsValue = _tabBarItemsAttributes[idx][CYLTabBarItemImageInsets];
                    UIEdgeInsets insets = [insetsValue UIEdgeInsetsValue];
                    imageInsets = insets;
                }
            } else {
                /** [CN] 如果是CYLPlusChildViewController ，title设置为空字符串，解决把第一个tabbarItem设置成plusButton后，其他的
                 tabbarItem会不显示title问题
                  见： https://github.com/ChenYilong/CYLTabBarController/issues/563
                 * [EN] If it is a CYLPlusChildViewController, set the title to an empty string. This fixes an issue where,
                 *      after making the
                 *      first tabbarItem the plusButton, the other tabbarItems would not show their titles
                 *      See: https://github.com/ChenYilong/CYLTabBarController/issues/563
                 **/
                title = @"";
                // [EN] A placeholder keeps the image its slot entry gives it (same tab item layout with or without that entry).
                // [CN] 占位控制器保持 slot 属性项提供的图片（有无该项时 TabBarItem 的布局相同）。
                if (viewController.cyl_isPlaceholder) {
                    normalImageInfo = [UIImage cyl_tabItemPlaceholderImage];
                    selectedImageInfo = [UIImage cyl_tabItemPlaceholderImage];
                }
                // [EN] Guarded by the data (`-cyl_tabBarItemsAttributesIncludePlusSlot`), not by the style.
                // [CN] 按数据判断（`-cyl_tabBarItemsAttributesIncludePlusSlot`），而不是按样式。
                if (![self cyl_tabBarItemsAttributesIncludePlusSlot]) {
                    idx--;
                }
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
    viewController.tabBarItem.image = normalImage;
    
    UIImage *selectedImage = [UIImage cyl_imageNamed:selectedImageInfo];;
    viewController.tabBarItem.selectedImage = selectedImage;
    
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
        [self.lottieURLs addObject:lottieURL];
        [viewController.tabBarItem cyl_setLottieURL:lottieURL];
        [[viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem cyl_setLottieURL:lottieURL];
        
        NSValue *tureLottieSizeValue = [CYLConstants cyl_getTureLottieSizeValue:lottieSizeValue fromNormalImage:normalImage];
        [self.lottieSizes addObject:tureLottieSizeValue];
        [viewController.tabBarItem cyl_setLottieSizeValue:tureLottieSizeValue];
        [[viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem cyl_setLottieSizeValue:tureLottieSizeValue];
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
static char CYLTitlePositionAdjustmentSetByCYLKey;
- (void)cyl_applyTitlePositionAdjustment:(UIOffset)offset toTabBarItem:(UITabBarItem *)tabBarItem {
    if (!tabBarItem) {
        return;
    }
    BOOL isZero = UIOffsetEqualToOffset(UIOffsetZero, offset);
    BOOL wasSetByCYL = (objc_getAssociatedObject(tabBarItem, &CYLTitlePositionAdjustmentSetByCYLKey) != nil);
    if (isZero && !wasSetByCYL) {
        return;
    }
    tabBarItem.titlePositionAdjustment = offset;
    objc_setAssociatedObject(tabBarItem, &CYLTitlePositionAdjustmentSetByCYLKey, isZero ? nil : [NSValue valueWithUIOffset:offset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (@available(iOS 13.0, *)) {
        [self cyl_syncTitlePositionAdjustmentAppearanceOfTabBarItem:tabBarItem];
    }
}

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
static char CYLTitlePositionAdjustmentItemOffsetKey;
static char CYLTitlePositionAdjustmentStandardAppearanceKey;
static char CYLTitlePositionAdjustmentScrollEdgeAppearanceKey;

/// The offset a tab asked for itself (`CYLTabBarItemTitlePositionAdjustment`), so a new controller-level offset does not
/// replace it. 记录 Tab 自身设置的偏移，避免被控制器级别的新偏移覆盖。
static void CYLRememberItemTitlePositionAdjustment(id _Nullable item, UIOffset offset) {
    id object = item;
    if (!object) {
        return;
    }
    BOOL isZero = UIOffsetEqualToOffset(UIOffsetZero, offset);
    objc_setAssociatedObject(object, &CYLTitlePositionAdjustmentItemOffsetKey, isZero ? nil : [NSValue valueWithUIOffset:offset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static UIOffset CYLTitlePositionAdjustmentForItem(id _Nullable item, UIOffset controllerOffset) {
    id object = item;
    NSValue *itemOffset = object ? objc_getAssociatedObject(object, &CYLTitlePositionAdjustmentItemOffsetKey) : nil;
    return itemOffset ? itemOffset.UIOffsetValue : controllerOffset;
}

API_AVAILABLE(ios(13.0))
static void CYLSetTitlePositionAdjustmentOfItemAppearance(UITabBarItemAppearance *itemAppearance, UIOffset offset) {
    for (UITabBarItemStateAppearance *state in @[ itemAppearance.normal, itemAppearance.selected, itemAppearance.disabled, itemAppearance.focused ]) {
        state.titlePositionAdjustment = offset;
    }
}

API_AVAILABLE(ios(13.0))
static UITabBarAppearance *CYLTabBarAppearanceWithTitlePositionAdjustment(UITabBarAppearance *base, UIOffset offset) {
    UITabBarAppearance *appearance = [base copy];
    CYLSetTitlePositionAdjustmentOfItemAppearance(appearance.stackedLayoutAppearance, offset);
    CYLSetTitlePositionAdjustmentOfItemAppearance(appearance.inlineLayoutAppearance, offset);
    CYLSetTitlePositionAdjustmentOfItemAppearance(appearance.compactInlineLayoutAppearance, offset);
    return appearance;
}

/// [EN] The per-tab colors and title fonts (`CYLTabBarItemTitleColor`, `CYLTabBarItemTitleFont`...) a tab asked for, kept on
///      its UITabBarItem; nil when none.
/// [CN] Tab 设置的颜色与标题字体（`CYLTabBarItemTitleColor`、`CYLTabBarItemTitleFont` 等），保存在其 UITabBarItem 上；没有时为 nil。
static char CYLTabBarItemColorsKey;

static NSDictionary<NSString *, id> *CYLTabBarItemColorsFromAttributes(NSDictionary *attributes) {
    NSMutableDictionary<NSString *, id> *colors = nil;
    for (NSString *key in @[ CYLTabBarItemTitleColor, CYLTabBarItemSelectedTitleColor, CYLTabBarItemIconColor, CYLTabBarItemSelectedIconColor ]) {
        id color = attributes[key];
        if ([color isKindOfClass:[UIColor class]]) {
            if (!colors) {
                colors = [NSMutableDictionary dictionary];
            }
            colors[key] = color;
        }
    }
    for (NSString *key in @[ CYLTabBarItemTitleFont, CYLTabBarItemSelectedTitleFont ]) {
        id font = attributes[key];
        if ([font isKindOfClass:[UIFont class]]) {
            if (!colors) {
                colors = [NSMutableDictionary dictionary];
            }
            colors[key] = font;
        }
    }
    return [colors copy];
}

/// [EN] Sets one title text attribute (color or font) of a state, keeping the others. [CN] 设置某个状态的一个标题属性（颜色或字体），保留其他属性。
API_AVAILABLE(ios(13.0))
static void CYLSetTitleAttributeOfStateAppearance(UITabBarItemStateAppearance *state, NSAttributedStringKey attributeName, id value) {
    if (!value) {
        return;
    }
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [state.titleTextAttributes mutableCopy] ?: [NSMutableDictionary dictionary];
    attributes[attributeName] = value;
    state.titleTextAttributes = attributes;
}

API_AVAILABLE(ios(13.0))
static void CYLSetColorsOfItemAppearance(UITabBarItemAppearance *itemAppearance, NSDictionary<NSString *, id> *colors) {
    CYLSetTitleAttributeOfStateAppearance(itemAppearance.normal, NSForegroundColorAttributeName, colors[CYLTabBarItemTitleColor]);
    CYLSetTitleAttributeOfStateAppearance(itemAppearance.selected, NSForegroundColorAttributeName, colors[CYLTabBarItemSelectedTitleColor]);
    // [EN] Fonts: the selected state uses the unselected font unless it has its own. [CN] 字体：选中状态没有单独设置时使用未选中的字体。
    UIFont *titleFont = colors[CYLTabBarItemTitleFont];
    UIFont *selectedTitleFont = colors[CYLTabBarItemSelectedTitleFont] ?: titleFont;
    CYLSetTitleAttributeOfStateAppearance(itemAppearance.normal, NSFontAttributeName, titleFont);
    CYLSetTitleAttributeOfStateAppearance(itemAppearance.selected, NSFontAttributeName, selectedTitleFont);
    if (colors[CYLTabBarItemIconColor]) {
        itemAppearance.normal.iconColor = colors[CYLTabBarItemIconColor];
    }
    if (colors[CYLTabBarItemSelectedIconColor]) {
        itemAppearance.selected.iconColor = colors[CYLTabBarItemSelectedIconColor];
    }
}

/*!
 * [EN] The appearance of one tab: a copy of `base` with its title offset (when `offsetValue` is set) and its colors (when
 *      `colors` is set) written into every layout.
 * [CN] 单个 Tab 的 appearance：`base` 的副本，写入其标题偏移（`offsetValue` 不为 nil 时）与颜色（`colors` 不为 nil 时），作用于所有布局。
 */
API_AVAILABLE(ios(13.0))
static UITabBarAppearance *CYLTabBarAppearanceForItem(UITabBarAppearance *base, NSValue *_Nullable offsetValue, NSDictionary<NSString *, id> *_Nullable colors) {
    UITabBarAppearance *appearance = offsetValue ? CYLTabBarAppearanceWithTitlePositionAdjustment(base, offsetValue.UIOffsetValue) : [base copy];
    if (colors.count > 0) {
        CYLSetColorsOfItemAppearance(appearance.stackedLayoutAppearance, colors);
        CYLSetColorsOfItemAppearance(appearance.inlineLayoutAppearance, colors);
        CYLSetColorsOfItemAppearance(appearance.compactInlineLayoutAppearance, colors);
    }
    return appearance;
}

/*!
 * [EN] Keeps one appearance of `tabBarItem` (`standardAppearance` or `scrollEdgeAppearance`) in step with its offset.
 *      `barAppearance` is the tab bar's appearance it is built from; `transparent` builds it with a transparent
 *      background. The associated state is `@[installed, barAppearance, appBase or NSNull, offset or NSNull, colors or
 *      NSNull]`: the bar appearance itself is kept (not a copy), so an unchanged tab bar is recognized by identity and
 *      nothing is installed again on layout; the offset and the per-tab colors it was built with tell when to rebuild.
 * [CN] 使 `tabBarItem` 的某个 appearance（`standardAppearance` 或 `scrollEdgeAppearance`）与偏移保持一致。`barAppearance`
 *      为其所基于的 TabBar appearance，`transparent` 表示以透明背景构建。关联状态为 `@[installed, barAppearance, appBase 或 NSNull, offset 或 NSNull, colors 或 NSNull]`（offset 与单个 Tab 的颜色用于判断是否需要重建）：
 *      保存的是 bar appearance 本身（不是副本），TabBar 未改变时按对象身份即可识别，布局时不会重复安装。
 */
API_AVAILABLE(ios(13.0))
static void CYLSyncTitlePositionAdjustmentAppearance(UITabBarItem *tabBarItem, const void *stateKey, UITabBarAppearance *_Nullable current, UITabBarAppearance *_Nullable barAppearance, BOOL transparent, NSValue *_Nullable offsetValue, NSDictionary<NSString *, id> *_Nullable colors, void (^setter)(UITabBarAppearance *_Nullable appearance), UITabBarAppearance *_Nullable (^getter)(void)) {
    // [EN] State: @[installed, source, appBase or NSNull, offset or NSNull, colors or NSNull] (the last two since the
    //      per-tab colors were added; an older 3-element state reads them as missing).
    // [CN] 状态：@[installed, source, appBase 或 NSNull, offset 或 NSNull, colors 或 NSNull]（后两项为加入单个 Tab 颜色后新增；
    //      旧的 3 元素状态读取为缺失）。
    NSArray *state = objc_getAssociatedObject(tabBarItem, stateKey);
    UITabBarAppearance *installed = state.firstObject;
    id storedAppBase = state.count > 2 ? state[2] : nil;
    UITabBarAppearance *appBase = [storedAppBase isKindOfClass:[UITabBarAppearance class]] ? storedAppBase : nil;
    BOOL installedByCYL = installed && (current == installed || [current isEqual:installed]);
    if (current && !installedByCYL) {
        // The app installed its own appearance on the item: build on it.
        // App 在 item 上安装了自己的 appearance：在其基础上构建。
        appBase = current;
    }
    if (!offsetValue && colors.count == 0) {
        if (state) {
            setter(appBase);
            objc_setAssociatedObject(tabBarItem, stateKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return;
    }
    id source = appBase ?: barAppearance;
    if (!source) {
        return;
    }
    id storedSource = state.count > 1 ? state[1] : nil;
    id storedOffset = state.count > 3 ? state[3] : nil;
    id storedColors = state.count > 4 ? state[4] : nil;
    id offsetToStore = offsetValue ?: [NSNull null];
    id colorsToStore = colors.count > 0 ? colors : [NSNull null];
    BOOL upToDate = installedByCYL && (storedSource == source || [storedSource isEqual:source]) &&
                    [storedOffset isEqual:offsetToStore] && [storedColors isEqual:colorsToStore];
    if (upToDate) {
        return;
    }
    UITabBarAppearance *base = source;
    if (!appBase && transparent) {
        base = [source copy];
        [base configureWithTransparentBackground];
    }
    setter(CYLTabBarAppearanceForItem(base, offsetValue, colors));
    UITabBarAppearance *newInstalled = getter();
    if (!newInstalled) {
        return;
    }
    objc_setAssociatedObject(tabBarItem, stateKey, @[ newInstalled, source, appBase ?: [NSNull null], offsetToStore, colorsToStore ], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)cyl_syncTitlePositionAdjustmentAppearanceOfTabBarItem:(UITabBarItem *)tabBarItem API_AVAILABLE(ios(13.0)) {
    NSValue *offsetValue = objc_getAssociatedObject(tabBarItem, &CYLTitlePositionAdjustmentSetByCYLKey);
    NSDictionary<NSString *, id> *colors = objc_getAssociatedObject(tabBarItem, &CYLTabBarItemColorsKey);
    UITabBar *tabBar = self.tabBar;
    UITabBarAppearance *standardAppearance = tabBar.standardAppearance;
    CYLSyncTitlePositionAdjustmentAppearance(tabBarItem, &CYLTitlePositionAdjustmentStandardAppearanceKey, tabBarItem.standardAppearance, standardAppearance, NO, offsetValue, colors, ^(UITabBarAppearance *appearance) {
        tabBarItem.standardAppearance = appearance;
    }, ^UITabBarAppearance *{
        return tabBarItem.standardAppearance;
    });
    if (@available(iOS 15.0, *)) {
        // Without a scroll edge appearance the tab bar shows its standard one with a transparent background at the
        // scroll edge: build the same, so the item's opaque standard copy is not used there.
        // 没有 scrollEdgeAppearance 时，TabBar 在滚动边缘显示透明背景的 standardAppearance：按相同方式构建，避免在此处使用
        // item 的不透明副本。
        UITabBarAppearance *scrollEdgeAppearance = tabBar.scrollEdgeAppearance;
        BOOL transparent = (scrollEdgeAppearance == nil);
        CYLSyncTitlePositionAdjustmentAppearance(tabBarItem, &CYLTitlePositionAdjustmentScrollEdgeAppearanceKey, tabBarItem.scrollEdgeAppearance, scrollEdgeAppearance ?: standardAppearance, transparent, offsetValue, colors, ^(UITabBarAppearance *appearance) {
            tabBarItem.scrollEdgeAppearance = appearance;
        }, ^UITabBarAppearance *{
            return tabBarItem.scrollEdgeAppearance;
        });
    }
}

/// Picks up changes the app made to the tab bar's appearance since the offsets were applied.
/// 同步 App 在应用偏移后对 TabBar appearance 所做的修改。
- (void)cyl_syncTitlePositionAdjustmentAppearances {
    if (@available(iOS 13.0, *)) {
        // [EN] Per-tab colors: read from `tabBarItemsAttributes` on every layout pass, so a reload or an in-place update
        //      is picked up; kept on the item and built into the same per-item appearance as the title offset.
        // [CN] 单个 Tab 的颜色：每次布局时从 `tabBarItemsAttributes` 读取，因此重新加载或原地更新后都会生效；保存在 item 上，
        //      与标题偏移写入同一个 item appearance。
        NSArray<UIViewController *> *viewControllers = self.viewControllers;
        for (NSUInteger index = 0; index < viewControllers.count; index++) {
            UITabBarItem *item = viewControllers[index].tabBarItem;
            NSDictionary<NSString *, id> *colors = CYLTabBarItemColorsFromAttributes([self tabBarItemAttributesAtIndex:index]);
            NSDictionary *storedColors = objc_getAssociatedObject(item, &CYLTabBarItemColorsKey);
            if (item && !(colors == storedColors || [colors isEqual:storedColors])) {
                objc_setAssociatedObject(item, &CYLTabBarItemColorsKey, colors, OBJC_ASSOCIATION_COPY_NONATOMIC);
            }
        }
        for (UITabBarItem *tabBarItem in self.tabBar.items) {
            if (objc_getAssociatedObject(tabBarItem, &CYLTitlePositionAdjustmentSetByCYLKey) ||
                objc_getAssociatedObject(tabBarItem, &CYLTabBarItemColorsKey) ||
                objc_getAssociatedObject(tabBarItem, &CYLTitlePositionAdjustmentStandardAppearanceKey)) {
                [self cyl_syncTitlePositionAdjustmentAppearanceOfTabBarItem:tabBarItem];
            }
        }
    }
}

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

static UIEdgeInsets CYLImageInsetsForItem(id _Nullable item, UIEdgeInsets controllerInsets) {
    id object = item;
    NSValue *itemInsets = object ? objc_getAssociatedObject(object, &CYLImageInsetsItemKey) : nil;
    return itemInsets ? itemInsets.UIEdgeInsetsValue : controllerInsets;
}

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
        NSDictionary<NSString *, NSValue *> *record = objc_getAssociatedObject(tabBarItem, &CYLImageOnlyTabAdjustmentKey);
        if (record) {
            NSMutableDictionary<NSString *, NSValue *> *newRecord = [record mutableCopy];
            [newRecord removeObjectsForKeys:@[ CYLImageOnlyTabOriginalInsetsKey, CYLImageOnlyTabAppliedInsetsKey ]];
            objc_setAssociatedObject(tabBarItem, &CYLImageOnlyTabAdjustmentKey, newRecord.count > 0 ? [newRecord copy] : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

/// [EN] The identifier the library wrote on an object, so a later change of the tab's identifier updates it while an
///      identifier the app set itself is kept.
/// [CN] 本库写入对象的 identifier，使 Tab 标识变化时可以更新它，同时保留 App 自己设置的 identifier。
static char CYLAccessibilityIdentifierSetByCYLKey;

/// [EN] Writes `identifier` on `element` unless the app set a different one itself. [CN] 写入 `identifier`，除非 App 自己设置了其他值。
static void CYLApplyDefaultAccessibilityIdentifier(NSObject<UIAccessibilityIdentification> *element, NSString *identifier) {
    if (!element || identifier.length == 0) {
        return;
    }
    NSString *current = element.accessibilityIdentifier;
    NSString *setByCYL = objc_getAssociatedObject(element, &CYLAccessibilityIdentifierSetByCYLKey);
    BOOL ownedByApp = current.length > 0 && ![current isEqualToString:setByCYL ?: @""];
    if (ownedByApp || [current isEqualToString:identifier]) {
        return;
    }
    element.accessibilityIdentifier = identifier;
    objc_setAssociatedObject(element, &CYLAccessibilityIdentifierSetByCYLKey, identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

/// [EN] Writes the explicit identifier, label and hint of `attributes` on `element` (only values that changed).
/// [CN] 将 `attributes` 中显式指定的 identifier、label、hint 写入 `element`（只写入有变化的值）。
static void CYLApplyExplicitAccessibility(NSObject<UIAccessibilityIdentification> *element, NSDictionary *attributes) {
    id identifier = attributes[CYLTabBarItemAccessibilityIdentifier];
    if ([identifier isKindOfClass:[NSString class]] && ![element.accessibilityIdentifier isEqualToString:identifier]) {
        element.accessibilityIdentifier = identifier;
        objc_setAssociatedObject(element, &CYLAccessibilityIdentifierSetByCYLKey, identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }
    id label = attributes[CYLTabBarItemAccessibilityLabel];
    if ([label isKindOfClass:[NSString class]] && ![element.accessibilityLabel isEqualToString:label]) {
        element.accessibilityLabel = label;
    }
    id hint = attributes[CYLTabBarItemAccessibilityHint];
    if ([hint isKindOfClass:[NSString class]] && ![element.accessibilityHint isEqualToString:hint]) {
        element.accessibilityHint = hint;
    }
}

/*!
 * [EN] Gives every tab (and the plus button) an `accessibilityIdentifier` and the explicit accessibility values of its
 *      attributes. Runs on layout (`-cyl_syncTabBarAppearances`); only changed values are written.
 * [CN] 为每个 Tab（以及 PlusButton）设置 `accessibilityIdentifier` 及其 attributes 中显式指定的无障碍信息。在布局时执行
 *      （`-cyl_syncTabBarAppearances`）；只写入有变化的值。
 */
- (void)cyl_syncTabBarItemAccessibility {
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    for (NSUInteger index = 0; index < viewControllers.count; index++) {
        UIViewController *viewController = viewControllers[index];
        // [EN] The plus child view controller's tab sits under the plus button, which gets the identifier instead.
        // [CN] PlusButton 子控制器的 Tab 位于 PlusButton 下方，由 PlusButton 使用该标识。
        if (viewController.cyl_isPlaceholder || viewController == [self cyl_contextPlusChildViewController]) {
            continue;
        }
        NSDictionary *attributes = [self tabBarItemAttributesAtIndex:index];
        NSString *identifier = viewController.cyl_tabBarItemIdentifier;
        NSObject<UIAccessibilityIdentification> *element = viewController.tabBarItem;
#if CYL_FLATDESIGN_AVAILABLE
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
            NSArray<CYLFlatDesignTabBarItem *> *items = [self.items copy];
            element = (index < items.count) ? items[index].tabBarButton : nil;
        }
#endif
        if (!element) {
            continue;
        }
        CYLApplyDefaultAccessibilityIdentifier(element, identifier);
        if (attributes) {
            CYLApplyExplicitAccessibility(element, attributes);
        }
    }
    UIButton *plusButton = [self cyl_contextPlusButton];
    if (plusButton && [self hasPlusButton]) {
        CYLApplyDefaultAccessibilityIdentifier(plusButton, plusButton.cyl_tabBarItemIdentifier);
    }
}

/// [EN] Marks the tab buttons (and the controller) the library filled with a selected background color.
/// [CN] 标记本库填充过选中背景色的 Tab 按钮（以及控制器）。
static char CYLColoredTabButtonsKey;

/// [EN] Moves the selected background color once the current run loop turn ends, after UIKit changed the selection.
/// [CN] 在当前 runloop 结束后（UIKit 修改选中状态之后）移动选中背景色。
- (void)cyl_setNeedsUpdateSelectedBackgroundColors {
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf cyl_updateSelectedBackgroundColorsOfTabButtons];
        // [EN] Also selection dependent: looping Lottie icons and the selected tab's badge.
        // [CN] 同样取决于选中状态：循环播放的 Lottie 图标与选中 Tab 的角标。
        [weakSelf cyl_updateLoopingLottieViews];
        [weakSelf cyl_updateBadgesOfSelectedTab];
    });
}

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
            UIView *lottieView = [eachControl cyl_lottieAnimationView];
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

static char CYLHidesBadgeOfSelectedTabKey;
/// [EN] The badge value hidden on a tab item ([NSNull null] for a nil one never stored). [CN] Tab item 上被隐藏的角标值。
static char CYLHiddenBadgeValueKey;
/// [EN] Marks a view controller whose CYLBadge was cleared by the library. [CN] 标记本库清除过 CYLBadge 的控制器。
static char CYLHiddenCYLBadgeKey;

/*!
 * [EN] `cyl_hidesBadgeOfSelectedTab`: hides the selected tab's badge, restores the others'; with the property off, restores
 *      everything it hid.
 * [CN] `cyl_hidesBadgeOfSelectedTab`：隐藏选中 Tab 的角标，恢复其他 Tab 的角标；属性关闭时恢复所有被隐藏的角标。
 */
- (void)cyl_updateBadgesOfSelectedTab {
    BOOL hides = [objc_getAssociatedObject(self, &CYLHidesBadgeOfSelectedTabKey) boolValue];
    UIViewController *selectedViewController = self.selectedViewController;
    for (UIViewController *viewController in self.viewControllers) {
        if (viewController.cyl_isPlaceholder) {
            continue;
        }
        BOOL hideThis = hides && viewController == selectedViewController;
        UITabBarItem *item = viewController.tabBarItem;
        NSString *hiddenValue = objc_getAssociatedObject(item, &CYLHiddenBadgeValueKey);
        if (hideThis && item.badgeValue) {
            objc_setAssociatedObject(item, &CYLHiddenBadgeValueKey, item.badgeValue, OBJC_ASSOCIATION_COPY_NONATOMIC);
            item.badgeValue = nil;
        } else if (!hideThis && hiddenValue) {
            item.badgeValue = hiddenValue;
            objc_setAssociatedObject(item, &CYLHiddenBadgeValueKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
        BOOL clearedByLibrary = [objc_getAssociatedObject(viewController, &CYLHiddenCYLBadgeKey) boolValue];
        if (hideThis && !clearedByLibrary && [viewController cyl_isShowBadge]) {
            [viewController cyl_clearBadge];
            objc_setAssociatedObject(viewController, &CYLHiddenCYLBadgeKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        } else if (!hideThis && clearedByLibrary) {
            [viewController cyl_resumeBadge];
            objc_setAssociatedObject(viewController, &CYLHiddenCYLBadgeKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

- (BOOL)cyl_hidesBadgeOfSelectedTab {
    return [objc_getAssociatedObject(self, &CYLHidesBadgeOfSelectedTabKey) boolValue];
}

- (void)setCyl_hidesBadgeOfSelectedTab:(BOOL)hidesBadgeOfSelectedTab {
    objc_setAssociatedObject(self, &CYLHidesBadgeOfSelectedTabKey, @(hidesBadgeOfSelectedTab), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_updateBadgesOfSelectedTab];
}

/*!
 * [EN] Classic tab bar: fills each tab button with its `CYLTabBarItemBackgroundColor`, and the selected one with its
 *      `CYLTabBarItemSelectedBackgroundColor` (the unselected color when it has none). Tabs without either key are left
 *      alone. Liquid Glass draws its own selection, so it is not touched.
 * [CN] 经典 TabBar：用 `CYLTabBarItemBackgroundColor` 填充每个 Tab 按钮，选中的按钮使用 `CYLTabBarItemSelectedBackgroundColor`
 *      （未设置时使用未选中背景色）。两个键都没有的 Tab 保持不变。液态玻璃自带选中效果，不做处理。
 */
- (void)cyl_updateSelectedBackgroundColorsOfTabButtons {
    if (!self.isViewLoaded || CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType || [CYLConstants isLiquidGlassActive] ||
        ![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    // [EN] Fast path: no tab uses the key and no button was colored before. [CN] 快速返回：没有 Tab 使用该键，且之前没有填充过按钮。
    BOOL usesSelectedBackgroundColor = NO;
    for (NSDictionary *attributes in self.tabBarItemsAttributes) {
        if ([attributes isKindOfClass:[NSDictionary class]] &&
            (attributes[CYLTabBarItemSelectedBackgroundColor] || attributes[CYLTabBarItemBackgroundColor])) {
            usesSelectedBackgroundColor = YES;
            break;
        }
    }
    BOOL coloredBefore = [objc_getAssociatedObject(self, &CYLColoredTabButtonsKey) boolValue];
    if (!usesSelectedBackgroundColor && !coloredBefore) {
        return;
    }
    CYLTabBar *tabBar = (CYLTabBar *)self.cyl_tabBar;
    NSUInteger tabIndex = 0;
    for (UIControl *control in tabBar.cyl_visibleControls) {
        // [EN] Counted as in `-cyl_bindTabControlActions`: system tab buttons only. [CN] 与 `-cyl_bindTabControlActions` 相同，只计系统 Tab 按钮。
        if (![control cyl_isTabButton]) {
            continue;
        }
        NSUInteger controlTabIndex = tabIndex++;
        NSDictionary *attributes = [self tabBarItemAttributesAtIndex:controlTabIndex];
        id selectedColor = attributes[CYLTabBarItemSelectedBackgroundColor];
        id normalColor = attributes[CYLTabBarItemBackgroundColor];
        selectedColor = [selectedColor isKindOfClass:[UIColor class]] ? selectedColor : nil;
        normalColor = [normalColor isKindOfClass:[UIColor class]] ? normalColor : nil;
        BOOL coloredByCYL = [objc_getAssociatedObject(control, &CYLColoredTabButtonsKey) boolValue];
        if (!selectedColor && !normalColor) {
            // [EN] The key was removed (e.g. by a reload): clear the color the library set. [CN] 该键已被移除（如重新加载）：清除本库设置的颜色。
            if (coloredByCYL) {
                control.backgroundColor = nil;
                objc_setAssociatedObject(control, &CYLColoredTabButtonsKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            continue;
        }
        // [EN] Selected: its own color, else the unselected one. [CN] 选中：使用选中背景色，未设置时使用未选中背景色。
        control.backgroundColor = (controlTabIndex == self.selectedIndex) ? (selectedColor ?: normalColor) : normalColor;
        objc_setAssociatedObject(control, &CYLColoredTabButtonsKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    objc_setAssociatedObject(self, &CYLColoredTabButtonsKey, usesSelectedBackgroundColor ? @YES : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*!
 * [EN] Brings everything built from the system tab bar's appearances up to date: the title offset copies of the tabs
 *      (issue #475) or, for FlatDesign (only when CYLFlatDesignTabBar is integrated), the flat design tab bar. Runs on layout and when `tabBar.standardAppearance` /
 *      `scrollEdgeAppearance` is assigned (KVO), so a new appearance applies at once.
 * [CN] 更新所有基于系统 TabBar appearance 构建的内容：Tab 的标题偏移副本（issue #475），扁平样式时（仅在集成了 CYLFlatDesignTabBar 时）为扁平样式 TabBar。在布局时以及
 *      `tabBar.standardAppearance` / `scrollEdgeAppearance` 被赋值时（KVO）执行，新的 appearance 立即生效。
 */
- (void)cyl_syncTabBarAppearances {
    [self cyl_syncTabBarItemAccessibility];
    if (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType) {
        // FIX: issue #475
        [self cyl_syncTitlePositionAdjustmentAppearances];
    } else {
#if CYL_FLATDESIGN_AVAILABLE
        // `tabBar.standardAppearance` also styles the flat design tab bar. `tabBar.standardAppearance` 同样作用于扁平样式 TabBar。
        [self cyl_syncFlatDesignStandardAppearance];
        [self cyl_syncFlatDesignTabBarItemColors];
#endif
    }
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

- (BOOL)automaticallyAdjustsImageOnlyTabs {
    return !self.cyl_imageOnlyTabsAdjustmentDisabled;
}

- (void)setAutomaticallyAdjustsImageOnlyTabs:(BOOL)automaticallyAdjustsImageOnlyTabs {
    if (self.automaticallyAdjustsImageOnlyTabs == automaticallyAdjustsImageOnlyTabs) {
        return;
    }
    self.cyl_imageOnlyTabsAdjustmentDisabled = !automaticallyAdjustsImageOnlyTabs;
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        // Read the stored tab bar: the getter would create one.
        // 读取已保存的 TabBar：getter 会创建新的 TabBar。
        if (![_cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
            return;
        }
        CYLTabBar *tabBar = (CYLTabBar *)_cyl_tabBar;
        if (automaticallyAdjustsImageOnlyTabs) {
            if (tabBar.tabImageViewDefaultOffset != 0.f) {
                [self offsetTabBarTabImageViewToFit:tabBar.tabImageViewDefaultOffset];
            } else {
                // Not measured yet: the next layout measures it. 尚未测量：下次布局时测量。
                [tabBar setNeedsLayout];
            }
        } else {
            [self cyl_restoreImageOnlyTabItems:tabBar.items];
        }
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/// [EN] Undoes what `-offsetTabBarTabImageViewToFit:` wrote, where the app has not changed the value since.
/// [CN] 撤销 `-offsetTabBarTabImageViewToFit:` 写入的值（App 之后未修改过的值）。
- (void)cyl_restoreImageOnlyTabItems:(NSArray<UITabBarItem *> *)tabBarItems {
    for (UITabBarItem *item in tabBarItems) {
        NSDictionary<NSString *, NSValue *> *record = objc_getAssociatedObject(item, &CYLImageOnlyTabAdjustmentKey);
        if (!record) {
            continue;
        }
        NSValue *appliedInsets = record[CYLImageOnlyTabAppliedInsetsKey];
        if (appliedInsets && UIEdgeInsetsEqualToEdgeInsets(item.imageInsets, appliedInsets.UIEdgeInsetsValue)) {
            item.imageInsets = record[CYLImageOnlyTabOriginalInsetsKey].UIEdgeInsetsValue;
        }
        NSValue *appliedTitle = record[CYLImageOnlyTabAppliedTitleKey];
        if (appliedTitle && UIOffsetEqualToOffset(item.titlePositionAdjustment, appliedTitle.UIOffsetValue)) {
            item.titlePositionAdjustment = record[CYLImageOnlyTabOriginalTitleKey].UIOffsetValue;
        }
        objc_setAssociatedObject(item, &CYLImageOnlyTabAdjustmentKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

/*!
 * FIX: issue #257, issue #522
 * [EN] Moves the images of the image-only tabs by `tabImageViewDefaultOffset` (measured once by `CYLTabBar`).
 *      Before, every item was written, on every notification: the image and title offsets the app had set on an item
 *      (directly or with `CYLTabBarItemImageInsets` / `CYLTabBarItemTitlePositionAdjustment`) were replaced, a tab with a
 *      title had its title moved off screen (`UIOffsetMake(0, MAXFLOAT)`) as soon as the first tab had none (#522), and
 *      writing the items laid the tab bar out again, which measured and wrote again (#257).
 *      Now only items without a title are written, only values the app left at zero, and a value already written is not
 *      written again. `automaticallyAdjustsImageOnlyTabs = NO` turns it off.
 * [CN] 按 `tabImageViewDefaultOffset`（由 `CYLTabBar` 测量一次）移动纯图标 Tab 的图片。
 *      以前每次通知都会写入所有 item：App 在 item 上设置的图片与标题偏移（直接设置，或通过 `CYLTabBarItemImageInsets` /
 *      `CYLTabBarItemTitlePositionAdjustment`）被替换；只要第一个 Tab 没有标题，有标题的 Tab 的标题也会被移出屏幕
 *      （`UIOffsetMake(0, MAXFLOAT)`，#522）；而写入 item 又会让 TabBar 重新布局，再次测量并写入（#257）。
 *      现在只写入没有标题的 item，只写入 App 保持为零的值，已写入的值不会重复写入。`automaticallyAdjustsImageOnlyTabs = NO`
 *      可关闭该功能。
 */
- (void)offsetTabBarTabImageViewToFit:(CGFloat)tabImageViewDefaultOffset {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if (!self.automaticallyAdjustsImageOnlyTabs) {
        return;
    }
    BOOL shouldCustomizeTitlePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, _titlePositionAdjustment));
    BOOL shouldCustomizeImageInsets = !(UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, _imageInsets));
    if (shouldCustomizeImageInsets) {
        return;
    }
    CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;
    UIEdgeInsets imageInset = UIEdgeInsetsMake(tabImageViewDefaultOffset, 0, -tabImageViewDefaultOffset, 0);
    UIOffset hiddenTitleOffset = UIOffsetMake(0, MAXFLOAT);

    for (UITabBarItem *item in cyl_tabBar.items) {
        if (item.title.length > 0) {
            // A tab with a title is not image-only. 有标题的 Tab 不是纯图标 Tab。
            continue;
        }
        NSDictionary<NSString *, NSValue *> *record = objc_getAssociatedObject(item, &CYLImageOnlyTabAdjustmentKey);
        NSMutableDictionary<NSString *, NSValue *> *newRecord = record ? [record mutableCopy] : [NSMutableDictionary dictionary];

        NSValue *appliedInsets = record[CYLImageOnlyTabAppliedInsetsKey];
        BOOL insetsAreOurs = appliedInsets && UIEdgeInsetsEqualToEdgeInsets(item.imageInsets, appliedInsets.UIEdgeInsetsValue);
        // Each value is judged by its own entry: `-updateImageInsets:` forgets the insets entry but keeps the title one.
        // 每个值按各自的记录判断：`-updateImageInsets:` 会清除内边距记录，但保留标题记录。
        BOOL insetsAreFree = !appliedInsets && UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, item.imageInsets);
        if (insetsAreOurs || insetsAreFree) {
            if (!UIEdgeInsetsEqualToEdgeInsets(item.imageInsets, imageInset)) {
                item.imageInsets = imageInset;
            }
            if (insetsAreFree) {
                newRecord[CYLImageOnlyTabOriginalInsetsKey] = [NSValue valueWithUIEdgeInsets:UIEdgeInsetsZero];
            }
            newRecord[CYLImageOnlyTabAppliedInsetsKey] = [NSValue valueWithUIEdgeInsets:imageInset];
        }

        // The item's own offset, kept by CYL (`CYLTabBarItemTitlePositionAdjustment` or the controller-level offset).
        // CYL 记录的 item 自身偏移（`CYLTabBarItemTitlePositionAdjustment` 或控制器级别的偏移）。
        BOOL titleOffsetSetByCYL = (objc_getAssociatedObject(item, &CYLTitlePositionAdjustmentItemOffsetKey) != nil) ||
                                   (objc_getAssociatedObject(item, &CYLTitlePositionAdjustmentSetByCYLKey) != nil);
        NSValue *appliedTitle = record[CYLImageOnlyTabAppliedTitleKey];
        BOOL titleIsOurs = appliedTitle && UIOffsetEqualToOffset(item.titlePositionAdjustment, appliedTitle.UIOffsetValue);
        BOOL titleIsFree = !appliedTitle && !titleOffsetSetByCYL && UIOffsetEqualToOffset(UIOffsetZero, item.titlePositionAdjustment);
        if (!shouldCustomizeTitlePositionAdjustment && (titleIsOurs || titleIsFree)) {
            if (!UIOffsetEqualToOffset(item.titlePositionAdjustment, hiddenTitleOffset)) {
                item.titlePositionAdjustment = hiddenTitleOffset;
            }
            if (titleIsFree) {
                newRecord[CYLImageOnlyTabOriginalTitleKey] = [NSValue valueWithUIOffset:UIOffsetZero];
            }
            newRecord[CYLImageOnlyTabAppliedTitleKey] = [NSValue valueWithUIOffset:hiddenTitleOffset];
        }
        objc_setAssociatedObject(item, &CYLImageOnlyTabAdjustmentKey, newRecord.count > 0 ? [newRecord copy] : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

#pragma mark - delegate
- (void)updateSelectionStatusIfNeededForTabBarController:(nullable UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    BOOL should = viewController != tabBarController.selectedViewController;
    [self updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController shouldSelect:should];
    CYLTabBar *tabBar = (CYLTabBar *)tabBarController.tabBar;
    if (should && [tabBar cyl_shouldUpdateHiddenStatueForPlusButtonLabel]) {
        if ([viewController isEqual:[self cyl_contextPlusChildViewController]]) {
            [[self cyl_contextPlusButton] setTabLabelHidden:YES];
        } else {
            [[self cyl_contextPlusButton] setTabLabelHidden:NO];
        }
    }
    if ([tabBarController.selectedViewController isEqual:[self cyl_contextPlusChildViewController]] && [tabBar cyl_shouldUpdateHiddenStatueForPlusButtonLabel]) {
        if (!should) {
            [[self cyl_contextPlusButton] setTabLabelHidden:YES];
        }
    }

    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)updateSelectionStatusIfNeededForTabBarController:(nullable UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController
                                            shouldSelect:(BOOL)shouldSelect {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [[viewController.tabBarItem cyl_tabButton] cyl_setUserInteractionDisabled:!shouldSelect];
    if (!shouldSelect) {
        return;
    }
    UIButton *plusButton = [self cyl_contextPlusButton];
    if (!viewController) {
        viewController = self.selectedViewController;
    }
    if (![self hasPlusChildViewController]) {
        return;
    }
    
    BOOL isCurrentViewController = [viewController cyl_isEqualToViewController:[self cyl_contextPlusChildViewController]];
    BOOL shouldConfigureSelectionStatus = (!isCurrentViewController);
    
    if (plusButton.selected) {
        plusButton.selected = NO;
    }
    if (!shouldConfigureSelectionStatus) {
        [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:self];
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
    // FIX: issue #152 — one user tap on a tab button, before the selection changes (also for a tab that needs login).
    // 一次用户点击 Tab 按钮，在选中变化之前（需要登录的 Tab 也算）。
    [self cyl_recognizeTabBarItemTapWillSelectViewController:viewController];
    // FIX: issue #19 — a tab that needs login, tapped while logged out: refuse it before anything changes (no transition,
    // no selection state) and start the login. 需要登录的 Tab 在未登录时被点击：在任何变化之前拒绝（无转场、不改选中状态），并发起登录。
    if ([self cyl_interceptLoginIfNeededForViewController:viewController]) {
        return NO;
    }
    // [EN] A custom action tab (CYLCustomTabAction): refuse the selection and run the action instead.
    // [CN] 使用自定义点击操作的 Tab（CYLCustomTabAction）：拒绝选中，改为执行对应操作。
    if ([self cyl_performCustomTabActionIfNeededForViewController:viewController]) {
        return NO;
    }
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if (YES == viewController.cyl_isPlaceholder) {
        return NO;
    }
    if (@available(iOS 18.0, *)) {
        
        UIViewController *fromVC = self.selectedViewController;
        
        UIView *fromView = fromVC.view;
        UIView *toView = viewController.view;
        
        if (fromView && toView && fromView != toView) {
            // 自定义过渡效果，用于“隐藏” tabbar 切换时产生的 VC 闪烁
            // FIX: issue #618
            // [EN] This runs before the selection is decided: a subclass calls super first and may still return NO
            //      (e.g. a tab that needs login). `+transitionFromView:toView:` removed `fromView` and inserted `toView`
            //      right away, so a refused selection left the selected tab's view out of the hierarchy, and the next
            //      tab switch could crash inside UIKit. Cross-dissolve the container instead: it animates whatever UIKit
            //      changes in this run loop, and does nothing when the selection is refused.
            // [CN] 这里在是否切换确定之前执行：子类会先调用 super，之后仍可能返回 NO（如需要登录的 Tab）。
            //      `+transitionFromView:toView:` 会立即移除 `fromView` 并插入 `toView`，切换被拒绝时当前 Tab 的视图已不在
            //      视图层级中，下一次切换 Tab 可能在 UIKit 内部崩溃。改为对容器做交叉溶解：只为本次 runloop 中 UIKit 的
            //      视图变化做动画，切换被拒绝时不产生任何变化。
            UIView *containerView = fromView.superview ?: self.view;
            [UIView transitionWithView:containerView
                              duration:0.01   // [CN] 几乎立即
                              // [EN] Almost immediate
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:nil
                            completion:nil];
        }
    }
    
    [self updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController];
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}


    BOOL should = viewController != tabBarController.selectedViewController;
    

    return should;
}

- (BOOL)tabBarController:(CYLTabBarController *)tabBarController shouldShowPlatterLiquidLensViewForControl:(UIControl *)control {
    if (![CYLConstants isLiquidGlassActive] || ![tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return NO;
    }
    if (![self hasPlusChildViewController]) {
        return YES;
    }

    if ([tabBarController.selectedViewController isEqual:[self cyl_contextPlusChildViewController]] && ![tabBarController.tabBar isPlusButtonLayoutCentered]) {
        return NO;
    }
    return YES;
}

- (void)tabBarController:(CYLTabBarController *)tabBarController beginShowPlatterLiquidLensViewForControl:(UIControl *)control {
    if (![CYLConstants isLiquidGlassActive] || ![tabBarController.tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    SEL action = @selector(tabBarController:shouldShowPlatterLiquidLensViewForControl:);
    BOOL shouldShowPlatterLiquidLensView = YES;
    if ([self.delegate respondsToSelector:action]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         shouldShowPlatterLiquidLensView = [self.delegate performSelector:action withObject:tabBarController withObject:control];
         )
    }
    if (shouldShowPlatterLiquidLensView) {
        [tabBarController.tabBar.cyl_platterLiquidLensViewContentView cyl_setHidden:NO];
        tabBarController.tabBar.liquidGlassContinuousGestureRecognizer.enabled = YES;
        tabBarController.tabBar.liquidGlassLongGestureRecognizer.enabled = YES;
    } else {
        [tabBarController.tabBar.cyl_platterLiquidLensViewContentView cyl_setHidden:YES];
        tabBarController.tabBar.liquidGlassContinuousGestureRecognizer.enabled = NO;
        tabBarController.tabBar.liquidGlassLongGestureRecognizer.enabled = NO;
    }
}

- (BOOL)isLottieEnabled {
    return [CYLConstants isLottieEnabledFromlottieURLs:self.lottieURLs tabBarItemsAttributes:self.tabBarItemsAttributes];
}

/*!
 * [EN] The control to report for `control`: the plus button for the system tab button of its child view controller (the
 *      layer under the plus button), `control` otherwise.
 * [CN] 上报给代理的控件：PlusButton 子控制器的系统 Tab 按钮（PlusButton 下方的图层）换成 PlusButton 本身，其他控件不变。
 */
- (nullable UIControl *)cyl_reportedControlForControl:(nullable UIControl *)control {
    // [EN] Guards: only with a plus button, and only when it has a child view controller (the second layer).
    // [CN] 仅在有 PlusButton，且其有子控制器（第二个图层）时处理。
    if (!control || ![self hasPlusButton] || ![self hasPlusChildViewController]) {
        return control;
    }
    UIControl *plusButton = [self cyl_contextPlusButton];
    if (!plusButton || control == plusButton || [control cyl_isPlusButton]) {
        return control;
    }
    UIViewController *plusChildViewController = [self cyl_contextPlusChildViewController];
    BOOL isPlusChildTabButton = (control == plusChildViewController.cyl_tabButton) ||
        (control == [plusChildViewController cyl_getViewControllerInsteadOfNavigationController].cyl_tabButton);
    return isPlusChildTabButton ? plusButton : control;
}

/// [EN] Remembers `control` until the end of the current run loop turn.
/// [CN] 记住 `control`，直到当前 runloop 结束。
- (void)cyl_markControlReportedInCurrentRunLoop:(UIControl *)control {
    self.cyl_controlReportedInCurrentRunLoop = control;
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.cyl_controlReportedInCurrentRunLoop = nil;
    });
}

/*!
 * [EN] Everything a reported tab tap does, the same in every style (`-didSelectControl:` for the classic style and Liquid
 *      Glass, `-cyl_flatDesignReportDidSelectControl:` for FlatDesign), each once per reported tap and also without a
 *      `didSelectControl` delegate:
 *      1. the tap animation, sound and haptic (issue #535);
 *      2. `-tabBarController:didSelectControl:`;
 *      3. Reselect / DoubleTap (issue #152).
 * [CN] 每次上报的 Tab 点击要做的事，所有样式相同（经典样式与液态玻璃为 `-didSelectControl:`，扁平样式为
 *      `-cyl_flatDesignReportDidSelectControl:`），每次上报各执行一次，没有实现 didSelectControl 代理时同样执行：
 *      1. 点击动画、声音与触感反馈（issue #535）；
 *      2. `-tabBarController:didSelectControl:`；
 *      3. Reselect / DoubleTap（issue #152）。
 */
- (void)cyl_sendDidSelectControl:(UIControl *)control {
    [self cyl_playTabButtonAnimationForControl:control];
    [self cyl_playTabButtonTapFeedback];
    SEL action = @selector(tabBarController:didSelectControl:);
    if ([self.delegate respondsToSelector:action]) {
        CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
        (
         [self.delegate performSelector:action withObject:self withObject:control];
         );
    }
    [self cyl_recognizeTabBarItemGestureForReportedControl:control];
}

- (void)didSelectControl:(UIControl *)control {
    [self cyl_setNeedsUpdateTabBarItemIconViews];
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
    BOOL shouldSelectViewController =  YES;
    @try {
        shouldSelectViewController = (!control.cyl_userInteractionDisabled) && (!control.hidden) ;
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
    UIControl *contentControl = control;
    UIControl *selectedContentControl = nil;
    if ([self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        selectedContentControl = [self.cyl_tabBar cyl_selectedContentControlFromContentControl:control];
        if (![control cyl_isPlusControl]) {
            [self.cyl_tabBar cyl_setSelectedControl:selectedContentControl  ?: contentControl];
        } else {
            [self.cyl_tabBar cyl_setSelectedControl:[self cyl_contextPlusButton]];
        }
        
        if (shouldSelectViewController) {
            //TODO:  pure tabbar
            CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;

            [cyl_tabBar.cyl_visibleControls enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.selected = NO;
            }];
            [cyl_tabBar.cyl_platterSelectedContentViews enumerateObjectsUsingBlock:^(UIControl * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                obj.selected = NO;
            }];
            contentControl.selected = YES;
            selectedContentControl.selected = YES;
            // [CN] 非液态玻璃 与 液态玻璃逻辑共用，Lottie播放逻辑都在 tabChangedToSelectedIndex 中。
            // [EN] Shared logic for non-Liquid Glass and Liquid Glass; all Lottie playback logic lives in
            //      tabChangedToSelectedIndex.
        }
    }
    UIControl *control_ = control ?: self.selectedViewController.cyl_tabButton;
    [self tabBarController:self beginShowPlatterLiquidLensViewForControl:control_];
    
    // FIX: plus button badge does not change on tap
    // [EN] A plus button with a child view controller has two layers: the plus button and, under it, the system tab button
    //      of `plusChildViewController`. A tap could be reported with that system tab button, which `-cyl_isPlusButton`
    //      does not recognize, or not at all: when the plus child view controller is already selected,
    //      `-updateSelectionStatusIfNeededForTabBarController:shouldSelectViewController:` disables that tab button and the
    //      check above skipped the report. Report the plus button itself instead (its own `cyl_userInteractionDisabled`
    //      still opts out), so the delegate always gets the same control for the plus button, as in a direct tap.
    // [CN] 带子控制器的 PlusButton 有两个图层：PlusButton 本身，以及其下方 `plusChildViewController` 的系统 Tab 按钮。点击时可能上报
    //      的是该系统 Tab 按钮（`-cyl_isPlusButton` 不认识它），或者根本不上报：子控制器已选中时，
    //      `-updateSelectionStatusIfNeededForTabBarController:shouldSelectViewController:` 会禁用该 Tab 按钮，上面的判断就跳过了回调。
    //      这里统一上报 PlusButton 本身（其 `cyl_userInteractionDisabled` 仍可关闭回调），代理每次都拿到同一个控件。
    UIControl *reportedControl = [self cyl_reportedControlForControl:control_];
    BOOL shouldReport = shouldSelectViewController;
    if (reportedControl != control_) {
        shouldReport = !reportedControl.cyl_userInteractionDisabled;
    }
    // [EN] One report per tap, only for a plus button with a child view controller. On Liquid Glass a tap on a plus button with a child view controller runs
    //      `-plusChildViewControllerButtonClicked:` → `-setSelectedIndex:`, which reports through the
    //      `selectedViewController` setter and then again itself; the gesture path for a selected control can add one more.
    //      A badge that toggles on each callback was then flipped twice and looked unchanged. Reports of the same control
    //      within one run loop turn belong to the same tap, so only the first one is sent. Tab buttons are not affected.
    // [CN] 每次点击只上报一次，仅限带子控制器的 PlusButton，普通 Tab 按钮不受影响。液态玻璃下点击带子控制器的 PlusButton 会执行 `-plusChildViewControllerButtonClicked:` →
    //      `-setSelectedIndex:`，它先通过 `selectedViewController` 的 setter 上报一次，自己又上报一次；选中状态下的手势路径还可能再上报。
    //      每次回调切换一次的角标因此被切换两次，看起来没有变化。同一 runloop 内对同一控件的多次上报属于同一次点击，只发送第一次。
    BOOL isPlusButtonWithChildViewController = [self hasPlusButton] && [self hasPlusChildViewController] &&
        reportedControl && (reportedControl == [self cyl_contextPlusButton]);
    if (shouldReport && isPlusButtonWithChildViewController &&
        reportedControl == self.cyl_controlReportedInCurrentRunLoop) {
        shouldReport = NO;
    }
    if (shouldReport) {
        if (isPlusButtonWithChildViewController) {
            [self cyl_markControlReportedInCurrentRunLoop:reportedControl];
        }
        [self cyl_sendDidSelectControl:reportedControl];
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

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
/*!
 * Issue #423 (hardening)
 * [EN] The tab bar item a tab button belongs to, found through the view controllers instead of the button's position.
 *      Each item keeps its own Lottie file (`cyl_lottieURL` / `cyl_lottieSizeValue`, from `CYLTabBarLottieURL`, or
 *      `CYLTabBarLottieFilePath` turned into a file URL), the same value `lottieURLs` holds, so this never shifts.
 *      Selecting a tab already uses the item (`-tabChangedToSelectedIndex:…`). The position-based lookups below only run
 *      at launch, where the counts are checked first, so they were aligned; this makes them independent of the plus
 *      button and of tabs without Lottie.
 * [CN] 通过子控制器（而不是按钮的位置）找到 Tab 按钮所属的 tabBarItem。每个 item 保存着自己的 Lottie 文件
 *      （`cyl_lottieURL` / `cyl_lottieSizeValue`，来自 `CYLTabBarLottieURL`，或由 `CYLTabBarLottieFilePath` 转成的文件 URL），
 *      与 `lottieURLs` 中的值相同，不会错位。选中 Tab 时本来就按 item 取（`-tabChangedToSelectedIndex:…`）；下面按位置取的代码只在
 *      启动时执行，且事先校验了数量，因此是对齐的。这里让它们不再依赖 PlusButton 和未设置 Lottie 的 Tab。
 */
- (nullable UITabBarItem *)cyl_tabBarItemForTabButton:(nullable UIControl *)control {
    if (!control || [control cyl_isPlusControl]) {
        return nil;
    }
    for (UIViewController *viewController in self.viewControllers) {
        if (viewController.cyl_isPlaceholder) {
            continue;
        }
        UITabBarItem *item = viewController.tabBarItem;
        if (item.cyl_tabButton == control || viewController.cyl_tabButton == control) {
            return item;
        }
    }
    return nil;
}

- (void)addLottieImageWithControl:(UIControl *)control
                        animation:(BOOL)animation
                  defaultSelected:(BOOL)defaultSelected {
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
        NSURL *lottieURL = tabBarItem.cyl_lottieURL;
        NSValue *lottieSizeValue = tabBarItem.cyl_lottieSizeValue;
        if (!lottieURL) {
            // FIX: issue #618 — a tab button without a matching Lottie entry (more tab buttons than
            // `tabBarItemsAttributes`) used to raise NSRangeException here.
            if (index >= self.lottieURLs.count || index >= self.lottieSizes.count) {
                return;
            }
            lottieURL = self.lottieURLs[index];
            lottieSizeValue = self.lottieSizes[index];
        }
        CGSize lottieSize = [lottieSizeValue CGSizeValue];
        [control cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.lottieAnimationViewContentMode animationSpeed:self.lottieAnimationSpeed];
        if (animation) {
            [self.cyl_tabBar cyl_animationLottieImageWithSelectedControl:control lottieURL:lottieURL size:lottieSize defaultSelected:defaultSelected contentMode:self.lottieAnimationViewContentMode];
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
        lottieURL = lottieURL ?: tabBarItem.cyl_lottieURL;
        lottieSizeValue = lottieSizeValue ?: tabBarItem.cyl_lottieSizeValue;
    }
    if ((!lottieURL || !lottieSizeValue) && [self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        
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
            lottieURL = lottieURL ?: CYLObjectAtIndex(self.lottieURLs, index);
            lottieSizeValue = lottieSizeValue ?: CYLObjectAtIndex(self.lottieSizes, index);
        }
    }
    
    CGSize lottieSize = [lottieSizeValue CGSizeValue];
    [control cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.lottieAnimationViewContentMode animationSpeed:self.lottieAnimationSpeed];
    
    if (![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    selectedContentControl = [self.cyl_tabBar cyl_selectedContentControlFromContentControl:contentControl];
    
    if (selectedContentControl) {
        [selectedContentControl cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.lottieAnimationViewContentMode animationSpeed:self.lottieAnimationSpeed];
    }
    
    if (animation) {
        [self.cyl_tabBar cyl_animationLottieImageWithSelectedControl:contentControl
                                                           lottieURL:lottieURL
                                                                size:lottieSize
                                                     defaultSelected:defaultSelected
                                                         contentMode:self.lottieAnimationViewContentMode];
        if (selectedContentControl) {
            [self.cyl_tabBar cyl_animationLottieImageWithSelectedControl:selectedContentControl
                                                               lottieURL:lottieURL
                                                                    size:lottieSize
                                                         defaultSelected:defaultSelected
                                                             contentMode:self.lottieAnimationViewContentMode];
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

/**
 *  lazy load lottieURLs
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)lottieURLs {
    if (_lottieURLs == nil) {
        NSMutableArray *lottieURLs = [[NSMutableArray alloc] init];
        _lottieURLs = lottieURLs;
    }
    return _lottieURLs;
}

/**
 *  lazy load lottieSizes
 *
 *  @return NSMutableArray
 */
- (NSMutableArray *)lottieSizes {
    if (_lottieSizes == nil) {
        NSMutableArray *lottieSizes = [[NSMutableArray alloc] init];
        _lottieSizes = lottieSizes;
    }
    return _lottieSizes;
}

- (nonnull UIWindow *)rootWindow {
    return CYLGetRootWindow();
}
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
    if (NSNotFound == indexOfSelectedViewController) { return; }
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

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#pragma clang diagnostic ignored "-Wdeprecated-implementations"
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    // FIX: issue #216
    // [EN] Themes that follow the system Dark Mode (`respondsSystemStyleAutomatically`): next run loop, once UIKit has
    //      finished passing the new traits down.
    // [CN] 跟随系统深色模式的主题（`respondsSystemStyleAutomatically`）：在下一个 runloop 处理，此时 UIKit 已向下传递完新的 trait。
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            UITraitCollection *traitCollection = self.traitCollection;
            dispatch_async(dispatch_get_main_queue(), ^{
                [CYLThemeManagerCenter updateThemesForTraitCollection:traitCollection];
            });
        }
    }
    // First: only when a #442 key (dark Lottie file or colors) is in use. 首先：仅在使用了 #442 新增的 key 时处理。
    if (![CYLConstants cyl_hasDarkLottieURLs]) {
        return;
    }
    // Then: only with a Lottie library (Lottie ObjC or Lottie Swift). 其次：仅在引入 Lottie 库（ObjC 或 Swift）时处理。
#if CYL_LOTTIE_AVAILABLE
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            // Next run loop: the tab buttons have the new traits by then. 下一个 runloop：此时 Tab 按钮已更新为新的 trait。
            __weak __typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf cyl_reloadLottieAnimationViewsForCurrentStyle];
            });
        }
    }
#endif
}
#pragma clang diagnostic pop

/// FIX: issue #442 — every tab's Lottie view (classic, Liquid Glass and flat design tab bars) follows the new style.
/// 所有 Tab 的 Lottie 视图（经典、液态玻璃、扁平样式）切换为新风格的动画。
- (void)cyl_reloadLottieAnimationViewsForCurrentStyle {
    if (![CYLConstants cyl_hasDarkLottieURLs]) {
        return;
    }
    NSMutableArray<UIView *> *views = [NSMutableArray arrayWithObject:self.tabBar];
    if (_cyl_tabBar && _cyl_tabBar != self.tabBar) {
        [views addObject:_cyl_tabBar];
    }
    while (views.count > 0) {
        UIView *view = views.lastObject;
        [views removeLastObject];
        if ([view isKindOfClass:[UIControl class]] && [view respondsToSelector:@selector(cyl_reloadLottieAnimationViewForCurrentStyle)]) {
            [view cyl_performSelector:@selector(cyl_reloadLottieAnimationViewForCurrentStyle)];
        }
        [views addObjectsFromArray:view.subviews];
    }
}

#pragma mark - UIContentContainer
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    // [EN] Scroll hiding (issue #13): a rotation or a Split View / Stage Manager resize ends any hide session.
    // [CN] 滚动隐藏（issue #13）：旋转或分屏 / 台前调度尺寸变化时结束隐藏会话。
    [self cyl_tabBarMinimizeLifecycleEvent];
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (!CGSizeEqualToSize(self.view.bounds.size, size)) {
            [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
                [self.selectedViewController.view setNeedsLayout];
                [self.selectedViewController.view layoutIfNeeded];
            } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                [self _cyl_refreshSystemTabBarVisibilityIfNeeded];
            }];
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/    }
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
}


#pragma mark - TabBarItem Action
#if CYL_FLATDESIGN_AVAILABLE

/*!
 * FIX: issue #610
 * [EN] Flat design: reports a tapped tab button or plus button through `tabBarController:didSelectControl:`, as the other
 *      styles do; it was never called in the flat design style. One place for every tap, each reported once: a tab button
 *      (`-[CYLFlatDesignTabBar _tabBarDidSelectButton:]`), a plus button with a child view controller
 *      (`-plusChildViewControllerButtonClicked:`, or the tab button under it) and one without
 *      (`-cyl_flatDesignPlusButtonTouchUpInside:`).
 * [CN] 扁平样式：与其他样式一样，通过 `tabBarController:didSelectControl:` 上报被点击的 Tab 按钮或 PlusButton；以前扁平样式下不会调用。
 *      所有点击共用这一处，每次只上报一次：Tab 按钮（`-[CYLFlatDesignTabBar _tabBarDidSelectButton:]`）、有子控制器的 PlusButton
 *      （`-plusChildViewControllerButtonClicked:`，或其下方的 Tab 按钮）、没有子控制器的 PlusButton（`-cyl_flatDesignPlusButtonTouchUpInside:`）。
 */
- (void)cyl_flatDesignReportDidSelectControl:(UIControl *)control {
    if (!control || control.cyl_userInteractionDisabled) {
        return;
    }
    [self cyl_sendDidSelectControl:control];
}

/// The target of a flat design plus button that has no child view controller (that one has no action of its own here).
/// 没有子控制器的扁平样式 PlusButton 的事件（有子控制器的由 `-plusChildViewControllerButtonClicked:` 处理）。
- (void)cyl_flatDesignPlusButtonTouchUpInside:(UIControl *)plusButton {
    [self cyl_flatDesignReportDidSelectControl:plusButton];
}

- (void)_cyltabBarItemClicked:(CYLFlatDesignTabBarItem *)tabBarItem {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;
        
        NSInteger index = [cyl_tabBar.items indexOfObject:tabBarItem];
        // FIX: issue #618 — an item that has no view controller (NSNotFound, or more items than view controllers)
        // used to raise NSRangeException here.
        if (index == NSNotFound || index >= (NSInteger)self.viewControllers.count) {
            return;
        }
        UIViewController *didSelectViewController = self.viewControllers[index];
        if (didSelectViewController.cyl_isPlaceholder) {
            return;
        }
        if (didSelectViewController.cyl_getViewControllerInsteadOfNavigationController.cyl_isPlaceholder) {
            return;
        }
        // FIX: issue #610 already reported by `-[CYLFlatDesignTabBar _tabBarDidSelectButton:]`, which every tap goes through.
        // 已由每次点击都会经过的 `-[CYLFlatDesignTabBar _tabBarDidSelectButton:]` 上报。
        // FIX: issue #152 — one user tap on a tab button, before the selection changes, also without a delegate.
        // 一次用户点击 Tab 按钮，在选中变化之前；没有代理时同样计数。
        [self cyl_recognizeTabBarItemTapWillSelectViewController:didSelectViewController];
        if ([self.delegate respondsToSelector:@selector(tabBarController:shouldSelectViewController:)]) {
            BOOL sholudSelect = [self.delegate tabBarController:self shouldSelectViewController:didSelectViewController];
            if (!sholudSelect) {
                return;
            }
        }
        [self setSelectedViewController:didSelectViewController];
        //    [self setSelectedIndex:index];
        [self updateSelectionStatusIfNeededForShouldSelectViewController:didSelectViewController shouldSelect:YES];
        //    [self tabChangedToSelectedIndex:index viewController:self.viewControllers[index] selectedItem:tabBarItem];
        if ([self.delegate respondsToSelector:@selector(tabBarController:didSelectViewController:)]) {
            [self.delegate tabBarController:self didSelectViewController:didSelectViewController];
        }
        
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}
#else
#endif
- (void)updateSelectionStatusIfNeededForShouldSelectViewController:(UIViewController *)viewController
                                                      shouldSelect:(BOOL)shouldSelect {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        //    [[viewController.tabBarItem cyl_tabButton] cyl_setUserInteractionDisabled:!shouldSelect];
        if (!shouldSelect) {
            return;
        }
        UIButton *plusButton = [self cyl_contextPlusButton];
        if (!viewController) {
            viewController = self.selectedViewController;
        }
        if (![self hasPlusChildViewController]) {
            return;
        }
        
        BOOL isCurrentViewController = [viewController cyl_isEqualToViewController:[self cyl_contextPlusChildViewController]];
        
        if (isCurrentViewController) {
            [plusButton setSelected:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarItemLottieAnimationPlayingNotification object:self];
        } else {
            [plusButton setSelected:NO];
        }
        
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

#if CYL_FLATDESIGN_AVAILABLE
// The `UINavigationControllerExtensionDelegate` callbacks below come from the flat design subspec only
// (UINavigationController+CYLFlatDesignTabBarPrivate); without it nothing calls them.
// 下面的 `UINavigationControllerExtensionDelegate` 回调只来自扁平样式子库（UINavigationController+CYLFlatDesignTabBarPrivate），没有该子库时不会被调用。
#pragma mark - UINavigationControllerExtensionDelegate
- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
              navigationBarDidChangeHeight:(CGFloat)height {
#if CYL_FLATDESIGN_AVAILABLE
    if (navigationController == self.selectedViewController) {
        [self _cyl_refreshSystemTabBarVisibilityIfNeeded];
    }
#endif
}

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
                    didBeginTransitionFrom:(UIViewController *)fromVC
                                        to:(UIViewController *)toVC
                                 operation:(UINavigationControllerOperation)operation {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        // [CN] 转场或pop手势返回时禁止用户交互
        // [EN] Disable user interaction during transitions or the interactive pop gesture
        self.view.userInteractionEnabled = NO;
        UIEdgeInsets additionalSafeAreaInsets = self.selectedViewController.additionalSafeAreaInsets;
        //FIX:  issue#652
        //        additionalSafeAreaInsets.bottom = self.tabBarHeight;
        [UIView performWithoutAnimation:^{
            self.selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
            if ([self _showsMoreNavigationController] && self.moreNavigationController != self.selectedViewController) {
                CYLSetAdditionalSafeAreaBottom(self.moreNavigationController, additionalSafeAreaInsets.bottom);
            }
        }];
        
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
                  didUpdateInteractiveFrom:(UIViewController *)fromVC
                                        to:(UIViewController *)toVC
                           percentComplete:(CGFloat)percentComplete {
    //     NSLog(@"pop手势返回：%.2f", percentComplete);
}


- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
                  didUpdateInteractiveFrom:(UIViewController *)fromVC
                                        to:(UIViewController *)toVC
                      popGestureRecognizer:(UIGestureRecognizer *)popGestureRecognizer {
    
}

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
                     willEndTransitionFrom:(UIViewController *)fromVC
                                        to:(UIViewController *)toVC
                                 operation:(UINavigationControllerOperation)operation
                                 cancelled:(BOOL)cancelled {

    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        BOOL showsTabBar = [self _shouldShowsBottomBar];
        if (operation == UINavigationControllerOperationPush) {
            if (!showsTabBar && !self.cyl_tabBar.hidden) {
                [self _addParallaxOverlayViewToViewController:fromVC];
            }
        } else {
            if (showsTabBar && self.cyl_tabBar.hidden) {
                [self _addParallaxOverlayViewToViewController:toVC];
            }
        }
        
        UIEdgeInsets additionalSafeAreaInsets = self.selectedViewController.additionalSafeAreaInsets;
        additionalSafeAreaInsets.bottom = showsTabBar ? self.tabBarHeight : 0;
        [UIView performWithoutAnimation:^{
            self.selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
            if ([self _showsMoreNavigationController] && self.moreNavigationController != self.selectedViewController) {
                CYLSetAdditionalSafeAreaBottom(self.moreNavigationController, additionalSafeAreaInsets.bottom);
            }
        }];
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
                      didEndTransitionFrom:(UIViewController *)fromVC
                                        to:(UIViewController *)toVC
                                 operation:(UINavigationControllerOperation)operation
                                 cancelled:(BOOL)cancelled {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        self.view.userInteractionEnabled = YES;
        if (_parallaxOverlayView) {
            [_parallaxOverlayView removeFromSuperview];
            _parallaxOverlayView = nil;
        }
        
        if (self.cyl_tabBar.superview != self.view) {
            self.cyl_tabBar.frame = self.tabBarFrame;
            [self.view addSubview:self.cyl_tabBar];
        }
        
        [self _updateBottomBarShowHideIfNeeded];
        // A refresh deferred while the bar was in the transition overlay must
        // be retried after the overlay has been removed (including cancellation).
        [self _cyl_refreshSystemTabBarVisibilityIfNeeded];
        if (!_cylDidRefreshSystemTabBarVisibility) {
            __weak __typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf _cyl_refreshSystemTabBarVisibilityIfNeeded];
            });
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}
#endif

#pragma mark - Private

- (CGRect)tabBarFrame {
    CGFloat tabBarHeight = self.tabBarHeight + self.view.safeAreaInsets.bottom;
    CGRect tabBarFrame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - tabBarHeight, CGRectGetWidth(self.view.bounds), tabBarHeight);
    return tabBarFrame;
}

- (BOOL)_showsMoreNavigationController {
    // [CN] 用 self.viewControllers.count > 5 判断行不行？
    // [EN] Would checking self.viewControllers.count > 5 work?
    BOOL _showsMoreNavigationController = NO;
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        // FIX: issue #662 — the guard was inverted, so FlatDesign never detected UIKit's More item and
        // `_checkHidesBottomBarWhenPushed` / the safe-area updates ignored `moreNavigationController`.
        // 判断条件写反了：扁平模式下永远识别不到 UIKit 的 More 项。
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {     return _showsMoreNavigationController; }

        // Ask UIKit instead of counting: iPad and regular width show more than five items without a More tab.
        // 以 UIKit 实际是否生成 More 项为准：iPad / regular 宽度下超过 5 个也不会出现 More。
        _showsMoreNavigationController = [self.tabBar.items containsObject:self.moreNavigationController.tabBarItem];
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    return _showsMoreNavigationController;
}

- (void)_captureItems {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        BOOL hasMoreItem = [self _showsMoreNavigationController];
        if (self.moreNavigationController) {
            hasMoreItem = [self.tabBar.items containsObject:self.moreNavigationController.tabBarItem];
        }
        NSMutableArray *items = [NSMutableArray array];
        if (hasMoreItem) {
            // `i + 1 < count` instead of `i < count - 1`: `count` is unsigned, so `count - 1` wraps to a huge
            // number when there are no items, and `viewControllers[i]` would run out of range.
            // 用 `i + 1 < count` 而不是 `i < count - 1`：count 是无符号数，没有 item 时 `count - 1` 会回绕成极大值，导致 `viewControllers[i]` 越界。
            for (NSUInteger i = 0; i + 1 < self.tabBar.items.count; i++) {
                UIViewController *viewController = self.viewControllers[i];
                if (!viewController.cyl_tabBarItem) {
                    continue;
                }
                [viewController cylflatdesign_setTabBarController:self];
                [items addObject:viewController.cyl_tabBarItem];
                [viewController cyl_setTabButton:viewController.cyl_tabBarItem.tabBarButton];
            }
            CYLFlatDesignTabBarItem *moreItem = self.moreNavigationController.cyl_tabBarItem;
            UITabBarItem *systemMoreItem = self.moreNavigationController.tabBarItem;
            if (moreItem.title.length == 0 && systemMoreItem.title.length < 0) {
                moreItem.title = systemMoreItem.title;
            }
            if (!moreItem.image && systemMoreItem.image) {
                moreItem.image = systemMoreItem.image;
            }
            if (!moreItem.selectedImage && systemMoreItem.selectedImage) {
                moreItem.selectedImage = systemMoreItem.selectedImage;
            }
            [items addObject:moreItem];
        } else {
            
            for (NSInteger i = 0; i < self.viewControllers.count; i++) {
                
                UIViewController *viewController = self.viewControllers[i];
                CYLFlatDesignTabBarItem *cyl_tabBarItem = viewController.cyl_tabBarItem;
                if (!cyl_tabBarItem) {
                    continue;
                }
                [viewController cylflatdesign_setTabBarController:self];
                cyl_tabBarItem.index = i;
                [items addObject:cyl_tabBarItem];
                [viewController cyl_setTabButton:cyl_tabBarItem.tabBarButton];
            }
            
            
        }
        if ((0 == self.viewControllers.count) || (0 == items.count)) {
            return;
        }
        [self _syncSystemItems];
        self.items = items;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)_syncSystemItems {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        for (UIViewController *viewController in self.viewControllers) {
            viewController.tabBarItem.title = viewController.cyl_tabBarItem.title;
            
            viewController.tabBarItem.image = viewController.cyl_tabBarItem.image;
            //        viewController.tabBarItem.badgeValue = viewController.cyl_badge.text;
            //        viewController.tabBarItem.badgeColor = viewController.cyl_tabBarItem.badgeColor;
            viewController.tabBarItem.titlePositionAdjustment = viewController.cyl_tabBarItem.titlePositionAdjustment;
            [viewController.tabBarItem setTitleTextAttributes:[viewController.cyl_tabBarItem titleTextAttributesForState:UIControlStateNormal] forState:UIControlStateNormal];
            [viewController.tabBarItem setTitleTextAttributes:[viewController.cyl_tabBarItem titleTextAttributesForState:UIControlStateSelected] forState:UIControlStateSelected];
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (BOOL)_shouldShowsBottomBar {
    BOOL showsTabBar = YES;
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return showsTabBar; }
        
        if (self.isTabBarHidden) {
            showsTabBar = NO;
        } else {
            showsTabBar = [self _checkHidesBottomBarWhenPushed];
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    
    return showsTabBar;
}

- (void)_updateBottomBarShowHideIfNeeded {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        BOOL showsTabBar = [self _shouldShowsBottomBar];
        if (!_tabBarIsAnimating) {
            self.cyl_tabBar.hidden = !showsTabBar;
        }
        [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
        // [EN] A tab was selected or a push/pop ended: track the new page's scroll view (issue #13).
        // [CN] 切换了 Tab 或 push/pop 结束：跟随新页面的滚动视图（issue #13）。
        [self cyl_updateTabBarMinimizeTracking];
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)_addParallaxOverlayViewToViewController:(UIViewController *)viewController {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        // create overlayView
        UIView *superview = viewController.view;
        if (!_parallaxOverlayView) {
            _parallaxOverlayView = [[_CYLFlatDesignTabBarParallaxOverlayView alloc] initWithFrame:superview.bounds];
        }
        _parallaxOverlayView.frame = superview.bounds;
        [superview addSubview:_parallaxOverlayView];
        [superview bringSubviewToFront:_parallaxOverlayView];
        
        if (self.cyl_tabBar.superview != _parallaxOverlayView) {
            // FIX: issue #662 (PR #665)
            // This runs inside the navigation transition's animation block; re-parenting and
            // re-positioning must not be animated, or the bar visibly slides into place.
            [UIView performWithoutAnimation:^{
                [self->_parallaxOverlayView addSubview:self.cyl_tabBar];
                if (!self->_tabBarIsAnimating) {
                    self.cyl_tabBar.frame = [self _tabBarFrameInParallaxOverlayView:self->_parallaxOverlayView];
                }
                self.cyl_tabBar.hidden = NO;
            }];
#if defined(DEBUG) || defined(BETA)
            [self _logTabBarClippingInParallaxOverlay];
#endif
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

/// FIX: issue #662 (push/pop follow-up, PR #665): tab bar shrinks/jumps during push and pop.
/// `tabBarFrame` is expressed in `self.view`'s coordinate space, but during a push/pop the tab bar is
/// moved into `_parallaxOverlayView`, which lives inside the child view controller's view. That view
/// does not always share `self.view`'s geometry: with an opaque navigation bar
/// (e.g. `edgesForExtendedLayout = UIRectEdgeNone`, a non-translucent bar, or libraries such as
/// HBDNavigationBar) it starts below the navigation bar and is shorter. Using `tabBarFrame` unchanged
/// placed the bar too low by the navigation bar height, so it was partly or fully off screen during the
/// transition and then snapped back when it returned to `self.view`.
/// Only the vertical position is converted; the horizontal position stays relative to the child's view
/// so the bar keeps moving with it (the parallax effect).
- (CGRect)_tabBarFrameInParallaxOverlayView:(UIView *)overlayView {
    CGRect frame = self.tabBarFrame;
    if (overlayView.window && overlayView.window == self.view.window) {
        frame.origin.y = [self.view convertPoint:CGPointMake(0, CGRectGetMinY(frame)) toView:overlayView].y;
    }
    // Otherwise the two views cannot be related yet; keep the previous behaviour.
    return frame;
}

#if defined(DEBUG) || defined(BETA)
/*!
 * FIX: issue #662 (PR #665) — DEBUG diagnostic, not a fix.
 * [EN] Reported on iPhone Duo: folded (outer display, 466 × 678, 84 pt trailing status column), the tab bar
 *      still looks shorter during push/pop and then recovers; unfolded (inner display) it is fine.
 *      The bar's frame and its content height are the same in both poses on this branch, so a folded-only
 *      shrink points to a view *above* the bar clipping it (clipsToBounds or a layer mask) while it rides
 *      the sliding page. This logs the first such ancestor, once per transition, so the cause can be fixed.
 * [CN] iPhone Duo 反馈：折叠状态（外屏 466 × 678，右侧 84pt 竖向状态栏）push/pop 时 TabBar 仍会变矮后恢复；
 *      展开状态（内屏）正常。本分支上 TabBar 的 frame 与内容高度在两种状态下一致，
 *      因此只在折叠时出现的变矮，指向 TabBar 的某个祖先视图在转场中把它裁掉（clipsToBounds 或 layer.mask）。
 *      此处在每次转场打印第一个裁切 TabBar 的祖先视图，便于定位并修复。
 */
- (void)_logTabBarClippingInParallaxOverlay {
    UIView *tabBar = self.cyl_tabBar;
    UIWindow *window = tabBar.window;
    if (!window) { return; }
    CGRect tabBarInWindow = [tabBar convertRect:tabBar.bounds toView:window];
    for (UIView *ancestor = tabBar.superview; ancestor && ancestor != window; ancestor = ancestor.superview) {
        CALayer *maskLayer = ancestor.layer.mask;
        if (!ancestor.clipsToBounds && !maskLayer) { continue; }
        CGRect clipRect = maskLayer ? [ancestor.layer convertRect:maskLayer.frame toLayer:window.layer]
                                    : [ancestor convertRect:ancestor.bounds toView:window];
        CGRect visibleRect = CGRectIntersection(tabBarInWindow, clipRect);
        if (CGRectGetHeight(visibleRect) < CGRectGetHeight(tabBarInWindow) - 0.5) {
            NSLog(@"🟠[CYL #662] tab bar clipped vertically by %@ (%@): tabBar=%@ clip=%@ visibleHeight=%.1f window=%@ windowSafe=%@",
                  NSStringFromClass(ancestor.class),
                  maskLayer ? @"layer.mask" : @"clipsToBounds",
                  NSStringFromCGRect(tabBarInWindow),
                  NSStringFromCGRect(clipRect),
                  CGRectGetHeight(visibleRect),
                  NSStringFromCGRect(window.bounds),
                  NSStringFromUIEdgeInsets(window.safeAreaInsets));
            return;
        }
    }
}
#endif

- (void)_updateAdditionalSafeAreaInsetsWithAnimated:(BOOL)animated {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        UIViewController *selectedViewController = self.selectedViewController;
        UIEdgeInsets additionalSafeAreaInsets = selectedViewController.additionalSafeAreaInsets;
        additionalSafeAreaInsets.bottom = self.cyl_tabBar.hidden ? 0 : self.tabBarHeight;
        if (animated) {
            [UIView animateWithDuration:0.2 animations:^{
                selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
                if ([self _showsMoreNavigationController] && self.moreNavigationController != selectedViewController) {
                    CYLSetAdditionalSafeAreaBottom(self.moreNavigationController, additionalSafeAreaInsets.bottom);
                }
            }];
        } else {
            selectedViewController.additionalSafeAreaInsets = additionalSafeAreaInsets;
            if ([self _showsMoreNavigationController] && self.moreNavigationController != selectedViewController) {
                CYLSetAdditionalSafeAreaBottom(self.moreNavigationController, additionalSafeAreaInsets.bottom);
            }
        }
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}
    
#if CYL_FLATDESIGN_AVAILABLE

- (void)changeItem:(CYLFlatDesignTabBarItem *)item toItem:(CYLFlatDesignTabBarItem *)toItem {
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        NSInteger index = [self.items indexOfObject:item];
        if (index == NSNotFound) {
            return;
        }
        [self.items replaceObjectAtIndex:index withObject:toItem];
        [self.cyl_tabBar setItems:self.items];

    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}
#else
#endif
    
@end

#pragma mark - Live tab bar controllers (most recently active last)

/*!
 * [EN] Every CYLTabBarController that has view controllers, held WEAKLY and ordered by when it last appeared: the last
 *      one is the most recently active. A controller joins at the bottom when it gets its view controllers, moves to the
 *      top in `-viewWillAppear:`, and drops out by itself when it is deallocated. This replaces "the root view
 *      controller" as the answer when nothing more specific is known: with several tab bar controllers (a pushed or
 *      presented one, #414), the root one is often not the one in use.
 * [CN] 所有已设置 viewControllers 的 CYLTabBarController，**弱引用** 保存，按最后一次显示的先后排序：最后一个就是最近活跃的。
 *      控制器在设置 viewControllers 时加入到最底部，在 `-viewWillAppear:` 时移到最顶部，释放后自动移除。
 *      在没有更具体信息时，用它代替“根控制器”作为答案：存在多个 TabBarController 时（push 或 present 出来的，#414），
 *      根控制器往往不是正在使用的那个。
 */
static NSPointerArray *CYLTabBarControllerActivationStack(void) {
    static NSPointerArray *stack;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stack = [NSPointerArray weakObjectsPointerArray];
    });
    return stack;
}

/// Removes `tabBarController`, and the entries of deallocated controllers (their weak pointers are NULL).
static void CYLTabBarControllerActivationStackRemove(NSPointerArray *stack, CYLTabBarController *tabBarController) {
    for (NSInteger index = (NSInteger)stack.count - 1; index >= 0; index--) {
        void *pointer = [stack pointerAtIndex:index];
        if (!pointer || pointer == (__bridge void *)tabBarController) {
            [stack removePointerAtIndex:index];
        }
    }
}

/// `object` is a CYLTabBarController that `matcher` accepts (any one when `matcher` is nil).
static BOOL CYLTabBarControllerMatches(id object, CYLTabBarControllerMatcher matcher) {
    return [object isKindOfClass:[CYLTabBarController class]] && (!matcher || matcher(object));
}

/// The style family a lookup asks for: flat design (`CYLTabBarStyleTypeFlatDesign`), or the system styles (any other
/// value: Default, System, LiquidGlass, as `-cyl_isSystemStyleTabBar` counts them).
static CYLTabBarControllerMatcher CYLTabBarControllerMatcherForStyleType(CYLTabBarStyleType styleType) {
    BOOL wantsFlatDesign = (CYLTabBarStyleTypeFlatDesign == styleType);
    return ^BOOL(CYLTabBarController *tabBarController) {
        return wantsFlatDesign == (CYLTabBarStyleTypeFlatDesign == tabBarController.tabBarStyleType);
    };
}

/// The reference set on `object` with `-cyl_setTabBarController:` or `-cylflatdesign_setTabBarController:`, if accepted.
static CYLTabBarController *CYLTabBarControllerExplicitReference(id object, CYLTabBarControllerMatcher matcher) {
    // [EN] Weak references set by `-cyl_setTabBarController:` / `-cylflatdesign_setTabBarController:` (CYLUtils).
    // [CN] 由 `-cyl_setTabBarController:` / `-cylflatdesign_setTabBarController:` 设置的弱引用（CYLUtils）。
    id tabBarController = [object cyl_weakAssociatedObjectForKey:@selector(cyl_tabBarController)];
    if (CYLTabBarControllerMatches(tabBarController, matcher)) {
        return tabBarController;
    }
#if CYL_FLATDESIGN_AVAILABLE
    tabBarController = [object cyl_weakAssociatedObjectForKey:@selector(cylflatdesign_tabBarController)];
    if (CYLTabBarControllerMatches(tabBarController, matcher)) {
        return tabBarController;
    }
#endif
    return nil;
}

/// The controller of a tab bar (system or flat design): its `delegate`, which the controller sets to itself. Known even
/// before the tab bar is in the controller's view, where the responder chain could not reach it.
static CYLTabBarController *CYLTabBarControllerOwningTabBar(UIResponder *responder) {
    id delegate = nil;
    if ([responder isKindOfClass:[UITabBar class]]) {
        delegate = ((UITabBar *)responder).delegate;
    }
#if CYL_FLATDESIGN_AVAILABLE
    else if ([responder isKindOfClass:[CYLFlatDesignTabBar class]]) {
        delegate = ((CYLFlatDesignTabBar *)responder).delegate;
    }
#endif
    return [delegate isKindOfClass:[CYLTabBarController class]] ? delegate : nil;
}

@implementation CYLTabBarController (CYLTabBarItemIdentifier)

/// This tab bar controller's plus button (its own copy with several tab bar controllers), if any.
- (UIControl *)cyl_identifiedPlusButton {
    return [self hasPlusButton] ? [self cyl_contextPlusButton] : nil;
}

/// The identifier of one of this controller's tabs: the one set, else the default. 已设置的标识，否则为默认值。
- (NSString *)cyl_tabBarItemIdentifierForViewController:(UIViewController *)viewController {
    if (!viewController) {
        return nil;
    }
    NSString *identifier = objc_getAssociatedObject(viewController, @selector(cyl_tabBarItemIdentifier));
    return identifier ?: [self cyl_defaultTabBarItemIdentifierForViewController:viewController];
}

+ (NSString *)cyl_defaultTabBarItemIdentifierForClass:(Class)aClass {
    // Swift classes are named "Module.Class"; the module is dropped. Swift 类名形如「模块.类名」，去掉模块名。
    NSString *name = aClass ? NSStringFromClass(aClass) : @"";
    NSRange dot = [name rangeOfString:@"." options:NSBackwardsSearch];
    return dot.location == NSNotFound ? name : [name substringFromIndex:NSMaxRange(dot)];
}

- (NSString *)cyl_defaultTabBarItemIdentifierForViewController:(UIViewController *)viewController {
    if (!viewController) {
        return nil;
    }
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    NSUInteger index = NSNotFound;
    for (NSUInteger i = 0; i < viewControllers.count; i++) {
        UIViewController *tab = viewControllers[i];
        if (tab == viewController || [tab cyl_getViewControllerInsteadOfNavigationController] == viewController) {
            index = i;
            break;
        }
    }
    if (index == NSNotFound) {
        return nil;
    }
    UIViewController *tab = viewControllers[index];
    // The plus child view controller is the plus button's tab. PlusButton 子控制器即 PlusButton 对应的 Tab。
    if ([tab cyl_isEqualToViewController:[self cyl_contextPlusChildViewController]] && [self cyl_identifiedPlusButton]) {
        return [self cyl_identifiedPlusButton].cyl_tabBarItemIdentifier;
    }
    Class contentClass = [[tab cyl_getViewControllerInsteadOfNavigationController] class];
    NSString *identifier = [CYLTabBarController cyl_defaultTabBarItemIdentifierForClass:contentClass];
    // The next tabs of the same class: "_2", "_3"... 后续同类的 Tab 依次加 "_2"、"_3"……
    NSUInteger occurrence = 1;
    for (NSUInteger i = 0; i < index; i++) {
        if ([[viewControllers[i] cyl_getViewControllerInsteadOfNavigationController] class] == contentClass) {
            occurrence++;
        }
    }
    return occurrence == 1 ? identifier : [NSString stringWithFormat:@"%@_%lu", identifier, (unsigned long)occurrence];
}

- (NSString *)cyl_selectedTabBarItemIdentifier {
    return [self cyl_tabBarItemIdentifierForViewController:self.selectedViewController];
}

- (NSUInteger)cyl_indexOfTabBarItemIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return NSNotFound;
    }
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    for (NSUInteger index = 0; index < viewControllers.count; index++) {
        if ([[self cyl_tabBarItemIdentifierForViewController:viewControllers[index]] isEqualToString:identifier]) {
            return index;
        }
    }
    return NSNotFound;
}

- (UIViewController *)cyl_viewControllerWithTabBarItemIdentifier:(NSString *)identifier {
    NSUInteger index = [self cyl_indexOfTabBarItemIdentifier:identifier];
    return index == NSNotFound ? nil : self.viewControllers[index];
}

- (UIViewController *)cyl_selectTabBarItemWithIdentifier:(NSString *)identifier {
    NSUInteger index = [self cyl_indexOfTabBarItemIdentifier:identifier];
    if (index == NSNotFound) {
        return nil;
    }
    self.selectedIndex = index;
    return self.viewControllers[index];
}

- (NSArray<NSString *> *)cyl_tabBarItemIdentifiers {
    NSMutableArray<NSString *> *identifiers = [NSMutableArray array];
    for (UIViewController *viewController in self.viewControllers) {
        NSString *identifier = [self cyl_tabBarItemIdentifierForViewController:viewController];
        if (identifier) {
            [identifiers addObject:identifier];
        }
    }
    NSString *plusButtonIdentifier = [self cyl_identifiedPlusButton].cyl_tabBarItemIdentifier;
    if (plusButtonIdentifier && ![identifiers containsObject:plusButtonIdentifier]) {
        [identifiers addObject:plusButtonIdentifier];
    }
    return [identifiers copy];
}

- (UIControl *)cyl_controlWithTabBarItemIdentifier:(NSString *)identifier {
    if (identifier.length == 0) {
        return nil;
    }
    UIControl *plusButton = [self cyl_identifiedPlusButton];
    if ([plusButton.cyl_tabBarItemIdentifier isEqualToString:identifier]) {
        return plusButton;
    }
    return [self cyl_viewControllerWithTabBarItemIdentifier:identifier].cyl_tabButton;
}

@end

#pragma mark - Selected index without the plus button (issue #515)

@implementation CYLTabBarController (CYLSelectedIndexIgnoringPlusButton)

/// [EN] YES for the plus button's child view controller or placeholder. [CN] PlusButton 的子控制器或占位控制器时为 YES。
- (BOOL)cyl_isPlusButtonViewController:(UIViewController *)viewController {
    // [EN] FIX: placeholder count mismatch — the same test as the slot insertion, so `cyl_viewControllersIgnoringPlusButton`
    //      also leaves out a plus child view controller inside a navigation controller.
    // [CN] FIX：占位导致的数量不匹配——与插入 slot 时使用同一判断，`cyl_viewControllersIgnoringPlusButton` 也会去掉被导航控制器包裹的
    //      PlusButton 子控制器。
    return [self cyl_isPlusSlotViewController:viewController];
}

- (NSArray<UIViewController *> *)cyl_viewControllersIgnoringPlusButton {
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    for (UIViewController *viewController in self.viewControllers) {
        if (![self cyl_isPlusButtonViewController:viewController]) {
            [viewControllers addObject:viewController];
        }
    }
    return [viewControllers copy];
}

- (NSUInteger)cyl_selectedIndexForIndexIgnoringPlusButton:(NSUInteger)index {
    NSArray<UIViewController *> *viewControllers = self.cyl_viewControllersIgnoringPlusButton;
    if (index >= viewControllers.count) {
        return NSNotFound;
    }
    return [self.viewControllers indexOfObject:viewControllers[index]];
}

- (NSUInteger)cyl_selectedIndexIgnoringPlusButton {
    UIViewController *selectedViewController = self.selectedViewController;
    if (!selectedViewController) {
        return NSNotFound;
    }
    return [self.cyl_viewControllersIgnoringPlusButton indexOfObject:selectedViewController];
}

- (void)cyl_setSelectedIndexIgnoringPlusButton:(NSUInteger)selectedIndexIgnoringPlusButton {
    NSUInteger selectedIndex = [self cyl_selectedIndexForIndexIgnoringPlusButton:selectedIndexIgnoringPlusButton];
    if (selectedIndex == NSNotFound) {
        return;
    }
    self.selectedIndex = selectedIndex;
}

@end

@implementation CYLTabBarController (CYLActiveTabBarController)

+ (void)cyl_registerTabBarController:(CYLTabBarController *)tabBarController {
    if (!tabBarController) {
        return;
    }
    NSPointerArray *stack = CYLTabBarControllerActivationStack();
    @synchronized (stack) {
        for (NSUInteger index = 0; index < stack.count; index++) {
            if ([stack pointerAtIndex:index] == (__bridge void *)tabBarController) {
                return;     // already known: keep its place
            }
        }
        [stack insertPointer:(__bridge void *)tabBarController atIndex:0];
    }
}

+ (void)cyl_markTabBarControllerActive:(CYLTabBarController *)tabBarController {
    if (!tabBarController) {
        return;
    }
    NSPointerArray *stack = CYLTabBarControllerActivationStack();
    @synchronized (stack) {
        CYLTabBarControllerActivationStackRemove(stack, tabBarController);
        [stack addPointer:(__bridge void *)tabBarController];
    }
}

+ (CYLTabBarController *)cyl_tabBarControllerForContext:(NSString *)context matching:(CYLTabBarControllerMatcher)matcher {
    NSPointerArray *stack = CYLTabBarControllerActivationStack();
    @synchronized (stack) {
        for (NSInteger index = (NSInteger)stack.count - 1; index >= 0; index--) {
            CYLTabBarController *tabBarController = (__bridge CYLTabBarController *)[stack pointerAtIndex:index];
            if (!tabBarController) {
                continue;
            }
            if (context && ![tabBarController.cyl_context isEqualToString:context]) {
                continue;
            }
            if (!CYLTabBarControllerMatches(tabBarController, matcher)) {
                continue;
            }
            return tabBarController;
        }
    }
    return nil;
}

+ (CYLTabBarController *)cyl_tabBarControllerForContext:(NSString *)context {
    return [self cyl_tabBarControllerForContext:context matching:nil];
}

+ (CYLTabBarController *)cyl_activeTabBarController {
    // The most recently active one is the context lookup without a context.
    return [self cyl_tabBarControllerForContext:nil];
}

/// Every control under `view` that hosts a Lottie view: the tab buttons of any style (Liquid Glass has a normal and a
/// selected one per tab, flat design has its own buttons).
static void CYLCollectLottieTabButtons(UIView *view, NSMutableArray<UIControl *> *tabButtons) {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIControl class]] && ((UIControl *)subview).cyl_lottieAnimationView) {
            [tabButtons addObject:(UIControl *)subview];
            continue;
        }
        CYLCollectLottieTabButtons(subview, tabButtons);
    }
}

/// One line per tab: badge shown or not, then each Lottie view's `animationSpeed`.
static NSString *CYLTabBarStateDescription(CYLTabBarController *tabBarController) {
    if (!tabBarController) {
        return @"no active CYLTabBarController";
    }
    NSMutableString *description = [NSMutableString stringWithFormat:@"%@ (%@)", NSStringFromClass([tabBarController class]), tabBarController.cyl_context ?: @"default context"];
    [tabBarController.viewControllers enumerateObjectsUsingBlock:^(UIViewController *viewController, NSUInteger idx, BOOL *stop) {
        [description appendFormat:@"\n  tab %@: badge %@", @(idx), [viewController cyl_isShowBadge] ? @"shown" : @"hidden"];
    }];
    NSMutableArray<UIControl *> *tabButtons = [NSMutableArray array];
    CYLCollectLottieTabButtons(tabBarController.cyl_tabBar ?: tabBarController.tabBar, tabButtons);
    for (UIControl *tabButton in tabButtons) {
        UIView *lottieView = tabButton.cyl_lottieAnimationView;
        id speed = [lottieView respondsToSelector:NSSelectorFromString(@"animationSpeed")] ? [lottieView valueForKey:@"animationSpeed"] : @"?";
        [description appendFormat:@"\n  Lottie view in %@ at x = %.0f: animationSpeed %@", NSStringFromClass([tabButton class]), CGRectGetMinX([tabButton convertRect:tabButton.bounds toView:nil]), speed];
    }
    if (tabButtons.count == 0) {
        [description appendString:@"\n  no Lottie views (Lottie not integrated or not configured)"];
    }
    return description;
}

+ (void)cyl_simulateMemoryWarning {
    [self cyl_simulateMemoryWarningForTabBarController:[self cyl_activeTabBarController]];
}

+ (void)cyl_simulateMemoryWarningForTabBarController:(CYLTabBarController *)tabBarController {
    UIApplication *application = [UIApplication sharedApplication];
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:application];
    if ([application.delegate respondsToSelector:@selector(applicationDidReceiveMemoryWarning:)]) {
        [application.delegate applicationDidReceiveMemoryWarning:application];
    }
    // A real memory warning also calls `-didReceiveMemoryWarning` on the view controllers; the notification does not.
    [tabBarController didReceiveMemoryWarning];
    // Log on the next run loop pass, after whatever the warning released has been released.
    __weak CYLTabBarController *weakTabBarController = tabBarController;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"⚠️ Simulated memory warning (issues #426, #428). Tab bar state afterwards:\n%@", CYLTabBarStateDescription(weakTabBarController));
    });
}

@end

@implementation NSObject (CYLTabBarControllerReferenceExtension)

- (void)cyl_setTabBarController:(nullable CYLTabBarController *)tabBarController {
    [self cyl_setWeakAssociatedObject:tabBarController forKey:@selector(cyl_tabBarController)];
}

/*!
 * [EN] The one lookup behind `-cyl_tabBarController` (system styles), `-cylflatdesign_tabBarController` (flat design),
 *      `-cyl_tabBarControllerForStyleType:` and `-cyl_owningTabBarController` (any style, which the plus button registry
 *      uses to find an object's context). `matcher` picks which controllers count (nil: any). In order:
 *      0. a tab bar controller that counts is its own;
 *      1. a reference set explicitly with `-cyl_setTabBarController:` or `-cylflatdesign_setTabBarController:`;
 *      2. where the object is: a view goes up its responder chain, through the tab bar it is in (its `delegate`), to the
 *         view controller that owns it; a view controller goes up its parents. So a tab button, the plus button or a view
 *         in a tab finds its own controller, not the root one;
 *      3. if `fallsBackToActive`, the most recently active one (`+cyl_activeTabBarController`), then the root view
 *         controller, as before.
 * [CN] `-cyl_tabBarController`（系统样式）、`-cylflatdesign_tabBarController`（扁平样式）、`-cyl_tabBarControllerForStyleType:`
 *      和 `-cyl_owningTabBarController`（任意样式，PlusButton 注册表用它确定对象的 context）共用的查找。`matcher` 决定哪些控制器符合（nil 表示任意）。顺序：
 *      0. 符合条件的 TabBarController 就是它自己；
 *      1. 通过 `-cyl_setTabBarController:` 或 `-cylflatdesign_setTabBarController:` 显式设置的引用；
 *      2. 对象所在的位置：View 沿响应链向上，经过它所在的 TabBar（其 `delegate`），到拥有它的 ViewController；ViewController
 *         沿父控制器链向上。因此 Tab 按钮、PlusButton 或 Tab 页面内的 View 找到的是自己的控制器，而不是根控制器；
 *      3. 若 `fallsBackToActive`，取最近活跃的那个（`+cyl_activeTabBarController`），最后才是根控制器（与以前一致）。
 */
- (CYLTabBarController *)cyl_tabBarControllerMatching:(CYLTabBarControllerMatcher)matcher fallsBackToActive:(BOOL)fallsBackToActive {
    // 0. A tab bar controller it accepts is its own: `-visiableTabBarSize` and the `CYL_IS_IPHONE_X` /
    //    `CYL_NoNeed_UIDesignRequiresCompatibility` macros ask `self.cyl_tabBarController` from inside it. Asking an
    //    ancestor or the root instead gave a pushed tab bar controller the outer one's values.
    //    匹配的 TabBarController 就是它自己：`-visiableTabBarSize` 和 `CYL_IS_IPHONE_X` 等宏在控制器内部使用
    //    `self.cyl_tabBarController`。以前取的是上层或根控制器，push 出来的 TabBarController 会拿到外层的值。
    if (CYLTabBarControllerMatches(self, matcher)) {
        return (CYLTabBarController *)self;
    }
    // 1. An explicit reference.
    CYLTabBarController *tabBarController = CYLTabBarControllerExplicitReference(self, matcher);
    if (tabBarController) {
        return tabBarController;
    }
    // 2. Where it is. A view: up its responder chain, through the tab bar it is in (whose `delegate` is the controller),
    //    to the view controller that owns it. A view controller, or that one: up its parents.
    UIViewController *viewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        viewController = ((UIViewController *)self).parentViewController;
    } else if ([self isKindOfClass:[UIView class]]) {
        UIResponder *responder = (UIView *)self;
        for (; responder && ![responder isKindOfClass:[UIViewController class]]; responder = responder.nextResponder) {
            tabBarController = CYLTabBarControllerOwningTabBar(responder);
            if (CYLTabBarControllerMatches(tabBarController, matcher)) {
                return tabBarController;
            }
        }
        viewController = (UIViewController *)responder;
    }
    for (; viewController; viewController = viewController.parentViewController) {
        if (CYLTabBarControllerMatches(viewController, matcher)) {
            return (CYLTabBarController *)viewController;
        }
        tabBarController = CYLTabBarControllerExplicitReference(viewController, matcher);
        if (tabBarController) {
            return tabBarController;
        }
    }
    if (!fallsBackToActive) {
        return nil;
    }
    // 3. Nothing more specific: the most recently active one, not a singleton-like root; the root only when none is known.
    tabBarController = [CYLTabBarController cyl_tabBarControllerForContext:nil matching:matcher];
    if (tabBarController) {
        return tabBarController;
    }
    UIViewController *rootViewController = [CYLGetRootViewController() cyl_getViewControllerInsteadOfNavigationController];
    return CYLTabBarControllerMatches(rootViewController, matcher) ? (CYLTabBarController *)rootViewController : nil;
}

- (CYLTabBarController *)cyl_owningTabBarController {
    // Only where it is: callers decide what to fall back to (the plus button registry must not take another
    // controller's context for a tab bar that is not attached yet).
    return [self cyl_tabBarControllerMatching:nil fallsBackToActive:NO];
}

- (CYLTabBarController *)cyl_tabBarControllerForStyleType:(CYLTabBarStyleType)styleType {
    return [self cyl_tabBarControllerMatching:CYLTabBarControllerMatcherForStyleType(styleType) fallsBackToActive:YES];
}

- (CYLTabBarController *)cyl_tabBarController {
    // System styles (everything but flat design). Falls back to the most recently active one, then the root, as the
    // root fallback did before (#414: with several tab bar controllers the root one is often not the one in use).
    // 系统样式（除扁平样式外）。回退到最近活跃的那个，最后才是根控制器（#414：存在多个 TabBarController 时根控制器往往不是正在使用的那个）。
    return [self cyl_tabBarControllerForStyleType:CYLTabBarStyleTypeDefault];
}

#pragma mark - @implementation UIViewController (CYLFlatDesignUITabBarControllerItem) @implementation UIViewController (CYLFlatDesignUIViewControllerItem)
// MARK: @implementation UIViewController (CYLFlatDesignUITabBarControllerItem) @implementation UIViewController (CYLFlatDesignUIViewControllerItem)

#if CYL_FLATDESIGN_AVAILABLE


- (void)cylflatdesign_setTabBarController:(UIViewController *)tabBarController {
    // The property is declared `weak` in the header, so store a weak box instead of
    // retaining the tab bar controller directly. A strong reference here creates a
    // retain cycle (tab bar controller -> child view controller -> tab bar controller)
    // and the whole FlatDesign tab tree is never deallocated after it is popped (#661).
    UIViewController *tabBarController_ = tabBarController;
    [self cyl_setWeakAssociatedObject:tabBarController_ forKey:@selector(cylflatdesign_tabBarController)];
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return;
    }
    if (referenceViewController.cyl_getViewControllerInsteadOfNavigationController) {
        [referenceViewController.cyl_getViewControllerInsteadOfNavigationController cyl_setWeakAssociatedObject:tabBarController_ forKey:@selector(cylflatdesign_tabBarController)];
    }
    
    /*!
     *     if ((![tabBarController isKindOfClass:[CYLFlatDesignUIViewController class]]) && (![tabBarController.cyl_getViewControllerInsteadOfNavigationController isKindOfClass:[CYLFlatDesignUIViewController class]]))  {
     return;
     }
     CYLFlatDesignUIViewController *flatDesignTabViewController = nil;
     if ([tabBarController isKindOfClass:[CYLFlatDesignUIViewController class]]) {
     flatDesignTabViewController = (CYLFlatDesignUIViewController *)tabBarController;
     } else if ([tabBarController.cyl_getViewControllerInsteadOfNavigationController isKindOfClass:[CYLFlatDesignUIViewController class]]) {
     flatDesignTabViewController = (CYLFlatDesignUIViewController *)tabBarController.cyl_getViewControllerInsteadOfNavigationController;
     }
     [flatDesignTabViewController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull childViewController, NSUInteger idx, BOOL * _Nonnull stop) {
     objc_setAssociatedObject(childViewController, @selector(cylflatdesign_tabBarController), tabBarController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
     objc_setAssociatedObject(childViewController.cyl_getViewControllerInsteadOfNavigationController, @selector(cylflatdesign_tabBarController), tabBarController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
     }];
     *
     */
}


/*!
 * [EN] Flat design. The same lookup as `-cyl_tabBarController`, `-cyl_tabBarControllerForStyleType:` with
 *      `CYLTabBarStyleTypeFlatDesign`, with two differences kept from before: an explicit reference
 *      (`-cylflatdesign_setTabBarController:`) is returned as it is, and there is no fallback: nil when the object is not
 *      inside a flat design tab bar controller (callers use that to tell whether they are).
 * [CN] 扁平样式。与 `-cyl_tabBarController` 使用同一个查找（`-cyl_tabBarControllerForStyleType:`，传 `CYLTabBarStyleTypeFlatDesign`），
 *      保留以前的两点不同：显式设置的引用（`-cylflatdesign_setTabBarController:`）原样返回；没有回退：对象不在扁平样式的
 *      TabBarController 内时返回 nil（调用方依此判断是否在其中）。
 */
- (UIViewController __kindof *)cylflatdesign_tabBarController {
    UIViewController *viewController = [self cyl_weakAssociatedObjectForKey:@selector(cylflatdesign_tabBarController)];
    if (viewController) {
        return viewController;
    }
    return [self cyl_tabBarControllerMatching:CYLTabBarControllerMatcherForStyleType(CYLTabBarStyleTypeFlatDesign) fallsBackToActive:NO];
}


/*!
 * - (CYLFlatDesignUIViewController *)cyl_nearestParentViewControllerThatIsKindOf:(Class)c {
 UIViewController *controller = self.parentViewController;
 while (controller && ![controller isKindOfClass:c]) {
 controller = controller.parentViewController;
 }
 if (controller && [controller isKindOfClass:c]) {
 return (CYLFlatDesignUIViewController *)controller;
 }
 return nil;
 }
 */
- (UIViewController __kindof *)cyl_nearestParentViewControllerThatIsKindOf:(Class)c {
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return nil;
    }
    UIViewController *controller = referenceViewController.parentViewController;
    while (controller && ![controller isKindOfClass:c]) {
        controller = controller.parentViewController;
    }
    
    if (controller && [controller isKindOfClass:c]) {
        return (UIViewController *)controller;
    }
    return nil;
}
#endif

@end

#pragma mark - CYLLogin (issue #19)

static NSString *const CYLTabBarLoggedInUserDefaultsKey = @"CYLTabBarControllerLoggedIn";
static char CYLLoginStateProviderKey;
static char CYLLoginRequiredTabBarItemIdentifiersKey;
static char CYLLoginRequiredBlockKey;
static char CYLLoginHandlerKey;
static char CYLLoginInterceptedViewControllerKey;

@implementation CYLTabBarController (CYLLogin)

- (BOOL)cyl_loggedIn {
    BOOL (^loginStateProvider)(void) = self.cyl_loginStateProvider;
    if (loginStateProvider) {
        return loginStateProvider();
    }
    return [[NSUserDefaults standardUserDefaults] boolForKey:CYLTabBarLoggedInUserDefaultsKey];
}

- (void)cyl_setLoggedIn:(BOOL)loggedIn {
    [[NSUserDefaults standardUserDefaults] setBool:loggedIn forKey:CYLTabBarLoggedInUserDefaultsKey];
    if (!loggedIn) {
        [self cyl_leaveTabRequiringLoginIfNeeded];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:CYLTabBarLoginStateDidChangeNotification object:self];
}

- (BOOL (^)(void))cyl_loginStateProvider {
    return objc_getAssociatedObject(self, &CYLLoginStateProviderKey);
}

- (void)cyl_setLoginStateProvider:(BOOL (^)(void))loginStateProvider {
    objc_setAssociatedObject(self, &CYLLoginStateProviderKey, loginStateProvider, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSArray<NSString *> *)cyl_loginRequiredTabBarItemIdentifiers {
    return objc_getAssociatedObject(self, &CYLLoginRequiredTabBarItemIdentifiersKey);
}

- (void)cyl_setLoginRequiredTabBarItemIdentifiers:(NSArray<NSString *> *)loginRequiredTabBarItemIdentifiers {
    objc_setAssociatedObject(self, &CYLLoginRequiredTabBarItemIdentifiersKey, loginRequiredTabBarItemIdentifiers, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(CYLTabBarController *, UIViewController *))cyl_loginRequiredBlock {
    return objc_getAssociatedObject(self, &CYLLoginRequiredBlockKey);
}

- (void)cyl_setLoginRequiredBlock:(BOOL (^)(CYLTabBarController *, UIViewController *))loginRequiredBlock {
    objc_setAssociatedObject(self, &CYLLoginRequiredBlockKey, loginRequiredBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CYLTabBarController *, UIViewController *, CYLTabBarLoginCompletion))cyl_loginHandler {
    return objc_getAssociatedObject(self, &CYLLoginHandlerKey);
}

- (void)cyl_setLoginHandler:(void (^)(CYLTabBarController *, UIViewController *, CYLTabBarLoginCompletion))loginHandler {
    objc_setAssociatedObject(self, &CYLLoginHandlerKey, loginHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)cyl_isLoginRequiredForViewController:(UIViewController *)viewController {
    if (!viewController || viewController.cyl_isPlaceholder) {
        return NO;
    }
    BOOL (^loginRequiredBlock)(CYLTabBarController *, UIViewController *) = self.cyl_loginRequiredBlock;
    if (loginRequiredBlock) {
        return loginRequiredBlock(self, viewController);
    }
    id<CYLTabBarControllerDelegate> delegate = (id<CYLTabBarControllerDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:requiresLoginToSelectViewController:)]) {
        return [delegate tabBarController:self requiresLoginToSelectViewController:viewController];
    }
    NSArray<NSString *> *identifiers = self.cyl_loginRequiredTabBarItemIdentifiers;
    NSString *identifier = viewController.cyl_tabBarItemIdentifier;
    return identifier.length > 0 && [identifiers containsObject:identifier];
}

- (BOOL)cyl_interceptLoginIfNeededForViewController:(UIViewController *)viewController {
    if (![self cyl_isLoginRequiredForViewController:viewController] || self.cyl_loggedIn) {
        return NO;
    }
    // One tap reaches here up to twice (`-tabBarController:shouldSelectViewController:`, then the tab button's action):
    // start the login only once per run loop turn. 一次点击最多到达这里两次：每个 runloop 只发起一次登录。
    if (objc_getAssociatedObject(self, &CYLLoginInterceptedViewControllerKey) == viewController) {
        return YES;
    }
    objc_setAssociatedObject(self, &CYLLoginInterceptedViewControllerKey, viewController, OBJC_ASSOCIATION_ASSIGN);
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            objc_setAssociatedObject(strongSelf, &CYLLoginInterceptedViewControllerKey, nil, OBJC_ASSOCIATION_ASSIGN);
        }
    });
    [self cyl_startLoginForViewController:viewController];
    return YES;
}

- (void)cyl_startLoginForViewController:(UIViewController *)viewController {
    __weak __typeof(self) weakSelf = self;
    __weak UIViewController *weakViewController = viewController;
    __block BOOL completed = NO;
    CYLTabBarLoginCompletion completion = ^(BOOL loggedIn) {
        void (^finish)(void) = ^{
            // Only the first call counts. 只有第一次调用有效。
            if (completed) {
                return;
            }
            completed = YES;
            __strong __typeof(weakSelf) strongSelf = weakSelf;
            UIViewController *strongViewController = weakViewController;
            if (!strongSelf || !loggedIn) {
                return;
            }
            strongSelf.cyl_loggedIn = YES;
            NSUInteger index = strongViewController ? [strongSelf.viewControllers indexOfObject:strongViewController] : NSNotFound;
            if (index != NSNotFound) {
                strongSelf.selectedIndex = index;
            }
        };
        if ([NSThread isMainThread]) {
            finish();
        } else {
            dispatch_async(dispatch_get_main_queue(), finish);
        }
    };
    void (^loginHandler)(CYLTabBarController *, UIViewController *, CYLTabBarLoginCompletion) = self.cyl_loginHandler;
    if (loginHandler) {
        loginHandler(self, viewController, completion);
        return;
    }
    id<CYLTabBarControllerDelegate> delegate = (id<CYLTabBarControllerDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:presentLoginForViewController:completion:)]) {
        [delegate tabBarController:self presentLoginForViewController:viewController completion:completion];
        return;
    }
#if defined(DEBUG) || defined(BETA)
    NSLog(CYLLocalizedString(@"🔴类名与方法名：%@（在第%@行）, 描述：%@"), @(__PRETTY_FUNCTION__), @(__LINE__), CYLLocalizedString(@"需要登录的 Tab 被点击，但没有设置 cyl_loginHandler 或代理方法 -tabBarController:presentLoginForViewController:completion:。"));
#endif
}

/// Logged out on a tab that needs login: select the first tab that does not. 在需要登录的 Tab 上退出登录：切换到第一个不需要登录的 Tab。
- (void)cyl_leaveTabRequiringLoginIfNeeded {
    UIViewController *selectedViewController = self.selectedViewController;
    if (!selectedViewController || ![self cyl_isLoginRequiredForViewController:selectedViewController]) {
        return;
    }
    NSArray<UIViewController *> *viewControllers = self.viewControllers;
    for (NSUInteger index = 0; index < viewControllers.count; index++) {
        UIViewController *viewController = viewControllers[index];
        if (!viewController.cyl_isPlaceholder && ![self cyl_isLoginRequiredForViewController:viewController]) {
            self.selectedIndex = index;
            return;
        }
    }
}

@end

#pragma mark - Tab bar item gestures (issue #152)

static char CYLTabBarItemGestureHandlerKey;
static char CYLTabBarItemDoubleTapIntervalKey;
static char CYLTabBarItemGestureStateKey;

/*!
 * [EN] What the gesture recognition remembers between taps: the last tapped control and when, the view controller that
 *      was selected after the previous tap, and whether this run loop turn already reported a control (programmatic
 *      selection can report the same control twice in one turn; that is not a second tap).
 * [CN] 手势识别在两次点击之间记录的信息：上次点击的控件与时间、上次点击后选中的控制器，以及当前 runloop 是否已上报过控件
 *      （代码切换时同一 runloop 内可能上报同一控件两次，这不是第二次点击）。
 */
@interface CYLTabBarItemGestureState : NSObject
@property (nonatomic, weak, nullable) UIControl *lastControl;
@property (nonatomic, assign) CFTimeInterval lastTapTime;
@property (nonatomic, weak, nullable) UIViewController *selectedViewControllerBeforeTap;
@property (nonatomic, weak, nullable) UIControl *controlReportedInCurrentRunLoop;
/// [EN] YES once a tab tap came through `-cyl_recognizeTabBarItemTapWillSelectViewController:`.
/// [CN] 一旦有 Tab 点击经过 `-cyl_recognizeTabBarItemTapWillSelectViewController:` 即为 YES。
@property (nonatomic, assign) BOOL receivesTabTapsBeforeSelection;
@end

@implementation CYLTabBarItemGestureState
@end

@implementation CYLTabBarController (CYLTabBarItemGesture)

- (CYLTabBarItemGestureHandler)cyl_tabBarItemGestureHandler {
    return objc_getAssociatedObject(self, &CYLTabBarItemGestureHandlerKey);
}

- (void)cyl_setTabBarItemGestureHandler:(CYLTabBarItemGestureHandler)tabBarItemGestureHandler {
    objc_setAssociatedObject(self, &CYLTabBarItemGestureHandlerKey, tabBarItemGestureHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
    if (self.isViewLoaded) {
        [self cyl_installTabBarItemLongPressIfNeeded];
    }
}

- (NSTimeInterval)cyl_tabBarItemDoubleTapInterval {
    NSNumber *value = objc_getAssociatedObject(self, &CYLTabBarItemDoubleTapIntervalKey);
    return value ? value.doubleValue : 0.35;
}

- (void)cyl_setTabBarItemDoubleTapInterval:(NSTimeInterval)tabBarItemDoubleTapInterval {
    objc_setAssociatedObject(self, &CYLTabBarItemDoubleTapIntervalKey, @(MAX(tabBarItemDoubleTapInterval, 0)), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*!
 * [EN] The same duration as `cyl_tabButtonLongPressMinimumDuration` (issue #535): one recognizer serves both long press
 *      APIs, see `CYLTabBarController+CYLInteraction.m`.
 * [CN] 与 `cyl_tabButtonLongPressMinimumDuration`（issue #535）是同一个时长：两套长按 API 共用一个手势，见
 *      `CYLTabBarController+CYLInteraction.m`。
 */
- (NSTimeInterval)cyl_tabBarItemLongPressDuration {
    return self.cyl_tabButtonLongPressMinimumDuration;
}

- (void)cyl_setTabBarItemLongPressDuration:(NSTimeInterval)tabBarItemLongPressDuration {
    self.cyl_tabButtonLongPressMinimumDuration = tabBarItemLongPressDuration;
}

- (CYLTabBarItemGestureState *)cyl_tabBarItemGestureState {
    CYLTabBarItemGestureState *state = objc_getAssociatedObject(self, &CYLTabBarItemGestureStateKey);
    if (!state) {
        state = [[CYLTabBarItemGestureState alloc] init];
        state.selectedViewControllerBeforeTap = self.selectedViewController;
        objc_setAssociatedObject(self, &CYLTabBarItemGestureStateKey, state, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return state;
}

- (BOOL)cyl_hasTabBarItemGestureReceiver {
    // [EN] `cyl_reselectBehavior` (CYLReselect) is driven by the Reselect gesture too.
    // [CN] `cyl_reselectBehavior`（CYLReselect）同样由 Reselect 手势驱动。
    return self.cyl_tabBarItemGestureHandler != nil || self.cyl_reselectBehavior != CYLTabBarReselectBehaviorNone ||
        [self.delegate respondsToSelector:@selector(tabBarController:didRecognizeTabBarItemGesture:control:viewController:)];
}

/*!
 * [EN] Taps are recognized for the gesture receivers above, and also for a tab item's `-[UITabBarItem cyl_doubleTapBlock]`.
 *      The long press keeps `-cyl_hasTabBarItemGestureReceiver`, so its recognizer is added only when someone listens.
 * [CN] 除上面的手势接收方外，Tab item 的 `-[UITabBarItem cyl_doubleTapBlock]` 也需要识别点击。长按仍使用
 *      `-cyl_hasTabBarItemGestureReceiver`，因此只有存在接收方时才添加长按手势。
 */
- (BOOL)cyl_hasTabBarItemTapReceiver {
    if ([self cyl_hasTabBarItemGestureReceiver]) {
        return YES;
    }
    for (UIViewController *viewController in self.viewControllers) {
        if ([self cyl_doubleTapBlockForViewController:viewController]) {
            return YES;
        }
    }
    return NO;
}

/// [EN] The double tap block of a tab: its item's, else its root view controller's item's. [CN] Tab 的双击 block：其 item 的，否则为根控制器 item 的。
- (nullable void (^)(UITabBarItem *, NSInteger))cyl_doubleTapBlockForViewController:(nullable UIViewController *)viewController {
    if (!viewController) {
        return nil;
    }
    return viewController.tabBarItem.cyl_doubleTapBlock ?: [viewController cyl_getViewControllerInsteadOfNavigationController].tabBarItem.cyl_doubleTapBlock;
}

/*!
 * [EN] YES when `control` is one of this controller's tab buttons, or its plus button; `viewController` is then the tab's
 *      view controller (the plus child view controller for the plus button, nil without one).
 * [CN] `control` 为本控制器的 Tab 按钮或 PlusButton 时返回 YES；此时 `viewController` 为对应 Tab 的控制器（PlusButton 为其子控制器，
 *      没有子控制器时为 nil）。
 */
- (BOOL)cyl_isTabBarItemGestureControl:(UIControl *)control viewController:(UIViewController *__autoreleasing _Nullable *_Nullable)viewController {
    if (!control) {
        return NO;
    }
    // Guard: the plus button only when there is one. 仅在有 PlusButton 时处理 PlusButton。
    if ([self hasPlusButton] && [control cyl_isPlusButton]) {
        if (viewController) {
            // Guard: the child view controller only when there is one. 仅在有子控制器时取子控制器。
            *viewController = [self hasPlusChildViewController] ? [CYLPlusButton plusChildViewControllerForOwner:self] : nil;
        }
        return YES;
    }
    for (UIViewController *eachViewController in self.viewControllers) {
        if (eachViewController.cyl_isPlaceholder) {
            continue;
        }
        if (eachViewController.tabBarItem.cyl_tabButton == control || eachViewController.cyl_tabButton == control) {
            if (viewController) {
                *viewController = eachViewController;
            }
            return YES;
        }
    }
    return NO;
}

- (void)cyl_reportTabBarItemGesture:(CYLTabBarItemGesture)gesture control:(UIControl *)control viewController:(nullable UIViewController *)viewController {
    // [EN] The built-in reselect behavior (CYLReselect) runs first, then the callbacks.
    // [CN] 先执行内置的重复点击操作（CYLReselect），再回调。
    if (gesture == CYLTabBarItemGestureReselect && viewController) {
        [self cyl_performReselectBehaviorForViewController:viewController];
    }
    CYLTabBarItemGestureHandler handler = self.cyl_tabBarItemGestureHandler;
    if (handler) {
        handler(self, gesture, control, viewController);
    }
    id<CYLTabBarControllerDelegate> delegate = (id<CYLTabBarControllerDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:didRecognizeTabBarItemGesture:control:viewController:)]) {
        [delegate tabBarController:self didRecognizeTabBarItemGesture:gesture control:control viewController:viewController];
    }
    // [EN] The tab's own double tap block, after the handler and the delegate. [CN] Tab 自己的双击 block，在 handler 与代理之后。
    if (CYLTabBarItemGestureDoubleTap == gesture) {
        void (^doubleTapBlock)(UITabBarItem *, NSInteger) = [self cyl_doubleTapBlockForViewController:viewController];
        NSUInteger index = viewController ? [self.viewControllers indexOfObject:viewController] : NSNotFound;
        if (doubleTapBlock && index != NSNotFound) {
            doubleTapBlock(viewController.tabBarItem, (NSInteger)index);
        }
    }
}

- (void)cyl_recognizeTabBarItemGestureForReportedControl:(UIControl *)control {
    if (![self cyl_hasTabBarItemTapReceiver]) {
        return;
    }
    // [EN] A CYLPlusButton counts its own taps (`-cyl_recognizePlusButtonTap:…`), tab buttons count before the selection
    //      (`-cyl_recognizeTabBarItemTapWillSelectViewController:`) once that is reached. The reports remain the source
    //      for a plus button that is not a CYLPlusButton, and for tab buttons when `shouldSelectViewController` is not reached.
    // [CN] CYLPlusButton 自己计数（`-cyl_recognizePlusButtonTap:…`）；Tab 按钮在执行到 `-cyl_recognizeTabBarItemTapWillSelectViewController:`
    //      后改为在选中之前计数。不是 CYLPlusButton 的 PlusButton，以及未执行到 `shouldSelectViewController` 时的 Tab 按钮，仍使用上报。
    if ([control isKindOfClass:[CYLPlusButton class]]) {
        return;
    }
    UIViewController *viewController = nil;
    if (![self cyl_isTabBarItemGestureControl:control viewController:&viewController]) {
        return;
    }
    CYLTabBarItemGestureState *state = [self cyl_tabBarItemGestureState];
    BOOL isPlusButton = [self hasPlusButton] && [control cyl_isPlusButton];
    if (!isPlusButton && state.receivesTabTapsBeforeSelection) {
        return;
    }
    BOOL isReselect = viewController && (viewController == state.selectedViewControllerBeforeTap);
    [self cyl_recognizeTabBarItemTapOnControl:control viewController:viewController isReselect:isReselect];
    // After the selection settles (FlatDesign reports before selecting; a tab needing login may refuse it).
    // 选中状态确定后再记录（扁平样式在选中之前上报；需要登录的 Tab 可能拒绝选中）。
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            [strongSelf cyl_tabBarItemGestureState].selectedViewControllerBeforeTap = strongSelf.selectedViewController;
        }
    });
}

/*!
 * FIX: issue #152 — the unified entry for taps on tab buttons, in every style.
 * [EN] A user tap on a tab button is about to select `viewController`. Called from `-tabBarController:shouldSelectViewController:`
 *      (classic and Liquid Glass: UIKit asks it once per user tap, for a new tab and for the selected tab alike, before
 *      the selection changes, and never for a selection made in code) and from `-_cyltabBarItemClicked:` (FlatDesign).
 *      So every tab tap is timed at the same moment and Reselect is simply "it is already selected", without the Liquid
 *      Glass touch-down / lift split of the `didSelectControl` reports. Once this is called, those reports are no longer
 *      used for tab buttons; they stay the source for tab bar controllers whose
 *      `-tabBarController:shouldSelectViewController:` is not reached (another delegate object, or a subclass override
 *      that does not call super).
 * [CN] 用户点击 Tab 按钮、即将选中 `viewController`。由 `-tabBarController:shouldSelectViewController:`（经典与液态玻璃：UIKit 对每次
 *      用户点击询问一次，无论是新 Tab 还是已选中的 Tab，都在选中变化之前，代码切换时不会询问）和 `-_cyltabBarItemClicked:`（扁平样式）调用。
 *      因此每次 Tab 点击都在同一时刻计时，Reselect 就是"已经选中"，不再受 `didSelectControl` 上报在液态玻璃下"按下 / 抬起"两个时刻的影响。
 *      一旦调用过本方法，Tab 按钮不再使用这些上报（PlusButton 通过 `-cyl_recognizePlusButtonTap:…` 进入同一入口）；未执行到 `-tabBarController:shouldSelectViewController:` 的
 *      TabBarController（代理是其他对象，或子类重写时未调用 super）也仍使用上报。
 */
- (void)cyl_recognizeTabBarItemTapWillSelectViewController:(UIViewController *)viewController {
    if (![self cyl_hasTabBarItemTapReceiver] || !viewController || viewController.cyl_isPlaceholder) {
        return;
    }
    UIControl *control = nil;
    // Guard: the plus child view controller, selected from the tab button under the plus button: a tap on the plus button.
    // PlusButton 子控制器（点击 PlusButton 下方的 Tab 按钮选中）：算作点击 PlusButton。
    if ([self hasPlusButton] && [self hasPlusChildViewController] &&
        viewController == [CYLPlusButton plusChildViewControllerForOwner:self]) {
        control = [CYLPlusButton plusButtonForOwner:self];
    } else {
        control = viewController.tabBarItem.cyl_tabButton ?: viewController.cyl_tabButton;
    }
    if (!control) {
        return;
    }
    // [EN] Liquid Glass: tab taps are counted when UIKit's own gesture ends (`-cyl_recognizeLiquidGlassTapOnControl:…`),
    //      which knows whether the press was a tap, a long press or a drag. The plus child view controller is still counted
    //      here, as before.
    // [CN] 液态玻璃：Tab 的点击在系统手势结束时计数（`-cyl_recognizeLiquidGlassTapOnControl:…`），那里知道这次是点击、长按还是拖动。
    //      PlusButton 子控制器仍和以前一样在这里计数。
    if (![control cyl_isPlusButton] && [self cyl_liquidGlassTakesTabTaps]) {
        return;
    }
    CYLTabBarItemGestureState *state = [self cyl_tabBarItemGestureState];
    BOOL isFirstTapFromHere = !state.receivesTabTapsBeforeSelection;
    state.receivesTabTapsBeforeSelection = YES;
    // The switch from the reports: in Liquid Glass a tap on the selected tab is reported on touch down, before UIKit asks
    // here on lift. The first time, that report was already counted; do not count the same tap again.
    // 从上报切换过来时：液态玻璃下点击已选中的 Tab 在手指按下时上报，UIKit 在抬起时才询问这里。第一次时该上报已计数，不再重复计数。
    if (isFirstTapFromHere && state.lastControl == control && (CACurrentMediaTime() - state.lastTapTime) < 1.0) {
        return;
    }
    BOOL isReselect = (viewController == self.selectedViewController);
    [self cyl_recognizeTabBarItemTapOnControl:control viewController:viewController isReselect:isReselect];
}

/*!
 * FIX: issue #152 — taps on the plus button, through the same entry as the tab buttons.
 * [EN] Called by a CYLPlusButton on `UIControlEventTouchUpInside`, in every style, with and without a child view
 *      controller: the moment a tap completes, like UIKit asking `shouldSelectViewController` for a tab. The plus button's
 *      own path differs per style (`-plusChildViewControllerButtonClicked:` → `-setSelectedIndex:`, the tab control action,
 *      `-gestureRecognizerShouldBegin:` on touch down in Liquid Glass, `-cyl_flatDesignPlusButtonTouchUpInside:`), so it is
 *      not used for the gestures. `selectedViewController` is what was selected on touch down (the child view controller
 *      may already be selected by the time this runs); nil when there was no touch down (actions sent by code).
 * [CN] CYLPlusButton 在 `UIControlEventTouchUpInside` 时调用，适用于所有样式，有无子控制器均可：即一次点击完成的时刻，与 UIKit 为 Tab
 *      询问 `shouldSelectViewController` 的时刻一致。PlusButton 自身的处理路径因样式而异（`-plusChildViewControllerButtonClicked:` →
 *      `-setSelectedIndex:`、Tab 按钮事件、液态玻璃下手指按下时的 `-gestureRecognizerShouldBegin:`、`-cyl_flatDesignPlusButtonTouchUpInside:`），
 *      因此手势不使用它们。`selectedViewController` 为手指按下时选中的控制器（执行到这里时子控制器可能已被选中）；没有按下（代码发送的事件）时为 nil。
 */
/*!
 * FIX: issue #152 — taps on tab buttons in Liquid Glass.
 * [EN] Called by `-cyl_liquidGlassTabBarGestureRecognizerDidUpdate:` (CYLTabBarController+CYLInteraction.m) when UIKit's
 *      Liquid Glass gesture ends where it began, without a long press: one tap. `selectedViewController` is what was
 *      selected on touch down, so a tap on the selected tab is a Reselect even if UIKit already selected it on touch down.
 *      From then on the `didSelectControl` reports are not counted for tab buttons, as for the shouldSelect entry.
 * [CN] 系统液态玻璃手势在按下的位置结束、且不是长按时，由 `-cyl_liquidGlassTabBarGestureRecognizerDidUpdate:`
 *      （CYLTabBarController+CYLInteraction.m）调用：一次点击。`selectedViewController` 为手指按下时选中的控制器，因此点击已选中的 Tab
 *      时，即使系统在按下时已选中它，也算 Reselect。此后与 shouldSelect 入口一样，Tab 按钮不再使用 `didSelectControl` 上报计数。
 */
- (void)cyl_recognizeLiquidGlassTapOnControl:(UIControl *)control selectedViewControllerAtTouchDown:(UIViewController *)selectedViewController {
    if (![self cyl_hasTabBarItemTapReceiver]) {
        return;
    }
    UIViewController *viewController = nil;
    if (![self cyl_isTabBarItemGestureControl:control viewController:&viewController]) {
        return;
    }
    [self cyl_tabBarItemGestureState].receivesTabTapsBeforeSelection = YES;
    BOOL isReselect = viewController && (viewController == selectedViewController);
    [self cyl_recognizeTabBarItemTapOnControl:control viewController:viewController isReselect:isReselect];
}

- (void)cyl_recognizePlusButtonTap:(UIControl *)plusButton selectedViewControllerAtTouchDown:(UIViewController *)selectedViewController {
    // Guard: only with a plus button. 仅在有 PlusButton 时处理。
    if (![self cyl_hasTabBarItemTapReceiver] || ![self hasPlusButton]) {
        return;
    }
    UIViewController *viewController = nil;
    if (![self cyl_isTabBarItemGestureControl:plusButton viewController:&viewController]) {
        return;
    }
    BOOL isReselect = viewController && (viewController == selectedViewController);
    [self cyl_recognizeTabBarItemTapOnControl:plusButton viewController:viewController isReselect:isReselect];
}

/*!
 * [EN] The core of the unified entry: one tap on a tab button or the plus button. Several calls for the same control in
 *      one run loop turn are one tap.
 * [CN] 统一入口的核心：Tab 按钮或 PlusButton 的一次点击。同一 runloop 内对同一控件的多次调用算一次点击。
 */
- (void)cyl_recognizeTabBarItemTapOnControl:(UIControl *)control viewController:(UIViewController *)viewController isReselect:(BOOL)isReselect {
    CYLTabBarItemGestureState *state = [self cyl_tabBarItemGestureState];
    if (state.controlReportedInCurrentRunLoop == control) {
        return;
    }
    state.controlReportedInCurrentRunLoop = control;
    [self cyl_recognizeTapOnControl:control viewController:viewController isReselect:isReselect];
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf cyl_tabBarItemGestureState].controlReportedInCurrentRunLoop = nil;
    });
}

/// [EN] Reports Reselect and DoubleTap for one tap. [CN] 为一次点击上报 Reselect 与 DoubleTap。
- (void)cyl_recognizeTapOnControl:(UIControl *)control viewController:(UIViewController *)viewController isReselect:(BOOL)isReselect {
    CYLTabBarItemGestureState *state = [self cyl_tabBarItemGestureState];
    CFTimeInterval now = CACurrentMediaTime();
    BOOL isDoubleTap = (state.lastControl == control) && (now - state.lastTapTime) <= self.cyl_tabBarItemDoubleTapInterval;
    // A third tap starts a new pair instead of making a second DoubleTap. 第三次点击重新开始计数，而不是再算一次 DoubleTap。
    state.lastControl = control;
    state.lastTapTime = isDoubleTap ? 0 : now;
    if (isReselect) {
        [self cyl_reportTabBarItemGesture:CYLTabBarItemGestureReselect control:control viewController:viewController];
    }
    if (isDoubleTap) {
        [self cyl_reportTabBarItemGesture:CYLTabBarItemGestureDoubleTap control:control viewController:viewController];
    }
}

- (void)cyl_installTabBarItemLongPressIfNeeded {
    if (![self cyl_hasTabBarItemGestureReceiver] || !self.isViewLoaded) {
        return;
    }
    // Remember what is selected before the first tap. 记录第一次点击之前选中的控制器。
    [self cyl_tabBarItemGestureState];
    // [EN] The long press recognizer is shared with issue #535 (`CYLTabBarController+CYLInteraction.m`).
    // [CN] 长按手势与 issue #535 共用（`CYLTabBarController+CYLInteraction.m`）。
    [self cyl_installInteractionGestureRecognizersIfNeeded];
}

@end

#pragma mark - CYLTabBarMinimize (issue #13)

// [EN] Minimize or hide the tab bar on scroll (issue #13). One API, three isolated paths, chosen by
//      `CYLTabBarMinimizeModeForTabBarController()`; each path is behind its own guard:
//      - FlatDesign (`#if CYL_FLATDESIGN_AVAILABLE`, FlatDesign style only): the selected page's scroll view is observed
//        and the flat tab bar is hidden and shown with `-setTabBarHidden:animated:`.
//      - Liquid Glass (iOS 26+ SDK and system, `+[CYLConstants isLiquidGlassActive]`): the native
//        `UITabBarController.tabBarMinimizeBehavior`; the scroll view is observed only to keep the plus button centered
//        while the system minimizes the bar (`-[CYLTabBar plusButtonIndex]`, as PR #728 does for the vertical bar).
//      - Classic (not FlatDesign, Liquid Glass not active: iOS 25 and earlier, and iOS 26 in UI compatibility mode): the
//        system tab bar (with its plus button) is hidden and shown while the page scrolls.
//      FlatDesign and classic hide the bar through the same public `-setTabBarHidden:animated:`; only their guards differ.
//      See docs/TabBar-Minimize-On-Scroll.md.
// [CN] 滚动时缩小或隐藏 TabBar（issue #13）。一个接口，三条相互隔离的路径，由 `CYLTabBarMinimizeModeForTabBarController()` 选择，
//      每条路径都在各自的 guard 之后：
//      - 扁平样式（`#if CYL_FLATDESIGN_AVAILABLE`，仅扁平样式）：观察选中页面的滚动视图，用 `-setTabBarHidden:animated:` 隐藏、显示
//        扁平 TabBar。
//      - 液态玻璃（iOS 26+ SDK 与系统，`+[CYLConstants isLiquidGlassActive]`）：使用系统原生的
//        `UITabBarController.tabBarMinimizeBehavior`；观察滚动视图只为在系统缩小 TabBar 时让 PlusButton 保持居中
//        （`-[CYLTabBar plusButtonIndex]`，与 PR #728 对竖向栏的处理相同）。
//      - 经典样式（非扁平样式且液态玻璃未启用：iOS 25 及以前，以及 iOS 26 的 UI 兼容模式）：页面滚动时，隐藏、显示系统 TabBar
//        （连同 PlusButton）。
//      扁平样式与经典样式都通过同一个公开接口 `-setTabBarHidden:animated:` 隐藏 TabBar，只是各自的 guard 不同。
//      见 docs/TabBar-Minimize-On-Scroll.md。

static const void *CYLTabBarMinimizeBehaviorKey = &CYLTabBarMinimizeBehaviorKey;
static const void *CYLTabBarMinimizeScrollTrackerKey = &CYLTabBarMinimizeScrollTrackerKey;
static void *CYLTabBarMinimizeContentOffsetContext = &CYLTabBarMinimizeContentOffsetContext;

/// [EN] Implemented in CYLTabBar.m (issue #13). [CN] 实现见 CYLTabBar.m（issue #13）。
@interface CYLTabBar (CYLTabBarMinimizeLayout)
- (BOOL)cyl_showsMinimizedBar;
@end

/// [EN] Distance (pt) to scroll in one direction before the tab bar hides or shows, so small movements do not flicker it.
/// [CN] 同一方向滚动超过该距离（pt）才隐藏或显示 TabBar，避免小幅滚动时闪动。
static const CGFloat CYLTabBarMinimizeScrollDistance = 12.0;
/// [EN] Content that scrolls less than this (pt) never hides the tab bar: hiding it would change the content's size.
/// [CN] 可滚动距离小于该值（pt）的内容不隐藏 TabBar：隐藏 TabBar 本身就会改变内容的可滚动范围。
static const CGFloat CYLTabBarMinimizeMinimumScrollableDistance = 100.0;
/// [EN] Hysteresis: hiding needs this much scrollable distance (pt), more than the 100pt that keeps the bar hidden, because
///      hiding the bar itself makes the visible area taller (by about the bar's height) and the content shorter to scroll.
///      Without it, content just long enough would hide, become "too short", show, and hide again.
/// [CN] 滞回：隐藏需要的可滚动距离（pt）大于保持隐藏所需的 100pt，因为隐藏 TabBar 本身会让可见区域变高（约一个 TabBar 的高度），
///      内容可滚动的距离随之变短。否则刚好够长的内容会隐藏、变得“太短”、显示、再隐藏，反复闪动。
static const CGFloat CYLTabBarMinimizeHideMinimumScrollableDistance = 200.0;
/// [EN] Classic style: how often the page on screen is checked again (core has no push/pop hook outside FlatDesign).
/// [CN] 经典样式：重新确认当前页面的间隔（FlatDesign 以外，Core 中没有 push/pop 回调）。
static const NSTimeInterval CYLTabBarMinimizeClassicPageCheckInterval = 0.5;
/// [EN] While the tab bar is hidden or minimized by scrolling: how often the safety net checks whether it must come back
///      (a page change, an alert, the app or window losing focus), for anything no notification reports.
/// [CN] TabBar 被滚动隐藏或缩小期间：安全网检查是否需要恢复的间隔（页面变化、弹框、App 或窗口失去焦点），用于没有通知可监听的情况。
static const NSTimeInterval CYLTabBarMinimizeRestoreCheckInterval = 0.25;
/// [EN] As in the Facebook app, the tab bar hides only once the user has scrolled this far (pt) into the content, never
///      right at its start.
/// [CN] 与 Facebook App 一致，用户滚入内容超过该距离（pt）后才隐藏 TabBar，内容起始处不隐藏。
static const CGFloat CYLTabBarMinimizeHideStartDistance = 50.0;
/// [EN] How long a found scroll view is reused while the page on screen stays the same, before the view hierarchy is
///      searched again (the search runs on layouts and on the classic page check).
/// [CN] 当前页面不变时复用已找到的滚动视图的时长，之后才重新遍历视图层级（遍历发生在布局与经典样式的页面检查时）。
static const CFTimeInterval CYLTabBarMinimizeResolveCacheDuration = 2.0;
#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
/// [EN] Liquid Glass: when the forced expand is checked (the system's animation has ended by then).
/// [CN] 液态玻璃：检查强制恢复结果的时间（此时系统动画已结束）。
static const NSTimeInterval CYLTabBarMinimizeLiquidGlassExpandCheckDelay = 0.35;
static const void *CYLTabBarMinimizeHoldsSystemNeverKey = &CYLTabBarMinimizeHoldsSystemNeverKey;
#endif

/// [EN] Which path handles `cyl_tabBarMinimizeBehavior`. [CN] 由哪条路径处理 `cyl_tabBarMinimizeBehavior`。
typedef NS_ENUM(NSInteger, CYLTabBarMinimizeMode) {
    /// [EN] Nothing to track (Automatic, Never, or the view is not loaded). [CN] 无需跟踪（Automatic、Never，或视图尚未加载）。
    CYLTabBarMinimizeModeNone = 0,
    CYLTabBarMinimizeModeFlatDesign,
    CYLTabBarMinimizeModeLiquidGlass,
    CYLTabBarMinimizeModeClassic,
};

/// [EN] The path for a tab bar controller, decided by guards in order. Never loads the view.
/// [CN] 依次通过各个 guard 决定 TabBarController 使用的路径。不会触发视图加载。
static CYLTabBarMinimizeMode CYLTabBarMinimizeModeForTabBarController(CYLTabBarController *tabBarController) {
    CYLTabBarMinimizeBehavior behavior = tabBarController.cyl_tabBarMinimizeBehavior;
    // Guard: only the scroll behaviors are tracked. 只跟踪滚动相关的取值。
    if (CYLTabBarMinimizeBehaviorOnScrollDown != behavior && CYLTabBarMinimizeBehaviorOnScrollUp != behavior) {
        return CYLTabBarMinimizeModeNone;
    }
    // Guard: the `cyl_tabBar` getter sets the tab bar up, so wait for the view. `cyl_tabBar` 的 getter 会创建 TabBar，需等视图加载。
    if (!tabBarController.isViewLoaded) {
        return CYLTabBarMinimizeModeNone;
    }
    // Guard: FlatDesign. 扁平样式。
    if (CYLTabBarStyleTypeFlatDesign == tabBarController.tabBarStyleType) {
#if CYL_FLATDESIGN_AVAILABLE
        if ([tabBarController.cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
            return CYLTabBarMinimizeModeFlatDesign;
        }
#endif
        return CYLTabBarMinimizeModeNone;
    }
    // Guard: Liquid Glass. 液态玻璃。
    if ([CYLConstants isLiquidGlassActive]) {
        return [tabBarController.cyl_tabBar isKindOfClass:[CYLTabBar class]] ? CYLTabBarMinimizeModeLiquidGlass : CYLTabBarMinimizeModeNone;
    }
    // [EN] Everything else is the classic system tab bar: iOS 25 and earlier, and iOS 26 in UI compatibility mode.
    // [CN] 其余都是经典系统 TabBar：iOS 25 及以前，以及 iOS 26 的 UI 兼容模式。
    return CYLTabBarMinimizeModeClassic;
}

/// [EN] The page the user sees in a tab: the top page of a navigation controller.
/// [CN] 用户在 Tab 中看到的页面：导航控制器的栈顶页面。
static UIViewController *CYLTabBarMinimizeVisibleViewController(UIViewController *viewController) {
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        return ((UINavigationController *)viewController).topViewController;
    }
    return viewController;
}

/// [EN] The scroll view that drives the tab bar, chosen as UIKit does: the page's bottom content scroll view, otherwise the
///      first visible scroll view in its view hierarchy (breadth first). Never loads a view.
/// [CN] 控制 TabBar 的滚动视图，与 UIKit 的选择方式一致：页面底部的 content scroll view，没有时取其视图层级中第一个可见的滚动视图
///      （广度优先）。不会触发视图加载。
static UIScrollView *CYLTabBarMinimizeScrollViewForViewController(UIViewController *viewController) {
    UIViewController *visibleViewController = CYLTabBarMinimizeVisibleViewController(viewController);
    if (!visibleViewController.isViewLoaded) {
        return nil;
    }
    if (@available(iOS 15.0, *)) {
        UIScrollView *contentScrollView = [visibleViewController contentScrollViewForEdge:NSDirectionalRectEdgeBottom];
        if (contentScrollView) {
            return contentScrollView;
        }
    }
    // [EN] Breadth first, the first scroll view that scrolls vertically wins, so a list inside a horizontal pager (a
    //      paging scroll view, a page view controller) is chosen, not the pager; otherwise the first scroll view.
    // [CN] 广度优先，第一个可以竖向滚动的滚动视图优先，因此横向分页容器（分页滚动视图、page view controller）中的列表会被选中，
    //      而不是分页容器本身；没有时取第一个滚动视图。
    UIScrollView *firstScrollView = nil;
    NSMutableArray<UIView *> *views = [NSMutableArray arrayWithObject:visibleViewController.view];
    for (NSUInteger index = 0; index < views.count; index++) {
        UIView *view = views[index];
        if (view.hidden) {
            continue;
        }
        if ([view isKindOfClass:[UIScrollView class]] && ![view isKindOfClass:[UITextView class]]) {
            UIScrollView *scrollView = (UIScrollView *)view;
            BOOL scrollsVertically = scrollView.contentSize.height > CGRectGetHeight(scrollView.bounds) + 1.0;
            BOOL isHorizontalPager = scrollView.pagingEnabled && scrollView.contentSize.width > CGRectGetWidth(scrollView.bounds) + 1.0;
            if (scrollsVertically && !isHorizontalPager) {
                return scrollView;
            }
            if (!firstScrollView) {
                firstScrollView = scrollView;
            }
        }
        [views addObjectsFromArray:view.subviews];
    }
    return firstScrollView;
}

/// [EN] Classic style: whether the tab bar sits at the bottom of its superview (not, e.g., a tab bar shown at the top).
/// [CN] 经典样式：TabBar 是否位于父视图底部（例如排除显示在顶部的 TabBar）。
static BOOL CYLTabBarMinimizeClassicTabBarIsAtBottom(UITabBar *tabBar) {
    UIView *container = tabBar.superview;
    if (!container) {
        return NO;
    }
    CGFloat bottom = tabBar.center.y + CGRectGetHeight(tabBar.bounds) * 0.5;
    return bottom >= CGRectGetHeight(container.bounds) - 1.0;
}

/// [EN] Classic style: whether UIKit hides the tab bar for the page on screen (`hidesBottomBarWhenPushed` on a page pushed
///      above the root of the selected navigation controller), so the bar is UIKit's to move, not ours.
/// [CN] 经典样式：UIKit 是否因当前页面隐藏 TabBar（选中的导航控制器中，根页面之上被 push 的页面设置了 `hidesBottomBarWhenPushed`），
///      此时 TabBar 由 UIKit 移动，而不是由这里处理。
static BOOL CYLTabBarMinimizeClassicPageHidesTabBar(UIViewController *selectedViewController) {
    if (![selectedViewController isKindOfClass:[UINavigationController class]]) {
        return NO;
    }
    NSArray<UIViewController *> *viewControllers = ((UINavigationController *)selectedViewController).viewControllers;
    for (NSUInteger index = 1; index < viewControllers.count; index++) {
        if (viewControllers[index].hidesBottomBarWhenPushed) {
            return YES;
        }
    }
    return NO;
}

/*!
 * [EN] Whether `window` is the key window of its scene, and the scene is in the foreground and active. With several
 *      scenes (iPad multiple windows) the app-wide `isKeyWindow` and `applicationState` say nothing about this scene, so
 *      the scene's own `keyWindow` (iOS 15+) and `activationState` (iOS 13+) are used when available.
 * [CN] `window` 是否是其 Scene 的 key window，且该 Scene 在前台并处于活跃状态。存在多个 Scene（iPad 多窗口）时，App 级别的
 *      `isKeyWindow` 与 `applicationState` 不能说明本 Scene 的状态，因此在可用时使用 Scene 自己的 `keyWindow`（iOS 15+）与
 *      `activationState`（iOS 13+）。
 */
static BOOL CYLTabBarMinimizeWindowIsKeyAndActive(UIWindow *window) {
    if (!window) {
        return NO;
    }
    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = window.windowScene;
        if (windowScene) {
            if (UISceneActivationStateForegroundActive != windowScene.activationState) {
                return NO;
            }
            if (@available(iOS 15.0, *)) {
                return windowScene.keyWindow == window;
            }
            return window.isKeyWindow;
        }
    }
    return window.isKeyWindow && UIApplicationStateActive == [UIApplication sharedApplication].applicationState;
}

/*!
 * [EN] Opt-in diagnostics for device testing: set the environment variable `CYLTabBarMinimizeLog` (or its ALL_CAPS
 *      spelling `CYL_TAB_BAR_MINIMIZE_LOG`, for scripts) to `1` in the Xcode scheme to log every session start, every
 *      restore with its reason, and every takeover by the app. Off otherwise, also in debug builds.
 * [CN] 用于真机测试的可选诊断：在 Xcode scheme 中把环境变量 `CYLTabBarMinimizeLog`（或供脚本使用的全大写写法 `CYL_TAB_BAR_MINIMIZE_LOG`）
 *      设为 `1`，即可打印每次会话开始、每次恢复及其原因、以及每次 App 接管。其他情况下关闭，Debug 构建也不例外。
 */
static BOOL CYLTabBarMinimizeLogEnabled(void) {
    static BOOL enabled;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSDictionary<NSString *, NSString *> *environment = [NSProcessInfo processInfo].environment;
        enabled = [environment[@"CYLTabBarMinimizeLog"] boolValue] || [environment[@"CYL_TAB_BAR_MINIMIZE_LOG"] boolValue];
    });
    return enabled;
}

static void CYLTabBarMinimizeLog(NSString *event, NSString *reason) {
    if (CYLTabBarMinimizeLogEnabled()) {
        NSLog(@"[CYLTabBarController] scroll hiding: %@ (%@)", event, reason ?: @"-");
    }
}

/// [EN] Observes the scroll view of the page on screen and runs the path's action. See the section comment above.
/// [CN] 观察当前显示页面的滚动视图，并执行对应路径的处理。见上方说明。
@interface _CYLTabBarMinimizeScrollTracker : NSObject <UIGestureRecognizerDelegate>
@property (nonatomic, weak, readonly) CYLTabBarController *tabBarController;
@property (nonatomic, weak, readonly) UIScrollView *scrollView;
@property (nonatomic, assign, readonly) CYLTabBarMinimizeMode mode;
- (instancetype)initWithTabBarController:(CYLTabBarController *)tabBarController;
- (void)updateMode:(CYLTabBarMinimizeMode)mode;
- (void)observeScrollView:(UIScrollView *)scrollView;
- (void)expandTabBar;
- (void)restoreTabBar;
- (void)restoreTabBarForReason:(NSString *)reason;
- (BOOL)isTabBarHiddenOrMinimizedByScroll;
- (BOOL)simulateHideForTesting;
- (void)observeTapsInView:(UIView *)view;
- (UIScrollView *)scrollViewForSelectedViewController:(UIViewController *)selectedViewController;
- (void)validateHideSession;
- (void)appDidRequestTabBarHidden:(BOOL)hidden;
@end

@implementation _CYLTabBarMinimizeScrollTracker {
    /// [EN] Distance scrolled in the current direction (positive: content moves up). [CN] 当前方向的累计滚动距离（正值：内容上移）。
    CGFloat _scrolledDistance;
    /// [EN] YES when the tab bar was hidden by scrolling, not by the app. [CN] TabBar 是滚动隐藏的，而不是 App 自己隐藏的。
    BOOL _hiddenByScroll;
    /// [EN] Liquid Glass: the minimized state the tab bar was last laid out for. [CN] 液态玻璃：上次布局时 TabBar 的缩小状态。
    BOOL _laidOutMinimized;
    /// [EN] Checks again on a timer: the page on screen (classic) and, while the bar is hidden or minimized, whether it
    ///      must come back (see `-checkTimerFired`). [CN] 定时检查：当前页面（经典样式），以及 TabBar 被隐藏或缩小期间是否需要恢复。
    NSTimer *_checkTimer;
    NSTimeInterval _checkTimerInterval;
    /// [EN] After a restore, the tab bar hides again only on a new drag, not on the momentum of the old one.
    /// [CN] 恢复之后，只有新的拖动才会再次隐藏 TabBar，旧拖动的惯性不会。
    BOOL _needsNewDrag;
    /// [EN] `isTracking` at the last offset change, to see a new drag start. [CN] 上次偏移变化时的 `isTracking`，用于识别新拖动的开始。
    BOOL _lastSeenTracking;
    /// [EN] Notification observers (app, scene, window, memory, keyboard). [CN] 通知观察者（App、Scene、窗口、内存、键盘）。
    NSMutableArray<id<NSObject>> *_notificationObservers;
    /// [EN] The one flag (whitelist): YES only while a hide session runs, i.e. the bar is hidden or minimized because the
    ///      user scrolled down through content, in the context recorded below. See `-beginHideSession`.
    /// [CN] 唯一的标记（白名单）：只有隐藏会话进行中才为 YES，即用户在下面记录的上下文中向下滚动浏览内容，TabBar 因此被隐藏或缩小。
    ///      见 `-beginHideSession`。
    BOOL _hideSessionActive;
    __weak UIScrollView *_sessionScrollView;
    __weak UIViewController *_sessionSelectedViewController;
    __weak UIViewController *_sessionPage;
    __weak UIWindow *_sessionWindow;
    /// [EN] The controller's frame in its window and its top safe area when the session began (a side menu moving it,
    ///      a container transition, an in-call / hotspot / recording status bar change them).
    /// [CN] 会话开始时控制器在窗口中的 frame 及顶部安全区（侧滑菜单移动控制器、容器转场、通话 / 热点 / 录屏状态栏会改变它们）。
    CGRect _sessionFrameInWindow;
    CGFloat _sessionSafeAreaTop;
    /// [EN] Observes a long press on the followed scroll view; never cancels or delays its touches.
    /// [CN] 观察所跟随滚动视图上的长按；从不取消或延迟其触摸。
    UILongPressGestureRecognizer *_longPressObserver;
    /// [EN] Observes taps anywhere in the controller's view; never cancels or delays touches.
    /// [CN] 观察控制器视图中任意位置的点击；从不取消或延迟触摸。
    UITapGestureRecognizer *_tapObserver;
    CYLTabBarMinimizeBehavior _sessionBehavior;
    CYLTabBarMinimizeMode _sessionMode;
    /// [EN] YES while scroll hiding itself calls `-setTabBarHidden:animated:`. [CN] 滚动隐藏自己调用 `-setTabBarHidden:animated:` 期间为 YES。
    BOOL _settingTabBarHidden;
    /// [EN] YES while the keyboard is on screen: typing is not reading, the bar never hides then.
    /// [CN] 键盘显示期间为 YES：输入不是浏览，此时不隐藏 TabBar。
    BOOL _keyboardVisible;
    /// [EN] The page the scroll view was last searched for, and when. [CN] 上次查找滚动视图时的页面及时间。
    __weak UIViewController *_resolvedPage;
    CFTimeInterval _resolvedAt;
    /// [EN] Scroll hiding's own last request and when it was made: a FlatDesign animation may replay it shortly after.
    /// [CN] 滚动隐藏自己最近一次请求及时间：扁平样式的动画可能稍后重放它。
    BOOL _lastOwnRequestHidden;
    CFTimeInterval _lastOwnRequestTime;
    /// [EN] The app took the tab bar over after scroll hiding's last request. [CN] 滚动隐藏最近一次请求之后，App 接管了 TabBar。
    BOOL _appTookTabBarOver;
}

- (instancetype)initWithTabBarController:(CYLTabBarController *)tabBarController {
    self = [super init];
    if (self) {
        _tabBarController = tabBarController;
        [self observeLifecycleNotifications];
    }
    return self;
}

- (void)dealloc {
    [_checkTimer invalidate];
    [_tapObserver.view removeGestureRecognizer:_tapObserver];
    for (id<NSObject> observer in _notificationObservers) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
    [self observeScrollView:nil];
}

#pragma mark Lifecycle

/*!
 * [EN] Where bugs hide: when the tab bar must come back. Every event below restores a tab bar hidden (FlatDesign,
 *      classic) or minimized (Liquid Glass) by scrolling, and then waits for a new drag before hiding it again:
 *      - will resign active: an incoming call, the low battery alert or any system alert, Control Center, Notification
 *        Center, the app switcher;
 *      - did enter background / will enter foreground / did become active: background and foreground switches, opening
 *        the app from a push notification (whose page push is then caught as a page change), returning from a call;
 *      - memory warning;
 *      - the same scene events (iOS 13+), only for the scene of this tab bar's window;
 *      - another window becoming key: alerts, HUDs or overlays shown in a window of their own.
 *      In-app alerts and modals, pushes and pops have no notification; the check timer catches them (`-checkTimerFired`).
 * [CN] 最容易出 bug 的地方：何时恢复显示。下列每个事件都会恢复被滚动隐藏（扁平样式、经典样式）或缩小（液态玻璃）的 TabBar，
 *      之后等待新的拖动才会再次隐藏：
 *      - 即将失去活跃：来电、低电量弹框或任何系统弹框、控制中心、通知中心、App 切换器；
 *      - 进入后台 / 即将进入前台 / 变为活跃：前后台切换、点击推送打开 App（随后 push 的页面按页面变化处理）、通话结束返回；
 *      - 内存警告；
 *      - 对应的 Scene 事件（iOS 13+），只处理本 TabBar 所在窗口的 Scene；
 *      - 其他窗口成为 key window：显示在独立窗口中的弹框、HUD 或浮层。
 *      App 内的弹框与模态页面、push 与 pop 没有通知，由定时检查处理（`-checkTimerFired`）。
 */
- (void)observeLifecycleNotifications {
    _notificationObservers = [NSMutableArray array];
    NSMutableArray<NSNotificationName> *names = [NSMutableArray arrayWithArray:@[
        UIApplicationWillResignActiveNotification,
        UIApplicationDidEnterBackgroundNotification,
        UIApplicationWillEnterForegroundNotification,
        UIApplicationDidBecomeActiveNotification,
        UIApplicationDidReceiveMemoryWarningNotification,
        UIWindowDidBecomeKeyNotification,
        UIKeyboardWillShowNotification,
        UIKeyboardWillHideNotification,
        UIAccessibilityVoiceOverStatusDidChangeNotification,
        UIAccessibilitySwitchControlStatusDidChangeNotification,
        UIAccessibilityReduceMotionStatusDidChangeNotification,
        UIAccessibilityGuidedAccessStatusDidChangeNotification,
        NSProcessInfoPowerStateDidChangeNotification,
    ]];
    if (@available(iOS 13.0, *)) {
        [names addObjectsFromArray:@[
            UISceneWillDeactivateNotification,
            UISceneDidEnterBackgroundNotification,
            UISceneWillEnterForegroundNotification,
            UISceneDidActivateNotification,
        ]];
    }
    __weak typeof(self) weakSelf = self;
    for (NSNotificationName name in names) {
        id<NSObject> observer = [[NSNotificationCenter defaultCenter] addObserverForName:name
                                                                                   object:nil
                                                                                    queue:[NSOperationQueue mainQueue]
                                                                               usingBlock:^(NSNotification *notification) {
            [weakSelf restoreTabBarForNotification:notification];
        }];
        [_notificationObservers addObject:observer];
    }
}

- (void)restoreTabBarForNotification:(NSNotification *)notification {
    UIWindow *window = self.tabBarController.viewIfLoaded.window;
    // [EN] Keyboard: remember whether it is on screen; it going away is not an interruption.
    // [CN] 键盘：记录是否显示；键盘收起不算打断。
    if ([notification.name isEqualToString:UIKeyboardWillHideNotification]) {
        _keyboardVisible = NO;
        return;
    }
    if ([notification.name isEqualToString:UIKeyboardWillShowNotification]) {
        // [EN] Only this window's keyboard counts: not another app's (Slide Over / Split View, not local), nor one in
        //      another scene of this app (this window is then not the key window of an active scene).
        // [CN] 只处理本窗口的键盘：不处理其他 App 的键盘（侧拉 / 分屏，非本地），也不处理本 App 其他 Scene 中的键盘（此时本窗口不是
        //      活跃 Scene 的 key window）。
        NSNumber *isLocal = notification.userInfo[UIKeyboardIsLocalUserInfoKey];
        if ((isLocal && !isLocal.boolValue) || !CYLTabBarMinimizeWindowIsKeyAndActive(window)) {
            return;
        }
        _keyboardVisible = YES;
    }
    // [EN] A keyboard left up when the app went to the background may never post WillHide; it posts WillShow again
    //      when it comes back, so forget it here instead of blocking hiding until then.
    // [CN] 进入后台时仍显示的键盘可能不会发送 WillHide；回到前台重新显示时会再次发送 WillShow，因此在这里清除记录，
    //      避免在此之前一直无法隐藏。
    if ([notification.name isEqualToString:UIApplicationDidEnterBackgroundNotification]) {
        _keyboardVisible = NO;
    }
    // Guard: this tab bar's own window becoming key is not an interruption. 本 TabBar 自己的窗口成为 key window 不算打断。
    if ([notification.name isEqualToString:UIWindowDidBecomeKeyNotification] && notification.object == window) {
        return;
    }
    // Guard: scene events of other scenes (iPad multiple windows). 其他 Scene 的事件（iPad 多窗口）。
    if (@available(iOS 13.0, *)) {
        UIWindowScene *windowScene = window.windowScene;
        if ([notification.object isKindOfClass:[UIScene class]] && windowScene && notification.object != windowScene) {
            return;
        }
    }
    [self restoreTabBarForReason:notification.name];
}

/*!
 * [EN] Shows a tab bar hidden or minimized by scrolling again, at once, and blocks hiding until the user starts a new
 *      drag. Does nothing to a tab bar the app hid itself.
 * [CN] 立即重新显示被滚动隐藏或缩小的 TabBar，并在用户开始新的拖动之前不再隐藏。App 自己隐藏的 TabBar 不处理。
 */
- (void)restoreTabBar {
    [self restoreTabBarForReason:@"restore"];
}

- (void)restoreTabBarForReason:(NSString *)reason {
    if ([self isTabBarHiddenOrMinimizedByScroll]) {
        CYLTabBarMinimizeLog(@"restore", reason);
    }
    [self endHideSession];
    _needsNewDrag = YES;
    _lastSeenTracking = self.scrollView.isTracking;
    _scrolledDistance = 0;
    [self expandTabBar];
    // Guard: Liquid Glass, only a bar the system shows minimized. 液态玻璃：只处理系统正以缩小状态显示的 TabBar。
    CYLTabBarController *tabBarController = self.tabBarController;
    if (CYLTabBarMinimizeModeLiquidGlass == _mode && tabBarController) {
        UIView *tabBar = tabBarController.cyl_tabBar;
        if ([tabBar isKindOfClass:[CYLTabBar class]] && [(CYLTabBar *)tabBar cyl_showsMinimizedBar]) {
            [tabBarController cyl_expandSystemMinimizedTabBar];
        }
    }
    [self updateCheckTimer];
}

/// [EN] YES while scrolling hid (FlatDesign, classic) or the system minimized (Liquid Glass) the tab bar.
/// [CN] TabBar 被滚动隐藏（扁平样式、经典样式）或被系统缩小（液态玻璃）期间为 YES。
- (BOOL)isTabBarHiddenOrMinimizedByScroll {
    if (_hiddenByScroll) {
        return YES;
    }
    if (CYLTabBarMinimizeModeLiquidGlass != _mode) {
        return NO;
    }
    UIView *tabBar = self.tabBarController.cyl_tabBar;
    return [tabBar isKindOfClass:[CYLTabBar class]] && [(CYLTabBar *)tabBar cyl_showsMinimizedBar];
}

/*!
 * [EN] Whether the tab bar may hide now. Hiding only makes sense while the user reads content in an active app; it is
 *      refused while: the app is not active, this window is not the key window, anything is presented (an alert, an
 *      action sheet, a modal page, from any child), a push or pop is running, or the scroll view is off screen.
 * [CN] 现在是否可以隐藏 TabBar。只有在活跃的 App 中浏览内容时才隐藏；以下情况拒绝隐藏：App 不活跃、本窗口不是 key window、有任何
 *      页面被 present（弹框、操作表、模态页面，来自任何子控制器）、push 或 pop 进行中、滚动视图不在屏幕上。
 */
- (BOOL)environmentAllowsHiding {
    return [self environmentRefusalReason] == nil;
}

/// [EN] Why the app does not allow hiding now, or nil when it does (also used for the log).
/// [CN] 当前不允许隐藏的原因，允许时返回 nil（也用于日志）。
- (NSString *)environmentRefusalReason {
    CYLTabBarController *tabBarController = self.tabBarController;
    UIWindow *window = tabBarController.viewIfLoaded.window;
    if (!CYLTabBarMinimizeWindowIsKeyAndActive(window)) {
        return @"window not key, or its scene / the app not active";
    }
    // [EN] On a Mac (Mac Catalyst, or an iPhone / iPad app on Apple silicon) a pointer and a resizable window make hiding
    //      the tab bar pointless. [CN] 在 Mac 上（Mac Catalyst，或运行在 Apple 芯片 Mac 上的 iPhone / iPad App），鼠标与可调整
    //      大小的窗口使隐藏 TabBar 没有意义。
#if TARGET_OS_MACCATALYST
    return @"Mac Catalyst";
#else
    if (@available(iOS 14.0, *)) {
        if ([NSProcessInfo processInfo].isiOSAppOnMac) {
            return @"iOS app running on a Mac";
        }
    }
#endif
    // [EN] VoiceOver and Switch Control users move through the tabs: never take them away.
    // [CN] VoiceOver 与切换控制的用户依靠 Tab 导航：不隐藏 TabBar。
    if (UIAccessibilityIsVoiceOverRunning() || UIAccessibilityIsSwitchControlRunning()) {
        return @"VoiceOver or Switch Control running";
    }
    if (_keyboardVisible) {
        return @"keyboard on screen";
    }
    // [EN] Presented by this controller or an ancestor, by the selected tab, or by the page on screen (a child that
    //      defines its own presentation context is not seen from above).
    // [CN] 由本控制器或其祖先、选中的 Tab、或当前页面 present（自行定义 presentation context 的子控制器从上层看不到）。
    UIViewController *selectedViewController = tabBarController.selectedViewController;
    if (tabBarController.presentedViewController || selectedViewController.presentedViewController ||
        CYLTabBarMinimizeVisibleViewController(selectedViewController).presentedViewController) {
        return @"a view controller is presented";
    }
    if (selectedViewController.transitionCoordinator) {
        return @"a push / pop transition is running";
    }
    if (!self.scrollView.window) {
        return @"scroll view off screen";
    }
    return nil;
}

#pragma mark Hide session (whitelist)

/*!
 * [EN] The robust core, a whitelist instead of a list of events: hiding the bar is valid only inside a "hide session".
 *      The one way to start a session is the user scrolling down through content (`-minimizeTabBar`; for Liquid Glass,
 *      the system minimizing the bar while the app allows hiding). The session records its context: the scroll view, the
 *      selected tab, the page on screen, the window, the behavior and the path. Anything that does not match that
 *      context, or that `-environmentAllowsHiding` refuses, ends the session and brings the bar back at once, also for
 *      situations nobody listed (e.g. a page shown from a notification banner, a share sheet, a split screen resize).
 *      It is checked on every scroll event, every layout of the tab bar controller, its view lifecycle callbacks, every
 *      observed notification, and by the check timer while the bar is hidden.
 * [CN] 健壮性的核心是白名单而不是事件列表：只有在“隐藏会话”内，TabBar 才可以保持隐藏。开始会话的唯一方式是用户向下滚动浏览内容
 *      （`-minimizeTabBar`；液态玻璃为 App 允许隐藏时系统缩小了 TabBar）。会话记录当时的上下文：滚动视图、选中的 Tab、当前显示的页面、
 *      窗口、取值与路径。任何与该上下文不一致、或 `-environmentAllowsHiding` 不允许的情况，都会结束会话并立即恢复显示，包括没有被
 *      列举到的情况（例如从通知横幅打开的页面、分享面板、分屏尺寸变化）。检查时机：每次滚动、TabBarController 每次布局、
 *      它的视图生命周期回调、每个被监听的通知，以及 TabBar 隐藏期间的定时检查。
 */
- (void)beginHideSession {
    CYLTabBarMinimizeLog(@"hide session begins", _mode == CYLTabBarMinimizeModeLiquidGlass ? @"system minimized" : @"user scrolled down");
    CYLTabBarController *tabBarController = self.tabBarController;
    UIViewController *selectedViewController = tabBarController.selectedViewController;
    _hideSessionActive = YES;
    _sessionScrollView = self.scrollView;
    _sessionSelectedViewController = selectedViewController;
    _sessionPage = CYLTabBarMinimizeVisibleViewController(selectedViewController);
    _sessionWindow = tabBarController.viewIfLoaded.window;
    _sessionBehavior = tabBarController.cyl_tabBarMinimizeBehavior;
    _sessionMode = _mode;
    UIView *controllerView = tabBarController.viewIfLoaded;
    _sessionFrameInWindow = controllerView ? [controllerView convertRect:controllerView.bounds toView:nil] : CGRectZero;
    _sessionSafeAreaTop = controllerView.safeAreaInsets.top;
}

- (void)endHideSession {
    _hideSessionActive = NO;
    _sessionScrollView = nil;
    _sessionSelectedViewController = nil;
    _sessionPage = nil;
    _sessionWindow = nil;
}

/// [EN] Whether the running session still matches its context and the app still allows hiding.
/// [CN] 正在进行的会话是否仍与其上下文一致，且 App 仍允许隐藏。
- (BOOL)hideSessionIsValid {
    return [self hideSessionInvalidReason] == nil;
}

/// [EN] Why the running session is no longer valid, or nil while it is (also used for the log).
/// [CN] 正在进行的会话为何不再有效，有效时返回 nil（也用于日志）。
- (NSString *)hideSessionInvalidReason {
    if (!_hideSessionActive) {
        return @"no hide session";
    }
    NSString *refusal = [self environmentRefusalReason];
    if (refusal) {
        return refusal;
    }
    CYLTabBarController *tabBarController = self.tabBarController;
    UIViewController *selectedViewController = tabBarController.selectedViewController;
    UIScrollView *scrollView = self.scrollView;
    UIScrollView *sessionScrollView = _sessionScrollView;
    UIViewController *sessionSelectedViewController = _sessionSelectedViewController;
    UIViewController *sessionPage = _sessionPage;
    UIWindow *sessionWindow = _sessionWindow;
    if (!scrollView || scrollView != sessionScrollView) {
        return @"scroll view changed";
    }
    if (!selectedViewController || selectedViewController != sessionSelectedViewController) {
        return @"tab changed";
    }
    if (!sessionPage || CYLTabBarMinimizeVisibleViewController(selectedViewController) != sessionPage) {
        return @"page changed (push / pop)";
    }
    if (!sessionWindow || tabBarController.viewIfLoaded.window != sessionWindow) {
        return @"window changed";
    }
    if (tabBarController.cyl_tabBarMinimizeBehavior != _sessionBehavior || _mode != _sessionMode) {
        return @"value or style changed";
    }
    UIView *controllerView = tabBarController.viewIfLoaded;
    CGRect frameInWindow = controllerView ? [controllerView convertRect:controllerView.bounds toView:nil] : CGRectZero;
    if (fabs(CGRectGetMinX(frameInWindow) - CGRectGetMinX(_sessionFrameInWindow)) > 1.0 ||
        fabs(CGRectGetMinY(frameInWindow) - CGRectGetMinY(_sessionFrameInWindow)) > 1.0 ||
        fabs(CGRectGetWidth(frameInWindow) - CGRectGetWidth(_sessionFrameInWindow)) > 1.0 ||
        fabs(CGRectGetHeight(frameInWindow) - CGRectGetHeight(_sessionFrameInWindow)) > 1.0) {
        return @"controller moved or resized in its window (side menu, container transition)";
    }
    if (fabs(controllerView.safeAreaInsets.top - _sessionSafeAreaTop) > 0.5) {
        return @"top safe area changed (in-call / hotspot / recording status bar)";
    }
    return nil;
}

/*!
 * [EN] Brings the bar back unless a valid session explains why it is hidden or minimized. Liquid Glass: a bar the system
 *      minimized while hiding is allowed adopts a session (the system decides when to minimize), any other is restored.
 * [CN] 除非有一个有效的会话说明 TabBar 为何被隐藏或缩小，否则恢复显示。液态玻璃：在允许隐藏时被系统缩小的 TabBar 会开始一个会话
 *      （何时缩小由系统决定），其他情况恢复显示。
 */
- (void)validateHideSession {
    CYLTabBarController *tabBarController = self.tabBarController;
    // [EN] Shown again by the app or UIKit (FlatDesign, classic): not hidden by scrolling any more.
    // [CN] 已被 App 或 UIKit 重新显示（扁平样式、经典样式）：不再是滚动隐藏状态。
    // [EN] Not while our own hide is under way: during the call, and for 0.5 s after it, FlatDesign may still report the
    //      bar as shown (seen on iOS 26.5), which would drop the flag while the bar ends up hidden, with nothing left to
    //      bring it back.
    // [CN] 我们自己的隐藏进行中时不判断：调用期间及之后 0.5 秒内，扁平样式可能仍报告 TabBar 为显示（在 iOS 26.5 上出现），会在 TabBar
    //      最终隐藏的情况下丢掉标记，之后再没有恢复它的途径。
    BOOL ownHideUnderWay = _settingTabBarHidden || (_lastOwnRequestHidden && CACurrentMediaTime() - _lastOwnRequestTime < 0.5);
    if (_hiddenByScroll && !tabBarController.isTabBarHidden && !ownHideUnderWay) {
        CYLTabBarMinimizeLog(@"no longer hidden by scrolling", @"the tab bar was shown again by the app or UIKit");
        _hiddenByScroll = NO;
    }
    // [EN] Classic: a pushed page with `hidesBottomBarWhenPushed` holds the bar; UIKit owns it there. End the session once
    //      and wait (no restore on every check); the bar comes back with the page change on the way back.
    // [CN] 经典样式：设置了 `hidesBottomBarWhenPushed` 的页面占用 TabBar，此时由 UIKit 控制。只结束一次会话并等待（不在每次检查时
    //      重复恢复）；返回时随页面变化恢复显示。
    if (CYLTabBarMinimizeModeClassic == _mode && _hiddenByScroll &&
        CYLTabBarMinimizeClassicPageHidesTabBar(tabBarController.selectedViewController)) {
        if (_hideSessionActive) {
            [self endHideSession];
        }
        return;
    }
    if (![self isTabBarHiddenOrMinimizedByScroll]) {
        // [EN] Shown again (by scrolling up, the system, or the app): the session is over. [CN] 已重新显示：会话结束。
        if (_hideSessionActive) {
            [self endHideSession];
        }
        return;
    }
    // [EN] Liquid Glass: the system decides when to minimize, so a minimize while hiding is allowed is adopted even before a
    //      new drag; refusing it would fight the system while the old drag's momentum runs.
    // [CN] 液态玻璃：何时缩小由系统决定，因此允许隐藏时的缩小即使发生在新的拖动之前也会被接受；拒绝它会在旧拖动的惯性期间与系统反复拉扯。
    if (CYLTabBarMinimizeModeLiquidGlass == _mode && !_hideSessionActive && [self environmentAllowsHiding]) {
        [self beginHideSession];
        return;
    }
    NSString *invalidReason = [self hideSessionInvalidReason];
    if (invalidReason) {
        [self restoreTabBarForReason:invalidReason];
    }
}

#pragma mark Long press on content

/*!
 * [EN] A long press on the content (a context menu, drag and drop, text selection) is not reading: it ends the session
 *      and shows the bar. The observer runs alongside every other recognizer and never cancels or delays touches, so the
 *      app's own gestures and context menus work as before; a press that moves (a scroll) fails it.
 * [CN] 在内容上长按（上下文菜单、拖放、选择文字）不是浏览：结束会话并显示 TabBar。该观察者与其他手势同时识别，从不取消或延迟触摸，
 *      App 自己的手势与上下文菜单不受影响；移动的按压（即滚动）不会被识别为长按。
 */
- (void)contentLongPressed:(UILongPressGestureRecognizer *)recognizer {
    if (UIGestureRecognizerStateBegan == recognizer.state) {
        [self restoreTabBarForReason:@"long press on content (context menu, drag, text selection)"];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

#pragma mark Testing

/// [EN] Hides as a user's downward scroll would (FlatDesign, classic), for self-tests. [CN] 像用户向下滚动一样隐藏（扁平样式、经典样式），用于自测。
- (BOOL)simulateHideForTesting {
    // [EN] Each refusal is logged (opt-in log, CYLTabBarMinimizeLog=1) so a self-test SKIP can be explained.
    // [CN] 每种拒绝都会记录到可选日志（CYLTabBarMinimizeLog=1），以便解释自测中的 SKIP。
    if (CYLTabBarMinimizeModeFlatDesign != _mode && CYLTabBarMinimizeModeClassic != _mode) {
        CYLTabBarMinimizeLog(@"test hide refused", CYLTabBarMinimizeModeLiquidGlass == _mode ? @"Liquid Glass: the system minimizes the bar" : @"scroll hiding is off");
        return NO;
    }
    NSString *refusal = [self environmentRefusalReason];
    if (refusal) {
        CYLTabBarMinimizeLog(@"test hide refused", refusal);
        return NO;
    }
    _needsNewDrag = NO;
    [self minimizeTabBar];
    if (!_hiddenByScroll) {
        UIScrollView *scrollView = _scrollView;
        CYLTabBarMinimizeLog(@"test hide refused", [NSString stringWithFormat:@"the bar did not hide (tab bar hidden already: %@, scroll view: %@, content height %.0f, bounds height %.0f, offset %.0f)",
                                                    self.tabBarController.isTabBarHidden ? @"YES" : @"NO",
                                                    scrollView ? NSStringFromClass([scrollView class]) : @"none",
                                                    scrollView.contentSize.height, CGRectGetHeight(scrollView.bounds), scrollView.contentOffset.y]);
    }
    return _hiddenByScroll;
}

#pragma mark Taps outside the content

/// [EN] Attaches the tap observer to the controller's view (once). [CN] 将点击观察者加到控制器的视图上（只加一次）。
- (void)observeTapsInView:(UIView *)view {
    if (!view || _tapObserver.view == view) {
        return;
    }
    if (!_tapObserver) {
        _tapObserver = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(controllerViewTapped:)];
        _tapObserver.cancelsTouchesInView = NO;
        _tapObserver.delaysTouchesBegan = NO;
        _tapObserver.delaysTouchesEnded = NO;
        _tapObserver.delegate = self;
    }
    [_tapObserver.view removeGestureRecognizer:_tapObserver];
    [view addGestureRecognizer:_tapObserver];
}

/*!
 * [EN] While the bar is hidden or minimized, a tap outside the followed scroll view (a navigation bar button, a button
 *      with a UIMenu, a segmented control in a header, the search field) is not reading: it ends the session and shows
 *      the bar. Taps inside the content (e.g. a like button in a post) keep it hidden, as in the Facebook app. The
 *      observer runs alongside every other recognizer and never cancels or delays touches.
 * [CN] TabBar 被隐藏或缩小期间，在所跟随滚动视图之外的点击（导航栏按钮、带 UIMenu 的按钮、头部的分段控件、搜索框）不是浏览：
 *      结束会话并显示 TabBar。内容中的点击（例如帖子里的点赞按钮）保持隐藏，与 Facebook App 一致。该观察者与其他手势同时识别，
 *      从不取消或延迟触摸。
 */
- (void)controllerViewTapped:(UITapGestureRecognizer *)recognizer {
    if (UIGestureRecognizerStateEnded != recognizer.state || ![self isTabBarHiddenOrMinimizedByScroll]) {
        return;
    }
    UIScrollView *scrollView = self.scrollView;
    if (scrollView && [scrollView pointInside:[recognizer locationInView:scrollView] withEvent:nil]) {
        return;
    }
    [self restoreTabBarForReason:@"tap outside the content (navigation bar, menu button, header)"];
}

#pragma mark Scroll view lookup

/*!
 * [EN] The scroll view to follow. While the page on screen stays the same and the followed scroll view is still on screen,
 *      it is reused for CYLTabBarMinimizeResolveCacheDuration instead of searching the view hierarchy on every layout and
 *      every classic page check. A new page is always searched at once.
 * [CN] 要跟随的滚动视图。当前页面不变且所跟随的滚动视图仍在屏幕上时，在 CYLTabBarMinimizeResolveCacheDuration 内直接复用，
 *      不必在每次布局与经典样式的页面检查时遍历视图层级。新页面总会立即查找。
 */
- (UIScrollView *)scrollViewForSelectedViewController:(UIViewController *)selectedViewController {
    UIViewController *page = CYLTabBarMinimizeVisibleViewController(selectedViewController);
    UIViewController *resolvedPage = _resolvedPage;
    UIScrollView *current = self.scrollView;
    CFTimeInterval now = CACurrentMediaTime();
    if (page && page == resolvedPage && now - _resolvedAt < CYLTabBarMinimizeResolveCacheDuration && (!current || current.window)) {
        return current;
    }
    _resolvedPage = page;
    _resolvedAt = now;
    return CYLTabBarMinimizeScrollViewForViewController(selectedViewController);
}

#pragma mark Check timer

/// [EN] Runs the check timer while it is needed: always for the classic path (page changes), and for every path while
///      the bar is hidden or minimized by scrolling (faster then). Stops otherwise.
/// [CN] 仅在需要时运行定时检查：经典样式始终运行（页面变化）；任何路径在 TabBar 被滚动隐藏或缩小期间运行（此时间隔更短）。其他情况停止。
- (void)updateCheckTimer {
    NSTimeInterval interval = 0;
    if ([self isTabBarHiddenOrMinimizedByScroll]) {
        interval = CYLTabBarMinimizeRestoreCheckInterval;
    } else if (CYLTabBarMinimizeModeClassic == _mode) {
        interval = CYLTabBarMinimizeClassicPageCheckInterval;
    }
    if (_checkTimer && interval == _checkTimerInterval) {
        return;
    }
    [_checkTimer invalidate];
    _checkTimer = nil;
    _checkTimerInterval = interval;
    if (interval <= 0) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    _checkTimer = [NSTimer scheduledTimerWithTimeInterval:interval repeats:YES block:^(NSTimer *timer) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.tabBarController) {
            [timer invalidate];
            return;
        }
        [strongSelf checkTimerFired];
    }];
    _checkTimer.tolerance = interval * 0.5;
}

/*!
 * [EN] The safety net for what no notification reports: a page change (push, pop, a push after a notification tap, a
 *      tab switch) is found by re-resolving the scroll view, which shows the bar again; an alert, a modal or a lost key
 *      window restores the bar.
 * [CN] 没有通知可监听情况的安全网：重新确认滚动视图即可发现页面变化（push、pop、点击推送后的 push、切换 Tab），并重新显示 TabBar；
 *      弹框、模态页面或失去 key window 时恢复 TabBar。
 */
- (void)checkTimerFired {
    CYLTabBarController *tabBarController = self.tabBarController;
    if (tabBarController.viewIfLoaded.window) {
        [tabBarController cyl_updateTabBarMinimizeTracking];
    }
    [self validateHideSession];
    [self updateCheckTimer];
}

- (void)updateMode:(CYLTabBarMinimizeMode)mode {
    if (_mode == mode) {
        return;
    }
    // [EN] Leaving a path: give back a tab bar it hid. [CN] 离开某条路径：恢复它隐藏的 TabBar。
    [self expandTabBar];
    _mode = mode;
    _scrolledDistance = 0;
    _laidOutMinimized = NO;
    [self updateCheckTimer];
}

- (void)observeScrollView:(UIScrollView *)scrollView {
    UIScrollView *observedScrollView = _scrollView;
    if (observedScrollView == scrollView) {
        return;
    }
    // [EN] A scroll view that is already gone was nilled out by `weak`; KVO drops its observers itself (iOS 11+).
    // [CN] 已释放的滚动视图会被 `weak` 置为 nil；KVO 会自行移除它的观察者（iOS 11+）。
    [observedScrollView removeObserver:self forKeyPath:@"contentOffset" context:CYLTabBarMinimizeContentOffsetContext];
    [observedScrollView removeGestureRecognizer:_longPressObserver];
    _scrollView = scrollView;
    _scrolledDistance = 0;
    if (scrollView) {
        if (!_longPressObserver) {
            _longPressObserver = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(contentLongPressed:)];
            _longPressObserver.cancelsTouchesInView = NO;
            _longPressObserver.delaysTouchesBegan = NO;
            _longPressObserver.delaysTouchesEnded = NO;
            _longPressObserver.delegate = self;
        }
        [scrollView addGestureRecognizer:_longPressObserver];
    }
    [scrollView addObserver:self
                 forKeyPath:@"contentOffset"
                    options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                    context:CYLTabBarMinimizeContentOffsetContext];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (context != CYLTabBarMinimizeContentOffsetContext) {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        return;
    }
    UIScrollView *scrollView = self.scrollView;
    if (!scrollView || object != scrollView) {
        return;
    }
    // Guard: Liquid Glass only follows the system; it never hides the bar itself. 液态玻璃只跟随系统，从不自行隐藏 TabBar。
    if (CYLTabBarMinimizeModeLiquidGlass == _mode) {
        // [EN] A new drag hands the minimize behavior back to the system after a restore.
        // [CN] 恢复之后，新的拖动把缩小行为交还给系统。
        BOOL tracking = scrollView.isTracking;
        if (tracking && !_lastSeenTracking) {
            _needsNewDrag = NO;
            [self.tabBarController cyl_releaseSystemMinimizeHoldIfNeeded];
        }
        _lastSeenTracking = tracking;
        [self layOutTabBarIfMinimizedStateChanged];
        [self validateHideSession];
        return;
    }
    // [EN] Every scroll event checks the session first. [CN] 每次滚动都先检查会话。
    [self validateHideSession];
    NSValue *oldValue = change[NSKeyValueChangeOldKey];
    NSValue *newValue = change[NSKeyValueChangeNewKey];
    if (![oldValue isKindOfClass:[NSValue class]] || ![newValue isKindOfClass:[NSValue class]]) {
        return;
    }
    [self scrollView:scrollView didScrollFromOffsetY:oldValue.CGPointValue.y toOffsetY:newValue.CGPointValue.y];
}

/// [EN] FlatDesign and classic: decide from the user's scrolling whether to hide or show the tab bar.
/// [CN] 扁平样式与经典样式：根据用户的滚动决定隐藏或显示 TabBar。
- (void)scrollView:(UIScrollView *)scrollView didScrollFromOffsetY:(CGFloat)oldOffsetY toOffsetY:(CGFloat)newOffsetY {
    // Guard: the paths that hide the bar themselves. 只处理自行隐藏 TabBar 的路径。
    if (CYLTabBarMinimizeModeFlatDesign != _mode && CYLTabBarMinimizeModeClassic != _mode) {
        return;
    }
    CYLTabBarMinimizeBehavior behavior = self.tabBarController.cyl_tabBarMinimizeBehavior;
    BOOL minimizesOnScrollDown = (CYLTabBarMinimizeBehaviorOnScrollDown == behavior);
    BOOL minimizesOnScrollUp = (CYLTabBarMinimizeBehaviorOnScrollUp == behavior);
    if (!minimizesOnScrollDown && !minimizesOnScrollUp) {
        return;
    }
    UIEdgeInsets insets = scrollView.adjustedContentInset;
    CGFloat minOffsetY = -insets.top;
    CGFloat maxOffsetY = MAX(minOffsetY, scrollView.contentSize.height + insets.bottom - CGRectGetHeight(scrollView.bounds));
    // [EN] Checked before the user-scroll guard below, so these also work for offsets set in code: content that no
    //      longer scrolls (e.g. reloaded shorter) never keeps the bar hidden, and back at the edge the content starts
    //      from (also after a tap on the status bar) the bar comes back, as the system does.
    // [CN] 放在下方“仅用户滚动”的 guard 之前，因此代码设置的偏移同样生效：不再能滚动的内容（例如重新加载后变短）不会让 TabBar
    //      保持隐藏；回到内容的起始边缘（包括点击状态栏回到顶部）时，与系统一致，重新显示 TabBar。
    if (maxOffsetY - minOffsetY < CYLTabBarMinimizeMinimumScrollableDistance) {
        _scrolledDistance = 0;
        if (_hiddenByScroll) {
            CYLTabBarMinimizeLog(@"restore", @"the content no longer scrolls");
        }
        [self expandTabBar];
        return;
    }
    // [EN] Half a point of tolerance: an animated scroll to the edge (e.g. a tap on the status bar) can end a fraction of a
    //      point away from it after pixel rounding, which an exact comparison would miss.
    // [CN] 允许半个点的误差：动画滚动到边缘（例如点击状态栏）在像素取整后可能停在离边缘不到一个点的位置，精确比较会漏掉。
    static const CGFloat CYLTabBarMinimizeEdgeTolerance = 0.5;
    if ((minimizesOnScrollDown && newOffsetY <= minOffsetY + CYLTabBarMinimizeEdgeTolerance) ||
        (minimizesOnScrollUp && newOffsetY >= maxOffsetY - CYLTabBarMinimizeEdgeTolerance)) {
        _scrolledDistance = 0;
        if (_hiddenByScroll) {
            CYLTabBarMinimizeLog(@"restore", @"back at the edge the content starts from");
        }
        [self expandTabBar];
        return;
    }
    // [EN] A new drag starts when `isTracking` turns on; it lifts the block set by a restore.
    // [CN] `isTracking` 由 NO 变为 YES 即开始新的拖动，解除恢复时设置的限制。
    BOOL tracking = scrollView.isTracking;
    if (tracking && !_lastSeenTracking) {
        _needsNewDrag = NO;
    }
    _lastSeenTracking = tracking;
    // [EN] Only scrolling by the user counts. Offsets set in code, e.g. when the safe area changes because the tab bar
    //      hides, are ignored.
    // [CN] 只响应用户的滚动。代码设置的偏移（例如 TabBar 隐藏导致安全区变化）不处理。
    if (!tracking && !scrollView.isDragging && !scrollView.isDecelerating) {
        return;
    }
    // [EN] Ignore the rubber band beyond either edge: it bounces back in the opposite direction.
    // [CN] 忽略超出边缘的回弹：回弹的方向与滚动方向相反。
    if (oldOffsetY < minOffsetY || oldOffsetY > maxOffsetY || newOffsetY < minOffsetY || newOffsetY > maxOffsetY) {
        return;
    }
    CGFloat delta = newOffsetY - oldOffsetY;
    if (delta == 0) {
        return;
    }
    if ((delta > 0) != (_scrolledDistance > 0)) {
        _scrolledDistance = 0;
    }
    _scrolledDistance += delta;
    if (fabs(_scrolledDistance) < CYLTabBarMinimizeScrollDistance) {
        return;
    }
    // [EN] Positive: the content moves up, i.e. the user scrolls down to read on.
    // [CN] 正值：内容上移，即用户向下滚动继续浏览。
    BOOL scrollsDown = (_scrolledDistance > 0);
    _scrolledDistance = 0;
    if (scrollsDown != minimizesOnScrollDown) {
        [self expandTabBar];
        return;
    }
    // [EN] Hide only while the user reads on, as in the Facebook app: not before a new drag after a restore, not in the
    //      first CYLTabBarMinimizeHideStartDistance of the content, and only when the app allows it.
    // [CN] 与 Facebook App 一致，只在用户继续浏览内容时隐藏：恢复后需新的拖动，内容开头 CYLTabBarMinimizeHideStartDistance 内不隐藏，
    //      并且需要 App 环境允许。
    if (_needsNewDrag) {
        return;
    }
    BOOL farEnoughIntoContent = minimizesOnScrollDown ? (newOffsetY > minOffsetY + CYLTabBarMinimizeHideStartDistance)
                                                      : (newOffsetY < maxOffsetY - CYLTabBarMinimizeHideStartDistance);
    if (!farEnoughIntoContent || maxOffsetY - minOffsetY < CYLTabBarMinimizeHideMinimumScrollableDistance ||
        ![self environmentAllowsHiding]) {
        return;
    }
    [self minimizeTabBar];
}

#pragma mark Liquid Glass

/*!
 * [EN] Liquid Glass: the system minimizes or expands the tab bar while the page scrolls, without a public callback. When
 *      the platter's geometry (`-[CYLTabBar cyl_showsMinimizedBar]`) flips, lay the tab bar out so the plus button
 *      follows: centered on its tab while minimized, the usual height-based position when expanded. Laid out once more
 *      after the system's animation.
 * [CN] 液态玻璃：页面滚动时系统会缩小或恢复 TabBar，没有公开的回调。当 platter 的几何尺寸（`-[CYLTabBar cyl_showsMinimizedBar]`）
 *      发生变化时重新布局 TabBar，让 PlusButton 跟随：缩小时居中于它的 Tab，恢复后回到按 TabBar 高度计算的位置。系统动画结束后再布局一次。
 */
- (void)layOutTabBarIfMinimizedStateChanged {
    UIView *tabBar = self.tabBarController.cyl_tabBar;
    if (![tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    BOOL minimized = [(CYLTabBar *)tabBar cyl_showsMinimizedBar];
    if (minimized == _laidOutMinimized) {
        return;
    }
    _laidOutMinimized = minimized;
    // [EN] Minimized: the safety net watches for anything that must bring the bar back. [CN] 缩小后：由安全网检查何时需要恢复。
    [self updateCheckTimer];
    [tabBar setNeedsLayout];
    __weak UIView *weakTabBar = tabBar;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakTabBar setNeedsLayout];
    });
}

#pragma mark Hide / show

/*!
 * [EN] FlatDesign and classic: hide the tab bar through the public `-setTabBarHidden:animated:`, the same API the app
 *      uses. Each path has its own guard: only a tab bar on screen is hidden, not one hidden by the app, nor by
 *      `hidesBottomBarWhenPushed`.
 * [CN] 扁平样式与经典样式：通过公开的 `-setTabBarHidden:animated:`（App 使用的同一个接口）隐藏 TabBar。每条路径都有自己的 guard：
 *      只隐藏正在显示的 TabBar，App 自己隐藏的、`hidesBottomBarWhenPushed` 隐藏的都不处理。
 */
- (void)minimizeTabBar {
    CYLTabBarController *tabBarController = self.tabBarController;
    if (!tabBarController) {
        return;
    }
    if (tabBarController.isTabBarHidden) {
        // [EN] Safety net: the bar is hidden by our own last request and the app has not taken it over since, but the
        //      flag was lost: take it back as hidden by scrolling, so a restore can show it again.
        // [CN] 安全网：TabBar 是我们最近一次请求隐藏的，此后 App 也没有接管，但标记丢失了：重新作为滚动隐藏处理，使恢复时能再次显示。
        if (!_hiddenByScroll && _lastOwnRequestHidden && !_appTookTabBarOver &&
            (CYLTabBarMinimizeModeFlatDesign == _mode || CYLTabBarMinimizeModeClassic == _mode)) {
            CYLTabBarMinimizeLog(@"hidden by scrolling again", @"our own hide was still in effect");
            _hiddenByScroll = YES;
            [self beginHideSession];
            [self updateCheckTimer];
        }
        return;
    }
    switch (_mode) {
        case CYLTabBarMinimizeModeFlatDesign:
            if (![self flatDesignCanHideTabBar]) {
                return;
            }
            break;
        case CYLTabBarMinimizeModeClassic:
            if (![self classicCanHideTabBar]) {
                return;
            }
            break;
        case CYLTabBarMinimizeModeLiquidGlass:
        case CYLTabBarMinimizeModeNone:
            return;
    }
    _hiddenByScroll = YES;
    // [EN] The one place a session starts for FlatDesign and classic. [CN] 扁平样式与经典样式开始会话的唯一位置。
    [self beginHideSession];
    [self setTabBarHiddenFromScroll:YES];
    [self updateCheckTimer];
}

- (void)expandTabBar {
    // Guard: only a tab bar hidden by scrolling is shown again. 只恢复被滚动隐藏的 TabBar。
    if (!_hiddenByScroll) {
        return;
    }
    // [EN] Guard (classic): a pushed page hides the bar through `hidesBottomBarWhenPushed`; keep it hidden by scrolling
    //      until a page that shows the bar is back, then show it.
    // [CN] Guard（经典样式）：被 push 的页面通过 `hidesBottomBarWhenPushed` 隐藏了 TabBar；保持“滚动隐藏”状态，等显示 TabBar
    //      的页面回来后再显示。
    CYLTabBarController *tabBarController = self.tabBarController;
    if (CYLTabBarMinimizeModeClassic == _mode && CYLTabBarMinimizeClassicPageHidesTabBar(tabBarController.selectedViewController)) {
        return;
    }
    _hiddenByScroll = NO;
    if (CYLTabBarMinimizeModeFlatDesign != _mode && CYLTabBarMinimizeModeClassic != _mode) {
        return;
    }
    if (tabBarController.isTabBarHidden) {
        [self setTabBarHiddenFromScroll:NO];
    }
    [self updateCheckTimer];
}

/// [EN] Scroll hiding's own call of the public `-setTabBarHidden:animated:`, marked so it is not taken for the app's.
/// [CN] 滚动隐藏自己调用公开的 `-setTabBarHidden:animated:`，做上标记，避免被当作 App 的调用。
- (void)setTabBarHiddenFromScroll:(BOOL)hidden {
    _settingTabBarHidden = YES;
    _lastOwnRequestHidden = hidden;
    _lastOwnRequestTime = CACurrentMediaTime();
    _appTookTabBarOver = NO;
    // [EN] No slide with Reduce Motion, nor when this window or its scene is not active (resign active, background,
    //      another key window): the app switcher snapshot taken then shows the bar fully back, not halfway.
    // [CN] 开启“减弱动态效果”时不执行滑动动画；本窗口或其 Scene 不活跃时（失去活跃、进入后台、其他窗口成为 key window）也不执行，
    //      使此时拍摄的 App 切换器快照显示完整恢复的 TabBar，而不是动画中途的状态。
    CYLTabBarController *tabBarController = self.tabBarController;
    BOOL animated = !UIAccessibilityIsReduceMotionEnabled() && CYLTabBarMinimizeWindowIsKeyAndActive(tabBarController.viewIfLoaded.window);
    [tabBarController setTabBarHidden:hidden animated:animated];
    _settingTabBarHidden = NO;
}

/*!
 * [EN] The app called `-setTabBarHidden:animated:` itself: it owns the tab bar from now on. A bar hidden by scrolling is
 *      no longer ours to show (it stays as the app wants), and the session ends. Ignored: scroll hiding's own calls, and
 *      a FlatDesign replay of our own last request within 0.5 s.
 * [CN] App 自己调用了 `-setTabBarHidden:animated:`：之后由 App 控制 TabBar。被滚动隐藏的 TabBar 不再由这里显示（保持 App 想要的状态），
 *      会话结束。忽略：滚动隐藏自己的调用，以及 0.5 秒内扁平样式动画对我们最近一次请求的重放。
 */
- (void)appDidRequestTabBarHidden:(BOOL)hidden {
    if (_settingTabBarHidden) {
        return;
    }
    if (hidden == _lastOwnRequestHidden && CACurrentMediaTime() - _lastOwnRequestTime < 0.5) {
        return;
    }
    // [EN] Any accepted app request: the safety net in -minimizeTabBar no longer takes the bar back.
    // [CN] 任何被接受的 App 请求：-minimizeTabBar 中的安全网不再收回 TabBar。
    _appTookTabBarOver = YES;
    if (!_hiddenByScroll && !_hideSessionActive) {
        return;
    }
    CYLTabBarMinimizeLog(@"the app takes the tab bar over", hidden ? @"setTabBarHidden:YES" : @"setTabBarHidden:NO");
    _hiddenByScroll = NO;
    [self endHideSession];
    _needsNewDrag = YES;
    _lastSeenTracking = self.scrollView.isTracking;
    [self updateCheckTimer];
}

/// [EN] FlatDesign guard: the flat tab bar is on screen in the controller's view (not in a transition overlay).
/// [CN] 扁平样式 guard：扁平 TabBar 正显示在控制器的视图中（不在转场 overlay 中）。
- (BOOL)flatDesignCanHideTabBar {
#if CYL_FLATDESIGN_AVAILABLE
    CYLTabBarController *tabBarController = self.tabBarController;
    UIView *tabBar = tabBarController.cyl_tabBar;
    return [tabBar isKindOfClass:[CYLFlatDesignTabBar class]] && !tabBar.hidden && tabBar.superview == tabBarController.view;
#else
    return NO;
#endif
}

/// [EN] Classic guard: the system tab bar is on screen at the bottom, and the page on screen does not hide it through
///      `hidesBottomBarWhenPushed`.
/// [CN] 经典样式 guard：系统 TabBar 正显示在底部，且当前页面没有通过 `hidesBottomBarWhenPushed` 隐藏它。
- (BOOL)classicCanHideTabBar {
    CYLTabBarController *tabBarController = self.tabBarController;
    UITabBar *tabBar = tabBarController.tabBar;
    if (!tabBar || tabBar.hidden || tabBar.alpha < 0.01 || !tabBar.window || !CYLTabBarMinimizeClassicTabBarIsAtBottom(tabBar)) {
        return NO;
    }
    return !CYLTabBarMinimizeClassicPageHidesTabBar(tabBarController.selectedViewController);
}
@end

#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
/// [EN] The native value for a CYLTabBarMinimizeBehavior. [CN] CYLTabBarMinimizeBehavior 对应的系统取值。
static UITabBarMinimizeBehavior CYLSystemTabBarMinimizeBehavior(CYLTabBarMinimizeBehavior behavior) API_AVAILABLE(ios(26.0)) {
    switch (behavior) {
        case CYLTabBarMinimizeBehaviorNever:
            return UITabBarMinimizeBehaviorNever;
        case CYLTabBarMinimizeBehaviorOnScrollDown:
            return UITabBarMinimizeBehaviorOnScrollDown;
        case CYLTabBarMinimizeBehaviorOnScrollUp:
            return UITabBarMinimizeBehaviorOnScrollUp;
        case CYLTabBarMinimizeBehaviorAutomatic:
            break;
    }
    return UITabBarMinimizeBehaviorAutomatic;
}

/// [EN] The CYLTabBarMinimizeBehavior for a native value. [CN] 系统取值对应的 CYLTabBarMinimizeBehavior。
static CYLTabBarMinimizeBehavior CYLTabBarMinimizeBehaviorFromSystem(UITabBarMinimizeBehavior behavior) API_AVAILABLE(ios(26.0)) {
    switch (behavior) {
        case UITabBarMinimizeBehaviorNever:
            return CYLTabBarMinimizeBehaviorNever;
        case UITabBarMinimizeBehaviorOnScrollDown:
            return CYLTabBarMinimizeBehaviorOnScrollDown;
        case UITabBarMinimizeBehaviorOnScrollUp:
            return CYLTabBarMinimizeBehaviorOnScrollUp;
        case UITabBarMinimizeBehaviorAutomatic:
            break;
    }
    return CYLTabBarMinimizeBehaviorAutomatic;
}
#endif

#pragma mark - Item styles in one place

/// [EN] The styles set through `CYLTabBarController (CYLTabBarItemStyle)`, by key. [CN] 通过 `CYLTabBarController (CYLTabBarItemStyle)` 设置的样式。
static char CYLTabBarItemStylesKey;
static NSString *const CYLStyleTitleFont = @"titleFont";
static NSString *const CYLStyleSelectedTitleFont = @"selectedTitleFont";
static NSString *const CYLStyleTitleColor = @"titleColor";
static NSString *const CYLStyleSelectedTitleColor = @"selectedTitleColor";
static NSString *const CYLStyleImageColor = @"imageColor";
static NSString *const CYLStyleSelectedImageColor = @"selectedImageColor";
static NSString *const CYLStyleBackgroundColor = @"backgroundColor";
static NSString *const CYLStyleShadowColor = @"shadowColor";

/// [EN] `attributes` with `value` for `key`, when there is a value. [CN] 有值时，将 `attributes` 中 `key` 设为 `value`。
static NSDictionary<NSAttributedStringKey, id> *CYLAttributesSettingValue(NSDictionary<NSAttributedStringKey, id> *_Nullable attributes, NSAttributedStringKey key, id _Nullable value) {
    NSMutableDictionary<NSAttributedStringKey, id> *result = [attributes mutableCopy] ?: [NSMutableDictionary dictionary];
    if (value) {
        result[key] = value;
    }
    return [result copy];
}

@implementation CYLTabBarController (CYLTabBarItemStyle)

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

- (NSMutableDictionary<NSString *, id> *)cyl_tabBarItemStyles {
    NSMutableDictionary<NSString *, id> *styles = objc_getAssociatedObject(self, &CYLTabBarItemStylesKey);
    if (!styles) {
        styles = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &CYLTabBarItemStylesKey, styles, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return styles;
}

- (void)cyl_setTabBarItemStyle:(nullable id)value forKey:(NSString *)key {
    [self cyl_tabBarItemStyles][key] = value;
    [self cyl_applyTabBarItemStyles];
}

- (nullable UIFont *)cyl_tabBarItemTitleFont { return [self cyl_tabBarItemStyles][CYLStyleTitleFont]; }
- (void)setCyl_tabBarItemTitleFont:(nullable UIFont *)font { [self cyl_setTabBarItemStyle:font forKey:CYLStyleTitleFont]; }
- (nullable UIFont *)cyl_tabBarItemSelectedTitleFont { return [self cyl_tabBarItemStyles][CYLStyleSelectedTitleFont]; }
- (void)setCyl_tabBarItemSelectedTitleFont:(nullable UIFont *)font { [self cyl_setTabBarItemStyle:font forKey:CYLStyleSelectedTitleFont]; }
- (nullable UIColor *)cyl_tabBarItemTitleColor { return [self cyl_tabBarItemStyles][CYLStyleTitleColor]; }
- (void)setCyl_tabBarItemTitleColor:(nullable UIColor *)color { [self cyl_setTabBarItemStyle:color forKey:CYLStyleTitleColor]; }
- (nullable UIColor *)cyl_tabBarItemSelectedTitleColor { return [self cyl_tabBarItemStyles][CYLStyleSelectedTitleColor]; }
- (void)setCyl_tabBarItemSelectedTitleColor:(nullable UIColor *)color { [self cyl_setTabBarItemStyle:color forKey:CYLStyleSelectedTitleColor]; }
- (nullable UIColor *)cyl_tabBarItemImageColor { return [self cyl_tabBarItemStyles][CYLStyleImageColor]; }
- (void)setCyl_tabBarItemImageColor:(nullable UIColor *)color { [self cyl_setTabBarItemStyle:color forKey:CYLStyleImageColor]; }
- (nullable UIColor *)cyl_tabBarItemSelectedImageColor { return [self cyl_tabBarItemStyles][CYLStyleSelectedImageColor]; }
- (void)setCyl_tabBarItemSelectedImageColor:(nullable UIColor *)color { [self cyl_setTabBarItemStyle:color forKey:CYLStyleSelectedImageColor]; }
- (nullable UIColor *)cyl_tabBarBackgroundColor { return [self cyl_tabBarItemStyles][CYLStyleBackgroundColor]; }
- (void)setCyl_tabBarBackgroundColor:(nullable UIColor *)color { [self cyl_setTabBarItemStyle:color forKey:CYLStyleBackgroundColor]; }
- (nullable UIColor *)cyl_tabBarShadowColor { return [self cyl_tabBarItemStyles][CYLStyleShadowColor]; }
- (void)setCyl_tabBarShadowColor:(nullable UIColor *)color { [self cyl_setTabBarItemStyle:color forKey:CYLStyleShadowColor]; }

/*!
 * [EN] Writes the stored styles into the tab bar: the appearances on iOS 13+, the classic styles before.
 * [CN] 把保存的样式写入 TabBar：iOS 13+ 写入 appearance，之前使用经典样式。
 */
- (void)cyl_applyTabBarItemStyles {
    NSDictionary<NSString *, id> *styles = [[self cyl_tabBarItemStyles] copy];
    if (styles.count == 0) {
        return;
    }
    UIFont *titleFont = styles[CYLStyleTitleFont];
    UIFont *selectedTitleFont = styles[CYLStyleSelectedTitleFont] ?: titleFont;
    UIColor *titleColor = styles[CYLStyleTitleColor];
    UIColor *selectedTitleColor = styles[CYLStyleSelectedTitleColor];
    UIColor *imageColor = styles[CYLStyleImageColor];
    UIColor *selectedImageColor = styles[CYLStyleSelectedImageColor];
    UIColor *backgroundColor = styles[CYLStyleBackgroundColor];
    UIColor *shadowColor = styles[CYLStyleShadowColor];
    UITabBar *tabBar = self.tabBar;
    if (@available(iOS 13.0, *)) {
        void (^apply)(UITabBarAppearance *) = ^(UITabBarAppearance *appearance) {
            if (backgroundColor) {
                appearance.backgroundColor = backgroundColor;
            }
            if (shadowColor) {
                appearance.shadowColor = shadowColor;
            }
            [appearance cyl_applyItemAppearanceWithBlock:^(UITabBarItemAppearance *itemAppearance) {
                NSDictionary *normalAttributes = CYLAttributesSettingValue(itemAppearance.normal.titleTextAttributes, NSFontAttributeName, titleFont);
                itemAppearance.normal.titleTextAttributes = CYLAttributesSettingValue(normalAttributes, NSForegroundColorAttributeName, titleColor);
                NSDictionary *selectedAttributes = CYLAttributesSettingValue(itemAppearance.selected.titleTextAttributes, NSFontAttributeName, selectedTitleFont);
                itemAppearance.selected.titleTextAttributes = CYLAttributesSettingValue(selectedAttributes, NSForegroundColorAttributeName, selectedTitleColor);
                if (imageColor) {
                    itemAppearance.normal.iconColor = imageColor;
                }
                if (selectedImageColor) {
                    itemAppearance.selected.iconColor = selectedImageColor;
                }
            }];
        };
        UITabBarAppearance *standardAppearance = [tabBar.standardAppearance copy];
        apply(standardAppearance);
        tabBar.standardAppearance = standardAppearance;
        if (@available(iOS 15.0, *)) {
            if (tabBar.scrollEdgeAppearance) {
                UITabBarAppearance *scrollEdgeAppearance = [tabBar.scrollEdgeAppearance copy];
                apply(scrollEdgeAppearance);
                tabBar.scrollEdgeAppearance = scrollEdgeAppearance;
            }
        }
        [self cyl_syncTabBarAppearances];
        return;
    }
    for (UIViewController *viewController in self.viewControllers) {
        UITabBarItem *item = viewController.tabBarItem;
        NSDictionary *normalAttributes = CYLAttributesSettingValue([item titleTextAttributesForState:UIControlStateNormal], NSFontAttributeName, titleFont);
        [item setTitleTextAttributes:CYLAttributesSettingValue(normalAttributes, NSForegroundColorAttributeName, titleColor) forState:UIControlStateNormal];
        NSDictionary *selectedAttributes = CYLAttributesSettingValue([item titleTextAttributesForState:UIControlStateSelected], NSFontAttributeName, selectedTitleFont);
        [item setTitleTextAttributes:CYLAttributesSettingValue(selectedAttributes, NSForegroundColorAttributeName, selectedTitleColor) forState:UIControlStateSelected];
    }
    if (imageColor) {
        tabBar.unselectedItemTintColor = imageColor;
    }
    if (selectedImageColor) {
        tabBar.tintColor = selectedImageColor;
    }
    if (backgroundColor) {
        tabBar.barTintColor = backgroundColor;
    }
    if (shadowColor) {
        CGFloat lineHeight = 1.0 / UIScreen.mainScreen.scale;
        tabBar.shadowImage = [UIImage cyl_imageWithColor:shadowColor size:CGSizeMake(1, lineHeight)];
    }
}

@end

#pragma mark - Opaque tab bar safe area

/// [EN] The bottom this library added to a page's `additionalSafeAreaInsets`. [CN] 本库为页面 `additionalSafeAreaInsets` 增加的底部值。
static char CYLOpaqueTabBarAddedBottomKey;
/// [EN] The page's safe area bottom when the library last wrote its inset. [CN] 本库上次写入时页面安全区域的底部值。
static char CYLOpaqueTabBarSafeBottomAtWriteKey;
static char CYLFixesOpaqueTabBarSafeAreaInsetsKey;

@implementation CYLTabBarController (CYLOpaqueTabBarSafeArea)

- (BOOL)cyl_fixesOpaqueTabBarSafeAreaInsets {
    NSNumber *value = objc_getAssociatedObject(self, &CYLFixesOpaqueTabBarSafeAreaInsetsKey);
    return value ? value.boolValue : YES;
}

- (void)setCyl_fixesOpaqueTabBarSafeAreaInsets:(BOOL)fixes {
    objc_setAssociatedObject(self, &CYLFixesOpaqueTabBarSafeAreaInsetsKey, @(fixes), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded];
}

/*!
 * [EN] UIKit bug: a page that extends under an opaque tab bar (`tabBar.translucent = NO` with
 *      `extendedLayoutIncludesOpaqueBars = YES`; before iOS 13.4 also a translucent bar) gets a bottom safe area that
 *      leaves the tab bar out, so the end of its scroll view stays under the bar. The page now shown in the selected tab
 *      gets the missing part in its `additionalSafeAreaInsets.bottom`, on top of the app's own value, which is kept. Self
 *      correcting: when UIKit gets it right the missing part is 0 and nothing changes, and a part added before is taken
 *      back when the page is no longer affected. Only the page itself, never its child view controllers. Not FlatDesign,
 *      which sets the safe area itself.
 * [CN] UIKit bug：延伸到不透明 TabBar 下方的页面（`tabBar.translucent = NO` 且 `extendedLayoutIncludesOpaqueBars = YES`；iOS 13.4 以前
 *      半透明 TabBar 也有此问题）得到的底部安全区域没有包含 TabBar，滚动视图的末尾因此被 TabBar 遮挡。选中 Tab 当前显示的页面会在其
 *      `additionalSafeAreaInsets.bottom` 中补上缺少的部分，App 自己设置的值保留不变。可自我修正：UIKit 计算正确时缺少的部分为 0，不做任何修改；
 *      页面不再受影响时撤回之前补上的部分。只作用于页面本身，不作用于其子控制器。扁平样式自行设置安全区域，不做处理。
 */
- (void)cyl_fixOpaqueTabBarSafeAreaInsetsIfNeeded {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType || !self.isViewLoaded || !self.view.window) {
        return;
    }
    UIViewController *selectedViewController = self.selectedViewController;
    UINavigationController *navigationController = [selectedViewController isKindOfClass:[UINavigationController class]] ? (UINavigationController *)selectedViewController : nil;
    UIViewController *page = navigationController ? navigationController.topViewController : selectedViewController;
    if (!page || !page.isViewLoaded || !page.view.window) {
        return;
    }
    UITabBar *tabBar = self.tabBar;
    BOOL barIsAffected = !tabBar.translucent;
    if (@available(iOS 13.4, *)) {
    } else {
        barIsAffected = YES;
    }
    BOOL pageHidesTabBar = NO;
    for (UIViewController *viewController in navigationController.viewControllers) {
        if (viewController.hidesBottomBarWhenPushed && viewController != navigationController.viewControllers.firstObject) {
            pageHidesTabBar = YES;
        }
        if (viewController == page) {
            break;
        }
    }
    BOOL affected = self.cyl_fixesOpaqueTabBarSafeAreaInsets && barIsAffected && page.extendedLayoutIncludesOpaqueBars &&
                    (page.edgesForExtendedLayout & UIRectEdgeBottom) && !pageHidesTabBar &&
                    !tabBar.hidden && tabBar.alpha > 0.01 && tabBar.window;
    CGFloat addedBottom = [objc_getAssociatedObject(page, &CYLOpaqueTabBarAddedBottomKey) doubleValue];
    UIEdgeInsets additionalInsets = page.additionalSafeAreaInsets;
    // [EN] Written, but the page has not been laid out with it yet: its safe area is stale, which would add the part again.
    // [CN] 已写入，但页面尚未据此重新布局：此时的安全区域是旧值，会把缺少的部分再加一次。
    NSNumber *safeBottomAtWrite = objc_getAssociatedObject(page, &CYLOpaqueTabBarSafeBottomAtWriteKey);
    if (safeBottomAtWrite && fabs(page.view.safeAreaInsets.bottom - safeBottomAtWrite.doubleValue) < 0.5 && addedBottom > 0) {
        return;
    }
    CGFloat appBottom = additionalInsets.bottom - addedBottom;
    CGFloat neededBottom = 0;
    if (affected) {
        CGRect pageRect = [page.view convertRect:page.view.bounds toView:self.view];
        CGRect barRect = [tabBar convertRect:tabBar.bounds toView:self.view];
        CGFloat coveredBottom = MAX(CGRectGetMaxY(pageRect) - CGRectGetMinY(barRect), 0);
        // [EN] What UIKit gives without any additional inset. [CN] 不含任何 additional inset 时 UIKit 给出的值。
        CGFloat systemBottom = page.view.safeAreaInsets.bottom - additionalInsets.bottom;
        neededBottom = MAX(coveredBottom - systemBottom - appBottom, 0);
    }
    if (fabs(neededBottom - addedBottom) < 0.5) {
        return;
    }
    CGFloat safeBottomBeforeWrite = page.view.safeAreaInsets.bottom;
    additionalInsets.bottom = appBottom + neededBottom;
    page.additionalSafeAreaInsets = additionalInsets;
    objc_setAssociatedObject(page, &CYLOpaqueTabBarAddedBottomKey, neededBottom > 0 ? @(neededBottom) : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(page, &CYLOpaqueTabBarSafeBottomAtWriteKey, neededBottom > 0 ? @(safeBottomBeforeWrite) : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

#pragma mark - Theme switching (issue #216)

/// [EN] What the app had set before the first theme changed it. [CN] 第一次被主题修改前 App 自己的设置。
static char CYLThemeOriginalTabBarItemsAttributesKey;
static char CYLThemeOriginalStandardAppearanceKey;
static char CYLThemeOriginalScrollEdgeAppearanceKey;
/// [EN] The launch theme was applied (or a theme change came first). [CN] 已应用启动时的主题（或已先收到主题切换）。
static char CYLThemeLaunchThemeAppliedKey;
/// [EN] Theme icons: the icon view provider each tab had before the theme replaced it (`NSNull` for none), the provider
///      the theme installed, and a counter that drops icons still loading when another theme is applied.
/// [CN] 主题图标：主题替换前每个 Tab 的图标视图 provider（没有时为 `NSNull`）、主题安装的 provider，以及一个计数器：应用其他主题时，
///      丢弃仍在加载的图标。
static char CYLThemeOriginalIconViewProvidersKey;
static char CYLThemeInstalledIconViewProvidersKey;
static char CYLThemeIconGenerationKey;
/// [EN] The plus button in a theme: its own title and images before the theme changed them (`NSNull` for none), what
///      the theme set, and a counter that drops images still loading when another theme is applied.
/// [CN] 主题中的 PlusButton：主题修改前它自己的标题与图片（没有时为 `NSNull`）、主题设置的内容，以及一个计数器：应用其他主题时，
///      丢弃仍在加载的图片。
static char CYLThemeOriginalPlusButtonPartsKey;
static char CYLThemeInstalledPlusButtonPartsKey;
static char CYLThemePlusButtonGenerationKey;
/// [EN] The three parts of the plus button a theme can change. [CN] 主题可以修改的 PlusButton 三个部分。
static NSString *const CYLThemePlusButtonPartTitle = @"title";
static NSString *const CYLThemePlusButtonPartImage = @"image";
static NSString *const CYLThemePlusButtonPartSelectedImage = @"selectedImage";

/// [EN] What the plus button shows now for `part`. [CN] PlusButton 当前显示的 `part`。
static id _Nullable CYLThemePlusButtonCurrentPart(CYLPlusButton *plusButton, NSString *part) {
    if ([part isEqualToString:CYLThemePlusButtonPartTitle]) {
        return plusButton.cyl_title;
    }
    return [plusButton imageForState:([part isEqualToString:CYLThemePlusButtonPartImage] ? UIControlStateNormal : UIControlStateSelected)];
}

/// [EN] The icon keys of `tabBarItemsAttributes`. [CN] `tabBarItemsAttributes` 中与图标有关的 key。
static NSArray<NSString *> *CYLThemeIconAttributeKeys(void) {
    return @[ CYLTabBarItemImage, CYLTabBarItemSelectedImage, CYLTabBarItemDarkImage, CYLTabBarItemSelectedDarkImage,
              CYLTabBarItemImageURL, CYLTabBarItemSelectedImageURL, CYLTabBarItemImageURLSize ];
}

/// [EN] `attributes` without its icon keys. [CN] 去掉图标 key 的 `attributes`。
static NSDictionary<NSString *, id> *CYLThemeAttributesWithoutIcons(NSDictionary<NSString *, id> *attributes) {
    NSMutableDictionary *withoutIcons = [attributes mutableCopy] ?: [NSMutableDictionary dictionary];
    [withoutIcons removeObjectsForKeys:CYLThemeIconAttributeKeys()];
    return [withoutIcons copy];
}

@implementation CYLTabBarController (CYLTheme)

- (void)cyl_themeDidChangeByManager:(CYLThemeManager *)manager identifier:(nullable __kindof NSObject<NSCopying> *)identifier theme:(nullable __kindof NSObject *)theme {
    [super cyl_themeDidChangeByManager:manager identifier:identifier theme:theme];
    // [EN] The default manager drives the tab bar; another manager (e.g. the themes of one page) only with a tab bar theme.
    // [CN] 默认管理器决定 TabBar 外观；其他管理器（例如某个页面自己的主题）仅在其主题为 TabBar 主题时生效。
    BOOL isDefaultManager = [manager.name isEqual:CYLThemeManagerNameDefault];
    if (!isDefaultManager && ![theme conformsToProtocol:@protocol(CYLTabBarTheme)]) {
        return;
    }
    [self cyl_applyTabBarTheme:theme];
}

- (void)cyl_applyLaunchTabBarThemeIfNeeded {
    if (objc_getAssociatedObject(self, &CYLThemeLaunchThemeAppliedKey)) {
        return;
    }
    objc_setAssociatedObject(self, &CYLThemeLaunchThemeAppliedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // [EN] Styles set before the tab bar was replaced by the library's own (CYLTabBar) are written into the bar shown now.
    // [CN] 在 TabBar 被替换为本库的 CYLTabBar 之前设置的样式，写入当前显示的 TabBar。
    [self cyl_applyTabBarItemStyles];
    id theme = CYLThemeManagerCenter.defaultThemeManager.currentTheme;
    // [EN] Nothing to restore yet: only a tab bar theme changes anything here.
    // [CN] 此时尚无需恢复：只有 TabBar 主题才需要处理。
    if ([theme conformsToProtocol:@protocol(CYLTabBarTheme)]) {
        [self cyl_applyTabBarTheme:theme];
    }
}

- (void)cyl_applyTabBarTheme:(id)theme {
    objc_setAssociatedObject(self, &CYLThemeLaunchThemeAppliedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    id<CYLTabBarTheme> tabBarTheme = [theme conformsToProtocol:@protocol(CYLTabBarTheme)] ? theme : nil;

    NSArray<NSDictionary<NSString *, id> *> *itemsAttributes = nil;
    if ([tabBarTheme respondsToSelector:@selector(cyl_tabBarItemsAttributesForTabBarController:)]) {
        itemsAttributes = [tabBarTheme cyl_tabBarItemsAttributesForTabBarController:self];
    }

    // [EN] Titles and the other keys, in place (issue #601), without the icon keys: the icons follow below.
    // [CN] 原地更新标题与其他 key（issue #601），不含图标 key：图标在下面处理。
    NSMutableArray<NSDictionary<NSString *, id> *> *itemsAttributesWithoutIcons = [NSMutableArray array];
    BOOL hasOtherKeys = NO;
    for (NSDictionary<NSString *, id> *attributes in itemsAttributes) {
        NSDictionary<NSString *, id> *withoutIcons = CYLThemeAttributesWithoutIcons(attributes);
        hasOtherKeys = hasOtherKeys || withoutIcons.count > 0;
        [itemsAttributesWithoutIcons addObject:withoutIcons];
    }
    NSArray *originalItemsAttributes = objc_getAssociatedObject(self, &CYLThemeOriginalTabBarItemsAttributesKey);
    if (hasOtherKeys) {
        if (!originalItemsAttributes) {
            NSMutableArray *original = [NSMutableArray array];
            for (NSDictionary<NSString *, id> *attributes in self.tabBarItemsAttributes) {
                [original addObject:CYLThemeAttributesWithoutIcons(attributes)];
            }
            objc_setAssociatedObject(self, &CYLThemeOriginalTabBarItemsAttributesKey, [original copy], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        [self updateTabBarItemsWithAttributes:itemsAttributesWithoutIcons];
    } else if (originalItemsAttributes) {
        [self updateTabBarItemsWithAttributes:originalItemsAttributes];
        objc_setAssociatedObject(self, &CYLThemeOriginalTabBarItemsAttributesKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // [EN] The icons, as views in place of each tab's icon (`-setTabBarItemIcon:selectedIcon:size:atIndex:`).
    // [CN] 图标：以视图替换每个 Tab 的图标（`-setTabBarItemIcon:selectedIcon:size:atIndex:`）。
    [self cyl_applyThemeIconsOfItemsAttributes:itemsAttributes];

    // [EN] The plus button's title and images (`-updatePlusButtonWithAttributes:`).
    // [CN] PlusButton 的标题与图片（`-updatePlusButtonWithAttributes:`）。
    NSDictionary<NSString *, id> *plusButtonAttributes = nil;
    if ([tabBarTheme respondsToSelector:@selector(cyl_plusButtonAttributesForTabBarController:)]) {
        plusButtonAttributes = [tabBarTheme cyl_plusButtonAttributesForTabBarController:self];
    }
    [self cyl_applyThemePlusButtonAttributes:plusButtonAttributes];

    // [EN] The appearance: a new object for every theme, so every style (FlatDesign included) applies it.
    // [CN] 外观：每个主题都是新对象，因此所有样式（包括扁平样式）都会应用。
    if (@available(iOS 13.0, *)) {
        UITabBar *tabBar = self.tabBar;
        UITabBarAppearance *appearance = nil;
        if ([tabBarTheme respondsToSelector:@selector(cyl_tabBarAppearanceForTabBarController:)]) {
            appearance = [tabBarTheme cyl_tabBarAppearanceForTabBarController:self];
        }
        id originalStandardAppearance = objc_getAssociatedObject(self, &CYLThemeOriginalStandardAppearanceKey);
        if (appearance) {
            if (!originalStandardAppearance) {
                objc_setAssociatedObject(self, &CYLThemeOriginalStandardAppearanceKey, tabBar.standardAppearance, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                if (@available(iOS 15.0, *)) {
                    objc_setAssociatedObject(self, &CYLThemeOriginalScrollEdgeAppearanceKey, tabBar.scrollEdgeAppearance ?: [NSNull null], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                }
            }
            tabBar.standardAppearance = appearance;
            if (@available(iOS 15.0, *)) {
                tabBar.scrollEdgeAppearance = [appearance copy];
            }
        } else if ([originalStandardAppearance isKindOfClass:[UITabBarAppearance class]]) {
            tabBar.standardAppearance = originalStandardAppearance;
            if (@available(iOS 15.0, *)) {
                id originalScrollEdgeAppearance = objc_getAssociatedObject(self, &CYLThemeOriginalScrollEdgeAppearanceKey);
                tabBar.scrollEdgeAppearance = [originalScrollEdgeAppearance isKindOfClass:[UITabBarAppearance class]] ? originalScrollEdgeAppearance : nil;
            }
            objc_setAssociatedObject(self, &CYLThemeOriginalStandardAppearanceKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(self, &CYLThemeOriginalScrollEdgeAppearanceKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        // [EN] Bring the title offset copies (issue #475) and the flat design tab bar up to date now.
        // [CN] 立即更新标题偏移副本（issue #475）与扁平样式 TabBar。
        [self cyl_syncTabBarAppearances];
    }

    if ([tabBarTheme respondsToSelector:@selector(cyl_customizeTabBarController:)]) {
        [tabBarTheme cyl_customizeTabBarController:self];
    }
    // [EN] Styles set in one place win over the theme's appearance. [CN] 在一处设置的样式优先于主题的外观。
    [self cyl_applyTabBarItemStyles];
}

/*!
 * [EN] The theme's icons, with the mechanism of `-setTabBarItemIcon:selectedIcon:size:atIndex:` (the "change all local
 *      icons" demo row): a view in place of each tab's icon, in every style (Liquid Glass, its selected layer included,
 *      the system tab bar, FlatDesign), also over a Lottie icon, drawn with its own colors. Setting `tabBarItem.image`
 *      did not show on Liquid Glass with Lottie icons, and made UIKit rebuild the tab buttons.
 *      - The icon of an entry: `CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL` (with `CYLTabBarItemImageURLSize`)
 *        win; else `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage`, combined with their dark images. Any source
 *        `-setTabBarItemIcon:...` takes: a UIImage, a name, a path, a URL.
 *      - Before the first theme icon, the tab's own provider (or none) is kept; a tab the new theme gives no icon gets it
 *        back, unless the app replaced the theme's icon meanwhile.
 *      - Icons are loaded first (network ones asynchronously) and shown only if no other theme came in between.
 * [CN] 主题图标，使用 `-setTabBarItemIcon:selectedIcon:size:atIndex:` 的机制（演示中的“修改所有本地图标”行）：以视图替换每个 Tab 的图标，
 *      适用于所有样式（液态玻璃，包括其选中图层；系统 TabBar；扁平样式），也能覆盖 Lottie 图标，按原图颜色绘制。原来设置
 *      `tabBarItem.image` 的方式在使用 Lottie 图标的液态玻璃上不显示，并会让 UIKit 重建 Tab 按钮。
 *      - 每项的图标：`CYLTabBarItemImageURL` / `CYLTabBarItemSelectedImageURL`（及 `CYLTabBarItemImageURLSize`）优先；否则为
 *        `CYLTabBarItemImage` / `CYLTabBarItemSelectedImage`，并与其深色图片合成。支持 `-setTabBarItemIcon:...` 的所有来源：UIImage、
 *        图片名、文件路径、URL。
 *      - 第一次设置主题图标前，保存该 Tab 自己的 provider（或没有）；新主题未提供图标的 Tab 恢复它，除非 App 期间替换了主题图标。
 *      - 先加载图标（网络图标为异步），只有期间没有切换到其他主题时才显示。
 */
- (void)cyl_applyThemeIconsOfItemsAttributes:(nullable NSArray<NSDictionary<NSString *, id> *> *)itemsAttributes {
    NSUInteger generation = [objc_getAssociatedObject(self, &CYLThemeIconGenerationKey) unsignedIntegerValue] + 1;
    objc_setAssociatedObject(self, &CYLThemeIconGenerationKey, @(generation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSMapTable<UIViewController *, id> *originalProviders = objc_getAssociatedObject(self, &CYLThemeOriginalIconViewProvidersKey);
    NSMapTable<UIViewController *, id> *installedProviders = objc_getAssociatedObject(self, &CYLThemeInstalledIconViewProvidersKey);
    if (!originalProviders) {
        originalProviders = [NSMapTable weakToStrongObjectsMapTable];
        installedProviders = [NSMapTable weakToStrongObjectsMapTable];
        objc_setAssociatedObject(self, &CYLThemeOriginalIconViewProvidersKey, originalProviders, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, &CYLThemeInstalledIconViewProvidersKey, installedProviders, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSMapTable<UIViewController *, CYLTabBarItemIconViewProvider> *providers = [self cyl_tabBarItemIconViewProviders];

    // [EN] The icon of each tab in this theme, by view controller (as `-updateTabBarItemsWithAttributes:`: one entry per
    //      tab, none for the plus button).
    // [CN] 该主题下每个 Tab 的图标，按子控制器保存（与 `-updateTabBarItemsWithAttributes:` 相同：每个 Tab 一项，PlusButton 不占项）。
    NSMapTable<UIViewController *, NSDictionary *> *themeIcons = [NSMapTable weakToStrongObjectsMapTable];
    NSUInteger attributesIndex = 0;
    for (NSUInteger index = 0; index < _viewControllers.count && attributesIndex < itemsAttributes.count; index++) {
        UIViewController *viewController = _viewControllers[index];
        if (viewController.cyl_isPlaceholder || viewController == [self cyl_contextPlusChildViewController]) {
            continue;
        }
        NSDictionary<NSString *, id> *attributes = itemsAttributes[attributesIndex++];
        id icon = attributes[CYLTabBarItemImageURL];
        id selectedIcon = attributes[CYLTabBarItemSelectedImageURL];
        NSValue *sizeValue = attributes[CYLTabBarItemImageURLSize];
        if (!icon) {
            id image = attributes[CYLTabBarItemImage];
            id selectedImage = attributes[CYLTabBarItemSelectedImage];
            // [EN] With a dark image, the combined image (names and UIImages); else the source as it is.
            // [CN] 有深色图片时为合成后的图片（图片名与 UIImage）；否则原样使用该来源。
            icon = attributes[CYLTabBarItemDarkImage] ? [UIImage cyl_imageWithImageInfo:image darkImageInfo:attributes[CYLTabBarItemDarkImage]] : image;
            selectedIcon = attributes[CYLTabBarItemSelectedDarkImage] ?
                [UIImage cyl_imageWithImageInfo:selectedImage darkImageInfo:attributes[CYLTabBarItemSelectedDarkImage]] : selectedImage;
            if (!icon) {
                icon = selectedIcon;
            }
        }
        if (!icon) {
            continue;
        }
        NSMutableDictionary *tabIcon = [NSMutableDictionary dictionaryWithObject:icon forKey:@"icon"];
        tabIcon[@"selectedIcon"] = selectedIcon;
        tabIcon[@"size"] = [sizeValue isKindOfClass:[NSValue class]] ? sizeValue : nil;
        [themeIcons setObject:[tabIcon copy] forKey:viewController];
    }

    // [EN] Tabs with a theme icon before: an icon the app set meanwhile becomes the one to restore; a tab without an icon
    //      in this theme gets its own provider back.
    // [CN] 之前有主题图标的 Tab：App 期间设置的图标成为要恢复的图标；本主题中没有图标的 Tab 恢复自己的 provider。
    for (UIViewController *viewController in originalProviders.keyEnumerator.allObjects) {
        id installed = [installedProviders objectForKey:viewController];
        id current = [providers objectForKey:viewController];
        BOOL replacedByApp = installed && current != installed;
        if (replacedByApp) {
            [originalProviders setObject:(current ?: [NSNull null]) forKey:viewController];
            [installedProviders removeObjectForKey:viewController];
        }
        if ([themeIcons objectForKey:viewController]) {
            continue;
        }
        id original = [originalProviders objectForKey:viewController];
        NSUInteger index = [_viewControllers indexOfObject:viewController];
        if (!replacedByApp && index != NSNotFound) {
            [self setTabBarItemIconViewProvider:([original isKindOfClass:[NSNull class]] ? nil : original) atIndex:index];
        }
        [originalProviders removeObjectForKey:viewController];
        [installedProviders removeObjectForKey:viewController];
    }

    // [EN] The theme's icons. [CN] 主题图标。
    __weak __typeof(self) weakSelf = self;
    for (UIViewController *viewController in themeIcons.keyEnumerator.allObjects) {
        if (![originalProviders objectForKey:viewController]) {
            id provider = [providers objectForKey:viewController];
            [originalProviders setObject:(provider ?: [NSNull null]) forKey:viewController];
        }
        NSDictionary *tabIcon = [themeIcons objectForKey:viewController];
        __weak UIViewController *weakViewController = viewController;
        CYLLoadTabBarItemIcon(tabIcon[@"icon"], ^(UIImage *image) {
            void (^show)(UIImage *) = ^(UIImage *selectedImage) {
                __strong __typeof(weakSelf) self = weakSelf;
                UIViewController *strongViewController = weakViewController;
                // [EN] Dropped when another theme came in between, or the tab is gone. [CN] 期间切换了其他主题或 Tab 已不存在时丢弃。
                if (!self || !strongViewController || !image ||
                    [objc_getAssociatedObject(self, &CYLThemeIconGenerationKey) unsignedIntegerValue] != generation) {
                    return;
                }
                NSUInteger index = [self.viewControllers indexOfObject:strongViewController];
                NSValue *sizeValue = tabIcon[@"size"];
                CGSize size = sizeValue ? sizeValue.CGSizeValue : CGSizeZero;
                if (index == NSNotFound || ![self setTabBarItemIcon:image selectedIcon:selectedImage size:size atIndex:index]) {
                    return;
                }
                id installed = [[self cyl_tabBarItemIconViewProviders] objectForKey:strongViewController];
                NSMapTable *installedMap = objc_getAssociatedObject(self, &CYLThemeInstalledIconViewProvidersKey);
                if (installed) {
                    [installedMap setObject:installed forKey:strongViewController];
                }
            };
            id selectedIcon = tabIcon[@"selectedIcon"];
            if (!selectedIcon || [selectedIcon isEqual:tabIcon[@"icon"]]) {
                show(nil);
            } else {
                CYLLoadTabBarItemIcon(selectedIcon, show);
            }
        });
    }
}

/*!
 * [EN] The theme's plus button, through `-updatePlusButtonWithAttributes:` (as the "change all titles" and "change all
 *      network icons" demo rows), one part at a time: the title, the image, the selected image.
 *      - Before the first change of a part, what the plus button shows is kept (`NSNull` for nothing).
 *      - A part the app changed after the theme becomes the one to restore, and is not touched again by this theme.
 *      - A part this theme does not give gets its own value back. An image the plus button never had is restored as
 *        the normal image (a button without a selected image shows its normal one); a title it never had as "".
 *      - Images are loaded first (network ones asynchronously) and shown only if no other theme came in between.
 * [CN] 主题中的 PlusButton，通过 `-updatePlusButtonWithAttributes:`（与演示中“批量更换标题”“批量下载网络图标”行相同）逐个部分处理：
 *      标题、图片、选中图片。
 *      - 第一次修改某个部分前，保存 PlusButton 当时显示的内容（没有时为 `NSNull`）。
 *      - 主题之后被 App 修改的部分成为要恢复的内容，本主题不再修改它。
 *      - 本主题未提供的部分恢复为它自己的内容。PlusButton 原本没有的图片恢复为普通图片（按钮没有选中图片时显示普通图片）；原本没有的
 *        标题恢复为 ""。
 *      - 先加载图片（网络图片为异步），只有期间没有切换到其他主题时才显示。
 */
- (void)cyl_applyThemePlusButtonAttributes:(nullable NSDictionary<NSString *, id> *)attributes {
    CYLPlusButton *plusButton = [CYLPlusButton plusButtonForOwner:self];
    if (!plusButton) {
        return;
    }
    NSUInteger generation = [objc_getAssociatedObject(self, &CYLThemePlusButtonGenerationKey) unsignedIntegerValue] + 1;
    objc_setAssociatedObject(self, &CYLThemePlusButtonGenerationKey, @(generation), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    NSMutableDictionary<NSString *, id> *originalParts = objc_getAssociatedObject(self, &CYLThemeOriginalPlusButtonPartsKey);
    NSMutableDictionary<NSString *, id> *installedParts = objc_getAssociatedObject(self, &CYLThemeInstalledPlusButtonPartsKey);
    if (!originalParts) {
        originalParts = [NSMutableDictionary dictionary];
        installedParts = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &CYLThemeOriginalPlusButtonPartsKey, originalParts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, &CYLThemeInstalledPlusButtonPartsKey, installedParts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    // [EN] What this theme gives, by part. [CN] 本主题提供的内容，按部分保存。
    NSMutableDictionary<NSString *, id> *themeParts = [NSMutableDictionary dictionary];
    themeParts[CYLThemePlusButtonPartTitle] = attributes[CYLTabBarItemTitle];
    themeParts[CYLThemePlusButtonPartImage] = attributes[CYLTabBarItemImageURL] ?: attributes[CYLTabBarItemImage];
    themeParts[CYLThemePlusButtonPartSelectedImage] = attributes[CYLTabBarItemSelectedImageURL] ?: attributes[CYLTabBarItemSelectedImage];
    NSValue *sizeValue = attributes[CYLTabBarItemImageURLSize];

    for (NSString *part in @[ CYLThemePlusButtonPartTitle, CYLThemePlusButtonPartImage, CYLThemePlusButtonPartSelectedImage ]) {
        id current = CYLThemePlusButtonCurrentPart(plusButton, part);
        id installed = installedParts[part];
        // [EN] Changed by the app after the theme: that is the plus button's own value now.
        // [CN] 主题之后被 App 修改：这就是 PlusButton 现在自己的内容。
        if (installed && ![current isEqual:installed]) {
            originalParts[part] = current ?: [NSNull null];
            [installedParts removeObjectForKey:part];
        }
        id themeValue = themeParts[part];
        if (!themeValue) {
            // [EN] Back to the plus button's own value, unless the app changed it (then nothing was installed).
            // [CN] 恢复 PlusButton 自己的内容，除非 App 修改过（此时没有记录主题设置的内容）。
            id original = originalParts[part];
            if (original && installedParts[part]) {
                [self cyl_restoreThemePlusButtonPart:part original:original plusButton:plusButton];
            }
            [originalParts removeObjectForKey:part];
            [installedParts removeObjectForKey:part];
            continue;
        }
        if (!originalParts[part]) {
            originalParts[part] = current ?: [NSNull null];
        }
        if ([part isEqualToString:CYLThemePlusButtonPartTitle]) {
            if ([self updatePlusButtonWithAttributes:@{ CYLTabBarItemTitle : themeValue }]) {
                installedParts[part] = CYLThemePlusButtonCurrentPart(plusButton, part) ?: themeValue;
            }
            continue;
        }
        __weak __typeof(self) weakSelf = self;
        __weak CYLPlusButton *weakPlusButton = plusButton;
        CYLLoadTabBarItemIcon(themeValue, ^(UIImage *image) {
            __strong __typeof(weakSelf) self = weakSelf;
            CYLPlusButton *strongPlusButton = weakPlusButton;
            // [EN] Dropped when another theme came in between. [CN] 期间切换了其他主题时丢弃。
            if (!self || !strongPlusButton || !image ||
                [objc_getAssociatedObject(self, &CYLThemePlusButtonGenerationKey) unsignedIntegerValue] != generation) {
                return;
            }
            NSString *imageKey = [part isEqualToString:CYLThemePlusButtonPartImage] ? CYLTabBarItemImage : CYLTabBarItemSelectedImage;
            NSMutableDictionary *imageAttributes = [NSMutableDictionary dictionaryWithObject:image forKey:imageKey];
            imageAttributes[CYLTabBarItemImageURLSize] = [sizeValue isKindOfClass:[NSValue class]] ? sizeValue : nil;
            if ([self updatePlusButtonWithAttributes:imageAttributes]) {
                NSMutableDictionary *installedMap = objc_getAssociatedObject(self, &CYLThemeInstalledPlusButtonPartsKey);
                installedMap[part] = CYLThemePlusButtonCurrentPart(strongPlusButton, part);
            }
        });
    }
}

/// [EN] Puts the plus button's own `part` back. [CN] 恢复 PlusButton 自己的 `part`。
- (void)cyl_restoreThemePlusButtonPart:(NSString *)part original:(id)original plusButton:(CYLPlusButton *)plusButton {
    BOOL hadNothing = [original isKindOfClass:[NSNull class]];
    if ([part isEqualToString:CYLThemePlusButtonPartTitle]) {
        [plusButton cyl_updateTitle:(hadNothing ? @"" : original) image:nil selectedImage:nil];
        return;
    }
    if ([part isEqualToString:CYLThemePlusButtonPartImage]) {
        if (!hadNothing) {
            [plusButton cyl_updateTitle:nil image:original selectedImage:nil];
        }
        return;
    }
    // [EN] No selected image of its own: the normal one, as a button without a selected image shows.
    // [CN] 原本没有选中图片：使用普通图片，与没有选中图片的按钮显示一致。
    UIImage *selectedImage = hadNothing ? [plusButton imageForState:UIControlStateNormal] : original;
    if (selectedImage) {
        [plusButton cyl_updateTitle:nil image:nil selectedImage:selectedImage];
    }
}

@end

@implementation CYLTabBarController (CYLTabBarMinimize)

- (CYLTabBarMinimizeBehavior)cyl_tabBarMinimizeBehavior {
    NSNumber *behavior = objc_getAssociatedObject(self, CYLTabBarMinimizeBehaviorKey);
    return (CYLTabBarMinimizeBehavior)behavior.integerValue;
}

- (void)setCyl_tabBarMinimizeBehavior:(CYLTabBarMinimizeBehavior)behavior {
    objc_setAssociatedObject(self, CYLTabBarMinimizeBehaviorKey, @(behavior), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
    // [EN] A new value from the app ends a Liquid Glass hold. [CN] App 设置新取值时结束液态玻璃的保持状态。
    objc_setAssociatedObject(self, CYLTabBarMinimizeHoldsSystemNeverKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
#endif
    [self cyl_updateTabBarMinimizeTracking];
}

/*!
 * [EN] Liquid Glass: UIKit has no API to expand a minimized tab bar. Writing `Never` (through `super`) makes the system
 *      expand it; `Never` is held until the user starts a new drag (`-cyl_releaseSystemMinimizeHoldIfNeeded`), then the
 *      app's value is written back, so minimizing on scroll keeps working. Does nothing on other systems or when the
 *      system value is already `Never`.
 * [CN] 液态玻璃：UIKit 没有恢复已缩小 TabBar 的接口。通过 `super` 写入 `Never` 让系统恢复 TabBar；`Never` 保持到用户开始新的拖动
 *      （`-cyl_releaseSystemMinimizeHoldIfNeeded`），之后写回 App 的取值，滚动缩小继续生效。其他系统或系统取值已是 `Never` 时不做处理。
 */
- (void)cyl_expandSystemMinimizedTabBar {
#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
    if (@available(iOS 26.0, *)) {
        if (UITabBarMinimizeBehaviorNever == [super tabBarMinimizeBehavior]) {
            return;
        }
        // [EN] Held until the user starts a new drag (`-cyl_releaseSystemMinimizeHoldIfNeeded`), as the new-drag rule of
        //      FlatDesign and classic: the old drag's momentum, or an alert still on screen, cannot minimize it again.
        // [CN] 保持到用户开始新的拖动（`-cyl_releaseSystemMinimizeHoldIfNeeded`），与扁平样式、经典样式的新拖动规则一致：
        //      旧拖动的惯性或仍在屏幕上的弹框都不能再次缩小 TabBar。
        objc_setAssociatedObject(self, CYLTabBarMinimizeHoldsSystemNeverKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        [super setTabBarMinimizeBehavior:UITabBarMinimizeBehaviorNever];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CYLTabBarMinimizeLiquidGlassExpandCheckDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self cyl_expandSystemMinimizedTabBarFallbackIfNeeded];
        });
    }
#endif
}

/*!
 * [EN] Liquid Glass, second mechanism: if writing `Never` did not expand the bar (self-check after
 *      CYLTabBarMinimizeLiquidGlassExpandCheckDelay), hide and show it once with UIKit's own `-setTabBarHidden:animated:`
 *      (iOS 18+, not animated, through `super` so it is not taken for the app's request), which lays it out expanded.
 *      Each step reports its result in the diagnostic log. Skipped for a bar the app hid itself.
 * [CN] 液态玻璃的第二种方式：如果写入 `Never` 没有恢复 TabBar（CYLTabBarMinimizeLiquidGlassExpandCheckDelay 之后自检），用 UIKit 自己的
 *      `-setTabBarHidden:animated:`（iOS 18+，无动画，通过 `super` 调用，不会被当作 App 的请求）隐藏再显示一次，使其按展开状态重新布局。
 *      每一步的结果都写入诊断日志。App 自己隐藏的 TabBar 不处理。
 */
- (void)cyl_expandSystemMinimizedTabBarFallbackIfNeeded {
#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
    if (@available(iOS 26.0, *)) {
        UIView *tabBar = self.cyl_tabBar;
        if (![tabBar isKindOfClass:[CYLTabBar class]] || ![(CYLTabBar *)tabBar cyl_showsMinimizedBar]) {
            return;
        }
        if ([super isTabBarHidden]) {
            return;
        }
        CYLTabBarMinimizeLog(@"Liquid Glass: writing Never did not expand the minimized tab bar; trying hide / show", nil);
        [super setTabBarHidden:YES animated:NO];
        [super setTabBarHidden:NO animated:NO];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CYLTabBarMinimizeLiquidGlassExpandCheckDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            UIView *checkedTabBar = self.cyl_tabBar;
            BOOL stillMinimized = [checkedTabBar isKindOfClass:[CYLTabBar class]] && [(CYLTabBar *)checkedTabBar cyl_showsMinimizedBar];
            CYLTabBarMinimizeLog(stillMinimized ? @"Liquid Glass: hide / show did not expand it either" : @"Liquid Glass: hide / show expanded it", nil);
        });
    }
#endif
}

- (void)cyl_releaseSystemMinimizeHoldIfNeeded {
#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
    if (![objc_getAssociatedObject(self, CYLTabBarMinimizeHoldsSystemNeverKey) boolValue]) {
        return;
    }
    objc_setAssociatedObject(self, CYLTabBarMinimizeHoldsSystemNeverKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // [EN] Writes the app's value back to UIKit. [CN] 把 App 的取值写回 UIKit。
    [self cyl_updateTabBarMinimizeTracking];
#endif
}

#pragma mark cyl_hidesTabBarOnScroll

- (BOOL)cyl_isTabBarHiddenByScroll {
    _CYLTabBarMinimizeScrollTracker *tracker = objc_getAssociatedObject(self, CYLTabBarMinimizeScrollTrackerKey);
    return [tracker isTabBarHiddenOrMinimizedByScroll];
}

- (BOOL)cyl_simulateHideOnScrollForTesting {
    [self cyl_updateTabBarMinimizeTracking];
    _CYLTabBarMinimizeScrollTracker *tracker = objc_getAssociatedObject(self, CYLTabBarMinimizeScrollTrackerKey);
    if (!tracker) {
        CYLTabBarMinimizeLog(@"test hide refused", @"no scroll tracker (scroll hiding is off, or no scroll view on the selected page)");
        return NO;
    }
    return [tracker simulateHideForTesting];
}

- (BOOL)cyl_hidesTabBarOnScroll {
    CYLTabBarMinimizeBehavior behavior = self.cyl_tabBarMinimizeBehavior;
    return (CYLTabBarMinimizeBehaviorOnScrollDown == behavior || CYLTabBarMinimizeBehaviorOnScrollUp == behavior);
}

/*!
 * [EN] The direct switch, one branch per style so it reads as what happens. All branches store the same value as
 *      `cyl_tabBarMinimizeBehavior` (OnScrollDown or Never), so the two APIs always agree, also after a style change.
 * [CN] 直接的开关，每种样式一个分支，读代码即可知道效果。所有分支保存的都是与 `cyl_tabBarMinimizeBehavior` 相同的取值
 *      （OnScrollDown 或 Never），因此两个接口始终一致，样式改变后也一样。
 */
- (void)setCyl_hidesTabBarOnScroll:(BOOL)hidesTabBarOnScroll {
    // 1. Liquid Glass (iOS 26+): Apple's own API; the system minimizes the tab bar.
    //    液态玻璃（iOS 26+）：直接调用 Apple 自己的接口，由系统缩小 TabBar。
#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
    if (@available(iOS 26.0, *)) {
        if (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType && [CYLConstants isLiquidGlassActive]) {
            self.tabBarMinimizeBehavior = hidesTabBarOnScroll ? UITabBarMinimizeBehaviorOnScrollDown : UITabBarMinimizeBehaviorNever;
            return;
        }
    }
#endif
    CYLTabBarMinimizeBehavior behavior = hidesTabBarOnScroll ? CYLTabBarMinimizeBehaviorOnScrollDown : CYLTabBarMinimizeBehaviorNever;
    // 2. FlatDesign: CYLTabBarController follows the page's scroll view and hides the flat tab bar with
    //    `-setTabBarHidden:animated:`.
    //    扁平样式：CYLTabBarController 跟随页面的滚动视图，用 `-setTabBarHidden:animated:` 隐藏扁平 TabBar。
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
        self.cyl_tabBarMinimizeBehavior = behavior;
        return;
    }
    // 3. Classic tab bar (iOS 25 and earlier such as iOS 17, and iOS 26 in UI compatibility mode): the same tracking; the
    //    system tab bar is hidden with `-setTabBarHidden:animated:` (UIKit on iOS 18+, FlatDesign's animation before).
    //    经典 TabBar（iOS 25 及以前如 iOS 17，以及 iOS 26 的 UI 兼容模式）：同样的跟随方式；用 `-setTabBarHidden:animated:` 隐藏系统
    //    TabBar（iOS 18+ 由 UIKit 执行，更早的系统使用扁平样式的动画）。
    self.cyl_tabBarMinimizeBehavior = behavior;
}

#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
/*!
 * [EN] The same switch through Apple's own API (iOS 26+): `tabBarController.tabBarMinimizeBehavior = ...` turns scroll
 *      hiding on and off in every style, exactly as `cyl_tabBarMinimizeBehavior`. Both read and write one stored value;
 *      the value really given to UIKit (`Never` for FlatDesign and the classic tab bar) is written through `super`.
 *      Use `cyl_tabBarMinimizeBehavior` where iOS 25 and earlier must be supported, since Apple's property does not
 *      exist there.
 * [CN] 通过 Apple 自己的接口（iOS 26+）使用同一个开关：`tabBarController.tabBarMinimizeBehavior = ...` 在所有样式下开启、关闭
 *      滚动隐藏，与 `cyl_tabBarMinimizeBehavior` 完全相同。二者读写同一个保存的取值；真正交给 UIKit 的取值（扁平样式与经典
 *      TabBar 为 `Never`）通过 `super` 写入。需要支持 iOS 25 及以前时请使用 `cyl_tabBarMinimizeBehavior`，因为这些系统上没有
 *      Apple 的这个属性。
 */
- (void)setTabBarMinimizeBehavior:(UITabBarMinimizeBehavior)tabBarMinimizeBehavior {
    if (@available(iOS 26.0, *)) {
        self.cyl_tabBarMinimizeBehavior = CYLTabBarMinimizeBehaviorFromSystem(tabBarMinimizeBehavior);
    }
}

- (UITabBarMinimizeBehavior)tabBarMinimizeBehavior {
    if (@available(iOS 26.0, *)) {
        // [EN] Not set by the app yet: UIKit's own value. [CN] App 尚未设置：返回 UIKit 自己的取值。
        if (!objc_getAssociatedObject(self, CYLTabBarMinimizeBehaviorKey)) {
            return [super tabBarMinimizeBehavior];
        }
        return CYLSystemTabBarMinimizeBehavior(self.cyl_tabBarMinimizeBehavior);
    }
    return 0;
}
#endif

- (void)cyl_updateTabBarMinimizeTracking {
    // [EN] Nothing to do until the app sets a value: UIKit's own default is left untouched.
    // [CN] App 设置取值之前不做任何处理：不改动 UIKit 自身的默认值。
    if (!objc_getAssociatedObject(self, CYLTabBarMinimizeBehaviorKey)) {
        return;
    }
#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
    if (@available(iOS 26.0, *)) {
        // [EN] Only Liquid Glass lets the system minimize the tab bar. FlatDesign and the classic tab bar (UI compatibility
        //      mode) hide it themselves, so the system is told never to minimize. Checked again on every layout, because
        //      the style can change after the value is set; only a different value is written.
        // [CN] 只有液态玻璃交给系统缩小 TabBar。扁平样式与经典 TabBar（UI 兼容模式）自行隐藏 TabBar，因此让系统不缩小。由于设置取值后
        //      样式仍可能改变，每次布局都会重新检查；只有取值不同时才写入。
        // [EN] Guard: while `-cyl_expandSystemMinimizedTabBar` holds `Never` to expand the bar, leave it.
        // [CN] Guard：`-cyl_expandSystemMinimizedTabBar` 为恢复 TabBar 暂时保持 `Never` 期间，不改动。
        BOOL holdsNever = [objc_getAssociatedObject(self, CYLTabBarMinimizeHoldsSystemNeverKey) boolValue];
        BOOL systemMinimizes = !holdsNever && (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType) && [CYLConstants isLiquidGlassActive];
        UITabBarMinimizeBehavior systemBehavior = systemMinimizes ? CYLSystemTabBarMinimizeBehavior(self.cyl_tabBarMinimizeBehavior) : UITabBarMinimizeBehaviorNever;
        // [EN] Through `super`: `-setTabBarMinimizeBehavior:` above is the app's switch, not UIKit's value.
        // [CN] 通过 `super`：上面的 `-setTabBarMinimizeBehavior:` 是 App 的开关，而不是交给 UIKit 的取值。
        if ([super tabBarMinimizeBehavior] != systemBehavior) {
            [super setTabBarMinimizeBehavior:systemBehavior];
        }
    }
#endif
    _CYLTabBarMinimizeScrollTracker *tracker = objc_getAssociatedObject(self, CYLTabBarMinimizeScrollTrackerKey);
    CYLTabBarMinimizeMode mode = CYLTabBarMinimizeModeForTabBarController(self);
#if defined(__IPHONE_26_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_26_0
    // [EN] Not Liquid Glass any more (style change, turned off): drop a hold, nothing will release it.
    // [CN] 不再是液态玻璃（样式改变、已关闭）：清除保持状态，之后不会再有释放它的拖动。
    if (CYLTabBarMinimizeModeLiquidGlass != mode) {
        objc_setAssociatedObject(self, CYLTabBarMinimizeHoldsSystemNeverKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
#endif
    if (CYLTabBarMinimizeModeNone == mode) {
        if (tracker) {
            CYLTabBarMinimizeMode previousMode = tracker.mode;
            // [EN] Turned off: stop observing and give back a tab bar that scrolling hid.
            // [CN] 已关闭：停止观察，并恢复被滚动隐藏的 TabBar。
            [tracker observeScrollView:nil];
            [tracker updateMode:CYLTabBarMinimizeModeNone];
            objc_setAssociatedObject(self, CYLTabBarMinimizeScrollTrackerKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            // [EN] Liquid Glass: put the plus button back at its usual position. [CN] 液态玻璃：让 PlusButton 回到常规位置。
            if (CYLTabBarMinimizeModeLiquidGlass == previousMode && self.isViewLoaded) {
                [self.cyl_tabBar setNeedsLayout];
            }
        }
        return;
    }
    if (!tracker) {
        tracker = [[_CYLTabBarMinimizeScrollTracker alloc] initWithTabBarController:self];
        objc_setAssociatedObject(self, CYLTabBarMinimizeScrollTrackerKey, tracker, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [tracker updateMode:mode];
    [tracker observeTapsInView:self.viewIfLoaded];
    UIScrollView *scrollView = [tracker scrollViewForSelectedViewController:self.selectedViewController];
    if (scrollView != tracker.scrollView) {
        // [EN] Another tab or page is on screen: show the tab bar again, as the system does.
        // [CN] 切换到其他 Tab 或页面：与系统一致，重新显示 TabBar。
        [tracker restoreTabBarForReason:@"page or scroll view changed"];
        [tracker observeScrollView:scrollView];
    }
    // [EN] Every layout of this controller checks the hide session. [CN] 本控制器每次布局都检查隐藏会话。
    [tracker validateHideSession];
}

- (void)cyl_tabBarMinimizeDidReceiveTabBarHiddenRequest:(BOOL)hidden {
    _CYLTabBarMinimizeScrollTracker *tracker = objc_getAssociatedObject(self, CYLTabBarMinimizeScrollTrackerKey);
    [tracker appDidRequestTabBarHidden:hidden];
}

- (void)cyl_tabBarMinimizeLifecycleEvent {
    _CYLTabBarMinimizeScrollTracker *tracker = objc_getAssociatedObject(self, CYLTabBarMinimizeScrollTrackerKey);
    // Guard: only while scroll hiding is on. 仅在开启滚动隐藏时处理。
    if (!tracker) {
        return;
    }
    [tracker restoreTabBarForReason:@"view lifecycle (appear / disappear / size change)"];
}

@end

#pragma mark - CYLReselect (tapping the selected tab again)

static char CYLReselectBehaviorKey;

@implementation CYLTabBarController (CYLReselect)

- (CYLTabBarReselectBehavior)cyl_reselectBehavior {
    return (CYLTabBarReselectBehavior)[objc_getAssociatedObject(self, &CYLReselectBehaviorKey) unsignedIntegerValue];
}

- (void)setCyl_reselectBehavior:(CYLTabBarReselectBehavior)reselectBehavior {
    objc_setAssociatedObject(self, &CYLReselectBehaviorKey, @(reselectBehavior), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    // [EN] As `cyl_tabBarItemGestureHandler` does: start recognizing the gestures. [CN] 与 `cyl_tabBarItemGestureHandler` 一样：开始识别手势。
    if (self.isViewLoaded) {
        [self cyl_installTabBarItemLongPressIfNeeded];
    }
}

- (UIViewController *)cyl_viewControllerForTabControl:(UIControl *)control {
    if (!control || [control cyl_isPlusControl]) {
        return nil;
    }
#if CYL_FLATDESIGN_AVAILABLE
    // [EN] FlatDesign: the item's button, matched by position (items and view controllers are aligned).
    // [CN] 扁平样式：按位置匹配 item 的按钮（items 与 viewControllers 一一对应）。
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
        NSArray<CYLFlatDesignTabBarItem *> *items = [self.items copy];
        for (NSUInteger index = 0; index < items.count && index < self.viewControllers.count; index++) {
            if ((UIControl *)items[index].tabBarButton == control) {
                UIViewController *viewController = self.viewControllers[index];
                return viewController.cyl_isPlaceholder ? nil : viewController;
            }
        }
        return nil;
    }
#endif
    // [EN] Liquid Glass shows two buttons per tab; the selected layer's button stands for the normal one.
    // [CN] 液态玻璃中每个 Tab 有两个按钮；选中层的按钮对应普通层的按钮。
    NSMutableArray<UIControl *> *candidates = [NSMutableArray arrayWithObject:control];
    if ([control cyl_isPlatterSelectedControl]) {
        UIControl *normalControl = [control cyl_platterNormalControl];
        if (normalControl && normalControl != control) {
            [candidates addObject:normalControl];
        }
    }
    for (UIViewController *viewController in self.viewControllers) {
        if (viewController.cyl_isPlaceholder) {
            continue;
        }
        UIViewController *contentViewController = [viewController cyl_getViewControllerInsteadOfNavigationController];
        for (UIControl *candidate in candidates) {
            if (viewController.tabBarItem.cyl_tabButton == candidate || viewController.cyl_tabButton == candidate ||
                contentViewController.cyl_tabButton == candidate) {
                return viewController;
            }
        }
    }
    // [EN] The classic tab bar numbers its buttons in `-cyl_bindTabControlActions` (system tab buttons only).
    // [CN] 经典 TabBar 在 `-cyl_bindTabControlActions` 中为按钮编号（只计系统 Tab 按钮）。
    if (![CYLConstants isLiquidGlassActive]) {
        NSInteger index = control.cyl_tabBarChildViewControllerIndex;
        if (index >= 0 && index < (NSInteger)self.viewControllers.count) {
            UIViewController *viewController = self.viewControllers[(NSUInteger)index];
            return viewController.cyl_isPlaceholder ? nil : viewController;
        }
    }
    return nil;
}

- (void)cyl_performReselectBehaviorForViewController:(UIViewController *)viewController {
    CYLTabBarReselectBehavior behavior = self.cyl_reselectBehavior;
    if (behavior == CYLTabBarReselectBehaviorNone) {
        return;
    }
    if ((behavior & CYLTabBarReselectBehaviorPopToRoot) && [viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = (UINavigationController *)viewController;
        if (navigationController.viewControllers.count > 1) {
            [navigationController popToRootViewControllerAnimated:YES];
            // [EN] Popped: the next tap, at the root page, scrolls to the top. [CN] 已返回根页面：下次点击（在根页面）再滚动到顶部。
            return;
        }
    }
    if (behavior & CYLTabBarReselectBehaviorScrollToTop) {
        UIScrollView *scrollView = CYLTabBarMinimizeScrollViewForViewController(viewController);
        if (scrollView) {
            CGPoint topOffset = CGPointMake(scrollView.contentOffset.x, -scrollView.adjustedContentInset.top);
            [scrollView setContentOffset:topOffset animated:YES];
        }
    }
}

@end

#pragma mark - CYLCustomTabAction (a tab that runs an action instead of being selected)

static char CYLCustomActionTabBarItemIdentifiersKey;
static char CYLShouldPerformCustomTabActionHandlerKey;
static char CYLCustomTabActionHandlerKey;
static char CYLCustomTabActionViewControllerKey;

@implementation CYLTabBarController (CYLCustomTabAction)

- (NSArray<NSString *> *)cyl_customActionTabBarItemIdentifiers {
    return objc_getAssociatedObject(self, &CYLCustomActionTabBarItemIdentifiersKey);
}

- (void)setCyl_customActionTabBarItemIdentifiers:(NSArray<NSString *> *)customActionTabBarItemIdentifiers {
    objc_setAssociatedObject(self, &CYLCustomActionTabBarItemIdentifiersKey, customActionTabBarItemIdentifiers, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL (^)(CYLTabBarController *, UIViewController *))cyl_shouldPerformCustomTabActionHandler {
    return objc_getAssociatedObject(self, &CYLShouldPerformCustomTabActionHandlerKey);
}

- (void)setCyl_shouldPerformCustomTabActionHandler:(BOOL (^)(CYLTabBarController *, UIViewController *))shouldPerformCustomTabActionHandler {
    objc_setAssociatedObject(self, &CYLShouldPerformCustomTabActionHandlerKey, shouldPerformCustomTabActionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void (^)(CYLTabBarController *, UIViewController *))cyl_customTabActionHandler {
    return objc_getAssociatedObject(self, &CYLCustomTabActionHandlerKey);
}

- (void)setCyl_customTabActionHandler:(void (^)(CYLTabBarController *, UIViewController *))customTabActionHandler {
    objc_setAssociatedObject(self, &CYLCustomTabActionHandlerKey, customTabActionHandler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (BOOL)cyl_isCustomActionTabViewController:(UIViewController *)viewController {
    if (!viewController || viewController.cyl_isPlaceholder) {
        return NO;
    }
    BOOL (^shouldPerformCustomTabActionHandler)(CYLTabBarController *, UIViewController *) = self.cyl_shouldPerformCustomTabActionHandler;
    if (shouldPerformCustomTabActionHandler) {
        return shouldPerformCustomTabActionHandler(self, viewController);
    }
    id<CYLTabBarControllerDelegate> delegate = (id<CYLTabBarControllerDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:shouldPerformCustomActionForViewController:)]) {
        return [delegate tabBarController:self shouldPerformCustomActionForViewController:viewController];
    }
    NSString *identifier = viewController.cyl_tabBarItemIdentifier;
    return identifier.length > 0 && [self.cyl_customActionTabBarItemIdentifiers containsObject:identifier];
}

- (BOOL)cyl_performCustomTabActionIfNeededForViewController:(UIViewController *)viewController {
    if (![self cyl_isCustomActionTabViewController:viewController]) {
        return NO;
    }
    // [EN] One tap reaches here up to twice (`-tabBarController:shouldSelectViewController:`, then the tab button's action):
    //      run the action only once per run loop turn.
    // [CN] 一次点击最多到达这里两次（`-tabBarController:shouldSelectViewController:`，然后是 Tab 按钮的事件）：每个 runloop 只执行一次。
    if (objc_getAssociatedObject(self, &CYLCustomTabActionViewControllerKey) == viewController) {
        return YES;
    }
    objc_setAssociatedObject(self, &CYLCustomTabActionViewControllerKey, viewController, OBJC_ASSOCIATION_ASSIGN);
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) {
            objc_setAssociatedObject(strongSelf, &CYLCustomTabActionViewControllerKey, nil, OBJC_ASSOCIATION_ASSIGN);
        }
    });
    void (^customTabActionHandler)(CYLTabBarController *, UIViewController *) = self.cyl_customTabActionHandler;
    if (customTabActionHandler) {
        customTabActionHandler(self, viewController);
        return YES;
    }
    id<CYLTabBarControllerDelegate> delegate = (id<CYLTabBarControllerDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:performCustomActionForViewController:)]) {
        [delegate tabBarController:self performCustomActionForViewController:viewController];
    }
    return YES;
}

@end
