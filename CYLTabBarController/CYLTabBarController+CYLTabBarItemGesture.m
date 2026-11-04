//
//  CYLTabBarController+CYLTabBarItemGesture.m
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

// [EN] Tab bar item gestures: tap, double tap and long press (issue #152).
//      Split out of CYLTabBarController.m without changes.
// [CN] Tab bar item 手势：单击、双击与长按（issue #152）。
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
    return self.cyl_tabBarItemGestureHandler != nil ||
        [self.delegate respondsToSelector:@selector(tabBarController:didRecognizeTabBarItemGesture:control:viewController:)];
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
    CYLTabBarItemGestureHandler handler = self.cyl_tabBarItemGestureHandler;
    if (handler) {
        handler(self, gesture, control, viewController);
    }
    id<CYLTabBarControllerDelegate> delegate = (id<CYLTabBarControllerDelegate>)self.delegate;
    if ([delegate respondsToSelector:@selector(tabBarController:didRecognizeTabBarItemGesture:control:viewController:)]) {
        [delegate tabBarController:self didRecognizeTabBarItemGesture:gesture control:control viewController:viewController];
    }
}

- (void)cyl_recognizeTabBarItemGestureForReportedControl:(UIControl *)control {
    if (![self cyl_hasTabBarItemGestureReceiver]) {
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
    if (![self cyl_hasTabBarItemGestureReceiver] || !viewController || viewController.cyl_isPlaceholder) {
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
    if (![self cyl_hasTabBarItemGestureReceiver]) {
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
    if (![self cyl_hasTabBarItemGestureReceiver] || ![self hasPlusButton]) {
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
