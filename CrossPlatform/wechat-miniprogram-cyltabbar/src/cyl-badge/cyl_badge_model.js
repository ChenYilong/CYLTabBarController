'use strict';

/**
 * [EN] The badge model, pure functions (docs/Animated-Item-Badge-CrossPlatform.md, phase 2): the value of iOS' `badgeValue`
 *      (`null` no badge, `""` a dot, otherwise the text; a number above the maximum shows "99+"; a number of 0 or below
 *      shows nothing), the style keys of iOS' `CYLBadgeAttributeKey`, and the one parser `cylBadgeParseAttributes`.
 *      Written statically on Linux and checked by `node --test`, not yet by the developer tools.
 * [CN] 角标模型，纯函数（docs/Animated-Item-Badge-CrossPlatform.md，阶段 2）：iOS `badgeValue` 的取值（`null` 无角标、`""` 红点，其余为文字；
 *      超过最大值的数字显示 "99+"；0 及以下的数字不显示），iOS `CYLBadgeAttributeKey` 的样式键，以及唯一的解析函数 `cylBadgeParseAttributes`。
 *      在 Linux 上静态编写并由 `node --test` 检查，尚未在开发者工具中检查。
 */
const { cylBadgeAnimationClass } = require('./cyl_badge_debug');

const CYL_BADGE_ANIMATION_NAMES = ['none', 'scale', 'shake', 'bounce', 'breathe', 'leftRightOnce', 'rightLeftOnce', 'fadeInOnce', 'rollingOnce', 'scaleOnce'];
// [EN] The animations with a CSS class in `cyl_badge_animations.wxss`. [CN] 在 `cyl_badge_animations.wxss` 中有 CSS 类的动画。
const CYL_BADGE_CSS_ANIMATIONS = ['scale', 'shake', 'bounce', 'breathe', 'scaleOnce'];

/** [EN] The keys, the same strings as iOS. [CN] 键，与 iOS 相同的字符串。 */
const CYLBadgeAttributeKey = {
  value: 'value', color: 'color', animation: 'animation', radius: 'radius', centerOffset: 'centerOffset', textColor: 'textColor',
  font: 'font', borderColor: 'borderColor', borderWidth: 'borderWidth', maximumNumber: 'maximumNumber', respectsReduceMotion: 'respectsReduceMotion',
};

/**
 * [EN] The canonical name of an animation (a number 0...9 or a name in any letter case); '' for anything else.
 * [CN] 动画的规范名称（数字 0...9 或任意大小写的名称）；其他值为 ''。
 */
function cylBadgeAnimationName(value) {
  if (typeof value === 'number' && Number.isInteger(value) && value >= 0 && value < CYL_BADGE_ANIMATION_NAMES.length) return CYL_BADGE_ANIMATION_NAMES[value];
  if (typeof value === 'string') {
    const found = CYL_BADGE_ANIMATION_NAMES.find((name) => name.toLowerCase() === value.trim().toLowerCase());
    if (found) return found;
  }
  return '';
}

function cylBadgeNumber(value) {
  if (typeof value === 'number' && Number.isFinite(value)) return value;
  if (typeof value === 'string' && value.trim() !== '' && Number.isFinite(Number(value))) return Number(value);
  return null;
}

/** [EN] `#RRGGBB` / `#RRGGBBAA` becomes a CSS color; any other non-empty string passes through; the rest is ignored. [CN] `#RRGGBB` / `#RRGGBBAA` 转为 CSS 颜色；其他非空字符串原样通过；其余忽略。 */
function cylBadgeColor(value) {
  if (typeof value !== 'string') return '';
  const text = value.trim();
  const match = /^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$/.exec(text);
  if (!match) return text;
  if (!match[2]) return `#${match[1]}`;
  const alpha = Math.round((parseInt(match[2], 16) / 255) * 1000) / 1000;
  const [r, g, b] = [0, 2, 4].map((i) => parseInt(match[1].slice(i, i + 2), 16));
  return `rgba(${r},${g},${b},${alpha})`;
}

/** [EN] `{x, y}` as a string, an object or a two-number array. [CN] `{x, y}` 字符串、对象或两个数字的数组。 */
function cylBadgePoint(value) {
  if (typeof value === 'string') {
    const match = /^\s*\{\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*\}\s*$/.exec(value);
    return match ? { x: Number(match[1]), y: Number(match[2]) } : null;
  }
  if (Array.isArray(value) && value.length === 2 && value.every((n) => typeof n === 'number')) return { x: value[0], y: value[1] };
  if (value && typeof value === 'object' && typeof value.x === 'number' && typeof value.y === 'number') return { x: value.x, y: value.y };
  return null;
}

