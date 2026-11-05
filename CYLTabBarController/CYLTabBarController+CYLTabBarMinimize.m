//
//  CYLTabBarController+CYLTabBarMinimize.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Minimizing or hiding the tab bar on scroll (issue #13).
//      Split out of CYLTabBarController.m without changes.
// [CN] 滚动时缩小或隐藏 TabBar（issue #13）。
//      从 CYLTabBarController.m 中拆分出来，内容未改动。

#import "CYLTabBarController.h"
#import "CYLTabBar.h"
#import <objc/runtime.h>
#import <dlfcn.h>
#import "UIViewController+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarControllerExtention.h"
#import "UIControl+CYLTabBarItemAnimation.h"
#import "UIImage+CYLTabBarControllerExtention.h"
#import "NSObject+CYLTabBarControllerExtention.h"



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
#import "CYLTabBarController+CYLPrivate.h"

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
/// [EN] Classic style: how often the page on screen is checked again (core has no push/pop hook outside FlatDesign).
/// [CN] 经典样式：重新确认当前页面的间隔（FlatDesign 以外，Core 中没有 push/pop 回调）。
static const NSTimeInterval CYLTabBarMinimizeClassicPageCheckInterval = 0.5;

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
    NSMutableArray<UIView *> *views = [NSMutableArray arrayWithObject:visibleViewController.view];
    for (NSUInteger index = 0; index < views.count; index++) {
        UIView *view = views[index];
        if (view.hidden) {
            continue;
        }
        if ([view isKindOfClass:[UIScrollView class]] && ![view isKindOfClass:[UITextView class]]) {
            return (UIScrollView *)view;
        }
        [views addObjectsFromArray:view.subviews];
    }
    return nil;
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

/// [EN] Observes the scroll view of the page on screen and runs the path's action. See the section comment above.
/// [CN] 观察当前显示页面的滚动视图，并执行对应路径的处理。见上方说明。
@interface _CYLTabBarMinimizeScrollTracker : NSObject
@property (nonatomic, weak, readonly) CYLTabBarController *tabBarController;
@property (nonatomic, weak, readonly) UIScrollView *scrollView;
@property (nonatomic, assign, readonly) CYLTabBarMinimizeMode mode;
- (instancetype)initWithTabBarController:(CYLTabBarController *)tabBarController;
- (void)updateMode:(CYLTabBarMinimizeMode)mode;
- (void)observeScrollView:(UIScrollView *)scrollView;
- (void)expandTabBar;
@end

@implementation _CYLTabBarMinimizeScrollTracker {
    /// [EN] Distance scrolled in the current direction (positive: content moves up). [CN] 当前方向的累计滚动距离（正值：内容上移）。
    CGFloat _scrolledDistance;
    /// [EN] YES when the tab bar was hidden by scrolling, not by the app. [CN] TabBar 是滚动隐藏的，而不是 App 自己隐藏的。
    BOOL _hiddenByScroll;
    /// [EN] Liquid Glass: the minimized state the tab bar was last laid out for. [CN] 液态玻璃：上次布局时 TabBar 的缩小状态。
    BOOL _laidOutMinimized;
    /// [EN] Classic: checks the page on screen again (see CYLTabBarMinimizeClassicPageCheckInterval). [CN] 经典样式：定时重新确认当前页面。
    NSTimer *_classicPageCheckTimer;
}

- (instancetype)initWithTabBarController:(CYLTabBarController *)tabBarController {
    self = [super init];
    if (self) {
        _tabBarController = tabBarController;
    }
    return self;
}

- (void)dealloc {
    [_classicPageCheckTimer invalidate];
    [self observeScrollView:nil];
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
    // Guard: the page check timer runs for the classic path only. 定时检查只用于经典样式。
    [_classicPageCheckTimer invalidate];
    _classicPageCheckTimer = nil;
    if (CYLTabBarMinimizeModeClassic == mode) {
        __weak typeof(self) weakSelf = self;
        _classicPageCheckTimer = [NSTimer scheduledTimerWithTimeInterval:CYLTabBarMinimizeClassicPageCheckInterval repeats:YES block:^(NSTimer *timer) {
            CYLTabBarController *tabBarController = weakSelf.tabBarController;
            if (!tabBarController) {
                [timer invalidate];
                return;
            }
            if (tabBarController.viewIfLoaded.window) {
                [tabBarController cyl_updateTabBarMinimizeTracking];
            }
        }];
        _classicPageCheckTimer.tolerance = CYLTabBarMinimizeClassicPageCheckInterval * 0.5;
    }
}

