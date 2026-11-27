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
    // [EN] The tab bar item's badge, drawn as it always was (phase 1: moved, not changed): `variant` "tab" takes the tab bar's sizes, `valueText`
    //      replaces `value`'s text, `dot` forces a dot, `styleText` and `classText` are the item's own inline style and animation class, used as given.
    // [CN] TabBar item 的角标，仍按原样绘制（阶段 1：移动，不改变）：`variant` 为 "tab" 时使用 TabBar 的尺寸；`valueText` 替代 `value` 的文字，`dot` 强制红点，
    //      `styleText` 与 `classText` 是 item 自己的内联样式与动画类，原样使用。
    variant: { type: String, value: '' },
    valueText: { type: String, value: '' },
    dot: { type: Boolean, value: false },
    styleText: { type: String, value: '' },
    classText: { type: String, value: '' },
  },
  data: { m: { showsBadge: false, isDot: false, text: '', className: '', style: '' } },
  observers: {
    'value, attributes, reduceMotion, variant, valueText, dot, styleText, classText': function (value, attributes, reduceMotion, variant, valueText, dot, styleText, classText) {
      if (variant === 'tab') {
        // [EN] The item computed everything: show it as it is. [CN] item 已经算好全部内容：原样显示。
        this.setData({ m: { showsBadge: true, isDot: dot, text: valueText, className: classText, style: styleText, variant } });
        return;
      }
      this.setData({ m: cylBadgeViewModel(value, attributes, { reduceMotion }) });
    },
  },
});
