/**
 * [EN] Colour contrast on dark Liquid Glass: an EXPLICIT title or icon colour that does not contrast enough with the glass is lifted
 *      (HSL lightness raised in 0.005 steps, hue, saturation and alpha kept, never above white). The rule proven in ClassifyMenu
 *      (CYLIconContrast); 3 for an icon tint, 4.5 for title text. Dark glass only: light glass is never changed. Pure and deterministic.
 *      Only '#RRGGBB', '#RRGGBBAA' and 'rgb()' / 'rgba()' (integer channels) are understood; any other text is returned as it is.
 * [CN] 深色液态玻璃上的颜色对比度：与玻璃对比度不足的「显式」标题或图标颜色会被提亮（HSL 亮度按 0.005 步进升高，保持色相、饱和度与透明度，
 *      最高为白色）。规则取自 ClassifyMenu（CYLIconContrast）；图标着色为 3，标题文字为 4.5。只处理深色玻璃：浅色玻璃不改变。纯函数、结果确定。
 *      只识别 '#RRGGBB'、'#RRGGBBAA' 与 'rgb()' / 'rgba()'（整数通道）；其他文本原样返回。
 */
const CYL_ICON_MINIMUM_CONTRAST = 3
const CYL_TITLE_MINIMUM_CONTRAST = 4.5
/** [EN] White share of the default frosted glass in dark mode (over black about #242424). */
const CYL_FROSTED_GLASS_WHITE_ALPHA = 0.14
/** [EN] The share of an explicit glass tint's alpha that tints the glass when no tint alpha is given. */
const CYL_DEFAULT_GLASS_TINT_SHARE = 0.75
const LIGHTNESS_STEP = 0.005
const RGB_MAX = 255
const HUE_SECTORS = 6

/** The { r, g, b, a, alphaText, hex } of a parseable color text, or null. */
function parseColor(text) {
  const value = String(text === null || text === undefined ? '' : text).trim()
  const hex = /^#([0-9a-fA-F]{6})([0-9a-fA-F]{2})?$/.exec(value)
  if (hex) {
    const n = Number.parseInt(hex[1], 16)
    const alphaDigits = hex[2] || ''
    return { r: Math.floor(n / 65536) % 256, g: Math.floor(n / 256) % 256, b: n % 256, a: alphaDigits ? Number.parseInt(alphaDigits, 16) / RGB_MAX : 1, alphaText: alphaDigits.toUpperCase(), hex: true }
  }
  const fn = /^rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})\s*(?:,\s*(\d*\.?\d+)\s*)?\)$/i.exec(value)
  if (!fn) return null
  const channels = [Number(fn[1]), Number(fn[2]), Number(fn[3])]
  if (channels.some((x) => x > RGB_MAX)) return null
  const alpha = fn[4] === undefined ? 1 : Number(fn[4])
  if (!(alpha >= 0 && alpha <= 1)) return null
  return { r: channels[0], g: channels[1], b: channels[2], a: alpha, alphaText: fn[4] === undefined ? '' : fn[4], hex: false }
}

/** WCAG relative luminance of an sRGB color, components 0..1. */
function relativeLuminance(red, green, blue) {
  const channel = (s) => (s <= 0.03928 ? s / 12.92 : Math.pow((s + 0.055) / 1.055, 2.4))
  return 0.2126 * channel(red) + 0.7152 * channel(green) + 0.0722 * channel(blue)
}

function contrastRatio(first, second) {
  return (Math.max(first, second) + 0.05) / (Math.min(first, second) + 0.05)
}

/**
 * [EN] The luminance the text is judged against: the glass over black. No usable glass color (empty, unparseable, alpha 0): the default
 *      frosted glass (white at 0.14); else the color times its alpha times `tintAlpha` (0.75 when missing or negative).
 */
function cylAnimatedItemGlassReferenceLuminance(glassColor, tintAlpha) {
  const tint = parseColor(glassColor)
  if (!tint || !(tint.a > 0)) return relativeLuminance(CYL_FROSTED_GLASS_WHITE_ALPHA, CYL_FROSTED_GLASS_WHITE_ALPHA, CYL_FROSTED_GLASS_WHITE_ALPHA)
  const share = tint.a * (typeof tintAlpha === 'number' && tintAlpha >= 0 ? tintAlpha : CYL_DEFAULT_GLASS_TINT_SHARE)
  return relativeLuminance((tint.r / RGB_MAX) * share, (tint.g / RGB_MAX) * share, (tint.b / RGB_MAX) * share)
}

