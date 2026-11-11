//
//  CYLTabBarController+CYLInteraction.h
//  CYLTabBarController
//
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
// [EN] The category needs the class; CYLTabBarController.h imports this header at its end, after the class.
// [CN] 分类需要类的声明；CYLTabBarController.h 在文件末尾（类声明之后）导入本头文件。
#import "CYLTabBarController.h"
#import "CYLTabButtonAnimation.h"
#import "CYLTabBarTransition.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 * FIX: issue #535
 * [EN] Built-in tap animations, see `cyl_tabButtonTapAnimationType`.
 * [CN] 内置的点击动画，见 `cyl_tabButtonTapAnimationType`。
 */
typedef NS_ENUM(NSInteger, CYLTabButtonTapAnimationType) {
    /*!
     * [EN] No animation (default). [CN] 无动画（默认）。
     */
    CYLTabButtonTapAnimationTypeNone = 0,
    /*!
     * [EN] 1.0 → 1.5 → 0.8 → 1.0, `CYLTabButtonScaleAnimation`. [CN] 放大再缩小。
     */
    CYLTabButtonTapAnimationTypeScale,
    /*!
     * [EN] Grows from small, `CYLTabButtonZoomInAnimation`. [CN] 从小放大。
     */
    CYLTabButtonTapAnimationTypeZoomIn,
    /*!
     * [EN] Elastic bounce, `CYLTabButtonBounceAnimation`. [CN] 弹性动画。
     */
    CYLTabButtonTapAnimationTypeBounce,
    /*!
     * [EN] Bounce with fireworks. [CN] 弹性动画加烟花。
     */
    CYLTabButtonTapAnimationTypeBounceWithFireworks,
    /*!
     * [EN] One full turn, `CYLTabButtonRotationAnimation`. [CN] 旋转一圈。
     */
    CYLTabButtonTapAnimationTypeRotation,
    /*!
     * [EN] Flip from left, `CYLTabButtonFlipAnimation`. [CN] 从左翻转。
     */
    CYLTabButtonTapAnimationTypeFlip,
    /*!
     * [EN] Icon down, title floats away, `CYLTabButtonFumeAnimation`. [CN] 图标下移、标题飘散。
     */
    CYLTabButtonTapAnimationTypeFume,
};

/*!
 * FIX: issue #535
 * [EN] Called on a long press on a tab button or the plus button.
 * [CN] 长按 Tab 按钮或 PlusButton 时回调。
 */
typedef void (^CYLTabBarControllerDidLongPressControlBlock)(CYLTabBarController *tabBarController, UIControl *control);

/*!
 * FIX: issue #535
 * [EN] Interaction features suggested in issue #535, for every style (classic, Liquid Glass and FlatDesign). They are
 *      all off by default, so nothing changes until you turn them on:
 *        - a tap animation for the tab buttons and the plus button (an enum, an animation object for all tabs, or one per tab);
 *        - a long press on a tab button or the plus button (a block or `-tabBarController:didLongPressControl:`);
 *        - swiping the page left or right to switch to the next or previous tab.
 *      The existing ways stay available: Lottie icons, your own animation in `-tabBarController:didSelectControl:`,
 *      and your own UITabBarControllerDelegate transitions (`CYLTabBarSlideTransitionAnimator`).
 * [CN] issue #535 中建议的交互功能，适用于所有样式（经典、液态玻璃与扁平样式）。默认全部关闭，开启前没有任何变化：
 *        - Tab 按钮与 PlusButton 的点击动画（枚举、所有 Tab 共用的动画对象，或每个 Tab 单独设置）；
 *        - 长按 Tab 按钮或 PlusButton（block 或 `-tabBarController:didLongPressControl:`）；
 *        - 左右滑动页面切换到下一个或上一个 Tab。
 *      原有方式仍然可用：Lottie 图标、在 `-tabBarController:didSelectControl:` 中自己做动画，以及自己的 UITabBarControllerDelegate 转场
 *      （`CYLTabBarSlideTransitionAnimator`）。
 */
@interface CYLTabBarController (CYLInteraction)

#pragma mark - Tap animation

/*!
 * [EN] The built-in tap animation of every tab button and the plus button. Default `CYLTabButtonTapAnimationTypeNone`.
 *      `cyl_defaultTabButtonAnimation` and `UIViewController.cyl_tabButtonAnimation` take precedence.
 * [CN] 所有 Tab 按钮与 PlusButton 的内置点击动画，默认 `CYLTabButtonTapAnimationTypeNone`。
 *      `cyl_defaultTabButtonAnimation` 与 `UIViewController.cyl_tabButtonAnimation` 优先。
 */
