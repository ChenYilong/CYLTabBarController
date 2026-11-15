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
const { cylSkinnedConfiguration, cylSkinReplacesIcons } = require('./cyl_demo_skins');
const { t } = require('./cyl_demo_localization');
const { cylApplyUpdates } = require('./cyl_demo_updates');

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

/**
 * [EN] The Objective-C example's tabs (+[MainTabBarController tabBarItemsAttributesForTabBar], docs/ObjC-Example-Parity
 *      item 1): Home (selected title "Refresh"), Nearby, Messages and Me, with its images (Example/Images.xcassets,
 *      copied to shared/objc by scripts/cyl_sync_shared.js), drawn as templates in the title colors as on iOS. Me has no
 *      identifier in Objective-C, so the class name is used (#408). Nearby and Me open the example's existing pages.
 * [CN] Objective-C 示例的 Tab（+[MainTabBarController tabBarItemsAttributesForTabBar]，docs/ObjC-Example-Parity 第 1 项）：
 *      首页（选中标题「Refresh」）、同城、消息、我的，使用其图片（Example/Images.xcassets，由 scripts/cyl_sync_shared.js
 *      复制到 shared/objc），与 iOS 一样按模板以标题颜色绘制。Objective-C 中「我的」没有 identifier，因此使用类名（#408）。
 *      同城与我的打开示例已有的页面。
 */
const CYL_DEMO_OBJC_IMAGE = (name) => `/shared/objc/${name}.png`;
const CYL_DEMO_OBJC_ITEM = {
  CYLTabBarItemImageURLSize: '{22, 22}',
  CYLTabBarItemIconRenderingMode: 'template',
  CYLTabBarItemTitleFont: 10,
};
const CYL_DEMO_OBJC_ITEMS = [
  Object.assign({}, CYL_DEMO_OBJC_ITEM, {
    CYLTabBarItemTitle: 'Home',
    CYLTabBarItemSelectedTitle: 'Refresh',
    CYLTabBarItemIdentifier: 'home',
    CYLTabBarItemImage: CYL_DEMO_OBJC_IMAGE('home_normal'),
    CYLTabBarItemSelectedImage: CYL_DEMO_OBJC_IMAGE('home_highlight'),
  }),
  Object.assign({}, CYL_DEMO_OBJC_ITEM, {
    CYLTabBarItemTitle: 'Nearby',
    CYLTabBarItemIdentifier: 'city',
    CYLTabBarItemPageIdentifier: 'web',
    CYLTabBarItemImage: CYL_DEMO_OBJC_IMAGE('fishpond_normal'),
    CYLTabBarItemSelectedImage: CYL_DEMO_OBJC_IMAGE('fishpond_highlight'),
  }),
  Object.assign({}, CYL_DEMO_OBJC_ITEM, {
    CYLTabBarItemTitle: 'Messages',
    CYLTabBarItemIdentifier: 'message',
    CYLTabBarItemImage: CYL_DEMO_OBJC_IMAGE('message_normal'),
    CYLTabBarItemSelectedImage: CYL_DEMO_OBJC_IMAGE('message_highlight'),
  }),
  Object.assign({}, CYL_DEMO_OBJC_ITEM, {
    CYLTabBarItemTitle: 'Me',
    CYLTabBarItemIdentifier: 'CYLMineViewController',
    CYLTabBarItemPageIdentifier: 'me',
    CYLTabBarItemImage: CYL_DEMO_OBJC_IMAGE('account_normal'),
    CYLTabBarItemSelectedImage: CYL_DEMO_OBJC_IMAGE('account_highlight'),
  }),
];

