/**
 * [EN] cyl-rive: a Rive animation component with the same properties, events and methods as cyl-lottie and cyl-pag,
 *      so cyl-tab-bar-item switches by file type. It runs @rive-app/canvas-advanced (../rive/canvas_advanced.js) on a
 *      <canvas type="2d">, with its WebAssembly loaded by WXWebAssembly from ../rive/rive.wasm.br (the approach of
 *      RiveViewer-miniapp's README). Rive icons have state machines instead of a timeline: playing sets the state
 *      machine boolean input (`input`) or the view model boolean (`active`) to true for `duration` seconds, or fires a
 *      trigger (`triggerInput` / `trigger`), like the iOS Rive subspec; options also come from the path's fragment
 *      ("icons.riv#artboard=CHAT&stateMachine=CHAT_Interactivity&input=active"). `colors` sets view model colors.
 *      Events: `ready`, `complete` (the input went back to false), `error`. Methods: cyl_play, cyl_pause, cyl_stop,
 *      cyl_playFromStart, cyl_input, cyl_animation.
 * [CN] cyl-rive：Rive 动画组件，属性、事件与方法与 cyl-lottie、cyl-pag 相同，因此 cyl-tab-bar-item 可以按文件类型切换。
 *      它在 <canvas type="2d"> 上运行 @rive-app/canvas-advanced（../rive/canvas_advanced.js），WebAssembly 由
 *      WXWebAssembly 从 ../rive/rive.wasm.br 加载（RiveViewer-miniapp README 中的方式）。Rive 图标使用状态机而不是
 *      时间线：播放时把状态机布尔输入（`input`）或 view model 布尔属性（`active`）设为 true，保持 `duration` 秒，或触发
 *      trigger（`triggerInput` / `trigger`），与 iOS 的 Rive 子库相同；选项也可以来自路径的 fragment
 *      （"icons.riv#artboard=CHAT&stateMachine=CHAT_Interactivity&input=active"）。`colors` 设置 view model 颜色。
 *      事件：`ready`、`complete`（输入恢复为 false）、`error`。方法：cyl_play、cyl_pause、cyl_stop、cyl_playFromStart、
 *      cyl_input、cyl_animation。
 */
const { Rive, CYLRiveEnvironment } = require('../rive/canvas_advanced.js')
const { cylRiveOptions, cylRiveColor, cylRivePlayKind, cylRiveLoopDelay, cylRiveNumberValues, cylRiveNextNumber } = require('./cyl_rive_options')

/**
 * [EN] A frame later, for an input switched off then on (as iOS and Android, 50 ms). [CN] 先关后开的输入在一帧之后打开（与 iOS、Android 一致，50 ms）。
 */
const CYL_RIVE_NEXT_FRAME_MS = 50

// [EN] A mini program cannot read files under miniprogram_npm, so the WebAssembly is copied to the package root
//      (cylMiniprogramAssets in package.json); set `wasmPath` when it lives elsewhere ('' keeps this default).
// [CN] 小程序不能读取 miniprogram_npm 下的文件，因此 WebAssembly 被复制到代码包根目录（package.json 中的
//      cylMiniprogramAssets）；放在其他位置时设置 `wasmPath`。
const CYL_DEFAULT_WASM = '/cyl-rive-miniprogram/rive.wasm.br'
let cylRuntime = null

/**
 * [EN] Whether the mini program runs in WeChat DevTools.
 * [CN] 小程序是否运行在微信开发者工具中。
 */
function cylIsDevTools() {
  try {
    const info = typeof wx.getDeviceInfo === 'function' ? wx.getDeviceInfo() : wx.getSystemInfoSync()
    return info.platform === 'devtools'
  } catch {
    return false
  }
}

/**
 * [EN] WeChat DevTools moves a canvas of a fixed bar with the page while it scrolls (see cyl-lottie). There, the Rive
 *      animation is shown as one <image> of its canvas, updated from the render loop at most every
 *      CYL_SNAPSHOT_INTERVAL_MS; the canvas only draws, off screen. Phones are not changed: they show the canvas.
 * [CN] 微信开发者工具在页面滚动时会让固定栏中的画布随页面移动（见 cyl-lottie）。因此在开发者工具中，Rive 动画只以一个
 *      <image> 显示其画布内容，由渲染循环最多每 CYL_SNAPSHOT_INTERVAL_MS 更新一次；画布只在屏幕外绘制。真机不变：显示画布。
 */
