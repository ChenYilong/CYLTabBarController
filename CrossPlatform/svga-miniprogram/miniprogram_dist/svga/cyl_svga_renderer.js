/**
 * [EN] Draws one frame of a decoded SVGA movie (cyl_svga_movie.js) on a CanvasRenderingContext2D: the mini program's
 *      <canvas type="2d"> context, or any 2D context. For each sprite: its alpha, transform and clip path, then its
 *      bitmap (drawn in its layout size) or its vector shapes (SVG path, rect, ellipse; fill, stroke, line cap, join,
 *      miter limit and dash). Sprites whose image key ends with ".matte" are masks and are not drawn; masking itself
 *      (matteKey) is not supported yet: the masked sprite is drawn without its mask.
 * [CN] 在 CanvasRenderingContext2D（小程序 <canvas type="2d"> 的上下文，或任意 2D 上下文）上绘制已解码 SVGA 动画
 *      （cyl_svga_movie.js）的一帧。每个 sprite：透明度、变换与裁剪路径，然后绘制其位图（按布局尺寸）或矢量形状（SVG 路径、
 *      矩形、椭圆；填充、描边、线帽、连接、斜接限制与虚线）。图片键以 ".matte" 结尾的 sprite 是遮罩，不绘制；遮罩效果本身
 *      （matteKey）暂不支持：被遮罩的 sprite 不带遮罩绘制。
 */

const CYL_LINE_CAPS = ['butt', 'round', 'square']
const CYL_LINE_JOINS = ['miter', 'round', 'bevel']

function cylRGBA(color) {
  const channel = (value) => Math.round(Math.max(0, Math.min(1, value)) * 255)
  return `rgba(${channel(color.r)}, ${channel(color.g)}, ${channel(color.b)}, ${Math.max(0, Math.min(1, color.a))})`
}

/**
 * [EN] The handlers of the path commands (upper case), on the parser state `p` with the origin (ox, oy) of a relative
 *      command. [CN] 路径命令（大写）的处理函数，作用于解析状态 `p`，(ox, oy) 为相对命令的原点。
 */
const CYL_PATH_COMMANDS = {
  M(p, ox, oy, relative) {
    p.x = ox + p.number()
    p.y = oy + p.number()
    p.startX = p.x
    p.startY = p.y
    p.commands.push(['M', p.x, p.y])
    // [EN] More pairs after M are line-tos. [CN] M 之后的更多坐标对是 lineTo。
    p.command = relative ? 'l' : 'L'
    p.lastType = 'M'
  },
  L(p, ox, oy) {
    p.x = ox + p.number()
    p.y = oy + p.number()
    p.commands.push(['L', p.x, p.y])
    p.lastType = 'L'
  },
  H(p, ox) {
    p.x = ox + p.number()
    p.commands.push(['L', p.x, p.y])
    p.lastType = 'L'
  },
  V(p, ox, oy) {
    p.y = oy + p.number()
    p.commands.push(['L', p.x, p.y])
    p.lastType = 'L'
  },
  C(p, ox, oy) {
    const x1 = ox + p.number(); const y1 = oy + p.number()
    const x2 = ox + p.number(); const y2 = oy + p.number()
    p.x = ox + p.number(); p.y = oy + p.number()
    p.commands.push(['C', x1, y1, x2, y2, p.x, p.y])
    p.lastControlX = x2; p.lastControlY = y2; p.lastType = 'C'
  },
  S(p, ox, oy) {
    const x1 = p.lastType === 'C' ? 2 * p.x - p.lastControlX : p.x
    const y1 = p.lastType === 'C' ? 2 * p.y - p.lastControlY : p.y
    const x2 = ox + p.number(); const y2 = oy + p.number()
    p.x = ox + p.number(); p.y = oy + p.number()
    p.commands.push(['C', x1, y1, x2, y2, p.x, p.y])
    p.lastControlX = x2; p.lastControlY = y2; p.lastType = 'C'
  },
  Q(p, ox, oy) {
    const x1 = ox + p.number(); const y1 = oy + p.number()
    p.x = ox + p.number(); p.y = oy + p.number()
    p.commands.push(['Q', x1, y1, p.x, p.y])
    p.lastControlX = x1; p.lastControlY = y1; p.lastType = 'Q'
  },
  T(p, ox, oy) {
    const x1 = p.lastType === 'Q' ? 2 * p.x - p.lastControlX : p.x
    const y1 = p.lastType === 'Q' ? 2 * p.y - p.lastControlY : p.y
    p.x = ox + p.number(); p.y = oy + p.number()
    p.commands.push(['Q', x1, y1, p.x, p.y])
    p.lastControlX = x1; p.lastControlY = y1; p.lastType = 'Q'
  },
  A(p, ox, oy) {
    p.index += 5
    p.x = ox + p.number()
    p.y = oy + p.number()
    p.commands.push(['L', p.x, p.y])
    p.lastType = 'L'
  },
  Z(p) {
    p.commands.push(['Z'])
    p.x = p.startX
    p.y = p.startY
    p.lastType = 'Z'
    // [EN] Z takes no numbers; a number after it starts an implicit command, which SVG does not allow.
    // [CN] Z 不带数字；其后的数字不合法，跳过。
    while (p.hasNumber()) {
      p.index++
    }
  },
}

