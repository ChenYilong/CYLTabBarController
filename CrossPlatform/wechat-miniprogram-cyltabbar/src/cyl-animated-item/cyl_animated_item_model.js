const { cylIsGIFImagePath } = require('./cyl_gif_image')
const { cylCountdownText } = require('./cyl_animated_item_countdown')
/**
 * [EN] The render model of cyl-animated-item, the mini program counterpart of iOS `CYLAnimatedItemView` (the
 *      CYLAnimatedItem pod) and Android `com.cyl.animateditem.CYLAnimatedItemView`. Pure functions without any wx API,
 *      tested in Node (test/cyl_animated_item.test.js). What shows, as on the other platforms: the animation once its
 *      engine component reports `ready`; until then, and after it reports `error` (no engine installed, a corrupt file, a
 *      failed download), the static image (`image` / `selectedImage`); the placeholder only when there is no static image.
 * [CN] cyl-animated-item 的渲染模型，对应 iOS 的 `CYLAnimatedItemView`（CYLAnimatedItem pod）与 Android 的
 *      `com.cyl.animateditem.CYLAnimatedItemView`。不使用任何 wx API 的纯函数，在 Node 中测试（test/cyl_animated_item.test.js）。
 *      显示规则与其他平台相同：动画组件报告 `ready` 后显示动画；在此之前以及报告 `error` 之后（没有安装引擎、文件损坏、下载失败），显示静态图片
 *      （`image` / `selectedImage`）；只有没有静态图片时才显示占位图。
 */

/**
 * [EN] The placeholder shipped with the component (a tab-icon-sized template, cyl_animated_item_placeholder.png), as a
 *      data URI: a relative `src` in a component's `<image>` was resolved against the page, so no placeholder showed
 *      (bug B6, docs/Animated-Item.md). [CN] 组件自带的占位图（cyl_animated_item_placeholder.png），以 data URI 提供：组件内 `<image>` 的
 *      相对 `src` 会按页面路径解析，导致占位图不显示（问题 B6）。
 */
const CYL_ANIMATED_ITEM_PLACEHOLDER = 'data:image/png;base64,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'

/**
 * [EN] Each animation type, its file extensions and the npm package an app adds. GIF is drawn by `<image>` itself.
 * [CN] 每种动画类型、其文件扩展名与 App 需要安装的 npm 包。GIF 由 `<image>` 自己绘制。
 */
const CYL_ANIMATED_ITEM_TYPES = [
  { type: 'lottie', extensions: ['json', 'lottie'], packageName: 'cyl-lottie-miniprogram' },
  { type: 'pag', extensions: ['pag'], packageName: 'cyl-pag-miniprogram' },
  { type: 'rive', extensions: ['riv'], packageName: 'cyl-rive-miniprogram' },
  { type: 'svga', extensions: ['svga'], packageName: 'cyl-svga-miniprogram' },
  { type: 'gif', extensions: ['gif'], packageName: '' },
]

/**
 * [EN] The animation type of a file from its extension, or '' when unknown. A trailing ".bin" is skipped: a mini program
 *      code package leaves out .pag, .riv and .svga files, so package copies are named *.svga.bin and alike, as the tab
 *      bar reads them (bug B6). [CN] 根据扩展名得到文件的动画类型，未知时为 ''。忽略末尾的 ".bin"：小程序代码包不包含 .pag、.riv 与 .svga 文件，
 *      包内副本命名为 *.svga.bin 等，与 TabBar 的读取方式相同（问题 B6）。
 */
function cylAnimatedItemType(path) {
  const file = String(path || '').split('#')[0].split('?')[0].replace(/\.bin$/i, '')
  const dot = file.lastIndexOf('.')
  const extension = dot >= 0 ? file.slice(dot + 1).toLowerCase() : ''
  const entry = CYL_ANIMATED_ITEM_TYPES.find((item) => extension && item.extensions.includes(extension))
  return entry ? entry.type : ''
}

/**
 * [EN] The npm package that plays `type`, or '' (GIF needs none). [CN] 播放 `type` 的 npm 包，没有时为 ''（GIF 不需要）。
 */
function cylAnimatedItemPackage(type) {
  const entry = CYL_ANIMATED_ITEM_TYPES.find((item) => item.type === type)
  return entry ? entry.packageName : ''
}

/**
 * [EN] The resting progress (0...1) of an engine: 1 while selected (a selected tab shows its last frame), else
 *      `restingProgress` clamped to 0...1, as `CYLAnimatedItemView.animationRestingProgress` on iOS.
 * [CN] 引擎的静止进度（0...1）：选中时为 1（选中的 Tab 显示最后一帧），否则为限制在 0...1 的 `restingProgress`，与 iOS 的
 *      `CYLAnimatedItemView.animationRestingProgress` 相同。
 */
