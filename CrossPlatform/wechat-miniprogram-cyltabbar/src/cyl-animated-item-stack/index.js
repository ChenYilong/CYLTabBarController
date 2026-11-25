/**
 * [EN] cyl-animated-item-stack: a centered vertical stack whose every element is a cyl-animated-item, the mini program
 *      counterpart of iOS / Android `CYLAnimatedItemStackView` (an empty state, a placeholder, an onboarding card). The
 *      items come from the `items` property (one object per item: title, image, animationUrl, action, spacingBefore,
 *      accessibilityLabel, titleLines, ...). A tap on an item with an `action` triggers `action` with that name; a tap
 *      anywhere else triggers `action` with `backgroundAction` (`detail.background` true). The first item is the
 *      reserved one. Animated icons need the same abstract nodes as cyl-animated-item (`generic:cyl-lottie-view` ...).
 * [CN] cyl-animated-item-stack：每个元素都是 cyl-animated-item 的居中竖向堆叠，对应 iOS / Android 的 `CYLAnimatedItemStackView`（空状态、占位图、
 *      引导卡片）。条目来自 `items` 属性（每个条目一个对象：title、image、animationUrl、action、spacingBefore、accessibilityLabel、titleLines 等）。
 *      点击带 `action` 的条目时以该名称触发 `action` 事件；点击其他位置时以 `backgroundAction` 触发 `action`（`detail.background` 为 true）。
 *      第一个条目是保留条目。动效图标需要与 cyl-animated-item 相同的抽象节点（`generic:cyl-lottie-view` 等）。
 */
const { cylStackSetDivider, cylStackAppendDivider, cylStackRemoveDivider, cylStackHasDivider, cylStackModel, cylStackActionAt, cylStackIndexForAction } = require('./cyl_animated_item_stack_model')

