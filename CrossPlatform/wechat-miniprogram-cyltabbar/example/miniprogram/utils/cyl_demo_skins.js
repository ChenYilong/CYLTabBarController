/**
 * [EN] The skins of the Objective-C example's skin picker (CYLDemoThemes.all in UIViewController+CYLThemeSettings.swift),
 *      in its order (docs/ObjC-Example-Parity items 9, 15 and 32): five color skins, eleven holiday skins and the network
 *      skin. Each gives the bar's colors; a holiday skin puts its icons in turn on the tabs (selected: full color;
 *      unselected: 45% opacity, made by scripts/cyl_sync_shared.js) and its last icon on the plus button; the network
 *      skin downloads the tab and plus button icons and puts "★ " before every title.
 * [CN] Objective-C 示例换肤菜单中的皮肤（UIViewController+CYLThemeSettings.swift 的 CYLDemoThemes.all），顺序相同
 *      （docs/ObjC-Example-Parity 第 9、15、32 项）：五个配色皮肤、十一个节日皮肤与网络皮肤。每个皮肤给出 TabBar 的颜色；
 *      节日皮肤依次把图标放到各 Tab 上（选中：全彩；未选中：45% 不透明度，由 scripts/cyl_sync_shared.js 生成），最后一个
 *      图标用于 PlusButton；网络皮肤从网络下载 Tab 与 PlusButton 图标，并在每个标题前加「★ 」。
 */
const CYL_NETWORK_ICON = (name) => `https://cdn-icons-png.flaticon.com/512/${name}.png`;

const CYL_DEMO_SKINS = [
  { name: 'Default' },
  { name: 'Grapefruit', tint: '#EF5362' },
  { name: 'Grass', tint: '#6EB43C' },
  { name: 'Pink Rose', tint: '#EE85C1' },
  { name: 'Dark', tint: '#27C0F3', bar: '#121214', normal: '#8E8E93' },
  { name: 'Spring Festival', tint: '#FFD54F', bar: '#C41E3A', normal: '#FFCDD2', icons: ['red_envelope', 'firecracker', 'red_paper_lantern', 'dragon', 'fireworks'] },
  { name: 'Christmas', tint: '#FFD666', bar: '#166534', normal: '#C8E6C9', icons: ['christmas_tree', 'wrapped_gift', 'snowman', 'bell', 'star'] },
  { name: 'Halloween', tint: '#FF9100', bar: '#26143A', normal: '#B39DDB', icons: ['jack_o_lantern', 'ghost', 'bat', 'spider', 'candy'] },
  { name: "Valentine's Day", tint: '#E91E63', bar: '#FFEBF0', normal: '#AD788C', icons: ['heart_with_ribbon', 'rose', 'love_letter', 'chocolate_bar', 'ring'] },
  { name: 'Mid-Autumn', tint: '#FFC107', bar: '#1A234C', normal: '#9FA8DA', icons: ['moon_cake', 'full_moon', 'rabbit', 'teacup_without_handle', 'crescent_moon'] },
  { name: 'Easter', tint: '#7CB342', bar: '#FFFAE1', normal: '#A1887F', icons: ['hatching_chick', 'egg', 'rabbit_face', 'tulip', 'basket'] },
  { name: 'New Year', tint: '#FFD740', bar: '#141428', normal: '#90A4AE', icons: ['party_popper', 'confetti_ball', 'clinking_glasses', 'sparkler', 'alarm_clock'] },
  { name: 'Summer', tint: '#0097A7', bar: '#FFF8E1', normal: '#8D6E63', icons: ['beach_with_umbrella', 'watermelon', 'palm_tree', 'tropical_drink', 'sun'] },
  { name: 'Birthday', tint: '#EC407A', bar: '#FFF3E0', normal: '#9575CD', icons: ['birthday_cake', 'balloon', 'candle', 'teddy_bear', 'wrapped_gift'] },
  { name: 'Space', tint: '#80DEEA', bar: '#0D1126', normal: '#7986CB', icons: ['rocket', 'ringed_planet', 'flying_saucer', 'glowing_star', 'comet'] },
  { name: 'Ocean', tint: '#FFFFFF', bar: '#01579B', normal: '#81D4FA', icons: ['spouting_whale', 'tropical_fish', 'spiral_shell', 'crab', 'water_wave'] },
  {
    name: 'Network icons',
    tint: '#007AFF',
    bar: '#F2F7FF',
    normal: '#78869C',
    network: {
      tabs: [['1946/1946488', '1946/1946436'], ['2099/2099085', '2099/2099085'], ['2099/2099100', '2099/2099100'], ['1077/1077063', '1077/1077114']],
      plusButton: ['992/992651', '1828/1828817'],
      titlePrefix: '★',
    },
  },
];

/**
 * [EN] The folder of a holiday skin's icons: the name in lowercase, without "'", "-" for spaces (CYLDemoTheme.icon(named:)).
 * [CN] 节日皮肤图标所在文件夹：小写名字，去掉 "'"，空格换成 "-"（CYLDemoTheme.icon(named:)）。
 */
