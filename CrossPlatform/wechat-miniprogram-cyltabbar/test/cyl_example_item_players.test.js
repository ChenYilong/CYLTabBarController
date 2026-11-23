/**
 * [EN] The example's playback controls (example/miniprogram/utils/cyl_item_players.js): Play all, Restart, speed and loop go
 *      through `cyl_player()` of each tab icon, with fake players on a fake tab bar. Run: `npm test`.
 * [CN] 示例的播放控件（example/miniprogram/utils/cyl_item_players.js）：全部播放、重新播放、速度与循环都通过每个 Tab 图标的
 *      `cyl_player()`，在伪造的 TabBar 上使用伪造的播放器。运行：`npm test`。
 */
const test = require('node:test')
const assert = require('node:assert/strict')
const { CYLAnimatedItemPlayer } = require('../src/cyl-animated-item/cyl_animated_item_player')
const { cylItemPlayers, cylPlayAll, cylRestartSelected, cylSetSpeed, cylSetLoops } = require('../example/miniprogram/utils/cyl_item_players')

/** A player over a recording host: `type` picks the capabilities (a GIF image has loops but no speed). */
function fakePlayer(type, log, name) {
  const state = { speed: 1, loop: false }
  return new CYLAnimatedItemPlayer({
    engine: () => null,
    type: () => type,
    usesLoop: () => type !== '',
    isPlaying: () => false,
    get: (key) => state[key],
    set: (patch) => { Object.assign(state, patch); log.push([name, 'set', patch]) },
    play: () => log.push([name, 'play']),
    stopAtProgress: () => {},
  })
}

function fakeTabBar(specs, log) {
  const icons = {}
  const slots = specs.map(({ key, type, selected, item = true }) => {
    if (type !== undefined) {
      icons[key] = { data: { selected }, cyl_player: (() => { const p = fakePlayer(type, log, key); return () => p })() }
    }
    return { key, item }
  })
  const items = Object.fromEntries(Object.keys(icons).map((key) => [`#cyl-item-${key}`, { selectComponent: (id) => (id === '#cyl-item-icon' ? icons[key] : null) }]))
  return { data: { cylSlots: slots }, selectComponent: (id) => items[id] || null }
}

const specs = [
  { key: 'home', type: 'lottie', selected: true },
  { key: 'gif', type: 'gif', selected: false },
  { key: 'plus', item: false },
  { key: 'bare' },
  { key: 'me', type: 'rive', selected: false },
]

test('the players are those of the items with an animated icon, in tab order', () => {
  const entries = cylItemPlayers(fakeTabBar(specs, []))
  assert.deepEqual(entries.map((e) => e.key), ['home', 'gif', 'me'])
  assert.deepEqual(entries.map((e) => e.selected), [true, false, false])
  assert.deepEqual(cylItemPlayers(null), [])
})

test('Play all plays every icon through its player; Restart plays the selected one', () => {
  const log = []
  const bar = fakeTabBar(specs, log)
  assert.equal(cylPlayAll(bar), 3)
  assert.deepEqual(log, [['home', 'play'], ['gif', 'play'], ['me', 'play']])
  log.length = 0
  assert.equal(cylRestartSelected(bar), 1)
  assert.deepEqual(log, [['home', 'play']])
})

test('speed reaches only the players that support it, loop only those that can loop', () => {
  const log = []
  const bar = fakeTabBar(specs, log)
  assert.equal(cylSetSpeed(bar, 2), 2, 'a GIF keeps its own speed')
  assert.deepEqual(log, [['home', 'set', { speed: 2 }], ['me', 'set', { speed: 2 }]])
  log.length = 0
  assert.equal(cylSetLoops(bar, true), 3, 'a GIF image can loop')
  assert.deepEqual(log.map(([name, , patch]) => [name, patch.loop]), [['home', true], ['gif', true], ['me', true]])
})

test('the Restart row has its own text in every language the example ships, none of them English', () => {
  const own = require('../example/miniprogram/utils/cyl_demo_strings')
  const more = require('../example/miniprogram/shared/strings_more')
  const languages = [...Object.keys(own), ...Object.keys(more)]
  assert.deepEqual(languages.sort(), ['ar', 'en', 'es', 'hi', 'zh-Hans', 'zh-Hant'])
  languages.filter((language) => language !== 'en').forEach((language) => {
    const text = (own[language] || more[language]).Restart
    assert.ok(text && text !== 'Restart', language)
  })
  assert.equal(own.en.Restart, 'Restart')
})
