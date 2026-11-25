/**
 * [EN] ONE-COLOR DETECTION (tint spec v2, section 5): pure functions over the file data, the same algorithm and fixtures on every
 *      platform. The result is 'one' (exactly one color), 'multi' (more than one, a gradient or an image) or 'unknown' (not
 *      parseable, or no color at all: the file keeps its original colors).
 *      WHAT THE MINI PROGRAM DOES WITH IT: it can only tint Rive (canvas fill) and a playing GIF (CSS filter). So the automatic
 *      rendering mode NEVER tints Lottie, PAG or SVGA here (their engines cannot recolor); `cylLottieColorKind` is kept for parity
 *      with the other platforms and for the shared tests. Rive and PAG / SVGA are undetectable. Only a GIF is detected at run time
 *      (`cylGIFColorKind`, from the first frame, cached per URL).
 *      Lottie: distinct RGB of fill (`fl`) and stroke (`st`) colors, static values and every keyframe value; the alpha of a color and fully
 *      transparent colors (a 4th channel of 0, or a static opacity of 0) are ignored; two colors within +-2/255 per channel are the
 *      same; gradient fills / strokes (`gf` / `gs`) and images (an image layer, `ty` 2, or an asset with `p`) are multi-color.
 *      GIF: pixels with alpha < 0.1 are ignored; the rest are quantized to 4 bits per channel; 98 % or more in ONE bucket is one color.
 * [CN] 单色检测（着色规范 v2 第 5 节）：作用于文件数据的纯函数，各平台算法与测试夹具相同。结果为 'one'（恰好一种颜色）、'multi'（多种颜色、
 *      渐变或图片）或 'unknown'（无法解析或没有任何颜色：保持原色）。
 *      小程序如何使用：小程序只能给 Rive（canvas 填充）与播放中的 GIF（CSS filter）改色，因此自动渲染模式在这里「从不」给 Lottie、PAG、SVGA
 *      着色（它们的引擎无法改色）；`cylLottieColorKind` 为与其他平台保持一致及共享测试而保留。Rive、PAG、SVGA 无法检测。运行时只检测 GIF
 *      （`cylGIFColorKind`，取第一帧，按 URL 缓存）。
 */

const CYL_ONE_COLOR_TOLERANCE = 2
const CYL_GIF_MIN_ALPHA = 0.1
const CYL_GIF_ONE_BUCKET_SHARE = 0.98

/** [EN] A color as [r, g, b] in 0-255 from a Lottie color array (0-1 floats; 0-255 when any channel is above 1); null when unusable or fully transparent. [CN] 由 Lottie 颜色数组得到 0-255 的 [r, g, b]；无法使用或完全透明时为 null。 */
function cylLottieRGB(value) {
  if (!Array.isArray(value) || value.length < 3) return null
  const channels = value.slice(0, 3).map(Number)
  if (channels.some((channel) => !Number.isFinite(channel))) return null
  if (value.length >= 4 && Number(value[3]) === 0) return null
  const scale = channels.some((channel) => channel > 1) ? 1 : 255
  return channels.map((channel) => Math.round(Math.min(255, Math.max(0, channel * scale))))
}

/** [EN] Every color array of an animated property (`{ a, k }`): the static value, or each keyframe's `s` and `e`. [CN] 动画属性（`{ a, k }`）的所有颜色数组：静态值，或每个关键帧的 `s` 与 `e`。 */
function cylLottieColorArrays(property) {
  const k = property && property.k
  if (!Array.isArray(k)) return []
  if (k.length && typeof k[0] === 'object' && k[0] !== null && !Array.isArray(k[0])) {
    const arrays = []
    k.forEach((frame) => { if (frame) { arrays.push(frame.s, frame.e) } })
    return arrays
  }
  return [k]
}

/** [EN] Whether the shape item is invisible: a static opacity of 0. [CN] 形状项是否不可见：静态不透明度为 0。 */
function cylLottieInvisible(item) {
  const o = item && item.o
  return !!o && o.a !== 1 && Number(o.k) === 0 && !Array.isArray(o.k)
}

/** [EN] Walks the JSON: collects colors into `state.colors`, sets `state.multi` for gradients and images. [CN] 遍历 JSON：把颜色收集到 `state.colors`，渐变与图片设置 `state.multi`。 */
function cylLottieWalk(node, state) {
  if (!node || typeof node !== 'object' || state.multi) return
  if (Array.isArray(node)) { node.forEach((child) => cylLottieWalk(child, state)); return }
  if (node.ty === 'gf' || node.ty === 'gs') { state.multi = true; return }
  if (node.ty === 2 && (node.refId !== undefined || node.ind !== undefined)) { state.multi = true; return }
  if (typeof node.p === 'string' && node.p !== '' && (node.w !== undefined || node.u !== undefined) && node.layers === undefined) { state.multi = true; return }
  if ((node.ty === 'fl' || node.ty === 'st') && !cylLottieInvisible(node)) {
    cylLottieColorArrays(node.c).forEach((array) => {
      const rgb = cylLottieRGB(array)
      if (rgb && !state.colors.some((known) => known.every((channel, i) => Math.abs(channel - rgb[i]) <= CYL_ONE_COLOR_TOLERANCE))) state.colors.push(rgb)
    })
  }
  Object.keys(node).forEach((key) => cylLottieWalk(node[key], state))
}

/**
 * [EN] 'one' | 'multi' | 'unknown' for a Lottie JSON (a parsed object or the JSON text). [CN] Lottie JSON（已解析对象或 JSON 文本）的检测结果。
 */
function cylLottieColorKind(json) {
  let data = json
  if (typeof json === 'string') {
    try { data = JSON.parse(json) } catch (e) { return 'unknown' }
  }
  if (!data || typeof data !== 'object') return 'unknown'
  const state = { colors: [], multi: false }
  cylLottieWalk(data, state)
  if (state.multi || state.colors.length > 1) return 'multi'
  return state.colors.length === 1 ? 'one' : 'unknown'
}

/**
 * [EN] 'one' | 'multi' | 'unknown' for the first frame of a GIF as RGBA bytes (`premultiplied` true: un-premultiply first). 'unknown' without
 *      enough data or without a visible pixel. [CN] GIF 第一帧（RGBA 字节）的检测结果（`premultiplied` 为 true 时先还原预乘）；数据不足或没有可见像素时为 'unknown'。
 */
function cylGIFColorKind(rgba, premultiplied) {
  if (!rgba || typeof rgba.length !== 'number' || rgba.length < 4) return 'unknown'
  const buckets = new Map()
  let visible = 0
  for (let i = 0; i + 3 < rgba.length; i += 4) {
    const alpha = rgba[i + 3] / 255
    if (alpha < CYL_GIF_MIN_ALPHA) continue
    const channel = (offset) => {
      const value = premultiplied ? Math.min(255, Math.round(rgba[i + offset] / alpha)) : rgba[i + offset]
      return value >> 4
    }
    const key = (channel(0) << 8) | (channel(1) << 4) | channel(2)
    buckets.set(key, (buckets.get(key) || 0) + 1)
    visible++
  }
  if (!visible) return 'unknown'
  return Math.max(...buckets.values()) / visible >= CYL_GIF_ONE_BUCKET_SHARE ? 'one' : 'multi'
}

module.exports = { cylLottieColorKind, cylGIFColorKind, CYL_ONE_COLOR_TOLERANCE }
