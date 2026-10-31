//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import "CYLTabBarController.h"
#import "CYLTabBar.h"
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


#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
#import <CYLTabBarController/CYLFlatDesignTabBar.h>
#import "CYLFlatDesignTabBar.h"

#else
#endif


//#import "CYLFlatDesignTabBarItem.h"
//#import "UINavigationController+CYLFlatDesignTabBarPrivate.h"
//#import "_CYLFlatDesignTabBarParallaxOverlayView.h"
//#import "CYLFlatDesignTabBarHideTabBar.h"


#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
NSString *const CYLTabBarItemImageInsets = @"CYLTabBarItemImageInsets";
NSString *const CYLTabBarItemTitlePositionAdjustment = @"CYLTabBarItemTitlePositionAdjustment";
NSString *const CYLTabBarItemImagePositionAdjustment = @"CYLTabBarItemImagePositionAdjustment";
NSString *const CYLTabBarLottieFilePath = @"CYLTabBarLottieFilePath";
NSString *const CYLTabBarLottieURL = @"CYLTabBarLottieURL";
NSString *const CYLTabBarLottieSize = @"CYLTabBarLottieSize";

NSUInteger CYLTabbarItemsCount = 0;
NSUInteger CYLPlusButtonIndex = 0;
CGFloat CYLTabBarItemWidth = 0.0f;
CGFloat CYLTabBarHeight = 49.0f;

NSString *const CYLTabBarItemWidthDidChangeNotification = @"CYLTabBarItemWidthDidChangeNotification";
NSString *const CYLTabBarItemLottieAnimationPlayingNotification = @"CYLTabBarItemLottieAnimationPlayingNotification";

NSString *const CYLTabBarStyleTypeDidChangeNotification = @"CYLTabBarStyleTypeDidChangeNotification";
static void * const CYLTabImageViewDefaultOffsetContext = (void*)&CYLTabImageViewDefaultOffsetContext;
//static void * const CYLTabBarControllerVisiableItemsCountContext = (void*)&CYLTabBarControllerVisiableItemsCountContext;

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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

@property (nonatomic, assign, getter=isObservingTabImageViewDefaultOffset) BOOL observingTabImageViewDefaultOffset;
@property (nonatomic, assign, getter=shouldInvokeOnceViewDidLayoutSubViewsBlock) BOOL invokeOnceViewDidLayoutSubViewsBlock;
@property (nonatomic, strong) NSMutableArray<NSURL *> *lottieURLs;
@property (nonatomic, strong) NSMutableArray *lottieSizes;
@property (nonatomic, assign, getter=isLottieViewAdded) BOOL lottieViewAdded;
@property (nonatomic, strong) UIImage *tabItemPlaceholderImage;
@property (nonatomic, copy) NSString *context;
@property (nonatomic, strong) CYLTabBar *tabBar;
@property (nonatomic, assign, readonly) CGRect tabBarFrame;

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
@property (nonatomic, strong) NSMutableArray<CYLFlatDesignTabBarItem *> *items;
@property (nonatomic, assign) BOOL cyl_tabBarHidden;
- (void)_cyl_refreshSystemTabBarVisibilityIfNeeded;
//@property (nonatomic, assign) CYLTabBarStyleType tabBarStyleType;
//@property (nonatomic, readwrite) CYLFlatDesignTabBar *cyl_tabBar;
#else
#endif
@end

@implementation CYLTabBarController {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
}

@synthesize viewControllers = _viewControllers;
@synthesize tabBarHeight = _tabBarHeight;
@synthesize cyl_tabBar = _cyl_tabBar;
@synthesize selectedViewController = _selectedViewController;
@dynamic tabBar;

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
//@synthesize viewControllers = _viewControllers;
@synthesize selectedIndex = _selectedIndex;
@dynamic delegate;

//@synthesize tabBarHeight = _tabBarHeight;
#else
#endif

#pragma mark -
#pragma mark - Life Cycle

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self _cyl_refreshSystemTabBarVisibilityIfNeeded];
}
#endif


- (void)tabChangedToControl:(UIControl *)control {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    UIViewController *vc = nil;
    [self tabChangedToSelectedViewController:vc control:control];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)tabChangedToSelectedViewController:(UIViewController *)viewController
                                   control:(UIControl *)control {
    
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self tabChangedToSelectedIndex:self.selectedIndex viewController:viewController control:control];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/*!
 * 三个地方 ， 都要调用：
 *  选中状态下的重新点击，（iOS26 需要在手势代理方法中进行hook追加该方法）
 *  用户切换index时
 *  代码切换index 时。
 */
- (void)tabChangedToSelectedIndex:(NSUInteger)selectedIndex
                   viewController:(UIViewController *)viewController
                          control:(UIControl *)control {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    //扁平样式，与玻璃样式均可使用
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
    
    UITabBarItem *item = viewController.tabBarItem;
    BOOL isChildViewControllerPlusButton = [control cyl_isChildViewControllerPlusButton];
    BOOL isLottieEnabled = [self isLottieEnabled];
    
    if (isLottieEnabled && !isChildViewControllerPlusButton) {
        //非液态玻璃 与 液态玻璃逻辑共用，Lottie 播放逻辑都在 tabChangedToSelectedIndex 中。
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
                BOOL defaultSelected = NO;
                if (idx == self.selectedIndex) {
                    defaultSelected = YES;
                }
                //TODO:  selected content, double add
                [self addLottieImageWithControl:tabButton animation:defaultSelected defaultSelected:defaultSelected];
                self.lottieViewAdded = YES;
            }];
        }
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
        //液态玻璃无法添加事件 放进手势响代理里处理。
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
        
        //FIX: iOS26 之前也不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
        [control addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
        
        // `selectedIndex` is NSNotFound while the "More" tab is selected; leave the buttons to UIKit then.
        if (isTabButton && self.selectedIndex != NSNotFound) {
            control.selected = (controlTabIndex == self.selectedIndex);
        }
    }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
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
        
            do {
                if (self.isLottieViewAdded) {
                    break;
                }
                //FIXME: ??
                NSArray *subTabBarButtonsWithoutPlusButton = tabBar.cyl_subTabBarButtonsWithoutPlusButton;
                BOOL isLottieEnabled = [self isLottieEnabled];
            
                if (![CYLConstants isLiquidGlassActive]) {
                    // 因为液态玻璃， 补全了所有的缺失的lottieURLs，所以一定保持一致， 无需要处理。
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
    
    
        if ([CYLConstants isLiquidGlassActive] && ([self hasPlusButton]) && [self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
            UIControl *plusControlOrigin = [self.cyl_tabBar cyl_platterContentViewWithIndex:CYLExternPlusButton.cyl_tabBarItemVisibleIndex];
            UIButton *selectedCover = CYLExternPlusButton.selectedContentView;
            UIControl *plusSelectedControl = plusControlOrigin.cyl_platterSelectedControl;
            [plusControlOrigin.cyl_tabImageView cyl_setHidden:YES];
            [plusControlOrigin.cyl_swappableImageViewViewInTabBarButton cyl_setHidden:YES];
        
            //由于 SelectedControl 所在图层的渲染比未选中图层有延迟， 所以必须加延迟，如果不加延迟，可能无法获取到正确的子视图， 有概率获取的子视图为nil
            // NSTimeInterval, not NSUInteger: an integer type truncated 0.5 to 0, so this never waited.
            // 必须是 NSTimeInterval：用 NSUInteger 会把 0.5 截断为 0，导致这里从未延迟。
            NSTimeInterval delaySecondsForSelectedContentView = 0.5;
            if ([self hasPlusChildViewController]) {
                [plusSelectedControl cyl_coverTabImageViewOrTabButton:YES
                                                              newView:selectedCover
                                                               offset:UIOffsetZero
                                                                 show:YES
                                              delayIfNeededForSeconds:delaySecondsForSelectedContentView
                                                           completion:^(BOOL isReplaced, UIControl * _Nonnull tabBarButton, UIView * _Nonnull selectedCover) {
                
                    /*!
                     *
                     *我要求 selectedCover 的中心坐标 强制与 CYLExternPlusButton坐标一致。 坐标系转换
                     * _UITabBarPlatterView
                     ├── SelectedContentView
                     │    └── selectedCover
                     │
                     └── CYLPlusButtonSubclass
                     */
                    UIView *platterView = CYLExternPlusButton.superview;
                    UIView *selectedContainerView = selectedCover.superview;
                
                    if (platterView && selectedContainerView) {
                    
                        CGPoint convertedCenter =
                        [selectedContainerView convertPoint:CYLExternPlusButton.center
                                                   fromView:platterView];
                    
                        selectedCover.center = convertedCenter;
                    }
                }];
            } else {
                //由于有几率无法获取到cyl_tabImageView， 只有延迟获取，才能避免获取为空nil。
                dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySecondsForSelectedContentView * NSEC_PER_SEC));
                dispatch_after(when, dispatch_get_main_queue(), ^{
                    //imageView 是主要的
                    [plusSelectedControl.cyl_tabImageView cyl_setHidden:YES];
                    //cyl_swappableImageViewViewInTabBarButton这个是防御性的， 理论上可以不隐藏。
                    [plusSelectedControl.cyl_swappableImageViewViewInTabBarButton cyl_setHidden:YES];
                });
            }
        }
    

    } else {/**  CYLTabBarStyleTypeFlatDesign*/}

    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (!_tabBarIsAnimating && !CGRectEqualToRect(self.cyl_tabBar.frame, self.tabBarFrame) && self.cyl_tabBar.superview == self.view) {
            //目的是动态更新tabbar高度 ， 测试方法为 修改 tabBarController.tabBarHeight ， 预期为实时跟新UI中的tabbar高度。// The goal is to dynamically update the tab bar height. The test method involves modifying `tabBarController.tabBarHeight`; the expected result is that the tab bar height in the UI updates in real time.
            self.cyl_tabBar.frame = self.tabBarFrame;
        }
        [self _cyl_refreshSystemTabBarVisibilityIfNeeded];

