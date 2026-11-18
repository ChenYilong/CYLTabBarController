// [EN] Unit tests of CYLAnimatedItemStackModel, the rules of the HarmonyOS CYLAnimatedItemStackView (the same cases as
//      iOS CYLTabBarControllerTests/CYLAnimatedItemStackViewTests.m). Run with Node 22.18+ (type stripping):
//      node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemStackModel（鸿蒙 CYLAnimatedItemStackView 的规则）的单元测试，用例与 iOS CYLAnimatedItemStackViewTests.m 相同。
//      用 Node 22.18+（类型擦除）运行：node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  CYLAnimatedItemStackModel, CYLAnimatedItemStackItem, CYLAnimatedItemStackDefaultSpacing,
} from '../src/main/ets/CYLAnimatedItemStackModel.ts';

function recorder() {
  const performed = [];
  const handler = (stack, action) => performed.push(action);
  return { performed, handler };
}

test('items are arranged in order and the first is reserved', () => {
  const a = new CYLAnimatedItemStackItem('No results');
  const b = new CYLAnimatedItemStackItem('Try another word');
  const stack = new CYLAnimatedItemStackModel([a, b]);
  assert.deepEqual(stack.items, [a, b]);
  assert.equal(stack.firstItem, a);
  assert.equal(stack.spacingBeforeOf(a), 0, 'the first item has no space above it');
  assert.equal(stack.spacingBeforeOf(b), CYLAnimatedItemStackDefaultSpacing);
  assert.equal(stack.contentMargin, 16);
});

test('an empty stack has no first item', () => {
  const stack = new CYLAnimatedItemStackModel();
  assert.equal(stack.firstItem, undefined);
  assert.deepEqual(stack.items, []);
});

test('append ignores duplicates and sets the spacing', () => {
  const stack = new CYLAnimatedItemStackModel();
  const first = stack.appendItem('Title');
  const hint = stack.appendItem('Hint', '', '', undefined, 8);
  stack.append(first, 'retry', 40);
  assert.equal(stack.items.length, 2);
  assert.equal(stack.actionFor(first), undefined, 'a duplicate append changes nothing');
  assert.equal(stack.spacingBeforeOf(hint), 8);
  const negative = stack.appendItem('Below', '', '', undefined, -5);
  assert.equal(stack.spacingBeforeOf(negative), 0);
});

test('an item tap performs its action', () => {
  const { performed, handler } = recorder();
  const stack = new CYLAnimatedItemStackModel([], new Map([['retry', handler]]));
  stack.appendItem('Empty');
  const button = stack.appendItem('Retry', '', '', 'retry');
  assert.equal(stack.actionFor(button), 'retry');
  assert.equal(stack.itemFor('retry'), button);
  assert.equal(stack.itemFor('missing'), undefined);
  assert.equal(stack.tapItem(button), true);
  assert.deepEqual(performed, ['retry']);
});

test('an item without an action takes no taps', () => {
  const stack = new CYLAnimatedItemStackModel();
  stack.appendItem('Title');
  const hint = stack.appendItem('Hint');
  assert.equal(stack.takesTaps(hint), false);
  assert.equal(stack.tapItem(hint), false);
  stack.setAction('open', hint);
  assert.equal(stack.takesTaps(hint), true);
  stack.setAction('', hint);
  assert.equal(stack.takesTaps(hint), false, "'' removes the action");
});

test('handlers can be set and removed', () => {
  const { performed, handler } = recorder();
  const stack = new CYLAnimatedItemStackModel();
  assert.equal(stack.performAction('retry'), false, 'no handler');
  stack.setHandler(handler, 'retry');
  assert.equal(stack.performAction('retry'), true);
  stack.setHandler(undefined, 'retry');
  assert.equal(stack.performAction('retry'), false);
  assert.deepEqual(performed, ['retry']);
});

test('the background action, and the first item reads as its button', () => {
  const { performed, handler } = recorder();
  const stack = new CYLAnimatedItemStackModel([], new Map([['reload', handler], ['retry', handler]]));
  const first = stack.appendItem('Nothing here');
  const button = stack.appendItem('Retry', '', '', 'retry');
  assert.equal(stack.tapBackground(), false, 'no background action yet');
  assert.equal(stack.readsAsButton(first), false);
  stack.backgroundAction = 'reload';
  assert.equal(stack.tapBackground(), true);
  assert.equal(stack.actsOnBackground(first), true);
  assert.equal(stack.readsAsButton(first), true);
  assert.equal(stack.takesTaps(first), true);
  assert.equal(stack.tapItem(first), true, "the first item's tap is the background's");
  assert.equal(stack.actsOnBackground(button), false, 'an item with its own action keeps it');
  stack.tapItem(button);
  assert.deepEqual(performed, ['reload', 'reload', 'retry']);
  stack.backgroundAction = '';
  assert.equal(stack.backgroundAction, undefined, "'' turns it off");
  assert.equal(stack.readsAsButton(first), false);
});

test('roles survive a title change', () => {
  const stack = new CYLAnimatedItemStackModel();
  const button = stack.appendItem('Retry', '', '', 'retry');
  button.title = 'Try again';
  stack.update();
  assert.equal(stack.readsAsButton(button), true);
  assert.equal(stack.accessibilityTextOf(button), 'Try again');
  button.accessibilityText = 'Retry the search';
  assert.equal(stack.accessibilityTextOf(button), 'Retry the search');
});

test('a decorative item is hidden from the screen reader', () => {
  const stack = new CYLAnimatedItemStackModel();
  stack.appendItem('Title');
  const separator = stack.appendItem('', 'separator.png');
  assert.equal(stack.isAccessibilityHidden(separator), true);
  separator.accessibilityText = 'Section';
  assert.equal(stack.isAccessibilityHidden(separator), false, 'a label makes it readable');
  separator.accessibilityText = '';
  stack.setAction('more', separator);
  assert.equal(stack.isAccessibilityHidden(separator), false, 'an action makes it readable');
});

test('removing an item moves the reserved role', () => {
  const stack = new CYLAnimatedItemStackModel();
  const first = stack.appendItem('Title', '', '', 'open');
  const second = stack.appendItem('Hint');
  stack.backgroundAction = 'reload';
  assert.equal(stack.actsOnBackground(second), false);
  stack.remove(first);
  assert.equal(stack.firstItem, second);
  assert.equal(stack.actsOnBackground(second), true);
  assert.equal(stack.actionFor(first), undefined, 'a removed item has no action');
  assert.equal(stack.spacingBeforeOf(second), 0);
  stack.remove(first);
  assert.equal(stack.items.length, 1, 'removing twice is harmless');
});

test('a long title wraps to the view width', () => {
  const stack = new CYLAnimatedItemStackModel();
  const item = stack.appendItem('A long title that needs more than one line on a phone');
  assert.equal(item.titleLines, 0, 'no line limit by default');
  assert.equal(stack.maxItemWidth(360), 328);
  stack.contentMargin = 24;
  assert.equal(stack.maxItemWidth(360), 312);
  stack.contentMargin = -4;
  assert.equal(stack.contentMargin, 0, 'never negative');
  assert.equal(stack.maxItemWidth(0), 0);
});

test('every change tells the listeners', () => {
  const stack = new CYLAnimatedItemStackModel();
  let calls = 0;
  const listener = () => { calls += 1; };
  stack.addListener(listener);
  const item = stack.appendItem('A');
  stack.setAction('go', item);
  stack.backgroundAction = 'bg';
  stack.remove(item);
  assert.equal(calls, 4);
  stack.removeListener(listener);
  stack.appendItem('B');
  assert.equal(calls, 4);
});