const CYL_USES_SNAPSHOTS = cylIsDevTools()
const CYL_SNAPSHOT_INTERVAL_MS = 33

/**
 * [EN] The Rive runtime, loaded once for every cyl-rive: WXWebAssembly instantiates the Brotli WebAssembly of the
 *      package (Emscripten's instantiateWasm hook).
 * [CN] Rive 运行时，所有 cyl-rive 只加载一次：WXWebAssembly 实例化包内的 Brotli WebAssembly（Emscripten 的
 *      instantiateWasm 钩子）。
 */
function cylLoadRuntime(wasmPath) {
  if (!cylRuntime) {
    cylRuntime = Rive({
      locateFile: () => wasmPath,
      instantiateWasm(imports, success) {
        WXWebAssembly.instantiate(wasmPath, imports)
          .then((result) => success(result.instance))
          .catch((error) => {
            cylRuntime = null
            console.error(`cyl-rive: loading ${wasmPath} failed: ${error ? error.message : error}`)
          })
        return {}
      },
    })
  }
  return cylRuntime
}

function cylPixelRatio() {
  try {
    return (typeof wx.getWindowInfo === 'function' ? wx.getWindowInfo() : wx.getSystemInfoSync()).pixelRatio || 2
  } catch (error) {
    return 2
  }
}

function cylReadBytes(path, callback) {
  const userData = wx.env?.USER_DATA_PATH || ''
  if (/^https?:\/\//.test(path) && !(userData && path.indexOf(userData) === 0)) {
    wx.request({
      url: path,
      responseType: 'arraybuffer',
      success: ({ data, statusCode }) => (statusCode >= 200 && statusCode < 300
        ? callback(null, data)
        : callback(new Error(`Loading '${path}' failed with HTTP status ${statusCode}.`))),
      fail: ({ errMsg }) => callback(new Error(errMsg)),
    })
    return
  }
  try {
    callback(null, wx.getFileSystemManager().readFileSync(path))
  } catch (error) {
    callback(new Error(`Reading '${path}' failed: ${error.message || error.errMsg || error}`))
  }
}

const CYL_FIT = { contain: 'contain', cover: 'cover', fill: 'fill' }

/**
 * [EN] Applies the first frame of a file that is not played yet: the state machine's entry state (or the animation's
 *      time 0) without moving on, so a file at rest shows its first frame.
 * [CN] 为尚未播放的文件应用第一帧：状态机的入口状态（或动画的 0 时刻），不再向前推进，因此静止的文件显示第一帧。
 */
function cylRivePoseFirstFrame(state) {
  const { instance, isStateMachine, artboard } = state
  if (!instance) {
    return
  }
  instance.advance(0)
  if (!isStateMachine) {
    instance.apply(1)
  }
  artboard.advance(0)
}

/**
 * [EN] The state machine to run: none when a named animation wins over the state machines (button.riv has both: its
 *      "active" animation is what plays), else the named one or the first.
 * [CN] 要运行的状态机：指定的动画优先于状态机时没有（button.riv 两者都有：播放的是其 "active" 动画），否则为指定的或第一个。
 */
function cylRiveMachine(artboard, options, namedAnimation) {
  if (namedAnimation) {
    return null
  }
  if (options.stateMachine) {
    return artboard.stateMachineByName(options.stateMachine)
  }
  return artboard.stateMachineCount() > 0 ? artboard.stateMachineByIndex(0) : null
}

/**
 * [EN] The instance that plays the artboard: a state machine instance, or a linear animation instance, or null.
 * [CN] 播放画板的实例：状态机实例、线性动画实例，或 null。
 */
function cylRiveInstance(rive, artboard, options) {
  const namedAnimation = options.animation && !options.stateMachine ? artboard.animationByName(options.animation) : null
  const machine = cylRiveMachine(artboard, options, namedAnimation)
  if (machine) {
    return { machine, instance: new rive.StateMachineInstance(machine, artboard), isStateMachine: true }
  }
  if (artboard.animationCount() > 0) {
    const animation = options.animation ? artboard.animationByName(options.animation) : artboard.animationByIndex(0)
    return { machine, instance: new rive.LinearAnimationInstance(animation, artboard), isStateMachine: false }
  }
  return { machine, instance: null, isStateMachine: false }
}

