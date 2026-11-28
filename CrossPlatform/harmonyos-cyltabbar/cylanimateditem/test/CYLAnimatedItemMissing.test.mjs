// [EN] Unit tests of CYLAnimatedItemMissing.ts (the reasons and the once-per-resource reporter of
//      `onResourceMissing` / `CYLAnimatedItemEngines.resourceMissingListener`). Node 22.18+:
//      node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemMissing.ts（`onResourceMissing` / `CYLAnimatedItemEngines.resourceMissingListener` 的原因与按资源只报告一次的报告器）的单元测试。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const M = await import('../src/main/ets/CYLAnimatedItemMissing.ts');

test('the four reasons are the strings every platform uses', () => {
  assert.equal(M.CYL_RESOURCE_NOT_FOUND, 'not found');
  assert.equal(M.CYL_RESOURCE_UNREADABLE, 'unreadable');
  assert.equal(M.CYL_RESOURCE_DECODE_FAILED, 'decode failed');
  assert.equal(M.CYL_RESOURCE_ENGINE_LIBRARY_MISSING, 'engine library missing');
});

test('the resource is the file as configured, without the # options', () => {
  assert.equal(M.cylAnimatedItemResourceOf('icons.riv#artboard=CHAT&input=active'), 'icons.riv');
  assert.equal(M.cylAnimatedItemResourceOf('home.pag'), 'home.pag');
  assert.equal(M.cylAnimatedItemResourceOf('https://example.com/a.json'), 'https://example.com/a.json');
  assert.equal(M.cylAnimatedItemResourceOf(''), '');
});

test('the reporter calls the item callback and the global listener once per resource', () => {
  const heard = [];
  const global = [];
  const reporter = new M.CYLAnimatedItemMissingReporter();
  const callback = (resource, reason) => heard.push([resource, reason]);
  const listener = (resource, reason) => global.push([resource, reason]);
  assert.equal(reporter.report('home.pag', 'not found', callback, listener), true);
  assert.equal(reporter.report('home.pag', 'decode failed', callback, listener), false, 'the same resource is reported once');
  assert.equal(reporter.report('other.pag', 'engine library missing', callback, listener), true);
  assert.deepEqual(heard, [['home.pag', 'not found'], ['other.pag', 'engine library missing']]);
  assert.deepEqual(global, heard);
  assert.equal(new M.CYLAnimatedItemMissingReporter().report('home.pag', 'not found', callback, listener), true, 'another item reports it again');
});

test('a throwing callback does not stop the listener, and no callback is fine', () => {
  const global = [];
  const reporter = new M.CYLAnimatedItemMissingReporter();
  assert.equal(reporter.report('a.gif', 'not found', () => { throw new Error('boom'); }, (r, why) => global.push([r, why])), true);
  assert.deepEqual(global, [['a.gif', 'not found']]);
  assert.equal(reporter.report('b.gif', 'not found'), true);
  assert.equal(reporter.report('', 'not found', () => assert.fail('an empty resource is not reported')), false);
});
