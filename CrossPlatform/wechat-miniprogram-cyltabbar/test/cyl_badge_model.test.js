'use strict'

// [EN] The cyl-badge model and its use by cyl-animated-item: the iOS value semantics, the one attributes parser, the accessibility text.
// [CN] cyl-badge 模型及其在 cyl-animated-item 中的使用：iOS 的取值语义、唯一的属性解析函数、无障碍文字。
const test = require('node:test')
const assert = require('node:assert/strict')
const { cylBadgeAnimationName, cylBadgeParseAttributes, cylBadgeText, cylBadgeViewModel } = require('../src/cyl-badge/cyl_badge_model')
const { cylAnimatedItemModel: model } = require('../src/cyl-animated-item/cyl_animated_item_model')

test('value: null none, empty string a dot, numbers above the maximum show 99+, zero and below show nothing', () => {
  assert.equal(cylBadgeText(null), null)
  assert.equal(cylBadgeText(undefined), null)
  assert.equal(cylBadgeText(''), '')
  assert.equal(cylBadgeText('3'), '3')
  assert.equal(cylBadgeText(120), '99+')
  assert.equal(cylBadgeText('120', 50), '50+')
  assert.equal(cylBadgeText(0), null)
  assert.equal(cylBadgeText('new'), 'new')
})

test('animation names: the ten iOS names in any letter case, numbers 0 to 9, nothing else', () => {
  assert.equal(cylBadgeAnimationName('Scale'), 'scale')
  assert.equal(cylBadgeAnimationName('leftrightonce'), 'leftRightOnce')
  assert.equal(cylBadgeAnimationName(9), 'scaleOnce')
  assert.equal(cylBadgeAnimationName('spin'), '')
  assert.equal(cylBadgeAnimationName(10), '')
  assert.equal(cylBadgeAnimationName({}), '')
})

test('the parser reads strings and native values and ignores null and unknown types', () => {
  const parsed = cylBadgeParseAttributes({ color: '#FF3B30', textColor: '#ffffff80', centerOffset: '{4, -2}', radius: '5', font: 12, maximumNumber: null, borderWidth: {}, animation: 'Shake', respectsReduceMotion: false, extra: 1 })
  assert.equal(parsed.color, '#FF3B30')
  assert.equal(parsed.textColor, 'rgba(255,255,255,0.502)')
  assert.deepEqual(parsed.centerOffset, { x: 4, y: -2 })
  assert.equal(parsed.radius, 5)
  assert.equal(parsed.fontSize, 12)
  assert.equal(parsed.maximumNumber, undefined)
  assert.equal(parsed.borderWidth, undefined)
  assert.equal(parsed.animation, 'shake')
  assert.equal(parsed.respectsReduceMotion, false)
  assert.deepEqual(cylBadgeParseAttributes(null), {})
  assert.deepEqual(cylBadgeParseAttributes('x'), {})
})

test('view model: a dot, a text, the animation class, the debug switch, Reduce Motion', () => {
  const dot = cylBadgeViewModel('', { animation: 'breathe' })
  assert.deepEqual([dot.showsBadge, dot.isDot, dot.className], [true, true, 'cyl-badge-breathe'])
  const text = cylBadgeViewModel(7, { color: '#00FF00', animation: 'scale' })
  assert.deepEqual([text.showsBadge, text.isDot, text.text, text.className], [true, false, '7', 'cyl-badge-scale'])
  assert.match(text.style, /background-color: #00FF00;/)
  assert.equal(cylBadgeViewModel(7, { animation: 'scale' }, { animationDisabled: true }).className, '')
  assert.equal(cylBadgeViewModel(7, { animation: 'scale' }, { reduceMotion: true }).className, '')
  assert.equal(cylBadgeViewModel(7, { animation: 'scale', respectsReduceMotion: false }, { reduceMotion: true }).className, 'cyl-badge-scale')
  assert.equal(cylBadgeViewModel(null, {}).showsBadge, false)
  // an animation without a CSS class (leftRightOnce, rollingOnce...) draws the badge without animating
  assert.equal(cylBadgeViewModel(7, { animation: 'rollingOnce' }).className, '')
})

test('the item: no badge by default; the badge never changes the icon box; reservesBadgeSpace reserves the overhang; the label carries the badge', () => {
  const plain = model({ title: 'Inbox', image: 'a.png' })
  assert.equal(plain.badgeShows, false)
  assert.equal(plain.ariaLabel, 'Inbox')
  const badged = model({ title: 'Inbox', image: 'a.png', badgeValue: '3', badgeAttributes: { centerOffset: '{2, -1}' } })
  assert.equal(badged.badgeShows, true)
  assert.equal(badged.iconStyle, plain.iconStyle, 'not measured')
  assert.equal(badged.ariaLabel, 'Inbox, 3')
  assert.match(badged.badgeAnchorStyle, /calc\(50% \+ 2px\), calc\(-50% \+ -1px\)/)
  const reserved = model({ title: 'Inbox', image: 'a.png', badgeValue: '3', reservesBadgeSpace: true, badgeAttributes: { radius: 6 } })
  assert.match(reserved.iconStyle, /margin: 6px;/)
  const described = model({ title: 'Inbox', image: 'a.png', badgeValue: '3', badgeAccessibilityLabel: '3 new items' })
  assert.equal(described.ariaLabel, 'Inbox, 3 new items')
  assert.equal(model({ title: 'Inbox', image: 'a.png', badgeValue: '' }).ariaLabel, 'Inbox', 'a dot adds no text without a description')
  assert.equal(model({ title: 'Inbox', image: 'a.png', badgeValue: null }).badgeShows, false, 'cleared')
})
