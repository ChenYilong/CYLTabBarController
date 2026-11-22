/**
 * [EN] The engine-free side of an animation (pure, unit tested with Node: test/CYLAnimatedItemPlayer.test.mjs):
 *      - `CYLAnimatedItemPlayer`: the live handle of one engine view (play from the start, stop at a progress, speed,
 *        loop, the end of a pass). Each engine (GIF and SVGA here; Lottie, PAG and Rive in the modules
 *        cylanimateditem_lottie, cylanimateditem_pag and cylanimateditem_rive) subclasses it; an engine that cannot do
 *        something says so (`supportsSpeed`, `supportsLoops`, `supportsProgress`) and treats the call as a no-op.
 *      - `CYLAnimatedItemTimedPlayer`: a player that drives its own progress on a timer, for engines with no speed or
 *        no player of their own (PAG on HarmonyOS, GIF frames, SVGA frames).
 *      - `CYLAnimatedItemPlaybackDriver`: how an item plays by default, the same on every engine (iOS and Android
 *        `CYLAnimatedItemView`): selected, it plays once from the start; unselected, it rests at progress 0; a restart
 *        plays again; speed and loop apply at once. A host that drives the player itself (CollectionViewClassifyMenu's
 *        tags: resting progress, Play all) turns it off (`drivesPlayback` false) and gets the player.
 *      Moved from CollectionViewClassifyMenu's example (`CYLAnimationPlayer`, `CYLTimedPlayer`) and the play rules of
 *      cyltabbar's `CYLLottieIcon` / `CYLSVGAView`.
 * [CN] 动画中与引擎无关的部分（纯逻辑，用 Node 做单元测试：test/CYLAnimatedItemPlayer.test.mjs）：
 *      - `CYLAnimatedItemPlayer`：一个引擎视图的实时句柄（从头播放、停在某进度、速度、循环、一遍播放结束）。每个引擎（这里的 GIF 与
 *        SVGA；模块 cylanimateditem_lottie、cylanimateditem_pag、cylanimateditem_rive 中的 Lottie、PAG、Rive）继承它；引擎做不到的事
 *        通过 `supportsSpeed`、`supportsLoops`、`supportsProgress` 说明，并把调用当作空操作。
 *      - `CYLAnimatedItemTimedPlayer`：用定时器自行推进进度的播放器，供没有速度或没有自己播放器的引擎使用（鸿蒙上的 PAG、GIF 帧、SVGA 帧）。
 *      - `CYLAnimatedItemPlaybackDriver`：条目默认的播放方式，所有引擎相同（与 iOS、Android 的 `CYLAnimatedItemView` 一致）：选中时从头播放
 *        一次；未选中时停在进度 0；重播时再次播放；速度与循环立即生效。自行驱动播放器的宿主（CollectionViewClassifyMenu 的标签：静止进度、
 *        全部播放）关闭它（`drivesPlayback` 为 false）并获得播放器。
 *      从 CollectionViewClassifyMenu 示例（`CYLAnimationPlayer`、`CYLTimedPlayer`）以及 cyltabbar 的 `CYLLottieIcon` / `CYLSVGAView` 的
 *      播放规则迁移而来。
 */
import { CYLAnimatedItemSource } from './CYLAnimatedItemSource';

/**
 * [EN] The live player of one engine view. The base class plays nothing.
 * [CN] 一个引擎视图的实时播放器。基类不播放任何内容。
 */
export class CYLAnimatedItemPlayer {
  /** [EN] "Lottie", "PAG", "Rive", "SVGA", "GIF" or an app's type. [CN] 类型。 */
  readonly type: string;
  readonly source: CYLAnimatedItemSource;
  /**
   * [EN] Called when a play-once pass (`loops` off) reaches its end; an engine that cannot tell never calls it.
   * [CN] 只播放一次（`loops` 关闭）的一遍播放到结尾时调用；无法判断结束的引擎从不调用。
   */
  onEnded?: () => void;
  protected speedValue: number = 1;
  protected loopsValue: boolean = false;

