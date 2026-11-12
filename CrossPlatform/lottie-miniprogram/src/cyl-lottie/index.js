/**
 * [EN] cyl-lottie: a component around this package's lottie library (the CYLTabBarController fork of
 *      lottie-miniprogram), in the manner of Lottie.WMC: put <cyl-lottie path="…" /> in WXML and it sets up its own
 *      <canvas type="2d">, sizes it for the screen's pixel ratio (sharp on devices, upstream issues #12, #23, #26),
 *      loads the animation from `path` (a network URL or a package file) or `animationData`, recolors it with
 *      `colors`, and destroys it when the component is removed. Events: `ready`, `complete`, `loopcomplete`, `error`.
 *      Methods: cyl_play, cyl_pause, cyl_stop, cyl_playFromStart, cyl_goToAndStop, cyl_goToAndPlay,
 *      cyl_playSegments, cyl_setSpeed, cyl_animation.
 * [CN] cyl-lottie：本包 lottie 库（CYLTabBarController 维护的 lottie-miniprogram 分支）的组件，方式与 Lottie.WMC 相同：
 *      在 WXML 中写 <cyl-lottie path="…" />，组件自己创建 <canvas type="2d">，按屏幕像素比设置尺寸（真机上清晰，
 *      上游 issue #12、#23、#26），从 `path`（网络地址或包内文件）或 `animationData` 加载动画，用 `colors` 换色，
 *      组件移除时销毁动画。事件：`ready`、`complete`、`loopcomplete`、`error`。方法：cyl_play、cyl_pause、cyl_stop、
 *      cyl_playFromStart、cyl_goToAndStop、cyl_goToAndPlay、cyl_playSegments、cyl_setSpeed、cyl_animation。
 */
const lottie = require('../index.js')
const {cylApplyLottieColors} = require('./cyl_lottie_colors')

const CYL_FIT = {
  contain: 'xMidYMid meet',
  cover: 'xMidYMid slice',
  fill: 'none',
}

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
            this.cyl_playFromStart()
          } else if (autoplay) {
            this.cylAnimation.play()
          }
          this.triggerEvent('ready', {
            totalFrames: this.cylAnimation.totalFrames,
            duration: this.cylAnimation.getDuration(false),
          })
        })
        animation.addEventListener('complete', () => this.triggerEvent('complete', {}))
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
    },

    cyl_play() {
      if (this.cylAnimation) {
        this.cylAnimation.play()
      }
    },

    cyl_pause() {
      if (this.cylAnimation) {
        this.cylAnimation.pause()
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
     * [EN] Plays from the first frame (a tab that becomes selected).
     * [CN] 从第一帧开始播放（Tab 被选中时）。
     */
    cyl_playFromStart() {
      if (!this.cylAnimation) {
        // [EN] A play request made while the file loads (a new tab page's tab bar selects its tab at once) runs when it
        //      is ready; dropping it showed the selected icon on its last frame with no animation.
        // [CN] 文件加载期间的播放请求（新 Tab 页面的 TabBar 会立即选中其 Tab）在就绪后执行；之前被丢弃，选中的图标
        //      直接停在最后一帧，没有动画。
        this.cylPendingPlay = true
        return
      }
      this.cylPendingPlay = false
      this.cylAnimation.goToAndPlay(0, true)
    },

    cyl_goToAndStop(value, isFrame) {
      if (this.cylAnimation) {
        this.cylAnimation.goToAndStop(value, isFrame)
      }
    },

    cyl_goToAndPlay(value, isFrame) {
      if (this.cylAnimation) {
        this.cylAnimation.goToAndPlay(value, isFrame)
      }
    },

    cyl_playSegments(segments, forceFlag) {
      if (this.cylAnimation) {
        this.cylAnimation.playSegments(segments, forceFlag)
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
