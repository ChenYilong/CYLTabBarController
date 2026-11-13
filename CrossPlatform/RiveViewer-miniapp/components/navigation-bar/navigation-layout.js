const DEFAULT_NAVIGATION_HEIGHT = 44
const ANDROID_NAVIGATION_HEIGHT = 48
const DESKTOP_EDGE_FALLBACK = 72
const MOBILE_EDGE_FALLBACK = 96

function toFiniteNumber(value, fallback = 0) {
  const number = Number(value)
  return Number.isFinite(number) ? number : fallback
}

function clamp(value, minimum, maximum) {
  return Math.min(Math.max(value, minimum), maximum)
}

function calculateNavigationLayout({
  windowInfo = {},
  deviceInfo = {},
  menuRect = {}
} = {}) {
  const platform = String(deviceInfo.platform || '').toLowerCase()
  const isAndroid = platform === 'android'
  const isDevtools = platform === 'devtools'
  const isDesktop = platform === 'mac' || platform === 'windows'
  const navigationHeight = isAndroid
    ? ANDROID_NAVIGATION_HEIGHT
    : DEFAULT_NAVIGATION_HEIGHT
  const windowWidth = Math.max(0, toFiniteNumber(windowInfo.windowWidth))
  const menuLeft = toFiniteNumber(menuRect.left, -1)
  const menuTop = toFiniteNumber(menuRect.top, -1)
  const menuWidth = Math.max(0, toFiniteNumber(menuRect.width))
  const menuHeight = Math.max(0, toFiniteNumber(menuRect.height))
  const hasValidMenuRect = Boolean(
    windowWidth > 0
    && menuLeft > 0
    && menuLeft < windowWidth
    && menuWidth > 0
    && menuHeight > 0
  )

  const fallbackEdgeWidth = isDesktop
    ? DESKTOP_EDGE_FALLBACK
    : MOBILE_EDGE_FALLBACK
  const maximumEdgeWidth = windowWidth
    ? Math.min(160, Math.max(fallbackEdgeWidth, windowWidth * 0.42))
    : 160
  const edgeWidth = Math.round(hasValidMenuRect
    ? clamp(windowWidth - menuLeft, 56, maximumEdgeWidth)
    : fallbackEdgeWidth)

  const statusBarHeight = Math.max(0, toFiniteNumber(windowInfo.statusBarHeight))
  const safeAreaTop = Math.max(0, toFiniteNumber(windowInfo.safeArea?.top))
  let topInset = 0
  if (isDesktop) {
    const menuAlignedInset = hasValidMenuRect
      ? menuTop - Math.max(0, (navigationHeight - menuHeight) / 2)
      : 0
    topInset = Math.max(statusBarHeight, safeAreaTop, menuAlignedInset)
  } else if (isAndroid || isDevtools) {
    topInset = Math.max(statusBarHeight, safeAreaTop)
  }

  return {
    platform,
    isAndroid,
    isDesktop,
    navigationHeight,
    edgeWidth,
    topInset: Math.max(0, Math.round(topInset)),
    hasValidMenuRect
  }
}

module.exports = {
  calculateNavigationLayout
}
