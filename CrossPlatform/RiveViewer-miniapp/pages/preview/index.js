const previewDefinition = require('./preview-definition')
const {
  getDesktopSplitUrl,
  getWindowInfo,
  supportsDesktopSplit
} = require('../../utils/desktop-split')

function redirectToDesktopSplit(page, fileId) {
  if (!fileId || page.desktopSplitRedirecting) return false
  page.desktopSplitRedirecting = true
  page.disposePreview?.()
  wx.reLaunch({
    url: getDesktopSplitUrl(fileId),
    fail: () => {
      page.desktopSplitRedirecting = false
    }
  })
  return true
}

Page({
  ...previewDefinition,

  onLoad(options = {}) {
    const fileId = decodeURIComponent(options.id || '')
    if (fileId && supportsDesktopSplit(getWindowInfo())) {
      redirectToDesktopSplit(this, fileId)
      return
    }
    previewDefinition.onLoad.call(this, options)
    this.desktopWindowResizeHandler = (result) => {
      if (!this.data.file || !supportsDesktopSplit(result?.size || getWindowInfo())) return
      redirectToDesktopSplit(this, this.data.file.id)
    }
    if (typeof wx.onWindowResize === 'function') {
      wx.onWindowResize(this.desktopWindowResizeHandler)
    }
  },

  onUnload() {
    if (this.desktopWindowResizeHandler && typeof wx.offWindowResize === 'function') {
      wx.offWindowResize(this.desktopWindowResizeHandler)
    }
    this.desktopWindowResizeHandler = null
    previewDefinition.onUnload.call(this)
  }
})