Component({
  properties: {
    /** [EN] A .riv file (or a .riv.bin package copy), with optional options in its fragment. [CN] .riv 文件（或包内的 .riv.bin 副本），fragment 中可带选项。 */
    path: { type: String, value: '' },
    artboard: { type: String, value: '' },
    stateMachine: { type: String, value: '' },
    /** [EN] Legacy state machine boolean input set to true when playing. [CN] 播放时设为 true 的状态机布尔输入（旧版）。 */
    input: { type: String, value: '' },
    /** [EN] Legacy state machine trigger input fired when playing. [CN] 播放时触发的状态机 trigger 输入（旧版）。 */
    triggerInput: { type: String, value: '' },
    /** [EN] View model boolean set to true when playing (default "active" with a view model). [CN] 播放时设为 true 的 view model 布尔属性。 */
    active: { type: String, value: '' },
    /** [EN] View model trigger fired instead. [CN] 改为触发的 view model trigger。 */
    trigger: { type: String, value: '' },
    /**
     * [EN] A state machine NUMBER input set on each play (house.riv: `Rooms`), with `values`. [CN] 每次播放设置的状态机 NUMBER 输入（house.riv：`Rooms`），配合 `values`。
     */
    numberInput: { type: String, value: '' },
    /**
     * [EN] Data binding: a view model number property path set on each play, with `values`. [CN] 数据绑定：每次播放设置的 view model 数字属性路径，配合 `values`。
     */
    number: { type: String, value: '' },
    /**
     * [EN] The numbers a play steps through, "3,4,5,6" (the next one each time, cycling); empty: +1. [CN] 每次播放依次使用的数字，"3,4,5,6"（每次取下一个，循环）；为空时 +1。
     */
    values: { type: String, value: '' },
    /** [EN] Seconds the input stays true (default 1, 0 keeps it). [CN] 输入保持 true 的秒数（默认 1，0 表示保持）。 */
    duration: { type: null, value: null },
    /** [EN] View model color path -> "#RRGGBB" (CYLTabBarRiveDarkColors). [CN] view model 颜色路径 -> 颜色。 */
    colors: { type: Object, value: null },
    /**
     * [EN] Repeats the play until `loop` is off: after the input goes back to false, or after each pass of a trigger, a
     *      held input or a state machine (cylRiveLoopDelay); turning it on plays at once.
     * [CN] 重复播放，直到关闭 `loop`：输入恢复为 false 后，或 trigger、保持的输入、状态机每播放一次后（cylRiveLoopDelay）；打开时立即播放。
     */
    loop: { type: Boolean, value: false },
    autoplay: { type: Boolean, value: true },
    /** [EN] Playback speed, above 0 (the render clock and the input duration). [CN] 播放速度，大于 0（渲染时钟与输入时长）。 */
    speed: { type: Number, value: 1 },
    restingFrame: { type: String, value: 'first' },
    fit: { type: String, value: 'contain' },
    label: { type: String, value: '' },
    /**
     * [EN] One color for the whole drawing (any CSS color), like a template image tinted on iOS: every drawn pixel takes
     *      it and keeps its alpha. '' keeps the file's own colors. cyl-tab-bar-item sets it from the `tint` option.
     * [CN] 整个画面使用一种颜色（任意 CSS 颜色），如同 iOS 上着色的模板图片：每个已绘制的像素取该颜色并保留透明度。
     *      '' 保持文件自身的颜色。cyl-tab-bar-item 根据 `tint` 选项设置它。
     */
    tint: { type: String, value: '' },
    /** [EN] The package path of rive.wasm.br. [CN] rive.wasm.br 的包内路径。 */
    wasmPath: { type: String, value: CYL_DEFAULT_WASM },
  },

  data: { cylCanvasId: '', cylSnapshot: '', cylCovered: CYL_USES_SNAPSHOTS },

  observers: {
    loop(loop) {
      // [EN] On: play now (each pass schedules the next); off: no further pass. [CN] 打开：立即播放（每次播放安排下一次）；关闭：不再安排。
      const state = this.cylState
      if (!state) {
        return
      }
      if (loop && !state.loopTimer) {
        this.cyl_playFromStart()
      } else if (!loop) {
        clearTimeout(state.loopTimer)
        state.loopTimer = null
      }
    },
    'path, artboard, stateMachine, colors, fit': function () {
      // [EN] WeChat runs an observer on every set, even with the same value: a host that re-renders (cyl-animated-item
      //      after `ready`) restarted the load dozens of times a second, so the file never played (bugs B8 / B11,
      //      docs/Animated-Item.md). Reload only when an input really changed, or after a failed load.
      // [CN] 微信在每次设置时都会运行 observer，即使值相同：重新渲染的宿主（`ready` 后的 cyl-animated-item）每秒重启加载数十次，
      //      文件永远不播放（问题 B8 / B10）。只在输入确实变化或加载失败后重新加载。
      if (this.cylReady && (this.cyl_loadKey() !== this.cylLoadKey || this.cylLoadFailed)) {
        this.cyl_load()
      }
    },
  },

  lifetimes: {
    created() {
      this.cylLoadToken = 0
    },
    attached() {
      this.setData({ cylCanvasId: `cyl-rive-${Math.random().toString(36).slice(2, 10)}` })
    },
    ready() {
      this.cylReady = true
      this.cyl_load()
    },
    detached() {
      this.cylReady = false
      this.cyl_destroy()
    },
  },

  methods: {
    cyl_destroy() {
      const state = this.cylState
      this.cylState = null
      if (!state) {
        return
      }
      if (state.frame && state.canvas.cancelAnimationFrame) {
        state.canvas.cancelAnimationFrame(state.frame)
      }
      clearTimeout(state.inputTimer)
      ;['instance', 'artboard', 'file', 'renderer'].forEach((key) => {
        try {
          if (state[key] && typeof state[key].delete === 'function') {
            state[key].delete()
          } else if (state[key] && typeof state[key].unref === 'function') {
            state[key].unref()
          }
        } catch (error) {}
      })
    },

    /** [EN] A failed load: the same inputs may load again. [CN] 加载失败：相同输入可再次加载。 */
    cyl_reportError(detail) {
      this.cylLoadFailed = true
      this.triggerEvent('error', detail)
    },

    /** [EN] The inputs of a load. [CN] 一次加载的输入。 */
    cyl_loadKey() {
      return JSON.stringify([this.data.path, this.data.artboard, this.data.stateMachine, this.data.colors, this.data.fit])
    },

    cyl_load() {
      const token = ++this.cylLoadToken
      this.cylLoadKey = this.cyl_loadKey()
      this.cylLoadFailed = false
      this.cyl_destroy()
      if (!this.data.path) {
        return
      }
      const { path, options } = cylRiveOptions(this.data.path, this.data)
      this.createSelectorQuery()
        .select(`#${this.data.cylCanvasId}`)
        .fields({ node: true, size: true })
        .exec((result) => {
          const info = result?.[0]
          if (token !== this.cylLoadToken || !this.cylReady) {
            return
          }
          if (!info?.node) {
            this.cyl_reportError( { message: 'cyl-rive: the canvas node is not available.' })
            return
          }
          const canvas = info.node
          const ratio = cylPixelRatio()
          canvas.width = Math.max(1, Math.round(info.width * ratio))
          canvas.height = Math.max(1, Math.round(info.height * ratio))
          cylReadBytes(path, (error, bytes) => {
            if (error) {
              this.cyl_reportError( { message: error.message })
              return
            }
            cylLoadRuntime(this.data.wasmPath || CYL_DEFAULT_WASM)
              .then((rive) => this.cyl_start(rive, canvas, bytes, options, token))
              .catch((error_) => this.cyl_reportError( { message: `cyl-rive: ${error_ ? error_.message : error_}` }))
          })
        })
    },

    async cyl_start(rive, canvas, bytes, options, token) {
      if (token !== this.cylLoadToken || !this.cylReady) {
        return
      }
      CYLRiveEnvironment.canvas = canvas
      const renderer = rive.makeRenderer(canvas)
      const file = await rive.load(new Uint8Array(bytes), undefined, false)
      if (token !== this.cylLoadToken || !this.cylReady) {
        file.unref()
        return
      }
      const artboard = options.artboard ? file.artboardByName(options.artboard) : file.defaultArtboard()
      if (!artboard) {
        this.cyl_reportError( { message: `cyl-rive: no artboard '${options.artboard || 'default'}'.` })
        return
      }
      const { machine, instance, isStateMachine } = cylRiveInstance(rive, artboard, options)
      // [EN] Rests on its first frame until it is played (docs/Animated-Item.md): a file whose state machine moves by itself
      //      (shapes.riv, truck.riv) no longer runs from load. A play, a loop pass or cyl_play() starts it.
      // [CN] 在被播放之前停在第一帧：状态机会自行运动的文件（shapes.riv、truck.riv）不再从加载起就运动。播放、循环或 cyl_play() 才开始。
      const state = { rive, canvas, renderer, file, artboard, instance, isStateMachine, options, playing: false, last: 0,
        machine: isStateMachine ? machine : null, animationSeconds: isStateMachine ? 0 : this.cyl_animationSeconds(instance) }
      state.viewModelInstance = this.cyl_bindViewModel(state)
      cylRivePoseFirstFrame(state)
      this.cylState = state
      this.cyl_scheduleFrame()
      this.triggerEvent('ready', {
        artboard: artboard.name,
        stateMachine: isStateMachine ? machine.name : '',
        inputs: isStateMachine ? this.cyl_inputNames() : [],
      })
      if (this.cylPendingPlay) {
        const pending = this.cylPendingPlay
        this.cyl_playFromStart(pending.seconds + (Date.now() - pending.requestedAt) / 1000)
      } else if (this.data.autoplay && this.data.loop) {
        this.cyl_playFromStart()
      }
    },

    /**
     * [EN] Binds the artboard's default view model instance (when the file has one) and applies `colors` to it.
     * [CN] 绑定画板的默认 view model 实例（文件有 view model 时），并把 `colors` 应用到它。
     */
    cyl_bindViewModel(state) {
      try {
        // [EN] Ask only when the file has view models: the runtime logs an error for an artboard without one.
        // [CN] 只在文件有 view model 时获取：画板没有 view model 时运行时会输出错误。
        if (typeof state.file.viewModelCount === 'function' && state.file.viewModelCount() === 0) {
          return null
        }
        const viewModel = state.file.defaultArtboardViewModel(state.artboard)
        if (!viewModel) {
          return null
        }
        const viewModelInstance = viewModel.defaultInstance()
        const colors = this.data.colors || {}
        Object.keys(colors).forEach((key) => {
          const color = cylRiveColor(colors[key])
          const property = viewModelInstance.color(key)
          if (color !== null && property) {
            property.value = color
          }
        })
        if (state.isStateMachine && state.instance.bindViewModelInstance) {
          state.instance.bindViewModelInstance(viewModelInstance)
        }
        return viewModelInstance
      } catch {
        return null
      }
    },

    cyl_inputNames() {
      const instance = this.cylState?.instance
      const names = []
      if (instance?.inputCount) {
        for (let index = 0; index < instance.inputCount(); index += 1) {
          names.push(instance.input(index).name)
        }
      }
      return names
    },

    /**
     * [EN] The state machine input with this name, or null.
     * [CN] 该名称的状态机输入，没有时返回 null。
     */
    cyl_input(name) {
      const instance = this.cylState?.instance
      if (!instance?.inputCount) {
        return null
      }
      for (let index = 0; index < instance.inputCount(); index += 1) {
        const input = instance.input(index)
        if (input.name === name) {
          return input
        }
      }
      return null
    },

    cyl_scheduleFrame() {
      const state = this.cylState
      if (!state?.canvas.requestAnimationFrame) {
        return
      }
      state.frame = state.canvas.requestAnimationFrame((time) => this.cyl_drawFrame(time))
    },

    cyl_drawFrame(time) {
      const state = this.cylState
      if (!state) {
        return
      }
      const elapsed = (state.last ? Math.min(0.1, (time - state.last) / 1000) : 0) * this.cyl_speed()
      state.last = time
      const { rive, renderer, artboard, instance, canvas } = state
      CYLRiveEnvironment.canvas = canvas
      if (state.playing && instance) {
        // [EN] advance() answers whether it is still moving: a loop pass restarts a file only once it has settled.
        // [CN] advance() 返回是否仍在运动：循环只在文件停止运动后才重新开始它。
        const moving = instance.advance(elapsed)
        state.settled = moving === false
        if (!state.isStateMachine) {
          instance.apply(1)
        }
      }
      artboard.advance(state.playing ? elapsed : 0)
      renderer.clear()
      renderer.save()
      renderer.align(rive.Fit[CYL_FIT[this.data.fit] || 'contain'], rive.Alignment.center,
        { minX: 0, minY: 0, maxX: canvas.width, maxY: canvas.height }, artboard.bounds)
      artboard.draw(renderer)
      renderer.restore()
      rive.resolveAnimationFrame()
      this.cyl_applyTint(canvas)
      if (CYL_USES_SNAPSHOTS && Date.now() - (this.cylSnapshotAt || 0) >= CYL_SNAPSHOT_INTERVAL_MS) {
        this.cyl_captureSnapshot()
      }
      this.cyl_scheduleFrame()
    },

    /**
     * [EN] Paints `tint` over the drawn pixels only (source-atop keeps their alpha), after Rive flushed the frame.
     * [CN] 在 Rive 提交本帧后，只在已绘制的像素上涂 `tint`（source-atop 保留其透明度）。
     */
    cyl_applyTint(canvas) {
      const tint = String(this.data.tint || '').trim()
      if (!tint || typeof canvas.getContext !== 'function') {
        return
      }
      const context = canvas.getContext('2d')
      if (!context) {
        return
      }
      context.save()
      context.setTransform(1, 0, 0, 1, 0, 0)
      context.globalCompositeOperation = 'source-atop'
      context.fillStyle = tint
      context.fillRect(0, 0, canvas.width, canvas.height)
      context.restore()
    },

    /** [EN] Reads the canvas into the <image> (WeChat DevTools only). [CN] 把画布内容读入 <image>（仅微信开发者工具）。 */
    cyl_captureSnapshot() {
      const canvas = this.cylState?.canvas
      if (!canvas || typeof canvas.toDataURL !== 'function') {
        return
      }
      this.cylSnapshotAt = Date.now()
      try {
        const snapshot = canvas.toDataURL('image/png')
        if (snapshot !== this.data.cylSnapshot) {
          this.setData({ cylSnapshot: snapshot })
        }
      } catch (error) {
        // [EN] Keep the last frame. [CN] 保留上一帧。
      }
    },

    /**
     * [EN] Plays the icon: sets its boolean input / view model boolean to true for `duration` seconds, or fires its
     *      trigger; a file without inputs restarts its animation.
     * [CN] 播放图标：把布尔输入 / view model 布尔属性设为 true 并保持 `duration` 秒，或触发 trigger；没有输入的文件
     *      重新播放其动画。
     */
    cyl_playFromStart(offset) {
      // [EN] `offset` (seconds) continues a playback another tab bar started: each tab page has its own tab bar.
      // [CN] `offset`（秒）继续另一个 TabBar 已开始的播放：每个 Tab 页面都有自己的 TabBar。
      const seconds = Math.max(0, Number(offset) || 0)
      const state = this.cylState
      if (!state) {
        // [EN] A play request made while the file loads (a new tab page's tab bar selects its tab at once) runs when it is ready.
        // [CN] 文件加载期间的播放请求（新 Tab 页面的 TabBar 会立即选中其 Tab）在就绪后执行。
        this.cylPendingPlay = {seconds, requestedAt: Date.now()}
        return
      }
      this.cylPendingPlay = null
      state.playing = true
      const { options } = state
      clearTimeout(state.inputTimer)
      clearTimeout(state.loopTimer)
      const inputs = this.cyl_playInputs(state)
      const { boolInput, activeProperty, numberInput, numberProperty } = inputs
      const kind = cylRivePlayKind({ hasTriggerInput: !!inputs.triggerInput, hasViewModelTrigger: !!inputs.viewModelTrigger,
        hasNumber: !!(numberInput || numberProperty), hasBoolInput: !!(boolInput || activeProperty) })
      const speed = this.cyl_speed()
      if (kind === 'trigger') {
        // [EN] A trigger does nothing once its state machine has reached the end (check.riv stayed on its finished check):
        //      restart it, then fire on the new instance a frame later.
        // [CN] 状态机到达结束状态后 trigger 不再起作用（check.riv 停在完成的对勾上）：先重新开始，一帧之后在新实例上触发。
        this.cyl_restart(state)
        state.inputTimer = setTimeout(() => {
          const restarted = this.cylState === state && options.triggerInput && this.cyl_input(options.triggerInput)
          if (restarted) {
            restarted.asTrigger().fire()
          }
        }, 50)
      } else if (kind === 'viewModelTrigger') {
        inputs.viewModelTrigger.trigger()
      } else if (kind === 'number') {
        // [EN] The next value (house.riv moves only when `Rooms` changes). [CN] 下一个值（house.riv 只在 `Rooms` 变化时运动）。
        const target = numberInput ? numberInput.asNumber() : numberProperty
        target.value = cylRiveNextNumber(cylRiveNumberValues(options.values), target.value)
      } else if (kind === 'input') {
        this.cyl_playInput(state, inputs, seconds, speed)
      } else {
        this.cyl_restart(state)
      }
      this.cyl_scheduleLoop(state, kind, seconds, speed)
    },

    /**
     * [EN] The inputs and view model properties the options name, for a play.
     * [CN] 选项指定的输入与 view model 属性，用于一次播放。
     */
    cyl_playInputs(state) {
      const { options } = state
      const triggerInput = options.triggerInput && this.cyl_input(options.triggerInput)
      const viewModelTrigger = options.trigger && state.viewModelInstance ? state.viewModelInstance.trigger(options.trigger) : null
      const boolInput = options.input && this.cyl_input(options.input)
      const activeName = options.active || (state.viewModelInstance && !boolInput ? 'active' : '')
      const activeProperty = activeName && state.viewModelInstance ? state.viewModelInstance.boolean(activeName) : null
      const numberInput = options.numberInput && this.cyl_input(options.numberInput)
      const numberProperty = options.number && state.viewModelInstance ? state.viewModelInstance.number(options.number) : null
      return { triggerInput, viewModelTrigger, boolInput, activeProperty, numberInput, numberProperty }
    },

    /**
     * [EN] Plays a boolean input or view model boolean (`kind` 'input'). [CN] 播放布尔输入或 view model 布尔属性（`kind` 为 'input'）。
     */
    cyl_playInput(state, inputs, seconds, speed) {
      const { options } = state
      const { boolInput, activeProperty } = inputs
      const kind = 'input'
      const setActive = (value) => {
        if (boolInput) {
          boolInput.asBool().value = value
        } else if (activeProperty) {
          activeProperty.value = value
        }
      }
      // [EN] A play always changes the value. An input already on (held, duration 0) goes off first, and the state
      //      machine needs real time with frames drawn in the off state: off and on in the same tick (advance(0))
      //      never ran the close transition, so the mini program's menu_button stayed open (isOpen read true at
      //      every 250 ms sample in DevTools). On a later frame (50 ms, as iOS and Android), or half a loop pass
      //      while looping a held input, so it opens and closes in turn.
      // [CN] 每次播放都会改变取值。已经为 true 的输入（保持、duration 为 0）先设为 false，状态机需要在 false 状态下经过真实时间并绘制帧：
      //      同一个 tick 内先关后开（advance(0)）不会运行关闭过渡，小程序的 menu_button 一直停在打开状态（DevTools 中每 250 ms 读取
      //      isOpen 都是 true）。在之后的帧（50 ms，与 iOS、Android 一致）再打开；循环保持的输入时等半个循环周期，使其交替打开与关闭。
      const turnOn = () => {
        setActive(true)
        if (seconds > 0 && state.instance && typeof state.instance.advance === 'function') {
          // [EN] Catch up with the playback the previous tab bar started. [CN] 追上前一个 TabBar 已开始的播放。
          state.instance.advance(Math.min(seconds, 2))
        }
        if (options.duration > 0) {
          state.inputTimer = setTimeout(() => {
            setActive(false)
            this.triggerEvent('complete', {})
          }, Math.max(0, options.duration - seconds) * 1000 / speed)
        }
      }
      const isOn = boolInput ? boolInput.asBool().value === true : !!activeProperty?.value
      if (isOn) {
        setActive(false)
        const offMs = this.data.loop && !(options.duration > 0)
          ? cylRiveLoopDelay({ kind, duration: options.duration, animationSeconds: state.animationSeconds, speed }) / 2
          : CYL_RIVE_NEXT_FRAME_MS
        state.inputTimer = setTimeout(() => {
          if (this.cylState === state) {
            turnOn()
          }
        }, offMs)
      } else {
        turnOn()
      }
    },

    /**
     * [EN] Schedules the next pass while `loop` is on. [CN] `loop` 打开时安排下一次播放。
     */
    cyl_scheduleLoop(state, kind, seconds, speed) {
      const { options } = state
      // [EN] Loop (docs/Animated-Item.md, the Rive loop): every kind plays again after its pass, while `loop` is on.
      // [CN] 循环（docs/Animated-Item.md，Rive 循环）：每种播放方式在一次播放后再次播放，直到关闭 `loop`。
      if (!this.data.loop) {
        return
      }
      const delay = cylRiveLoopDelay({ kind, duration: options.duration, animationSeconds: state.animationSeconds, speed })
      const pass = () => {
        if (!this.data.loop || this.cylState !== state) {
          return
        }
        // [EN] A file that keeps moving on its own (shapes.riv, truck.riv loop by themselves) is not cut short: check
        //      again after another pass. [CN] 自己持续运动的文件（shapes.riv、truck.riv 自身循环）不被打断：再等一次检查。
        if (kind === 'restart' && !state.settled) {
          state.loopTimer = setTimeout(pass, delay)
          return
        }
        this.triggerEvent('loopcomplete', {})
        this.cyl_playFromStart()
      }
      state.loopTimer = setTimeout(pass, Math.max(0, delay - seconds * 1000 / speed))
    },

    /**
     * [EN] Restarts the icon: a state machine gets a new instance (with the view model bound again), an animation goes back
     *      to its start. A state machine at its end state (or one whose input the options do not name) plays again.
     * [CN] 重新开始图标：状态机创建新实例（重新绑定 view model），动画回到开头。处于结束状态的状态机（或选项未指定其输入的状态机）也能再次播放。
     */
    cyl_restart(state) {
      if (state.isStateMachine && state.machine) {
        const previous = state.instance
        state.instance = new state.rive.StateMachineInstance(state.machine, state.artboard)
        if (state.viewModelInstance && typeof state.instance.bindViewModelInstance === 'function') {
          state.instance.bindViewModelInstance(state.viewModelInstance)
        }
        if (previous && typeof previous.delete === 'function') {
          previous.delete()
        }
      } else if (state.instance) {
        state.instance.time = 0
      }
    },

    /** [EN] A linear animation's length in seconds (0 when unknown). [CN] 线性动画的时长（秒，未知时为 0）。 */
    cyl_animationSeconds(instance) {
      const animation = instance?.animation
      if (animation && Number(animation.duration) > 0 && Number(animation.fps) > 0) {
        return Number(animation.duration) / Number(animation.fps)
      }
      return instance && Number(instance.duration) > 0 ? Number(instance.duration) : 0
    },

    /** [EN] The speed in use (1 when not above 0). [CN] 当前速度（不大于 0 时为 1）。 */
    cyl_speed() {
      const speed = Number(this.data.speed)
      return speed > 0 ? speed : 1
    },

    /** [EN] Changes the speed, also of the playing animation. [CN] 修改速度，正在播放的动画同样生效。 */
    cyl_setSpeed(speed) {
      if (Number(speed) > 0) {
        this.setData({ speed: Number(speed) })
      }
    },

    cyl_play() {
      if (this.cylState) {
        this.cylState.playing = true
      }
    },

    cyl_pause() {
      if (this.cylState) {
        this.cylState.playing = false
      }
    },

    /** [EN] Stops: the input goes back to false. [CN] 停止：输入恢复为 false。 */
    cyl_stop() {
      const state = this.cylState
      if (!state) {
        return
      }
      clearTimeout(state.inputTimer)
      clearTimeout(state.loopTimer)
      state.loopTimer = null
      const input = state.options.input && this.cyl_input(state.options.input)
      if (input) {
        input.asBool().value = false
      }
    },

    /** [EN] {rive, file, artboard, instance} or null. [CN] 返回 {rive, file, artboard, instance}，没有时为 null。 */
    cyl_animation() {
      const state = this.cylState
      return state ? { rive: state.rive, file: state.file, artboard: state.artboard, instance: state.instance } : null
    },
  },
})