/**
 * [EN] Parses an SVG path ("M0 0 L10 10 C … Z") into absolute commands: M, L, C, Q, Z (H, V, S, T, A and the relative
 *      forms are converted; an arc becomes a straight line to its end point).
 * [CN] 把 SVG 路径（"M0 0 L10 10 C … Z"）解析为绝对命令：M、L、C、Q、Z（H、V、S、T、A 与相对形式会被转换；圆弧变为到终点的直线）。
 */
function cylParsePath(d) {
  const tokens = String(d || '').match(/[a-zA-Z]|-?(?:\d+\.?\d*|\.\d+)(?:e[-+]?\d+)?/g) || []
  const p = {
    commands: [], index: 0, command: '', x: 0, y: 0, startX: 0, startY: 0, lastControlX: 0, lastControlY: 0, lastType: '',
  }
  p.number = () => Number.parseFloat(tokens[p.index++])
  p.hasNumber = () => p.index < tokens.length && !/[a-zA-Z]/.test(tokens[p.index])
  while (p.index < tokens.length) {
    if (/[a-zA-Z]/.test(tokens[p.index])) {
      p.command = tokens[p.index++]
    }
    const relative = p.command === p.command.toLowerCase()
    const handler = Object.prototype.hasOwnProperty.call(CYL_PATH_COMMANDS, p.command.toUpperCase()) // NOSONAR: `Object.hasOwn` needs a newer runtime
      ? CYL_PATH_COMMANDS[p.command.toUpperCase()] : null
    if (handler) {
      handler(p, relative ? p.x : 0, relative ? p.y : 0, relative)
    } else {
      p.index++
    }
  }
  return p.commands
}

const cylPathCache = {}

function cylTracePath(context, d) {
  const commands = cylPathCache[d] || (cylPathCache[d] = cylParsePath(d))
  context.beginPath()
  commands.forEach((item) => {
    switch (item[0]) {
      case 'M': context.moveTo(item[1], item[2]); break
      case 'L': context.lineTo(item[1], item[2]); break
      case 'C': context.bezierCurveTo(item[1], item[2], item[3], item[4], item[5], item[6]); break
      case 'Q': context.quadraticCurveTo(item[1], item[2], item[3], item[4]); break
      default: context.closePath()
    }
  })
}

function cylTraceShape(context, shape) {
  if (shape.type === 1 && shape.rect) {
    const { x, y, width, height, cornerRadius } = shape.rect
    const radius = Math.min(cornerRadius || 0, width / 2, height / 2)
    context.beginPath()
    context.moveTo(x + radius, y)
    context.lineTo(x + width - radius, y)
    context.arcTo(x + width, y, x + width, y + radius, radius)
    context.lineTo(x + width, y + height - radius)
    context.arcTo(x + width, y + height, x + width - radius, y + height, radius)
    context.lineTo(x + radius, y + height)
    context.arcTo(x, y + height, x, y + height - radius, radius)
    context.lineTo(x, y + radius)
    context.arcTo(x, y, x + radius, y, radius)
    context.closePath()
    return true
  }
  if (shape.type === 2 && shape.ellipse) {
    const { x, y, radiusX, radiusY } = shape.ellipse
    // [EN] Four cubic curves (kappa 0.5523), so it also works without context.ellipse(). [CN] 四段三次曲线，不依赖 context.ellipse()。
    const k = 0.5522847498
    context.beginPath()
    context.moveTo(x + radiusX, y)
    context.bezierCurveTo(x + radiusX, y + radiusY * k, x + radiusX * k, y + radiusY, x, y + radiusY)
    context.bezierCurveTo(x - radiusX * k, y + radiusY, x - radiusX, y + radiusY * k, x - radiusX, y)
    context.bezierCurveTo(x - radiusX, y - radiusY * k, x - radiusX * k, y - radiusY, x, y - radiusY)
    context.bezierCurveTo(x + radiusX * k, y - radiusY, x + radiusX, y - radiusY * k, x + radiusX, y)
    context.closePath()
    return true
  }
  if (shape.type === 0 && shape.d) {
    cylTracePath(context, shape.d)
    return true
  }
  return false
}

