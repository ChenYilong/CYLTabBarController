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
