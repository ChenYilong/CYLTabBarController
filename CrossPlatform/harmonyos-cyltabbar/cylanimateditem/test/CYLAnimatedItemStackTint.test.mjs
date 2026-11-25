// [EN] Unit tests of the divider color, the stack inheritance (effective = item ?? stack) and the host-row needs of the stack
//      (spec /tmp/xpr/stack-tint-spec.txt, A, B, C, E). Node: node --test test/*.test.mjs
// [CN] 分隔线颜色、堆叠继承（生效值 = 条目 ?? 堆叠）与堆叠对宿主行的支持的单元测试。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const C = await import('../src/main/ets/CYLAnimatedItemColors.ts');
const M = await import('../src/main/ets/CYLAnimatedItemStackModel.ts');

const divider = (fields) => ({ ...C.cylAnimatedItemDividerColor({ ...new C.CYLAnimatedItemDividerInput(), ...fields }) });

// [EN] Divider color, one row per case: dividerColor set / explicit icon color at alpha 0.6 / built-in (secondary label), light and dark.
// [CN] 分隔线颜色，每种情况一行。
const BUILTIN = (dark) => ({ source: 'builtin', color: dark ? '#99EBEBF5' : '#993C3C43', resource: 'font_secondary', opacity: 1 });
const DIVIDER_TABLE = [];
for (const dark of [false, true]) {
  DIVIDER_TABLE.push({ dark, dividerColor: '#FF8000', iconColor: '#112233', expect: { source: 'divider', color: '#FF8000', resource: '', opacity: 1 } });
  DIVIDER_TABLE.push({ dark, dividerColor: '#80FF8000', iconColor: '', expect: { source: 'divider', color: '#80FF8000', resource: '', opacity: 1 } });
  DIVIDER_TABLE.push({ dark, dividerColor: 'red', iconColor: '', expect: { source: 'divider', color: 'red', resource: '', opacity: 1 } });
  DIVIDER_TABLE.push({ dark, dividerColor: '', iconColor: '#112233', expect: { source: 'icon', color: '#99112233', resource: '', opacity: 1 } });
  DIVIDER_TABLE.push({ dark, dividerColor: '', iconColor: '#FF112233', expect: { source: 'icon', color: '#99112233', resource: '', opacity: 1 } });
  DIVIDER_TABLE.push({ dark, dividerColor: '', iconColor: '#ffaabbcc', expect: { source: 'icon', color: '#99AABBCC', resource: '', opacity: 1 } });
  DIVIDER_TABLE.push({ dark, dividerColor: '', iconColor: 'blue', expect: { source: 'icon', color: 'blue', resource: '', opacity: 0.6 } });
  DIVIDER_TABLE.push({ dark, dividerColor: '  ', iconColor: '', expect: BUILTIN(dark) });
}
for (const row of DIVIDER_TABLE) {
  test(`divider color ${JSON.stringify(row)}`, () => {
    assert.deepEqual(divider({ dark: row.dark, dividerColor: row.dividerColor, iconColor: row.iconColor }), row.expect);
  });
}

// [EN] Contrast, >= 3:1 on light and dark bars: the built-in constants (iOS secondaryLabel probe values) and the SDK colors the view draws
//      (sys.color.font_secondary, read from the SDK resource tables: light #99182431, dark #99FFFFFF). Bars: white / black, and the usual
//      system grays.
// [CN] 对比度，浅色与深色栏上 >= 3:1：内置常量（iOS secondaryLabel 实测值）与视图实际绘制的 SDK 颜色。
test('divider contrast >= 3:1 on light and dark bars (built-in constants and SDK colors)', () => {
  const rows = [
    ['#993C3C43', '#FFFFFF'], ['#993C3C43', '#F2F2F7'], ['#99EBEBF5', '#000000'], ['#99EBEBF5', '#1C1C1E'],
    ['#99182431', '#FFFFFF'], ['#99182431', '#F1F3F5'], ['#99FFFFFF', '#000000'], ['#A9FFFFFF', '#000000'], ['#99FFFFFF', '#1C1C1E']
  ];
  for (const [fg, bg] of rows) {
    const ratio = C.cylAnimatedItemContrast(fg, bg);
    assert.ok(ratio >= 3, `${fg} on ${bg} = ${ratio.toFixed(2)}`);
  }
  for (const dark of [false, true]) {
    const builtIn = divider({ dark });
    assert.ok(C.cylAnimatedItemContrast(builtIn.color, dark ? '#000000' : '#FFFFFF') >= 3, `built-in ${dark ? 'dark' : 'light'}`);
  }
  // [EN] The old default (separator 0.12 / 0.3 alpha) was the reason: 1.3:1. [CN] 旧的默认值（分隔色 0.12 / 透明度 0.3）仅 1.3:1，故改之。
  assert.ok(C.cylAnimatedItemContrast('#3D3C3C43', '#FFFFFF') < 3);
});

