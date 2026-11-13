/**
 * [EN] cyl-animation-placeholder: the default of the abstract nodes `cyl-lottie-view`, `cyl-pag-view` and `cyl-rive-view`
 *      of cyl-tab-bar-item (and cyl-tab-bar, which forwards them). cyl-tabbar-miniprogram depends on no animation
 *      library: an app installs the packages it wants (cyl-lottie-miniprogram, cyl-pag-miniprogram,
 *      cyl-rive-miniprogram) and names their components, e.g. `generic:cyl-lottie-view="cyl-lottie"`. A tab whose
 *      library is not installed shows this empty view, which emits `error` once so the app can fall back to images.
 *      It has the methods of cyl-lottie, cyl-pag and cyl-rive, which do nothing.
 * [CN] cyl-animation-placeholder：cyl-tab-bar-item（以及转发它们的 cyl-tab-bar）的抽象节点 `cyl-lottie-view`、
 *      `cyl-pag-view`、`cyl-rive-view` 的默认实现。cyl-tabbar-miniprogram 不依赖任何动画库：应用安装需要的包
 *      （cyl-lottie-miniprogram、cyl-pag-miniprogram、cyl-rive-miniprogram）并指定其组件，例如
 *      `generic:cyl-lottie-view="cyl-lottie"`。动画库未安装的 Tab 显示这个空视图，它发出一次 `error`，以便应用改用图片。
 *      它具有 cyl-lottie、cyl-pag、cyl-rive 的方法，但不做任何事。
 */
const cylNothing = function () {}

Component({
  properties: {
    path: { type: String, value: '' },
    loop: { type: Boolean, value: false },
    autoplay: { type: Boolean, value: true },
    restingFrame: { type: String, value: 'first' },
    speed: { type: Number, value: 1 },
    colors: { type: Object, value: null },
    label: { type: String, value: '' },
  },

  lifetimes: {
    ready() {
      if (this.data.path) {
        this.triggerEvent('error', {
          message: `cyl-tab-bar: no animation component for '${this.data.path}'; install its package and set the generic (see README).`,
        })
      }
    },
  },

  methods: {
    cyl_play: cylNothing,
    cyl_pause: cylNothing,
    cyl_stop: cylNothing,
    cyl_playFromStart: cylNothing,
    cyl_goToAndStop: cylNothing,
    cyl_goToAndPlay: cylNothing,
    cyl_setProgress: cylNothing,
    cyl_setSpeed: cylNothing,
    /** [EN] Always null: no animation. [CN] 始终为 null：没有动画。 */
    cyl_animation() {
      return null
    },
  },
})
