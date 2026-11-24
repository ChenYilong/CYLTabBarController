const { cylLiquidGlassIsActive, cylLiquidGlassStyle } = require('./cyl_liquid_glass');

/**
 * [EN] cyl-liquid-glass: a Liquid Glass background for any component (the same names as iOS `CYLLiquidGlassView`): put it first
 *      inside a positioned parent; it fills the parent, blurs what is behind it (CSS `backdrop-filter`), is tinted with
 *      `glassTintColor` and clipped to `cornerRadius`. It takes no touches and is hidden from accessibility. `isGlassDrawn` (data)
 *      is `cylLiquidGlassIsActive()`: when false the caller keeps its flat background and does not render the component.
 * [CN] cyl-liquid-glass：任意组件的液态玻璃背景（与 iOS 的 `CYLLiquidGlassView` 同名）：放在有定位的父视图内的最前面；它占满父视图，
 *      模糊其后的内容（CSS `backdrop-filter`），以 `glassTintColor` 着色并按 `cornerRadius` 裁剪。不接收触摸，对辅助功能隐藏。
 *      `isGlassDrawn`（data）即 `cylLiquidGlassIsActive()`：为 false 时调用方保持其扁平背景，不渲染该组件。
 */
Component({
  properties: {
    /** [EN] The tint (a CSS color such as 'rgba(255,136,0,0.4)'); '' for none. [CN] 着色（CSS 颜色，如 'rgba(255,136,0,0.4)'）；'' 表示不着色。 */
    glassTintColor: { type: String, value: '' },
    /** [EN] The corner radius, px. [CN] 圆角半径，单位 px。 */
    cornerRadius: { type: Number, value: 0 },
    /** [EN] Dark glass for a dark skin. [CN] 深色皮肤使用深色玻璃。 */
    isDark: { type: Boolean, value: false },
  },
  data: {
    glassStyle: '',
    isGlassDrawn: true,
  },
  observers: {
    'glassTintColor, cornerRadius': function observe(glassTintColor, cornerRadius) {
      this.setData({ glassStyle: cylLiquidGlassStyle(glassTintColor, cornerRadius), isGlassDrawn: cylLiquidGlassIsActive() });
    },
  },
  lifetimes: {
    attached() {
      this.setData({
        glassStyle: cylLiquidGlassStyle(this.data.glassTintColor, this.data.cornerRadius),
        isGlassDrawn: cylLiquidGlassIsActive(),
      });
    },
  },
});
