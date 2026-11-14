/**
 * [EN] The Rive options of a tab icon, as the iOS Rive subspec reads them (docs/Rive-Animation.md): from the URL
 *      fragment written by CYLTabBarAnimationURLWithOptions() ("icons.riv#artboard=CHAT&stateMachine=…&input=active")
 *      and from the component's properties, the properties winning. Pure functions, tested in Node.
 * [CN] Tab 图标的 Rive 选项，读取方式与 iOS 的 Rive 子库相同（docs/Rive-Animation.md）：来自
 *      CYLTabBarAnimationURLWithOptions() 写入的 URL fragment（"icons.riv#artboard=CHAT&stateMachine=…&input=active"）
 *      与组件属性，属性优先。纯函数，在 Node 中测试。
 */
const CYL_OPTION_NAMES = ['artboard', 'stateMachine', 'animation', 'input', 'triggerInput', 'active', 'trigger',
  'duration', 'color']

/**
 * [EN] {path, options}: the file path without its fragment, and the fragment's options.
 * [CN] {path, options}：去掉 fragment 的文件路径，以及 fragment 中的选项。
 */
function cylRiveRoute(route) {
  const value = String(route || '')
  const index = value.indexOf('#')
  const options = {}
  if (index >= 0) {
    value.slice(index + 1).split('&').forEach((pair) => {
      const [key, raw] = pair.split('=')
      if (CYL_OPTION_NAMES.includes(key) && raw !== undefined) {
        options[key] = decodeURIComponent(raw)
      }
    })
  }
  return { path: index >= 0 ? value.slice(0, index) : value, options }
}

/**
 * [EN] The options in use: properties over the fragment; `duration` in seconds (default 1, 0 keeps the input on,
 *      at most 60), as on iOS.
 * [CN] 实际使用的选项：属性优先于 fragment；`duration` 单位为秒（默认 1，0 表示保持，最长 60），与 iOS 相同。
 */
function cylRiveOptions(route, properties) {
  const { path, options } = cylRiveRoute(route)
  const merged = Object.assign({}, options)
  CYL_OPTION_NAMES.forEach((key) => {
    if (properties && properties[key] !== undefined && properties[key] !== null && properties[key] !== '') {
      merged[key] = properties[key]
    }
  })
  const duration = Number(merged.duration === undefined ? 1 : merged.duration)
  merged.duration = Number.isFinite(duration) ? Math.min(60, Math.max(0, duration)) : 1
  return { path, options: merged }
}

/**
 * [EN] "#RRGGBB" / "#RRGGBBAA" as a Rive ARGB integer; null when invalid.
 * [CN] 把 "#RRGGBB" / "#RRGGBBAA" 转为 Rive 的 ARGB 整数；无效时返回 null。
 */
function cylRiveColor(hex) {
  const value = String(hex || '').trim().replace(/^#/, '')
  if (!/^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(value)) {
    return null
  }
  const alpha = value.length === 8 ? parseInt(value.slice(6, 8), 16) : 255
  return ((alpha << 24) >>> 0) + parseInt(value.slice(0, 6), 16)
}

module.exports = { cylRiveRoute, cylRiveOptions, cylRiveColor }