function cylSkinIcon(skin, name, faded) {
  const folder = skin.name.toLowerCase().replace(/'/g, '').replace(/ /g, '-');
  return `/shared/theme/${folder}/${name}${faded ? '_faded' : ''}.png`;
}

function cylSkinNamed(name) {
  return CYL_DEMO_SKINS.find((skin) => skin.name === name) || CYL_DEMO_SKINS[0];
}

/**
 * [EN] The skin in use (CYLDemoThemes.setFollowsSystem): following the system, Dark in Dark Mode; in light mode back to
 *      Default from Dark, otherwise the skin chosen.
 * [CN] 当前使用的皮肤（CYLDemoThemes.setFollowsSystem）：跟随系统时深色模式为 Dark；浅色模式从 Dark 回到 Default，否则为所选皮肤。
 */
function cylEffectiveSkin(state) {
  const chosen = (state && state.skin) || 'Default';
  if (!state || !state.skinFollowsSystem) {
    return cylSkinNamed(chosen);
  }
  if (state.systemTheme === 'dark') {
    return cylSkinNamed('Dark');
  }
  return cylSkinNamed(chosen === 'Dark' ? 'Default' : chosen);
}

/**
 * [EN] The list row of a skin (cyl_themeListCell): its name, what it changes, its first icon or a swatch of its tint.
 * [CN] 皮肤的列表行（cyl_themeListCell）：名字、修改的内容、第一个图标或 tint 色块。
 */
function cylSkinSummary(skin) {
  if (skin.network) {
    return 'Network icons, titles and colors';
  }
  return skin.icons ? 'Holiday icons and colors' : 'Colors only';
}

function cylSkinPreview(skin) {
  return {
    icon: skin.icons ? cylSkinIcon(skin, skin.icons[0], false) : '',
    swatch: skin.icons ? '' : (skin.tint || '#C7C7CC'),
    glyph: skin.network ? '↓' : '',
  };
}

/**
 * [EN] The configuration in `skin`: its bar colors as a skin of CYLTabBarControllerThemes that is in use in light and
 *      dark mode (cyl_tabBarAppearanceForTabBarController:), its tab icons and titles (cyl_tabBarItemsAttributesFor...),
 *      and its plus button images (cyl_plusButtonAttributesFor...). `translate` gives a title in the example's language.
 * [CN] `skin` 下的配置：TabBar 颜色作为 CYLTabBarControllerThemes 中的一个皮肤，在浅色与深色模式下都使用
 *      （cyl_tabBarAppearanceForTabBarController:）；Tab 图标与标题（cyl_tabBarItemsAttributesFor...）；PlusButton 图片
 *      （cyl_plusButtonAttributesFor...）。`translate` 给出示例语言中的标题。
 */
function cylSkinnedConfiguration(configuration, skin, translate) {
  if (!skin || !skin.tint) {
    return configuration;
  }
  const identifier = `skin:${skin.name}`;
  const normal = skin.normal || '#8E8E93';
  const theme = Object.assign(skin.bar ? { CYLTabBarBackgroundColor: skin.bar } : {}, {
    CYLTabBarItemTitleColor: normal,
    CYLTabBarItemSelectedTitleColor: skin.tint,
    CYLTabBarItemIconColor: normal,
    CYLTabBarItemSelectedIconColor: skin.tint,
  });
  const items = (configuration.CYLTabBarControllerTabBarItemsAttributes || []).map((attributes, index) => {
    if (skin.icons) {
      const name = skin.icons[index % skin.icons.length];
      return Object.assign({}, attributes, {
        CYLTabBarItemImage: cylSkinIcon(skin, name, true),
        CYLTabBarItemSelectedImage: cylSkinIcon(skin, name, false),
        // [EN] Full color icons are drawn as they are (UIImageRenderingModeAlwaysOriginal), 75 px @3x. [CN] 全彩图标按原图绘制，@3x 75 像素。
        CYLTabBarItemIconRenderingMode: 'original',
        CYLTabBarItemImageURLSize: '{25, 25}',
      });
    }
    if (skin.network) {
      const [image, selectedImage] = skin.network.tabs[index % skin.network.tabs.length];
      return Object.assign({}, attributes, {
        CYLTabBarItemTitle: `${skin.network.titlePrefix} ${translate(attributes.CYLTabBarItemTitle)}`,
        CYLTabBarItemImage: CYL_NETWORK_ICON(image),
        CYLTabBarItemSelectedImage: CYL_NETWORK_ICON(selectedImage),
        CYLTabBarItemIconRenderingMode: 'original',
        CYLTabBarItemImageURLSize: '{24, 24}',
      });
    }
    return attributes;
  });
  let plusButton = configuration.CYLTabBarControllerPlusButton;
  if (plusButton && skin.icons) {
    const icon = cylSkinIcon(skin, skin.icons[skin.icons.length - 1], false);
    plusButton = Object.assign({}, plusButton, { CYLTabBarItemImage: icon, CYLTabBarItemSelectedImage: icon });
  } else if (plusButton && skin.network) {
    plusButton = Object.assign({}, plusButton, {
      CYLTabBarItemImage: CYL_NETWORK_ICON(skin.network.plusButton[0]),
      CYLTabBarItemSelectedImage: CYL_NETWORK_ICON(skin.network.plusButton[1]),
    });
  }
  return Object.assign({}, configuration, {
    CYLTabBarControllerTabBarItemsAttributes: items,
    CYLTabBarControllerPlusButton: plusButton,
    CYLTabBarControllerThemes: Object.assign({}, configuration.CYLTabBarControllerThemes, { [identifier]: theme }),
    CYLTabBarControllerThemeIdentifier: identifier,
    CYLTabBarControllerDarkThemeIdentifier: identifier,
  });
}

/**
 * [EN] Whether a skin replaces the tab icons (the animation icons then give way to its images).
 * [CN] 皮肤是否替换 Tab 图标（此时动画图标让位于其图片）。
 */
function cylSkinReplacesIcons(skin) {
  return Boolean(skin && (skin.icons || skin.network));
}

module.exports = {
  CYL_DEMO_SKINS,
  cylEffectiveSkin,
  cylSkinNamed,
  cylSkinSummary,
  cylSkinPreview,
  cylSkinnedConfiguration,
  cylSkinReplacesIcons,
};
