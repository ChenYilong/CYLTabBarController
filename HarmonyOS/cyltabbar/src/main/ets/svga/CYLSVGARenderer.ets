import { image } from '@kit.ImageKit';
import { CYLSVGAColor, CYLSVGAFrame, CYLSVGAMovie, CYLSVGAShape, CYLSVGASprite } from './CYLSVGAMovie';

/**
 * [EN] FIX: issue #415. Draws one frame of an SVGA movie on an ArkUI CanvasRenderingContext2D, the same way as the WeChat
 *      mini program renderer (cyl_svga_renderer.js): per sprite its alpha, transform and clip path, then its bitmap (in
 *      its layout size) or its vector shapes. ".matte" sprites are masks and are not drawn; masking itself is not
 *      supported yet.
 * [CN] FIX: issue #415。在 ArkUI 的 CanvasRenderingContext2D 上绘制 SVGA 动画的一帧，方式与微信小程序的渲染器
 *      （cyl_svga_renderer.js）相同：每个 sprite 先设置透明度、变换与裁剪路径，再绘制其位图（按布局尺寸）或矢量形状。".matte"
 *      sprite 是遮罩，不绘制；遮罩效果暂不支持。
 */
class CYLPathCommand {
  name: string = 'Z';
  values: number[] = [];

  constructor(name: string, values: number[]) {
    this.name = name;
    this.values = values;
  }
}

const CYL_LINE_CAPS: CanvasLineCap[] = ['butt', 'round', 'square'];
const CYL_LINE_JOINS: CanvasLineJoin[] = ['miter', 'round', 'bevel'];

function cylClamp(value: number): number {
  return Math.max(0, Math.min(1, value));
}

function cylRGBA(color: CYLSVGAColor): string {
  return `rgba(${Math.round(cylClamp(color.r) * 255)}, ${Math.round(cylClamp(color.g) * 255)}, ${Math.round(cylClamp(color.b) * 255)}, ${cylClamp(color.a)})`;
}

function cylIsCommand(token: string): boolean {
  return /^[a-zA-Z]$/.test(token);
}

/**
 * [EN] Parses an SVG path into absolute M, L, C, Q and Z commands (H, V, S, T and relative forms converted; an arc
 *      becomes a line to its end point).
 * [CN] 把 SVG 路径解析为绝对的 M、L、C、Q、Z 命令（H、V、S、T 与相对形式会被转换；圆弧变为到终点的直线）。
 */
export function cylParseSVGAPath(d: string): CYLPathCommand[] {
  const tokens: string[] = d.match(/[a-zA-Z]|-?(?:\d+\.?\d*|\.\d+)(?:e[-+]?\d+)?/g) ?? [];
  const commands: CYLPathCommand[] = [];
  let index = 0;
  let command = '';
  let x = 0;
  let y = 0;
  let startX = 0;
  let startY = 0;
  let controlX = 0;
  let controlY = 0;
  let lastType = '';
  const next = (): number => {
    const value = parseFloat(tokens[index]);
    index += 1;
    return value;
  };
  while (index < tokens.length) {
    if (cylIsCommand(tokens[index])) {
      command = tokens[index];
      index += 1;
    }
    const relative = command === command.toLowerCase();
    const ox = relative ? x : 0;
    const oy = relative ? y : 0;
    const upper = command.toUpperCase();
    if (upper === 'M') {
      x = ox + next();
      y = oy + next();
      startX = x;
      startY = y;
      commands.push(new CYLPathCommand('M', [x, y]));
      command = relative ? 'l' : 'L';
      lastType = 'M';
    } else if (upper === 'L' || upper === 'H' || upper === 'V') {
      if (upper !== 'V') {
        x = ox + next();
      }
      if (upper !== 'H') {
        y = oy + next();
      }
      commands.push(new CYLPathCommand('L', [x, y]));
      lastType = 'L';
    } else if (upper === 'C' || upper === 'S') {
      let x1 = lastType === 'C' ? 2 * x - controlX : x;
      let y1 = lastType === 'C' ? 2 * y - controlY : y;
      if (upper === 'C') {
        x1 = ox + next();
        y1 = oy + next();
      }
      const x2 = ox + next();
      const y2 = oy + next();
      x = ox + next();
      y = oy + next();
      commands.push(new CYLPathCommand('C', [x1, y1, x2, y2, x, y]));
      controlX = x2;
      controlY = y2;
      lastType = 'C';
    } else if (upper === 'Q' || upper === 'T') {
      let x1 = lastType === 'Q' ? 2 * x - controlX : x;
      let y1 = lastType === 'Q' ? 2 * y - controlY : y;
      if (upper === 'Q') {
        x1 = ox + next();
        y1 = oy + next();
      }
      x = ox + next();
      y = oy + next();
      commands.push(new CYLPathCommand('Q', [x1, y1, x, y]));
      controlX = x1;
      controlY = y1;
      lastType = 'Q';
    } else if (upper === 'A') {
      index += 5;
      x = ox + next();
      y = oy + next();
      commands.push(new CYLPathCommand('L', [x, y]));
      lastType = 'L';
    } else if (upper === 'Z') {
      commands.push(new CYLPathCommand('Z', []));
      x = startX;
      y = startY;
      lastType = 'Z';
      while (index < tokens.length && !cylIsCommand(tokens[index])) {
        index += 1;
      }
    } else {
      index += 1;
    }
  }
  return commands;
}

