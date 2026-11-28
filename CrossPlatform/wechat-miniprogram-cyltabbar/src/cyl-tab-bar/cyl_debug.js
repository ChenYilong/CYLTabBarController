/**
 * [EN] Debugging switches of the component, the mini program counterpart of the build options of the iOS, Android and
 *      HarmonyOS cores. A mini program has no compile-time defines, so they are constants in the source: change one,
 *      rebuild in the developer tools, and change it back before committing. Never publish a version with one on.
 * [CN] 组件的调试开关，对应 iOS、Android 与鸿蒙核心库的编译选项。小程序没有编译期宏，因此写成源码中的常量：修改后在开发者工具中重新编译，
 *      提交前改回。不要发布开启了开关的版本。
 */

/**
 * [EN] Badge debugging moved to `cyl-badge/cyl_badge_debug.js` (the badge module owns its switch); re-exported here so the old
 *      path keeps working (docs/Badge-Debugging.md).
 * [CN] 角标调试移到 `cyl-badge/cyl_badge_debug.js`（角标模块拥有自己的开关）；在此重新导出，旧路径仍可用（docs/Badge-Debugging.md）。
 */
module.exports = require('../cyl-badge/cyl_badge_debug');