/**
 * [EN] The one parser of a badge style dictionary: the keys of `CYLBadgeAttributeKey`; values are native values or strings;
 *      null and unknown types are ignored, never a throw.
 * [CN] 角标样式字典的唯一解析函数：键为 `CYLBadgeAttributeKey`；值为原生值或字符串；null 与未知类型被忽略，不会抛出异常。
 */
function cylBadgeParseAttributes(attributes) {
  const source = attributes && typeof attributes === 'object' ? attributes : {};
  const out = {};
  const color = cylBadgeColor(source.color); if (color) out.color = color;
  const textColor = cylBadgeColor(source.textColor); if (textColor) out.textColor = textColor;
  const borderColor = cylBadgeColor(source.borderColor); if (borderColor) out.borderColor = borderColor;
  [['radius', 'radius'], ['font', 'fontSize'], ['borderWidth', 'borderWidth'], ['maximumNumber', 'maximumNumber']].forEach(([key, name]) => {
    const n = cylBadgeNumber(source[key]);
    if (n !== null) out[name] = n;
  });
  const offset = cylBadgePoint(source.centerOffset); if (offset) out.centerOffset = offset;
  const animation = cylBadgeAnimationName(source.animation); if (animation) out.animation = animation;
  if (typeof source.respectsReduceMotion === 'boolean') out.respectsReduceMotion = source.respectsReduceMotion;
  return out;
}

/**
 * [EN] The badge text of a value: '' for a dot, null for no badge (null / undefined, or a number of 0 or below), the text
 *      otherwise; a number above `maximum` shows "<maximum>+".
 * [CN] 值对应的角标文字：红点为 ''，无角标为 null（null / undefined，或 0 及以下的数字），其余为文字；超过 `maximum` 的数字显示 "<maximum>+"。
 */
function cylBadgeText(value, maximum = 99) {
  if (value === null || value === undefined) return null;
  if (value === '') return '';
  const text = String(value);
  const number = cylBadgeNumber(value);
  if (number !== null && /^\s*-?\d+(\.\d+)?\s*$/.test(text)) {
    if (number <= 0) return null;
    if (number > maximum) return `${maximum}+`;
  }
  return text;
}

/**
 * [EN] What `cyl-badge` draws: whether it shows, dot or text, the animation class, and the inline style (color, text color,
 *      font size, border, size from the radius). The position is not here: the anchor places the badge (strategy S2, S4).
 * [CN] `cyl-badge` 绘制的内容：是否显示、红点还是文字、动画类，以及内联样式（颜色、文字颜色、字号、边框、由半径得到的尺寸）。位置不在这里：由锚点放置
 *      角标（策略 S2、S4）。
 */
function cylBadgeViewModel(value, attributes, options = {}) {
  const a = cylBadgeParseAttributes(attributes);
  const text = cylBadgeText(value, a.maximumNumber);
  const reduceMotion = options.reduceMotion === true && a.respectsReduceMotion !== false;
  const animation = !reduceMotion && CYL_BADGE_CSS_ANIMATIONS.includes(a.animation) ? a.animation : '';
  const shows = text !== null;
  const isDot = shows && text === '';
  const style = [];
  if (a.color) style.push(`background-color: ${a.color};`);
  if (a.textColor && !isDot) style.push(`color: ${a.textColor};`);
  if (a.fontSize && !isDot) style.push(`font-size: ${a.fontSize}px;`);
  if (a.borderWidth) style.push(`border: ${a.borderWidth}px solid ${a.borderColor || 'transparent'};`);
  if (a.radius) style.push(isDot ? `width: ${a.radius * 2}px; height: ${a.radius * 2}px;` : `min-width: ${a.radius * 2}px; height: ${a.radius * 2}px; border-radius: ${a.radius}px;`);
  const offset = a.centerOffset || { x: 0, y: 0 };
  return {
    showsBadge: shows,
    isDot,
    text: shows ? text : '',
    className: cylBadgeAnimationClass(animation, options.animationDisabled),
    style: style.join(' '),
    offset,
  };
}

module.exports = { CYL_BADGE_ANIMATION_NAMES, CYLBadgeAttributeKey, cylBadgeAnimationName, cylBadgeParseAttributes, cylBadgeText, cylBadgeViewModel };
