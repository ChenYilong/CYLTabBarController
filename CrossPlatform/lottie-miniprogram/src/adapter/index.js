import XHR from './XMLHttpRequest'

function noop() {}

function systemInfo() {
  try {
    if (typeof wx.getWindowInfo === 'function') {
      return wx.getWindowInfo()
    }
    return wx.getSystemInfoSync()
  } catch (e) {
    return {pixelRatio: 2}
  }
}

const g = {
  // [EN] The timer of the frame fallback, in ms (issue #28: configurable through setFrameInterval()).
  // [CN] 帧回退定时器的间隔（毫秒）（issue #28：可通过 setFrameInterval() 配置）。
  frameInterval: 16,
  requestAnimationFrame(cb) {
    return setTimeout(() => {
      typeof cb === 'function' && cb(Date.now())
    }, g.frameInterval)
  },
  cancelAnimationFrame(id) {
    clearTimeout(id)
  },
  // [EN] Every canvas passed to setup(), the latest last (issues #16, #55, #58).
  // [CN] 传给 setup() 的所有 canvas，最新的在最后（issue #16、#55、#58）。
  canvases: [],
  XMLHttpRequest: XHR,
}

g.window = {
  devicePixelRatio: systemInfo().pixelRatio,
  XMLHttpRequest: XHR,
}
g.document = g.window.document = {
  body: {},
  createElement: createElementWithoutCanvas,
}
g.navigator = g.window.navigator = {
  userAgent: ''
}

/**
 * [EN] The canvas that drives the frames and creates images: the latest canvas still registered.
 * [CN] 驱动帧并创建图片的 canvas：仍在注册中的最新 canvas。
 */
function currentCanvas() {
  return g.canvases.length > 0 ? g.canvases[g.canvases.length - 1] : null
}

/**
 * [EN] A data URL as a file in the user data folder, because canvas.createImage() of older base libraries does not
 *      load base64 images (issues #4, #29). Returns the source unchanged when it cannot be written.
 * [CN] 把 data URL 写为用户数据目录中的文件，因为较旧基础库的 canvas.createImage() 不能加载 base64 图片
 *      （issue #4、#29）。无法写入时原样返回。
 */
let dataFileIndex = 0
function imageSource(src) {
  const match = /^data:image\/(\w+);base64,(.*)$/.exec(String(src || ''))
  if (!match || typeof wx.getFileSystemManager !== 'function' || !wx.env || !wx.env.USER_DATA_PATH) {
    return src
  }
  try {
    dataFileIndex += 1
    const filePath = `${wx.env.USER_DATA_PATH}/cyl_lottie_${Date.now()}_${dataFileIndex}.${match[1]}`
    wx.getFileSystemManager().writeFileSync(filePath, match[2], 'base64')
    return filePath
  } catch (e) {
    return src
  }
}

function createImg(canvas) {
  if (!canvas || typeof canvas.createImage === 'undefined') {
    return {}
  }
  const img = canvas.createImage()
  img.addEventListener = img.addEventListener || function (evtName, callback) {
    if (evtName === 'load') {
      img.onload = function () {
        setTimeout(callback, 0)
      }
    } else if (evtName === 'error') {
      img.onerror = callback
    }
  }
  const descriptor = Object.getOwnPropertyDescriptor(Object.getPrototypeOf(img), 'src')
  if (descriptor && descriptor.set) {
    Object.defineProperty(img, 'src', {
      configurable: true,
      get() {
        return descriptor.get ? descriptor.get.call(img) : undefined
      },
      set(value) {
        descriptor.set.call(img, imageSource(value))
      },
    })
  }
  return img
}

/**
 * [EN] A canvas that lottie creates for image processing: an offscreen canvas where the base library has one
 *      (2.16.1+), so images whose size differs from the JSON and masks work (issues #10, #29, #30); otherwise a stub.
 * [CN] lottie 为图片处理创建的 canvas：基础库支持时（2.16.1+）使用离屏 canvas，使尺寸与 JSON 不一致的图片与遮罩可用
 *      （issue #10、#29、#30）；否则使用占位对象。
 */
function createCanvas() {
  if (typeof wx.createOffscreenCanvas === 'function') {
    try {
      const offscreen = wx.createOffscreenCanvas({type: '2d', width: 1, height: 1})
      if (offscreen && typeof offscreen.getContext === 'function') {
        offscreen.style = {}
        return offscreen
      }
    } catch (e) {}
  }
  return {
    style: {},
    getContext() {
      return {
        fillRect: noop,
        drawImage: noop,
        fillStyle: '',
      }
    },
  }
}