test('explicit icon color at alpha 0.6: contrast of black and white icon colors on their bars', () => {
  assert.ok(C.cylAnimatedItemContrast(divider({ iconColor: '#000000' }).color, '#FFFFFF') >= 3);
  assert.ok(C.cylAnimatedItemContrast(divider({ iconColor: '#FFFFFF' }).color, '#000000') >= 3);
});

test('constants', () => {
  assert.equal(C.CYL_ANIMATED_ITEM_DIVIDER_ALPHA, 0.6);
  assert.equal(C.CYL_ANIMATED_ITEM_DIVIDER_LENGTH, 20);
  assert.equal(M.CYLAnimatedItemDividerLength, 20);
  assert.equal(new M.CYLAnimatedItemStackModel().dividerLength, 20);
  assert.equal('isDivider' in new M.CYLAnimatedItemStackItem(), false, 'no divider item');
});

test('effective = own ?? inherited', () => {
  for (const [own, inherited, expected] of [['', '', ''], ['', '#111111', '#111111'], ['#222222', '#111111', '#222222'],
    ['  ', '#111111', '#111111'], ['bad', '#111111', 'bad'], ['title', '', 'title']]) {
    assert.equal(C.cylAnimatedItemEffective(own, inherited), expected, `${own}|${inherited}`);
  }
});

const tint = (stack, item, fields) => ({ ...C.cylAnimatedItemResolveTint({ ...new C.CYLAnimatedItemTintInput(),
  propTint: stack.animationTintOf(item), propDarkTint: stack.animationDarkTintOf(item), ...fields }) });

test('stack tint: stack only, item wins, appended later, cleared, appearance change', () => {
  const stack = new M.CYLAnimatedItemStackModel();
  const a = stack.appendItem('A');
  const b = stack.appendItem('B');
  // [EN] Nothing set: the file's own colors. [CN] 都未设置：文件自身颜色。
  assert.equal(tint(stack, a, {}).kind, 'none');
  // [EN] Stack only: every item, existing and appended later. [CN] 只设堆叠：所有条目，包括之后追加的。
  stack.animationTint = '#102030';
  stack.animationDarkTint = '#A0B0C0';
  const late = stack.appendItem('Late');
  for (const item of [a, b, late]) {
    assert.deepEqual(tint(stack, item, { dark: false }), { kind: 'fixed', color: '#FF102030' });
    // [EN] Appearance change: the dark tint applies. [CN] 外观变化：深色着色生效。
    assert.deepEqual(tint(stack, item, { dark: true }), { kind: 'fixed', color: '#FFA0B0C0' });
  }
  // [EN] The item's own value wins. [CN] 条目自己的值优先。
  b.animationTint = 'title';
  assert.deepEqual(tint(stack, b, {}), { kind: 'icon', color: '' }, '"title" always has an effective icon color (built-in at least)');
  assert.equal(tint(stack, a, {}).kind, 'fixed', 'the others still inherit');
  b.animationDarkTint = '#00FF00';
  assert.equal(stack.animationDarkTintOf(b), '#00FF00');
  // [EN] Clearing the stack value removes the inherited value from the items that set none; their own stay. [CN] 清除堆叠值：未设置者失去继承值，自有值保留。
  stack.animationTint = '';
  stack.animationDarkTint = '';
  assert.equal(tint(stack, a, { dark: true }).kind, 'none');
  assert.equal(tint(stack, late, {}).kind, 'none');
  assert.equal(stack.animationTintOf(b), 'title');
  // [EN] Clearing the item's own value inherits again. [CN] 清除条目自己的值后重新继承。
  stack.animationTint = '#102030';
  b.animationTint = '';
  assert.equal(stack.animationTintOf(b), '#102030');
});

