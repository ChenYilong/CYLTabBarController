/**
 * [EN] Recolors a Lottie animation before it is loaded, as CYLTabBarLottieDarkColors / CYLTabBarAnimationColors do on
 *      iOS: keypath -> "#RRGGBB" or "#RRGGBBAA". A keypath is a dot-separated list of layer, group and shape names
 *      ("Icon_Shop_Normal.**.Fill 1"), "*" matches one name and "**" any number of names; a trailing ".Color" is
 *      optional. Matching fills ("fl") and strokes ("st") get the color as a static value. Pure functions, tested in
 *      Node.
 * [CN] 在加载前给 Lottie 动画换色，与 iOS 的 CYLTabBarLottieDarkColors / CYLTabBarAnimationColors 相同：
 *      keypath -> "#RRGGBB" 或 "#RRGGBBAA"。keypath 是以点分隔的图层、分组与形状名称（"Icon_Shop_Normal.**.Fill 1"），
 *      "*" 匹配一个名称，"**" 匹配任意多个名称；末尾的 ".Color" 可省略。匹配到的填充（"fl"）与描边（"st"）使用该颜色
 *      作为静态值。纯函数，在 Node 中测试。
 */

/**
 * [EN] "#RRGGBB" / "#RRGGBBAA" / "#RGB" as Lottie's [r, g, b, a] in 0…1; null when invalid.
 * [CN] 把 "#RRGGBB" / "#RRGGBBAA" / "#RGB" 转为 Lottie 的 [r, g, b, a]（0…1）；无效时返回 null。
 */
function cylLottieColor(hex) {
  const value = String(hex || '').trim().replace(/^#/, '')
  const full = value.length === 3 ? value.split('').map((c) => c + c).join('') : value
  if (!/^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$/.test(full)) {
    return null
  }
  const channels = full.match(/../g).map((pair) => parseInt(pair, 16) / 255)
  return channels.length === 3 ? channels.concat(1) : channels
}

/**
 * [EN] Whether a list of names matches a keypath pattern ("*" one name, "**" any number).
 * [CN] 名称列表是否匹配 keypath 模式（"*" 匹配一个名称，"**" 匹配任意多个）。
 */
function cylMatches(pattern, names) {
  if (pattern.length === 0) {
    return names.length === 0
  }
  const [head, ...rest] = pattern
  if (head === '**') {
    for (let index = 0; index <= names.length; index += 1) {
      if (cylMatches(rest, names.slice(index))) {
        return true
      }
    }
    return false
  }
  return names.length > 0 && (head === '*' || head === names[0]) && cylMatches(rest, names.slice(1))
}

function cylVisitShapes(shapes, path, visit) {
  (shapes || []).forEach((shape) => {
    const shapePath = path.concat(shape.nm || '')
    if (shape.ty === 'fl' || shape.ty === 'st') {
      visit(shape, shapePath)
    }
    if (shape.ty === 'gr') {
      cylVisitShapes(shape.it, shapePath, visit)
    }
  })
}

/**
 * [EN] A deep copy of the animation with the colors applied; the input is never changed. Returns the input itself
 *      when `colors` is empty or not a dictionary.
 * [CN] 返回应用了颜色的动画深拷贝；不会修改输入。`colors` 为空或不是字典时返回输入本身。
 */
function cylApplyLottieColors(animationData, colors) {
  if (!animationData || !colors || typeof colors !== 'object' || Object.keys(colors).length === 0) {
    return animationData
  }
  const rules = Object.keys(colors)
    .map((keypath) => ({
      pattern: keypath.split('.').filter((name, index, list) => !(index === list.length - 1 && name === 'Color')),
      color: cylLottieColor(colors[keypath]),
    }))
    .filter((rule) => rule.color && rule.pattern.length > 0)
  if (rules.length === 0) {
    return animationData
  }
  const copy = JSON.parse(JSON.stringify(animationData))
  const visitLayers = (layers) => {
    (layers || []).forEach((layer) => {
      cylVisitShapes(layer.shapes, [layer.nm || ''], (shape, names) => {
        rules.forEach((rule) => {
          if (cylMatches(rule.pattern, names)) {
            shape.c = {a: 0, k: rule.color.slice()}
          }
        })
      })
    })
  }
  visitLayers(copy.layers)
  ;(copy.assets || []).forEach((asset) => visitLayers(asset.layers))
  return copy
}

module.exports = {cylApplyLottieColors, cylLottieColor, cylMatches}
