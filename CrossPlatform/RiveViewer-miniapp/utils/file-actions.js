const { prepareShareFileSync } = require('./library')

function getPlatform() {
  const info = wx.getDeviceInfo ? wx.getDeviceInfo() : wx.getSystemInfoSync()
  return String(info.platform || '').toLowerCase()
}

function isDesktopWechat() {
  return ['windows', 'mac', 'devtools'].includes(getPlatform())
}

function isCancelError(error) {
  return String(error?.errMsg || error?.message || '').toLowerCase().includes('cancel')
}

function describeFileActionError(error, fallback) {
  const message = String(error?.errMsg || error?.message || '').trim()
  if (!message) return fallback
  if (message.includes('can only be invoked by user TAP gesture')) {
    return '微信没有识别到有效点击，请关闭菜单后重新操作。'
  }
  if (message.toLowerCase().includes('not supported')) {
    return '当前微信版本或设备暂不支持这项操作。'
  }
  return `${fallback}\n${message}`
}

function sharePreparedFile(id, callbacks = {}) {
  if (typeof wx.shareFileMessage !== 'function') {
    callbacks.fail?.({ errMsg: 'shareFileMessage:fail not supported' })
    return
  }

  let file
  try {
    file = prepareShareFileSync(id)
  } catch (error) {
    callbacks.fail?.(error)
    return
  }

  wx.shareFileMessage({
    filePath: file.path,
    fileName: file.name,
    success: callbacks.success,
    fail: callbacks.fail
  })
}

function savePreparedFileToDisk(id, callbacks = {}) {
  if (!isDesktopWechat() || typeof wx.saveFileToDisk !== 'function') {
    callbacks.fail?.({ errMsg: 'saveFileToDisk:fail not supported on mobile' })
    return
  }

  let file
  try {
    file = prepareShareFileSync(id)
  } catch (error) {
    callbacks.fail?.(error)
    return
  }

  wx.saveFileToDisk({
    filePath: file.path,
    success: callbacks.success,
    fail: callbacks.fail
  })
}

module.exports = {
  describeFileActionError,
  isCancelError,
  isDesktopWechat,
  savePreparedFileToDisk,
  sharePreparedFile
}