test('stack setters notify (so the view redraws)', () => {
  const stack = new M.CYLAnimatedItemStackModel();
  let count = 0;
  stack.addListener(() => { count += 1; });
  stack.animationTint = '#000000';
  stack.animationDarkTint = '#FFFFFF';
  stack.dividerColor = '#808080';
  stack.dispatchesItemTaps = false;
  stack.hugsContent = true;
  stack.showsDividers = true;
  stack.dividerLength = 10;
  stack.setDividerAfter(stack.appendItem('a'), true);
  assert.equal(count, 9);
});

test('dispatchesItemTaps false: no item or background action runs, nothing takes touches', () => {
  const stack = new M.CYLAnimatedItemStackModel();
  const hit = [];
  stack.setHandler((s, action) => hit.push(action), 'x');
  stack.setHandler((s, action) => hit.push(action), 'bg');
  stack.backgroundAction = 'bg';
  const a = stack.appendItem('A', '', '', 'x');
  assert.equal(stack.dispatchesItemTaps, true);
  stack.tapItem(a);
  stack.tapBackground();
  assert.deepEqual(hit, ['x', 'bg']);
  stack.dispatchesItemTaps = false;
  assert.equal(stack.tapItem(a), false);
  assert.equal(stack.tapBackground(), false);
  assert.equal(stack.takesTaps(a), false);
  assert.equal(stack.readsAsButton(a), false);
  assert.deepEqual(hit, ['x', 'bg']);
  assert.equal(stack.performAction('x'), true, 'a host can still run an action by name');
});

test('host row: horizontal, contentMargin 0, spacing, spacingBefore, subclasses', () => {
  class Chip extends M.CYLAnimatedItemStackItem {
    constructor() { super('chip'); this.extra = 1; }
  }
  const stack = new M.CYLAnimatedItemStackModel();
  stack.axis = 'horizontal';
  stack.contentMargin = 0;
  stack.spacing = 4;
  assert.equal(stack.contentMargin, 0);
  assert.equal(new M.CYLAnimatedItemStackModel().contentMargin, 16, 'the default stays 16');
  assert.equal(stack.hugsContent, false);
  const a = stack.appendItem('A');
  const chip = new Chip();
  stack.append(chip, undefined, 10);
  const c = stack.appendItem('C');
  assert.equal(stack.items[1], chip);
  assert.deepEqual([a, chip, c].map((i) => stack.spacingBeforeOf(i)), [0, 10, 4]);
  assert.equal(stack.maxItemWidth(100), 100);
});

test('add, remove, reorder; hidden items leave no spacing', () => {
  const stack = new M.CYLAnimatedItemStackModel();
  stack.spacing = 6;
  const [a, b, c] = ['a', 'b', 'c'].map((t) => stack.appendItem(t));
  const d = new M.CYLAnimatedItemStackItem('d');
  stack.insert(d, 1);
  assert.deepEqual(stack.items.map((i) => i.title), ['a', 'd', 'b', 'c']);
  stack.move(c, 0);
  assert.deepEqual(stack.items.map((i) => i.title), ['c', 'a', 'd', 'b']);
  stack.insert(c, 99);
  assert.deepEqual(stack.items.map((i) => i.title), ['a', 'd', 'b', 'c'], 'inserting a member moves it');
  stack.remove(d);
  assert.deepEqual(stack.items.map((i) => i.title), ['a', 'b', 'c']);
  stack.setItems([c, a, d]);
  assert.deepEqual(stack.items.map((i) => i.title), ['c', 'a', 'd'], 'b left out is removed, d is new');
  // actions go with the items
  stack.setAction('go', a);
  stack.move(a, 2);
  assert.equal(stack.actionFor(a), 'go');
  stack.setItems([c, d]);
  assert.equal(stack.actionFor(a), undefined);
  // hidden: no spacing, the next visible one is first
  stack.setItems([a, b, c]);
  assert.deepEqual([a, b, c].map((i) => stack.spacingBeforeOf(i)), [0, 6, 6]);
  a.isHidden = true;
  assert.deepEqual([a, b, c].map((i) => stack.spacingBeforeOf(i)), [0, 0, 6]);
  assert.deepEqual(stack.visibleItems, [b, c]);
  assert.equal(stack.isAccessibilityHidden(a), true);
  b.isHidden = true;
  assert.deepEqual([a, b, c].map((i) => stack.spacingBeforeOf(i)), [0, 0, 0]);
  a.isHidden = false;
  b.isHidden = false;
  b.alpha = 0.3;
  assert.equal(stack.spacingBeforeOf(b), 6, 'a faded item keeps its place and spacing');
});

