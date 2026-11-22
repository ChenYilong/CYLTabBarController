/**
 * [EN] SVGA frame timing (pure, unit tested with Node): one pass's duration and the frame shown at a progress.
 * [CN] SVGA 帧时间（纯逻辑，用 Node 做单元测试）：一遍的时长以及某进度显示的帧。
 */
/** [EN] The frame rate used when a file gives none. [CN] 文件未给出帧率时使用的帧率。 */
export const CYL_SVGA_DEFAULT_FPS: number = 20;

/** [EN] One pass in milliseconds at speed 1 (0 without frames). [CN] 速度 1 时一遍的毫秒数（没有帧时为 0）。 */
export function cylSVGADurationMs(frames: number, fps: number): number {
  if (!(frames > 0)) {
    return 0;
  }
  return frames * 1000 / (fps > 0 ? fps : CYL_SVGA_DEFAULT_FPS);
}

/**
 * [EN] The frame shown at `progress`: 0 is the first frame and 1 the last (CYLTableViewPlaceHolder's SVGA player).
 * [CN] `progress` 处显示的帧：0 为第一帧，1 为最后一帧（与 CYLTableViewPlaceHolder 的 SVGA 播放器相同）。
 */
export function cylSVGAFrameAt(frames: number, progress: number): number {
  if (!(frames > 0)) {
    return 0;
  }
  return Math.round(Math.min(1, Math.max(0, progress)) * (frames - 1));
}
