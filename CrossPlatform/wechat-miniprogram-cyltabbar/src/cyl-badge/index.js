const { cylBadgeViewModel } = require('./cyl_badge_model');

/**
 * [EN] `cyl-badge`: a dot, a number or a text badge with the style of `badgeAttributes`. `value` follows iOS' `badgeValue`:
 *      null (the default, never '') no badge, '' a dot, otherwise the text. The host places it (an anchor on the icon).
 *      Not run in the developer tools yet: the model is covered by `node --test`.
 * [CN] `cyl-badge`：带 `badgeAttributes` 样式的红点、数字或文字角标。`value` 遵循 iOS 的 `badgeValue`：null（默认值，绝不是 ''）无角标、
 *      '' 红点，其余为文字。位置由宿主决定（图标上的锚点）。尚未在开发者工具中运行：模型由 `node --test` 覆盖。
 */
Component({
  options: { styleIsolation: 'isolated' },
  properties: {
    value: { type: null, value: null },
    attributes: { type: Object, value: null },
    reduceMotion: { type: Boolean, value: false },
  },
  data: { m: { showsBadge: false, isDot: false, text: '', className: '', style: '' } },
  observers: {
    'value, attributes, reduceMotion': function (value, attributes, reduceMotion) {
      this.setData({ m: cylBadgeViewModel(value, attributes, { reduceMotion }) });
    },
  },
});