function cylAnimatedItemRestingProgress(p) {
  if (p.selected) return 1
  const progress = Number(p.restingProgress)
  return Number.isFinite(progress) ? Math.min(1, Math.max(0, progress)) : 0
}

/**
 * [EN] What the GIF `<image>` shows. Without stills (`gifFirstFrame` / `gifLastFrame`) the GIF itself, always playing, as
 *      before. With them: the GIF while it plays (`gifPlaying`), else its last frame while selected or resting at 1, its
 *      first frame otherwise; a missing still falls back to the other one, then to the GIF.
 * [CN] GIF `<image>` 显示的内容。没有静帧（`gifFirstFrame` / `gifLastFrame`）时显示 GIF 本身并一直播放（与之前相同）。有静帧时：
 *      播放中（`gifPlaying`）显示 GIF，否则选中或静止进度为 1 时显示最后一帧，其余显示第一帧；缺少的静帧用另一帧代替，再退回 GIF。
 */
function cylAnimatedItemGifSource(p, animationPath) {
  const first = p.gifFirstFrame || ''
  const last = p.gifLastFrame || ''
  if (!first && !last) return animationPath
  if (p.gifPlaying) return animationPath
  const atEnd = cylAnimatedItemRestingProgress(p) >= 1
  return (atEnd ? last || first : first || last) || animationPath
}

/**
 * [EN] The model of one item from its properties and state (`animationLoaded`, `animationFailed`).
 * [CN] 由属性与状态（`animationLoaded`、`animationFailed`）得到一个条目的模型。
 */
/**
 * [EN] Whether the item is dark: `userInterfaceStyle` 'light' or 'dark' forces it (like the tab bar's
 *      `CYLTabBarControllerUserInterfaceStyle`); 'system' or unset follows `systemTheme` ('dark' / 'light').
 * [CN] 项是否为深色：`userInterfaceStyle` 为 'light' 或 'dark' 时强制（同 TabBar 的 `CYLTabBarControllerUserInterfaceStyle`）；
 *      'system' 或未设置时跟随 `systemTheme`（'dark' / 'light'）。
 */
function cylAnimatedItemIsDark(p) {
  const style = String(p.userInterfaceStyle || 'system').toLowerCase()
  if (style === 'light' || style === 'dark') return style === 'dark'
  return p.systemTheme === 'dark'
}

/** [EN] A positive size, or `fallback`. [CN] 正数尺寸，否则为 `fallback`。 */
function cylAnimatedItemDimension(value, fallback) {
  return Number(value) > 0 ? Number(value) : fallback
}

/**
 * [EN] Font weight: 'normal', 'bold', 'bolder', 'lighter' or 100–900; anything else keeps the default ('').
 * [CN] 字重：'normal'、'bold'、'bolder'、'lighter' 或 100–900；其他值保持默认（''）。
 */
function cylAnimatedItemFontWeight(weight) {
  const text = weight === null || weight === undefined ? '' : String(weight).trim()
  return /^(normal|bold|bolder|lighter|[1-9]00)$/.test(text) ? text : ''
}

/**
 * [EN] The gap between the icon and the title (margin-top when vertical, margin-left when horizontal); -1 keeps the
 *      default (2 px / 4 px). [CN] 图标与标题的间距（纵向为 margin-top，横向为 margin-left）；-1 为默认（2 px / 4 px）。
 */
function cylAnimatedItemSpacingStyle(p) {
  if (Number(p.titleSpacing) >= 0 && p.titleSpacing !== null && p.titleSpacing !== undefined && p.titleSpacing !== '') {
    const property = p.axis === 'vertical' ? 'margin-top' : 'margin-left'
    return `${property}: ${Number(p.titleSpacing)}px;`
  }
  return ''
}

/** [EN] The title's inline style. [CN] 标题的行内样式。 */
function cylAnimatedItemTitleStyle(p, titleColor, titleLines) {
  const titleFontWeight = cylAnimatedItemFontWeight(p.titleFontWeight)
  return (titleColor ? `color: ${titleColor};` : '') +
    (titleFontWeight ? `font-weight: ${titleFontWeight};` : '') +
    (Number(p.titleFontSize) > 0 ? `font-size: ${Number(p.titleFontSize)}px;` : '') +
    (titleLines > 1 ? `-webkit-line-clamp: ${titleLines};` : '') +
    (Number(p.titleLineHeight) > 0 ? `line-height: ${Number(p.titleLineHeight)}px;` : '') +
    cylAnimatedItemSpacingStyle(p)
}

/** [EN] The title's line class: none for one line, wrapping for no limit, clamped for n > 1. [CN] 标题行数的类名：单行无类名，不限行数时换行，n > 1 时截断。 */
function cylAnimatedItemTitleLinesClass(titleLines) {
  if (titleLines === 1) {
    return ''
  }
  return titleLines > 1 ? 'cyl-animated-item-title-wrap cyl-animated-item-title-clamp' : 'cyl-animated-item-title-wrap'
}