#else
#endif
    } else {}


    if (self.shouldInvokeOnceViewDidLayoutSubViewsBlock) {
        //在对象生命周期内，不添加 flag 属性的情况下，防止多次调进这个方法
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

/// 控制器支持方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if ([_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {     return self.selectedViewController.supportedInterfaceOrientations; }
        return self.selectedViewController.supportedInterfaceOrientations;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/ }
    return self.selectedViewController.supportedInterfaceOrientations;
}

- (void)dealloc {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
        [self removePlusButtonIfNeeded];
        /// MARK: 这里是全局处理，如果生成新的，这里操作时会破坏新的视图展示
        //    BOOL isAdded = [self isPlusViewControllerAdded:_viewControllers];
        //    BOOL hasPlusChildViewController = [self hasPlusChildViewController] && isAdded;
        //    if (isAdded && hasPlusChildViewController && CYLPlusChildViewController.cyl_plusViewControllerEverAdded == YES) {
        //        [CYLPlusChildViewController cyl_setPlusViewControllerEverAdded:NO];
        //    }
        // KVO反注册
        if (self.cyl_tabBar && self.isObservingTabImageViewDefaultOffset) {
            [self.cyl_tabBar cyl_removeObserver:self forKeyPath:@"tabImageViewDefaultOffset"];
        }
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}

    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        [self cyl_removeObserver:self forKeyPath:@"cyl_tabBar"];
#else
#endif
    } else { }
}

#pragma mark - Overrides

- (BOOL)isTabBarHidden {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
    return self.cyl_tabBarHidden;
#else
    return NO;
#endif
}

- (void)setTabBarHidden:(BOOL)tabBarHidden {
    [self setTabBarHidden:tabBarHidden animated:NO];
}

- (void)setTabBarHidden:(BOOL)hidden animated:(BOOL)animated {
    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
                
        // 隐藏系统 tabBar
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
                // 让 hidesBottomBarWhenPushed 优先级更高
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
    } else { }
}

