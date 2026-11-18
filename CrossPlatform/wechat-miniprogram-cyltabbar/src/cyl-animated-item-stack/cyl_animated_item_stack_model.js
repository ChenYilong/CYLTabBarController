/**
 * [EN] The render model of cyl-animated-item-stack, the mini program counterpart of iOS / Android
 *      `CYLAnimatedItemStackView`: a centered vertical stack whose every element is a cyl-animated-item. Pure functions
 *      without any wx API, tested in Node (test/cyl_animated_item_stack.test.js).
 * [CN] cyl-animated-item-stack 的渲染模型，对应 iOS / Android 的 `CYLAnimatedItemStackView`：每个元素都是 cyl-animated-item 的居中竖向堆叠。
 *      纯函数，不调用 wx API，在 Node 中测试（test/cyl_animated_item_stack.test.js）。
 */

/**
 * [EN] The default space between items and around them, in px. [CN] 条目之间及四周的默认间距，单位 px。
 */
const CYL_STACK_DEFAULT_SPACING = 16

/**
 * [EN] A non-negative number, or `fallback`. [CN] 非负数，否则为 `fallback`。
 */
function cylStackLength(value, fallback) {
  const number = Number(value)
  return Number.isFinite(number) && number >= 0 ? number : fallback
}

/**
 * [EN] An action name, or '' for none. [CN] 动作名称；没有时为 ''。
 */
function cylStackAction(value) {
  return typeof value === 'string' ? value.trim() : ''
}

/**
 * [EN] The render model: every item normalized (icon above the title, titles wrapping unless `titleLines` is given, the
 *      spacing before it, its screen reader role), and the container's padding. An item with an action is a button; one
 *      without is text; one with nothing to read (no title, no label, no action) is decoration and hidden; the first item
 *      reads as a button for the background action.
 * [CN] 渲染模型：每个条目都被规范化（图标在标题上方，未指定 `titleLines` 时标题换行，条目前的间距，读屏角色），以及容器的内边距。带动作的条目是
 *      按钮；没有动作的是文字；没有可朗读内容（无标题、无标签、无动作）的是装饰并隐藏；第一个条目可作为背景动作的按钮。
 */
function cylStackModel(p) {
  const backgroundAction = cylStackAction(p.backgroundAction)
  const margin = cylStackLength(p.contentMargin, CYL_STACK_DEFAULT_SPACING)
  const list = Array.isArray(p.items) ? p.items.filter((item) => item && typeof item === 'object') : []
  const items = list.map((item, index) => {
    const action = cylStackAction(item.action)
    // [EN] Takes taps: an action, and not `enabled: false` (a tap on it then reaches the background).
    // [CN] 接收点击：有动作且不是 `enabled: false`（否则点击传给背景）。
    const enabled = item.enabled !== false
    const interactive = Boolean(action) && enabled
    const actsOnBackground = !interactive && index === 0 && Boolean(backgroundAction)
    const title = item.title === undefined || item.title === null ? '' : String(item.title)
    const label = String(item.accessibilityLabel || '')
    const button = interactive || actsOnBackground
    const spacing = index === 0 ? 0 : cylStackLength(item.spacingBefore, CYL_STACK_DEFAULT_SPACING)
    return {
      key: item.key !== undefined ? String(item.key) : `cyl-stack-${index}`,
      index,
      title,
      image: String(item.image || ''),
      selectedImage: String(item.selectedImage || ''),
      animationUrl: String(item.animationUrl || ''),
      iconSize: cylStackLength(item.iconSize, 24),
      titleLines: item.titleLines === undefined ? 0 : cylStackLength(item.titleLines, 0),
      titleColor: String(item.titleColor || ''),
      titleFontSize: cylStackLength(item.titleFontSize, 0),
      titleFontWeight: item.titleFontWeight === undefined ? '' : item.titleFontWeight,
      iconTint: String(item.iconTint || ''),
      loop: Boolean(item.loop),
      accessibilityLabel: label,
      action,
      enabled,
      interactive,
      role: button ? 'button' : 'text',
      hidden: !button && !title && !label,
      wrapperStyle: spacing ? `margin-top: ${spacing}px;` : '',
    }
  })
  return { items, backgroundAction, containerStyle: `padding: ${margin}px;` }
}

/**
 * [EN] The action a tap on the item at `index` performs: its own while it is interactive, or '' (the tap then reaches the
 *      background).
 * [CN] 点击 `index` 处条目执行的动作：条目可交互时为它自己的动作，否则为 ''（点击随后传给背景）。
 */
function cylStackActionAt(model, index) {
  const item = model && model.items ? model.items[index] : null
  return item && item.interactive ? item.action : ''
}

/**
 * [EN] The index of the first item whose tap performs `action`; -1 without one. [CN] 点击时执行 `action` 的第一个条目的下标；没有时为 -1。
 */
function cylStackIndexForAction(model, action) {
  const name = cylStackAction(action)
  if (!name || !model || !model.items) return -1
  return model.items.findIndex((item) => item.action === name)
}

module.exports = { cylStackModel, cylStackActionAt, cylStackIndexForAction, CYL_STACK_DEFAULT_SPACING }
