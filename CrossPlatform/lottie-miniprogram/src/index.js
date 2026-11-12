import {setup, g, restore} from './adapter'
const {window, document, navigator} = g

;'__LOTTIE_CANVAS__'

function loadAnimation(options) {
  ['wrapper', 'container'].forEach(key => {
    if (key in options) {
      throw new Error(`Not support '${key}' parameter in miniprogram version of lottie.`)
    }
  })
  if (typeof options.path === 'string' && !/^https?\:\/\//.test(options.path)) {
    throw new Error(`The 'path' is only support http protocol.`)
  }
  if (!options.rendererSettings || !options.rendererSettings.context) {
    throw new Error(`Parameter 'rendererSettings.context' should be a CanvasRenderingContext2D.`)
  }
  options.renderer = 'canvas'

  const _aniItem = window.lottie.loadAnimation(options)
  // try to fix https://github.com/airbnb/lottie-web/issues/1772
  const originalDestroy = _aniItem.destroy.bind(_aniItem)
  _aniItem.destroy = function () {
    // 恢复到上一次 canvas 的环境，避免当前 canvas 被销毁后导致 lottie-web 内部死锁
    restore()
    if (_aniItem.renderer && !_aniItem.renderer.destroyed) {
      _aniItem.renderer.renderConfig.clearCanvas = false
    }
    originalDestroy()
  }.bind(_aniItem)

  return _aniItem
}

const {freeze, unfreeze} = window.lottie

export {
  setup,
  loadAnimation,
  freeze,
  unfreeze,
}
