/**
 * [EN] cyl-pag: a PAG animation component on libpag-lite-miniprogram (Tencent/libpag web/lite, vendored in ../libpag),
 *      with the same properties, events and methods as cyl-lottie, so cyl-tab-bar-item switches by file type. It sets
 *      up its own <canvas type="webgl">, sized for the pixel ratio, reads `path` (a package file, a user data file or
 *      a network URL) as an ArrayBuffer and plays it. libpag-lite plays PAG files made of one BMP video sequence only
 *      (export the composition as BMP); other files emit `error`. Events: `ready`, `complete`, `loopcomplete`,
 *      `error`. Methods: cyl_play, cyl_pause, cyl_stop, cyl_playFromStart, cyl_setProgress, cyl_animation.
 * [CN] cyl-pag：基于 libpag-lite-miniprogram（Tencent/libpag web/lite，内置于 ../libpag）的 PAG 动画组件，属性、事件与
 *      方法与 cyl-lottie 相同，因此 cyl-tab-bar-item 可以按文件类型切换。组件自己创建 <canvas type="webgl">，按像素比
 *      设置尺寸，把 `path`（包内文件、用户数据目录文件或网络地址）读为 ArrayBuffer 并播放。libpag-lite 只能播放由单个
 *      BMP 视频序列帧组成的 PAG 文件（导出时选择 BMP）；其他文件发出 `error`。事件：`ready`、`complete`、
 *      `loopcomplete`、`error`。方法：cyl_play、cyl_pause、cyl_stop、cyl_playFromStart、cyl_setProgress、cyl_animation。
 */
const { PAGView } = require('../libpag/pag.js')

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
      } else if (!view.isPlaying()) {
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
            this.cyl_start(data, canvas)
          })
        })
    },

    cyl_start(data, canvas) {
      try {
        const view = PAGView.init(data, canvas)
        this.cylView = view
        const scaleModes = { contain: 'LetterBox', cover: 'Zoom', fill: 'Stretch' }
        if (typeof view.setScaleMode === 'function') {
          view.setScaleMode(scaleModes[this.data.fit] || 'LetterBox')
        }
        view.setRepeatCount(this.data.loop ? 0 : 1)
        view.addListener('onAnimationEnd', () => this.triggerEvent('complete', {}))
        view.addListener('onAnimationRepeat', () => this.triggerEvent('loopcomplete', {}))
        this.cyl_rest()
        if (this.data.autoplay) {
          view.play()
        }
        this.triggerEvent('ready', { duration: view.duration() })
        if (this.cylPendingPlay) {
          this.cyl_playFromStart()
        }
      } catch (error) {
        this.cylView = null
        this.triggerEvent('error', { message: `cyl-pag: ${error.message || error}` })
      }
    },

    /** [EN] Shows the resting frame without playing. [CN] 不播放，显示静止帧。 */
    cyl_rest() {
      if (this.cylView) {
        this.cylView.setProgress(this.data.restingFrame === 'last' ? 1 : 0)
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
    cyl_playFromStart() {
      const view = this.cylView
      if (!view) {
        // [EN] A play request made while the file loads (a new tab page's tab bar selects its tab at once) runs when it is ready.
        // [CN] 文件加载期间的播放请求（新 Tab 页面的 TabBar 会立即选中其 Tab）在就绪后执行。
        this.cylPendingPlay = true
        return
      }
      this.cylPendingPlay = false
      Promise.resolve(view.setProgress(0)).then(() => view.play())
    },

    /** [EN] Moves to a progress between 0 and 1. [CN] 跳到 0 到 1 之间的进度。 */
    cyl_setProgress(progress) {
      if (this.cylView) {
        this.cylView.setProgress(Math.min(1, Math.max(0, Number(progress) || 0)))
      }
    },

    /** [EN] The libpag-lite PAGView, or null. [CN] libpag-lite 的 PAGView，没有时为 null。 */
    cyl_animation() {
      return this.cylView || null
    },
  },
})
