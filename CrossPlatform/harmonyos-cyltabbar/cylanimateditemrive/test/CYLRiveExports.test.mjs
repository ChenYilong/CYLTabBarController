// [EN] The export lists of both Rive modules and the option strings stay as released: cylanimateditem_rive only re-exports
//      cylanimateditemrive, and the option constants keep their strings. Node 22.18+.
// [CN] 两个 Rive 模块的导出列表与选项字符串保持发布时的样子：cylanimateditem_rive 只重新导出 cylanimateditemrive，选项常量的字符串不变。
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const read = (path) => readFileSync(new URL(path, import.meta.url), 'utf8');

test('cylanimateditem_rive exports the names it always exported, from cylanimateditemrive', () => {
  const index = read('../../cylanimateditem_rive/Index.ets');
  ['CYLAnimatedItemRive', 'CYLAnimatedItemRivePlayer', 'CYLAnimatedItemRiveView', 'cylRiveRendererType', 'cylRiveIsSupported',
    'cylEnsureRiveInitialized', 'CYLAnimatedItemRiveOption', 'cylRiveNextNumber', 'cylRiveUsesLegacyRuntime']
    .forEach((name) => assert.match(index, new RegExp(`\\b${name}\\b`), name));
  assert.match(index, /from 'cylanimateditemrive'/);
});

test('cylanimateditemrive keeps its export list', () => {
  const index = read('../Index.ets');
  ['CYLRiveIcon', 'CYLTabBarAnimationOptionRiveArtboard', 'CYLTabBarAnimationOptionRiveStateMachine',
    'CYLTabBarAnimationOptionRiveActiveProperty', 'CYLTabBarAnimationOptionRiveActiveDuration',
    'CYLTabBarAnimationOptionRiveTriggerProperty', 'CYLTabBarAnimationOptionRiveInput', 'CYLTabBarAnimationOptionRiveTriggerInput',
    'CYLTabBarAnimationOptionRiveAnimation', 'CYLTabBarAnimationOptionRiveLegacyRuntime', 'CYLTabBarAnimationOptionRiveNumberInput',
    'CYLTabBarAnimationOptionRiveNumberValues', 'CYLTabBarAnimationOptionRiveColor', 'cylRiveNextNumber', 'cylRiveFileAndOptions', 'cylRiveRendererType',
    'cylEnsureRiveInitialized', 'cylRiveIsSupported', 'CYLRiveLoopPolicy', 'CYLRiveAnimationBuilder', 'cylRegisterRiveEngine']
    .forEach((name) => assert.match(index, new RegExp(`\\b${name}\\b`), name));
});

test('the option constants keep their strings', () => {
  const source = read('../src/main/ets/CYLRiveIcon.ets');
  const expected = {
    Artboard: 'artboard', StateMachine: 'stateMachine', ActiveProperty: 'active', ActiveDuration: 'duration',
    TriggerProperty: 'trigger', Input: 'input', TriggerInput: 'triggerInput', Animation: 'animation', LegacyRuntime: 'legacy',
    NumberInput: 'numberInput', NumberValues: 'values', Color: 'color',
  };
  Object.entries(expected).forEach(([name, value]) => {
    assert.match(source, new RegExp(`CYLTabBarAnimationOptionRive${name}: string = '${value}'`), name);
  });
});

test('the thin module has no Rive logic of its own', () => {
  assert.equal(/src\/main\/ets/.test(read('../../cylanimateditem_rive/Index.ets')), false);
});