/**
 * [EN] The Objective-C example's plus button (CYLPlusButtonSubclass, items 3 and 4): "Post" with its images at index 2,
 *      55 x 80 with a 55 x 55 image, its center 14 pt above the bar's middle (+constantOfPlusButtonCenterYOffsetForTabBarHeight:
 *      returns -14), the title on the tab titles' line, a 9.5 pt title that is green when selected, and its own page.
 * [CN] Objective-C 示例的 PlusButton（CYLPlusButtonSubclass，第 3、4 项）：位于第 2 位、带图片的「Post」，55 x 80，图片
 *      55 x 55，中心在 TabBar 中线上方 14 pt（+constantOfPlusButtonCenterYOffsetForTabBarHeight: 返回 -14），标题与 Tab 标题
 *      同一行，标题 9.5 pt、选中时为绿色，并有自己的页面。
 */
const CYL_DEMO_PLUS_BUTTON = {
  CYLTabBarItemTitle: 'Post',
  CYLTabBarItemImage: CYL_DEMO_OBJC_IMAGE('post_normal'),
  CYLTabBarItemSelectedImage: CYL_DEMO_OBJC_IMAGE('post_highlight'),
  CYLTabBarItemIdentifier: 'plus',
  CYLTabBarItemPageIdentifier: 'publish',
  CYLTabBarItemSelectedTitleColor: '#34C759',
  CYLTabBarItemTitleFont: 9.5,
  CYLPlusButtonIndexInTabBar: 2,
  CYLPlusButtonSize: '{55, 80}',
  CYLPlusButtonImageSize: '{55, 55}',
  CYLPlusButtonCenterYMultiplier: 0.5,
  CYLPlusButtonCenterYOffset: -14,
  CYLPlusButtonAlignsTitle: true,
  CYLPlusButtonKeepsTitleVisible: true,
  CYLPlusButtonShowsSelection: true,
};

/**
 * [EN] The Objective-C example's tab bar appearance (+demoStandardAppearanceWithTitlePositionAdjustment:): titles and
 *      icons red, green when selected, in light and dark mode.
 * [CN] Objective-C 示例的 TabBar 外观（+demoStandardAppearanceWithTitlePositionAdjustment:）：标题与图标为红色，选中时为
 *      绿色，浅色与深色模式相同。
 */
const CYL_DEMO_OBJC_COLORS = {
  CYLTabBarItemTitleColor: '#FF0000',
  CYLTabBarItemIconColor: '#FF0000',
  CYLTabBarItemSelectedTitleColor: '#34C759',
  CYLTabBarItemSelectedIconColor: '#34C759',
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
  city: 'green_lottie_tab_discover',
  message: 'green_lottie_tab_news',
  CYLMineViewController: 'green_lottie_tab_mine',
};

/**
 * [EN] As the Objective-C example (CYLTabBarAnimationColors of the Nearby tab): its Lottie icon's gray outline.
 * [CN] 与 Objective-C 示例相同（同城 Tab 的 CYLTabBarAnimationColors）：其 Lottie 图标的灰色轮廓。
 */
const CYL_DEMO_LOTTIE_COLORS = { city: { 'Icon_Discovery_Normal.**.Color': '#7F7F7F' } };

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
const CYL_DEMO_PAG = { home: 'tab_home', message: 'tab_moments', city: 'tab_health', CYLMineViewController: 'tab_me' };

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
const CYL_DEMO_RIVE = { home: 'CHAT', city: 'SEARCH', message: 'BELL', CYLMineViewController: 'USER' };

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
    const colors = CYL_DEMO_LOTTIE_COLORS[attributes.CYLTabBarItemIdentifier];
    return name ? Object.assign({}, attributes, {
      CYLTabBarLottieURL: `${name}.json`,
      CYLTabBarLottieDarkURL: `${name}_dark.json`,
      CYLTabBarLottieSize: '{30, 30}',
    }, colors ? { CYLTabBarAnimationColors: colors } : {}) : attributes;
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
    city: { CYLTabBarItemImage: file('tab_fire'), CYLTabBarItemSelectedImage: file('tab_fire') },
  };
  return items.map((attributes) => {
    const extra = keys[attributes.CYLTabBarItemIdentifier];
    return extra && Object.values(extra)[0] ? Object.assign({}, attributes, extra) : attributes;
  });
}

