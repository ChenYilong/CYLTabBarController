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
    // [EN] For a host that draws the icon with this component (the tab bar item): Lottie / Rive colors (keypath -> color),
    //      autoplay, a tint for the static image, a non-square icon, the embedded layout and hiding it from screen
    //      readers (the host is the accessibility element). [CN] 供用本组件绘制图标的宿主（TabBar Item）使用：Lottie / Rive
    //      颜色（keypath -> 颜色）、自动播放、静态图片着色、非正方形图标、嵌入式布局，以及对读屏隐藏（宿主是无障碍元素）。
    // [EN] 'lottie', 'pag', 'rive', 'svga' or 'gif' when the file name does not say it ('' reads the extension; "*.svga.bin" is read as SVGA).
    // [CN] 文件名无法表明类型时指定 'lottie'、'pag'、'rive'、'svga' 或 'gif'（'' 按扩展名读取；"*.svga.bin" 读作 SVGA）。
    animationType: { type: String, value: '' },
    colors: { type: Object, value: null },
    autoplay: { type: Boolean, value: true },
    iconTint: { type: String, value: '' },
    iconWidth: { type: Number, value: 0 },
    iconHeight: { type: Number, value: 0 },
    bare: { type: Boolean, value: false },
    accessibilityHidden: { type: Boolean, value: false },
  },

  data: {
    animationLoaded: false,
    animationFailed: false,
    m: {},
  },

  observers: {
    'animationUrl, animationType': function (animationUrl, animationType) {
      // [EN] A host re-renders and sets the same file again: keep the loaded / failed state, because the engine view
      //      (cyl-lottie reloads only when its inputs change) does not load again and sends no new `ready`; resetting
      //      here left the static image over a playing animation.
      // [CN] 宿主重新渲染时会再次设置同一个文件：保留已加载 / 失败状态，因为引擎视图（cyl-lottie 只在输入变化时重新加载）
      //      不会再次加载、也不会再发 `ready`；在这里重置会让静态图片盖住正在播放的动画。
      const key = `${animationUrl || ''}|${animationType || ''}`
      if (key === this.cylAnimationKey) {
        return
      }
      this.cylAnimationKey = key
      this.setData({ animationLoaded: false, animationFailed: false })
      this.cyl_update()
    },
    'title, image, selectedImage, placeholderImage, selected, enabled, axis, iconSize, iconWidth, iconHeight, iconTint, accessoryImage, accessoryText, accessoryAccessibilityLabel, accessoryPlacement, accessibilityLabel': function () {
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

    /** [EN] The engine component, or null (no engine type, GIF, or not drawn yet). [CN] 引擎组件，没有时为 null。 */
    cyl_animationView() {
      return this.selectComponent('#cyl-animated-item-animation')
    },

    /**
     * [EN] Plays the animation from its first frame, or `offset` seconds in, when its engine can.
     * [CN] 引擎支持时，从首帧（或第 `offset` 秒）播放动画。
     */
    cyl_playFromStart(offset) {
      const view = this.cyl_animationView()
      if (view && typeof view.cyl_playFromStart === 'function') {
        view.cyl_playFromStart(offset)
      }
    },

    /** [EN] Stops the animation on its resting frame. [CN] 停止动画并显示静止帧。 */
    cyl_stop() {
      const view = this.cyl_animationView()
      if (view && typeof view.cyl_stop === 'function') {
        view.cyl_stop()
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
