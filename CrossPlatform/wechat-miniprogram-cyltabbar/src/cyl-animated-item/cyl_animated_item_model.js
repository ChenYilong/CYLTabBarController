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

/** [EN] The placeholder shipped with the component (a tab-icon-sized template). [CN] 组件自带的占位图（适合 Tab 图标尺寸的模板图）。 */
const CYL_ANIMATED_ITEM_PLACEHOLDER = './cyl_animated_item_placeholder.png'

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
 * [EN] The animation type of a file from its extension, or '' when unknown. [CN] 根据扩展名得到文件的动画类型，未知时为 ''。
 */
function cylAnimatedItemType(path) {
  const file = String(path || '').split('#')[0].split('?')[0]
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
 * [EN] The model of one item from its properties and state (`animationLoaded`, `animationFailed`).
 * [CN] 由属性与状态（`animationLoaded`、`animationFailed`）得到一个条目的模型。
 */
function cylAnimatedItemModel(p) {
  const animationPath = p.animationUrl || ''
  const animationType = cylAnimatedItemType(animationPath)
  const usesEngine = !!animationPath && !!animationType && animationType !== 'gif' && !p.animationFailed
  const gifShows = animationType === 'gif' && !p.animationFailed
  const animationShows = gifShows || (usesEngine && !!p.animationLoaded)
  const staticImage = (p.selected && p.selectedImage) || p.image || ''
  const placeholder = p.placeholderImage === undefined || p.placeholderImage === null ? CYL_ANIMATED_ITEM_PLACEHOLDER : p.placeholderImage
  let fallbackImage = staticImage
  if (!fallbackImage && animationPath && !animationShows) {
    fallbackImage = placeholder
  }
  const iconSize = Number(p.iconSize) > 0 ? Number(p.iconSize) : 24
  const iconWidth = Number(p.iconWidth) > 0 ? Number(p.iconWidth) : iconSize
  const iconHeight = Number(p.iconHeight) > 0 ? Number(p.iconHeight) : iconSize
  const title = p.title || ''
  const label = p.accessibilityLabel || title
  return {
    title,
    animationPath,
    animationType,
    usesEngine,
    gifPath: gifShows ? animationPath : '',
    fallbackImage,
    fallbackHidden: animationShows && !gifShows,
    showsIcon: !!(fallbackImage || usesEngine || gifShows),
    iconStyle: `width: ${iconWidth}px; height: ${iconHeight}px;`,
    // [EN] A tint applies to the static image only; an animation keeps its own colors. [CN] 着色只作用于静态图片。
    iconTint: p.iconTint || '',
    axisClass: p.axis === 'vertical' ? 'cyl-animated-item-vertical' : 'cyl-animated-item-horizontal',
    accessoryPlacement: ['leading', 'trailing', 'topTrailing'].includes(p.accessoryPlacement) ? p.accessoryPlacement : 'trailing',
    hasAccessory: !!(p.accessoryImage || p.accessoryText),
    accessoryLabel: p.accessoryAccessibilityLabel || p.accessoryText || '',
    ariaLabel: label,
    ariaSelected: !!p.selected,
    ariaDisabled: p.enabled === false,
  }
}

module.exports = {
  cylAnimatedItemModel,
  cylAnimatedItemType,
  cylAnimatedItemPackage,
  CYL_ANIMATED_ITEM_PLACEHOLDER,
  CYL_ANIMATED_ITEM_TYPES,
}
