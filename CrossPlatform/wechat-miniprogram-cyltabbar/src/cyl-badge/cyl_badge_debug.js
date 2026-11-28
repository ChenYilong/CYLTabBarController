/**
 * [EN] The badge debugging switch (docs/Badge-Debugging.md), moved here from `cyl-tab-bar/cyl_debug.js`, which re-exports it:
 *      true leaves out the badge animation classes (cyl-badge-<type>), so a screenshot shows each badge at its laid-out
 *      place while badge positions are checked. Change it, rebuild, change it back before committing; never publish it on.
 * [CN] 角标调试开关（docs/Badge-Debugging.md），从 `cyl-tab-bar/cyl_debug.js` 移到这里（那里重新导出）：为 true 时不添加角标动画类
 *      （cyl-badge-<type>），调试角标坐标时截图中的角标就在布局位置。修改后重新编译，提交前改回；不要发布开启的版本。
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
