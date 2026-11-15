import { CYLThemeManagerCenter } from 'cyltabbar';

/**
 * [EN] One skin of the iOS demo's theme list (issue #216, CYLDemoTheme; DemoThemes.kt): a tint, a bar color, an
 *      unselected color; a holiday skin's icons (rawfile Skins/1.0.0/<theme>/<icon>@3x.png, copied from
 *      Example-Shared/Configurations) in turn on every tab, the last one on the plus button; the network skin a "★"
 *      title prefix and icons from the network.
 * [CN] iOS 演示皮肤列表中的一个皮肤（issue #216）：强调色、TabBar 颜色、未选中颜色；节日皮肤的图标依次用于每个 Tab，最后一个用于 PlusButton；
 *      网络皮肤为标题加 "★" 前缀并使用网络图标。
 */
export class DemoTheme {
  name: string;
  tint?: string;
  bar?: string;
  normal?: string;
  icons: string[];
  titlePrefix?: string;
  iconURLs: string[][];
  plusURL?: string;

  constructor(name: string, tint?: string, bar?: string, normal?: string, icons: string[] = [], titlePrefix?: string,
    iconURLs: string[][] = [], plusURL?: string) {
    this.name = name;
    this.tint = tint;
    this.bar = bar;
    this.normal = normal;
    this.icons = icons;
    this.titlePrefix = titlePrefix;
    this.iconURLs = iconURLs;
    this.plusURL = plusURL;
  }

  /** [EN] The rawfile path of a holiday icon. [CN] 节日图标的 rawfile 路径。 */
  iconPath(icon: string): string {
    const folder = this.name.toLowerCase().replace("'", '').split(' ').join('-');
    return `Skins/1.0.0/${folder}/${icon}@3x.png`;
  }
}

export const DEMO_THEMES: DemoTheme[] = [
  new DemoTheme('Default'),
  new DemoTheme('Grapefruit', '#EF5362'),
  new DemoTheme('Grass', '#6EB43C'),
  new DemoTheme('Pink Rose', '#EE85C1'),
  new DemoTheme('Dark', '#27C0F3', '#121214', '#8E8E93'),
  new DemoTheme('Spring Festival', '#FFD54F', '#C41E3A', '#FFCDD2', ['red_envelope', 'firecracker', 'red_paper_lantern', 'dragon', 'fireworks']),
  new DemoTheme('Christmas', '#FFD666', '#166534', '#C8E6C9', ['christmas_tree', 'wrapped_gift', 'snowman', 'bell', 'star']),
  new DemoTheme('Halloween', '#FF9100', '#26143A', '#B39DDB', ['jack_o_lantern', 'ghost', 'bat', 'spider', 'candy']),
  new DemoTheme("Valentine's Day", '#E91E63', '#FFEBF0', '#AD788C', ['heart_with_ribbon', 'rose', 'love_letter', 'chocolate_bar', 'ring']),
  new DemoTheme('Mid-Autumn', '#FFC107', '#1A234C', '#9FA8DA', ['moon_cake', 'full_moon', 'rabbit', 'teacup_without_handle', 'crescent_moon']),
  new DemoTheme('Easter', '#7CB342', '#FFFAE1', '#A1887F', ['hatching_chick', 'egg', 'rabbit_face', 'tulip', 'basket']),
  new DemoTheme('New Year', '#FFD740', '#141428', '#90A4AE', ['party_popper', 'confetti_ball', 'clinking_glasses', 'sparkler', 'alarm_clock']),
  new DemoTheme('Summer', '#0097A7', '#FFF8E1', '#8D6E63', ['beach_with_umbrella', 'watermelon', 'palm_tree', 'tropical_drink', 'sun']),
  new DemoTheme('Birthday', '#EC407A', '#FFF3E0', '#9575CD', ['birthday_cake', 'balloon', 'candle', 'teddy_bear', 'wrapped_gift']),
  new DemoTheme('Space', '#80DEEA', '#0D1126', '#7986CB', ['rocket', 'ringed_planet', 'flying_saucer', 'glowing_star', 'comet']),
  new DemoTheme('Ocean', '#FFFFFF', '#01579B', '#81D4FA', ['spouting_whale', 'tropical_fish', 'spiral_shell', 'crab', 'water_wave']),
  new DemoTheme('Network', '#007AFF', '#F2F7FF', '#78869C', [], '★', [
    ['https://cdn-icons-png.flaticon.com/512/1946/1946488.png', 'https://cdn-icons-png.flaticon.com/512/1946/1946436.png'],
    ['https://cdn-icons-png.flaticon.com/512/2099/2099085.png', 'https://cdn-icons-png.flaticon.com/512/2099/2099085.png'],
    ['https://cdn-icons-png.flaticon.com/512/2099/2099100.png', 'https://cdn-icons-png.flaticon.com/512/2099/2099100.png'],
    ['https://cdn-icons-png.flaticon.com/512/1077/1077063.png', 'https://cdn-icons-png.flaticon.com/512/1077/1077114.png'],
  ], 'https://cdn-icons-png.flaticon.com/512/992/992651.png'),
];

/** [EN] Registers the skins with the default manager once. [CN] 向默认管理器注册一次皮肤。 */
export function demoRegisterThemes(): void {
  const manager = CYLThemeManagerCenter.defaultThemeManager;
  if (manager.themeIdentifiers.length > 0) {
    return;
  }
  DEMO_THEMES.forEach((theme: DemoTheme) => manager.addThemeIdentifier(theme.name, theme));
}
