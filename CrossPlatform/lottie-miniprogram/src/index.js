import {setup, g, restore, setFrameInterval} from './adapter'
const {window, document, navigator} = g
// [EN] Issue #53: lottie-web calls `new XMLHttpRequest()`; a mini game has no such global and strict mode forbids
//      assigning one, so the name is declared in this module instead.
// [CN] issue #53：lottie-web 调用 `new XMLHttpRequest()`；小游戏没有这个全局对象，严格模式也不允许给它赋值，
//      因此在本模块中声明这个名称。
// eslint-disable-next-line no-unused-vars
const XMLHttpRequest = g.XMLHttpRequest
// [EN] The UMD wrapper of lottie-web writes to `module.exports` when `module` exists; it is hidden from it so the
//      factory result lands on `window.lottie` (the light canvas build has no `eval`, issues #2, #51, #56).
// [CN] lottie-web 的 UMD 包装在 `module` 存在时写入 `module.exports`；这里对它隐藏，使工厂函数的结果写到
//      `window.lottie`（light canvas 版本不含 `eval`，issue #2、#51、#56）。
// eslint-disable-next-line no-unused-vars
const lottieWeb = (function (module, exports, define, globalThis, self) {
  ;'__LOTTIE_CANVAS__'
  return window.lottie
}).call(window, undefined, undefined, undefined, undefined, window)

/**
 * [EN] Whether a path is a network URL.
 * [CN] 路径是否为网络地址。
 */
function isNetworkPath(path) {
  return /^https?:\/\//.test(path)
}

/**
 * [EN] Reads an animation from a network URL (wx.request) or a file of the mini program package or the user data
 *      folder (FileSystemManager), issue #15. Calls back with (error, animationData).
 * [CN] 从网络地址（wx.request）或小程序包内、用户数据目录中的文件（FileSystemManager）读取动画，issue #15。
 *      回调参数为 (error, animationData)。
 */