const cylPathCache: Map<string, CYLPathCommand[]> = new Map<string, CYLPathCommand[]>();

function cylTracePath(context: CanvasRenderingContext2D, d: string): void {
  let commands = cylPathCache.get(d);
  if (commands === undefined) {
    commands = cylParseSVGAPath(d);
    cylPathCache.set(d, commands);
  }
  context.beginPath();
  commands.forEach((item: CYLPathCommand) => {
    const v = item.values;
    if (item.name === 'M') {
      context.moveTo(v[0], v[1]);
    } else if (item.name === 'L') {
      context.lineTo(v[0], v[1]);
    } else if (item.name === 'C') {
      context.bezierCurveTo(v[0], v[1], v[2], v[3], v[4], v[5]);
    } else if (item.name === 'Q') {
      context.quadraticCurveTo(v[0], v[1], v[2], v[3]);
    } else {
      context.closePath();
    }
  });
}

function cylTraceShape(context: CanvasRenderingContext2D, shape: CYLSVGAShape): boolean {
  if (shape.type === 1 && shape.rect !== undefined) {
    const r = shape.rect;
    const radius = Math.min(r.cornerRadius, r.width / 2, r.height / 2);
    context.beginPath();
    context.moveTo(r.x + radius, r.y);
    context.lineTo(r.x + r.width - radius, r.y);
    context.arcTo(r.x + r.width, r.y, r.x + r.width, r.y + radius, radius);
    context.lineTo(r.x + r.width, r.y + r.height - radius);
    context.arcTo(r.x + r.width, r.y + r.height, r.x + r.width - radius, r.y + r.height, radius);
    context.lineTo(r.x + radius, r.y + r.height);
    context.arcTo(r.x, r.y + r.height, r.x, r.y + r.height - radius, radius);
    context.lineTo(r.x, r.y + radius);
    context.arcTo(r.x, r.y, r.x + radius, r.y, radius);
    context.closePath();
    return true;
  }
  if (shape.type === 2 && shape.ellipse !== undefined) {
    const e = shape.ellipse;
    const k = 0.5522847498;
    context.beginPath();
    context.moveTo(e.x + e.radiusX, e.y);
    context.bezierCurveTo(e.x + e.radiusX, e.y + e.radiusY * k, e.x + e.radiusX * k, e.y + e.radiusY, e.x, e.y + e.radiusY);
    context.bezierCurveTo(e.x - e.radiusX * k, e.y + e.radiusY, e.x - e.radiusX, e.y + e.radiusY * k, e.x - e.radiusX, e.y);
    context.bezierCurveTo(e.x - e.radiusX, e.y - e.radiusY * k, e.x - e.radiusX * k, e.y - e.radiusY, e.x, e.y - e.radiusY);
    context.bezierCurveTo(e.x + e.radiusX * k, e.y - e.radiusY, e.x + e.radiusX, e.y - e.radiusY * k, e.x + e.radiusX, e.y);
    context.closePath();
    return true;
  }
  if (shape.type === 0 && shape.d.length > 0) {
    cylTracePath(context, shape.d);
    return true;
  }
  return false;
}

