/**
 * [EN] UIColor+CYLTabBarControllerExtention: the iOS system and semantic colors (light / dark values of UIKit), picked by
 *      the app's color mode (AppStorage cyl_colorMode, set by cyl_updateColorMode), plus cyl_colorWithLightColor:darkColor:
 *      and cyl_randomColor. Read a getter again after a color mode change (a @StorageProp('cyl_colorMode') in the page
 *      re-renders).
 * [CN] UIColor+CYLTabBarControllerExtention：iOS 系统与语义颜色（UIKit 的浅色 / 深色值），按应用颜色模式（AppStorage cyl_colorMode）选择，
 *      并提供 cyl_colorWithLightColor:darkColor: 与 cyl_randomColor。颜色模式变化后重新读取即可。
 */
function cylIsDark(): boolean {
  return AppStorage.get<string>('cyl_colorMode') === 'dark';
}

function cylPick(light: string, dark: string): string {
  return cylIsDark() ? dark : light;
}

export class CYLColor {
  /** [EN] +cyl_colorWithLightColor:darkColor:. [CN] 浅色 / 深色模式下的颜色。 */
  static cyl_colorWithLightColorDarkColor(light: ResourceColor, dark: ResourceColor): ResourceColor {
    return cylIsDark() ? dark : light;
  }

  /** [EN] cyl_randomColor: any hue, saturation and brightness 0.5-1. [CN] 随机颜色：任意色相，饱和度与亮度 0.5–1。 */
  static get cyl_randomColor(): string {
    const h = Math.random() * 360;
    const s = 0.5 + Math.random() * 0.5;
    const v = 0.5 + Math.random() * 0.5;
    const c = v * s;
    const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
    const m = v - c;
    const rgb = h < 60 ? [c, x, 0] : h < 120 ? [x, c, 0] : h < 180 ? [0, c, x] : h < 240 ? [0, x, c] : h < 300 ? [x, 0, c] : [c, 0, x];
    return '#' + rgb.map((n: number) => Math.round((n + m) * 255).toString(16).padStart(2, '0')).join('').toUpperCase();
  }

  static get cyl_systemRedColor(): string { return cylPick('#FF3B30', '#FF453A'); }
  static get cyl_systemGreenColor(): string { return cylPick('#34C759', '#30D158'); }
  static get cyl_systemBlueColor(): string { return cylPick('#007AFF', '#0A84FF'); }
  static get cyl_systemOrangeColor(): string { return cylPick('#FF9500', '#FF9F0A'); }
  static get cyl_systemYellowColor(): string { return cylPick('#FFCC00', '#FFD60A'); }
  static get cyl_systemPinkColor(): string { return cylPick('#FF2D55', '#FF375F'); }
  static get cyl_systemPurpleColor(): string { return cylPick('#AF52DE', '#BF5AF2'); }
  static get cyl_systemTealColor(): string { return cylPick('#5AC8FA', '#64D2FF'); }
  static get cyl_systemIndigoColor(): string { return cylPick('#5856D6', '#5E5CE6'); }
  static get cyl_systemGrayColor(): string { return cylPick('#8E8E93', '#8E8E93'); }
  static get cyl_systemGray2Color(): string { return cylPick('#AEAEB2', '#636366'); }
  static get cyl_systemGray3Color(): string { return cylPick('#C7C7CC', '#48484A'); }
  static get cyl_systemGray4Color(): string { return cylPick('#D1D1D6', '#3A3A3C'); }
  static get cyl_systemGray5Color(): string { return cylPick('#E5E5EA', '#2C2C2E'); }
  static get cyl_systemGray6Color(): string { return cylPick('#F2F2F7', '#1C1C1E'); }
  static get cyl_labelColor(): string { return cylPick('#000000', '#FFFFFF'); }
  static get cyl_secondaryLabelColor(): string { return cylPick('#993C3C43', '#99EBEBF5'); }
  static get cyl_tertiaryLabelColor(): string { return cylPick('#4D3C3C43', '#4DEBEBF5'); }
  static get cyl_quaternaryLabelColor(): string { return cylPick('#2E3C3C43', '#29EBEBF5'); }
  static get cyl_linkColor(): string { return cylPick('#007AFF', '#0984FF'); }
  static get cyl_placeholderTextColor(): string { return cylPick('#4D3C3C43', '#4DEBEBF5'); }
  static get cyl_separatorColor(): string { return cylPick('#4A3C3C43', '#99545458'); }
  static get cyl_opaqueSeparatorColor(): string { return cylPick('#C6C6C8', '#38383A'); }
  static get cyl_systemBackgroundColor(): string { return cylPick('#FFFFFF', '#000000'); }
  static get cyl_secondarySystemBackgroundColor(): string { return cylPick('#F2F2F7', '#1C1C1E'); }
  static get cyl_tertiarySystemBackgroundColor(): string { return cylPick('#FFFFFF', '#2C2C2E'); }
  static get cyl_systemGroupedBackgroundColor(): string { return cylPick('#F2F2F7', '#000000'); }
  static get cyl_secondarySystemGroupedBackgroundColor(): string { return cylPick('#FFFFFF', '#1C1C1E'); }
  static get cyl_tertiarySystemGroupedBackgroundColor(): string { return cylPick('#F2F2F7', '#2C2C2E'); }
  static get cyl_systemFillColor(): string { return cylPick('#33787880', '#5C787880'); }
  static get cyl_secondarySystemFillColor(): string { return cylPick('#29787880', '#52787880'); }
  static get cyl_tertiarySystemFillColor(): string { return cylPick('#1F767680', '#3D767680'); }
  static get cyl_quaternarySystemFillColor(): string { return cylPick('#14747480', '#2E767680'); }
  /** [EN] lightTextColor is always light (white at 60 %). [CN] 始终为浅色（60% 白）。 */
  static get cyl_lightTextColor(): string { return '#99FFFFFF'; }
  /** [EN] darkTextColor is always dark (black). [CN] 始终为深色（黑色）。 */
  static get cyl_darkTextColor(): string { return '#000000'; }
}
