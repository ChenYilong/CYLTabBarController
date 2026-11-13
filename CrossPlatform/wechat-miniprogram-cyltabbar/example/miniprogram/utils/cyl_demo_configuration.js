/**
 * [EN] The example's configuration: the shared sample (Example-Shared/Configurations/cyl_tabbar_configuration.json,
 *      copied to shared/configuration.js) plus a raised plus button with its own page, as every example sets
 *      CYLTabBarController up (AGENTS.md, "How the examples set CYLTabBarController up").
 * [CN] 示例的配置：共用示例配置（Example-Shared/Configurations/cyl_tabbar_configuration.json，复制为
 *      shared/configuration.js），加上带有自己页面的凸起 PlusButton，与所有示例的设置方式相同（AGENTS.md「How the
 *      examples set CYLTabBarController up」）。
 */
const cylSharedConfiguration = require('../shared/configuration');
const cylAnimations = require('../shared/animations');

/**
 * [EN] The example installs one animation package (`npm run setup -- --animation=lottie|pag|rive|gif`, see
 *      scripts/cyl_animation_choice.js); shared/animations.js names it and lists its icons.
 * [CN] 示例只安装一个动画包（`npm run setup -- --animation=lottie|pag|rive|gif`，见 scripts/cyl_animation_choice.js）；
 *      shared/animations.js 给出它的名称并列出其图标。
 */
function cylInstalledAnimation() {
  return cylAnimations.installed;
}

/**
 * [EN] The icons of the installed animation package that are in the code package (PAG files may not be downloaded).
 * [CN] 已安装动画包中存在于代码包内的图标（PAG 文件可能未下载）。
 */
function cylAvailableAnimationFiles() {
  return cylAnimations.files.filter((file) => {
    try {
      wx.getFileSystemManager().accessSync(file);
      return true;
    } catch (error) {
      return false;
    }
  });
}

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
  message: 'green_lottie_tab_news',
  discover: 'green_lottie_tab_discover',
  me: 'green_lottie_tab_mine',
};

/**
 * [EN] Four tabs and the plus button, as the iOS example: the shared configuration limits Message to iOS and Android
 *      (CYLTabBarItemPlatforms "ios,android", which the Platforms key demonstrates), so the example adds this platform.
 * [CN] 与 iOS 示例一样显示四个 Tab 与 PlusButton：共用配置把 Message 限定为 iOS 与 Android（CYLTabBarItemPlatforms
 *      "ios,android"，用于演示 Platforms 键），因此示例为它加上本平台。
 */
function cylDemoPlatforms(items) {
  return items.map((attributes) => (attributes.CYLTabBarItemPlatforms
    ? Object.assign({}, attributes, { CYLTabBarItemPlatforms: `${attributes.CYLTabBarItemPlatforms},miniprogram` })
    : attributes));
}

/**
 * [EN] PAG tab icons (CYLTabBarPAGFilePath) as in the iOS PAG example (Example-PAG): one vector PAG file per tab.
 * [CN] 与 iOS PAG 示例（Example-PAG）相同的 PAG Tab 图标（CYLTabBarPAGFilePath）：每个 Tab 一个矢量 PAG 文件。
 */
const CYL_DEMO_PAG = { home: 'tab_home', message: 'tab_moments', discover: 'tab_health', me: 'tab_me' };

function cylDemoPAGItems(items, files) {
  return items.map((attributes) => {
    const name = CYL_DEMO_PAG[attributes.CYLTabBarItemIdentifier];
    const file = name && files.find((path) => path.endsWith(`/${name}.pag.bin`));
    return file ? Object.assign({}, attributes, {
      CYLTabBarPAGFilePath: file,
      CYLTabBarPAGSize: '{30, 30}',
    }) : attributes;
  });
}

/**
 * [EN] Rive tab icons (CYLTabBarRiveFilePath) as in the iOS Rive examples: one artboard of icons.riv per tab, its
 *      "<ARTBOARD>_Interactivity" state machine and the "active" input, 32 x 32.
 * [CN] 与 iOS Rive 示例相同的 Rive Tab 图标（CYLTabBarRiveFilePath）：每个 Tab 使用 icons.riv 的一个画板、其
 *      "<画板>_Interactivity" 状态机与 "active" 输入，32 x 32。
 */
const CYL_DEMO_RIVE = { home: 'CHAT', discover: 'SEARCH', message: 'BELL', me: 'USER' };

