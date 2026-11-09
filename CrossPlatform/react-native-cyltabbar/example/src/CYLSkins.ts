/**
 * The skins of the Objective-C example's skin picker (UIViewController+CYLThemeSettings.m, `CYLDemoThemes()`), in its
 * order: colors only, holiday icons and colors, network icons, titles and colors. Each skin gives the bar's colors, and
 * the tab and plus button images that replace the Lottie icons.
 * Objective-C 示例换肤菜单中的皮肤（UIViewController+CYLThemeSettings.m 的 `CYLDemoThemes()`），顺序相同：仅配色、节日图标与配色、
 * 网络图标、标题与配色。每个皮肤给出 TabBar 的颜色，以及替换 Lottie 图标的 Tab 与 PlusButton 图片。
 */
import type { CYLTabBarImage } from 'react-native-cyltabbar';

export type CYLSkin = {
  name: string;
  /** The selected color, also the badges' (nil: the app's own appearance). 选中颜色，也是角标颜色（未设置：App 自己的外观）。 */
  tint?: string;
  bar?: string;
  /** Unselected titles and icons (default systemGray). 未选中的标题与图标（默认 systemGray）。 */
  normal?: string;
  /** Holiday icons, in turn on every tab; the last one on the plus button. 节日图标，依次用于各 Tab；最后一个用于 PlusButton。 */
  icons?: string[];
  /** Network icons [normal, selected] per tab, the plus button's, and the title prefix. 每个 Tab 的网络图标、PlusButton 的网络图标与标题前缀。 */
  network?: { tabs: [string, string][]; plusButton: [string, string]; titlePrefix: string };
};

