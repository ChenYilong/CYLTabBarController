/**
 * [EN] The example's configuration: the shared sample (Example-Shared/Configurations/cyl_tabbar_configuration.json,
 *      copied to shared/configuration.js) plus a raised plus button with its own page, as every example sets
 *      CYLTabBarController up (AGENTS.md, "How the examples set CYLTabBarController up").
 * [CN] 示例的配置：共用示例配置（Example-Shared/Configurations/cyl_tabbar_configuration.json，复制为
 *      shared/configuration.js），加上带有自己页面的凸起 PlusButton，与所有示例的设置方式相同（AGENTS.md「How the
 *      examples set CYLTabBarController up」）。
 */
const cylSharedConfiguration = require('../shared/configuration');

const CYL_DEMO_PLUS_BUTTON = {
  CYLTabBarItemTitle: 'Post',
  CYLTabBarItemImage: 'system:plus.circle',
  CYLTabBarItemSelectedImage: 'system:plus.circle.fill',
  CYLTabBarItemIdentifier: 'publish',
  CYLTabBarItemPageIdentifier: 'publish',
  CYLPlusButtonCenterYMultiplier: 0.3,
  CYLPlusButtonImageSize: '{56, 56}',
  CYLPlusButtonKeepsTitleVisible: true,
};

/**
 * [EN] A third skin, with the Christmas icons of the shared manifest (Skins/2.1.0/christmas).
 * [CN] 第三个皮肤，使用共用清单中的圣诞图标（Skins/2.1.0/christmas）。
 */
const CYL_DEMO_CHRISTMAS_THEME = {
  CYLTabBarItemTitleColor: '#2E7D32',
  CYLTabBarItemSelectedTitleColor: '#C62828',
  CYLTabBarBackgroundColor: '#FFF8E1',
};

/**
 * [EN] The configuration with the example's overrides (style type, tap animation, login-required tabs), which the Me
 *      page changes at run time.
 * [CN] 带有示例覆盖项（样式、点击动画、需要登录的 Tab）的配置，Me 页面会在运行时修改这些覆盖项。
 */
function cylDemoConfiguration(overrides) {
  return Object.assign({}, cylSharedConfiguration, {
    CYLTabBarControllerPlusButton: CYL_DEMO_PLUS_BUTTON,
    CYLTabBarControllerThemes: Object.assign({}, cylSharedConfiguration.CYLTabBarControllerThemes, {
      christmas: CYL_DEMO_CHRISTMAS_THEME,
    }),
    CYLTabBarControllerTabButtonTapAnimation: 'bounce',
  }, overrides || {});
}

module.exports = { cylDemoConfiguration };
