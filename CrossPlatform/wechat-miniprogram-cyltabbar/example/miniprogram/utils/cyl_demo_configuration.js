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
  CYLPlusButtonShowsSelection: true,
};

/**
 * [EN] Icon colors for the dark skin: its "system:" images are tinted (#787), so the light images it falls back to are
 *      readable on the dark bar.
 * [CN] 深色皮肤的图标颜色：其 "system:" 图片会被着色（#787），因此它回退使用的浅色图片在深色 TabBar 上也清晰可见。
 */
const CYL_DEMO_DARK_ICON_COLORS = {
  CYLTabBarItemIconColor: '#AEAEB2',
  CYLTabBarItemSelectedIconColor: '#0A84FF',
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
 * [EN] Lottie tab icons (Example/Classes/Other/LottieResources of the Objective-C example, copied to shared/lottie by
 *      scripts/cyl_sync_shared.js), by tab identifier; the Me page turns them off ("cylDemoLottie": false).
 * [CN] Lottie Tab 图标（Objective-C 示例的 Example/Classes/Other/LottieResources，由 scripts/cyl_sync_shared.js 复制到
 *      shared/lottie），按 Tab 标识；Me 页面可以关闭它们（"cylDemoLottie": false）。
 */
const CYL_DEMO_LOTTIE = {
  home: 'green_lottie_tab_home',
  discover: 'green_lottie_tab_discover',
  me: 'green_lottie_tab_mine',
};

function cylDemoLottieItems(items) {
  return items.map((attributes) => {
    const name = CYL_DEMO_LOTTIE[attributes.CYLTabBarItemIdentifier];
    return name ? Object.assign({}, attributes, {
      CYLTabBarLottieURL: `${name}.json`,
      CYLTabBarLottieDarkURL: `${name}_dark.json`,
      CYLTabBarLottieSize: '{30, 30}',
    }) : attributes;
  });
}

/**
 * [EN] The configuration with the example's overrides (style type, tap animation, login-required tabs), which the Me
 *      page changes at run time.
 * [CN] 带有示例覆盖项（样式、点击动画、需要登录的 Tab）的配置，Me 页面会在运行时修改这些覆盖项。
 */
function cylDemoConfiguration(overrides) {
  const options = overrides || {};
  let items = options.cylDemoLottie === false
    ? cylSharedConfiguration.CYLTabBarControllerTabBarItemsAttributes
    : cylDemoLottieItems(cylSharedConfiguration.CYLTabBarControllerTabBarItemsAttributes);
  if (options.cylDemoBoldTitles) {
    items = items.map((attributes) => Object.assign({}, attributes, { CYLTabBarItemSelectedTitleFont: 'bold:11' }));
  }
  const configurationOverrides = Object.assign({}, options);
  delete configurationOverrides.cylDemoLottie;
  delete configurationOverrides.cylDemoBoldTitles;
  return Object.assign({}, cylSharedConfiguration, {
    CYLTabBarControllerTabBarItemsAttributes: items,
    CYLTabBarControllerPlusButton: CYL_DEMO_PLUS_BUTTON,
    CYLTabBarControllerThemes: Object.assign({}, cylSharedConfiguration.CYLTabBarControllerThemes, {
      dark: Object.assign({}, cylSharedConfiguration.CYLTabBarControllerThemes.dark, CYL_DEMO_DARK_ICON_COLORS),
      christmas: CYL_DEMO_CHRISTMAS_THEME,
    }),
    CYLTabBarControllerTabButtonTapAnimation: 'bounce',
  }, configurationOverrides);
}

module.exports = { cylDemoConfiguration };
