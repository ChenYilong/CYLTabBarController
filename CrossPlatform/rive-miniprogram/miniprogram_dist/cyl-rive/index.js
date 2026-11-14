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
const { cylRiveOptions, cylRiveColor } = require('./cyl_rive_options')

// [EN] A mini program cannot read files under miniprogram_npm, so the WebAssembly is copied to the package root
//      (cylMiniprogramAssets in package.json); set `wasmPath` when it lives elsewhere.
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
  } catch (error) {
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
            console.error(`cyl-rive: loading ${wasmPath} failed: ${error && error.message}`)
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
  const userData = (wx.env && wx.env.USER_DATA_PATH) || ''
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
    /** [EN] Seconds the input stays true (default 1, 0 keeps it). [CN] 输入保持 true 的秒数（默认 1，0 表示保持）。 */
    duration: { type: null, value: null },
    /** [EN] View model color path -> "#RRGGBB" (CYLTabBarRiveDarkColors). [CN] view model 颜色路径 -> 颜色。 */
    colors: { type: Object, value: null },
    /**
     * [EN] Repeats the play: after the input goes back to false, it turns true again until `loop` is off.
     * [CN] 重复播放：输入恢复为 false 后再次设为 true，直到关闭 `loop`。
     */
    loop: { type: Boolean, value: false },
    autoplay: { type: Boolean, value: true },
    /** [EN] Playback speed, above 0 (the render clock and the input duration). [CN] 播放速度，大于 0（渲染时钟与输入时长）。 */
    speed: { type: Number, value: 1 },
    restingFrame: { type: String, value: 'first' },
    fit: { type: String, value: 'contain' },
    label: { type: String, value: '' },
    /** [EN] The package path of rive.wasm.br. [CN] rive.wasm.br 的包内路径。 */
    wasmPath: { type: String, value: CYL_DEFAULT_WASM },
  },

  data: { cylCanvasId: '', cylSnapshot: '', cylCovered: CYL_USES_SNAPSHOTS },

  observers: {
    'path, artboard, stateMachine, colors, fit': function () {
      if (this.cylReady) {
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

    cyl_load() {
      const token = ++this.cylLoadToken
      this.cyl_destroy()
      if (!this.data.path) {
        return
      }
      const { path, options } = cylRiveOptions(this.data.path, this.data)
      this.createSelectorQuery()
        .select(`#${this.data.cylCanvasId}`)
        .fields({ node: true, size: true })
        .exec((result) => {
          const info = result && result[0]
          if (token !== this.cylLoadToken || !this.cylReady) {
            return
          }
          if (!info || !info.node) {
            this.triggerEvent('error', { message: 'cyl-rive: the canvas node is not available.' })
            return
          }
          const canvas = info.node
          const ratio = cylPixelRatio()
          canvas.width = Math.max(1, Math.round(info.width * ratio))
          canvas.height = Math.max(1, Math.round(info.height * ratio))
          cylReadBytes(path, (error, bytes) => {
            if (error) {
              this.triggerEvent('error', { message: error.message })
              return
            }
            cylLoadRuntime(this.data.wasmPath)
              .then((rive) => this.cyl_start(rive, canvas, bytes, options, token))
              .catch((failure) => this.triggerEvent('error', { message: `cyl-rive: ${failure && failure.message}` }))
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
        this.triggerEvent('error', { message: `cyl-rive: no artboard '${options.artboard || 'default'}'.` })
        return
      }
      let instance = null
      let isStateMachine = false
      const machine = options.stateMachine
        ? artboard.stateMachineByName(options.stateMachine)
        : (artboard.stateMachineCount() > 0 ? artboard.stateMachineByIndex(0) : null)
      if (machine) {
        instance = new rive.StateMachineInstance(machine, artboard)
        isStateMachine = true
      } else if (artboard.animationCount() > 0) {
        const animation = options.animation ? artboard.animationByName(options.animation) : artboard.animationByIndex(0)
        instance = new rive.LinearAnimationInstance(animation, artboard)
      }
      const state = { rive, canvas, renderer, file, artboard, instance, isStateMachine, options, playing: true, last: 0 }
      state.viewModelInstance = this.cyl_bindViewModel(state)
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
      } catch (error) {
        return null
      }
    },

    cyl_inputNames() {
      const instance = this.cylState && this.cylState.instance
      const names = []
      if (instance && instance.inputCount) {
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
      const instance = this.cylState && this.cylState.instance
      if (!instance || !instance.inputCount) {
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
      if (!state || !state.canvas.requestAnimationFrame) {
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
        instance.advance(elapsed)
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
      if (CYL_USES_SNAPSHOTS && Date.now() - (this.cylSnapshotAt || 0) >= CYL_SNAPSHOT_INTERVAL_MS) {
        this.cyl_captureSnapshot()
      }
      this.cyl_scheduleFrame()
    },

    /** [EN] Reads the canvas into the <image> (WeChat DevTools only). [CN] 把画布内容读入 <image>（仅微信开发者工具）。 */
    cyl_captureSnapshot() {
      const canvas = this.cylState && this.cylState.canvas
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
      const seconds = Number(offset) > 0 ? Number(offset) : 0
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
      const triggerInput = options.triggerInput && this.cyl_input(options.triggerInput)
      if (triggerInput) {
        triggerInput.asTrigger().fire()
        return
      }
      if (options.trigger && state.viewModelInstance && state.viewModelInstance.trigger(options.trigger)) {
        state.viewModelInstance.trigger(options.trigger).trigger()
        return
      }
      const boolInput = options.input && this.cyl_input(options.input)
      const activeName = options.active || (state.viewModelInstance && !boolInput ? 'active' : '')
      const activeProperty = activeName && state.viewModelInstance ? state.viewModelInstance.boolean(activeName) : null
      const setActive = (value) => {
        if (boolInput) {
          boolInput.asBool().value = value
        } else if (activeProperty) {
          activeProperty.value = value
        }
      }
      if (boolInput || activeProperty) {
        setActive(true)
        if (seconds > 0 && state.instance && typeof state.instance.advance === 'function') {
          // [EN] Catch up with the playback the previous tab bar started. [CN] 追上前一个 TabBar 已开始的播放。
          state.instance.advance(Math.min(seconds, 2))
        }
        if (options.duration > 0) {
          const speed = this.cyl_speed()
          state.inputTimer = setTimeout(() => {
            setActive(false)
            this.triggerEvent('complete', {})
            // [EN] Loop: play again after the icon settles, while `loop` is on. [CN] 循环：图标复位后再次播放，直到关闭 `loop`。
            if (this.data.loop) {
              state.inputTimer = setTimeout(() => {
                if (this.data.loop && this.cylState === state) {
                  this.triggerEvent('loopcomplete', {})
                  this.cyl_playFromStart()
                }
              }, 400 / speed)
            }
          }, Math.max(0, options.duration - seconds) * 1000 / speed)
        }
        return
      }
      if (!state.isStateMachine && state.instance) {
        state.instance.time = 0
      }
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
