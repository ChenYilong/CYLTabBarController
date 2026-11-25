/**
 * [EN] The Liquid Glass of `CYLAnimatedItemView` on HarmonyOS NEXT (`itemBackgroundStyle = liquidGlass`): the availability rule and
 *      the blur values of the glass imitation (API 12 to 21 have no system glass material, so the glass is a blur with a tint). The
 *      tab bar (`cyltabbar`) depends on this module and draws its own capsule with the same values; this module knows nothing of it.
 *      An ArkUI struct has no static members, so the rule is this exported class (iOS and Android: `CYLAnimatedItemView.isLiquidGlassActive()`).
 * [CN] 鸿蒙 `CYLAnimatedItemView` 的液态玻璃（`itemBackgroundStyle = liquidGlass`）：可用性判断与玻璃仿制的模糊数值（API 12 到 21 没有系统玻璃材质，
 *      因此玻璃是带着色的模糊）。TabBar（`cyltabbar`）依赖本模块并用相同的数值绘制自己的胶囊；本模块不了解 TabBar。ArkUI struct 没有静态成员，
 *      所以规则是这个导出的类（iOS 与 Android 为 `CYLAnimatedItemView.isLiquidGlassActive()`）。
 */
export class CYLLiquidGlass {
  /**
   * [EN] The blur radius of the glass imitation, vp. [CN] 玻璃仿制的模糊半径，单位 vp。
   */
  static readonly BLUR_RADIUS: number = 28;
  /**
   * [EN] The share of a host color's alpha that tints the glass. [CN] 宿主颜色透明度中用于给玻璃着色的比例。
   */
  static readonly GLASS_TINT_ALPHA: number = 0.75;
  /**
   * [EN] The saturation of the glass imitation. [CN] 玻璃仿制的饱和度。
   */
  static readonly BLUR_SATURATION: number = 1.6;
  /**
   * [EN] The brightness of light glass. [CN] 浅色玻璃的亮度。
   */
  static readonly LIGHT_BRIGHTNESS: number = 1.05;
  /**
   * [EN] The brightness of dark glass. [CN] 深色玻璃的亮度。
   */
  static readonly DARK_BRIGHTNESS: number = 0.9;

  /**
   * [EN] The width of the glass rim, vp (Android: 1 dp). [CN] 玻璃边缘细边的宽度，单位 vp（Android 为 1 dp）。
   */
  static readonly RIM_WIDTH: number = 1;
  /**
   * [EN] The rim on light glass: black at alpha 41/255. [CN] 浅色玻璃上的细边：黑色，透明度 41/255。
   */
  static readonly RIM_LIGHT: string = '#29000000';
  /**
   * [EN] The rim on dark glass: white at alpha 56/255. [CN] 深色玻璃上的细边：白色，透明度 56/255。
   */
  static readonly RIM_DARK: string = '#38FFFFFF';
  /**
   * [EN] Whether the app's color mode is dark (AppStorage `cyl_colorMode`, set by cyltabbar's `cyl_updateColorMode`; light when unset). The rule
   *      of the rim and the sheen: read when the background is applied.
   * [CN] 应用颜色模式是否为深色（AppStorage 的 `cyl_colorMode`，由 cyltabbar 的 `cyl_updateColorMode` 设置；未设置时为浅色）。细边与高光的规则：
   *      应用背景时读取。
   */
  static isDark(): boolean {
    return AppStorage.get<string>('cyl_colorMode') === 'dark';
  }

  /**
   * [EN] The rim of a tag, a section card or an item: Android's hairline (`CYLLiquidGlassView`, 1 dp, the same on all four edges), black at alpha 41/255 on
   *      light glass and white at alpha 56/255 on dark glass (measured on the Android example: rim (201,200,199) over a (240,238,237) fill). There is no
   *      sheen and no directional edge. One definition: the tag list applies it to its cards and tags through `CYLAnimatedItemBackgroundModifier`.
   * [CN] 标签、分组卡片或条目的细边：Android 的细边（`CYLLiquidGlassView`，1 dp，四条边相同），浅色玻璃上为黑色、透明度 41/255，深色玻璃上为白色、
   *      透明度 56/255（在 Android 示例上测得：细边 (201,200,199)，底色 (240,238,237)）。没有高光，也没有方向性边缘。只有这一份定义：标签列表通过
   *      `CYLAnimatedItemBackgroundModifier` 把它用于卡片与标签。
   */
  static rimColor(dark: boolean): string {
    return dark ? CYLLiquidGlass.RIM_DARK : CYLLiquidGlass.RIM_LIGHT;
  }

  /**
   * [EN] For tests: replaces the rule of `isActive()` (`undefined`, the default, uses the rule). [CN] 供测试使用：替代 `isActive()` 的规则（默认 `undefined`，使用规则）。
   */
  static activeOverride: boolean | undefined = undefined;

  /**
   * [EN] Whether Liquid Glass is in use: always true on HarmonyOS, whose tab bar draws the blur imitation on every supported API
   *      (the system material replaces it from API 24); when false a host keeps its flat background.
   * [CN] 是否使用液态玻璃：在鸿蒙上始终为真，因为 TabBar 在每个受支持的 API 上都绘制模糊仿制（系统材质从 API 24 起替代它）；为 false 时宿主保持扁平背景。
   */
  static isActive(): boolean {
    const override: boolean | undefined = CYLLiquidGlass.activeOverride;
    return override !== undefined ? override : true;
  }
}