/** [EN] Strokes the traced shape with its style. [CN] 按样式描边已绘制路径的形状。 */
function cylStrokeShape(context, style) {
  context.strokeStyle = cylRGBA(style.stroke)
  context.lineWidth = style.strokeWidth
  context.lineCap = CYL_LINE_CAPS[style.lineCap] || 'butt'
  context.lineJoin = CYL_LINE_JOINS[style.lineJoin] || 'miter'
  if (style.miterLimit > 0) {
    context.miterLimit = style.miterLimit
  }
  if (typeof context.setLineDash === 'function') {
    const dash = style.lineDash[0] > 0 || style.lineDash[1] > 0 ? [style.lineDash[0], style.lineDash[1]] : []
    context.setLineDash(dash)
    context.lineDashOffset = style.lineDash[2] || 0
  }
  context.stroke()
}

function cylDrawShape(context, shape) {
  context.save()
  const t = shape.transform
  if (t) {
    context.transform(t.a, t.b, t.c, t.d, t.tx, t.ty)
  }
  if (cylTraceShape(context, shape) && shape.styles) {
    const style = shape.styles
    if (style.fill && style.fill.a > 0) {
      context.fillStyle = cylRGBA(style.fill)
      context.fill()
    }
    if (style.stroke && style.stroke.a > 0 && style.strokeWidth > 0) {
      cylStrokeShape(context, style)
    }
  }
  context.restore()
}

/**
 * [EN] The transform that fits the movie's view box into a box of `width` × `height` (contain, cover or fill).
 * [CN] 把动画的 viewBox 放入 `width` × `height` 区域的变换（contain、cover 或 fill）。
 */
function cylFitTransform(movie, width, height, fit) {
  const boxWidth = movie.viewBoxWidth || width
  const boxHeight = movie.viewBoxHeight || height
  let scaleX = width / boxWidth
  let scaleY = height / boxHeight
  if (fit !== 'fill') {
    const scale = fit === 'cover' ? Math.max(scaleX, scaleY) : Math.min(scaleX, scaleY)
    scaleX = scale
    scaleY = scale
  }
  return { a: scaleX, b: 0, c: 0, d: scaleY, tx: (width - boxWidth * scaleX) / 2, ty: (height - boxHeight * scaleY) / 2 }
}

/**
 * [EN] Clears the canvas area and draws frame `frameIndex` (clamped) with `bitmaps` ({imageKey: drawable image}).
 *      Returns the number of sprites drawn.
 * [CN] 清空画布区域并用 `bitmaps`（{imageKey: 可绘制的图片}）绘制第 `frameIndex` 帧（自动限制范围）。返回绘制的 sprite 数。
 */
function cylDrawSVGAFrame(context, movie, bitmaps, frameIndex, width, height, fit) {
  const base = cylFitTransform(movie, width, height, fit)
  const last = Math.max(0, movie.frames - 1)
  const index = Math.max(0, Math.min(last, Math.floor(frameIndex)))
  context.setTransform(1, 0, 0, 1, 0, 0)
  context.clearRect(0, 0, width, height)
  let drawn = 0
  movie.sprites.forEach((sprite) => {
    if (String(sprite.imageKey).endsWith('.matte')) {
      return
    }
    const frame = sprite.frames[index]
    if (!frame || !(frame.alpha > 0)) { // NOSONAR: NaN / undefined alpha is invisible, unlike `<= 0`
      return
    }
    context.save()
    context.setTransform(base.a, base.b, base.c, base.d, base.tx, base.ty)
    context.globalAlpha = frame.alpha
    const t = frame.transform
    if (t) {
      context.transform(t.a, t.b, t.c, t.d, t.tx, t.ty)
    }
    if (frame.clipPath) {
      cylTracePath(context, frame.clipPath)
      context.clip()
    }
    const bitmap = bitmaps[sprite.imageKey]
    if (bitmap && frame.layout) {
      context.drawImage(bitmap, 0, 0, frame.layout.width, frame.layout.height)
    }
    frame.shapes.forEach((shape) => cylDrawShape(context, shape))
    context.restore()
    drawn += 1
  })
  return drawn
}

module.exports = { cylDrawSVGAFrame, cylParsePath, cylFitTransform }
