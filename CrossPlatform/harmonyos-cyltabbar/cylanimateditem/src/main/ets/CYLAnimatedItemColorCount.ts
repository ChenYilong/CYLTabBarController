/**
 * [EN] One-color detection of an animation file (tint spec v2, section 5): a PURE function over the file data, the same algorithm and the
 *      same fixtures on every platform. `'oneColor'` = the file may be tinted by `animationRenderingMode` automatic, `'multiColor'` and
 *      `'unknown'` (not detectable, parse failure, nothing to see) keep the original colors. Unit tested with Node
 *      (test/CYLAnimatedItemColorCount.test.mjs). No ArkUI import: the engine side only supplies the text / the decoded pixels
 *      (`CYLAnimatedItemColorCountLoader.ets`).
 * [CN] 动画文件的单色检测（着色规范 v2 第 5 节）：对文件数据的纯函数，各平台算法与夹具相同。`'oneColor'` = `animationRenderingMode` 为 automatic
 *      时可以着色；`'multiColor'` 与 `'unknown'`（无法检测、解析失败、无内容）保持原色。用 Node 做单元测试。
 */

/** [EN] The file is one color. [CN] 单色。 */
export const CYL_COLOR_COUNT_ONE: string = 'oneColor';
/** [EN] The file has several colors (or a gradient / an image). [CN] 多色（或含渐变 / 图片）。 */
export const CYL_COLOR_COUNT_MULTI: string = 'multiColor';
/** [EN] Not detectable. [CN] 无法检测。 */
export const CYL_COLOR_COUNT_UNKNOWN: string = 'unknown';

/** [EN] Two Lottie colors within this many 1/255 steps per channel are the same color. [CN] 每通道相差不超过此值（1/255）的两个颜色视为同色。 */
export const CYL_COLOR_COUNT_TOLERANCE: number = 2;
/** [EN] GIF: pixels with alpha below this (0...1) are ignored. [CN] GIF：透明度低于此值（0...1）的像素被忽略。 */
export const CYL_GIF_COLOR_MIN_ALPHA: number = 0.1;
/** [EN] GIF: the share of the visible pixels one 4-bit bucket needs. [CN] GIF：单个 4 位桶需要占据的可见像素比例。 */
export const CYL_GIF_COLOR_DOMINANT_SHARE: number = 0.98;

/** [EN] A color's channels as 0...255, from a Lottie color array (0...1; an array with a channel above 1 is read as 0...255). [CN] Lottie 颜色数组转 0...255。 */
function lottieColor(values: number[]): number[] | undefined {
  if (values.length < 3) {
    return undefined;
  }
  for (let i = 0; i < Math.min(values.length, 4); i++) {
    if (typeof values[i] !== 'number' || !Number.isFinite(values[i])) {
      return undefined;
    }
  }
  if (values.length >= 4 && values[3] === 0) {
    return undefined; // [EN] fully transparent: ignored. [CN] 完全透明：忽略。
  }
  const scale = Math.max(values[0], values[1], values[2]) > 1 ? 1 : 255;
  return [Math.round(values[0] * scale), Math.round(values[1] * scale), Math.round(values[2] * scale)];
}

/** [EN] The colors one animatable color property holds: its static value or every keyframe's start and end. [CN] 一个可动画颜色属性的所有颜色：静态值或每个关键帧的起止值。 */
function propertyColors(property: object | undefined, into: number[][]): void {
  if (property === undefined || property === null) {
    return;
  }
  const k: object | undefined = (property as Record<string, Object>)['k'];
  if (!Array.isArray(k) || k.length === 0) {
    return;
  }
  if (typeof k[0] === 'number') {
    const c = lottieColor(k as number[]);
    if (c !== undefined) {
      into.push(c);
    }
    return;
  }
  for (const keyframe of k as object[]) {
    for (const key of ['s', 'e']) {
      const value: Object | undefined = (keyframe as Record<string, Object>)[key];
      if (Array.isArray(value)) {
        const c = lottieColor(value as number[]);
        if (c !== undefined) {
          into.push(c);
        }
      }
    }
  }
}

