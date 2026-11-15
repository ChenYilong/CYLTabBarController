/**
 * [EN] cyl-svga: an SVGA 2.x animation component with the same properties, events and methods as cyl-lottie, cyl-pag and
 *      cyl-rive, so cyl-tab-bar-item switches by file type. The file is decoded by ../svga/cyl_svga_movie.js (inflate
 *      with fflate, protobuf by hand) and drawn frame by frame on a <canvas type="2d"> by ../svga/cyl_svga_renderer.js;
 *      its PNG images become canvas images (canvas.createImage with a data URL). A mini program cannot package .svga
 *      files: use a .svga.bin copy, a user data path or a URL.
 *      Events: `ready` ({duration}), `complete`, `loopcomplete`, `error`. Methods: cyl_play, cyl_pause, cyl_stop,
 *      cyl_playFromStart, cyl_setProgress, cyl_setSpeed, cyl_duration, cyl_animation.
 * [CN] cyl-svga：SVGA 2.x 动画组件，属性、事件与方法与 cyl-lottie、cyl-pag、cyl-rive 相同，因此 cyl-tab-bar-item 可以按文件
 *      类型切换。文件由 ../svga/cyl_svga_movie.js 解码（fflate 解压，protobuf 手写解析），由 ../svga/cyl_svga_renderer.js 在
 *      <canvas type="2d"> 上逐帧绘制；其中的 PNG 图片转为画布图片（canvas.createImage 加 data URL）。小程序代码包不能包含
 *      .svga 文件：使用 .svga.bin 副本、用户数据路径或网络地址。
 */
const { cylDecodeSVGA } = require('../svga/cyl_svga_movie.js')
const { cylDrawSVGAFrame } = require('../svga/cyl_svga_renderer.js')

/**
 * [EN] Whether the mini program runs in WeChat DevTools. [CN] 小程序是否运行在微信开发者工具中。
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
 * [EN] WeChat DevTools moves a canvas of a fixed bar with the page while it scrolls (see cyl-lottie): there the canvas only
 *      draws, off screen, and an <image> of it shows the animation. Phones show the canvas.
 * [CN] 微信开发者工具在页面滚动时会让固定栏中的画布随页面移动（见 cyl-lottie）：因此在开发者工具中画布只在屏幕外绘制，由其
 *      <image> 显示动画。真机显示画布。
 */
const CYL_USES_SNAPSHOTS = cylIsDevTools()
const CYL_SNAPSHOT_INTERVAL_MS = 33

function cylPixelRatio() {
  try {
    return (typeof wx.getWindowInfo === 'function' ? wx.getWindowInfo() : wx.getSystemInfoSync()).pixelRatio || 2
  } catch (error) {
    return 2
  }
}

/**
 * [EN] Reads an SVGA file as an ArrayBuffer: http(s) with wx.request, anything else with the file system.
 * [CN] 把 SVGA 文件读为 ArrayBuffer：http(s) 使用 wx.request，其他使用文件系统。
 */
function cylReadSVGA(path, callback) {
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

/**
 * [EN] Loads the movie's PNG images as images of `canvas`; calls back with {imageKey: image} once all are loaded (a broken
 *      image is left out).
 * [CN] 把动画中的 PNG 图片加载为 `canvas` 的图片；全部加载后回调 {imageKey: 图片}（损坏的图片会被略过）。
 */
function cylLoadBitmaps(canvas, movie, callback) {
  const keys = Object.keys(movie.images)
  const bitmaps = {}
  let left = keys.length
  if (left === 0) {
    callback(bitmaps)
    return
  }
  const done = () => {
    left -= 1
    if (left === 0) {
      callback(bitmaps)
    }
  }
  keys.forEach((key) => {
    const bytes = movie.images[key]
    const image = canvas.createImage()
    image.onload = () => {
      bitmaps[key] = image
      done()
    }
    image.onerror = done
    const buffer = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength)
    image.src = `data:image/png;base64,${wx.arrayBufferToBase64(buffer)}`
  })
}

