/**
 * [EN] cyl-pag: a PAG animation component on libpag-miniprogram (Tencent/libpag web, the full WebAssembly + WebGL build,
 *      vendored in ../libpag), with the same properties, events and methods as cyl-lottie, so cyl-tab-bar-item
 *      switches by file type. It sets up its own <canvas type="webgl">, sized for the pixel ratio, reads `path` (a
 *      package file, a user data file or a network URL) as an ArrayBuffer and plays it. The full build plays vector
 *      PAG files such as the iOS example's tab icons (libpag-lite played BMP sequences only). Events: `ready`
 *      (duration in seconds), `complete`, `loopcomplete`, `error`. Methods: cyl_play, cyl_pause, cyl_stop,
 *      cyl_playFromStart, cyl_setProgress, cyl_animation.
 * [CN] cyl-pag：基于 libpag-miniprogram（Tencent/libpag web 的完整 WebAssembly + WebGL 版本，内置于 ../libpag）的 PAG
 *      动画组件，属性、事件与方法与 cyl-lottie 相同，因此 cyl-tab-bar-item 可以按文件类型切换。组件自己创建
 *      <canvas type="webgl">，按像素比设置尺寸，把 `path`（包内文件、用户数据目录文件或网络地址）读为 ArrayBuffer
 *      并播放。完整版本可以播放矢量 PAG 文件，例如 iOS 示例的 Tab 图标（libpag-lite 只能播放 BMP 序列帧）。事件：
 *      `ready`（时长，单位秒）、`complete`、`loopcomplete`、`error`。方法：cyl_play、cyl_pause、cyl_stop、
 *      cyl_playFromStart、cyl_setProgress、cyl_animation。
 */
const { PAGInit } = require('../libpag/libpag.js')

// [EN] A mini program cannot read files under miniprogram_npm, so the WebAssembly is copied to the package root
//      (cylMiniprogramAssets in package.json); set `wasmPath` when it lives elsewhere.
// [CN] 小程序不能读取 miniprogram_npm 下的文件，因此 WebAssembly 被复制到代码包根目录（package.json 中的
//      cylMiniprogramAssets）；放在其他位置时设置 `wasmPath`。
const CYL_DEFAULT_WASM = '/cyl-pag-miniprogram/libpag.wasm.br'
// [EN] PAGScaleMode of libpag. [CN] libpag 的 PAGScaleMode。
const CYL_SCALE_MODES = { fill: 1, contain: 2, cover: 3 }
let cylModule = null

/**
 * [EN] The libpag module, loaded once for every cyl-pag; a failed load is retried by the next cyl-pag.
 * [CN] libpag 模块，所有 cyl-pag 只加载一次；加载失败时由下一个 cyl-pag 重试。
 */
function cylLoadPAG(wasmPath) {
  if (!cylModule) {
    cylModule = PAGInit({ locateFile: () => wasmPath }).catch((error) => {
      cylModule = null
      throw error
    })
  }
  return cylModule
}

function cylPixelRatio() {
  try {
    return (typeof wx.getWindowInfo === 'function' ? wx.getWindowInfo() : wx.getSystemInfoSync()).pixelRatio || 2
  } catch (error) {
    return 2
  }
}

/**
 * [EN] Reads a PAG file as an ArrayBuffer: http(s) with wx.request, anything else (a package path, the user data
 *      folder, which is "http://usr" in the DevTools) with the file system.
 * [CN] 把 PAG 文件读为 ArrayBuffer：http(s) 使用 wx.request，其他（包内路径、用户数据目录，在开发者工具中为
 *      "http://usr"）使用文件系统。
 */
