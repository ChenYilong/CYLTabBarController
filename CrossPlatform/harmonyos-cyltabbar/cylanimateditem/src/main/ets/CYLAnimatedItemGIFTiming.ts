/**
 * [EN] GIF frame timing (pure, unit tested with Node): each frame's delay (10 ms or less: 100 ms, as browsers do and as the
 *      iOS and Android GIF engines of CYLAnimatedItem do) and the frame shown at a progress.
 * [CN] GIF 帧时间（纯逻辑，用 Node 做单元测试）：每帧的延时（10 毫秒或更小为 100 毫秒，与浏览器以及 iOS、Android 的 CYLAnimatedItem GIF 引擎相同）
 *      以及某进度显示的帧。
 */
export const CYL_GIF_DEFAULT_DELAY_MS: number = 100;
/**
 * [EN] The longest declared delay still replaced by the default: browsers show 0-10 ms frames for 100 ms (iOS
 *      CYLGIFTabBarItemAnimationView: under 11 ms; Android CYLGIFDecoder: 10 ms or less), so a GIF made for browsers does
 *      not race. [CN] 仍按默认值处理的最长声明延时：浏览器把 0-10 毫秒的帧显示 100 毫秒（iOS：小于 11 毫秒；Android：10 毫秒或更小），
 *      为浏览器制作的 GIF 因此不会播得过快。
 */
export const CYL_GIF_MIN_DELAY_MS: number = 10;

/** [EN] The delays of `count` frames from the decoder's list. [CN] 由解码器列表得到 `count` 帧的延时。 */
export function cylGIFDelays(count: number, delays: number[]): number[] {
  const result: number[] = [];
  for (let i = 0; i < count; i++) {
    const delay = i < delays.length ? delays[i] : CYL_GIF_DEFAULT_DELAY_MS;
    result.push(delay > CYL_GIF_MIN_DELAY_MS ? delay : CYL_GIF_DEFAULT_DELAY_MS);
  }
  return result;
}

/** [EN] The total of `delays`. [CN] `delays` 之和。 */
export function cylGIFDuration(delays: number[]): number {
  return delays.reduce((sum: number, delay: number) => sum + delay, 0);
}

/** [EN] The frame shown at `progress` (1: the last frame; -1 without frames). [CN] `progress` 处显示的帧（1 为最后一帧；没有帧时为 -1）。 */
export function cylGIFFrameIndex(delays: number[], progress: number): number {
  if (delays.length === 0) {
    return -1;
  }
  if (progress >= 1) {
    return delays.length - 1;
  }
  let t = Math.max(0, progress) * cylGIFDuration(delays);
  for (let i = 0; i < delays.length; i++) {
    if (t < delays[i]) {
      return i;
    }
    t -= delays[i];
  }
  return delays.length - 1;
}

/**
 * [EN] The GIF trailer byte. A file that does not end with it was cut short: ImageKit decodes its last frame only partly
 *      (CYLTableViewPlaceHolder 3fe1896d: a truncated GIF rested on a fragment of its second frame).
 * [CN] GIF 结尾字节。不以它结尾的文件被截断了：ImageKit 只解码出其最后一帧的一部分（CYLTableViewPlaceHolder 3fe1896d：截断的 GIF 停在第二帧的残片上）。
 */
export const CYL_GIF_TRAILER: number = 0x3B;

/** [EN] Whether `bytes` end with the GIF trailer. [CN] `bytes` 是否以 GIF 结尾字节结束。 */
export function cylGIFHasTrailer(bytes: Uint8Array): boolean {
  return bytes.length > 0 && bytes[bytes.length - 1] === CYL_GIF_TRAILER;
}

/**
 * [EN] How many of `decoded` frames to show: a file without its trailer drops its incomplete last frame (one frame stays).
 * [CN] `decoded` 帧中要显示的帧数：没有结尾字节的文件丢弃其不完整的最后一帧（至少保留一帧）。
 */
export function cylGIFUsableFrameCount(decoded: number, hasTrailer: boolean): number {
  return decoded > 1 && !hasTrailer ? decoded - 1 : decoded;
}

/**
 * [EN] The cache file name of a GIF handed to ArkUI's Image when ImageKit cannot decode it: stable for a URL and a size.
 * [CN] ImageKit 无法解码时交给 ArkUI Image 的 GIF 缓存文件名：对同一 URL 与大小保持不变。
 */
export function cylGIFCacheFileName(url: string, byteLength: number): string {
  let hash = 5381;
  for (let i = 0; i < url.length; i++) {
    hash = ((hash * 33) ^ url.charCodeAt(i)) >>> 0;
  }
  return 'cyl-gif-' + hash.toString(16) + '-' + byteLength + '.gif';
}