Component({
  properties: {
    /** [EN] An .svga (2.x) file: a .svga.bin package copy, a user data path or a URL. [CN] .svga（2.x）文件：包内的 .svga.bin 副本、用户数据路径或网络地址。 */
    path: { type: String, value: '' },
    loop: { type: Boolean, value: false },
    autoplay: { type: Boolean, value: true },
    /** [EN] "first" or "last": the frame shown before playing and after cyl_stop(). [CN] 播放前与停止后显示的帧。 */
    restingFrame: { type: String, value: 'first' },
    /** [EN] contain, cover or fill. [CN] 缩放方式。 */
    fit: { type: String, value: 'contain' },
    /** [EN] Accepted for parity with cyl-lottie; SVGA files carry their own colors. [CN] 为与 cyl-lottie 一致而保留；SVGA 文件自带颜色。 */
    colors: { type: Object, value: null },
    label: { type: String, value: '' },
    /** [EN] Playback speed, above 0, also while playing. [CN] 播放速度，大于 0，播放中同样生效。 */
    speed: { type: Number, value: 1 },
  },

  data: { cylCanvasId: '', cylSnapshot: '', cylCovered: CYL_USES_SNAPSHOTS },

  observers: {
    'path, fit': function () {
      if (this.cylReady) {
        this.cyl_load()
      }
    },
    'loop, autoplay, restingFrame': function (loop, autoplay) {
      if (!this.cylMovie) {
        return
      }
      if (autoplay) {
        this.cyl_play()
      } else if (!this.cylPlaying) {
        this.cyl_rest()
      }
    },
  },

  lifetimes: {
    created() {
      this.cylLoadToken = 0
      this.cylFrame = 0
      this.cylPlaying = false
    },
    attached() {
      this.setData({ cylCanvasId: `cyl-svga-${Math.random().toString(36).slice(2, 10)}` })
    },
    ready() {
      this.cylReady = true
      this.cyl_load()
    },
    detached() {
      this.cylReady = false
      this.cyl_cancelFrame()
      this.cylMovie = null
    },
  },

  methods: {
    cyl_load() {
      const token = ++this.cylLoadToken
      this.cyl_cancelFrame()
      this.cylMovie = null
      this.cylPlaying = false
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
            this.triggerEvent('error', { message: 'cyl-svga: the canvas node is not available.' })
            return
          }
          const canvas = info.node
          const ratio = cylPixelRatio()
          canvas.width = Math.max(1, Math.round(info.width * ratio))
          canvas.height = Math.max(1, Math.round(info.height * ratio))
          this.cylCanvas = canvas
          this.cylContext = canvas.getContext('2d')
          cylReadSVGA(this.data.path, (error, data) => {
            if (token !== this.cylLoadToken || !this.cylReady) {
              return
            }
            if (error) {
              this.triggerEvent('error', { message: error.message })
              return
            }
            let movie
            try {
              movie = cylDecodeSVGA(data)
            } catch (decodeError) {
              this.triggerEvent('error', { message: decodeError.message })
              return
            }
            cylLoadBitmaps(canvas, movie, (bitmaps) => {
              if (token !== this.cylLoadToken || !this.cylReady) {
                return
              }
              this.cylMovie = movie
              this.cylBitmaps = bitmaps
              this.cyl_rest()
              this.triggerEvent('ready', { duration: this.cyl_duration() })
              if (this.cylPendingPlay) {
                const pending = this.cylPendingPlay
                this.cyl_playFromStart(pending.seconds + (Date.now() - pending.requestedAt) / 1000)
              } else if (this.data.autoplay) {
                this.cyl_play()
              }
            })
          })
        })
    },

    /** [EN] Draws the current frame. [CN] 绘制当前帧。 */
    cyl_draw() {
      const movie = this.cylMovie
      const canvas = this.cylCanvas
      if (!movie || !canvas || !this.cylContext) {
        return
      }
      cylDrawSVGAFrame(this.cylContext, movie, this.cylBitmaps || {}, this.cylFrame, canvas.width, canvas.height, this.data.fit)
      if (CYL_USES_SNAPSHOTS && (!this.cylPlaying || Date.now() - (this.cylSnapshotAt || 0) >= CYL_SNAPSHOT_INTERVAL_MS)) {
        this.cyl_captureSnapshot()
      }
    },

    /** [EN] Reads the canvas into the <image> (WeChat DevTools only). [CN] 把画布内容读入 <image>（仅微信开发者工具）。 */
    cyl_captureSnapshot() {
      const canvas = this.cylCanvas
      if (!CYL_USES_SNAPSHOTS || !canvas || typeof canvas.toDataURL !== 'function') {
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

    cyl_cancelFrame() {
      if (this.cylFrameRequest && this.cylCanvas && typeof this.cylCanvas.cancelAnimationFrame === 'function') {
        this.cylCanvas.cancelAnimationFrame(this.cylFrameRequest)
      }
      this.cylFrameRequest = null
    },

    /** [EN] The render loop: the frame follows the time since the playback started, times the speed. [CN] 渲染循环：帧号跟随自播放开始的时间乘以速度。 */
    cyl_tick() {
      const movie = this.cylMovie
      if (!movie || !this.cylPlaying) {
        return
      }
      const speed = Number(this.data.speed) > 0 ? Number(this.data.speed) : 1
      const elapsed = (Date.now() - this.cylStartedAt) / 1000
      let frame = this.cylStartFrame + elapsed * movie.fps * speed
      if (frame >= movie.frames) {
        if (this.data.loop) {
          this.triggerEvent('loopcomplete', {})
          this.cylStartFrame = 0
          this.cylStartedAt = Date.now()
          frame = 0
        } else {
          this.cylFrame = movie.frames - 1
          this.cylPlaying = false
          this.cyl_draw()
          this.triggerEvent('complete', {})
          return
        }
      }
      this.cylFrame = frame
      this.cyl_draw()
      this.cylFrameRequest = this.cylCanvas.requestAnimationFrame(() => this.cyl_tick())
    },

    /** [EN] Shows the resting frame without playing. [CN] 不播放，显示静止帧。 */
    cyl_rest() {
      if (this.cylMovie) {
        this.cyl_cancelFrame()
        this.cylPlaying = false
        this.cylFrame = this.data.restingFrame === 'last' ? this.cylMovie.frames - 1 : 0
        this.cyl_draw()
      }
    },

    cyl_play() {
      const movie = this.cylMovie
      if (!movie || this.cylPlaying) {
        return
      }
      if (this.cylFrame >= movie.frames - 1) {
        this.cylFrame = 0
      }
      this.cylPlaying = true
      this.cylStartFrame = this.cylFrame
      this.cylStartedAt = Date.now()
      this.cyl_cancelFrame()
      this.cyl_tick()
    },

    cyl_pause() {
      this.cyl_cancelFrame()
      this.cylPlaying = false
      this.cyl_draw()
    },

    cyl_stop() {
      this.cyl_rest()
    },

    /** [EN] Plays from the beginning (a tab that becomes selected); `offset` seconds continue another bar's playback. [CN] 从头播放（Tab 被选中时）；`offset` 秒继续另一个 TabBar 的播放。 */
    cyl_playFromStart(offset) {
      const seconds = Number(offset) > 0 ? Number(offset) : 0
      const movie = this.cylMovie
      if (!movie) {
        this.cylPendingPlay = { seconds, requestedAt: Date.now() }
        return
      }
      this.cylPendingPlay = null
      this.cyl_cancelFrame()
      this.cylPlaying = false
      const speed = Number(this.data.speed) > 0 ? Number(this.data.speed) : 1
      const frame = seconds * movie.fps * speed
      if (frame >= movie.frames - 1 && !this.data.loop) {
        this.cylFrame = movie.frames - 1
        this.cyl_draw()
        return
      }
      this.cylFrame = frame % movie.frames
      this.cyl_play()
    },

    /** [EN] Moves to a progress between 0 and 1. [CN] 跳到 0 到 1 之间的进度。 */
    cyl_setProgress(progress) {
      if (this.cylMovie) {
        this.cylFrame = Math.min(1, Math.max(0, Number(progress) || 0)) * (this.cylMovie.frames - 1)
        if (this.cylPlaying) {
          this.cylStartFrame = this.cylFrame
          this.cylStartedAt = Date.now()
        }
        this.cyl_draw()
      }
    },

    /** [EN] Changes the speed, also of the playing animation. [CN] 修改速度，正在播放的动画同样生效。 */
    cyl_setSpeed(speed) {
      if (Number(speed) > 0) {
        if (this.cylPlaying) {
          this.cylStartFrame = this.cylFrame
          this.cylStartedAt = Date.now()
        }
        this.setData({ speed: Number(speed) })
      }
    },

    /** [EN] The duration in seconds at speed 1. [CN] 速度为 1 时的时长，单位秒。 */
    cyl_duration() {
      return this.cylMovie ? this.cylMovie.frames / this.cylMovie.fps : 0
    },

    /** [EN] The decoded movie, or null. [CN] 解码后的动画，没有时为 null。 */
    cyl_animation() {
      return this.cylMovie || null
    },
  },
})