function cylReadPAG(path, callback) {
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

Component({
  properties: {
    /** [EN] A .pag file: package path, user data path or URL. [CN] .pag 文件：包内路径、用户数据路径或网络地址。 */
    path: { type: String, value: '' },
    loop: { type: Boolean, value: false },
    autoplay: { type: Boolean, value: true },
    /** [EN] "first" or "last": the frame shown before playing and after cyl_stop(). [CN] 播放前与停止后显示的帧。 */
    restingFrame: { type: String, value: 'first' },
    /** [EN] contain (LetterBox), cover (Zoom) or fill (Stretch). [CN] 缩放方式。 */
    fit: { type: String, value: 'contain' },
    /** [EN] Accepted for parity with cyl-lottie; PAG files carry their own colors. [CN] 为与 cyl-lottie 一致而保留；PAG 文件自带颜色。 */
    colors: { type: Object, value: null },
    label: { type: String, value: '' },
    /** [EN] libpag.wasm.br in the code package. [CN] 代码包内的 libpag.wasm.br。 */
    wasmPath: { type: String, value: CYL_DEFAULT_WASM },
  },

  data: { cylCanvasId: '' },

  observers: {
    'path, fit': function () {
      if (this.cylReady) {
        this.cyl_load()
      }
    },
    'loop, autoplay, restingFrame': function (loop, autoplay) {
      const view = this.cylView
      if (!view) {
        return
      }
      view.setRepeatCount(loop ? 0 : 1)
      if (autoplay) {
        view.play()
      } else if (!view.isPlaying) {
        this.cyl_rest()
      }
    },
  },

  lifetimes: {
    created() {
      this.cylLoadToken = 0
    },
    attached() {
      this.setData({ cylCanvasId: `cyl-pag-${Math.random().toString(36).slice(2, 10)}` })
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
      if (this.cylView) {
        try {
          this.cylView.destroy()
        } catch (error) {}
        this.cylView = null
      }
      if (this.cylFile) {
        try {
          this.cylFile.destroy()
        } catch (error) {}
        this.cylFile = null
      }
    },

    cyl_load() {
      const token = ++this.cylLoadToken
      this.cyl_destroy()
      if (!this.data.path) {
        return
      }
      this.createSelectorQuery()
        .select(`#${this.data.cylCanvasId}`)
        .fields({ node: true, size: true })
        .exec((result) => {
          const info = result && result[0]
          if (token !== this.cylLoadToken || !this.cylReady) {
            return
          }
          if (!info || !info.node) {
            this.triggerEvent('error', { message: 'cyl-pag: the canvas node is not available.' })
            return
          }
          const canvas = info.node
          const ratio = cylPixelRatio()
          canvas.width = Math.max(1, Math.round(info.width * ratio))
          canvas.height = Math.max(1, Math.round(info.height * ratio))
          cylReadPAG(this.data.path, (error, data) => {
            if (token !== this.cylLoadToken || !this.cylReady) {
              return
            }
            if (error) {
              this.triggerEvent('error', { message: error.message })
              return
            }
            this.cyl_start(data, canvas, token)
          })
        })
    },

    async cyl_start(data, canvas, token) {
      const current = () => token === this.cylLoadToken && this.cylReady
      let file = null
      try {
        const PAG = await cylLoadPAG(this.data.wasmPath)
        file = current() ? await PAG.PAGFile.load(data) : null
        if (!file || !current()) {
          if (file) {
            file.destroy()
          }
          return
        }
        const view = await PAG.PAGView.init(file, canvas, { firstFrame: false })
        if (!current()) {
          view.destroy()
          file.destroy()
          return
        }
        this.cylFile = file
        this.cylView = view
        view.setScaleMode(CYL_SCALE_MODES[this.data.fit] || CYL_SCALE_MODES.contain)
        view.setRepeatCount(this.data.loop ? 0 : 1)
        view.addListener('onAnimationEnd', () => this.triggerEvent('complete', {}))
        view.addListener('onAnimationRepeat', () => this.triggerEvent('loopcomplete', {}))
        this.cyl_rest()
        if (this.data.autoplay) {
          view.play()
        }
        this.triggerEvent('ready', { duration: this.cyl_duration() })
        if (this.cylPendingPlay) {
          const pending = this.cylPendingPlay
          this.cyl_playFromStart(pending.seconds + (Date.now() - pending.requestedAt) / 1000)
        }
      } catch (error) {
        if (file && file !== this.cylFile) {
          try {
            file.destroy()
          } catch (destroyError) {}
        }
        if (current()) {
          this.cyl_destroy()
          this.triggerEvent('error', { message: `cyl-pag: ${(error && error.message) || error}` })
        }
      }
    },

    /** [EN] The duration in seconds (libpag counts microseconds). [CN] 时长，单位秒（libpag 以微秒计）。 */
    cyl_duration() {
      return this.cylView ? (Number(this.cylView.duration()) || 0) / 1000000 : 0
    },

    /** [EN] Shows the resting frame without playing. [CN] 不播放，显示静止帧。 */
    cyl_rest() {
      if (this.cylView) {
        this.cylView.setProgress(this.data.restingFrame === 'last' ? 1 : 0)
        this.cylView.flush()
      }
    },

    cyl_play() {
      if (this.cylView) {
        this.cylView.play()
      }
    },

    cyl_pause() {
      if (this.cylView) {
        this.cylView.pause()
      }
    },

    cyl_stop() {
      if (this.cylView) {
        this.cylView.pause()
        this.cyl_rest()
      }
    },

    /** [EN] Plays from the beginning (a tab that becomes selected). [CN] 从头播放（Tab 被选中时）。 */
    cyl_playFromStart(offset) {
      // [EN] `offset` (seconds) continues a playback another tab bar started: each tab page has its own tab bar.
      // [CN] `offset`（秒）继续另一个 TabBar 已开始的播放：每个 Tab 页面都有自己的 TabBar。
      const seconds = Number(offset) > 0 ? Number(offset) : 0
      const view = this.cylView
      if (!view) {
        // [EN] A play request made while the file loads (a new tab page's tab bar selects its tab at once) runs when it is ready.
        // [CN] 文件加载期间的播放请求（新 Tab 页面的 TabBar 会立即选中其 Tab）在就绪后执行。
        this.cylPendingPlay = {seconds, requestedAt: Date.now()}
        return
      }
      this.cylPendingPlay = null
      const duration = this.cyl_duration()
      const progress = duration > 0 ? Math.min(1, seconds / duration) : 0
      view.pause()
      view.setProgress(progress)
      if (progress < 1) {
        view.play()
      } else {
        view.flush()
      }
    },

    /** [EN] Moves to a progress between 0 and 1. [CN] 跳到 0 到 1 之间的进度。 */
    cyl_setProgress(progress) {
      if (this.cylView) {
        this.cylView.setProgress(Math.min(1, Math.max(0, Number(progress) || 0)))
        this.cylView.flush()
      }
    },

    /** [EN] The libpag PAGView, or null. [CN] libpag 的 PAGView，没有时为 null。 */
    cyl_animation() {
      return this.cylView || null
    },
  },
})
