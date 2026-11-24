/**
 * [EN] The availability rule of Liquid Glass, the one rule every CYLTabBarController component asks (the same name as iOS
 *      `CYLLiquidGlass.isActive()`, Android `CYLLiquidGlass.isActive()` and HarmonyOS `CYLLiquidGlass.isActive()`): always true in a
 *      mini program, whose glass is a CSS `backdrop-filter` (blur and saturation) over a translucent tint; where the WebView does
 *      not support `backdrop-filter` the tint alone stays, as in the tab bar's lens (cyl-glass-lens). `activeOverride` replaces
 *      the rule in tests.
 * [CN] 液态玻璃的可用性判断，CYLTabBarController 各组件共用的唯一规则（与 iOS、Android、鸿蒙的 `CYLLiquidGlass.isActive()` 同名）：在
 *      小程序中始终为真，其玻璃是半透明着色之上的 CSS `backdrop-filter`（模糊与饱和度）；WebView 不支持 `backdrop-filter` 时只剩着色，
 *      与 TabBar 的透镜（cyl-glass-lens）相同。`activeOverride` 供测试替换该规则。
 */
const state = { activeOverride: undefined };

/**
 * [EN] Whether Liquid Glass is in use; when false the caller keeps its flat background and does not render the component.
 * [CN] 是否使用液态玻璃；为 false 时调用方保持其扁平背景，不渲染该组件。
 */
function cylLiquidGlassIsActive() {
  return state.activeOverride !== undefined ? state.activeOverride : true;
}

/**
 * [EN] For tests: replaces the rule (`undefined` uses it). [CN] 供测试使用：替代该规则（`undefined` 表示使用该规则）。
 */
function cylLiquidGlassSetActiveOverride(value) {
  state.activeOverride = value;
}

/**
 * [EN] The inline style of the glass: the corner radius (px) and, when given, the tint (a CSS color).
 * [CN] 玻璃的行内样式：圆角（px）与（如有）着色（CSS 颜色）。
 */
function cylLiquidGlassStyle(glassTintColor, cornerRadius) {
  const radius = Number(cornerRadius) > 0 ? Number(cornerRadius) : 0;
  let style = `border-radius:${radius}px;`;
  if (typeof glassTintColor === 'string' && glassTintColor.length > 0) {
    style += `background-color:${glassTintColor};`;
  }
  return style;
}

module.exports = { cylLiquidGlassIsActive, cylLiquidGlassSetActiveOverride, cylLiquidGlassStyle };