function readAnimationData(path, callback) {
  if (/\.(zip|lottie)(\?|#|$)/i.test(path)) {
    // [EN] Issue #47: a zip / dotLottie file is not a Lottie JSON. [CN] issue #47：zip / dotLottie 不是 Lottie JSON。
    callback(new Error(`'${path}' is a zip or .lottie file; lottie-miniprogram loads Lottie JSON only.`))
    return
  }
  const parse = (data) => {
    if (data && typeof data === 'object' && !(data instanceof ArrayBuffer)) {
      return data
    }
    return JSON.parse(String(data))
  }
  if (isNetworkPath(path)) {
    wx.request({
      url: path,
      dataType: 'json',
      success: ({data, statusCode}) => {
        if (statusCode < 200 || statusCode >= 300) {
          callback(new Error(`Loading '${path}' failed with HTTP status ${statusCode}.`))
          return
        }
        try {
          callback(null, parse(data))
        } catch (e) {
          callback(e)
        }
      },
      fail: ({errMsg}) => callback(new Error(errMsg)),
    })
    return
  }
  try {
    const text = wx.getFileSystemManager().readFileSync(path, 'utf8')
    callback(null, parse(text))
  } catch (e) {
    callback(new Error(`Reading '${path}' failed: ${e.message || e.errMsg || e}`))
  }
}

/**
 * [EN] Wraps an animation so destroy() unregisters its canvas and never deadlocks lottie-web
 *      (https://github.com/airbnb/lottie-web/issues/1772, issues #1, #13, #58).
 * [CN] 包装动画，使 destroy() 注销它的 canvas，且不会让 lottie-web 死锁
 *      （https://github.com/airbnb/lottie-web/issues/1772，issue #1、#13、#58）。
 */
function wrapDestroy(animation, canvas) {
  const originalDestroy = animation.destroy.bind(animation)
  animation.destroy = function () {
    restore(canvas)
    animation.wrapper = animation.wrapper || {innerHTML: ''}
    if (animation.renderer && !animation.renderer.destroyed) {
      animation.renderer.renderConfig.clearCanvas = false
    }
    originalDestroy()
  }
  return animation
}

/**
 * [EN] A stand-in returned while `path` is read: it records the calls made before the animation exists and replays
 *      them on it, so callers can use the result right away (issue #42: listen to 'DOMLoaded' / 'data_ready' and play
 *      when the data is in).
 * [CN] 读取 `path` 期间返回的替身：记录动画创建前的调用，并在动画创建后重放，因此调用方可以立即使用返回值
 *      （issue #42：监听 'DOMLoaded' / 'data_ready'，数据就绪后再播放）。
 */
function createPendingAnimation(options, canvas) {
  const calls = []
  let animation = null
  let destroyed = false
  const pending = {isLoaded: false}
  const methods = ['play', 'stop', 'pause', 'setSpeed', 'goToAndPlay', 'goToAndStop', 'setDirection', 'playSegments',
    'setSubframe', 'addEventListener', 'removeEventListener', 'triggerEvent', 'resize', 'setLoop']
  methods.forEach((name) => {
    pending[name] = function (...args) {
      if (animation) {
        return animation[name](...args)
      }
      calls.push([name, args])
      return undefined
    }
  })
  pending.getDuration = (inFrames) => (animation ? animation.getDuration(inFrames) : 0)
  pending.destroy = () => {
    destroyed = true
    if (animation) {
      animation.destroy()
    } else {
      restore(canvas)
    }
  }
  pending.cylResolve = (data, error) => {
    if (destroyed) {
      return
    }
    if (error) {
      const listeners = calls.filter(([name, args]) => name === 'addEventListener' && args[0] === 'data_failed')
      listeners.forEach(([, args]) => args[1](error))
      console.error(error.message)
      return
    }
    setup(canvas)
    animation = loadAnimation(Object.assign({}, options, {path: undefined, animationData: data}))
    calls.forEach(([name, args]) => animation[name](...args))
    calls.length = 0
    Object.keys(animation).forEach((key) => {
      if (!(key in pending) || key === 'isLoaded') {
        pending[key] = animation[key]
      }
    })
    pending.cylAnimation = animation
  }
  return pending
}

function loadAnimation(options) {
  ['wrapper', 'container'].forEach(key => {
    if (key in options) {
      throw new Error(`Not support '${key}' parameter in miniprogram version of lottie.`)
    }
  })
  if (!options.rendererSettings || !options.rendererSettings.context) {
    throw new Error(`Parameter 'rendererSettings.context' should be a CanvasRenderingContext2D.`)
  }
  const canvas = options.rendererSettings.context.canvas
  if (canvas) {
    // [EN] Issues #36, #55: images and frames use this animation's own canvas, so several canvases work together.
    // [CN] issue #36、#55：图片与帧使用该动画自己的 canvas，因此多个 canvas 可以同时工作。
    setup(canvas)
  }
  if (typeof options.path === 'string' && !options.animationData) {
    const pending = createPendingAnimation(options, canvas)
    readAnimationData(options.path, (error, data) => {
      if (error) {
        // [EN] Errors arrive after the caller added its 'data_failed' listener. [CN] 错误在调用方添加 'data_failed' 监听之后到达。
        setTimeout(() => pending.cylResolve(null, error), 0)
      } else {
        pending.cylResolve(data, null)
      }
    })
    return pending
  }
  const settings = Object.assign({}, options, {renderer: 'canvas'})
  delete settings.path
  return wrapDestroy(lottieWeb.loadAnimation(settings), canvas)
}

const {freeze, unfreeze, getRegisteredAnimations} = lottieWeb
const lottieDestroy = lottieWeb.destroy

// PR #17: destroy every animation (or the ones with this name) when a page is unloaded, so the animations work again
// the next time the page renders them; lottie-web reads `wrapper.innerHTML` while destroying, which a mini program has
// no DOM for.
function destroy(name) {
  const animations = getRegisteredAnimations() || []
  animations.forEach(animation => {
    animation.wrapper = animation.wrapper || {
      innerHTML: ''
    }
  })
  lottieDestroy(name)
}

export default {
  setup,
  loadAnimation,
  freeze,
  unfreeze,
  destroy,
  setFrameInterval,
}

export {
  setup,
  loadAnimation,
  freeze,
  unfreeze,
  destroy,
  setFrameInterval,
}