/**
 * [EN] The Home row "Replace neighboring tabs" (issue #481, replaceViewControllerAtIndex:withViewController:attributes:):
 *      a replaced tab is "Replaced page A" (left, a.circle) or "Replaced page B" (right, b.circle) and shows its plain
 *      page (pages/web for Nearby, see cylReplacedPage). `replaced`: {identifier: "A" | "B"}.
 * [CN] 首页「替换相邻 Tab 的页面」行（issue #481）：被替换的 Tab 为「替换页 A」（左侧，a.circle）或「替换页 B」（右侧，
 *      b.circle），并显示其空白页面（同城为 pages/web，见 cylReplacedPage）。`replaced`：{标识: "A" | "B"}。
 */
function cylLetterIcon(letter, filled) {
  const circle = filled ? '<circle cx="12" cy="12" r="11" fill="#000"/>' : '<circle cx="12" cy="12" r="10" fill="none" stroke="#000" stroke-width="1.8"/>';
  const text = `<text x="12" y="16.5" font-family="-apple-system, Helvetica, Arial" font-size="13" font-weight="600" text-anchor="middle" fill="${filled ? '#fff' : '#000'}">${letter.toLowerCase()}</text>`;
  return `data:image/svg+xml;utf8,${encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">${circle}${text}</svg>`)}`;
}

function cylReplacedItems(items, replaced) {
  if (!replaced) {
    return items;
  }
  return items.map((attributes) => {
    const letter = replaced[attributes.CYLTabBarItemIdentifier];
    if (!letter) {
      return attributes;
    }
    const title = t('Replaced page %@').replace('%@', letter);
    const changed = Object.assign({}, attributes, {
      CYLTabBarItemTitle: title,
      CYLTabBarItemSelectedTitle: title,
      CYLTabBarItemImage: cylLetterIcon(letter, false),
      CYLTabBarItemSelectedImage: cylLetterIcon(letter, true),
      CYLTabBarItemImageURLSize: '{22, 22}',
      CYLTabBarItemIconRenderingMode: 'template',
    });
    ['CYLTabBarLottieURL', 'CYLTabBarLottieDarkURL', 'CYLTabBarLottieSize', 'CYLTabBarAnimationColors', 'CYLTabBarPAGFilePath',
      'CYLTabBarRiveFilePath', 'CYLTabBarGIFFilePath', 'CYLTabBarAnimationFilePath'].forEach((key) => delete changed[key]);
    return changed;
  });
}

/**
 * [EN] The plain page of a replaced tab: its title and background color (systemTeal for A, systemPink for B), or null.
 * [CN] 被替换 Tab 的空白页面：标题与背景色（A 为 systemTeal，B 为 systemPink），否则为 null。
 */
function cylReplacedPage(overrides, identifier) {
  const letter = ((overrides || {}).cylDemoReplaced || {})[identifier];
  return letter ? { title: t('Replaced page %@').replace('%@', letter), color: letter === 'A' ? '#30B0C7' : '#FF2D55' } : null;
}

/**
 * [EN] The configuration with the example's overrides (style type, tap animation, login-required tabs), which the Me
 *      page changes at run time, in `skin` (utils/cyl_demo_skins.js; none: the example's own colors and icons).
 * [CN] 带有示例覆盖项（样式、点击动画、需要登录的 Tab）的配置，Me 页面会在运行时修改这些覆盖项；使用 `skin`
 *      （utils/cyl_demo_skins.js；未提供时为示例自己的颜色与图标）。
 */
function cylDemoConfiguration(overrides, skin) {
  const options = overrides || {};
  const sharedItems = CYL_DEMO_OBJC_ITEMS;
  // [EN] "images" or the installed animation (the default); a skin's icons replace the animations. [CN] "images" 或已安装的动画（默认）；皮肤图标替换动画。
  const icons = options.cylDemoIcons === 'images' || options.cylDemoLottie === false || cylSkinReplacesIcons(skin)
    ? 'images' : cylInstalledAnimation();
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
  // [EN] Per-tab attributes the Home rows change at run time (titles, icons, offsets, colors), by identifier.
  // [CN] 首页各行在运行时修改的单个 Tab 属性（标题、图标、偏移、颜色），按标识符。
  const itemAttributes = options.cylDemoItemAttributes || {};
  const changedItems = cylReplacedItems(styledItems.map((attributes) => Object.assign({}, attributes,
    itemAttributes['*'], itemAttributes[attributes.CYLTabBarItemIdentifier])), options.cylDemoReplaced);
  const configurationOverrides = Object.assign({}, options);
  delete configurationOverrides.cylDemoLottie;
  delete configurationOverrides.cylDemoIcons;
  delete configurationOverrides.cylDemoBoldTitles;
  delete configurationOverrides.cylDemoItemAttributes;
  delete configurationOverrides.cylDemoPlusAttributes;
  delete configurationOverrides.cylDemoTouchableArea;
  delete configurationOverrides.cylDemoReplaced;
  delete configurationOverrides.cylDemoUpdates;
  delete configurationOverrides.cylDemoAppearance;
  // [EN] The Home rows that change the tabs in place, last: they act on what is shown (utils/cyl_demo_updates.js).
  // [CN] 原地修改 Tab 的首页各行最后应用：它们作用于当前显示的内容（utils/cyl_demo_updates.js）。
  return cylApplyUpdates(cylSkinnedConfiguration(Object.assign({}, cylSharedConfiguration, {
    CYLTabBarControllerTabBarItemsAttributes: changedItems,
    // [EN] The Home row "PlusButton touchable area" (issue #91): showsTouchableArea and touchableAreaScale.
    // [CN] 首页「PlusButton 点击范围」行（issue #91）：showsTouchableArea 与 touchableAreaScale。
    CYLTabBarControllerPlusButton: Object.assign({}, CYL_DEMO_PLUS_BUTTON, options.cylDemoPlusAttributes, options.cylDemoTouchableArea ? {
      CYLPlusButtonShowsTouchableArea: Boolean(options.cylDemoTouchableArea.shows),
      CYLPlusButtonTouchableAreaScale: options.cylDemoTouchableArea.scale || 1,
    } : {}),
    // [EN] The Objective-C example starts on Liquid Glass (CYLMainRootViewController). [CN] Objective-C 示例以液态玻璃启动。
    CYLTabBarControllerStyleType: 'liquidGlass',
    // [EN] The Objective-C example's title offset (0, -3.5), which the aligned plus button follows. [CN] Objective-C 示例的标题偏移。
    CYLTabBarControllerTitlePositionAdjustment: '{0, -3.5}',
    CYLTabBarControllerThemes: Object.assign({}, cylSharedConfiguration.CYLTabBarControllerThemes, {
      light: Object.assign({}, cylSharedConfiguration.CYLTabBarControllerThemes.light, CYL_DEMO_OBJC_COLORS),
      dark: Object.assign({}, cylSharedConfiguration.CYLTabBarControllerThemes.dark, CYL_DEMO_DARK_ICON_COLORS,
        CYL_DEMO_OBJC_COLORS),
      christmas: CYL_DEMO_CHRISTMAS_THEME,
    }),
    // [EN] -[MainTabBarController tabBarController:didSelectControl:] scales the tapped icon. [CN] 点击的图标播放缩放动画。
    CYLTabBarControllerTabButtonTapAnimation: 'scale',
    // [EN] -[MainTabBarController setUpLoginRequiredTabs] (issue #19). [CN] 需要登录的 Tab（issue #19）。
    CYLTabBarControllerLoginRequiredTabBarItemIdentifiers: ['message', 'CYLMineViewController'],
  }, configurationOverrides), skin, t), options.cylDemoUpdates, options.cylDemoAppearance, t);
}

module.exports = { cylDemoConfiguration, cylInstalledAnimation, cylAvailableAnimationFiles, cylReplacedPage };
