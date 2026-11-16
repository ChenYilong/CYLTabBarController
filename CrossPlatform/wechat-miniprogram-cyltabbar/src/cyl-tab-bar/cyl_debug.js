/**
 * [EN] Debugging switches of the component, the mini program counterpart of the build options of the iOS, Android and
 *      HarmonyOS cores. A mini program has no compile-time defines, so they are constants in the source: change one,
 *      rebuild in the developer tools, and change it back before committing. Never publish a version with one on.
 * [CN] 组件的调试开关，对应 iOS、Android 与鸿蒙核心库的编译选项。小程序没有编译期宏，因此写成源码中的常量：修改后在开发者工具中重新编译，
 *      提交前改回。不要发布开启了开关的版本。
 */

/**
 * [EN] Badge debugging (docs/Badge-Debugging.md): true leaves out the badge animation classes (cyl-badge-<type>), so a
 *      screenshot shows each badge at its laid-out place while badge positions are checked.
 * [CN] 角标调试（docs/Badge-Debugging.md）：为 true 时不添加角标动画类（cyl-badge-<type>），调试角标坐标时截图中的角标就在布局位置。
 */
const CYL_BADGE_ANIMATION_DISABLED = false;

/**
 * [EN] The class of a badge animation ('' when there is none or the badge debugging switch is on).
 * [CN] 角标动画的类名（没有动画或开启角标调试开关时为 ''）。
 */
function cylBadgeAnimationClass(animation, disabled = CYL_BADGE_ANIMATION_DISABLED) {
  return !disabled && animation ? `cyl-badge-${animation}` : '';
}

module.exports = { CYL_BADGE_ANIMATION_DISABLED, cylBadgeAnimationClass };