class LottieScan {
  colors: number[][] = [];
  multi: boolean = false;
}

function scanLottie(node: object | undefined, scan: LottieScan): void {
  if (scan.multi || node === undefined || node === null || typeof node !== 'object') {
    return;
  }
  if (Array.isArray(node)) {
    for (const child of node as object[]) {
      scanLottie(child, scan);
    }
    return;
  }
  const record = node as Record<string, Object>;
  const ty: Object = record['ty'];
  if (ty === 'gf' || ty === 'gs') {
    scan.multi = true; // [EN] gradient. [CN] 渐变。
    return;
  }
  if (ty === 'fl' || ty === 'st') {
    propertyColors(record['c'], scan.colors);
  }
  // [EN] A layer of type 2 is an image layer. [CN] 类型 2 的图层是图片图层。
  if (ty === 2 && typeof record['refId'] === 'string') {
    scan.multi = true;
    return;
  }
  for (const key of Object.keys(record)) {
    const child: Object = record[key];
    if (child !== null && typeof child === 'object') {
      scanLottie(child, scan);
    }
  }
}

/** [EN] Whether two colors are the same within the tolerance. [CN] 两个颜色在容差内是否相同。 */
function sameColor(a: number[], b: number[]): boolean {
  return Math.abs(a[0] - b[0]) <= CYL_COLOR_COUNT_TOLERANCE && Math.abs(a[1] - b[1]) <= CYL_COLOR_COUNT_TOLERANCE &&
    Math.abs(a[2] - b[2]) <= CYL_COLOR_COUNT_TOLERANCE;
}

/**
 * [EN] The distinct colors of a Lottie JSON text (fill `fl` and stroke `st` colors, static and every keyframe value; alpha ignored, fully
 *      transparent colors skipped, colors within +-2/255 per channel merged); -1 when the file is multi-color by kind (a gradient `gf` / `gs`,
 *      an image asset with `p`, an image layer ty 2); undefined when the text does not parse.
 * [CN] Lottie JSON 文本中不同颜色的数量（填充 `fl` 与描边 `st` 的静态值及每个关键帧值；忽略 alpha，跳过完全透明，每通道相差 +-2/255 内合并）；按类型即为多色
 *      （渐变 `gf` / `gs`、带 `p` 的图片资源、ty 2 图片图层）时为 -1；文本无法解析时为 undefined。
 */
export function cylAnimatedItemLottieColorCount(json: string): number | undefined {
  let root: object;
  try {
    root = JSON.parse(json) as object;
  } catch (e) {
    return undefined;
  }
  if (root === null || typeof root !== 'object') {
    return undefined;
  }
  const assets: object[] | undefined = (root as Record<string, object[]>)['assets'];
  if (Array.isArray(assets)) {
    for (const asset of assets) {
      const p: Object = (asset as Record<string, Object>)['p'];
      if (typeof p === 'string' && p.length > 0) {
        return -1;
      }
    }
  }
  const scan = new LottieScan();
  scanLottie(root, scan);
  if (scan.multi) {
    return -1;
  }
  const distinct: number[][] = [];
  for (const color of scan.colors) {
    if (!distinct.some((d: number[]) => sameColor(d, color))) {
      distinct.push(color);
    }
  }
  return distinct.length;
}

/** [EN] One-color detection of Lottie JSON text. [CN] Lottie JSON 文本的单色检测。 */
export function cylAnimatedItemLottieColorKind(json: string): string {
  const count = cylAnimatedItemLottieColorCount(json);
  if (count === undefined || count === 0) {
    return CYL_COLOR_COUNT_UNKNOWN;
  }
  return count === 1 ? CYL_COLOR_COUNT_ONE : CYL_COLOR_COUNT_MULTI;
}