const names = (stack) => stack.elements.map((e) => (e.isDivider ? '|' : e.item.title)).join('');
function makeStack(titles) {
  const stack = new M.CYLAnimatedItemStackModel();
  stack.spacing = 6;
  return [stack, ...titles.map((t) => stack.appendItem(t))];
}

test('dividers: off by default; showsDividers puts one between every two visible items', () => {
  const [stack, a, b, c] = makeStack(['a', 'b', 'c']);
  assert.equal(stack.showsDividers, false);
  assert.equal(names(stack), 'abc');
  stack.showsDividers = true;
  assert.equal(names(stack), 'a|b|c', 'never before the first or after the last');
  assert.deepEqual(stack.items.map((i) => i.title), ['a', 'b', 'c'], 'the items list has no dividers');
  assert.equal(stack.elements.filter((e) => e.isDivider).length, 2);
  assert.equal(new Set(stack.elements.map((e) => e.key)).size, 5, 'keys are unique');
  // spacing: before the divider `spacing`, after it the next item's spacingBefore (a fallback, never added on top)
  b.spacingBefore = 40;
  assert.deepEqual([a, b, c].map((i) => stack.spacingBeforeOf(i)), [0, 40, 6]);
  assert.deepEqual(stack.elements.map((e) => e.spacingBefore), [0, 6, 40, 6, 6]);
  assert.equal(stack.dividerSpacingBefore, undefined);
  stack.showsDividers = false;
  assert.deepEqual([a, b, c].map((i) => stack.spacingBeforeOf(i)), [0, 40, 6], 'without dividers spacingBefore applies');
});

test('dividers: setDividerAfter on / off overrides the gap, undefined clears it', () => {
  const [stack, a, b, c] = makeStack(['a', 'b', 'c']);
  stack.setDividerAfter(b, true);
  assert.equal(names(stack), 'ab|c');
  assert.equal(stack.dividerAfter(b), true);
  assert.equal(stack.dividerAfter(a), false);
  stack.showsDividers = true;
  stack.setDividerAfter(a, false);
  assert.equal(names(stack), 'ab|c', 'false removes this gap only');
  assert.equal(stack.dividerAfter(a), false);
  stack.setDividerAfter(a, undefined);
  assert.equal(names(stack), 'a|b|c');
  stack.setDividerAfter(c, true);
  assert.equal(names(stack), 'a|b|c', 'nothing after the last item');
  assert.equal(stack.dividerAfter(c), true, 'the setting is kept, the divider is not drawn');
  assert.equal(stack.showsDividerAfter(c), false);
  stack.setDividerAfter(new M.CYLAnimatedItemStackItem('x'), true);
  assert.equal(names(stack), 'a|b|c', 'an item not in the stack is ignored');
});

test('dividers: hidden neighbours leave no divider or spacing', () => {
  const [stack, a, b, c, d] = makeStack(['a', 'b', 'c', 'd']);
  stack.showsDividers = true;
  b.isHidden = true;
  assert.equal(names(stack), 'a|c|d', 'one divider across the hidden item');
  assert.deepEqual([a, b, c, d].map((i) => stack.spacingBeforeOf(i)), [0, 0, 6, 6]);
  a.isHidden = true;
  assert.equal(names(stack), 'c|d', 'no divider before the first visible item');
  d.isHidden = true;
  assert.equal(names(stack), 'c', 'none after the last visible one');
  assert.deepEqual(stack.elements.length, 1);
  b.isHidden = false;
  stack.setDividerAfter(b, false);
  assert.equal(names(stack), 'bc');
  c.isHidden = true;
  assert.equal(names(stack), 'b');
  // a faded item is still visible
  c.isHidden = false;
  c.alpha = 0.2;
  stack.setDividerAfter(b, undefined);
  assert.equal(names(stack), 'b|c');
});

