/**
 * [EN] GIF frame timing (pure, unit tested with Node): each frame's delay (0 or less: 100 ms, as browsers do) and the frame
 *      shown at a progress. [CN] GIF 帧时间（纯逻辑，用 Node 做单元测试）：每帧的延时（0 或更小为 100 毫秒，与浏览器相同）以及某进度显示的帧。
 */
export const CYL_GIF_DEFAULT_DELAY_MS: number = 100;

/** [EN] The delays of `count` frames from the decoder's list. [CN] 由解码器列表得到 `count` 帧的延时。 */
export function cylGIFDelays(count: number, delays: number[]): number[] {
  const result: number[] = [];
  for (let i = 0; i < count; i++) {
    const delay = i < delays.length ? delays[i] : CYL_GIF_DEFAULT_DELAY_MS;
    result.push(delay > 0 ? delay : CYL_GIF_DEFAULT_DELAY_MS);
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
