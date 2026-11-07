// [EN] The method names are the iOS names on purpose (`cyl_…`, `tabBarController_…`), see docs/Android-API-Map.md. [CN] 方法名刻意沿用 iOS 名称（`cyl_…`、`tabBarController_…`），见 docs/Android-API-Map.md。
@file:Suppress("FunctionName", "kotlin:S100")

package com.cyl.tabbar

import android.view.View

/**
 * [EN] `CYLTabBarControllerDelegate` (and the `UITabBarControllerDelegate` methods it extends), every method optional.
 * [CN] `CYLTabBarControllerDelegate`（含其继承的 `UITabBarControllerDelegate` 方法），每个方法都可选。
 */
interface CYLTabBarControllerDelegate {

    // MARK: - UITabBarControllerDelegate

    /** [EN] Return false to refuse the selection. [CN] 返回 false 拒绝选中。 */
    fun tabBarController_shouldSelectViewController(tabBarController: CYLTabBarController, viewController: CYLViewController): Boolean = true

    fun tabBarController_didSelectViewController(tabBarController: CYLTabBarController, viewController: CYLViewController) { /* [EN] Optional. [CN] 可选。 */ }

    /**
     * [EN] `-tabBarController:animationControllerForTransitionFromViewController:toViewController:`: return a
     *      `CYLTabBarSlideTransitionAnimator` to slide between the pages; null: no transition.
     * [CN] 返回 `CYLTabBarSlideTransitionAnimator` 以滑动切换页面；null：无转场。
     */
    fun tabBarController_animationControllerForTransition(tabBarController: CYLTabBarController, fromViewController: CYLViewController, toViewController: CYLViewController): CYLTabBarSlideTransitionAnimator? = null

    /** [EN] `-tabBarController:interactionControllerForAnimationController:`: a `CYLTabBarInteractiveTransition` while a pan drives the transition. [CN] 拖动驱动转场时返回 `CYLTabBarInteractiveTransition`。 */
    fun tabBarController_interactionControllerForAnimationController(tabBarController: CYLTabBarController, animationController: CYLTabBarSlideTransitionAnimator): CYLTabBarInteractiveTransition? = null

    // MARK: - CYLTabBarControllerDelegate

    /** [EN] Issue #19: whether selecting `viewController` needs the user to be logged in. [CN] 选中该页面是否需要登录（issue #19）。 */
    fun tabBarController_requiresLoginToSelectViewController(tabBarController: CYLTabBarController, viewController: CYLViewController): Boolean =
        tabBarController.cyl_isLoginRequiredForViewController(viewController)

    /** [EN] Issue #19: present the login UI, then call `completion(loggedIn)`. [CN] 展示登录界面，完成后调用 `completion(loggedIn)`（issue #19）。 */
    fun tabBarController_presentLoginForViewController(tabBarController: CYLTabBarController, viewController: CYLViewController, completion: (Boolean) -> Unit) {
        completion(false)
    }

    /** [EN] A tab button was tapped (after the selection). [CN] 点击了某个 Tab 按钮（选中之后）。 */
    fun tabBarController_didSelectControl(tabBarController: CYLTabBarController, control: View) { /* [EN] Optional. [CN] 可选。 */ }

    /** [EN] A gesture on a tab button (#535): tap, double tap, long press, swipe. [CN] Tab 按钮上的手势（#535）。 */
    fun tabBarController_didRecognizeTabBarItemGesture(tabBarController: CYLTabBarController, gesture: CYLEnums.CYLTabBarItemGesture, control: View, viewController: CYLViewController?) { /* [EN] Optional. [CN] 可选。 */ }

    /** [EN] A long press on a tab button. [CN] 长按了某个 Tab 按钮。 */
    fun tabBarController_didLongPressControl(tabBarController: CYLTabBarController, control: View) { /* [EN] Optional. [CN] 可选。 */ }

    /** [EN] Custom tab actions: whether the tab runs an action instead of being selected. [CN] 自定义 Tab 动作：是否执行动作而不是选中。 */
    fun tabBarController_shouldPerformCustomActionForViewController(tabBarController: CYLTabBarController, viewController: CYLViewController): Boolean =
        tabBarController.cyl_isCustomActionTabViewController(viewController)

    fun tabBarController_performCustomActionForViewController(tabBarController: CYLTabBarController, viewController: CYLViewController) { /* [EN] Optional. [CN] 可选。 */ }

    /** [EN] Liquid Glass only on iOS; Android has no lens view: the answer is ignored. [CN] 仅 iOS 液态玻璃；Android 没有镜片视图，返回值被忽略。 */
    fun tabBarController_shouldShowPlatterLiquidLensViewForControl(tabBarController: CYLTabBarController, control: View): Boolean = true

    /** [EN] An asynchronous page arrived (`page`), or failed (nil) and the tab was removed (docs/Tab-Page-Registry.md). [CN] 异步页面到达（或失败，Tab 已移除）。 */
    fun cyl_tabBarController_didLoadPage(tabBarController: CYLTabBarController, page: CYLViewController?, placeholder: CYLViewController, index: Int) { /* [EN] Optional. [CN] 可选。 */ }
}
