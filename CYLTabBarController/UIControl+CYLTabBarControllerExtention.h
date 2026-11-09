//
//  CYLTabBarController.m
//  CYLTabBarController
//
//  v1.99.x Created by 微博@iOS程序犭袁 ( http://weibo.com/luohanchenyilong/ ) on 10/20/15.
//  Copyright © 2026 https://github.com/ChenYilong . All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CYLConstants.h"

NS_ASSUME_NONNULL_BEGIN
@class LOTAnimationView;
@interface UIControl (CYLTabBarControllerExtention)

/*!
 * [EN] Returns the Lottie animation view inside this tab button (searching two levels deep); nil for the plus button.
 * [CN] 返回 Tab 按钮内的 Lottie 动画视图（向下查找两层）；PlusButton 返回 nil。
 */
- (nullable UIView *)cyl_lottieAnimationView DEPRECATED_MSG_ATTRIBUTE("Use -cyl_tabBarItemAnimationView");

/*!
 * [EN] Returns YES if the control is the plus button that has a child view controller added to the tab bar.
 * [CN] 判断当前控件是否为已添加子控制器的 PlusButton。
 */
- (BOOL)cyl_isChildViewControllerPlusButton;

/*!
 * [EN] Returns YES if the control is selected and its tab is the tab bar controller's selected index.
 * [CN] 判断当前控件是否处于选中状态，且对应的 Tab 为 TabBarController 当前选中的索引。
 */
- (BOOL)cyl_isSelected;

/*!
 * [EN] Returns YES if the Lottie animation view has been added and laid out.
 * [CN] 判断 Lottie 动画视图是否已添加并完成布局。
 */
- (BOOL)cyl_isLottieReady DEPRECATED_MSG_ATTRIBUTE("Use -cyl_isTabBarItemAnimationReady");

/*!
 * [EN] Returns YES if the control is the plus button (the registered plus button class, or the plus child view controller's button).
 * [CN] 判断当前控件是否为 PlusButton（已注册的 PlusButton 类，或 PlusButton 子控制器对应的按钮）。
 */
- (BOOL)cyl_isPlusControl;

/*!
 * PlusButton without plusViewController equals NSNotFound
 */
@property (nonatomic, assign, getter=cyl_tabBarChildViewControllerIndex, setter=cyl_setTabBarChildViewControllerIndex:) NSInteger cyl_tabBarChildViewControllerIndex;

/*!
 * FIX: issue #408
 * [EN] The identifier of this tab button or plus button, nil when it has none. Use it in
 *      `-tabBarController:didSelectControl:`. In order: a value set here; for a plus button,
 *      `+[CYLPlusButtonSubclassing tabBarItemIdentifier]`, else its class name (e.g. @"CYLPlusButtonSubclass"); the
 *      identifier of the tab it selects (`CYLTabBarItemIdentifier`, else the default).
 * [CN] 该 Tab 按钮或 PlusButton 的标识，没有时为 nil，可在 `-tabBarController:didSelectControl:` 中使用。依次取：这里设置的值；
 *      PlusButton 的 `+[CYLPlusButtonSubclassing tabBarItemIdentifier]`，未实现时为其类名（如 @"CYLPlusButtonSubclass"）；
 *      所选 Tab 的标识（`CYLTabBarItemIdentifier`，未设置时为默认值）。
 */
@property (nonatomic, copy, nullable, getter=cyl_tabBarItemIdentifier, setter=cyl_setTabBarItemIdentifier:) NSString *cyl_tabBarItemIdentifier;

/*!
 * [EN] A name to show for this tab button or plus button, e.g. in an alert or a log: the title the user sees (its
 *      accessibility label), else `cyl_tabBarItemIdentifier`, else its class name. An identifier can be a generated
 *      class name (e.g. a SwiftUI hosting controller's), so the title comes first.
 * [CN] 用于显示该 Tab 按钮或 PlusButton 的名称（例如弹框或日志中）：依次取用户看到的标题（其 accessibility label）、
 *      `cyl_tabBarItemIdentifier`、类名。标识可能是自动生成的类名（例如 SwiftUI hosting controller 的类名），因此优先使用标题。
 */