  constructor(type: string, source: CYLAnimatedItemSource) {
    this.type = type;
    this.source = source;
  }

  get supportsSpeed(): boolean {
    return true;
  }

  get supportsLoops(): boolean {
    return true;
  }

  get supportsProgress(): boolean {
    return true;
  }

  get speed(): number {
    return this.speedValue;
  }

  /** [EN] Applied at once, also while playing (0 or less: 1). [CN] 立即生效，播放中也一样（0 或更小为 1）。 */
  set speed(value: number) {
    this.speedValue = value > 0 ? value : 1;
    this.applySpeed();
  }

  get loops(): boolean {
    return this.loopsValue;
  }

  /** [EN] Applied at once: turning it off lets the pass in progress finish. [CN] 立即生效：关闭时当前这一遍播放完。 */
  set loops(value: boolean) {
    this.loopsValue = value;
    this.applyLoops();
  }

  get isPlaying(): boolean {
    return false;
  }

  /** [EN] The progress (0...1), or undefined when the engine has none. [CN] 进度（0...1），引擎没有进度时为 undefined。 */
  get progress(): number | undefined {
    return undefined;
  }

  /**
   * [EN] Whether `applyColors` recolors the animation (false here; Lottie and Rive implement it).
   * [CN] `applyColors` 能否为动画改色（此处为 false；Lottie 与 Rive 实现了它）。
   */
  get supportsColors(): boolean {
    return false;
  }

  /**
   * [EN] Recolors the animation: keypath (Lottie, lottie-ios names) or view model property (Rive) → color ("#RRGGBB" or
   *      "#AARRGGBB"), for example a dark-mode color set; undefined restores the file's own colors. A no-op where
   *      `supportsColors` is false.
   * [CN] 为动画改色：keypath（Lottie，lottie-ios 名称）或视图模型属性（Rive）→ 颜色（"#RRGGBB" 或 "#AARRGGBB"），例如深色模式的颜色表；
   *      undefined 恢复文件自身的颜色。`supportsColors` 为 false 时为空操作。
   */
  applyColors(colors: Map<string, string> | undefined): void {
  }

  /** [EN] Plays from progress 0. [CN] 从进度 0 播放。 */
  play(): void {
  }

  /** [EN] Stops at `progress` (0...1; 1 is the last frame). [CN] 停在 `progress`（0...1；1 为最后一帧）。 */
  stopAtProgress(progress: number): void {
  }

  /** [EN] Releases the engine's resources. [CN] 释放引擎资源。 */
  destroy(): void {
    this.onEnded = undefined;
  }

  /** [EN] For subclasses: a play-once pass ended. [CN] 供子类调用：只播放一次的一遍播放结束。 */
  protected didEnd(): void {
    if (!this.loopsValue) {
      this.onEnded?.();
    }
  }

  protected applySpeed(): void {
  }

  protected applyLoops(): void {
  }
}

/**
 * [EN] The clock of a timed player (`setInterval` and `Date.now` by default; tests pass their own).
 * [CN] 定时播放器的时钟（默认 `setInterval` 与 `Date.now`；测试传入自己的时钟）。
 */
export interface CYLAnimatedItemClock {
  now(): number;
  start(tick: () => void, intervalMs: number): number;
  stop(timer: number): void;
}

export const CYL_ANIMATED_ITEM_SYSTEM_CLOCK: CYLAnimatedItemClock = {
  now: (): number => Date.now(),
  start: (tick: () => void, intervalMs: number): number => setInterval(tick, intervalMs),
  stop: (timer: number): void => clearInterval(timer)
};

/** [EN] About 60 frames per second. [CN] 约每秒 60 帧。 */
const CYL_TICK_MS: number = 16;