/** A holiday icon in full color (selected) and at 45% opacity (unselected, `CYLDemoFadedImage`). 全彩（选中）与 45% 不透明度（未选中）的节日图标。 */
export const THEME_ICONS: Record<string, { image: CYLTabBarImage; faded: CYLTabBarImage }> = {
  alarm_clock: { image: require('./assets/theme/alarm_clock.png'), faded: require('./assets/theme/alarm_clock_faded.png') },
  balloon: { image: require('./assets/theme/balloon.png'), faded: require('./assets/theme/balloon_faded.png') },
  basket: { image: require('./assets/theme/basket.png'), faded: require('./assets/theme/basket_faded.png') },
  bat: { image: require('./assets/theme/bat.png'), faded: require('./assets/theme/bat_faded.png') },
  beach_with_umbrella: { image: require('./assets/theme/beach_with_umbrella.png'), faded: require('./assets/theme/beach_with_umbrella_faded.png') },
  bell: { image: require('./assets/theme/bell.png'), faded: require('./assets/theme/bell_faded.png') },
  birthday_cake: { image: require('./assets/theme/birthday_cake.png'), faded: require('./assets/theme/birthday_cake_faded.png') },
  candle: { image: require('./assets/theme/candle.png'), faded: require('./assets/theme/candle_faded.png') },
  candy: { image: require('./assets/theme/candy.png'), faded: require('./assets/theme/candy_faded.png') },
  chocolate_bar: { image: require('./assets/theme/chocolate_bar.png'), faded: require('./assets/theme/chocolate_bar_faded.png') },
  christmas_tree: { image: require('./assets/theme/christmas_tree.png'), faded: require('./assets/theme/christmas_tree_faded.png') },
  clinking_glasses: { image: require('./assets/theme/clinking_glasses.png'), faded: require('./assets/theme/clinking_glasses_faded.png') },
  comet: { image: require('./assets/theme/comet.png'), faded: require('./assets/theme/comet_faded.png') },
  confetti_ball: { image: require('./assets/theme/confetti_ball.png'), faded: require('./assets/theme/confetti_ball_faded.png') },
  crab: { image: require('./assets/theme/crab.png'), faded: require('./assets/theme/crab_faded.png') },
  crescent_moon: { image: require('./assets/theme/crescent_moon.png'), faded: require('./assets/theme/crescent_moon_faded.png') },
  dragon: { image: require('./assets/theme/dragon.png'), faded: require('./assets/theme/dragon_faded.png') },
  egg: { image: require('./assets/theme/egg.png'), faded: require('./assets/theme/egg_faded.png') },
  firecracker: { image: require('./assets/theme/firecracker.png'), faded: require('./assets/theme/firecracker_faded.png') },
  fireworks: { image: require('./assets/theme/fireworks.png'), faded: require('./assets/theme/fireworks_faded.png') },
  flying_saucer: { image: require('./assets/theme/flying_saucer.png'), faded: require('./assets/theme/flying_saucer_faded.png') },
  full_moon: { image: require('./assets/theme/full_moon.png'), faded: require('./assets/theme/full_moon_faded.png') },
  ghost: { image: require('./assets/theme/ghost.png'), faded: require('./assets/theme/ghost_faded.png') },
  glowing_star: { image: require('./assets/theme/glowing_star.png'), faded: require('./assets/theme/glowing_star_faded.png') },
  hatching_chick: { image: require('./assets/theme/hatching_chick.png'), faded: require('./assets/theme/hatching_chick_faded.png') },
  heart_with_ribbon: { image: require('./assets/theme/heart_with_ribbon.png'), faded: require('./assets/theme/heart_with_ribbon_faded.png') },
  jack_o_lantern: { image: require('./assets/theme/jack_o_lantern.png'), faded: require('./assets/theme/jack_o_lantern_faded.png') },
  love_letter: { image: require('./assets/theme/love_letter.png'), faded: require('./assets/theme/love_letter_faded.png') },
  moon_cake: { image: require('./assets/theme/moon_cake.png'), faded: require('./assets/theme/moon_cake_faded.png') },
  palm_tree: { image: require('./assets/theme/palm_tree.png'), faded: require('./assets/theme/palm_tree_faded.png') },
  party_popper: { image: require('./assets/theme/party_popper.png'), faded: require('./assets/theme/party_popper_faded.png') },
  rabbit: { image: require('./assets/theme/rabbit.png'), faded: require('./assets/theme/rabbit_faded.png') },
  rabbit_face: { image: require('./assets/theme/rabbit_face.png'), faded: require('./assets/theme/rabbit_face_faded.png') },
  red_envelope: { image: require('./assets/theme/red_envelope.png'), faded: require('./assets/theme/red_envelope_faded.png') },
  red_paper_lantern: { image: require('./assets/theme/red_paper_lantern.png'), faded: require('./assets/theme/red_paper_lantern_faded.png') },
  ring: { image: require('./assets/theme/ring.png'), faded: require('./assets/theme/ring_faded.png') },
  ringed_planet: { image: require('./assets/theme/ringed_planet.png'), faded: require('./assets/theme/ringed_planet_faded.png') },
  rocket: { image: require('./assets/theme/rocket.png'), faded: require('./assets/theme/rocket_faded.png') },
  rose: { image: require('./assets/theme/rose.png'), faded: require('./assets/theme/rose_faded.png') },
  snowman: { image: require('./assets/theme/snowman.png'), faded: require('./assets/theme/snowman_faded.png') },
  sparkler: { image: require('./assets/theme/sparkler.png'), faded: require('./assets/theme/sparkler_faded.png') },
  spider: { image: require('./assets/theme/spider.png'), faded: require('./assets/theme/spider_faded.png') },
  spiral_shell: { image: require('./assets/theme/spiral_shell.png'), faded: require('./assets/theme/spiral_shell_faded.png') },
  spouting_whale: { image: require('./assets/theme/spouting_whale.png'), faded: require('./assets/theme/spouting_whale_faded.png') },
  star: { image: require('./assets/theme/star.png'), faded: require('./assets/theme/star_faded.png') },
  sun: { image: require('./assets/theme/sun.png'), faded: require('./assets/theme/sun_faded.png') },
  teacup_without_handle: { image: require('./assets/theme/teacup_without_handle.png'), faded: require('./assets/theme/teacup_without_handle_faded.png') },
  teddy_bear: { image: require('./assets/theme/teddy_bear.png'), faded: require('./assets/theme/teddy_bear_faded.png') },
  tropical_drink: { image: require('./assets/theme/tropical_drink.png'), faded: require('./assets/theme/tropical_drink_faded.png') },
  tropical_fish: { image: require('./assets/theme/tropical_fish.png'), faded: require('./assets/theme/tropical_fish_faded.png') },
  tulip: { image: require('./assets/theme/tulip.png'), faded: require('./assets/theme/tulip_faded.png') },
  water_wave: { image: require('./assets/theme/water_wave.png'), faded: require('./assets/theme/water_wave_faded.png') },
  watermelon: { image: require('./assets/theme/watermelon.png'), faded: require('./assets/theme/watermelon_faded.png') },
  wrapped_gift: { image: require('./assets/theme/wrapped_gift.png'), faded: require('./assets/theme/wrapped_gift_faded.png') },
};

