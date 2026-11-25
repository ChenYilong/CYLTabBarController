// [EN] Unit tests of the built-in colors and the state color resolution (tint spec v2, sections 1-3, 7): precedence item explicit > stack
//      explicit > built-in; the EFFECTIVE color vs the EXPLICIT one; the constants (iOS probe values) are pinned.
// [CN] 内置颜色与状态颜色解析的单元测试（着色规范 v2 第 1-3、7 节）：优先级 条目显式 > 堆叠显式 > 内置；生效颜色与显式颜色；常量（iOS 实测值）被固定。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const C = await import('../src/main/ets/CYLAnimatedItemColors.ts');

const input = (fields) => {
  const base = new C.CYLAnimatedItemStateColorInput();
  const item = { ...new C.CYLAnimatedItemStateColors(), ...(fields.item ?? {}) };
  const stack = { ...new C.CYLAnimatedItemStateColors(), ...(fields.stack ?? {}) };
  return { ...base, ...fields, item, stack };
};

test('built-ins: names of the SDK colors and the iOS probe constants, light and dark', () => {
  const b = (role, dark) => ({ ...C.cylAnimatedItemBuiltInColor(role, dark) });
  assert.deepEqual(b('normal', false), { resource: 'font_primary', color: '#FF000000' });
  assert.deepEqual(b('normal', true), { resource: 'font_primary', color: '#FFFFFFFF' });
  assert.deepEqual(b('selected', false), { resource: 'interactive_active', color: '#FF0088FF' });
  assert.deepEqual(b('selected', true), { resource: 'interactive_active', color: '#FF0091FF' });
  assert.deepEqual(b('disabled', false), { resource: '', color: '#73868686' }, '134,134,134 at 0.45');
  assert.deepEqual(b('disabled', true), { resource: '', color: '#598C8C8C' }, '140,140,140 at 0.35');
  assert.deepEqual(b('divider', false), { resource: 'font_secondary', color: '#993C3C43' }, '60,60,67 at 0.60');
  assert.deepEqual(b('divider', true), { resource: 'font_secondary', color: '#99EBEBF5' }, '235,235,245 at 0.60');
  assert.deepEqual(b('whatever', false), b('normal', false), 'unknown role = normal');
});

test('state color: item explicit > stack explicit > built-in, per state, each property on its own', () => {
  const R = (fields) => ({ ...C.cylAnimatedItemResolveStateColor(input(fields)) });
  const E = (fields) => C.cylAnimatedItemExplicitStateColor(input(fields));
  // nothing set: explicit '' and the built-in of the state
  assert.equal(E({}), '');
  assert.equal(R({}).builtIn.resource, 'font_primary');
  assert.equal(R({ selected: true }).builtIn.resource, 'interactive_active', 'selecting changes the color even with nothing set');
  assert.equal(R({ enabled: false }).builtIn.color, '#73868686');
  assert.equal(R({ enabled: false, dark: true }).builtIn.color, '#598C8C8C');
  assert.equal(R({ enabled: false, selected: true }).builtIn.color, '#73868686', 'disabled wins over selected');
  // stack only, then item wins
  assert.equal(E({ stack: { normal: '#111111' } }), '#111111');
  assert.equal(E({ stack: { normal: '#111111' }, item: { normal: '#222222' } }), '#222222');
  assert.equal(E({ stack: { normal: '#111111' }, item: { normal: '  ' } }), '#111111', 'blank = not set');
  // selected: only the selected property counts, never the normal one
  assert.equal(E({ selected: true, item: { normal: '#222222' } }), '', 'only a normal color: selected has none, so it is the built-in selected');
  assert.equal(E({ selected: true, item: { normal: '#222222', selected: '#333333' } }), '#333333');
  assert.equal(E({ selected: true, stack: { selected: '#444444' }, item: { normal: '#222222' } }), '#444444');
  // disabled: only the disabled property
  assert.equal(E({ enabled: false, item: { normal: '#222222' } }), '');
  assert.equal(E({ enabled: false, item: { disabled: '#555555' } }), '#555555');
  assert.equal(E({ enabled: false, selected: true, stack: { disabled: '#666666', selected: '#444444' } }), '#666666');
  // the source the view uses to pick its own ResourceColor
  const S = (fields) => C.cylAnimatedItemStateColorSource(input(fields));
  assert.equal(S({}), 'builtIn');
  assert.equal(S({ stack: { normal: 'x' } }), 'stack');
  assert.equal(S({ stack: { normal: 'x' }, item: { normal: 'y' } }), 'item');
});

test('the built-in divider and an explicit icon color: alpha 0.6 and the constant', () => {
  assert.equal(C.CYL_ANIMATED_ITEM_DIVIDER_ALPHA, 0.6);
  const d = (fields) => ({ ...C.cylAnimatedItemDividerColor({ ...new C.CYLAnimatedItemDividerInput(), ...fields }) });
  assert.equal(d({ iconColor: '#102030' }).color, '#99102030');
  assert.equal(d({ iconColor: '#80102030' }).color, '#99102030', 'the alpha replaces the color\'s own');
  assert.equal(d({}).resource, 'font_secondary');
});

test('contrast helper: black on white is 21:1, same color 1:1', () => {
  assert.ok(Math.abs(C.cylAnimatedItemContrast('#000000', '#FFFFFF') - 21) < 1e-9);
  assert.ok(Math.abs(C.cylAnimatedItemContrast('#FFFFFF', '#FFFFFF') - 1) < 1e-9);
  assert.equal(C.cylAnimatedItemContrast('red', '#FFFFFF'), 0);
});

test('stack: item defaults and the stack level of title / disabled / rendering mode', async () => {
  const M = await import('../src/main/ets/CYLAnimatedItemStackModel.ts');
  const item = new M.CYLAnimatedItemStackItem('a');
  assert.equal(item.titleColor, '');
  assert.equal(item.selectedTitleColor, '');
  assert.equal(item.disabledIconColor, '');
  assert.equal(item.animationRenderingMode, 'automatic');
  const stack = new M.CYLAnimatedItemStackModel();
  assert.equal(stack.animationRenderingMode, 'automatic');
  stack.animationRenderingMode = 'alwaysOriginal';
  assert.equal(stack.animationRenderingMode, 'alwaysOriginal');
  stack.animationRenderingMode = 'nonsense';
  assert.equal(stack.animationRenderingMode, 'automatic');
  stack.titleColor = '#123456';
  stack.selectedTitleColor = '#654321';
  stack.disabledIconColor = '#777777';
  assert.deepEqual([stack.titleColor, stack.selectedTitleColor, stack.disabledIconColor], ['#123456', '#654321', '#777777']);
});
