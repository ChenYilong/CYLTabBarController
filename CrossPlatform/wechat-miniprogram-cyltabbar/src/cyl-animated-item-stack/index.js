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
const { cylStackModel, cylStackActionAt, cylStackIndexForAction } = require('./cyl_animated_item_stack_model')

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
    /**
     * [EN] The action of a tap outside items with an action; '' (default) turns it off. [CN] 点击带动作条目以外位置时的动作；''（默认）关闭。
     */
    backgroundAction: { type: String, value: '' },
  },
  data: { m: cylStackModel({}) },
  observers: {
    'items, contentMargin, backgroundAction'(items, contentMargin, backgroundAction) {
      this.setData({ m: cylStackModel({ items, contentMargin, backgroundAction }) })
    },
  },
  methods: {
    /**
     * [EN] Triggers `action` for `name` (as a tap on its item would); false for an empty name.
     * [CN] 为 `name` 触发 `action` 事件（与点击其条目相同）；名称为空时返回 false。
     */
    performAction(name) {
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
      const index = Number(event.currentTarget.dataset.index)
      const action = cylStackActionAt(this.data.m, index)
      if (!action) return
      // [EN] The same tap bubbles to the container next: remember it, so it is not also a background tap.
      // [CN] 同一次点击随后冒泡到容器：记录下来，避免同时成为背景点击。
      this.cyl_handledTap = event.timeStamp
      this.triggerEvent('action', { action, index, background: false })
    },

    cyl_onBackgroundTap(event) {
      if (this.cyl_handledTap !== undefined && this.cyl_handledTap === event.timeStamp) return
      const action = this.data.m.backgroundAction
      if (action) this.triggerEvent('action', { action, index: -1, background: true })
    },
  },
})