export const SKINS: CYLSkin[] = [
  { name: 'Default' },
  { name: 'Grapefruit', tint: '#EF5362' },
  { name: 'Grass', tint: '#6EB43C' },
  { name: 'Pink Rose', tint: '#EE85C1' },
  { name: 'Dark', tint: '#27C0F3', bar: '#121214', normal: '#8E8E93' },
  { name: "Spring Festival", tint: '#FFD54F', bar: '#C41E3A', normal: '#FFCDD2', icons: ['red_envelope', 'firecracker', 'red_paper_lantern', 'dragon', 'fireworks'] },
  { name: "Christmas", tint: '#FFD666', bar: '#166534', normal: '#C8E6C9', icons: ['christmas_tree', 'wrapped_gift', 'snowman', 'bell', 'star'] },
  { name: "Halloween", tint: '#FF9100', bar: '#26143A', normal: '#B39DDB', icons: ['jack_o_lantern', 'ghost', 'bat', 'spider', 'candy'] },
  { name: "Valentine's Day", tint: '#E91E63', bar: '#FFEBF0', normal: '#AD788C', icons: ['heart_with_ribbon', 'rose', 'love_letter', 'chocolate_bar', 'ring'] },
  { name: "Mid-Autumn", tint: '#FFC107', bar: '#1A234C', normal: '#9FA8DA', icons: ['moon_cake', 'full_moon', 'rabbit', 'teacup_without_handle', 'crescent_moon'] },
  { name: "Easter", tint: '#7CB342', bar: '#FFFAE1', normal: '#A1887F', icons: ['hatching_chick', 'egg', 'rabbit_face', 'tulip', 'basket'] },
  { name: "New Year", tint: '#FFD740', bar: '#141428', normal: '#90A4AE', icons: ['party_popper', 'confetti_ball', 'clinking_glasses', 'sparkler', 'alarm_clock'] },
  { name: "Summer", tint: '#0097A7', bar: '#FFF8E1', normal: '#8D6E63', icons: ['beach_with_umbrella', 'watermelon', 'palm_tree', 'tropical_drink', 'sun'] },
  { name: "Birthday", tint: '#EC407A', bar: '#FFF3E0', normal: '#9575CD', icons: ['birthday_cake', 'balloon', 'candle', 'teddy_bear', 'wrapped_gift'] },
  { name: "Space", tint: '#80DEEA', bar: '#0D1126', normal: '#7986CB', icons: ['rocket', 'ringed_planet', 'flying_saucer', 'glowing_star', 'comet'] },
  { name: "Ocean", tint: '#FFFFFF', bar: '#01579B', normal: '#81D4FA', icons: ['spouting_whale', 'tropical_fish', 'spiral_shell', 'crab', 'water_wave'] },
  {
    name: 'Network icons',
    tint: '#007AFF',
    bar: '#F2F7FF',
    normal: '#78869C',
    network: {
      tabs: [
        ['https://cdn-icons-png.flaticon.com/512/1946/1946488.png', 'https://cdn-icons-png.flaticon.com/512/1946/1946436.png'],
        ['https://cdn-icons-png.flaticon.com/512/2099/2099085.png', 'https://cdn-icons-png.flaticon.com/512/2099/2099085.png'],
        ['https://cdn-icons-png.flaticon.com/512/2099/2099100.png', 'https://cdn-icons-png.flaticon.com/512/2099/2099100.png'],
        ['https://cdn-icons-png.flaticon.com/512/1077/1077063.png', 'https://cdn-icons-png.flaticon.com/512/1077/1077114.png'],
      ],
      plusButton: ['https://cdn-icons-png.flaticon.com/512/992/992651.png', 'https://cdn-icons-png.flaticon.com/512/1828/1828817.png'],
      titlePrefix: '★',
    },
  },
];
