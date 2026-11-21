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
const { cylGIFImageInfo } = require('./cyl_gif_image')
const { CYLAnimatedItemCountdown, CYL_COUNTDOWN_TICK_INTERVAL } = require('./cyl_animated_item_countdown')

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
     * [EN] Inside a control that is itself the accessibility element and handles taps (a tag, a bar item): no padding,
     *      no 44 px minimum, hidden from accessibility, no gestures. The control keeps its own label and touch target.
     * [CN] 位于本身就是无障碍元素并处理点击的控件内（标签、栏目）：无内边距、无 44 px 最小高度、对无障碍隐藏、无手势。控件保留自己的标签与触控区域。
     */
    embedded: { type: Boolean, value: false },
    /**
     * [EN] Plays once when the file is ready (default, as before). false: rests until `playAnimation()`.
     * [CN] 文件就绪后播放一次（默认，与之前相同）。false：静止，直到调用 `playAnimation()`。
     */
    autoplay: { type: Boolean, value: true },
    /**
     * [EN] Whether a play-once animation (`loop` off) is replaced by the still image when it ends (iOS / Android
     *      `showsImageWhenAnimationEnds`): the engine is hidden and `selectedImage` / `image` (else the placeholder)
     *      shows. Off by default, so the last frame stays. `playAnimation()`, `stopAnimation()`, a new selection, a new
     *      file or turning `loop` on shows the animation again. The end is the engine's `complete` (Lottie, PAG, Rive,
     *      SVGA) or the end of a timed GIF pass (with stills); `animationcomplete` is sent either way.
     * [CN] 只播放一次的动画（`loop` 关闭）结束时是否换成静态图片（iOS / Android 的 `showsImageWhenAnimationEnds`）：隐藏引擎，显示
     *      `selectedImage` / `image`（没有时为占位图）。默认关闭，保留最后一帧。`playAnimation()`、`stopAnimation()`、重新选中、新文件或开启
     *      `loop` 时重新显示动画。结束来自引擎的 `complete`（Lottie、PAG、Rive、SVGA）或有静帧的 GIF 一遍计时结束；两种情况都发送 `animationcomplete`。
     */
    showsImageWhenAnimationEnds: { type: Boolean, value: false },
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
    // [EN] For a host that draws the icon with this component (the tab bar item): Lottie / Rive colors (keypath -> color),
    //      autoplay, a tint for the static image, a non-square icon, the embedded layout and hiding it from screen
    //      readers (the host is the accessibility element). [CN] 供用本组件绘制图标的宿主（TabBar Item）使用：Lottie / Rive
    //      颜色（keypath -> 颜色）、自动播放、静态图片着色、非正方形图标、嵌入式布局，以及对读屏隐藏（宿主是无障碍元素）。
    // [EN] `animationType` and `autoplay` are declared above ("*.svga.bin" is read as SVGA).
    // [CN] `animationType` 与 `autoplay` 已在上方声明（"*.svga.bin" 读作 SVGA）。
    colors: { type: Object, value: null },
    iconTint: { type: String, value: '' },
    /**
     * [EN] One color for the animation (any CSS color), like a template image: Rive draws every pixel in it. '' keeps the
     *      file's colors. Rive only for now; other engines keep their colors.
     * [CN] 动画使用的一种颜色（任意 CSS 颜色），如同模板图片：Rive 把每个像素绘制为该颜色。'' 保持文件自身的颜色。
     *      目前仅支持 Rive；其他引擎保持自身颜色。
     */
    animationTint: { type: String, value: '' },
    /**
     * [EN] The title's color (any CSS color); '' keeps the inherited color.
     * [CN] 标题颜色（任意 CSS 颜色）；'' 时沿用继承的颜色。
     */
    titleColor: { type: String, value: '' },
    /**
     * [EN] The title's font size in px; 0 keeps the default 14 px.
     * [CN] 标题字号（px）；0 时为默认的 14 px。
     */
    titleFontSize: { type: Number, value: 0 },
    /**
     * [EN] The title's font weight: 'normal', 'bold', 'bolder', 'lighter' or 100–900 (string or number); '' keeps the
     *      default.
     * [CN] 标题字重：'normal'、'bold'、'bolder'、'lighter' 或 100–900（字符串或数字）；'' 时保持默认。
     */
    titleFontWeight: { type: String, optionalTypes: [Number], value: '' },
    /**
     * [EN] The title's color in dark mode (any CSS color); '' keeps `titleColor`. Dark follows `userInterfaceStyle`.
     * [CN] 深色模式下的标题颜色（任意 CSS 颜色）；'' 时沿用 `titleColor`。是否深色由 `userInterfaceStyle` 决定。
     */
    titleDarkColor: { type: String, value: '' },
    /**
     * [EN] 'system' (default) follows the system theme (needs `"darkmode": true` in app.json); 'light' or 'dark' forces it.
     * [CN] 'system'（默认）跟随系统主题（需在 app.json 中设置 `"darkmode": true`）；'light' 或 'dark' 时强制。
     */
    userInterfaceStyle: { type: String, value: 'system' },
    /**
     * [EN] The title's line count: 1 one line with an ellipsis (default), 0 no limit, n > 1 up to n lines, then an ellipsis.
     * [CN] 标题行数：1 为单行省略（默认），0 为不限，n > 1 为最多 n 行后省略。
     */
    titleLines: { type: Number, value: 1 },
    /**
     * [EN] The title's line height in px; 0 keeps the default.
     * [CN] 标题行高（px）；0 时为默认值。
     */
    titleLineHeight: { type: Number, value: 0 },
    /**
     * [EN] The gap between the icon and the title in px (below the icon when vertical, beside it when horizontal); -1
     *      keeps the default 2 px (vertical) / 4 px (horizontal).
     * [CN] 图标与标题的间距（px；纵向在图标下方，横向在图标旁）；-1 为默认的 2 px（纵向）/ 4 px（横向）。
     */
    titleSpacing: { type: Number, value: -1 },
    /**
     * [EN] 'plain' (default) or 'countdown': a countdown button, e.g. "Get code" of an SMS login (`itemStyle`, the same name
     *      as on iOS, Android and HarmonyOS; `style` is the host's own attribute). Set the `countdown…` properties, then call
     *      `startCountdown()` (or set `startsCountdownOnTap`). The end is a time read from the local clock, so the seconds in the
     *      background count (FIX: issue #1 of SMSCodeButton); a clock past the longest duration, or set back to before the start,
     *      closes it; `countdownCacheKey` keeps it across a restart. While it runs the item is disabled. Events: `countdownstart`,
     *      `countdowntick` (`detail.seconds`, once per second), `countdownfinish`.
     * [CN] 'plain'（默认）或 'countdown'：倒计时按钮，例如短信登录的「获取验证码」（`itemStyle`，与 iOS、Android、HarmonyOS
     *      同名；`style` 是宿主自己的属性）。设置 `countdown…` 属性后调用 `startCountdown()`（或设置 `startsCountdownOnTap`）。结束是从本地时钟读取的时间点，
     *      因此后台的秒数计入（修复 SMSCodeButton 的 issue #1）；时钟超过最长时长或被调回到开始之前时关闭；`countdownCacheKey` 使其在重启后继续。
     *      倒计时中条目不可用。事件：`countdownstart`、`countdowntick`（`detail.seconds`，每秒一次）、`countdownfinish`。
     */
    itemStyle: { type: String, value: 'plain' },
    countdownDuration: { type: Number, value: 60 },
    countdownIdleTitle: { type: String, value: 'Get code' },
    countdownRunningTitleFormat: { type: String, value: '%ld s left' },
    countdownFinishedTitle: { type: String, value: 'Resend' },
    countdownImage: { type: String, value: '' },
    countdownRunningTitleColor: { type: String, value: '#999999' },
    startsCountdownOnTap: { type: Boolean, value: false },
    countdownCacheKey: { type: String, value: '' },
    iconWidth: { type: Number, value: 0 },
    iconHeight: { type: Number, value: 0 },
    bare: { type: Boolean, value: false },
    accessibilityHidden: { type: Boolean, value: false },
    // [EN] The role a screen reader announces: "button" (default) or "text" (a container's hint that takes no taps, e.g.
    //      cyl-animated-item-stack). [CN] 读屏朗读的角色："button"（默认）或 "text"（容器中不接收点击的提示，例如 cyl-animated-item-stack）。
    accessibilityRole: { type: String, value: 'button' },
  },

  data: {
    animationLoaded: false,
    animationFailed: false,
    gifPlaying: false,
    gifImageReady: false,
    gifImagePlaying: false,
    animationEnded: false,
    lottieData: null,
    m: {},
    systemTheme: 'light',
    countdownState: 'idle',
    countdownSeconds: 0,
  },

  observers: {
    'animationUrl, animationData, animationType': function (animationUrl, animationData, animationType) {
      // [EN] A host re-renders and sets the same file (or the same Lottie data object) again: keep the loaded / failed
      //      state, because the engine view (cyl-lottie reloads only when its inputs change) does not load again and sends
      //      no new `ready`; resetting here left the static image over a playing animation.
      // [CN] 宿主重新渲染时会再次设置同一个文件（或同一个 Lottie 数据对象）：保留已加载 / 失败状态，因为引擎视图（cyl-lottie
      //      只在输入变化时重新加载）不会再次加载、也不会再发 `ready`；在这里重置会让静态图片盖住正在播放的动画。
      const key = `${animationUrl || ''}|${animationType || ''}`
      // [EN] The same file after a failure is a retry (the network is back): reset so the engine view may load it again.
      // [CN] 失败后再次设置同一个文件即为重试（例如网络恢复）：重置，让引擎视图可以再次加载。
      if (key === this.cylAnimationKey && animationData === this.cylAnimationData && !this.data.animationFailed) {
        return
      }
      this.cylAnimationKey = key
      this.cylAnimationData = animationData
      clearTimeout(this.cylGifTimer)
      this.cylPendingPlay = false
      // cyl-lottie keeps the data it gets and changes it while playing: every item gets its own copy.
      const lottieData = animationData && typeof animationData === 'object' ? JSON.parse(JSON.stringify(animationData)) : null // NOSONAR: `structuredClone` is not in every mini program runtime
      this.setData({ animationLoaded: false, animationFailed: false, gifPlaying: false, animationEnded: false, lottieData })
      this.cyl_update()
    },
    'title, image, selectedImage, placeholderImage, embedded, enabled, axis, iconSize, accessoryImage, accessoryText, accessoryAccessibilityLabel, accessoryPlacement, accessibilityLabel, gifFirstFrame, gifLastFrame, iconWidth, iconHeight, iconTint, animationTint, titleColor, titleFontSize, titleFontWeight, titleDarkColor, userInterfaceStyle, titleLines, titleLineHeight, titleSpacing': function () {
      this.cyl_update()
    },
    'itemStyle, countdownIdleTitle, countdownRunningTitleFormat, countdownFinishedTitle, countdownImage, countdownRunningTitleColor, countdownDuration': function (itemStyle) {
      if (itemStyle !== 'countdown' && this.cylCountdown && this.data.countdownState !== 'idle') this.resetCountdown()
      this.cyl_update()
    },
    'countdownCacheKey, itemStyle': function (key, itemStyle) {
      if (itemStyle === 'countdown') this.cyl_countdown().setCacheKey(key)
    },
    'showsImageWhenAnimationEnds': function (shows) {
      if (!shows) this.cyl_showAnimationAgain()
    },
    'selected, restingProgress': function () {
      this.cyl_showAnimationAgain()
      this.cyl_update()
      if (!this.data.autoplay || this.data.gifFirstFrame || this.data.gifLastFrame) {
        // [EN] No longer selected: stop the engine (and any play still waiting for it) before showing the resting frame, so
        //      two tabs never look selected (the iOS contract: a switch stops and resets the other tabs).
        // [CN] 不再被选中：先停止引擎（以及仍在等待它的播放），再显示静止帧，避免两个 Tab 同时看起来是选中的（iOS 约定：切换时停止并重置其他 Tab）。
        if (!this.data.selected) this.cyl_halt()
        this.cyl_rest()
      }
      // [EN] Another tab is selected: a playing GIF image rests. [CN] 选中了其他 Tab：正在播放的 GIF 图片回到静止。
      if (!this.data.selected && this.data.gifImagePlaying) this.cyl_restGIFImage()
    },
    'loop': function () {
      if (this.data.loop) this.cyl_showAnimationAgain()
      // [EN] A GIF image: off lets the pass in progress end, on keeps it playing. [CN] GIF 图片：关闭时让当前一遍播完，开启时一直播放。
      if (this.data.gifImagePlaying) {
        clearTimeout(this.cylGIFImageTimer)
        if (!this.data.loop) this.cyl_scheduleGIFImageEnd()
      }
      // Engines take `loop` live; a GIF with stills is timed here: off lets the pass in progress end, on keeps it playing.
      if (!this.data.gifPlaying) return
      clearTimeout(this.cylGifTimer)
      if (!this.data.loop) this.cyl_scheduleGifEnd()
    },
  },

  lifetimes: {
    attached() {
      // [EN] The system theme, kept current while attached. [CN] 系统主题，挂载期间保持最新。
      let theme = 'light'
      try {
        const info = typeof wx.getAppBaseInfo === 'function' ? wx.getAppBaseInfo() : wx.getSystemInfoSync()
        theme = info.theme === 'dark' ? 'dark' : 'light'
      } catch {
        theme = 'light'
      }
      this.data.systemTheme = theme
      this.cylThemeListener = (result) => {
        this.data.systemTheme = result?.theme === 'dark' ? 'dark' : 'light'
        this.cyl_update()
      }
      if (typeof wx !== 'undefined' && typeof wx.onThemeChange === 'function') wx.onThemeChange(this.cylThemeListener)
      // [EN] A countdown kept before a restart continues. [CN] 重启之前保存的倒计时继续。
      if (this.data.itemStyle === 'countdown') this.cyl_countdown().setCacheKey(this.data.countdownCacheKey)
      this.cyl_update()
    },
    detached() {
      this.cyl_stopCountdownTimer()
      if (typeof wx !== 'undefined' && typeof wx.offAppShow === 'function' && this.cylAppShowListener) wx.offAppShow(this.cylAppShowListener)
      clearTimeout(this.cylGifTimer)
      clearTimeout(this.cylGIFImageTimer)
      if (typeof wx !== 'undefined' && typeof wx.offThemeChange === 'function' && this.cylThemeListener) wx.offThemeChange(this.cylThemeListener)
    },
  },

  methods: {
    /**
     * [EN] The countdown state machine of this item, made on first use with the local clock and the mini program storage.
     * [CN] 本条目的倒计时状态机，首次使用时以本地时钟与小程序存储创建。
     */
    cyl_countdown() {
      if (this.cylCountdown) return this.cylCountdown
      const storage = typeof wx !== 'undefined' && typeof wx.getStorageSync === 'function' ? {
        get: (name) => { try { return wx.getStorageSync(name) } catch { return null } },
        set: (name, value) => { try { wx.setStorageSync(name, value) } catch { /* [EN] a full storage only loses the restart case. [CN] 存储已满只会丢失重启恢复。 */ } },
        remove: (name) => { try { wx.removeStorageSync(name) } catch { /* [EN] nothing to drop. [CN] 没有可丢弃的内容。 */ } },
      } : null
      const countdown = new CYLAnimatedItemCountdown({
        storage,
        onChange: () => {
          const running = countdown.state === 'running'
          this.setData({ countdownState: countdown.state, countdownSeconds: countdown.shown })
          if (running) this.cyl_startCountdownTimer()
          else this.cyl_stopCountdownTimer()
          this.cyl_update()
        },
        onStart: () => this.triggerEvent('countdownstart', {}),
        onTick: (seconds) => this.triggerEvent('countdowntick', { seconds }),
        onFinish: () => this.triggerEvent('countdownfinish', {}),
      })
      this.cylCountdown = countdown
      // [EN] The time spent in the background counts: read the clock when the mini program is shown again.
      // [CN] 后台度过的时间计入：小程序再次显示时读取时钟。
      this.cylAppShowListener = () => countdown.refresh()
      if (typeof wx !== 'undefined' && typeof wx.onAppShow === 'function') wx.onAppShow(this.cylAppShowListener)
      return countdown
    },

    cyl_startCountdownTimer() {
      if (this.cylCountdownTimer) return
      this.cylCountdownTimer = setInterval(() => this.cyl_countdown().refresh(), CYL_COUNTDOWN_TICK_INTERVAL)
    },

    cyl_stopCountdownTimer() {
      clearInterval(this.cylCountdownTimer)
      this.cylCountdownTimer = null
    },

    /**
     * [EN] Starts (or restarts) the countdown for `seconds` (default `countdownDuration`, e.g. the server's "retry after").
     *      Switches the item to the countdown style when it is not. [CN] 开始（或重新开始）`seconds` 秒的倒计时（默认 `countdownDuration`，
     *      例如服务器返回的「多少秒后重试」）。条目不是倒计时样式时切换为倒计时样式。
     */
    startCountdown(seconds) {
      if (this.data.itemStyle !== 'countdown') {
        this.setData({ itemStyle: 'countdown' })
        this.cyl_countdown().setCacheKey(this.data.countdownCacheKey)
      }
      this.cyl_countdown().startFor(Number(seconds) > 0 ? Number(seconds) : this.data.countdownDuration)
    },

    /** [EN] Stops and goes idle, with no finish event. [CN] 停止并回到待机，不触发结束事件。 */
    resetCountdown() {
      this.cyl_countdown().reset()
    },

    /** [EN] Reads the clock now (done by the item itself). [CN] 立即读取时钟（条目自己会做）。 */
    refreshCountdown() {
      this.cyl_countdown().refresh()
    },

    cyl_update() {
      const m = cylAnimatedItemModel({ ...this.data })
      this.setData({ m })
      if ((m.gifImage || '') !== (this.cylGIFImageSource || '')) this.cyl_loadGIFImage(m.gifImage || '')
      else if (m.gifImage && this.cylGIFImageInfo && (m.iconTint || '') !== (this.cylGIFImageTint || '')) this.cyl_drawGIFImageStill()
    },

    /**
     * [EN] Reads and decodes a GIF image (a package or local file, or an http(s) URL), then draws its first frame.
     * [CN] 读取并解码 GIF 图片（代码包或本地文件，或 http(s) 地址），然后绘制其第一帧。
     */
    cyl_loadGIFImage(path) {
      this.cylGIFImageSource = path
      this.cylGIFImageInfo = null
      clearTimeout(this.cylGIFImageTimer)
      if (this.data.gifImageReady || this.data.gifImagePlaying) this.setData({ gifImageReady: false, gifImagePlaying: false })
      if (!path || typeof wx === 'undefined') return
      const decoded = (buffer) => {
        if (this.cylGIFImageSource !== path || !buffer) return
        const info = cylGIFImageInfo(new Uint8Array(buffer))
        if (!info) return
        this.cylGIFImageInfo = info
        this.cyl_drawGIFImageStill()
      }
      if (/^https?:\/\//.test(path)) {
        wx.request({ url: path, responseType: 'arraybuffer', success: (result) => {
          if (result.statusCode >= 200 && result.statusCode < 300) decoded(result.data)
        } })
        return
      }
      const fs = wx.getFileSystemManager()
      fs.readFile({ filePath: path, success: (result) => decoded(result.data), fail: () => {
        // [EN] A package path may also be read without its leading slash. [CN] 代码包路径也可以去掉开头的斜杠读取。
        if (path.startsWith('/')) fs.readFile({ filePath: path.slice(1), success: (result) => decoded(result.data) })
      } })
    },

    /** [EN] Draws the first frame of the GIF image, centered in a square canvas. [CN] 在正方形 canvas 中居中绘制 GIF 图片的第一帧。 */
    cyl_drawGIFImageStill() {
      const info = this.cylGIFImageInfo
      if (!info) return
      this.createSelectorQuery().select('#cyl-gif-image-still').fields({ node: true }).exec((result) => {
        const canvas = result?.[0]?.node
        if (!canvas || this.cylGIFImageInfo !== info) return
        const side = Math.max(info.width, info.height)
        canvas.width = side
        canvas.height = side
        const context = canvas.getContext('2d')
        const pixels = context.createImageData(info.width, info.height)
        pixels.data.set(info.frame)
        context.clearRect(0, 0, side, side)
        context.putImageData(pixels, Math.floor((side - info.width) / 2), Math.floor((side - info.height) / 2))
        // [EN] A template image (`iconTint`): the still takes the tint as the <image> does. [CN] 模板图片（`iconTint`）：静帧与 <image> 一样着色。
        const tint = this.data.m?.iconTint
        if (tint) {
          context.globalCompositeOperation = 'source-in'
          context.fillStyle = tint
          context.fillRect(0, 0, side, side)
          context.globalCompositeOperation = 'source-over'
        }
        this.cylGIFImageTint = tint || ''
        this.setData({ gifImageReady: true })
        this.cyl_update()
      })
    },

    /**
     * [EN] Plays the GIF image from its first frame: one pass, or until `loop` is turned off; then the still again.
     * [CN] 从第一帧播放 GIF 图片：播放一遍，或一直播放到关闭 `loop`；之后回到静帧。
     */
    cyl_playGIFImage() {
      clearTimeout(this.cylGIFImageTimer)
      this.cylGIFImageStartedAt = Date.now()
      // [EN] Setting the source again restarts the GIF from its first frame. [CN] 重新设置图片来源会让 GIF 从第一帧开始。
      this.setData({ gifImagePlaying: true, 'm.fallbackImage': '' }, () => {
        this.cyl_update()
        if (!this.data.loop) this.cyl_scheduleGIFImageEnd()
      })
    },

    /** [EN] The end of the pass in progress, then the still. [CN] 当前一遍结束后显示静帧。 */
    cyl_scheduleGIFImageEnd() {
      const duration = this.cylGIFImageInfo?.duration || 1000
      const elapsed = Date.now() - (this.cylGIFImageStartedAt || Date.now())
      this.cylGIFImageTimer = setTimeout(() => this.cyl_restGIFImage(), duration - (elapsed % duration))
    },

    /** [EN] Back to the first-frame still. [CN] 回到第一帧静帧。 */
    cyl_restGIFImage() {
      clearTimeout(this.cylGIFImageTimer)
      if (!this.data.gifImagePlaying) return
      // [EN] The canvas comes back empty: draw the still again. [CN] canvas 重新创建后为空：再次绘制静帧。
      this.setData({ gifImagePlaying: false }, () => this.cyl_drawGIFImageStill())
      this.cyl_update()
    },

    /** [EN] The engine component drew the file. [CN] 引擎组件已绘制该文件。 */
    cyl_onAnimationReady(event) {
      this.setData({ animationLoaded: true })
      // [EN] Forwarded as `animationready` with the engine's detail (e.g. `duration`). [CN] 以 `animationready` 转发，带引擎的 detail（如 `duration`）。
      this.triggerEvent('animationready', event?.detail || {})
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
      this.cyl_showAnimationAgain()
      const m = this.data.m
      if (m.gifImage && this.cylGIFImageInfo) {
        this.cyl_playGIFImage()
        return
      }
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
      this.cyl_showAnimationAgain()
      this.cyl_halt()
      this.cyl_rest()
    },

    /**
     * [EN] Cancels a play that waits for the file and stops the engine where it is (a seek alone, `cyl_setProgress`, does not stop
     *      SVGA or PAG, and Rive has no seek), so the resting frame that follows is the last thing drawn.
     * [CN] 取消仍在等待文件的播放，并让引擎停在当前位置（单独的跳转 `cyl_setProgress` 不会停止 SVGA 或 PAG，Rive 也没有跳转），
     *      这样随后显示的静止帧就是最后绘制的内容。
     */
    cyl_halt() {
      this.cylPendingPlay = false
      clearTimeout(this.cylGifTimer)
      if (this.data.gifImagePlaying) this.cyl_restGIFImage()
      if (!this.data.m.usesEngine || !this.data.animationLoaded) return
      const engine = this.selectComponent(CYL_ENGINE_ID)
      if (engine && typeof engine.cyl_pause === 'function') engine.cyl_pause()
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
        const last = Math.max(0, (player?.totalFrames || 1) - 1)
        engine.cyl_goToAndStop(Math.round(last * progress), true)
      } else if (typeof engine.cyl_rest === 'function') {
        engine.cyl_rest()
      } else if (typeof engine.cyl_stop === 'function') {
        // [EN] Rive: stopping resets its input, which is its resting state. [CN] Rive：停止会重置其输入，即静止状态。
        engine.cyl_stop()
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
        // [EN] A timed pass of a GIF with stills ended: the same as an engine's `complete`. [CN] 有静帧的 GIF 一遍计时结束：与引擎的 `complete` 相同。
        this.cyl_animationDidEnd()
        this.triggerEvent('animationcomplete', { type: 'gif' })
      }, duration - (elapsed % duration))
    },

    /**
     * [EN] A play-once pass ended: the still image replaces the animation when `showsImageWhenAnimationEnds`.
     * [CN] 只播放一次的一遍结束：开启 `showsImageWhenAnimationEnds` 时用静态图片替换动画。
     */
    cyl_animationDidEnd() {
      if (this.data.loop || !this.data.showsImageWhenAnimationEnds || this.data.animationEnded) return
      this.setData({ animationEnded: true })
      this.cyl_update()
    },

    /** [EN] The animation shows again in place of the still image. [CN] 重新显示动画，替换静态图片。 */
    cyl_showAnimationAgain() {
      if (!this.data.animationEnded) return
      this.setData({ animationEnded: false })
      this.cyl_update()
    },

    /**
     * [EN] No engine, a corrupt file or a failed download: back to the static image (or the placeholder), and once per type
     *      a log naming the package to add. [CN] 没有引擎、文件损坏或下载失败：回到静态图片（或占位图），并按类型输出一次需要安装的包。
     */
    cyl_onAnimationError(event) {
      this.setData({ animationFailed: true })
      this.cyl_update()
      // [EN] Forwarded as `animationerror` with the engine's detail (`message`); the item still falls back to its image.
      // [CN] 以 `animationerror` 转发，带引擎的 detail（`message`）；条目仍回到静态图片。
      this.triggerEvent('animationerror', event?.detail || {})
      const type = this.data.m.animationType
      if (type && !cylWarnedTypes.includes(type)) {
        cylWarnedTypes.push(type)
        console.warn(`[cyl-animated-item] ${type} animation (${this.data.animationUrl}) cannot play: ${event?.detail?.message || 'no engine'}. ` +
          `Showing the static image, or the placeholder without one. Install ${cylAnimatedItemPackage(type)} and set generic:cyl-${type}-view.`)
      }
    },

    /**
     * [EN] The engine finished a play (a non-looping pass): forwarded as `animationcomplete`, e.g. to count repeats.
     * [CN] 引擎播放结束（非循环的一遍）：以 `animationcomplete` 转发，例如用于统计重复次数。
     */
    cyl_onAnimationComplete(event) {
      this.cyl_animationDidEnd()
      this.triggerEvent('animationcomplete', event?.detail || {})
    },

    /** [EN] A looping play finished one pass: forwarded as `animationloopcomplete`. [CN] 循环播放完成一遍：以 `animationloopcomplete` 转发。 */
    cyl_onAnimationLoopComplete(event) {
      this.triggerEvent('animationloopcomplete', event?.detail || {})
    },

    /** [EN] The engine component, or null (no engine type, GIF, or not drawn yet). [CN] 引擎组件，没有时为 null。 */
    cyl_animationView() {
      return this.selectComponent(CYL_ENGINE_ID)
    },

    /**
     * [EN] Plays the animation from its first frame, or `offset` seconds in, when its engine can.
     * [CN] 引擎支持时，从首帧（或第 `offset` 秒）播放动画。
     */
    cyl_playFromStart(offset) {
      // [EN] A GIF image plays from its first frame (a selected tab, a re-tap, Play all). [CN] GIF 图片从第一帧播放（选中、再次点击、全部播放）。
      if (this.data.m.gifImage && this.cylGIFImageInfo) {
        this.cyl_playGIFImage()
        return
      }
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
      if (this.data.enabled && !this.data.embedded && this.data.countdownState !== 'running') {
        this.triggerEvent('itemtap', {})
        // [EN] After the page handled the tap (send the code there), the countdown starts. [CN] 页面处理点击（在那里发送验证码）之后开始倒计时。
        if (this.data.itemStyle === 'countdown' && this.data.startsCountdownOnTap) this.startCountdown()
      }
    },

    cyl_onLongPress() {
      if (this.data.enabled && !this.data.embedded) {
        this.triggerEvent('itemlongpress', {})
      }
    },

    cyl_onAccessoryTap() {
      if (this.data.enabled) {
        this.triggerEvent('accessorytap', {})
      }
    },

    cyl_onTouchStart(event) {
      if (!this.data.dragEnabled || this.data.embedded) return
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
