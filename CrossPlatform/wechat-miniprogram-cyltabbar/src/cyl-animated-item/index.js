/**
 * [EN] cyl-animated-item: an icon + title view to reuse in other repositories (CollectionViewClassifyMenu's tags,
 *      CYLSearchViewController's bar items): an icon that plays an animation file through the abstract nodes
 *      `cyl-lottie-view`, `cyl-pag-view`, `cyl-rive-view`, `cyl-svga-view` (the app names its engine components, e.g.
 *      `generic:cyl-lottie-view="cyl-lottie"`; GIF is drawn by `<image>`), its static image, a title beside or below it,
 *      an optional accessory with its own tap (`accessorytap`), and gestures on the whole item (`itemtap`,
 *      `itemlongpress`, `dragstart` / `dragmove` / `dragend` when `drag-enabled`). It depends on no animation package.
 *      A file whose engine is not installed shows the static image, or the placeholder, and logs once in the developer
 *      tools which package to add. Accessibility: one element, role button, `accessibility-label` (else the title),
 *      selected and disabled states.
 * [CN] cyl-animated-item：可在其他仓库复用的图标 + 标题视图（CollectionViewClassifyMenu 的标签、CYLSearchViewController 的栏目）：
 *      通过抽象节点 `cyl-lottie-view`、`cyl-pag-view`、`cyl-rive-view`、`cyl-svga-view` 播放动画文件的图标（App 指定引擎组件，例如
 *      `generic:cyl-lottie-view="cyl-lottie"`；GIF 由 `<image>` 绘制）、其静态图片、位于旁边或下方的标题、带独立点击的可选附加图标
 *      （`accessorytap`），以及整个条目的手势（`itemtap`、`itemlongpress`，`drag-enabled` 时的 `dragstart` / `dragmove` / `dragend`）。
 *      不依赖任何动画包。没有安装引擎的文件显示静态图片或占位图，并在开发者工具中输出一次需要安装的包。无障碍：一个元素，角色为按钮，
 *      `accessibility-label`（否则为标题），带选中与禁用状态。
 */
const { cylAnimatedItemModel, cylAnimatedItemPackage } = require('./cyl_animated_item_model')

const cylWarnedTypes = []

Component({
  properties: {
    title: { type: String, value: '' },
    image: { type: String, value: '' },
    selectedImage: { type: String, value: '' },
    placeholderImage: { type: String, value: null, optionalTypes: [Object] },
    animationUrl: { type: String, value: '' },
    selected: { type: Boolean, value: false },
    enabled: { type: Boolean, value: true },
    axis: { type: String, value: 'horizontal' },
    iconSize: { type: Number, value: 24 },
    loop: { type: Boolean, value: false },
    speed: { type: Number, value: 1 },
    accessoryImage: { type: String, value: '' },
    accessoryText: { type: String, value: '' },
    accessoryAccessibilityLabel: { type: String, value: '' },
    accessoryPlacement: { type: String, value: 'trailing' },
    dragEnabled: { type: Boolean, value: false },
    accessibilityLabel: { type: String, value: '' },
  },

  data: {
    animationLoaded: false,
    animationFailed: false,
    m: {},
  },

  observers: {
    'animationUrl': function () {
      this.setData({ animationLoaded: false, animationFailed: false })
      this.cyl_update()
    },
    'title, image, selectedImage, placeholderImage, selected, enabled, axis, iconSize, accessoryImage, accessoryText, accessoryAccessibilityLabel, accessoryPlacement, accessibilityLabel': function () {
      this.cyl_update()
    },
  },

  lifetimes: {
    attached() {
      this.cyl_update()
    },
  },

  methods: {
    cyl_update() {
      this.setData({ m: cylAnimatedItemModel({ ...this.data }) })
    },

    /** [EN] The engine component drew the file. [CN] 引擎组件已绘制该文件。 */
    cyl_onAnimationReady() {
      this.setData({ animationLoaded: true })
      this.cyl_update()
    },

    /**
     * [EN] No engine, a corrupt file or a failed download: back to the static image (or the placeholder), and once per type
     *      a log naming the package to add. [CN] 没有引擎、文件损坏或下载失败：回到静态图片（或占位图），并按类型输出一次需要安装的包。
     */
    cyl_onAnimationError(event) {
      this.setData({ animationFailed: true })
      this.cyl_update()
      const type = this.data.m.animationType
      if (type && !cylWarnedTypes.includes(type)) {
        cylWarnedTypes.push(type)
        console.warn(`[cyl-animated-item] ${type} animation (${this.data.animationUrl}) cannot play: ${(event && event.detail && event.detail.message) || 'no engine'}. ` +
          `Showing the static image, or the placeholder without one. Install ${cylAnimatedItemPackage(type)} and set generic:cyl-${type}-view.`)
      }
    },

    cyl_onTap() {
      if (this.data.enabled) {
        this.triggerEvent('itemtap', {})
      }
    },

    cyl_onLongPress() {
      if (this.data.enabled) {
        this.triggerEvent('itemlongpress', {})
      }
    },

    cyl_onAccessoryTap() {
      if (this.data.enabled) {
        this.triggerEvent('accessorytap', {})
      }
    },

    cyl_onTouchStart(event) {
      if (!this.data.dragEnabled) return
      const touch = event.touches[0]
      this.cylDragStart = { x: touch.clientX, y: touch.clientY }
      this.triggerEvent('dragstart', {})
    },

    cyl_onTouchMove(event) {
      if (!this.data.dragEnabled || !this.cylDragStart) return
      const touch = event.touches[0]
      this.triggerEvent('dragmove', { dx: touch.clientX - this.cylDragStart.x, dy: touch.clientY - this.cylDragStart.y })
    },

    cyl_onTouchEnd(event) {
      if (!this.data.dragEnabled || !this.cylDragStart) return
      const touch = event.changedTouches[0]
      this.triggerEvent('dragend', { dx: touch.clientX - this.cylDragStart.x, dy: touch.clientY - this.cylDragStart.y })
      this.cylDragStart = null
    },
  },
})
