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
const { cylAnimatedItemInherited, CYL_ANIMATED_ITEM_DIVIDER_LENGTH: CYL_STACK_DIVIDER_LENGTH } = require('../cyl-animated-item/cyl_animated_item_model')

/**
 * [EN] A non-negative number, or `fallback`. [CN] 非负数，否则为 `fallback`。
 */
function cylStackLength(value, fallback) {
  const number = Number(value)
  return Number.isFinite(number) && number >= 0 ? number : fallback
}

/**
 * [EN] Whether the divider after an item shows: its own `dividerAfter` (false hides, true or an options object shows), else the stack's `showsDividers`.
 * [CN] 条目之后的分割线是否显示：条目自己的 `dividerAfter`（false 隐藏，true 或选项对象显示），否则取堆叠的 `showsDividers`。
 */
function cylStackDividerShown(own, showsDividers) {
  if (own === false) return false
  if (own === true || (own !== null && typeof own === 'object')) return true
  return (own === undefined || own === null) && Boolean(showsDividers)
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
  // [EN] `itemContentHorizontalInset` (px, left and right only, on top of the margin): the stack has no glass background here, so only an explicit value (0 or more) counts.
  // [CN] `itemContentHorizontalInset`（px，仅左右，叠加在边距之上）：此处的堆叠没有玻璃背景，所以只有显式值（0 及以上）有效。
  const sideInset = Math.max(0, Number(p.itemContentHorizontalInset) || 0)
  // [EN] iOS `axis` and `spacing`: 'horizontal' lays the items in one row (anything else is vertical); `spacing` is the space
  //      before items without their own `spacingBefore`. [CN] iOS 的 `axis` 与 `spacing`：'horizontal' 排成一行（其他值为竖向）；
  //      `spacing` 是没有自己 `spacingBefore` 的条目之前的间距。
  const horizontal = p.axis === 'horizontal'
  const stackSpacing = cylStackLength(p.spacing, CYL_STACK_DEFAULT_SPACING)
  const stackIconColor = String(p.iconColor || '')
  const stackSelectedIconColor = String(p.selectedIconColor || '')
  // [EN] Stack-level tint and divider color (the same names as the item), inherited by every item that did not set its own; clearing one ('') removes it
  //      from the items that did not set their own. [CN] 堆叠级着色与分割线颜色（与条目同名），未自行设置的条目都会继承；清除（''）后这些条目随之失去该值。
  const hugs = Boolean(p.hugsContent)
  const list = Array.isArray(p.items) ? p.items.filter((item) => item && typeof item === 'object') : []
  // [EN] `visible: false` (display none) leaves no spacing: the first VISIBLE item has none before it. [CN] `visible: false`（display none）不留间距：第一个可见条目之前没有间距。
  const firstVisible = list.findIndex((item) => item.visible !== false)
  const items = list.map((item, index) => {
    const visible = item.visible !== false
    const action = cylStackAction(item.action)
    // [EN] Takes taps: an action, and not `enabled: false` (a tap on it then reaches the background).
    // [CN] 接收点击：有动作且不是 `enabled: false`（否则点击传给背景）。
    const enabled = item.enabled !== false
    const interactive = Boolean(action) && enabled
    const actsOnBackground = !interactive && index === firstVisible && Boolean(backgroundAction)
    const title = item.title === undefined || item.title === null ? '' : String(item.title)
    const label = String(item.accessibilityLabel || '')
    const button = interactive || actsOnBackground
    const spacing = index === firstVisible ? 0 : cylStackLength(item.spacingBefore, stackSpacing)
    const spacingProperty = horizontal ? 'margin-left' : 'margin-top'
    // [EN] A hidden item is display none; `alpha` (0 to 1) fades it, its space stays. [CN] 隐藏的条目为 display none；`alpha`（0 到 1）使其淡出，但仍占位。
    const alpha = item.alpha === undefined || item.alpha === null || item.alpha === '' ? 1 : Math.min(1, Math.max(0, Number(item.alpha)))
    const fade = Number.isFinite(alpha) && alpha < 1 ? ` opacity: ${alpha};` : ''
    // [EN] The icon color (iOS `itemAppearance` iconColor): the item's own, else the stack's; selected first tries the
    //      selected colors. `iconTint` is the older name of an item's `iconColor`.
    // [CN] 图标颜色（iOS `itemAppearance` 的 iconColor）：条目自己的，否则为堆叠的；选中时先取选中颜色。`iconTint` 是条目 `iconColor` 的旧名称。
    const selected = Boolean(item.selected)
    const normalColor = String(item.iconColor || item.iconTint || '') || stackIconColor
    const iconColor = (selected && (String(item.selectedIconColor || '') || stackSelectedIconColor)) || normalColor
    return {
      key: item.key !== undefined ? String(item.key) : `cyl-stack-${index}`,
      index,
      title,
      image: String(item.image || ''),
      selectedImage: String(item.selectedImage || ''),
      animationUrl: String(item.animationUrl || ''),
      iconSize: cylStackLength(item.iconSize, 24),
      titleLines: item.titleLines === undefined ? 0 : cylStackLength(item.titleLines, 0),
      titleColor: cylAnimatedItemInherited(item.titleColor, p.titleColor),
      titleFontSize: cylStackLength(item.titleFontSize, 0),
      titleFontWeight: item.titleFontWeight === undefined ? '' : item.titleFontWeight,
      iconTint: iconColor,
      selected,
      loop: Boolean(item.loop),
      visible,
      animationTint: cylAnimatedItemInherited(item.animationTint, p.animationTint),
      // [EN] Inherited rendering mode and the built-in selected color the stack hands every item (tint spec v2). [CN] 堆叠传给每个条目的继承渲染模式与内置选中颜色。
      animationRenderingMode: cylAnimatedItemInherited(item.animationRenderingMode, p.animationRenderingMode),
      builtInSelectedColor: String(p.defaultSelectedColor || '').trim(),
      animationDarkTint: cylAnimatedItemInherited(item.animationDarkTint, p.animationDarkTint),
      animationIconTint: normalColor,
      animationSelectedIconTint: String(item.selectedIconColor || '') || stackSelectedIconColor,
      accessibilityLabel: label,
      action,
      enabled,
      interactive,
      role: button ? 'button' : 'text',
      hidden: !visible || (!button && !title && !label),
      spacing,
      fade,
      wrapperStyle: '',
    }
  })
  // [EN] Built-in dividers (G1-G4): a divider belongs to the gap AFTER its owner item (`dividerAfter`: true, an object { spacingBefore, spacingAfter }, or false
  //      for no divider in that gap even with `showsDividers`; unset follows `showsDividers`). It shows only when the owner is visible and a later visible item
  //      exists, so hidden items leave neither divider nor spacing; it moves with its item and goes with it. The gap with a divider is before + thickness + after:
  //      before = the divider's own ?? `dividerSpacingBefore` ?? `spacing`; after = its own ?? `dividerSpacingAfter` ?? the NEXT item's spacingBefore ?? `spacing`.
  //      The next item's own margin is then 0 (its spacingBefore is only the fallback, never added on top): spacing 12 with divider(8, 8) is 8 + 1 + 8 = 17.
  //      [CN] 内置分割线（G1-G4）：分割线属于其所有者条目「之后」的间隙（`dividerAfter`：true、对象 { spacingBefore, spacingAfter }，或 false 表示即使
  //      `showsDividers` 为真该间隙也没有分割线；未设置时跟随 `showsDividers`）。只有所有者可见且之后还有可见条目时才显示，因此隐藏的条目既不留分割线也不留间距；
  //      分割线随其条目移动、随其条目删除。有分割线的间隙 = before + 粗细 + after：before = 自己的值 ?? `dividerSpacingBefore` ?? `spacing`；
  //      after = 自己的值 ?? `dividerSpacingAfter` ?? 下一个条目的 spacingBefore ?? `spacing`。此时下一个条目自己的外边距为 0（其 spacingBefore 只是回退值，
  //      绝不叠加）：spacing 12 加 divider(8, 8) 为 8 + 1 + 8 = 17。
  // [EN] The divider is an internal cyl-animated-item (`cylInternalDivider`): it gets the stack's `dividerColor`, its effective normal icon color, the tint inheritance
  //      and the stack's appearance, and draws the line itself (see cylAnimatedItemDividerColor). [CN] 分割线是内部的 cyl-animated-item（`cylInternalDivider`）：
  //      它获得堆叠的 `dividerColor`、有效的普通图标颜色、着色继承与堆叠的外观，并自己画线（见 cylAnimatedItemDividerColor）。
  const divider = {
    color: String(p.dividerColor || '').trim(),
    length: cylStackLength(p.dividerLength, CYL_STACK_DIVIDER_LENGTH),
    vertical: horizontal,
    iconTint: stackIconColor,
    animationTint: cylAnimatedItemInherited('', p.animationTint),
    animationDarkTint: cylAnimatedItemInherited('', p.animationDarkTint),
    builtInSelectedColor: String(p.defaultSelectedColor || '').trim(),
    userInterfaceStyle: String(p.userInterfaceStyle || 'system'),
  }
  const before = horizontal ? 'margin-left' : 'margin-top'
  const after = horizontal ? 'margin-right' : 'margin-bottom'
  const optional = (value) => {
    if (value === undefined || value === null || value === '') return undefined
    const number = Number(value)
    return number >= 0 ? number : undefined
  }
  const stackBefore = optional(p.dividerSpacingBefore)
  const stackAfter = optional(p.dividerSpacingAfter)
  let owner = null
  items.forEach((entry) => {
    entry.hasDividerAfter = false
    entry.dividerBefore = false
    if (!entry.visible) return
    if (owner) {
      const own = list[owner.index].dividerAfter
      const shown = cylStackDividerShown(own, p.showsDividers)
      if (shown) {
        const values = own !== null && typeof own === 'object' ? own : {}
        const gapBefore = optional(values.spacingBefore) ?? stackBefore ?? stackSpacing
        const gapAfter = optional(values.spacingAfter) ?? stackAfter ?? entry.spacing
        owner.hasDividerAfter = true
        entry.dividerBefore = true
        entry.dividerStyle = `${before}: ${gapBefore}px; ${after}: ${gapAfter}px;`
        entry.spacing = 0
      }
    }
    owner = entry
  })
  items.forEach((entry) => {
    entry.wrapperStyle = (entry.visible ? '' : 'display: none;') + (entry.visible && entry.spacing ? `${before}: ${entry.spacing}px;` : '') + entry.fade
  })
  return { items, backgroundAction, divider, horizontal, hugsContent: hugs, containerClass: hugs ? 'cyl-stack-hug' : '', containerStyle: sideInset > 0 ? `padding: ${margin}px ${margin + sideInset}px;` : `padding: ${margin}px;` }
}

