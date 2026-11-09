// The skins of the Objective-C example's skin picker (UIViewController+CYLThemeSettings.m, `CYLDemoThemes()`), in its
// order: colors only, holiday icons and colors, network icons, titles and colors. Each skin gives the bar's colors, and the
// tab and plus button images that replace the Lottie icons.
// Objective-C 示例换肤菜单中的皮肤（UIViewController+CYLThemeSettings.m 的 `CYLDemoThemes()`），顺序相同：仅配色、节日图标与配色、
// 网络图标、标题与配色。每个皮肤给出 TabBar 的颜色，以及替换 Lottie 图标的 Tab 与 PlusButton 图片。

/// Network icons [normal, selected] per tab, the plus button's, and the title prefix. 每个 Tab 与 PlusButton 的网络图标及标题前缀。
class CYLSkinNetwork {
  const CYLSkinNetwork({
    required this.tabs,
    required this.plusButton,
    required this.titlePrefix,
  });
  final List<List<String>> tabs;
  final List<String> plusButton;
  final String titlePrefix;
}

class CYLSkin {
  const CYLSkin(
    this.name, {
    this.tint,
    this.bar,
    this.normal,
    this.icons,
    this.network,
  });
  final String name;

  /// The selected color, also the badges' (null: the app's own appearance). 选中颜色，也是角标颜色（null：App 自己的外观）。
  final String? tint;
  final String? bar;

  /// Unselected titles and icons (default systemGray). 未选中的标题与图标（默认 systemGray）。
  final String? normal;

  /// Holiday icons, in turn on every tab; the last one on the plus button. 节日图标，依次用于各 Tab；最后一个用于 PlusButton。
  final List<String>? icons;
  final CYLSkinNetwork? network;
}

/// A holiday icon in full color (selected) and at 45% opacity (unselected, `CYLDemoFadedImage`).
/// 全彩（选中）与 45% 不透明度（未选中）的节日图标。
String themeIcon(String name, {bool faded = false}) =>
    'assets/theme/$name${faded ? '_faded' : ''}.png';

const skins = <CYLSkin>[
  CYLSkin('Default'),
  CYLSkin('Grapefruit', tint: '#EF5362'),
  CYLSkin('Grass', tint: '#6EB43C'),
  CYLSkin('Pink Rose', tint: '#EE85C1'),
  CYLSkin('Dark', tint: '#27C0F3', bar: '#121214', normal: '#8E8E93'),
  CYLSkin(
    'Spring Festival',
    tint: '#FFD54F',
    bar: '#C41E3A',
    normal: '#FFCDD2',
    icons: [
      'red_envelope',
      'firecracker',
      'red_paper_lantern',
      'dragon',
      'fireworks',
    ],
  ),
  CYLSkin(
    'Christmas',
    tint: '#FFD666',
    bar: '#166534',
    normal: '#C8E6C9',
    icons: ['christmas_tree', 'wrapped_gift', 'snowman', 'bell', 'star'],
  ),
  CYLSkin(
    'Halloween',
    tint: '#FF9100',
    bar: '#26143A',
    normal: '#B39DDB',
    icons: ['jack_o_lantern', 'ghost', 'bat', 'spider', 'candy'],
  ),
  CYLSkin(
    'Valentine\'s Day',
    tint: '#E91E63',
    bar: '#FFEBF0',
    normal: '#AD788C',
    icons: [
      'heart_with_ribbon',
      'rose',
      'love_letter',
      'chocolate_bar',
      'ring',
    ],
  ),
  CYLSkin(
    'Mid-Autumn',
    tint: '#FFC107',
    bar: '#1A234C',
    normal: '#9FA8DA',
    icons: [
      'moon_cake',
      'full_moon',
      'rabbit',
      'teacup_without_handle',
      'crescent_moon',
    ],
  ),
  CYLSkin(
    'Easter',
    tint: '#7CB342',
    bar: '#FFFAE1',
    normal: '#A1887F',
    icons: ['hatching_chick', 'egg', 'rabbit_face', 'tulip', 'basket'],
  ),
  CYLSkin(
    'New Year',
    tint: '#FFD740',
    bar: '#141428',
    normal: '#90A4AE',
    icons: [
      'party_popper',
      'confetti_ball',
      'clinking_glasses',
      'sparkler',
      'alarm_clock',
    ],
  ),
  CYLSkin(
    'Summer',
    tint: '#0097A7',
    bar: '#FFF8E1',
    normal: '#8D6E63',
    icons: [
      'beach_with_umbrella',
      'watermelon',
      'palm_tree',
      'tropical_drink',
      'sun',
    ],
  ),
  CYLSkin(
    'Birthday',
    tint: '#EC407A',
    bar: '#FFF3E0',
    normal: '#9575CD',
    icons: ['birthday_cake', 'balloon', 'candle', 'teddy_bear', 'wrapped_gift'],
  ),
  CYLSkin(
    'Space',
    tint: '#80DEEA',
    bar: '#0D1126',
    normal: '#7986CB',
    icons: [
      'rocket',
      'ringed_planet',
      'flying_saucer',
      'glowing_star',
      'comet',
    ],
  ),
  CYLSkin(
    'Ocean',
    tint: '#FFFFFF',
    bar: '#01579B',
    normal: '#81D4FA',
    icons: [
      'spouting_whale',
      'tropical_fish',
      'spiral_shell',
      'crab',
      'water_wave',
    ],
  ),
  CYLSkin(
    'Network icons',
    tint: '#007AFF',
    bar: '#F2F7FF',
    normal: '#78869C',
    network: CYLSkinNetwork(
      tabs: [
        [
          'https://cdn-icons-png.flaticon.com/512/1946/1946488.png',
          'https://cdn-icons-png.flaticon.com/512/1946/1946436.png',
        ],
        [
          'https://cdn-icons-png.flaticon.com/512/2099/2099085.png',
          'https://cdn-icons-png.flaticon.com/512/2099/2099085.png',
        ],
        [
          'https://cdn-icons-png.flaticon.com/512/2099/2099100.png',
          'https://cdn-icons-png.flaticon.com/512/2099/2099100.png',
        ],
        [
          'https://cdn-icons-png.flaticon.com/512/1077/1077063.png',
          'https://cdn-icons-png.flaticon.com/512/1077/1077114.png',
        ],
      ],
      plusButton: [
        'https://cdn-icons-png.flaticon.com/512/992/992651.png',
        'https://cdn-icons-png.flaticon.com/512/1828/1828817.png',
      ],
      titlePrefix: '★',
    ),
  ),
];
