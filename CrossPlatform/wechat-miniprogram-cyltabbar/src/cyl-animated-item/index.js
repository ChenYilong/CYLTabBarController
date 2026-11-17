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
const { cylAnimatedItemModel, cylAnimatedItemPackage, cylAnimatedItemRestingProgress } = require('./cyl_animated_item_model')

/**
 * [EN] The id of the engine node (only one is rendered), reached by `selectComponent` for the playback methods.
 * [CN] 引擎节点的 id（只渲染一个），播放方法通过 `selectComponent` 获取它。
 */
const CYL_ENGINE_ID = '#cyl-animated-item-engine'

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
    /**
     * [EN] Lottie JSON as an object (a data module), instead of `animationUrl`; each item plays its own copy.
     * [CN] 以对象形式提供的 Lottie JSON（数据模块），代替 `animationUrl`；每个条目播放自己的副本。
     */
    animationData: { type: Object, value: null },
    /**
     * [EN] The type of `animationUrl` ('lottie', 'pag', 'rive', 'svga', 'gif') when its extension does not say it (a file
     *      renamed to `.bin` for a code package); '' or an unknown type reads it from the extension.
     * [CN] 当扩展名无法说明时（为代码包改名为 `.bin` 的文件）`animationUrl` 的类型（'lottie'、'pag'、'rive'、'svga'、'gif'）；
     *      '' 或未知类型时根据扩展名判断。
     */
    animationType: { type: String, value: '' },
    /**
     * [EN] Plays once when the file is ready (default, as before). false: rests until `playAnimation()`.
     * [CN] 文件就绪后播放一次（默认，与之前相同）。false：静止，直到调用 `playAnimation()`。
     */
    autoplay: { type: Boolean, value: true },
    /**
     * [EN] The frame (0...1) shown at rest while not selected (iOS `animationRestingProgress`); selected shows the last.
     * [CN] 未选中时静止显示的帧（0...1，iOS 的 `animationRestingProgress`）；选中时显示最后一帧。
     */
    restingProgress: { type: Number, value: 0 },
    /**
     * [EN] GIF stills (PNG): the first and last frames shown at rest; with them a GIF plays one pass (`gifDuration` ms)
     *      on `playAnimation()`, or until `loop` is turned off. Without them a GIF always plays, as before.
     * [CN] GIF 静帧（PNG）：静止时显示的第一帧与最后一帧；有静帧时 `playAnimation()` 播放一遍（`gifDuration` 毫秒），或循环直到关闭
     *      `loop`。没有静帧时 GIF 一直播放（与之前相同）。
     */
    gifFirstFrame: { type: String, value: '' },
    gifLastFrame: { type: String, value: '' },
    gifDuration: { type: Number, value: 1000 },
    /**
     * [EN] Where cyl-rive and cyl-pag load their WebAssembly from (their `wasm-path`); '' keeps the engine's default.
     * [CN] cyl-rive 与 cyl-pag 加载 WebAssembly 的位置（其 `wasm-path`）；'' 使用引擎的默认路径。
     */
    riveWasmPath: { type: String, value: '' },
    pagWasmPath: { type: String, value: '' },
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
    gifPlaying: false,
    lottieData: null,
    m: {},
  },

  observers: {
    'animationUrl, animationData': function (animationUrl, animationData) {
      clearTimeout(this.cylGifTimer)
      this.cylPendingPlay = false
      // cyl-lottie keeps the data it gets and changes it while playing: every item gets its own copy.
      const lottieData = animationData && typeof animationData === 'object' ? JSON.parse(JSON.stringify(animationData)) : null
      this.setData({ animationLoaded: false, animationFailed: false, gifPlaying: false, lottieData })
      this.cyl_update()
    },
    'title, image, selectedImage, placeholderImage, animationType, enabled, axis, iconSize, accessoryImage, accessoryText, accessoryAccessibilityLabel, accessoryPlacement, accessibilityLabel, gifFirstFrame, gifLastFrame': function () {
      this.cyl_update()
    },
    'selected, restingProgress': function () {
      this.cyl_update()
      if (!this.data.autoplay || this.data.gifFirstFrame || this.data.gifLastFrame) this.cyl_rest()
    },
    'loop': function () {
      // Engines take `loop` live; a GIF with stills is timed here: off lets the pass in progress end, on keeps it playing.
      if (!this.data.gifPlaying) return
      clearTimeout(this.cylGifTimer)
      if (!this.data.loop) this.cyl_scheduleGifEnd()
    },
  },

  lifetimes: {
    attached() {
      this.cyl_update()
    },
    detached() {
      clearTimeout(this.cylGifTimer)
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
      if (this.cylPendingPlay) {
        this.playAnimation()
      } else if (!this.data.autoplay) {
        this.cyl_rest()
      }
    },

    /**
     * [EN] Plays the animation from progress 0, once (or until `loop` is turned off): the engine's `cyl_playFromStart()`, or
     *      the GIF again from its first frame. A file still loading plays when it is ready. Play all calls this on every item.
     * [CN] 从进度 0 播放一次动画（或循环直到关闭 `loop`）：引擎的 `cyl_playFromStart()`，或从第一帧重新播放 GIF。仍在加载的文件在就绪后播放。
     *      “全部播放”对每个条目调用此方法。
     */
    playAnimation() {
      const m = this.data.m
      if (m.animationType === 'gif' && m.gifPath) {
        this.cyl_playGif()
        return
      }
      if (!m.usesEngine) return
      if (!this.data.animationLoaded) {
        this.cylPendingPlay = true
        return
      }
      this.cylPendingPlay = false
      const engine = this.selectComponent(CYL_ENGINE_ID)
      if (engine && typeof engine.cyl_playFromStart === 'function') engine.cyl_playFromStart()
    },

    /** [EN] The same as `playAnimation()` (iOS `restartAnimation`). [CN] 与 `playAnimation()` 相同（iOS 的 `restartAnimation`）。 */
    restartAnimation() {
      this.playAnimation()
    },

    /** [EN] Stops and shows the resting frame (iOS `stopAnimation`). [CN] 停止并显示静止帧（iOS 的 `stopAnimation`）。 */
    stopAnimation() {
      this.cylPendingPlay = false
      this.cyl_rest()
    },

    /**
     * [EN] The resting frame: the last one while selected, else `restingProgress`. Lottie through `cyl_goToAndStop`, PAG
     *      and SVGA through `cyl_setProgress`, Rive through its `resting-frame` (first / last), GIF through its stills.
     * [CN] 静止帧：选中时为最后一帧，否则为 `restingProgress`。Lottie 用 `cyl_goToAndStop`，PAG 与 SVGA 用 `cyl_setProgress`，
     *      Rive 用 `resting-frame`（first / last），GIF 用其静帧。
     */
    cyl_rest() {
      clearTimeout(this.cylGifTimer)
      if (this.data.gifPlaying) {
        this.setData({ gifPlaying: false })
        this.cyl_update()
      }
      if (!this.data.m.usesEngine || !this.data.animationLoaded) return
      const engine = this.selectComponent(CYL_ENGINE_ID)
      if (!engine) return
      const progress = cylAnimatedItemRestingProgress(this.data)
      if (typeof engine.cyl_setProgress === 'function') {
        engine.cyl_setProgress(progress)
      } else if (typeof engine.cyl_goToAndStop === 'function' && typeof engine.cyl_animation === 'function') {
        const player = engine.cyl_animation()
        const last = Math.max(0, ((player && player.totalFrames) || 1) - 1)
        engine.cyl_goToAndStop(Math.round(last * progress), true)
      } else if (typeof engine.cyl_rest === 'function') {
        engine.cyl_rest()
      }
    },

    cyl_playGif() {
      clearTimeout(this.cylGifTimer)
      if (!this.data.gifFirstFrame && !this.data.gifLastFrame) {
        // Without stills the GIF always plays; setting its source again restarts it from the first frame.
        const path = this.data.m.gifPath
        this.setData({ 'm.gifPath': '' }, () => this.setData({ 'm.gifPath': path }))
        return
      }
      this.cylGifStartedAt = Date.now()
      this.setData({ gifPlaying: false, 'm.gifPath': this.data.gifFirstFrame || this.data.m.gifPath }, () => {
        this.setData({ gifPlaying: true })
        this.cyl_update()
        if (!this.data.loop) this.cyl_scheduleGifEnd()
      })
    },

    /** [EN] One pass, then the resting still. [CN] 播放一遍后显示静帧。 */
    cyl_scheduleGifEnd() {
      const duration = Number(this.data.gifDuration) > 0 ? Number(this.data.gifDuration) : 1000
      const elapsed = Date.now() - (this.cylGifStartedAt || Date.now())
      this.cylGifTimer = setTimeout(() => {
        this.setData({ gifPlaying: false })
        this.cyl_update()
      }, duration - (elapsed % duration))
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