test('dividers follow append, remove and reorder by themselves', () => {
  const [stack, a, b, c] = makeStack(['a', 'b', 'c']);
  stack.showsDividers = true;
  stack.setDividerAfter(a, false);
  assert.equal(names(stack), 'ab|c');
  stack.appendItem('d');
  assert.equal(names(stack), 'ab|c|d');
  stack.remove(b);
  assert.equal(names(stack), 'ac|d', 'the override of a stays with a');
  stack.remove(c);
  assert.equal(names(stack), 'ad');
  stack.setDividerAfter(a, undefined);
  assert.equal(names(stack), 'a|d');
  stack.move(a, 1);
  assert.equal(names(stack), 'd|a', 'the divider follows the new order');
  stack.setDividerAfter(stack.items[0], false);
  assert.equal(names(stack), 'da');
  stack.setItems([a]);
  assert.equal(names(stack), 'a');
  stack.setItems([a, b]);
  assert.equal(names(stack), 'a|b', 'b came back without its old override');
});

test('stack divider color: derived from the stack icon color at 0.6, else built-in, light and dark', () => {
  const stack = new M.CYLAnimatedItemStackModel();
  const color = (dark) => divider({ dividerColor: stack.dividerColor, iconColor: stack.iconColor, dark });
  for (const dark of [false, true]) {
    assert.deepEqual(color(dark), BUILTIN(dark));
  }
  stack.iconColor = '#112233';
  for (const dark of [false, true]) {
    assert.deepEqual(color(dark), { source: 'icon', color: '#99112233', resource: '', opacity: 1 });
  }
  stack.dividerColor = '#FF8000';
  for (const dark of [false, true]) {
    assert.deepEqual(color(dark), { source: 'divider', color: '#FF8000', resource: '', opacity: 1 });
  }
  stack.dividerColor = '';
  stack.iconColor = '';
  assert.equal(color(true).source, 'builtin', 'clearing both falls back again');
});

test('dividerLength: default 20, never negative', () => {
  const stack = new M.CYLAnimatedItemStackModel();
  assert.equal(stack.dividerLength, 20);
  stack.dividerLength = 12;
  assert.equal(stack.dividerLength, 12);
  stack.dividerLength = -3;
  assert.equal(stack.dividerLength, 0);
});

// [EN] The gap math (ADDENDUM 3, G3), one row each: before = own ?? stack ?? spacing; after = own ?? stack ?? next.spacingBefore ?? spacing;
//      gap = before + 1 + after; no divider: next.spacingBefore ?? spacing.
// [CN] 间隙计算，每行一例。
const GAP_ROWS = [
  { name: 'worked example: spacing 12, divider(8, 8)', spacing: 12, next: -1, divider: [8, 8], stack: [undefined, undefined], gap: 17, spacings: [8, 8] },
  { name: 'nothing set: spacing both sides', spacing: 12, next: -1, divider: [undefined, undefined], stack: [undefined, undefined], gap: 25, spacings: [12, 12] },
  { name: 'after falls back to the next item spacingBefore', spacing: 12, next: 5, divider: [undefined, undefined], stack: [undefined, undefined], gap: 18, spacings: [12, 5] },
  { name: 'stack defaults', spacing: 12, next: 5, divider: [undefined, undefined], stack: [3, 4], gap: 8, spacings: [3, 4] },
  { name: 'own values win over the stack defaults', spacing: 12, next: 5, divider: [8, undefined], stack: [3, 4], gap: 13, spacings: [8, 4] },
  { name: 'own after wins over stack and next', spacing: 12, next: 5, divider: [undefined, 0], stack: [3, 4], gap: 4, spacings: [3, 0] },
  { name: 'zero is a value, not unset', spacing: 12, next: 5, divider: [0, 0], stack: [3, 4], gap: 1, spacings: [0, 0] },
];
for (const row of GAP_ROWS) {
  test(`gap math: ${row.name}`, () => {
    const [stack, a, b] = makeStack(['a', 'b']);
    stack.spacing = row.spacing;
    b.spacingBefore = row.next;
    stack.dividerSpacingBefore = row.stack[0];
    stack.dividerSpacingAfter = row.stack[1];
    stack.setDivider(a, row.divider[0], row.divider[1]);
    assert.equal(stack.gapAfter(a), row.gap);
    assert.deepEqual(stack.elements.map((e) => e.spacingBefore), [0, row.spacings[0], row.spacings[1]]);
  });
}