/**
 * [EN] The action a tap on the item at `index` performs: its own while it is interactive, or '' (the tap then reaches the
 *      background).
 * [CN] 点击 `index` 处条目执行的动作：条目可交互时为它自己的动作，否则为 ''（点击随后传给背景）。
 */
function cylStackActionAt(model, index) {
  const item = model?.items ? model.items[index] : null
  return item?.interactive ? item.action : ''
}

/**
 * [EN] The index of the first item whose tap performs `action`; -1 without one. [CN] 点击时执行 `action` 的第一个条目的下标；没有时为 -1。
 */
function cylStackIndexForAction(model, action) {
  const name = cylStackAction(action)
  if (!name || !model?.items) return -1
  return model.items.findIndex((item) => item.action === name)
}

/**
 * [EN] The model helpers of the append flow (the equivalents of `appendDivider`, `setDivider(after:)`, `removeDivider(after:)`, `hasDivider(after:)`); each returns a NEW
 *      items list for the `items` property. `appendDivider` attaches a divider after the CURRENT LAST item (the list unchanged when empty): append the camera, call
 *      `appendDivider(8, 8)`, append the search button. Spacings are optional (undefined = the fallbacks of the gap math). `removeDivider` turns that gap off even with
 *      `showsDividers`. [CN] 追加流程的模型辅助函数（对应 `appendDivider`、`setDivider(after:)`、`removeDivider(after:)`、`hasDivider(after:)`）；每个都返回新的 `items` 列表。
 *      `appendDivider` 在当前最后一个条目之后添加分割线（列表为空时不变）：先追加相机，调用 `appendDivider(8, 8)`，再追加搜索按钮。间距可省略（即间隙计算中的回退值）。
 *      `removeDivider` 让该间隙即使在 `showsDividers` 时也没有分割线。
 */
