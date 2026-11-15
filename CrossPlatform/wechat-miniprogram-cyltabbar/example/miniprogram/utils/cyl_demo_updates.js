/**
 * [EN] The Home rows that change the tabs in place (UIViewController+CYLTabBarItemUpdate.swift, docs/ObjC-Example-Parity
 *      items 21–26) and the standardAppearance row (CYLSettingsDemoRows.swift, item 14). Each row is a flag in the
 *      overrides (`cylDemoUpdates`, `cylDemoAppearance`); the configuration is built from the flags, so a second tap
 *      restores the initial values, and a new tab bar (Flat Design / Liquid Glass) starts without them, as on iOS.
 * [CN] 原地修改 Tab 的首页各行（UIViewController+CYLTabBarItemUpdate.swift，docs/ObjC-Example-Parity 第 21–26 项）与
 *      standardAppearance 行（CYLSettingsDemoRows.swift，第 14 项）。每行是覆盖项中的一个标记（`cylDemoUpdates`、
 *      `cylDemoAppearance`）；配置由这些标记生成，因此再点一次恢复初始值，新的 TabBar（Flat Design / Liquid Glass）也不带
 *      这些修改，与 iOS 相同。
 */
const CYL_FLATICON = (name) => `https://cdn-icons-png.flaticon.com/512/${name}.png`;
const CYL_ICON_SIZE = '{24, 24}';

/**
 * [EN] A small SVG as a data URL (the SF Symbols the iOS rows draw: heart, heart.fill, plus.circle, plus.circle.fill).
 * [CN] 以 data URL 表示的小 SVG（iOS 各行绘制的 SF Symbols：heart、heart.fill、plus.circle、plus.circle.fill）。
 */
function cylSVG(body) {
  return `data:image/svg+xml;utf8,${encodeURIComponent(`<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">${body}</svg>`)}`;
}
const CYL_HEART_PATH = 'M12 20.5s-7.5-4.6-9.2-9.1C1.6 8.2 3.6 4.5 7.2 4.5c2 0 3.6 1.1 4.8 2.8 1.2-1.7 2.8-2.8 4.8-2.8 3.6 0 5.6 3.7 4.4 6.9-1.7 4.5-9.2 9.1-9.2 9.1z';
const CYL_SYMBOLS = {
  heart: cylSVG(`<path d="${CYL_HEART_PATH}" fill="none" stroke="#8E8E93" stroke-width="1.8" stroke-linejoin="round"/>`),
  heartFill: cylSVG(`<path d="${CYL_HEART_PATH}" fill="#FF3B30"/>`),
  plusCircle: cylSVG('<circle cx="12" cy="12" r="10" fill="none" stroke="#FF9500" stroke-width="1.8"/><path d="M12 7v10M7 12h10" stroke="#FF9500" stroke-width="1.8" stroke-linecap="round"/>'),
  plusCircleFill: cylSVG('<circle cx="12" cy="12" r="11" fill="#FF9500"/><path d="M12 7v10M7 12h10" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>'),
};

// [EN] Item 22: this page's tab icon from the network. [CN] 第 22 项：当前页 Tab 的网络图标。
const CYL_HOME_NETWORK_ICON = [CYL_FLATICON('3132/3132732'), CYL_FLATICON('3132/3132779')];
// [EN] Item 25: the library's animated GIF. [CN] 第 25 项：库的 GIF 动图。
const CYL_GIF = '/shared/objc/cyl_tab_sample_animated.gif';
// [EN] Item 23: one pair per real tab, then the plus button's. [CN] 第 23 项：每个真实 Tab 一对图标，然后是 PlusButton 的。
const CYL_ALL_NETWORK_ICONS = [['1946/1946488', '1946/1946436'], ['2099/2099085', '2099/2099085'], ['2099/2099100', '2099/2099100'], ['1077/1077063', '1077/1077114']]
  .map((pair) => pair.map(CYL_FLATICON));
const CYL_PLUS_NETWORK_ICONS = [CYL_FLATICON('992/992651'), CYL_FLATICON('1828/1828817')];
// [EN] Item 24: an image name, a file path, a UIImage and a GIF file URL on iOS; local images here. [CN] 第 24 项：iOS 上依次为图片名、文件路径、UIImage 与 GIF 文件 URL；这里为本地图片。
const CYL_ALL_LOCAL_ICONS = [
  ['/shared/objc/img_tab_home_0.png', '/shared/objc/img_tab_home_1.png'],
  ['/shared/objc/img_tab_message_0.png', '/shared/objc/img_tab_message_1.png'],
  [CYL_SYMBOLS.heart, CYL_SYMBOLS.heartFill],
  [CYL_GIF, CYL_GIF],
];

// [EN] The animation keys an icon row replaces. [CN] 图标行替换掉的动画键。
const CYL_ANIMATION_KEYS = ['CYLTabBarLottieURL', 'CYLTabBarLottieDarkURL', 'CYLTabBarLottieSize', 'CYLTabBarAnimationColors',
  'CYLTabBarPAGFilePath', 'CYLTabBarPAGSize', 'CYLTabBarRiveFilePath', 'CYLTabBarRiveSize', 'CYLTabBarGIFFilePath',
  'CYLTabBarAnimationFilePath', 'CYLTabBarGIFSize'];

function cylIcon(attributes, image, selectedImage) {
  const changed = Object.assign({}, attributes, {
    CYLTabBarItemImage: image,
    CYLTabBarItemSelectedImage: selectedImage,
    CYLTabBarItemImageURLSize: CYL_ICON_SIZE,
    CYLTabBarItemIconRenderingMode: 'original',
  });
  CYL_ANIMATION_KEYS.forEach((key) => delete changed[key]);
  return changed;
}

