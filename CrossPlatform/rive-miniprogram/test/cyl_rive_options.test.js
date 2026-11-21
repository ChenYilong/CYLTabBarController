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