- (BOOL)_checkHidesBottomBarWhenPushed {
    BOOL showsTabBar = YES;
    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
- (void)setDelegate:(id<CYLTabBarControllerDelegate, CYLFlatDesignUITabBarControllerDelegate>)delegate {

#else
    - (void)setDelegate:(id<CYLTabBarControllerDelegate>)delegate {
#endif

        [super setDelegate:delegate];
    
        if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
        if (viewController != CYLPlusChildViewController) {
                    
            if (_tabBarItemsAttributes.count > idx) {
                if (@available(iOS 13.0, *)) {
                    //fix https://github.com/ChenYilong/CYLTabBarController/issues/437
                    title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle] ?: @"";
                } else {
                    title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle];
                }
                        
                normalImageInfo = _tabBarItemsAttributes[idx][CYLTabBarItemImage];
                selectedImageInfo = _tabBarItemsAttributes[idx][CYLTabBarItemSelectedImage];
                lottieURL = _tabBarItemsAttributes[idx][CYLTabBarLottieURL];
                lottieFilePath = _tabBarItemsAttributes[idx][CYLTabBarLottieFilePath];
                        
                if (!lottieURL) {
                    lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
                }
                lottieSizeValue = _tabBarItemsAttributes[idx][CYLTabBarLottieSize];
                        
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
            /**如果是CYLPlusChildViewController ，title设置为空字符串，解决把第一个tabbarItem设置成plusButton后，其他的
             tabbarItem会不显示title问题
              见： https://github.com/ChenYilong/CYLTabBarController/issues/563
             **/
            title = @"";
            if ([CYLConstants isLiquidGlassActive] && ([self hasPlusButton])) {
            } else {
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
 *  添加一个子控制器
 *
 *  @param viewController    控制器
 *  @param title             标题
 *  @param normalImageInfo   图片
 *  @param selectedImageInfo 选中图片
 */
- (void)addOneChildViewController:(UIViewController *)viewController
                              idx:(NSUInteger)idx
                        WithTitle:(NSString *)title
                  normalImageInfo:(id)normalImageInfo
                selectedImageInfo:(id)selectedImageInfo
          titlePositionAdjustment:(UIOffset)titlePositionAdjustment
          imagePositionAdjustment:(UIOffset)imagePositionAdjustment
                      imageInsets:(UIEdgeInsets)imageInsets
                        lottieURL:(NSURL *)lottieURL
                   lottieFilePath:(NSString *)lottieFilePath
                  lottieSizeValue:(NSValue *)lottieSizeValue {
    
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
        }        //cyl_setTabBarItem 方法内部需要获取到tabbarvc但是， cyl_setTabBarItem是在初始化完成前的配置， 所以需要手动指定tabbarvc，否则cyl_setTabBarItem会初始化失败。
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
                                context:(NSString *)context {
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
                                context:(NSString *)context {
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
                                context:(NSString *)context {
    if (self = [super init]) {
        _imageInsets = imageInsets;
        _titlePositionAdjustment = titlePositionAdjustment;
        _tabBarItemsAttributes = tabBarItemsAttributes;
        _adjustTabBarItemImageViewSizeDependOnSuperView = YES;
        //以下为重要步骤，谨慎修改顺序：
        self.tabBarStyleType = styleType;// 步骤1 must use setter 必须在 self.viewControllers之前设置， 因为 self.viewControllers直接涉及到样式判断逻辑。
        [self cyl_tabBar];
        self.context = context; // 步骤2 must use setter 必须在 self.viewControllers之前设置， 因为 self.viewControllers 直接涉及样式contxt 与 PlusButton的判断逻辑。否则 contxt 永远是默认值
        self.viewControllers = viewControllers;// 步骤3 must use setter,必须在 self.tabBarStyleType之后设置， 因为 self.viewControllers 直接涉及到扁平TabBar样式KVC逻辑。
        
    }
    return self;
}

- (UIViewContentMode)lottieAnimationViewContentMode {
    return UIViewContentModeScaleAspectFit;
}

- (void)removePlusButtonIfNeeded {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    if (!self.hasPlusButton) {
        return;
    }
    if ([[CYLExternPlusButton class] respondsToSelector:@selector(tabBarContext)]) {
        NSString *plusButtonContext = [[CYLExternPlusButton class] performSelector:@selector(tabBarContext)];
        if (plusButtonContext && ![self.cyl_context isEqualToString:plusButtonContext]) {
            // contexts differ; remove PlusButton
            if ([[CYLExternPlusButton class] respondsToSelector:@selector(removePlusButton)]) {
                [[CYLExternPlusButton class] performSelector:@selector(removePlusButton)];
            }
        }
    }
    
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

+ (instancetype)tabBarControllerWithViewControllers:(NSArray<UIViewController *> *)viewControllers
                              tabBarItemsAttributes:(NSArray<NSDictionary *> *)tabBarItemsAttributes
                                        imageInsets:(UIEdgeInsets)imageInsets
                            titlePositionAdjustment:(UIOffset)titlePositionAdjustment
                                          styleType:(CYLTabBarStyleType)styleType
                                            context:(NSString *)context {
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
                                            context:(NSString *)context {
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
                                            context:(NSString *)context {
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

#pragma mark -  *  iOS26+ , 有 plusButton

// MARK:  *  iOS26+ , 有 plusButton

/*!
 *  iOS26+ , 有 plusButton
 */
- (void)alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:(NSArray *)viewControllers {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        if (![self.cyl_tabBar hasPlusButton]) {
            _viewControllers = viewControllers;
            return;
        }
        UIViewController *viewController = nil;
        NSInteger index = NSNotFound;
        if ([self hasPlusChildViewController]) {
            viewController = CYLPlusChildViewController;
            //        index = CYLPlusButtonIndex;
        } else {
            UIViewController *placeholderViewController = [UIViewController new];
            [placeholderViewController cyl_setIsPlaceholder:YES];
            viewController = placeholderViewController;
        }
        _viewControllers = [[self alignViewControllers:viewControllers withPlusButtonViewControllerPlaceholder:viewController] copy];
        [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:index];
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}

    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (![self.cyl_tabBar hasPlusButton]) {
            _viewControllers = viewControllers;
            return;
        }
        UIViewController *viewController = nil;
        NSInteger index = NSNotFound;
        if ([self hasPlusChildViewController]) {
            viewController = CYLPlusChildViewController;
        } else {
            UIViewController *placeholderViewController = [UIViewController new];
            [placeholderViewController cyl_setIsPlaceholder:YES];
            viewController = placeholderViewController;
        }
           

        index = CYLPlusButtonIndex;
        _viewControllers = [[self alignViewControllers:viewControllers withPlusButtonViewControllerPlaceholder:viewController] copy];
                
        [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:index];
        
#else
#endif
    } else {}
}

/*!
 *  iOS26+ , 有 plusButton
 */
- (NSMutableArray *)alignViewControllers:(NSArray *)arrayWithoutPlusButton withPlusButtonViewControllerPlaceholder:(id)plusButtonViewControllerPlaceholder {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        if (!plusButtonViewControllerPlaceholder) {
            return [arrayWithoutPlusButton mutableCopy];
        }
        if (![self.cyl_tabBar hasPlusButton]) {
            return [arrayWithoutPlusButton mutableCopy];
        }
        NSMutableArray *arrayWithPlusButton = nil;
        if ([arrayWithoutPlusButton isKindOfClass:[NSArray class]]) {
            arrayWithPlusButton = [NSMutableArray arrayWithArray:arrayWithoutPlusButton];
        } else if ([arrayWithoutPlusButton isKindOfClass:[NSMutableArray class]]) {
            arrayWithPlusButton = (NSMutableArray *)arrayWithoutPlusButton;
        }
        NSInteger index = NSNotFound;
        if (plusButtonViewControllerPlaceholder && (plusButtonViewControllerPlaceholder == CYLPlusChildViewController)) {
            //        index = CYLPlusButtonIndex;
        }
    
        NSInteger plusButtonIndex = (index != NSNotFound) ? CYLPlusButtonIndex : arrayWithoutPlusButton.count / 2;
    
        if (arrayWithPlusButton.count > plusButtonIndex) {
            [arrayWithPlusButton insertObject:plusButtonViewControllerPlaceholder atIndex:plusButtonIndex];
            //FIXME:  to delete 液态玻璃暂时不支持自定义PlusButton位置。
            [CYLExternPlusButton cyl_setTabBarItemVisibleIndex:plusButtonIndex];
            [self cyl_addChildViewController:plusButtonViewControllerPlaceholder];
        }
        return arrayWithPlusButton;
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}

    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return [arrayWithoutPlusButton mutableCopy]; }
        if (!plusButtonViewControllerPlaceholder) {
            return [arrayWithoutPlusButton mutableCopy];
        }
        if (![self.cyl_tabBar hasPlusButton]) {
            return [arrayWithoutPlusButton mutableCopy];
        }
        NSMutableArray *arrayWithPlusButton = nil;
        if ([arrayWithoutPlusButton isKindOfClass:[NSArray class]]) {
            arrayWithPlusButton = [NSMutableArray arrayWithArray:arrayWithoutPlusButton];
        } else if ([arrayWithoutPlusButton isKindOfClass:[NSMutableArray class]]) {
            arrayWithPlusButton = (NSMutableArray *)arrayWithoutPlusButton;
        }
        NSInteger index = NSNotFound;
        //    if (plusButtonViewControllerPlaceholder && (plusButtonViewControllerPlaceholder == CYLPlusChildViewController)) {
        index = CYLPlusButtonIndex;
        //    }
        NSInteger plusButtonIndex = (index != NSNotFound) ? CYLPlusButtonIndex : arrayWithoutPlusButton.count / 2;
        if (arrayWithPlusButton.count > plusButtonIndex) {
            [arrayWithPlusButton insertObject:plusButtonViewControllerPlaceholder atIndex:plusButtonIndex];
            [CYLExternPlusButton cyl_setTabBarItemVisibleIndex:plusButtonIndex];
            [self cyl_addChildViewController:plusButtonViewControllerPlaceholder];
        }
                
        //TODO:  插入self.items
        //    if (self.items.count > plusButtonIndex) {
        //        [self.items insertObject:[CYLFlatDesignTabBarItem new] atIndex:plusButtonIndex];
        //    }
        return arrayWithPlusButton;
            
#else
#endif
        
    } else {    }
    return [arrayWithoutPlusButton mutableCopy];
}
/*!
 *  iOS26+ , 有 plusButton
 */
- (void)alignTabControlIfNeededWithViewControllers:(NSArray *)viewControllers {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
        if (![self.cyl_tabBar hasPlusButton]) {
            _viewControllers = [viewControllers copy];
            return;
        }
        [self doubleCheckTabControlAlignWithViewControllers:_viewControllers ?: viewControllers];
        BOOL isAdded = [self isPlusViewControllerAdded:_viewControllers];
        BOOL addedFlag = [CYLPlusChildViewController cyl_plusViewControllerEverAdded];
        BOOL hasPlusChildViewController = [self hasPlusChildViewController] && !isAdded && !addedFlag;
        if (hasPlusChildViewController) {
            [self alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:viewControllers];
            [CYLPlusChildViewController cyl_setPlusViewControllerEverAdded:YES];
        } else {
            [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:NSNotFound];
        }
    
        if (![CYLConstants isLiquidGlassActive]) {
            if (!hasPlusChildViewController) {
                _viewControllers = [viewControllers copy];
            }
            return;
        }
    
        if (![self hasPlusButton]) {
            if (!hasPlusChildViewController) {
                _viewControllers = [viewControllers copy];
            }
            return;
        }
    
        if (![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
            if (!hasPlusChildViewController) {
                _viewControllers = [viewControllers copy];
            }
            return;
        }
    
        // iOS26+ , 有 plusButton
        if ([self hasPlusButton] && [CYLConstants isLiquidGlassActive]) {
            [self alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:viewControllers];
            NSDictionary *plusInfo =
            @{
                CYLTabBarItemTitle: @"",
                CYLTabBarItemImage :  [UIImage cyl_tabItemPlaceholderImage],
                CYLTabBarItemSelectedImage : [UIImage cyl_tabItemPlaceholderImage]
            };
            _tabBarItemsAttributes = [self alignViewControllers:_tabBarItemsAttributes withPlusButtonViewControllerPlaceholder:plusInfo];
        }
        [self doubleCheckTabControlAlignWithViewControllers:_viewControllers ?: viewControllers];
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}

    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (![self.cyl_tabBar hasPlusButton]) {
            _viewControllers = [viewControllers copy];
            return;
        }
        [self doubleCheckTabControlAlignWithViewControllers:_viewControllers ?: viewControllers];
        BOOL isAdded = [self isPlusViewControllerAdded:_viewControllers];
        BOOL addedFlag = [CYLPlusChildViewController cyl_plusViewControllerEverAdded];
        BOOL hasPlusChildViewController = [self hasPlusChildViewController] && !isAdded && !addedFlag;
        if (hasPlusChildViewController) {
            [self alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:viewControllers];
            [CYLPlusChildViewController cyl_setPlusViewControllerEverAdded:YES];
        } else {
            [CYLExternPlusButton cyl_setTabBarChildViewControllerIndex:NSNotFound];
        }
        
        //        if (![CYLConstants isLiquidGlassActive]) {
        //            if (!hasPlusChildViewController) {
        //                _viewControllers = [viewControllers copy];
        //            }
        //            return;
        //        }
        
        if (![self hasPlusButton]) {
            if (!hasPlusChildViewController) {
                _viewControllers = [viewControllers copy];
            }
            return;
        }
        
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
            if (!hasPlusChildViewController) {
                _viewControllers = [viewControllers copy];
            }
            return;
        }
        
        // iOS26+ , 有 plusButton
        //        if ([self hasPlusButton] && [CYLConstants isLiquidGlassActive]) {
        if ([self hasPlusButton]) {

            [self alignTabControlIfNeededWithPlusChildViewControllerFromViewControllers:viewControllers];
            NSDictionary *plusInfo =
            @{
                CYLTabBarItemTitle: @"",
                CYLTabBarItemImage :  [UIImage cyl_tabItemPlaceholderImage],
                CYLTabBarItemSelectedImage : [UIImage cyl_tabItemPlaceholderImage]
            };
            _tabBarItemsAttributes = [self alignViewControllers:_tabBarItemsAttributes withPlusButtonViewControllerPlaceholder:plusInfo];
        }
        [self doubleCheckTabControlAlignWithViewControllers:_viewControllers ?: viewControllers];
#else
#endif
    } else {}
}

- (void)doubleCheckTabControlAlignWithViewControllers:(NSArray *)viewControllers {
    //FIXME:  to delete
    if (!viewControllers) {
        viewControllers = _viewControllers;
    }
    if ((!_tabBarItemsAttributes) || (_tabBarItemsAttributes.count != viewControllers.count)) {
#if defined(DEBUG) || defined(BETA)
        NSAssert(NO, @" [DEBUG] The count of CYLTabBarControllers is not equal to the count of tabBarItemsAttributes.【Chinese】【仅为调试阶段的提示信息】设置_tabBarItemsAttributes属性时，请确保元素个数与控制器的个数相同，并在方法`-setViewControllers:`之前设置");
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
 * 设置为 NO，表示扁平化设计， 本属性相当于UI兼容模式的代码替代版本，仅仅在 iOS26+ 系统有效。
 * 由于 UI 兼容模式的命名晦涩， 更优雅直观的方式为 设置 CYLTabBarStyleType，其内部会设置该属性用于决定是否使用扁平设计。
 
 * @return means  CYLTabBarStyleType == CYLTabBarStyleTypeFlatDesign if return NO, means  CYLTabBarStyleType == CYLTabBarStyleTypeLiquidGlass if return YES;
 * @attention better switch to property CYLTabBarStyleType
 */
- (BOOL)noNeedUIDesignCompatibility {
    if (!CYL_IS_IOS_26) {
        return YES;
    }
    BOOL isLiquidGlass = [CYLConstants isLiquidGlassActive];
    //， 这个表示requiresCompatibility，必须使用， 否则iOS26里的兼容模式会错乱。
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

- (BOOL)hasPlusButton {
    return [self.cyl_tabBar hasPlusButton];
}

- (NSUInteger)allItemsInTabBarCount {
    NSUInteger allItemsInTabBar = CYLTabbarItemsCount;
    if ([self hasPlusButton]) {
        allItemsInTabBar += 1;
    }
    return allItemsInTabBar;
}

- (id<UIApplicationDelegate>)appDelegate {
    return [UIApplication sharedApplication].delegate;
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
        [viewControllers removeObjectAtIndex:CYLPlusButtonIndex];
    }
    [self setViewControllers:viewControllers];
    [self.view setNeedsLayout];
    self.selectedIndex = index;
    [superView addSubview:selected.view];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/**
 *  利用 KVC 把系统的 tabBar 类型改为自定义类型。
 *  仅限 CYLTabBar，在ViewDidLoad中调用
 *  不涉及 CYLTabBarStyleTypeFlatDesign样式（ 会在 setViewControllers 内部设置。）
 */
- (void)setUpDefaultStyleTabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [self setUpTabBar:nil];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/**
 *  利用 KVC 把系统的 tabBar 类型改为自定义类型。
 *  包含所有样式类型：
 *   CYLTabBar，在ViewDidLoad中调用；因为考虑到PlusButton的逻辑， 涉及坐标计算，还有运行中增删 PlusButton的逻辑，需要涉及重新布局，需要layoutSubviews中进行。故延迟调用。
 *   CYLTabBarStyleTypeFlatDesign样式 会在 setViewControllers 内部调用，调用时机靠前。
 */
- (void)setUpTabBar:(UIView __kindof *)_tabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN //Not CYLTabBarStyleTypeFlatDesign
    @try {
        CYLTabBar *tabBar = (CYLTabBar *)_tabBar;
        if (!tabBar) {
            tabBar = [[CYLTabBar alloc] init];
            [tabBar cyl_setTabBarController:self];
            _tabBar = tabBar;
            _cyl_tabBar = tabBar;
        }
        [self cyl_setValue:tabBar forKey:@"tabBar"];
        [self setUpIPADForTabBar:tabBar];
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@: reason %@", @(__PRETTY_FUNCTION__), @(__LINE__), @"setUpTabBar failed", exception.reason);
#endif
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

/** ipados 18 固定tabbar 在底部 */
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
                //防止未来类名变动， 暂时不会调用。
                [self.cyl_tabBar removeFromSuperview];
                [self.view addSubview:self.cyl_tabBar];
            }
        }
    }
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (BOOL)hasPlusChildViewController {
    BOOL hasPlusChildViewControllerBool = NO;
    
    /*!
     *     SEL action = @selector(hasPlusChildViewController);
        if ([self.cyl_tabBar respondsToSelector:action]) {
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
             hasPlusChildViewControllerBool = [self.cyl_tabBar performSelector:action];
                                                    )
        }

     */
    CYL_PERFORM_SELECTOR_BOOL(self.cyl_tabBar, hasPlusChildViewController, hasPlusChildViewControllerBool);
    
    return hasPlusChildViewControllerBool;
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
        childController == CYLPlusChildViewController ||
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
    NSUInteger tabCount = 0;
    for (UIViewController *viewController in _viewControllers) {
        if (viewController == CYLPlusChildViewController || viewController.cyl_isPlaceholder) {
            continue;
        }
        tabCount++;
    }
    if (attributesCount == tabCount) {
        return;
    }
    NSLog(@"🔴[CYL #618] tabBarItemsAttributes has %lu entries for %lu tab view controllers (the plus button's view controller not counted). Each tab needs exactly one entry; a mismatch shows tabs without a view controller, and tapping one can crash. See https://github.com/ChenYilong/CYLTabBarController/issues/618",
          (unsigned long)attributesCount, (unsigned long)tabCount);
}
#endif

- (void)setViewControllers:(NSArray<__kindof UIViewController *> *)viewControllers {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
        //#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
                [CYLPlusChildViewController willMoveToParentViewController:nil];
                [CYLPlusChildViewController.view removeFromSuperview];
                [CYLPlusChildViewController removeFromParentViewController];
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
    
        CYLTabbarItemsCount = [viewControllers count];
        if (![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
            _viewControllers = viewControllers;
            return;

        }
        CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;

        CYLTabBarItemWidth = (cyl_tabBar.cyl_boundsSize.width - CYLPlusButtonWidth) / (CYLTabbarItemsCount);
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
            if (viewController != CYLPlusChildViewController) {
                if (_tabBarItemsAttributes.count > idx) {
                    if (@available(iOS 13.0, *)) {
                        //fix https://github.com/ChenYilong/CYLTabBarController/issues/437
                        title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle] ?: @"";
                    } else {
                        title = _tabBarItemsAttributes[idx][CYLTabBarItemTitle];
                    }
                
                    normalImageInfo = _tabBarItemsAttributes[idx][CYLTabBarItemImage];
                    selectedImageInfo = _tabBarItemsAttributes[idx][CYLTabBarItemSelectedImage];
                    lottieURL = _tabBarItemsAttributes[idx][CYLTabBarLottieURL];
                    lottieFilePath = _tabBarItemsAttributes[idx][CYLTabBarLottieFilePath];
                
                    if (!lottieURL) {
                        lottieURL = [CYLConstants cyl_getURLFromString:lottieFilePath];
                    }
                    lottieSizeValue = _tabBarItemsAttributes[idx][CYLTabBarLottieSize];
                
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
                /**如果是CYLPlusChildViewController ，title设置为空字符串，解决把第一个tabbarItem设置成plusButton后，其他的
                 tabbarItem会不显示title问题
                  见： https://github.com/ChenYilong/CYLTabBarController/issues/563
                 **/
                title = @"";
                if ([CYLConstants isLiquidGlassActive] && ([self hasPlusButton])) {
                } else {
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
            //            //已经在addOneChildViewController 中操作， 这里无需重复处理
            //            // [self addChildViewController:viewController];
            //
            //            if (!viewController.cyl_isPlaceholder && ![viewController cyl_isEqualToViewController:CYLPlusChildViewController]) {
            //#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        _needsReloadItems = YES;
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
        CYLTabbarItemsCount = [viewControllers count];
        if (0 == CYLPlusButtonIndex) {
            CYLPlusButtonIndex = [[CYLExternPlusButton class] indexForTabbarItemsCount:CYLTabbarItemsCount];
        }
        [super setViewControllers:viewControllers];
        if (@available(iOS 27.1, *)) {
            _cylDidRefreshSystemTabBarVisibility = NO;
            if (self.isViewLoaded) { [self.view setNeedsLayout]; }
        }
        //    _viewControllers = viewControllers;
        [self alignTabControlIfNeededWithViewControllers:viewControllers];
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
 *  添加一个子控制器
 *
 *  @param viewController    控制器
 *  @param title             标题
 *  @param normalImageInfo   图片
 *  @param selectedImageInfo 选中图片
 */
- (void)addOneChildViewController:(UIViewController *)viewController
                        WithTitle:(NSString *)title
                  normalImageInfo:(id)normalImageInfo
                selectedImageInfo:(id)selectedImageInfo
          titlePositionAdjustment:(UIOffset)titlePositionAdjustment
          imagePositionAdjustment:(UIOffset)imagePositionAdjustment
                      imageInsets:(UIEdgeInsets)imageInsets
                        lottieURL:(NSURL *)lottieURL
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
    
    UIOffset offset = self.titlePositionAdjustment;
    BOOL shouldCustomizeTitlePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, titlePositionAdjustment));
    if (shouldCustomizeTitlePositionAdjustment) {
        offset = titlePositionAdjustment;
    }
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
    BOOL wasSetByCYL = [objc_getAssociatedObject(tabBarItem, &CYLTitlePositionAdjustmentSetByCYLKey) boolValue];
    if (isZero && !wasSetByCYL) {
        return;
    }
    tabBarItem.titlePositionAdjustment = offset;
    objc_setAssociatedObject(tabBarItem, &CYLTitlePositionAdjustmentSetByCYLKey, isZero ? nil : @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIImage *)getImageFromImageInfo:(id)imageInfo {
    UIImage *image = [UIImage cyl_getImageFromImageInfo:imageInfo];
    return image;
}

#pragma mark -
#pragma mark - KVO Method

// KVO监听执行
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        if(context != CYLTabImageViewDefaultOffsetContext) {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
            return;
        }
        if(context == CYLTabImageViewDefaultOffsetContext) {
            CGFloat tabImageViewDefaultOffset = [change[NSKeyValueChangeNewKey] doubleValue];
            [self offsetTabBarTabImageViewToFit:tabImageViewDefaultOffset];
        }
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
#pragma mark - Observe
    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if ([keyPath isEqualToString:@"cyl_tabBar"]) {
            CYLFlatDesignTabBar *oldTabBar = change[NSKeyValueChangeOldKey];
            [oldTabBar removeFromSuperview];
            
            CYLFlatDesignTabBar *newTabBar = change[NSKeyValueChangeNewKey];
            newTabBar.delegate = self;
            newTabBar.items = oldTabBar.items;
            newTabBar.selectedItem = oldTabBar.selectedItem;
            self.cyl_tabBar = newTabBar;
            if (newTabBar) {
                [self.view addSubview:newTabBar];
                [self.view setNeedsLayout];
            }
        }
#else
#endif
    } else {}
}


- (void)offsetTabBarTabImageViewToFit:(CGFloat)tabImageViewDefaultOffset {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    BOOL shouldCustomizeTitlePositionAdjustment= !(UIOffsetEqualToOffset(UIOffsetZero, _titlePositionAdjustment));
    BOOL shouldCustomizeImageInsets = !(UIEdgeInsetsEqualToEdgeInsets(UIEdgeInsetsZero, _imageInsets));
    if (shouldCustomizeImageInsets) {
        return;
    }
    CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;

    NSArray<UITabBarItem *> *tabBarItems = cyl_tabBar.items;
    [tabBarItems enumerateObjectsUsingBlock:^(UITabBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UIEdgeInsets imageInset = UIEdgeInsetsMake(tabImageViewDefaultOffset, 0, -tabImageViewDefaultOffset, 0);
        obj.imageInsets = imageInset;
        if (!shouldCustomizeTitlePositionAdjustment) {
            obj.titlePositionAdjustment = UIOffsetMake(0, MAXFLOAT);
        }
    }];
} else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

#pragma mark - delegate
- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    BOOL should = viewController != tabBarController.selectedViewController;
    [self updateSelectionStatusIfNeededForTabBarController:tabBarController shouldSelectViewController:viewController shouldSelect:should];
    CYLTabBar *tabBar = (CYLTabBar *)tabBarController.tabBar;
    if (should && [tabBar cyl_shouldUpdateHiddenStatueForPlusButtonLabel]) {
        if ([viewController isEqual:CYLPlusChildViewController]) {
            [CYLExternPlusButton setTabLabelHidden:YES];
        } else {
            [CYLExternPlusButton setTabLabelHidden:NO];
        }
    }
    if ([tabBarController.selectedViewController isEqual:CYLPlusChildViewController] && [tabBar cyl_shouldUpdateHiddenStatueForPlusButtonLabel]) {
        if (!should) {
            [CYLExternPlusButton setTabLabelHidden:YES];
        }
    }

    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
}

- (void)updateSelectionStatusIfNeededForTabBarController:(UITabBarController *)tabBarController
                              shouldSelectViewController:(UIViewController *)viewController
                                            shouldSelect:(BOOL)shouldSelect {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    [[viewController.tabBarItem cyl_tabButton] cyl_setUserInteractionDisabled:!shouldSelect];
    if (!shouldSelect) {
        return;
    }
    UIButton *plusButton = CYLExternPlusButton;
    if (!viewController) {
        viewController = self.selectedViewController;
    }
    if (![self hasPlusChildViewController]) {
        return;
    }
    
    BOOL isCurrentViewController = [viewController cyl_isEqualToViewController:CYLPlusChildViewController];
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
                              duration:0.01   // 几乎立即
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

    if ([tabBarController.selectedViewController isEqual:CYLPlusChildViewController] && ![tabBarController.tabBar isPlusButtonLayoutCentered]) {
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

- (void)didSelectControl:(UIControl *)control {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
    
    SEL actin = @selector(tabBarController:didSelectControl:);
    
    BOOL shouldSelectViewController =  YES;
    @try {
        shouldSelectViewController = (!control.cyl_userInteractionDisabled) && (!control.hidden) ;
    } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
        NSLog(@"🔴类名与方法名：%@（在第%@行），描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
    }
    UIControl *contentControl = control;
    UIControl *selectedContentControl = nil;
    if ([self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        selectedContentControl = [self.cyl_tabBar cyl_selectedContentControlFromContentControl:control];
        if (![control cyl_isPlusControl]) {
            [self.cyl_tabBar cyl_setSelectedControl:selectedContentControl  ?: contentControl];
        } else {
            [self.cyl_tabBar cyl_setSelectedControl:CYLExternPlusButton];
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
            //非液态玻璃 与 液态玻璃逻辑共用，Lottie播放逻辑都在 tabChangedToSelectedIndex 中。
        }
    }
    UIControl *control_ = control ?: self.selectedViewController.cyl_tabButton;
    [self tabBarController:self beginShowPlatterLiquidLensViewForControl:control_];
    
    if (shouldSelectViewController){
        if ([self.delegate respondsToSelector:actin]) {
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
             [self.delegate performSelector:actin withObject:self withObject:control_];
             );
        }
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
                        lottieURL:(NSURL *)lottieURL
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
        // FIX: issue #618 — a tab button without a matching Lottie entry (more tab buttons than
        // `tabBarItemsAttributes`) used to raise NSRangeException here.
        if (index >= self.lottieURLs.count || index >= self.lottieSizes.count) {
            return;
        }
        NSURL *lottieURL = self.lottieURLs[index];
        NSValue *lottieSizeValue = self.lottieSizes[index];
        CGSize lottieSize = [lottieSizeValue CGSizeValue];
        [control cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.lottieAnimationViewContentMode];
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
    //TODO: selectedContentControl不对，plusButton 下一个会添加失败，添加的是 plusButton对应的lottie， 顺延了。
    if (control.cyl_isPlusControl) {
        return;
    }
    
    NSURL *lottieURL = theLottieURL;
    NSValue *lottieSizeValue = theLottieSizeValue;
    if ([self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        
        @try {
            CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;
            NSUInteger index = [cyl_tabBar.cyl_subTabBarButtons indexOfObject:contentControl];
            if (NSNotFound != index) {
                if (!lottieURL) {
                    //TODO:lottieURLs 与 Control对应的index不一致， 因为 lottieURLs 可能会少一个 plusButton 对应的。如何能够不通过index就获取到 lottieURLs ?
                    lottieURL = self.lottieURLs[index];
                }
                
                if (!lottieSizeValue) {
                    lottieSizeValue = self.lottieSizes[index];
                }
            }
        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
            NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
        }
    }
    
    CGSize lottieSize = [lottieSizeValue CGSizeValue];
    [control cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.lottieAnimationViewContentMode];
    
    if (![self.cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
        return;
    }
    selectedContentControl = [self.cyl_tabBar cyl_selectedContentControlFromContentControl:contentControl];
    
    if (selectedContentControl) {
        [selectedContentControl cyl_addLottieImageWithLottieURL:lottieURL size:lottieSize contentMode:self.lottieAnimationViewContentMode];
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

#pragma mark -
#pragma mark - getter & setter
// MARK: getter & setter

- (UIView __kindof *)cyl_tabBar {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (_cyl_tabBar && [_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
            _cyl_tabBar = nil;
        }
#else
#endif
    
        if (!_cyl_tabBar) {
            // 处理tabBar，使用自定义 tabBar 并添加 发布按钮。仅限 CYLTabBar，CYLTabBarStyleTypeFlatDesign 会在 setViewControllers 内部设置。
            [self setUpDefaultStyleTabBar];
            // KVO注册监听
            if (!self.isObservingTabImageViewDefaultOffset) {
                @try {
                    //CYLTabBarController may crash when deallocating
                    [_cyl_tabBar addObserver:self forKeyPath:@"tabImageViewDefaultOffset" options:NSKeyValueObservingOptionNew context:CYLTabImageViewDefaultOffsetContext];
                } @catch(NSException *exception) {
#if defined(DEBUG) || defined(BETA)
                    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
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
     *添加自定义的 CYLFlatDesignTabBar
     */


    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (_cyl_tabBar && [_cyl_tabBar isKindOfClass:[CYLTabBar class]]) {
            _cyl_tabBar = nil;
        }
        if (!_cyl_tabBar) {
            // 通过KVC 换成 CYLFlatDesignTabBarHideTabBar 控制系统 UITabBar 永久隐藏
            CYLFlatDesignTabBarHideTabBar *tabBar = [[CYLFlatDesignTabBarHideTabBar alloc] init];
            [self cyl_setValue:tabBar forKey:@"tabBar"];
            // KVC can fail silently. Hide the actual system bar, not just the
            // replacement object that may not have been installed.
            if (!self.tabBar.hidden) { self.tabBar.hidden = YES; }
            
            CYLFlatDesignTabBar *flatDesignTabBar = [[CYLFlatDesignTabBar alloc] initWithFrame:self.tabBarFrame];
            flatDesignTabBar.delegate = self;
            _cyl_tabBar = (UIView *)flatDesignTabBar;
            _cylDidRefreshSystemTabBarVisibility = NO;
            _cylRefreshedSystemTabBarWindow = nil;
            [self.view addSubview:_cyl_tabBar];
            [self addObserver:self forKeyPath:@"cyl_tabBar" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
            
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

- (void)setContext:(NSString *)context {
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        self.cyl_context = context;
        @try {
            CYLTabBar *cyl_tabBar = (CYLTabBar *)self.cyl_tabBar;
            cyl_tabBar.context = self.cyl_context;
            [cyl_tabBar setValue:self.cyl_context forKey:@"context"];
        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
            //fix [bug]: #556
            NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@，[DEBUG] Please ensure that your custom CYLTabBarController subclass calls `super.viewDidLoad()` in the `viewDidLoad` method, and that this call is placed on the last line of the `viewDidLoad` method; otherwise, CYLTabBar KVC settings will fail.【DEBUG】请确保你的自定义 CYLTabBarController 的子类，在viewDidLoad中调用了 `super.viewDidLoad()`，且在viewDidLoad方法中最后一行调用，否则 CYLTabBar KVC 设置会失败。", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
        }
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}


    //CYLTabBarStyleTypeFlatDesign
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        self.cyl_context = context;
        @try {
            CYLFlatDesignTabBar *cyl_tabBar = (CYLFlatDesignTabBar *)self.cyl_tabBar;

            cyl_tabBar.context = self.cyl_context;
            [cyl_tabBar setValue:self.cyl_context forKey:@"context"];
        } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
            //fix [bug]: #556
            NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@，【DEBUG】请确保你的自定义 CYLTabBarController 的子类，在viewDidLoad中调用了 `super.viewDidLoad()`，且在viewDidLoad方法中最后一行调用，否则 CYLTabBar KVC 设置会失败。", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
#endif
        }
        
        if ([[CYLExternPlusButton class] respondsToSelector:@selector(tabBarContext)]) {
            NSString *plusButtonContext = [[CYLExternPlusButton class] performSelector:@selector(tabBarContext)];
            if (plusButtonContext && ![self.cyl_context isEqualToString:plusButtonContext]) {
                // contexts differ; remove PlusButton
                if ([[CYLExternPlusButton class] respondsToSelector:@selector(removePlusButton)]) {
                    [[CYLExternPlusButton class] performSelector:@selector(removePlusButton)];
                }
            }
        }
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
            _tabBarHeight = CYLTabBarHeight;
        }
        return _tabBarHeight;
        
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
    
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return _tabBarHeight; }
        if (0 == _tabBarHeight) {
            _tabBarHeight = CYLTabBarHeight;
        }
        return _tabBarHeight;
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    return _tabBarHeight;
}

//#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
    NSUInteger indexOfSelectedViewController = [self.childViewControllers indexOfObject:selectedViewController];
    if (NSNotFound == indexOfSelectedViewController) { return; }
    [super setSelectedViewController:selectedViewController];
    _selectedViewController = selectedViewController;

    if (selectedViewController.cyl_isPlaceholder) { return; }

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
        //必须调用父类逻辑。
        //    _selectedViewController = selectedViewController;
        //
        //    [super setSelectedViewController:selectedViewController];
        // Fix: #574 解决iOS15 扁平风格， 有时候TabBar会变透明的问题
        if (CYL_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"15.0") && ![CYLConstants isLiquidGlassActive]) {
            if (nil == [UITabBar appearance].backgroundImage) {
                @try {
                    //因为非核心功能， 仅为部分版本的细节修复， 所以用try catch 防止异常， 防止影响主要功能。
                    if (self.cyl_tabBar.cyl_tabBackgroundView && self.cyl_tabBar.cyl_tabBackgroundView.cyl_tabEffectView) {
                        self.cyl_tabBar.cyl_tabBackgroundView.cyl_tabEffectView.alpha = 1;
                    }
                    if (self.cyl_tabBar.cyl_tabShadowImageView && (self.cyl_tabBar.cyl_tabShadowImageView.subviews.count > 0)) {
                        self.cyl_tabBar.cyl_tabShadowImageView.subviews.firstObject.alpha = 1;
                    }
                } @catch (NSException *exception) {
#if defined(DEBUG) || defined(BETA)
                    NSLog(@"🔴类名与方法名：%@（在第%@行）, 描述：%@", @(__PRETTY_FUNCTION__), @(__LINE__), exception.reason);
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
        if ([selectedViewController isEqual:CYLPlusChildViewController]) {
            CYLExternPlusButton.selected = YES;
            [self tabChangedToSelectedIndex:CYLPlusButtonIndex
                             viewController:selectedViewController
                                    control:CYLExternPlusButton];
        } else {
            [self tabChangedToSelectedIndex:self.selectedIndex
                             viewController:selectedViewController
                                    control:control];
        }
        [self cyl_setNeedsLiquidGlassTabBarResample];
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}


    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (NSNotFound == selectedIndex) { return; }
        //  iOS26 液态玻璃样式 不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
            
        // 用户点击 tab 时会触发 //showing initial vc for every tab :)
        //        UIControl *control = selectedViewController.cyl_tabButton;
        if ([selectedViewController isEqual:CYLPlusChildViewController]) {
            CYLExternPlusButton.selected = YES;
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
    if (!viewController || !CYLExternPlusButton || ![self hasPlusButton] || ![self hasPlusChildViewController]) {
        return nil;
    }
    if (![viewController cyl_isEqualToViewController:CYLPlusChildViewController]) {
        return nil;
    }
    Class plusButtonClass = [CYLExternPlusButton class];
    if ([plusButtonClass respondsToSelector:@selector(shouldSelectPlusChildViewController)] &&
        ![plusButtonClass shouldSelectPlusChildViewController]) {
        return nil;
    }
    return CYLExternPlusButton;
}

#pragma mark - Override selectedIndex (Programmatic changes)

- (void)setSelectedIndex:(NSUInteger)selectedIndex {
    //    if (self.selectedIndex == selectedIndex) { return; }
    CYL_IF_NOT_FLATDESIGN_BEGIN     //Not CYLTabBarStyleTypeFlatDesign
        [super setSelectedIndex:selectedIndex];
    
        UIViewController *selectedViewController;
        if (self.viewControllers && self.viewControllers.count > 0 && self.viewControllers.count > selectedIndex) {
            selectedViewController = [self.viewControllers objectAtIndex:selectedIndex];
            self.selectedViewController = selectedViewController;
        }
        //  iOS26 液态玻璃样式 不再使用点击事件， 而是在 `-setSelectedViewController` and `-setSelectedIndex`中处理
        // 代码切换 tab 时会触发
        if (YES == _selectedViewController.cyl_isPlaceholder) {
            return;
        }
        [self tabChangedToSelectedIndex:selectedIndex
                         viewController:selectedViewController
                                control:[self cyl_plusButtonControlIfSelectingPlusChildViewController:selectedViewController]];
    
    } else {/**  CYLTabBarStyleTypeFlatDesign*/}
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        if (self.selectedIndex != selectedIndex) {
            _selectedIndex = selectedIndex;
            [super setSelectedIndex:selectedIndex];
            if (selectedIndex < 0 || selectedIndex >= self.viewControllers.count) { return; }
            _selectedViewController = self.viewControllers[selectedIndex];
            if (_needsReloadItems) {
                [self _captureItems];
                [self.cyl_tabBar setItems:self.items];
                _needsReloadItems = NO;
            }
            //TODO:  这里避免使用selectedViewController，因为 self.viewControllers 被经过PlusButton补充，
            //        self.cyl_tabBar.selectedItem = selectedItem;
            [self tabChangedToSelectedIndex:selectedIndex viewController:nil selectedItem:nil];
            
        }
        [self _updateBottomBarShowHideIfNeeded];
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    
}

- (CGSize)visiableTabBarSize {
    return self.cyl_tabBarController.tabBar.cyl_boundsSize;
}

/*!
 * 三个地方 ， 都要调用：
 *  选中状态下的重新点击，（iOS26 需要在手势代理方法中进行hook追加该方法）
 *  用户切换index时
 *  代码切换index 时。
 **/
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
- (void)tabChangedToSelectedIndex:(NSUInteger)selectedIndex
                   viewController:(UIViewController *)viewController
                     selectedItem:(CYLFlatDesignTabBarItem *)selectedItem {
    
    CYL_IF_FLATDESIGN_BEGIN
    
    //扁平样式可使用
    if (![self.tabBar isKindOfClass:[UITabBar class]] && ![self.tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) {
        return;
    }
    if (!viewController) {
        viewController = self.selectedViewController;
    }
    if (!selectedItem) {
        selectedItem = viewController.cyl_tabBarItem;
    }
    UIControl *control = viewController.cyl_tabButton;
    //    BOOL isChildViewControllerPlusButton = [control cyl_isChildViewControllerPlusButton];
    //    BOOL isLottieEnabled = [self isLottieEnabled];
    
    //TODO:  setSelectedIndex 这里避免使用selectedViewController，因为 self.viewControllers 被经过PlusButton补充，
    
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
// MARK: 状态栏

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
        
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return childViewController; }
        return childViewController;
#else
#endif
        
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
    return childViewController;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation {
    UIViewController *childViewController = self.childViewControllerForStatusBarStyle;

    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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

#pragma mark - UIContentContainer
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)

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
        SEL actin = @selector(tabBarController:didSelectControl:);
        if ([self.delegate respondsToSelector:actin]) {
            CYL_SUPPRESS_ARC_PERFORM_SELECTOR_LEAKS
            (
             [self.delegate performSelector:actin withObject:self withObject:tabBarItem.tabBarButton];
             )
            
        }
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        //    [[viewController.tabBarItem cyl_tabButton] cyl_setUserInteractionDisabled:!shouldSelect];
        if (!shouldSelect) {
            return;
        }
        UIButton *plusButton = CYLExternPlusButton;
        if (!viewController) {
            viewController = self.selectedViewController;
        }
        if (![self hasPlusChildViewController]) {
            return;
        }
        
        BOOL isCurrentViewController = [viewController cyl_isEqualToViewController:CYLPlusChildViewController];
        
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

#pragma mark - UINavigationControllerExtensionDelegate
- (void)cylflatdesign_navigationController:(UINavigationController *)navigationController
              navigationBarDidChangeHeight:(CGFloat)height {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        // 转场或pop手势返回时禁止用户交互
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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

#pragma mark - Private

- (CGRect)tabBarFrame {
    CGRect tabBarFrame = _cyl_tabBar.frame;
    CGFloat tabBarHeight = self.tabBarHeight + self.view.safeAreaInsets.bottom;
    tabBarFrame = CGRectMake(0, CGRectGetHeight(self.view.bounds) - tabBarHeight, CGRectGetWidth(self.view.bounds), tabBarHeight);
    return tabBarFrame;
}

- (BOOL)_showsMoreNavigationController {
    // 用 self.viewControllers.count > 5 判断行不行？
    BOOL _showsMoreNavigationController = NO;
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
        if (![_cyl_tabBar isKindOfClass:[CYLFlatDesignTabBar class]]) { return; }
        
        BOOL showsTabBar = [self _shouldShowsBottomBar];
        if (!_tabBarIsAnimating) {
            self.cyl_tabBar.hidden = !showsTabBar;
        }
        [self _updateAdditionalSafeAreaInsetsWithAnimated:NO];
#else
#endif
    } else {/** Not CYLTabBarStyleTypeFlatDesign*/}
}

- (void)_addParallaxOverlayViewToViewController:(UIViewController *)viewController {
    if (CYLTabBarStyleTypeFlatDesign == self.tabBarStyleType) {
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)
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
    
#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)

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

@implementation NSObject (CYLTabBarControllerReferenceExtension)

- (void)cyl_setTabBarController:(CYLTabBarController *)tabBarController {
    id __weak weakObject = tabBarController;
    id (^block)(void) = ^{ return weakObject; };
    objc_setAssociatedObject(self, @selector(cyl_tabBarController),
                             block, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

//TODO: 更新实现，多实例场景下进行栈操作，弹出最新一个。
- (CYLTabBarController *)cyl_tabBarController {
    CYLTabBarController *tabBarController;
    id (^block)(void) = objc_getAssociatedObject(self, @selector(cyl_tabBarController));
    tabBarController = (block ? block() : nil);
    if (tabBarController && [tabBarController cyl_isSystemStyleTabBar]) {
        return tabBarController;
    }
    if ([self isKindOfClass:[UIViewController class]] && [(UIViewController *)self parentViewController]) {
        tabBarController = [[(UIViewController *)self parentViewController] cyl_tabBarController];
        if ([tabBarController cyl_isSystemStyleTabBar]) {
            return tabBarController;
        }
    }
    
    UIViewController *rootViewController = [CYLGetRootViewController() cyl_getViewControllerInsteadOfNavigationController];;
    if ([rootViewController cyl_isSystemStyleTabBar]) {
        tabBarController = (CYLTabBarController *)rootViewController;
    }
    return tabBarController;
}
#pragma mark - @implementation UIViewController (CYLFlatDesignUITabBarControllerItem) @implementation UIViewController (CYLFlatDesignUIViewControllerItem)
// MARK: @implementation UIViewController (CYLFlatDesignUITabBarControllerItem) @implementation UIViewController (CYLFlatDesignUIViewControllerItem)

#if __has_include(<CYLTabBarController/CYLFlatDesignTabBar.h>)


- (void)cylflatdesign_setTabBarController:(UIViewController *)tabBarController {
    // The property is declared `weak` in the header, so store a weak box instead of
    // retaining the tab bar controller directly. A strong reference here creates a
    // retain cycle (tab bar controller -> child view controller -> tab bar controller)
    // and the whole FlatDesign tab tree is never deallocated after it is popped (#661).
    UIViewController *tabBarController_ = tabBarController;
    objc_setAssociatedObject(self, @selector(cylflatdesign_tabBarController), [self cyl_cylflatdesign_weakBoxWithTarget:tabBarController_], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return;
    }
    if (referenceViewController.cyl_getViewControllerInsteadOfNavigationController) {
        objc_setAssociatedObject(referenceViewController.cyl_getViewControllerInsteadOfNavigationController, @selector(cylflatdesign_tabBarController), [self cyl_cylflatdesign_weakBoxWithTarget:tabBarController_], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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

/// Wraps `target` in a block that only holds it weakly, matching `cyl_setTabBarController:`.
/// The block itself is retained by the associated object, but the target is not.
- (id)cyl_cylflatdesign_weakBoxWithTarget:(UIViewController *)target {
    id __weak weakTarget = target;
    return ^{ return weakTarget; };
}

- (UIViewController __kindof *)cylflatdesign_tabBarController {
    // The associated object is always a weak box block; unwrap it.
    id (^box)(void) = objc_getAssociatedObject(self, @selector(cylflatdesign_tabBarController));
    UIViewController *viewController = (box ? box() : nil);
    if (viewController) {
        return viewController;
    }
    /*!
     *     viewController = [self cyl_nearestParentViewControllerThatIsKindOf:[CYLFlatDesignUIViewController class]];
     if (viewController) {
     return viewController;
     }
     */
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return nil;
    }
    
    UIViewController *flatDesignTabBarController = referenceViewController.tabBarController;
    
    if ([flatDesignTabBarController cyl_isFlatDesignStyleTabBar]) {
        viewController = flatDesignTabBarController;
    }
    flatDesignTabBarController = referenceViewController.cyl_getViewControllerInsteadOfNavigationController.tabBarController;
    
    if ([flatDesignTabBarController cyl_isFlatDesignStyleTabBar]) {
        viewController = flatDesignTabBarController;
    }
    flatDesignTabBarController = [self cyl_nearestParentViewControllerThatIsFlatDesignStyleTabBar];
    
    if ([flatDesignTabBarController cyl_isFlatDesignStyleTabBar]) {
        viewController = flatDesignTabBarController;
    }
    
    return viewController;
}


- (UIViewController __kindof *)cyl_nearestParentViewControllerThatIsFlatDesignStyleTabBar {
    UIViewController *referenceViewController = nil;
    if ([self isKindOfClass:[UIViewController class]]) {
        referenceViewController = (UIViewController *)self;
    }
    if (!referenceViewController) {
        return nil;
    }
    UIViewController *controller = referenceViewController.parentViewController;
    while (controller && ![controller cyl_isFlatDesignStyleTabBar]) {
        controller = controller.parentViewController;
    }
    
    if (controller && [controller cyl_isFlatDesignStyleTabBar]) {
        return (UIViewController *)controller;
    }
    return nil;
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