function cylStackSetDivider(items, index, spacingBefore, spacingAfter) {
  const list = Array.isArray(items) ? items : []
  if (!(index >= 0 && index < list.length)) return list
  const value = spacingBefore === undefined && spacingAfter === undefined ? true : { spacingBefore, spacingAfter }
  return list.map((item, i) => (i === index ? { ...item, dividerAfter: value } : item))
}

function cylStackAppendDivider(items, spacingBefore, spacingAfter) {
  const list = Array.isArray(items) ? items : []
  return cylStackSetDivider(list, list.length - 1, spacingBefore, spacingAfter)
}

function cylStackRemoveDivider(items, index) {
  const list = Array.isArray(items) ? items : []
  if (!(index >= 0 && index < list.length)) return list
  return list.map((item, i) => (i === index ? { ...item, dividerAfter: false } : item))
}

/**
 * [EN] Whether the item at `index` has a divider after it right now (in a model from `cylStackModel`). [CN] 下标 `index` 处的条目当前之后是否有分割线（在 `cylStackModel` 的模型中）。
 */
function cylStackHasDivider(model, index) {
  return Boolean(model?.items?.[index]?.hasDividerAfter)
}

module.exports = { cylStackSetDivider, cylStackAppendDivider, cylStackRemoveDivider, cylStackHasDivider, CYL_STACK_DIVIDER_LENGTH, cylStackModel, cylStackActionAt, cylStackIndexForAction, CYL_STACK_DEFAULT_SPACING }