@property (nonatomic, copy, readonly, getter=cyl_tabBarItemDisplayName) NSString *cyl_tabBarItemDisplayName;

/*!
 * PlusButton has its own visible index,
 * in this case PlusButton is same as TabBarItem
 */
@property (nonatomic, assign, getter=cyl_tabBarItemVisibleIndex, setter=cyl_setTabBarItemVisibleIndex:) NSInteger cyl_tabBarItemVisibleIndex;
/*!
 *
 * [CN] 对于- (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control;
 *   // 即使 PlusButton 也添加了自定义点击事件，点击 PlusButton 后也会触发该代理方法。
    // 可在PlusButton初始化时使用 CYLExternPlusButton.cyl_shouldNotSelect = YES; 来禁止该协议方法触发plusButton回调
 [EN] For - (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control;
      Even if the PlusButton has its own custom tap event, tapping the PlusButton still triggers this delegate method.
      Set CYLExternPlusButton.cyl_shouldNotSelect = YES; when initializing the PlusButton to stop this protocol
      method from firing the plusButton callback
 */
/*!
 * ⚠️ [EN] Deprecated: it did two jobs at once, the app's switch for the plus button's `tabBarController:didSelectControl:`
 *      reports and the library's lock on the selected tab button, which turned the plus button's reports off once its
 *      page was selected. Use `CYLPlusButton.reportsTapsToDelegate`. Still works: while `reportsTapsToDelegate` is not
 *      set, YES here keeps the plus button's taps out of the delegate, as before.
 * ⚠️ [CN] 已废弃：它同时承担两件事——App 控制 PlusButton 是否回调 `tabBarController:didSelectControl:` 的开关，以及库对已选中 Tab 按钮的锁定，
 *      导致 PlusButton 页面选中后不再上报点击。请使用 `CYLPlusButton.reportsTapsToDelegate`。仍然有效：未设置 `reportsTapsToDelegate` 时，
 *      这里设为 YES 仍会阻止 PlusButton 的点击回调代理，与以前相同。
 */
@property (nonatomic, assign, getter=cyl_shouldNotSelect, setter=cyl_setShouldNotSelect:) BOOL cyl_shouldNotSelect CYL_DEPRECATED("Use CYLPlusButton.reportsTapsToDelegate");
/*!
 * same as cyl_userInteractionDisabled.
 * [CN] 对于- (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control;
 *   // 即使 PlusButton 也添加了自定义点击事件，点击 PlusButton 后也会触发该代理方法。
    // 可在PlusButton初始化时使用 CYLExternPlusButton.cyl_userInteractionDisabled = YES; 来禁止该协议方法触发plusButton回调
 [EN] For - (void)tabBarController:(CYLTabBarController *)tabBarController didSelectControl:(UIControl *)control;
      Even if the PlusButton has its own custom tap event, tapping the PlusButton still triggers this delegate method.
      Set CYLExternPlusButton.cyl_userInteractionDisabled = YES; when initializing the PlusButton to stop this
      protocol method from firing the plusButton callback
 */
/*!
 * ⚠️ [EN] Deprecated: it did two jobs at once, the app's switch for the plus button's `tabBarController:didSelectControl:`
 *      reports and the library's lock on the selected tab button, which turned the plus button's reports off once its
 *      page was selected. Use `CYLPlusButton.reportsTapsToDelegate`. Still works: while `reportsTapsToDelegate` is not
 *      set, YES here keeps the plus button's taps out of the delegate, as before.
 * ⚠️ [CN] 已废弃：它同时承担两件事——App 控制 PlusButton 是否回调 `tabBarController:didSelectControl:` 的开关，以及库对已选中 Tab 按钮的锁定，
 *      导致 PlusButton 页面选中后不再上报点击。请使用 `CYLPlusButton.reportsTapsToDelegate`。仍然有效：未设置 `reportsTapsToDelegate` 时，
 *      这里设为 YES 仍会阻止 PlusButton 的点击回调代理，与以前相同。
 */