@property (nonatomic, assign, setter=cyl_setTabButtonTapAnimationType:) CYLTabButtonTapAnimationType cyl_tabButtonTapAnimationType;

/*!
 * [EN] An animation object for every tab button and the plus button: one of the `CYLTabButton...Animation` classes or
 *      your own `<CYLTabButtonAnimation>`. Takes precedence over `cyl_tabButtonTapAnimationType`.
 * [CN] 所有 Tab 按钮与 PlusButton 共用的动画对象：`CYLTabButton...Animation` 类之一，或自己实现的 `<CYLTabButtonAnimation>`。
 *      优先于 `cyl_tabButtonTapAnimationType`。
 */
@property (nonatomic, strong, nullable, setter=cyl_setDefaultTabButtonAnimation:) id<CYLTabButtonAnimation> cyl_defaultTabButtonAnimation;

/*!
 * [EN] Plays the tap animation of `control` now (the one that applies to it), e.g. from your own gesture.
 * [CN] 立即播放 `control` 的点击动画（对它生效的那个），例如在自己的手势中调用。
 */
- (void)cyl_playTabButtonAnimationForControl:(UIControl *)control;

#pragma mark - Tap sound and haptic feedback

/*!
 * FIX: issue #535
 * [EN] Plays a sound on every reported tap of a tab button or the plus button: right before
 *      `-tabBarController:didSelectControl:` is called, together with the tap animation, so in the same cases (a tap, a
 *      repeated tap on the selected tab, a swipe, a change of `selectedIndex` in code; not a tap refused by the login
 *      check). Default NO. The sound is `cyl_tabButtonTapSoundURL`, or the system keyboard click when it is nil. Like any
 *      system sound, it follows the ring/silent switch and the system volume. Ported from the `PlaySound` /
 *      `NSObject (Sound)` code suggested in the issue (JobsKits/JobsTabbarItemLottie); here the sound is created once and
 *      released when it changes.
 * [CN] 每次上报 Tab 按钮或 PlusButton 的点击时播放声音：在调用 `-tabBarController:didSelectControl:` 之前，与点击动画同时，因此场景相同
 *      （点击、再次点击已选中的 Tab、滑动切换、代码修改 `selectedIndex`；被登录检查拒绝的点击不会播放）。默认 NO。声音为 `cyl_tabButtonTapSoundURL`，为 nil 时使用
 *      系统键盘点击声。与所有系统音效一样，受静音开关与系统音量控制。移植自 issue 中建议的 `PlaySound` / `NSObject (Sound)` 代码
 *      （JobsKits/JobsTabbarItemLottie）；这里音效只创建一次，更换时释放。
 */
@property (nonatomic, assign, setter=cyl_setTabButtonTapSoundEnabled:) BOOL cyl_tabButtonTapSoundEnabled;

/*!
 * [EN] A local sound file (a file URL; .caf, .wav or .aif, at most 30 seconds) for `cyl_tabButtonTapSoundEnabled`.
 *      nil (default): the system keyboard click.
 * [CN] `cyl_tabButtonTapSoundEnabled` 使用的本地音频文件（文件 URL；.caf、.wav 或 .aif，最长 30 秒）。nil（默认）：系统键盘点击声。
 */
@property (nonatomic, copy, nullable, setter=cyl_setTabButtonTapSoundURL:) NSURL *cyl_tabButtonTapSoundURL;

/*!
 * FIX: issue #535
 * [EN] Plays an impact haptic on every reported tap of a tab button or the plus button, with the tap sound (see
 *      `cyl_tabButtonTapSoundEnabled` for when). Default NO. Ported from the
 *      issue's `+feedbackGenerator` (`UIImpactFeedbackGenerator`). Only devices with a Taptic Engine vibrate; the
 *      simulator does not.
 * [CN] 每次上报 Tab 按钮或 PlusButton 的点击时播放触感反馈，与点击声音时机相同（见 `cyl_tabButtonTapSoundEnabled`）。默认 NO。移植自 issue 中的 `+feedbackGenerator`
 *      （`UIImpactFeedbackGenerator`）。只有带 Taptic Engine 的设备会振动，模拟器不会。
 */