function cylDrawShape(context: CanvasRenderingContext2D, shape: CYLSVGAShape): void {
  context.save();
  const t = shape.transform;
  if (t !== undefined) {
    context.transform(t.a, t.b, t.c, t.d, t.tx, t.ty);
  }
  const style = shape.styles;
  if (cylTraceShape(context, shape) && style !== undefined) {
    if (style.fill !== undefined && style.fill.a > 0) {
      context.fillStyle = cylRGBA(style.fill);
      context.fill();
    }
    if (style.stroke !== undefined && style.stroke.a > 0 && style.strokeWidth > 0) {
      context.strokeStyle = cylRGBA(style.stroke);
      context.lineWidth = style.strokeWidth;
      context.lineCap = CYL_LINE_CAPS[style.lineCap] ?? 'butt';
      context.lineJoin = CYL_LINE_JOINS[style.lineJoin] ?? 'miter';
      if (style.miterLimit > 0) {
        context.miterLimit = style.miterLimit;
      }
      const dashed = style.lineDash[0] > 0 || style.lineDash[1] > 0;
      context.setLineDash(dashed ? [style.lineDash[0], style.lineDash[1]] : []);
      context.lineDashOffset = style.lineDash[2];
      context.stroke();
    }
  }
  context.restore();
}

/**
 * [EN] Clears the canvas area and draws frame `frameIndex` (clamped), the view box fitted (contain) into `width` × `height`.
 * [CN] 清空画布区域并绘制第 `frameIndex` 帧（自动限制范围），viewBox 等比（contain）放入 `width` × `height`。
 */
export function cylDrawSVGAFrame(context: CanvasRenderingContext2D, movie: CYLSVGAMovie, bitmaps: Map<string, image.PixelMap>,
  frameIndex: number, width: number, height: number): void {
  const boxWidth = movie.viewBoxWidth > 0 ? movie.viewBoxWidth : width;
  const boxHeight = movie.viewBoxHeight > 0 ? movie.viewBoxHeight : height;
  const scale = Math.min(width / boxWidth, height / boxHeight);
  const offsetX = (width - boxWidth * scale) / 2;
  const offsetY = (height - boxHeight * scale) / 2;
  const index = Math.max(0, Math.min(Math.max(0, movie.frames - 1), Math.floor(frameIndex)));
  context.setTransform(1, 0, 0, 1, 0, 0);
  context.clearRect(0, 0, width, height);
  movie.sprites.forEach((sprite: CYLSVGASprite) => {
    if (/\.matte$/.test(sprite.imageKey)) {
      return;
    }
    const frame: CYLSVGAFrame | undefined = sprite.frames[index];
    if (frame === undefined || !(frame.alpha > 0)) {
      return;
    }
    context.save();
    context.setTransform(scale, 0, 0, scale, offsetX, offsetY);
    context.globalAlpha = frame.alpha;
    const t = frame.transform;
    if (t !== undefined) {
      context.transform(t.a, t.b, t.c, t.d, t.tx, t.ty);
    }
    if (frame.clipPath.length > 0) {
      cylTracePath(context, frame.clipPath);
      context.clip();
    }
    const bitmap = bitmaps.get(sprite.imageKey);
    if (bitmap !== undefined && frame.layout !== undefined) {
      context.drawImage(bitmap, 0, 0, frame.layout.width, frame.layout.height);
    }
    frame.shapes.forEach((shape: CYLSVGAShape) => cylDrawShape(context, shape));
    context.restore();
  });
}