/**
 * [EN] A player that advances its own progress on a timer: speed, loop and progress for any engine. Subclasses give
 *      `durationMs` (one pass at speed 1) and draw `progressValue` in `render()`.
 * [CN] 用定时器自行推进进度的播放器：为任何引擎提供速度、循环与进度。子类提供 `durationMs`（速度 1 时一遍的时长）并在 `render()` 中
 *      绘制 `progressValue`。
 */
export class CYLAnimatedItemTimedPlayer extends CYLAnimatedItemPlayer {
  clock: CYLAnimatedItemClock = CYL_ANIMATED_ITEM_SYSTEM_CLOCK;
  protected progressValue: number = 0;
  private timer: number = -1;
  private lastTick: number = 0;

  get isPlaying(): boolean {
    return this.timer >= 0;
  }

  get progress(): number | undefined {
    return this.progressValue;
  }

  /** [EN] One pass at speed 1, in milliseconds (0: nothing to play). [CN] 速度 1 时一遍的毫秒数（0 表示无可播放）。 */
  protected get durationMs(): number {
    return 0;
  }

  /** [EN] Shows `progressValue`. [CN] 显示 `progressValue`。 */
  protected render(): void {
  }

  play(): void {
    this.stopTimer();
    this.progressValue = 0;
    this.render();
    if (this.durationMs <= 0) {
      return;
    }
    this.lastTick = this.clock.now();
    this.timer = this.clock.start(() => this.tick(), CYL_TICK_MS);
  }

  stopAtProgress(progress: number): void {
    this.stopTimer();
    this.progressValue = Math.min(1, Math.max(0, progress));
    this.render();
  }

  destroy(): void {
    this.stopTimer();
    super.destroy();
  }

  /** [EN] One timer tick (public for tests). [CN] 一次定时器回调（为测试而公开）。 */
  tick(): void {
    const now = this.clock.now();
    const elapsed = now - this.lastTick;
    this.lastTick = now;
    let p = this.progressValue + elapsed * this.speedValue / this.durationMs;
    let ended = false;
    if (p >= 1) {
      if (this.loopsValue) {
        p = p % 1;
      } else {
        p = 1;
        this.stopTimer();
        ended = true;
      }
    }
    this.progressValue = p;
    this.render();
    if (ended) {
      this.didEnd();
    }
  }

  private stopTimer(): void {
    if (this.timer >= 0) {
      this.clock.stop(this.timer);
      this.timer = -1;
    }
  }
}

/**
 * [EN] What the driver reads: the item's selection and playback. [CN] 驱动读取的内容：条目的选中状态与播放设置。
 */
export interface CYLAnimatedItemPlayback {
  selected: boolean;
  speed: number;
  loops: boolean;
  restartToken: number;
}

/**
 * [EN] Plays a player the way an item plays by default (see the file comment). An engine view calls `attach` once its
 *      player is ready and `update` whenever the item's playback changes.
 * [CN] 以条目的默认方式播放播放器（见文件注释）。引擎视图在播放器就绪时调用 `attach`，条目播放设置变化时调用 `update`。
 */
export class CYLAnimatedItemPlaybackDriver {
  private player?: CYLAnimatedItemPlayer;
  private last?: CYLAnimatedItemPlayback;

  attach(player: CYLAnimatedItemPlayer, playback: CYLAnimatedItemPlayback): void {
    this.player = player;
    player.speed = playback.speed;
    player.loops = playback.loops;
    if (playback.selected) {
      player.play();
    } else {
      player.stopAtProgress(0);
    }
    this.last = CYLAnimatedItemPlaybackDriver.copy(playback);
  }

  update(playback: CYLAnimatedItemPlayback): void {
    const player = this.player;
    const last = this.last;
    if (player === undefined || last === undefined) {
      return;
    }
    this.last = CYLAnimatedItemPlaybackDriver.copy(playback);
    if (playback.speed !== last.speed) {
      player.speed = playback.speed;
    }
    if (playback.loops !== last.loops) {
      player.loops = playback.loops;
      // [EN] Turning loop on replays a finished pass of a selected item (cyltabbar's CYLLottieIcon).
      // [CN] 开启循环时重新播放选中条目已结束的一遍（cyltabbar 的 CYLLottieIcon）。
      if (playback.loops && playback.selected && !player.isPlaying) {
        player.play();
      }
    }
    if (playback.restartToken !== last.restartToken) {
      player.play();
    } else if (playback.selected !== last.selected) {
      if (playback.selected) {
        player.play();
      } else {
        player.stopAtProgress(0);
      }
    }
  }

