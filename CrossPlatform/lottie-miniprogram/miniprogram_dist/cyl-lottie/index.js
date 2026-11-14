/**
 * [EN] cyl-lottie: a component around this package's lottie library (the CYLTabBarController fork of
 *      lottie-miniprogram), in the manner of Lottie.WMC: put <cyl-lottie path="…" /> in WXML and it sets up its own
 *      <canvas type="2d">, sizes it for the screen's pixel ratio (sharp on devices, upstream issues #12, #23, #26),
 *      loads the animation from `path` (a network URL or a package file) or `animationData`, recolors it with
 *      `colors`, and destroys it when the component is removed. Events: `ready`, `complete`, `loopcomplete`, `error`.
 *      Methods: cyl_play, cyl_pause, cyl_stop, cyl_playFromStart, cyl_goToAndStop, cyl_goToAndPlay,
 *      cyl_playSegments, cyl_setSpeed, cyl_refreshLayout, cyl_animation.
 * [CN] cyl-lottie：本包 lottie 库（CYLTabBarController 维护的 lottie-miniprogram 分支）的组件，方式与 Lottie.WMC 相同：
 *      在 WXML 中写 <cyl-lottie path="…" />，组件自己创建 <canvas type="2d">，按屏幕像素比设置尺寸（真机上清晰，
 *      上游 issue #12、#23、#26），从 `path`（网络地址或包内文件）或 `animationData` 加载动画，用 `colors` 换色，
 *      组件移除时销毁动画。事件：`ready`、`complete`、`loopcomplete`、`error`。方法：cyl_play、cyl_pause、cyl_stop、
 *      cyl_playFromStart、cyl_goToAndStop、cyl_goToAndPlay、cyl_playSegments、cyl_setSpeed、cyl_refreshLayout、cyl_animation。
 */
const lottie = require('../index.js')
const {cylApplyLottieColors} = require('./cyl_lottie_colors')

const CYL_FIT = {
  contain: 'xMidYMid meet',
  cover: 'xMidYMid slice',
  fill: 'none',
}

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
 * [EN] WeChat DevTools does not keep a <canvas type="2d"> inside a fixed bar (the custom tab bar) in place while the
 *      page scrolls: it moves with the gesture until the component renders again. There, an animation that is not
 *      playing shows a still image of its frame instead (an <image> stays in place); the canvas comes back while it
 *      plays. Phones are not changed.
 * [CN] 微信开发者工具在页面滚动时不会让固定栏（自定义 TabBar）中的 <canvas type="2d"> 保持原位：它随手势移动，直到组件
 *      再次渲染。因此在开发者工具中，未播放的动画改为显示当前帧的静态图片（<image> 保持原位）；播放时恢复画布。真机不变。
 */
const CYL_USES_SNAPSHOTS = cylIsDevTools()

function cylPixelRatio() {
  try {
    return (typeof wx.getWindowInfo === 'function' ? wx.getWindowInfo() : wx.getSystemInfoSync()).pixelRatio || 2
  } catch (error) {
    return 2
  }
}

