/**
 * [EN] The engine side of one-color detection: reads the file (Lottie JSON text from a rawfile or inline; a GIF's first frame decoded by ImageKit)
 *      and hands the data to the pure functions of `CYLAnimatedItemColorCount.ts` (the same algorithm and fixtures as every platform). PAG, SVGA,
 *      Rive and unreadable files are 'unknown' (the original colors stay).
 * [CN] 单色检测的引擎侧：读取文件（rawfile 或内联的 Lottie JSON 文本；由 ImageKit 解码的 GIF 首帧），把数据交给 `CYLAnimatedItemColorCount.ts` 中的纯函数
 *      （算法与夹具与各平台相同）。PAG、SVGA、Rive 与无法读取的文件为 'unknown'（保持原色）。
 */
import { image } from '@kit.ImageKit';
import { buffer } from '@kit.ArkTS';
import { common } from '@kit.AbilityKit';
import { CYLAnimatedItemSource } from './CYLAnimatedItemSource';
import {
  CYL_COLOR_COUNT_UNKNOWN, cylAnimatedItemColorDetectable, cylAnimatedItemGifColorKind, cylAnimatedItemLottieColorKind
} from './CYLAnimatedItemColorCount';

/**
 * [EN] 'oneColor' | 'multiColor' | 'unknown' for an animation source; never rejects. Run once per file (the caller caches).
 * [CN] 动画来源的检测结果；从不 reject。每个文件只运行一次（调用方缓存）。
 */
export async function cylAnimatedItemDetectColorKind(source: CYLAnimatedItemSource, context: common.Context | undefined): Promise<string> {
  try {
    if (source.inlineJSON !== undefined) {
      return cylAnimatedItemLottieColorKind(source.inlineJSON);
    }
    if (!cylAnimatedItemColorDetectable(source.type) || context === undefined) {
      return CYL_COLOR_COUNT_UNKNOWN;
    }
    const bytes: Uint8Array | undefined = source.rawFileContent(context.resourceManager);
    if (bytes === undefined) {
      return CYL_COLOR_COUNT_UNKNOWN;
    }
    if (source.type === 'Lottie') {
      return cylAnimatedItemLottieColorKind(buffer.from(bytes.buffer, bytes.byteOffset, bytes.byteLength).toString('utf8'));
    }
    return await cylFirstFrameKind(bytes);
  } catch (e) {
    return CYL_COLOR_COUNT_UNKNOWN;
  }
}

/** [EN] The longer side, in px, a static image is scanned at (as Android). [CN] 扫描静态图片时长边的像素数（与 Android 相同）。 */
const CYL_STATIC_IMAGE_SCAN_SIZE: number = 48;

/**
 * [EN] 'oneColor' | 'multiColor' | 'unknown' for a static image resource (`$r` media, SVG included, or `$rawfile`); never rejects. A path or URL
 *      string is not detected ('unknown': the original colors stay).
 * [CN] 静态图片资源（`$r` 媒体资源，包括 SVG，或 `$rawfile`）的检测结果；从不 reject。路径或 URL 字符串不检测（'unknown'：保持原色）。
 */
export async function cylAnimatedItemDetectImageColorKind(resource: Resource, context: common.Context | undefined): Promise<string> {
  try {
    if (context === undefined) {
      return CYL_COLOR_COUNT_UNKNOWN;
    }
    const name: Object | undefined = resource.id === -1 || resource.params === undefined ? undefined : resource.params[0] as Object;
    const bytes: Uint8Array = resource.type === CYL_RAWFILE_RESOURCE_TYPE ?
      await context.resourceManager.getRawFileContent(name as string) : await context.resourceManager.getMediaContent(resource.id);
    return await cylFirstFrameKind(bytes, CYL_STATIC_IMAGE_SCAN_SIZE);
  } catch (e) {
    return CYL_COLOR_COUNT_UNKNOWN;
  }
}

/** [EN] The `type` of a `$rawfile(...)` resource. [CN] `$rawfile(...)` 资源的 `type`。 */
const CYL_RAWFILE_RESOURCE_TYPE: number = 30000;

/** [EN] The first frame as RGBA bytes (scaled to at most `maxSide` px when given), through the pure detector. [CN] 首帧的 RGBA 字节（给出 `maxSide` 时缩放到长边最多该像素数），交给纯检测函数。 */
async function cylFirstFrameKind(bytes: Uint8Array, maxSide?: number): Promise<string> {
  const data = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
  const imageSource: image.ImageSource = image.createImageSource(data);
  try {
    const options: image.DecodingOptions = { desiredPixelFormat: image.PixelMapFormat.RGBA_8888, index: 0 };
    if (maxSide !== undefined) {
      const size: image.Size = (await imageSource.getImageInfo()).size;
      const scale: number = Math.min(1, maxSide / Math.max(size.width, size.height, 1));
      options.desiredSize = { width: Math.max(1, Math.round(size.width * scale)), height: Math.max(1, Math.round(size.height * scale)) };
    }
    const pixelMap: image.PixelMap = await imageSource.createPixelMap(options);
    try {
      const info: image.ImageInfo = await pixelMap.getImageInfo();
      const pixels: ArrayBuffer = new ArrayBuffer(pixelMap.getPixelBytesNumber());
      await pixelMap.readPixelsToBuffer(pixels);
      // [EN] Decoded colors are premultiplied unless the map says UNPREMUL. [CN] 解码得到的颜色已预乘 alpha，除非 PixelMap 标明 UNPREMUL。
      return cylAnimatedItemGifColorKind(new Uint8Array(pixels), info.alphaType !== image.AlphaType.UNPREMUL);
    } finally {
      pixelMap.release();
    }
  } finally {
    imageSource.release();
  }
}