function hslFromRgb(red, green, blue) {
  const high = Math.max(red, green, blue)
  const low = Math.min(red, green, blue)
  const lightness = (high + low) / 2
  const delta = high - low
  if (!(delta > 0)) return { hue: 0, saturation: 0, lightness }
  const saturation = delta / (1 - Math.abs(2 * lightness - 1))
  let hue
  if (high === red) {
    hue = (green - blue) / delta
    if (hue < 0) hue += HUE_SECTORS
  } else if (high === green) {
    hue = (blue - red) / delta + 2
  } else {
    hue = (red - green) / delta + 4
  }
  return { hue: hue / HUE_SECTORS, saturation, lightness }
}

function rgbFromHsl(hue, saturation, lightness) {
  const chroma = (1 - Math.abs(2 * lightness - 1)) * saturation
  const sector = hue * HUE_SECTORS
  const second = chroma * (1 - Math.abs((sector % 2) - 1))
  const base = lightness - chroma / 2
  const parts = [[chroma, second, 0], [second, chroma, 0], [0, chroma, second], [0, second, chroma], [second, 0, chroma], [chroma, 0, second]][Math.floor(sector) % HUE_SECTORS]
  return { red: parts[0] + base, green: parts[1] + base, blue: parts[2] + base }
}

function byteOf(x) {
  return Math.max(0, Math.min(RGB_MAX, Math.round(x * RGB_MAX)))
}

/**
 * [EN] `color` lifted until it has `minimumContrast` against the glass (see the file comment); `color` itself (the same text) when it
 *      already passes or cannot be parsed. Call it only for an explicit color, on drawn dark glass.
 * @param {string} color the explicit color text
 * @param {number} minimumContrast 3 (icon tint) or 4.5 (title)
 * @param {string} [glassColor] the explicit glass color ('' or missing: the default frosted glass)
 * @param {number} [tintAlpha] the tint alpha of the glass (missing or negative: 0.75)
 */
function cylAnimatedItemContrastLift(color, minimumContrast, glassColor, tintAlpha) {
  const c = parseColor(color)
  if (!c) return color
  const reference = cylAnimatedItemGlassReferenceLuminance(glassColor, tintAlpha)
  const hsl = hslFromRgb(c.r / RGB_MAX, c.g / RGB_MAX, c.b / RGB_MAX)
  // The ratio of the color as drawn (whole bytes), so the result keeps the ratio it was judged by.
  const ratioAt = (lightness) => {
    const rgb = rgbFromHsl(hsl.hue, hsl.saturation, lightness)
    return contrastRatio(relativeLuminance(byteOf(rgb.red) / RGB_MAX, byteOf(rgb.green) / RGB_MAX, byteOf(rgb.blue) / RGB_MAX), reference)
  }
  if (contrastRatio(relativeLuminance(c.r / RGB_MAX, c.g / RGB_MAX, c.b / RGB_MAX), reference) >= minimumContrast) return color
  let lightness = hsl.lightness
  while (lightness < 1 && ratioAt(lightness) < minimumContrast) lightness = Math.min(1, lightness + LIGHTNESS_STEP)
  const rgb = rgbFromHsl(hsl.hue, hsl.saturation, lightness)
  const [r, g, b] = [byteOf(rgb.red), byteOf(rgb.green), byteOf(rgb.blue)]
  if (c.hex) return `#${[r, g, b].map((x) => x.toString(16).padStart(2, '0')).join('').toUpperCase()}${c.alphaText}`
  return c.alphaText ? `rgba(${r}, ${g}, ${b}, ${c.alphaText})` : `rgb(${r}, ${g}, ${b})`
}

module.exports = {
  CYL_ICON_MINIMUM_CONTRAST,
  CYL_TITLE_MINIMUM_CONTRAST,
  CYL_FROSTED_GLASS_WHITE_ALPHA,
  CYL_DEFAULT_GLASS_TINT_SHARE,
  cylAnimatedItemGlassReferenceLuminance,
  cylAnimatedItemContrastLift,
}
