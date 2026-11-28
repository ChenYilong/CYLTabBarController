// [EN] The pure badge style parser of cylbadge (docs/Animated-Item-Badge-CrossPlatform.md, HarmonyOS phase 2): the iOS key names, the ten animation names, strings
//      and native values read, null and unknown types ignored, never a throw. Run by `node --test`; the ArkUI part (`CYLBadgeView`) is not covered.
// [CN] cylbadge 的纯角标样式解析器（docs/Animated-Item-Badge-CrossPlatform.md，鸿蒙阶段 2）：iOS 的键名、十个动画名、字符串与原生值被读取，
//      null 与未知类型被忽略，不会抛出异常。由 `node --test` 运行；ArkUI 部分（`CYLBadgeView`）不在覆盖范围内。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const P = await import('../src/main/ets/CYLBadgeAttributeParser.ts');

test('the keys are the iOS strings', () => {
  const K = P.CYLBadgeAttributeKey;
  assert.deepEqual(
    [K.value, K.color, K.animation, K.radius, K.centerOffset, K.textColor, K.font, K.borderColor, K.borderWidth, K.maximumNumber, K.respectsReduceMotion],
    ['value', 'color', 'animation', 'radius', 'centerOffset', 'textColor', 'font', 'borderColor', 'borderWidth', 'maximumNumber', 'respectsReduceMotion'],
  );
});

test('the animation: the ten names in any letter case, numbers 0 to 9, anything else is none', () => {
  const index = (value) => P.cylBadgeAnimationIndex({ animation: value });
  assert.equal(index('Scale'), 1);
  assert.equal(index('leftrightonce'), 5);
  assert.equal(index('SCALEONCE'), 9);
  assert.equal(index(9), 9);
  assert.equal(index(10), 0);
  assert.equal(index('spin'), 0);
  assert.equal(index({}), 0);
  assert.equal(P.cylBadgeAnimationIndex(undefined), 0);
});

test('strings and native values are read', () => {
  const parsed = P.cylParseBadgeAttributes({
    color: '#FF3B30', textColor: '#ffffff80', borderColor: ' #000000 ', centerOffset: '{4, -2}', radius: '5', font: 12, borderWidth: 2,
    maximumNumber: '9', respectsReduceMotion: false, animation: 'Shake',
  });
  assert.equal(parsed.color, '#FF3B30');
  assert.equal(parsed.textColor, '#ffffff80');
  assert.equal(parsed.borderColor, '#000000');
  assert.equal(parsed.centerOffsetX, 4);
  assert.equal(parsed.centerOffsetY, -2);
  assert.equal(parsed.radius, 5);
  assert.equal(parsed.fontSize, 12);
  assert.equal(parsed.borderWidth, 2);
  assert.equal(parsed.maximumNumber, 9);
  assert.equal(parsed.respectsReduceMotion, false);
  assert.equal(parsed.animationIndex, 2);
});

test('null, unknown keys and unknown types are ignored', () => {
  const parsed = P.cylParseBadgeAttributes({ color: 5, radius: {}, centerOffset: 'x', font: -3, maximumNumber: null, extra: 1, respectsReduceMotion: 'yes' });
  assert.equal(parsed.color, undefined);
  assert.equal(parsed.radius, undefined);
  assert.equal(parsed.centerOffsetX, undefined);
  assert.equal(parsed.fontSize, undefined);
  assert.equal(parsed.maximumNumber, undefined);
  assert.equal(parsed.respectsReduceMotion, undefined);
  assert.equal(parsed.animationIndex, 0);
  assert.deepEqual({ ...P.cylParseBadgeAttributes(undefined) }, { animationIndex: 0 });
});
