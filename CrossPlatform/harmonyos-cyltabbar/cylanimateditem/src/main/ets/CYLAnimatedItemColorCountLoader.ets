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

/** [EN] The GIF's first frame as RGBA bytes, through the pure detector. [CN] GIF 首帧的 RGBA 字节，交给纯检测函数。 */
async function cylFirstFrameKind(bytes: Uint8Array): Promise<string> {
  const data = bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength) as ArrayBuffer;
  const imageSource: image.ImageSource = image.createImageSource(data);
  try {
    const options: image.DecodingOptions = { desiredPixelFormat: image.PixelMapFormat.RGBA_8888, index: 0 };
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