@property (nonatomic, assign, setter=cyl_setTabButtonHapticFeedbackEnabled:) BOOL cyl_tabButtonHapticFeedbackEnabled;

/*!
 * [EN] The strength of `cyl_tabButtonHapticFeedbackEnabled`. Default `UIImpactFeedbackStyleMedium`, as in the issue.
 * [CN] `cyl_tabButtonHapticFeedbackEnabled` 的强度。默认 `UIImpactFeedbackStyleMedium`，与 issue 一致。
 */
@property (nonatomic, assign, setter=cyl_setTabButtonHapticFeedbackStyle:) UIImpactFeedbackStyle cyl_tabButtonHapticFeedbackStyle;

/*!
 * [EN] Plays the tap sound and the haptic now, the ones that are turned on, e.g. from your own button.
 * [CN] 立即播放已开启的点击声音与触感反馈，例如在自己的按钮中调用。
 */
- (void)cyl_playTabButtonTapFeedback;

#pragma mark - Long press

/*!
 * [EN] Called on a long press on a tab button or the plus button, before `-tabBarController:didLongPressControl:`.
 *      With either of them, a long press no longer selects the tab when the finger lifts.
 * [CN] 长按 Tab 按钮或 PlusButton 时回调，先于 `-tabBarController:didLongPressControl:`。设置了任意一个时，长按后抬起手指不会再选中该 Tab。
 */
@property (nonatomic, copy, nullable, setter=cyl_setDidLongPressControlBlock:) CYLTabBarControllerDidLongPressControlBlock cyl_didLongPressControlBlock;

/*!
 * [EN] How long a press lasts before it is a long press. Default 0.5 s, at least 0.1 s. The same value as
 *      `cyl_tabBarItemLongPressDuration` (issue #152): one recognizer serves both long press APIs.
 * [CN] 按住多久算长按，默认 0.5 秒，最短 0.1 秒。与 `cyl_tabBarItemLongPressDuration`（issue #152）是同一个值：两套长按 API
 *      共用一个手势。
 */
@property (nonatomic, assign, setter=cyl_setTabButtonLongPressMinimumDuration:) NSTimeInterval cyl_tabButtonLongPressMinimumDuration;

#pragma mark - Swipe to switch tabs

/*!
 * [EN] Swipe the page left for the next tab and right for the previous one, with a slide animation. Default NO.
 *      The tab under the plus button is skipped when the plus button has no child view controller. The switch goes
 *      through `-tabBarController:shouldSelectViewController:` and the login check (issue #19), like a tap. It starts
 *      only on a horizontal swipe, when the selected tab's navigation stack is at its root, and not on a horizontally
 *      scrolling scroll view, so the back gesture and carousels keep working.
 * [CN] 向左滑动页面切换到下一个 Tab，向右切换到上一个，带滑动动画。默认 NO。PlusButton 没有子控制器时跳过其下方的 Tab。切换与点击一样
 *      经过 `-tabBarController:shouldSelectViewController:` 与登录检查（issue #19）。仅在水平滑动、当前 Tab 的导航栈位于根控制器，
 *      且不在可横向滚动的 scrollView 上时触发，因此返回手势与轮播图不受影响。
 */
@property (nonatomic, assign, setter=cyl_setSwipeToSwitchTabEnabled:) BOOL cyl_swipeToSwitchTabEnabled;

/*!
 * [EN] Selects the next (`step` 1) or previous (`step` -1) selectable tab with the slide animation, as a swipe does.
 *      Returns NO when there is none or the switch was refused.
 * [CN] 与滑动相同：带滑动动画选中下一个（`step` 为 1）或上一个（`step` 为 -1）可选中的 Tab。没有可选的 Tab 或切换被拒绝时返回 NO。
 */
- (BOOL)cyl_switchToAdjacentTabWithStep:(NSInteger)step animated:(BOOL)animated;

@end

/*!
 * FIX: issue #535
 * [EN] A tap animation for this view controller's tab only; takes precedence over the tab bar controller's.
 * [CN] 仅用于该控制器所在 Tab 的点击动画，优先于 TabBarController 的设置。
 */
@interface UIViewController (CYLTabButtonAnimation)

@property (nonatomic, strong, nullable, setter=cyl_setTabButtonAnimation:) id<CYLTabButtonAnimation> cyl_tabButtonAnimation;

@end

NS_ASSUME_NONNULL_END