  detach(): void {
    this.player = undefined;
    this.last = undefined;
  }

  private static copy(playback: CYLAnimatedItemPlayback): CYLAnimatedItemPlayback {
    return {
      selected: playback.selected, speed: playback.speed, loops: playback.loops, restartToken: playback.restartToken
    };
  }
}

/**
 * [EN] What an engine view reports to, and reads from, its item (`CYLAnimatedItemEngineState` implements it).
 * [CN] 引擎视图向条目报告、并从条目读取的内容（由 `CYLAnimatedItemEngineState` 实现）。
 */
export interface CYLAnimatedItemEngineHost extends CYLAnimatedItemPlayback {
  /** [EN] Whether the item plays the player itself (the default rules); false: the host drives it. [CN] 是否按默认规则播放；false 时由宿主驱动。 */
  drivesPlayback: boolean;
  /** [EN] The file is drawn. [CN] 文件已绘制。 */
  onLoaded: () => void;
  /** [EN] The file cannot play. [CN] 文件无法播放。 */
  onFailed: () => void;
  /** [EN] A play-once pass ended. [CN] 只播放一次的一遍播放结束。 */
  onEnded: () => void;
  /** [EN] The player once ready, undefined when the view goes away. [CN] 就绪的播放器，视图消失时为 undefined。 */
  onPlayer: (player: CYLAnimatedItemPlayer | undefined) => void;
}

/**
 * [EN] The glue every engine view uses between its player and its item: hands the player out, reports it loaded, plays it
 *      by the default rules (unless the host drives it), forwards its end, and releases it. One per engine view.
 * [CN] 每个引擎视图在其播放器与条目之间使用的连接：交出播放器、报告加载完成、按默认规则播放（除非宿主驱动）、转发结束事件并释放。每个引擎视图一个。
 */
export class CYLAnimatedItemEngineBinding {
  private host?: CYLAnimatedItemEngineHost;
  private player?: CYLAnimatedItemPlayer;
  private driver: CYLAnimatedItemPlaybackDriver = new CYLAnimatedItemPlaybackDriver();

  /** [EN] The player now, if any. [CN] 当前的播放器（如有）。 */
  get current(): CYLAnimatedItemPlayer | undefined {
    return this.player;
  }

  /** [EN] The engine view's player is ready. [CN] 引擎视图的播放器已就绪。 */
  ready(host: CYLAnimatedItemEngineHost, player: CYLAnimatedItemPlayer): void {
    this.release();
    this.host = host;
    this.player = player;
    player.onEnded = () => this.host?.onEnded();
    host.onPlayer(player);
    if (host.drivesPlayback) {
      this.driver.attach(player, host);
    }
    host.onLoaded();
  }

  /** [EN] The file cannot play. [CN] 文件无法播放。 */
  failed(host: CYLAnimatedItemEngineHost): void {
    host.onFailed();
  }

  /** [EN] The item's playback changed. [CN] 条目的播放设置发生变化。 */
  update(host: CYLAnimatedItemEngineHost): void {
    this.host = host;
    if (host.drivesPlayback) {
      this.driver.update(host);
    }
  }

  /** [EN] The engine view goes away: the host loses the player, which is destroyed. [CN] 引擎视图消失：宿主失去播放器，播放器被销毁。 */
  release(): void {
    const player = this.player;
    this.player = undefined;
    this.driver.detach();
    if (player !== undefined) {
      this.host?.onPlayer(undefined);
      player.destroy();
    }
  }
}