/**
 * [EN] The animation type: 'lottie' for inline data; `animationType` names the type when the file name cannot (a URL
 *      without an extension). [CN] 动画类型：内联数据为 'lottie'；文件名无法表明类型时（无扩展名的 URL），由 `animationType` 指定。
 */
function cylAnimatedItemResolvedType(p, animationPath, hasAnimationData) {
  const givenType = String(p.animationType || '').toLowerCase()
  const namedType = CYL_ANIMATED_ITEM_TYPES.some((item) => item.type === givenType) ? givenType : ''
  return hasAnimationData ? 'lottie' : namedType || cylAnimatedItemType(animationPath)
}

/**
 * [EN] The static image (the selected one when selected); the placeholder while a source has no animation showing.
 * [CN] 静态图片（选中时为选中图片）；有动画源但动画未显示时为占位图。
 */
function cylAnimatedItemFallbackImage(p, hasSource, animationShows) {
  const staticImage = (p.selected && p.selectedImage) || p.image || ''
  if (staticImage || !hasSource || animationShows) {
    return staticImage
  }
  return p.placeholderImage === undefined || p.placeholderImage === null ? CYL_ANIMATED_ITEM_PLACEHOLDER : p.placeholderImage
}

/** [EN] The GIF image of an item: its static image when that is a GIF and no animation shows. [CN] 条目的 GIF 图片：静态图片是 GIF 且没有动画显示时。 */
function cylGIFImageOf(p, hasSource, fallbackImage) {
  if (hasSource && !p.animationFailed) return ''
  return cylIsGIFImagePath(fallbackImage) ? fallbackImage : ''
}

/** [EN] Whether the first-frame still covers the GIF image (decoded, not playing). [CN] 第一帧静帧是否代替 GIF 图片显示（已解码且未播放）。 */
function cylGIFImageStillShows(p, hasSource, fallbackImage) {
  return !!cylGIFImageOf(p, hasSource, fallbackImage) && !!p.gifImageReady && !p.gifImagePlaying
}

/**
 * [EN] The widest title a countdown shows (idle, finished, the running one with the widest digits of the duration), in px,
 *      estimated from the font size (a CJK character is one em wide, any other 0.6 em), so the item keeps its width while the
 *      digits change. 0 for another style. [CN] 倒计时会显示的最宽标题（待机、结束、以最宽数字组成的倒计时），单位 px，按字号估算
 *      （中日韩字符宽 1 em，其他字符 0.6 em），使条目在数字变化时保持宽度。其他样式为 0。
 */
function cylAnimatedItemCountdownTitleWidth(p) {
  if (p.itemStyle !== 'countdown') return 0
  const fontSize = Number(p.titleFontSize) > 0 ? Number(p.titleFontSize) : 14
  const digits = String(Math.max(1, Math.ceil(Number(p.countdownDuration) || 60))).length
  const widest = Number('8'.repeat(digits))
  const width = (text) => Array.from(text).reduce((sum, ch) => sum + (/[\u2e80-\u9fff\uac00-\ud7af\uff00-\uffef]/.test(ch) ? 1 : 0.6), 0) * fontSize
  return Math.ceil(Math.max(
    width(p.countdownIdleTitle || ''),
    width(p.countdownFinishedTitle || ''),
    width(cylCountdownText(p.countdownRunningTitleFormat || '', widest))))
}

/**
 * [EN] The properties of a countdown item: its title for the state (idle, running with the seconds left, finished), the
 *      countdown icon and the gray title color while running, and disabled while running. Another style keeps `p`.
 * [CN] 倒计时条目的属性：当前状态的标题（待机、带剩余秒数的倒计时、结束）、倒计时中的图标与灰色标题、倒计时中不可用。其他样式保持 `p` 不变。
 */
function cylAnimatedItemCountdownProperties(p) {
  if (p.itemStyle !== 'countdown') return p
  const running = p.countdownState === 'running'
  let title = p.countdownIdleTitle || ''
  if (running) title = cylCountdownText(p.countdownRunningTitleFormat || '', Math.max(Number(p.countdownSeconds) || 0, 0))
  else if (p.countdownState === 'finished') title = p.countdownFinishedTitle || ''
  return {
    ...p,
    title,
    image: running && p.countdownImage ? p.countdownImage : p.image,
    enabled: p.enabled !== false && !running,
    titleColor: running ? p.countdownRunningTitleColor || '#999999' : p.titleColor,
    titleDarkColor: running ? '' : p.titleDarkColor,
  }
}

