/**
 * [EN] The Rive options of a tab icon, as the iOS Rive subspec reads them (docs/Rive-Animation.md): from the URL
 *      fragment written by CYLTabBarAnimationURLWithOptions() ("icons.riv#artboard=CHAT&stateMachine=…&input=active")
 *      and from the component's properties, the properties winning. Pure functions, tested in Node.
 * [CN] Tab 图标的 Rive 选项，读取方式与 iOS 的 Rive 子库相同（docs/Rive-Animation.md）：来自
 *      CYLTabBarAnimationURLWithOptions() 写入的 URL fragment（"icons.riv#artboard=CHAT&stateMachine=…&input=active"）
 *      与组件属性，属性优先。纯函数，在 Node 中测试。
 */
/**
 * [EN] Every option name cyl-rive reads from the path fragment and its properties; exported as `CYL_RIVE_OPTION_NAMES` so an
 *      adapter that writes the fragment imports it instead of copying it.
 * [CN] cyl-rive 从路径 fragment 与属性读取的全部选项名；导出为 `CYL_RIVE_OPTION_NAMES`，写 fragment 的适配器直接导入，不再复制。
 */
const CYL_OPTION_NAMES = Object.freeze(['artboard', 'stateMachine', 'animation', 'input', 'triggerInput', 'active', 'trigger',
  'duration', 'color', 'numberInput', 'number', 'values'])

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
  const merged = { ...options }
  CYL_OPTION_NAMES.forEach((key) => {
    if (properties?.[key] !== undefined && properties[key] !== null && properties[key] !== '') {
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
  const alpha = value.length === 8 ? Number.parseInt(value.slice(6, 8), 16) : 255
  return ((alpha << 24) >>> 0) + Number.parseInt(value.slice(0, 6), 16)
}

/**
 * [EN] What one play does (docs/Animated-Item.md, the Rive loop): 'trigger' fires the legacy trigger input, 'viewModelTrigger'
 *      fires the view model trigger, 'input' turns the boolean input / view model boolean off and then on (so a play always
 *      makes a transition, also when the value was already true), 'restart' restarts the state machine (a new instance) or
 *      the animation: a file whose input or trigger is missing, or that has none, still plays again.
 * [CN] 一次播放做什么（docs/Animated-Item.md，Rive 循环）：'trigger' 触发旧版 trigger 输入，'viewModelTrigger' 触发 view model trigger，
 *      'input' 先把布尔输入 / view model 布尔属性设为 false 再设为 true（即使原值已是 true，每次播放都会产生状态切换），'restart' 重新开始状态机
 *      （新实例）或动画：缺少输入或 trigger、或没有输入的文件也能再次播放。
 */
function cylRivePlayKind({ hasTriggerInput, hasViewModelTrigger, hasNumber, hasBoolInput }) {
  if (hasTriggerInput) {
    return 'trigger'
  }
  if (hasViewModelTrigger) {
    return 'viewModelTrigger'
  }
  if (hasNumber) {
    return 'number'
  }
  return hasBoolInput ? 'input' : 'restart'
}

/**
 * [EN] The `values` option ("3,4,5,6") as numbers; an empty list when it has none. [CN] `values` 选项（"3,4,5,6"）转为数字；没有时为空数组。
 */
function cylRiveNumberValues(values) {
  return String(values === undefined || values === null ? '' : values).split(',')
    .map((value) => value.trim()).filter((value) => value !== '').map(Number).filter((value) => Number.isFinite(value))
}

/**
 * [EN] Number inputs (house.riv's `Rooms`, a state machine NUMBER input, or a view model number for data binding): the value a
 *      play sets: the one after `current` in `values`, cycling; without `values`, `current + 1`. A state machine that
 *      moves only when the number changes plays on every call.
 * [CN] 数字输入（house.riv 的 `Rooms` 状态机 NUMBER 输入，或数据绑定的 view model 数字属性）：一次播放设置的值：`values` 中 `current` 的下一个，循环；
 *      没有 `values` 时为 `current + 1`。只在数字变化时运动的状态机，每次调用都会播放。
 */
function cylRiveNextNumber(values, current) {
  if (!values.length) {
    return (Number(current) || 0) + 1
  }
  const index = values.indexOf(Number(current))
  return values[(index + 1) % values.length]
}

/** [EN] Seconds of a loop pass when the file gives none (held input, trigger, state machine). [CN] 文件未给出时一次循环的秒数。 */
const CYL_RIVE_LOOP_SECONDS = 1.5
/** [EN] The pause after an input goes back to false, before the next pass. [CN] 输入恢复为 false 后、下一次播放前的停顿。 */
const CYL_RIVE_LOOP_PAUSE_SECONDS = 0.4

/**
 * [EN] Milliseconds from a play to the next one while looping: after the input goes back to false (`duration` above 0, plus a
 *      short pause), else after the animation's own length when it is known, else CYL_RIVE_LOOP_SECONDS; divided by the speed.
 * [CN] 循环时从一次播放到下一次的毫秒数：输入恢复为 false 后（`duration` 大于 0，再加短暂停顿），否则为动画自身时长（已知时），否则为
 *      CYL_RIVE_LOOP_SECONDS；再除以速度。
 */
function cylRiveLoopDelay({ kind, duration, animationSeconds, speed }) {
  const rate = Number(speed) > 0 ? Number(speed) : 1
  let seconds
  if (kind === 'input' && Number(duration) > 0) {
    seconds = Number(duration) + CYL_RIVE_LOOP_PAUSE_SECONDS
  } else if (Number(animationSeconds) > 0) {
    seconds = Number(animationSeconds)
  } else if (Number(duration) > 0) {
    seconds = Number(duration) + CYL_RIVE_LOOP_PAUSE_SECONDS
  } else {
    seconds = CYL_RIVE_LOOP_SECONDS
  }
  return Math.round(seconds * 1000 / rate)
}

module.exports = { CYL_RIVE_OPTION_NAMES: CYL_OPTION_NAMES, cylRiveRoute, cylRiveOptions, cylRiveColor, cylRivePlayKind, cylRiveLoopDelay, cylRiveNumberValues,
  cylRiveNextNumber, CYL_RIVE_LOOP_SECONDS }
