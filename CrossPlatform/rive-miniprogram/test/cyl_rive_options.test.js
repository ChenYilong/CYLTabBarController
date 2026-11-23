/**
 * [EN] Tests of the cyl-rive options helper (pure functions, no mini program runtime).
 * [CN] cyl-rive 选项辅助函数的测试（纯函数，不需要小程序运行时）。
 */
const test = require('node:test')
const assert = require('node:assert')
const { cylRiveRoute, cylRiveOptions, cylRiveColor } = require('../miniprogram_dist/cyl-rive/cyl_rive_options')

test('the fragment of CYLTabBarAnimationURLWithOptions() gives artboard, state machine and input', () => {
  const route = '/shared/rive/icons.riv.bin#artboard=CHAT&stateMachine=CHAT_Interactivity&input=active&unknown=1'
  assert.deepEqual(cylRiveRoute(route), {
    path: '/shared/rive/icons.riv.bin',
    options: { artboard: 'CHAT', stateMachine: 'CHAT_Interactivity', input: 'active' },
  })
  assert.deepEqual(cylRiveRoute('a.riv'), { path: 'a.riv', options: {} })
})

test('component properties win over the fragment; duration defaults to 1 and is clamped to 0...60', () => {
  const { path, options } = cylRiveOptions('a.riv#artboard=A&duration=5', { artboard: 'B', input: '' })
  assert.equal(path, 'a.riv')
  assert.equal(options.artboard, 'B')
  assert.equal(options.input, undefined)
  assert.equal(options.duration, 5)
  assert.equal(cylRiveOptions('a.riv', {}).options.duration, 1)
  assert.equal(cylRiveOptions('a.riv#duration=600', {}).options.duration, 60)
  assert.equal(cylRiveOptions('a.riv#duration=-1', {}).options.duration, 0)
  assert.equal(cylRiveOptions('a.riv#duration=x', {}).options.duration, 1)
})

test('colors become Rive ARGB integers', () => {
  assert.equal(cylRiveColor('#FF0000'), 0xFFFF0000)
  assert.equal(cylRiveColor('00FF0080'), 0x8000FF00)
  assert.equal(cylRiveColor('red'), null)
})

/*
 * [EN] The shared vectors every platform's parser reads (`CrossPlatform/animated-item-fixtures/source-options.json`): the path
 *      is the vector's file, the options are the vector's options that cyl-rive reads (`CYL_RIVE_OPTION_NAMES`). Inline JSON
 *      vectors are Lottie and not a route.
 * [CN] 各平台解析器共同读取的测试向量（`CrossPlatform/animated-item-fixtures/source-options.json`）：路径即向量的 file，选项即向量中
 *      cyl-rive 读取的选项（`CYL_RIVE_OPTION_NAMES`）。内联 JSON 向量属于 Lottie，不是路径。
 */
const fs = require('node:fs')
const path = require('node:path')
const { CYL_RIVE_OPTION_NAMES } = require('../miniprogram_dist/cyl-rive/cyl_rive_options')

const fixture = JSON.parse(fs.readFileSync(path.join(__dirname, '../../animated-item-fixtures/source-options.json'), 'utf8'))

fixture.cases.filter((vector) => 'file' in vector).forEach((vector) => {
  test(`shared source vector: ${vector.input.trim().slice(0, 60)}`, () => {
    const options = Object.fromEntries(Object.entries(vector.options).filter(([key]) => CYL_RIVE_OPTION_NAMES.includes(key)))
    assert.deepEqual(cylRiveRoute(vector.input), { path: vector.file, options })
  })
})

test('the shared rules: "?" before "#", undecodable text kept, an http query stays in the path, empty values dropped', () => {
  assert.deepEqual(cylRiveRoute('icons.riv?artboard=CHAT#input=active'), { path: 'icons.riv', options: { artboard: 'CHAT', input: 'active' } })
  assert.deepEqual(cylRiveRoute('a.riv#artboard=100%'), { path: 'a.riv', options: { artboard: '100%' } })
  assert.deepEqual(cylRiveRoute('https://x.cn/a.riv?token=1#artboard=A'), { path: 'https://x.cn/a.riv?token=1', options: { artboard: 'A' } })
  assert.deepEqual(cylRiveRoute('a.riv#input=&artboard=B&=x'), { path: 'a.riv', options: { artboard: 'B' } })
})

/*
 * [EN] Every `#` option of the shared vectors is accounted for: the ones cyl-rive reads arrive in `cylRiveOptions` (also with
 *      the component's other properties empty) with the vector's decoded value, and the rest belong to the item, not to cyl-rive
 *      (`tint` is applied by cyl-animated-item / the `tint` property), so no vector option is lost or invented.
 * [CN] 共享向量中的每个 `#` 选项都有归属：cyl-rive 读取的选项会以向量解码后的值出现在 `cylRiveOptions` 中（组件其他属性为空时也一样），
 *      其余属于条目而不属于 cyl-rive（`tint` 由 cyl-animated-item / `tint` 属性处理），因此没有选项丢失或凭空出现。
 */
const CYL_ITEM_OPTION_NAMES = ['tint']

fixture.cases.filter((vector) => 'file' in vector).forEach((vector) => {
  test(`full option set of shared vector: ${vector.input.trim().slice(0, 60)}`, () => {
    const names = Object.keys(vector.options)
    names.forEach((name) => assert.ok(CYL_RIVE_OPTION_NAMES.includes(name) || CYL_ITEM_OPTION_NAMES.includes(name), `unowned option ${name}`))
    const { path: file, options } = cylRiveOptions(vector.input, { artboard: '', stateMachine: '', input: '' })
    assert.equal(file, vector.file)
    names.filter((name) => CYL_RIVE_OPTION_NAMES.includes(name)).forEach((name) => assert.equal(options[name], vector.options[name]))
    assert.deepEqual(Object.keys(options).filter((name) => name !== 'duration').sort(), names.filter((name) => CYL_RIVE_OPTION_NAMES.includes(name)).sort())
    assert.equal(options.duration, 1, 'the default duration')
  })
})

test('the shared vectors exercise artboard, stateMachine, input and tint at least once, with percent decoding and a "#" inside a value', () => {
  const seen = new Set(fixture.cases.flatMap((vector) => Object.keys(vector.options)))
  ;['artboard', 'stateMachine', 'input', 'tint'].forEach((name) => assert.ok(seen.has(name), name))
  assert.ok(fixture.cases.some((vector) => Object.values(vector.options).includes('State Machine 1')), 'percent-decoded value')
  assert.ok(fixture.cases.some((vector) => vector.options.tint === '#FF0000'), 'a "#" after "="')
})