function createElement(tagName) {
  if (tagName === 'canvas') {
    return createCanvas()
  } else if (tagName === 'img') {
    return createImg(currentCanvas())
  }
  return {style: {}, setAttribute: noop, appendChild: noop}
}

function createElementWithoutCanvas(tagName) {
  return createElement(tagName)
}

function wrapSetLineDash(ctx, originalSetLineDash) {
  return function setLineDash(segments) {
    return originalSetLineDash.call(ctx, Array.from(segments))
  }
}

function wrapFill(ctx, originalFill) {
  return function fill() {
    // ignore parameters which causes iOS wechat 7.0.5 crash.
    return originalFill.call(ctx)
  }
}

function wrapMethodFatory(ctx, methodName, wrappedMethod) {
  const originalMethod = ctx[methodName]
  if (typeof originalMethod === 'function' && !originalMethod.cylWrapped) {
    ctx[methodName] = wrappedMethod(ctx, originalMethod)
    ctx[methodName].cylWrapped = true
  }
}

/**
 * [EN] Frames come from the latest registered canvas (PR #50: its own requestAnimationFrame, which iOS calls on time),
 *      or from the timer when no canvas is left, so a canvas that is gone never stops every animation (issue #16).
 * [CN] 帧来自最新注册的 canvas（PR #50：使用它自己的 requestAnimationFrame，iOS 上按时调用），没有 canvas 时使用定时器，
 *      因此已经不存在的 canvas 不会让所有动画停止（issue #16）。
 */
function requestAnimationFrame(cb) {
  const canvas = currentCanvas()
  if (canvas && typeof canvas.requestAnimationFrame === 'function') {
    return canvas.requestAnimationFrame((timeStamp) => {
      typeof cb === 'function' && cb(timeStamp)
    })
  }
  return g.requestAnimationFrame(cb)
}

function cancelAnimationFrame(id) {
  const canvas = currentCanvas()
  if (canvas && typeof canvas.cancelAnimationFrame === 'function') {
    canvas.cancelAnimationFrame(id)
  }
  g.cancelAnimationFrame(id)
}

g.window.requestAnimationFrame = requestAnimationFrame
g.window.cancelAnimationFrame = cancelAnimationFrame

export const setup = (canvas) => {
  if (!canvas || typeof canvas.getContext !== 'function') {
    throw new Error('lottie.setup(canvas) needs the node of a <canvas type="2d">: createSelectorQuery().select(...).node().')
  }
  const ctx = canvas.getContext('2d')
  if (!ctx) {
    // [EN] Issue #32: a null context fails later with a misleading message.
    // [CN] issue #32：context 为 null 时，后面会报出误导性的错误。
    throw new Error('lottie.setup(canvas): canvas.getContext("2d") returned null; use <canvas type="2d">.')
  }
  if (!ctx.canvas) {
    ctx.canvas = canvas
  }
  g.canvases = g.canvases.filter(item => item !== canvas)
  g.canvases.push(canvas)
  g.document.body = {}
  g.document.createElement = createElement

  wrapMethodFatory(ctx, 'setLineDash', wrapSetLineDash)
  wrapMethodFatory(ctx, 'fill', wrapFill)
}

/**
 * [EN] Unregisters a canvas (the one of a destroyed animation, or the latest one); frames continue on the previous
 *      canvas or the timer, so loading again after destroy() works (issue #58).
 * [CN] 注销一个 canvas（已销毁动画的 canvas，或最新的 canvas）；帧继续由前一个 canvas 或定时器驱动，因此 destroy() 之后
 *      再次加载可以正常工作（issue #58）。
 */
export const restore = (canvas) => {
  if (canvas) {
    g.canvases = g.canvases.filter(item => item !== canvas)
  } else {
    g.canvases.pop()
  }
}

/**
 * [EN] The interval of the frame timer in ms (issue #28), used when no canvas is registered; 16 by default.
 * [CN] 帧定时器的间隔（毫秒）（issue #28），在没有注册 canvas 时使用；默认 16。
 */
export const setFrameInterval = (interval) => {
  const value = Number(interval)
  if (Number.isFinite(value) && value > 0) {
    g.frameInterval = value
  }
}

export {g}