/**
 * [EN] One-color detection of a GIF's first frame, over its decoded RGBA bytes (4 per pixel: R, G, B, A). `premultiplied` true when the colors
 *      are premultiplied by alpha (ImageKit's usual PixelMap): they are un-premultiplied first. Pixels with alpha < 0.1 are ignored; the rest are
 *      quantized to 4 bits per channel; one bucket with >= 98 % of them = one color. No visible pixel: unknown.
 * [CN] GIF 首帧的单色检测，输入为解码后的 RGBA 字节（每像素 4 个：R、G、B、A）。颜色已按 alpha 预乘（ImageKit 常见的 PixelMap）时 `premultiplied` 为 true：先还原。
 *      忽略 alpha < 0.1 的像素；其余量化为每通道 4 位；单个桶占 >= 98 % 即为单色。没有可见像素：unknown。
 */
export function cylAnimatedItemGifColorKind(rgba: ArrayLike<number>, premultiplied: boolean): string {
  const buckets: Map<number, number> = new Map<number, number>();
  let visible = 0;
  const minAlpha = CYL_GIF_COLOR_MIN_ALPHA * 255;
  for (let i = 0; i + 3 < rgba.length; i += 4) {
    const a = rgba[i + 3];
    if (a < minAlpha) {
      continue;
    }
    let r = rgba[i];
    let g = rgba[i + 1];
    let b = rgba[i + 2];
    if (premultiplied && a < 255) {
      r = Math.min(255, Math.round(r * 255 / a));
      g = Math.min(255, Math.round(g * 255 / a));
      b = Math.min(255, Math.round(b * 255 / a));
    }
    const key = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4);
    buckets.set(key, (buckets.get(key) ?? 0) + 1);
    visible += 1;
  }
  if (visible === 0) {
    return CYL_COLOR_COUNT_UNKNOWN;
  }
  let most = 0;
  buckets.forEach((count: number) => {
    most = Math.max(most, count);
  });
  return most >= CYL_GIF_COLOR_DOMINANT_SHARE * visible ? CYL_COLOR_COUNT_ONE : CYL_COLOR_COUNT_MULTI;
}

/**
 * [EN] Whether a static image is drawn in the icon color when no explicit icon color is set (the rendering mode, as for an animation and as Android's
 *      `staticImageRenderingColor`): alwaysTemplate yes, alwaysOriginal no, automatic only when the image is detected as 'oneColor'.
 * [CN] 没有显式图标颜色时静态图片是否用图标颜色绘制（按渲染模式，与动画及 Android 的 `staticImageRenderingColor` 相同）：alwaysTemplate 是，
 *      alwaysOriginal 否，automatic 仅当图片检测为 'oneColor' 时。
 */
export function cylAnimatedItemStaticImageTints(renderingMode: string, colorKind: string): boolean {
  if (renderingMode === 'alwaysOriginal') {
    return false;
  }
  return renderingMode === 'alwaysTemplate' || colorKind === CYL_COLOR_COUNT_ONE;
}

/**
 * [EN] Whether the type of a file can be detected: Lottie (JSON text), GIF (first frame pixels); PAG, SVGA, Rive and anything else are 'unknown'.
 * [CN] 该类型的文件能否检测：Lottie（JSON 文本）、GIF（首帧像素）；PAG、SVGA、Rive 与其他均为 'unknown'。
 */
export function cylAnimatedItemColorDetectable(type: string): boolean {
  return type === 'Lottie' || type === 'GIF';
}

/**
 * [EN] The detection cache, per animation file (the URL without its options): detection runs once per file.
 * [CN] 检测缓存，按动画文件（不含选项的 URL）：每个文件只检测一次。
 */
export class CYLAnimatedItemColorCountCache {
  private readonly kinds: Map<string, string> = new Map<string, string>();

  get(key: string): string | undefined {
    return this.kinds.get(key);
  }

  set(key: string, kind: string): void {
    this.kinds.set(key, kind);
  }

  clear(): void {
    this.kinds.clear();
  }
}

/** [EN] The shared cache. [CN] 共享缓存。 */
export const CYL_ANIMATED_ITEM_COLOR_COUNT_CACHE: CYLAnimatedItemColorCountCache = new CYLAnimatedItemColorCountCache();