- (void)observeScrollView:(UIScrollView *)scrollView {
    UIScrollView *observedScrollView = _scrollView;
    if (observedScrollView == scrollView) {
        return;
    }
    // [EN] A scroll view that is already gone was nilled out by `weak`; KVO drops its observers itself (iOS 11+).
    // [CN] 已释放的滚动视图会被 `weak` 置为 nil；KVO 会自行移除它的观察者（iOS 11+）。
    [observedScrollView removeObserver:self forKeyPath:@"contentOffset" context:CYLTabBarMinimizeContentOffsetContext];
    _scrollView = scrollView;
    _scrolledDistance = 0;
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
        [self layOutTabBarIfMinimizedStateChanged];
        return;
    }
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
    // [EN] Only scrolling by the user counts. Offsets set in code, e.g. when the safe area changes because the tab bar
    //      hides, are ignored.
    // [CN] 只响应用户的滚动。代码设置的偏移（例如 TabBar 隐藏导致安全区变化）不处理。
    if (!scrollView.isTracking && !scrollView.isDragging && !scrollView.isDecelerating) {
        return;
    }
    UIEdgeInsets insets = scrollView.adjustedContentInset;
    CGFloat minOffsetY = -insets.top;
    CGFloat maxOffsetY = MAX(minOffsetY, scrollView.contentSize.height + insets.bottom - CGRectGetHeight(scrollView.bounds));
    if (maxOffsetY - minOffsetY < CYLTabBarMinimizeMinimumScrollableDistance) {
        return;
    }
    // [EN] Back at the edge the content starts from: show the tab bar, as the system does.
    // [CN] 回到内容的起始边缘：与系统一致，显示 TabBar。
    if ((minimizesOnScrollDown && newOffsetY <= minOffsetY) || (minimizesOnScrollUp && newOffsetY >= maxOffsetY)) {
        _scrolledDistance = 0;
        [self expandTabBar];
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
    if (scrollsDown == minimizesOnScrollDown) {
        [self minimizeTabBar];
    } else {
        [self expandTabBar];
    }
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
    if (!tabBarController || tabBarController.isTabBarHidden) {
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
    [tabBarController setTabBarHidden:YES animated:YES];
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
    if (CYLTabBarMinimizeModeClassic == _mode && CYLTabBarMinimizeClassicPageHidesTabBar(self.tabBarController.selectedViewController)) {
        return;
    }
    _hiddenByScroll = NO;
    if (CYLTabBarMinimizeModeFlatDesign != _mode && CYLTabBarMinimizeModeClassic != _mode) {
        return;
    }
    CYLTabBarController *tabBarController = self.tabBarController;
    if (tabBarController.isTabBarHidden) {
        [tabBarController setTabBarHidden:NO animated:YES];
    }
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

@implementation CYLTabBarController (CYLTabBarMinimize)

- (UIScrollView *)cyl_tabBarMinimizeScrollViewForViewController:(UIViewController *)viewController {
    return CYLTabBarMinimizeScrollViewForViewController(viewController);
}

- (CYLTabBarMinimizeBehavior)cyl_tabBarMinimizeBehavior {
    NSNumber *behavior = objc_getAssociatedObject(self, CYLTabBarMinimizeBehaviorKey);
    return (CYLTabBarMinimizeBehavior)behavior.integerValue;
}

- (void)setCyl_tabBarMinimizeBehavior:(CYLTabBarMinimizeBehavior)behavior {
    objc_setAssociatedObject(self, CYLTabBarMinimizeBehaviorKey, @(behavior), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [self cyl_updateTabBarMinimizeTracking];
}

#pragma mark cyl_hidesTabBarOnScroll

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
        BOOL systemMinimizes = (CYLTabBarStyleTypeFlatDesign != self.tabBarStyleType) && [CYLConstants isLiquidGlassActive];
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
    UIScrollView *scrollView = CYLTabBarMinimizeScrollViewForViewController(self.selectedViewController);
    if (scrollView != tracker.scrollView) {
        // [EN] Another tab or page is on screen: show the tab bar again, as the system does.
        // [CN] 切换到其他 Tab 或页面：与系统一致，重新显示 TabBar。
        [tracker expandTabBar];
        [tracker observeScrollView:scrollView];
    }
}

@end