@property (nonatomic, assign, getter=cyl_userInteractionDisabled, setter=cyl_setUserInteractionDisabled:) BOOL cyl_userInteractionDisabled CYL_DEPRECATED("Use CYLPlusButton.reportsTapsToDelegate");

/*!
 * [EN] Adds a Lottie animation view loaded from `lottieURL` in place of the tab image; does nothing if one already exists or for the plus button.
 * [CN] 用 lottieURL 加载 Lottie 动画视图并替换 Tab 图片；已存在动画视图或为 PlusButton 时不做处理。
 */
- (void)cyl_addLottieImageWithLottieURL:(nullable NSURL *)lottieURL
                                   size:(CGSize)size
                            contentMode:(UIViewContentMode)contentMode DEPRECATED_MSG_ATTRIBUTE("Use -cyl_addTabBarItemAnimationWithURL:size:contentMode:");

/*!
 * [EN] Adds a Lottie animation view loaded from a local file path in place of the tab image; a zero `size` uses the default placeholder size.
 * [CN] 用本地文件路径加载 Lottie 动画视图并替换 Tab 图片；size 为 CGSizeZero 时使用默认占位尺寸。
 */
- (void)cyl_addLottieImageWithLottieFilePath:(NSString *)lottieFilePath
                                   size:(CGSize)size
                            contentMode:(UIViewContentMode)contentMode DEPRECATED_MSG_ATTRIBUTE("Use -cyl_addTabBarItemAnimationWithURL:size:contentMode: with a file URL");

/*!
 * [EN] Same as `-cyl_addLottieImageWithLottieURL:size:contentMode:`, and sets `animationSpeed` on the Lottie view when this
 *      call adds it. An existing view keeps its speed, so a speed set for one tab is not overwritten later.
 * [CN] 同 `-cyl_addLottieImageWithLottieURL:size:contentMode:`，本次调用新添加 Lottie 视图时设置其 `animationSpeed`。
 *      已存在的视图保持原速度，因此为某个 Tab 单独设置的速度之后不会被覆盖。
 */
- (void)cyl_addLottieImageWithLottieURL:(nullable NSURL *)lottieURL
                                   size:(CGSize)size
                            contentMode:(UIViewContentMode)contentMode
                         animationSpeed:(CGFloat)animationSpeed DEPRECATED_MSG_ATTRIBUTE("Use -cyl_addTabBarItemAnimationWithURL:size:contentMode:animationSpeed:");

/*!
 * [EN] Sets the playback speed of this tab's Lottie animation view, e.g. 1.5 for 1.5 times as fast. Does nothing when the
 *      view has not been added yet, when Lottie is not integrated, or for a value of 0 or less. To set it for every tab,
 *      set `-[CYLTabBarController lottieAnimationSpeed]` instead (issue #428).
 * [CN] 设置当前 Tab 的 Lottie 动画视图播放速度，例如 1.5 表示 1.5 倍速。动画视图尚未添加、未集成 Lottie 或传入值小于等于 0 时
 *      不做处理。为所有 Tab 设置时，请改为设置 `-[CYLTabBarController lottieAnimationSpeed]`（issue #428）。
 */
- (void)cyl_setLottieAnimationSpeed:(CGFloat)animationSpeed DEPRECATED_MSG_ATTRIBUTE("Use -cyl_setTabBarItemAnimationSpeed:");

/*!
 * FIX: issue #442
 * [EN] Swaps this tab's Lottie view for the version of its animation that matches the current interface style
 *      (`CYLTabBarLottieDarkURL`), keeping its position and playback state. Does nothing when it already matches, has no
 *      dark version, or Lottie is not integrated. CYLTabBarController calls it when the style changes.
 * [CN] 将当前 Tab 的 Lottie 视图替换为与当前界面风格相符的动画版本（`CYLTabBarLottieDarkURL`），保持位置和播放状态。已相符、
 *      没有深色版本或未集成 Lottie 时不做处理。CYLTabBarController 在风格变化时会自动调用。
 */
- (void)cyl_reloadLottieAnimationViewForCurrentStyle DEPRECATED_MSG_ATTRIBUTE("Use -cyl_reloadTabBarItemAnimationViewForCurrentStyle");