test('gap math: no divider; thickness is 1; no gap after the last or a hidden item', () => {
  const [stack, a, b] = makeStack(['a', 'b']);
  assert.equal(stack.gapAfter(a), 6);
  b.spacingBefore = 9;
  assert.equal(stack.gapAfter(a), 9);
  assert.equal(stack.gapAfter(b), undefined);
  stack.setDivider(a, 8, 8);
  stack.spacing = 12;
  assert.equal(stack.gapAfter(a), 17, 'not 12 + 8 + 1 + 8 + 12');
  b.isHidden = true;
  assert.equal(stack.gapAfter(a), undefined);
  a.isHidden = true;
  b.isHidden = false;
  assert.equal(stack.gapAfter(a), undefined);
});

test('appendDivider: no-op on an empty stack; attaches to the current last item (append flow)', () => {
  const stack = new M.CYLAnimatedItemStackModel();
  let count = 0;
  stack.addListener(() => { count += 1; });
  stack.appendDivider(8, 8);
  assert.equal(count, 0);
  assert.equal(stack.elements.length, 0);
  const camera = stack.appendItem('camera');
  stack.appendDivider(8, 8);
  const search = stack.appendItem('search');
  assert.equal(stack.hasDivider(camera), true);
  assert.equal(stack.hasDivider(search), false);
  assert.equal(names(stack), 'camera|search');
  assert.equal(stack.gapAfter(camera), 17);
  stack.appendDivider();
  assert.equal(stack.hasDivider(search), true);
  assert.equal(names(stack), 'camera|search', 'nothing after the last visible item yet');
  const more = stack.appendItem('more');
  assert.equal(names(stack), 'camera|search|more');
  assert.equal(stack.gapAfter(search), 16 + 1 + 16, 'default spacing 16');
  assert.ok(more);
});

test('removeDivider turns one gap off even with showsDividers; hasDivider; setDivider replaces', () => {
  const [stack, a, b, c] = makeStack(['a', 'b', 'c']);
  stack.showsDividers = true;
  assert.equal(stack.hasDivider(a), true);
  stack.removeDivider(a);
  assert.equal(stack.hasDivider(a), false);
  assert.equal(names(stack), 'ab|c');
  stack.setDivider(a, 2, 3);
  assert.equal(stack.gapAfter(a), 6);
  stack.setDivider(b, 1);
  assert.equal(stack.gapAfter(b), 1 + 1 + 6);
  stack.removeDivider(new M.CYLAnimatedItemStackItem('x'));
  stack.setDividerAfter(a, undefined);
  assert.equal(stack.hasDivider(a), true, 'forgetting the own setting: showsDividers decides');
  assert.ok(c);
});

test('the divider moves with its owner and is deleted with it', () => {
  const [stack, a, b, c] = makeStack(['a', 'b', 'c']);
  stack.setDivider(a, 8, 8);
  assert.equal(names(stack), 'a|bc');
  stack.move(a, 2);
  assert.equal(names(stack), 'bca', 'last now: no divider drawn');
  stack.move(a, 0);
  assert.equal(names(stack), 'a|bc');
  stack.setItems([b, a, c]);
  assert.equal(names(stack), 'ba|c');
  assert.equal(stack.gapAfter(a), 17);
  stack.remove(a);
  stack.insert(a, 0);
  assert.equal(stack.hasDivider(a), false, 'removed with its owner');
  assert.equal(names(stack), 'abc');
  assert.ok(c);
});

test('hidden owner and hidden next item; accessibility', () => {
  const [stack, a, b, c] = makeStack(['a', 'b', 'c']);
  stack.setDivider(a, 8, 8);
  stack.setDivider(b, 8, 8);
  assert.equal(names(stack), 'a|b|c');
  a.isHidden = true;
  assert.equal(names(stack), 'b|c', 'hidden owner: no divider');
  a.isHidden = false;
  b.isHidden = true;
  assert.equal(names(stack), 'a|c', 'a divider shows across the hidden next item to the next visible one');
  assert.equal(stack.gapAfter(a), 17);
  c.isHidden = true;
  assert.equal(names(stack), 'a', 'no later visible item: no divider');
  stack.items.forEach((item) => assert.equal(stack.takesTaps(item), false));
  assert.ok(stack.elements.filter((e) => e.isDivider).every((e) => e.item !== undefined));
});