Component({
  properties: {
    /**
     * [EN] The items, top to bottom; the first is the reserved one. [CN] 条目，自上而下；第一个是保留条目。
     */
    items: { type: Array, value: [] },
    /**
     * [EN] The smallest space between the items and the component's edges, in px (16). [CN] 条目与组件边缘之间的最小间距，单位 px（16）。
     */
    contentMargin: { type: Number, value: 16 },
    /** [EN] The space between the outer border and the items on the left and right, in px, added to contentMargin horizontally; -1 (default) is 0 here (no glass background). [CN] 外侧边框与条目之间左右的间距（px），仅在水平方向叠加到 contentMargin 上；-1（默认）在此为 0（无玻璃背景）。 */
    itemContentHorizontalInset: { type: Number, value: -1 },
    /**
     * [EN] The action of a tap outside items with an action; '' (default) turns it off. [CN] 点击带动作条目以外位置时的动作；''（默认）关闭。
     */
    backgroundAction: { type: String, value: '' },
    /** [EN] 'vertical' (default) or 'horizontal' (one row), as iOS `axis`. [CN] 'vertical'（默认）或 'horizontal'（一行），对应 iOS `axis`。 */
    axis: { type: String, value: 'vertical' },
    /** [EN] The space before items without their own `spacingBefore`, in px (16), as iOS `spacing`. [CN] 没有自己 `spacingBefore` 的条目之前的间距，单位 px（16），对应 iOS `spacing`。 */
    spacing: { type: Number, value: 16 },
    /** [EN] The icon color of items without their own (iOS stack `itemAppearance`); '' for none. [CN] 没有自己颜色的条目的图标颜色（iOS 堆叠的 `itemAppearance`）；'' 表示没有。 */
    iconColor: { type: String, value: '' },
    /** [EN] The icon color of selected items without their own; '' uses `iconColor`. [CN] 没有自己颜色的选中条目的图标颜色；'' 时使用 `iconColor`。 */
    selectedIconColor: { type: String, value: '' },
    /** [EN] The animation tint of items without their own (see cyl-animated-item `animationTint`); '' for none. [CN] 没有自己 `animationTint` 的条目的动画着色（见 cyl-animated-item）；'' 表示没有。 */
    animationTint: { type: String, value: '' },
    /** [EN] The dark-mode color of a fixed `animationTint`, for items without their own. [CN] 固定 `animationTint` 的深色模式颜色，供没有自己值的条目使用。 */
    animationDarkTint: { type: String, value: '' },
    /**
     * [EN] true: a built-in divider between every two visible items (an item's `dividerAfter` true / false overrides its own gap). Never before the first or after the
     *      last visible item; hidden items leave none. The dividers are the stack's, not items: a user never writes one.
     * [CN] true：每两个可见条目之间有一条内置分割线（条目的 `dividerAfter` 为 true / false 时覆盖其所在的间隙）。绝不出现在第一个可见条目之前或最后一个可见条目之后；
     *      隐藏的条目不留分割线。分割线属于堆叠而不是条目：用户从不编写。
     */
    showsDividers: { type: Boolean, value: false },
    /** [EN] The space before / after a divider without its own value (px); -1 (default) = not set: before falls back to `spacing`, after to the next item's spacingBefore, then `spacing`. A gap with a divider is before + 1 + after. [CN] 没有自己值的分割线之前 / 之后的间距（px）；-1（默认）表示未设置：before 回退到 `spacing`，after 回退到下一个条目的 spacingBefore，再到 `spacing`。有分割线的间隙为 before + 1 + after。 */
    dividerSpacingBefore: { type: Number, value: -1 },
    dividerSpacingAfter: { type: Number, value: -1 },
    /** [EN] The divider color; '' (default) derives it: `iconColor` at alpha 0.3, else the separator color (light / dark by `userInterfaceStyle`). [CN] 分割线颜色；'' （默认）时推导：`iconColor` 的 0.3 透明度，否则为分隔线颜色（按 `userInterfaceStyle` 区分浅色 / 深色）。 */
    dividerColor: { type: String, value: '' },
    /** [EN] The divider's length in px (20); it is 1 px thick. [CN] 分割线长度，单位 px（20）；粗 1 px。 */
    dividerLength: { type: Number, value: 20 },
    /** [EN] 'system' (default) follows the system theme; 'light' or 'dark' forces it for the dividers (each divider item resolves its own color). [CN] 'system'（默认）跟随系统主题；'light' 或 'dark' 时对分割线强制（每个分割线条目自己解析颜色）。 */
    userInterfaceStyle: { type: String, value: 'system' },
    /** [EN] true: the stack hugs its items (its size follows them) instead of filling its parent; contentMargin may be 0. [CN] true：堆叠贴合条目（大小随条目变化）而不是填满父视图；contentMargin 可为 0。 */
    hugsContent: { type: Boolean, value: false },
    /** [EN] false: the stack takes over no taps (no item action, no background action; the host handles them). [CN] false：堆叠不接管任何点击（没有条目动作、没有背景动作，由宿主处理）。 */
    dispatchesItemTaps: { type: Boolean, value: true },
  },
  data: { m: cylStackModel({}) },
  observers: {
    'items, contentMargin, itemContentHorizontalInset, backgroundAction, axis, spacing, iconColor, selectedIconColor, animationTint, animationDarkTint, dividerColor, dividerLength, dividerSpacingBefore, dividerSpacingAfter, showsDividers, hugsContent, userInterfaceStyle'() {
      this.setData({ m: cylStackModel({ ...this.data }) })
    },
  },
  methods: {
    /**
     * [EN] The divider flow on the `items` property (the same as the model helpers): `appendDivider(before, after)` after the current last item (no-op when empty),
     *      `setDividerAfter(index, before, after)`, `removeDividerAfter(index)` (that gap off even with `showsDividers`), `hasDividerAfter(index)`.
     * [CN] 作用于 `items` 属性的分割线流程（与模型辅助函数相同）：`appendDivider(before, after)` 在当前最后一个条目之后添加（空时无操作）、
     *      `setDividerAfter(index, before, after)`、`removeDividerAfter(index)`（该间隙即使在 `showsDividers` 时也没有）、`hasDividerAfter(index)`。
     */
    appendDivider(spacingBefore, spacingAfter) { this.setData({ items: cylStackAppendDivider(this.data.items, spacingBefore, spacingAfter) }) },
    setDividerAfter(index, spacingBefore, spacingAfter) { this.setData({ items: cylStackSetDivider(this.data.items, index, spacingBefore, spacingAfter) }) },
    removeDividerAfter(index) { this.setData({ items: cylStackRemoveDivider(this.data.items, index) }) },
    hasDividerAfter(index) { return cylStackHasDivider(this.data.m, index) },

    /** [EN] A tap on a built-in divider does nothing. [CN] 点击内置分割线不做任何事。 */
    cyl_noop() {},

    /**
     * [EN] Triggers `action` for `name` (as a tap on its item would); false for an empty name.
     * [CN] 为 `name` 触发 `action` 事件（与点击其条目相同）；名称为空时返回 false。
     */
    performAction(name) {
      if (!this.data.dispatchesItemTaps) return false
      const action = String(name || '').trim()
      if (!action) return false
      this.triggerEvent('action', { action, index: cylStackIndexForAction(this.data.m, action), background: false })
      return true
    },

    /**
     * [EN] The index of the first item whose tap performs `action`; -1 without one. [CN] 点击时执行 `action` 的第一个条目的下标；没有时为 -1。
     */
    itemIndexForAction(action) {
      return cylStackIndexForAction(this.data.m, action)
    },

    cyl_onItemTap(event) {
      if (!this.data.dispatchesItemTaps) return
      const index = Number(event.currentTarget.dataset.index)
      const action = cylStackActionAt(this.data.m, index)
      if (!action) return
      // [EN] The same tap bubbles to the container next: remember it, so it is not also a background tap.
      // [CN] 同一次点击随后冒泡到容器：记录下来，避免同时成为背景点击。
      this.cyl_handledTap = event.timeStamp
      this.triggerEvent('action', { action, index, background: false })
    },

    cyl_onBackgroundTap(event) {
      if (!this.data.dispatchesItemTaps) return
      if (this.cyl_handledTap !== undefined && this.cyl_handledTap === event.timeStamp) return
      const action = this.data.m.backgroundAction
      if (action) this.triggerEvent('action', { action, index: -1, background: true })
    },
  },
})
