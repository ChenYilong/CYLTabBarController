package com.cyl.tabbar;

import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.lang.reflect.Method;

/**
 * [EN] `CYLTabButtonAnimation` (issue #535): a tap animation of a tab button or the plus button. The tab bar controller
 *      plays it when the button is selected (a tap, a repeated tap on the selected tab, or a change of `selectedIndex`
 *      in code). `button` is the tab button (or the plus button), `iconView` its image view and `titleLabel` its title,
 *      null when it has none.
 *      Every method is optional, as on iOS, and comes in the same two spellings (`cyl_play…` and `cylPlay…`); when both
 *      are implemented, the `cylPlay…` one is called. A Java interface, so that `cyl_respondsToSelector` can tell an
 *      implemented method from the default one, like `-respondsToSelector:`.
 * [CN] `CYLTabButtonAnimation`（issue #535）：Tab 按钮或 PlusButton 的点击动画。按钮被选中时（点击、再次点击已选中的 Tab、代码修改
 *      `selectedIndex`）由 TabBarController 播放。`button` 为 Tab 按钮（或 PlusButton），`iconView` 为其图片视图，`titleLabel` 为其
 *      标题，没有标题时为 null。
 *      与 iOS 一样，每个方法都是可选的，并有相同的两种写法（`cyl_play…` 与 `cylPlay…`）；两者都实现时调用 `cylPlay…`。使用 Java 接口，
 *      以便 `cyl_respondsToSelector` 能像 `-respondsToSelector:` 一样区分已实现的方法与默认方法。
 */
public interface CYLTabButtonAnimation {

    /**
     * [EN] Plays the animation of a button that is being selected. [CN] 播放按钮被选中的动画。
     */
    default void cyl_playSelectAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] `cyl_playSelectAnimationWithTabButton` without the underscore. [CN] 去掉下划线的写法。
     */
    default void cylPlaySelectAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] `cyl_playDeselectAnimationWithTabButton` without the underscore. [CN] 去掉下划线的写法。
     */
    default void cylPlayDeselectAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] `cyl_playReselectAnimationWithTabButton` without the underscore. [CN] 去掉下划线的写法。
     */
    default void cylPlayReselectAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] `cyl_playHighlightAnimationWithTabButton` without the underscore. [CN] 去掉下划线的写法。
     */
    default void cylPlayHighlightAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] `cyl_playDehighlightAnimationWithTabButton` without the underscore. [CN] 去掉下划线的写法。
     */
    default void cylPlayDehighlightAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] `cyl_playBadgeChangedAnimationWithTabButton` without the underscore. [CN] 去掉下划线的写法。
     */
    default void cylPlayBadgeChangedAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable View badgeView) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] Plays the animation of the button selected before, when another button gets selected. [CN] 另一个按钮被选中时，播放之前选中按钮的动画。
     */
    default void cyl_playDeselectAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] Undoes what this animation left on the button (a held frame, a hidden title, a moved icon) when another
     *      animation takes over the button.
     * [CN] 其他动画接管按钮时，撤销本动画留在按钮上的状态（停留的帧、隐藏的标题、移动的图标）。
     */
    default void cyl_resetTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] `cyl_fromLeft`, set before the select animation: true when the button selected before is on the left. [CN] 选中动画前设置：之前选中的按钮在左侧时为 true。
     */
    default boolean cyl_isFromLeft() {
        return false;
    }

    default void cyl_setFromLeft(boolean fromLeft) {
        // [EN] Optional: implement it together with `cyl_isFromLeft`. [CN] 可选：与 `cyl_isFromLeft` 一起实现。
    }

    /**
     * [EN] `cyl_toRight`, set before the deselect animation: true when the button selected next is on the right. [CN] 取消选中动画前设置：之后选中的按钮在右侧时为 true。
     */
    default boolean cyl_isToRight() {
        return false;
    }

    default void cyl_setToRight(boolean toRight) {
        // [EN] Optional: implement it together with `cyl_isToRight`. [CN] 可选：与 `cyl_isToRight` 一起实现。
    }

    /**
     * [EN] A tap on the selected button (a reselect); without it the select animation plays again. [CN] 再次点击已选中的按钮；未实现时再次播放选中动画。
     */
    default void cyl_playReselectAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] A finger went down on the button (pressed). [CN] 手指按下按钮。
     */
    default void cyl_playHighlightAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] The finger lifted from a pressed button, or its touch was cancelled. [CN] 手指从按下的按钮抬起，或触摸被取消。
     */
    default void cyl_playDehighlightAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable TextView titleLabel) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] The button's badge appeared or changed (not removed). [CN] 按钮的角标出现或改变（不含移除）。
     */
    default void cyl_playBadgeChangedAnimationWithTabButton(@NonNull View button, @NonNull View iconView, @Nullable View badgeView) {
        // [EN] Optional. [CN] 可选。
    }

    /**
     * [EN] `-respondsToSelector:` for these optional methods: true when the object's class implements the method named
     *      `selector` (a method name of this interface), not only the interface's default. Override it when whether a
     *      method counts as implemented changes at run time, as `CYLTabButtonBlockAnimation` does.
     * [CN] 这些可选方法的 `-respondsToSelector:`：对象的类实现了名为 `selector` 的方法（本接口的方法名）而不只是接口默认实现时为 true。
     *      某个方法是否算作已实现会在运行时变化时重写它，如 `CYLTabButtonBlockAnimation`。
     */
    default boolean cyl_respondsToSelector(@NonNull String selector) {
        for (Method method : getClass().getMethods()) {
            if (method.getName().equals(selector) && method.getDeclaringClass() != CYLTabButtonAnimation.class && !method.getDeclaringClass().isInterface()) {
                return true;
            }
        }
        return false;
    }
}