/*!
 * [EN] Plays the Lottie animation for this tab (adding the view if needed); shows the final frame instead when `defaultSelected` is YES.
 * [CN] 播放当前 Tab 的 Lottie 动画（必要时先添加视图）；defaultSelected 为 YES 时直接显示最后一帧。
 */
- (void)cyl_animationLottieImageWithLottieURL:(NSURL *)lottieURL
                                         size:(CGSize)size
                              defaultSelected:(BOOL)defaultSelected
                                  contentMode:(UIViewContentMode)contentMode DEPRECATED_MSG_ATTRIBUTE("Use -cyl_playTabBarItemAnimationWithURL:size:defaultSelected:contentMode:");

/*!
 * [EN] Stops this tab's Lottie animation if it has started.
 * [CN] 若当前 Tab 的 Lottie 动画已开始播放，则停止。
 */
- (void)cyl_stopAnimationOfLottieView DEPRECATED_MSG_ATTRIBUTE("Use -cyl_stopTabBarItemAnimation");

/*!
 * [EN] Replaces the tab image view with `newView`.
 * [CN] 用 newView 替换 Tab 按钮的图片视图。
 */
- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                      show:(BOOL)show;

/*!
 * [EN] Replaces the tab image view with `newView` at `offset`, calling `completion` with the result.
 * [CN] 用 newView 替换 Tab 按钮的图片视图并应用 offset 偏移，完成后通过 completion 回调结果。
 */
- (void)cyl_replaceTabImageViewWithNewView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)show
                                completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Replaces the whole tab button with `newView` and hides the original image view.
 * [CN] 用 newView 替换整个 Tab 按钮，并隐藏原图片视图。
 */
- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                   show:(BOOL)show;


/*!
 * [EN] Replaces the whole tab button with `newView` at `offset`, calling `completion` with the result.
 * [CN] 用 newView 替换整个 Tab 按钮并应用 offset 偏移，完成后通过 completion 回调结果。
 */
- (void)cyl_replaceTabButtonWithNewView:(UIView *)newView
                                 offset:(UIOffset)offset
                                   show:(BOOL)theShow
                             completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Returns YES if the control is a Liquid Glass platter selected-state control.
 * [CN] 判断当前控件是否为液态玻璃 Platter 中的选中态控件。
 */
- (BOOL)cyl_isPlatterSelectedControl;

/*!
 * [EN] Returns the platter selected-state control matching this control, or self if none.
 * [CN] 返回与当前控件对应的 Platter 选中态控件，没有则返回自身。
 */
- (nullable UIControl *)cyl_platterSelectedControl;

/*!
 * [EN] Returns YES if the control lives in the platter content view (normal state).
 * [CN] 判断当前控件是否位于 Platter 内容视图中（常态控件）。
 */
- (BOOL)cyl_isPlatterNormalControl;

/*!
 * [EN] Returns the platter normal-state control matching this control, or self if none.
 * [CN] 返回与当前控件对应的 Platter 常态控件，没有则返回自身。
 */
- (UIControl *)cyl_platterNormalControl;

/*!
 * [EN] Covers the tab image view (or the whole button) with `newView` without hiding the original; waits `delay` seconds if the button is not ready yet (e.g. Lottie still loading).
 * [CN] 用 newView 覆盖 Tab 图片视图（或整个按钮），不隐藏原视图；按钮未就绪（如 Lottie 未初始化完成）时延迟 delay 秒执行。
 */
- (void)cyl_coverTabImageViewOrTabButton:(BOOL)isTabButton
                                 newView:(UIView *)newView
                                  offset:(UIOffset)offset
                                    show:(BOOL)theShow
                 delayIfNeededForSeconds:(CGFloat)delay
                              completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Same as `-cyl_coverTabImageViewOrTabButton:...`, applied to the platter selected-state control (or self).
 * [CN] 同 -cyl_coverTabImageViewOrTabButton:...，但作用于 Platter 选中态控件（没有则作用于自身）。
 */