function cylDemoRiveItems(items, files) {
  return items.map((attributes) => {
    const artboard = CYL_DEMO_RIVE[attributes.CYLTabBarItemIdentifier];
    return artboard ? Object.assign({}, attributes, {
      CYLTabBarRiveFilePath: `${files[0]}#artboard=${artboard}&stateMachine=${artboard}_Interactivity&input=active`,
      CYLTabBarRiveSize: '{32, 32}',
    }) : attributes;
  });
}

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
 * [EN] GIF tab icons as in the iOS Example-GIF: Home and Message use animation keys (CYLTabBarGIFFilePath,
 *      CYLTabBarAnimationFilePath with a .gif), shown while selected; Discover passes the GIF as a plain image; Me keeps
 *      its static image.
 * [CN] 与 iOS Example-GIF 相同的 GIF Tab 图标：Home 与 Message 使用动画键（CYLTabBarGIFFilePath、文件为 .gif 的
 *      CYLTabBarAnimationFilePath），选中时显示；Discover 把 GIF 作为普通图片传入；Me 保留静态图片。
 */
function cylDemoGIFItems(items, files) {
  const file = (name) => files.find((candidate) => candidate.endsWith(`/${name}.gif`));
  const keys = {
    home: { CYLTabBarGIFFilePath: file('tab_rocket'), CYLTabBarGIFSize: '{30, 30}' },
    message: { CYLTabBarAnimationFilePath: file('tab_star'), CYLTabBarGIFSize: '{30, 30}' },
    discover: { CYLTabBarItemImage: file('tab_fire'), CYLTabBarItemSelectedImage: file('tab_fire') },
  };
  return items.map((attributes) => {
    const extra = keys[attributes.CYLTabBarItemIdentifier];
    return extra && Object.values(extra)[0] ? Object.assign({}, attributes, extra) : attributes;
  });
}

/**
 * [EN] The configuration with the example's overrides (style type, tap animation, login-required tabs), which the Me
 *      page changes at run time.
 * [CN] 带有示例覆盖项（样式、点击动画、需要登录的 Tab）的配置，Me 页面会在运行时修改这些覆盖项。
 */
function cylDemoConfiguration(overrides) {
  const options = overrides || {};
  const sharedItems = cylDemoPlatforms(cylSharedConfiguration.CYLTabBarControllerTabBarItemsAttributes);
  // [EN] "images" or the installed animation (the default). [CN] "images" 或已安装的动画（默认）。
  const icons = options.cylDemoIcons === 'images' || options.cylDemoLottie === false ? 'images' : cylInstalledAnimation();
  const files = icons === 'images' ? [] : cylAvailableAnimationFiles();
  const builders = {
    lottie: cylDemoLottieItems,
    pag: cylDemoPAGItems,
    rive: cylDemoRiveItems,
    gif: cylDemoGIFItems,
  };
  // [EN] Lottie icons are named by tab; the others need their files. [CN] Lottie 图标按 Tab 命名；其他需要文件。
  const items = icons !== 'images' && (icons === 'lottie' || files.length)
    ? builders[icons](sharedItems, files) : sharedItems;
  let styledItems = items;
  if (options.cylDemoBoldTitles) {
    styledItems = items.map((attributes) => Object.assign({}, attributes, { CYLTabBarItemSelectedTitleFont: 'bold:11' }));
  }
  const configurationOverrides = Object.assign({}, options);
  delete configurationOverrides.cylDemoLottie;
  delete configurationOverrides.cylDemoIcons;
  delete configurationOverrides.cylDemoBoldTitles;
  return Object.assign({}, cylSharedConfiguration, {
    CYLTabBarControllerTabBarItemsAttributes: styledItems,
    CYLTabBarControllerPlusButton: CYL_DEMO_PLUS_BUTTON,
    CYLTabBarControllerThemes: Object.assign({}, cylSharedConfiguration.CYLTabBarControllerThemes, {
      dark: Object.assign({}, cylSharedConfiguration.CYLTabBarControllerThemes.dark, CYL_DEMO_DARK_ICON_COLORS),
      christmas: CYL_DEMO_CHRISTMAS_THEME,
    }),
    CYLTabBarControllerTabButtonTapAnimation: 'bounce',
  }, configurationOverrides);
}

module.exports = { cylDemoConfiguration, cylInstalledAnimation, cylAvailableAnimationFiles };