function cylAnimatedItemModel(input) {
  const p = cylAnimatedItemCountdownProperties(input)
  const animationPath = p.animationUrl || ''
  const hasAnimationData = !!p.animationData && typeof p.animationData === 'object'
  const animationType = cylAnimatedItemResolvedType(p, animationPath, hasAnimationData)
  const hasSource = !!animationPath || hasAnimationData
  const usesEngine = hasSource && !!animationType && animationType !== 'gif' && !p.animationFailed
  const gifShows = animationType === 'gif' && !p.animationFailed
  const animationShows = gifShows || (usesEngine && !!p.animationLoaded)
  const fallbackImage = cylAnimatedItemFallbackImage(p, hasSource, animationShows)
  const iconSize = cylAnimatedItemDimension(p.iconSize, 24)
  const iconWidth = cylAnimatedItemDimension(p.iconWidth, iconSize)
  const iconHeight = cylAnimatedItemDimension(p.iconHeight, iconSize)
  const title = p.title || ''
  const label = p.accessibilityLabel || title
  // [EN] Title look: color, font size (px) and line count (1: one line with an ellipsis, the default; 0: no limit;
  //      n > 1: up to n lines, then an ellipsis). [CN] 标题外观：颜色、字号（px）与行数（1：单行省略，默认；0：不限；n > 1：最多 n 行后省略）。
  const titleLines = Number.isFinite(Number(p.titleLines)) && Number(p.titleLines) >= 0 ? Math.floor(Number(p.titleLines)) : 1
  // [EN] Dark mode: `titleDarkColor` replaces `titleColor` while the item is dark (`userInterfaceStyle` 'dark', or
  //      'system' / unset with the system theme dark). [CN] 深色模式：项为深色时（`userInterfaceStyle` 为 'dark'，或为 'system' /
  //      未设置且系统主题为深色）以 `titleDarkColor` 代替 `titleColor`。
  const dark = cylAnimatedItemIsDark(p)
  const titleColor = dark && p.titleDarkColor ? p.titleDarkColor : p.titleColor
  const countdownWidth = cylAnimatedItemCountdownTitleWidth(p)
  const titleStyle = cylAnimatedItemTitleStyle(p, titleColor, titleLines) + (countdownWidth > 0 ? `min-width: ${countdownWidth}px; text-align: center;` : '')
  const titleLinesClass = cylAnimatedItemTitleLinesClass(titleLines)
  return {
    title,
    titleStyle,
    titleLinesClass,
    dark,
    animationPath,
    animationType,
    restingFrame: p.selected ? 'last' : 'first',
    usesEngine,
    gifPath: gifShows ? cylAnimatedItemGifSource(p, animationPath) : '',
    fallbackImage,
    fallbackHidden: (animationShows && !gifShows) || cylGIFImageStillShows(p, hasSource, fallbackImage),
    // [EN] A GIF given as the image (no animation, or a failed one): it rests on its first frame, drawn on a canvas, until
    //      it is played (docs/GIF-Animation.md). [CN] 作为图片传入的 GIF（没有动画或动画失败）：在被播放之前停在第一帧（绘制在 canvas 上）。
    gifImage: cylGIFImageOf(p, hasSource, fallbackImage),
    gifImageStill: cylGIFImageStillShows(p, hasSource, fallbackImage),
    showsIcon: !!(fallbackImage || usesEngine || gifShows),
    iconStyle: `width: ${iconWidth}px; height: ${iconHeight}px;`,
    // [EN] A tint applies to the static image only; an animation keeps its own colors. [CN] 着色只作用于静态图片。
    iconTint: p.iconTint || '',
    // [EN] The animation's one color (cyl-rive `tint`). [CN] 动画的单一颜色（cyl-rive 的 `tint`）。
    animationTint: String(p.animationTint || '').trim(),
    axisClass: (p.axis === 'vertical' ? 'cyl-animated-item-vertical' : 'cyl-animated-item-horizontal') + (p.embedded ? ' cyl-animated-item-embedded' : '') + (p.itemStyle === 'countdown' ? ' cyl-animated-item-countdown' : ''),
    ariaHidden: !!p.embedded,
    accessoryPlacement: ['leading', 'trailing', 'topTrailing'].includes(p.accessoryPlacement) ? p.accessoryPlacement : 'trailing',
    hasAccessory: !!(p.accessoryImage || p.accessoryText),
    accessoryLabel: p.accessoryAccessibilityLabel || p.accessoryText || '',
    ariaLabel: label,
    ariaSelected: !!p.selected,
    ariaDisabled: p.enabled === false,
  }
}

module.exports = {
  cylAnimatedItemCountdownTitleWidth,
  cylAnimatedItemIsDark,
  cylAnimatedItemModel,
  cylAnimatedItemType,
  cylAnimatedItemPackage,
  cylAnimatedItemRestingProgress,
  cylAnimatedItemGifSource,
  CYL_ANIMATED_ITEM_PLACEHOLDER,
  CYL_ANIMATED_ITEM_TYPES,
}