- (void)cyl_coverSeclectContentTabImageViewOrTabButton:(BOOL)isTabButton
                               newView:(UIView *)newView
                                    offset:(UIOffset)offset
                                      show:(BOOL)theShow
                           delayIfNeededForSeconds:(CGFloat)delay
                                            completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Covers the visible tab image view (or button) with `newView`; forwards to the selected-content variant.
 * [CN] 用 newView 覆盖当前可见的 Tab 图片视图（或按钮），内部转调选中态内容的覆盖方法。
 */
- (void)cyl_coverVisiableTabImageViewOrTabButton:(BOOL)isTabButton
                                         newView:(UIView *)newView
                                          offset:(UIOffset)offset
                                            show:(BOOL)theShow
                         delayIfNeededForSeconds:(CGFloat)delay
                                      completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Covers the normal-state content with `contentNewView` and the selected-state content with `seclectContentNewView`.
 * [CN] 分别用 contentNewView 覆盖常态内容、用 seclectContentNewView 覆盖选中态内容。
 */
- (void)cyl_coverVisiableTabImageViewOrTabButton:(BOOL)isTabButton
                                  contentNewView:(UIView *)contentNewView
                           seclectContentNewView:(UIView *)seclectContentNewView
                                          offset:(UIOffset)offset
                                            show:(BOOL)theShow
                         delayIfNeededForSeconds:(CGFloat)delay
                                      completion:(void(^)(BOOL isReplaced, UIControl *tabBarButton, UIView *newView))completion;

/*!
 * [EN] Hides the control and its selected-state counterpart, including labels and images, and disables their interaction.
 * [CN] 隐藏当前控件及其选中态对应控件（包括标题与图片），并禁用交互。
 */
- (void)cyl_hideControl;

@end

@interface UIControl (CYLTabBarControllerExtentionDeprecated)

@property (nonatomic, strong, setter=cyl_setTabBadgePointView:, getter=cyl_tabBadgePointView) UIView *cyl_tabBadgePointView CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
@property (nonatomic, assign, setter=cyl_setTabBadgePointViewOffset:, getter=cyl_tabBadgePointViewOffset) UIOffset cyl_tabBadgePointViewOffset CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
/*!
 * *  调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 * @attention 已经废弃，请改用`-[UIViewController cyl_showBadgeValue:animationType:]`
 * [EN] Deprecated. Shows the red-dot badge. Use `-[UIViewController cyl_showBadgeValue:animationType:]` instead.
 * [CN] 已废弃。显示红点角标，请改用 -[UIViewController cyl_showBadgeValue:animationType:]。
 */
- (void)cyl_showTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
/*!
 * *  调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 * @attention 已经废弃，请改用`-[UIViewController cyl_showBadgeValue:animationType:]`
 * [EN] Deprecated. Removes the red-dot badge. Use `-[UIViewController cyl_clearBadge]` instead.
 * [CN] 已废弃。移除红点角标，请改用 -[UIViewController cyl_clearBadge]。
 */
- (void)cyl_removeTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");
/*!
 * *  调用该方法前已经添加了系统的角标，调用该方法后，系统的角标并未被移除，只是被隐藏，调用 `-cyl_removeTabBadgePoint` 后会重新展示。
 * @attention 已经废弃，请改用`-[UIViewController cyl_showBadgeValue:animationType:]`
 * [EN] Deprecated. Returns YES if the red-dot badge is shown. Use `-[UIViewController cyl_isShowBadge]` instead.
 * [CN] 已废弃。判断红点角标是否显示，请改用 -[UIViewController cyl_isShowBadge]。
 */
- (BOOL)cyl_isShowTabBadgePoint CYL_DEPRECATED("Deprecated in 1.19.0. Use method in <CYLBadgeProtocol> instead.");

@end

/*!
 * FIX: issue #604
 * [EN] Library-neutral tab icon animation (Lottie, PAG, Rive…). Every call goes to the animation service of the
 *      `CYLTabBarItemAnimation` subspec; without an animation subspec they do nothing. They replace the deprecated
 *      Lottie-named methods above (`-cyl_lottieAnimationView`, `-cyl_addLottieImageWithLottieURL:…`…).
 * [CN] 与动画库无关的 Tab 图标动画方法（Lottie、PAG、Rive…）。每个调用都交给 `CYLTabBarItemAnimation` 子库的动画服务；没有引入
 *      动画子库时不做处理。它们取代上面已废弃的 Lottie 命名方法（`-cyl_lottieAnimationView`、`-cyl_addLottieImageWithLottieURL:…`…）。
 */
