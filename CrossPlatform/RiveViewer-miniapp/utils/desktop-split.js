const DESKTOP_SPLIT_MIN_WIDTH = 960

function getWindowInfo() {
  try {
    return typeof wx.getWindowInfo === 'function'
      ? wx.getWindowInfo()
      : wx.getSystemInfoSync()
  } catch (error) {
    return {}
  }
}

function getPlatform() {
  try {
    const info = typeof wx.getDeviceInfo === 'function'
      ? wx.getDeviceInfo()
      : wx.getSystemInfoSync()
    return String(info.platform || '').toLowerCase()
  } catch (error) {
    return ''
  }
}

function supportsDesktopSplit(windowInfo = getWindowInfo(), platform = getPlatform()) {
  const desktop = platform === 'mac' || platform === 'windows' || platform === 'devtools'
  return desktop && Number(windowInfo.windowWidth || 0) >= DESKTOP_SPLIT_MIN_WIDTH
}

function getDesktopSplitUrl(fileId) {
  return `/pages/index/index?preview=${encodeURIComponent(fileId || '')}`
}

module.exports = {
  DESKTOP_SPLIT_MIN_WIDTH,
  getDesktopSplitUrl,
  getWindowInfo,
  supportsDesktopSplit
}
