/**
 * [EN] The rules of a GIF given as a tab image on HarmonyOS (`CYLTabBarItemImageURL` ".gif", or an image path ending in
 *      ".gif"), not the GIF animation keys: it rests on its first frame until its tab is played (selected or tapped again),
 *      plays one pass, or repeats while `tabBarItemAnimationLoops` is on, then rests again (docs/GIF-Animation.md, as iOS
 *      915bddbd and Android `CYLGIFDrawable`). Pure logic, unit tested with Node (test/CYLGIFImagePlayback.test.mjs).
 * [CN] 鸿蒙上作为 Tab 图片传入的 GIF（`CYLTabBarItemImageURL` 为 ".gif"，或以 ".gif" 结尾的图片路径）的规则，不含 GIF 动画 key：在 Tab 被播放
 *      （选中或再次点击）之前停在第一帧，播放一遍，`tabBarItemAnimationLoops` 开启时重复播放，之后回到静止（docs/GIF-Animation.md，与 iOS 915bddbd、
 *      Android `CYLGIFDrawable` 一致）。纯逻辑，用 Node 做单元测试（test/CYLGIFImagePlayback.test.mjs）。
 */

/** [EN] Whether an image path or URL is a GIF (".gif", before any query or fragment). [CN] 图片路径或 URL 是否为 GIF。 */
export function cylIsGIFImagePath(path: Object | undefined): boolean {
  if (typeof path !== 'string') {
    return false;
  }
  const plain = path.split('#')[0].split('?')[0];
  return plain.toLowerCase().endsWith('.gif');
}

/** [EN] The play time of a GIF: the sum of its frame delays (ms), 100 ms for a missing or 0 delay, as browsers do. [CN] GIF 的播放时长：各帧延时之和（毫秒），缺失或为 0 的延时按 100 毫秒。 */
export function cylGIFDuration(delays: number[]): number {
  let total = 0;
  for (const delay of delays) {
    total += delay > 0 ? delay : 100;
  }
  return total > 0 ? total : 100;
}

/** [EN] What a GIF image shows: Resting (the first frame), PlayingOnce, Looping. [CN] GIF 图片显示的内容：静止（第一帧）、播放一遍、重复播放。 */
export class CYLGIFImageState {
  static readonly Resting: number = 0;
  static readonly PlayingOnce: number = 1;
  static readonly Looping: number = 2;
}

/**
 * [EN] The playback state of the GIF images of a tab bar, one per tab index. `play` returns the new state (and a token
 *      that changes on every play, so the view restarts the animation); `finish` ends a single pass unless a newer play
 *      started; `setLoops(false)` stops every GIF image, `setLoops(true)` repeats the selected tab's.
 * [CN] TabBar 中 GIF 图片的播放状态，每个 Tab 下标一个。`play` 返回新状态（以及每次播放都会变化的令牌，使视图重新开始动画）；`finish` 结束单次播放，
 *      除非之后又开始了新的播放；`setLoops(false)` 停止所有 GIF 图片，`setLoops(true)` 让选中 Tab 的 GIF 重复播放。
 */
export class CYLGIFImagePlayback {
  private states: number[] = [];
  private tokens: number[] = [];
  loops: boolean = false;

  stateOf(index: number): number {
    return this.states[index] ?? CYLGIFImageState.Resting;
  }

  tokenOf(index: number): number {
    return this.tokens[index] ?? 0;
  }

  /** [EN] Plays the GIF image of a tab from its first frame. [CN] 从第一帧播放某个 Tab 的 GIF 图片。 */
  play(index: number): number {
    this.states[index] = this.loops ? CYLGIFImageState.Looping : CYLGIFImageState.PlayingOnce;
    this.tokens[index] = this.tokenOf(index) + 1;
    return this.tokens[index];
  }

  /** [EN] A single pass that started with `token` has ended. [CN] 以 `token` 开始的单次播放已结束。 */
  finish(index: number, token: number): boolean {
    if (this.tokenOf(index) !== token || this.stateOf(index) !== CYLGIFImageState.PlayingOnce) {
      return false;
    }
    this.states[index] = CYLGIFImageState.Resting;
    return true;
  }

  /** [EN] Rests a tab's GIF image on its first frame. [CN] 让某个 Tab 的 GIF 图片停在第一帧。 */
  stop(index: number): void {
    this.states[index] = CYLGIFImageState.Resting;
    this.tokens[index] = this.tokenOf(index) + 1;
  }

  /** [EN] The loop switch: off rests every GIF image, on repeats the selected one. [CN] 循环开关：关闭时所有 GIF 图片停止，开启时选中的重复播放。 */
  setLoops(loops: boolean, selectedIndex: number, count: number): void {
    this.loops = loops;
    for (let index = 0; index < count; index++) {
      if (!loops) {
        if (this.stateOf(index) !== CYLGIFImageState.Resting) {
          this.stop(index);
        }
      } else if (index === selectedIndex) {
        this.play(index);
      }
    }
  }
}