@interface UIControl (CYLTabBarItemAnimation)

/// [EN] The tab's animation view (searching two levels deep); nil for the plus button. [CN] Tab 的动画视图（向下查找两层）；PlusButton 返回 nil。
- (nullable UIView *)cyl_tabBarItemAnimationView;

/// [EN] YES once the animation view has been added and laid out. [CN] 动画视图已添加并完成布局时返回 YES。
- (BOOL)cyl_isTabBarItemAnimationReady;

/// [EN] Adds the animation at `URL` (a local file) in place of the tab's icon, once; a zero `size` uses the placeholder size.
/// [CN] 用 `URL`（本地文件）的动画替换 Tab 图标显示（只添加一次）；size 为 CGSizeZero 时使用占位尺寸。
- (void)cyl_addTabBarItemAnimationWithURL:(nullable NSURL *)URL
                                     size:(CGSize)size
                              contentMode:(UIViewContentMode)contentMode;

/// [EN] The same, and sets `animationSpeed` when this call adds the view (#428). [CN] 同上，本次调用新添加视图时设置 `animationSpeed`（#428）。
- (void)cyl_addTabBarItemAnimationWithURL:(nullable NSURL *)URL
                                     size:(CGSize)size
                              contentMode:(UIViewContentMode)contentMode
                           animationSpeed:(CGFloat)animationSpeed;

/// [EN] Sets the playback speed; nothing for a value of 0 or less, or a library without speed. [CN] 设置播放速度；小于等于 0 或动画库没有播放速度时不做处理。
- (void)cyl_setTabBarItemAnimationSpeed:(CGFloat)animationSpeed;

/// [EN] Swaps the view for the version of its animation matching the current style (#442). [CN] 将视图替换为与当前界面风格相符的动画版本（#442）。
- (void)cyl_reloadTabBarItemAnimationViewForCurrentStyle;

/*!
 * FIX: issue #216
 * [EN] Replaces the animation of this tab button by the one at `URL`, keeping the playback state (a theme that gives the
 *      tab another file); adds it when the button has none. `-updateTabBarItemsWithAttributes:` calls it for an
 *      animation key, so a `CYLTabBarTheme` does not need to.
 * [CN] 把本 Tab 按钮的动画替换为 `URL` 的动画并保留播放状态（主题为该 Tab 指定了另一个文件）；按钮没有动画时添加。
 *      `-updateTabBarItemsWithAttributes:` 遇到动画 key 时会调用它，`CYLTabBarTheme` 无需自己调用。
 */
- (void)cyl_replaceTabBarItemAnimationWithURL:(NSURL *)URL size:(CGSize)size contentMode:(UIViewContentMode)contentMode;

/*!
 * FIX: issue #216
 * [EN] Applies the colors registered for this tab button's animation again (`CYLTabBarAnimationColors`, resolved for the
 *      current theme, plus the dark colors in Dark Mode). Called for you on every theme change.
 * [CN] 重新应用为本 Tab 按钮动画注册的颜色（按当前主题解析的 `CYLTabBarAnimationColors`，深色模式下加上深色颜色）。每次主题切换时会自动调用。
 */
- (void)cyl_refreshTabBarItemAnimationColors;

/// [EN] Adds the animation if needed and plays it (`defaultSelected`: shows its last frame). [CN] 必要时添加动画并播放（`defaultSelected`：显示最后一帧）。
- (void)cyl_playTabBarItemAnimationWithURL:(NSURL *)URL
                                      size:(CGSize)size
                           defaultSelected:(BOOL)defaultSelected
                               contentMode:(UIViewContentMode)contentMode;

/// [EN] Stops the tab's animation if it has started. [CN] 若 Tab 的动画已开始播放，则停止。
- (void)cyl_stopTabBarItemAnimation;

@end

NS_ASSUME_NONNULL_END
