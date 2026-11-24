/**
 * [EN] The teardown row of the example Home list (example/miniprogram/utils/cyl_demo_teardown.js; iOS CYLDemoReleaseRow): the real
 *      cyl-dealloc-block-executor port runs the armed callbacks when a bar is torn down, the countdown takes 3 s, and the summary and
 *      status lines use the example's strings. Run: `npm test`.
 * [CN] 示例首页列表的销毁行（example/miniprogram/utils/cyl_demo_teardown.js；对应 iOS 的 CYLDemoReleaseRow）：真实的
 *      cyl-dealloc-block-executor 移植在 TabBar 被销毁时运行已登记的回调，倒计时为 3 秒，摘要与状态行使用示例的字符串。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const { LifecycleController } = require('../src/cyl-dealloc-block-executor/index')

function fakeBar() {
  const bar = {}
  bar.cylLifecycle = new LifecycleController(bar)
  bar.cylLifecycle.onLoad()
  return bar
}

function teardown() {
  global.wx = { getAppBaseInfo: () => ({ language: 'en' }), getSystemInfoSync: () => ({ language: 'en' }) }
  const file = require.resolve('../example/miniprogram/utils/cyl_demo_teardown')
  delete require.cache[file]
  return require(file)
}

test('the armed dealloc callbacks run once when the bars are detached, and the summary counts them', () => {
  const demo = teardown()
  const bars = [fakeBar(), fakeBar()]
  assert.equal(demo.cylArm(bars[0], 'pages/home/index'), true)
  assert.equal(demo.cylArm(bars[1], 'pages/me/index'), true)
  assert.equal(demo.cylSummary(), 'dealloc callbacks ran: 0 / 2')
  bars[0].cylLifecycle.onUnload()
  bars[0].cylLifecycle.onUnload()
  assert.equal(demo.cylRanCount(), 1, 'a bar runs its teardown blocks once')
  bars[1].cylLifecycle.onUnload()
  assert.equal(demo.cylSummary(), 'dealloc callbacks ran: 2 / 2 (pages/home/index, pages/me/index)')
})

test('a bar without a lifecycle, or one that is already detached, is not armed', () => {
  const demo = teardown()
  assert.equal(demo.cylArm(null, 'x'), false)
  assert.equal(demo.cylArm({}, 'x'), false)
  const bar = fakeBar()
  bar.cylLifecycle.onUnload()
  assert.equal(demo.cylArm(bar, 'x'), false)
  assert.equal(demo.cylArmedCount(), 0)
})

test('the countdown takes 3 s, ticks, releases once, and ignores a second start', (t) => {
  t.mock.timers.enable({ apis: ['setInterval'] })
  const demo = teardown()
  const ticks = []
  let released = 0
  const bars = [{ bar: fakeBar(), name: 'a' }]
  assert.equal(demo.cylStart(bars, () => ticks.push(demo.cylStatus()), () => { released += 1 }), true)
  assert.equal(demo.cylStart(bars, () => {}, () => {}), false, 'a running countdown is not restarted')
  t.mock.timers.tick(1000)
  t.mock.timers.tick(1000)
  assert.equal(released, 0)
  t.mock.timers.tick(1000)
  assert.equal(released, 1)
  assert.deepEqual(ticks, ['teardown: releasing in 3 s', 'teardown: releasing in 2 s', 'teardown: releasing in 1 s'])
  assert.equal(demo.cylStatus(), 'teardown: not run')
  t.mock.timers.tick(5000)
  assert.equal(released, 1)
})

test('nothing to arm: the countdown does not start', () => {
  const demo = teardown()
  assert.equal(demo.cylStart([{ bar: null, name: 'a' }], () => {}, () => {}), false)
  assert.equal(demo.cylRemaining(), 0)
})