Component({
  properties: {
    /**
     * [EN] A network URL (http/https) or a file of the mini program package ("/assets/home.json"), Lottie JSON only.
     * [CN] 网络地址（http/https）或小程序包内的文件（"/assets/home.json"），仅支持 Lottie JSON。
     */
    path: {type: String, value: ''},
    /**
     * [EN] The animation as an object; used when `path` is empty.
     * [CN] 动画对象；`path` 为空时使用。
     */
    animationData: {type: Object, value: null},
    loop: {type: Boolean, value: false},
    autoplay: {type: Boolean, value: true},
    /**
     * [EN] Playback speed; above 0.
     * [CN] 播放速度；大于 0。
     */
    speed: {type: Number, value: 1},
    /**
     * [EN] keypath -> "#RRGGBB" / "#RRGGBBAA", applied before loading (e.g. a Dark Mode palette).
     * [CN] keypath -> "#RRGGBB" / "#RRGGBBAA"，加载前应用（例如深色模式配色）。
     */
    colors: {type: Object, value: null},
    /**
     * [EN] contain (default), cover (fills the canvas, crops the rest; upstream issue #43) or fill.
     * [CN] contain（默认）、cover（铺满画布，裁掉多余部分；上游 issue #43）或 fill。
     */
    fit: {type: String, value: 'contain'},
    /**
     * [EN] The frame shown before playing and after cyl_stop(): "first" or "last".
     * [CN] 播放前以及 cyl_stop() 之后显示的帧："first" 或 "last"。
     */
    restingFrame: {type: String, value: 'first'},
    /**
     * [EN] The accessibility label; empty hides the animation from accessibility (its host reads instead).
     * [CN] 无障碍标签；为空时对无障碍隐藏动画（由宿主朗读）。
     */
    label: {type: String, value: ''},
  },

  data: {
    cylCanvasId: '',
    cylSnapshot: '',
    cylSnapshotShown: false,
  },

  observers: {
    'path, animationData, colors, fit': function () {
      if (this.cylReady) {
        this.cyl_load()
      }
    },
    'speed': function (speed) {
      if (this.cylAnimation && speed > 0) {
        this.cylAnimation.setSpeed(speed)
      }
    },
    'loop, autoplay, restingFrame': function (loop, autoplay) {
      const animation = this.cylAnimation
      if (!animation || !animation.isLoaded) {
        return
      }
      animation.setLoop(loop)
      if (autoplay) {
        animation.play()
      } else if (animation.isPaused) {
        this.cyl_rest()
      }
      this.cyl_syncSnapshot()
    },
  },

  lifetimes: {
    created() {
      this.cylLoadToken = 0
    },
    attached() {
      this.setData({cylCanvasId: `cyl-lottie-${Math.random().toString(36).slice(2, 10)}`})
    },
    ready() {
      this.cylReady = true
      this.cyl_load()
    },
    detached() {
      this.cylReady = false
      clearTimeout(this.cylSnapshotTimer)
      this.cyl_destroy()
    },
  },

  methods: {
    cyl_destroy() {
      if (this.cylAnimation) {
        this.cylAnimation.destroy()
        this.cylAnimation = null
      }
    },

    /**
     * [EN] WeChat DevTools only (CYL_USES_SNAPSHOTS): once the animation is not playing, shows a still image of the
     *      canvas instead of the canvas; while it plays, shows the canvas. Runs after every playback change.
     * [CN] 仅微信开发者工具（CYL_USES_SNAPSHOTS）：动画未播放时以画布的静态图片代替画布；播放时显示画布。每次播放状态
     *      变化后运行。
     */
    cyl_syncSnapshot() {
      if (!CYL_USES_SNAPSHOTS) {
        return
      }
      clearTimeout(this.cylSnapshotTimer)
      // [EN] On the next turn, after lottie has drawn the frame. [CN] 在下一轮执行，此时 lottie 已画好该帧。
      this.cylSnapshotTimer = setTimeout(() => {
        const animation = this.cylAnimation
        const playing = Boolean(animation && !animation.isPaused)
        if (playing || !animation || !this.cylCanvas || typeof this.cylCanvas.toDataURL !== 'function') {
          if (this.data.cylSnapshotShown) {
            this.setData({cylSnapshotShown: false})
          }
          return
        }
        try {
          this.setData({cylSnapshot: this.cylCanvas.toDataURL('image/png'), cylSnapshotShown: true})
        } catch (error) {
          this.setData({cylSnapshotShown: false})
        }
      }, 0)
    },

    /**
     * [EN] (Re)loads the animation into the canvas, sized for the pixel ratio; a newer load cancels an older one.
     * [CN] （重新）把动画加载到画布中，按像素比设置尺寸；新的加载会取消旧的加载。
     */
    cyl_load() {
      const token = ++this.cylLoadToken
      const {path, animationData} = this.data
      this.cyl_destroy()
      if (!path && !animationData) {
        return
      }
      this.createSelectorQuery()
        .select(`#${this.data.cylCanvasId}`)
        .fields({node: true, size: true})
        .exec((result) => {
          const info = result && result[0]
          if (token !== this.cylLoadToken || !this.cylReady) {
            return
          }
          if (!info || !info.node) {
            this.triggerEvent('error', {message: 'cyl-lottie: the canvas node is not available.'})
            return
          }
          const canvas = info.node
          const ratio = cylPixelRatio()
          canvas.width = Math.max(1, Math.round(info.width * ratio))
          canvas.height = Math.max(1, Math.round(info.height * ratio))
          const context = canvas.getContext('2d')
          this.cylCanvas = canvas
          this.cyl_start(canvas, context, token)
        })
    },

    cyl_start(canvas, context, token) {
      const {path, animationData, colors, loop, autoplay, speed, fit} = this.data
      const settings = {
        loop,
        autoplay: false,
        rendererSettings: {
          context,
          clearCanvas: true,
          preserveAspectRatio: CYL_FIT[fit] || CYL_FIT.contain,
        },
      }
      if (animationData) {
        settings.animationData = cylApplyLottieColors(animationData, colors)
      } else {
        settings.path = path
      }
      try {
        lottie.setup(canvas)
        const animation = lottie.loadAnimation(settings)
        this.cylAnimation = animation
        animation.addEventListener('DOMLoaded', () => {
          if (token !== this.cylLoadToken) {
            return
          }
          if (!animationData && colors && Object.keys(colors).length > 0) {
            // [EN] A path is recolored once its data is in: load it again as data. [CN] path 的数据就绪后再换色：以数据重新加载。
            const data = (animation.cylAnimation || animation).animationData
            this.cyl_destroy()
            this.setData({animationData: data, path: ''})
            return
          }
          // [EN] A `path` load returns a stand-in; from here on use the animation itself. [CN] `path` 加载返回替身；此后使用动画本身。
          this.cylAnimation = animation.cylAnimation || animation
          if (speed > 0 && speed !== 1) {
            this.cylAnimation.setSpeed(speed)
          }
          this.cyl_rest()
          if (this.cylPendingPlay) {
            const pending = this.cylPendingPlay
            this.cyl_playFromStart(pending.seconds + (Date.now() - pending.requestedAt) / 1000)
          } else if (autoplay) {
            this.cylAnimation.play()
          }
          this.cyl_syncSnapshot()
          this.triggerEvent('ready', {
            totalFrames: this.cylAnimation.totalFrames,
            duration: this.cylAnimation.getDuration(false),
          })
        })
        animation.addEventListener('complete', () => {
          this.cyl_syncSnapshot()
          this.triggerEvent('complete', {})
        })
        animation.addEventListener('loopComplete', () => this.triggerEvent('loopcomplete', {}))
        animation.addEventListener('error', (event) => {
          const native = event && (event.nativeError || event)
          this.triggerEvent('error', {message: (native && native.message) || 'cyl-lottie: rendering failed.'})
        })
        animation.addEventListener('data_failed', (error) => {
          this.triggerEvent('error', {message: (error && error.message) || 'cyl-lottie: loading failed.'})
        })
      } catch (error) {
        this.triggerEvent('error', {message: error.message})
      }
    },

    /**
     * [EN] Shows the resting frame ("first" or "last") without playing.
     * [CN] 不播放，显示静止帧（"first" 或 "last"）。
     */
    cyl_rest() {
      const animation = this.cylAnimation
      if (!animation || !animation.totalFrames) {
        return
      }
      const frame = this.data.restingFrame === 'last' ? Math.max(0, animation.totalFrames - 1) : 0
      animation.goToAndStop(frame, true)
      this.cyl_syncSnapshot()
    },

    cyl_play() {
      if (this.cylAnimation) {
        this.cylAnimation.play()
        this.cyl_syncSnapshot()
      }
    },

    cyl_pause() {
      if (this.cylAnimation) {
        this.cylAnimation.pause()
        this.cyl_syncSnapshot()
      }
    },

    /**
     * [EN] Stops and shows the resting frame.
     * [CN] 停止并显示静止帧。
     */
    cyl_stop() {
      if (this.cylAnimation) {
        this.cylAnimation.stop()
        this.cyl_rest()
      }
    },

    /**
     * [EN] Renders the component again, without touching the animation, so the canvas goes back to where the page
     *      puts it. WeChat DevTools leaves a <canvas type="2d"> of a fixed bar (the custom tab bar) where it was after a
     *      page scroll, over the page content, until the component renders again.
     * [CN] 重新渲染组件（不改动画），使画布回到页面布局的位置。微信开发者工具在页面滚动后会把固定栏（自定义 TabBar）中的
     *      <canvas type="2d"> 留在原处、盖在页面内容上，直到组件再次渲染。
     */
    cyl_refreshLayout() {
      this.setData({cylLayoutVersion: (this.data.cylLayoutVersion || 0) + 1})
    },

    /**
     * [EN] Plays from the first frame (a tab that becomes selected).
     * [CN] 从第一帧开始播放（Tab 被选中时）。
     */
    cyl_playFromStart(offset) {
      // [EN] `offset` (seconds) continues a playback another tab bar started: each tab page has its own tab bar.
      // [CN] `offset`（秒）继续另一个 TabBar 已开始的播放：每个 Tab 页面都有自己的 TabBar。
      const seconds = Number(offset) > 0 ? Number(offset) : 0
      if (!this.cylAnimation) {
        // [EN] A play request made while the file loads (a new tab page's tab bar selects its tab at once) runs when it
        //      is ready; dropping it showed the selected icon on its last frame with no animation.
        // [CN] 文件加载期间的播放请求（新 Tab 页面的 TabBar 会立即选中其 Tab）在就绪后执行；之前被丢弃，选中的图标
        //      直接停在最后一帧，没有动画。
        this.cylPendingPlay = {seconds, requestedAt: Date.now()}
        return
      }
      this.cylPendingPlay = null
      const animation = this.cylAnimation
      const speed = Math.abs(animation.playSpeed || 1)
      const frame = Math.floor(seconds * (animation.frameRate || 30) * speed)
      if (frame >= animation.totalFrames - 1) {
        animation.goToAndStop(Math.max(0, animation.totalFrames - 1), true)
      } else {
        animation.goToAndPlay(frame, true)
      }
      this.cyl_syncSnapshot()
    },

    cyl_goToAndStop(value, isFrame) {
      if (this.cylAnimation) {
        this.cylAnimation.goToAndStop(value, isFrame)
        this.cyl_syncSnapshot()
      }
    },

    cyl_goToAndPlay(value, isFrame) {
      if (this.cylAnimation) {
        this.cylAnimation.goToAndPlay(value, isFrame)
        this.cyl_syncSnapshot()
      }
    },

    cyl_playSegments(segments, forceFlag) {
      if (this.cylAnimation) {
        this.cylAnimation.playSegments(segments, forceFlag)
        this.cyl_syncSnapshot()
      }
    },

    cyl_setSpeed(speed) {
      if (this.cylAnimation && speed > 0) {
        this.cylAnimation.setSpeed(speed)
      }
    },

    /**
     * [EN] The lottie animation item, for anything this component does not wrap; null before it loads.
     * [CN] lottie 动画对象，用于本组件未封装的功能；加载前为 null。
     */
    cyl_animation() {
      return this.cylAnimation || null
    },
  },
})