/**
 * [EN] The standardAppearance themes in the row's order (Original, Dark, Centered capsule, Green line), as skins of
 *      CYLTabBarControllerThemes. The centered capsule's selection indicator is the selected item's background.
 * [CN] standardAppearance 主题，按本行顺序（原始、深色、居中胶囊、绿色描边），作为 CYLTabBarControllerThemes 中的皮肤。
 *      居中胶囊的选中指示器用选中 Item 的背景色表示。
 */
const CYL_APPEARANCES = ['Original', 'Dark', 'Centered capsule', 'Green line'];
const CYL_APPEARANCE_THEMES = {
  Dark: {
    CYLTabBarBackgroundColor: '#141414',
    CYLTabBarShadowColor: '#00000000',
    CYLTabBarItemTitleColor: '#AAAAAA',
    CYLTabBarItemIconColor: '#AAAAAA',
    CYLTabBarItemSelectedTitleColor: '#FFFFFF',
    CYLTabBarItemSelectedIconColor: '#FFFFFF',
    CYLTabBarItemBadgeBackgroundColor: '#FF9500',
  },
  'Centered capsule': {
    CYLTabBarItemTitleColor: '#8E8E93',
    CYLTabBarItemIconColor: '#8E8E93',
    CYLTabBarItemSelectedTitleColor: '#FF2D55',
    CYLTabBarItemSelectedIconColor: '#FF2D55',
    CYLTabBarItemSelectedBackgroundColor: '#FF2D5533',
    CYLTabBarItemBadgeBackgroundColor: '#AF52DE',
  },
  'Green line': {
    CYLTabBarBackgroundColor: '#FFFFFF',
    CYLTabBarShadowColor: '#34C759',
    CYLTabBarItemTitleColor: '#3C3C4399',
    CYLTabBarItemIconColor: '#3C3C4399',
    CYLTabBarItemSelectedTitleColor: '#34C759',
    CYLTabBarItemSelectedIconColor: '#34C759',
    CYLTabBarItemBadgePositionAdjustment: '{2, -2}',
  },
};

/**
 * [EN] The configuration with the update rows that are on (`updates`: {changeTabTitle, homeIcon: "network" | "gif" |
 *      "custom", allIcons: "network" | "local", allTitles}) and the standardAppearance theme. "This page's tab" is Home,
 *      where the rows are. `translate` gives a title in the example's language.
 * [CN] 带有已开启的更新行（`updates`：{changeTabTitle、homeIcon: "network" | "gif" | "custom"、allIcons: "network" |
 *      "local"、allTitles}）与 standardAppearance 主题的配置。「当前页 Tab」为各行所在的首页。`translate` 给出示例语言中的标题。
 */
function cylApplyUpdates(configuration, updates, appearance, translate) {
  const flags = updates || {};
  let items = configuration.CYLTabBarControllerTabBarItemsAttributes || [];
  let plusButton = configuration.CYLTabBarControllerPlusButton;
  if (flags.allIcons) {
    const icons = flags.allIcons === 'local' ? CYL_ALL_LOCAL_ICONS : CYL_ALL_NETWORK_ICONS;
    items = items.map((attributes, index) => cylIcon(attributes, icons[index % icons.length][0], icons[index % icons.length][1]));
    if (plusButton) {
      const plusIcons = flags.allIcons === 'local' ? [CYL_SYMBOLS.plusCircle, CYL_SYMBOLS.plusCircleFill] : CYL_PLUS_NETWORK_ICONS;
      plusButton = Object.assign({}, plusButton, { CYLTabBarItemImage: plusIcons[0], CYLTabBarItemSelectedImage: plusIcons[1] });
    }
  }
  items = items.map((attributes, index) => {
    if (index !== 0) {
      return attributes;
    }
    let changed = attributes;
    if (flags.homeIcon === 'network') {
      changed = cylIcon(changed, CYL_HOME_NETWORK_ICON[0], CYL_HOME_NETWORK_ICON[1]);
    } else if (flags.homeIcon === 'gif') {
      changed = cylIcon(changed, CYL_GIF, CYL_GIF);
    } else if (flags.homeIcon === 'custom') {
      // [EN] "Switch tab icon": a custom view on iOS; a full color image here. [CN] 「切换 Tab 图标」：iOS 上为自定义视图；这里为全彩图片。
      changed = cylIcon(changed, '/shared/theme/christmas/bell.png', '/shared/theme/christmas/bell.png');
    }
    if (flags.changeTabTitle) {
      const title = translate('Purchased courses');
      changed = Object.assign({}, changed, { CYLTabBarItemTitle: title, CYLTabBarItemSelectedTitle: title });
    }
    return changed;
  });
  if (flags.allTitles) {
    items = items.map((attributes) => Object.assign({}, attributes, { CYLTabBarItemTitle: `★ ${translate(attributes.CYLTabBarItemTitle)}` }));
    if (plusButton) {
      plusButton = Object.assign({}, plusButton, { CYLTabBarItemTitle: `★ ${translate(plusButton.CYLTabBarItemTitle)}` });
    }
  }
  const changed = Object.assign({}, configuration, {
    CYLTabBarControllerTabBarItemsAttributes: items,
    CYLTabBarControllerPlusButton: plusButton,
  });
  const theme = CYL_APPEARANCE_THEMES[appearance];
  if (theme) {
    const identifier = `appearance:${appearance}`;
    Object.assign(changed, {
      CYLTabBarControllerThemes: Object.assign({}, configuration.CYLTabBarControllerThemes, { [identifier]: theme }),
      CYLTabBarControllerThemeIdentifier: identifier,
      CYLTabBarControllerDarkThemeIdentifier: identifier,
    });
  }
  return changed;
}

module.exports = { cylApplyUpdates, CYL_APPEARANCES };
