// [EN] Unit tests of CYLAnimatedItemSource.ts (values, options, rawfile names). Node 22.18+:
//      node --test CrossPlatform/harmonyos-cyltabbar/cylanimateditem/test/*.test.mjs
// [CN] CYLAnimatedItemSource.ts 的单元测试（值、选项、rawfile 名称）。
import './cyl-ts-import.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const { CYLAnimatedItemSource: S, cylAnimatedItemFileAndOptions } = await import('../src/main/ets/CYLAnimatedItemSource.ts');

test('a rawfile path with "#" options, decoded, and its type', () => {
  const s = S.parse('asset:Rive/house.riv#stateMachine=State%20Machine%201&input=active');
  assert.equal(s.path, 'Rive/house.riv');
  assert.equal(s.type, 'Rive');
  assert.equal(s.option('stateMachine'), 'State Machine 1');
  assert.equal(s.option('input'), 'active');
  assert.equal(s.directory, 'Rive/');
  assert.equal(s.fileName, 'house.riv');
});

test('"?" (the earlier HarmonyOS form), a second group after "#", and a color inside a value', () => {
  const [file, options] = cylAnimatedItemFileAndOptions('rive/icons.riv?artboard=CHAT#input=active&tint=#FF0000');
  assert.equal(file, 'rive/icons.riv');
  assert.equal(options.get('artboard'), 'CHAT');
  assert.equal(options.get('input'), 'active');
  assert.equal(options.get('tint'), '#FF0000');
});

test('inline Lottie JSON and a plain path without options', () => {
  const inline = S.parse(' {"v":"5.7.4"} ');
  assert.equal(inline.inlineJSON, '{"v":"5.7.4"}');
  assert.equal(inline.type, 'Lottie');
  assert.equal(inline.path, '');
  const plain = S.parse('lottie/home.json');
  assert.equal(plain.path, 'lottie/home.json');
  assert.equal(plain.options.size, 0);
  assert.equal(S.parse('svga/a.svga?tint=title').type, 'SVGA');
  assert.equal(S.parse('a.gif').type, 'GIF');
  assert.equal(S.parse('a.pag').type, 'PAG');
});

test('rawfile names: the path, then its last component', () => {
  const files = new Map([['house.riv', new Uint8Array([1, 2])]]);
  const reader = {
    getRawFileContentSync: (name) => { if (!files.has(name)) { throw new Error('none'); } return files.get(name); },
    getRawFdSync: (name) => { if (!files.has(name)) { throw new Error('none'); } return {}; },
    closeRawFdSync: () => {}
  };
  const s = S.parse('asset:assets/house.riv');
  assert.deepEqual(s.rawFileCandidates, ['assets/house.riv', 'house.riv']);
  assert.deepEqual([...s.rawFileContent(reader)], [1, 2]);
  assert.equal(s.existingRawFilePath(reader), 'house.riv');
  assert.equal(S.parse('missing.riv').rawFileContent(reader), undefined);
  assert.equal(S.parse('missing.riv').existingRawFilePath(reader), 'missing.riv');
});
